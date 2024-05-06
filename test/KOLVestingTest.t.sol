// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {KOLVestingContract} from "../src/KOLVestingContract.sol";
import {MockERC20} from "./MockERC20.sol";

contract KOLVestingTest is Test {
    KOLVestingContract public vestingContract;
    MockERC20 public token;
    address[] public investors;

    function setUp() public {
        token = new MockERC20();
        vestingContract = new KOLVestingContract(address(token));
        vestingContract.transferOwnership(address(this));

        uint256 startTime = block.timestamp + 1 days; //start time is after first day
        token.approve(address(vestingContract), 10_000 ether);
        token.transfer(address(vestingContract), 2000 ether);

        // Initialize multiple investors with custom vesting parameters
        investors.push(address(0x123)); // Original investor
        investors.push(address(0x456)); // Additional investor for testing
        uint256[] memory totalAmounts = new uint256[](2);
        totalAmounts[0] = 1000 ether;
        totalAmounts[1] = 500 ether;
        uint256[] memory cliffDurations = new uint256[](2);
        cliffDurations[0] = 30 days; // 1 month cliff
        cliffDurations[1] = 15 days; // 15 days cliff
        uint256[] memory vestingDurations = new uint256[](2);
        vestingDurations[0] = 90 days; // 3 months vesting
        vestingDurations[1] = 60 days; // 2 months vesting
        uint256[] memory immediateReleasePercentages = new uint256[](2);
        immediateReleasePercentages[0] = 10; // 10% immediate release
        immediateReleasePercentages[1] = 20; // 20% immediate release
        uint256[] memory startTimes = new uint256[](2);
        startTimes[0] = startTime;
        startTimes[1] = startTime;

        for (uint256 i = 0; i < investors.length; i++) {
            vm.prank(address(this));
            vestingContract.initializeVesting(
                investors[i],
                totalAmounts[i],
                cliffDurations[i],
                vestingDurations[i],
                immediateReleasePercentages[i],
                startTimes[i]
            );
        }
    }

    function testInitialVesting() public {
        vm.warp(block.timestamp + 1 days); // Warp past the start time
        for (uint256 i = 0; i < investors.length; i++) {
            // Fetch each field individually if the Solidity version or testing framework doesn't support struct retrieval directly
            (uint256 totalAllocated,,,, uint256 immediateReleasePercentage,) =
                vestingContract.vestingSchedules(investors[i]);

            uint256 initialClaimable = totalAllocated * immediateReleasePercentage / 100;
            uint256 expectedAmount = vestingContract.claimableAmount(investors[i]);

            assertEq(expectedAmount, initialClaimable, "Initial vesting amount incorrect");
        }
    }

    function testClaimTokens() public {
        for (uint256 i = 0; i < investors.length; i++) {
            vm.warp(block.timestamp + 31 days); // Warp past the cliff duration for claiming
            vm.startPrank(investors[i]);
            vestingContract.claimTokens();
            vm.stopPrank();

            // Check balances after claiming
            (, uint256 releasedAmount,,,,) = vestingContract.vestingSchedules(investors[i]);
            assertGt(releasedAmount, 0, "Released amount should be greater than 0");
            assertEq(
                token.balanceOf(investors[i]),
                releasedAmount,
                "Claimed tokens do not match released amount"
            );
        }
    }

    function testVestingProgression() public {
        address investor = investors[0]; // Test with the first investor

        // Simulate passing time and claiming tokens at different intervals
        uint256[] memory checkpoints = new uint256[](3);
        checkpoints[0] = block.timestamp + 46 days;
        checkpoints[1] = block.timestamp + 76 days;
        checkpoints[2] = block.timestamp + 121 days;

        for (uint256 i = 0; i < checkpoints.length; i++) {
            vm.warp(checkpoints[i]);
            vm.startPrank(investor);
            vestingContract.claimTokens();
            vm.stopPrank();

            (, uint256 releasedAmount,,,,) = vestingContract.vestingSchedules(investor);
            assertGt(
                releasedAmount, 0, "Released amount should be greater than 0 at each checkpoint"
            );
        }
    }

    function testClaimWithoutVesting() public {
        vm.warp(block.timestamp + 3 days);
        address randomUser = address(0x666);

        // Try to claim tokens before vesting starts
        vm.expectRevert("No tokens are claimable");
        vm.prank(randomUser);
        vestingContract.claimTokens();
    }

    // test claim before vesting starts
    function testClaimBeforeVestingStart() public {
        address investor = investors[0];
        vm.expectRevert("Vesting has not started yet");
        vm.prank(investor);
        vestingContract.claimTokens();
    }
}
