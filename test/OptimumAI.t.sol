// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OptimumAI} from "../src/OptimumAI.sol";

contract OptimumTest is Test {
    OptimumAI public optimum;

    function setUp() public {
        optimum = new OptimumAI();
    }
}
