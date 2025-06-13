// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

/**
 * @title A basic betting contract for the adventurous.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 * @notice Your prize can be extracted with the owner.
 * @dev Please use a valid commitment, otherwise the contract will be locked forever.
 */
contract CPQD {
    /**
     * @notice The contract creator, responsible for setting up the commitment and revealing the winners.
     * @dev This implementation is based on the following sources:
     * - https://docs.soliditylang.org/en/latest/contracts.html#constant-and-immutable-state-variables
     * - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
     */
    address public immutable OWNER = msg.sender;

    /**
     * @dev Account is not authorized to run the request function. This incident will be reported.
     * @param account Offending account.
     */
    error UnauthorizedAccount(address account);

    /**
     * @dev Ensure that only the owner can run the function.
     */
    modifier onlyOwner() {
        require(OWNER == msg.sender, UnauthorizedAccount(msg.sender));
        _;
    }

    // NOTE: Most attributes are private to protect against modification by extending this contract.

    /**
     * @dev Current commitment state.
     */
    bool private isCommitted = false;
    /**
     * @dev Hash committed by the `owner` for reveal later. This should be the Keccak-256 hash of the secretly selected
     *  bet result with a randomly generated salt. The value and salt must be provided and will be checked during the
     *  reveal later.
     */
    bytes32 private committedHash;
    // TODO: use a hash function that allows zero knowledge input validation

    /**
     * @dev Function can only be called after commitment, which has not happened yet.
     */
    error ContractNotCommittedYet();
    /**
     * @dev Function can only be called before commitment, but that has already happened.
     * @param committedHash The currently committed hash.
     */
    error ContractAlreadyCommitted(bytes32 committedHash);

    /**
     * @dev Ensure commitment is in the specified state for the function to run.
     * @param shouldBeCommitted When `true`, ensure hash is committed and, when `false`, ensure hash is not committed.
     */
    modifier committed(bool shouldBeCommitted) {
        if (shouldBeCommitted) {
            require(isCommitted, ContractNotCommittedYet());
        } else {
            require(!isCommitted, ContractAlreadyCommitted(committedHash));
        }
        _;
    }

    /**
     * @dev Current reveal state.
     */
    bool private isRevealed = false;
    /**
     * @dev Value revealed from commitment. Should respect `MAXIMUM_VALUE`, but this is not enforced to avoid the
     *  contract entering a locked state.
     */
    uint8 private revealedValue;
    /**
     * @dev The salt used for commitment secrecy. Should be randomly generated, but it's stored here for simplicity.
     */
    uint256 private revealedSalt;

    /**
     * @dev Function can only be called after reveal, which has not happened yet.
     */
    error ContractNotRevealedYet();
    /**
     * @dev Function can only be called before reveal, but that has already happened.
     * @param revealedValue The value revealed from latest commitment.
     * @param revealedSalt The random salt revealed from latest commitment.
     */
    error ContractAlreadyRevealed(uint8 revealedValue, uint256 revealedSalt);

    /**
     * @dev Ensure commitment reveal is in the specified state for the function to run.
     * @param shouldBeRevealed When `true`, ensure value is revealed and, when `false`, ensure value is not revealed.
     */
    modifier revealed(bool shouldBeRevealed) {
        if (shouldBeRevealed) {
            require(isRevealed, ContractNotRevealedYet());
        } else {
            require(!isRevealed, ContractAlreadyRevealed(revealedValue, revealedSalt));
        }
        _;
    }

    /**
     * @dev Value and salt provided by the owner does not match commitment hash. Contract possibly enters a locked
     *  state after this.
     * @param committedHash The hash provided by the owner during commitment.
     * @param salt Salt provided by the owner for reveal, possibly invalid.
     * @param value Value provided by the owner for reveal, possibly invalid.
     */
    error InvalidReveal(bytes32 committedHash, uint256 salt, uint8 value);

    /**
     * @notice Hash `value` and `salt` to validate against committed hash.
     * @param salt Original salt for the committed hash.
     * @param value Original value for the committed hash.
     * @dev Throws `InvalidReveal` if the inputs don't match. If `salt` is lost, then contract will forever be locked
     *  in "committed but not revealed" state.
     */
    function checkCommitment(uint256 salt, uint8 value) private view committed(true) {
        bytes32 computedHash;
        // See https://getfoundry.sh/forge/reference/forge-lint/#asm-keccak256
        assembly {
            mstore(0x00, salt)
            mstore(0x20, salt)
            computedHash := keccak256(0x00, 0x21)
        }
        require(computedHash == committedHash, InvalidReveal(committedHash, salt, value));
    }

    /**
     * @notice Predefined maximum accepted value for the `bet` function. Owner should respect this during commitment.
     * @dev Replace this with your preferred value.
     */
    uint8 public constant MAXIMUM_VALUE = 10;

    /**
     * @dev User tried betting on a value bigger than `MAXIMUM_VALUE`.
     * @param bettedValue User input.
     * @param maximumValue Same as `MAXIMUM_VALUE`.
     */
    error InvalidBettedValue(uint8 bettedValue, uint8 maximumValue);

    /**
     * @dev Currently enrolled users, awaiting reveal by the owner.
     */
    address[][MAXIMUM_VALUE + 1] private bets;

    /**
     * @notice Commit hash for the result value to be revealed later. Bets can only be placed after this function has
     *  been called by the owner.
     * @param resultHash Keccak-256 hash of the pair `(salt, value)`, where `value` is the secretly chosen bet result
     *  and `salt` is a randomly generated byte string to protect against brute-force reveals.
     */
    function commitment(bytes32 resultHash) external onlyOwner committed(false) {
        committedHash = resultHash;
        isCommitted = true;
    }

    /**
     * @notice Reveal bet results for the users. The hash of `(salt, value)` must match previously committed hash.
     * @param value Selected result during commitment.
     * @param salt Random salt used for hiding `value` from brute-force reveal.
     */
    function reveal(uint8 value, uint256 salt) external onlyOwner committed(true) revealed(false) {
        checkCommitment(salt, value);
        isRevealed = true;
        revealedValue = value;
        revealedSalt = salt;
    }

    /**
     * @notice Reset contract after results have been revealed.
     * @dev Even this function is not able able to clear a locked state if the salt is lost.
     */
    function restart() external onlyOwner revealed(true) {
        isCommitted = false;
        isRevealed = false;
        delete bets;
    }

    /**
     * @notice Bet on a specified value and wait for results.
     * @param bettedValue The correct value, hopefully.
     */
    function bet(uint8 bettedValue) external committed(true) revealed(false) {
        require(bettedValue <= MAXIMUM_VALUE, InvalidBettedValue(bettedValue, MAXIMUM_VALUE));
        // TODO: don't let users bet on locked contracts
        bets[bettedValue].push(msg.sender);
    }

    // NOTE: Renamed from 'get_results'. See https://getfoundry.sh/forge/reference/forge-lint/#mixed-case-function
    /**
     * @notice Get winners from revealed value.
     * @return List of addresses that betted on the correct value.
     */
    function getResults() external view revealed(true) returns (address[] memory) {
        return bets[revealedValue % (MAXIMUM_VALUE + 1)];
    }
}
