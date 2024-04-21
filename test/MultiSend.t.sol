// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {MultiSend} from "../src/MultiSend.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract OptimumTest is Test {
    MultiSend public multiSend;
    ERC20Mock public token;

    function setUp() public {
        multiSend = new MultiSend();
        token = new ERC20Mock();
        token.mint(address(this), 10000 ether);
    }

    function testMultiTransfer() public {
        address payable[] memory addresses = new address payable[](2);
        addresses[0] = payable(address(0x1));
        addresses[1] = payable(address(0x2));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 1 ether;

        vm.prank(address(this));
        multiSend.multiTransfer{value: 2 ether}(addresses, amounts);

        assertEq(address(0x1).balance, 1 ether);
        assertEq(address(0x2).balance, 1 ether);
    }

    function testMultiTransferInsufficientFunds() public {
        address payable[] memory addresses = new address payable[](2);
        addresses[0] = payable(address(0x1));
        addresses[1] = payable(address(0x2));
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 10 ether;
        amounts[1] = 10 ether;

        vm.expectRevert("Insufficient Ether provided");
        multiSend.multiTransfer{value: 5 ether}(addresses, amounts);
    }

    function testMultiTransferToken() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(0x1);
        addresses[1] = address(0x2);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 100 ether;

        token.approve(address(multiSend), 200 ether);
        vm.startPrank(address(this));
        multiSend.multiTransferToken(address(token), addresses, amounts);
        vm.stopPrank();

        assertEq(token.balanceOf(address(0x1)), 100 ether);
        assertEq(token.balanceOf(address(0x2)), 100 ether);
    }

    function testMultiTransferTokenInsufficientAllowance() public {
        address[] memory addresses = new address[](2);
        addresses[0] = address(0x1);
        addresses[1] = address(0x2);
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 100 ether;

        token.approve(address(multiSend), 50 ether); // Insufficient approval
        vm.expectRevert();
        multiSend.multiTransferToken(address(token), addresses, amounts);
    }

    receive() external payable {}
}
