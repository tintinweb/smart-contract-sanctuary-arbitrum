// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ICollateralManager} from "./interfaces/ICollateralManager.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {Helpers} from "../libraries/Helpers.sol";

interface IERC20Custom is IERC20 {
    function decimals() external view returns (uint8);
}

/// @title Collateral Manager for the USDs Protocol
/// @author Sperax Foundation
/// @notice This contract manages the addition and removal of collateral, configuration of collateral strategies, and allocation percentages.
/// @dev Collateral Manager interacts with the Vault and various strategies for collateral management.
contract CollateralManager is ICollateralManager, Ownable {
    // Struct for storing collateral data
    struct CollateralData {
        bool mintAllowed; // mint switch for collateral
        bool redeemAllowed; // redemption switch for collateral
        bool allocationAllowed; // allocation switch for collateral
        bool exists;
        address defaultStrategy; // default redemption strategy for collateral
        uint16 baseMintFee;
        uint16 baseRedeemFee;
        uint16 downsidePeg; // min price of collateral to be eligible for minting
        uint16 desiredCollateralComposition; // collateral composition in vault
        uint16 collateralCapacityUsed; // tracks current allocation capacity of a collateral
        uint256 conversionFactor; // normalization factor for bringing token amounts to same decimal levels
    }

    // Struct for storing strategy data
    struct StrategyData {
        uint16 allocationCap;
        bool exists;
    }

    uint16 public collateralCompositionUsed; // vault composition allocated to collaterals
    address public immutable VAULT; // address of USDs-vault
    address[] private collaterals; // address of all registered collaterals
    mapping(address => CollateralData) public collateralInfo; // collateral configuration
    mapping(address => mapping(address => StrategyData)) private collateralStrategyInfo; // collateral -> strategy => collateralStrategy config
    mapping(address => address[]) private collateralStrategies; // collateral => strategies[]

    // Events
    event CollateralAdded(address collateral, CollateralBaseData data);
    event CollateralRemoved(address collateral);
    event CollateralInfoUpdated(address collateral, CollateralBaseData data);
    event CollateralStrategyAdded(address collateral, address strategy);
    event CollateralStrategyUpdated(address collateral, address strategy);
    event CollateralStrategyRemoved(address collateral, address strategy);

    // Custom error messages
    error CollateralExists();
    error CollateralDoesNotExist();
    error CollateralStrategyExists();
    error CollateralStrategyMapped();
    error CollateralStrategyNotMapped();
    error CollateralNotSupportedByStrategy();
    error CollateralAllocationPaused();
    error CollateralStrategyInUse();
    error AllocationPercentageLowerThanAllocatedAmt();
    error IsDefaultStrategy();

    /// @dev Constructor to initialize the Collateral Manager
    /// @param _vault Address of the Vault contract
    constructor(address _vault) {
        Helpers._isNonZeroAddr(_vault);
        VAULT = _vault;
    }

    /// @notice Register a collateral for mint & redeem in USDs
    /// @param _collateral Address of the collateral
    /// @param _data Collateral configuration data
    function addCollateral(address _collateral, CollateralBaseData memory _data) external onlyOwner {
        // Check if collateral is already added
        // Initialize collateral storage data
        if (collateralInfo[_collateral].exists) revert CollateralExists();

        // Check that configuration values do not exceed maximum percentage
        Helpers._isLTEMaxPercentage(_data.downsidePeg);
        Helpers._isLTEMaxPercentage(_data.baseMintFee);
        Helpers._isLTEMaxPercentage(_data.baseRedeemFee);

        // Check the desired collateral composition does not exceed the maximum
        Helpers._isLTEMaxPercentage(
            _data.desiredCollateralComposition + collateralCompositionUsed, "Collateral composition exceeded"
        );

        collateralInfo[_collateral] = CollateralData({
            mintAllowed: _data.mintAllowed,
            redeemAllowed: _data.redeemAllowed,
            allocationAllowed: _data.allocationAllowed,
            defaultStrategy: address(0),
            baseMintFee: _data.baseMintFee,
            baseRedeemFee: _data.baseRedeemFee,
            downsidePeg: _data.downsidePeg,
            collateralCapacityUsed: 0,
            desiredCollateralComposition: _data.desiredCollateralComposition,
            exists: true,
            conversionFactor: 10 ** (18 - IERC20Custom(_collateral).decimals())
        });

        collaterals.push(_collateral);
        collateralCompositionUsed += _data.desiredCollateralComposition;

        emit CollateralAdded(_collateral, _data);
    }

    /// @notice Update existing collateral configuration
    /// @param _collateral Address of the collateral
    /// @param _updateData Updated configuration for the collateral
    function updateCollateralData(address _collateral, CollateralBaseData memory _updateData) external onlyOwner {
        // Check if collateral is added
        // Update the collateral storage data
        if (!collateralInfo[_collateral].exists) {
            revert CollateralDoesNotExist();
        }

        // Check that updated configuration values do not exceed maximum percentage
        Helpers._isLTEMaxPercentage(_updateData.downsidePeg);
        Helpers._isLTEMaxPercentage(_updateData.baseMintFee);
        Helpers._isLTEMaxPercentage(_updateData.baseRedeemFee);

        CollateralData storage data = collateralInfo[_collateral];

        // Calculate the new capacity used to ensure it does not exceed the maximum collateral composition
        uint16 newCapacityUsed =
            (collateralCompositionUsed - data.desiredCollateralComposition + _updateData.desiredCollateralComposition);

        Helpers._isLTEMaxPercentage(newCapacityUsed, "Collateral composition exceeded");

        // Update the collateral data
        data.mintAllowed = _updateData.mintAllowed;
        data.redeemAllowed = _updateData.redeemAllowed;
        data.allocationAllowed = _updateData.allocationAllowed;
        data.baseMintFee = _updateData.baseMintFee;
        data.baseRedeemFee = _updateData.baseRedeemFee;
        data.downsidePeg = _updateData.downsidePeg;
        data.desiredCollateralComposition = _updateData.desiredCollateralComposition;

        // Update the collateral composition used
        collateralCompositionUsed = newCapacityUsed;

        emit CollateralInfoUpdated(_collateral, _updateData);
    }

    /// @notice Un-list a collateral
    /// @param _collateral Address of the collateral
    function removeCollateral(address _collateral) external onlyOwner {
        // Check if the collateral exists
        if (!collateralInfo[_collateral].exists) {
            revert CollateralDoesNotExist();
        }
        // Check if collateral strategies are empty
        if (collateralStrategies[_collateral].length != 0) {
            revert CollateralStrategyExists();
        }

        uint256 numCollateral = collaterals.length;

        for (uint256 i; i < numCollateral;) {
            if (collaterals[i] == _collateral) {
                // Remove the collateral from the list
                collaterals[i] = collaterals[numCollateral - 1];
                collaterals.pop();
                // Update the collateral composition used
                collateralCompositionUsed -= collateralInfo[_collateral].desiredCollateralComposition;
                // Delete the collateral data
                delete (collateralInfo[_collateral]);
                break;
            }

            unchecked {
                ++i;
            }
        }

        emit CollateralRemoved(_collateral);
    }

    /// @notice Add a new strategy to collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @param _allocationCap Allocation capacity
    function addCollateralStrategy(address _collateral, address _strategy, uint16 _allocationCap) external onlyOwner {
        CollateralData storage collateralData = collateralInfo[_collateral];

        // Check if the collateral is valid
        if (!collateralData.exists) revert CollateralDoesNotExist();
        // Check if the collateral strategy is not already added.
        if (collateralStrategyInfo[_collateral][_strategy].exists) {
            revert CollateralStrategyMapped();
        }
        // Check if collateral allocation is supported by the strategy.
        if (!IStrategy(_strategy).supportsCollateral(_collateral)) {
            revert CollateralNotSupportedByStrategy();
        }

        // Check if the allocation percentage is within bounds
        Helpers._isLTEMaxPercentage(
            _allocationCap + collateralData.collateralCapacityUsed, "Allocation percentage exceeded"
        );

        // Add information to collateral mapping
        collateralStrategyInfo[_collateral][_strategy] = StrategyData(_allocationCap, true);
        collateralStrategies[_collateral].push(_strategy);
        collateralData.collateralCapacityUsed += _allocationCap;

        emit CollateralStrategyAdded(_collateral, _strategy);
    }

    /// @notice Update existing strategy for collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @param _allocationCap Allocation capacity
    function updateCollateralStrategy(address _collateral, address _strategy, uint16 _allocationCap)
        external
        onlyOwner
    {
        // Check if the collateral and strategy are mapped
        // Check if the new allocation percentage is within bounds
        // _allocationCap <= 100 - collateralCapacityUsed  + oldAllocationPer
        if (!collateralStrategyInfo[_collateral][_strategy].exists) {
            revert CollateralStrategyNotMapped();
        }

        CollateralData storage collateralData = collateralInfo[_collateral];
        StrategyData storage strategyData = collateralStrategyInfo[_collateral][_strategy];

        // Calculate the new capacity used to ensure it's within bounds
        uint16 newCapacityUsed = collateralData.collateralCapacityUsed - strategyData.allocationCap + _allocationCap;
        Helpers._isLTEMaxPercentage(newCapacityUsed, "Allocation percentage exceeded");

        // Calculate the current allocated percentage
        uint256 totalCollateral = getCollateralInVault(_collateral) + getCollateralInStrategies(_collateral);
        uint256 currentAllocatedPer =
            (getCollateralInAStrategy(_collateral, _strategy) * Helpers.MAX_PERCENTAGE) / totalCollateral;

        // Ensure the new allocation percentage is greater than or equal to the currently allocated percentage
        if (_allocationCap < currentAllocatedPer) {
            revert AllocationPercentageLowerThanAllocatedAmt();
        }

        // Update the collateral data and strategy data
        collateralData.collateralCapacityUsed = newCapacityUsed;
        strategyData.allocationCap = _allocationCap;

        emit CollateralStrategyUpdated(_collateral, _strategy);
    }

    /// @notice Remove an existing strategy from collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @dev Ensure all the collateral is removed from the strategy before calling this
    ///      Otherwise it will create error in collateral accounting
    function removeCollateralStrategy(address _collateral, address _strategy) external onlyOwner {
        // Check if the collateral and strategy are mapped
        // Ensure none of the collateral is deposited into the strategy
        // Remove collateral capacity and the strategy from the list
        if (!collateralStrategyInfo[_collateral][_strategy].exists) {
            revert CollateralStrategyNotMapped();
        }

        if (collateralInfo[_collateral].defaultStrategy == _strategy) {
            revert IsDefaultStrategy();
        }
        if (IStrategy(_strategy).checkBalance(_collateral) != 0) {
            revert CollateralStrategyInUse();
        }

        uint256 numStrategy = collateralStrategies[_collateral].length;
        // Unlink the strategy from the collateral and update collateral capacity used
        for (uint256 i; i < numStrategy;) {
            if (collateralStrategies[_collateral][i] == _strategy) {
                collateralStrategies[_collateral][i] = collateralStrategies[_collateral][numStrategy - 1];
                collateralStrategies[_collateral].pop();
                collateralInfo[_collateral].collateralCapacityUsed -=
                    collateralStrategyInfo[_collateral][_strategy].allocationCap;
                delete collateralStrategyInfo[_collateral][_strategy];
                break;
            }

            unchecked {
                ++i;
            }
        }

        emit CollateralStrategyRemoved(_collateral, _strategy);
    }

    /// @inheritdoc ICollateralManager
    function updateCollateralDefaultStrategy(address _collateral, address _strategy) external onlyOwner {
        if (!collateralStrategyInfo[_collateral][_strategy].exists && _strategy != address(0)) {
            revert CollateralStrategyNotMapped();
        }
        collateralInfo[_collateral].defaultStrategy = _strategy;
    }

    /// @inheritdoc ICollateralManager
    function validateAllocation(address _collateral, address _strategy, uint256 _amount) external view returns (bool) {
        if (!collateralInfo[_collateral].allocationAllowed) {
            revert CollateralAllocationPaused();
        }

        StrategyData storage strategyData = collateralStrategyInfo[_collateral][_strategy];

        if (!strategyData.exists) {
            revert CollateralStrategyNotMapped();
        }

        uint256 maxCollateralUsage = (
            strategyData.allocationCap * (getCollateralInVault(_collateral) + getCollateralInStrategies(_collateral))
        ) / Helpers.MAX_PERCENTAGE;

        // Get the collateral balance in the specified strategy
        uint256 collateralBalance = IStrategy(_strategy).checkBalance(_collateral);

        // Check if the allocation request is within the allowed limits
        if (maxCollateralUsage >= collateralBalance) {
            return ((maxCollateralUsage - collateralBalance) >= _amount);
        }

        return false;
    }

    /// @inheritdoc ICollateralManager
    function getFeeCalibrationData(address _collateral) external view returns (uint16, uint16, uint16, uint256) {
        // Compose and return collateral mint params
        CollateralData memory collateralStorageData = collateralInfo[_collateral];

        // Check if collateral exists
        if (!collateralStorageData.exists) revert CollateralDoesNotExist();

        uint256 totalCollateral = getCollateralInStrategies(_collateral) + getCollateralInVault(_collateral);

        return (
            collateralStorageData.baseMintFee,
            collateralStorageData.baseRedeemFee,
            collateralStorageData.desiredCollateralComposition,
            totalCollateral * collateralStorageData.conversionFactor
        );
    }

    /// @inheritdoc ICollateralManager
    function getMintParams(address _collateral) external view returns (CollateralMintData memory mintData) {
        // Compose and return collateral mint params
        CollateralData memory collateralStorageData = collateralInfo[_collateral];

        // Check if collateral exists
        if (!collateralInfo[_collateral].exists) {
            revert CollateralDoesNotExist();
        }

        return CollateralMintData({
            mintAllowed: collateralStorageData.mintAllowed,
            baseMintFee: collateralStorageData.baseMintFee,
            downsidePeg: collateralStorageData.downsidePeg,
            desiredCollateralComposition: collateralStorageData.desiredCollateralComposition,
            conversionFactor: collateralStorageData.conversionFactor
        });
    }

    /// @inheritdoc ICollateralManager
    function getRedeemParams(address _collateral) external view returns (CollateralRedeemData memory redeemData) {
        if (!collateralInfo[_collateral].exists) {
            revert CollateralDoesNotExist();
        }
        // Check if collateral exists
        // Compose and return collateral redeem params

        CollateralData memory collateralStorageData = collateralInfo[_collateral];

        return CollateralRedeemData({
            redeemAllowed: collateralStorageData.redeemAllowed,
            defaultStrategy: collateralStorageData.defaultStrategy,
            baseRedeemFee: collateralStorageData.baseRedeemFee,
            desiredCollateralComposition: collateralStorageData.desiredCollateralComposition,
            conversionFactor: collateralStorageData.conversionFactor
        });
    }

    /// @notice Gets a list of all listed collaterals
    /// @return List of addresses representing all listed collaterals
    function getAllCollaterals() external view returns (address[] memory) {
        return collaterals;
    }

    /// @notice Gets a list of all strategies linked to a collateral
    /// @param _collateral Address of the collateral
    /// @return List of addresses representing available strategies for the collateral
    function getCollateralStrategies(address _collateral) external view returns (address[] memory) {
        return collateralStrategies[_collateral];
    }

    /// @notice Verifies if a strategy is linked to a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @return True if the strategy is linked to the collateral, otherwise False
    function isValidStrategy(address _collateral, address _strategy) external view returns (bool) {
        return collateralStrategyInfo[_collateral][_strategy].exists;
    }

    /// @inheritdoc ICollateralManager
    function getCollateralInStrategies(address _collateral) public view returns (uint256 amountInStrategies) {
        uint256 numStrategy = collateralStrategies[_collateral].length;

        for (uint256 i; i < numStrategy;) {
            amountInStrategies += IStrategy(collateralStrategies[_collateral][i]).checkBalance(_collateral);
            unchecked {
                ++i;
            }
        }

        return amountInStrategies;
    }

    /// @inheritdoc ICollateralManager
    function getCollateralInVault(address _collateral) public view returns (uint256 amountInVault) {
        return IERC20(_collateral).balanceOf(VAULT);
    }

    /// @notice Get the amount of collateral allocated in a strategy
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @return allocatedAmt Allocated amount
    function getCollateralInAStrategy(address _collateral, address _strategy)
        public
        view
        returns (uint256 allocatedAmt)
    {
        return IStrategy(_strategy).checkBalance(_collateral);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ICollateralManager {
    struct CollateralBaseData {
        bool mintAllowed;
        bool redeemAllowed;
        bool allocationAllowed;
        uint16 baseMintFee;
        uint16 baseRedeemFee;
        uint16 downsidePeg;
        uint16 desiredCollateralComposition;
    }

    struct CollateralMintData {
        bool mintAllowed;
        uint16 baseMintFee;
        uint16 downsidePeg;
        uint16 desiredCollateralComposition;
        uint256 conversionFactor;
    }

    struct CollateralRedeemData {
        bool redeemAllowed;
        address defaultStrategy;
        uint16 baseRedeemFee;
        uint16 desiredCollateralComposition;
        uint256 conversionFactor;
    }

    /// @notice Update existing collateral configuration
    /// @param _collateral Address of the collateral
    /// @param _updateData Updated configuration for the collateral
    function updateCollateralData(address _collateral, CollateralBaseData memory _updateData) external;

    function updateCollateralDefaultStrategy(address _collateral, address _strategy) external;

    /// @notice Validate allocation for a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the desired strategy
    /// @param _amount Amount to be allocated.
    /// @return True for valid allocation request.
    function validateAllocation(address _collateral, address _strategy, uint256 _amount) external view returns (bool);

    /// @notice Get the required data for mint
    /// @param _collateral Address of the collateral
    /// @return Base fee config for collateral (baseMintFee, baseRedeemFee, composition, totalCollateral)
    function getFeeCalibrationData(address _collateral) external view returns (uint16, uint16, uint16, uint256);

    /// @notice Get the required data for mint
    /// @param _collateral Address of the collateral
    /// @return mintData
    function getMintParams(address _collateral) external view returns (CollateralMintData memory mintData);

    /// @notice Get the required data for USDs redemption
    /// @param _collateral Address of the collateral
    /// @return redeemData
    function getRedeemParams(address _collateral) external view returns (CollateralRedeemData memory redeemData);

    /// @notice Gets list of all the listed collateral
    /// @return address[] of listed collaterals
    function getAllCollaterals() external view returns (address[] memory);

    /// @notice Get the amount of collateral in all Strategies
    /// @param _collateral Address of the collateral
    /// @return amountInStrategies
    function getCollateralInStrategies(address _collateral) external view returns (uint256 amountInStrategies);

    /// @notice Get the amount of collateral in vault
    /// @param _collateral Address of the collateral
    /// @return amountInVault
    function getCollateralInVault(address _collateral) external view returns (uint256 amountInVault);

    /// @notice Verify if a strategy is linked to a collateral
    /// @param _collateral Address of the collateral
    /// @param _strategy Address of the strategy
    /// @return boolean true if the strategy is linked to the collateral
    function isValidStrategy(address _collateral, address _strategy) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IStrategy {
    /// @notice Deposit asset into the strategy
    /// @param _asset Address of the asset
    /// @param _amount Amount of asset to be deposited
    function deposit(address _asset, uint256 _amount) external;

    /// @notice Withdraw `_asset` to `_recipient` (usually vault)
    /// @param _recipient Address of the recipient
    /// @param _asset Address of the asset
    /// @param _amount Amount to be withdrawn
    /// @return amountReceived The actual amount received
    function withdraw(address _recipient, address _asset, uint256 _amount) external returns (uint256);

    /// @notice Check if collateral allocation is supported by the strategy
    /// @param _asset Address of the asset which is to be checked
    /// @return isSupported True if supported and False if not
    function supportsCollateral(address _asset) external view returns (bool);

    /// @notice Get the amount of a specific asset held in the strategy
    ///           excluding the interest
    /// @dev    Assuming balanced withdrawal
    /// @param  _asset      Address of the asset
    /// @return Balance of the asset
    function checkBalance(address _asset) external view returns (uint256);

    /// @notice Gets the amount of asset withdrawable at any given time
    /// @param _asset Address of the asset
    /// @return availableBalance Available balance of the asset
    function checkAvailableBalance(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title A standard library for errors and constant values
/// @author Sperax Foundation
library Helpers {
    // Constants
    uint16 internal constant MAX_PERCENTAGE = 10000;
    address internal constant SPA = 0x5575552988A3A80504bBaeB1311674fCFd40aD4B;
    address internal constant USDS = 0xD74f5255D557944cf7Dd0E45FF521520002D5748;

    // Errors
    error CustomError(string message);
    error InvalidAddress();
    error GTMaxPercentage(uint256 actual);
    error InvalidAmount();
    error MinSlippageError(uint256 actualAmt, uint256 minExpectedAmt);
    error MaxSlippageError(uint256 actualAmt, uint256 maxExpectedAmt);

    /// @notice Checks the expiry of a transaction's deadline
    /// @param _deadline Deadline specified by the sender of the transaction
    /// @dev Reverts if the current block's timestamp is greater than `_deadline`
    function _checkDeadline(uint256 _deadline) internal view {
        if (block.timestamp > _deadline) revert CustomError("Deadline passed");
    }

    /// @notice Checks for a non-zero address
    /// @param _addr Address to be validated
    /// @dev Reverts if `_addr` is equal to `address(0)`
    function _isNonZeroAddr(address _addr) internal pure {
        if (_addr == address(0)) revert InvalidAddress();
    }

    /// @notice Checks for a non-zero amount
    /// @param _amount Amount to be validated
    /// @dev Reverts if `_amount` is equal to `0`
    function _isNonZeroAmt(uint256 _amount) internal pure {
        if (_amount == 0) revert InvalidAmount();
    }

    /// @notice Checks for a non-zero amount with a custom error message
    /// @param _amount Amount to be validated
    /// @param _err Custom error message
    /// @dev Reverts if `_amount` is equal to `0` with the provided custom error message
    function _isNonZeroAmt(uint256 _amount, string memory _err) internal pure {
        if (_amount == 0) revert CustomError(_err);
    }

    /// @notice Checks whether the `_percentage` is less than or equal to `MAX_PERCENTAGE`
    /// @param _percentage The percentage to be checked
    /// @dev Reverts if `_percentage` is greater than `MAX_PERCENTAGE`
    function _isLTEMaxPercentage(uint256 _percentage) internal pure {
        if (_percentage > MAX_PERCENTAGE) revert GTMaxPercentage(_percentage);
    }

    /// @notice Checks whether the `_percentage` is less than or equal to `MAX_PERCENTAGE` with a custom error message
    /// @param _percentage The percentage to be checked
    /// @param _err Custom error message
    /// @dev Reverts with the provided custom error message if `_percentage` is greater than `MAX_PERCENTAGE`
    function _isLTEMaxPercentage(uint256 _percentage, string memory _err) internal pure {
        if (_percentage > MAX_PERCENTAGE) revert CustomError(_err);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}