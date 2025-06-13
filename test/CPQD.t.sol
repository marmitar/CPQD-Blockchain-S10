// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { CPQD } from "../src/CPQD.sol";

import { Test, console } from "forge-std/Test.sol";

contract CPQDTest is Test {
    // The contract instance we will be testing
    CPQD public cpqd;

    // Create addresses for different actors in our tests
    address public constant OWNER = address(0x1); // A dedicated address for the owner
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

        // Pre-calculate the hash that the owner will commit to.
        // This matches the on-chain hashing logic.
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
}
