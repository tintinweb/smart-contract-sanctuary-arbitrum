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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IStakingOperator} from "./interfaces/IStakingOperator.sol";

/// @title Staking Operator Contract
/// @notice Manages the staking operations including setting unlock windows and collateral tokens
contract StakingOperator is Ownable, IStakingOperator {
    /// @notice Represents the unlock window
    UnlockWindow public unlockWindow;

    /// @notice Flag to indicate if the unlock window is active
    bool public isUnlockWindowActive;

    /// @notice Maps original tokens to their wrapped counterparts
    mapping(address original => address wrapped) public collateralTokens;

    /// @notice Maps wrapped tokens to their original counterparts
    mapping(address wrapped => address original) public originalTokens;

    /**
     * @notice Constructor to initialize the contract with unlock window parameters and owner
     * @param unlockWindowStart The start timestamp of the unlock window
     * @param unlockWindowDuration The duration of the unlock window
     * @param owner The address of the contract owner
     */
    constructor(
        uint256 unlockWindowStart,
        uint256 unlockWindowDuration,
        bool isUnlockWindowActive_,
        address owner
    ) Ownable(owner) {
        if (isUnlockWindowActive_) {
            _setUnlockWindow(unlockWindowStart, unlockWindowDuration);
            isUnlockWindowActive = true;
        }
    }

    /**
     * @notice Gets the original token for a collateral token
     * @param wrapped The address of the wrapped token
     * @return The address of the original token
     */
    function getOriginalToken(address wrapped) external view returns (address) {
        return originalTokens[wrapped];
    }

    /**
     * @notice Gets the collateral token for an original token
     * @param original The address of the original token
     * @return The address of the collateral (wrapped) token
     */
    function getCollateralToken(
        address original
    ) external view returns (address) {
        return collateralTokens[original];
    }

    /**
     * @notice Checks if unlock is allowed at the current timestamp
     * @param currentTimestamp The current timestamp to check
     * @return True if unlock is allowed, false otherwise
     */
    function isUnlockAllowed(
        uint256 currentTimestamp
    ) external view returns (bool) {
        if (!isUnlockWindowActive) {
            return true;
        }

        return
            currentTimestamp >= unlockWindow.start &&
            currentTimestamp <= unlockWindow.start + unlockWindow.duration;
    }

    /**
     * @notice Sets the unlock allowed flag
     * @param isUnlockWindowActive_ Flag to indicate if the unlock window is active
     * @dev Can only be called by the contract owner
     */
    function setIsUnlockWindowActive(
        bool isUnlockWindowActive_
    ) external onlyOwner {
        isUnlockWindowActive = isUnlockWindowActive_;
    }

    /**
     * @notice Sets the unlock window parameters and checks
     * @param unlockWindowStart The start timestamp of the unlock window
     * @param unlockWindowDuration The duration of the unlock window
     * @dev Can only be called by the contract owner
     */
    function setUnlockWindow(
        uint256 unlockWindowStart,
        uint256 unlockWindowDuration
    ) external onlyOwner {
        _setUnlockWindow(unlockWindowStart, unlockWindowDuration);
    }

    /**
     * @notice Sets the collateral token for an original token
     * @param original The address of the original token
     * @param wrapped The address of the collateral (wrapped) token
     * @param force Flag to force set the collateral token
     * @dev Can only be called by the contract owner
     * @dev Reverts if original and wrapped tokens are the same or if either address is zero
     * @dev Reverts if the original token is already set
     */
    function setCollateralToken(
        address original,
        address wrapped,
        bool force
    ) external onlyOwner {
        if (collateralTokens[original] != address(0) && !force) {
            revert CollateralTokenAlreadySet();
        }

        if (
            (original == wrapped) ||
            (original == address(0)) ||
            (wrapped == address(0))
        ) {
            revert InvalidCollateralToken();
        }

        collateralTokens[original] = wrapped;
        originalTokens[wrapped] = original;

        emit CollateralTokenSet(original, wrapped);
    }

    /**
     * @notice Sets the unlock window parameters
     * @param unlockWindowStart The start timestamp of the unlock window
     * @param unlockWindowDuration The duration of the unlock window
     */
    function _setUnlockWindow(
        uint256 unlockWindowStart,
        uint256 unlockWindowDuration
    ) internal {
        if (unlockWindowStart == 0) {
            revert InvalidUnlockWindowStart();
        }

        if (unlockWindowDuration == 0) {
            revert InvalidUnlockWindowDuration();
        }

        unlockWindow = UnlockWindow(unlockWindowStart, unlockWindowDuration);
        emit UnlockWindowSet(unlockWindowStart, unlockWindowDuration);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/// @title Staking Operator Interface
/// @notice Interface for managing staking operations including unlock windows and collateral tokens
interface IStakingOperator {
    /// @notice Structure to define the unlock window
    /// @param start The start timestamp of the unlock window
    /// @param duration The duration of the unlock window
    struct UnlockWindow {
        uint256 start;
        uint256 duration;
    }

    /// @notice Event emitted when the unlock window is set
    /// @param start The start timestamp of the unlock window
    /// @param duration The duration of the unlock window
    event UnlockWindowSet(uint256 start, uint256 duration);

    /// @notice Event emitted when a collateral token is set
    /// @param original The address of the original token
    /// @param wrapped The address of the collateral (wrapped) token
    event CollateralTokenSet(address original, address wrapped);

    /// @notice Error thrown when an invalid collateral token is set
    error InvalidCollateralToken();
    /// @notice Error thrown when an invalid original token is already set
    error CollateralTokenAlreadySet();
    /// @notice Error thrown when an invalid unlock window duration is set
    error InvalidUnlockWindowDuration();
    /// @notice Error thrown when an invalid unlock window start is set
    error InvalidUnlockWindowStart();

    /**
     * @notice Gets the collateral token for an original token
     * @param original The address of the original token
     * @return The address of the collateral (wrapped) token
     */
    function getCollateralToken(
        address original
    ) external view returns (address);

    /**
     * @notice Gets the original token for a collateral token
     * @param wrapped The address of the wrapped token
     * @return The address of the original token
     */
    function getOriginalToken(address wrapped) external view returns (address);

    /**
     * @notice Checks if unlock is allowed at the current timestamp
     * @param currentTimestamp The current timestamp to check
     * @return True if unlock is allowed, false otherwise
     */
    function isUnlockAllowed(
        uint256 currentTimestamp
    ) external view returns (bool);

    /**
     * @notice Sets the collateral token for an original token
     * @param original The address of the original token
     * @param wrapped The address of the collateral (wrapped) token
     * @param force Flag to force set the collateral token
     * @dev Reverts if original and wrapped tokens are the same or if either address is zero
     */
    function setCollateralToken(address original, address wrapped, bool force) external;

    /**
     * @notice Sets the unlock window parameters
     * @param unlockWindowStart The start timestamp of the unlock window
     * @param unlockWindowDuration The duration of the unlock window
     */
    function setUnlockWindow(
        uint256 unlockWindowStart,
        uint256 unlockWindowDuration
    ) external;
}