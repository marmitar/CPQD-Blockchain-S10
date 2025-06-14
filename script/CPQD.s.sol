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
     * @return The final owner.
     */
    function run() external returns (CPQD, address) {
        address owner = vm.envOr("OWNER", address(0));

        vm.startBroadcast();
        CPQD cpqd = new CPQD(owner);
        vm.stopBroadcast();

        return (cpqd, cpqd.OWNER());
    }
}

/**
 * @title Base class for other CPQD scripts.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDScript is Script {
    CPQD private cpqd = CPQD(address(0));

    function targetContract() internal returns (CPQD) {
        address cpqd_addr = vm.envOr("CONTRACT", address(0));
        if (cpqd_addr != address(0)) {
            cpqd = CPQD(cpqd_addr);
        }

        require(address(cpqd) != address(0));
        return cpqd;
    }

    /**
     * @dev Must be called after `targetContract`.
     */
    function inputValue() internal view returns (uint8) {
        uint value = vm.envUint("VALUE");
        require(value < cpqd.MAXIMUM_VALUE());
        return uint8(value);
    }

    function inputSalt() internal view returns (uint256) {
        bytes32 salt = vm.envBytes32("SALT");
        return uint256(salt);
    }

    function randomSalt() internal returns (uint256) {
        string[] memory inputs = new string[](4);
        inputs[0] = "head";
        inputs[1] = "-c";
        inputs[2] = "32";
        inputs[3] = "/dev/random";

        bytes memory randomBytes = vm.ffi(inputs);
        return uint256(bytes32(randomBytes));
    }
}

/**
 * @title Commmit a secret value to a CPQD instance.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDCommit is CPQDScript {
    /**
     * @notice Secret value is passed on the `VALUE` environment variable. Uses last contract address for commitment,
     *  or a new one provided via the `CONTRACT` variable.
     * @return Information of the target contract in the network.
     * @return Chosen secret value.
     * @return Randomly generated salt.
     * @return Committed hash.
     */
    function run() external returns (CPQD, uint8, uint256, bytes32) {
        CPQD cpqd = targetContract();
        uint8 value = inputValue();
        uint256 salt = randomSalt();

        bytes32 commitHash = keccak256(abi.encode(salt, value));

        vm.startBroadcast();
        cpqd.commitment(commitHash);
        vm.stopBroadcast();

        return (cpqd, value, salt, commitHash);
    }
}

/**
 * @title Place a CPQD bet on the given value.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDBet is CPQDScript {
    /**
     * @notice Betted value is passed on the `VALUE` environment variable. Uses last contract address for betting,
     *  or a new one provided via the `CONTRACT` variable.
     * @return Information of the target contract in the network.
     * @return Betted value.
     * @return Address associated with the bet.
     */
    function run() external returns (CPQD, uint8, address) {
        CPQD cpqd = targetContract();
        uint8 value = inputValue();

        vm.startBroadcast();
        cpqd.bet(value);
        vm.stopBroadcast();

        return (cpqd, value, msg.sender);
    }
}

/**
 * @title Reveal committed secret in CPQD instance.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDReveal is CPQDScript {
    /**
     * @notice Secret value and salt are passed on the `VALUE` and `SALT` environment variables, respectively. Uses
     *  last contract address for reveal, or a new one provided via the `CONTRACT` variable.
     * @return Information of the target contract in the network.
     * @return Revealed secret value.
     * @return Revealed random salt.
     */
    function run() external returns (CPQD, uint8, uint256) {
        CPQD cpqd = targetContract();
        uint8 value = inputValue();
        uint256 salt = inputSalt();

        vm.startBroadcast();
        cpqd.reveal(value, salt);
        vm.stopBroadcast();

        return (cpqd, value, salt);
    }
}

/**
 * @title Reset CPQD instance state after reveal.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDRestart is CPQDScript {
    /**
     * @notice Uses last contract address for restart, or a new one provided via the `CONTRACT` variable.
     * @return Information of the target contract in the network.
     */
    function run() external returns (CPQD) {
        CPQD cpqd = targetContract();

        vm.startBroadcast();
        cpqd.restart();
        vm.stopBroadcast();

        return cpqd;
    }
}
