// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IGMXV2OrchestratorReader} from "./interfaces/IGMXV2OrchestratorReader.sol";
import {IGMXV2RouteReader} from "./interfaces/IGMXV2RouteReader.sol";

import {GMXV2Keys} from "./libraries/GMXV2Keys.sol";

import {BaseOrchestratorReader} from "../../../utilities/BaseOrchestratorReader.sol";

/// @title GMXV2Reader
/// @dev Extends the BaseOrchestratorReader contract with GMX V2 integration specific logic
contract GMXV2OrchestratorReader is IGMXV2OrchestratorReader, BaseOrchestratorReader {

    IGMXV2RouteReader private immutable _routeReader;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _dataStore The DataStore contract address
    /// @param _wntAddr The WNT contract address
    /// @param _routeReaderAddr The GMXRouteReader contract address
    constructor(address _dataStore, address _wntAddr, address _routeReaderAddr) BaseOrchestratorReader(_dataStore, _wntAddr) {
        _routeReader = IGMXV2RouteReader(_routeReaderAddr);
    }

    // ============================================================================================
    // View functions
    // ============================================================================================

    function routeReader() override external view returns (address) {
        return address(_routeReader);
    }

    function isWaitingForCallback(bytes32 _routeKey) override external view returns (bool) {
        return _routeReader.isWaitingForCallback(_routeKey);
    }

    function positionKey(address _route) override public view returns (bytes32) {
        return keccak256(
            abi.encode(
                _route,
                dataStore.getAddress(GMXV2Keys.routeMarketToken(_route)),
                collateralToken(_route),
                isLong(_route)
            ));
    }

    function gmxDataStore() external view returns (address) {
        return dataStore.getAddress(GMXV2Keys.GMX_DATA_STORE);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title IGMXV2OrchestratorReader
/// @dev Interface for GMXV2OrchestratorReader contract
interface IGMXV2OrchestratorReader {
    function gmxDataStore() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IGMXPosition} from "../../interfaces/IGMXPosition.sol";

import {OrderUtils} from "../libraries/OrderUtils.sol";

/// @title IGMXV2RouteReader
/// @dev Interface for GMXV2RouteReader contract
interface IGMXV2RouteReader {
    function isWaitingForCallback(bytes32 _routeKey) external view returns (bool);
    function getCreateOrderParams(uint256 _sizeDelta, uint256 _collateralDelta, uint256 _acceptablePrice, uint256 _executionFee, address _route, bool _isIncreaseBool) external view returns (OrderUtils.CreateOrderParams memory _params);
    function gmxRouter() external view returns (address);
    function gmxExchangeRouter() external view returns (address);
    function gmxOrderVault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title GMXV2Keys
/// @dev Keys for values in the DataStore
library GMXV2Keys {
    /// @dev key for GMX V2's Router
    bytes32 public constant ROUTER = keccak256(abi.encode("GMXV2_ROUTER"));
    /// @dev key for GMX V2's Exchange Router
    bytes32 public constant EXCHANGE_ROUTER = keccak256(abi.encode("GMXV2_EXCHANGE_ROUTER"));
    /// @dev key for GMX V2's Order Vault
    bytes32 public constant ORDER_VAULT = keccak256(abi.encode("GMXV2_ORDER_VAULT"));
    /// @dev key for GMX V2's Order Handler
    bytes32 public constant ORDER_HANDLER = keccak256(abi.encode("GMXV2_ORDER_HANDLER"));
    /// @dev key for GMX V2's Reader
    bytes32 public constant GMX_READER = keccak256(abi.encode("GMXV2_GMX_READER"));
    /// @dev key for GMX V2's DataStore
    bytes32 public constant GMX_DATA_STORE = keccak256(abi.encode("GMXV2_GMX_DATA_STORE"));

    // -------------------------------------------------------------------------------------------

    function routeMarketToken(address _route) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("GMXV2_ROUTE_MARKET_TOKEN", _route));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ================= BaseOrchestratorReader =====================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IBaseOrchestratorReader} from "./interfaces/IBaseOrchestratorReader.sol";

import {BaseReader, Keys} from "./BaseReader.sol";

/// @title BaseOrchestratorReader
/// @dev Base contract for Orchestrator DataStore read functions
abstract contract BaseOrchestratorReader is IBaseOrchestratorReader, BaseReader {

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _dataStore The DataStore contract address
    /// @param _wntAddr The WNT contract address
    constructor(address _dataStore, address _wntAddr) BaseReader(_dataStore, _wntAddr) {}

    // ============================================================================================
    // View functions
    // ============================================================================================

    // global

    function routeReader() virtual external view returns (address) {}

    function routeSetter() external view returns (address) {
        return dataStore.getAddress(Keys.ROUTE_SETTER);
    }

    function platformAccountBalance(address _asset) external view returns (uint256) {
        return dataStore.getUint(Keys.platformAccountKey(_asset));
    }

    function isRouteTypeRegistered(bytes32 _routeTypeKey) external view returns (bool) {
        return dataStore.getBool(Keys.isRouteTypeRegisteredKey(_routeTypeKey));
    }

    // deployed contracts

    function routeFactory() external view returns (address) {
        return dataStore.getAddress(Keys.ROUTE_FACTORY);
    }

    function multiSubscriber() external view returns (address) {
        return dataStore.getAddress(Keys.MULTI_SUBSCRIBER);
    }

    // keys

    function positionKey(address _route) virtual public view returns (bytes32) {}

    // route

    function isWaitingForCallback(bytes32 _routeKey) virtual external view returns (bool);

    function subscribedPuppetsCount(bytes32 _routeKey) external view returns (uint256) {
        return dataStore.getAddressCount(Keys.routePuppetsKey(_routeKey));
    }

    function puppetAt(bytes32 _routeKey, uint256 _index) external view returns (address) {
        return dataStore.getAddressValueAt(Keys.routePuppetsKey(_routeKey), _index);
    }

    // puppets

    function puppetSubscriptions(address _puppet) external view returns (address[] memory) {
        address _route;
        uint256 _cleanSubscriptionCount = 0;
        bytes32 _puppetAllowancesKey = Keys.puppetAllowancesKey(_puppet);
        uint256 _dirtySubscriptionCount = dataStore.getAddressToUintCount(_puppetAllowancesKey);
        for (uint256 i = 0; i < _dirtySubscriptionCount; i++) {
            (_route,) = dataStore.getAddressToUintAt(_puppetAllowancesKey, i);
            if (puppetSubscriptionExpiry(_puppet, routeKey(_route)) > block.timestamp) {
                _cleanSubscriptionCount++;
            }
        }

        uint256 j = 0;
        address[] memory _subscriptions = new address[](_cleanSubscriptionCount);
        for (uint256 i = 0; i < _dirtySubscriptionCount; i++) {
            (_route,) = dataStore.getAddressToUintAt(_puppetAllowancesKey, i);
            if (puppetSubscriptionExpiry(_puppet, routeKey(_route)) > block.timestamp) {
                _subscriptions[j] = _route;
                j++;
            }
        }

        return _subscriptions;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGMXPosition {

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the position's account
    // @param market the position's market
    // @param collateralToken the position's collateralToken
    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    // @param sizeInUsd the position's size in USD
    // @param sizeInTokens the position's size in tokens
    // @param collateralAmount the amount of collateralToken for collateral
    // @param borrowingFactor the position's borrowing factor
    // @param fundingFeeAmountPerSize the position's funding fee per size
    // @param longTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.longToken
    // @param shortTokenClaimableFundingAmountPerSize the position's claimable funding amount per size
    // for the market.shortToken
    // @param increasedAtBlock the block at which the position was last increased
    // @param decreasedAtBlock the block at which the position was last decreased
    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    // @param isLong whether the position is a long or short
    struct Flags {
        bool isLong;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "../../interfaces/IGMXOrder.sol";

library OrderUtils {

    error InvalidOrderType();

    // @dev CreateOrderParams struct used in createOrder to avoid stack
    // too deep errors
    //
    // @param addresses address values
    // @param numbers number values
    // @param orderType for order.orderType
    // @param decreasePositionSwapType for order.decreasePositionSwapType
    // @param isLong for order.isLong
    // @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        IGMXOrder.OrderType orderType;
        IGMXOrder.DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    function isIncrease(IGMXOrder.OrderType _orderType) internal pure returns (bool) {
        if (OrderUtils.isIncreaseOrder(_orderType)) {
            return true;
        } else if (OrderUtils.isDecreaseOrder(_orderType)) {
            return false;
        } else {
            revert InvalidOrderType();
        }
    }

    // @dev check if an orderType is an increase order
    // @param orderType the order type
    // @return whether an orderType is an increase order
    function isIncreaseOrder(IGMXOrder.OrderType orderType) internal pure returns (bool) {
        return orderType == IGMXOrder.OrderType.MarketIncrease ||
               orderType == IGMXOrder.OrderType.LimitIncrease;
    }

    // @dev check if an orderType is a decrease order
    // @param orderType the order type
    // @return whether an orderType is a decrease order
    function isDecreaseOrder(IGMXOrder.OrderType orderType) internal pure returns (bool) {
        return orderType == IGMXOrder.OrderType.MarketDecrease ||
               orderType == IGMXOrder.OrderType.LimitDecrease ||
               orderType == IGMXOrder.OrderType.StopLossDecrease ||
               orderType == IGMXOrder.OrderType.Liquidation;
    }

    // @dev check if an orderType is a liquidation order
    // @param orderType the order type
    // @return whether an orderType is a liquidation order
    function isLiquidationOrder(IGMXOrder.OrderType orderType) internal pure returns (bool) {
        return orderType == IGMXOrder.OrderType.Liquidation;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ================ IBaseOrchestratorReader =====================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IBaseReader} from "./IBaseReader.sol";

/// @title IBaseOrchestratorReader
/// @dev Interface for BaseOrchestratorReader contract
interface IBaseOrchestratorReader is IBaseReader {

    // global

    function routeReader() external view returns (address);
    function routeSetter() external view returns (address);
    function platformAccountBalance(address _asset) external view returns (uint256);
    function isRouteTypeRegistered(bytes32 _routeTypeKey) external view returns (bool);

    // deployed contracts

    function routeFactory() external view returns (address);
    function multiSubscriber() external view returns (address);

    // keys

    function positionKey(address _route) external view returns (bytes32);

    // route

    function isWaitingForCallback(bytes32 _routeKey) external view returns (bool);
    function subscribedPuppetsCount(bytes32 _routeKey) external view returns (uint256);
    function puppetAt(bytes32 _routeKey, uint256 _index) external view returns (address);

    // puppets

    function puppetSubscriptions(address _puppet) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ======================= BaseReader ===========================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {IBaseRouteSetter} from "./interfaces/IBaseRouteSetter.sol";
import {IBaseReader} from "./interfaces/IBaseReader.sol";
import {IDataStore} from "./interfaces/IDataStore.sol";

import {BaseReaderHelper, Keys} from "./libraries/BaseReaderHelper.sol";

/// @title BaseReader
/// @dev Base contract for reading from DataStore
abstract contract BaseReader is IBaseReader {

    address private immutable _wnt;

    uint256 private constant _PRECISION = 1e18;
    uint256 private constant _BASIS_POINTS_DIVISOR = 10000;

    IDataStore public immutable dataStore;

    // ============================================================================================
    // Constructor
    // ============================================================================================

    /// @notice The ```constructor``` function is called on deployment
    /// @param _dataStore The DataStore contract address
    /// @param _wntAddr The WNT contract address
    constructor(address _dataStore, address _wntAddr) {
        dataStore = IDataStore(_dataStore);
        _wnt = _wntAddr;
    }

    // ============================================================================================
    // View functions
    // ============================================================================================

    // global

    function precision() public pure returns (uint256) {
        return _PRECISION;
    }

    function withdrawalFeePercentage() public view returns (uint256) {
        return dataStore.getUint(Keys.WITHDRAWAL_FEE);
    }

    function managementFeePercentage() public view returns (uint256) { 
        return dataStore.getUint(Keys.MANAGEMENT_FEE);
    }

    function basisPointsDivisor() public pure returns (uint256) {
        return _BASIS_POINTS_DIVISOR;
    }

    function collateralTokenDecimals(address _token) public view returns (uint256) {
        return dataStore.getUint(Keys.collateralTokenDecimalsKey(_token));
    }

    function platformFeeRecipient() public view returns (address) {
        return dataStore.getAddress(Keys.PLATFORM_FEES_RECIPIENT);
    }

    function wnt() external view returns (address) {
        return _wnt;
    }

    function keeper() external view returns (address) {
        return dataStore.getAddress(Keys.KEEPER);
    }

    function isPaused() external view returns (bool) {
        return dataStore.getBool(Keys.PAUSED);
    }

    function isCollateralToken(address _token) external view returns (bool) {
        return dataStore.getBool(Keys.isCollateralTokenKey(_token));
    }

    function isRouteRegistered(address _route) external view returns (bool) {
        return dataStore.getBool(Keys.isRouteRegisteredKey(routeKey(_route)));
    }

    function isRouteRegistered(bytes32 _routeKey) external view returns (bool) {
        return dataStore.getBool(Keys.isRouteRegisteredKey(_routeKey));
    }

    function referralCode() public view returns (bytes32) {
        return dataStore.getBytes32(Keys.REFERRAL_CODE);
    }

    function routes() external view returns (address[] memory) {
        return dataStore.getAddressArray(Keys.ROUTES);
    }

    // keys
 
    function routeKey(address _route) public view returns (bytes32) {
        return BaseReaderHelper.routeKey(dataStore, trader(_route), routeType(_route));
    }

    function routeKey(address _trader, bytes32 _routeTypeKey) public view returns (bytes32) {
        return BaseReaderHelper.routeKey(dataStore, _trader, _routeTypeKey);
    }

    // deployed contracts

    function orchestrator() public view returns (address) {
        return dataStore.getAddress(Keys.ORCHESTRATOR);
    }

    function scoreGauge() external view returns (address) {
        return dataStore.getAddress(Keys.SCORE_GAUGE);
    }

    // puppets

    function puppetSubscriptionExpiry(address _puppet, bytes32 _routeKey) public view returns (uint256) {
        return BaseReaderHelper.puppetSubscriptionExpiry(dataStore, _puppet, _routeKey);
    }

    function subscribedPuppets(bytes32 _routeKey) public view returns (address[] memory) {
        return BaseReaderHelper.subscribedPuppets(dataStore, _routeKey);
    }

    // Route data

    function collateralToken(address _route) public view returns (address) {
        return dataStore.getAddress(Keys.routeCollateralTokenKey(_route));
    }

    function indexToken(address _route) public view returns (address) {
        return dataStore.getAddress(Keys.routeIndexTokenKey(_route));
    }

    function trader(address _route) public view returns (address) {
        return dataStore.getAddress(Keys.routeTraderKey(_route));
    }

    function routeAddress(bytes32 _routeKey) public view returns (address) {
        return dataStore.getAddress(Keys.routeAddressKey(_routeKey));
    }

    function routeAddress(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bytes memory _data
    ) external view returns (address) {
        return routeAddress(routeKey(_trader, Keys.routeTypeKey(_collateralToken, _indexToken, _isLong, _data)));
    }

    function isLong(address _route) public view returns (bool) {
        return dataStore.getBool(Keys.routeIsLongKey(_route));
    }

    function isPositionOpen(bytes32 _routeKey) external view returns (bool) {
        return dataStore.getBool(Keys.isPositionOpenKey(_routeKey));
    }

    function routeType(address _route) public view returns (bytes32) {
        return dataStore.getBytes32(Keys.routeRouteTypeKey(_route));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IGMXOrder {

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be cancelled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account of the order
    // @param receiver the receiver for any token transfers
    // this field is meant to allow the output of an order to be
    // received by an address that is different from the creator of the
    // order whether this is for swaps or whether the account is the owner
    // of a position
    // for funding fees and claimable collateral, the funds are still
    // credited to the owner of the position indicated by order.account
    // @param callbackContract the contract to call for callbacks
    // @param uiFeeReceiver the ui fee receiver
    // @param market the trading market
    // @param initialCollateralToken for increase orders, initialCollateralToken
    // is the token sent in by the user, the token will be swapped through the
    // specified swapPath, before being deposited into the position as collateral
    // for decrease orders, initialCollateralToken is the collateral token of the position
    // withdrawn collateral from the decrease of the position will be swapped
    // through the specified swapPath
    // for swaps, initialCollateralToken is the initial token sent for the swap
    // @param swapPath an array of market addresses to swap through
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd the requested change in position size
    // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
    // is the amount of the initialCollateralToken sent in by the user
    // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
    // collateralToken to withdraw
    // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
    // in for the swap
    // @param orderType the order type
    // @param triggerPrice the trigger price for non-market orders
    // @param acceptablePrice the acceptable execution price for increase / decrease orders
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    // @param minOutputAmount the minimum output amount for decrease orders and swaps
    // note that for decrease orders, multiple tokens could be received, for this reason, the
    // minOutputAmount value is treated as a USD value for validation in decrease orders
    // @param updatedAtBlock the block at which the order was last updated
    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    // @param isLong whether the order is for a long or short
    // @param shouldUnwrapNativeToken whether to unwrap native tokens before
    // transferring to the user
    // @param isFrozen whether the order is frozen
    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ====================== IBaseReader ===========================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

/// @title IBaseReader
/// @dev Interface for BaseReader contract
interface IBaseReader {

    // global

    function precision() external pure returns (uint256);
    function withdrawalFeePercentage() external view returns (uint256);
    function managementFeePercentage() external view returns (uint256);
    function basisPointsDivisor() external pure returns (uint256);
    function collateralTokenDecimals(address _token) external view returns (uint256);
    function platformFeeRecipient() external view returns (address);
    function wnt() external view returns (address);
    function keeper() external view returns (address);
    function isPaused() external view returns (bool);
    function isCollateralToken(address _token) external view returns (bool);
    function isRouteRegistered(address _route) external view returns (bool);
    function isRouteRegistered(bytes32 _routeKey) external view returns (bool);
    function referralCode() external view returns (bytes32);
    function routes() external view returns (address[] memory);

    // keys
 
    function routeKey(address _route) external view returns (bytes32);
    function routeKey(address _trader, bytes32 _routeTypeKey) external view returns (bytes32);

    // deployed contracts

    function orchestrator() external view returns (address);
    function scoreGauge() external view returns (address);

    // puppets

    function puppetSubscriptionExpiry(address _puppet, bytes32 _routeKey) external view returns (uint256);
    function subscribedPuppets(bytes32 _routeKey) external view returns (address[] memory);

    // Route data

    function collateralToken(address _route) external view returns (address);
    function indexToken(address _route) external view returns (address);
    function trader(address _route) external view returns (address);
    function routeAddress(bytes32 _routeKey) external view returns (address);
    function routeAddress(address _trader, address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) external view returns (address);
    function isLong(address _route) external view returns (bool);
    function isPositionOpen(bytes32 _routeKey) external view returns (bool);
    function routeType(address _route) external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title IBaseRouteSetter
/// @dev Interface for BaseRouteSetter contract
interface IBaseRouteSetter {

    struct AddCollateralRequest {
        bool isAdjustmentRequired;
        uint256 puppetsAmountIn;
        uint256 traderAmountIn;
        uint256 traderShares;
        uint256 totalSupply;
        uint256 totalAssets;
        uint256[] puppetsShares;
        uint256[] puppetsAmounts;
    }

    struct TraderTargetLeverage {
        uint256 positionSize;
        uint256 positionCollateral;
        uint256 sizeIncrease;
        uint256 collateralIncrease;
    }

    struct RequestSharesData {
        uint256 positionIndex;
        uint256 totalSupply;
        uint256 totalAssets;
        uint256[] puppetsAmounts;
    }

    // route
    function initializePositionPuppets(uint256 _positionIndex, bytes32 _routeKey, address[] memory _puppets) external;
    function storeNewAddCollateralRequest(AddCollateralRequest memory _addCollateralRequest, uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) external;
    function storeTargetLeverage(TraderTargetLeverage memory _traderTargetLeverage, uint256 _basisPointsDivisor, bytes32 _routeKey) external;
    function storeIncreasePositionRequest(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, uint256 _amountIn, uint256 _sizeDelta, bytes32 _routeKey, bytes32 _requestKey) external;
    function storePnLOnSuccessfullDecrease(bytes32 _routeKey, int256 _puppetsPnL, int256 _traderAssets) external;
    function storePositionAmounts(uint256 _positionIndex, uint256 _totalSupply, uint256 _totalAssets, bytes32 _routeKey) external;
    function storeDecreasePositionRequest(uint256 _positionIndex, uint256 _sizeDelta, bytes32 _routeKey, bytes32 _requestKey) external;
    function storeKeeperRequest(bytes32 _routeKey, bytes32 _requestKey) external;
    function storeCumulativeVolumeGenerated(uint256 _cumulativeVolumeGenerated, bytes32 _routeKey) external;
    function addPuppetShares(uint256 _positionIndex, uint256 _puppetIndex, uint256 _newPuppetShares, uint256 _puppetAmountIn, int256 _puppetPnL, bytes32 _routeKey) external;
    function addPuppetsShares(uint256[] memory _puppetsAmounts, uint256 _positionIndex, uint256 _totalAssets, uint256 _totalSupply, bytes32 _routeKey) external returns (uint256, uint256);
    function addTraderShares(uint256 _positionIndex, uint256 _newTraderShares, uint256 _traderAmountIn, int256 _traderPnL, bytes32 _routeKey) external;
    function setAllocateShares(RequestSharesData memory _requestSharesData, uint256 _traderAmountIn, bytes32 _routeKey) external returns (uint256);
    function setIsKeeperAdjustmentEnabled(bytes32 _routeKey, bool _isKeeperAdjustmentEnabled) external;
    function setIsWaitingForKeeperAdjustment(bytes32 _routeKey, bool _isWaitingForKeeperAdjustment) external;
    function setAdjustmentFlags(bool _isAdjustmentRequired, bool _isExecuted, bool _isKeeperRequest, bytes32 _routeKey) external;
    function resetPuppetsArray(uint256 _positionIndex, bytes32 _routeKey) external;
    function resetRoute(bytes32 _routeKey) external;

    // ============================================================================================
    // Errors
    // ============================================================================================

    error Unauthorized();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ========================= IDataStore =========================
// ==============================================================
// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

interface IDataStore {

    // ============================================================================================
    // Owner Functions
    // ============================================================================================

    /// @notice Update the ownership of the contract
    /// @param _owner The owner address
    /// @param _isActive The status of the owner
    function updateOwnership(address _owner, bool _isActive) external;

    // ============================================================================================
    // Getters
    // ============================================================================================

    /// @dev get the uint value for the given key
    /// @param _key the key of the value
    /// @return _value the uint value for the key
    function getUint(bytes32 _key) external view returns (uint256 _value);

    /// @dev get the int value for the given key
    /// @param _key the key of the value
    /// @return _value the int value for the key
    function getInt(bytes32 _key) external view returns (int256 _value);

    /// @dev get the address value for the given key
    /// @param _key the key of the value
    /// @return _value the address value for the key
    function getAddress(bytes32 _key) external view returns (address _value);

    /// @dev get the bool value for the given key
    /// @param _key the key of the value
    /// @return _value the bool value for the key
    function getBool(bytes32 _key) external view returns (bool _value);

    /// @dev get the string value for the given key
    /// @param _key the key of the value
    /// @return _value the string value for the key
    function getString(bytes32 _key) external view returns (string memory _value);

    /// @dev get the bytes32 value for the given key
    /// @param _key the key of the value
    /// @return _value the bytes32 value for the key
    function getBytes32(bytes32 _key) external view returns (bytes32 _value);

    /// @dev get the int array for the given key
    /// @param _key the key of the int array
    /// @return _value the int array for the key
    function getIntArray(bytes32 _key) external view returns (int256[] memory _value);

    /// @dev get the int array for the given key and index
    /// @param _key the key of the int array
    /// @param _index the index of the int array
    function getIntArrayAt(bytes32 _key, uint256 _index) external view returns (int256);

    /// @dev get the uint array for the given key
    /// @param _key the key of the uint array
    /// @return _value the uint array for the key
    function getUintArray(bytes32 _key) external view returns (uint256[] memory _value);

    /// @dev get the uint array for the given key and index
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array
    function getUintArrayAt(bytes32 _key, uint256 _index) external view returns (uint256);

    /// @dev get the address array for the given key
    /// @param _key the key of the address array
    /// @return _value the address array for the key
    function getAddressArray(bytes32 _key) external view returns (address[] memory _value);

    /// @dev get the address array for the given key and index
    /// @param _key the key of the address array
    /// @param _index the index of the address array
    function getAddressArrayAt(bytes32 _key, uint256 _index) external view returns (address);

    /// @dev get the bool array for the given key
    /// @param _key the key of the bool array
    /// @return _value the bool array for the key
    function getBoolArray(bytes32 _key) external view returns (bool[] memory _value);

    /// @dev get the bool array for the given key and index
    /// @param _key the key of the bool array
    /// @param _index the index of the bool array
    function getBoolArrayAt(bytes32 _key, uint256 _index) external view returns (bool);

    /// @dev get the string array for the given key
    /// @param _key the key of the string array
    /// @return _value the string array for the key
    function getStringArray(bytes32 _key) external view returns (string[] memory _value);

    /// @dev get the string array for the given key and index
    /// @param _key the key of the string array
    /// @param _index the index of the string array
    function getStringArrayAt(bytes32 _key, uint256 _index) external view returns (string memory);

    /// @dev get the bytes32 array for the given key
    /// @param _key the key of the bytes32 array
    /// @return _value the bytes32 array for the key
    function getBytes32Array(bytes32 _key) external view returns (bytes32[] memory _value);

    /// @dev get the bytes32 array for the given key and index
    /// @param _key the key of the bytes32 array
    /// @param _index the index of the bytes32 array
    function getBytes32ArrayAt(bytes32 _key, uint256 _index) external view returns (bytes32);

    /// @dev check whether the given value exists in the set
    /// @param _setKey the key of the set
    /// @param _value the value to check
    /// @return _exists whether the value exists in the set
    function containsAddress(bytes32 _setKey, address _value) external view returns (bool _exists);

    /// @dev get the length of the set
    /// @param _setKey the key of the set
    /// @return _length the length of the set
    function getAddressCount(bytes32 _setKey) external view returns (uint256 _length);

    /// @dev get the values of the set at the given index
    /// @param _setKey the key of the set
    /// @param _index the index of the value to return
    /// @return _value the value at the given index
    function getAddressValueAt(bytes32 _setKey, uint256 _index) external view returns (address _value);

    /// @dev check whether the key exists in the map
    /// @param _mapKey the key of the map
    /// @param _key the key to check
    /// @return _exists whether the key exists in the map
    function containsAddressToUint(bytes32 _mapKey, address _key) external view returns (bool _exists);

    /// @dev get the value associated with key. reverts if the key does not exist
    /// @param _mapKey the key of the map
    /// @param _key the key to get the value for
    /// @return _value the value associated with the key
    function getAddressToUintFor(bytes32 _mapKey, address _key) external view returns (uint256 _value);

    /// @dev tries to returns the value associated with key. does not revert if key is not in the map
    /// @param _mapKey the key of the map
    /// @param _key the key to get the value for
    /// @return _exists whether the key exists in the map
    /// @return _value the value associated with the key
    function tryGetAddressToUintFor(bytes32 _mapKey, address _key) external view returns (bool _exists, uint256 _value);

    /// @dev get the length of the map
    /// @param _mapKey the key of the map
    /// @return _length the length of the map
    function getAddressToUintCount(bytes32 _mapKey) external view returns (uint256 _length);

    /// @dev get the key and value pairs of the map in the given index
    /// @param _mapKey the key of the map
    /// @param _index the index of the key and value pair to return
    /// @return _key the key at the given index
    /// @return _value the value at the given index
    function getAddressToUintAt(bytes32 _mapKey, uint256 _index) external view returns (address _key, uint256 _value);

    /// ============================================================================================
    /// Setters
    /// ============================================================================================

    /// @dev set the uint value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setUint(bytes32 _key, uint256 _value) external;

    /// @dev add the input uint value to the existing uint value
    /// @param _key the key of the value
    /// @param _value the amount to add to the existing uint value
    function incrementUint(bytes32 _key, uint256 _value) external;

    /// @dev subtract the input uint value from the existing uint value
    /// @param _key the key of the value
    /// @param _value the amount to subtract from the existing uint value
    function decrementUint(bytes32 _key, uint256 _value) external;

    /// @dev set the int value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setInt(bytes32 _key, int256 _value) external;

    /// @dev add the input int value to the existing int value
    /// @param _key the key of the value
    /// @param _value the amount to add to the existing int value
    function incrementInt(bytes32 _key, int256 _value) external;

    /// @dev subtract the input int value from the existing int value
    /// @param _key the key of the value
    /// @param _value the amount to subtract from the existing int value
    function decrementInt(bytes32 _key, int256 _value) external;

    /// @dev set the address value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setAddress(bytes32 _key, address _value) external;

    /// @dev set the bool value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setBool(bytes32 _key, bool _value) external;

    /// @dev set the string value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setString(bytes32 _key, string memory _value) external;

    /// @dev set the bytes32 value for the given key
    /// @param _key the key of the value
    /// @param _value the value to set
    function setBytes32(bytes32 _key, bytes32 _value) external;

    /// @dev set the int array for the given key
    /// @param _key the key of the int array
    /// @param _value the value of the int array
    function setIntArray(bytes32 _key, int256[] memory _value) external;

    /// @dev push the input int value to the existing int array
    /// @param _key the key of the int array
    /// @param _value the value to push to the existing int array
    function pushIntArray(bytes32 _key, int256 _value) external;

    /// @dev set a specific index of the int array with the input value
    /// @param _key the key of the int array
    /// @param _index the index of the int array to set
    /// @param _value the value to set
    function setIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external;

    /// @dev increment the int value at the given index of the int array with the input value
    /// @param _key the key of the int array
    /// @param _index the index of the int array to increment
    /// @param _value the value to increment
    function incrementIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external;

    /// @dev decrement the int value at the given index of the int array with the input value
    /// @param _key the key of the int array
    /// @param _index the index of the int array to decrement
    /// @param _value the value to decrement
    function decrementIntArrayAt(bytes32 _key, uint256 _index, int256 _value) external;

    /// @dev set the uint array for the given key
    /// @param _key the key of the uint array
    /// @param _value the value of the uint array
    function setUintArray(bytes32 _key, uint256[] memory _value) external;

    /// @dev push the input uint value to the existing uint array
    /// @param _key the key of the uint array
    /// @param _value the value to push to the existing uint array
    function pushUintArray(bytes32 _key, uint256 _value) external;

    /// @dev set a specific index of the uint array with the input value
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array to set
    /// @param _value the value to set
    function setUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external;

    /// @dev increment the uint value at the given index of the uint array with the input value
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array to increment
    /// @param _value the value to increment
    function incrementUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external;

    /// @dev decrement the uint value at the given index of the uint array with the input value
    /// @param _key the key of the uint array
    /// @param _index the index of the uint array to decrement
    /// @param _value the value to decrement
    function decrementUintArrayAt(bytes32 _key, uint256 _index, uint256 _value) external;

    /// @dev set the address array for the given key
    /// @param _key the key of the address array
    /// @param _value the value of the address array
    function setAddressArray(bytes32 _key, address[] memory _value) external;

    /// @dev push the input address value to the existing address array
    /// @param _key the key of the address array
    /// @param _value the value to push to the existing address array
    function pushAddressArray(bytes32 _key, address _value) external;

    /// @dev set a specific index of the address array with the input value
    /// @param _key the key of the address array
    /// @param _index the index of the address array to set
    /// @param _value the value to set
    function setAddressArrayAt(bytes32 _key, uint256 _index, address _value) external;

    /// @dev set the bool array for the given key
    /// @param _key the key of the bool array
    /// @param _value the value of the bool array
    function setBoolArray(bytes32 _key, bool[] memory _value) external;

    /// @dev push the input bool value to the existing bool array
    /// @param _key the key of the bool array
    /// @param _value the value to push to the existing bool array
    function pushBoolArray(bytes32 _key, bool _value) external;

    /// @dev set a specific index of the bool array with the input value
    /// @param _key the key of the bool array
    /// @param _index the index of the bool array to set
    /// @param _value the value to set
    function setBoolArrayAt(bytes32 _key, uint256 _index, bool _value) external;

    /// @dev set the string array for the given key
    /// @param _key the key of the string array
    /// @param _value the value of the string array
    function setStringArray(bytes32 _key, string[] memory _value) external;

    /// @dev push the input string value to the existing string array
    /// @param _key the key of the string array
    /// @param _value the value to push to the existing string array
    function pushStringArray(bytes32 _key, string memory _value) external;

    /// @dev set a specific index of the string array with the input value
    /// @param _key the key of the string array
    /// @param _index the index of the string array to set
    /// @param _value the value to set
    function setStringArrayAt(bytes32 _key, uint256 _index, string memory _value) external;

    /// @dev set the bytes32 array for the given key
    /// @param _key the key of the bytes32 array
    /// @param _value the value of the bytes32 array
    function setBytes32Array(bytes32 _key, bytes32[] memory _value) external;

    /// @dev push the input bytes32 value to the existing bytes32 array
    /// @param _key the key of the bytes32 array
    /// @param _value the value to push to the existing bytes32 array
    function pushBytes32Array(bytes32 _key, bytes32 _value) external;

    /// @dev set a specific index of the bytes32 array with the input value
    /// @param _key the key of the bytes32 array
    /// @param _index the index of the bytes32 array to set
    /// @param _value the value to set
    function setBytes32ArrayAt(bytes32 _key, uint256 _index, bytes32 _value) external;

    /// @dev add the given value to the set
    /// @param _setKey the key of the set
    /// @param _value the value to add
    function addAddress(bytes32 _setKey, address _value) external;

    /// @dev add a key-value pair to a map, or updates the value for an existing key returns true 
    ///      if the key was added to the map, that is if it was not already present
    /// @param _mapKey the key of the map
    /// @param _key the key to add
    /// @param _value the value to add
    function addAddressToUint(bytes32 _mapKey, address _key, uint256 _value) external returns (bool _added);

    // ============================================================================================
    // Removers
    // ============================================================================================

    /// @dev delete the uint value for the given key
    /// @param _key the key of the value
    function removeUint(bytes32 _key) external;

    function removeInt(bytes32 _key) external;

    /// @dev delete the address value for the given key
    /// @param _key the key of the value
    function removeAddress(bytes32 _key) external;

    /// @dev delete the bool value for the given key
    /// @param _key the key of the value
    function removeBool(bytes32 _key) external;

    /// @dev delete the string value for the given key
    /// @param _key the key of the value
    function removeString(bytes32 _key) external;

    /// @dev delete the bytes32 value for the given key
    /// @param _key the key of the value
    function removeBytes32(bytes32 _key) external;

    /// @dev delete the uint array for the given key
    /// @param _key the key of the uint array
    function removeUintArray(bytes32 _key) external;

    /// @dev delete the int array for the given key
    /// @param _key the key of the int array
    function removeIntArray(bytes32 _key) external;

    /// @dev delete the address array for the given key
    /// @param _key the key of the address array
    function removeAddressArray(bytes32 _key) external;

    /// @dev delete the bool array for the given key
    /// @param _key the key of the bool array
    function removeBoolArray(bytes32 _key) external;

    /// @dev delete the string array for the given key
    /// @param _key the key of the string array
    function removeStringArray(bytes32 _key) external;

    /// @dev delete the bytes32 array for the given key
    /// @param _key the key of the bytes32 array
    function removeBytes32Array(bytes32 _key) external;

    /// @dev remove the given value from the set
    /// @param _setKey the key of the set
    /// @param _value the value to remove
    function removeAddress(bytes32 _setKey, address _value) external;

    /// @dev removes a value from a set
    ///      returns true if the key was removed from the map, that is if it was present
    /// @param _mapKey the key of the map
    /// @param _key the key to remove
    /// @param _removed whether or not the key was removed
    function removeUintToAddress(bytes32 _mapKey, address _key) external returns (bool _removed);

    // ============================================================================================
    // Events
    // ============================================================================================

    event UpdateOwnership(address owner, bool isActive);

    // ============================================================================================
    // Errors
    // ============================================================================================

    error Unauthorized();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

// ==============================================================
//  _____                 _      _____ _                        |
// |  _  |_ _ ___ ___ ___| |_   |   __|_|___ ___ ___ ___ ___    |
// |   __| | | . | . | -_|  _|  |   __| |   | .'|   |  _| -_|   |
// |__|  |___|  _|  _|___|_|    |__|  |_|_|_|__,|_|_|___|___|   |
//           |_| |_|                                            |
// ==============================================================
// ==================== BaseReaderHelper ========================
// ==============================================================

// Puppet Finance: https://github.com/GMX-Blueberry-Club/puppet-contracts

// Primary Author
// johnnyonline: https://github.com/johnnyonline

// Reviewers
// itburnz: https://github.com/nissoh

// ==============================================================

import {Keys} from "./Keys.sol";

import {IDataStore} from "../interfaces/IDataStore.sol";

library BaseReaderHelper {

    function puppetSubscriptionExpiry(IDataStore _dataStore, address _puppet, bytes32 _routeKey) public view returns (uint256) {
        uint256 _expiry = _dataStore.getUint(Keys.puppetSubscriptionExpiryKey(_puppet, _routeKey));
        if (_expiry > block.timestamp) {
            return _expiry;
        } else {
            return 0;
        }
    }

    function routeKey(IDataStore _dataStore, address _trader, bytes32 _routeTypeKey) external view returns (bytes32) {
        address _collateralToken = _dataStore.getAddress(Keys.routeTypeCollateralTokenKey(_routeTypeKey));
        address _indexToken = _dataStore.getAddress(Keys.routeTypeIndexTokenKey(_routeTypeKey));
        bool _isLong = _dataStore.getBool(Keys.routeTypeIsLongKey(_routeTypeKey));
        return keccak256(abi.encode(_trader, _collateralToken, _indexToken, _isLong));
    }

    function subscribedPuppets(IDataStore _dataStore, bytes32 _routeKey) external view returns (address[] memory) {
        bytes32 _routePuppetsKey = Keys.routePuppetsKey(_routeKey);
        uint256 _dirtyPuppetsLength = _dataStore.getAddressCount(_routePuppetsKey);
        address[] memory _dirtyPuppets = new address[](_dirtyPuppetsLength);
        uint256 _cleanCount = 0;
        for (uint256 i = 0; i < _dirtyPuppetsLength; i++) {
            address _puppet = _dataStore.getAddressValueAt(_routePuppetsKey, i);
            _dirtyPuppets[i] = _puppet;
            if (puppetSubscriptionExpiry(_dataStore, _puppet, _routeKey) > block.timestamp) _cleanCount++;
        }

        uint256 j = 0;
        address[] memory _cleanPuppets = new address[](_cleanCount);
        for (uint256 i = 0; i < _dirtyPuppetsLength; i++) {
            address _puppet = _dirtyPuppets[i];
            if (puppetSubscriptionExpiry(_dataStore, _puppet, _routeKey) > block.timestamp) {
                _cleanPuppets[j] = _puppet;
                j++;
            }
        }

        return _cleanPuppets;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Keys
/// @dev Keys for values in the DataStore
library Keys {

    // DataStore.uintValues

    /// @dev key for management fee (DataStore.uintValues)
    bytes32 public constant MANAGEMENT_FEE = keccak256(abi.encode("MANAGEMENT_FEE"));
    /// @dev key for withdrawal fee (DataStore.uintValues)
    bytes32 public constant WITHDRAWAL_FEE = keccak256(abi.encode("WITHDRAWAL_FEE"));
    /// @dev key for performance fee (DataStore.uintValues)
    bytes32 public constant PERFORMANCE_FEE = keccak256(abi.encode("PERFORMANCE_FEE"));

    // DataStore.intValues

    // DataStore.addressValues

    /// @dev key for sending received fees
    bytes32 public constant PLATFORM_FEES_RECIPIENT = keccak256(abi.encode("PLATFORM_FEES_RECIPIENT"));
    /// @dev key for subscribing to multiple Routes
    bytes32 public constant MULTI_SUBSCRIBER = keccak256(abi.encode("MULTI_SUBSCRIBER"));
    /// @dev key for the address of the keeper
    bytes32 public constant KEEPER = keccak256(abi.encode("KEEPER"));
    /// @dev key for the address of the Score Gauge
    bytes32 public constant SCORE_GAUGE = keccak256(abi.encode("SCORE_GAUGE"));
    /// @dev key for the address of the Route Factory
    bytes32 public constant ROUTE_FACTORY = keccak256(abi.encode("ROUTE_FACTORY"));
    /// @dev key for the address of the Route Setter
    bytes32 public constant ROUTE_SETTER = keccak256(abi.encode("ROUTE_SETTER"));
    /// @dev key for the address of the Orchestrator
    bytes32 public constant ORCHESTRATOR = keccak256(abi.encode("ORCHESTRATOR"));

    // DataStore.boolValues

    /// @dev key for pause status
    bytes32 public constant PAUSED = keccak256(abi.encode("PAUSED"));

    // DataStore.stringValues

    // DataStore.bytes32Values

    /// @dev key for the referral code
    bytes32 public constant REFERRAL_CODE = keccak256(abi.encode("REFERRAL_CODE"));

    // DataStore.addressArrayValues

    /// @dev key for the array of routes
    bytes32 public constant ROUTES = keccak256(abi.encode("ROUTES"));


    // -------------------------------------------------------------------------------------------

    // global

    function routeTypeKey(address _collateralToken, address _indexToken, bool _isLong, bytes memory _data) public pure returns (bytes32) {
        return keccak256(abi.encode(_collateralToken, _indexToken, _isLong, _data));
    }

    function routeTypeCollateralTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN", _routeTypeKey));
    }

    function routeTypeIndexTokenKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("INDEX_TOKEN", _routeTypeKey));
    }

    function routeTypeIsLongKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_LONG", _routeTypeKey));
    }

    function routeTypeDataKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("DATA", _routeTypeKey));
    }

    function platformAccountKey(address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PLATFORM_ACCOUNT", _asset));
    }

    function isRouteTypeRegisteredKey(bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_TYPE_REGISTERED", _routeTypeKey));
    }

    function isCollateralTokenKey(address _token) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_COLLATERAL_TOKEN", _token));
    }

    function collateralTokenDecimalsKey(address _collateralToken) public pure returns (bytes32) {
        return keccak256(abi.encode("COLLATERAL_TOKEN_DECIMALS", _collateralToken));
    }

    // route

    function routeCollateralTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_COLLATERAL_TOKEN", _route));
    }

    function routeIndexTokenKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_INDEX_TOKEN", _route));
    }

    function routeIsLongKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_IS_LONG", _route));
    }

    function routeTraderKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_TRADER", _route));
    }

    function routeDataKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_DATA", _route));
    }

    function routeRouteTypeKey(address _route) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ROUTE_TYPE", _route));
    }

    function routeAddressKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_ADDRESS", _routeKey));
    }

    function routePuppetsKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ROUTE_PUPPETS", _routeKey));
    }

    function targetLeverageKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TARGET_LEVERAGE", _routeKey));
    }

    function isKeeperRequestsKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("KEEPER_REQUESTS", _routeKey, _requestKey));
    }

    function isRouteRegisteredKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_ROUTE_REGISTERED", _routeKey));
    }

    function isWaitingForKeeperAdjustmentKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_WAITING_FOR_KEEPER_ADJUSTMENT", _routeKey));
    }

    function isKeeperAdjustmentEnabledKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_KEEPER_ADJUSTMENT_ENABLED", _routeKey));
    }

    function isPositionOpenKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("IS_POSITION_OPEN", _routeKey));
    }

    // route position

    function positionIndexKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_INDEX", _routeKey));
    }

    function positionPuppetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS", _positionIndex, _routeKey));
    }

    function positionTraderSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TRADER_SHARES", _positionIndex, _routeKey));
    }

    function positionPuppetsSharesKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_PUPPETS_SHARES", _positionIndex, _routeKey));
    }

    function positionLastTraderAmountInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_TRADER_AMOUNT_IN", _positionIndex, _routeKey));
    }

    function positionLastPuppetsAmountsInKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_LAST_PUPPETS_AMOUNTS_IN", _positionIndex, _routeKey));
    }

    function positionTotalSupplyKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_SUPPLY", _positionIndex, _routeKey));
    }

    function positionTotalAssetsKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("POSITION_TOTAL_ASSETS", _positionIndex, _routeKey));
    }

    function cumulativeVolumeGeneratedKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("CUMULATIVE_VOLUME_GENERATED", _routeKey));
    }

    function puppetsPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPETS_PNL", _routeKey));
    }

    function traderPnLKey(bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("TRADER_PNL", _routeKey));
    }

    // route request

    function requestKeyToAddCollateralRequestsIndexKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEY_TO_ADD_COLLATERAL_REQUESTS_INDEX", _routeKey, _requestKey));
    }

    function addCollateralRequestsIndexKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUESTS_INDEX", _positionIndex, _routeKey));
    }

    function addCollateralRequestPuppetsSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNTS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestPuppetsAmountInKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_PUPPETS_AMOUNT_IN", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestIsAdjustmentRequiredKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_IS_ADJUSTMENT_REQUIRED", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTraderSharesKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TRADER_SHARES", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalSupplyKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_SUPPLY", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function addCollateralRequestTotalAssetsKey(uint256 _positionIndex, uint256 _addCollateralRequestsIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("ADD_COLLATERAL_REQUEST_TOTAL_ASSETS", _positionIndex, _addCollateralRequestsIndex, _routeKey));
    }

    function pendingSizeDeltaKey(bytes32 _routeKey, bytes32 _requestKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PENDING_SIZE_DELTA", _routeKey, _requestKey));
    }

    function requestKeysKey(uint256 _positionIndex, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("REQUEST_KEYS", _positionIndex, _routeKey));
    }

    // puppet

    function puppetAllowancesKey(address _puppet) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_ALLOWANCES", _puppet));
    }

    function puppetSubscriptionExpiryKey(address _puppet, bytes32 _routeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_SUBSCRIPTION_EXPIRY", _puppet, _routeKey));
    }

    function puppetDepositAccountKey(address _puppet, address _asset) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_DEPOSIT_ACCOUNT", _puppet, _asset));
    }

    function puppetThrottleLimitKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_THROTTLE_LIMIT", _puppet, _routeTypeKey));
    }

    function puppetLastPositionOpenedTimestampKey(address _puppet, bytes32 _routeTypeKey) public pure returns (bytes32) {
        return keccak256(abi.encode("PUPPET_LAST_POSITION_OPENED_TIMESTAMP", _puppet, _routeTypeKey));
    }
}