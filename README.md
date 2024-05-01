# OptimumAI ERC20 Token and MultiSend Contracts

This repository contains the smart contracts for the OptimumAI ERC20 token and the MultiSend feature, both written in Solidity.

## OptimumAI ERC20 Token

The OptimumAI ERC20 token is an optimized ERC20 token with added features and functionality. The contract for this token can be found in [src/OptimumAI.sol](src/OptimumAI.sol).

## MultiSend Contract

The MultiSend contract allows for multiple transactions to be sent in a single batch, reducing the cost and complexity of sending multiple transactions. The contract for this feature can be found in [src/MultiSend.sol](src/MultiSend.sol).

`MultiSend` contract:

- **multiTransfer**:

  - Allows sending multiple Ether to multiple addresses in one transaction.
  - Inputs: `_addresses` array of recipient addresses, `_amounts` array of corresponding amounts to be sent.
  - Validates input array lengths match and sufficient Ether is provided.
  - Loops through addresses and amounts, sending Ether to each address.

- **multiTransferToken**:

  - Allows sending multiple ERC20 tokens to multiple addresses in one transaction.
  - Inputs: `_token` address of the token contract, `_addresses` array of recipient addresses, `_amounts` array of corresponding token amounts to be sent.
  - Validates input array lengths match.
  - Transfers total required tokens from the sender to the contract.
  - Loops through addresses and amounts, transferring tokens to each address.

- **emergencyStop**:

  - Allows the contract owner to pause the contract in case of a critical security flaw.
  - Pausing stops all functionality except for the escape hatch.

- **Escape Hatch**:

  - Provides an emergency function to transfer any Ether or tokens held in the contract to a specified destination.
  - Can be called only by the contract owner.
  - Allows transferring Ether or ERC20 tokens out of the contract in case of emergencies.

- **Default payable function**:
  - Rejects direct Ether transfers to the contract, ensuring tokens are sent through the intended functions.

The contract also inherits functionality from other contracts like `Ownable`, `ReentrancyGuard`, and `Pausable`, providing ownership management, protection against reentrancy attacks, and pausing functionality, respectively.

## License

This project is licensed under the MIT License.
