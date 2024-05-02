// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {OptimumAISeedSaleVesting} from "../src/OptimumAISeedSaleVesting.sol";
import {MockERC20} from "./MockERC20.sol";

contract OptimumVestingTest is Test {
    OptimumAISeedSaleVesting public vestingContract;
    MockERC20 public token;
    address investor = address(0x123);

    function setUp() public {
        token = new MockERC20();
        vestingContract = new OptimumAISeedSaleVesting(address(token));
        vestingContract.transferOwnership(address(this));

        uint256 startTime = block.timestamp;
        token.approve(address(vestingContract), 10_000 ether);
        token.transfer(address(vestingContract), 1000 ether);

        vm.prank(address(this));
        vestingContract.initializeVesting(investor, 1000 ether, startTime);
    }

    function testInitialVesting() public {
        // Immediately after TGE, 50% should be available
        assertEq(vestingContract.claimableAmount(investor), 500 ether);
    }

    function testClaimTokens() public {
        // Simulate investor claiming tokens
        vm.startPrank(investor);
        vestingContract.claimTokens();
        vm.stopPrank();

        // Verify investor received the tokens and vestingContract reduced balance
        assertEq(token.balanceOf(investor), 500 ether);
        assertEq(vestingContract.releasedAmount(investor), 500 ether);
    }

    function testLinearVestingProgression() public {
        // Get initial vesting start time
        (,, uint256 vestingStart) = vestingContract.investors(investor);

        // Define test checkpoints and their expected vested amounts
        uint256[] memory checkpoints = new uint256[](3);
        checkpoints[0] = vestingStart + 15 days; // Halfway through the first month
        checkpoints[1] = vestingStart + 45 days; // One and a half months in
        checkpoints[2] = vestingStart + 75 days; // Two and a half months in

        uint256 totalTokens = 1000 ether;
        uint256 initialRelease = totalTokens * 50 / 100; // 500 ether released at TGE
        uint256 remainingTokens = totalTokens - initialRelease; // 500 ether to be vested linearly

        uint256[] memory expectedAmounts = new uint256[](3);
        for (uint256 i = 0; i < checkpoints.length; i++) {
            uint256 timeElapsedSinceStart = checkpoints[i] - vestingStart;
            expectedAmounts[i] = initialRelease
                + (remainingTokens * timeElapsedSinceStart) / vestingContract.VESTING_DURATION();
        }

        for (uint256 i = 0; i < checkpoints.length; i++) {
            vm.warp(checkpoints[i]);
            vm.startPrank(investor);
            vestingContract.claimTokens();
            vm.stopPrank();

            // Check the actual token balance against the expected vested amount
            assertEq(
                token.balanceOf(investor),
                expectedAmounts[i],
                "Incorrect vested amount at checkpoint"
            );
            assertEq(
                vestingContract.releasedAmount(investor),
                expectedAmounts[i],
                "Incorrect released amount recorded in the contract"
            );
        }
    }

    function testClaimWithoutVesting() public {
        address randomUser = address(0x456);

        // Try to claim tokens without any vested tokens
        vm.expectRevert("OptimumAIVesting: No claimable amount available");
        vm.prank(randomUser);
        vestingContract.claimTokens();
    }
}
