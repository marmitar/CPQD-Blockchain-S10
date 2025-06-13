// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CPQD {

    bytes32 hash;
    uint salt;
    mapping (uint => address []) public bets;

    function commitment (bytes32 h, uint s) public {
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