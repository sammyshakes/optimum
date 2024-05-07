// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {OptimumAI} from "../src/OptimumAI.sol";
import {MultiSend} from "../src/MultiSend.sol";
import {OptimumAISeedSaleVesting} from "../src/OptimumAISeedSaleVesting.sol";
import {OptimumKOLVesting} from "../src/OptimumKOLVesting.sol";

contract Deploy is Script {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));

    OptimumAI public optimum;

    function run() external {
        vm.startBroadcast(deployerPrivateKey);
        optimum = new OptimumAI();
        new MultiSend();
        new OptimumAISeedSaleVesting(address(optimum));
        new OptimumKOLVesting(address(optimum));

        console2.log("Optimum deployed");
        console2.log("MultiSend deployed");
        console2.log("OptimumAISeedSaleVesting deployed");
        console2.log("OptimumKOLVesting deployed");

        vm.stopBroadcast();
    }
}
