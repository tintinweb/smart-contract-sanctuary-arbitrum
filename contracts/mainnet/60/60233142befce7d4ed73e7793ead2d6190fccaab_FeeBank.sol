// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {Address} from "./libraries/Address.sol";
import {IFeeBank} from "./interfaces/IFeeBank.sol";

/**
 * @title Fee Bank
 * @author Trader Joe
 * @notice This contracts holds fees from the different products of the protocol.
 * The fee manager can call any contract from this contract to execute different actions.
 */
contract FeeBank is IFeeBank {
    using Address for address;

    address internal immutable _FEE_MANAGER;

    /**
     * @notice Modifier to check if the caller is the fee manager.
     */
    modifier onlyFeeManager() {
        if (msg.sender != _FEE_MANAGER) revert FeeBank__OnlyFeeManager();
        _;
    }

    /**
     * @dev Constructor that sets the fee manager address.
     * Needs to be deployed by the fee manager itself.
     */
    constructor() {
        _FEE_MANAGER = msg.sender;
    }

    /**
     * @notice Returns the fee manager address.
     * @return The fee manager address.
     */
    function getFeeManager() external view override returns (address) {
        return _FEE_MANAGER;
    }

    /**
     * @notice Delegate calls to a contract.
     * @dev Only callable by the fee manager.
     * @param target The target contract.
     * @param data The data to delegate call.
     * @return The return data from the delegate call.
     */
    function delegateCall(address target, bytes calldata data) external onlyFeeManager returns (bytes memory) {
        return target.delegateCall(data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IFeeBank {
    error FeeBank__NonContract();
    error FeeBank__CallFailed();
    error FeeBank__OnlyFeeManager();

    function getFeeManager() external view returns (address);

    function delegateCall(address target, bytes calldata data) external returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library Address {
    error Address__SendFailed();
    error Address__NonContract();
    error Address__CallFailed();

    /**
     * @dev Sends the given amount of ether to the given address, forwarding all available gas and reverting on errors.
     * @param target The address to send ether to.
     * @param value The amount of ether to send.
     */
    function sendValue(address target, uint256 value) internal {
        (bool success,) = target.call{value: value}("");
        if (!success) revert Address__SendFailed();
    }

    /**
     * @dev Calls the target contract with the given data and bubbles up errors.
     * @param target The target contract.
     * @param data The data to call the target contract with.
     * @return The return data from the call.
     */
    function directCall(address target, bytes memory data) internal returns (bytes memory) {
        return directCallWithValue(target, data, 0);
    }

    /**
     * @dev Calls the target contract with the given data and bubbles up errors.
     * @param target The target contract.
     * @param data The data to call the target contract with.
     * @param value The amount of ether to send to the target contract.
     * @return The return data from the call.
     */
    function directCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{value: value}(data);

        _catchError(target, success, returnData);

        return returnData;
    }

    /**
     * @dev Delegate calls the target contract with the given data and bubbles up errors.
     * @param target The target contract.
     * @param data The data to delegate call the target contract with.
     * @return The return data from the delegate call.
     */
    function delegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = target.delegatecall(data);

        _catchError(target, success, returnData);

        return returnData;
    }

    /**
     * @dev Bubbles up errors from the target contract, target must be a contract.
     * @param target The target contract.
     * @param success The success flag from the call.
     * @param returnData The return data from the call.
     */
    function _catchError(address target, bool success, bytes memory returnData) private view {
        if (success) {
            if (returnData.length == 0 && target.code.length == 0) {
                revert Address__NonContract();
            }
        } else {
            if (returnData.length > 0) {
                assembly {
                    revert(add(32, returnData), mload(returnData))
                }
            } else {
                revert Address__CallFailed();
            }
        }
    }
}