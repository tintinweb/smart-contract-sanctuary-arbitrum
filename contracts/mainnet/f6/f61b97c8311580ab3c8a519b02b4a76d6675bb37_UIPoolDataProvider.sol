// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IPoolAddressesProvider} from "@yldr-lending/core/src/interfaces/IPoolAddressesProvider.sol";
import {IPool} from "@yldr-lending/core/src/interfaces/IPool.sol";
import {IYLDROracle} from "@yldr-lending/core/src/interfaces/IYLDROracle.sol";
import {IYToken} from "@yldr-lending/core/src/interfaces/IYToken.sol";
import {IVariableDebtToken} from "@yldr-lending/core/src/interfaces/IVariableDebtToken.sol";
import {DefaultReserveInterestRateStrategy} from
    "@yldr-lending/core/src/protocol/pool/DefaultReserveInterestRateStrategy.sol";
import {YLDRProtocolDataProvider} from "@yldr-lending/core/src/misc/YLDRProtocolDataProvider.sol";
import {WadRayMath} from "@yldr-lending/core/src/protocol/libraries/math/WadRayMath.sol";
import {ReserveConfiguration} from "@yldr-lending/core/src/protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "@yldr-lending/core/src/protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "@yldr-lending/core/src/protocol/libraries/types/DataTypes.sol";
import {IUIPoolDataProvider} from "src/interfaces/IUIPoolDataProvider.sol";
import {IChainlinkAggregatorV3} from "src/interfaces/ext/IChainlinkAggregatorV3.sol";

contract UIPoolDataProvider is IUIPoolDataProvider {
    using WadRayMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    IChainlinkAggregatorV3 public immutable networkBaseTokenPriceInUsdProxyAggregator;

    constructor(IChainlinkAggregatorV3 _networkBaseTokenPriceInUsdProxyAggregator) {
        networkBaseTokenPriceInUsdProxyAggregator = _networkBaseTokenPriceInUsdProxyAggregator;
    }

    function getReservesList(IPoolAddressesProvider provider) public view override returns (address[] memory) {
        IPool pool = IPool(provider.getPool());
        return pool.getReservesList();
    }

    function getReservesData(IPoolAddressesProvider provider)
        public
        view
        override
        returns (AggregatedReserveData[] memory reservesData, BaseCurrencyInfo memory baseCurrencyInfo)
    {
        IYLDROracle oracle = IYLDROracle(provider.getPriceOracle());
        IPool pool = IPool(provider.getPool());
        YLDRProtocolDataProvider poolDataProvider = YLDRProtocolDataProvider(provider.getPoolDataProvider());

        address[] memory reserves = pool.getReservesList();
        reservesData = new AggregatedReserveData[](reserves.length);

        for (uint256 i = 0; i < reserves.length; i++) {
            AggregatedReserveData memory reserveData = reservesData[i];
            reserveData.underlyingAsset = reserves[i];

            // reserve current state
            DataTypes.ReserveData memory baseData = pool.getReserveData(reserveData.underlyingAsset);
            //the liquidity index. Expressed in ray
            reserveData.liquidityIndex = baseData.liquidityIndex;
            //variable borrow index. Expressed in ray
            reserveData.variableBorrowIndex = baseData.variableBorrowIndex;
            //the current supply rate. Expressed in ray
            reserveData.liquidityRate = baseData.currentLiquidityRate;
            //the current variable borrow rate. Expressed in ray
            reserveData.variableBorrowRate = baseData.currentVariableBorrowRate;
            //the current stable borrow rate. Expressed in ray
            reserveData.lastUpdateTimestamp = baseData.lastUpdateTimestamp;
            reserveData.yTokenAddress = baseData.yTokenAddress;
            reserveData.variableDebtTokenAddress = baseData.variableDebtTokenAddress;
            //address of the interest rate strategy
            reserveData.interestRateStrategyAddress = baseData.interestRateStrategyAddress;
            reserveData.priceInMarketReferenceCurrency = oracle.getAssetPrice(reserveData.underlyingAsset);
            reserveData.priceOracle = oracle.getSourceOfAsset(reserveData.underlyingAsset);
            reserveData.availableLiquidity =
                IERC20Metadata(reserveData.underlyingAsset).balanceOf(reserveData.yTokenAddress);
            reserveData.totalScaledVariableDebt =
                IVariableDebtToken(reserveData.variableDebtTokenAddress).scaledTotalSupply();

            reserveData.symbol = IERC20Metadata(reserveData.underlyingAsset).symbol();
            reserveData.name = IERC20Metadata(reserveData.underlyingAsset).name();

            //stores the reserve configuration
            DataTypes.ReserveConfigurationMap memory reserveConfigurationMap = baseData.configuration;
            (
                reserveData.baseLTVasCollateral,
                reserveData.reserveLiquidationThreshold,
                reserveData.reserveLiquidationBonus,
                reserveData.decimals,
                reserveData.reserveFactor
            ) = reserveConfigurationMap.getParams();
            reserveData.usageAsCollateralEnabled = reserveData.baseLTVasCollateral != 0;

            (reserveData.isActive, reserveData.isFrozen, reserveData.borrowingEnabled, reserveData.isPaused) =
                reserveConfigurationMap.getFlags();

            // interest rates
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).getVariableRateSlope1()
            returns (uint256 res) {
                reserveData.variableRateSlope1 = res;
            } catch {}
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).getVariableRateSlope2()
            returns (uint256 res) {
                reserveData.variableRateSlope2 = res;
            } catch {}
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).getBaseVariableBorrowRate()
            returns (uint256 res) {
                reserveData.baseVariableBorrowRate = res;
            } catch {}
            try DefaultReserveInterestRateStrategy(reserveData.interestRateStrategyAddress).OPTIMAL_USAGE_RATIO()
            returns (uint256 res) {
                reserveData.optimalUsageRatio = res;
            } catch {}

            (reserveData.borrowCap, reserveData.supplyCap) = reserveConfigurationMap.getCaps();

            try poolDataProvider.getFlashLoanEnabled(reserveData.underlyingAsset) returns (bool flashLoanEnabled) {
                reserveData.flashLoanEnabled = flashLoanEnabled;
            } catch (bytes memory) {
                reserveData.flashLoanEnabled = true;
            }

            reserveData.accruedToTreasury = baseData.accruedToTreasury;
        }

        (, baseCurrencyInfo.networkBaseTokenPriceInUsd,,,) = networkBaseTokenPriceInUsdProxyAggregator.latestRoundData();
        baseCurrencyInfo.networkBaseTokenPriceDecimals = networkBaseTokenPriceInUsdProxyAggregator.decimals();

        baseCurrencyInfo.marketReferenceCurrencyUnit = oracle.BASE_CURRENCY_UNIT();
        baseCurrencyInfo.marketReferenceCurrencyPriceInUsd = int256(baseCurrencyInfo.marketReferenceCurrencyUnit);
    }

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        override
        returns (UserReserveData[] memory userReservesData, UserERC1155ReserveData[] memory userERC1155ReservesData)
    {
        IPool pool = IPool(provider.getPool());
        address[] memory reserves = pool.getReservesList();
        DataTypes.UserConfigurationMap memory userConfig = pool.getUserConfiguration(user);

        userReservesData = new UserReserveData[](user != address(0) ? reserves.length : 0);

        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory baseData = pool.getReserveData(reserves[i]);

            // user reserve data
            userReservesData[i].underlyingAsset = reserves[i];
            userReservesData[i].scaledYTokenBalance = IYToken(baseData.yTokenAddress).scaledBalanceOf(user);
            userReservesData[i].usageAsCollateralEnabledOnUser = userConfig.isUsingAsCollateral(i);

            if (userConfig.isBorrowing(i)) {
                userReservesData[i].scaledVariableDebt =
                    IVariableDebtToken(baseData.variableDebtTokenAddress).scaledBalanceOf(user);
            }
        }

        DataTypes.ERC1155ReserveUsageData[] memory userUsedERC1155Reserves = pool.getUserUsedERC1155Reserves(user);
        userERC1155ReservesData = new UserERC1155ReserveData[](userUsedERC1155Reserves.length);

        for (uint256 i = 0; i < userUsedERC1155Reserves.length; i++) {
            DataTypes.ERC1155ReserveData memory reserveData =
                pool.getERC1155ReserveData(userUsedERC1155Reserves[i].asset);
            userERC1155ReservesData[i].asset = userUsedERC1155Reserves[i].asset;
            userERC1155ReservesData[i].tokenId = userUsedERC1155Reserves[i].tokenId;
            userERC1155ReservesData[i].balance =
                IERC1155(reserveData.nTokenAddress).balanceOf(user, userUsedERC1155Reserves[i].tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the value of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPoolAddressesProvider
 *
 * @notice Defines the basic interface for a Pool Addresses Provider.
 */
interface IPoolAddressesProvider {
    /**
     * @dev Emitted when the market identifier is updated.
     * @param oldMarketId The old id of the market
     * @param newMarketId The new id of the market
     */
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /**
     * @dev Emitted when the pool is updated.
     * @param newAddress The new address of the Pool
     */
    event PoolUpdated(address indexed newAddress);

    /**
     * @dev Emitted when the pool configurator is updated.
     * @param newAddress The new address of the PoolConfigurator
     */
    event PoolConfiguratorUpdated(address indexed newAddress);

    /**
     * @dev Emitted when the price oracle is updated.
     * @param oldAddress The old address of the PriceOracle
     * @param newAddress The new address of the PriceOracle
     */
    event PriceOracleUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL manager is updated.
     * @param oldAddress The old address of the ACLManager
     * @param newAddress The new address of the ACLManager
     */
    event ACLManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the ACL admin is updated.
     * @param oldAddress The old address of the ACLAdmin
     * @param newAddress The new address of the ACLAdmin
     */
    event ACLAdminUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the price oracle sentinel is updated.
     * @param oldAddress The old address of the PriceOracleSentinel
     * @param newAddress The new address of the PriceOracleSentinel
     */
    event PriceOracleSentinelUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the pool data provider is updated.
     * @param oldAddress The old address of the PoolDataProvider
     * @param newAddress The new address of the PoolDataProvider
     */
    event PoolDataProviderUpdated(address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when a new proxy is created.
     * @param id The identifier of the proxy
     * @param proxyAddress The address of the created proxy contract
     * @param implementationAddress The address of the implementation contract
     */
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /**
     * @dev Emitted when a new non-proxied contract address is registered.
     * @param id The identifier of the contract
     * @param oldAddress The address of the old contract
     * @param newAddress The address of the new contract
     */
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /**
     * @dev Emitted when the implementation of the proxy registered with id is updated
     * @param id The identifier of the contract
     * @param proxyAddress The address of the proxy contract
     * @param newImplementationAddress The address of the new implementation contract
     */
    event AddressSetAsProxy(bytes32 indexed id, address indexed proxyAddress, address indexed newImplementationAddress);

    /**
     * @notice Returns the id of the YLDR market to which this contract points to.
     * @return The market id
     */
    function getMarketId() external view returns (string memory);

    /**
     * @notice Associates an id with a specific PoolAddressesProvider.
     * @dev This can be used to create an onchain registry of PoolAddressesProviders to
     * identify and validate multiple YLDR markets.
     * @param newMarketId The market id
     */
    function setMarketId(string calldata newMarketId) external;

    /**
     * @notice Returns an address by its identifier.
     * @dev The returned address might be an EOA or a contract, potentially proxied
     * @dev It returns ZERO if there is no registered address with the given id
     * @param id The id
     * @return The address of the registered for the specified id
     */
    function getAddress(bytes32 id) external view returns (address);

    /**
     * @notice General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `newImplementationAddress`.
     * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param newImplementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external;

    /**
     * @notice Sets an address for an id replacing the address saved in the addresses map.
     * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external;

    /**
     * @notice Returns the address of the Pool proxy.
     * @return The Pool proxy address
     */
    function getPool() external view returns (address);

    /**
     * @notice Updates the implementation of the Pool, or creates a proxy
     * setting the new `pool` implementation when the function is called for the first time.
     * @param newPoolImpl The new Pool implementation
     */
    function setPoolImpl(address newPoolImpl) external;

    /**
     * @notice Returns the address of the PoolConfigurator proxy.
     * @return The PoolConfigurator proxy address
     */
    function getPoolConfigurator() external view returns (address);

    /**
     * @notice Updates the implementation of the PoolConfigurator, or creates a proxy
     * setting the new `PoolConfigurator` implementation when the function is called for the first time.
     * @param newPoolConfiguratorImpl The new PoolConfigurator implementation
     */
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl) external;

    /**
     * @notice Returns the address of the price oracle.
     * @return The address of the PriceOracle
     */
    function getPriceOracle() external view returns (address);

    /**
     * @notice Updates the address of the price oracle.
     * @param newPriceOracle The address of the new PriceOracle
     */
    function setPriceOracle(address newPriceOracle) external;

    /**
     * @notice Returns the address of the ACL manager.
     * @return The address of the ACLManager
     */
    function getACLManager() external view returns (address);

    /**
     * @notice Updates the address of the ACL manager.
     * @param newAclManager The address of the new ACLManager
     */
    function setACLManager(address newAclManager) external;

    /**
     * @notice Returns the address of the ACL admin.
     * @return The address of the ACL admin
     */
    function getACLAdmin() external view returns (address);

    /**
     * @notice Updates the address of the ACL admin.
     * @param newAclAdmin The address of the new ACL admin
     */
    function setACLAdmin(address newAclAdmin) external;

    /**
     * @notice Returns the address of the price oracle sentinel.
     * @return The address of the PriceOracleSentinel
     */
    function getPriceOracleSentinel() external view returns (address);

    /**
     * @notice Updates the address of the price oracle sentinel.
     * @param newPriceOracleSentinel The address of the new PriceOracleSentinel
     */
    function setPriceOracleSentinel(address newPriceOracleSentinel) external;

    /**
     * @notice Returns the address of the data provider.
     * @return The address of the DataProvider
     */
    function getPoolDataProvider() external view returns (address);

    /**
     * @notice Updates the address of the data provider.
     * @param newDataProvider The address of the new DataProvider
     */
    function setPoolDataProvider(address newDataProvider) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IPool
 *
 * @notice Defines the basic interface for an YLDR Pool.
 */
interface IPool {
    /**
     * @dev Emitted on supply()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the yTokens
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event Supply(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 amount, uint16 indexed referralCode
    );

    /**
     * @dev Emitted on supplyERC1155()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the supply
     * @param onBehalfOf The beneficiary of the supply, receiving the yTokens
     * @param tokenId The tokenId supplied
     * @param amount The amount supplied
     * @param referralCode The referral code used
     */
    event SupplyERC1155(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 tokenId,
        uint256 amount,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlying asset being withdrawn
     * @param user The address initiating the withdrawal, owner of yTokens
     * @param to The address that will receive the underlying
     * @param amount The amount to be withdrawn
     */
    event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

    /**
     * @dev Emitted on withdrawERC1155()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the withdrawal
     * @param onBehalfOf The beneficiary of the withdrawal, receiving the yTokens
     * @param tokenId The tokenId withdrawn
     * @param amount The amount withdrawn
     */
    event WithdrawERC1155(
        address indexed reserve, address user, address indexed onBehalfOf, uint256 tokenId, uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRate The numeric rate at which the user has borrowed, expressed in ray
     * @param referralCode The referral code used
     */
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     * @param useYTokens True if the repayment is done using yTokens, `false` if done with underlying asset directly
     */
    event Repay(
        address indexed reserve, address indexed user, address indexed repayer, uint256 amount, bool useYTokens
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     */
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseERC1155ReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param tokenId The tokenId of token being enabled as collateral
     * @param user The address of the user enabling the usage as collateral
     */
    event ERC1155ReserveUsedAsCollateralEnabled(address indexed reserve, uint256 indexed tokenId, address indexed user);

    /**
     * @dev Emitted on setUserUseERC1155ReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param tokenId The tokenId of token being disabled as collateral
     * @param user The address of the user disabling the usage as collateral
     */
    event ERC1155ReserveUsedAsCollateralDisabled(
        address indexed reserve, uint256 indexed tokenId, address indexed user
    );

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param openPosition Whether a new borrow position was opened
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     */
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        bool openPosition,
        uint256 premium,
        uint16 indexed referralCode
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveYToken True if the liquidators wants to receive the collateral yTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveYToken
    );

    /**
     * @dev Emitted when a borrower is liquidated.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param collateralTokenId The tokenId of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liquidator
     * @param liquidator The address of the liquidator
     * @param receiveNToken True if the liquidators wants to receive the collateral nTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    event ERC1155LiquidationCall(
        address indexed collateralAsset,
        uint256 collateralTokenId,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveNToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated.
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The next liquidity rate
     * @param variableBorrowRate The next variable borrow rate
     * @param liquidityIndex The next liquidity index
     * @param variableBorrowIndex The next variable borrow index
     */
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Emitted when the protocol treasury receives minted yTokens from the accrued interest.
     * @param reserve The address of the reserve
     * @param amountMinted The amount minted to the treasury
     */
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);

    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying yTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the yTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of yTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Supplies an `tokenId` of underlying asset into the reserve, receiving in return overlying nTokens.
     * @param asset The address of the underlying asset to supply
     * @param tokenId The tokenId to be supplied
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the nTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of nTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function supplyERC1155(address asset, uint256 tokenId, uint256 amount, address onBehalfOf, uint16 referralCode)
        external;

    /**
     * @notice Supply with transfer approval of asset to be supplied done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the yTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of yTokens
     *   is a different wallet
     * @param deadline The deadline timestamp that the permit is valid
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     */
    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent yTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole yToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Withdraws an `amount` of underlying asset with `tokenId` from the reserve, burning the equivalent nTokens owned
     * @param asset The address of the underlying asset to withdraw
     * @param tokenId The tokenId to be withdrawn
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole nToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     */
    function withdrawERC1155(address asset, uint256 tokenId, uint256 amount, address to) external returns (uint256);

    /**
     * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 variable debt tokens
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     */
    function borrow(address asset, uint256 amount, uint16 referralCode, address onBehalfOf) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     */
    function repay(address asset, uint256 amount, address onBehalfOf) external returns (uint256);

    /**
     * @notice Repay with transfer approval of asset to be repaid done via permit function
     * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @param deadline The deadline timestamp that the permit is valid
     * @param permitV The V parameter of ERC712 permit sig
     * @param permitR The R parameter of ERC712 permit sig
     * @param permitS The S parameter of ERC712 permit sig
     * @return The final amount repaid
     */
    function repayWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    /**
     * @notice Repays a borrowed `amount` on a specific reserve using the reserve yTokens, burning the
     * equivalent debt tokens
     * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 debt tokens
     * @dev  Passing uint256.max as amount will clean up any residual yToken dust balance, if the user yToken
     * balance is not enough to cover the whole debt
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @return The final amount repaid
     */
    function repayWithYTokens(address asset, uint256 amount) external returns (uint256);

    /**
     * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
     * @param asset The address of the underlying asset supplied
     * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
     */
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveYToken True if the liquidators wants to receive the collateral yTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveYToken
    ) external;

    /**
     * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param collateralTokenId The tokenId of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveNToken True if the liquidators wants to receive the collateral nTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     */
    function erc1155LiquidationCall(
        address collateralAsset,
        uint256 collateralTokenId,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveNToken
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts of the assets being flash-borrowed
     * @param createPosition Array of boolean values:
     *   false -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   true -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        bool[] calldata createPosition,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept
     * into consideration.
     * @param receiverAddress The address of the contract receiving the funds, implementing IFlashLoanSimpleReceiver interface
     * @param asset The address of the asset being flash-borrowed
     * @param amount The amount of the asset being flash-borrowed
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     */
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @notice Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
     * @return totalDebtBase The total debt of the user in the base currency used by the price feed
     * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
     * @return currentLiquidationThreshold The liquidation threshold of the user
     * @return ltv The loan to value of The user
     * @return healthFactor The current health factor of the user
     */
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    /**
     * @notice Initializes a reserve, activating it, assigning an yToken and debt token and an
     * interest rate strategy
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param yTokenAddress The address of the yToken that will be assigned to the reserve
     * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
     * @param interestRateStrategyAddress The address of the interest rate strategy contract
     */
    function initReserve(
        address asset,
        address yTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @notice Initializes a reserve, activating it, assigning an nToken and configuration provider
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param nTokenAddress The address of the nToken that will be assigned to the reserve
     * @param configurationProvider The address of the provider of configuration for the reserve
     */
    function initERC1155Reserve(address asset, address nTokenAddress, address configurationProvider) external;

    /**
     * @notice Drop a reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserve(address asset) external;

    /**
     * @notice Drop a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     */
    function dropERC1155Reserve(address asset) external;

    /**
     * @notice Updates the address of the interest rate strategy contract
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The address of the interest rate strategy contract
     */
    function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress) external;

    /**
     * @notice Updates the address of the configuration provider for a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configurationProvider The address of the new configuration provider
     */
    function setERC1155ReserveConfigurationProvider(address asset, address configurationProvider) external;

    /**
     * @notice Updates the liquidation protocol fee for a ERC1155 reserve
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param liquidationProtocolFee New liquidation protocol fee
     */
    function setERC1155ReserveLiquidationProtocolFee(address asset, uint256 liquidationProtocolFee) external;

    /**
     * @notice Sets the configuration bitmap of the reserve as a whole
     * @dev Only callable by the PoolConfigurator contract
     * @param asset The address of the underlying asset of the reserve
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(address asset, DataTypes.ReserveConfigurationMap calldata configuration) external;

    /**
     * @notice Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @notice Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     */
    function getUserConfiguration(address user) external view returns (DataTypes.UserConfigurationMap memory);

    /**
     * @notice Returns the list of ERC1155 reserves used by a user
     * @param user The user address
     * @return The list of ERC1155 reserves used as a collateral by a user
     */
    function getUserUsedERC1155Reserves(address user)
        external
        view
        returns (DataTypes.ERC1155ReserveUsageData[] memory);

    /**
     * @notice Returns the normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @notice Returns the normalized variable debt per unit of asset
     * @dev WARNING: This function is intended to be used primarily by the protocol itself to get a
     * "dynamic" variable index based on time, current stored index and virtual rate at the current
     * moment (approx. a borrower would get if opening a position). This means that is always used in
     * combination with variable debt supply/balances.
     * If using this function externally, consider that is possible to have an increasing normalized
     * variable debt that is not equivalent to how the variable debt index would be updated in storage
     * (e.g. only updates with non-zero variable debt supply)
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @notice Returns the state and configuration of the ERC1155 reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     */
    function getERC1155ReserveData(address asset) external view returns (DataTypes.ERC1155ReserveData memory);

    /**
     * @notice Validates and finalizes an yToken transfer
     * @dev Only callable by the overlying yToken of the `asset`
     * @param asset The address of the underlying asset of the yToken
     * @param from The user from which the yTokens are transferred
     * @param to The user receiving the yTokens
     * @param amount The amount being transferred/withdrawn
     * @param balanceFromBefore The yToken balance of the `from` user before the transfer
     * @param balanceToBefore The yToken balance of the `to` user before the transfer
     */
    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    /**
     * @notice Validates and finalizes an nToken transfer
     * @dev Only callable by the overlying nToken of the `asset`
     * @param asset The address of the underlying asset of the nToken
     * @param from The user from which the nToken are transferred
     * @param to The user receiving the nToken
     * @param ids The ids of tokens being transferred/withdrawn
     * @param amounts The amounts being transferred/withdrawn
     */
    function finalizeERC1155Transfer(
        address asset,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Returns the list of the underlying assets of all the initialized reserves
     * @dev It does not include dropped reserves
     * @return The addresses of the underlying assets of the initialized reserves
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @notice Returns the address of the underlying asset of a reserve by the reserve id as stored in the DataTypes.ReserveData struct
     * @param id The id of the reserve as stored in the DataTypes.ReserveData struct
     * @return The address of the reserve associated with id
     */
    function getReserveAddressById(uint16 id) external view returns (address);

    /**
     * @notice Returns the PoolAddressesProvider connected to this contract
     * @return The address of the PoolAddressesProvider
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Updates flash loan premiums. Flash loan premium consists of two parts:
     * - A part is sent to yToken holders as extra, one time accumulated interest
     * - A part is collected by the protocol treasury
     * @dev The total premium is calculated on the total borrowed amount
     * @dev The premium to protocol is calculated on the total premium, being a percentage of `flashLoanPremiumTotal`
     * @dev Only callable by the PoolConfigurator contract
     * @param flashLoanPremiumTotal The total premium, expressed in bps
     * @param flashLoanPremiumToProtocol The part of the premium sent to the protocol treasury, expressed in bps
     */
    function updateFlashloanPremiums(uint128 flashLoanPremiumTotal, uint128 flashLoanPremiumToProtocol) external;

    /**
     * @notice Updates max amount of ERC1155 collaterals user may have.
     * @dev Only callable by the PoolConfigurator contract
     * @param maxERC1155CollateralReservesNumber The new value
     */
    function updateMaxERC1155CollateralReserves(uint256 maxERC1155CollateralReservesNumber) external;

    /**
     * @notice Returns the total fee on flash loans
     * @return The total fee on flashloans
     */
    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    /**
     * @notice Returns the part of the flashloan fees sent to protocol
     * @return The flashloan fee sent to the protocol treasury
     */
    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    /**
     * @notice Returns the maximum number of reserves supported to be listed in this Pool
     * @return The maximum number of reserves supported
     */
    function MAX_NUMBER_RESERVES() external view returns (uint16);

    /**
     * @notice Returns the maximum number of ERC1155 collateral reserves which can be used by a single user
     * @return The maximum number of ERC1155 collateral reserves supported
     */
    function MAX_ERC1155_COLLATERAL_RESERVES() external view returns (uint256);

    /**
     * @notice Mints the assets accrued through the reserve factor to the treasury in the form of yTokens
     * @param assets The list of reserves for which the minting needs to be executed
     */
    function mintToTreasury(address[] calldata assets) external;

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPriceOracleGetter} from "./IPriceOracleGetter.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IYLDROracle
 *
 * @notice Defines the basic interface for the YLDR Oracle
 */
interface IYLDROracle is IPriceOracleGetter {
    /**
     * @dev Emitted after the base currency is set
     * @param baseCurrency The base currency of used for price quotes
     * @param baseCurrencyUnit The unit of the base currency
     */
    event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

    /**
     * @dev Emitted after the price source of an asset is updated
     * @param asset The address of the asset
     * @param source The price source of the asset
     */
    event AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the price source of an ERC1155 asset is updated
     * @param asset The address of the asset
     * @param source The price source of the asset
     */
    event ERC1155AssetSourceUpdated(address indexed asset, address indexed source);

    /**
     * @dev Emitted after the address of fallback oracle is updated
     * @param fallbackOracle The address of the fallback oracle
     */
    event FallbackOracleUpdated(address indexed fallbackOracle);

    /**
     * @notice Returns the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(address[] calldata assets, address[] calldata sources) external;

    /**
     * @notice Sets or replaces price sources of ERC1155 assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setERC1155AssetSources(address[] calldata assets, address[] calldata sources) external;

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
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

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
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableYToken} from "./IInitializableYToken.sol";

/**
 * @title IYToken
 *
 * @notice Defines the basic interface for an YToken.
 */
interface IYToken is IERC20, IScaledBalanceToken, IInitializableYToken {
    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The scaled amount being transferred
     * @param index The next liquidity index of the reserve
     */
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @notice Mints `amount` yTokens to `user`
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted yTokens
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address caller, address onBehalfOf, uint256 amount, uint256 index) external returns (bool);

    /**
     * @notice Burns yTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @dev In some instances, the mint event could be emitted from a burn transaction
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the yTokens will be burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The next liquidity index of the reserve
     */
    function burn(address from, address receiverOfUnderlying, uint256 amount, uint256 index) external;

    /**
     * @notice Mints yTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The next liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @notice Transfers yTokens in the event of a borrow being liquidated, in case the liquidators reclaims the yToken
     * @param from The address getting liquidated, current owner of the yTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     */
    function transferOnLiquidation(address from, address to, uint256 value) external;

    /**
     * @notice Transfers the underlying asset to `target`.
     * @dev Used by the Pool to transfer assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the underlying
     * @param amount The amount getting transferred
     */
    function transferUnderlyingTo(address target, uint256 amount) external;

    /**
     * @notice Handles the underlying received by the yToken after the transfer has been completed.
     * @dev The default implementation is empty as with standard ERC20 tokens, nothing needs to be done after the
     * transfer is concluded. However in the future there may be yTokens that allow for example to stake the underlying
     * to receive LM rewards. In that case, `handleRepayment()` would perform the staking of the underlying asset.
     * @param user The user executing the repayment
     * @param onBehalfOf The address of the user who will get his debt reduced/removed
     * @param amount The amount getting repaid
     */
    function handleRepayment(address user, address onBehalfOf, uint256 amount) external;

    /**
     * @notice Allow passing a signed message to approve spending
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    /**
     * @notice Returns the address of the underlying asset of this yToken (E.g. WETH for aWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    /**
     * @notice Returns the address of the YLDR treasury, receiving the fees on this yToken.
     * @return Address of the YLDR treasury
     */
    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    /**
     * @notice Get the domain separator for the token
     * @dev Return cached value if chainId matches cache, otherwise recomputes separator
     * @return The domain separator of the token at current chain
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Returns the nonce for owner.
     * @param owner The address of the owner
     * @return The nonce of the owner
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(address token, address to, uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";
import {IInitializableDebtToken} from "./IInitializableDebtToken.sol";

/**
 * @title IVariableDebtToken
 *
 * @notice Defines the basic interface for a variable debt token.
 */
interface IVariableDebtToken is IScaledBalanceToken, IInitializableDebtToken {
    /**
     * @notice Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return True if the previous balance of the user is 0, false otherwise
     * @return The scaled total debt of the reserve
     */
    function mint(address user, address onBehalfOf, uint256 amount, uint256 index) external returns (bool, uint256);

    /**
     * @notice Burns user variable debt
     * @dev In some instances, a burn transaction will emit a mint event
     * if the amount to burn is less than the interest that the user accrued
     * @param from The address from which the debt will be burned
     * @param amount The amount getting burned
     * @param index The variable debt index of the reserve
     * @return The scaled total debt of the reserve
     */
    function burn(address from, uint256 amount, uint256 index) external returns (uint256);

    /**
     * @notice Returns the address of the underlying asset of this debtToken (E.g. WETH for variableDebtWETH)
     * @return The address of the underlying asset
     */
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {IDefaultInterestRateStrategy} from "../../interfaces/IDefaultInterestRateStrategy.sol";
import {IReserveInterestRateStrategy} from "../../interfaces/IReserveInterestRateStrategy.sol";
import {IPoolAddressesProvider} from "../../interfaces/IPoolAddressesProvider.sol";

/**
 * @title DefaultReserveInterestRateStrategy contract
 *
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_USAGE_RATIO`
 * point of usage and another from that one to 100%.
 * - An instance of this same contract, can't be used across different YLDR markets, due to the caching
 *   of the PoolAddressesProvider
 */
contract DefaultReserveInterestRateStrategy is IDefaultInterestRateStrategy {
    using WadRayMath for uint256;
    using PercentageMath for uint256;

    /// @inheritdoc IDefaultInterestRateStrategy
    uint256 public immutable OPTIMAL_USAGE_RATIO;

    /// @inheritdoc IDefaultInterestRateStrategy
    uint256 public immutable MAX_EXCESS_USAGE_RATIO;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    // Base variable borrow rate when usage rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when usage ratio > OPTIMAL_USAGE_RATIO. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    /**
     * @dev Constructor.
     * @param provider The address of the PoolAddressesProvider contract
     * @param optimalUsageRatio The optimal usage ratio
     * @param baseVariableBorrowRate The base variable borrow rate
     * @param variableRateSlope1 The variable rate slope below optimal usage ratio
     * @param variableRateSlope2 The variable rate slope above optimal usage ratio
     */
    constructor(
        IPoolAddressesProvider provider,
        uint256 optimalUsageRatio,
        uint256 baseVariableBorrowRate,
        uint256 variableRateSlope1,
        uint256 variableRateSlope2
    ) {
        require(WadRayMath.RAY >= optimalUsageRatio, Errors.INVALID_OPTIMAL_USAGE_RATIO);
        OPTIMAL_USAGE_RATIO = optimalUsageRatio;
        MAX_EXCESS_USAGE_RATIO = WadRayMath.RAY - optimalUsageRatio;
        ADDRESSES_PROVIDER = provider;
        _baseVariableBorrowRate = baseVariableBorrowRate;
        _variableRateSlope1 = variableRateSlope1;
        _variableRateSlope2 = variableRateSlope2;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getVariableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getVariableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getBaseVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate;
    }

    /// @inheritdoc IDefaultInterestRateStrategy
    function getMaxVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate + _variableRateSlope1 + _variableRateSlope2;
    }

    struct CalcInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 borrowUsageRatio;
        uint256 supplyUsageRatio;
        uint256 availableLiquidityPlusDebt;
    }

    /// @inheritdoc IReserveInterestRateStrategy
    function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
        public
        view
        override
        returns (uint256, uint256)
    {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = params.totalVariableDebt;

        vars.currentLiquidityRate = 0;
        vars.currentVariableBorrowRate = _baseVariableBorrowRate;

        if (vars.totalDebt != 0) {
            vars.availableLiquidity =
                IERC20(params.reserve).balanceOf(params.yToken) + params.liquidityAdded - params.liquidityTaken;

            vars.availableLiquidityPlusDebt = vars.availableLiquidity + vars.totalDebt;
            vars.borrowUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
            vars.supplyUsageRatio = vars.totalDebt.rayDiv(vars.availableLiquidityPlusDebt);
        }

        if (vars.borrowUsageRatio > OPTIMAL_USAGE_RATIO) {
            uint256 excessBorrowUsageRatio =
                (vars.borrowUsageRatio - OPTIMAL_USAGE_RATIO).rayDiv(MAX_EXCESS_USAGE_RATIO);

            vars.currentVariableBorrowRate += _variableRateSlope1 + _variableRateSlope2.rayMul(excessBorrowUsageRatio);
        } else {
            vars.currentVariableBorrowRate +=
                _variableRateSlope1.rayMul(vars.borrowUsageRatio).rayDiv(OPTIMAL_USAGE_RATIO);
        }

        vars.currentLiquidityRate = _getOverallBorrowRate(params.totalVariableDebt, vars.currentVariableBorrowRate)
            .rayMul(vars.supplyUsageRatio).percentMul(PercentageMath.PERCENTAGE_FACTOR - params.reserveFactor);

        return (vars.currentLiquidityRate, vars.currentVariableBorrowRate);
    }

    /**
     * @dev Calculates the overall borrow rate as the weighted average between the total variable debt and total stable
     * debt
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param currentVariableBorrowRate The current variable borrow rate of the reserve
     * @return The weighted averaged borrow rate
     */
    function _getOverallBorrowRate(uint256 totalVariableDebt, uint256 currentVariableBorrowRate)
        internal
        pure
        returns (uint256)
    {
        if (totalVariableDebt == 0) return 0;

        return currentVariableBorrowRate;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.10;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ReserveConfiguration} from "../protocol/libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../protocol/libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";
import {WadRayMath} from "../protocol/libraries/math/WadRayMath.sol";
import {IPoolAddressesProvider} from "../interfaces/IPoolAddressesProvider.sol";
import {IVariableDebtToken} from "../interfaces/IVariableDebtToken.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IPoolDataProvider} from "../interfaces/IPoolDataProvider.sol";

/**
 * @title YLDRProtocolDataProvider
 *
 * @notice Peripheral contract to collect and pre-process information from the Pool.
 */
contract YLDRProtocolDataProvider is IPoolDataProvider {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    address constant MKR = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @inheritdoc IPoolDataProvider
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /**
     * @notice Constructor
     * @param addressesProvider The address of the PoolAddressesProvider contract
     */
    constructor(IPoolAddressesProvider addressesProvider) {
        ADDRESSES_PROVIDER = addressesProvider;
    }

    /// @inheritdoc IPoolDataProvider
    function getAllReservesTokens() external view override returns (TokenData[] memory) {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        TokenData[] memory reservesTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            if (reserves[i] == MKR) {
                reservesTokens[i] = TokenData({symbol: "MKR", tokenAddress: reserves[i]});
                continue;
            }
            if (reserves[i] == ETH) {
                reservesTokens[i] = TokenData({symbol: "ETH", tokenAddress: reserves[i]});
                continue;
            }
            reservesTokens[i] = TokenData({symbol: IERC20Metadata(reserves[i]).symbol(), tokenAddress: reserves[i]});
        }
        return reservesTokens;
    }

    /// @inheritdoc IPoolDataProvider
    function getAllYTokens() external view override returns (TokenData[] memory) {
        IPool pool = IPool(ADDRESSES_PROVIDER.getPool());
        address[] memory reserves = pool.getReservesList();
        TokenData[] memory yTokens = new TokenData[](reserves.length);
        for (uint256 i = 0; i < reserves.length; i++) {
            DataTypes.ReserveData memory reserveData = pool.getReserveData(reserves[i]);
            yTokens[i] = TokenData({
                symbol: IERC20Metadata(reserveData.yTokenAddress).symbol(),
                tokenAddress: reserveData.yTokenAddress
            });
        }
        return yTokens;
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveConfigurationData(address asset)
        external
        view
        override
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool isActive,
            bool isFrozen
        )
    {
        DataTypes.ReserveConfigurationMap memory configuration =
            IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset);

        (ltv, liquidationThreshold, liquidationBonus, decimals, reserveFactor) = configuration.getParams();

        (isActive, isFrozen, borrowingEnabled,) = configuration.getFlags();

        usageAsCollateralEnabled = liquidationThreshold != 0;
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveCaps(address asset) external view override returns (uint256 borrowCap, uint256 supplyCap) {
        (borrowCap, supplyCap) = IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getCaps();
    }

    /// @inheritdoc IPoolDataProvider
    function getPaused(address asset) external view override returns (bool isPaused) {
        (,,, isPaused) = IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getFlags();
    }

    /// @inheritdoc IPoolDataProvider
    function getLiquidationProtocolFee(address asset) external view override returns (uint256) {
        return IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset).getLiquidationProtocolFee();
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalYToken,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        )
    {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        return (
            reserve.accruedToTreasury,
            IERC20Metadata(reserve.yTokenAddress).totalSupply(),
            IERC20Metadata(reserve.variableDebtTokenAddress).totalSupply(),
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.lastUpdateTimestamp
        );
    }

    /// @inheritdoc IPoolDataProvider
    function getYTokenTotalSupply(address asset) external view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);
        return IERC20Metadata(reserve.yTokenAddress).totalSupply();
    }

    /// @inheritdoc IPoolDataProvider
    function getTotalDebt(address asset) external view override returns (uint256) {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);
        return IERC20Metadata(reserve.variableDebtTokenAddress).totalSupply();
    }

    /// @inheritdoc IPoolDataProvider
    function getUserReserveData(address asset, address user)
        external
        view
        override
        returns (
            uint256 currentYTokenBalance,
            uint256 currentVariableDebt,
            uint256 scaledVariableDebt,
            uint256 liquidityRate,
            bool usageAsCollateralEnabled
        )
    {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        DataTypes.UserConfigurationMap memory userConfig =
            IPool(ADDRESSES_PROVIDER.getPool()).getUserConfiguration(user);

        currentYTokenBalance = IERC20Metadata(reserve.yTokenAddress).balanceOf(user);
        currentVariableDebt = IERC20Metadata(reserve.variableDebtTokenAddress).balanceOf(user);
        scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledBalanceOf(user);
        liquidityRate = reserve.currentLiquidityRate;
        usageAsCollateralEnabled = userConfig.isUsingAsCollateral(reserve.id);
    }

    /// @inheritdoc IPoolDataProvider
    function getReserveTokensAddresses(address asset)
        external
        view
        override
        returns (address yTokenAddress, address variableDebtTokenAddress)
    {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        return (reserve.yTokenAddress, reserve.variableDebtTokenAddress);
    }

    /// @inheritdoc IPoolDataProvider
    function getInterestRateStrategyAddress(address asset) external view override returns (address irStrategyAddress) {
        DataTypes.ReserveData memory reserve = IPool(ADDRESSES_PROVIDER.getPool()).getReserveData(asset);

        return (reserve.interestRateStrategyAddress);
    }

    /// @inheritdoc IPoolDataProvider
    function getFlashLoanEnabled(address asset) external view override returns (bool) {
        DataTypes.ReserveConfigurationMap memory configuration =
            IPool(ADDRESSES_PROVIDER.getPool()).getConfiguration(asset);

        return configuration.getFlashLoanEnabled();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 *
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library WadRayMath {
    // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a*b, in wad
     */
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_WAD), WAD)
        }
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @param b Wad
     * @return c = a/b, in wad
     */
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) { revert(0, 0) }

            c := div(add(mul(a, WAD), div(b, 2)), b)
        }
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raymul b
     */
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
        assembly {
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) { revert(0, 0) }

            c := div(add(mul(a, b), HALF_RAY), RAY)
        }
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @param b Ray
     * @return c = a raydiv b
     */
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
        assembly {
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) { revert(0, 0) }

            c := div(add(mul(a, RAY), div(b, 2)), b)
        }
    }

    /**
     * @dev Casts ray down to wad
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Ray
     * @return b = a converted to wad, rounded half up to the nearest wad
     */
    function rayToWad(uint256 a) internal pure returns (uint256 b) {
        assembly {
            b := div(a, WAD_RAY_RATIO)
            let remainder := mod(a, WAD_RAY_RATIO)
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) { b := add(b, 1) }
        }
    }

    /**
     * @dev Converts wad up to ray
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param a Wad
     * @return b = a converted in ray
     */
    function wadToRay(uint256 a) internal pure returns (uint256 b) {
        // to avoid overflow, b/WAD_RAY_RATIO == a
        assembly {
            b := mul(a, WAD_RAY_RATIO)

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) { revert(0, 0) }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveConfiguration library
 *
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 internal constant LTV_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 internal constant LIQUIDATION_THRESHOLD_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_BONUS_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 internal constant DECIMALS_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant ACTIVE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FROZEN_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWING_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant PAUSED_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROWABLE_IN_ISOLATION_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant FLASHLOAN_ENABLED_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant RESERVE_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant BORROW_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant SUPPLY_CAP_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_MASK =
        0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
    uint256 internal constant DEBT_CEILING_MASK = 0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 internal constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 internal constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 internal constant IS_PAUSED_START_BIT_POSITION = 60;
    uint256 internal constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
    uint256 internal constant FLASHLOAN_ENABLED_START_BIT_POSITION = 63;
    uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;
    uint256 internal constant BORROW_CAP_START_BIT_POSITION = 80;
    uint256 internal constant SUPPLY_CAP_START_BIT_POSITION = 116;
    uint256 internal constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
    uint256 internal constant DEBT_CEILING_START_BIT_POSITION = 212;

    uint256 internal constant MAX_VALID_LTV = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 internal constant MAX_VALID_DECIMALS = 255;
    uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;
    uint256 internal constant MAX_VALID_BORROW_CAP = 68719476735;
    uint256 internal constant MAX_VALID_SUPPLY_CAP = 68719476735;
    uint256 internal constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 65535;
    uint256 internal constant MAX_VALID_DEBT_CEILING = 1099511627775;

    uint256 public constant DEBT_CEILING_DECIMALS = 2;
    uint16 public constant MAX_RESERVES_COUNT = 128;

    /**
     * @notice Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv The new ltv
     */
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
        require(ltv <= MAX_VALID_LTV, Errors.INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @notice Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     */
    function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return self.data & ~LTV_MASK;
    }

    /**
     * @notice Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     */
    function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold) internal pure {
        require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.INVALID_LIQ_THRESHOLD);

        self.data = (self.data & LIQUIDATION_THRESHOLD_MASK) | (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     */
    function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     */
    function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus) internal pure {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.INVALID_LIQ_BONUS);

        self.data = (self.data & LIQUIDATION_BONUS_MASK) | (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     */
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     */
    function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals) internal pure {
        require(decimals <= MAX_VALID_DECIMALS, Errors.INVALID_DECIMALS);

        self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @notice Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     */
    function getDecimals(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @notice Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     */
    function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
        self.data = (self.data & ACTIVE_MASK) | (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @notice Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     */
    function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @notice Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     */
    function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
        self.data = (self.data & FROZEN_MASK) | (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @notice Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     */
    function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @notice Sets the paused state of the reserve
     * @param self The reserve configuration
     * @param paused The paused state
     */
    function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
        self.data = (self.data & PAUSED_MASK) | (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the paused state of the reserve
     * @param self The reserve configuration
     * @return The paused state
     */
    function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~PAUSED_MASK) != 0;
    }

    /**
     * @notice Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     */
    function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled) internal pure {
        self.data = (self.data & BORROWING_MASK) | (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     */
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @notice Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     */
    function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor) internal pure {
        require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.INVALID_RESERVE_FACTOR);

        self.data = (self.data & RESERVE_FACTOR_MASK) | (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @notice Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     */
    function getReserveFactor(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @notice Sets the borrow cap of the reserve
     * @param self The reserve configuration
     * @param borrowCap The borrow cap
     */
    function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap) internal pure {
        require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.INVALID_BORROW_CAP);

        self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the borrow cap of the reserve
     * @param self The reserve configuration
     * @return The borrow cap
     */
    function getBorrowCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the supply cap of the reserve
     * @param self The reserve configuration
     * @param supplyCap The supply cap
     */
    function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap) internal pure {
        require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.INVALID_SUPPLY_CAP);

        self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
    }

    /**
     * @notice Gets the supply cap of the reserve
     * @param self The reserve configuration
     * @return The supply cap
     */
    function getSupplyCap(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
    }

    /**
     * @notice Sets the liquidation protocol fee of the reserve
     * @param self The reserve configuration
     * @param liquidationProtocolFee The liquidation protocol fee
     */
    function setLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self, uint256 liquidationProtocolFee)
        internal
        pure
    {
        require(liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE, Errors.INVALID_LIQUIDATION_PROTOCOL_FEE);

        self.data = (self.data & LIQUIDATION_PROTOCOL_FEE_MASK)
            | (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation protocol fee
     * @param self The reserve configuration
     * @return The liquidation protocol fee
     */
    function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
        return (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
    }

    /**
     * @notice Sets the flashloanable flag for the reserve
     * @param self The reserve configuration
     * @param flashLoanEnabled True if the asset is flashloanable, false otherwise
     */
    function setFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self, bool flashLoanEnabled) internal pure {
        self.data = (self.data & FLASHLOAN_ENABLED_MASK)
            | (uint256(flashLoanEnabled ? 1 : 0) << FLASHLOAN_ENABLED_START_BIT_POSITION);
    }

    /**
     * @notice Gets the flashloanable flag for the reserve
     * @param self The reserve configuration
     * @return The flashloanable flag
     */
    function getFlashLoanEnabled(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~FLASHLOAN_ENABLED_MASK) != 0;
    }

    /**
     * @notice Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flag representing active
     * @return The state flag representing frozen
     * @return The state flag representing borrowing enabled
     * @return The state flag representing paused
     */
    function getFlags(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool, bool, bool, bool) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~PAUSED_MASK) != 0
        );
    }

    /**
     * @notice Gets the configuration parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing ltv
     * @return The state param representing liquidation threshold
     * @return The state param representing liquidation bonus
     * @return The state param representing reserve decimals
     * @return The state param representing reserve factor
     */
    function getParams(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (uint256, uint256, uint256, uint256, uint256)
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @notice Gets the caps parameters of the reserve from storage
     * @param self The reserve configuration
     * @return The state param representing borrow cap
     * @return The state param representing supply cap.
     */
    function getCaps(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256, uint256) {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
            (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ReserveConfiguration} from "./ReserveConfiguration.sol";

/**
 * @title UserConfiguration library
 *
 * @notice Implements the bitmap logic to handle the user configuration
 */
library UserConfiguration {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    uint256 internal constant BORROWING_MASK = 0x5555555555555555555555555555555555555555555555555555555555555555;
    uint256 internal constant COLLATERAL_MASK = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;

    /**
     * @notice Sets if the user is borrowing the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param borrowing True if the user is borrowing the reserve, false otherwise
     */
    function setBorrowing(DataTypes.UserConfigurationMap storage self, uint256 reserveIndex, bool borrowing) internal {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            uint256 bit = 1 << (reserveIndex << 1);
            if (borrowing) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Sets if the user is using as collateral the reserve identified by reserveIndex
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @param usingAsCollateral True if the user is using the reserve as collateral, false otherwise
     */
    function setUsingAsCollateral(
        DataTypes.UserConfigurationMap storage self,
        uint256 reserveIndex,
        bool usingAsCollateral
    ) internal {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            uint256 bit = 1 << ((reserveIndex << 1) + 1);
            if (usingAsCollateral) {
                self.data |= bit;
            } else {
                self.data &= ~bit;
            }
        }
    }

    /**
     * @notice Returns if a user has been using the reserve for borrowing or as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing or as collateral, false otherwise
     */
    function isUsingAsCollateralOrBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
        internal
        pure
        returns (bool)
    {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            return (self.data >> (reserveIndex << 1)) & 3 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve for borrowing
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve for borrowing, false otherwise
     */
    function isBorrowing(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
        internal
        pure
        returns (bool)
    {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            return (self.data >> (reserveIndex << 1)) & 1 != 0;
        }
    }

    /**
     * @notice Validate a user has been using the reserve as collateral
     * @param self The configuration object
     * @param reserveIndex The index of the reserve in the bitmap
     * @return True if the user has been using a reserve as collateral, false otherwise
     */
    function isUsingAsCollateral(DataTypes.UserConfigurationMap memory self, uint256 reserveIndex)
        internal
        pure
        returns (bool)
    {
        unchecked {
            require(reserveIndex < ReserveConfiguration.MAX_RESERVES_COUNT, Errors.INVALID_RESERVE_INDEX);
            return (self.data >> ((reserveIndex << 1) + 1)) & 1 != 0;
        }
    }

    /**
     * @notice Checks if a user has been supplying only one reserve as collateral
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     */
    function isUsingAsCollateralOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        uint256 collateralData = self.data & COLLATERAL_MASK;
        return collateralData != 0 && (collateralData & (collateralData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been supplying any reserve as collateral
     * @param self The configuration object
     * @return True if the user has been supplying as collateral any reserve, false otherwise
     */
    function isUsingAsCollateralAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        return self.data & COLLATERAL_MASK != 0;
    }

    /**
     * @notice Checks if a user has been borrowing only one asset
     * @dev this uses a simple trick - if a number is a power of two (only one bit set) then n & (n - 1) == 0
     * @param self The configuration object
     * @return True if the user has been supplying as collateral one reserve, false otherwise
     */
    function isBorrowingOne(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        uint256 borrowingData = self.data & BORROWING_MASK;
        return borrowingData != 0 && (borrowingData & (borrowingData - 1) == 0);
    }

    /**
     * @notice Checks if a user has been borrowing from any reserve
     * @param self The configuration object
     * @return True if the user has been borrowing any reserve, false otherwise
     */
    function isBorrowingAny(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        return self.data & BORROWING_MASK != 0;
    }

    /**
     * @notice Checks if a user has not been using any reserve for borrowing or supply
     * @param self The configuration object
     * @return True if the user has not been borrowing or supplying any reserve, false otherwise
     */
    function isEmpty(DataTypes.UserConfigurationMap memory self) internal pure returns (bool) {
        return self.data == 0;
    }

    /**
     * @notice Returns the address of the first asset flagged in the bitmap given the corresponding bitmask
     * @param self The configuration object
     * @return The index of the first asset flagged in the bitmap once the corresponding mask is applied
     */
    function _getFirstAssetIdByMask(DataTypes.UserConfigurationMap memory self, uint256 mask)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 bitmapData = self.data & mask;
            uint256 firstAssetPosition = bitmapData & ~(bitmapData - 1);
            uint256 id;

            while ((firstAssetPosition >>= 2) != 0) {
                id += 1;
            }
            return id;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library DataTypes {
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //timestamp of last update
        uint40 lastUpdateTimestamp;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint16 id;
        //yToken address
        address yTokenAddress;
        //variableDebtToken address
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the current treasury balance, scaled
        uint128 accruedToTreasury;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60: asset is paused
        //bit 61: borrowing in isolation mode is enabled
        //bit 62: siloed borrowing enabled
        //bit 63: flashloaning enabled
        //bit 64-79: reserve factor
        //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
        //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
        //bit 152-167 liquidation protocol fee
        //bit 168-175 eMode category
        //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
        //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
        //bit 252-255 unused
        uint256 data;
    }

    struct ERC1155ReserveData {
        address nTokenAddress;
        address configurationProvider;
        uint256 liquidationProtocolFee;
    }

    struct ERC1155ReserveConfiguration {
        bool isActive;
        bool isFrozen;
        bool isPaused;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    struct UserConfigurationMap {
        /**
         * @dev Bitmap of the users collaterals and borrows. It is divided in pairs of bits, one pair per asset.
         * The first bit indicates if an asset is used as collateral by the user, the second whether an
         * asset is borrowed by the user.
         */
        uint256 data;
    }

    struct ERC1155ReserveUsageData {
        address asset;
        uint256 tokenId;
    }

    struct UserERC1155ConfigurationMap {
        // List of ERC1155 reserves used by user
        ERC1155ReserveUsageData[] usedERC1155Reserves;
        // Mapping matching given asset and tokenId to index in usedERC1155Reserves array + 1
        // Index 0 is used for not used reserves
        mapping(address asset => mapping(uint256 tokenId => uint256 indexPlus1)) usedERC1155ReservesMap;
    }

    struct ReserveCache {
        uint256 currScaledVariableDebt;
        uint256 nextScaledVariableDebt;
        uint256 currLiquidityIndex;
        uint256 nextLiquidityIndex;
        uint256 currVariableBorrowIndex;
        uint256 nextVariableBorrowIndex;
        uint256 currLiquidityRate;
        uint256 currVariableBorrowRate;
        uint256 reserveFactor;
        ReserveConfigurationMap reserveConfiguration;
        address yTokenAddress;
        address variableDebtTokenAddress;
        uint40 reserveLastUpdateTimestamp;
    }

    struct ExecuteLiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        address debtAsset;
        address user;
        bool receiveYToken;
        address priceOracle;
        address priceOracleSentinel;
    }

    struct ExecuteERC1155LiquidationCallParams {
        uint256 reservesCount;
        uint256 debtToCover;
        address collateralAsset;
        uint256 collateralTokenId;
        address debtAsset;
        address user;
        bool receiveNToken;
        address priceOracle;
        address priceOracleSentinel;
        uint256 maxERC1155CollateralReserves;
    }

    struct ExecuteSupplyParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteSupplyERC1155Params {
        address asset;
        uint256 tokenId;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
        uint256 maxERC1155CollateralReserves;
    }

    struct ExecuteBorrowParams {
        address asset;
        address user;
        address onBehalfOf;
        uint256 amount;
        uint16 referralCode;
        bool releaseUnderlying;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ExecuteRepayParams {
        address asset;
        uint256 amount;
        address onBehalfOf;
        bool useYTokens;
    }

    struct ExecuteWithdrawParams {
        address asset;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct ExecuteWithdrawERC1155Params {
        address asset;
        uint256 tokenId;
        uint256 amount;
        address to;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeTransferParams {
        address asset;
        address from;
        address to;
        uint256 amount;
        uint256 balanceFromBefore;
        uint256 balanceToBefore;
        uint256 reservesCount;
        address oracle;
    }

    struct FinalizeERC1155TransferParams {
        address asset;
        address from;
        address to;
        uint256[] ids;
        uint256[] amounts;
        uint256 reservesCount;
        address oracle;
        uint256 maxERC1155CollateralReserves;
    }

    struct FlashloanParams {
        address receiverAddress;
        address[] assets;
        uint256[] amounts;
        bool[] createPosition;
        address onBehalfOf;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
        uint256 reservesCount;
        address addressesProvider;
        bool isAuthorizedFlashBorrower;
    }

    struct FlashloanSimpleParams {
        address receiverAddress;
        address asset;
        uint256 amount;
        bytes params;
        uint16 referralCode;
        uint256 flashLoanPremiumToProtocol;
        uint256 flashLoanPremiumTotal;
    }

    struct FlashLoanRepaymentParams {
        uint256 amount;
        uint256 totalPremium;
        uint256 flashLoanPremiumToProtocol;
        address asset;
        address receiverAddress;
        uint16 referralCode;
    }

    struct CalculateUserAccountDataParams {
        UserConfigurationMap userConfig;
        uint256 reservesCount;
        address user;
        address oracle;
    }

    struct ValidateBorrowParams {
        ReserveCache reserveCache;
        UserConfigurationMap userConfig;
        address asset;
        address userAddress;
        uint256 amount;
        uint256 reservesCount;
        address oracle;
        address priceOracleSentinel;
    }

    struct ValidateLiquidationCallParams {
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct ValidateERC1155LiquidationCallParams {
        address collateralReserveAddress;
        uint256 collateralReserveTokenId;
        ReserveCache debtReserveCache;
        uint256 totalDebt;
        uint256 healthFactor;
        address priceOracleSentinel;
    }

    struct ValidateHealthFactorParams {
        UserConfigurationMap userConfig;
        address user;
        uint256 reservesCount;
        address oracle;
    }

    struct CalculateInterestRatesParams {
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalVariableDebt;
        uint256 reserveFactor;
        address reserve;
        address yToken;
    }

    struct InitReserveParams {
        address asset;
        address yTokenAddress;
        address variableDebtAddress;
        address interestRateStrategyAddress;
        uint16 reservesCount;
        uint16 maxNumberReserves;
    }

    struct InitERC1155ReserveParams {
        address asset;
        address nTokenAddress;
        address configurationProvider;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import {IPoolAddressesProvider} from "@yldr-lending/core/src/interfaces/IPoolAddressesProvider.sol";

interface IUIPoolDataProvider {
    struct InterestRates {
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
    }

    struct AggregatedReserveData {
        address underlyingAsset;
        string name;
        string symbol;
        uint256 decimals;
        uint256 baseLTVasCollateral;
        uint256 reserveLiquidationThreshold;
        uint256 reserveLiquidationBonus;
        uint256 reserveFactor;
        bool usageAsCollateralEnabled;
        bool borrowingEnabled;
        bool isActive;
        bool isFrozen;
        bool isPaused;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 liquidityRate;
        uint128 variableBorrowRate;
        uint40 lastUpdateTimestamp;
        address yTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint256 availableLiquidity;
        uint256 totalScaledVariableDebt;
        uint256 priceInMarketReferenceCurrency;
        address priceOracle;
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 baseVariableBorrowRate;
        uint256 optimalUsageRatio;
        uint128 accruedToTreasury;
        bool flashLoanEnabled;
        uint256 borrowCap;
        uint256 supplyCap;
    }

    struct UserReserveData {
        address underlyingAsset;
        uint256 scaledYTokenBalance;
        bool usageAsCollateralEnabledOnUser;
        uint256 scaledVariableDebt;
    }

    struct UserERC1155ReserveData {
        address asset;
        uint256 tokenId;
        uint256 balance;
    }

    struct BaseCurrencyInfo {
        uint256 marketReferenceCurrencyUnit;
        int256 marketReferenceCurrencyPriceInUsd;
        int256 networkBaseTokenPriceInUsd;
        uint8 networkBaseTokenPriceDecimals;
    }

    function getReservesList(IPoolAddressesProvider provider) external view returns (address[] memory);

    function getReservesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveData[] memory, BaseCurrencyInfo memory);

    function getUserReservesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveData[] memory, UserERC1155ReserveData[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 *
 * @notice Interface for the YLDR price oracle.
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

    /**
     * @notice Returns the ERC1155 asset price in the base currency
     * It returns the price of totalSupply of given tokenId. To calculate partial amount, use price * shares / totalSupply
     * @param asset The address of the asset
     * @param tokenId The tokenId of the asset
     * @return The price of the asset
     */
    function getERC1155AssetPrice(address asset, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IScaledBalanceToken
 *
 * @notice Defines the basic interface for a scaled-balance token.
 */
interface IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param caller The address performing the mint
     * @param onBehalfOf The address of the user that will receive the minted tokens
     * @param value The scaled-up amount being minted (based on user entered amount and balance increase from interest)
     * @param balanceIncrease The increase in scaled-up balance since the last action of 'onBehalfOf'
     * @param index The next liquidity index of the reserve
     */
    event Mint(
        address indexed caller, address indexed onBehalfOf, uint256 value, uint256 balanceIncrease, uint256 index
    );

    /**
     * @dev Emitted after the burn action
     * @dev If the burn function does not involve a transfer of the underlying asset, the target defaults to zero address
     * @param from The address from which the tokens will be burned
     * @param target The address that will receive the underlying, if any
     * @param value The scaled-up amount being burned (user entered amount - balance increase from interest)
     * @param balanceIncrease The increase in scaled-up balance since the last action of 'from'
     * @param index The next liquidity index of the reserve
     */
    event Burn(address indexed from, address indexed target, uint256 value, uint256 balanceIncrease, uint256 index);

    /**
     * @notice Returns the scaled balance of the user.
     * @dev The scaled balance is the sum of all the updated stored balance divided by the reserve's liquidity index
     * at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     */
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled total supply
     */
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @notice Returns the scaled total supply of the scaled balance token. Represents sum(debt/index)
     * @return The scaled total supply
     */
    function scaledTotalSupply() external view returns (uint256);

    /**
     * @notice Returns last index interest was accrued to the user's balance
     * @param user The address of the user
     * @return The last index interest was accrued to the user's balance, expressed in ray
     */
    function getPreviousIndex(address user) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPool} from "./IPool.sol";

/**
 * @title IInitializableYToken
 *
 * @notice Interface for the initialize function on YToken
 */
interface IInitializableYToken {
    /**
     * @dev Emitted when an yToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this yToken
     * @param yTokenDecimals The decimals of the underlying
     * @param yTokenName The name of the yToken
     * @param yTokenSymbol The symbol of the yToken
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 yTokenDecimals,
        string yTokenName,
        string yTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes yToken
     * @param initializingPool The pool contract that is initializing this contract
     * @param treasury The address of the YLDR treasury, receiving the fees on this yToken
     * @param underlyingAsset The address of the underlying asset of this yToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param yTokenDecimals The decimals of the yToken, same as the underlying asset's
     * @param yTokenName The name of the yToken
     * @param yTokenSymbol The symbol of the yToken
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool initializingPool,
        address treasury,
        address underlyingAsset,
        address incentivesController,
        uint8 yTokenDecimals,
        string memory yTokenName,
        string memory yTokenSymbol,
        bytes memory params
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPool} from "./IPool.sol";

/**
 * @title IInitializableDebtToken
 *
 * @notice Interface for the initialize function common between debt tokens
 */
interface IInitializableDebtToken {
    /**
     * @dev Emitted when a debt token is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param incentivesController The address of the incentives controller for this yToken
     * @param debtTokenDecimals The decimals of the debt token
     * @param debtTokenName The name of the debt token
     * @param debtTokenSymbol The symbol of the debt token
     * @param params A set of encoded parameters for additional initialization
     */
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address incentivesController,
        uint8 debtTokenDecimals,
        string debtTokenName,
        string debtTokenSymbol,
        bytes params
    );

    /**
     * @notice Initializes the debt token.
     * @param pool The pool contract that is initializing this contract
     * @param underlyingAsset The address of the underlying asset of this yToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
     * @param debtTokenName The name of the token
     * @param debtTokenSymbol The symbol of the token
     * @param params A set of encoded parameters for additional initialization
     */
    function initialize(
        IPool pool,
        address underlyingAsset,
        address incentivesController,
        uint8 debtTokenDecimals,
        string memory debtTokenName,
        string memory debtTokenSymbol,
        bytes calldata params
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title PercentageMath library
 *
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 */
library PercentageMath {
    // Maximum percentage factor (100.00%)
    uint256 internal constant PERCENTAGE_FACTOR = 1e4;

    // Half percentage factor (50.00%)
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;

    /**
     * @notice Executes a percentage multiplication
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentmul percentage
     */
    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if iszero(or(iszero(percentage), iszero(gt(value, div(sub(not(0), HALF_PERCENTAGE_FACTOR), percentage))))) {
                revert(0, 0)
            }

            result := div(add(mul(value, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /**
     * @notice Executes a percentage division
     * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return result value percentdiv percentage
     */
    function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        // to avoid overflow, value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR
        assembly {
            if or(
                iszero(percentage), iszero(iszero(gt(value, div(sub(not(0), div(percentage, 2)), PERCENTAGE_FACTOR))))
            ) { revert(0, 0) }

            result := div(add(mul(value, PERCENTAGE_FACTOR), div(percentage, 2)), percentage)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 *
 * @notice Defines the error messages emitted by the different contracts of the YLDR protocol
 */
library Errors {
    string public constant CALLER_NOT_POOL_ADMIN = "1"; // 'The caller of the function is not a pool admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "2"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_POOL_OR_EMERGENCY_ADMIN = "3"; // 'The caller of the function is not a pool or emergency admin'
    string public constant CALLER_NOT_RISK_OR_POOL_ADMIN = "4"; // 'The caller of the function is not a risk or pool admin'
    string public constant CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = "5"; // 'The caller of the function is not an asset listing or pool admin'
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "7"; // 'Pool addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "8"; // 'Invalid id for the pool addresses provider'
    string public constant NOT_CONTRACT = "9"; // 'Address is not a contract'
    string public constant CALLER_NOT_POOL_CONFIGURATOR = "10"; // 'The caller of the function is not the pool configurator'
    string public constant CALLER_NOT_YTOKEN = "11"; // 'The caller of the function is not an YToken'
    string public constant INVALID_ADDRESSES_PROVIDER = "12"; // 'The address of the pool addresses provider is invalid'
    string public constant INVALID_FLASHLOAN_EXECUTOR_RETURN = "13"; // 'Invalid return value of the flashloan executor function'
    string public constant RESERVE_ALREADY_ADDED = "14"; // 'Reserve has already been added to reserve list'
    string public constant NO_MORE_RESERVES_ALLOWED = "15"; // 'Maximum amount of reserves in the pool reached'
    string public constant RESERVE_LIQUIDITY_NOT_ZERO = "18"; // 'The liquidity of the reserve needs to be 0'
    string public constant FLASHLOAN_PREMIUM_INVALID = "19"; // 'Invalid flashloan premium'
    string public constant INVALID_RESERVE_PARAMS = "20"; // 'Invalid risk parameters for the reserve'
    string public constant CALLER_MUST_BE_POOL = "23"; // 'The caller of this function must be a pool'
    string public constant INVALID_MINT_AMOUNT = "24"; // 'Invalid amount to mint'
    string public constant INVALID_BURN_AMOUNT = "25"; // 'Invalid amount to burn'
    string public constant INVALID_AMOUNT = "26"; // 'Amount must be greater than 0'
    string public constant RESERVE_INACTIVE = "27"; // 'Action requires an active reserve'
    string public constant RESERVE_FROZEN = "28"; // 'Action cannot be performed because the reserve is frozen'
    string public constant RESERVE_PAUSED = "29"; // 'Action cannot be performed because the reserve is paused'
    string public constant BORROWING_NOT_ENABLED = "30"; // 'Borrowing is not enabled'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "32"; // 'User cannot withdraw more than the available balance'
    string public constant INVALID_INTEREST_RATE_MODE_SELECTED = "33"; // 'Invalid interest rate mode selected'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "34"; // 'The collateral balance is 0'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "35"; // 'Health factor is lesser than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "36"; // 'There is not enough collateral to cover a new borrow'
    string public constant COLLATERAL_SAME_AS_BORROWING_CURRENCY = "37"; // 'Collateral is (mostly) the same currency that is being borrowed'
    string public constant NO_DEBT = "39"; // 'For repayment of debt, the user needs to have debt'
    string public constant NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "40"; // 'To repay on behalf of a user an explicit amount to repay is needed'
    string public constant NO_OUTSTANDING_VARIABLE_DEBT = "42"; // 'User does not have outstanding variable rate debt on this reserve'
    string public constant UNDERLYING_BALANCE_ZERO = "43"; // 'The underlying balance needs to be greater than 0'
    string public constant INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "44"; // 'Interest rate rebalance conditions were not met'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "45"; // 'Health factor is not below the threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "46"; // 'The collateral chosen cannot be liquidated'
    string public constant SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "47"; // 'User did not borrow the specified currency'
    string public constant INCONSISTENT_FLASHLOAN_PARAMS = "49"; // 'Inconsistent flashloan parameters'
    string public constant BORROW_CAP_EXCEEDED = "50"; // 'Borrow cap is exceeded'
    string public constant SUPPLY_CAP_EXCEEDED = "51"; // 'Supply cap is exceeded'
    string public constant DEBT_CEILING_EXCEEDED = "53"; // 'Debt ceiling is exceeded'
    string public constant UNDERLYING_CLAIMABLE_RIGHTS_NOT_ZERO = "54"; // 'Claimable rights over underlying not zero (yToken supply or accruedToTreasury)'
    string public constant VARIABLE_DEBT_SUPPLY_NOT_ZERO = "56"; // 'Variable debt supply is not zero'
    string public constant LTV_VALIDATION_FAILED = "57"; // 'Ltv validation failed'
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "59"; // 'Price oracle sentinel validation failed'
    string public constant RESERVE_ALREADY_INITIALIZED = "61"; // 'Reserve has already been initialized'
    string public constant LTV_ZERO = "62"; // 'LTV is zero'
    string public constant INVALID_LTV = "63"; // 'Invalid ltv parameter for the reserve'
    string public constant INVALID_LIQ_THRESHOLD = "64"; // 'Invalid liquidity threshold parameter for the reserve'
    string public constant INVALID_LIQ_BONUS = "65"; // 'Invalid liquidity bonus parameter for the reserve'
    string public constant INVALID_DECIMALS = "66"; // 'Invalid decimals parameter of the underlying asset of the reserve'
    string public constant INVALID_RESERVE_FACTOR = "67"; // 'Invalid reserve factor parameter for the reserve'
    string public constant INVALID_BORROW_CAP = "68"; // 'Invalid borrow cap for the reserve'
    string public constant INVALID_SUPPLY_CAP = "69"; // 'Invalid supply cap for the reserve'
    string public constant INVALID_LIQUIDATION_PROTOCOL_FEE = "70"; // 'Invalid liquidation protocol fee for the reserve'
    string public constant INVALID_DEBT_CEILING = "73"; // 'Invalid debt ceiling for the reserve
    string public constant INVALID_RESERVE_INDEX = "74"; // 'Invalid reserve index'
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "75"; // 'ACL admin cannot be set to the zero address'
    string public constant INCONSISTENT_PARAMS_LENGTH = "76"; // 'Array parameters that should be equal length are not'
    string public constant ZERO_ADDRESS_NOT_VALID = "77"; // 'Zero address not valid'
    string public constant INVALID_EXPIRATION = "78"; // 'Invalid expiration'
    string public constant INVALID_SIGNATURE = "79"; // 'Invalid signature'
    string public constant OPERATION_NOT_SUPPORTED = "80"; // 'Operation not supported'
    string public constant DEBT_CEILING_NOT_ZERO = "81"; // 'Debt ceiling is not zero'
    string public constant ASSET_NOT_LISTED = "82"; // 'Asset is not listed'
    string public constant INVALID_OPTIMAL_USAGE_RATIO = "83"; // 'Invalid optimal usage ratio'
    string public constant UNDERLYING_CANNOT_BE_RESCUED = "85"; // 'The underlying asset cannot be rescued'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "86"; // 'Reserve has already been added to reserve list'
    string public constant POOL_ADDRESSES_DO_NOT_MATCH = "87"; // 'The token implementation pool address and the pool address provided by the initializing pool do not match'
    string public constant RESERVE_DEBT_NOT_ZERO = "90"; // the total debt of the reserve needs to be 0
    string public constant FLASHLOAN_DISABLED = "91"; // FlashLoaning for this asset is disabled
    string public constant CALLER_NOT_NTOKEN = "92"; // 'The caller of the function is not an NToken'
    string public constant ERC1155_RESERVE_CANNOT_BE_USED_AS_COLLATERAL = "93"; // ERC1155 reserve can only be supplied if it can be enabled as collateral
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IReserveInterestRateStrategy} from "./IReserveInterestRateStrategy.sol";
import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IDefaultInterestRateStrategy
 *
 * @notice Defines the basic interface of the DefaultReserveInterestRateStrategy
 */
interface IDefaultInterestRateStrategy is IReserveInterestRateStrategy {
    /**
     * @notice Returns the usage ratio at which the pool aims to obtain most competitive borrow rates.
     * @return The optimal usage ratio, expressed in ray.
     */
    function OPTIMAL_USAGE_RATIO() external view returns (uint256);

    /**
     * @notice Returns the excess usage ratio above the optimal.
     * @dev It's always equal to 1-optimal usage ratio (added as constant for gas optimizations)
     * @return The max excess usage ratio, expressed in ray.
     */
    function MAX_EXCESS_USAGE_RATIO() external view returns (uint256);

    /**
     * @notice Returns the address of the PoolAddressesProvider
     * @return The address of the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns the variable rate slope below optimal usage ratio
     * @dev It's the variable rate when usage ratio > 0 and <= OPTIMAL_USAGE_RATIO
     * @return The variable rate slope, expressed in ray
     */
    function getVariableRateSlope1() external view returns (uint256);

    /**
     * @notice Returns the variable rate slope above optimal usage ratio
     * @dev It's the variable rate when usage ratio > OPTIMAL_USAGE_RATIO
     * @return The variable rate slope, expressed in ray
     */
    function getVariableRateSlope2() external view returns (uint256);

    /**
     * @notice Returns the base variable borrow rate
     * @return The base variable borrow rate, expressed in ray
     */
    function getBaseVariableBorrowRate() external view returns (uint256);

    /**
     * @notice Returns the maximum variable borrow rate
     * @return The maximum variable borrow rate, expressed in ray
     */
    function getMaxVariableBorrowRate() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IReserveInterestRateStrategy
 *
 * @notice Interface for the calculation of the interest rates
 */
interface IReserveInterestRateStrategy {
    /**
     * @notice Calculates the interest rates depending on the reserve's state and configurations
     * @param params The parameters needed to calculate interest rates
     * @return liquidityRate The liquidity rate expressed in rays
     * @return variableBorrowRate The variable borrow rate expressed in rays
     */
    function calculateInterestRates(DataTypes.CalculateInterestRatesParams memory params)
        external
        view
        returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IPoolAddressesProvider} from "./IPoolAddressesProvider.sol";

/**
 * @title IPoolDataProvider
 *
 * @notice Defines the basic interface of a PoolDataProvider
 */
interface IPoolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }

    /**
     * @notice Returns the address for the PoolAddressesProvider contract.
     * @return The address for the PoolAddressesProvider contract
     */
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);

    /**
     * @notice Returns the list of the existing reserves in the pool.
     * @dev Handling MKR and ETH in a different way since they do not have standard `symbol` functions.
     * @return The list of reserves, pairs of symbols and addresses
     */
    function getAllReservesTokens() external view returns (TokenData[] memory);

    /**
     * @notice Returns the list of the existing YTokens in the pool.
     * @return The list of YTokens, pairs of symbols and addresses
     */
    function getAllYTokens() external view returns (TokenData[] memory);

    /**
     * @notice Returns the configuration data of the reserve
     * @dev Not returning borrow and supply caps for compatibility, nor pause flag
     * @param asset The address of the underlying asset of the reserve
     * @return decimals The number of decimals of the reserve
     * @return ltv The ltv of the reserve
     * @return liquidationThreshold The liquidationThreshold of the reserve
     * @return liquidationBonus The liquidationBonus of the reserve
     * @return reserveFactor The reserveFactor of the reserve
     * @return usageAsCollateralEnabled True if the usage as collateral is enabled, false otherwise
     * @return borrowingEnabled True if borrowing is enabled, false otherwise
     * @return isActive True if it is active, false otherwise
     * @return isFrozen True if it is frozen, false otherwise
     */
    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool isActive,
            bool isFrozen
        );

    /**
     * @notice Returns the caps parameters of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return borrowCap The borrow cap of the reserve
     * @return supplyCap The supply cap of the reserve
     */
    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);

    /**
     * @notice Returns if the pool is paused
     * @param asset The address of the underlying asset of the reserve
     * @return isPaused True if the pool is paused, false otherwise
     */
    function getPaused(address asset) external view returns (bool isPaused);

    /**
     * @notice Returns the protocol fee on the liquidation bonus
     * @param asset The address of the underlying asset of the reserve
     * @return The protocol fee on liquidation
     */
    function getLiquidationProtocolFee(address asset) external view returns (uint256);

    /**
     * @notice Returns the reserve data
     * @param asset The address of the underlying asset of the reserve
     * @return accruedToTreasuryScaled The scaled amount of tokens accrued to treasury that is to be minted
     * @return totalYToken The total supply of the yToken
     * @return totalVariableDebt The total variable debt of the reserve
     * @return liquidityRate The liquidity rate of the reserve
     * @return variableBorrowRate The variable borrow rate of the reserve
     * @return liquidityIndex The liquidity index of the reserve
     * @return variableBorrowIndex The variable borrow index of the reserve
     * @return lastUpdateTimestamp The timestamp of the last update of the reserve
     */
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 accruedToTreasuryScaled,
            uint256 totalYToken,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    /**
     * @notice Returns the total supply of yTokens for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total supply of the yToken
     */
    function getYTokenTotalSupply(address asset) external view returns (uint256);

    /**
     * @notice Returns the total debt for a given asset
     * @param asset The address of the underlying asset of the reserve
     * @return The total debt for asset
     */
    function getTotalDebt(address asset) external view returns (uint256);

    /**
     * @notice Returns the user data in a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param user The address of the user
     * @return currentYTokenBalance The current YToken balance of the user
     * @return currentVariableDebt The current variable debt of the user
     * @return scaledVariableDebt The scaled variable debt of the user
     * @return liquidityRate The liquidity rate of the reserve
     * @return usageAsCollateralEnabled True if the user is using the asset as collateral, false
     *         otherwise
     */
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentYTokenBalance,
            uint256 currentVariableDebt,
            uint256 scaledVariableDebt,
            uint256 liquidityRate,
            bool usageAsCollateralEnabled
        );

    /**
     * @notice Returns the token addresses of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return yTokenAddress The YToken address of the reserve
     * @return variableDebtTokenAddress The VariableDebtToken address of the reserve
     */
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (address yTokenAddress, address variableDebtTokenAddress);

    /**
     * @notice Returns the address of the Interest Rate strategy
     * @param asset The address of the underlying asset of the reserve
     * @return irStrategyAddress The address of the Interest Rate strategy
     */
    function getInterestRateStrategyAddress(address asset) external view returns (address irStrategyAddress);

    /**
     * @notice Returns whether the reserve has FlashLoans enabled or disabled
     * @param asset The address of the underlying asset of the reserve
     * @return True if FlashLoans are enabled, false otherwise
     */
    function getFlashLoanEnabled(address asset) external view returns (bool);
}