# OptimumAI Smart Contracts

This repository contains the smart contracts for OptimumAI written in Solidity.

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

## OptimumAISeedSaleVesting Contract

The `OptimumAISeedSaleVesting` contract manages the vesting of tokens for investors participating in a seed sale. The contract allows for the distribution of ERC20 tokens according to a vesting schedule, enabling investors to claim their vested tokens over time. The contract owner can initialize vesting schedules, and investors can claim their vested tokens based on the time elapsed since the start of their vesting period. The contract also includes an emergency withdrawal function to recover tokens in case of emergencies. The contract for this feature can be found in [src/OptimumAISeedSaleVesting.sol](src/OptimumAISeedSaleVesting.sol).

`OptimumAISeedSaleVesting` contract:

- **Token Vesting Management**: Manages the vesting of tokens for investors participating in a seed sale.
- **Key Features**:
  - **Token Distribution**: Handles the distribution of ERC20 tokens according to a vesting schedule.
  - **Investor Struct**: Utilizes a struct to store each investor's total allocated tokens, released tokens, and the start time of their vesting period.
  - **Events**:
    - `VestingInitialized`: Emitted when vesting is initialized for an investor.
    - `TokensClaimed`: Emitted when an investor claims their vested tokens.
    - `EmergencyWithdrawal`: Emitted during the emergency withdrawal of tokens by the contract owner.
- **Functionalities**:
  - **Initialize Vesting**: Sets up vesting for a specific investor, defining the total token amount and the start time of vesting. Only callable by the contract owner.
  - **Claim Tokens**: Allows investors to claim their vested tokens as per the schedule.
  - **Calculate Claimable Amount**: Provides the amount of tokens an investor can currently claim, based on the time elapsed since the start of their vesting.
  - **Calculate Released Amount**: Retrieves the total amount of tokens that have been released to an investor up to the current point.
  - **Emergency Withdrawal**: Enables the contract owner to withdraw all tokens from the contract in case of emergencies. This function ensures that tokens can be recovered if needed.
- **Access Control**:
  - Only the contract owner can initialize vesting schedules and perform emergency withdrawals.
- **Vesting Schedule**:
  - **Initial Release**: 50% of the allocated tokens are available immediately after the Token Generation Event (TGE).
  - **Vesting Duration**: The remaining 50% of tokens are vested linearly over 3 months, allowing for partial claims at any point during this period.

## OptimumAIKOLVesting Contract

`OptimumAIKOLVesting` contract manages the vesting of tokens for Key Opinion Leaders (KOLs) participating in the OptimumAI ecosystem. The contract allows the contract owner to initialize vesting schedules for KOLs, enabling them to claim their vested tokens over time. The contract owner can adjust the vesting schedules for KOLs as needed. The contract for this feature can be found in [src/OptimumAIKOLVesting.sol](src/OptimumAIKOLVesting.sol).:

- **Vesting Schedule Struct**:

  - Defines a struct `VestingSchedule` to hold details of each vesting schedule, including total allocated tokens, released tokens, cliff duration, vesting duration, immediate release percentage, and start time.

- **Initialization**:

  - Allows the contract owner to initialize vesting schedules for Key Opinion Leaders (KOLs).
  - Inputs: KOL address, total token amount, cliff duration, vesting duration, immediate release percentage, and start time.
  - Checks for valid inputs and sets up the vesting schedule.

- **Claim Tokens**:

  - Allows KOLs to claim vested tokens.
  - Validates if vesting has started and if tokens are claimable based on the current timestamp.
  - Calculates the claimable amount based on the vesting schedule.
  - Transfers the claimable tokens to the KOL.

- **Claimable Amount Calculation**:

  - Calculates the amount of tokens claimable by a KOL at a given timestamp based on their vesting schedule.
  - Considers immediate release, cliff duration, vesting duration, and elapsed time since the start of vesting.

- **Adjust Vesting Schedule**:

  - Allows the contract owner to adjust the vesting schedule for a KOL.
  - Inputs: KOL address, new cliff duration, new vesting duration, new immediate release percentage.
  - Updates the vesting schedule parameters for the specified KOL.

- **Events**:

  - Emits events for vesting initialization, tokens claimed, and vesting schedule updates.

- **Constructor**:
  - Initializes the contract with the address of the OptimumAI token.

## License

This project is licensed under the MIT License.
