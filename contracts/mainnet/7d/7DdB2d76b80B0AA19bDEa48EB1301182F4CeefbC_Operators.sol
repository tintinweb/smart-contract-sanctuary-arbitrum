// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title IContractExecutor Interface
 * @notice This interface defines the execute function used to interact with external contracts.
 */
interface IContractExecutor {
    /**
     * @notice Executes a call to an external contract.
     * @dev Execution logic is left up to the implementation.
     * @param target The address of the contract to be called
     * @param callData The calldata to be sent
     * @param nativeValue The amount of native token (e.g., Ether) to be sent along with the call
     * @return bytes The data returned from the executed call
     */
    function executeContract(
        address target,
        bytes calldata callData,
        uint256 nativeValue
    ) external payable returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';
import { IContractExecutor } from './IContractExecutor.sol';

/**
 * @title IOperators Interface
 * @notice Interface for an access control mechanism where operators have exclusive
 * permissions to execute functions.
 */
interface IOperators is IOwnable, IContractExecutor {
    error NotOperator();
    error InvalidOperator();
    error OperatorAlreadyAdded();
    error NotAnOperator();
    error ExecutionFailed();

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    /**
     * @notice Check if an account is an operator.
     * @param account Address of the account to check
     * @return bool True if the account is an operator, false otherwise
     */
    function isOperator(address account) external view returns (bool);

    /**
     * @notice Adds an operator.
     * @param operator The address to add as an operator
     */
    function addOperator(address operator) external;

    /**
     * @notice Removes an operator.
     * @param operator The address of the operator to remove
     */
    function removeOperator(address operator) external;

    /**
     * @notice Executes an external contract call.
     * @dev Execution logic is left up to the implementation.
     * @param target The contract to call
     * @param callData The data to call the target contract with
     * @param nativeValue The amount of native asset to send with the call
     * @return bytes The data returned from the contract call
     */
    function executeContract(
        address target,
        bytes calldata callData,
        uint256 nativeValue
    ) external payable returns (bytes memory);
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

import { IOperators } from '../interfaces/IOperators.sol';
import { Ownable } from './Ownable.sol';

/**
 * @title Operators
 * @notice This contract provides an access control mechanism, where an owner can register
 * operator accounts that can call arbitrary contracts on behalf of this contract.
 * @dev The owner account is initially set as the deployer address.
 */
contract Operators is Ownable, IOperators {
    mapping(address => bool) public operators;

    /**
     * @notice Sets the initial owner of the contract.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @notice Modifier that requires the `msg.sender` to be an operator.
     * @dev Reverts with a NotOperator error if the condition is not met.
     */
    modifier onlyOperator() {
        if (!operators[msg.sender]) revert NotOperator();
        _;
    }

    /**
     * @notice Returns whether an address is an operator.
     * @param account Address to check
     * @return boolean whether the address is an operator
     */
    function isOperator(address account) external view returns (bool) {
        return operators[account];
    }

    /**
     * @notice Adds an address as an operator.
     * @dev Can only be called by the current owner.
     * @param operator address to be added as operator
     */
    function addOperator(address operator) external onlyOwner {
        if (operator == address(0)) revert InvalidOperator();
        if (operators[operator]) revert OperatorAlreadyAdded();

        operators[operator] = true;

        emit OperatorAdded(operator);
    }

    /**
     * @notice Removes an address as an operator.
     * @dev Can only be called by the current owner.
     * @param operator address to be removed as operator
     */
    function removeOperator(address operator) external onlyOwner {
        if (operator == address(0)) revert InvalidOperator();
        if (!operators[operator]) revert NotAnOperator();

        operators[operator] = false;

        emit OperatorRemoved(operator);
    }

    /**
     * @notice Allows an operator to execute arbitrary functions on any smart contract.
     * @dev Can only be called by an operator.
     * @param target address of the contract to execute the function on. Existence is not checked.
     * @param callData ABI encoded function call to execute on target
     * @param nativeValue The amount of native asset to send with the call. If `nativeValue` is set to `0`, then `msg.value` is forwarded instead.
     * @return data return data from executed function call
     */
    function executeContract(
        address target,
        bytes calldata callData,
        uint256 nativeValue
    ) external payable onlyOperator returns (bytes memory) {
        if (nativeValue == 0) {
            nativeValue = msg.value;
        }

        (bool success, bytes memory data) = target.call{ value: nativeValue }(callData);
        if (!success) {
            revert ExecutionFailed();
        }

        return data;
    }

    /**
     * @notice This function enables the contract to accept native value transfers.
     */
    receive() external payable {}
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