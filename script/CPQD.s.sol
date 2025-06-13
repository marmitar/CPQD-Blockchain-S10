// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { CPQD } from "../src/CPQD.sol";
import { Script } from "forge-std/Script.sol";

/**
 * @title Deploy a new CPQD contract to a network.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDDeploy is Script {
    /**
     * @notice The `sender` is used as owner by default, but that can be overridden by setting the `OWNER` environment
     *  variable.
     * @return The new contract information in the network.
     */
    function run() external returns (CPQD) {
        address owner = vm.envOr("OWNER", address(0));

        vm.startBroadcast();
        CPQD cpqd = new CPQD(owner);
        vm.stopBroadcast();

        return cpqd;
    }
}
