// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.27 <0.9.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * ## References
 * - https://docs.soliditylang.org/en/latest/contracts.html#constant-and-immutable-state-variables
 * - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
contract CPQDOwnable {
    /**
     * Address of this contract's creator.
     */
    address public immutable owner = msg.sender;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error UnauthorizedAccount(address account);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, UnauthorizedAccount(msg.sender));
        _;
    }
}

contract CPQDComittable {
    bytes32 public constant NOT_COMMITED = 0;

    bytes32 public committedHash = NOT_COMMITED;

    error ContractNotCommittedYet();
    error ContractAlreadyCommitted(bytes32 committedHash);

    function isCommitted() public view returns (bool) {
        return committedHash != NOT_COMMITED;
    }

    modifier commited(bool shouldBeCommitted) {
        if (shouldBeCommitted) {
            require(isCommitted(), ContractNotCommittedYet());
        } else {
            require(!isCommitted(), ContractAlreadyCommitted(committedHash));
        }
        _;
    }

    function commitHash(bytes32 resultHash) internal commited(false) {
        committedHash = resultHash;
    }
}

contract CPQDRevealable {
    uint8 public constant NOT_REVEALED = 0;

    uint8 public revealedValue = NOT_REVEALED;
    uint256 public revealedSalt = NOT_REVEALED;

    error ContractNotRevealedYet();
    error ContractAlreadyRevealed(uint256 revealedValue, uint256 revealedSalt);

    function isRevealed() public view returns (bool) {
        return revealedSalt != NOT_REVEALED;
    }

    modifier revealed(bool shouldBeRevealed) {
        if (shouldBeRevealed) {
            require(isRevealed(), ContractNotRevealedYet());
        } else {
            require(!isRevealed(), ContractAlreadyRevealed(revealedValue, revealedSalt));
        }
        _;
    }

    function revealValue(uint8 value, uint256 salt) internal revealed(false) {
        revealedValue = value;
        revealedSalt = salt;
    }
}

contract CPQD is CPQDOwnable, CPQDComittable, CPQDRevealable {
    mapping (uint8 => address []) public bets;

    function commitment(bytes32 resultHash) external onlyOwner commited(false) {
        commitHash(resultHash);
    }

    function reveal(uint8 value, uint256 salt) external onlyOwner commited(true) revealed(false) {
        assert(keccak256(abi.encodePacked(value, salt)) == committedHash);
        revealValue(value, salt);
    }

    function bet(uint8 bettedValue) external commited(true) revealed(false) {
        bets[bettedValue].push(msg.sender);
    }

    function getResults() external view revealed(true) returns (address [] memory) {
        return bets[revealedValue];
    }
}
