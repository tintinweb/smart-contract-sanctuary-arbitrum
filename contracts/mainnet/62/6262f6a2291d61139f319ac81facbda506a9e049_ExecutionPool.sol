// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IGasPool } from "./identity/ticker/operator/ITickerOperator.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SendNativeHelper } from "./SendNativeHelper.sol";

contract ExecutionPool is IGasPool, Ownable, SendNativeHelper {
    error NoPermission();

    event AccessUpdated(address indexed who, bool isEnable);
    event Paid(address indexed caller, address indexed to, uint256 amount);

    mapping(address => bool) private accesses;

    modifier onlyAccess() {
        if (!accesses[msg.sender]) revert NoPermission();

        _;
    }

    constructor(address _owner) Ownable(_owner) { }

    function payTo(address _to, uint256 _amount) external onlyAccess {
        _sendNative(_to, _amount, true);

        emit Paid(msg.sender, _to, _amount);
    }

    function setAccessTo(address _to, bool _enable) external onlyOwner {
        accesses[_to] = _enable;

        emit AccessUpdated(_to, _enable);
    }

    function hasAccess(address _who) external view returns (bool) {
        return accesses[_who];
    }

    function retrieveNative(address _to) external onlyOwner {
        _sendNative(_to, address(this).balance, true);
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

/**
 * @title IGasPool
 * @notice If you have a community // service pool to pay all fee, it must have this interface integrated
 * @dev is the feePayer is not the contract address, it will fallback to calling IGasPool::payTo()
 */
interface IGasPool {
    function payTo(address _to, uint256 _amount) external;
}

interface ITickerOperator {
    error FailedToSendETH();
    error NotHeroglyph();

    event FeePayerUpdated(address indexed feePayer);

    /**
     * @notice onValidatorTriggered() Callback function when your ticker has been selectionned
     * @param _lzEndpointSelectionned // The selectionned layer zero endpoint target for this ticker
     * @param _blockNumber  // The number of the block minted
     * @param _validatorWithdrawer // The block miner address
     * @param _maxFeeCost // The max fee possible for executing this ticker
     * @dev be sure to apply onlyRelay to this function
     * @dev TIP: Avoid using reverts; instead, use return statements, unless you need to restore your contract to its
     * initial state.
     * @dev TIP:Keep in mind that a miner may utilize your ticker more than once in their graffiti. To avoid any
     * repetition, consider utilizing blockNumber to track actions.
     */
    function onValidatorTriggered(
        uint32 _lzEndpointSelectionned,
        uint32 _blockNumber,
        address _validatorWithdrawer,
        uint128 _maxFeeCost
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/**
 * @title SendNativeHelper
 * @notice This helper facilitates the sending of native tokens and manages actions in case of reversion or tracking
 * rewards upon failure.
 */
abstract contract SendNativeHelper {
    error NotEnough();
    error FailedToSendETH();

    mapping(address wallet => uint256) internal pendingClaims;

    function _sendNative(address _to, uint256 _amount, bool _revertIfFails) internal {
        if (_amount == 0) return;

        (bool success,) = _to.call{ value: _amount }("");

        if (!success) {
            if (_revertIfFails) revert FailedToSendETH();
            pendingClaims[_to] += _amount;
        }
    }

    function claimFund() external {
        uint256 balance = pendingClaims[msg.sender];
        pendingClaims[msg.sender] = 0;

        if (balance == 0) revert NotEnough();

        _sendNative(msg.sender, balance, true);
    }

    function getPendingToClaim(address _user) external view returns (uint256) {
        return pendingClaims[_user];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}