// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OptimumAISeedSaleVesting is Ownable(msg.sender) {
    // Events
    event VestingInitialized(address indexed investor, uint256 totalAmount, uint256 releaseTime);
    event TokensClaimed(address indexed investor, uint256 amountClaimed);
    event EmergencyWithdrawal(address token, uint256 amount);

    // State variables
    IERC20 public token;
    mapping(address => uint256) private _totalAllocated;
    mapping(address => uint256) private _released;
    mapping(address => uint256) public _vestingStart;

    uint256 public constant TGE_RELEASE_PERCENTAGE = 50; // TGE release percentage
    uint256 public constant VESTING_DURATION = 3 * 30 days; // Duration of the vesting period

    constructor(address _token) {
        token = IERC20(_token);
    }

    /// @notice Initializes vesting for an investor
    /// @param investor The address of the investor
    /// @param totalAmount The total amount of tokens to be vested
    /// @param startTime The start time of the vesting period
    /// @dev Only the owner can call this function
    function initializeVesting(address investor, uint256 totalAmount, uint256 startTime)
        external
        onlyOwner
    {
        require(totalAmount > 0, "OptimumAIVesting: totalAmount must be greater than 0");
        _totalAllocated[investor] = totalAmount;
        _vestingStart[investor] = startTime;
        emit VestingInitialized(investor, totalAmount, startTime);
    }

    /// @notice Allows an investor to claim their vested tokens
    /// @dev The investor can claim their vested tokens after the vesting period
    function claimTokens() external {
        uint256 amount = claimableAmount(msg.sender);
        require(amount > 0, "OptimumAIVesting: No claimable amount available");
        _released[msg.sender] += amount;
        token.transfer(msg.sender, amount);
        emit TokensClaimed(msg.sender, amount);
    }

    /// @notice Returns the amount of tokens claimable by an investor
    /// @param investor The address of the investor
    /// @return The amount of tokens claimable by the investor
    function claimableAmount(address investor) public view returns (uint256) {
        uint256 totalAllocated = _totalAllocated[investor];
        if (block.timestamp < _vestingStart[investor]) {
            return 0;
        }

        uint256 initialRelease = totalAllocated * TGE_RELEASE_PERCENTAGE / 100;
        if (block.timestamp < _vestingStart[investor] + VESTING_DURATION) {
            uint256 timeSinceStart = block.timestamp - _vestingStart[investor];
            uint256 vestedAmount =
                (totalAllocated - initialRelease) * timeSinceStart / VESTING_DURATION;
            return initialRelease + vestedAmount - _released[investor];
        } else {
            return totalAllocated - _released[investor]; // All tokens are vested after the full duration
        }
    }

    /// @notice Returns the total amount of tokens released to an investor
    /// @param investor The address of the investor
    /// @return The total amount of tokens released to the investor
    function releasedAmount(address investor) public view returns (uint256) {
        return _released[investor];
    }

    /// @notice Allows the owner to withdraw any ERC20 tokens from the contract
    /// @param erc20Token The address of the ERC20 token to withdraw
    /// @param amount The amount of tokens to withdraw
    function emergencyWithdrawERC20(IERC20 erc20Token, uint256 amount) external onlyOwner {
        require(erc20Token.transfer(owner(), amount), "Transfer failed");
        emit EmergencyWithdrawal(address(erc20Token), amount);
    }
}
