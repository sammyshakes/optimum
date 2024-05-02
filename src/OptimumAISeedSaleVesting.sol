// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptimumAISeedSaleVesting is Ownable(msg.sender) {
    // Events
    event VestingInitialized(address indexed investor, uint256 totalAmount, uint256 releaseTime);
    event TokensClaimed(address indexed investor, uint256 amountClaimed);
    event EmergencyWithdrawal(address token, uint256 amount);

    struct Investor {
        uint256 totalAllocated;
        uint256 released;
        uint256 vestingStart;
    }

    // State variables
    IERC20 public token;
    mapping(address => Investor) public investors;

    uint256 public constant TGE_RELEASE_PERCENTAGE = 50; // TGE release percentage
    uint256 public constant VESTING_DURATION = 3 * 30 days; // Duration of the vesting period

    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @notice Initializes vesting for multiple investors
    /// @param investorsArray The addresses of the investors
    /// @param totalAmounts The total amounts of tokens to be vested for each investor
    /// @param startTimes The start times of the vesting period for each investor
    /// @dev Only the owner can call this function
    function initializeVesting(
        address[] calldata investorsArray,
        uint256[] calldata totalAmounts,
        uint256[] calldata startTimes
    ) external onlyOwner {
        require(
            investorsArray.length == totalAmounts.length && totalAmounts.length == startTimes.length,
            "OptimumAIVesting: Array lengths must match"
        );

        for (uint256 i = 0; i < investorsArray.length; i++) {
            require(totalAmounts[i] > 0, "OptimumAIVesting: Total amount must be greater than 0");
            investors[investorsArray[i]] = Investor({
                totalAllocated: totalAmounts[i],
                released: 0,
                vestingStart: startTimes[i]
            });
            emit VestingInitialized(investorsArray[i], totalAmounts[i], startTimes[i]);
        }
    }

    /// @notice Allows an investor to claim their vested tokens
    /// @dev The investor must have tokens available to claim
    function claimTokens() external {
        uint256 amount = claimableAmount(msg.sender);
        require(amount > 0, "OptimumAIVesting: No claimable amount available");
        Investor storage investor = investors[msg.sender];
        investor.released += amount;
        token.transfer(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);
    }

    /// @notice Returns the amount of tokens that an investor can claim
    /// @param investor The address of the investor
    /// @return The amount of tokens that can be claimed
    function claimableAmount(address investor) public view returns (uint256) {
        Investor storage inv = investors[investor];
        if (block.timestamp < inv.vestingStart) {
            return 0;
        }

        uint256 initialRelease = inv.totalAllocated * TGE_RELEASE_PERCENTAGE / 100;
        if (block.timestamp < inv.vestingStart + VESTING_DURATION) {
            uint256 timeSinceStart = block.timestamp - inv.vestingStart;
            uint256 vestedAmount =
                (inv.totalAllocated - initialRelease) * timeSinceStart / VESTING_DURATION;
            return initialRelease + vestedAmount - inv.released;
        } else {
            return inv.totalAllocated - inv.released; // All tokens are vested after the full duration
        }
    }

    /// @notice Returns the total amount of tokens released to an investor
    /// @param investor The address of the investor
    /// @return The total amount of tokens released to the investor
    function releasedAmount(address investor) public view returns (uint256) {
        return investors[investor].released;
    }

    /// @notice Allows the owner to emergency withdraw any remaining tokens from the contract
    /// @dev This function is only callable by the owner
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(owner(), balance), "Transfer failed");
        emit EmergencyWithdrawal(address(token), balance);
    }
}
