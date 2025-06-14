// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { CPQD } from "../src/CPQD.sol";
import { Script, console } from "forge-std/Script.sol";

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
        console.log("current sender:", msg.sender);
        console.log("selected owner:", owner);

        vm.startBroadcast();
        CPQD cpqd = new CPQD(owner);
        vm.stopBroadcast();

        console.log("new contract:", address(cpqd));
        console.log("effective owner:", cpqd.OWNER());
        return (cpqd, cpqd.OWNER());
    }
}

/**
 * @title Base class for other CPQD scripts.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
abstract contract CPQDScript is Script {
    CPQD private cpqd = CPQD(address(0));

    /**
     * @dev Read input from `envName`, falling back to prompting the user with `promptMessage`.
     */
    function readOrPrompt(string memory envName, string memory promptMessage) private returns (string memory) {
        try vm.envString(envName) returns (string memory envValue) {
            console.log("evironment variable:", envName, envValue);

            if (bytes(vm.trim(envValue)).length != 0) {
                return envValue;
            }
        } catch { }

        string memory promptInput = vm.prompt(promptMessage);
        console.log("user input on prompt:", promptMessage, "=>", promptInput);
        return promptInput;
    }

    function targetContract() internal returns (CPQD) {
        address cpqdAddr;
        if (address(cpqd) == address(0)) {
            string memory input = readOrPrompt("CONTRACT", "Enter contract address");
            cpqdAddr = vm.parseAddress(input);
        } else {
            cpqdAddr = vm.envOr("CONTRACT", address(cpqd));
        }

        require(cpqdAddr != address(0));
        cpqd = CPQD(cpqdAddr);
        console.log("target contract selected:", cpqdAddr);
        return cpqd;
    }

    /**
     * @dev Must be called after `targetContract()`.
     */
    function inputValue() internal returns (uint8) {
        string memory input = readOrPrompt("VALUE", "Enter chosen value");
        uint256 value = vm.parseUint(input);

        require(value <= cpqd.MAXIMUM_VALUE());
        uint8 result = uint8(value);
        console.log("input value:", result);
        return result;
    }

    function inputSalt() internal returns (uint256) {
        string memory input = readOrPrompt("SALT", "Enter secret salt");
        uint256 salt;
        try vm.parseBytes32(input) returns (bytes32 data) {
            salt = uint256(data);
        } catch {
            salt = vm.parseUint(input);
        }

        uint256 result = uint256(salt);
        console.log("input salt:", result);
        return result;
    }

    function randomSalt() internal view returns (uint256) {
        uint256 result = vm.randomUint(256);
        console.log("random salt:", result);
        return result;
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

        console.log("commitment done:", uint256(cpqd.committedHash()));
        return (cpqd, value, salt, cpqd.committedHash());
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

        console.log("bet placed:", value, msg.sender);
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

        bytes32 commitHash = keccak256(abi.encode(salt, value));
        console.log("revealing commitment from hash:", uint256(commitHash));

        vm.startBroadcast();
        cpqd.reveal(value, salt);
        vm.stopBroadcast();

        console.log("commitment revealed:", cpqd.revealedValue(), cpqd.revealedSalt());
        return (cpqd, cpqd.revealedValue(), cpqd.revealedSalt());
    }
}

/**
 * @title Get winners after CPQD reveal.
 * @author Tiago de Paula <tiagodepalves@gmail.com>
 */
contract CPQDResults is CPQDScript {
    /**
     * @return Information of the target contract in the network.
     * @return Array of winner addresses.
     */
    function run() external returns (CPQD, address[] memory) {
        CPQD cpqd = targetContract();

        address[] memory results = cpqd.getResults();
        for (uint256 i = 0; i < results.length; i++) {
            console.log("winner:", i, "=>", results[i]);
        }
        if (results.length <= 0) {
            console.log("no winners.");
        }
        return (cpqd, results);
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

        console.log("contract restarted.");
        return cpqd;
    }
}
