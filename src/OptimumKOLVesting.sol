// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract OptimumKOLVesting is Ownable(msg.sender), Pausable {
    struct VestingSchedule {
        uint256 totalAllocated;
        uint256 released;
        uint256 cliffDuration;
        uint256 vestingDuration;
        uint256 immediateReleasePercentage;
        uint256 startTime;
    }

    IERC20 public token;
    mapping(address => VestingSchedule) public vestingSchedules;

    event VestingInitialized(address indexed kol, uint256 totalAmount, uint256 startTime);
    event TokensClaimed(address indexed kol, uint256 amountClaimed);
    event VestingScheduleUpdated(address indexed kol);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @notice Initializes vesting for a KOL
    /// @param kolAddress The address of the KOL
    /// @param totalTokenAmount The total amount of tokens to be vested
    /// @param cliffDuration The duration of the cliff period in seconds
    /// @param vestingDuration The duration of the vesting period in seconds
    /// @param immediateReleasePercentage The percentage of tokens to be released immediately
    /// @param startTime The start time of the vesting period
    /// @dev Only the owner can call this function
    function initializeVesting(
        address kolAddress,
        uint256 totalTokenAmount,
        uint256 cliffDuration,
        uint256 vestingDuration,
        uint256 immediateReleasePercentage,
        uint256 startTime
    ) external onlyOwner {
        require(totalTokenAmount > 0, "Total token amount must be greater than 0");
        require(
            immediateReleasePercentage <= 100,
            "Immediate release percentage must be between 0 and 100"
        );

        vestingSchedules[kolAddress] = VestingSchedule({
            totalAllocated: totalTokenAmount,
            released: 0,
            cliffDuration: cliffDuration,
            vestingDuration: vestingDuration,
            immediateReleasePercentage: immediateReleasePercentage,
            startTime: startTime
        });

        emit VestingInitialized(kolAddress, totalTokenAmount, startTime);
    }

    /// @notice Allows a KOL to claim their vested tokens
    /// @dev The KOL must have tokens available to claim
    function claimTokens() external whenNotPaused {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];
        require(block.timestamp >= schedule.startTime, "Vesting has not started yet");

        uint256 amount = claimableAmount(msg.sender);
        require(amount > 0, "No tokens are claimable");

        schedule.released += amount;
        token.transfer(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);
    }

    /// @notice Returns the amount of tokens that a KOL can claim
    /// @param kol The address of the KOL
    /// @return The amount of tokens that can be claimed
    function claimableAmount(address kol) public view returns (uint256) {
        VestingSchedule storage schedule = vestingSchedules[kol];

        uint256 immediateRelease =
            schedule.totalAllocated * schedule.immediateReleasePercentage / 100;

        // Immediately release the specified percentage of tokens when vesting starts
        if (block.timestamp < schedule.startTime) {
            return 0;
        } else if (
            block.timestamp >= schedule.startTime
                && block.timestamp < schedule.startTime + schedule.cliffDuration
        ) {
            // Only the immediate release amount is available during the cliff period
            return immediateRelease - schedule.released;
        } else {
            uint256 totalVestingTime =
                schedule.startTime + schedule.cliffDuration + schedule.vestingDuration;
            if (block.timestamp < totalVestingTime) {
                uint256 timeSinceCliff =
                    block.timestamp - (schedule.startTime + schedule.cliffDuration);
                uint256 vestedAmount = (
                    (schedule.totalAllocated - immediateRelease) * timeSinceCliff
                ) / schedule.vestingDuration;
                return immediateRelease + vestedAmount - schedule.released;
            } else {
                return schedule.totalAllocated - schedule.released; // All tokens are vested after the full duration
            }
        }
    }

    /// @notice Adjusts the vesting schedule for a KOL
    /// @param kol The address of the KOL
    /// @param newCliffDuration The new duration of the cliff period in seconds
    /// @param newVestingDuration The new duration of the vesting period in seconds
    /// @param newImmediateReleasePercentage The new percentage of tokens to be released immediately
    /// @dev Only the owner can call this function
    function adjustVestingSchedule(
        address kol,
        uint256 newCliffDuration,
        uint256 newVestingDuration,
        uint256 newImmediateReleasePercentage
    ) external onlyOwner {
        require(newImmediateReleasePercentage <= 100, "Invalid release percentage");

        VestingSchedule storage schedule = vestingSchedules[kol];
        schedule.cliffDuration = newCliffDuration;
        schedule.vestingDuration = newVestingDuration;
        schedule.immediateReleasePercentage = newImmediateReleasePercentage;

        emit VestingScheduleUpdated(kol);
    }

    /// @notice Allows the owner to pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allows the owner to unpause the contract
    function unpause() external onlyOwner {
        _unpause();
    }
}
