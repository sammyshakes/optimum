// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// Imports
import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract DeployMultisig is Script {
    // Deployments
    MultiSigWallet public wallet;

    address public owner1 = vm.envAddress("MULTISIG_OWNER_1_ADDRESS");
    address public owner2 = vm.envAddress("MULTISIG_OWNER_2_ADDRESS");

    address public requiredConfirmationAddress =
        vm.envAddress("MULTISIG_REQUIRED_CONFIRMATION_ADDRESS");

    uint256 numComfirmations = vm.envUint("MULTISIG_REQUIRED_CONFIRMATIONS");

    function run() external {
        uint256 deployerPrivateKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));

        // NOTE: requiredConfirmationAddress must also be in owners array
        address[] memory owners = new address[](8);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = requiredConfirmationAddress;

        vm.startBroadcast(deployerPrivateKey);

        wallet = new MultiSigWallet(owners, requiredConfirmationAddress, numComfirmations);

        vm.stopBroadcast();
    }
}
