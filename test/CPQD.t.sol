// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.8.27 <0.9.0;

import { CPQD } from "../src/CPQD.sol";

import { Test, console } from "forge-std/Test.sol";

contract CPQDTest is Test {
    CPQD public cpqd;

    function setUp() public {
        cpqd = new CPQD(address(0));
        // cpqd.setNumber(0);
    }

    // function test_Increment() public {
    //     cpqd.increment();
    //     assertEq(cpqd.number(), 1);
    // }

    // function testFuzz_SetNumber(uint256 x) public {
    //     cpqd.setNumber(x);
    //     assertEq(cpqd.number(), x);
    // }
}
