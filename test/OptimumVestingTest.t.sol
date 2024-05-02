// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OptimumAISeedSaleVesting} from "../src/OptimumAISeedSaleVesting.sol";
import {MockERC20} from "./MockERC20.sol";

contract OptimumVestingTest is Test {
    OptimumAISeedSaleVesting public vestingContract;
    MockERC20 public token;
    address[] public investors;

    function setUp() public {
        token = new MockERC20();
        vestingContract = new OptimumAISeedSaleVesting(address(token));
        vestingContract.transferOwnership(address(this));

        uint256 startTime = block.timestamp;
        token.approve(address(vestingContract), 10_000 ether);
        token.transfer(address(vestingContract), 1000 ether);

        // Initialize multiple investors
        investors.push(address(0x123)); // Original investor
        investors.push(address(0x456)); // Additional investor for testing
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1000 ether;
        amounts[1] = 500 ether; // Different amount for variety
        uint256[] memory startTimes = new uint256[](2);
        startTimes[0] = startTime;
        startTimes[1] = startTime;

        vm.prank(address(this));
        vestingContract.initializeVesting(investors, amounts, startTimes);
    }

    function testInitialVesting() public {
        for (uint256 i = 0; i < investors.length; i++) {
            uint256 expectedAmount = vestingContract.claimableAmount(investors[i]);
            //get total allocated amount
            (uint256 totalAllocated,,) = vestingContract.investors(investors[i]);
            uint256 initialClaimable = totalAllocated * 50 / 100;
            assertEq(expectedAmount, initialClaimable, "Initial vesting amount incorrect");
        }
    }

    function testClaimTokens() public {
        for (uint256 i = 0; i < investors.length; i++) {
            vm.startPrank(investors[i]);
            vestingContract.claimTokens();
            vm.stopPrank();

            // Check balances after claiming
            uint256 releasedAmount = vestingContract.releasedAmount(investors[i]);
            assertEq(
                token.balanceOf(investors[i]),
                releasedAmount,
                "Claimed tokens do not match released amount"
            );
            //get total allocated amount
            (uint256 totalAllocated,,) = vestingContract.investors(investors[i]);
            assertEq(releasedAmount, totalAllocated * 50 / 100, "Claimed amount incorrect");
        }
    }

    function testLinearVestingProgression() public {
        address investor = investors[0]; // Test with the first investor
        (,, uint256 vestingStart) = vestingContract.investors(investor);

        // Define checkpoints and expected vested amounts
        uint256[] memory checkpoints = new uint256[](3);
        checkpoints[0] = vestingStart + 15 days;
        checkpoints[1] = vestingStart + 45 days;
        checkpoints[2] = vestingStart + 75 days;

        (uint256 totalTokens,,) = vestingContract.investors(investor);
        uint256 initialRelease = totalTokens * 50 / 100;
        uint256 remainingTokens = totalTokens - initialRelease;

        for (uint256 i = 0; i < checkpoints.length; i++) {
            uint256 timeElapsedSinceStart = checkpoints[i] - vestingStart;
            uint256 expectedAmount = initialRelease
                + (remainingTokens * timeElapsedSinceStart) / vestingContract.VESTING_DURATION();

            vm.warp(checkpoints[i]);
            vm.startPrank(investor);
            vestingContract.claimTokens();
            vm.stopPrank();

            assertEq(
                token.balanceOf(investor), expectedAmount, "Incorrect vested amount at checkpoint"
            );
            assertEq(
                vestingContract.releasedAmount(investor),
                expectedAmount,
                "Incorrect released amount recorded in the contract"
            );
        }
    }

    function testClaimWithoutVesting() public {
        address randomUser = address(0x666);

        // Try to claim tokens without any vested tokens
        vm.expectRevert("OptimumAIVesting: No claimable amount available");
        vm.prank(randomUser);
        vestingContract.claimTokens();
    }
}
