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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
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

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (VestingTokenFactory.sol)
pragma solidity ^0.8.24;

import { Ownable } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { FactoryFeeManager } from "./abstracts/FactoryFeeManager.sol";

import { Errors } from "./libraries/Errors.sol";
import { IFeeManager } from "./interfaces/IFeeManager.sol";
import { IVestingToken } from "./interfaces/IVestingToken.sol";

/*

 _   _  _   _ __     __ _____  ____  _____ 
| | | || \ | |\ \   / /| ____|/ ___||_   _|
| | | ||  \| | \ \ / / |  _|  \___ \  | |  
| |_| || |\  |  \ V /  | |___  ___) | | |  
 \___/ |_| \_|   \_/   |_____||____/  |_|  
                                           
 */

/// @title VestingTokenFactory
/// @dev The VestingTokenFactory contract can be used to create vesting contracts for any ERC20 token.
/// @author JA (@ubinatus) v3
/// @author Klaus Hott (@Janther) v2
contract VestingTokenFactory is FactoryFeeManager {
    /// @param underlyingToken Address of the ERC20 that will be vest into `vestingToken`.
    /// @param vestingToken    Address of the newly deployed `VestingToken`.
    event VestingTokenCreated(address indexed underlyingToken, address vestingToken);

    /// @notice The address that will be used as a delegate call target for `VestingToken`s.
    address public immutable implementation;

    /// @dev It will be used as the salt for create2
    bytes32 internal _salt;

    /// @dev Maps `underlyingToken`s to an array of `VestingToken`s.
    mapping(address => address[]) internal _vestingTokensByUnderlyingToken;

    /// @dev Creates a vesting token factory contract.
    ///
    /// Requirements:
    ///
    /// - `implementationAddress` has to be a contract.
    /// - `feeCollectorAddress` can't be address 0x0.
    /// - `transferFeePercentage` must be within minTransferFee and maxTransferFee.
    ///
    /// @param implementationAddress    Address of `VestingToken` contract implementation.
    /// @param feeCollectorAddress      Address of `feeCollector`.
    /// @param creationFeeValue         Value for `creationFee` that will be charged when deploying `VestingToken`'s.
    /// @param transferFeePercentage    Value for `transferFeePercentage` that will be charged on `VestingToken`'s
    /// transfers.
    /// @param claimFeeValue            Value for `claimFee` that will be charged on `VestingToken`'s claims.
    constructor(
        address implementationAddress,
        address feeCollectorAddress,
        uint64 creationFeeValue,
        uint64 transferFeePercentage,
        uint64 claimFeeValue
    )
        Ownable(msg.sender)
    {
        if (implementationAddress == address(0)) revert Errors.AddressCanNotBeZero();

        bytes32 seed;
        assembly ("memory-safe") {
            seed := chainid()
        }
        _salt = seed;

        implementation = implementationAddress;
        setFeeCollector(feeCollectorAddress);
        scheduleGlobalCreationFee(creationFeeValue);
        scheduleGlobalTransferFee(transferFeePercentage);
        scheduleGlobalClaimFee(claimFeeValue);
        _feeData.creationFee = creationFeeValue;
        _feeData.transferFeePercentage = transferFeePercentage;
        _feeData.claimFee = claimFeeValue;
    }

    /// @notice Increments the salt one step.
    /// @dev In the rare case that create2 fails, this function can be used to skip that particular salt.
    function nextSalt() public {
        assembly {
            // Allocate memory for the _salt value to hash
            let ptr := mload(0x40)
            // Store current _salt value in memory allocated
            mstore(ptr, sload(_salt.slot))
            // Perform keccak256 hash of the _salt value stored in memory
            let hash := keccak256(ptr, 32)
            // Update _salt with the new hash value
            sstore(_salt.slot, hash)
        }
    }

    /// @notice Creates new VestingToken contracts.
    ///
    /// Requirements:
    ///
    /// - `underlyingTokenAddress` cannot be the zero address.
    /// - `timestamps` must be given in ascending order.
    /// - `percentages` must be given in ascending order and the last one must always be 1 eth, where 1 eth equals to
    /// 100%.
    ///
    /// @param name                   The token collection name.
    /// @param symbol                 The token collection symbol.
    /// @param underlyingTokenAddress The ERC20 token that will be held by this contract.
    /// @param milestonesArray        Array of all Milestones for this Contract's lifetime.
    function createVestingToken(
        string calldata name,
        string calldata symbol,
        address underlyingTokenAddress,
        IVestingToken.Milestone[] calldata milestonesArray
    )
        external
        payable
        returns (address vestingToken)
    {
        address impl = implementation;
        bytes32 salt = _salt;

        // Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
        assembly ("memory-safe") {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, impl)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, impl), 0x5af43d82803e903d91602b57fd5bf3))
            vestingToken := create2(0, 0x09, 0x37, salt)
        }

        if (vestingToken == address(0)) revert Errors.FailedToDeploy();
        nextSalt();

        _processCreationFee(underlyingTokenAddress);

        IVestingToken(vestingToken).initialize(name, symbol, underlyingTokenAddress, milestonesArray);

        _vestingTokensByUnderlyingToken[underlyingTokenAddress].push(vestingToken);
        emit VestingTokenCreated(underlyingTokenAddress, vestingToken);
    }

    /// @notice Exposes the whole array that `_vestingTokensByUnderlyingToken` maps.
    function vestingTokens(address underlyingToken) external view returns (address[] memory) {
        return _vestingTokensByUnderlyingToken[underlyingToken];
    }
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (FactoryFeeManager.sol)
pragma solidity ^0.8.24;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { Errors } from "../libraries/Errors.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";
import { IFactoryFeeManager } from "../interfaces/IFactoryFeeManager.sol";

/// @title FactoryFeeManager
/// @notice See the documentation in {IFactoryFeeManager}.
/// @author JA (@ubinatus)
abstract contract FactoryFeeManager is Ownable2Step, IFactoryFeeManager {
    /**
     *
     * CONSTANTS
     *
     */

    /// @dev Transfer fee is calculated using 18 decimals where 0.05 ether is 5%.
    uint64 internal constant MAX_TRANSFER_FEE = 0.05 ether;

    /**
     *
     * STATE
     *
     */

    /// @dev Stores fee related information for collection purposes.
    FeeData internal _feeData;

    /// @dev Stores the info necessary for an upcoming change of the global creation fee.
    UpcomingFeeData internal _upcomingCreationFee;

    /// @dev Stores the info necessary for an upcoming change of the global transfer fee.
    UpcomingFeeData internal _upcomingTransferFee;

    /// @dev Stores the info necessary for an upcoming change of the global claim fee.
    UpcomingFeeData internal _upcomingClaimFee;

    /// @dev Maps `underlyingToken`s to a custom creation fee struct.
    mapping(address => CustomFeeData) internal _creationFeeByUnderlyingToken;

    /// @dev Maps `underlyingToken`s to a custom transfer fee struct.
    mapping(address => CustomFeeData) internal _transferFeeByUnderlyingToken;

    /// @dev Maps `underlyingToken`s to a custom claim fee struct.
    mapping(address => CustomFeeData) internal _claimFeeByUnderlyingToken;

    /**
     *
     * FUNCTIONS
     *
     */

    /// @inheritdoc IFactoryFeeManager
    function setFeeCollector(address newFeeCollector) public override onlyOwner {
        if (newFeeCollector == address(0)) revert Errors.AddressCanNotBeZero();

        _feeData.feeCollector = newFeeCollector;
        emit FeeCollectorChange(newFeeCollector);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleGlobalCreationFee(uint64 newFeeValue) public override onlyOwner {
        if (_upcomingCreationFee.valueChangeAt <= block.timestamp) {
            _feeData.creationFee = _upcomingCreationFee.nextValue;
        }

        _upcomingCreationFee.nextValue = newFeeValue;
        _upcomingCreationFee.valueChangeAt = uint64(block.timestamp + 1 hours);

        emit GlobalCreationFeeChange(newFeeValue);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleGlobalTransferFee(uint64 newFeePercentage) public override onlyOwner {
        if (newFeePercentage > MAX_TRANSFER_FEE) revert Errors.FeeOutOfRange();

        _upcomingTransferFee.nextValue = newFeePercentage;
        _upcomingTransferFee.valueChangeAt = uint64(block.timestamp + 1 hours);

        emit GlobalTransferFeeChange(newFeePercentage);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleGlobalClaimFee(uint64 newFeeValue) public override onlyOwner {
        if (_upcomingClaimFee.valueChangeAt <= block.timestamp) {
            _feeData.claimFee = _upcomingClaimFee.nextValue;
        }

        _upcomingClaimFee.nextValue = newFeeValue;
        _upcomingClaimFee.valueChangeAt = uint64(block.timestamp + 1 hours);

        emit GlobalClaimFeeChange(newFeeValue);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleCustomCreationFee(address underlyingToken, uint64 newFeeValue) external override onlyOwner {
        CustomFeeData storage customFee = _creationFeeByUnderlyingToken[underlyingToken];

        if (customFee.valueChangeAt <= block.timestamp) {
            customFee.value = customFee.nextValue;
        }

        uint64 ts = uint64(block.timestamp + 1 hours);

        customFee.nextEnableState = true;
        customFee.statusChangeAt = ts;
        customFee.nextValue = newFeeValue;
        customFee.valueChangeAt = ts;

        emit CustomCreationFeeChange(underlyingToken, newFeeValue);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleCustomTransferFee(address underlyingToken, uint64 newFeePercentage) external override onlyOwner {
        if (newFeePercentage > MAX_TRANSFER_FEE) revert Errors.FeeOutOfRange();

        CustomFeeData storage customFee = _transferFeeByUnderlyingToken[underlyingToken];

        if (customFee.valueChangeAt <= block.timestamp) {
            customFee.value = customFee.nextValue;
        }

        uint64 ts = uint64(block.timestamp + 1 hours);

        customFee.nextEnableState = true;
        customFee.statusChangeAt = ts;
        customFee.nextValue = newFeePercentage;
        customFee.valueChangeAt = ts;

        emit CustomTransferFeeChange(underlyingToken, newFeePercentage);
    }

    /// @inheritdoc IFactoryFeeManager
    function scheduleCustomClaimFee(address underlyingToken, uint64 newFeeValue) external override onlyOwner {
        CustomFeeData storage customFee = _claimFeeByUnderlyingToken[underlyingToken];

        if (customFee.valueChangeAt <= block.timestamp) {
            customFee.value = customFee.nextValue;
        }

        uint64 ts = uint64(block.timestamp + 1 hours);

        customFee.nextEnableState = true;
        customFee.statusChangeAt = ts;
        customFee.nextValue = newFeeValue;
        customFee.valueChangeAt = ts;

        emit CustomClaimFeeChange(underlyingToken, newFeeValue);
    }

    /// @inheritdoc IFactoryFeeManager
    function toggleCustomCreationFee(address underlyingToken, bool enable) external override onlyOwner {
        CustomFeeData storage customFee = _creationFeeByUnderlyingToken[underlyingToken];

        if (customFee.statusChangeAt <= block.timestamp) {
            customFee.isEnabled = customFee.nextEnableState;
        }

        customFee.nextEnableState = enable;
        customFee.statusChangeAt = uint64(block.timestamp + 1 hours);

        emit CustomCreationFeeToggle(underlyingToken, enable);
    }

    /// @inheritdoc IFactoryFeeManager
    function toggleCustomTransferFee(address underlyingToken, bool enable) external override onlyOwner {
        CustomFeeData storage customFee = _transferFeeByUnderlyingToken[underlyingToken];

        if (customFee.statusChangeAt <= block.timestamp) {
            customFee.isEnabled = customFee.nextEnableState;
        }

        customFee.nextEnableState = enable;
        customFee.statusChangeAt = uint64(block.timestamp + 1 hours);

        emit CustomTransferFeeToggle(underlyingToken, enable);
    }

    /// @inheritdoc IFactoryFeeManager
    function toggleCustomClaimFee(address underlyingToken, bool enable) external override onlyOwner {
        CustomFeeData storage customFee = _claimFeeByUnderlyingToken[underlyingToken];

        if (customFee.statusChangeAt <= block.timestamp) {
            customFee.isEnabled = customFee.nextEnableState;
        }

        customFee.nextEnableState = enable;
        customFee.statusChangeAt = uint64(block.timestamp + 1 hours);

        emit CustomClaimFeeToggle(underlyingToken, enable);
    }

    /// @inheritdoc IFactoryFeeManager
    function minTransferFee() external pure override returns (uint64) {
        return 0;
    }

    /// @inheritdoc IFactoryFeeManager
    function maxTransferFee() external pure override returns (uint64) {
        return MAX_TRANSFER_FEE;
    }

    /// @inheritdoc IFactoryFeeManager
    function feeCollector() external view override returns (address) {
        return _feeData.feeCollector;
    }

    /// @inheritdoc IFactoryFeeManager
    function globalCreationFee() external view override returns (uint64) {
        return block.timestamp >= _upcomingCreationFee.valueChangeAt
            ? _upcomingCreationFee.nextValue
            : _feeData.creationFee;
    }

    /// @inheritdoc IFactoryFeeManager
    function globalTransferFee() external view override returns (uint64) {
        return block.timestamp >= _upcomingTransferFee.valueChangeAt
            ? _upcomingTransferFee.nextValue
            : _feeData.transferFeePercentage;
    }

    /// @inheritdoc IFactoryFeeManager
    function globalClaimFee() external view override returns (uint64) {
        return block.timestamp >= _upcomingClaimFee.valueChangeAt ? _upcomingClaimFee.nextValue : _feeData.claimFee;
    }

    /// @inheritdoc IFeeManager
    function creationFeeData(address underlyingToken)
        external
        view
        returns (address feeCollectorAddress, uint64 creationFeeValue)
    {
        feeCollectorAddress = _feeData.feeCollector;
        creationFeeValue =
            _getCurrentFee(_feeData.creationFee, _upcomingCreationFee, _creationFeeByUnderlyingToken[underlyingToken]);
    }

    /// @notice Returns the current transfer fee for a specific underlying token, considering any pending updates.
    /// @param underlyingToken Address of the `underlyingToken`.
    function transferFeeData(address underlyingToken)
        external
        view
        returns (address feeCollectorAddress, uint64 transferFeePercentage)
    {
        feeCollectorAddress = _feeData.feeCollector;
        transferFeePercentage = _getCurrentFee(
            _feeData.transferFeePercentage, _upcomingTransferFee, _transferFeeByUnderlyingToken[underlyingToken]
        );
    }

    /// @notice Returns the current claim fee for a specific underlying token, considering any pending updates.
    /// @param underlyingToken Address of the `underlyingToken`.
    function claimFeeData(address underlyingToken)
        external
        view
        returns (address feeCollectorAddress, uint64 claimFeeValue)
    {
        feeCollectorAddress = _feeData.feeCollector;
        claimFeeValue =
            _getCurrentFee(_feeData.claimFee, _upcomingClaimFee, _claimFeeByUnderlyingToken[underlyingToken]);
    }

    /// @notice Calculates the current fee based on global, custom, and upcoming fee data.
    /// @dev This function considers the current timestamp and determines the appropriate fee
    /// based on whether a custom or upcoming fee should be applied.
    /// @param globalValue The default global fee value used when no custom fees are applicable.
    /// @param upcomingGlobalFee A struct containing data about an upcoming fee change, including the timestamp
    /// for the change and the new value to be applied.
    /// @param customFee A struct containing data about the custom fee, including its enablement status,
    /// timestamps for changes, and its values (current and new).
    /// @return currentValue The calculated current fee value, taking into account the global value,
    /// custom fee, and upcoming fee data based on the current timestamp.
    function _getCurrentFee(
        uint64 globalValue,
        UpcomingFeeData memory upcomingGlobalFee,
        CustomFeeData memory customFee
    )
        internal
        view
        returns (uint64 currentValue)
    {
        if (block.timestamp >= customFee.statusChangeAt) {
            // If isCustomFee is true based on status, directly return the value based on the customFee conditions.
            if (customFee.nextEnableState) {
                return block.timestamp >= customFee.valueChangeAt ? customFee.nextValue : customFee.value;
            }
        } else if (customFee.isEnabled) {
            // This block handles the case where current timestamp is not past statusChangeAt, but custom is enabled.
            return block.timestamp >= customFee.valueChangeAt ? customFee.nextValue : customFee.value;
        }

        // If none of the custom fee conditions apply, return the global or upcoming fee value.
        return block.timestamp >= upcomingGlobalFee.valueChangeAt ? upcomingGlobalFee.nextValue : globalValue;
    }

    /// @notice Processes the creation fee for a transaction.
    /// @dev This function retrieves the creation fee data from the manager contract and, if the creation fee is greater
    /// than zero, sends the `msg.value` to the fee collector address. Reverts if the transferred value is less than the
    /// required creation fee or if the transfer fails.
    function _processCreationFee(address underlyingToken) internal {
        uint64 creationFeeValue =
            _getCurrentFee(_feeData.creationFee, _upcomingCreationFee, _creationFeeByUnderlyingToken[underlyingToken]);

        if (creationFeeValue != 0) {
            if (msg.value < creationFeeValue) revert Errors.InsufficientCreationFee();

            bytes4 unsuccessfulClaimFeeTransfer = Errors.UnsuccessfulCreationFeeTransfer.selector;
            address feeCollectorAddress = _feeData.feeCollector;

            assembly {
                let ptr := mload(0x40)
                let sendSuccess := call(gas(), feeCollectorAddress, callvalue(), 0x00, 0x00, 0x00, 0x00)
                if iszero(sendSuccess) {
                    mstore(ptr, unsuccessfulClaimFeeTransfer)
                    revert(ptr, 0x04)
                }
            }
        }
    }
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (interfaces/IFactoryFeeManager.sol)
pragma solidity ^0.8.24;

import { IFeeManager } from "./IFeeManager.sol";

/// @title IFactoryFeeManager
/// @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
interface IFactoryFeeManager is IFeeManager {
    /**
     *
     * EVENTS
     *
     */

    /// @param feeCollector Address of the new fee collector.
    event FeeCollectorChange(address indexed feeCollector);

    /// @param creationFeeValue Value for the new creation fee.
    event GlobalCreationFeeChange(uint64 creationFeeValue);

    /// @param transferFeePercentage Value for the new transfer fee.
    event GlobalTransferFeeChange(uint64 transferFeePercentage);

    /// @param claimFeeValue Value for the new claim fee.
    event GlobalClaimFeeChange(uint64 claimFeeValue);

    /// @param underlyingToken Address of the underlying token.
    /// @param creationFeeValue Value for the new creation fee.
    event CustomCreationFeeChange(address indexed underlyingToken, uint64 creationFeeValue);

    /// @param underlyingToken Address of the underlying token.
    /// @param enable Indicates the enabled state of the fee.
    event CustomCreationFeeToggle(address indexed underlyingToken, bool enable);

    /// @param underlyingToken Address of the underlying token.
    /// @param transferFeePercentage Value for the new transfer fee.
    event CustomTransferFeeChange(address indexed underlyingToken, uint64 transferFeePercentage);

    /// @param underlyingToken Address of the underlying token.
    /// @param enable Indicates the enabled state of the fee.
    event CustomTransferFeeToggle(address indexed underlyingToken, bool enable);

    /// @param underlyingToken Address of the underlying token.
    /// @param claimFeeValue Value for the new claim fee.
    event CustomClaimFeeChange(address indexed underlyingToken, uint64 claimFeeValue);

    /// @param underlyingToken Address of the underlying token.
    /// @param enable Indicates the enabled state of the fee.
    event CustomClaimFeeToggle(address indexed underlyingToken, bool enable);

    /**
     *
     * FUNCTIONS
     *
     */

    /// @dev Set address of fee collector.
    ///
    /// Requirements:
    ///
    /// - `msg.sender` has to be the owner of the contract.
    /// - `newFeeCollector` can't be address 0x0.
    ///
    /// @param newFeeCollector Address of `feeCollector`.
    ///
    function setFeeCollector(address newFeeCollector) external;

    /// @notice Sets a new global creation fee value, to take effect after 1 hour.
    /// @param newFeeValue Value for `creationFee` that will be charged on `VestingToken`'s deployments.
    function scheduleGlobalCreationFee(uint64 newFeeValue) external;

    /// @notice Sets a new global transfer fee percentage, to take effect after 1 hour.
    ///
    /// @dev Percentages and fees are calculated using 18 decimals where 1 ether is 100%.
    ///
    /// Requirements:
    ///
    /// - `newFeePercentage` must be within minTransferFee and maxTransferFee.
    ///
    /// @param newFeePercentage Value for `transferFeePercentage` that will be charged on `VestingToken`'s transfers.
    function scheduleGlobalTransferFee(uint64 newFeePercentage) external;

    /// @notice Sets a new global claim fee value, to take effect after 1 hour.
    /// @param newFeeValue Value for `claimFee` that will be charged on `VestingToken`'s claims.
    function scheduleGlobalClaimFee(uint64 newFeeValue) external;

    /// @notice Sets a new custom creation fee value for a specific underlying token, to be enabled and take effect
    /// after 1 hour from the time of this transaction.
    ///
    /// @dev Allows the contract owner to modify the creation fee associated with a specific underlying token.
    /// The new fee becomes effective after a delay of 1 hour, aiming to provide a buffer for users to be aware of the
    /// upcoming fee change.
    /// This function updates the fee and schedules its activation, ensuring transparency and predictability in fee
    /// adjustments.
    /// The fee is specified in wei, allowing for granular control over the fee structure. Emits a
    /// `CustomCreationFeeChange` event upon successful fee update.
    ///
    /// Requirements:
    /// - The caller must have owner privileges to execute this function.
    ///
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @param newFeeValue The new creation fee amount to be set, in wei, to replace the current fee after the specified
    /// delay.
    function scheduleCustomCreationFee(address underlyingToken, uint64 newFeeValue) external;

    /// @notice Sets a new custom transfer fee percentage for a specific underlying token, to be enabled and take effect
    /// after 1 hour from the time of this transaction.
    ///
    /// @dev This function allows the contract owner to adjust the transfer fee for an underlying token.
    /// The fee adjustment is delayed by 1 hour to provide transparency and predictability. Fees are calculated with
    /// precision to 18 decimal places, where 1 ether equals 100% fee.
    /// The function enforces fee limits; `newFeePercentage` must be within the predefined 0-`MAX_TRANSFER_FEE` bounds.
    /// If the custom fee was previously disabled or set to a different value, this operation schedules the new fee to
    /// take effect after the delay, enabling it if necessary.
    /// Emits a `CustomTransferFeeChange` event upon successful execution.
    ///
    /// Requirements:
    /// - Caller must be the contract owner.
    /// - `newFeePercentage` must be within the range limited by `MAX_TRANSFER_FEE`.
    ///
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @param newFeePercentage The new transfer fee percentage to be applied, expressed in ether terms (18 decimal
    /// places) where 1 ether represents 100%.
    function scheduleCustomTransferFee(address underlyingToken, uint64 newFeePercentage) external;

    /// @notice Sets a new custom claim fee value for a specific underlying token, to be enabled and take effect
    /// after 1 hour from the time of this transaction.
    ///
    /// @dev Allows the contract owner to modify the claim fee associated with a specific underlying token.
    /// The new fee becomes effective after a delay of 1 hour, aiming to provide a buffer for users to be aware of the
    /// upcoming fee change.
    /// This function updates the fee and schedules its activation, ensuring transparency and predictability in fee
    /// adjustments.
    /// The fee is specified in wei, allowing for granular control over the fee structure. Emits a
    /// `CustomClaimFeeChange` event upon successful fee update.
    ///
    /// Requirements:
    /// - The caller must have owner privileges to execute this function.
    ///
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @param newFeeValue The new claim fee amount to be set, in wei, to replace the current fee after the specified
    /// delay.
    function scheduleCustomClaimFee(address underlyingToken, uint64 newFeeValue) external;
    /// @notice Enables or disables the custom creation fee for a given underlying token, with the change taking effect
    /// after 1 hour.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @param enable True to enable the fee, false to disable it.
    function toggleCustomCreationFee(address underlyingToken, bool enable) external;

    /// @notice Enables or disables the custom transfer fee for a given underlying token, to take effect after 1 hour.
    ///
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @param enable True to enable the fee, false to disable it.
    function toggleCustomTransferFee(address underlyingToken, bool enable) external;

    /// @notice Enables or disables the custom claim fee for a given underlying token, with the change taking effect
    /// after 1 hour.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @param enable True to enable the fee, false to disable it.
    function toggleCustomClaimFee(address underlyingToken, bool enable) external;

    /// @dev Exposes the minimum transfer fee.
    function minTransferFee() external pure returns (uint64);

    /// @dev Exposes the maximum transfer fee.
    function maxTransferFee() external pure returns (uint64);

    /// @notice Exposes the `FeeData.feeCollector` to users.
    function feeCollector() external view returns (address);

    /// @notice Retrieves the current global creation fee to users.
    function globalCreationFee() external view returns (uint64);

    /// @notice Retrieves the current global transfer fee percentage to users.
    function globalTransferFee() external view returns (uint64);

    /// @notice Retrieves the current global claim fee to users.
    function globalClaimFee() external view returns (uint64);

    /// @notice Returns the current creation fee for a specific underlying token, considering any pending updates.
    /// @param underlyingToken Address of the `underlyingToken`.
    function creationFeeData(address underlyingToken)
        external
        view
        override
        returns (address feeCollectorAddress, uint64 creationFeeValue);

    /// @notice Returns the current transfer fee for a specific underlying token, considering any pending updates.
    /// @param underlyingToken Address of the `underlyingToken`.
    function transferFeeData(address underlyingToken)
        external
        view
        override
        returns (address feeCollectorAddress, uint64 transferFeePercentage);

    /// @notice Returns the current claim fee for a specific underlying token, considering any pending updates.
    /// @param underlyingToken Address of the `underlyingToken`.
    function claimFeeData(address underlyingToken)
        external
        view
        override
        returns (address feeCollectorAddress, uint64 claimFeeValue);
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (interfaces/IFeeManager.sol)
pragma solidity ^0.8.24;

/// @title IFeeManager
/// @dev Interface that describes the struct and accessor function for the data related to the collection of fees.
interface IFeeManager {
    /// @dev The `FeeData` struct is used to store fee configurations such as the collection address and fee amounts for
    /// various transaction types in the contract.
    struct FeeData {
        /// @notice The address designated to collect fees.
        /// @dev This address is responsible for receiving fees generated from various sources.
        address feeCollector;
        /// @notice The fixed fee amount required to be sent as value with each `createVestingToken` operation.
        /// @dev `creationFee` is denominated in the smallest unit of the token. It must be sent as the transaction
        /// value during the execution of the payable `createVestingToken` function.
        uint64 creationFee;
        /// @notice The transfer fee expressed in ether, where 0.01 ether corresponds to a 1% fee.
        /// @dev `transferFeePercentage` is not in basis points but in ether units, with each ether unit representing a
        /// percentage of the transaction value to be collected as a fee. This structure allows for flexible and easily
        /// understandable fee calculations for `transfer` and `transferFrom` operations.
        uint64 transferFeePercentage;
        /// @notice The fixed fee amount required to be sent as value with each `claim` operation.
        /// @dev `claimFee` is denominated in the smallest unit of the token. It must be sent as the transaction value
        /// during the execution of the payable `claim` function.
        uint64 claimFee;
    }

    /// @dev Stores global fee data upcoming change and timestamp for that change.
    struct UpcomingFeeData {
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
    }

    /// @dev Stores custom fee data, including its current state, upcoming changes, and the timestamps for those
    /// changes.
    struct CustomFeeData {
        /// @notice Indicates if the custom fee is currently enabled.
        bool isEnabled;
        /// @notice The current fee value in wei.
        uint64 value;
        /// @notice The new fee value in wei to be applied at `valueChangeAt`.
        uint64 nextValue;
        /// @notice Timestamp at which a new fee value becomes effective.
        uint64 valueChangeAt;
        /// @notice Indicates the future state of `isEnabled` after `statusChangeAt`.
        bool nextEnableState;
        /// @notice Timestamp at which the change to `isEnabled` becomes effective.
        uint64 statusChangeAt;
    }

    /// @notice Exposes the creation fee for new `VestingToken`s deployments.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @dev Enabled custom fees overrides the global creation fee.
    function creationFeeData(address underlyingToken)
        external
        view
        returns (address feeCollector, uint64 creationFeeValue);

    /// @notice Exposes the transfer fee for `VestingToken`s to consume.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @dev Enabled custom fees overrides the global transfer fee.
    function transferFeeData(address underlyingToken)
        external
        view
        returns (address feeCollector, uint64 transferFeePercentage);

    /// @notice Exposes the claim fee for `VestingToken`s to consume.
    /// @param underlyingToken Address of the `underlyingToken`.
    /// @dev Enabled custom fees overrides the global claim fee.
    function claimFeeData(address underlyingToken) external view returns (address feeCollector, uint64 claimFeeValue);
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (interfaces/IVestingToken.sol)
pragma solidity ^0.8.24;

/// @title IVestingToken
/// @dev Interface that describes the Milestone struct and initialize function so the `VestingTokenFactory` knows how to
/// initialize the `VestingToken`.
interface IVestingToken {
    /// @dev Ramps describes how the periods between release tokens.
    ///     - Cliff releases nothing until the end of the period.
    ///     - Linear releases tokens every second according to a linear slope.
    ///
    /// (0) Cliff             (1) Linear
    ///  |                     |
    ///  |        _____        |        _____
    ///  |       |             |       /
    ///  |       |             |      /
    ///  |_______|_____        |_____/_______
    ///      T0   T1               T0   T1
    ///
    enum Ramp {
        Cliff,
        Linear
    }

    /// @dev `timestamp` represents a moment in time when this Milestone is considered expired.
    /// @dev `ramp` defines the behaviour of the release of tokens in period between the previous Milestone and the
    /// current one.
    /// @dev `percentage` is the percentage of tokens that should be released once this Milestone has expired.
    struct Milestone {
        uint64 timestamp;
        Ramp ramp;
        uint64 percentage;
    }

    /// @notice Initializes the contract by setting up the ERC20 variables, the `underlyingToken`, and the
    /// `milestonesArray` information.
    ///
    /// @param name                   The token collection name.
    /// @param symbol                 The token collection symbol.
    /// @param underlyingTokenAddress The ERC20 token that will be held by this contract.
    /// @param milestonesArray        Array of all Milestones for this Contract's lifetime.
    function initialize(
        string memory name,
        string memory symbol,
        address underlyingTokenAddress,
        Milestone[] calldata milestonesArray
    )
        external;
}

// SPDX-License-Identifier: None
// Unvest Contracts (last updated v3.0.0) (libraries/Errors.sol)
pragma solidity ^0.8.24;

/// @title Errors Library
/// @notice Provides custom errors for VestingTokenFactory and VestingToken contracts.
library Errors {
    /*//////////////////////////////////////////////////////
                      VestingTokenFactory
    //////////////////////////////////////////////////////*/

    /// @notice Error to indicate that an address cannot be the zero address.
    error AddressCanNotBeZero();

    /// @notice Error to indicate that deployment of a contract failed.
    error FailedToDeploy();

    /// @notice Error to indicate that a fee is out of the accepted range.
    error FeeOutOfRange();

    /// @notice Error to indicate that the creation fee is insufficient.
    error InsufficientCreationFee();

    /// @notice Error to indicate an unsuccessful transfer of the creation fee.
    error UnsuccessfulCreationFeeTransfer();

    /*//////////////////////////////////////////////////////
                      VestingToken
    //////////////////////////////////////////////////////*/

    /// @notice Error to indicate that the minimum number of milestones has not been reached.
    error MinMilestonesNotReached();

    /// @notice Error to indicate that the maximum number of milestones has been exceeded.
    error MaxAllowedMilestonesHit();

    /// @notice Error to indicate that the claimable amount of an import is greater than expected.
    error ClaimableAmountOfImportIsGreaterThanExpected();

    /// @notice Error to indicate that equal percentages are only allowed before setting up linear milestones.
    error EqualPercentagesOnlyAllowedBeforeLinear();

    /// @notice Error to indicate that the sum of all individual amounts is not equal to the `totalAmount`.
    error InvalidTotalAmount();

    /// @notice Error to indicate that input arrays must have the same length.
    error InputArraysMustHaveSameLength();

    /// @notice Error to indicate that the last percentage in a milestone must be 100.
    error LastPercentageMustBe100();

    /// @notice Error to indicate that milestone percentages are not sorted in ascending order.
    error MilestonePercentagesNotSorted();

    /// @notice Error to indicate that milestone timestamps are not sorted in ascending chronological order.
    error MilestoneTimestampsNotSorted();

    /// @notice Error to indicate that there are more than two equal percentages, which is not allowed.
    error MoreThanTwoEqualPercentages();

    /// @notice Error to indicate that only the last percentage in a series can be 100.
    error OnlyLastPercentageCanBe100();

    /// @notice Error to indicate that the amount unlocked is greater than expected.
    error UnlockedIsGreaterThanExpected();

    /// @notice Error to indicate an unsuccessful fetch of token balance.
    error UnsuccessfulFetchOfTokenBalance();

    /// @notice Error to indicate that the claim fee provided does not match the expected claim fee.
    error IncorrectClaimFee();

    /// @notice Error to indicate an unsuccessful transfer of the claim fee.
    error UnsuccessfulClaimFeeTransfer();

    /// @notice Error to indicate that there is no balance available to claim.
    error NoClaimableAmount();
}