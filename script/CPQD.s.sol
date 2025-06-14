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

    /**
     * @dev Read input from `envName`, falling back to prompting the user with `promptMessage`.
     */
    function readOrPrompt(string memory envName, string memory promptMessage) private returns (string memory) {
        try vm.envString(envName) returns (string memory result) {
            if (bytes(result).length != 0) {
                return result;
            }
        } catch { }

        return vm.prompt(promptMessage);
    }

    function targetContract() internal returns (CPQD) {
        address cpqd_addr;
        if (address(cpqd) == address(0)) {
            string memory input = readOrPrompt("CONTRACT", "Enter contract address");
            cpqd_addr = vm.parseAddress(input);
        } else {
            cpqd_addr = vm.envOr("CONTRACT", address(cpqd));
        }

        require(cpqd_addr != address(0));
        cpqd = CPQD(cpqd_addr);
        return cpqd;
    }

    /**
     * @dev Must be called after `targetContract()`.
     */
    function inputValue() internal returns (uint8) {
        string memory input = readOrPrompt("VALUE", "Enter chosen value");
        uint256 value = vm.parseUint(input);

        require(value < cpqd.MAXIMUM_VALUE());
        return uint8(value);
    }

    function inputSalt() internal returns (uint256) {
        string memory input = readOrPrompt("SALT", "Enter secret salt");
        bytes32 salt = vm.parseBytes32(input);
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
     * @notice Secret value can be passed on the `VALUE` environment variable. Uses last contract address for
     *  commitment, or a new one provided via the `CONTRACT` variable.
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
     * @notice Betted value can be passed on the `VALUE` environment variable. Uses last contract address for betting,
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
     * @notice Secret value and salt can be passed on the `VALUE` and `SALT` environment variables, respectively. Uses
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
