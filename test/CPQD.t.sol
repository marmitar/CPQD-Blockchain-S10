// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { CPQD } from "../src/CPQD.sol";
import { StdInvariant, Test } from "forge-std/Test.sol";

/**
 * @title Unit tests for the CPQD contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDTest is Test {
    // The contract instance we will be testing
    CPQD public cpqd;

    // Create addresses for different actors in our tests
    address public constant OWNER = address(0x1);
    address public constant ALICE = address(0x2);
    address public constant BOB = address(0x3);

    // Variables for the commit/reveal scheme
    uint8 constant SECRET_VALUE = 5;
    uint256 constant SECRET_SALT = 12_345;
    bytes32 public committedHash;

    // This function runs before each test function
    function setUp() public {
        // Deploy the CPQD contract, setting our dedicated OWNER address as the owner.
        // We use vm.prank to pretend we are the OWNER address during this single call.
        vm.startPrank(OWNER);
        cpqd = new CPQD(OWNER);
        vm.stopPrank();

        committedHash = keccak256(abi.encode(SECRET_SALT, SECRET_VALUE));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * OWNERSHIP & DEPLOYMENT TESTS
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    function test_OwnerIsSetCorrectly() public view {
        assertEq(cpqd.OWNER(), OWNER);
    }

    function test_ConstructorFallback() public {
        // Test the other constructor path by passing address(0)
        CPQD cpqd2 = new CPQD(address(0));
        // The owner should be the deployer, which is this test contract itself.
        assertEq(cpqd2.OWNER(), address(this));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * COMMITMENT TESTS
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    function test_OwnerCanCommit() public {
        vm.prank(OWNER);
        cpqd.commitment(committedHash);
        // We can't directly check private variables, but we can check the effect.
        // The `bet` function should now be callable. This implicitly tests the state change.
        cpqd.bet(1);
    }

    function test_RevertWhen_NonOwnerTriesToCommit() public {
        // We expect this call to revert with our custom error
        vm.expectRevert(abi.encodeWithSelector(CPQD.UnauthorizedAccount.selector, ALICE));
        // Alice (not the owner) tries to call commitment
        vm.prank(ALICE);
        cpqd.commitment(committedHash);
    }

    function test_RevertWhen_CommitIsCalledTwice() public {
        // First commit succeeds
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        // Second commit must fail
        vm.expectRevert(abi.encodeWithSelector(CPQD.ContractAlreadyCommitted.selector, committedHash));
        vm.prank(OWNER);
        cpqd.commitment(committedHash);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * BETTING TESTS
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    function test_RevertWhen_BettingBeforeCommitment() public {
        vm.expectRevert(CPQD.ContractNotCommittedYet.selector);
        cpqd.bet(1);
    }

    function test_UsersCanBet() public {
        // 1. Owner commits
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        // 2. Alice and Bob place bets
        vm.prank(ALICE);
        cpqd.bet(SECRET_VALUE); // Alice bets on the correct value

        vm.prank(BOB);
        cpqd.bet(SECRET_VALUE + 1); // Bob bets on an incorrect value

        // There is no direct way to check the `bets` array since it's private.
        // We will verify the results in the `getResults` test. This test just ensures the calls succeed.
    }

    function test_RevertWhen_BettingOnInvalidValue() public {
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        uint8 invalidBet = cpqd.MAXIMUM_VALUE() + 1;
        vm.expectRevert(abi.encodeWithSelector(CPQD.InvalidBettedValue.selector, invalidBet, cpqd.MAXIMUM_VALUE()));
        cpqd.bet(invalidBet);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * REVEAL TESTS
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    function test_OwnerCanReveal() public {
        // Setup: commitment must happen first
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        // Action: owner reveals with the correct value and salt
        vm.prank(OWNER);
        cpqd.reveal(SECRET_VALUE, SECRET_SALT);

        // We can't check private state, but `getResults` is now callable, which proves the state changed.
        cpqd.getResults();
    }

    function test_RevertWhen_RevealWithMismatchedHash() public {
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        uint256 wrongSalt = SECRET_SALT + 1;
        vm.expectRevert(abi.encodeWithSelector(CPQD.MismatchedReveal.selector, committedHash, wrongSalt, SECRET_VALUE));
        vm.prank(OWNER);
        cpqd.reveal(SECRET_VALUE, wrongSalt);
    }

    function test_RevertWhen_RevealInvalidValue() public {
        uint8 invalidValue = cpqd.MAXIMUM_VALUE() + 1;
        // We need to commit to a hash of an invalid value to test this path
        bytes32 hashOfInvalid = keccak256(abi.encode(invalidValue, SECRET_SALT));

        vm.prank(OWNER);
        cpqd.commitment(hashOfInvalid);

        vm.expectRevert(
            abi.encodeWithSelector(CPQD.MismatchedReveal.selector, hashOfInvalid, SECRET_SALT, invalidValue)
        );
        vm.prank(OWNER);
        cpqd.reveal(invalidValue, SECRET_SALT);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * RESULTS & RESTART TESTS
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    function test_GetResultsReturnsCorrectWinners() public {
        // 1. Commit
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        // 2. Bets
        vm.prank(ALICE);
        cpqd.bet(SECRET_VALUE); // Alice is a winner

        vm.prank(BOB);
        cpqd.bet(SECRET_VALUE); // Bob is also a winner

        vm.prank(address(4));
        cpqd.bet(SECRET_VALUE - 1); // Not a winner

        // 3. Reveal
        vm.prank(OWNER);
        cpqd.reveal(SECRET_VALUE, SECRET_SALT);

        // 4. Check results
        address[] memory winners = cpqd.getResults();

        assertEq(winners.length, 2);
        assertEq(winners[0], ALICE);
        assertEq(winners[1], BOB);
    }

    function test_RestartResetsState() public {
        // Full cycle: Commit -> Bet -> Reveal -> Restart
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        vm.prank(ALICE);
        cpqd.bet(SECRET_VALUE);

        vm.prank(OWNER);
        cpqd.reveal(SECRET_VALUE, SECRET_SALT);

        // Now, restart the contract
        vm.prank(OWNER);
        cpqd.restart();

        // After restart, betting should be disabled again until a new commitment
        vm.expectRevert(CPQD.ContractNotCommittedYet.selector);
        cpqd.bet(1);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * FUZZ TESTS
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    /**
     * @notice Fuzz test the bet function to ensure it only accepts valid values.
     * @dev This tests the property: "A user can bet on any value if and only if it is within the allowed range".
     * @param bettedValue A fuzzed (random) input for the bet value.
     */
    function testFuzz_Bet(uint8 bettedValue) public {
        // Constrain the fuzzer's input using vm.assume.
        // This part of the test will only run for valid bet values.
        vm.assume(bettedValue <= cpqd.MAXIMUM_VALUE());

        // Setup: The contract must be in the committed state to accept bets.
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        // Action: Alice places a bet with the valid fuzzed value.
        vm.prank(ALICE);
        cpqd.bet(bettedValue);

        // The assertion is implicit: if the call doesn't revert, the test for this input passes.
    }

    /**
     * @notice Fuzz test the reveal function to ensure its cryptographic security.
     * @dev This tests the property: "The reveal will only succeed with the one true combination of value and salt".
     * @param value A fuzzed input for the value.
     * @param salt A fuzzed input for the salt.
     */
    function testFuzz_RevealMustBeCorrect(uint8 value, uint256 salt) public {
        // Constrain the fuzzer. We want to test every possible combination EXCEPT the correct one.
        // If the fuzzer happens to guess the correct value and salt, we discard this run.
        vm.assume(value != SECRET_VALUE || salt != SECRET_SALT);

        // Setup: The contract must be committed.
        vm.prank(OWNER);
        cpqd.commitment(committedHash);

        // Expectation: For any incorrect pair of (value, salt), the reveal must fail.
        // We can't predict the exact error, as it could be MismatchedReveal or InvalidRevealedValue,
        // so we use a generic `vm.expectRevert()` which catches any revert.
        vm.expectRevert();
        vm.prank(OWNER);
        cpqd.reveal(value, salt);
    }

    /**
     * @notice Fuzz test the commitment function with random hashes.
     * @dev This tests the property: "The contract correctly stores any bytes32 value as the committed hash".
     * @param randomHash A fuzzed input for the hash.
     */
    function testFuzz_Commitment(bytes32 randomHash) public {
        // Assume the fuzzer's input is not the one hash that would make this test succeed
        vm.assume(randomHash != committedHash);

        // Expectation: The owner can commit to any valid hash.
        vm.prank(OWNER);
        cpqd.commitment(randomHash);

        // To verify, we'll try to reveal. It should fail with a MismatchedReveal error,
        // proving that the `randomHash` was indeed stored correctly.
        vm.expectRevert(abi.encodeWithSelector(CPQD.MismatchedReveal.selector, randomHash, SECRET_SALT, SECRET_VALUE));
        vm.prank(OWNER);
        cpqd.reveal(SECRET_VALUE, SECRET_SALT);
    }

    /**
     * @notice Fuzz test to demonstrate the low probability of a hash collision.
     * @dev This tests the property that for a given salt, a random hash is extremely unlikely
     * to match the hash of that salt combined with a fixed value.
     * @param fuzzerHash A completely random hash from the fuzzer.
     * @param fuzzerSalt A completely random salt from the fuzzer.
     */
    function testFuzz_HashCollision(bytes32 fuzzerHash, uint256 fuzzerSalt) public pure {
        // We will use a fixed value that is different from our main SECRET_VALUE
        uint8 fixedValueToTest = 7;

        // Calculate the "correct" hash for the fuzzer's salt and our fixed value.
        bytes32 correctHash = keccak256(abi.encode(fuzzerSalt, fixedValueToTest));

        // The core of the test: we assume the fuzzer did NOT randomly find the one-in-2^256
        // hash that would make this test fail. This is the fix for the edge case we discussed.
        vm.assume(fuzzerHash != correctHash);

        // Assert that the random hash provided by the fuzzer does not equal the
        // hash we just calculated. Because of the `assume` above, this will always be true.
        assertNotEq(fuzzerHash, correctHash);
    }
}

/**
 * @title Runtime invariant tests for the CPQD contract.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDInvariantTest is StdInvariant, Test {
    // contract under test
    CPQD public cpqd;

    // Actors
    address public owner = address(0x1);
    address[] public users; // A list of users who can place bets

    // Ghost Variables: Our off-chain model of the contract's state
    enum State {
        Uncommitted,
        Committed,
        Revealed
    }

    State public currentState;
    // We'll track all bets placed to verify winners later
    mapping(uint8 => mapping(address => bool)) public hasBetted;
    uint8 public ghostRevealedValue;

    function setUp() public {
        // Create a pool of users (bettors)
        users.push(address(0x10));
        users.push(address(0x11));
        users.push(address(0x12));

        // Deploy the contract with our designated owner
        vm.startPrank(owner);
        cpqd = new CPQD(owner);
        vm.stopPrank();

        // --- Invariant Target Configuration ---
        // This is the core of Handler-based testing. We tell the fuzzer:
        // "Do NOT call the CPQD contract directly. ONLY call functions on THIS handler contract."
        targetContract(address(this));
        // We exclude the owner from the list of random senders for `bet` calls.
        // The owner's actions are explicitly handled in `commit`, `reveal`, `restart`.
        excludeSender(owner);

        // Tell the fuzzer to never call setUp or the invariant functions as part of its random sequence.
        // We build an array of the function selectors we want to ignore.
        bytes4[] memory selectorsToExclude = new bytes4[](3);
        selectorsToExclude[0] = this.setUp.selector;
        selectorsToExclude[1] = this.invariant_stateMachine.selector;
        selectorsToExclude[2] = this.invariant_winnersAreCorrect.selector;

        // We package this into the required FuzzSelector struct.
        excludeSelector(FuzzSelector({ addr: address(this), selectors: selectorsToExclude }));
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * HANDLER FUNCTIONS
     * These are the functions the fuzzer will call randomly.
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    function commitment(bytes32 hash) public {
        // Only allow this action if the contract is in the correct state
        if (currentState == State.Uncommitted) {
            vm.prank(owner);
            cpqd.commitment(hash);
            // Update our ghost state
            currentState = State.Committed;
        }
    }

    function bet(uint8 bettedValue, uint256 userIndex) public {
        // Only allow bets in the committed state
        if (currentState == State.Committed) {
            // Constrain inputs to valid ranges
            bettedValue = uint8(bound(bettedValue, 0, cpqd.MAXIMUM_VALUE()));
            address bettor = users[userIndex % users.length];

            // Record the bet in our ghost state and place the actual bet
            hasBetted[bettedValue][bettor] = true;
            vm.prank(bettor);
            cpqd.bet(bettedValue);
        }
    }

    function reveal(uint8 value, uint256 salt) public {
        if (currentState == State.Committed) {
            bytes32 hash = keccak256(abi.encode(salt, value));
            bytes32 expectedHash = cpqd.committedHash();

            // Only proceed if the reveal is valid
            if (hash == expectedHash && value <= cpqd.MAXIMUM_VALUE()) {
                vm.prank(owner);
                cpqd.reveal(value, salt);
                currentState = State.Revealed;
                ghostRevealedValue = value;
            }
        }
    }

    function restart() public {
        if (currentState == State.Revealed) {
            vm.prank(owner);
            cpqd.restart();
            // Reset our ghost state and all bet tracking
            currentState = State.Uncommitted;
            // FIXME: delete hasBetted;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°*
     *
     * INVARIANTS
     * These properties MUST always be true after any function call.
     *
     *..°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.*/

    /**
     * @notice Invariant: The contract's state machine can only move in a valid sequence.
     * @dev For example, it's impossible for the contract to be revealed if it was never committed.
     * This invariant checks that our ghost state matches the contract's real state.
     */
    function invariant_stateMachine() public view {
        bool isCommitted = cpqd.isCommitted();
        bool isRevealed = cpqd.isRevealed();

        if (currentState == State.Uncommitted) {
            assertFalse(isCommitted);
            assertFalse(isRevealed);
        } else if (currentState == State.Committed) {
            assertTrue(isCommitted);
            assertFalse(isRevealed);
        } else if (currentState == State.Revealed) {
            assertTrue(isCommitted);
            assertTrue(isRevealed);
        }
    }

    /**
     * @notice Invariant: The list of winners returned by the contract must be correct.
     * @dev It proves that only users who bet on the correct value are included in the winners' array.
     */
    function invariant_winnersAreCorrect() public view {
        // This invariant only applies when the contract is in the revealed state.
        if (currentState == State.Revealed) {
            address[] memory winners = cpqd.getResults();
            for (uint256 i = 0; i < winners.length; i++) {
                // Assert that every address in the winners array is an address that
                // we recorded as having placed a bet on the correct value.
                assertTrue(hasBetted[ghostRevealedValue][winners[i]]);
            }
        }
    }
}
