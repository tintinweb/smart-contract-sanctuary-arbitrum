// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IContractIdentifier {
    /**
     * @notice Returns the contract ID. It can be used as a check during upgrades.
     * @dev Meant to be overridden in derived contracts.
     * @return bytes32 The contract ID
     */
    function contractId() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IContractIdentifier } from './IContractIdentifier.sol';

interface IImplementation is IContractIdentifier {
    error NotProxy();

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IOwnable Interface
 * @notice IOwnable is an interface that abstracts the implementation of a
 * contract with ownership control features. It's commonly used in upgradable
 * contracts and includes the functionality to get current owner, transfer
 * ownership, and propose and accept ownership.
 */
interface IOwnable {
    error NotOwner();
    error InvalidOwner();
    error InvalidOwnerAddress();

    event OwnershipTransferStarted(address indexed newOwner);
    event OwnershipTransferred(address indexed newOwner);

    /**
     * @notice Returns the current owner of the contract.
     * @return address The address of the current owner
     */
    function owner() external view returns (address);

    /**
     * @notice Returns the address of the pending owner of the contract.
     * @return address The address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Transfers ownership of the contract to a new address
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Proposes to transfer the contract's ownership to a new address.
     * The new owner needs to accept the ownership explicitly.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external;

    /**
     * @notice Transfers ownership to the pending owner.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';
import { IImplementation } from './IImplementation.sol';

// General interface for upgradable contracts
interface IUpgradable is IOwnable, IImplementation {
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();

    event Upgraded(address indexed newImplementation);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error NativeTransferFailed();

/*
 * @title SafeNativeTransfer
 * @dev This library is used for performing safe native value transfers in Solidity by utilizing inline assembly.
 */
library SafeNativeTransfer {
    /*
     * @notice Perform a native transfer to a given address.
     * @param receiver The recipient address to which the amount will be sent.
     * @param amount The amount of native value to send.
     * @throws NativeTransferFailed error if transfer is not successful.
     */
    function safeNativeTransfer(address receiver, uint256 amount) internal {
        bool success;

        assembly {
            success := call(gas(), receiver, amount, 0, 0, 0, 0)
        }

        if (!success) revert NativeTransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '../interfaces/IERC20.sol';

error TokenTransferFailed();

/*
 * @title SafeTokenCall
 * @dev This library is used for performing safe token transfers.
 */
library SafeTokenCall {
    /*
     * @notice Make a safe call to a token contract.
     * @param token The token contract to interact with.
     * @param callData The function call data.
     * @throws TokenTransferFailed error if transfer of token is not successful.
     */
    function safeCall(IERC20 token, bytes memory callData) internal {
        (bool success, bytes memory returnData) = address(token).call(callData);
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || address(token).code.length == 0) revert TokenTransferFailed();
    }
}

/*
 * @title SafeTokenTransfer
 * @dev This library safely transfers tokens from the contract to a recipient.
 */
library SafeTokenTransfer {
    /*
     * @notice Transfer tokens to a recipient.
     * @param token The token contract.
     * @param receiver The recipient of the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function safeTransfer(
        IERC20 token,
        address receiver,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount));
    }
}

/*
 * @title SafeTokenTransferFrom
 * @dev This library helps to safely transfer tokens on behalf of a token holder.
 */
library SafeTokenTransferFrom {
    /*
     * @notice Transfer tokens on behalf of a token holder.
     * @param token The token contract.
     * @param from The address of the token holder.
     * @param to The address the tokens are to be sent to.
     * @param amount The amount of tokens to be transferred.
     */
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        SafeTokenCall.safeCall(token, abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '../interfaces/IImplementation.sol';

/**
 * @title Implementation
 * @notice This contract serves as a base for other contracts and enforces a proxy-first access restriction.
 * @dev Derived contracts must implement the setup function.
 */
abstract contract Implementation is IImplementation {
    address private immutable implementationAddress;

    /**
     * @dev Contract constructor that sets the implementation address to the address of this contract.
     */
    constructor() {
        implementationAddress = address(this);
    }

    /**
     * @dev Modifier to require the caller to be the proxy contract.
     * Reverts if the caller is the current contract (i.e., the implementation contract itself).
     */
    modifier onlyProxy() {
        if (implementationAddress == address(this)) revert NotProxy();
        _;
    }

    /**
     * @notice Initializes contract parameters.
     * This function is intended to be overridden by derived contracts.
     * The overriding function must have the onlyProxy modifier.
     * @param params The parameters to be used for initialization
     */
    function setup(bytes calldata params) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IImplementation } from '../interfaces/IImplementation.sol';
import { IUpgradable } from '../interfaces/IUpgradable.sol';
import { Ownable } from '../utils/Ownable.sol';
import { Implementation } from './Implementation.sol';

/**
 * @title Upgradable Contract
 * @notice This contract provides an interface for upgradable smart contracts and includes the functionality to perform upgrades.
 */
abstract contract Upgradable is Ownable, Implementation, IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @notice Constructor sets the implementation address to the address of the contract itself
     * @dev This is used in the onlyProxy modifier to prevent certain functions from being called directly
     * on the implementation contract itself.
     * @dev The owner is initially set as address(1) because the actual owner is set within the proxy. It is not
     * set as the zero address because Ownable is designed to throw an error for ownership transfers to the zero address.
     */
    constructor() Ownable(address(1)) {}

    /**
     * @notice Returns the address of the current implementation
     * @return implementation_ Address of the current implementation
     */
    function implementation() public view returns (address implementation_) {
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    /**
     * @notice Upgrades the contract to a new implementation
     * @param newImplementation The address of the new implementation contract
     * @param newImplementationCodeHash The codehash of the new implementation contract
     * @param params Optional setup parameters for the new implementation contract
     * @dev This function is only callable by the owner.
     */
    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external override onlyOwner {
        if (IUpgradable(newImplementation).contractId() != IUpgradable(implementation()).contractId())
            revert InvalidImplementation();

        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        emit Upgraded(newImplementation);

        if (params.length > 0) {
            // slither-disable-next-line controlled-delegatecall
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    /**
     * @notice Sets up the contract with initial data
     * @param data Initialization data for the contract
     * @dev This function is only callable by the proxy contract.
     */
    function setup(bytes calldata data) external override(IImplementation, Implementation) onlyProxy {
        _setup(data);
    }

    /**
     * @notice Internal function to set up the contract with initial data
     * @param data Initialization data for the contract
     * @dev This function should be implemented in derived contracts.
     */
    function _setup(bytes calldata data) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from '../interfaces/IOwnable.sol';

/**
 * @title Ownable
 * @notice A contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The owner account is set through ownership transfer. This module makes
 * it possible to transfer the ownership of the contract to a new account in one
 * step, as well as to an interim pending owner. In the second flow the ownership does not
 * change until the pending owner accepts the ownership transfer.
 */
abstract contract Ownable is IOwnable {
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;
    // keccak256('ownership-transfer')
    bytes32 internal constant _OWNERSHIP_TRANSFER_SLOT =
        0x9855384122b55936fbfb8ca5120e63c6537a1ac40caf6ae33502b3c5da8c87d1;

    /**
     * @notice Initializes the contract by transferring ownership to the owner parameter.
     * @param _owner Address to set as the initial owner of the contract
     */
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /**
     * @notice Modifier that throws an error if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner();

        _;
    }

    /**
     * @notice Returns the current owner of the contract.
     * @return owner_ The current owner of the contract
     */
    function owner() public view returns (address owner_) {
        assembly {
            owner_ := sload(_OWNER_SLOT)
        }
    }

    /**
     * @notice Returns the pending owner of the contract.
     * @return owner_ The pending owner of the contract
     */
    function pendingOwner() public view returns (address owner_) {
        assembly {
            owner_ := sload(_OWNERSHIP_TRANSFER_SLOT)
        }
    }

    /**
     * @notice Transfers ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner.
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Propose to transfer ownership of the contract to a new account `newOwner`.
     * @dev Can only be called by the current owner. The ownership does not change
     * until the new owner accepts the ownership transfer.
     * @param newOwner The address to transfer ownership to
     */
    function proposeOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert InvalidOwnerAddress();

        emit OwnershipTransferStarted(newOwner);

        assembly {
            sstore(_OWNERSHIP_TRANSFER_SLOT, newOwner)
        }
    }

    /**
     * @notice Accepts ownership of the contract.
     * @dev Can only be called by the pending owner
     */
    function acceptOwnership() external virtual {
        address newOwner = pendingOwner();
        if (newOwner != msg.sender) revert InvalidOwner();

        _transferOwnership(newOwner);
    }

    /**
     * @notice Internal function to transfer ownership of the contract to a new account `newOwner`.
     * @dev Called in the constructor to set the initial owner.
     * @param newOwner The address to transfer ownership to
     */
    function _transferOwnership(address newOwner) internal virtual {
        if (newOwner == address(0)) revert InvalidOwnerAddress();

        emit OwnershipTransferred(newOwner);

        assembly {
            sstore(_OWNER_SLOT, newOwner)
            sstore(_OWNERSHIP_TRANSFER_SLOT, 0)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC20 } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IERC20.sol';
import { SafeTokenTransfer, SafeTokenTransferFrom } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeTransfer.sol';
import { SafeNativeTransfer } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/SafeNativeTransfer.sol';
import { IAxelarGasService } from '../interfaces/IAxelarGasService.sol';
import { Upgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradable/Upgradable.sol';

/**
 * @title AxelarGasService
 * @notice This contract manages gas payments and refunds for cross-chain communication on the Axelar network.
 * @dev The owner address of this contract should be the microservice that pays for gas.
 * @dev Users pay gas for cross-chain calls, and the gasCollector can collect accumulated fees and/or refund users if needed.
 */
contract AxelarGasService is Upgradable, IAxelarGasService {
    using SafeTokenTransfer for IERC20;
    using SafeTokenTransferFrom for IERC20;
    using SafeNativeTransfer for address payable;

    address public immutable gasCollector;

    /**
     * @notice Constructs the AxelarGasService contract.
     * @param gasCollector_ The address of the gas collector
     */
    constructor(address gasCollector_) {
        gasCollector = gasCollector_;
    }

    /**
     * @notice Modifier that ensures the caller is the designated gas collector.
     */
    modifier onlyCollector() {
        if (msg.sender != gasCollector) revert NotCollector();

        _;
    }

    /**
     * @notice Pay for gas using ERC20 tokens for a contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external override {
        emit GasPaidForContractCall(
            sender,
            destinationChain,
            destinationAddress,
            keccak256(payload),
            gasToken,
            gasFeeAmount,
            refundAddress
        );

        IERC20(gasToken).safeTransferFrom(msg.sender, address(this), gasFeeAmount);
    }

    /**
     * @notice Pay for gas using ERC20 tokens for a contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string memory symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external override {
        emit GasPaidForContractCallWithToken(
            sender,
            destinationChain,
            destinationAddress,
            keccak256(payload),
            symbol,
            amount,
            gasToken,
            gasFeeAmount,
            refundAddress
        );

        IERC20(gasToken).safeTransferFrom(msg.sender, address(this), gasFeeAmount);
    }

    /**
     * @notice Pay for gas using native currency for a contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable override {
        emit NativeGasPaidForContractCall(sender, destinationChain, destinationAddress, keccak256(payload), msg.value, refundAddress);
    }

    /**
     * @notice Pay for gas using native currency for a contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable override {
        emit NativeGasPaidForContractCallWithToken(
            sender,
            destinationChain,
            destinationAddress,
            keccak256(payload),
            symbol,
            amount,
            msg.value,
            refundAddress
        );
    }

    /**
     * @notice Pay for gas using ERC20 tokens for an express contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to express execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForExpressCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external override {
        emit GasPaidForExpressCall(sender, destinationChain, destinationAddress, keccak256(payload), gasToken, gasFeeAmount, refundAddress);

        IERC20(gasToken).safeTransferFrom(msg.sender, address(this), gasFeeAmount);
    }

    /**
     * @notice Pay for gas using ERC20 tokens for an express contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to express execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string memory symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external override {
        emit GasPaidForExpressCallWithToken(
            sender,
            destinationChain,
            destinationAddress,
            keccak256(payload),
            symbol,
            amount,
            gasToken,
            gasFeeAmount,
            refundAddress
        );

        IERC20(gasToken).safeTransferFrom(msg.sender, address(this), gasFeeAmount);
    }

    /**
     * @notice Pay for gas using native currency for an express contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForExpressCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable override {
        emit NativeGasPaidForExpressCall(sender, destinationChain, destinationAddress, keccak256(payload), msg.value, refundAddress);
    }

    /**
     * @notice Pay for gas using native currency for an express contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable override {
        emit NativeGasPaidForExpressCallWithToken(
            sender,
            destinationChain,
            destinationAddress,
            keccak256(payload),
            symbol,
            amount,
            msg.value,
            refundAddress
        );
    }

    /**
     * @notice Add additional gas payment using ERC20 tokens after initiating a cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param gasToken The ERC20 token address used to add gas
     * @param gasFeeAmount The amount of tokens to add as gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addGas(
        bytes32 txHash,
        uint256 logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external override {
        emit GasAdded(txHash, logIndex, gasToken, gasFeeAmount, refundAddress);

        IERC20(gasToken).safeTransferFrom(msg.sender, address(this), gasFeeAmount);
    }

    /**
     * @notice Add additional gas payment using native currency after initiating a cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable override {
        emit NativeGasAdded(txHash, logIndex, msg.value, refundAddress);
    }

    /**
     * @notice Add additional gas payment using ERC20 tokens after initiating an express cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to express execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param gasToken The ERC20 token address used to add gas
     * @param gasFeeAmount The amount of tokens to add as gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external override {
        emit ExpressGasAdded(txHash, logIndex, gasToken, gasFeeAmount, refundAddress);

        IERC20(gasToken).safeTransferFrom(msg.sender, address(this), gasFeeAmount);
    }

    /**
     * @notice Add additional gas payment using native currency after initiating an express cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to express execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable override {
        emit NativeExpressGasAdded(txHash, logIndex, msg.value, refundAddress);
    }

    /**
     * @notice Allows the gasCollector to collect accumulated fees from the contract.
     * @dev Use address(0) as the token address for native currency.
     * @param receiver The address to receive the collected fees
     * @param tokens Array of token addresses to be collected
     * @param amounts Array of amounts to be collected for each respective token address
     */
    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external onlyCollector {
        if (receiver == address(0)) revert InvalidAddress();

        uint256 tokensLength = tokens.length;
        if (tokensLength != amounts.length) revert InvalidAmounts();

        for (uint256 i; i < tokensLength; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            if (amount == 0) revert InvalidAmounts();

            if (token == address(0)) {
                if (amount <= address(this).balance) receiver.safeNativeTransfer(amount);
            } else {
                // slither-disable-next-line calls-loop
                if (amount <= IERC20(token).balanceOf(address(this))) IERC20(token).safeTransfer(receiver, amount);
            }
        }
    }

    /**
     * @dev Deprecated refund function, kept for backward compatibility.
     */
    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external onlyCollector {
        _refund(bytes32(0), 0, receiver, token, amount);
    }

    /**
     * @notice Refunds gas payment to the receiver in relation to a specific cross-chain transaction.
     * @dev Only callable by the gasCollector.
     * @dev Use address(0) as the token address to refund native currency.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param receiver The address to receive the refund
     * @param token The token address to be refunded
     * @param amount The amount to refund
     */
    function refund(
        bytes32 txHash,
        uint256 logIndex,
        address payable receiver,
        address token,
        uint256 amount
    ) external onlyCollector {
        _refund(txHash, logIndex, receiver, token, amount);
    }

    /**
     * @dev Internal function to implement gas refund logic.
     */
    function _refund(
        bytes32 txHash,
        uint256 logIndex,
        address payable receiver,
        address token,
        uint256 amount
    ) private {
        if (receiver == address(0)) revert InvalidAddress();

        emit Refunded(txHash, logIndex, receiver, token, amount);

        if (token == address(0)) {
            receiver.safeNativeTransfer(amount);
        } else {
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

    /**
     * @notice Returns a unique identifier for the contract.
     * @return bytes32 Hash of the contract identifier
     */
    function contractId() external pure returns (bytes32) {
        return keccak256('axelar-gas-service');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol';

/**
 * @title IAxelarGasService Interface
 * @notice This is an interface for the AxelarGasService contract which manages gas payments
 * and refunds for cross-chain communication on the Axelar network.
 * @dev This interface inherits IUpgradable
 */
interface IAxelarGasService is IUpgradable {
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForExpressCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event ExpressGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeExpressGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    event Refunded(bytes32 indexed txHash, uint256 indexed logIndex, address payable receiver, address token, uint256 amount);

    /**
     * @notice Pay for gas using ERC20 tokens for a contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using ERC20 tokens for a contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using native currency for a contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    /**
     * @notice Pay for gas using native currency for a contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    /**
     * @notice Pay for gas using ERC20 tokens for an express contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to express execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForExpressCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using ERC20 tokens for an express contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to express execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param gasToken The address of the ERC20 token used to pay for gas
     * @param gasFeeAmount The amount of tokens to pay for gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Pay for gas using native currency for an express contract call on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForExpressCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    /**
     * @notice Pay for gas using native currency for an express contract call with tokens on a destination chain.
     * @dev This function is called on the source chain before calling the gateway to execute a remote contract.
     * @param sender The address making the payment
     * @param destinationChain The target chain where the contract call with tokens will be made
     * @param destinationAddress The target address on the destination chain
     * @param payload Data payload for the contract call with tokens
     * @param symbol The symbol of the token to be sent with the call
     * @param amount The amount of tokens to be sent with the call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function payNativeGasForExpressCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    /**
     * @notice Add additional gas payment using ERC20 tokens after initiating a cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param gasToken The ERC20 token address used to add gas
     * @param gasFeeAmount The amount of tokens to add as gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addGas(
        bytes32 txHash,
        uint256 logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Add additional gas payment using native currency after initiating a cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    /**
     * @notice Add additional gas payment using ERC20 tokens after initiating an express cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to express execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param gasToken The ERC20 token address used to add gas
     * @param gasFeeAmount The amount of tokens to add as gas
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    /**
     * @notice Add additional gas payment using native currency after initiating an express cross-chain call.
     * @dev This function can be called on the source chain after calling the gateway to express execute a remote contract.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param refundAddress The address where refunds, if any, should be sent
     */
    function addNativeExpressGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    /**
     * @notice Allows the gasCollector to collect accumulated fees from the contract.
     * @dev Use address(0) as the token address for native currency.
     * @param receiver The address to receive the collected fees
     * @param tokens Array of token addresses to be collected
     * @param amounts Array of amounts to be collected for each respective token address
     */
    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Refunds gas payment to the receiver in relation to a specific cross-chain transaction.
     * @dev Only callable by the gasCollector.
     * @dev Use address(0) as the token address to refund native currency.
     * @param txHash The transaction hash of the cross-chain call
     * @param logIndex The log index for the cross-chain call
     * @param receiver The address to receive the refund
     * @param token The token address to be refunded
     * @param amount The amount to refund
     */
    function refund(
        bytes32 txHash,
        uint256 logIndex,
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    /**
     * @notice Returns the address of the designated gas collector.
     * @return address of the gas collector
     */
    function gasCollector() external returns (address);
}