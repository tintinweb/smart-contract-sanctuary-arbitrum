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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title   IPoolAddressesProviderRegistry
 * @author  maneki.finance
 * @notice  Defines the basic interface for an Maneki Pool Addresses Provider Registry.
 * @dev     Based on AaveV3's IPoolAddressesProviderRegistry
 */
interface IPoolAddressesProviderRegistry {
    /**
     * @dev     Emitted when a new AddressesProvider is registered.
     * @param   addressesProvider The address of the registered PoolAddressesProvider
     * @param   id The id of the registered PoolAddressesProvider
     */
    event AddressesProviderRegistered(
        address indexed addressesProvider,
        uint256 indexed id
    );

    /**
     * @dev     Emitted when an AddressesProvider is unregistered.
     * @param   addressesProvider The address of the unregistered PoolAddressesProvider
     * @param   id The id of the unregistered PoolAddressesProvider
     */
    event AddressesProviderUnregistered(
        address indexed addressesProvider,
        uint256 indexed id
    );

    /**
     * @notice  Returns the list of registered addresses providers
     * @return  The list of addresses providers
     */
    function getAddressesProvidersList()
        external
        view
        returns (address[] memory);

    /**
     * @notice  Returns the id of a registered PoolAddressesProvider
     * @param   addressesProvider The address of the PoolAddressesProvider
     * @return  The id of the PoolAddressesProvider or 0 if is not registered
     */
    function getAddressesProviderIdByAddress(
        address addressesProvider
    ) external view returns (uint256);

    /**
     * @notice  Returns the address of a registered PoolAddressesProvider
     * @param   id The id of the market
     * @return  The address of the PoolAddressesProvider with the given id or zero address if it is not registered
     */
    function getAddressesProviderAddressById(
        uint256 id
    ) external view returns (address);

    /**
     * @notice  Registers an addresses provider
     * @dev     The PoolAddressesProvider must not already be registered in the registry
     * @dev     The id must not be used by an already registered PoolAddressesProvider
     * @param   provider The address of the new PoolAddressesProvider
     * @param   id The id for the new PoolAddressesProvider, referring to the market it belongs to
     */
    function registerAddressesProvider(address provider, uint256 id) external;

    /**
     * @notice  Removes an addresses provider from the list of registered addresses providers
     * @param   provider The PoolAddressesProvider address
     */
    function unregisterAddressesProvider(address provider) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IPoolAddressesProviderRegistry} from "../../interfaces/IPoolAddressesProviderRegistry.sol";

/**
 * @title   PoolAddressesProviderRegistry
 * @author  maneki.finance
 * @notice  Main registry of PoolAddressesProvider of Maneki markets.
 * @dev     Used for indexing purposes of Maneki protocol's markets. The id assigned to a PoolAddressesProvider refers to the
 *          market it is connected with, for example with `1` for the Maneki main market and `2` for the next created.
 *          Based on AaveV3's PoolAddressesProviderRegistry
 */
contract PoolAddressesProviderRegistry is
    Ownable,
    IPoolAddressesProviderRegistry
{
    // Map of address provider ids (addressesProvider => id)
    mapping(address => uint256) private _addressesProviderToId;
    // Map of id to address provider (id => addressesProvider)
    mapping(uint256 => address) private _idToAddressesProvider;
    // List of addresses providers
    address[] private _addressesProvidersList;
    // Map of address provider list indexes (addressesProvider => indexInList)
    mapping(address => uint256) private _addressesProvidersIndexes;

    /**
     * @dev     Constructor.
     * @param   owner The owner address of this contract.
     */
    constructor(address owner) Ownable(msg.sender) {
        transferOwnership(owner);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProvidersList()
        external
        view
        override
        returns (address[] memory)
    {
        return _addressesProvidersList;
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function registerAddressesProvider(
        address provider,
        uint256 id
    ) external override onlyOwner {
        require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);
        require(
            _idToAddressesProvider[id] == address(0),
            Errors.INVALID_ADDRESSES_PROVIDER_ID
        );
        require(
            _addressesProviderToId[provider] == 0,
            Errors.ADDRESSES_PROVIDER_ALREADY_ADDED
        );

        _addressesProviderToId[provider] = id;
        _idToAddressesProvider[id] = provider;

        _addToAddressesProvidersList(provider);
        emit AddressesProviderRegistered(provider, id);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function unregisterAddressesProvider(
        address provider
    ) external override onlyOwner {
        require(
            _addressesProviderToId[provider] != 0,
            Errors.ADDRESSES_PROVIDER_NOT_REGISTERED
        );
        uint256 oldId = _addressesProviderToId[provider];
        _idToAddressesProvider[oldId] = address(0);
        _addressesProviderToId[provider] = 0;

        _removeFromAddressesProvidersList(provider);

        emit AddressesProviderUnregistered(provider, oldId);
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProviderIdByAddress(
        address addressesProvider
    ) external view override returns (uint256) {
        return _addressesProviderToId[addressesProvider];
    }

    /// @inheritdoc IPoolAddressesProviderRegistry
    function getAddressesProviderAddressById(
        uint256 id
    ) external view override returns (address) {
        return _idToAddressesProvider[id];
    }

    /**
     * @notice  Adds the addresses provider address to the list.
     * @param   provider The address of the PoolAddressesProvider
     */
    function _addToAddressesProvidersList(address provider) internal {
        _addressesProvidersIndexes[provider] = _addressesProvidersList.length;
        _addressesProvidersList.push(provider);
    }

    /**
     * @notice  Removes the addresses provider address from the list.
     * @param   provider The address of the PoolAddressesProvider
     */
    function _removeFromAddressesProvidersList(address provider) internal {
        uint256 index = _addressesProvidersIndexes[provider];

        _addressesProvidersIndexes[provider] = 0;

        // Swap the index of the last addresses provider in the list with the index of the provider to remove
        uint256 lastIndex = _addressesProvidersList.length - 1;
        if (index < lastIndex) {
            address lastProvider = _addressesProvidersList[lastIndex];
            _addressesProvidersList[index] = lastProvider;
            _addressesProvidersIndexes[lastProvider] = index;
        }
        _addressesProvidersList.pop();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

/**
 * @title   Errors library
 * @author  maneki.finance
 * @notice  Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev     Based on AaveV3's Errors.sol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "Caller not Pool Admin";
    string public constant CALLER_NOT_EMERGENCY_ADMIN =
        "Caller not Emergency Admin";
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN =
        "Caller not Pool or Emergency Admin";
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN =
        "Caller not Risk or Pool Admin";
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN =
        "Caller not Asset Listing or Pool Admin";
    string public constant CALLER_NOT_BRIDGE = "Caller not Bridge";
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED =
        "Pool Addresses Provider not registered";
    string public constant INVALID_ADDRESSES_PROVIDER_ID =
        "Invalid Pool Addresses Provider ID";
    string public constant NOT_CONTRACT = "Address is not a contract";
    string public constant CALLER_NOT_POOL_CONFIGURATOR =
        "Caller not Pool Configurator";
    string public constant CALLER_NOT_ATOKEN = "Caller not MToken";
    string public constant INVALID_ADDRESSES_PROVIDER =
        "Invalid Pool Addresses Provider address";
    string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN =
        "Invalid flashloan executor return value";
    string public constant RESERVE_ALREADY_ADDED = "Reserve already added";
    string public constant NO_MORE_RESERVES_ALLOWED =
        "Maximum amount of reserves reached";
    string public constant EMODE_CATEGORY_RESERVED =
        "Zero eMode category is reserved for volatile heterogeneous assets";
    string public constant INVALID_EMODE_CATEGORY_ASSIGNMENT =
        "Invalid eMode category assignment to asset";
    string public constant RESERVE_LIQUIDITY_NOT_ZERO =
        "The liquidity of the reserve needs to be 0";
    string public constant FLASHLOAN_PREMIUM_INVALID =
        "Invalid flashloan premium";
    string public constant INVALID_RESERVE_PARAMS =
        "Invalid risk parameters for the reserve";
    string public constant INVALID_EMODE_CATEGORY_PARAMS =
        "Invalid risk parameters for the eMode category";
    string public constant BRIDGE_PROTOCOL_FEE_INVALID =
        "Invalid bridge protocol fee";
    string public constant CALLER_MUST_BE_POOL =
        "The caller of this function must be a pool";
    string public constant INVALID_MINT_AMOUNT = "Invalid amount to mint";
    string public constant INVALID_BURN_AMOUNT = "Invalid amount to burn";
    string public constant INVALID_AMOUNT = "Amount must be greater than 0";
    string public constant RESERVE_INACTIVE =
        "Action requires an active reserve";
    string public constant RESERVE_FROZEN = "Reserve is frozen";
    string public constant RESERVE_PAUSED = "Reserve is paused";
    string public constant BORROWING_NOT_ENABLED = "Borrowing is not enabled";
    string public constant STABLE_BORROWING_NOT_ENABLED =
        "Stable borrowing not enabled";
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE =
        "Cannot withdraw more than available user balance";
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED =
        "Invalid interest rate mode";
    string public constant COLLATERAL_BALANCE_IS_ZERO =
        "The collateral balance is 0";
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "Health factor is lesser than the liquidation threshold";
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW =
        "Not enough collateral to cover new borrow";
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY =
        "Collateral is (mostly) the same currency that is being borrowed";
    string public constant AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE =
        "Amount is greater than the max loan size in stable rate mode'";
    string public constant NO_DEBT_OF_SELECTED_TYPE =
        "User does not have debt on selected reserve to repay";
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF =
        "To repay on behalf of a user an explicit amount to repay is needed";
    string public constant NO_OUTSTANDING_STABLE_DEBT =
        "User does not have outstanding stable rate debt on selected reserve";
    string public constant NO_OUTSTANDING_VARIABLE_DEBT =
        "User does not have outstanding variable rate debt on selected reserve";
    string public constant UNDERLYING_BALANCE_ZERO =
        "The underlying balance needs to be greater than 0'";
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET =
        "Interest rate rebalance conditions were not met";
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD =
        "Health factor is not below the threshold";
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED =
        "The collateral chosen cannot be liquidated";
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER =
        "User did not borrow the specified currency";
    string public constant INCONSISTENT_FLASHLOAN_PARAMS =
        "Inconsistent flashloan parameters";
    string public constant BORROW_CAP_EXCEEDED = "Borrow cap is exceeded";
    string public constant SUPPLY_CAP_EXCEEDED = "Supply cap is exceeded";
    string public constant UNBACKED_MINT_CAP_EXCEEDED =
        "Unbacked mint cap is exceeded";
    string public constant DEBT_CEILING_EXCEEDED = "Debt ceiling is exceeded";
    string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO =
        "Claimable rights over underlying not zero (mToken supply or accruedToTreasury)";
    string public constant STABLE_DEBT_NOT_ZERO =
        "Stable debt supply is not zero";
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO =
        "Variable debt supply is not zero";
    string public constant LTV_VALIDATION_FAILED = "Ltv validation failed";
    string public constant INCONSISTENT_EMODE_CATEGORY =
        "Inconsistent eMode category";
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED =
        "Price oracle sentinel validation failed";
    string public constant ASSET_NOT_BORROWABLE_IN_ISOLATION =
        "Asset is not borrowable in isolation mode";
    string public constant RESERVE_ALREADY_INITIALIZED =
        "Reserve has already been initialized";
    string public constant USER_IN_ISOLATION_MODE = "User is in isolation mode";
    string public constant INVALID_LTV =
        "Invalid ltv parameter for the reserve";
    string public constant INVALID_LIQ_THRESHOLD =
        "Invalid liquidity threshold parameter for the reserve";
    string public constant INVALID_LIQ_BONUS =
        "Invalid liquidity bonus parameter for the reserve";
    string public constant INVALID_DECIMALS =
        "Invalid decimals parameter of the underlying asset of the reserve";
    string public constant INVALID_RESERVE_FACTOR =
        "Invalid reserve factor parameter for the reserve";
    string public constant INVALID_BORROW_CAP =
        "Invalid borrow cap for the reserve";
    string public constant INVALID_SUPPLY_CAP =
        "Invalid supply cap for the reserve";
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE =
        "Invalid liquidation protocol fee for the reserve";
    string public constant INVALID_EMODE_CATEGORY =
        "Invalid eMode category for the reserve";
    string public constant INVALID_UNBACKED_MINT_CAP =
        "Invalid unbacked mint cap for the reserve";
    string public constant INVALID_DEBT_CEILING =
        "Invalid debt ceiling for the reserve";
    string public constant INVALID_RESERVE_INDEX = "Invalid reserve index";
    string public constant ACL_ADMIN_CANNOT_BE_ZERO =
        "ACL admin cannot be set to the zero address";
    string public constant INCONSISTENT_PARAMS_LENGTH =
        "Inconsistent parameters length";
    string public constant ZERO_ADDRESS_NOT_VALID = "Zero address not valid";
    string public constant INVALID_EXPIRATION = "Invalid expiration";
    string public constant INVALID_SIGNATURE = "Invalid signature";
    string public constant OPERATION_NOT_SUPPORTED = "Operation not supported";
    string public constant DEBT_CEILING_NOT_ZERO = "Debt ceiling is not zero";
    string public constant ASSET_NOT_LISTED = "Asset is not listed";
    string public constant INVALID_OPTIMAL_USAGE_RATIO =
        "Invalid optimal usage ratio";
    string public constant INVALID_OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO =
        "Invalid optimal stable to total debt ratio";
    string public constant UNDERLYING_CANNOT_BE_RESCUED =
        "The underlying asset cannot be rescued";
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED =
        "Reserve has already been added to reserve list";
    string public constant POOL_ADDRESSES_DO_NOT_MATCH =
        "The token implementation pool address and the pool address provided by the initializing pool do not match";
    string public constant STABLE_BORROWING_ENABLED =
        "Stable borrowing is enabled";
    string public constant SILOED_BORROWING_VIOLATION =
        "User is trying to borrow multiple assets including a siloed one";
    string public constant RESERVE_DEBT_NOT_ZERO =
        "The total debt of the reserve needs to be 0";
    string public constant FLASHLOAN_DISABLED =
        "FlashLoaning for this asset is disabled";
    string public constant REBASING_DISTRIBUTOR_CANNOT_BE_ZERO =
        "Rebasing Distributor cannot be zero address";
    string public constant REBASING_DISTRIBUTOR_ALREADY_SET =
        "Rebasing Distributor already set";
    string public constant DELEGATE_CALL_FAILED = "Delegate call failed";
    string public constant ONLY_PUBLIC_LIQUIDATOR_ALLOWED =
        "Only PublicLiquidator allowed to liquidate";
}