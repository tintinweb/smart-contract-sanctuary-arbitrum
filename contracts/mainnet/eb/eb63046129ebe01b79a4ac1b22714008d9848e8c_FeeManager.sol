// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ISafeOwnable {
    error SafeOwnable__OnlyOwner();
    error SafeOwnable__OnlyPendingOwner();

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PendingOwnerSet(address indexed owner, address indexed pendingOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address newPendingOwner) external;

    function becomeOwner() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ISafeOwnable.sol";

/**
 * @title Safe Ownable
 * @author 0x0Louis
 * @notice This contract is used to manage the ownership of a contract in a two-step process.
 */
abstract contract SafeOwnable is ISafeOwnable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Modifier that checks if the caller is the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner()) revert SafeOwnable__OnlyOwner();
        _;
    }

    /**
     * @dev Modifier that checks if the caller is the pending owner.
     */
    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner()) revert SafeOwnable__OnlyPendingOwner();
        _;
    }

    /**
     * @notice Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @notice Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual override returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Sets the pending owner to a new address.
     * @param newOwner The address to transfer ownership to.
     */
    function setPendingOwner(address newOwner) public virtual override onlyOwner {
        _setPendingOwner(newOwner);
    }

    /**
     * @notice Accepts ownership of the contract.
     * @dev Can only be called by the pending owner.
     */
    function becomeOwner() public virtual override onlyPendingOwner {
        _transferOwnership(_pendingOwner);
        _setPendingOwner(address(0));
    }

    /** Private Functions */

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev Sets the pending owner to a new address.
     * @param newPendingOwner The address to transfer ownership to.
     */
    function _setPendingOwner(address newPendingOwner) internal virtual {
        _pendingOwner = newPendingOwner;
        emit PendingOwnerSet(msg.sender, newPendingOwner);
    }
}

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

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeOwnable} from "solrary/access/SafeOwnable.sol";

import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {IFeeBank, FeeBank} from "./FeeBank.sol";
import {Address} from "./libraries/Address.sol";

/**
 * @title Fee Manager
 * @author Trader Joe
 * @notice This contract allows to let the fee bank contract to delegate call to any contract without
 * any risk of overwriting the storage variables of the fee bank contract.
 */
contract FeeManager is SafeOwnable, IFeeManager {
    using Address for address;

    IFeeBank internal immutable _FEE_BANK;

    uint256 internal _verifiedRound;
    mapping(address => Component) private _components;

    /**
     * @dev Modifier to check if the caller is a verified component operator of a verified component.
     */
    modifier onlyVerifiedComponentOperator(address component) {
        Component storage _component = _components[component];

        uint256 round = _component.verifiedRound;

        if (round == 0) revert FeeManager__ComponentNotVerified();
        if (_component.operators[msg.sender] != round) revert FeeManager__OnlyComponentOperator();

        _;
    }

    /**
     * @dev Constructor that creates the fee bank.
     */
    constructor() {
        _FEE_BANK = new FeeBank();
    }

    /**
     * @notice Returns the fee bank address.
     * @return The fee bank address.
     */
    function getFeeBank() external view override returns (IFeeBank) {
        return _FEE_BANK;
    }

    /**
     * @notice Returns whether a component is verified.
     * @param component The component address.
     * @return Whether the component is verified, true if verified, false otherwise.
     */
    function isVerifiedComponent(address component) external view override returns (bool) {
        return _components[component].verifiedRound > 0;
    }

    /**
     * @notice Returns whether an operator is allowed to call a component.
     * @param component The component address.
     * @param operator The operator address.
     * @return Whether the operator is allowed to call the component, true if allowed, false otherwise.
     */
    function isComponentOperator(address component, address operator) external view override returns (bool) {
        Component storage _component = _components[component];

        uint256 round = _component.verifiedRound;
        return round > 0 && _component.operators[operator] == round;
    }

    /**
     * @notice Return the result of multiple static calls to different contracts.
     * @param targets The target contracts.
     * @param data The data to static call.
     * @return results The return data from the static calls.
     */
    function batchStaticCall(address[] calldata targets, bytes[] calldata data)
        external
        view
        override
        returns (bytes[] memory results)
    {
        if (targets.length != data.length) revert FeeManager__InvalidLength();

        results = new bytes[](targets.length);

        for (uint256 i; i < targets.length;) {
            (bool success, bytes memory result) = targets[i].staticcall(data[i]);

            unchecked {
                if (success) results[i++] = result;
            }
        }
    }

    /**
     * @notice Verifies a component.
     * @dev Only callable by the owner.
     * @param component The component address.
     */
    function verifyComponent(address component) external override onlyOwner {
        if (component == address(_FEE_BANK)) revert FeeManager__FeeBankIsNotAComponent();

        Component storage _component = _components[component];

        uint256 round = _component.verifiedRound;

        if (round > 0) revert FeeManager__ComponentAlreadyVerified();

        uint256 verifiedRound = ++_verifiedRound;
        _component.verifiedRound = verifiedRound;

        emit ComponentVerified(component, verifiedRound);
    }

    /**
     * @notice Unverifies a component.
     * @dev Only callable by the owner.
     * @param component The component address.
     */
    function unverifyComponent(address component) external override onlyOwner {
        Component storage _component = _components[component];

        if (_component.verifiedRound == 0) revert FeeManager__ComponentNotVerified();

        _component.verifiedRound = 0;

        emit ComponentUnverified(component);
    }

    /**
     * @notice Adds an operator to a component.
     * @dev Only callable by the owner.
     * @param component The component address.
     * @param operator The operator address.
     */
    function addComponentOperator(address component, address operator) external override onlyOwner {
        Component storage _component = _components[component];

        uint256 round = _component.verifiedRound;

        if (round == 0) revert FeeManager__ComponentNotVerified();
        if (_component.operators[operator] == round) revert FeeManager__ComponentOperatorAlreadyAdded();

        _component.operators[operator] = round;

        emit ComponentOperatorAdded(component, operator, round);
    }

    /**
     * @notice Removes an operator from a component.
     * @dev Only callable by the owner.
     * @param component The component address.
     * @param operator The operator address.
     */
    function removeComponentOperator(address component, address operator) external override onlyOwner {
        Component storage _component = _components[component];

        uint256 round = _component.verifiedRound;
        if (round == 0) revert FeeManager__ComponentNotVerified();
        if (_component.operators[operator] != round) revert FeeManager__ComponentOperatorNotAdded();

        _component.operators[operator] = 0;

        emit ComponentOperatorRemoved(component, operator);
    }

    /**
     * @notice Calls a component and returns the result.
     * @dev Only callable by a verified component operator.
     * @param component The component address.
     * @param data The data to call the component with.
     * @return The result of the call.
     */
    function callComponent(address component, bytes calldata data) external override returns (bytes memory) {
        return _callComponent(component, data);
    }

    /**
     * @notice Calls multiple components and returns the results.
     * @dev Only callable by a verified operator of each component.
     * @param components The component addresses.
     * @param data The data to call the components with.
     * @return The results of the calls.
     */
    function callComponents(address[] calldata components, bytes[] calldata data)
        external
        override
        returns (bytes[] memory)
    {
        if (components.length != data.length) revert FeeManager__InvalidLength();

        bytes[] memory results = new bytes[](components.length);

        for (uint256 i; i < components.length;) {
            results[i] = _callComponent(components[i], data[i]);

            unchecked {
                ++i;
            }
        }

        return results;
    }

    /**
     * @notice Calls a contract `target` with `data` and returns the result.
     * @dev Only callable by the owner.
     * @param target The target contract address.
     * @param data The data to call the contract with.
     * @return returnData The result of the call.
     */
    function directCall(address target, bytes calldata data)
        external
        override
        onlyOwner
        returns (bytes memory returnData)
    {
        if (data.length == 0) {
            target.sendValue(address(this).balance);
        } else {
            returnData = target.directCall(data);
        }
    }

    /**
     * @dev Calls a component and returns the result. This function is used to delegate call to the fee bank.
     * Only callable by a verified component operator.
     * @param component The component address.
     * @param data The data to call the component with.
     * @return The result of the call.
     */
    function _callComponent(address component, bytes calldata data)
        internal
        onlyVerifiedComponentOperator(component)
        returns (bytes memory)
    {
        return _FEE_BANK.delegateCall(component, data);
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

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ISafeOwnable} from "solrary/access/ISafeOwnable.sol";

import {IFeeBank} from "./IFeeBank.sol";

interface IFeeManager is ISafeOwnable {
    error FeeManager__ComponentNotVerified();
    error FeeManager__OnlyComponentOperator();
    error FeeManager__ComponentAlreadyVerified();
    error FeeManager__ComponentOperatorAlreadyAdded();
    error FeeManager__ComponentOperatorNotAdded();
    error FeeManager__FeeBankIsNotAComponent();
    error FeeManager__InvalidLength();

    struct Component {
        mapping(address => uint256) operators;
        uint256 verifiedRound;
    }

    event ComponentVerified(address indexed component, uint256 indexed round);

    event ComponentUnverified(address indexed component);

    event ComponentOperatorAdded(address indexed component, address indexed operator, uint256 indexed round);

    event ComponentOperatorRemoved(address indexed component, address indexed operator);

    function getFeeBank() external view returns (IFeeBank);

    function isVerifiedComponent(address component) external view returns (bool);

    function isComponentOperator(address component, address operator) external view returns (bool);

    function batchStaticCall(address[] calldata targets, bytes[] calldata data)
        external
        view
        returns (bytes[] memory results);

    function verifyComponent(address component) external;

    function unverifyComponent(address component) external;

    function addComponentOperator(address component, address operator) external;

    function removeComponentOperator(address component, address operator) external;

    function callComponent(address component, bytes calldata data) external returns (bytes memory);

    function callComponents(address[] calldata component, bytes[] calldata data) external returns (bytes[] memory);

    function directCall(address target, bytes calldata data) external returns (bytes memory);
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