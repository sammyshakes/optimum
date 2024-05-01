// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {OptimumAI} from "../src/OptimumAI.sol";
import {MultiSend} from "../src/MultiSend.sol";

contract Deploy is Script {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        new OptimumAI();
        new MultiSend();

        console2.log("Optimum deployed");
        console2.log("MultiSend deployed");

        vm.stopBroadcast();
    }
}
