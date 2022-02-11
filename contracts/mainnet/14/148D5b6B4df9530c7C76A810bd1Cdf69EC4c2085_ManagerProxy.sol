// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IController {
    function owner() external view returns (address);

    function paused() external view returns (bool);

    function getContract(bytes32 _id) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IManager {
    event SetController(address controller);

    function setController(address _controller) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import {IManager} from "./IManager.sol";
import {IController} from "./IController.sol";

// Copy of https://github.com/livepeer/protocol/blob/confluence/contracts/Manager.sol
// Tests at https://github.com/livepeer/protocol/blob/confluence/test/unit/ManagerProxy.js
contract Manager is IManager {
    // Controller that contract is registered with
    IController public controller;

    // Check if sender is controller
    modifier onlyController() {
        _onlyController();
        _;
    }

    // Check if sender is controller owner
    modifier onlyControllerOwner() {
        _onlyControllerOwner();
        _;
    }

    // Check if controller is not paused
    modifier whenSystemNotPaused() {
        _whenSystemNotPaused();
        _;
    }

    // Check if controller is paused
    modifier whenSystemPaused() {
        _whenSystemPaused();
        _;
    }

    constructor(address _controller) {
        controller = IController(_controller);
    }

    /**
     * @notice Set controller. Only callable by current controller
     * @param _controller Controller contract address
     */
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        emit SetController(_controller);
    }

    function _onlyController() private view {
        require(msg.sender == address(controller), "caller must be Controller");
    }

    function _onlyControllerOwner() private view {
        require(
            msg.sender == controller.owner(),
            "caller must be Controller owner"
        );
    }

    function _whenSystemNotPaused() private view {
        require(!controller.paused(), "system is paused");
    }

    function _whenSystemPaused() private view {
        require(controller.paused(), "system is not paused");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ManagerProxyTarget.sol";

/**
 * @title ManagerProxy
 * @notice A proxy contract that uses delegatecall to execute function calls on a target contract using its own storage context.
 The target contract is a Manager contract that is registered with the Controller.
 * @dev Both this proxy contract and its target contract MUST inherit from ManagerProxyTarget in order to guarantee
 that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 potentially break the delegate proxy upgradeability mechanism. Since this proxy contract inherits from ManagerProxyTarget which inherits
 from Manager, it implements the setController() function. The target contract will also implement setController() since it also inherits
 from ManagerProxyTarget. Thus, any transaction sent to the proxy that calls setController() will execute against the proxy instead
 of the target. As a result, developers should keep in mind that the proxy will always execute the same logic for setController() regardless
 of the setController() implementation on the target contract. Generally, developers should not add any additional functions to this proxy contract
 because any function implemented on the proxy will always be executed against the proxy and the call **will not** be forwarded to the target contract
 */
contract ManagerProxy is ManagerProxyTarget {
    /**
     * @notice ManagerProxy constructor. Invokes constructor of base Manager contract with provided Controller address.
     * Also, sets the contract ID of the target contract that function calls will be executed on.
     * @param _controller Address of Controller that this contract will be registered with
     * @param _targetContractId contract ID of the target contract
     */
    constructor(address _controller, bytes32 _targetContractId)
        Manager(_controller)
    {
        targetContractId = _targetContractId;
    }

    /**
     * @notice Fallback function that delegates calls to target contract when there is no msg.data
     */
    receive() external payable {
        _fallback();
    }

    /**
     * @notice Fallback function that delegates calls to target contract when there is msg.data
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Uses delegatecall to execute function calls on this proxy contract's target contract using its own storage context.
     This fallback function will look up the address of the target contract using the Controller and the target contract ID.
     It will then use the calldata for a function call as the data payload for a delegatecall on the target contract. The return value
     of the executed function call will also be returned
     */
    function _fallback() private {
        address target = controller.getContract(targetContractId);
        require(target != address(0), "target contract must be registered");

        assembly {
            // Solidity keeps a free memory pointer at position 0x40 in memory
            let freeMemoryPtrPosition := 0x40
            // Load the free memory pointer
            let calldataMemoryOffset := mload(freeMemoryPtrPosition)
            // Update free memory pointer to after memory space we reserve for calldata
            mstore(
                freeMemoryPtrPosition,
                add(calldataMemoryOffset, calldatasize())
            )
            // Copy calldata (method signature and params of the call) to memory
            calldatacopy(calldataMemoryOffset, 0x0, calldatasize())

            // Call method on target contract using calldata which is loaded into memory
            let ret := delegatecall(
                gas(),
                target,
                calldataMemoryOffset,
                calldatasize(),
                0,
                0
            )

            // Load the free memory pointer
            let returndataMemoryOffset := mload(freeMemoryPtrPosition)
            // Update free memory pointer to after memory space we reserve for returndata
            mstore(
                freeMemoryPtrPosition,
                add(returndataMemoryOffset, returndatasize())
            )
            // Copy returndata (result of the method invoked by the delegatecall) to memory
            returndatacopy(returndataMemoryOffset, 0x0, returndatasize())

            switch ret
            case 0 {
                // Method call failed - revert
                // Return any error message stored in mem[returndataMemoryOffset..(returndataMemoryOffset + returndatasize)]
                revert(returndataMemoryOffset, returndatasize())
            }
            default {
                // Return result of method call stored in mem[returndataMemoryOffset..(returndataMemoryOffset + returndatasize)]
                return(returndataMemoryOffset, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./Manager.sol";

/**
 * @title ManagerProxyTarget
 * @notice The base contract that target contracts used by a proxy contract should inherit from
 * @dev Both the target contract and the proxy contract (implemented as ManagerProxy) MUST inherit from ManagerProxyTarget in order to guarantee
 that both contracts have the same storage layout. Differing storage layouts in a proxy contract and target contract can
 potentially break the delegate proxy upgradeability mechanism
 */
abstract contract ManagerProxyTarget is Manager {
    // Used to look up target contract address in controller's registry
    bytes32 public targetContractId;
}