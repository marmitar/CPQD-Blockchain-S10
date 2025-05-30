// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CPQD {
    /**
     * Address of this contract's creator.
     *
     * ## References
     * - https://docs.soliditylang.org/en/latest/contracts.html#constant-and-immutable-state-variables
     * - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
     */
    address public immutable owner = msg.sender;

    bytes32 hash;
    uint salt;
    mapping (uint => address []) public bets;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error CPQDUnauthorizedAccount(address account);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert CPQDUnauthorizedAccount(msg.sender);
        }
        _;
    }

    function commitment(bytes32 h, uint s) public onlyOwner {
        hash = h;
        salt = s;
    }

    function bet(uint b) public {
        bets[b].push(msg.sender);
    }

    function get_results(uint secret) public view returns (address [] memory){
        return bets[secret];
    }
}
