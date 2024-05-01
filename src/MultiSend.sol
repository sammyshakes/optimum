// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @dev Creates an escape hatch function that can be called in an emergency to send any ether or tokens held in the contract to an `escapeHatchDestination`.
contract Escapable is Ownable(msg.sender), ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice The `escapeHatch()` should only be called as a last resort if a security issue is uncovered or something unexpected happened.
    /// @param _token to transfer, use 0x0 for ether
    function escapeHatch(address _token, address payable _escapeHatchDestination)
        external
        onlyOwner
        nonReentrant
    {
        require(_escapeHatchDestination != address(0), "Invalid destination address");

        if (_token == address(0)) {
            // Escape ether
            uint256 balance = address(this).balance;
            (bool sent,) = _escapeHatchDestination.call{value: balance}("");
            require(sent, "Failed to send Ether");
            emit EscapeHatchCalled(_token, balance);
        } else {
            // Escape tokens
            IERC20 token = IERC20(_token);
            uint256 balance = token.balanceOf(address(this));
            token.safeTransfer(_escapeHatchDestination, balance);
            emit EscapeHatchCalled(_token, balance);
        }
    }

    event EscapeHatchCalled(address indexed token, uint256 amount);
}

/// @title MultiSend
/// @notice `MultiSend` is a contract for sending multiple ETH/ERC20 Tokens to multiple addresses.
contract MultiSend is Pausable, Escapable {
    using Address for address;
    using SafeERC20 for IERC20;

    /// @notice Send to multiple addresses using two arrays which include the address and the amount.
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of amounts to send
    function multiTransfer(address payable[] calldata _addresses, uint256[] calldata _amounts)
        external
        payable
        whenNotPaused
    {
        require(_addresses.length == _amounts.length, "Address and amount array lengths must match");
        uint256 totalSent = 0;
        for (uint256 i = 0; i < _addresses.length; i++) {
            totalSent += _amounts[i];
            require(totalSent <= msg.value, "Insufficient Ether provided");
            (bool sent,) = _addresses[i].call{value: _amounts[i]}("");
            require(sent, "Failed to send Ether");
        }
    }

    /// @notice Send ERC20 tokens to multiple addresses using two arrays which include the address and the amount.
    /// @param _token The token to send
    /// @param _addresses Array of addresses to send to
    /// @param _amounts Array of token amounts to send
    function multiTransferToken(
        address _token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external whenNotPaused {
        require(_addresses.length == _amounts.length, "Address and amount array lengths must match");
        IERC20 token = IERC20(_token);
        uint256 totalRequired = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            totalRequired += _amounts[i];
        }
        token.safeTransferFrom(msg.sender, address(this), totalRequired);
        for (uint256 i = 0; i < _addresses.length; i++) {
            token.safeTransfer(_addresses[i], _amounts[i]);
        }
    }

    /// @dev Emergency stop contract in case of a critical security flaw discovered
    function emergencyStop() external onlyOwner {
        _pause();
    }

    /// @dev Default payable function to not allow sending Ether directly
    receive() external payable {
        revert("Cannot accept Ether directly.");
    }
}
