// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../utils/TwoStepOwnable.sol";

/// @title HourglassOracle
/// @notice Provides a linear moving average between two most recent prices.

contract HourglassOracle is TwoStepOwnable {
    uint256 private constant _DECIMALS = 1e18;

    /// @notice Time factor for the moving average
    uint256 private _seconds;
    /// @notice Timestamp of the last update
    uint256 private _lastUpdateTime;
    /// @notice Previous price
    uint256 private _previousPrice;
    /// @notice Most recently updated price
    uint256 private _newestPrice;
    /// @notice Address of the updater that can update the price
    address public updater;
    address public pendingUpdater;

    /// @param _maSeconds The weight factor for the exponential moving average
    /// @param _initialPrice The initial price
    /// @param _updater The address that can update the price
    /// @param _owner The initial owner
    constructor(uint256 _maSeconds, uint256 _initialPrice, address _updater, address _owner) {
        // initialize permissioned addresses
        require(_updater != address(0));
        updater = _updater;
        _setInitialOwner(_owner);

        // initialize prices
        require(_maSeconds <= _DECIMALS);
        _seconds = _maSeconds;
        _newestPrice = _initialPrice;
        _previousPrice = _initialPrice;
        _lastUpdateTime = block.timestamp;
    }

    /// @notice Updates the exponential moving average weight factor
    /// @param _maSeconds The new weight factor, in wei
    function updateEmaSeconds(uint256 _maSeconds) external onlyOwner {
        if (_maSeconds > _DECIMALS) {
            revert InvalidDuration();
        }
        emit MovingAverageUpdated(_seconds, _maSeconds);
        _seconds = _maSeconds;
    }

    /// @notice Updates the current price
    /// @param _newPrice The new price
    function update(uint256 _newPrice) external {
        if (msg.sender != updater) {
            revert CallerIsNotUpdater();
        }

        // store the present value as the prior price to prevent price gaps
        _previousPrice = pricePerShare();
        // update the last update time to the current block timestamp
        _lastUpdateTime = block.timestamp;
        // update the current price to the newest price
        _newestPrice = _newPrice;

        emit PriceUpdated(_previousPrice, _newPrice);
    }

    /// @notice Obtains the current EMA price
    /// @return The current  price
    function pricePerShare() public view returns (uint256) {
        // calculate time elapsed since last update
        uint256 timeElapsed = block.timestamp - _lastUpdateTime;
        uint256 timeWeight;

        // determine the time weight
        if (timeElapsed >= _seconds) {
            // If more than 24 hours elapsed, set time weight to 1e18
            timeWeight = _DECIMALS;
        } else {
            // linearly approach 1e18 every 24 hours
            timeWeight = (timeElapsed * _DECIMALS) / _seconds;
        }
        return ((_newestPrice * timeWeight) / _DECIMALS) + ((_previousPrice * (_DECIMALS - timeWeight)) / _DECIMALS);
    }

    ////////// TRANSFER UPDATER //////////

    /// @notice Sets a new pending updater, the address that sets the price
    /// @param _newUpdater The new pending updater address, to cancel, set to address(0)
    function setNewUpdater(address _newUpdater) external onlyOwner {
        emit NewUpdaterProposed(_newUpdater);
        pendingUpdater = _newUpdater;
    }

    /// @notice Accepts the pending updater, setting the new updater
    function acceptUpdater() external {
        if (msg.sender != pendingUpdater) {
            revert CallerIsNotUpdater();
        }
        emit NewUpdaterSet(updater, pendingUpdater);
        updater = pendingUpdater;
        pendingUpdater = address(0);
    }

    ////////// VIEW FUNCTIONS //////////

    /// @notice Returns the current time weight factor (in seconds)
    function movingAveragePeriod() external view returns (uint256) {
        return _seconds;
    }

    /// @notice Returns the last update time
    /// @return Last time updated
    function lastUpdateTime() external view returns (uint256) {
        return _lastUpdateTime;
    }

    /// @notice Returns the most recently updated price
    function newestPrice() external view returns (uint256) {
        return _newestPrice;
    }

    function previousPrice() external view returns (uint256) {
        return _previousPrice;
    }

    error InvalidDuration();
    error CallerIsNotUpdater();

    event NewUpdaterProposed(address pendingUpdater);
    event NewUpdaterSet(address oldUpdater, address newUpdater);
    event MovingAverageUpdated(uint256 oldDuration, uint256 newDuration);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./TwoStepOwnableInterface.sol";

/**
 * @title   TwoStepOwnable
 * @author  OpenSea Protocol Team
 * @notice  TwoStepOwnable provides access control for inheriting contracts,
 *          where the ownership of the contract can be exchanged via a two step
 *          process. A potential owner is set by the current owner by calling
 *          `transferOwnership`, then accepted by the new potential owner by
 *          calling `acceptOwnership`.
 */
abstract contract TwoStepOwnable is TwoStepOwnableInterface {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Ensure that the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }

        // Continue with function execution.
        _;
    }

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external override onlyOwner {
        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress();
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any. Only the owner
     *         of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override onlyOwner {
        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;

        // Set the caller as the owner of this contract.
        _setOwner(msg.sender);
    }

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice A public view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() public view override returns (address) {
        return _owner;
    }

    /**
     * @notice Internal function that sets the inital owner of the base
     *         contract. The initial owner must not already be set.
     *         To be called in the constructor or when initializing a proxy.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure that an initial owner has been supplied.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure that the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Set the initial owner.
        _setOwner(initialOwner);
    }

    /**
     * @notice Private function that sets a new owner and emits a corresponding
     *         event.
     *
     * @param newOwner The address to assign as the new owner.
     */
    function _setOwner(address newOwner) private {
        // Emit an event indicating that the new owner has been set.
        emit OwnershipTransferred(_owner, newOwner);

        // Set the new owner.
        _owner = newOwner;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title   TwoStepOwnableInterface
 * @author  OpenSea Protocol
 * @notice  TwoStepOwnableInterface contains all external function interfaces,
 *          events and errors for the TwoStepOwnable contract.
 */

interface TwoStepOwnableInterface {
    /**
     * @dev Emit an event whenever the contract owner registers a new potential
     *      owner.
     *
     * @param newPotentialOwner The new potential owner of the contract.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever contract ownership is transferred.
     *
     * @param previousOwner The previous owner of the contract.
     * @param newOwner      The new owner of the contract.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Revert with an error when attempting to set an initial owner when
     *      one has already been set.
     */
    error OwnerAlreadySet(address currentOwner);

    /**
     * @dev Revert with an error when attempting to call a function with the
     *      onlyOwner modifier from an account other than that of the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register an initial owner
     *      and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to claim ownership of the
     *      contract with a caller that is not the current potential owner.
     */
    error CallerIsNotNewPotentialOwner();

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any. Only the owner
     *         of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}