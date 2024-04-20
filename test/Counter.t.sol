// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Optimum} from "../src/Optimum.sol";

contract OptimumTest is Test {
    Optimum public optimum;

    function setUp() public {
        optimum = new Optimum();
    }
}
