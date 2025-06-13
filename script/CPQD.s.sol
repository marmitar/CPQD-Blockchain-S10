// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { CPQD } from "../src/CPQD.sol";

import { Script, console } from "forge-std/Script.sol";

contract CPQDScript is Script {
    CPQD public cpqd;

    function setUp() public { }

    function run() public {
        vm.startBroadcast();

        cpqd = new CPQD(address(0));

        vm.stopBroadcast();
    }
}
