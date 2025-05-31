// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.27 <0.9.0;

contract CPQD {
    // ## References
    // - https://docs.soliditylang.org/en/latest/contracts.html#constant-and-immutable-state-variables
    // - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
    address public immutable owner = msg.sender;

    error UnauthorizedAccount(address account);

    modifier onlyOwner() {
        require(owner == msg.sender, UnauthorizedAccount(msg.sender));
        _;
    }

    bool private isCommitted = false;
    bytes32 private committedHash;

    error ContractNotCommittedYet();
    error ContractAlreadyCommitted(bytes32 committedHash);

    modifier committed(bool shouldBeCommitted) {
        if (shouldBeCommitted) {
            require(isCommitted, ContractNotCommittedYet());
        } else {
            require(!isCommitted, ContractAlreadyCommitted(committedHash));
        }
        _;
    }

    bool private isRevealed = false;
    uint8 private revealedValue;
    uint256 private revealedSalt;

    error ContractNotRevealedYet();
    error ContractAlreadyRevealed(uint8 revealedValue, uint256 revealedSalt);

    modifier revealed(bool shouldBeRevealed) {
        if (shouldBeRevealed) {
            require(isRevealed, ContractNotRevealedYet());
        } else {
            require(!isRevealed, ContractAlreadyRevealed(revealedValue, revealedSalt));
        }
        _;
    }

    error InvalidReveal(bytes32 committedHash, uint8 value, uint256 salt);

    function checkCommitment(uint8 value, uint256 salt) private view committed(true) {
        bytes32 currentHash = committedHash;
        bytes32 computedHash = keccak256(abi.encodePacked(value, salt));
        require(computedHash == currentHash, InvalidReveal(committedHash, value, salt));
    }

    uint8 public constant MAXIMUM_VALUE = 10;
    error InvalidBettedValue(uint8 bettedValue, uint8 maximumValue);

    address[][10] private bets;

    function commitment(bytes32 resultHash) external onlyOwner committed(false) {
        committedHash = resultHash;
        isCommitted = true;
    }

    function reveal(uint8 value, uint256 salt) external onlyOwner committed(true) revealed(false) {
        checkCommitment(value, salt);
        isRevealed = true;
        revealedValue = value;
        revealedSalt = salt;
    }

    function restart() external onlyOwner revealed(true) {
        isCommitted = false;
        isRevealed = false;
        delete bets;
    }

    function bet(uint8 bettedValue) external committed(true) revealed(false) {
        require(bettedValue <= MAXIMUM_VALUE, InvalidBettedValue(bettedValue, MAXIMUM_VALUE));
        bets[bettedValue].push(msg.sender);
    }

    function getResults() external view revealed(true) returns (address [] memory) {
        return bets[revealedValue];
    }
}
