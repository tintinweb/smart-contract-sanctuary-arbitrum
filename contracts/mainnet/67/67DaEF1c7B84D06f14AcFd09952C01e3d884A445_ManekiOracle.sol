// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IACLManager
 * @author maneki.finance
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /**
     * @notice Returns the contract address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Returns the identifier of the PoolAdmin role
     * @return The id of the PoolAdmin role
     */
    function POOL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the EmergencyAdmin role
     * @return The id of the EmergencyAdmin role
     */
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the RiskAdmin role
     * @return The id of the RiskAdmin role
     */
    function RISK_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the FlashBorrower role
     * @return The id of the FlashBorrower role
     */
    function FLASH_BORROWER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the Bridge role
     * @return The id of the Bridge role
     */
    function BRIDGE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the identifier of the AssetListingAdmin role
     * @return The id of the AssetListingAdmin role
     */
    function ASSET_LISTING_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Set the role as admin of a specific role.
     * @dev By default the admin role for all roles is `DEFAULT_ADMIN_ROLE`.
     * @param role The role to be managed by the admin role
     * @param adminRole The admin role
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    /**
     * @notice Adds a new admin as PoolAdmin
     * @param admin The address of the new admin
     */
    function addPoolAdmin(address admin) external;

    /**
     * @notice Removes an admin as PoolAdmin
     * @param admin The address of the admin to remove
     */
    function removePoolAdmin(address admin) external;

    /**
     * @notice Returns true if the address is PoolAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is PoolAdmin, false otherwise
     */
    function isPoolAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as EmergencyAdmin
     * @param admin The address of the new admin
     */
    function addEmergencyAdmin(address admin) external;

    /**
     * @notice Removes an admin as EmergencyAdmin
     * @param admin The address of the admin to remove
     */
    function removeEmergencyAdmin(address admin) external;

    /**
     * @notice Returns true if the address is EmergencyAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is EmergencyAdmin, false otherwise
     */
    function isEmergencyAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new admin as RiskAdmin
     * @param admin The address of the new admin
     */
    function addRiskAdmin(address admin) external;

    /**
     * @notice Removes an admin as RiskAdmin
     * @param admin The address of the admin to remove
     */
    function removeRiskAdmin(address admin) external;

    /**
     * @notice Returns true if the address is RiskAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is RiskAdmin, false otherwise
     */
    function isRiskAdmin(address admin) external view returns (bool);

    /**
     * @notice Adds a new address as FlashBorrower
     * @param borrower The address of the new FlashBorrower
     */
    function addFlashBorrower(address borrower) external;

    /**
     * @notice Removes an address as FlashBorrower
     * @param borrower The address of the FlashBorrower to remove
     */
    function removeFlashBorrower(address borrower) external;

    /**
     * @notice Returns true if the address is FlashBorrower, false otherwise
     * @param borrower The address to check
     * @return True if the given address is FlashBorrower, false otherwise
     */
    function isFlashBorrower(address borrower) external view returns (bool);

    /**
     * @notice Adds a new address as Bridge
     * @param bridge The address of the new Bridge
     */
    function addBridge(address bridge) external;

    /**
     * @notice Removes an address as Bridge
     * @param bridge The address of the bridge to remove
     */
    function removeBridge(address bridge) external;

    /**
     * @notice Returns true if the address is Bridge, false otherwise
     * @param bridge The address to check
     * @return True if the given address is Bridge, false otherwise
     */
    function isBridge(address bridge) external view returns (bool);

    /**
     * @notice Adds a new admin as AssetListingAdmin
     * @param admin The address of the new admin
     */
    function addAssetListingAdmin(address admin) external;

    /**
     * @notice Removes an admin as AssetListingAdmin
     * @param admin The address of the admin to remove
     */
    function removeAssetListingAdmin(address admin) external;

    /**
     * @notice Returns true if the address is AssetListingAdmin, false otherwise
     * @param admin The address to check
     * @return True if the given address is AssetListingAdmin, false otherwise
     */
    function isAssetListingAdmin(address admin) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity 0.8.24;

interface IAggregator {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );

    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

import {IPriceOracleGetter} from "./IPriceOracleGetter.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IManekiOracle
 * @author maneki.finance
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IManekiOracle is IPriceOracleGetter {
    /**
     * @dev Emitted after the base currency is set
     * @param baseCurrency The base currency of used for price quotes
     * @param baseCurrencyUnit The unit of the base currency
     */
    event BaseCurrencySet(
        address indexed baseCurrency,
        uint256 baseCurrencyUnit
    );

    /**
     * @dev Emitted after the price source of an asset is updated
     * @param asset The address of the asset
     * @param source The price source of the asset
     */
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the address of fallback oracle is updated
     * @param fallbackOracle The address of the fallback oracle
     */
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER()
        external
        view
        returns (IPoolAddressesProvider);

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external;

    /**
     * @notice Sets the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function setFallbackOracle(address fallbackOracle) external;

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return The prices of the given assets
     */
    function getAssetsPrices(
        address[] calldata assets
    ) external view returns (uint256[] memory);

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns the address of the fallback oracle
     * @return The address of the fallback oracle
     */
    function getFallbackOracle() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title   IPoolAddressesProvider
 * @author  maneki.finance
 * @notice  Defines the basic interface for a Pool Addresses Provider
 * @dev     Based on AaveV3's IPoolAddressesProvider
 */
interface IPoolAddressesProvider {
    /**
     * @dev     Emitted when the market identifier is updated.
     * @param   oldMarketId The old id of the market
     * @param   newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev     Emitted when the pool is updated.
     * @param   oldAddress The old address of the Pool
     * @param   newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev     Emitted when the pool configurator is updated.
     * @param   oldAddress The old address of the PoolConfigurator
     * @param   newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the price oracle is updated.
     * @param   oldAddress The old address of the PriceOracle
     * @param   newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the ACL manager is updated.
     * @param   oldAddress The old address of the ACLManager
     * @param   newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the ACL admin is updated.
     * @param   oldAddress The old address of the ACLAdmin
     * @param   newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the price oracle sentinel is updated.
     * @param   oldAddress The old address of the PriceOracleSentinel
     * @param   newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the pool data provider is updated.
     * @param   oldAddress The old address of the PoolDataProvider
     * @param   newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when a new proxy is created.
     * @param   id The identifier of the proxy
     * @param   proxyAddress The address of the created proxy contract
     * @param   implementationAddress The address of the implementation contract
     */
    event ProxyCreated(
        bytes32 indexed id,
        address indexed proxyAddress,
        address indexed implementationAddress
    );

    /**
     * @dev     Emitted when a new non-proxied contract address is registered.
     * @param   id The identifier of the contract
     * @param   oldAddress The address of the old contract
     * @param   newAddress The address of the new contract
     */
    event AddressSet(
        bytes32 indexed id,
        address indexed oldAddress,
        address indexed newAddress
    );

    /**
     * @dev     Emitted when the implementation of the proxy registered with id is updated
     * @param   id The identifier of the contract
     * @param   proxyAddress The address of the proxy contract
     * @param   oldImplementationAddress The address of the old implementation contract
     * @param   newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /**
     * @notice  Returns the id of the Maneki market to which this contract points to.
     * @return  The market id
     */
    function getMarketId() external view returns (string memory);

    /**
     * @notice  Associates an id with a specific PoolAddressesProvider.
     * @dev     This can be used to create an onchain registry of PoolAddressesProviders to
     *          identify and validate multiple Maneki markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice  Returns an address by its identifier.
     * @dev     The returned address might be an EOA or a contract, potentially proxied
     * @dev     It returns ZERO if there is no registered address with the given id
     * @param   id The id
     * @return  The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice  General function to update the implementation of a proxy registered with
     *          certain `id`. If there is no proxy registered, it will instantiate one and
     *          set as implementation the `newImplementationAddress`.
     * @dev     IMPORTANT Use this function carefully, only for ids that don't have an explicit
     *          setter function, in order to avoid unexpected consequences
     * @param   id The id
     * @param   newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(
        bytes32 id,
        address newImplementationAddress
    ) external;

    /**
     * @notice  Sets an address for an id replacing the address saved in the addresses map.
     * @dev     IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param   id The id
     * @param   newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice  Returns the address of the Pool proxy.
     * @return  The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @notice  Updates the implementation of the Pool, or creates a proxy
     *          setting the new `pool` implementation when the function is called for the first time.
     * @param   newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice  Returns the address of the PoolConfigurator proxy.
     * @return  The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice  Updates the implementation of the PoolConfigurator, or creates a proxy
     *          setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param   newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice  Returns the address of the price oracle.
     * @return  The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice  Updates the address of the price oracle.
     * @param   newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice  Returns the address of the ACL manager.
     * @return  The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice  Updates the address of the ACL manager.
     * @param   newAclManager The address of the new ACLManager
     */
    function setACLManager(address newAclManager) external;

    /**
     * @notice  Returns the address of the ACL admin.
     * @return  The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice  Updates the address of the ACL admin.
     * @param   newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice  Returns the address of the price oracle sentinel.
     * @return  The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice  Updates the address of the price oracle sentinel.
     * @param   newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice  Returns the address of the data provider.
     * @return  The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice  Updates the address of the data provider.
     * @param   newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.24;

/**
 * @title IPriceOracleGetter
 * @author maneki.finance
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
    /**
     * @notice Returns the base currency address
     * @dev Address 0x0 is reserved for USD as base currency.
     * @return Returns the base currency address.
     */
    function BASE_CURRENCY() external view returns (address);

    /**
     * @notice Returns the base currency unit
     * @dev 1 ether for ETH, 1e8 for USD.
     * @return Returns the base currency unit.
     */
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    /**
     * @notice Returns the asset price in the base currency
     * @param asset The address of the asset
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {IAggregator} from "../interfaces/IAggregator.sol";
import {Errors} from "../protocol/libraries/helpers/Errors.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IManekiOracle} from "../interfaces/IManekiOracle.sol";

/**
 * @title ManekiOracle
 * @author maneki.finance
 * @notice Contract to get asset prices, manage price sources and update the fallback oracle
 * - Use of Chainlink Aggregators as first source of price
 * - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallback oracle
 * - Owned by the Aave governance
 */
contract ManekiOracle is IManekiOracle {
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Map of asset price sources (asset => priceSource)
    mapping(address => IAggregator) private assetsSources;

    IPriceOracleGetter private _fallbackOracle;
    address public immutable override BASE_CURRENCY;
    uint256 public immutable override BASE_CURRENCY_UNIT;

    /**
     * @dev Only asset listing or pool admin can call functions marked by this modifier.
     */
    modifier onlyAssetListingOrPoolAdmins() {
        _onlyAssetListingOrPoolAdmins();
        _;
    }

    /**
     * @notice Constructor
     * @param provider The address of the new PoolAddressesProvider
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     * @param fallbackOracle The address of the fallback oracle to use if the data of an
     *        aggregator is not consistent
     * @param baseCurrency The base currency used for the price quotes. If USD is used, base currency is 0x0
     * @param baseCurrencyUnit The unit of the base currency
     */
    constructor(
        IPoolAddressesProvider provider,
        address[] memory assets,
        address[] memory sources,
        address fallbackOracle,
        address baseCurrency,
        uint256 baseCurrencyUnit
    ) {
        ADDRESSES_PROVIDER = provider;
        _setFallbackOracle(fallbackOracle);
        _setAssetsSources(assets, sources);
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
        emit BaseCurrencySet(baseCurrency, baseCurrencyUnit);
    }

    /// @inheritdoc IManekiOracle
    function setAssetSources(
        address[] calldata assets,
        address[] calldata sources
    ) external override onlyAssetListingOrPoolAdmins {
        _setAssetsSources(assets, sources);
    }

    /// @inheritdoc IManekiOracle
    function setFallbackOracle(
        address fallbackOracle
    ) external override onlyAssetListingOrPoolAdmins {
        _setFallbackOracle(fallbackOracle);
    }

    /**
     * @notice Internal function to set the sources for each asset
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     */
    function _setAssetsSources(
        address[] memory assets,
        address[] memory sources
    ) internal {
        require(
            assets.length == sources.length,
            Errors.INCONSISTENT_PARAMS_LENGTH
        );
        for (uint256 i = 0; i < assets.length; i++) {
            assetsSources[assets[i]] = IAggregator(sources[i]);
            emit AssetSourceUpdated(assets[i], sources[i]);
        }
    }

    /**
     * @notice Internal function to set the fallback oracle
     * @param fallbackOracle The address of the fallback oracle
     */
    function _setFallbackOracle(address fallbackOracle) internal {
        _fallbackOracle = IPriceOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    /// @inheritdoc IPriceOracleGetter
    function getAssetPrice(
        address asset
    ) public view override returns (uint256) {
        IAggregator source = assetsSources[asset];

        if (asset == BASE_CURRENCY) {
            return BASE_CURRENCY_UNIT;
        } else if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            int256 price = source.latestAnswer();
            if (price > 0) {
                return uint256(price);
            } else {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    /// @inheritdoc IManekiOracle
    function getAssetsPrices(
        address[] calldata assets
    ) external view override returns (uint256[] memory) {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            prices[i] = getAssetPrice(assets[i]);
        }
        return prices;
    }

    /// @inheritdoc IManekiOracle
    function getSourceOfAsset(
        address asset
    ) external view override returns (address) {
        return address(assetsSources[asset]);
    }

    /// @inheritdoc IManekiOracle
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }

    function _onlyAssetListingOrPoolAdmins() internal view {
        IACLManager aclManager = IACLManager(
            ADDRESSES_PROVIDER.getACLManager()
        );
        require(
            aclManager.isAssetListingAdmin(msg.sender) ||
                aclManager.isPoolAdmin(msg.sender),
            Errors.CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN
        );
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