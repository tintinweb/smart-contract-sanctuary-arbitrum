// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";
import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/token/types/Token6.sol";
import "../interfaces/IEmptySetReserve.sol";

interface IBatcher {
    event Wrap(address indexed to, UFixed18 amount);
    event Unwrap(address indexed to, UFixed18 amount);
    event Rebalance(UFixed18 newMinted, UFixed18 newRedeemed);
    event Close(UFixed18 amount);

    error BatcherNotImplementedError();
    error BatcherBalanceMismatchError(UFixed18 oldBalance, UFixed18 newBalance);

    function RESERVE() external view returns (IEmptySetReserve); // solhint-disable-line func-name-mixedcase
    function USDC() external view returns (Token6); // solhint-disable-line func-name-mixedcase
    function DSU() external view returns (Token18); // solhint-disable-line func-name-mixedcase
    function totalBalance() external view returns (UFixed18);
    function wrap(UFixed18 amount, address to) external;
    function unwrap(UFixed18 amount, address to) external;
    function rebalance() external;
}

//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";

interface IEmptySetReserve {
    event Redeem(address indexed account, uint256 costAmount, uint256 redeemAmount);
    event Mint(address indexed account, uint256 mintAmount, uint256 costAmount);
    event Repay(address indexed account, uint256 repayAmount);

    function debt(address borrower) external view returns (UFixed18);
    function repay(address borrower, UFixed18 amount) external;
    function mint(UFixed18 amount) external;
    function redeem(UFixed18 amount) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;
import {
    IFactory,
    IMarket,
    Position,
    Local,
    UFixed18Lib,
    UFixed18,
    OracleVersion,
    RiskParameter
} from "@equilibria/perennial-v2/contracts/interfaces/IMarket.sol";
import { IBatcher } from "@equilibria/emptyset-batcher/interfaces/IBatcher.sol";
import { IEmptySetReserve } from "@equilibria/emptyset-batcher/interfaces/IEmptySetReserve.sol";
import { UFixed6, UFixed6Lib } from "@equilibria/root/number/types/UFixed6.sol";
import { Fixed6, Fixed6Lib } from "@equilibria/root/number/types/Fixed6.sol";
import { Token6 } from "@equilibria/root/token/types/Token6.sol";
import { Token18 } from "@equilibria/root/token/types/Token18.sol";
import { TriggerOrder } from "../types/TriggerOrder.sol";
import { InterfaceFee } from "../types/InterfaceFee.sol";

interface IMultiInvoker {
    enum PerennialAction {
        NO_OP,           // 0
        UPDATE_POSITION, // 1
        UPDATE_VAULT,    // 2
        PLACE_ORDER,     // 3
        CANCEL_ORDER,    // 4
        EXEC_ORDER,      // 5
        COMMIT_PRICE,    // 6
        __LIQUIDATE__DEPRECATED,
        APPROVE          // 8
    }

    struct Invocation {
        PerennialAction action;
        bytes args;
    }

    event OperatorUpdated(address indexed account, address indexed operator, bool newEnabled);
    event KeeperFeeCharged(address indexed account, address indexed market, address indexed to, UFixed6 fee);
    event OrderPlaced(address indexed account, IMarket indexed market, uint256 indexed nonce, TriggerOrder order);
    event OrderExecuted(address indexed account, IMarket indexed market, uint256 nonce);
    event OrderCancelled(address indexed account, IMarket indexed market, uint256 nonce);
    event InterfaceFeeCharged(address indexed account, IMarket indexed market, InterfaceFee fee);

    // sig: 0x42ecdedb
    error MultiInvokerUnauthorizedError();
    // sig: 0x88d67968
    error MultiInvokerOrderMustBeSingleSidedError();
    // sig: 0xbccd78e7
    error MultiInvokerMaxFeeExceededError();
    // sig: 0x47b7c1b0
    error MultiInvokerInvalidInstanceError();
    // sig: 0xb6befb58
    error MultiInvokerInvalidOrderError();
    // sig: 0x6f462962
    error MultiInvokerCantExecuteError();

    function updateOperator(address operator, bool newEnabled) external;
    function operators(address account, address operator) external view returns (bool);
    function invoke(address account, Invocation[] calldata invocations) external payable;
    function invoke(Invocation[] calldata invocations) external payable;
    function marketFactory() external view returns (IFactory);
    function vaultFactory() external view returns (IFactory);
    function batcher() external view returns (IBatcher);
    function reserve() external view returns (IEmptySetReserve);
    function keepBufferBase() external view returns (uint256);
    function keepBufferCalldata() external view returns (uint256);
    function latestNonce() external view returns (uint256);
    function orders(address account, IMarket market, uint256 nonce) external view returns (TriggerOrder memory);
    function canExecuteOrder(address account, IMarket market, uint256 nonce) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;
import { UFixed6, UFixed6Lib } from "@equilibria/root/number/types/UFixed6.sol";

/// @dev Interface fee type
struct InterfaceFee {
    /// @dev The amount of the fee
    UFixed6 amount;

    /// @dev The address to send the fee to
    address receiver;

    /// @dev Whether or not to unwrap the fee
    bool unwrap;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed6.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IMarket.sol";
import "@equilibria/perennial-v2/contracts/types/Position.sol";
import "./InterfaceFee.sol";

struct TriggerOrder {
    uint8 side;
    int8 comparison;
    UFixed6 fee;
    Fixed6 price;
    Fixed6 delta;
    InterfaceFee interfaceFee1;
    InterfaceFee interfaceFee2;
}
using TriggerOrderLib for TriggerOrder global;
struct StoredTriggerOrder {
    /* slot 0 */
    uint8 side;         // 0 = maker, 1 = long, 2 = short
    int8 comparison;    // -2 = lt, -1 = lte, 0 = eq, 1 = gte, 2 = gt
    uint64 fee;         // <= 18.44tb
    int64 price;        // <= 9.22t
    int64 delta;        // <= 9.22t
    bytes6 __unallocated0__;

    /* slot 1 */
    address interfaceFeeReceiver1;
    uint48 interfaceFeeAmount1;      // <= 281m
    bool interfaceFeeUnwrap1;
    bytes5 __unallocated1__;

    /* slot 2 */
    address interfaceFeeReceiver2;
    uint48 interfaceFeeAmount2;      // <= 281m
    bool interfaceFeeUnwrap2;
    bytes5 __unallocated2__;
}
struct TriggerOrderStorage { StoredTriggerOrder value; }
using TriggerOrderStorageLib for TriggerOrderStorage global;

/**
 * @title TriggerOrderLib
 * @notice Library for TriggerOrder logic and data.
 */
library TriggerOrderLib {
    // @notice Returns whether the trigger order is fillable at the latest price
    // @param self The trigger order
    // @param latestVersion The latest oracle version
    // @return Whether the trigger order is fillable
    function fillable(TriggerOrder memory self, OracleVersion memory latestVersion) internal pure returns (bool) {
        if (!latestVersion.valid) return false;
        if (self.comparison == 1) return latestVersion.price.gte(self.price);
        if (self.comparison == -1) return latestVersion.price.lte(self.price);
        return false;
    }

    // @notice Executes the trigger order on the given position
    // @param self The trigger order
    // @param currentPosition The current position
    // @return The collateral delta, if any
    function execute(
        TriggerOrder memory self,
        Position memory currentPosition
    ) internal pure returns (Fixed6 collateral) {
        // update position
        if (self.side == 0)
            currentPosition.maker = self.delta.isZero() ?
                UFixed6Lib.ZERO :
                UFixed6Lib.from(Fixed6Lib.from(currentPosition.maker).add(self.delta));
        if (self.side == 1)
            currentPosition.long = self.delta.isZero() ?
                UFixed6Lib.ZERO :
                UFixed6Lib.from(Fixed6Lib.from(currentPosition.long).add(self.delta));
        if (self.side == 2)
            currentPosition.short = self.delta.isZero() ?
                UFixed6Lib.ZERO :
                UFixed6Lib.from(Fixed6Lib.from(currentPosition.short).add(self.delta));

        // Handles collateral withdrawal magic value
        if (self.side == 3) collateral = (self.delta.eq(Fixed6.wrap(type(int64).min)) ? Fixed6Lib.MIN : self.delta);
    }
}

library TriggerOrderStorageLib {
    // sig: 0xf3469aa7
    error TriggerOrderStorageInvalidError();

    function read(TriggerOrderStorage storage self) internal view returns (TriggerOrder memory) {
        StoredTriggerOrder memory storedValue = self.value;
        return TriggerOrder(
            uint8(storedValue.side),
            int8(storedValue.comparison),
            UFixed6.wrap(uint256(storedValue.fee)),
            Fixed6.wrap(int256(storedValue.price)),
            Fixed6.wrap(int256(storedValue.delta)),
            InterfaceFee(
                UFixed6.wrap(uint256(storedValue.interfaceFeeAmount1)),
                storedValue.interfaceFeeReceiver1,
                storedValue.interfaceFeeUnwrap1
            ),
            InterfaceFee(
                UFixed6.wrap(uint256(storedValue.interfaceFeeAmount2)),
                storedValue.interfaceFeeReceiver2,
                storedValue.interfaceFeeUnwrap2
            )
        );
    }

    function store(TriggerOrderStorage storage self, TriggerOrder memory newValue) internal {
        if (newValue.side > type(uint8).max) revert TriggerOrderStorageInvalidError();
        if (newValue.comparison > type(int8).max) revert TriggerOrderStorageInvalidError();
        if (newValue.comparison < type(int8).min) revert TriggerOrderStorageInvalidError();
        if (newValue.fee.gt(UFixed6.wrap(type(uint64).max))) revert TriggerOrderStorageInvalidError();
        if (newValue.price.gt(Fixed6.wrap(type(int64).max))) revert TriggerOrderStorageInvalidError();
        if (newValue.price.lt(Fixed6.wrap(type(int64).min))) revert TriggerOrderStorageInvalidError();
        if (newValue.delta.gt(Fixed6.wrap(type(int64).max))) revert TriggerOrderStorageInvalidError();
        if (newValue.delta.lt(Fixed6.wrap(type(int64).min))) revert TriggerOrderStorageInvalidError();
        if (newValue.interfaceFee1.amount.gt(UFixed6.wrap(type(uint48).max))) revert TriggerOrderStorageInvalidError();
        if (newValue.interfaceFee2.amount.gt(UFixed6.wrap(type(uint48).max))) revert TriggerOrderStorageInvalidError();

        self.value = StoredTriggerOrder(
            uint8(newValue.side),
            int8(newValue.comparison),
            uint64(UFixed6.unwrap(newValue.fee)),
            int64(Fixed6.unwrap(newValue.price)),
            int64(Fixed6.unwrap(newValue.delta)),
            bytes6(0),
            newValue.interfaceFee1.receiver,
            uint48(UFixed6.unwrap(newValue.interfaceFee1.amount)),
            newValue.interfaceFee1.unwrap,
            bytes5(0),
            newValue.interfaceFee2.receiver,
            uint48(UFixed6.unwrap(newValue.interfaceFee2.amount)),
            newValue.interfaceFee2.unwrap,
            bytes5(0)
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IInstance.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IOracleProvider.sol";

interface IOracle is IOracleProvider, IInstance {
    // sig: 0x8852e53b
    error OracleOutOfSyncError();
    // sig: 0x0f7338e5
    error OracleOutOfOrderCommitError();

    event OracleUpdated(IOracleProvider newProvider);

    /// @dev The state for a single epoch
    struct Epoch {
        /// @dev The oracle provider for this epoch
        IOracleProvider provider;

        /// @dev The last timestamp that this oracle provider is valid
        uint96 timestamp;
    }

    /// @dev The global state for oracle
    struct Global {
        /// @dev The current epoch
        uint128 current;

        /// @dev The latest epoch
        uint128 latest;
    }

    function initialize(IOracleProvider initialProvider) external;
    function update(IOracleProvider newProvider) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IInstance.sol";
import "@equilibria/root/number/types/UFixed6.sol";
import "@equilibria/root/token/types/Token18.sol";
import "./IOracleProvider.sol";
import "../types/OracleVersion.sol";
import "../types/MarketParameter.sol";
import "../types/RiskParameter.sol";
import "../types/Version.sol";
import "../types/Local.sol";
import "../types/Global.sol";
import "../types/Position.sol";
import "../types/Checkpoint.sol";
import "../libs/VersionLib.sol";

interface IMarket is IInstance {
    struct MarketDefinition {
        Token18 token;
        IOracleProvider oracle;
    }

    struct Context {
        ProtocolParameter protocolParameter;
        MarketParameter marketParameter;
        RiskParameter riskParameter;
        OracleVersion latestOracleVersion;
        uint256 currentTimestamp;
        Global global;
        Local local;
        PositionContext latestPosition;
        OrderContext pending;
    }

    struct SettlementContext {
        Version latestVersion;
        Checkpoint latestCheckpoint;
        OracleVersion orderOracleVersion;
    }

    struct UpdateContext {
        bool operator;
        address liquidator;
        address referrer;
        UFixed6 referralFee;
        OrderContext order;
        PositionContext currentPosition;
    }

    struct PositionContext {
        Position global;
        Position local;
    }

    struct OrderContext {
        Order global;
        Order local;
    }

    event Updated(address indexed sender, address indexed account, uint256 version, UFixed6 newMaker, UFixed6 newLong, UFixed6 newShort, Fixed6 collateral, bool protect, address referrer);
    event OrderCreated(address indexed account, Order order);
    event PositionProcessed(uint256 orderId, Order order, VersionAccumulationResult accumulationResult);
    event AccountPositionProcessed(address indexed account, uint256 orderId, Order order, CheckpointAccumulationResult accumulationResult);
    event BeneficiaryUpdated(address newBeneficiary);
    event CoordinatorUpdated(address newCoordinator);
    event FeeClaimed(address indexed account, UFixed6 amount);
    event ExposureClaimed(address indexed account, Fixed6 amount);
    event ParameterUpdated(MarketParameter newParameter);
    event RiskParameterUpdated(RiskParameter newRiskParameter);
    event OracleUpdated(IOracleProvider newOracle);

    // sig: 0x0fe90964
    error MarketInsufficientLiquidityError();
    // sig: 0x00e2b6a8
    error MarketInsufficientMarginError();
    // sig: 0x442145e5
    error MarketInsufficientCollateralError();
    // sig: 0xba555da7
    error MarketProtectedError();
    // sig: 0x6ed43d8e
    error MarketMakerOverLimitError();
    // sig: 0x29ab4c44
    error MarketClosedError();
    // sig: 0x07732aee
    error MarketCollateralBelowLimitError();
    // sig: 0x5bdace60
    error MarketOperatorNotAllowedError();
    // sig: 0x8a68c1dc
    error MarketNotSingleSidedError();
    // sig: 0x736f9fda
    error MarketOverCloseError();
    // sig: 0x935bdc21
    error MarketExceedsPendingIdLimitError();
    // sig: 0x9bca0625
    error MarketNotCoordinatorError();
    // sig: 0xb602d086
    error MarketNotBeneficiaryError();
    // sig: 0x534f7fe6
    error MarketInvalidProtectionError();
    // sig: 0xab1e3a00
    error MarketStalePriceError();
    // sig: 0x15f9ae70
    error MarketEfficiencyUnderLimitError();
    // sig: 0x7302d51a
    error MarketInvalidMarketParameterError(uint256 code);
    // sig: 0xc5f0e98a
    error MarketInvalidRiskParameterError(uint256 code);
    // sig: 0x9dbdc5fd
    error MarketInvalidReferrerError();
    // sig: 0x5c5cb438
    error MarketSettleOnlyError();

    // sig: 0x2142bc27
    error GlobalStorageInvalidError();
    // sig: 0xc83d08ec
    error LocalStorageInvalidError();
    // sig: 0x7c53e926
    error MarketParameterStorageInvalidError();
    // sig: 0x98eb4898
    error PositionStorageLocalInvalidError();
    // sig: 0x7ecd083f
    error RiskParameterStorageInvalidError();
    // sig: 0xd2777e72
    error VersionStorageInvalidError();

    function initialize(MarketDefinition calldata definition_) external;
    function token() external view returns (Token18);
    function oracle() external view returns (IOracleProvider);
    function payoff() external view returns (address);
    function positions(address account) external view returns (Position memory);
    function pendingOrders(address account, uint256 id) external view returns (Order memory);
    function pendings(address account) external view returns (Order memory);
    function locals(address account) external view returns (Local memory);
    function versions(uint256 timestamp) external view returns (Version memory);
    function position() external view returns (Position memory);
    function pendingOrder(uint256 id) external view returns (Order memory);
    function pending() external view returns (Order memory);
    function global() external view returns (Global memory);
    function checkpoints(address account, uint256 version) external view returns (Checkpoint memory);
    function liquidators(address account, uint256 id) external view returns (address);
    function referrers(address account, uint256 id) external view returns (address);
    function settle(address account) external;
    function update(address account, UFixed6 newMaker, UFixed6 newLong, UFixed6 newShort, Fixed6 collateral, bool protect) external;
    function update(address account, UFixed6 newMaker, UFixed6 newLong, UFixed6 newShort, Fixed6 collateral, bool protect, address referrer) external;
    function parameter() external view returns (MarketParameter memory);
    function riskParameter() external view returns (RiskParameter memory);
    function updateOracle(IOracleProvider newOracle) external;
    function updateParameter(address newBeneficiary, address newCoordinator, MarketParameter memory newParameter) external;
    function updateRiskParameter(RiskParameter memory newRiskParameter, bool isMigration) external;
    function claimFee() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/attribute/interfaces/IFactory.sol";
import "../types/ProtocolParameter.sol";
import "./IMarket.sol";

interface IMarketFactory is IFactory {
    event ParameterUpdated(ProtocolParameter newParameter);
    event OperatorUpdated(address indexed account, address indexed operator, bool newEnabled);
    event ReferralFeeUpdated(address indexed referrer, UFixed6 newFee);
    event MarketCreated(IMarket indexed market, IMarket.MarketDefinition definition);

    // sig: 0x0a37dc74
    error FactoryInvalidPayoffError();
    // sig: 0x5116bce5
    error FactoryInvalidOracleError();
    // sig: 0x213e2260
    error FactoryAlreadyRegisteredError();

    // sig: 0x4dc1bc59
    error ProtocolParameterStorageInvalidError();

    function oracleFactory() external view returns (IFactory);
    function parameter() external view returns (ProtocolParameter memory);
    function operators(address account, address operator) external view returns (bool);
    function referralFee(address referrer) external view returns (UFixed6);
    function markets(IOracleProvider oracle) external view returns (IMarket);
    function initialize() external;
    function updateParameter(ProtocolParameter memory newParameter) external;
    function updateOperator(address operator, bool newEnabled) external;
    function updateReferralFee(address referrer, UFixed6 newReferralFee) external;
    function create(IMarket.MarketDefinition calldata definition) external returns (IMarket);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../types/OracleVersion.sol";
import "./IMarket.sol";

/// @dev OracleVersion Invariants
///       - Version are requested at a timestamp, the current timestamp is determined by the oracle
///         - The current timestamp may not be equal to block.timestamp, for example when batching timestamps
///       - Versions are allowed to "fail" and will be marked as .valid = false
///         - Invalid versions will always include the latest valid price as its price field
///       - Versions must be committed in order, i.e. all requested versions prior to latestVersion must be available
///       - Non-requested versions may be committed, but will not receive a settlement fee
///         - This is useful for immediately liquidating an account with a valid off-chain price in between orders
///         - Satisfying the above constraints, only versions more recent than the latest version may be committed
///       - Current must always be greater than Latest, never equal
interface IOracleProvider {
    // sig: 0x652fafab
    error OracleProviderUnauthorizedError();

    event OracleProviderVersionRequested(uint256 indexed version);
    event OracleProviderVersionFulfilled(OracleVersion version);

    function request(IMarket market, address account) external;
    function status() external view returns (OracleVersion memory, uint256);
    function latest() external view returns (OracleVersion memory);
    function current() external view returns (uint256);
    function at(uint256 timestamp) external view returns (OracleVersion memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/accumulator/types/Accumulator6.sol";
import "../types/OracleVersion.sol";
import "../types/RiskParameter.sol";
import "../types/Global.sol";
import "../types/Local.sol";
import "../types/Order.sol";
import "../types/Version.sol";
import "../types/Checkpoint.sol";

struct CheckpointAccumulationResult {
    /// @dev Total Collateral change due to pnl, funding, and interest from the previous position to the next position
    Fixed6 collateral;

    /// @dev Linear fee accumulated from the previous position to the next position
    Fixed6 linearFee;

    /// @dev Proportional fee accumulated from the previous position to the next position
    Fixed6 proportionalFee;

    /// @dev Adiabatic fee accumulated from the previous position to the next position
    Fixed6 adiabaticFee;

    /// @dev Settlement fee charged for this checkpoint
    UFixed6 settlementFee;

    /// @dev Liquidation fee accumulated for this checkpoint (only if the order is protected)
    UFixed6 liquidationFee;

    /// @dev Subtractive fee accumulated from the previous position to the next position (this amount is included in the linear fee)
    UFixed6 subtractiveFee;
}

/// @title CheckpointLib
/// @notice Manages the logic for the local order accumulation
library CheckpointLib {
    /// @notice Accumulate pnl and fees from the latest position to next position
    /// @param self The Local object to update
    /// @param order The next order
    /// @param fromPosition The previous latest position
    /// @param fromVersion The previous latest version
    /// @param toVersion The next latest version
    /// @return next The next checkpoint
    /// @return result The accumulated pnl and fees
    function accumulate(
        Checkpoint memory self,
        Order memory order,
        Position memory fromPosition,
        Version memory fromVersion,
        Version memory toVersion
    ) external pure returns (Checkpoint memory next, CheckpointAccumulationResult memory result) {
        // accumulate
        result.collateral = _accumulateCollateral(fromPosition, fromVersion, toVersion);
        (result.linearFee, result.subtractiveFee) = _accumulateLinearFee(order, toVersion);
        result.proportionalFee = _accumulateProportionalFee(order, toVersion);
        result.adiabaticFee = _accumulateAdiabaticFee(order, toVersion);
        result.settlementFee = _accumulateSettlementFee(order, toVersion);
        result.liquidationFee = _accumulateLiquidationFee(order, toVersion);

        // update checkpoint
        next.collateral = self.collateral
            .sub(self.tradeFee)                       // trade fee processed post settlement
            .sub(Fixed6Lib.from(self.settlementFee))  // settlement / liquidation fee processed post settlement
            .add(self.transfer)                       // deposit / withdrawal processed post settlement
            .add(result.collateral);                  // incorporate collateral change at this settlement
        next.transfer = order.collateral;
        next.tradeFee = result.linearFee.add(result.proportionalFee).add(result.adiabaticFee);
        next.settlementFee = result.settlementFee.add(result.liquidationFee);
    }

    /// @notice Accumulate pnl, funding, and interest from the latest position to next position
    /// @param fromPosition The previous latest position
    /// @param fromVersion The previous latest version
    /// @param toVersion The next version
    function _accumulateCollateral(
        Position memory fromPosition,
        Version memory fromVersion,
        Version memory toVersion
    ) private pure returns (Fixed6) {
        return toVersion.makerValue.accumulated(fromVersion.makerValue, fromPosition.maker)
            .add(toVersion.longValue.accumulated(fromVersion.longValue, fromPosition.long))
            .add(toVersion.shortValue.accumulated(fromVersion.shortValue, fromPosition.short));
    }

    /// @notice Accumulate trade fees for the next position
    /// @param order The next order
    /// @param toVersion The next version
    function _accumulateLinearFee(
        Order memory order,
        Version memory toVersion
    ) private pure returns (Fixed6 linearFee, UFixed6 subtractiveFee) {
        Fixed6 makerLinearFee = Fixed6Lib.ZERO
            .sub(toVersion.makerLinearFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.makerTotal()));
        Fixed6 takerLinearFee = Fixed6Lib.ZERO
            .sub(toVersion.takerLinearFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.takerTotal()));

        UFixed6 makerSubtractiveFee = order.makerTotal().isZero() ?
            UFixed6Lib.ZERO :
            UFixed6Lib.from(makerLinearFee).muldiv(order.makerReferral, order.makerTotal());
        UFixed6 takerSubtractiveFee = order.takerTotal().isZero() ?
            UFixed6Lib.ZERO :
            UFixed6Lib.from(takerLinearFee).muldiv(order.takerReferral, order.takerTotal());

        linearFee = makerLinearFee.add(takerLinearFee);
        subtractiveFee = makerSubtractiveFee.add(takerSubtractiveFee);
    }

    /// @notice Accumulate trade fees for the next position
    /// @param order The next order
    /// @param toVersion The next version
    function _accumulateProportionalFee(
        Order memory order,
        Version memory toVersion
    ) private pure returns (Fixed6) {
        return Fixed6Lib.ZERO
            .sub(toVersion.makerProportionalFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.makerTotal()))
            .sub(toVersion.takerProportionalFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.takerTotal()));
    }

    /// @notice Accumulate adiabatic fees for the next position
    /// @param order The next order
    /// @param toVersion The next version
    function _accumulateAdiabaticFee(
        Order memory order,
        Version memory toVersion
    ) private pure returns (Fixed6) {
        return Fixed6Lib.ZERO
            .sub(toVersion.makerPosFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.makerPos))
            .sub(toVersion.makerNegFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.makerNeg))
            .sub(toVersion.takerPosFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.takerPos()))
            .sub(toVersion.takerNegFee.accumulated(Accumulator6(Fixed6Lib.ZERO), order.takerNeg()));
    }


    /// @notice Accumulate settlement fees for the next position
    /// @param order The next order
    /// @param toVersion The next version
    function _accumulateSettlementFee(
        Order memory order,
        Version memory toVersion
    ) private pure returns (UFixed6) {
        return toVersion.settlementFee.accumulated(Accumulator6(Fixed6Lib.ZERO), UFixed6Lib.from(order.orders)).abs();
    }

    /// @notice Accumulate liquidation fees for the next position
    /// @param order The next order
    /// @param toVersion The next version
    function _accumulateLiquidationFee(
        Order memory order,
        Version memory toVersion
    ) private pure returns (UFixed6 liquidationFee) {
        if (order.protected())
            return toVersion.liquidationFee.accumulated(Accumulator6(Fixed6Lib.ZERO), UFixed6Lib.ONE).abs();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/accumulator/types/Accumulator6.sol";
import "@equilibria/root/accumulator/types/UAccumulator6.sol";
import "../types/ProtocolParameter.sol";
import "../types/MarketParameter.sol";
import "../types/RiskParameter.sol";
import "../types/Global.sol";
import "../types/Position.sol";
import "../types/Version.sol";

/// @dev Individual accumulation values
struct VersionAccumulationResult {
    /// @dev Sum of the linear and proportional fees
    UFixed6 positionFee;

    /// @dev Position fee received by makers
    UFixed6 positionFeeMaker;

    /// @dev Position fee received by the protocol
    UFixed6 positionFeeProtocol;

    /// @dev Total subtractive position fees credited to referrers
    UFixed6 positionFeeSubtractive;

    /// @dev Profit/loss accrued from the oustanding adiabatic fee credit or liability
    Fixed6 positionFeeExposure;

    /// @dev Portion of exposure fees charged to makers
    Fixed6 positionFeeExposureMaker;

    /// @dev Portion of exposure fees charged to the protocol
    Fixed6 positionFeeExposureProtocol;

    /// @dev Sum of the adiabatic fees charged or credited
    Fixed6 positionFeeImpact;

    /// @dev Funding accrued by makers
    Fixed6 fundingMaker;

    /// @dev Funding accrued by longs
    Fixed6 fundingLong;

    /// @dev Funding accrued by shorts
    Fixed6 fundingShort;

    /// @dev Funding received by the protocol
    UFixed6 fundingFee;

    /// @dev Interest accrued by makers
    Fixed6 interestMaker;

    /// @dev Interest accrued by longs
    Fixed6 interestLong;

    /// @dev Interest accrued by shorts
    Fixed6 interestShort;

    /// @dev Interest received by the protocol
    UFixed6 interestFee;

    /// @dev Price-based profit/loss accrued by makers
    Fixed6 pnlMaker;

    /// @dev Price-based profit/loss accrued by longs
    Fixed6 pnlLong;

    /// @dev Price-based profit/loss accrued by shorts
    Fixed6 pnlShort;

    /// @dev Total settlement fee charged
    UFixed6 settlementFee;

    /// @dev Snapshot of the riskParameter.liquidationFee at the version (0 if not valid)
    UFixed6 liquidationFee;
}

/// @title VersionLib
/// @notice Manages the logic for the global order accumulation
library VersionLib {
    struct AccumulationContext {
        Global global;
        Position fromPosition;
        Order order;
        OracleVersion fromOracleVersion;
        OracleVersion toOracleVersion;
        MarketParameter marketParameter;
        RiskParameter riskParameter;
    }

    /// @notice Accumulates the global state for the period from `fromVersion` to `toOracleVersion`
    /// @param self The Version object to update
    /// @param global The global state
    /// @param fromPosition The previous latest position
    /// @param order The new order
    /// @param fromOracleVersion The previous latest oracle version
    /// @param toOracleVersion The next latest oracle version
    /// @param marketParameter The market parameter
    /// @param riskParameter The risk parameter
    /// @return next The accumulated version
    /// @return nextGlobal The next global state
    /// @return result The accumulation result
    function accumulate(
        Version memory self,
        Global memory global,
        Position memory fromPosition,
        Order memory order,
        OracleVersion memory fromOracleVersion,
        OracleVersion memory toOracleVersion,
        MarketParameter memory marketParameter,
        RiskParameter memory riskParameter
    ) external pure returns (Version memory next, Global memory nextGlobal, VersionAccumulationResult memory result) {
        AccumulationContext memory context = AccumulationContext(
            global,
            fromPosition,
            order,
            fromOracleVersion,
            toOracleVersion,
            marketParameter,
            riskParameter
        );

        // setup next accumulators
        _next(self, next);

        // record oracle version
        next.valid = toOracleVersion.valid;
        global.latestPrice = toOracleVersion.price;

        // accumulate settlement fee
        result.settlementFee = _accumulateSettlementFee(next, context);

        // accumulate liquidation fee
        result.liquidationFee = _accumulateLiquidationFee(next, context);

        // accumulate linear fee
        _accumulateLinearFee(next, context, result);

        // accumulate proportional fee
        _accumulateProportionalFee(next, context, result);

        // accumulate adiabatic fee
        _accumulateAdiabaticFee(next, context, result);

        // if closed, don't accrue anything else
        if (marketParameter.closed) return (next, global, result);

        // accumulate funding
        (result.fundingMaker, result.fundingLong, result.fundingShort, result.fundingFee) =
            _accumulateFunding(next, context);

        // accumulate interest
        (result.interestMaker, result.interestLong, result.interestShort, result.interestFee) =
            _accumulateInterest(next, context);

        // accumulate P&L
        (result.pnlMaker, result.pnlLong, result.pnlShort) = _accumulatePNL(next, context);

        return (next, global, result);
    }

    /// @notice Copies over the version-over-version accumulators to prepare the next version
    /// @param self The Version object to update
    function _next(Version memory self, Version memory next) internal pure {
        next.makerValue._value = self.makerValue._value;
        next.longValue._value = self.longValue._value;
        next.shortValue._value = self.shortValue._value;
    }

    /// @notice Globally accumulates settlement fees since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    function _accumulateSettlementFee(
        Version memory next,
        AccumulationContext memory context
    ) private pure returns (UFixed6 settlementFee) {
        settlementFee = context.order.orders == 0 ? UFixed6Lib.ZERO : context.marketParameter.settlementFee;
        next.settlementFee.decrement(Fixed6Lib.from(settlementFee), UFixed6Lib.from(context.order.orders));
    }

    /// @notice Globally accumulates hypothetical liquidation fee since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    function _accumulateLiquidationFee(
        Version memory next,
        AccumulationContext memory context
    ) private pure returns (UFixed6 liquidationFee) {
        liquidationFee = context.toOracleVersion.valid ? context.riskParameter.liquidationFee : UFixed6Lib.ZERO;
        next.liquidationFee.decrement(Fixed6Lib.from(liquidationFee), UFixed6Lib.ONE);
    }

    /// @notice Globally accumulates linear fees since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    function _accumulateLinearFee(
        Version memory next,
        AccumulationContext memory context,
        VersionAccumulationResult memory result
    ) private pure {
        (UFixed6 makerLinearFee, UFixed6 makerSubtractiveFee) = _accumulateSubtractiveFee(
            context.riskParameter.makerFee.linear(
                Fixed6Lib.from(context.order.makerTotal()),
                context.toOracleVersion.price.abs()
            ),
            context.order.makerTotal(),
            context.order.makerReferral,
            next.makerLinearFee
        );

        (UFixed6 takerLinearFee, UFixed6 takerSubtractiveFee) = _accumulateSubtractiveFee(
            context.riskParameter.takerFee.linear(
                Fixed6Lib.from(context.order.takerTotal()),
                context.toOracleVersion.price.abs()
            ),
            context.order.takerTotal(),
            context.order.takerReferral,
            next.takerLinearFee
        );

        UFixed6 linearFee = makerLinearFee.add(takerLinearFee);

        UFixed6 protocolFee = context.fromPosition.maker.isZero() ?
            linearFee :
            context.marketParameter.positionFee.mul(linearFee);
        UFixed6 positionFeeMaker = linearFee.sub(protocolFee);
        next.makerValue.increment(Fixed6Lib.from(positionFeeMaker), context.fromPosition.maker);

        result.positionFee = result.positionFee.add(linearFee);
        result.positionFeeMaker = result.positionFeeMaker.add(positionFeeMaker);
        result.positionFeeProtocol = result.positionFeeProtocol.add(protocolFee);
        result.positionFeeSubtractive = result.positionFeeSubtractive.add(makerSubtractiveFee).add(takerSubtractiveFee);
    }

    /// @notice Globally accumulates subtractive fees since last oracle update
    /// @param linearFee The linear fee to accumulate
    /// @param total The total order size for the fee
    /// @param referral The referral size for the fee
    /// @param linearFeeAccumulator The accumulator for the linear fee
    /// @return newLinearFee The new linear fee after subtractive fees
    /// @return subtractiveFee The total subtractive fee
    function _accumulateSubtractiveFee(
        UFixed6 linearFee,
        UFixed6 total,
        UFixed6 referral,
        Accumulator6 memory linearFeeAccumulator
    ) private pure returns (UFixed6 newLinearFee, UFixed6 subtractiveFee) {
        linearFeeAccumulator.decrement(Fixed6Lib.from(linearFee), total);
        subtractiveFee = total.isZero() ? UFixed6Lib.ZERO : linearFee.muldiv(referral, total);
        newLinearFee = linearFee.sub(subtractiveFee);
    }

    /// @notice Globally accumulates proportional fees since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    function _accumulateProportionalFee(
        Version memory next,
        AccumulationContext memory context,
        VersionAccumulationResult memory result
    ) private pure {
        UFixed6 makerProportionalFee = context.riskParameter.makerFee.proportional(
            Fixed6Lib.from(context.order.makerTotal()),
            context.toOracleVersion.price.abs()
        );
        next.makerProportionalFee.decrement(Fixed6Lib.from(makerProportionalFee), context.order.makerTotal());

        UFixed6 takerProportionalFee = context.riskParameter.takerFee.proportional(
            Fixed6Lib.from(context.order.takerTotal()),
            context.toOracleVersion.price.abs()
        );
        next.takerProportionalFee.decrement(Fixed6Lib.from(takerProportionalFee), context.order.takerTotal());

        UFixed6 proportionalFee = makerProportionalFee.add(takerProportionalFee);
        UFixed6 protocolFee = context.fromPosition.maker.isZero() ?
            proportionalFee :
            context.marketParameter.positionFee.mul(proportionalFee);
        UFixed6 positionFeeMaker = proportionalFee.sub(protocolFee);
        next.makerValue.increment(Fixed6Lib.from(positionFeeMaker), context.fromPosition.maker);

        result.positionFee = result.positionFee.add(proportionalFee);
        result.positionFeeMaker = result.positionFeeMaker.add(positionFeeMaker);
        result.positionFeeProtocol = result.positionFeeProtocol.add(protocolFee);
    }

    /// @notice Globally accumulates adiabatic fees since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    function _accumulateAdiabaticFee(
        Version memory next,
        AccumulationContext memory context,
        VersionAccumulationResult memory result
    ) private pure {
        Fixed6 exposure = context.riskParameter.takerFee.exposure(context.fromPosition.skew())
            .add(context.riskParameter.makerFee.exposure(context.fromPosition.maker));

        _accumulatePositionFeeComponentExposure(next, context, result, exposure);

        Fixed6 adiabaticFee;

        // position fee from positive skew taker orders
        adiabaticFee = context.riskParameter.takerFee.adiabatic(
            context.fromPosition.skew(),
            Fixed6Lib.from(context.order.takerPos()),
            context.toOracleVersion.price.abs()
        );
        next.takerPosFee.decrement(adiabaticFee, context.order.takerPos());
        result.positionFeeImpact = result.positionFeeImpact.add(adiabaticFee);

        // position fee from negative skew taker orders
        adiabaticFee = context.riskParameter.takerFee.adiabatic(
            context.fromPosition.skew().add(Fixed6Lib.from(context.order.takerPos())),
            Fixed6Lib.from(-1, context.order.takerNeg()),
            context.toOracleVersion.price.abs()
        );
        next.takerNegFee.decrement(adiabaticFee, context.order.takerNeg());
        result.positionFeeImpact = result.positionFeeImpact.add(adiabaticFee);

        // position fee from negative skew maker orders
        adiabaticFee = context.riskParameter.makerFee.adiabatic(
            context.fromPosition.maker,
            Fixed6Lib.from(-1, context.order.makerNeg),
            context.toOracleVersion.price.abs()
        );
        next.makerNegFee.decrement(adiabaticFee, context.order.makerNeg);
        result.positionFeeImpact = result.positionFeeImpact.add(adiabaticFee);

        // position fee from positive skew maker orders
        adiabaticFee = context.riskParameter.makerFee.adiabatic(
            context.fromPosition.maker.sub(context.order.makerNeg),
            Fixed6Lib.from(context.order.makerPos),
            context.toOracleVersion.price.abs()
        );
        next.makerPosFee.decrement(adiabaticFee, context.order.makerPos);
        result.positionFeeImpact = result.positionFeeImpact.add(adiabaticFee);
    }

    /// @notice Globally accumulates single component of the position fees exposure since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    /// @param result The accumulation result
    /// @param latestExposure The latest exposure
    function _accumulatePositionFeeComponentExposure(
        Version memory next,
        AccumulationContext memory context,
        VersionAccumulationResult memory result,
        Fixed6 latestExposure
    ) private pure {
        Fixed6 impactExposure = context.toOracleVersion.price.sub(context.fromOracleVersion.price).mul(latestExposure);
        Fixed6 impactExposureMaker = impactExposure.mul(Fixed6Lib.NEG_ONE);
        Fixed6 impactExposureProtocol = context.fromPosition.maker.isZero() ? impactExposureMaker : Fixed6Lib.ZERO;
        impactExposureMaker = impactExposureMaker.sub(impactExposureProtocol);
        next.makerValue.increment(impactExposureMaker, context.fromPosition.maker);

        result.positionFeeExposure = impactExposure;
        result.positionFeeExposureProtocol = impactExposureProtocol;
        result.positionFeeExposureMaker = impactExposureMaker;
    }

    /// @notice Globally accumulates all long-short funding since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    /// @return fundingMaker The total funding accrued by makers
    /// @return fundingLong The total funding accrued by longs
    /// @return fundingShort The total funding accrued by shorts
    /// @return fundingFee The total fee accrued from funding accumulation
    function _accumulateFunding(Version memory next, AccumulationContext memory context) private pure returns (
        Fixed6 fundingMaker,
        Fixed6 fundingLong,
        Fixed6 fundingShort,
        UFixed6 fundingFee
    ) {
        Fixed6 toSkew = context.toOracleVersion.valid ?
            context.fromPosition.skew().add(context.order.long()).sub(context.order.short()) :
            context.fromPosition.skew();

        // Compute long-short funding rate
        Fixed6 funding = context.global.pAccumulator.accumulate(
            context.riskParameter.pController,
            toSkew.unsafeDiv(Fixed6Lib.from(context.riskParameter.takerFee.scale)).min(Fixed6Lib.ONE).max(Fixed6Lib.NEG_ONE),
            context.fromOracleVersion.timestamp,
            context.toOracleVersion.timestamp,
            context.fromPosition.takerSocialized().mul(context.fromOracleVersion.price.abs())
        );

        // Handle maker receive-only status
        if (context.riskParameter.makerReceiveOnly && funding.sign() != context.fromPosition.skew().sign())
            funding = funding.mul(Fixed6Lib.NEG_ONE);

        // Initialize long and short funding
        (fundingLong, fundingShort) = (Fixed6Lib.NEG_ONE.mul(funding), funding);

        // Compute fee spread
        fundingFee = funding.abs().mul(context.marketParameter.fundingFee);
        Fixed6 fundingSpread = Fixed6Lib.from(fundingFee).div(Fixed6Lib.from(2));

        // Adjust funding with spread
        (fundingLong, fundingShort) = (
            fundingLong.sub(Fixed6Lib.from(fundingFee)).add(fundingSpread),
            fundingShort.sub(fundingSpread)
        );

        // Redirect net portion of minor's side to maker
        if (context.fromPosition.long.gt(context.fromPosition.short)) {
            fundingMaker = fundingShort.mul(Fixed6Lib.from(context.fromPosition.socializedMakerPortion()));
            fundingShort = fundingShort.sub(fundingMaker);
        }
        if (context.fromPosition.short.gt(context.fromPosition.long)) {
            fundingMaker = fundingLong.mul(Fixed6Lib.from(context.fromPosition.socializedMakerPortion()));
            fundingLong = fundingLong.sub(fundingMaker);
        }

        next.makerValue.increment(fundingMaker, context.fromPosition.maker);
        next.longValue.increment(fundingLong, context.fromPosition.long);
        next.shortValue.increment(fundingShort, context.fromPosition.short);
    }

    /// @notice Globally accumulates all maker interest since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    /// @return interestMaker The total interest accrued by makers
    /// @return interestLong The total interest accrued by longs
    /// @return interestShort The total interest accrued by shorts
    /// @return interestFee The total fee accrued from interest accumulation
    function _accumulateInterest(
        Version memory next,
        AccumulationContext memory context
    ) private pure returns (Fixed6 interestMaker, Fixed6 interestLong, Fixed6 interestShort, UFixed6 interestFee) {
        UFixed6 notional = context.fromPosition.long.add(context.fromPosition.short).min(context.fromPosition.maker).mul(context.fromOracleVersion.price.abs());

        // Compute maker interest
        UFixed6 interest = context.riskParameter.utilizationCurve.accumulate(
            context.fromPosition.utilization(context.riskParameter),
            context.fromOracleVersion.timestamp,
            context.toOracleVersion.timestamp,
            notional
        );

        // Compute fee
        interestFee = interest.mul(context.marketParameter.interestFee);

        // Adjust long and short funding with spread
        interestLong = Fixed6Lib.from(
            context.fromPosition.major().isZero() ?
            interest :
            interest.muldiv(context.fromPosition.long, context.fromPosition.long.add(context.fromPosition.short))
        );
        interestShort = Fixed6Lib.from(interest).sub(interestLong);
        interestMaker = Fixed6Lib.from(interest.sub(interestFee));

        interestLong = interestLong.mul(Fixed6Lib.NEG_ONE);
        interestShort = interestShort.mul(Fixed6Lib.NEG_ONE);
        next.makerValue.increment(interestMaker, context.fromPosition.maker);
        next.longValue.increment(interestLong, context.fromPosition.long);
        next.shortValue.increment(interestShort, context.fromPosition.short);
    }

    /// @notice Globally accumulates position profit & loss since last oracle update
    /// @param next The Version object to update
    /// @param context The accumulation context
    /// @return pnlMaker The total pnl accrued by makers
    /// @return pnlLong The total pnl accrued by longs
    /// @return pnlShort The total pnl accrued by shorts
    function _accumulatePNL(
        Version memory next,
        AccumulationContext memory context
    ) private pure returns (Fixed6 pnlMaker, Fixed6 pnlLong, Fixed6 pnlShort) {
        pnlLong = context.toOracleVersion.price.sub(context.fromOracleVersion.price)
            .mul(Fixed6Lib.from(context.fromPosition.longSocialized()));
        pnlShort = context.fromOracleVersion.price.sub(context.toOracleVersion.price)
            .mul(Fixed6Lib.from(context.fromPosition.shortSocialized()));
        pnlMaker = pnlLong.add(pnlShort).mul(Fixed6Lib.NEG_ONE);

        next.longValue.increment(pnlLong, context.fromPosition.long);
        next.shortValue.increment(pnlShort, context.fromPosition.short);
        next.makerValue.increment(pnlMaker, context.fromPosition.maker);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/accumulator/types/Accumulator6.sol";
import "./OracleVersion.sol";
import "./RiskParameter.sol";
import "./Global.sol";
import "./Local.sol";
import "./Order.sol";
import "./Version.sol";

/// @dev Checkpoint type
struct Checkpoint {
    /// @dev The trade fee that the order incurred at the checkpoint settlement
    Fixed6 tradeFee;

    // @dev The settlement and liquidation fee that the order incurred at the checkpoint settlement
    UFixed6 settlementFee;

    /// @dev The amount deposited or withdrawn at the checkpoint settlement
    Fixed6 transfer;

    /// @dev The collateral at the time of the checkpoint settlement
    Fixed6 collateral;
}
struct CheckpointStorage { uint256 slot0; }
using CheckpointStorageLib for CheckpointStorage global;

/// @dev Manually encodes and decodes the Checkpoint struct into storage.
///
///     struct StoredCheckpoint {
///         /* slot 0 */
///         int48 tradeFee;
///         uint48 settlementFee;
///         int64 transfer;
///         int64 collateral;
///     }
///
library CheckpointStorageLib {
    // sig: 0xba85116a
    error CheckpointStorageInvalidError();

    function read(CheckpointStorage storage self) internal view returns (Checkpoint memory) {
        uint256 slot0 = self.slot0;
        return Checkpoint(
            Fixed6.wrap(int256(slot0 << (256 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 48 - 48)) >> (256 - 48)),
            Fixed6.wrap(int256(slot0 << (256 - 48 - 48 - 64)) >> (256 - 64)),
            Fixed6.wrap(int256(slot0 << (256 - 48 - 48 - 64 - 64)) >> (256 - 64))
        );
    }

    function store(CheckpointStorage storage self, Checkpoint memory newValue) external {
        if (newValue.tradeFee.gt(Fixed6.wrap(type(int48).max))) revert CheckpointStorageInvalidError();
        if (newValue.tradeFee.lt(Fixed6.wrap(type(int48).min))) revert CheckpointStorageInvalidError();
        if (newValue.settlementFee.gt(UFixed6.wrap(type(uint48).max))) revert CheckpointStorageInvalidError();
        if (newValue.transfer.gt(Fixed6.wrap(type(int64).max))) revert CheckpointStorageInvalidError();
        if (newValue.transfer.lt(Fixed6.wrap(type(int64).min))) revert CheckpointStorageInvalidError();
        if (newValue.collateral.gt(Fixed6.wrap(type(int64).max))) revert CheckpointStorageInvalidError();
        if (newValue.collateral.lt(Fixed6.wrap(type(int64).min))) revert CheckpointStorageInvalidError();

        uint256 encoded0 =
            uint256(Fixed6.unwrap(newValue.tradeFee)        << (256 - 48)) >> (256 - 48) |
            uint256(UFixed6.unwrap(newValue.settlementFee)  << (256 - 48)) >> (256 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.transfer)        << (256 - 64)) >> (256 - 48 - 48 - 64) |
            uint256(Fixed6.unwrap(newValue.collateral)      << (256 - 64)) >> (256 - 48 - 48 - 64 - 64);

        assembly {
            sstore(self.slot, encoded0)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/pid/types/PAccumulator6.sol";
import "./ProtocolParameter.sol";
import "./MarketParameter.sol";
import "../libs/VersionLib.sol";

/// @dev Global type
struct Global {
    /// @dev The current position ID
    uint256 currentId;

    /// @dev The latest position id
    uint256 latestId;

    /// @dev The accrued protocol fee
    UFixed6 protocolFee;

    /// @dev The accrued oracle fee
    UFixed6 oracleFee;

    /// @dev The accrued risk fee
    UFixed6 riskFee;

    /// @dev The accrued donation
    UFixed6 donation;

    /// @dev The latest seen price
    Fixed6 latestPrice;

    /// @dev The accumulated market exposure
    Fixed6 exposure;

    /// @dev The current PAccumulator state
    PAccumulator6 pAccumulator;
}
using GlobalLib for Global global;
struct GlobalStorage { uint256 slot0; uint256 slot1; } // SECURITY: must remain at (2) slots
using GlobalStorageLib for GlobalStorage global;

/// @title Global
/// @notice Holds the global market state
library GlobalLib {
    /// @notice Increments the fees by `amount` using current parameters
    /// @param self The Global object to update
    /// @param newLatestId The new latest position id
    /// @param accumulation The accumulation result
    /// @param marketParameter The current market parameters
    /// @param protocolParameter The current protocol parameters
    function update(
        Global memory self,
        uint256 newLatestId,
        VersionAccumulationResult memory accumulation,
        MarketParameter memory marketParameter,
        ProtocolParameter memory protocolParameter
    ) internal pure {
        UFixed6 marketFee = accumulation.positionFeeProtocol
            .add(accumulation.fundingFee)
            .add(accumulation.interestFee);

        UFixed6 protocolFeeAmount = marketFee.mul(protocolParameter.protocolFee);
        UFixed6 marketFeeAmount = marketFee.sub(protocolFeeAmount);

        UFixed6 oracleFeeAmount = marketFeeAmount.mul(marketParameter.oracleFee);
        UFixed6 riskFeeAmount = marketFeeAmount.mul(marketParameter.riskFee);
        UFixed6 donationAmount = marketFeeAmount.sub(oracleFeeAmount).sub(riskFeeAmount);

        self.latestId = newLatestId;
        self.protocolFee = self.protocolFee.add(protocolFeeAmount);
        self.oracleFee = self.oracleFee.add(accumulation.settlementFee).add(oracleFeeAmount);
        self.riskFee = self.riskFee.add(riskFeeAmount);
        self.donation = self.donation.add(donationAmount);
        self.exposure = self.exposure.add(accumulation.positionFeeExposureProtocol);
    }
}

/// @dev Manually encodes and decodes the Global struct into storage.
///
///     struct StoredGlobal {
///         /* slot 0 */
///         uint32 currentId;           // <= 4.29b
///         uint32 latestId;            // <= 4.29b
///         uint48 protocolFee;         // <= 281m
///         uint48 oracleFee;           // <= 281m
///         uint48 riskFee;             // <= 281m
///         uint48 donation;            // <= 281m
///
///         /* slot 1 */
///         int32 pAccumulator.value;   // <= 214000%
///         int24 pAccumulator.skew;    // <= 838%
///         int64 latestPrice;          // <= 9.22t
///         int64 exposure;             // <= 9.22t
///     }
///
library GlobalStorageLib {
    // sig: 0x2142bc27
    error GlobalStorageInvalidError();

    function read(GlobalStorage storage self) internal view returns (Global memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);
        return Global(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            uint256(slot0 << (256 - 32 - 32)) >> (256 - 32),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48 - 48 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 48 - 48 - 48 - 48)) >> (256 - 48)),
            Fixed6.wrap(int256(slot1 << (256 - 32 - 24 - 64)) >> (256 - 64)),
            Fixed6.wrap(int256(slot1 << (256 - 32 - 24 - 64 - 64)) >> (256 - 64)),
            PAccumulator6(
                Fixed6.wrap(int256(slot1 << (256 - 32)) >> (256 - 32)),
                Fixed6.wrap(int256(slot1 << (256 - 32 - 24)) >> (256 - 24))
            )
        );
    }

    function store(GlobalStorage storage self, Global memory newValue) external {
        if (newValue.currentId > uint256(type(uint32).max)) revert GlobalStorageInvalidError();
        if (newValue.latestId > uint256(type(uint32).max)) revert GlobalStorageInvalidError();
        if (newValue.protocolFee.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.oracleFee.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.riskFee.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.donation.gt(UFixed6.wrap(type(uint48).max))) revert GlobalStorageInvalidError();
        if (newValue.latestPrice.gt(Fixed6.wrap(type(int64).max))) revert GlobalStorageInvalidError();
        if (newValue.latestPrice.lt(Fixed6.wrap(type(int64).min))) revert GlobalStorageInvalidError();
        if (newValue.exposure.gt(Fixed6.wrap(type(int64).max))) revert GlobalStorageInvalidError();
        if (newValue.exposure.lt(Fixed6.wrap(type(int64).min))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._value.gt(Fixed6.wrap(type(int32).max))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._value.lt(Fixed6.wrap(type(int32).min))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._skew.gt(Fixed6.wrap(type(int24).max))) revert GlobalStorageInvalidError();
        if (newValue.pAccumulator._skew.lt(Fixed6.wrap(type(int24).min))) revert GlobalStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.currentId << (256 - 32)) >> (256 - 32) |
            uint256(newValue.latestId << (256 - 32)) >> (256 - 32 - 32) |
            uint256(UFixed6.unwrap(newValue.protocolFee) << (256 - 48)) >> (256 - 32 - 32 - 48) |
            uint256(UFixed6.unwrap(newValue.oracleFee) << (256 - 48)) >> (256 - 32 - 32 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.riskFee) << (256 - 48)) >> (256 - 32 - 32 - 48 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.donation) << (256 - 48)) >> (256 - 32 - 32 - 48 - 48 - 48 - 48);

        uint256 encoded1 =
            uint256(Fixed6.unwrap(newValue.pAccumulator._value) << (256 - 32)) >> (256 - 32) |
            uint256(Fixed6.unwrap(newValue.pAccumulator._skew) << (256 - 24)) >> (256 - 32 - 24) |
            uint256(Fixed6.unwrap(newValue.latestPrice) << (256 - 64)) >> (256 - 32 - 24 - 64) |
            uint256(Fixed6.unwrap(newValue.exposure) << (256 - 64)) >> (256 - 32 - 24 - 64 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";
import "@equilibria/root/accumulator/types/UAccumulator6.sol";
import "@equilibria/root/accumulator/types/Accumulator6.sol";
import "./Version.sol";
import "./Position.sol";
import "./RiskParameter.sol";
import "./OracleVersion.sol";
import "./Order.sol";
import "./Checkpoint.sol";
import "../libs/CheckpointLib.sol";

/// @dev Local type
struct Local {
    /// @dev The current position id
    uint256 currentId;

    /// @dev The latest position id
    uint256 latestId;

    /// @dev The collateral balance
    Fixed6 collateral;

    /// @dev The claimable balance
    UFixed6 claimable;
}
using LocalLib for Local global;
struct LocalStorage { uint256 slot0; uint256 slot1; }
using LocalStorageLib for LocalStorage global;

/// @title Local
/// @notice Holds the local account state
library LocalLib {
    /// @notice Updates the collateral with the new deposit or withdrwal
    /// @param self The Local object to update
    /// @param transfer The amount to update the collateral by
    function update(Local memory self, Fixed6 transfer) internal pure {
        self.collateral = self.collateral.add(transfer);
    }

    /// @notice Updates the collateral with the new collateral change
    /// @param self The Local object to update
    /// @param accumulation The accumulation result
    function update(Local memory self, uint256 newId, CheckpointAccumulationResult memory accumulation) internal pure {
        Fixed6 tradeFee = accumulation.linearFee
            .add(accumulation.proportionalFee)
            .add(accumulation.adiabaticFee);
        self.collateral = self.collateral
            .add(accumulation.collateral)
            .sub(tradeFee)
            .sub(Fixed6Lib.from(accumulation.settlementFee))
            .sub(Fixed6Lib.from(accumulation.liquidationFee));
        self.latestId = newId;
    }

    /// @notice Updates the claimable with the new amount
    /// @param self The Local object to update
    /// @param amount The amount to update the claimable by
    function credit(Local memory self, UFixed6 amount) internal pure {
        self.claimable = self.claimable.add(amount);
    }
}

/// @dev Manually encodes and decodes the Local struct into storage.
///
///     struct StoredLocal {
///         /* slot 0 */
///         uint32 currentId;       // <= 4.29b
///         uint32 latestId;        // <= 4.29b
///         int64 collateral;       // <= 9.22t
///         uint64 claimable;       // <= 18.44t
///         bytes4 __DEPRECATED;    // UNSAFE UNTIL RESET
///
///         /* slot 1 */
///         bytes28 __DEPRECATED;   // UNSAFE UNTIL RESET
///     }
///
library LocalStorageLib {
    // sig: 0xc83d08ec
    error LocalStorageInvalidError();

    function read(LocalStorage storage self) internal view returns (Local memory) {
        uint256 slot0 = self.slot0;
        return Local(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            uint256(slot0 << (256 - 32 - 32)) >> (256 - 32),
            Fixed6.wrap(int256(slot0 << (256 - 32 - 32 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 64 - 64)) >> (256 - 64))
        );
    }

    function store(LocalStorage storage self, Local memory newValue) internal {
        if (newValue.currentId > uint256(type(uint32).max)) revert LocalStorageInvalidError();
        if (newValue.latestId > uint256(type(uint32).max)) revert LocalStorageInvalidError();
        if (newValue.collateral.gt(Fixed6.wrap(type(int64).max))) revert LocalStorageInvalidError();
        if (newValue.collateral.lt(Fixed6.wrap(type(int64).min))) revert LocalStorageInvalidError();
        if (newValue.claimable.gt(UFixed6.wrap(type(uint64).max))) revert LocalStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.currentId << (256 - 32)) >> (256 - 32) |
            uint256(newValue.latestId << (256 - 32)) >> (256 - 32 - 32) |
            uint256(Fixed6.unwrap(newValue.collateral) << (256 - 64)) >> (256 - 32 - 32 - 64) |
            uint256(UFixed6.unwrap(newValue.claimable) << (256 - 64)) >> (256 - 32 - 32 - 64 - 64);
        uint256 encoded1; // reset deprecated storage on settlement

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/token/types/Token18.sol";
import "@equilibria/root/number/types/UFixed6.sol";
import "./ProtocolParameter.sol";

/// @dev MarketParameter type
struct MarketParameter {
    /// @dev The fee that is taken out of funding
    UFixed6 fundingFee;

    /// @dev The fee that is taken out of interest
    UFixed6 interestFee;

    /// @dev The fee that is taken out of maker and taker fees
    UFixed6 positionFee;

    /// @dev The share of the collected fees that is paid to the oracle
    UFixed6 oracleFee;

    /// @dev The share of the collected fees that is paid to the risk coordinator
    UFixed6 riskFee;

    /// @dev The maximum amount of orders that can be pending at one time globally
    uint256 maxPendingGlobal;

    /// @dev The maximum amount of orders that can be pending at one time per account
    uint256 maxPendingLocal;

    /// @dev The fixed fee that is charge whenever an oracle request occurs
    UFixed6 settlementFee;

    /// @dev Whether longs and shorts can always close even when they'd put the market into socialization
    bool takerCloseAlways;

    /// @dev Whether makers can always close even when they'd put the market into socialization
    bool makerCloseAlways;

    /// @dev Whether the market is in close-only mode
    bool closed;

     /// @dev Whether the market is in settle-only mode
    bool settle;
}
struct MarketParameterStorage { uint256 slot0; uint256 slot1; } // SECURITY: must remain at (2) slots
using MarketParameterStorageLib for MarketParameterStorage global;

/// @dev Manually encodes and decodes the MarketParameter struct into storage.
///
///    struct StoredMarketParameter {
///        /* slot 0 */
///        uint24 fundingFee;          // <= 1677%
///        uint24 interestFee;         // <= 1677%
///        uint24 positionFee;         // <= 1677%
///        uint24 oracleFee;           // <= 1677%
///        uint24 riskFee;             // <= 1677%
///        uint16 maxPendingGlobal;    // <= 65k
///        uint16 maxPendingLocal;     // <= 65k
///        uint48 settlementFee;       // <= 281m
///        uint8 flags;
///    }
///
library MarketParameterStorageLib {
    // sig: 0x7c53e926
    error MarketParameterStorageInvalidError();

    function read(MarketParameterStorage storage self) internal view returns (MarketParameter memory) {
        uint256 slot0 = self.slot0;

        uint256 flags = uint256(slot0) >> (256 - 8);
        (bool takerCloseAlways, bool makerCloseAlways, bool closed, bool settle) =
            (flags & 0x01 == 0x01, flags & 0x02 == 0x02, flags & 0x04 == 0x04, flags & 0x08 == 0x08);

        return MarketParameter(
            UFixed6.wrap(uint256(slot0 << (256 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
            uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 16)) >> (256 - 16),
            uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16)) >> (256 - 16),
            UFixed6.wrap(uint256(slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16 - 48)) >> (256 - 48)),
            takerCloseAlways,
            makerCloseAlways,
            closed,
            settle
        );
    }

    function validate(MarketParameter memory self, ProtocolParameter memory protocolParameter) private pure {
        if (self.settlementFee.gt(protocolParameter.maxFeeAbsolute)) revert MarketParameterStorageInvalidError();

        if (self.fundingFee.max(self.interestFee).max(self.positionFee).gt(protocolParameter.maxCut))
            revert MarketParameterStorageInvalidError();

        if (self.oracleFee.add(self.riskFee).gt(UFixed6Lib.ONE)) revert MarketParameterStorageInvalidError();
    }

    function validateAndStore(
        MarketParameterStorage storage self,
        MarketParameter memory newValue,
        ProtocolParameter memory protocolParameter
    ) external {
        validate(newValue, protocolParameter);

        if (newValue.maxPendingGlobal > uint256(type(uint16).max)) revert MarketParameterStorageInvalidError();
        if (newValue.maxPendingLocal > uint256(type(uint16).max)) revert MarketParameterStorageInvalidError();

        _store(self, newValue);
    }

    function _store(MarketParameterStorage storage self, MarketParameter memory newValue) private {
        uint256 flags = (newValue.takerCloseAlways ? 0x01 : 0x00) |
            (newValue.makerCloseAlways ? 0x02 : 0x00) |
            (newValue.closed ? 0x04 : 0x00) |
            (newValue.settle ? 0x08 : 0x00);

        uint256 encoded0 =
            uint256(UFixed6.unwrap(newValue.fundingFee) << (256 - 24)) >> (256 - 24) |
            uint256(UFixed6.unwrap(newValue.interestFee) << (256 - 24)) >> (256 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.positionFee) << (256 - 24)) >> (256 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.oracleFee) << (256 - 24)) >> (256 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.riskFee) << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24) |
            uint256(newValue.maxPendingGlobal << (256 - 16)) >> (256 - 24 - 24 - 24 - 24 - 24 - 16) |
            uint256(newValue.maxPendingLocal << (256 - 16)) >> (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16) |
            uint256(UFixed6.unwrap(newValue.settlementFee) << (256 - 48)) >> (256 - 24 - 24 - 24 - 24 - 24 - 16 - 16 - 48) |
            uint256(flags << (256 - 8)) >> (256 - 24 - 24 - 24 - 24 - 24 - 32 - 32 - 32 - 32 - 8);

        assembly {
            sstore(self.slot, encoded0)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/Fixed6.sol";

/// @dev A singular oracle version with its corresponding data
struct OracleVersion {
    /// @dev the timestamp of the oracle update
    uint256 timestamp;

    /// @dev The oracle price of the corresponding version
    Fixed6 price;

    /// @dev Whether the version is valid
    bool valid;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./OracleVersion.sol";
import "./RiskParameter.sol";
import "./Global.sol";
import "./Local.sol";
import "./Position.sol";
import "./MarketParameter.sol";

/// @dev Order type
struct Order {
    /// @dev The timestamp of the order
    uint256 timestamp;

    /// @dev The quantity of orders that are included in this order
    uint256 orders;

    /// @dev The change in the collateral
    Fixed6 collateral;

    /// @dev The positive skew maker order size
    UFixed6 makerPos;

    /// @dev The negative skew maker order size
    UFixed6 makerNeg;

    /// @dev The positive skew long order size
    UFixed6 longPos;

    /// @dev The negative skew long order size
    UFixed6 longNeg;

    /// @dev The positive skew short order size
    UFixed6 shortPos;

    /// @dev The negative skew short order size
    UFixed6 shortNeg;

    /// @dev The protection status semaphore
    uint256 protection;

    /// @dev The referral fee
    UFixed6 makerReferral;

    /// @dev The referral fee
    UFixed6 takerReferral;
}
using OrderLib for Order global;
struct OrderStorageGlobal { uint256 slot0; uint256 slot1; uint256 slot2; } // SECURITY: must remain at (3) slots
using OrderStorageGlobalLib for OrderStorageGlobal global;
struct OrderStorageLocal { uint256 slot0; uint256 slot1; } // SECURITY: must remain at (2) slots
using OrderStorageLocalLib for OrderStorageLocal global;

/// @title Order
/// @notice Holds the state for an account's update order
library OrderLib {
    /// @notice Returns whether the order is ready to be settled
    /// @param self The order object to check
    /// @param latestVersion The latest oracle version
    /// @return Whether the order is ready to be settled
    function ready(Order memory self, OracleVersion memory latestVersion) internal pure returns (bool) {
        return latestVersion.timestamp >= self.timestamp;
    }

    /// @notice Prepares the next order from the current order
    /// @param self The order object to update
    /// @param timestamp The current timestamp
    function next(Order memory self, uint256 timestamp) internal pure  {
        invalidate(self);
        (self.timestamp, self.orders, self.collateral, self.protection) = (timestamp, 0, Fixed6Lib.ZERO, 0);
    }

    /// @notice Invalidates the order
    /// @param self The order object to update
    function invalidate(Order memory self) internal pure {
        (self.makerReferral, self.takerReferral) =
            (UFixed6Lib.ZERO, UFixed6Lib.ZERO);
        (self.makerPos, self.makerNeg, self.longPos, self.longNeg, self.shortPos, self.shortNeg) =
            (UFixed6Lib.ZERO, UFixed6Lib.ZERO, UFixed6Lib.ZERO, UFixed6Lib.ZERO, UFixed6Lib.ZERO, UFixed6Lib.ZERO);
    }

    /// @notice Creates a new order from the current position and an update request
    /// @param timestamp The current timestamp
    /// @param position The current position
    /// @param collateral The change in the collateral
    /// @param newMaker The new maker
    /// @param newLong The new long
    /// @param newShort The new short
    /// @param protect Whether to protect the order
    /// @param referralFee The referral fee
    /// @return newOrder The resulting order
    function from(
        uint256 timestamp,
        Position memory position,
        Fixed6 collateral,
        UFixed6 newMaker,
        UFixed6 newLong,
        UFixed6 newShort,
        bool protect,
        UFixed6 referralFee
    ) internal pure returns (Order memory newOrder) {
        (Fixed6 makerAmount, Fixed6 longAmount, Fixed6 shortAmount) = (
            Fixed6Lib.from(newMaker).sub(Fixed6Lib.from(position.maker)),
            Fixed6Lib.from(newLong).sub(Fixed6Lib.from(position.long)),
            Fixed6Lib.from(newShort).sub(Fixed6Lib.from(position.short))
        );

        UFixed6 referral = makerAmount.abs().add(longAmount.abs()).add(shortAmount.abs()).mul(referralFee);

        newOrder = Order(
            timestamp,
            0,
            collateral,
            makerAmount.max(Fixed6Lib.ZERO).abs(),
            makerAmount.min(Fixed6Lib.ZERO).abs(),
            longAmount.max(Fixed6Lib.ZERO).abs(),
            longAmount.min(Fixed6Lib.ZERO).abs(),
            shortAmount.max(Fixed6Lib.ZERO).abs(),
            shortAmount.min(Fixed6Lib.ZERO).abs(),
            protect ? 1 : 0,
            makerAmount.isZero() ? UFixed6Lib.ZERO : referral,
            makerAmount.isZero() ? referral : UFixed6Lib.ZERO
        );
        if (!isEmpty(newOrder)) newOrder.orders = 1;
    }

    /// @notice Returns whether the order increases any of the account's positions
    /// @return Whether the order increases any of the account's positions
    function increasesPosition(Order memory self) internal pure returns (bool) {
        return increasesMaker(self) || increasesTaker(self);
    }

    /// @notice Returns whether the order increases the account's long or short positions
    /// @return Whether the order increases the account's long or short positions
    function increasesTaker(Order memory self) internal pure returns (bool) {
        return !self.longPos.isZero() || !self.shortPos.isZero();
    }

    /// @notice Returns whether the order increases the account's maker position
    /// @return Whether the order increases the account's maker positions
    function increasesMaker(Order memory self) internal pure returns (bool) {
        return !self.makerPos.isZero();
    }

    /// @notice Returns whether the order decreases the liquidity of the market
    /// @return Whether the order decreases the liquidity of the market
    function decreasesLiquidity(Order memory self, Position memory currentPosition) internal pure returns (bool) {
        Fixed6 currentSkew = currentPosition.skew();
        Fixed6 latestSkew = currentSkew.sub(long(self)).add(short(self));
        return !self.makerNeg.isZero() || currentSkew.abs().gt(latestSkew.abs());
    }

    /// @notice Returns whether the order decreases the efficieny of the market
    /// @dev Decreased efficiency ratio intuitively means that the market is "more efficient" on an OI to LP basis.
    /// @return Whether the order decreases the liquidity of the market
    function decreasesEfficiency(Order memory self, Position memory currentPosition) internal pure returns (bool) {
        UFixed6 currentMajor = currentPosition.major();
        UFixed6 latestMajor = UFixed6Lib.from(Fixed6Lib.from(currentPosition.long).sub(long(self)))
            .max(UFixed6Lib.from(Fixed6Lib.from(currentPosition.short).sub(short(self))));
        return !self.makerNeg.isZero() || currentMajor.gt(latestMajor);
    }

    /// @notice Returns whether the order is applicable for liquidity checks
    /// @param self The Order object to check
    /// @param marketParameter The market parameter
    /// @return Whether the order is applicable for liquidity checks
    function liquidityCheckApplicable(
        Order memory self,
        MarketParameter memory marketParameter
    ) internal pure returns (bool) {
        return !marketParameter.closed &&
            ((maker(self).isZero()) || !marketParameter.makerCloseAlways || increasesMaker(self)) &&
            ((long(self).isZero() && short(self).isZero()) || !marketParameter.takerCloseAlways || increasesTaker(self));
    }

    /// @notice Returns whether the order is protected
    /// @param self The order object to check
    /// @return Whether the order is protected
    function protected(Order memory self) internal pure returns (bool) {
        return self.protection != 0;
    }

    /// @notice Returns whether the order is empty
    /// @param self The order object to check
    /// @return Whether the order is empty
    function isEmpty(Order memory self) internal pure returns (bool) {
        return pos(self).isZero() && neg(self).isZero();
    }

     /// @notice Returns the direction of the order
    /// @dev 0 = maker, 1 = long, 2 = short
    /// @param self The position object to check
    /// @return The direction of the position
    function direction(Order memory self) internal pure returns (uint256) {
        if (!self.longPos.isZero() || !self.longNeg.isZero()) return 1;
        if (!self.shortPos.isZero() || !self.shortNeg.isZero()) return 2;

        return 0;
    }

    /// @notice Returns the magnitude of the order
    /// @param self The order object to check
    /// @return The magnitude of the order
    function magnitude(Order memory self) internal pure returns (Fixed6) {
        return maker(self).add(long(self)).add(short(self));
    }

    /// @notice Returns the maker delta of the order
    /// @param self The order object to check
    /// @return The maker delta of the order
    function maker(Order memory self) internal pure returns (Fixed6) {
        return Fixed6Lib.from(self.makerPos).sub(Fixed6Lib.from(self.makerNeg));
    }

    /// @notice Returns the long delta of the order
    /// @param self The order object to check
    /// @return The long delta of the order
    function long(Order memory self) internal pure returns (Fixed6) {
        return Fixed6Lib.from(self.longPos).sub(Fixed6Lib.from(self.longNeg));
    }

    /// @notice Returns the short delta of the order
    /// @param self The order object to check
    /// @return The short delta of the order
    function short(Order memory self) internal pure returns (Fixed6) {
        return Fixed6Lib.from(self.shortPos).sub(Fixed6Lib.from(self.shortNeg));
    }

    /// @notice Returns the positive taker delta of the order
    /// @param self The order object to check
    /// @return The positive taker delta of the order
    function takerPos(Order memory self) internal pure returns (UFixed6) {
        return self.longPos.add(self.shortNeg);
    }

    /// @notice Returns the negative taker delta of the order
    /// @param self The order object to check
    /// @return The negative taker delta of the order
    function takerNeg(Order memory self) internal pure returns (UFixed6) {
        return self.shortPos.add(self.longNeg);
    }

    /// @notice Returns the total maker delta of the order
    /// @param self The order object to check
    /// @return The total maker delta of the order
    function makerTotal(Order memory self) internal pure returns (UFixed6) {
        return self.makerPos.add(self.makerNeg);
    }

    /// @notice Returns the total taker delta of the order
    /// @param self The order object to check
    /// @return The total taker delta of the order
    function takerTotal(Order memory self) internal pure returns (UFixed6) {
        return self.takerPos().add(self.takerNeg());
    }

    /// @notice Returns the positive delta of the order
    /// @param self The order object to check
    /// @return The positive delta of the order
    function pos(Order memory self) internal pure returns (UFixed6) {
        return self.makerPos.add(self.longPos).add(self.shortPos);
    }

    /// @notice Returns the positive delta of the order
    /// @param self The order object to check
    /// @return The positive delta of the order
    function neg(Order memory self) internal pure returns (UFixed6) {
        return self.makerNeg.add(self.longNeg).add(self.shortNeg);
    }

    /// @notice Updates the current global order with a new local order
    /// @param self The order object to update
    /// @param order The new order
    function add(Order memory self, Order memory order) internal pure {
        (self.orders, self.collateral, self.protection, self.makerReferral, self.takerReferral) = (
            self.orders + order.orders,
            self.collateral.add(order.collateral),
            self.protection + order.protection,
            self.makerReferral.add(order.makerReferral),
            self.takerReferral.add(order.takerReferral)
        );

        (self.makerPos, self.makerNeg, self.longPos, self.longNeg, self.shortPos, self.shortNeg) = (
            self.makerPos.add(order.makerPos),
            self.makerNeg.add(order.makerNeg),
            self.longPos.add(order.longPos),
            self.longNeg.add(order.longNeg),
            self.shortPos.add(order.shortPos),
            self.shortNeg.add(order.shortNeg)
        );
    }

    /// @notice Subtracts the latest local order from current global order
    /// @param self The order object to update
    /// @param order The latest order
    function sub(Order memory self, Order memory order) internal pure {
        (self.orders, self.collateral, self.protection, self.makerReferral, self.takerReferral) = (
            self.orders - order.orders,
            self.collateral.sub(order.collateral),
            self.protection - order.protection,
            self.makerReferral.sub(order.makerReferral),
            self.takerReferral.sub(order.takerReferral)
        );

        (self.makerPos, self.makerNeg, self.longPos, self.longNeg, self.shortPos, self.shortNeg) = (
            self.makerPos.sub(order.makerPos),
            self.makerNeg.sub(order.makerNeg),
            self.longPos.sub(order.longPos),
            self.longNeg.sub(order.longNeg),
            self.shortPos.sub(order.shortPos),
            self.shortNeg.sub(order.shortNeg)
        );
    }
}

/// @dev Manually encodes and decodes the global Order struct into storage.
///
///     struct StoredOrderGlobal {
///         /* slot 0 */
///         uint32 timestamp;
///         uint32 orders;
///         int64 collateral;
///         uint64 makerPos;
///         uint64 makerNeg;
///
///         /* slot 1 */
///         uint64 longPos;
///         uint64 longNeg;
///         uint64 shortPos;
///         uint64 shortNeg;
///
///         /* slot 2 */
///         uint64 takerReferral;
///         uint64 makerReferral;
///     }
///
library OrderStorageGlobalLib {
    function read(OrderStorageGlobal storage self) internal view returns (Order memory) {
        (uint256 slot0, uint256 slot1, uint256 slot2) = (self.slot0, self.slot1, self.slot2);

        return Order(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            uint256(slot0 << (256 - 32 - 32)) >> (256 - 32),
            Fixed6.wrap(int256(slot0 << (256 - 32 - 32 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 64 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 64 - 64 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot1 << (256 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot1 << (256 - 64 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot1 << (256 - 64 - 64 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot1 << (256 - 64 - 64 - 64 - 64)) >> (256 - 64)),
            0,
            UFixed6.wrap(uint256(slot2 << (256 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot2 << (256 - 64 - 64)) >> (256 - 64))
        );
    }

    function store(OrderStorageGlobal storage self, Order memory newValue) internal {
        OrderStorageLib.validate(newValue);

        if (newValue.makerPos.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageLib.OrderStorageInvalidError();
        if (newValue.makerNeg.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageLib.OrderStorageInvalidError();
        if (newValue.longPos.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageLib.OrderStorageInvalidError();
        if (newValue.longNeg.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageLib.OrderStorageInvalidError();
        if (newValue.shortPos.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageLib.OrderStorageInvalidError();
        if (newValue.shortNeg.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageLib.OrderStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.timestamp << (256 - 32)) >> (256 - 32) |
            uint256(newValue.orders << (256 - 32)) >> (256 - 32 - 32) |
            uint256(Fixed6.unwrap(newValue.collateral) << (256 - 64)) >> (256 - 32 - 32 - 64) |
            uint256(UFixed6.unwrap(newValue.makerPos) << (256 - 64)) >> (256 - 32 - 32 - 64 - 64) |
            uint256(UFixed6.unwrap(newValue.makerNeg) << (256 - 64)) >> (256 - 32 - 32 - 64 - 64 - 64);
        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.longPos) << (256 - 64)) >> (256 - 64) |
            uint256(UFixed6.unwrap(newValue.longNeg) << (256 - 64)) >> (256 - 64 - 64) |
            uint256(UFixed6.unwrap(newValue.shortPos) << (256 - 64)) >> (256 - 64 - 64 - 64) |
            uint256(UFixed6.unwrap(newValue.shortNeg) << (256 - 64)) >> (256 - 64 - 64 - 64 - 64);
        uint256 encoded2 =
            uint256(UFixed6.unwrap(newValue.makerReferral) << (256 - 64)) >> (256 - 64) |
            uint256(UFixed6.unwrap(newValue.takerReferral) << (256 - 64)) >> (256 - 64 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
            sstore(add(self.slot, 2), encoded2)
        }
    }
}

/// @dev Manually encodes and decodes the local Order struct into storage.
///
///     struct StoredOrderLocal {
///         /* slot 0 */
///         uint32 timestamp;
///         uint32 orders;
///         int64 collateral;
///         uint2 direction;
///         uint62 magnitudePos;
///         uint62 magnitudeNeg;
///         uint1 protection;
///
///         /* slot 1 */
///         uint64 takerReferral;
///         uint64 makerReferral;
///     }
///
library OrderStorageLocalLib {
    function read(OrderStorageLocal storage self) internal view returns (Order memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);

        uint256 direction = uint256(slot0 << (256 - 32 - 32 - 64 - 2)) >> (256 - 2);
        UFixed6 magnitudePos = UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 64 - 2 - 62)) >> (256 - 62));
        UFixed6 magnitudeNeg = UFixed6.wrap(uint256(slot0 << (256 - 32 - 32 - 64 - 2 - 62 - 62)) >> (256 - 62));

        return Order(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            uint256(slot0 << (256 - 32 - 32)) >> (256 - 32),
            Fixed6.wrap(int256(slot0 << (256 - 32 - 32 - 64)) >> (256 - 64)),
            direction == 0 ? magnitudePos : UFixed6Lib.ZERO,
            direction == 0 ? magnitudeNeg : UFixed6Lib.ZERO,
            direction == 1 ? magnitudePos : UFixed6Lib.ZERO,
            direction == 1 ? magnitudeNeg : UFixed6Lib.ZERO,
            direction == 2 ? magnitudePos : UFixed6Lib.ZERO,
            direction == 2 ? magnitudeNeg : UFixed6Lib.ZERO,
            uint256(slot0 << (256 - 32 - 32 - 64 - 2 - 62 - 62 - 1)) >> (256 - 1),
            UFixed6.wrap(uint256(slot1 << (256 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot1 << (256 - 64 - 64)) >> (256 - 64))
        );
    }

    function store(OrderStorageLocal storage self, Order memory newValue) internal {
        OrderStorageLib.validate(newValue);

        (UFixed6 magnitudePos, UFixed6 magnitudeNeg) = (newValue.pos(), newValue.neg());

        if (magnitudePos.gt(UFixed6.wrap(2 ** 62 - 1))) revert OrderStorageLib.OrderStorageInvalidError();
        if (magnitudeNeg.gt(UFixed6.wrap(2 ** 62 - 1))) revert OrderStorageLib.OrderStorageInvalidError();
        if (newValue.protection > 1) revert OrderStorageLib.OrderStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.timestamp << (256 - 32)) >> (256 - 32) |
            uint256(newValue.orders << (256 - 32)) >> (256 - 32 - 32) |
            uint256(Fixed6.unwrap(newValue.collateral) << (256 - 64)) >> (256 - 32 - 32 - 64) |
            uint256(newValue.direction() << (256 - 2)) >> (256 - 32 - 32 - 64 - 2) |
            uint256(UFixed6.unwrap(magnitudePos) << (256 - 62)) >> (256 - 32 - 32 - 64 - 2 - 62) |
            uint256(UFixed6.unwrap(magnitudeNeg) << (256 - 62)) >> (256 - 32 - 32 - 64 - 2 - 62 - 62) |
            uint256(newValue.protection << (256 - 1)) >> (256 - 32 - 32 - 64 - 2 - 62 - 62 - 1);
        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.makerReferral) << (256 - 64)) >> (256 - 64) |
            uint256(UFixed6.unwrap(newValue.takerReferral) << (256 - 64)) >> (256 - 64 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

library OrderStorageLib {
    // sig: 0x67e45965
    error OrderStorageInvalidError();

    function validate(Order memory newValue) internal pure {
        if (newValue.timestamp > type(uint32).max) revert OrderStorageInvalidError();
        if (newValue.orders > type(uint32).max) revert OrderStorageInvalidError();
        if (newValue.collateral.gt(Fixed6.wrap(type(int64).max))) revert OrderStorageInvalidError();
        if (newValue.collateral.lt(Fixed6.wrap(type(int64).min))) revert OrderStorageInvalidError();
        if (newValue.makerReferral.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageInvalidError();
        if (newValue.takerReferral.gt(UFixed6.wrap(type(uint64).max))) revert OrderStorageInvalidError();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./OracleVersion.sol";
import "./RiskParameter.sol";
import "./Global.sol";
import "./Local.sol";
import "./Order.sol";

/// @dev Order type
struct Position {
    /// @dev The timestamp of the position
    uint256 timestamp;

    /// @dev The maker position size
    UFixed6 maker;

    /// @dev The long position size
    UFixed6 long;

    /// @dev The short position size
    UFixed6 short;
}
using PositionLib for Position global;
struct PositionStorageGlobal { uint256 slot0; uint256 slot1; } // SECURITY: must remain at (2) slots
using PositionStorageGlobalLib for PositionStorageGlobal global;
struct PositionStorageLocal { uint256 slot0; uint256 slot1; } // SECURITY: must remain at (2) slots
using PositionStorageLocalLib for PositionStorageLocal global;

/// @title Position
/// @notice Holds the state for a position
library PositionLib {
    /// @notice Returns a cloned copy of the position
    /// @param self The position object to clone
    /// @return A cloned copy of the position
    function clone(Position memory self) internal pure returns (Position memory) {
        return Position(self.timestamp, self.maker, self.long, self.short);
    }

    /// @notice Updates the position with a new order
    /// @param self The position object to update
    /// @param order The new order
    function update(Position memory self, Order memory order) internal pure {
        self.timestamp = order.timestamp;

        (self.maker, self.long, self.short) = (
            UFixed6Lib.from(Fixed6Lib.from(self.maker).add(order.maker())),
            UFixed6Lib.from(Fixed6Lib.from(self.long).add(order.long())),
            UFixed6Lib.from(Fixed6Lib.from(self.short).add(order.short()))
        );
    }

    /// @notice Returns the direction of the position
    /// @dev 0 = maker, 1 = long, 2 = short
    /// @param self The position object to check
    /// @return The direction of the position
    function direction(Position memory self) internal pure returns (uint256) {
        return self.long.isZero() ? (self.short.isZero() ? 0 : 2) : 1;
    }

    /// @notice Returns the maximum position size
    /// @param self The position object to check
    /// @return The maximum position size
    function magnitude(Position memory self) internal pure returns (UFixed6) {
        return self.long.max(self.short).max(self.maker);
    }

    /// @notice Returns the maximum taker position size
    /// @param self The position object to check
    /// @return The maximum taker position size
    function major(Position memory self) internal pure returns (UFixed6) {
        return self.long.max(self.short);
    }

    /// @notice Returns the minimum maker position size
    /// @param self The position object to check
    /// @return The minimum maker position size
    function minor(Position memory self) internal pure returns (UFixed6) {
        return self.long.min(self.short);
    }

    /// @notice Returns the skew of the position
    /// @param self The position object to check
    /// @return The skew of the position
    function skew(Position memory self) internal pure returns (Fixed6) {
        return Fixed6Lib.from(self.long).sub(Fixed6Lib.from(self.short));
    }

    /// @notice Returns the utilization of the position
    /// @dev utilization = major / (maker + minor)
    /// @param self The position object to check
    /// @param riskParameter The current risk parameter
    /// @return The utilization of the position
    function utilization(Position memory self, RiskParameter memory riskParameter) internal pure returns (UFixed6) {
        // long-short net utilization of the maker position
        UFixed6 netUtilization = major(self).unsafeDiv(self.maker.add(minor(self)));

        // efficiency limit utilization of the maker position
        UFixed6 efficiencyUtilization = major(self).mul(riskParameter.efficiencyLimit).unsafeDiv(self.maker);

        // maximum of the two utilizations, capped at 100%
        return netUtilization.max(efficiencyUtilization).min(UFixed6Lib.ONE);
    }

    /// @notice Returns the portion of the position that is covered by the maker
    /// @param self The position object to check
    /// @return The portion of the position that is covered by the maker
    function socializedMakerPortion(Position memory self) internal pure returns (UFixed6) {
        return takerSocialized(self).isZero() ?
            UFixed6Lib.ZERO :
            takerSocialized(self).sub(minor(self)).div(takerSocialized(self));
    }

    /// @notice Returns the long position with socialization taken into account
    /// @param self The position object to check
    /// @return The long position with socialization taken into account
    function longSocialized(Position memory self) internal pure returns (UFixed6) {
        return self.maker.add(self.short).min(self.long);
    }

    /// @notice Returns the short position with socialization taken into account
    /// @param self The position object to check
    /// @return The short position with socialization taken into account
    function shortSocialized(Position memory self) internal pure returns (UFixed6) {
        return self.maker.add(self.long).min(self.short);
    }

    /// @notice Returns the major position with socialization taken into account
    /// @param self The position object to check
    /// @return The major position with socialization taken into account
    function takerSocialized(Position memory self) internal pure returns (UFixed6) {
        return major(self).min(minor(self).add(self.maker));
    }

    /// @notice Returns the efficiency of the position
    /// @dev efficiency = maker / major
    /// @param self The position object to check
    /// @return The efficiency of the position
    function efficiency(Position memory self) internal pure returns (UFixed6) {
        return self.maker.unsafeDiv(major(self)).min(UFixed6Lib.ONE);
    }

    /// @notice Returns the whether the position is socialized
    /// @param self The position object to check
    /// @return Whether the position is socialized
    function socialized(Position memory self) internal pure returns (bool) {
        return self.maker.add(self.short).lt(self.long) || self.maker.add(self.long).lt(self.short);
    }

    /// @notice Returns the whether the position is single-sided
    /// @param self The position object to check
    /// @return Whether the position is single-sided
    function singleSided(Position memory self) internal pure returns (bool) {
        return magnitude(self).eq(self.long.add(self.short).add(self.maker));
    }

    /// @notice Returns the whether the position is empty
    /// @param self The position object to check
    /// @return Whether the position is empty
    function empty(Position memory self) internal pure returns (bool) {
        return magnitude(self).isZero();
    }

    /// @notice Returns the maintenance requirement of the position
    /// @param positionMagnitude The position magnitude value to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The maintenance requirement of the position
    function maintenance(
        UFixed6 positionMagnitude,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        return _collateralRequirement(positionMagnitude, latestVersion, riskParameter.maintenance, riskParameter.minMaintenance);
    }

    /// @notice Returns the margin requirement of the position
    /// @param positionMagnitude The position magnitude value to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The margin requirement of the position
    function margin(
        UFixed6 positionMagnitude,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        return _collateralRequirement(positionMagnitude, latestVersion, riskParameter.margin, riskParameter.minMargin);
    }

    /// @notice Returns the maintenance requirement of the position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The maintenance requirement of the position
    function maintenance(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        return maintenance(magnitude(self), latestVersion, riskParameter);
    }

    /// @notice Returns the margin requirement of the position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @return The margin requirement of the position
    function margin(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter
    ) internal pure returns (UFixed6) {
        return margin(magnitude(self), latestVersion, riskParameter);
    }

    /// @notice Returns the collateral requirement of the position magnitude
    /// @param positionMagnitude The position magnitude value to check
    /// @param latestVersion The latest oracle version
    /// @param requirementRatio The ratio requirement to the notional
    /// @param requirementFixed The fixed requirement
    /// @return The collateral requirement of the position magnitude
    function _collateralRequirement(
        UFixed6 positionMagnitude,
        OracleVersion memory latestVersion,
        UFixed6 requirementRatio,
        UFixed6 requirementFixed
    ) private pure returns (UFixed6) {
        if (positionMagnitude.isZero()) return UFixed6Lib.ZERO;
        return positionMagnitude.mul(latestVersion.price.abs()).mul(requirementRatio).max(requirementFixed);
    }

    /// @notice Returns the whether the position is maintained
    /// @dev shortfall is considered solvent for 0-position
    /// @param positionMagnitude The position magnitude value to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @param collateral The current account's collateral
    /// @return Whether the position is maintained
    function maintained(
        UFixed6 positionMagnitude,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter,
        Fixed6 collateral
    ) internal pure returns (bool) {
        return UFixed6Lib.unsafeFrom(collateral).gte(maintenance(positionMagnitude, latestVersion, riskParameter));
    }

    /// @notice Returns the whether the position is margined
    /// @dev shortfall is considered solvent for 0-position
    /// @param positionMagnitude The position magnitude value to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @param collateral The current account's collateral
    /// @return Whether the position is margined
    function margined(
        UFixed6 positionMagnitude,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter,
        Fixed6 collateral
    ) internal pure returns (bool) {
        return UFixed6Lib.unsafeFrom(collateral).gte(margin(positionMagnitude, latestVersion, riskParameter));
    }

    /// @notice Returns the whether the position is maintained
    /// @dev shortfall is considered solvent for 0-position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @param collateral The current account's collateral
    /// @return Whether the position is maintained
    function maintained(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter,
        Fixed6 collateral
    ) internal pure returns (bool) {
        return maintained(magnitude(self), latestVersion, riskParameter, collateral);
    }

    /// @notice Returns the whether the position is margined
    /// @dev shortfall is considered solvent for 0-position
    /// @param self The position object to check
    /// @param latestVersion The latest oracle version
    /// @param riskParameter The current risk parameter
    /// @param collateral The current account's collateral
    /// @return Whether the position is margined
    function margined(
        Position memory self,
        OracleVersion memory latestVersion,
        RiskParameter memory riskParameter,
        Fixed6 collateral
    ) internal pure returns (bool) {
        return margined(magnitude(self), latestVersion, riskParameter, collateral);
    }
}

/// @dev Manually encodes and decodes the global Position struct into storage.
///
///     struct StoredPositionGlobal {
///         /* slot 0 */
///         uint32 timestamp;
///         uint96 __unallocated__;
///         uint64 long;
///         uint64 short;
///
///         /* slot 1 */
///         uint64 maker;
///         uint192 __unallocated__;
///     }
///
library PositionStorageGlobalLib {
    function read(PositionStorageGlobal storage self) internal view returns (Position memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);
        return Position(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            UFixed6.wrap(uint256(slot1 << (256 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48 - 48 - 64)) >> (256 - 64)),
            UFixed6.wrap(uint256(slot0 << (256 - 32 - 48 - 48 - 64 - 64)) >> (256 - 64))
        );
    }

    function store(PositionStorageGlobal storage self, Position memory newValue) external {
        PositionStorageLib.validate(newValue);

        if (newValue.maker.gt(UFixed6.wrap(type(uint64).max))) revert PositionStorageLib.PositionStorageInvalidError();
        if (newValue.long.gt(UFixed6.wrap(type(uint64).max))) revert PositionStorageLib.PositionStorageInvalidError();
        if (newValue.short.gt(UFixed6.wrap(type(uint64).max))) revert PositionStorageLib.PositionStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.timestamp << (256 - 32)) >> (256 - 32) |
            uint256(UFixed6.unwrap(newValue.long) << (256 - 64)) >> (256 - 32 - 48 - 48 - 64) |
            uint256(UFixed6.unwrap(newValue.short) << (256 - 64)) >> (256 - 32 - 48 - 48 - 64 - 64);
        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.maker) << (256 - 64)) >> (256 - 64);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

/// @dev Manually encodes and decodes the local Position struct into storage.
///
///     struct StoredPositionLocal {
///         /* slot 0 */
///         uint32 timestamp;
///         uint224 __unallocated__;
///
///         /* slot 1 */
///         uint2 direction;
///         uint62 magnitude;
///         uint192 __unallocated__;
///     }
///
library PositionStorageLocalLib {
    function read(PositionStorageLocal storage self) internal view returns (Position memory) {
        (uint256 slot0, uint256 slot1) = (self.slot0, self.slot1);

        uint256 direction = uint256(slot1 << (256 - 2)) >> (256 - 2);
        UFixed6 magnitude = UFixed6.wrap(uint256(slot1 << (256 - 2 - 62)) >> (256 - 62));

        return Position(
            uint256(slot0 << (256 - 32)) >> (256 - 32),
            direction == 0 ? magnitude : UFixed6Lib.ZERO,
            direction == 1 ? magnitude : UFixed6Lib.ZERO,
            direction == 2 ? magnitude : UFixed6Lib.ZERO
        );
    }

    function store(PositionStorageLocal storage self, Position memory newValue) external {
        PositionStorageLib.validate(newValue);

        UFixed6 magnitude = newValue.magnitude();

        if (magnitude.gt(UFixed6.wrap(2 ** 62 - 1))) revert PositionStorageLib.PositionStorageInvalidError();

        uint256 encoded0 =
            uint256(newValue.timestamp << (256 - 32)) >> (256 - 32);
        uint256 encoded1 =
            uint256(newValue.direction() << (256 - 2)) >> (256 - 2) |
            uint256(UFixed6.unwrap(magnitude) << (256 - 62)) >> (256 - 2 - 62);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
        }
    }
}

library PositionStorageLib {
    // sig: 0x52a8a97f
    error PositionStorageInvalidError();

    function validate(Position memory newValue) internal pure {
        if (newValue.timestamp > type(uint32).max) revert PositionStorageInvalidError();
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed6.sol";

/// @dev ProtocolParameter type
struct ProtocolParameter {
    /// @dev The share of the market fees that are retained by the protocol before being distributed
    UFixed6 protocolFee;

    /// @dev The maximum for market fee parameters
    UFixed6 maxFee;

    /// @dev The maximum for market absolute fee parameters
    UFixed6 maxFeeAbsolute;

    /// @dev The maximum for market cut parameters
    UFixed6 maxCut;

    /// @dev The maximum for market rate parameters
    UFixed6 maxRate;

    /// @dev The minimum for market maintenance parameters
    UFixed6 minMaintenance;

    /// @dev The minimum for market efficiency parameters
    UFixed6 minEfficiency;

    /// @dev The default referrer fee
    UFixed6 referralFee;
}
struct StoredProtocolParameter {
    /* slot 0 */
    uint24 protocolFee;        // <= 1677%
    uint24 maxFee;             // <= 1677%
    uint48 maxFeeAbsolute;     // <= 281m
    uint24 maxCut;             // <= 1677%
    uint32 maxRate;            // <= 214748% (capped at 31 bits to accommodate int32 rates)
    uint24 minMaintenance;     // <= 1677%
    uint24 minEfficiency;      // <= 1677%
    uint24 referralFee;        // <= 1677%
}
struct ProtocolParameterStorage { StoredProtocolParameter value; } // SECURITY: must remain at (1) slots
using ProtocolParameterStorageLib for ProtocolParameterStorage global;

library ProtocolParameterStorageLib {
    // sig: 0x4dc1bc59
    error ProtocolParameterStorageInvalidError();

    function read(ProtocolParameterStorage storage self) internal view returns (ProtocolParameter memory) {
        StoredProtocolParameter memory value = self.value;
        return ProtocolParameter(
            UFixed6.wrap(uint256(value.protocolFee)),
            UFixed6.wrap(uint256(value.maxFee)),
            UFixed6.wrap(uint256(value.maxFeeAbsolute)),
            UFixed6.wrap(uint256(value.maxCut)),
            UFixed6.wrap(uint256(value.maxRate)),
            UFixed6.wrap(uint256(value.minMaintenance)),
            UFixed6.wrap(uint256(value.minEfficiency)),
            UFixed6.wrap(uint256(value.referralFee))
        );
    }

    function validate(ProtocolParameter memory self) internal pure {
        if (self.protocolFee.gt(self.maxCut)) revert ProtocolParameterStorageInvalidError();
        if (self.maxCut.gt(UFixed6Lib.ONE)) revert ProtocolParameterStorageInvalidError();
    }

    function validateAndStore(ProtocolParameterStorage storage self, ProtocolParameter memory newValue) internal {
        validate(newValue);

        if (newValue.maxFee.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.maxFeeAbsolute.gt(UFixed6.wrap(type(uint48).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.maxRate.gt(UFixed6.wrap(type(uint32).max / 2))) revert ProtocolParameterStorageInvalidError();
        if (newValue.minMaintenance.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.minEfficiency.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();
        if (newValue.referralFee.gt(UFixed6.wrap(type(uint24).max))) revert ProtocolParameterStorageInvalidError();

        self.value = StoredProtocolParameter(
            uint24(UFixed6.unwrap(newValue.protocolFee)),
            uint24(UFixed6.unwrap(newValue.maxFee)),
            uint48(UFixed6.unwrap(newValue.maxFeeAbsolute)),
            uint24(UFixed6.unwrap(newValue.maxCut)),
            uint32(UFixed6.unwrap(newValue.maxRate)),
            uint24(UFixed6.unwrap(newValue.minMaintenance)),
            uint24(UFixed6.unwrap(newValue.minEfficiency)),
            uint24(UFixed6.unwrap(newValue.referralFee))
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed6.sol";
import "@equilibria/root/utilization/types/UJumpRateUtilizationCurve6.sol";
import "@equilibria/root/pid/types/PController6.sol";
import "@equilibria/root/adiabatic/types/LinearAdiabatic6.sol";
import "@equilibria/root/adiabatic/types/InverseAdiabatic6.sol";
import "../interfaces/IOracleProvider.sol";
import "./ProtocolParameter.sol";

/// @dev RiskParameter type
struct RiskParameter {
    /// @dev The minimum amount of collateral required to open a new position as a percentage of notional
    UFixed6 margin;

    /// @dev The minimum amount of collateral that must be maintained as a percentage of notional
    UFixed6 maintenance;

    /// @dev The taker impact fee
    LinearAdiabatic6 takerFee;

    /// @dev The maker fee configuration
    InverseAdiabatic6 makerFee;

    /// @dev The maximum amount of maker positions that opened
    UFixed6 makerLimit;

    /// @dev The minimum limit of the efficiency metric
    UFixed6 efficiencyLimit;

    /// @dev The percentage fee on the notional that is charged when a position is liquidated
    UFixed6 liquidationFee;

    /// @dev The utilization curve that is used to compute maker interest
    UJumpRateUtilizationCurve6 utilizationCurve;

    /// @dev The p controller that is used to compute long-short funding
    PController6 pController;

    /// @dev The minimum fixed amount that is required to open a position
    UFixed6 minMargin;

    /// @dev The minimum fixed amount that is required for maintenance
    UFixed6 minMaintenance;

    /// @dev The maximum amount of time since the latest oracle version that update may still be called
    uint256 staleAfter;

    /// @dev Whether or not the maker should always receive positive funding
    bool makerReceiveOnly;
}
struct RiskParameterStorage { uint256 slot0; uint256 slot1; uint256 slot2; } // SECURITY: must remain at (3) slots
using RiskParameterStorageLib for RiskParameterStorage global;

//    struct StoredRiskParameter {
//        /* slot 0 */ (30)
//        uint24 margin;                              // <= 1677%
//        uint24 maintenance;                         // <= 1677%
//        uint24 takerFee;                            // <= 1677%
//        uint24 takerFeeMagnitude;                   // <= 1677%
//        uint24 takerImpactFee;                      // <= 1677%
//        uint24 makerFee;                            // <= 1677%
//        uint24 makerFeeMagnitude;                   // <= 1677%
//        uint48 makerLimit;                          // <= 281t (no decimals)
//        uint24 efficiencyLimit;                     // <= 1677%
//
//        /* slot 1 */ (31)
//        uint24 makerImpactFee;                      // <= 1677%
//        uint48 makerSkewScale;                      // <= 281t (no decimals)
//        uint48 takerSkewScale;                      // <= 281t (no decimals)
//        uint24 utilizationCurveMinRate;             // <= 1677%
//        uint24 utilizationCurveMaxRate;             // <= 1677%
//        uint24 utilizationCurveTargetRate;          // <= 1677%
//        uint24 utilizationCurveTargetUtilization;   // <= 1677%
//        int32 pControllerMin;                       // <= 214748%
//
//        /* slot 2 */ (32)
//        uint48 pControllerK;                        // <= 281m
//        int32 pControllerMax;                       // <= 214748%
//        uint48 minMargin;                           // <= 281m
//        uint48 minMaintenance;                      // <= 281m
//        uint48 liquidationFee;                      // <= 281m
//        uint24 staleAfter;                          // <= 16m s
//        bool makerReceiveOnly;
//    }
library RiskParameterStorageLib {
    // sig: 0x7ecd083f
    error RiskParameterStorageInvalidError();

    function read(RiskParameterStorage storage self) internal view returns (RiskParameter memory) {
        (uint256 slot0, uint256 slot1, uint256 slot2) = (self.slot0, self.slot1, self.slot2);
        return RiskParameter(
            UFixed6.wrap(uint256(       slot0 << (256 - 24)) >> (256 - 24)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24)) >> (256 - 24)),
            LinearAdiabatic6(
                UFixed6.wrap(uint256(   slot0 << (256 - 24 - 24 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot0 << (256 - 24 - 24 - 24 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot0 << (256 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
                UFixed6Lib.from(uint256(slot1 << (256 - 24 - 48 - 48)) >> (256 - 48))
            ),
            InverseAdiabatic6(
                UFixed6.wrap(uint256(   slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24)) >> (256 - 24)),
                UFixed6Lib.from(uint256(slot1 << (256 - 24 - 48)) >> (256 - 48))
            ),
            UFixed6Lib.from(uint256(    slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(       slot0 << (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 48 - 24)) >> (256 - 24)),

            UFixed6.wrap(uint256(       slot2 << (256 - 48 - 32 - 48 - 48 - 48)) >> (256 - 48)),
            UJumpRateUtilizationCurve6(
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 48 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 48 - 24 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 48 - 24 - 24 - 24)) >> (256 - 24)),
                UFixed6.wrap(uint256(   slot1 << (256 - 24 - 48 - 48 - 24 - 24 - 24 - 24)) >> (256 - 24))
            ),

            PController6(
                UFixed6.wrap(uint256(   slot2 << (256 - 48)) >> (256 - 48)),
                Fixed6.wrap(int256(     slot1 << (256 - 24 - 48 - 48 - 24 - 24 - 24 - 24 - 32)) >> (256 - 32)),
                Fixed6.wrap(int256(     slot2 << (256 - 48 - 32)) >> (256 - 32))
            ),
            UFixed6.wrap(uint256(       slot2 << (256 - 48 - 32 - 48)) >> (256 - 48)),
            UFixed6.wrap(uint256(       slot2 << (256 - 48 - 32 - 48 - 48)) >> (256 - 48)),
                         uint256(       slot2 << (256 - 48 - 32 - 48 - 48 - 48 - 24)) >> (256 - 24),
            0 !=        (uint256(       slot2 << (256 - 48 - 32 - 48 - 48 - 48 - 24 - 8)) >> (256 - 8))
        );
    }

    function validate(RiskParameter memory self, ProtocolParameter memory protocolParameter) private pure {
        if (
            self.takerFee.linearFee.max(self.takerFee.proportionalFee).max(self.takerFee.adiabaticFee)
                .max(self.makerFee.linearFee).max(self.makerFee.proportionalFee).max(self.makerFee.adiabaticFee)
                .gt(protocolParameter.maxFee)
        ) revert RiskParameterStorageInvalidError();

        if (self.liquidationFee.gt(protocolParameter.maxFeeAbsolute)) revert RiskParameterStorageInvalidError();

        if (
            self.utilizationCurve.minRate.max(self.utilizationCurve.maxRate).max(self.utilizationCurve.targetRate)
                .max(self.pController.max.abs()).max(self.pController.min.abs())
                .gt(protocolParameter.maxRate)
        ) revert RiskParameterStorageInvalidError();

        if (self.maintenance.lt(protocolParameter.minMaintenance)) revert RiskParameterStorageInvalidError();

        if (self.margin.lt(self.maintenance)) revert RiskParameterStorageInvalidError();

        if (self.efficiencyLimit.lt(protocolParameter.minEfficiency)) revert RiskParameterStorageInvalidError();

        if (self.utilizationCurve.targetUtilization.gt(UFixed6Lib.ONE)) revert RiskParameterStorageInvalidError();

        if (self.minMaintenance.lt(self.liquidationFee)) revert RiskParameterStorageInvalidError();

        if (self.minMargin.lt(self.minMaintenance)) revert RiskParameterStorageInvalidError();

        // Disable non-zero maker adiabatic fee
        if (!self.makerFee.adiabaticFee.isZero()) revert RiskParameterStorageInvalidError();
    }

    function validateAndStore(
        RiskParameterStorage storage self,
        RiskParameter memory newValue,
        ProtocolParameter memory protocolParameter
    ) external {
        validate(newValue, protocolParameter);

        if (newValue.margin.gt(UFixed6.wrap(type(uint24).max))) revert RiskParameterStorageInvalidError();
        if (newValue.minMargin.gt(UFixed6.wrap(type(uint48).max))) revert RiskParameterStorageInvalidError();
        if (newValue.efficiencyLimit.gt(UFixed6.wrap(type(uint24).max))) revert RiskParameterStorageInvalidError();
        if (newValue.makerLimit.gt(UFixed6Lib.from(type(uint48).max))) revert RiskParameterStorageInvalidError();
        if (newValue.pController.k.gt(UFixed6.wrap(type(uint48).max))) revert RiskParameterStorageInvalidError();
        if (newValue.takerFee.scale.gt(UFixed6Lib.from(type(uint48).max))) revert RiskParameterStorageInvalidError();
        if (newValue.makerFee.scale.gt(UFixed6Lib.from(type(uint48).max))) revert RiskParameterStorageInvalidError();
        if (newValue.staleAfter > uint256(type(uint24).max)) revert RiskParameterStorageInvalidError();

        uint256 encoded0 =
            uint256(UFixed6.unwrap(newValue.margin)                    << (256 - 24)) >> (256 - 24) |
            uint256(UFixed6.unwrap(newValue.maintenance)               << (256 - 24)) >> (256 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.takerFee.linearFee)        << (256 - 24)) >> (256 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.takerFee.proportionalFee)  << (256 - 24)) >> (256 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.takerFee.adiabaticFee)     << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.makerFee.linearFee)        << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.makerFee.proportionalFee)  << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24) |
            uint256(newValue.makerLimit.truncate()                     << (256 - 48)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 48) |
            uint256(UFixed6.unwrap(newValue.efficiencyLimit)           << (256 - 24)) >> (256 - 24 - 24 - 24 - 24 - 24 - 24 - 24 - 48 - 24);

        uint256 encoded1 =
            uint256(UFixed6.unwrap(newValue.makerFee.adiabaticFee)              << (256 - 24)) >> (256 - 24) |
            uint256(newValue.makerFee.scale.truncate()                          << (256 - 48)) >> (256 - 24 - 48) |
            uint256(newValue.takerFee.scale.truncate()                          << (256 - 48)) >> (256 - 24 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.minRate)           << (256 - 24)) >> (256 - 24 - 48 - 48 - 24) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.maxRate)           << (256 - 24)) >> (256 - 24 - 48 - 48 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.targetRate)        << (256 - 24)) >> (256 - 24 - 48 - 48 - 24 - 24 - 24) |
            uint256(UFixed6.unwrap(newValue.utilizationCurve.targetUtilization) << (256 - 24)) >> (256 - 24 - 48 - 48 - 24 - 24 - 24 - 24) |
            uint256(Fixed6.unwrap(newValue.pController.min)                     << (256 - 32)) >> (256 - 24 - 48 - 48 - 24 - 24 - 24 - 24 - 32);

        uint256 encoded2 =
            uint256(UFixed6.unwrap(newValue.pController.k)                  << (256 - 48)) >> (256 - 48) |
            uint256(Fixed6.unwrap(newValue.pController.max)                 << (256 - 32)) >> (256 - 48 - 32) |
            uint256(UFixed6.unwrap(newValue.minMargin)                      << (256 - 48)) >> (256 - 48 - 32 - 48) |
            uint256(UFixed6.unwrap(newValue.minMaintenance)                 << (256 - 48)) >> (256 - 48 - 32 - 48 - 48) |
            uint256(UFixed6.unwrap(newValue.liquidationFee)                 << (256 - 48)) >> (256 - 48 - 32 - 48 - 48 - 48) |
            uint256(newValue.staleAfter                                     << (256 - 24)) >> (256 - 48 - 32 - 48 - 48 - 48 - 24) |
            uint256((newValue.makerReceiveOnly ? uint256(1) : uint256(0))   << (256 - 8))  >> (256 - 48 - 32 - 48 - 48 - 48 - 24 - 8);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
            sstore(add(self.slot, 2), encoded2)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/accumulator/types/Accumulator6.sol";
import "./ProtocolParameter.sol";
import "./MarketParameter.sol";
import "./RiskParameter.sol";
import "./Global.sol";
import "./Position.sol";
import "./Order.sol";

/// @dev Version type
struct Version {
    /// @dev whether this version had a valid oracle price
    bool valid;

    /// @dev The maker accumulator value
    Accumulator6 makerValue;

    /// @dev The long accumulator value
    Accumulator6 longValue;

    /// @dev The short accumulator value
    Accumulator6 shortValue;

    /// @dev The accumulated linear fee for maker orders
    Accumulator6 makerLinearFee;

    /// @dev The accumulated proportional fee for maker orders
    Accumulator6 makerProportionalFee;

    /// @dev The accumulated linear fee for taker orders
    Accumulator6 takerLinearFee;

    /// @dev The accumulated proportional fee for taker orders
    Accumulator6 takerProportionalFee;

    /// @dev The accumulated fee for positive skew maker orders
    Accumulator6 makerPosFee;

    /// @dev The accumulated fee for negative skew maker orders
    Accumulator6 makerNegFee;

    /// @dev The accumulated fee for positive skew taker orders
    Accumulator6 takerPosFee;

    /// @dev The accumulated fee for negative skew taker orders
    Accumulator6 takerNegFee;

    /// @dev The accumulated settlement fee for each individual order
    Accumulator6 settlementFee;

    /// @dev The accumulated liquidation fee for each individual order
    Accumulator6 liquidationFee;
}
struct VersionStorage { uint256 slot0; uint256 slot1; uint256 slot2; }
using VersionStorageLib for VersionStorage global;

/// @dev Manually encodes and decodes the Version struct into storage.
///
///     struct StoredVersion {
///         /* slot 0 */
///         bool valid;
///         int64 makerValue;
///         int64 longValue;
///         int64 shortValue;
///         uint48 liquidationFee;
///
///         /* slot 1 */
///         int48 makerPosFee;
///         int48 makerNegFee;
///         int48 takerPosFee;
///         int48 takerNegFee;
///         uint48 settlementFee;
///
///         /* slot 2 */
///         int48 makerLinearFee;
///         int48 makerProportionalFee;
///         int48 takerLinearFee;
///         int48 takerProportionalFee;
///     }
///
library VersionStorageLib {
    // sig: 0xd2777e72
    error VersionStorageInvalidError();

    function read(VersionStorage storage self) internal view returns (Version memory) {
        (uint256 slot0, uint256 slot1, uint256 slot2) = (self.slot0, self.slot1, self.slot2);
        return Version(
            (uint256(slot0 << (256 - 8)) >> (256 - 8)) != 0,
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64)) >> (256 - 64))),
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64 - 64)) >> (256 - 64))),
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64 - 64 - 64)) >> (256 - 64))),

            Accumulator6(Fixed6.wrap(int256(slot2 << (256 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot2 << (256 - 48 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot2 << (256 - 48 - 48 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot2 << (256 - 48 - 48 - 48 - 48)) >> (256 - 48))),

            Accumulator6(Fixed6.wrap(int256(slot1 << (256 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot1 << (256 - 48 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot1 << (256 - 48 - 48 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot1 << (256 - 48 - 48 - 48 - 48)) >> (256 - 48))),

            Accumulator6(Fixed6.wrap(int256(slot1 << (256 - 48 - 48 - 48 - 48 - 48)) >> (256 - 48))),
            Accumulator6(Fixed6.wrap(int256(slot0 << (256 - 8 - 64 - 64 - 64 - 48)) >> (256 - 48)))
        );
    }

    function store(VersionStorage storage self, Version memory newValue) external {
        if (newValue.makerValue._value.gt(Fixed6.wrap(type(int64).max))) revert VersionStorageInvalidError();
        if (newValue.makerValue._value.lt(Fixed6.wrap(type(int64).min))) revert VersionStorageInvalidError();
        if (newValue.longValue._value.gt(Fixed6.wrap(type(int64).max))) revert VersionStorageInvalidError();
        if (newValue.longValue._value.lt(Fixed6.wrap(type(int64).min))) revert VersionStorageInvalidError();
        if (newValue.shortValue._value.gt(Fixed6.wrap(type(int64).max))) revert VersionStorageInvalidError();
        if (newValue.shortValue._value.lt(Fixed6.wrap(type(int64).min))) revert VersionStorageInvalidError();
        if (newValue.makerLinearFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.makerLinearFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.makerProportionalFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.makerProportionalFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.takerLinearFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.takerLinearFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.takerProportionalFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.takerProportionalFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.makerPosFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.makerPosFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.makerNegFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.makerNegFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.takerPosFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.takerPosFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.takerNegFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.takerNegFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.settlementFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.settlementFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();
        if (newValue.liquidationFee._value.gt(Fixed6.wrap(type(int48).max))) revert VersionStorageInvalidError();
        if (newValue.liquidationFee._value.lt(Fixed6.wrap(type(int48).min))) revert VersionStorageInvalidError();

        uint256 encoded0 =
            uint256((newValue.valid ? uint256(1) : uint256(0)) << (256 - 8)) >> (256 - 8) |
            uint256(Fixed6.unwrap(newValue.makerValue._value) << (256 - 64)) >> (256 - 8 - 64) |
            uint256(Fixed6.unwrap(newValue.longValue._value) << (256 - 64)) >> (256 - 8 - 64 - 64) |
            uint256(Fixed6.unwrap(newValue.shortValue._value) << (256 - 64)) >> (256 - 8 - 64 - 64 - 64) |
            uint256(Fixed6.unwrap(newValue.liquidationFee._value) << (256 - 48)) >> (256 - 8 - 64 - 64 - 64 - 48);
        uint256 encoded1 =
            uint256(Fixed6.unwrap(newValue.makerPosFee._value) << (256 - 48)) >> (256 - 48) |
            uint256(Fixed6.unwrap(newValue.makerNegFee._value) << (256 - 48)) >> (256 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.takerPosFee._value) << (256 - 48)) >> (256 - 48 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.takerNegFee._value) << (256 - 48)) >> (256 - 48 - 48 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.settlementFee._value) << (256 - 48)) >> (256 - 48 - 48 - 48 - 48 - 48);
        uint256 encoded2 =
            uint256(Fixed6.unwrap(newValue.makerLinearFee._value) << (256 - 48)) >> (256 - 48) |
            uint256(Fixed6.unwrap(newValue.makerProportionalFee._value) << (256 - 48)) >> (256 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.takerLinearFee._value) << (256 - 48)) >> (256 - 48 - 48 - 48) |
            uint256(Fixed6.unwrap(newValue.takerProportionalFee._value) << (256 - 48)) >> (256 - 48 - 48 - 48 - 48);

        assembly {
            sstore(self.slot, encoded0)
            sstore(add(self.slot, 1), encoded1)
            sstore(add(self.slot, 2), encoded2)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";
import "../../number/types/UFixed6.sol";

/// @dev Accumulator6 type
struct Accumulator6 {
    Fixed6 _value;
}

using Accumulator6Lib for Accumulator6 global;
struct StoredAccumulator6 {
    int256 _value;
}
struct Accumulator6Storage { StoredAccumulator6 value; }
using Accumulator6StorageLib for Accumulator6Storage global;


/**
 * @title Accumulator6Lib
 * @notice Library that surfaces math operations for the signed Accumulator type.
 * @dev This accumulator tracks cumulative changes to a value over time. Using the `accumulated` function, one
 * can determine how much a value has changed between two points in time. The `increment` and `decrement` functions
 * can be used to update the accumulator.
 */
library Accumulator6Lib {
    /**
     * Returns how much has been accumulated between two accumulators
     * @param self The current point of the accumulation to compare with `from`
     * @param from The starting point of the accumulation
     * @param total Demoninator of the ratio (see `increment` and `decrement` functions)
     */
    function accumulated(Accumulator6 memory self, Accumulator6 memory from, UFixed6 total) internal pure returns (Fixed6) {
        return _mul(self._value.sub(from._value), total);
    }

    /**
     * @notice Increments an accumulator by a given ratio
     * @dev Always rounds down in order to prevent overstating the accumulated value
     * @param self The accumulator to increment
     * @param amount Numerator of the ratio
     * @param total Denominator of the ratio
     */
    function increment(Accumulator6 memory self, Fixed6 amount, UFixed6 total) internal pure {
        if (amount.isZero()) return;
        self._value = self._value.add(_div(amount, total));
    }

    /**
     * @notice Decrements an accumulator by a given ratio
     * @dev Always rounds down in order to prevent overstating the accumulated value
     * @param self The accumulator to decrement
     * @param amount Numerator of the ratio
     * @param total Denominator of the ratio
     */
    function decrement(Accumulator6 memory self, Fixed6 amount, UFixed6 total) internal pure {
        if (amount.isZero()) return;
        self._value = self._value.add(_div(amount.mul(Fixed6Lib.NEG_ONE), total));
    }

    function _div(Fixed6 amount, UFixed6 total) private pure returns (Fixed6) {
        return amount.sign() == -1 ? amount.divOut(Fixed6Lib.from(total)) : amount.div(Fixed6Lib.from(total));
    }

    function _mul(Fixed6 amount, UFixed6 total) private pure returns (Fixed6) {
        return amount.sign() == -1 ? amount.mulOut(Fixed6Lib.from(total)) : amount.mul(Fixed6Lib.from(total));
    }
}

library Accumulator6StorageLib {
    function read(Accumulator6Storage storage self) internal view returns (Accumulator6 memory) {
        StoredAccumulator6 memory storedValue = self.value;
        return Accumulator6(Fixed6.wrap(int256(storedValue._value)));
    }

    function store(Accumulator6Storage storage self, Accumulator6 memory newValue) internal {
        self.value = StoredAccumulator6(Fixed6.unwrap(newValue._value));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/UFixed6.sol";

/// @dev UAccumulator6 type
struct UAccumulator6 {
    UFixed6 _value;
}

using UAccumulator6Lib for UAccumulator6 global;
struct StoredUAccumulator6 {
    uint256 _value;
}
struct UAccumulator6Storage { StoredUAccumulator6 value; }
using UAccumulator6StorageLib for UAccumulator6Storage global;


/**
 * @title UAccumulator6Lib
 * @notice Library that surfaces math operations for the unsigned Accumulator type.
 * @dev This accumulator tracks cumulative changes to a monotonically increasing value over time. Using the `accumulated` function, one
 * can determine how much a value has changed between two points in time. The `increment` function can be used to update the accumulator.
 */
library UAccumulator6Lib {
    /**
     * Returns how much has been accumulated between two accumulators
     * @param self The current point of the accumulation to compare with `from`
     * @param from The starting point of the accumulation
     * @param total Demoninator of the ratio (see `increment` function)
     */
    function accumulated(UAccumulator6 memory self, UAccumulator6 memory from, UFixed6 total) internal pure returns (UFixed6) {
        return self._value.sub(from._value).mul(total);
    }

    /**
     * @notice Increments an accumulator by a given ratio
     * @dev Always rounds down in order to prevent overstating the accumulated value
     * @param self The accumulator to increment
     * @param amount Numerator of the ratio
     * @param total Denominator of the ratio
     */
    function increment(UAccumulator6 memory self, UFixed6 amount, UFixed6 total) internal pure {
        if (amount.isZero()) return;
        self._value = self._value.add(amount.div(total));
    }
}

library UAccumulator6StorageLib {
    function read(UAccumulator6Storage storage self) internal view returns (UAccumulator6 memory) {
        StoredUAccumulator6 memory storedValue = self.value;
        return UAccumulator6(UFixed6.wrap(uint256(storedValue._value)));
    }

    function store(UAccumulator6Storage storage self, UAccumulator6 memory newValue) internal {
        self.value = StoredUAccumulator6(UFixed6.unwrap(newValue._value));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed6.sol";
import "../number/types/Fixed6.sol";

/**
 * @title AdiabaticMath6
 * @notice Library for managing math operations for adiabatic fees.
 */
library AdiabaticMath6 {
    error Adiabatic6ZeroScaleError();

    /// @notice Computes the base fees for an order
    /// @param fee The linear fee percentage
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The linear fee in underlying terms
    function linearFee(UFixed6 fee, Fixed6 change, UFixed6 price) internal pure returns (UFixed6) {
        return change.abs().mul(price).mul(fee);
    }

    /// @notice Computes the base fees for an order
    /// @param scale The scale of the skew
    /// @param fee The proportional fee percentage
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The proportional fee in underlying terms
    function proportionalFee(UFixed6 scale, UFixed6 fee, Fixed6 change, UFixed6 price) internal pure returns (UFixed6) {
        return change.abs().mul(price).muldiv(change.abs(), scale).mul(fee);
    }

    /// @notice Computes the adiabatic fee from a latest skew and change in skew over a linear function
    /// @param scale The scale of the skew
    /// @param adiabaticFee The adiabatic fee percentage
    /// @param latest The latest skew in asset terms
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The adiabatic fee in underlying terms
    function linearCompute(
        UFixed6 scale,
        UFixed6 adiabaticFee,
        Fixed6 latest,
        Fixed6 change,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        if (latest.isZero() && change.isZero()) return Fixed6Lib.ZERO;
        if (scale.isZero()) revert Adiabatic6ZeroScaleError();

        // normalize for skew scale
        (Fixed6 latestScaled, Fixed6 changeScaled) =
            (latest.div(Fixed6Lib.from(scale)), change.div(Fixed6Lib.from(scale)));

        // adiabatic fee = notional * fee percentage * mean of skew range
        return change.mul(Fixed6Lib.from(price)).mul(Fixed6Lib.from(adiabaticFee))
            .mul(_linearMean(latestScaled, latestScaled.add(changeScaled)));
    }

    /// @notice Finds the mean value of the function f(x) = x over `from` to `to`
    /// @param from The lower bound
    /// @param to The upper bound
    /// @return The mean value
    function _linearMean(Fixed6 from, Fixed6 to) private pure returns (Fixed6) {
        return from.add(to).div(Fixed6Lib.from(2));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";
import "../../number/types/UFixed6.sol";
import "../AdiabaticMath6.sol";

/// @dev InverseAdiabatic6 type
struct InverseAdiabatic6 {
    UFixed6 linearFee;
    UFixed6 proportionalFee;
    UFixed6 adiabaticFee;
    UFixed6 scale;
}
using InverseAdiabatic6Lib for InverseAdiabatic6 global;

/**
 * @title InverseAdiabatic6Lib
 * @notice Library that that manages the inverse adiabatic fee algorithm
 * @dev This algorithm specifies an adiatatic fee over the function:
 *
 *      f(skew) = adiabaticFee * max(scale - skew, 0), skew >= 0
 *
 *      This is used to reward or penalize actions that move skew up or down this curve accordingly with net-zero
 *      value to the system with respect to the underlying asset.
 */
library InverseAdiabatic6Lib {
    /// @notice Computes the adiabatic fee from a latest skew and change in skew
    /// @param self The adiabatic configuration
    /// @param latest The latest skew in asset terms
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The adiabatic fee in underlying terms
    function compute(
        InverseAdiabatic6 memory self,
        UFixed6 latest,
        Fixed6 change,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        UFixed6 current = UFixed6Lib.from(Fixed6Lib.from(latest).add(change));
        Fixed6 latestSkew = Fixed6Lib.from(self.scale.unsafeSub(latest));
        Fixed6 currentSkew = Fixed6Lib.from(self.scale.unsafeSub(current));

        return AdiabaticMath6.linearCompute(
            self.scale,
            self.adiabaticFee,
            latestSkew,
            currentSkew.sub(latestSkew),
            price
        );
    }

    /// @notice Computes the latest exposure
    /// @param self The adiabatic configuration
    /// @param latest The latest skew in asset terms
    /// @return The latest total exposure in asset terms
    function exposure(InverseAdiabatic6 memory self, UFixed6 latest) internal pure returns (Fixed6) {
        return compute(self, UFixed6Lib.ZERO, Fixed6Lib.from(latest), UFixed6Lib.ONE);
    }

    /// @notice Computes the linear fee
    /// @param self The adiabatic configuration
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The linear fee in underlying terms
    function linear(InverseAdiabatic6 memory self, Fixed6 change, UFixed6 price) internal pure returns (UFixed6) {
        return AdiabaticMath6.linearFee(self.linearFee, change, price);
    }

    /// @notice Computes the proportional fee
    /// @param self The adiabatic configuration
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The proportional fee in underlying terms
    function proportional(InverseAdiabatic6 memory self, Fixed6 change, UFixed6 price) internal pure returns (UFixed6) {
        return AdiabaticMath6.proportionalFee(self.scale, self.proportionalFee, change, price);
    }

    /// @notice Computes the adiabatic fee
    /// @param self The adiabatic configuration
    /// @param latest The latest skew in asset terms
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The adiabatic fee in underlying terms
    function adiabatic(
        InverseAdiabatic6 memory self,
        UFixed6 latest,
        Fixed6 change,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        return compute(self, latest, change, price);
    }

    /// @dev Updates the scale and compute the resultant change fee
    /// @param self The adiabatic configuration
    /// @param newConfig The new fee config
    /// @param latest The latest skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The update fee in underlying terms
    function update(
        InverseAdiabatic6 memory self,
        InverseAdiabatic6 memory newConfig,
        UFixed6 latest,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        Fixed6 prior = compute(self, UFixed6Lib.ZERO, Fixed6Lib.from(latest), price);
        (self.linearFee, self.proportionalFee, self.adiabaticFee, self.scale) =
            (newConfig.linearFee, newConfig.proportionalFee, newConfig.adiabaticFee, newConfig.scale);
        return compute(self, UFixed6Lib.ZERO, Fixed6Lib.from(latest), price).sub(prior);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";
import "../../number/types/UFixed6.sol";
import "../AdiabaticMath6.sol";

/// @dev LinearAdiabatic6 type
struct LinearAdiabatic6 {
    UFixed6 linearFee;
    UFixed6 proportionalFee;
    UFixed6 adiabaticFee;
    UFixed6 scale;
}
using LinearAdiabatic6Lib for LinearAdiabatic6 global;

/**
 * @title LinearAdiabatic6Lib
 * @notice Library that that manages the linear adiabatic fee algorithm
 * @dev This algorithm specifies an adiatatic fee over the function:
 *
 *      f(skew) = adiabaticFee * skew
 *
 *      This is used to reward or penalize actions that move skew up or down this curve accordingly with net-zero
 *      value to the system with respect to the underlying asset.
 */
library LinearAdiabatic6Lib {
    /// @notice Computes the adiabatic fee from a latest skew and change in skew
    /// @param self The adiabatic configuration
    /// @param latest The latest skew in asset terms
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The adiabatic fee in underlying terms
    function compute(
        LinearAdiabatic6 memory self,
        Fixed6 latest,
        Fixed6 change,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        return AdiabaticMath6.linearCompute(
            self.scale,
            self.adiabaticFee,
            latest,
            change,
            price
        );
    }

    /// @notice Computes the latest exposure along with all fees
    /// @param self The adiabatic configuration
    /// @param latest The latest skew in asset terms
    /// @return The latest total exposure in asset terms
    function exposure(LinearAdiabatic6 memory self, Fixed6 latest) internal pure returns (Fixed6) {
        return compute(self, Fixed6Lib.ZERO, latest, UFixed6Lib.ONE);
    }

    /// @notice Computes the linear fee
    /// @param self The adiabatic configuration
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The linear fee in underlying terms
    function linear(LinearAdiabatic6 memory self, Fixed6 change, UFixed6 price) internal pure returns (UFixed6) {
        return AdiabaticMath6.linearFee(self.linearFee, change, price);
    }

    /// @notice Computes the proportional fee
    /// @param self The adiabatic configuration
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The proportional fee in underlying terms
    function proportional(LinearAdiabatic6 memory self, Fixed6 change, UFixed6 price) internal pure returns (UFixed6) {
        return AdiabaticMath6.proportionalFee(self.scale, self.proportionalFee, change, price);
    }

    /// @notice Computes the adiabatic fee
    /// @param self The adiabatic configuration
    /// @param latest The latest skew in asset terms
    /// @param change The change in skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The adiabatic fee in underlying terms
    function adiabatic(
        LinearAdiabatic6 memory self,
        Fixed6 latest,
        Fixed6 change,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        return compute(self, latest, change, price);
    }

    /// @dev Updates the scale and compute the resultant change fee
    /// @param self The adiabatic configuration
    /// @param newConfig The new fee config
    /// @param latest The latest skew in asset terms
    /// @param price The price of the underlying asset
    /// @return The update fee in underlying terms
    function update(
        LinearAdiabatic6 memory self,
        LinearAdiabatic6 memory newConfig,
        Fixed6 latest,
        UFixed6 price
    ) internal pure returns (Fixed6) {
        Fixed6 prior = compute(self, Fixed6Lib.ZERO, latest, price);
        (self.linearFee, self.proportionalFee, self.adiabaticFee, self.scale) =
            (newConfig.linearFee, newConfig.proportionalFee, newConfig.adiabaticFee, newConfig.scale);
        return compute(self, Fixed6Lib.ZERO, latest, price).sub(prior);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "./IPausable.sol";
import "./IInstance.sol";

interface IFactory is IBeacon, IOwnable, IPausable {
    event InstanceRegistered(IInstance indexed instance);

    error FactoryNotInstanceError();

    function instances(IInstance instance) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IInitializable {
    error InitializableZeroVersionError();
    error InitializableAlreadyInitializedError(uint256 version);
    error InitializableNotInitializingError();

    event Initialized(uint256 version);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IFactory.sol";
import "./IInitializable.sol";

interface IInstance is IInitializable {
    error InstanceNotOwnerError(address sender);
    error InstanceNotFactoryError(address sender);
    error InstancePausedError();

    function factory() external view returns (IFactory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IInitializable.sol";

interface IOwnable is IInitializable {
    event OwnerUpdated(address indexed newOwner);
    event PendingOwnerUpdated(address indexed newPendingOwner);

    error OwnableNotOwnerError(address sender);
    error OwnableNotPendingOwnerError(address sender);

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function updatePendingOwner(address newPendingOwner) external;
    function acceptOwner() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IInitializable.sol";
import "./IOwnable.sol";

interface IPausable is IInitializable, IOwnable {
    event PauserUpdated(address indexed newPauser);
    event Paused();
    event Unpaused();

    error PausablePausedError();
    error PausableNotPauserError(address sender);

    function pauser() external view returns (address);
    function paused() external view returns (bool);
    function updatePauser(address newPauser) external;
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

/**
 * @title NumberMath
 * @notice Library for additional math functions that are not included in the OpenZeppelin libraries.
 */
library NumberMath {
    error DivisionByZero();

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) revert DivisionByZero();
        return Math.ceilDiv(a, b);
    }

    /**
     * @notice Divides `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Dividend
     * @param b Divisor
     * @return Resulting quotient
     */
    function divOut(int256 a, int256 b) internal pure returns (int256) {
        return sign(a) * sign(b) * int256(divOut(SignedMath.abs(a), SignedMath.abs(b)));
    }

    /**
     * @notice Returns the sign of an int256
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a int256 to find the sign of
     * @return Sign of the int256
     */
    function sign(int256 a) internal pure returns (int256) {
        if (a > 0) return 1;
        if (a < 0) return -1;
        return 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev Fixed18 type
type Fixed18 is int256;
using Fixed18Lib for Fixed18 global;
type Fixed18Storage is bytes32;
using Fixed18StorageLib for Fixed18Storage global;

/**
 * @title Fixed18Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed18Lib {
    error Fixed18OverflowError(uint256 value);

    int256 private constant BASE = 1e18;
    Fixed18 public constant ZERO = Fixed18.wrap(0);
    Fixed18 public constant ONE = Fixed18.wrap(BASE);
    Fixed18 public constant NEG_ONE = Fixed18.wrap(-1 * BASE);
    Fixed18 public constant MAX = Fixed18.wrap(type(int256).max);
    Fixed18 public constant MIN = Fixed18.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (Fixed18) {
        uint256 value = UFixed18.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed18OverflowError(value);
        return Fixed18.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed18 m) internal pure returns (Fixed18) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed18.wrap(-1 * Fixed18.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed18 a) internal pure returns (bool) {
        return Fixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) + Fixed18.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) - Fixed18.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * BASE / Fixed18.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldiv(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, int256 b, int256 c) internal pure returns (Fixed18) {
        return muldivOut(a, Fixed18.wrap(b), Fixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(Fixed18.unwrap(a) * Fixed18.unwrap(b) / Fixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed18 a, Fixed18 b, Fixed18 c) internal pure returns (Fixed18) {
        return Fixed18.wrap(NumberMath.divOut(Fixed18.unwrap(a) * Fixed18.unwrap(b), Fixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed18 a, Fixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed18 a, Fixed18 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed18.unwrap(a), Fixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.min(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed18 a, Fixed18 b) internal pure returns (Fixed18) {
        return Fixed18.wrap(SignedMath.max(Fixed18.unwrap(a), Fixed18.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed18 a) internal pure returns (int256) {
        return Fixed18.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed18 a) internal pure returns (int256) {
        if (Fixed18.unwrap(a) > 0) return 1;
        if (Fixed18.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed18 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(SignedMath.abs(Fixed18.unwrap(a)));
    }
}

library Fixed18StorageLib {
    function read(Fixed18Storage self) internal view returns (Fixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed18Storage self, Fixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev Fixed6 type
type Fixed6 is int256;
using Fixed6Lib for Fixed6 global;
type Fixed6Storage is bytes32;
using Fixed6StorageLib for Fixed6Storage global;

/**
 * @title Fixed6Lib
 * @notice Library for the signed fixed-decimal type.
 */
library Fixed6Lib {
    error Fixed6OverflowError(uint256 value);

    int256 private constant BASE = 1e6;
    Fixed6 public constant ZERO = Fixed6.wrap(0);
    Fixed6 public constant ONE = Fixed6.wrap(BASE);
    Fixed6 public constant NEG_ONE = Fixed6.wrap(-1 * BASE);
    Fixed6 public constant MAX = Fixed6.wrap(type(int256).max);
    Fixed6 public constant MIN = Fixed6.wrap(type(int256).min);

    /**
     * @notice Creates a signed fixed-decimal from an unsigned fixed-decimal
     * @param a Unsigned fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (Fixed6) {
        uint256 value = UFixed6.unwrap(a);
        if (value > uint256(type(int256).max)) revert Fixed6OverflowError(value);
        return Fixed6.wrap(int256(value));
    }

    /**
     * @notice Creates a signed fixed-decimal from a sign and an unsigned fixed-decimal
     * @param s Sign
     * @param m Unsigned fixed-decimal magnitude
     * @return New signed fixed-decimal
     */
    function from(int256 s, UFixed6 m) internal pure returns (Fixed6) {
        if (s > 0) return from(m);
        if (s < 0) {
            // Since from(m) multiplies m by BASE, from(m) cannot be type(int256).min
            // which is the only value that would overflow when negated. Therefore,
            // we can safely negate from(m) without checking for overflow.
            unchecked { return Fixed6.wrap(-1 * Fixed6.unwrap(from(m))); }
        }
        return ZERO;
    }

    /**
     * @notice Creates a signed fixed-decimal from a signed integer
     * @param a Signed number
     * @return New signed fixed-decimal
     */
    function from(int256 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-18 signed fixed-decimal
     * @param a Base-18 signed fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New signed fixed-decimal
     */
    function from(Fixed18 a, bool roundOut) internal pure returns (Fixed6) {
        return roundOut ? Fixed6.wrap(NumberMath.divOut(Fixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the signed fixed-decimal is equal to zero.
     * @param a Signed fixed-decimal
     * @return Whether the signed fixed-decimal is zero.
     */
    function isZero(Fixed6 a) internal pure returns (bool) {
        return Fixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting summed signed fixed-decimal
     */
    function add(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) + Fixed6.unwrap(b));
    }

    /**
     * @notice Subtracts signed fixed-decimal `b` from `a`
     * @param a Signed fixed-decimal to subtract from
     * @param b Signed fixed-decimal to subtract
     * @return Resulting subtracted signed fixed-decimal
     */
    function sub(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) - Fixed6.unwrap(b));
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mul(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two signed fixed-decimals `a` and `b` together, rounding the result away from zero if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Resulting multiplied signed fixed-decimal
     */
    function mulOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function div(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * BASE / Fixed6.unwrap(b));
    }

    /**
     * @notice Divides signed fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @param a Signed fixed-decimal to divide
     * @param b Signed fixed-decimal to divide by
     * @return Resulting divided signed fixed-decimal
     */
    function divOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6Lib.from(sign(a) * sign(b), a.abs().divOut(b.abs()));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result away from zero if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0`, `MAX` for `n/0`, and `MIN` for `-n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        if (isZero(b)) {
            if (gt(a, ZERO)) return MAX;
            if (lt(a, ZERO)) return MIN;
            return ONE;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldiv(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed number to multiply by
     * @param c Signed number to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, int256 b, int256 c) internal pure returns (Fixed6) {
        return muldivOut(a, Fixed6.wrap(b), Fixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(Fixed6.unwrap(a) * Fixed6.unwrap(b) / Fixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First signed fixed-decimal
     * @param b Signed fixed-decimal to multiply by
     * @param c Signed fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(Fixed6 a, Fixed6 b, Fixed6 c) internal pure returns (Fixed6) {
        return Fixed6.wrap(NumberMath.divOut(Fixed6.unwrap(a) * Fixed6.unwrap(b), Fixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is greater than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether signed fixed-decimal `a` is less than or equal to `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(Fixed6 a, Fixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the signed fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(Fixed6 a, Fixed6 b) internal pure returns (uint256) {
        (int256 au, int256 bu) = (Fixed6.unwrap(a), Fixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a signed fixed-decimal representing the ratio of `a` over `b`
     * @param a First signed number
     * @param b Second signed number
     * @return Ratio of `a` over `b`
     */
    function ratio(int256 a, int256 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.min(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of signed fixed-decimals `a` and `b`
     * @param a First signed fixed-decimal
     * @param b Second signed fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(Fixed6 a, Fixed6 b) internal pure returns (Fixed6) {
        return Fixed6.wrap(SignedMath.max(Fixed6.unwrap(a), Fixed6.unwrap(b)));
    }

    /**
     * @notice Converts the signed fixed-decimal into an integer, truncating any decimal portion
     * @param a Signed fixed-decimal
     * @return Truncated signed number
     */
    function truncate(Fixed6 a) internal pure returns (int256) {
        return Fixed6.unwrap(a) / BASE;
    }

    /**
     * @notice Returns the sign of the signed fixed-decimal
     * @dev Returns: -1 for negative
     *                0 for zero
     *                1 for positive
     * @param a Signed fixed-decimal
     * @return Sign of the signed fixed-decimal
     */
    function sign(Fixed6 a) internal pure returns (int256) {
        if (Fixed6.unwrap(a) > 0) return 1;
        if (Fixed6.unwrap(a) < 0) return -1;
        return 0;
    }

    /**
     * @notice Returns the absolute value of the signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return Absolute value of the signed fixed-decimal
     */
    function abs(Fixed6 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(SignedMath.abs(Fixed6.unwrap(a)));
    }
}

library Fixed6StorageLib {
    function read(Fixed6Storage self) internal view returns (Fixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Fixed6Storage self, Fixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed18.sol";
import "./UFixed6.sol";

/// @dev UFixed18 type
type UFixed18 is uint256;
using UFixed18Lib for UFixed18 global;
type UFixed18Storage is bytes32;
using UFixed18StorageLib for UFixed18Storage global;

/**
 * @title UFixed18Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed18Lib {
    error UFixed18UnderflowError(int256 value);

    uint256 private constant BASE = 1e18;
    UFixed18 public constant ZERO = UFixed18.wrap(0);
    UFixed18 public constant ONE = UFixed18.wrap(BASE);
    UFixed18 public constant MAX = UFixed18.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed18 a) internal pure returns (UFixed18) {
        int256 value = Fixed18.unwrap(a);
        if (value < 0) revert UFixed18UnderflowError(value);
        return UFixed18.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @dev Does not revert on underflow, instead returns `ZERO`
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function unsafeFrom(Fixed18 a) internal pure returns (UFixed18) {
        return a.lt(Fixed18Lib.ZERO) ? ZERO : from(a);
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE);
    }

    /**
     * @notice Creates a signed fixed-decimal from a base-6 signed fixed-decimal
     * @param a Base-6 signed fixed-decimal
     * @return New signed fixed-decimal
     */
    function from(UFixed6 a) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed6.unwrap(a) * 1e12);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed18 a) internal pure returns (bool) {
        return UFixed18.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) + UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) - UFixed18.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on underflow, instead returns `ZERO`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function unsafeSub(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return gt(b, a) ? ZERO : sub(a, b);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * BASE / UFixed18.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * BASE, UFixed18.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldiv(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, uint256 b, uint256 c) internal pure returns (UFixed18) {
        return muldivOut(a, UFixed18.wrap(b), UFixed18.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(UFixed18.unwrap(a) * UFixed18.unwrap(b) / UFixed18.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed18 a, UFixed18 b, UFixed18 c) internal pure returns (UFixed18) {
        return UFixed18.wrap(NumberMath.divOut(UFixed18.unwrap(a) * UFixed18.unwrap(b), UFixed18.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed18 a, UFixed18 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed18 a, UFixed18 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed18.unwrap(a), UFixed18.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.min(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed18 a, UFixed18 b) internal pure returns (UFixed18) {
        return UFixed18.wrap(Math.max(UFixed18.unwrap(a), UFixed18.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed18 a) internal pure returns (uint256) {
        return UFixed18.unwrap(a) / BASE;
    }
}

library UFixed18StorageLib {
    function read(UFixed18Storage self) internal view returns (UFixed18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed18Storage self, UFixed18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../NumberMath.sol";
import "./Fixed6.sol";
import "./UFixed18.sol";

/// @dev UFixed6 type
type UFixed6 is uint256;
using UFixed6Lib for UFixed6 global;
type UFixed6Storage is bytes32;
using UFixed6StorageLib for UFixed6Storage global;

/**
 * @title UFixed6Lib
 * @notice Library for the unsigned fixed-decimal type.
 */
library UFixed6Lib {
    error UFixed6UnderflowError(int256 value);

    uint256 private constant BASE = 1e6;
    UFixed6 public constant ZERO = UFixed6.wrap(0);
    UFixed6 public constant ONE = UFixed6.wrap(BASE);
    UFixed6 public constant MAX = UFixed6.wrap(type(uint256).max);

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(Fixed6 a) internal pure returns (UFixed6) {
        int256 value = Fixed6.unwrap(a);
        if (value < 0) revert UFixed6UnderflowError(value);
        return UFixed6.wrap(uint256(value));
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a signed fixed-decimal
     * @dev Does not revert on underflow, instead returns `ZERO`
     * @param a Signed fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function unsafeFrom(Fixed6 a) internal pure returns (UFixed6) {
        return a.lt(Fixed6Lib.ZERO) ? ZERO : from(a);
    }

    /**
     * @notice Creates a unsigned fixed-decimal from a unsigned integer
     * @param a Unsigned number
     * @return New unsigned fixed-decimal
     */
    function from(uint256 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed18.unwrap(a) / 1e12);
    }

    /**
     * @notice Creates an unsigned fixed-decimal from a base-18 unsigned fixed-decimal
     * @param a Base-18 unsigned fixed-decimal
     * @param roundOut Whether to round the result away from zero if there is a remainder
     * @return New unsigned fixed-decimal
     */
    function from(UFixed18 a, bool roundOut) internal pure returns (UFixed6) {
        return roundOut ? UFixed6.wrap(NumberMath.divOut(UFixed18.unwrap(a), 1e12)): from(a);
    }

    /**
     * @notice Returns whether the unsigned fixed-decimal is equal to zero.
     * @param a Unsigned fixed-decimal
     * @return Whether the unsigned fixed-decimal is zero.
     */
    function isZero(UFixed6 a) internal pure returns (bool) {
        return UFixed6.unwrap(a) == 0;
    }

    /**
     * @notice Adds two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting summed unsigned fixed-decimal
     */
    function add(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) + UFixed6.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `b` from `a`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function sub(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) - UFixed6.unwrap(b));
    }

    /**
     * @notice Subtracts unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on underflow, instead returns `ZERO`
     * @param a Unsigned fixed-decimal to subtract from
     * @param b Unsigned fixed-decimal to subtract
     * @return Resulting subtracted unsigned fixed-decimal
     */
    function unsafeSub(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return gt(b, a) ? ZERO : sub(a, b);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mul(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / BASE);
    }

    /**
     * @notice Multiplies two unsigned fixed-decimals `a` and `b` together, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Resulting multiplied unsigned fixed-decimal
     */
    function mulOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), BASE));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function div(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * BASE / UFixed6.unwrap(b));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function divOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * BASE, UFixed6.unwrap(b)));
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDiv(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return div(a, b);
        }
    }

    /**
     * @notice Divides unsigned fixed-decimal `a` by `b`, rounding the result up to the next integer if there is a remainder
     * @dev Does not revert on divide-by-0, instead returns `ONE` for `0/0` and `MAX` for `n/0`.
     * @param a Unsigned fixed-decimal to divide
     * @param b Unsigned fixed-decimal to divide by
     * @return Resulting divided unsigned fixed-decimal
     */
    function unsafeDivOut(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        if (isZero(b)) {
            return isZero(a) ? ONE : MAX;
        } else {
            return divOut(a, b);
        }
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldiv(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned number to multiply by
     * @param c Unsigned number to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, uint256 b, uint256 c) internal pure returns (UFixed6) {
        return muldivOut(a, UFixed6.wrap(b), UFixed6.wrap(c));
    }


    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldiv(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(UFixed6.unwrap(a) * UFixed6.unwrap(b) / UFixed6.unwrap(c));
    }

    /**
     * @notice Computes a * b / c without loss of precision due to BASE conversion, rounding the result up to the next integer if there is a remainder
     * @param a First unsigned fixed-decimal
     * @param b Unsigned fixed-decimal to multiply by
     * @param c Unsigned fixed-decimal to divide by
     * @return Resulting computation
     */
    function muldivOut(UFixed6 a, UFixed6 b, UFixed6 c) internal pure returns (UFixed6) {
        return UFixed6.wrap(NumberMath.divOut(UFixed6.unwrap(a) * UFixed6.unwrap(b), UFixed6.unwrap(c)));
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is equal to `b`
     */
    function eq(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 1;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than `b`
     */
    function gt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 2;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than `b`
     */
    function lt(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return compare(a, b) == 0;
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is greater than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is greater than or equal to `b`
     */
    function gte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return gt(a, b) || eq(a, b);
    }

    /**
     * @notice Returns whether unsigned fixed-decimal `a` is less than or equal to `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Whether `a` is less than or equal to `b`
     */
    function lte(UFixed6 a, UFixed6 b) internal pure returns (bool) {
        return lt(a, b) || eq(a, b);
    }

    /**
     * @notice Compares the unsigned fixed-decimals `a` and `b`
     * @dev Returns: 2 for greater than
     *               1 for equal to
     *               0 for less than
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Compare result of `a` and `b`
     */
    function compare(UFixed6 a, UFixed6 b) internal pure returns (uint256) {
        (uint256 au, uint256 bu) = (UFixed6.unwrap(a), UFixed6.unwrap(b));
        if (au > bu) return 2;
        if (au < bu) return 0;
        return 1;
    }

    /**
     * @notice Returns a unsigned fixed-decimal representing the ratio of `a` over `b`
     * @param a First unsigned number
     * @param b Second unsigned number
     * @return Ratio of `a` over `b`
     */
    function ratio(uint256 a, uint256 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(a * BASE / b);
    }

    /**
     * @notice Returns the minimum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Minimum of `a` and `b`
     */
    function min(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.min(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Returns the maximum of unsigned fixed-decimals `a` and `b`
     * @param a First unsigned fixed-decimal
     * @param b Second unsigned fixed-decimal
     * @return Maximum of `a` and `b`
     */
    function max(UFixed6 a, UFixed6 b) internal pure returns (UFixed6) {
        return UFixed6.wrap(Math.max(UFixed6.unwrap(a), UFixed6.unwrap(b)));
    }

    /**
     * @notice Converts the unsigned fixed-decimal into an integer, truncating any decimal portion
     * @param a Unsigned fixed-decimal
     * @return Truncated unsigned number
     */
    function truncate(UFixed6 a) internal pure returns (uint256) {
        return UFixed6.unwrap(a) / BASE;
    }
}

library UFixed6StorageLib {
    function read(UFixed6Storage self) internal view returns (UFixed6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(UFixed6Storage self, UFixed6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";
import "./PController6.sol";

/// @dev PAccumulator6 type
struct PAccumulator6 {
    Fixed6 _value;
    Fixed6 _skew;
}
using PAccumulator6Lib for PAccumulator6 global;

/// @title PAccumulator6Lib
/// @notice Accumulator for a the fixed 6-decimal PID controller. This holds the "last seen state" of the PID controller
///         and works in conjunction with the PController6 to compute the current rate.
/// @dev This implementation is specifically a P controller, with I_k and D_k both set to 0. In between updates, it
///      continues to accumulate at a linear rate based on the previous skew, but the rate is capped at the max value.
///      Once the rate hits the max value, it will continue to accumulate at the max value until the next update.
library PAccumulator6Lib {
    /// @notice Accumulates the rate against notional given the prior and current state
    /// @param self The controller accumulator
    /// @param controller The controller configuration
    /// @param skew The current skew
    /// @param fromTimestamp The timestamp of the prior accumulation
    /// @param toTimestamp The current timestamp
    /// @param notional The notional to accumulate against
    /// @return accumulated The total accumulated amount
    function accumulate(
        PAccumulator6 memory self,
        PController6 memory controller,
        Fixed6 skew,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        UFixed6 notional
    ) internal pure returns (Fixed6 accumulated) {
        // compute new value and intercept
        (Fixed6 newValue, UFixed6 interceptTimestamp) =
            controller.compute(self._value, self._skew, fromTimestamp, toTimestamp);

        // accumulate rate within max
        accumulated = _accumulate(
            self._value.add(newValue),
            UFixed6Lib.from(fromTimestamp),
            interceptTimestamp,
            notional
        ).div(Fixed6Lib.from(2)); // rate = self._value + newValue / 2 -> divide here for added precision

        // accumulate rate outside of max
        accumulated = _accumulate(
            newValue,
            interceptTimestamp,
            UFixed6Lib.from(toTimestamp),
            notional
        ).add(accumulated);

        // update values
        self._value = newValue;
        self._skew = skew;
    }

    /// @notice Helper function to accumulate a singular rate against notional
    /// @param rate The rate to accumulate
    /// @param fromTimestamp The timestamp to accumulate from
    /// @param toTimestamp The timestamp to accumulate to
    /// @param notional The notional to accumulate against
    /// @return The accumulated amount
    function _accumulate(
        Fixed6 rate,
        UFixed6 fromTimestamp,
        UFixed6 toTimestamp,
        UFixed6 notional
    ) private pure returns (Fixed6) {
        return rate
            .mul(Fixed6Lib.from(toTimestamp.sub(fromTimestamp)))
            .mul(Fixed6Lib.from(notional))
            .div(Fixed6Lib.from(365 days));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../number/types/Fixed6.sol";

/// @dev PController6 type
struct PController6 {
    UFixed6 k;
    Fixed6 min;
    Fixed6 max;
}
using PController6Lib for PController6 global;

/// @title PController6Lib
/// @notice Configuration for a the fixed 6-decimal PID controller.
/// @dev Each second, the PID controller's value is incremented by `skew / k`, with `max` as the maximum value.
library PController6Lib {
    /// @notice compute the new value and intercept timestamp based on the prior controller state
    /// @dev `interceptTimestamp` will never exceed `toTimestamp`
    /// @param self the controller configuration
    /// @param value the prior value
    /// @param skew The prior skew
    /// @param fromTimestamp The prior timestamp
    /// @param toTimestamp The current timestamp
    /// @return newValue the new value
    /// @return interceptTimestamp the timestamp at which the value will be at the max
    function compute(
        PController6 memory self,
        Fixed6 value,
        Fixed6 skew,
        uint256 fromTimestamp,
        uint256 toTimestamp
    ) internal pure returns (Fixed6 newValue, UFixed6 interceptTimestamp) {
        // compute the new value without considering the max
        Fixed6 newValueUncapped = value.add(
            Fixed6Lib.from(int256(toTimestamp - fromTimestamp))
                .mul(skew)
                .div(Fixed6Lib.from(self.k))
        );

        // cap the new value between min and max
        newValue = newValueUncapped.min(self.max).max(self.min);

        // compute distance and range to the resultant value
        (UFixed6 distance, Fixed6 range) = (UFixed6Lib.from(toTimestamp - fromTimestamp), newValueUncapped.sub(value));

        // compute the amount of buffer until the value is outside the max
        UFixed6 buffer = value.gt(self.max) || value.lt(self.min) ?
            UFixed6Lib.ZERO :
            (range.sign() > 0 ? self.max : self.min).sub(value).abs();

        // compute the timestamp at which the value will be at the max
        interceptTimestamp = range.isZero() ?
            UFixed6Lib.from(toTimestamp) :
            UFixed6Lib.from(fromTimestamp).add(distance.muldiv(buffer, range.abs())).min(UFixed6Lib.from(toTimestamp));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../number/types/UFixed18.sol";

/// @dev Token18
type Token18 is address;
using Token18Lib for Token18 global;
type Token18Storage is bytes32;
using Token18StorageLib for Token18Storage global;

/**
 * @title Token18Lib
 * @notice Library to manage 18-decimal ERC20s that is compliant with the fixed-decimal types.
 * @dev Maintains significant gas savings over other Token implementations since no conversion take place
 */
library Token18Lib {
    using SafeERC20 for IERC20;

    Token18 public constant ZERO = Token18.wrap(address(0));

    /**
     * @notice Returns whether a token is the zero address
     * @param self Token to check for
     * @return Whether the token is the zero address
     */
    function isZero(Token18 self) internal pure returns (bool) {
        return Token18.unwrap(self) == Token18.unwrap(ZERO);
    }

    /**
     * @notice Returns whether the two tokens are equal
     * @param a First token to compare
     * @param b Second token to compare
     * @return Whether the two tokens are equal
     */
    function eq(Token18 a, Token18 b) internal pure returns (bool) {
        return Token18.unwrap(a) ==  Token18.unwrap(b);
    }

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @dev Uses `approve` rather than `safeApprove` since the race condition
     *      in safeApprove does not apply when going to an infinite approval
     * @param self Token to grant approval
     * @param grantee Address to allow spending
     */
    function approve(Token18 self, address grantee) internal {
        IERC20(Token18.unwrap(self)).approve(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @dev There are important race conditions to be aware of when using this function
            with values other than 0. This will revert if moving from non-zero to non-zero amounts
            See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a55b7d13722e7ce850b626da2313f3e66ca1d101/contracts/token/ERC20/IERC20.sol#L57
     * @param self Token to grant approval
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token18 self, address grantee, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeApprove(grantee, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token18 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token18 self, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransfer(recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token18 self, address benefactor, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, address(this), UFixed18.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token18 self, address benefactor, address recipient, UFixed18 amount) internal {
        IERC20(Token18.unwrap(self)).safeTransferFrom(benefactor, recipient, UFixed18.unwrap(amount));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token18 self) internal view returns (string memory) {
        return IERC20Metadata(Token18.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token18 self) internal view returns (UFixed18) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token18 self, address account) internal view returns (UFixed18) {
        return UFixed18.wrap(IERC20(Token18.unwrap(self)).balanceOf(account));
    }
}

library Token18StorageLib {
    function read(Token18Storage self) internal view returns (Token18 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Token18Storage self, Token18 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../../number/types/UFixed6.sol";

/// @dev Token6
type Token6 is address;
using Token6Lib for Token6 global;
type Token6Storage is bytes32;
using Token6StorageLib for Token6Storage global;

/**
 * @title Token6Lib
 * @notice Library to manage 6-decimal ERC20s that is compliant with the fixed-decimal types.
 */
library Token6Lib {
    using SafeERC20 for IERC20;

    Token6 public constant ZERO = Token6.wrap(address(0));

    /**
     * @notice Returns whether a token is the zero address
     * @param self Token to check for
     * @return Whether the token is the zero address
     */
    function isZero(Token6 self) internal pure returns (bool) {
        return Token6.unwrap(self) == Token6.unwrap(ZERO);
    }

    /**
     * @notice Returns whether the two tokens are equal
     * @param a First token to compare
     * @param b Second token to compare
     * @return Whether the two tokens are equal
     */
    function eq(Token6 a, Token6 b) internal pure returns (bool) {
        return Token6.unwrap(a) ==  Token6.unwrap(b);
    }

    /**
     * @notice Approves `grantee` to spend infinite tokens from the caller
     * @dev Uses `approve` rather than `safeApprove` since the race condition
     *      in safeApprove does not apply when going to an infinite approval
     * @param self Token to grant approval
     * @param self Token to grant approval
     * @param grantee Address to allow spending
     */
    function approve(Token6 self, address grantee) internal {
        IERC20(Token6.unwrap(self)).approve(grantee, type(uint256).max);
    }

    /**
     * @notice Approves `grantee` to spend `amount` tokens from the caller
     * @dev There are important race conditions to be aware of when using this function
            with values other than 0. This will revert if moving from non-zero to non-zero amounts
            See https://github.com/OpenZeppelin/openzeppelin-contracts/blob/a55b7d13722e7ce850b626da2313f3e66ca1d101/contracts/token/ERC20/IERC20.sol#L57
     * @param self Token to grant approval
     * @param self Token to grant approval
     * @param grantee Address to allow spending
     * @param amount Amount of tokens to approve to spend
     */
    function approve(Token6 self, address grantee, UFixed6 amount) internal {
        IERC20(Token6.unwrap(self)).safeApprove(grantee, UFixed6.unwrap(amount));
    }

    /**
     * @notice Transfers all held tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to receive the tokens
     */
    function push(Token6 self, address recipient) internal {
        push(self, recipient, balanceOf(self, address(this)));
    }

    /**
     * @notice Transfers `amount` tokens from the caller to the `recipient`
     * @param self Token to transfer
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function push(Token6 self, address recipient, UFixed6 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransfer(recipient, UFixed6.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to the caller
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param amount Amount of tokens to transfer
     */
    function pull(Token6 self, address benefactor, UFixed6 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, address(this), UFixed6.unwrap(amount));
    }

    /**
     * @notice Transfers `amount` tokens from the `benefactor` to `recipient`
     * @dev Reverts if trying to pull Ether
     * @param self Token to transfer
     * @param benefactor Address to transfer tokens from
     * @param recipient Address to transfer tokens to
     * @param amount Amount of tokens to transfer
     */
    function pullTo(Token6 self, address benefactor, address recipient, UFixed6 amount) internal {
        IERC20(Token6.unwrap(self)).safeTransferFrom(benefactor, recipient, UFixed6.unwrap(amount));
    }

    /**
     * @notice Returns the name of the token
     * @param self Token to check for
     * @return Token name
     */
    function name(Token6 self) internal view returns (string memory) {
        return IERC20Metadata(Token6.unwrap(self)).name();
    }

    /**
     * @notice Returns the symbol of the token
     * @param self Token to check for
     * @return Token symbol
     */
    function symbol(Token6 self) internal view returns (string memory) {
        return IERC20Metadata(Token6.unwrap(self)).symbol();
    }

    /**
     * @notice Returns the `self` token balance of the caller
     * @param self Token to check for
     * @return Token balance of the caller
     */
    function balanceOf(Token6 self) internal view returns (UFixed6) {
        return balanceOf(self, address(this));
    }

    /**
     * @notice Returns the `self` token balance of `account`
     * @param self Token to check for
     * @param account Account to check
     * @return Token balance of the account
     */
    function balanceOf(Token6 self, address account) internal view returns (UFixed6) {
        return UFixed6.wrap(IERC20(Token6.unwrap(self)).balanceOf(account));
    }
}

library Token6StorageLib {
    function read(Token6Storage self) internal view returns (Token6 value) {
        assembly ("memory-safe") {
            value := sload(self)
        }
    }

    function store(Token6Storage self, Token6 value) internal {
        assembly ("memory-safe") {
            sstore(self, value)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../number/types/UFixed6.sol";
import "../number/types/Fixed6.sol";

/**
 * @title CurveMath6
 * @notice Library for managing math operations for utilization curves.
 */
library CurveMath6 {
    error CurveMath6OutOfBoundsError();

    /**
     * @notice Computes a linear interpolation between two points
     * @param startX First point's x-coordinate
     * @param startY First point's y-coordinate
     * @param endX Second point's x-coordinate
     * @param endY Second point's y-coordinate
     * @param targetX x-coordinate to interpolate
     * @return y-coordinate for `targetX` along the line from (`startX`, `startY`) -> (`endX`, `endY`)
     */
    function linearInterpolation(
        UFixed6 startX,
        Fixed6 startY,
        UFixed6 endX,
        Fixed6 endY,
        UFixed6 targetX
    ) internal pure returns (Fixed6) {
        if (targetX.lt(startX) || targetX.gt(endX)) revert CurveMath6OutOfBoundsError();

        UFixed6 xRange = endX.sub(startX);
        Fixed6 yRange = endY.sub(startY);
        UFixed6 xRatio = targetX.sub(startX).div(xRange);
        return yRange.mul(Fixed6Lib.from(xRatio)).add(startY);
    }

    /**
     * @notice Computes a linear interpolation between two points
     * @param startX First point's x-coordinate
     * @param startY First point's y-coordinate
     * @param endX Second point's x-coordinate
     * @param endY Second point's y-coordinate
     * @param targetX x-coordinate to interpolate
     * @return y-coordinate for `targetX` along the line from (`startX`, `startY`) -> (`endX`, `endY`)
     */
    function linearInterpolation(
        UFixed6 startX,
        UFixed6 startY,
        UFixed6 endX,
        UFixed6 endY,
        UFixed6 targetX
    ) internal pure returns (UFixed6) {
        return UFixed6Lib.from(linearInterpolation(startX, Fixed6Lib.from(startY), endX, Fixed6Lib.from(endY), targetX));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../CurveMath6.sol";
import "../../number/types/UFixed6.sol";

/// @dev UJumpRateUtilizationCurve6 type
struct UJumpRateUtilizationCurve6 {
    UFixed6 minRate;
    UFixed6 maxRate;
    UFixed6 targetRate;
    UFixed6 targetUtilization;
}
using UJumpRateUtilizationCurve6Lib for UJumpRateUtilizationCurve6 global;

/**
 * @title UJumpRateUtilizationCurve6Lib
 * @notice Library for the unsigned base-6 Jump Rate utilization curve type
 */
library UJumpRateUtilizationCurve6Lib {
    /**
     * @notice Computes the corresponding rate for a utilization ratio
     * @param utilization The utilization ratio
     * @return The corresponding rate
     */
    function compute(UJumpRateUtilizationCurve6 memory self, UFixed6 utilization) internal pure returns (UFixed6) {
        if (utilization.lt(self.targetUtilization)) {
            return CurveMath6.linearInterpolation(
                UFixed6Lib.ZERO,
                self.minRate,
                self.targetUtilization,
                self.targetRate,
                utilization
            );
        }
        if (utilization.lt(UFixed6Lib.ONE)) {
            return CurveMath6.linearInterpolation(
                self.targetUtilization,
                self.targetRate,
                UFixed6Lib.ONE,
                self.maxRate,
                utilization
            );
        }
        return self.maxRate;
    }

    function accumulate(
        UJumpRateUtilizationCurve6 memory self,
        UFixed6 utilization,
        uint256 fromTimestamp,
        uint256 toTimestamp,
        UFixed6 notional
    ) internal pure returns (UFixed6) {
        return compute(self, utilization)
            .mul(UFixed6Lib.from(toTimestamp - fromTimestamp))
            .mul(notional)
            .div(UFixed6Lib.from(365 days));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import {Initializable} from "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMathUpgradeable {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";
import "./math/SignedMathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMathUpgradeable.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC5267.sol)

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.3) (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;

import "./TransparentUpgradeableProxy.sol";
import "../../access/Ownable.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(ITransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(ITransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(ITransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(ITransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        ITransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev Interface for {TransparentUpgradeableProxy}. In order to implement transparency, {TransparentUpgradeableProxy}
 * does not implement this interface directly, and some of its functions are implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {TransparentUpgradeableProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface ITransparentUpgradeableProxy is IERC1967 {
    function admin() external view returns (address);

    function implementation() external view returns (address);

    function changeAdmin(address) external;

    function upgradeTo(address) external;

    function upgradeToAndCall(address, bytes memory) external payable;
}

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 *
 * NOTE: The real interface of this proxy is that defined in `ITransparentUpgradeableProxy`. This contract does not
 * inherit from that interface, and instead the admin functions are implicitly implemented using a custom dispatch
 * mechanism in `_fallback`. Consequently, the compiler will not produce an ABI for this contract. This is necessary to
 * fully implement transparency without decoding reverts caused by selector clashes between the proxy and the
 * implementation.
 *
 * WARNING: It is not recommended to extend this contract to add additional external functions. If you do so, the compiler
 * will not check that there are no selector conflicts, due to the note above. A selector clash between any new function
 * and the functions declared in {ITransparentUpgradeableProxy} will be resolved in favor of the new one. This could
 * render the admin operations inaccessible, which could prevent upgradeability. Transparency may also be compromised.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     *
     * CAUTION: This modifier is deprecated, as it could cause issues if the modified function has arguments, and the
     * implementation provides a function with the same selector.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior
     */
    function _fallback() internal virtual override {
        if (msg.sender == _getAdmin()) {
            bytes memory ret;
            bytes4 selector = msg.sig;
            if (selector == ITransparentUpgradeableProxy.upgradeTo.selector) {
                ret = _dispatchUpgradeTo();
            } else if (selector == ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                ret = _dispatchUpgradeToAndCall();
            } else if (selector == ITransparentUpgradeableProxy.changeAdmin.selector) {
                ret = _dispatchChangeAdmin();
            } else if (selector == ITransparentUpgradeableProxy.admin.selector) {
                ret = _dispatchAdmin();
            } else if (selector == ITransparentUpgradeableProxy.implementation.selector) {
                ret = _dispatchImplementation();
            } else {
                revert("TransparentUpgradeableProxy: admin cannot fallback to proxy target");
            }
            assembly {
                return(add(ret, 0x20), mload(ret))
            }
        } else {
            super._fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function _dispatchAdmin() private returns (bytes memory) {
        _requireZeroValue();

        address admin = _getAdmin();
        return abi.encode(admin);
    }

    /**
     * @dev Returns the current implementation.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function _dispatchImplementation() private returns (bytes memory) {
        _requireZeroValue();

        address implementation = _implementation();
        return abi.encode(implementation);
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _dispatchChangeAdmin() private returns (bytes memory) {
        _requireZeroValue();

        address newAdmin = abi.decode(msg.data[4:], (address));
        _changeAdmin(newAdmin);

        return "";
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     */
    function _dispatchUpgradeTo() private returns (bytes memory) {
        _requireZeroValue();

        address newImplementation = abi.decode(msg.data[4:], (address));
        _upgradeToAndCall(newImplementation, bytes(""), false);

        return "";
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     */
    function _dispatchUpgradeToAndCall() private returns (bytes memory) {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        _upgradeToAndCall(newImplementation, data, true);

        return "";
    }

    /**
     * @dev Returns the current admin.
     *
     * CAUTION: This function is deprecated. Use {ERC1967Upgrade-_getAdmin} instead.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev To keep this contract fully transparent, all `ifAdmin` functions must be payable. This helper is here to
     * emulate some proxy functions being non-payable while still allowing value to pass through.
     */
    function _requireZeroValue() private {
        require(msg.value == 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
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
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
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
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     *
     * _Available since v4.9._
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/ShortStrings.sol)

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

// | string  | 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA   |
// | length  | 0x                                                              BB |
type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 *
 * Strings of arbitrary length can be optimized using this library if
 * they are short enough (up to 31 bytes) by packing them with their
 * length (1 byte) in a single EVM word (32 bytes). Additionally, a
 * fallback mechanism can be used for every other case.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    // Used as an identifier for strings longer than 31 bytes.
    bytes32 private constant _FALLBACK_SENTINEL = 0x00000000000000000000000000000000000000000000000000000000000000FF;

    error StringTooLong(string str);
    error InvalidShortString();

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = byteLength(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function byteLength(ShortString sstr) internal pure returns (uint256) {
        uint256 result = uint256(ShortString.unwrap(sstr)) & 0xFF;
        if (result > 31) {
            revert InvalidShortString();
        }
        return result;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(_FALLBACK_SENTINEL);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return toString(value);
        } else {
            return store;
        }
    }

    /**
     * @dev Return the length of a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     *
     * WARNING: This will return the "byte length" of the string. This may not reflect the actual length in terms of
     * actual characters as the UTF-8 encoding of a single character can span over multiple bytes.
     */
    function byteLengthWithFallback(ShortString value, string storage store) internal view returns (uint256) {
        if (ShortString.unwrap(value) != _FALLBACK_SENTINEL) {
            return byteLength(value);
        } else {
            return bytes(store).length;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);

    /// @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

interface IApproveAndCall {
    // enum ApprovalType {NOT_REQUIRED, MAX, MAX_MINUS_ONE, ZERO_THEN_MAX, ZERO_THEN_MAX_MINUS_ONE}

    // /// @dev Lens to be called off-chain to determine which (if any) of the relevant approval functions should be called
    // /// @param token The token to approve
    // /// @param amount The amount to approve
    // /// @return The required approval type
    // function getApprovalType(address token, uint256 amount) external returns (ApprovalType);

    // /// @notice Approves a token for the maximum possible amount
    // /// @param token The token to approve
    // function approveMax(address token) external payable;

    // /// @notice Approves a token for the maximum possible amount minus one
    // /// @param token The token to approve
    // function approveMaxMinusOne(address token) external payable;

    // /// @notice Approves a token for zero, then the maximum possible amount
    // /// @param token The token to approve
    // function approveZeroThenMax(address token) external payable;

    // /// @notice Approves a token for zero, then the maximum possible amount minus one
    // /// @param token The token to approve
    // function approveZeroThenMaxMinusOne(address token) external payable;

    // /// @notice Calls the position manager with arbitrary calldata
    // /// @param data Calldata to pass along to the position manager
    // /// @return result The result from the call
    // function callPositionManager(bytes memory data) external payable returns (bytes memory result);

    // struct MintParams {
    //     address token0;
    //     address token1;
    //     uint24 fee;
    //     int24 tickLower;
    //     int24 tickUpper;
    //     uint256 amount0Min;
    //     uint256 amount1Min;
    //     address recipient;
    // }

    // /// @notice Calls the position manager's mint function
    // /// @param params Calldata to pass along to the position manager
    // /// @return result The result from the call
    // function mint(MintParams calldata params) external payable returns (bytes memory result);

    // struct IncreaseLiquidityParams {
    //     address token0;
    //     address token1;
    //     uint256 tokenId;
    //     uint256 amount0Min;
    //     uint256 amount1Min;
    // }

    // /// @notice Calls the position manager's increaseLiquidity function
    // /// @param params Calldata to pass along to the position manager
    // /// @return result The result from the call
    // function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (bytes memory result);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol';

/// @title MulticallExtended interface
/// @notice Enables calling multiple methods in a single call to the contract with optional validation
interface IMulticallExtended is IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param deadline The time by which this function must be called before failing
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param previousBlockhash The expected parent blockHash
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes32 previousBlockhash, bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/interfaces/ISelfPermit.sol';

import './IV2SwapRouter.sol';
import './IV3SwapRouter.sol';
import './IApproveAndCall.sol';
import './IMulticallExtended.sol';

/// @title Router token swapping functionality
interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter, IApproveAndCall, IMulticallExtended, ISelfPermit {

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V2
interface IV2SwapRouter {
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for an exact amount of another token
    /// @param amountOut The amount of token to swap for
    /// @param amountInMax The maximum amount of input that the caller will pay
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountIn The amount of token to pay
    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IV3SwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Self Permit
/// @notice Functionality to call permit on any EIP-2612-compliant token for use in the route
interface ISelfPermit {
    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend a given token from `msg.sender`
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this).
    /// Can be used instead of #selfPermit to prevent calls from failing due to a frontrun of a call to #selfPermit
    /// @param token The address of the token spent
    /// @param value The amount that can be spent of token
    /// @param deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    /// @notice Permits this contract to spend the sender's tokens for permit signatures that have the `allowed` parameter
    /// @dev The `owner` is always msg.sender and the `spender` is always address(this)
    /// Can be used instead of #selfPermitAllowed to prevent calls from failing due to a frontrun of a call to #selfPermitAllowed.
    /// @param token The address of the token spent
    /// @param nonce The current nonce of the owner
    /// @param expiry The timestamp at which the permit is no longer valid
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity 0.8.18;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {IAddressBookGamma} from "../interfaces/IGamma.sol";

/**
 * @author Opyn Team
 * @title AddressBook Module
 */
contract AddressBook is IAddressBook, OwnableUpgradeable {
    mapping(bytes32 => address) private _addresses;
    /// @dev Address of OpynAddressBook to get state of their addressbook
    bytes32 private constant OPYN_ADDRESS_BOOK = keccak256("OPYN_ADDRESS_BOOK");
    /// @dev Address of LP_MANAGER
    bytes32 private constant LP_MANAGER = keccak256("LP_MANAGER");
    /// @dev Address of ORDER_UTIL
    bytes32 private constant ORDER_UTIL = keccak256("ORDER_UTIL");
    /// @dev Address of FEE_COLLECTOR
    bytes32 private constant FEE_COLLECTOR = keccak256("FEE_COLLECTOR");
    /// @dev Address of LENS
    bytes32 private constant LENS = keccak256("LENS");
    /// @dev Address of TRADE_EXECUTOR
    bytes32 private constant TRADE_EXECUTOR = keccak256("TRADE_EXECUTOR");

    /// 3rd party
    /// @dev Address of PERENNIAL_MULTI_INVOKER
    bytes32 private constant PERENNIAL_MULTI_INVOKER =
        keccak256("PERENNIAL_MULTI_INVOKER");
    /// @dev Address of PERENNIAL_LENS
    bytes32 private constant PERENNIAL_LENS = keccak256("PERENNIAL_LENS");

    /**
     *****************************************
     * Mutating Functions
     *****************************************
     */

    /// @notice Perform inherited contracts' initializations
    function __AddressBook_init() external initializer {
        __Ownable_init_unchained();
    }

    /** Opyn Implentation to call out to opyns contract to return values found on their addressbook
     **/
    /**
     * @notice return Otoken implementation address
     * @return Otoken implementation address
     */
    function getOtokenImpl() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getOtokenImpl();
    }

    /**
     * @notice return oTokenFactory address
     * @return OtokenFactory address
     */
    function getOtokenFactory() external view returns (address) {
        return
            IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getOtokenFactory();
    }

    /**
     * @notice return Whitelist address
     * @return Whitelist address
     */
    function getWhitelist() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getWhitelist();
    }

    /**
     * @notice return Controller address
     * @return Controller address
     */
    function getController() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getController();
    }

    /**
     * @notice return MarginPool address
     * @return MarginPool address
     */
    function getMarginPool() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getMarginPool();
    }

    /**
     * @notice return MarginCalculator address
     * @return MarginCalculator address
     */
    function getMarginCalculator() external view returns (address) {
        return
            IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK))
                .getMarginCalculator();
    }

    /**
     * @notice return LiquidationManager address
     * @return LiquidationManager address
     */
    function getLiquidationManager() external view returns (address) {
        return
            IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK))
                .getLiquidationManager();
    }

    /**
     * @notice return Oracle address
     * @return Oracle address
     */
    function getOracle() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getOracle();
    }

    function getAccessKey() external view returns (address) {
        return IAddressBookGamma(getAddress(OPYN_ADDRESS_BOOK)).getAccessKey();
    }

    /**
     *****************************************
     * Setters for siren implenetation
     *****************************************
     */

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param opynAddressBook The opynAddressBook to set
     */
    function setOpynAddressBook(address opynAddressBook) external onlyOwner {
        _addresses[OPYN_ADDRESS_BOOK] = opynAddressBook;
        emit OpynAddressBookUpdated(opynAddressBook);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param lpManagerAddress LpManager address
     */
    function setLpManager(address lpManagerAddress) external onlyOwner {
        _addresses[LP_MANAGER] = lpManagerAddress;
        emit LpManagerUpdated(lpManagerAddress);
    }

    function setOrderUtil(address orderUtilAddress) external onlyOwner {
        _addresses[ORDER_UTIL] = orderUtilAddress;
        emit OrderUtilUpdated(orderUtilAddress);
    }

    function setFeeCollector(address feeCollectorAddress) external onlyOwner {
        _addresses[FEE_COLLECTOR] = feeCollectorAddress;
        emit FeeCollectorUpdated(feeCollectorAddress);
    }

    function setLens(address lensAddress) external onlyOwner {
        _addresses[LENS] = lensAddress;
        emit LensUpdated(lensAddress);
    }

    function setTradeExecutor(address tradeExecutorAddress) external onlyOwner {
        _addresses[TRADE_EXECUTOR] = tradeExecutorAddress;
        emit TradeExecutorUpdated(tradeExecutorAddress);
    }

    function setPerennialMultiInvoker(
        address multiInvokerAddress
    ) external onlyOwner {
        _addresses[PERENNIAL_MULTI_INVOKER] = multiInvokerAddress;
        emit PerennialMultiInvokerUpdated(multiInvokerAddress);
    }

    function setPerennialLens(address lensAddress) external onlyOwner {
        _addresses[PERENNIAL_LENS] = lensAddress;
        emit PerennialLensUpdated(lensAddress);
    }

    /**
     *****************************************
     * Getters for siren implenetation
     *****************************************
     */

    function getOpynAddressBook() external view returns (address) {
        return getAddress(OPYN_ADDRESS_BOOK);
    }

    function getLpManager() external view override returns (address) {
        return getAddress(LP_MANAGER);
    }

    function getOrderUtil() external view returns (address) {
        return getAddress(ORDER_UTIL);
    }

    /// @notice Fee Collector address
    /// @return FeeCollector address
    function getFeeCollector() external view returns (address) {
        return getAddress(FEE_COLLECTOR);
    }

    /// @notice Siren Lens address
    /// @return Lens address
    function getLens() external view returns (address) {
        return getAddress(LENS);
    }

    /// @notice TradeExecutor address
    /// @return TradeExecutor address
    function getTradeExecutor() external view returns (address) {
        return getAddress(TRADE_EXECUTOR);
    }

    /// @notice Perennial MultiInvoker address
    /// @return MultiInvoker address
    function getPerennialMultiInvoker() external view returns (address) {
        return getAddress(PERENNIAL_MULTI_INVOKER);
    }

    /// @notice Perennial Lens address
    /// @return PerennialLens address
    function getPerennialLens() external view returns (address) {
        return getAddress(PERENNIAL_LENS);
    }

    /**
     *****************************************
     * General Admin Functions for Address Book
     *****************************************
     */
    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(
        bytes32 id,
        address newAddress
    ) external override onlyOwner {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }
}

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Fees Collector contract
contract FeeCollector is OwnableUpgradeable {
    event FeeCollected(
        address pool,
        address referrer,
        address feeAsset,
        uint256 totalFee,
        uint256 referrerAmount
    );

    event FeeWithdrawn(address referrer, address feeAsset, uint256 amount);

    event ReferrerFeeSplitSet(uint256 referrerFeeSplitBips);

    using SafeERC20 for IERC20;

    /// @notice Fees collected (referrer => token => amount)
    mapping(address => mapping(address => uint256)) public feesCollected;

    /// @notice Fees withdrawn (referrer => token => amount)
    mapping(address => mapping(address => uint256)) public feesWithdrawn;

    /// @notice How much in bps referrer gets
    uint256 public referrerFeeSplitBips;

    function __FeeCollector_init() external initializer {
        referrerFeeSplitBips = 5_000; // 50% by default
        __Ownable_init();
    }

    /// @notice Get balance of asset available for withdrawal
    /// @param feeAsset Asset address
    /// @param referrer Referrer address (use zero-address for protocol balance)
    function getBalance(
        address feeAsset,
        address referrer
    ) public view returns (uint256) {
        return
            feesCollected[referrer][feeAsset] -
            feesWithdrawn[referrer][feeAsset];
    }

    /// @notice Transfer fee from the pool
    function collectFee(
        address feeAsset,
        uint256 feeAmount,
        address referrer
    ) external {
        uint256 referrerAmount;

        if (referrer != address(0)) {
            referrerAmount = (feeAmount * referrerFeeSplitBips) / 10_000;
            // record referrer fees
            feesCollected[referrer][feeAsset] += referrerAmount;
        }

        // record protocol fees
        feesCollected[address(0)][feeAsset] += feeAmount - referrerAmount;

        IERC20(feeAsset).safeTransferFrom(msg.sender, address(this), feeAmount);

        // Emit event
        emit FeeCollected(
            msg.sender,
            referrer,
            feeAsset,
            feeAmount,
            referrerAmount
        );
    }

    /// @notice Referrer can withdraw accumulated fees
    function withdrawFee(address feeAsset) external {
        _withdrawFee(feeAsset, msg.sender);
    }

    /// @notice Owner can withdraw accumulated fees
    function ownerWithdrawFee(address feeAsset) external onlyOwner {
        _withdrawFee(feeAsset, address(0));
    }

    /// @notice Withdraw accumulated fees
    function _withdrawFee(address feeAsset, address referrer) internal {
        uint256 feeAmount = getBalance(feeAsset, referrer);

        if (feeAmount == 0) return;

        feesWithdrawn[referrer][feeAsset] += feeAmount;

        IERC20(feeAsset).safeTransfer(msg.sender, feeAmount);

        emit FeeWithdrawn(referrer, feeAsset, feeAmount);
    }

    /// @notice Owner can set referral fee split
    function setReferrerFeeSplit(
        uint256 _referrerFeeSplitBips
    ) external onlyOwner {
        require(_referrerFeeSplitBips <= 10_000, "Fee spilt too high");

        referrerFeeSplitBips = _referrerFeeSplitBips;

        emit ReferrerFeeSplitSet(_referrerFeeSplitBips);
    }
}

// SPDX-License-Identifier: None

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IOtoken, IOracle, GammaTypes, IController, IOtokenFactory, IMarginCalculator} from "../interfaces/IGamma.sol";
import "./HedgedPoolStorage.sol";
import "../interfaces/ILpManager.sol";
import "../libs/Math.sol";
import "../libs/Dates.sol";
import "../libs/OpynLib.sol";
import "../interfaces/IOrderUtil.sol";
import "../interfaces/IFeeCollector.sol";
import "../interfaces/ITradeExecutor.sol";
import "../interfaces/CustomErrors.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract HedgedPool is
    Initializable,
    OwnableUpgradeable,
    ERC20Upgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155Holder,
    HedgedPoolStorageV1
{
    /// @notice Pool is initialized
    event HedgedPoolInitialized(
        address strikeToken,
        address collateralToken,
        string tokenName,
        string tokenSymbol
    );

    /// @notice All series for a given expiry settled
    event ExpirySettled(uint256 expiryTimestamp);

    struct TradeLeg {
        int256 amount;
        int256 premium;
        uint256 fee;
        address oToken;
    }

    event Trade(
        address referrer,
        uint256 totalPremium,
        uint256 totalFee,
        uint256 totalNotional,
        TradeLeg[] legs
    );

    /// @dev NOTE: No local variables should be added here.  Instead see HedgedPoolStorage.sol

    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice Emitted when hedger address is set
    event HedgerSet(address underlying, address hedger);

    event VaultMarginUpdated(uint256 vaultId, int256 collateralChange);

    event UnderlyingConfigured(
        address _underlying,
        bool _enabled,
        uint256 _minPercent,
        uint256 _maxPercent,
        uint256 _increment
    );

    event AllowedExpirationsSetV2(
        address _underlying,
        uint8 _numMonths,
        uint8 _numQuarters,
        bool allowDailyExpiration
    );

    function onlyKeeper() internal view {
        if (!keepers[msg.sender]) {
            revert CustomErrors.Unauthorized();
        }
    }

    function onlyAccessKey() internal view {
        if (
            isLocked &&
            IERC1155(addressBook.getAccessKey()).balanceOf(
                msg.sender,
                accessKeyId
            ) ==
            0
        ) {
            revert CustomErrors.NoAccessKey();
        }
    }

    /// Initialize the contract, and create an lpToken to track ownership
    function __HedgedPool_init(
        address _addresBookAddress,
        address _strikeToken,
        address _collateralToken,
        string calldata _tokenName,
        string calldata _tokenSymbol
    ) public initializer {
        addressBook = IAddressBook(_addresBookAddress);

        strikeToken = IERC20(_strikeToken);
        collateralToken = IERC20(_collateralToken);

        // Initizlie ERC20 LP token
        __ERC20_init(_tokenName, _tokenSymbol);
        numDecimals = IERC20MetadataUpgradeable(address(collateralToken))
            .decimals();

        // Set first rounds end date
        lastSettledExpiry = Dates.get8amAligned(block.timestamp, 1 days);
        withdrawalRoundEnd = lastSettledExpiry + 1 days;
        depositRoundEnd = Dates.get8amAligned(block.timestamp, 1 days) + 1 days;

        __Ownable_init();
        __ReentrancyGuard_init();

        // Set default values
        pricePerShareCached = 1e8;
        seriesPerExpirationLimit = 20;

        _refreshConfigInternal();

        emit HedgedPoolInitialized(
            _strikeToken,
            _collateralToken,
            _tokenName,
            _tokenSymbol
        );
    }

    /// @notice Get total value of the pool shares
    /// @param pricePerShare price per share * 1e8
    function getTotalPoolValue(
        uint256 pricePerShare
    ) public view returns (uint256) {
        return (totalSupply() * pricePerShare) / 1e8;
    }

    /// @notice Get total pool value based on the latest cached share price
    function getTotalPoolValueCached() public view returns (uint256) {
        return getTotalPoolValue(pricePerShareCached);
    }

    /**
     * @notice Settle all expired long and short tokens
     * @return amount of collateral redeemed from the vault
     */
    function settleAll() public returns (uint256) {
        // Save pre-settlement collateral balance
        uint256 startCollateralBalance = collateralToken.balanceOf(
            address(this)
        );

        uint256 expiry = lastSettledExpiry + 1 days;

        while (expiry <= block.timestamp) {
            for (uint iu = 0; iu < underlyingTokens.length(); iu++) {
                address underlying = underlyingTokens.at(iu);

                uint256 vaultId = ITradeExecutor(tradeExecutor).marginVaults(
                    address(this),
                    underlying,
                    0
                );
                (
                    int256 exposureBeforeCalls,
                    int256 exposureBeforePuts
                ) = IController(controller).getVaultExposure(
                        address(this),
                        vaultId
                    );

                OpynLib.settle(controller, vaultId);

                (
                    int256 exposureAfterCalls,
                    int256 exposureAfterPuts
                ) = IController(controller).getVaultExposure(
                        address(this),
                        vaultId
                    );

                // exposure can only go down when shorts are removed from the vault
                notionalExposure[underlying][false] += Math.max(
                    0,
                    exposureAfterCalls - exposureBeforeCalls
                );
                notionalExposure[underlying][true] += Math.max(
                    0,
                    exposureAfterPuts - exposureBeforePuts
                );

                // remove options from the pool
                for (
                    uint io = 0;
                    io < oTokensByExpiry[underlying][expiry].length;
                    io++
                ) {
                    activeOTokens.remove(
                        oTokensByExpiry[underlying][expiry][io]
                    );
                }
            }

            lastSettledExpiry = expiry;

            emit ExpirySettled(expiry);

            expiry += 1 days;
        }

        uint256 endCollateralBalance = collateralToken.balanceOf(address(this));

        processWithdrawals();

        return endCollateralBalance - startCollateralBalance;
    }

    /*****************
    Keeper methods
    ******************/

    /// @notice Close current deposit and withdrawal rounds at specified share price within the guardrails
    /// @param pricePerShare price per share * 1e8
    function closeRound(uint256 pricePerShare) external {
        onlyKeeper();

        // price per share guardrails (10% per day)
        if (
            pricePerShare < (pricePerShareCached * 90) / 100 ||
            pricePerShare > (pricePerShareCached * 110) / 100
        ) {
            revert CustomErrors.InvalidPricePerShare();
        }

        _closeRound(pricePerShare);
    }

    /// @notice Manually close round using price per share outside of the guardrails
    /// @param pricePerShare price per share * 1e8
    function closeRoundAdmin(uint256 pricePerShare) external onlyOwner {
        _closeRound(pricePerShare);
    }

    /// @notice Close current deposit and withdrawal rounds at specified share price
    /// @param pricePerShare price per share * 1e8
    function _closeRound(uint256 pricePerShare) internal {
        // cannot close a round when there's unsettled expiry
        if (lastSettledExpiry + 1 days < block.timestamp) {
            revert CustomErrors.NotSettled();
        }

        // advance to the next round if necessary
        int256 sharesDiff;
        // close withdrawal round
        if (withdrawalRoundEnd <= block.timestamp) {
            sharesDiff -= int256(
                ILpManager(lpManager).closeWithdrawalRound(pricePerShare)
            );

            withdrawalRoundEnd += 1 days;

            pricePerShareCached = pricePerShare;
        }

        if (depositRoundEnd <= block.timestamp) {
            sharesDiff += int256(
                ILpManager(lpManager).closeDepositRound(pricePerShare)
            );

            depositRoundEnd += 1 days;

            pricePerShareCached = pricePerShare;
        }

        // mint or burn LP tokens
        if (sharesDiff < 0) {
            // burn lp tokens corresponding to filled withdrawal shares
            _burn(address(this), uint256(-sharesDiff));
        } else if (sharesDiff > 0) {
            // mint lp tokens corresponding to new deposits
            _mint(address(this), uint256(sharesDiff));
        }
    }

    /*****************
    LP Manager methods
    ******************/

    /// @dev process pending withdrawals
    function processWithdrawals() internal {
        uint256 freeCollateral = collateralToken.balanceOf(address(this)) -
            ILpManager(lpManager).getCashLocked(address(this), true);

        uint256 cashBuffer = getCashBuffer();

        // exit early if nothing to withdraw
        if (freeCollateral <= cashBuffer) return;

        uint256 unfilledShares = ILpManager(lpManager).getUnfilledShares(
            address(this)
        );
        // lock amount using the last cached price per share + 10%
        // any excess will be refunded after round close
        uint256 requiredAmount = (unfilledShares * pricePerShareCached * 11) /
            1e9;
        uint256 withdrawAmount = Math.min(
            requiredAmount,
            freeCollateral - cashBuffer
        );
        if (withdrawAmount > 0) {
            ILpManager(lpManager).addPendingCash(withdrawAmount);
        }
    }

    /// @notice Redeem shares from processed deposits
    function redeemShares() external nonReentrant {
        _redeemShares(msg.sender);
    }

    function _redeemShares(address lpAddress) private {
        uint256 sharesAmount = ILpManager(lpManager).redeemShares(lpAddress);

        if (sharesAmount > 0) {
            this.transfer(lpAddress, sharesAmount);
        }
    }

    /// @notice Request withdrawal
    function requestWithdrawal(uint256 sharesAmount) external nonReentrant {
        address lpAddress = msg.sender;

        // redeem unredeemed shares first
        _redeemShares(msg.sender);

        if (balanceOf(lpAddress) < sharesAmount) {
            revert CustomErrors.InsufficientBalance();
        }

        ILpManager(lpManager).requestWithdrawal(lpAddress, sharesAmount);

        // Burn the lp tokens
        _burn(msg.sender, sharesAmount);
        // mint LP tokens to self for accounting
        _mint(address(this), sharesAmount);
    }

    /// @notice Withdraw available cash
    function withdrawCash() external nonReentrant {
        (uint256 cashAmount, ) = ILpManager(lpManager).withdrawCash(msg.sender);

        if (cashAmount > 0) {
            IERC20(collateralToken).safeTransfer(msg.sender, cashAmount);
        }
    }

    /// @notice Request deposit
    function requestDeposit(uint256 amount) external nonReentrant {
        onlyAccessKey();

        if (amount == 0) {
            revert CustomErrors.ZeroValue();
        }

        address lpAddress = msg.sender;

        ILpManager(lpManager).requestDeposit(lpAddress, amount);

        IERC20(collateralToken).safeTransferFrom(
            lpAddress,
            address(this),
            amount
        );
    }

    /// @notice Cancel pending unprocessed deposit
    function cancelPendingDeposit(uint256 amount) external nonReentrant {
        ILpManager(lpManager).cancelPendingDeposit(msg.sender, amount);

        IERC20(collateralToken).safeTransfer(msg.sender, amount);
    }

    /// @notice Available liquidity in the pool (excludes pending deposits and withdrawals)
    function getCollateralBalance() public view override returns (uint256) {
        return
            collateralToken.balanceOf(address(this)) -
            ILpManager(lpManager).getCashLocked(address(this), true);
    }

    function getCashBuffer() public view returns (uint256) {
        uint256 cashBuffer;

        for (uint256 i = 0; i < underlyingTokens.length(); i++) {
            address underlyingAsset = underlyingTokens.at(i);
            uint256 underlyingPrice;
            int256 exposureCalls = notionalExposure[underlyingAsset][false];
            int256 exposurePuts = notionalExposure[underlyingAsset][true];

            uint256 cashBufferCalls;
            uint256 cashBufferPuts;

            if (exposureCalls < 0) {
                // calls

                underlyingPrice = IOracle(oracle).getPrice(underlyingAsset);
                cashBufferCalls =
                    (((((uint256(-exposureCalls) * underlyingPrice) /
                        (10 ** 8)) * spotShockPercent[underlyingAsset][false]) /
                        100 /
                        CASH_BUFFER_LEVERAGE) * (10 ** numDecimals)) /
                    (10 ** 8);
            }

            if (exposurePuts < 0) {
                // puts
                if (underlyingPrice == 0)
                    underlyingPrice = IOracle(oracle).getPrice(underlyingAsset);

                cashBufferPuts =
                    (((((uint256(-exposurePuts) * underlyingPrice) /
                        (10 ** 8)) * spotShockPercent[underlyingAsset][true]) /
                        100 /
                        CASH_BUFFER_LEVERAGE) * (10 ** numDecimals)) /
                    (10 ** 8);
            }

            cashBuffer += Math.max(cashBufferCalls, cashBufferPuts);
        }

        return cashBuffer;
    }

    /*****************
    ERC20 methods
    ******************/

    function decimals() public view override(ERC20Upgradeable) returns (uint8) {
        return numDecimals;
    }

    function balanceOf(
        address account
    ) public view override(ERC20Upgradeable) returns (uint256) {
        (, uint256 sharesRedeemable) = ILpManager(lpManager).getDepositStatus(
            address(this),
            account
        );
        return super.balanceOf(account) + sharesRedeemable;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override(ERC20Upgradeable) {
        // redeem unredeemed shares first
        _redeemShares(sender);

        super._transfer(sender, recipient, amount);
    }

    /***********************
    Trading methods
    ***********************/

    struct TradeVars {
        int256 exposureDiffCalls;
        int256 exposureDiffPuts;
    }

    /// @notice execute a signed buy or sell order
    /// @param order Order struct containing order parameters
    /// @param traderDeposit Amount of collateral to deposit
    /// @param traderVaultId MarginVault id of the trader
    /// @param autoCreateVault Whether to auto create vault if it doesn't exist
    function trade(
        IOrderUtil.Order calldata order,
        uint256 traderDeposit,
        uint256 traderVaultId,
        bool autoCreateVault
    ) public nonReentrant {
        onlyAccessKey();

        // validate that the order signer has QUOTE_PROVIDER role. The signing contract has to return the recovered signer.
        processOrder(order);

        if (traderDeposit > 0) {
            collateralToken.safeTransferFrom(
                msg.sender,
                address(this),
                traderDeposit
            );
        }

        TradeVars memory vars;

        address[] memory oTokens;
        uint256 fee;
        (
            oTokens,
            fee,
            vars.exposureDiffCalls,
            vars.exposureDiffPuts
        ) = ITradeExecutor(tradeExecutor).executeTrade(
            order,
            ITradeExecutor(tradeExecutor).marginVaults(
                address(this),
                order.underlying,
                0
            ),
            msg.sender,
            traderDeposit,
            traderVaultId,
            autoCreateVault
        );

        // charge fee
        if (fee > 0) {
            IFeeCollector(feeCollector).collectFee(
                address(collateralToken),
                fee,
                order.referrer
            );
        }

        // update notional exposure
        uint256 notionalExposureOfPoolCallsBefore = Math.abs(
            notionalExposure[order.underlying][false]
        );
        uint256 notionalExposureOfPoolPutsBefore = Math.abs(
            notionalExposure[order.underlying][true]
        );

        notionalExposure[order.underlying][false] += vars.exposureDiffCalls;
        notionalExposure[order.underlying][true] += vars.exposureDiffPuts;

        // Check absolute notional Exposure of the pool has it gone up or down? - if it has gone down then we dont need to check the second if
        if (
            Math.abs(notionalExposure[order.underlying][false]) >
            notionalExposureOfPoolCallsBefore ||
            Math.abs(notionalExposure[order.underlying][true]) >
            notionalExposureOfPoolPutsBefore
        ) {
            if (getCollateralBalance() < getCashBuffer()) {
                revert CustomErrors.NotEnoughLiquidity();
            }
        }

        // store oTokens
        uint256 underlyingPrice = IOracle(oracle).getPrice(order.underlying);

        uint256 totalPremium;
        uint256 totalAmount;
        TradeLeg[] memory tradeLegs = new TradeLeg[](order.legs.length);
        for (uint256 i; i < order.legs.length; i++) {
            IOrderUtil.OptionLeg memory leg = order.legs[i];

            processOToken(
                order.underlying,
                leg.strike,
                leg.expiration,
                oTokens[i],
                underlyingPrice
            );

            tradeLegs[i] = TradeLeg({
                oToken: oTokens[i],
                amount: leg.amount,
                premium: leg.premium,
                fee: leg.fee
            });

            totalPremium += Math.abs(leg.premium);
            totalAmount += Math.abs(leg.amount);
        }

        emit Trade(order.referrer, totalPremium, fee, totalAmount, tradeLegs);
    }

    /// @notice Process a pool order
    /// @param order is the id of the vault to be settled
    function processOrder(IOrderUtil.Order calldata order) internal {
        if (!underlyingTokens.contains(order.underlying)) {
            revert CustomErrors.InvalidUnderlying();
        }

        // Validate each leg
        for (uint i = 0; i < order.legs.length; i++) {
            IOrderUtil.OptionLeg memory leg = order.legs[i];
            if (leg.expiration <= block.timestamp) {
                revert CustomErrors.SeriesExpired();
            }
            if (
                leg.amount == 0 ||
                leg.premium == 0 ||
                (leg.amount > 0 && leg.premium < 0) ||
                (leg.amount < 0 && leg.premium > 0)
            ) {
                revert CustomErrors.InvalidOrder();
            }
        }

        // Check that the pool address
        if (order.poolAddress != address(this)) {
            revert CustomErrors.InvalidPoolAddress();
        }

        // Get order signers
        (address signer /* address[] memory coSigners */, ) = IOrderUtil(
            orderUtil
        ).processOrder(order);

        // TODO: check n-of-m co-signers
        // Check that the signatory has the Role Quote provider
        if (!quoteProviders[signer]) {
            revert CustomErrors.Unauthorized();
        }
    }

    /// @notice Get active oToken by index
    /// @param index is the index of the active oToken
    /// @return oToken address
    function getActiveOToken(uint256 index) public view returns (address) {
        return activeOTokens.at(index);
    }

    /// @notice Get all active oTokens
    function getActiveOTokens() public view returns (address[] memory) {
        address[] memory series = new address[](activeOTokens.length());
        for (uint256 i = 0; i < activeOTokens.length(); i++) {
            series[i] = activeOTokens.at(i);
        }
        return series;
    }

    /*******************
    Series management
    ********************/

    //  Guard Rails around price, price of a call should never exceed of the underlying

    /// @dev Update limit of series per expiration date
    function updateSeriesPerExpirationLimit(
        uint256 _seriesPerExpirationLimit
    ) public onlyOwner {
        seriesPerExpirationLimit = _seriesPerExpirationLimit;
    }

    /// @notice Validates oToken and adds it to the pool mappings for tracking
    function processOToken(
        address underlying,
        uint256 strikePrice,
        uint256 expiry,
        address oToken,
        uint256 underlyingPrice
    ) internal {
        // If otoken exists in our amm we can return otoken Address
        if (activeOTokens.contains(oToken)) {
            return;
        }

        // Validate expiration
        if (
            !Dates.isValidExpiry(
                block.timestamp,
                expiry,
                allowedExpirations[underlying].numMonths,
                allowedExpirations[underlying].numQuarters,
                allowedExpirations[underlying].allowDailyExpiration
            )
        ) {
            revert CustomErrors.ExpiryNotSupported();
        }

        // We should always be less than the series per epxiraiotn since we are adding one onto the list
        if (
            oTokensByExpiry[underlying][expiry].length >=
            seriesPerExpirationLimit
        ) {
            revert CustomErrors.SeriesPerExpiryLimitExceeded();
        }

        {
            // Validate strike has been added by the owner - get the strike range info and ensure it is within params
            TokenStrikeRange memory existingRange = allowedStrikeRanges[
                underlying
            ];
            uint256 minStrike = (underlyingPrice * existingRange.minPercent) /
                100;
            if (strikePrice < minStrike) {
                revert CustomErrors.StrikeTooLow(minStrike);
            }

            uint256 maxStrike = (underlyingPrice * existingRange.maxPercent) /
                100;
            if (strikePrice > maxStrike) {
                revert CustomErrors.StrikeTooHigh(maxStrike);
            }

            if (strikePrice % existingRange.increment != 0) {
                revert CustomErrors.StrikeInvalidIncrement();
            }
        }

        // Finally add to our active oTokens in our pool
        activeOTokens.add(oToken);
        oTokensByExpiry[underlying][expiry].push(oToken);
    }

    /*******************
    Hedging
    ********************/

    /// @notice Set hedger address for an underlying
    function setHedger(address underlying, address hedger) external onlyOwner {
        // remove approval from the old hedger
        if (address(hedgers[underlying]) != address(0)) {
            collateralToken.approve(address(hedgers[underlying]), 0);
        }

        hedgers[underlying] = hedger;
        collateralToken.approve(hedger, type(uint256).max);

        emit HedgerSet(underlying, hedger);
    }

    /// @notice Keeper can update margin for all vaults and the hedge
    function syncMargin(
        address[] calldata underlying
    ) external returns (uint256) {
        onlyKeeper();

        uint256 collateralMoved;

        // move collateral
        for (uint256 i = 0; i < underlying.length; i++) {
            uint256 vaultId = ITradeExecutor(tradeExecutor).marginVaults(
                address(this),
                underlyingTokens.at(i),
                0
            );
            // withdraw excess collateral from vaults
            collateralMoved += Math.abs(
                _syncVaultMargin(vaultId, OpynLib.MARGIN_UPDATE_TYPE.EXCESS)
            );

            collateralMoved += Math.abs(IHedger(hedgers[underlying[i]]).sync());

            // deposit shortfall into vaults
            collateralMoved += Math.abs(
                _syncVaultMargin(vaultId, OpynLib.MARGIN_UPDATE_TYPE.SHORTFALL)
            );
        }

        processWithdrawals();

        return collateralMoved;
    }

    /// @notice Withdraw excess or deposit shortfall margin into a vault
    function _syncVaultMargin(
        uint256 vaultId,
        OpynLib.MARGIN_UPDATE_TYPE updateType
    ) internal returns (int256 collateralChange) {
        // if already updated in this block, skip
        if (lastMarginUpdate[vaultId] == block.timestamp) return 0;

        collateralChange = OpynLib.syncVaultMargin(
            controller,
            calculator,
            address(collateralToken),
            vaultId,
            updateType,
            getCollateralBalance(),
            MARGIN_HIGH_RANGE_PERCENT,
            MARGIN_LOW_RANGE_PERCENT
        );

        if (collateralChange != 0) {
            lastMarginUpdate[vaultId] = block.timestamp;
        }

        return collateralChange;
    }

    /*******************
    Pool config
    ********************/

    /// @notice This function allows the owner address to update allowed strikes for the auto series creation feature
    /// @param _underlying underlying token address
    /// @param _enabled whether the underlying is enabled or not
    /// @param _minPercent minimum strike allowed as percent of underlying price
    /// @param _maxPercent maximum strike allowed as percent of underlying price
    /// @param _increment price increment allowed - e.g. if increment is 10, then 100 would be valid and 101 would not be (strike % increment == 0)
    /// @param _spotShockPercentCalls spot shock for cash buffer for calls
    /// @param _spotShockPercentPuts spot shock for cash buffer for puts
    /// @dev Only the owner address should be allowed to call this
    function configUnderlying(
        address _underlying,
        bool _enabled,
        uint256 _minPercent,
        uint256 _maxPercent,
        uint256 _increment,
        uint256 _spotShockPercentCalls,
        uint256 _spotShockPercentPuts
    ) public onlyOwner {
        require(_underlying != address(0));

        if (_enabled) {
            // enable underlying
            if (!underlyingTokens.contains(_underlying)) {
                underlyingTokens.add(_underlying);
                // create margin vault
                ITradeExecutor(tradeExecutor).openMarginVault(
                    _underlying,
                    0,
                    address(0)
                );
            }

            if (_minPercent > _maxPercent)
                revert CustomErrors.InvalidArgument();
            if (_increment == 0) revert CustomErrors.InvalidArgument();

            allowedStrikeRanges[_underlying] = TokenStrikeRange(
                _minPercent,
                _maxPercent,
                _increment
            );

            spotShockPercent[_underlying][false] = _spotShockPercentCalls;
            spotShockPercent[_underlying][true] = _spotShockPercentPuts;
        } else {
            // disable underlying
            underlyingTokens.remove(_underlying);
        }

        emit UnderlyingConfigured(
            _underlying,
            _enabled,
            _minPercent,
            _maxPercent,
            _increment
        );
    }

    function getAllUnderlyings() external view returns (address[] memory) {
        address[] memory underlyings = new address[](underlyingTokens.length());
        for (uint256 i = 0; i < underlyingTokens.length(); i++) {
            underlyings[i] = underlyingTokens.at(i);
        }
        return underlyings;
    }

    /// @notice Configure expirations allowed in the pool
    /// @param numMonths include last Friday of up to _numMonths in the future (0 - no montlys, 1 includes end of the current months)
    /// @param numQuarters include last Friday of up to _numQuarters in the future (0 - no quarterlys, 1 includes the next quarter)
    function setAllowedExpirations(
        address underlying,
        uint8 numMonths,
        uint8 numQuarters,
        bool allowDailyExpiration
    ) external onlyOwner {
        if (numMonths > 12 || numQuarters > 6) {
            revert CustomErrors.InvalidArgument();
        }

        ExpiryConfig storage exp = allowedExpirations[underlying];
        exp.numMonths = numMonths;
        exp.numQuarters = numQuarters;
        exp.allowDailyExpiration = allowDailyExpiration;

        emit AllowedExpirationsSetV2(
            underlying,
            numMonths,
            numQuarters,
            allowDailyExpiration
        );
    }

    /// @notice Allow/disallow an address to perform keeper tasks
    function setKeeper(
        address keeperAddress,
        bool isPermitted
    ) external onlyOwner {
        keepers[keeperAddress] = isPermitted;
    }

    /// @notice Add/remove an address from allowed quote providers
    function setQuoteProvider(
        address quoteProviderAddress,
        bool isPermitted
    ) external onlyOwner {
        quoteProviders[quoteProviderAddress] = isPermitted;
    }

    /// @notice Refresh frequently used addresses
    function refreshConfiguration() external onlyOwner {
        _refreshConfigInternal();
    }

    /// @notice Store frequently used addresses
    function _refreshConfigInternal() internal {
        // remove old approvals
        if (marginPool != address(0)) {
            collateralToken.approve(marginPool, 0);
        }
        if (feeCollector != address(0)) {
            collateralToken.approve(feeCollector, 0);
        }
        if (tradeExecutor != address(0)) {
            collateralToken.approve(tradeExecutor, 0);
            IController(controller).setOperator(tradeExecutor, false);
        }

        controller = addressBook.getController();
        calculator = addressBook.getMarginCalculator();
        oracle = addressBook.getOracle();
        marginPool = addressBook.getMarginPool();
        oTokenFactory = addressBook.getOtokenFactory();
        orderUtil = addressBook.getOrderUtil();
        lpManager = addressBook.getLpManager();
        feeCollector = addressBook.getFeeCollector();
        tradeExecutor = addressBook.getTradeExecutor();
        IController(controller).setOperator(tradeExecutor, true);

        // give approvals
        collateralToken.approve(marginPool, type(uint256).max);
        collateralToken.approve(feeCollector, type(uint256).max);
        collateralToken.approve(tradeExecutor, type(uint256).max);
    }

    /// @notice Set access key token requirement
    function setLock(bool _isLocked) external onlyOwner {
        isLocked = _isLocked;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "../interfaces/IHedgedPool.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import "../interfaces/IHedger.sol";

/// This contract stores all new local variables for the MinterAmm.sol contract.
/// This allows us to upgrade the contract and add new variables without worrying about
///   memory layout when we add new variables.
/// Each time a new version is created with new variables, the version "V1, V2, etc" should
//    be bumped and inherit from the previous version, and the MinterAmm should inherit from
///   the newest version.
abstract contract HedgedPoolStorageV1 is IHedgedPool {
    uint256 constant MARGIN_LOW_RANGE_PERCENT = 10;
    uint256 constant MARGIN_HIGH_RANGE_PERCENT = 15;
    uint256 constant CASH_BUFFER_LEVERAGE = 10;

    /// @notice The ERC20 tokens used by all the Series associated with this AMM
    IERC20 public strikeToken;
    IERC20 public collateralToken;

    // @notice Allowed underlying assets for the pool
    EnumerableSet.AddressSet underlyingTokens;

    IAddressBook public addressBook;

    /// @notice Hedgers for each underlying
    mapping(address => address) public hedgers;

    /// @dev the number of decimals for this ERC20's human readable numeric
    uint8 internal numDecimals;

    /// @notice current withdrawal round end timestamp
    uint256 public withdrawalRoundEnd;

    /// @notice current deposit round end timestamp
    uint256 public depositRoundEnd;

    /// @notice last settled expiration timestamp for each underlying
    uint256 public lastSettledExpiry;

    /// @notice last recorded pool share price
    uint256 public pricePerShareCached;

    /// @notice underlying => expiry => oToken
    mapping(address => mapping(uint256 => address[])) oTokensByExpiry;
    // underlying => MarginVault id
    mapping(address => uint256) public marginVaults;

    /// @notice vault id => block number
    mapping(uint256 => uint256) lastMarginUpdate;

    /// @notice stores all non-expired oTokens that the pool has ever traded
    EnumerableSet.AddressSet activeOTokens;

    /// @dev For a token, store the range for a strike price for the auto series creation feature
    struct TokenStrikeRange {
        uint256 minPercent;
        uint256 maxPercent;
        uint256 increment;
    }

    /// @dev Strike ranges for each underlying
    mapping(address => TokenStrikeRange) public allowedStrikeRanges;

    /// @dev Max series for each expiration date
    uint256 public seriesPerExpirationLimit;

    /// @dev Config for dynamic expirations
    struct ExpiryConfig {
        uint8 numMonths;
        uint8 numQuarters;
        bool allowDailyExpiration;
    }

    /// @dev Expirations allowed for trading in the pool (underlying => config)
    mapping(address => ExpiryConfig) public allowedExpirations;

    /// @dev List of permitted keeper addresses
    mapping(address => bool) public keepers;

    /// @dev List of permitted quote providers
    mapping(address => bool) public quoteProviders;

    /// @dev Frequently used contracts
    address internal controller;
    address internal calculator;
    address internal oTokenFactory;
    address internal oracle;
    address internal orderUtil;
    address internal marginPool;
    address internal lpManager;
    address internal feeCollector;
    address internal tradeExecutor;

    bool public isLocked;
    uint256 constant accessKeyId = 1;

    /// @dev Notional exposure of the pool (incl possible liquidations) (underlying => isPut => amount)
    mapping(address => mapping(bool => int256)) public notionalExposure;

    /// @dev Spot shock for each underlying (underlying => isPut => percent)
    mapping(address => mapping(bool => uint256)) public spotShockPercent;
}

// Next version example:
/// contract HedgedPoolStorageV1 is HedgedPoolStorageV2 {
///   address public myAddress;
/// }
/// Then... HedgedPool should inherit from HedgedPoolStorageV1

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVault, IPositionRouter, IRouter, IPositionRouterCallbackReceiver} from "../../interfaces/IGmx1.sol";
import "../../interfaces/IHedgedPool.sol";
import "../../interfaces/IHedger.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title GMX v1 protocol perpetual hedger
/// @notice Hedges pool delta by trading perpetual contracts on GMX v1

contract Gmx1Hedger is
    IHedger,
    OwnableUpgradeable,
    IPositionRouterCallbackReceiver
{
    using SafeERC20 for IERC20;

    event HedgeUpdated(int256 oldDelta, int256 newDelta);

    event Synced(int256 collateralDiff);

    // Gmx uses 30 decimals precision
    uint256 private constant GMX_DECIMALS = 30;

    uint256 private constant SIREN_DECIMALS = 8;

    uint256 private constant BASIS_POINT = 10000;

    uint256 public maxSwapSlippageBP;

    // Siren HedgedPool that will be our account for this contract
    address public hedgedPool;

    /// @dev approve target for GMX position router
    IRouter public router;

    //ExchangeRouter what we use to execute orders
    IPositionRouter public positionRouter;

    IVault public vault;

    struct MarketInfo {
        address indexToken;
        address longToken;
        address shortToken;
    }

    MarketInfo public marketInfo;

    uint256 public targetLeverage;

    uint256 public maxLeverage;

    bytes32 public referralCode;

    IERC20 collateralToken;

    uint256 public collateralDecimals;

    int256 private deltaCached;

    mapping(bytes32 => bool) public pendingOrders;

    uint256 public pendingOrdersCount;

    struct Position {
        uint256 size;
        uint256 sizeInTokens;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        int256 unrealizedPnl;
        uint256 lastIncreasedTime;
        bool isLong;
    }

    event GmxOrderCanceled(bytes32 key);

    event GmxOrderExecuted(bytes32 key);

    event GmxIncreaseOrderCreated(bytes32 key, bool isLong);

    event GmxDecreaseOrderCreated(bytes32 key, bool isLong);

    event GmxDepositOrderCreated(bytes32 key, bool isLong);

    event GmxWithdrawlOrderCreated(bytes32 key, bool isLong);

    event HedgerInitalized(
        address hedger,
        address indexToken,
        address longToken,
        address shortToken
    );

    modifier onlyAuthorized() {
        require(
            msg.sender == hedgedPool ||
                IHedgedPool(hedgedPool).keepers(msg.sender) ||
                msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    modifier noPendingOrders() {
        require(pendingOrdersCount == 0, "Orders pending");
        _;
    }

    //Take the gmx price and compare the min and max
    // work on script to get the prices
    // _targetLeverage = 5
    // _maxLeverage = 10
    // maxSwapSlippageBP = 100
    function __Gmx1Hedger_init(
        address _hedgedPool,
        address _positionRouter,
        uint256 _targetLeverage,
        uint256 _maxLeverage,
        uint256 _maxSwapSlippageBP,
        bytes32 _referralCode,
        address _indexToken,
        address _longToken,
        address _shortToken
    ) external initializer {
        _updateConfig(
            _positionRouter,
            _targetLeverage,
            _maxLeverage,
            _maxSwapSlippageBP,
            _referralCode
        );

        hedgedPool = _hedgedPool;
        collateralToken = IHedgedPool(hedgedPool).collateralToken();
        collateralDecimals = IERC20MetadataUpgradeable(address(collateralToken))
            .decimals();

        marketInfo = MarketInfo(_indexToken, _longToken, _shortToken);

        emit HedgerInitalized(
            address(this),
            marketInfo.indexToken,
            marketInfo.longToken,
            marketInfo.shortToken
        );

        __Ownable_init();
    }

    function hedgerType() external pure returns (string memory) {
        return "GMX1";
    }

    /// @notice Update hedger configuration
    function updateConfig(
        address _positionRouter,
        uint256 _targetLeverage,
        uint256 _maxLeverage,
        uint256 _maxSwapSlippageBP,
        bytes32 _referralCode
    ) external onlyOwner {
        _updateConfig(
            _positionRouter,
            _targetLeverage,
            _maxLeverage,
            _maxSwapSlippageBP,
            _referralCode
        );
    }

    receive() external payable {}

    function _updateConfig(
        address _positionRouter,
        uint256 _targetLeverage,
        uint256 _maxLeverage,
        uint256 _maxSwapSlippageBP,
        bytes32 _referralCode
    ) private {
        targetLeverage = _targetLeverage;
        maxLeverage = _maxLeverage;
        maxSwapSlippageBP = _maxSwapSlippageBP;
        referralCode = _referralCode;
        positionRouter = IPositionRouter(_positionRouter);
        vault = IVault(positionRouter.vault());
        router = IRouter(vault.router());

        router.approvePlugin(address(positionRouter));
    }

    function gmxPositionCallback(
        bytes32 key,
        bool isExecuted,
        bool /* isIncrease */
    ) external {
        require(
            address(msg.sender) == address(positionRouter),
            "!positionRouter"
        );
        require(pendingOrders[key] == true, "!order key");
        pendingOrders[key] = false;
        pendingOrdersCount = pendingOrdersCount - 1;

        if (isExecuted) {
            // TODO: Maybe here and on cancle order we want to get information form the order
            emit GmxOrderExecuted(key);
        } else {
            collateralToken.safeTransfer(
                hedgedPool,
                collateralToken.balanceOf(address(this))
            );
            emit GmxOrderCanceled(key);
        }

        if (pendingOrdersCount == 0) {
            _syncDelta();
        }
    }

    /// @notice Adjust perpetual position in order to hedge given delta exposure
    /// @param targetDelta Target delta of the hedge (1e8)
    /// @param indexTokenPrice minPrice from Gmx oracle multiplied by oracle decimals
    /// @return deltaDiff difference between the new delta and the old delta
    function hedge(
        int256 targetDelta,
        uint256 indexTokenPrice
    ) external payable onlyAuthorized returns (int256 deltaDiff) {
        _syncDelta();

        deltaDiff = targetDelta - deltaCached;

        // calculate changes in long and short
        uint currentLong;
        uint currentShort;
        uint targetLong;
        uint targetShort;

        if (targetDelta >= 0) {
            targetLong = uint256(targetDelta);

            // need long hedge
            if (deltaCached >= 0) {
                currentLong = uint256(deltaCached);
            } else {
                currentShort = uint256(-deltaCached);
            }
        } else if (targetDelta < 0) {
            targetShort = uint256(-targetDelta);

            // need short hedge
            if (deltaCached <= 0) {
                currentShort = uint256(-deltaCached);
            } else {
                currentLong = uint256(deltaCached);
            }
        }

        _changePosition(
            currentLong,
            targetLong,
            currentShort,
            targetShort,
            indexTokenPrice
        );

        emit HedgeUpdated(deltaCached, targetDelta);

        deltaCached = targetDelta;

        return deltaDiff;
    }

    function sync() external onlyAuthorized returns (int256 collateralDiff) {
        collateralDiff = _sync();
        return collateralDiff;
    }

    function getDelta() external view returns (int256) {
        return deltaCached;
    }

    function getCollateralValue() external view returns (uint256) {
        uint256 collateralValue;

        (
            Position memory longPosition,
            Position memory shortPosition
        ) = _getPositions();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position memory position = isLong ? longPosition : shortPosition;

            // TODO: handle edge case where position value is below zero
            collateralValue += uint256(
                int256(position.collateral) + position.unrealizedPnl
            );
        }

        return collateralValue;
    }

    /// @notice Get required collateral
    /// @return collateral shortfall (positive) or excess (negative)
    function getRequiredCollateral() external view returns (int256) {
        int256 requiredCollateral;

        (
            Position memory longPosition,
            Position memory shortPosition
        ) = _getPositions();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position memory position = isLong ? longPosition : shortPosition;

            uint256 price = isLong
                ? vault.getMinPrice(marketInfo.indexToken)
                : vault.getMaxPrice(marketInfo.indexToken);

            int256 marginCurrent = int256(position.collateral) +
                position.unrealizedPnl;
            uint256 marginRequired = _getMarginRequired(
                position.sizeInTokens,
                price
            );

            requiredCollateral += int256(marginRequired) - marginCurrent;
        }

        return requiredCollateral;
    }

    /// @notice Withdraw excess collateral or deposit more
    /// @return collateralDiff deposit (positive) or withdrawal (negative) amount
    function _sync() internal returns (int collateralDiff) {
        // sync delta
        _syncDelta();

        (
            Position memory longPosition,
            Position memory shortPosition
        ) = _getPositions();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            uint256 indexTokenPrice = isLong
                ? vault.getMinPrice(marketInfo.indexToken)
                : vault.getMaxPrice(marketInfo.indexToken);

            Position memory position = isLong ? longPosition : shortPosition;
            int256 marginCurrent;

            marginCurrent =
                int256(position.collateral) +
                position.unrealizedPnl;

            uint256 marginRequired = _getMarginRequired(
                position.sizeInTokens,
                indexTokenPrice
            );

            if (int256(marginRequired) > marginCurrent) {
                // deposit
                uint256 depositAmount = uint256(
                    int256(marginRequired) - marginCurrent
                );
                _depositCollateral(position, isLong, depositAmount);
                collateralDiff += int256(depositAmount);
            } else if (int256(marginRequired) < marginCurrent) {
                // withdraw
                uint256 withdrawAmount = uint256(marginCurrent) -
                    marginRequired;
                _withdrawCollateral(position, isLong, withdrawAmount);
                collateralDiff -= int256(withdrawAmount);
            }
        }

        emit Synced(collateralDiff);

        return collateralDiff;
    }

    /// @notice sync cached delta value
    function _syncDelta() internal noPendingOrders {
        int256 totalSizeInTokens;

        (
            Position memory longPosition,
            Position memory shortPosition
        ) = _getPositions();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position memory position = isLong ? longPosition : shortPosition;

            require(
                position.sizeInTokens == 0 || totalSizeInTokens == 0,
                "two non-zero positions"
            );

            totalSizeInTokens += isLong
                ? int256(position.sizeInTokens)
                : -int256(position.sizeInTokens);
        }

        deltaCached = totalSizeInTokens;
    }

    function _getPositions()
        internal
        view
        returns (Position memory longPosition, Position memory shortPosition)
    {
        for (uint256 i; i < 2; i++) {
            bool isLong = i == 0;

            (
                uint size,
                uint collateral,
                uint averagePrice,
                uint entryFundingRate,
                ,
                ,
                ,
                uint lastIncreasedTime
            ) = vault.getPosition(
                    address(this),
                    isLong
                        ? address(marketInfo.longToken)
                        : address(marketInfo.shortToken),
                    address(marketInfo.indexToken),
                    isLong
                );

            uint256 sizeInTokens = 0;
            int unrealizedPnl = 0;
            if (averagePrice > 0) {
                sizeInTokens = size / (averagePrice / (10 ** SIREN_DECIMALS));

                (bool hasUnrealizedProfit, uint absUnrealizedPnl) = vault
                    .getDelta(
                        address(marketInfo.indexToken),
                        size,
                        averagePrice,
                        isLong,
                        lastIncreasedTime
                    );

                if (hasUnrealizedProfit) {
                    unrealizedPnl = int256(absUnrealizedPnl);
                } else {
                    unrealizedPnl = -int256(absUnrealizedPnl);
                }
            }

            Position memory position = Position({
                size: size,
                sizeInTokens: sizeInTokens,
                collateral: collateral /
                    10 ** (GMX_DECIMALS - collateralDecimals),
                averagePrice: averagePrice,
                entryFundingRate: entryFundingRate,
                unrealizedPnl: unrealizedPnl /
                    int256(10 ** (GMX_DECIMALS - collateralDecimals)),
                lastIncreasedTime: lastIncreasedTime,
                isLong: isLong
            });

            if (isLong) {
                longPosition = position;
            } else {
                shortPosition = position;
            }
        }

        return (longPosition, shortPosition);
    }

    //Internal Helper Functions

    struct ChangePositionVars {
        Position longPosition;
        Position shortPosition;
    }

    function _changePosition(
        uint256 currentLong,
        uint256 targetLong,
        uint256 currentShort,
        uint256 targetShort,
        uint256 spot
    ) internal {
        ChangePositionVars memory vars;

        (vars.longPosition, vars.shortPosition) = _getPositions();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            uint256 currentPos = isLong ? currentLong : currentShort;
            uint256 targetPos = isLong ? targetLong : targetShort;

            if (targetPos == currentPos) continue;

            Position memory position = isLong
                ? vars.longPosition
                : vars.shortPosition;
            int256 marginCurrent;

            marginCurrent =
                int256(position.collateral) +
                position.unrealizedPnl;

            uint256 marginRequired = _getMarginRequired(targetPos, spot);

            if (targetPos > currentPos) {
                // increase position

                //First get the sizeInTokens of the position
                uint256 initialCollateralDelta;
                if (marginRequired > uint256(marginCurrent)) {
                    initialCollateralDelta = uint256(
                        marginRequired - uint256(marginCurrent)
                    );
                }

                uint256 sizeDeltaUsd = ((targetPos - currentPos) * spot) /
                    (10 ** SIREN_DECIMALS);

                _gmxPositionIncrease(
                    position,
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    spot
                );
            } else if (targetPos < currentPos) {
                // decrease position
                uint256 initialCollateralDelta;
                if (marginRequired < uint256(marginCurrent)) {
                    initialCollateralDelta =
                        uint256(marginCurrent) -
                        marginRequired;
                }

                uint256 sizeDeltaUsd = (position.size *
                    (currentPos - targetPos)) / currentPos;

                {
                    _gmxPositionDecrease(
                        position,
                        isLong,
                        sizeDeltaUsd,
                        initialCollateralDelta,
                        spot
                    );
                }
            }
        }
    }

    /// @notice Deposit collateral to a product
    function _depositCollateral(
        Position memory position,
        bool isLong,
        uint256 amount
    ) internal {
        if (amount == 0) return;

        uint256 poolBalance = IHedgedPool(hedgedPool).getCollateralBalance();
        if (amount > poolBalance) {
            // pool doesn't have enough collateral, move all we can
            amount = poolBalance;
        }

        uint256 spot = isLong
            ? vault.getMaxPrice(marketInfo.indexToken)
            : vault.getMinPrice(marketInfo.indexToken);

        _gmxPositionIncrease(position, isLong, 0, amount, spot);
    }

    /// @notice Withdraw collateral from a product
    /// @dev It withdraws directly to the hedged pool
    function _withdrawCollateral(
        Position memory position,
        bool isLong,
        uint256 amount
    ) internal {
        if (amount == 0) return;

        uint256 spot = isLong
            ? vault.getMinPrice(marketInfo.indexToken)
            : vault.getMaxPrice(marketInfo.indexToken);

        _gmxPositionDecrease(position, isLong, 0, amount, spot);
    }

    /**
     * @dev create increase position order on GMX router
     */
    function _gmxPositionIncrease(
        Position memory currentPos,
        bool isLong,
        uint sizeDelta,
        uint collateralDelta,
        uint spot
    ) internal {
        // add margin fee
        // when we increase position, fee always got deducted from collateral
        collateralDelta +=
            _getPositionFee(
                isLong ? marketInfo.longToken : marketInfo.shortToken,
                currentPos.size,
                sizeDelta,
                currentPos.entryFundingRate
            ) /
            10 ** (GMX_DECIMALS - collateralDecimals);

        {
            // avoid stack too deep
            uint swapFeeBP = _getSwapFeeBP(
                isLong,
                true,
                collateralDelta * 10 ** (18 - collateralDecimals)
            );
            collateralDelta =
                (collateralDelta * (BASIS_POINT + swapFeeBP)) /
                BASIS_POINT;
        }

        address[] memory path;
        uint acceptableSpot;

        if (isLong) {
            path = new address[](2);
            path[0] = address(collateralToken);
            path[1] = marketInfo.longToken;
            acceptableSpot =
                (spot * (BASIS_POINT + maxSwapSlippageBP)) /
                BASIS_POINT;
        } else {
            if (marketInfo.shortToken == address(collateralToken)) {
                path = new address[](1);
                path[0] = marketInfo.shortToken;
            } else {
                path = new address[](2);
                path[0] = address(collateralToken);
                path[1] = marketInfo.shortToken;
            }
            acceptableSpot =
                (spot * (BASIS_POINT - maxSwapSlippageBP)) /
                BASIS_POINT;
        }

        // if the trade ends up with collateral > size, adjust collateral.
        // gmx restrict position to have size >= collateral, so we cap the collateral to be same as size.
        if (
            currentPos.collateral + collateralDelta >
            currentPos.size + sizeDelta
        ) {
            collateralDelta =
                (currentPos.size + sizeDelta) -
                currentPos.collateral;
        }

        collateralToken.safeTransferFrom(
            hedgedPool,
            address(this),
            collateralDelta
        );

        // TODO: enable maxLeverage check
        // {
        //     // prevent stack too deep
        //     uint finalSize = currentPos.size + sizeDelta;
        //     uint finalCollateral = currentPos.collateral + collateralDelta;
        //     require(finalSize / finalCollateral <= maxLeverage, "!maxLeverage");
        // }

        IERC20(collateralToken).approve(address(router), collateralDelta);

        uint executionFee = _getExecutionFee();
        bytes32 key = positionRouter.createIncreasePosition{
            value: executionFee
        }(
            path,
            marketInfo.indexToken, // index token
            collateralDelta, // amount in via router is in the native currency decimals
            0, // min out
            sizeDelta,
            isLong,
            acceptableSpot,
            executionFee,
            referralCode,
            address(this)
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        // check if this is strickly a deposit
        if (sizeDelta == 0) {
            emit GmxDepositOrderCreated(key, isLong);
        } else {
            emit GmxIncreaseOrderCreated(key, isLong);
        }
    }

    /**
     * @dev create increase position order on GMX router
     * @param sizeDelta is the change in current delta required to get to the desired hedge. in USD term
     */
    function _gmxPositionDecrease(
        Position memory currentPos,
        bool isLong,
        uint sizeDelta,
        uint collateralDelta,
        uint spot
    ) internal {
        address[] memory path;
        uint acceptableSpot;

        bool isClose = currentPos.size == sizeDelta;

        if (isLong) {
            path = new address[](2);
            path[0] = marketInfo.longToken;
            path[1] = address(collateralToken);
            acceptableSpot =
                (spot * (BASIS_POINT - maxSwapSlippageBP)) /
                BASIS_POINT;
        } else {
            if (marketInfo.shortToken == address(collateralToken)) {
                path = new address[](1);
                path[0] = marketInfo.shortToken;
            } else {
                path = new address[](2);
                path[0] = marketInfo.shortToken;
                path[1] = address(collateralToken);
            }
            acceptableSpot =
                (spot * (BASIS_POINT + maxSwapSlippageBP)) /
                BASIS_POINT;
        }

        if (collateralDelta > currentPos.collateral) {
            collateralDelta = currentPos.collateral;
        }

        uint executionFee = _getExecutionFee();
        bytes32 key = positionRouter.createDecreasePosition{
            value: executionFee
        }(
            path,
            marketInfo.longToken,
            // CollateralDelta for decreases is in GMX_DECIMALS rather than asset decimals like for opens...
            // In the case of closes, 0 must be passed in
            isClose
                ? 0
                : collateralDelta * (10 ** (GMX_DECIMALS - collateralDecimals)),
            sizeDelta,
            isLong,
            address(hedgedPool),
            acceptableSpot,
            0,
            executionFee,
            false,
            address(this)
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        if (sizeDelta == 0) {
            emit GmxWithdrawlOrderCreated(key, isLong);
        } else {
            emit GmxDecreaseOrderCreated(key, isLong);
        }
    }

    function _getSwapFeeBP(
        bool isLong,
        bool isIncrease,
        uint amountIn18
    ) internal view returns (uint feeBP) {
        address inToken;
        address outToken;

        if (isLong) {
            inToken = isIncrease
                ? address(collateralToken)
                : marketInfo.longToken;
            outToken = isIncrease
                ? marketInfo.longToken
                : address(collateralToken);
        } else {
            inToken = isIncrease
                ? address(collateralToken)
                : marketInfo.shortToken;
            outToken = isIncrease
                ? marketInfo.shortToken
                : address(collateralToken);
        }
        if (inToken == outToken) return 0;

        uint256 priceIn = vault.getMinPrice(inToken);

        // adjust usdgAmounts by the same usdgAmount as debt is shifted between the assets
        uint256 usdgAmount = (amountIn18 * priceIn) / (10 ** GMX_DECIMALS);

        uint256 baseBps = vault.swapFeeBasisPoints();
        uint256 taxBps = vault.taxBasisPoints();
        uint256 feesBasisPoints0 = vault.getFeeBasisPoints(
            inToken,
            usdgAmount,
            baseBps,
            taxBps,
            true
        );
        uint256 feesBasisPoints1 = vault.getFeeBasisPoints(
            outToken,
            usdgAmount,
            baseBps,
            taxBps,
            false
        );
        // use the higher of the two fee basis points
        return
            feesBasisPoints0 > feesBasisPoints1
                ? feesBasisPoints0
                : feesBasisPoints1;
    }

    function _getPositionFee(
        address positionCollateralToken,
        uint size,
        uint sizeDelta,
        uint entryFundingRate
    ) internal view returns (uint) {
        uint fundingFee = vault.getFundingFee(
            positionCollateralToken,
            size,
            entryFundingRate
        );
        return fundingFee + vault.getPositionFee(sizeDelta);
    }

    function _getMarginRequired(
        uint256 size, // in SIREN_DECIMALS
        uint256 price // in GMX_DECIMALS
    ) internal view returns (uint256) {
        return
            (size * price) /
            targetLeverage /
            (10 ** (GMX_DECIMALS + SIREN_DECIMALS - collateralDecimals));
    }

    /**
     * @dev returns the execution fee plus the cost of the gas callback
     */
    function _getExecutionFee() internal view returns (uint) {
        return positionRouter.minExecutionFee();
    }

    function withdrawEth(address to, uint256 amount) public onlyOwner {
        payable(to).transfer(amount);
    }

    function resetPendingOrder() public onlyOwner {
        pendingOrdersCount = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOrderHandler, MarketUtils, Price, Market, IReferralStorage, IMarketToken, ISwapHandler, IOrderVault, IGmxOracle, IEventEmitter, BaseOrderUtils, PositionUtils, IGmxUtils, Order, IOrderUtils, IDataStore, IReader, IExchangeRouter, Position, EventUtils, IOrderCallbackReceiver} from "../../interfaces/IGmx2.sol";
import "../../interfaces/IHedgedPool.sol";
import "../../interfaces/IHedger.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title GMX v2 protocol perpetual hedger
/// @notice Hedges pool delta by trading perpetual contracts on GMX v2

contract Gmx2Hedger is IHedger, IOrderCallbackReceiver, OwnableUpgradeable {
    using SafeERC20 for IERC20;
    using Price for Price.Props;
    using Position for Position.Props;

    event HedgeUpdated(int256 oldDelta, int256 newDelta);

    event Synced(int256 collateralDiff);

    // Gmx uses 30 decimals precision
    uint256 private constant GMX_DECIMALS = 30;

    uint256 private constant SIREN_DECIMALS = 8;

    uint256 private constant ORDER_GAS_LIMIT = 50e6;

    uint256 private constant ACCEPTABLE_PRICE_THRESHOLD = 10;

    // Siren HedgedPool that will be our account for this contract
    address public hedgedPool;

    //ExchangeRouter what we use to execute orders
    address public exchangeRouter;

    address public orderVault;

    address public dataStore;

    address public reader;

    //Market that our long token is based on ie weth, wbtc, ect
    address public market;

    address public gmxOralce;

    uint256 public leverage;

    IERC20 collateralToken;

    uint256 public collateralDecimals;

    address public gmxUtils;

    uint256 public underlyingDecimals;

    int256 private deltaCached;

    Market.Props public marketProps;

    mapping(bytes32 => bool) public pendingOrders;

    uint256 public pendingOrdersCount;

    BaseOrderUtils.ExecuteOrderParamsContracts executOrderParamContracts;

    bytes32 public referralCode;

    event GmxOrderCanceled(bytes32 key);

    event GmxOrderExecuted(bytes32 key);

    event GmxIncreaseOrderCreated(bytes32 key, bool isLong);

    event GmxDecreaseOrderCreated(bytes32 key, bool isLong);

    event GmxDepositOrderCreated(bytes32 key, bool isLong);

    event GmxWithdrawlOrderCreated(bytes32 key, bool isLong);

    event HedgerInitalized(
        address hedger,
        address indexToken,
        address longToken,
        address shortToken
    );

    modifier onlyAuthorized() {
        require(
            msg.sender == hedgedPool ||
                IHedgedPool(hedgedPool).keepers(msg.sender) ||
                msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    modifier noPendingOrders() {
        require(pendingOrdersCount == 0, "Orders pending");
        _;
    }

    //Take the gmx price and compare the min and max
    // work on script to get the prices
    function __Gmx2Hedger_init(
        address _hedgedPool,
        address _exchangeRouter,
        address _reader,
        address _market,
        address _gmxUtils,
        uint256 _leverage,
        bytes32 _referralCode
    ) external initializer {
        market = _market;
        _updateConfig(
            _exchangeRouter,
            _reader,
            _gmxUtils,
            _leverage,
            _referralCode
        );

        hedgedPool = _hedgedPool;
        collateralToken = IHedgedPool(hedgedPool).collateralToken();
        collateralDecimals = IERC20MetadataUpgradeable(address(collateralToken))
            .decimals();

        emit HedgerInitalized(
            address(this),
            marketProps.indexToken,
            marketProps.longToken,
            marketProps.shortToken
        );

        __Ownable_init();
    }

    function hedgerType() external pure returns (string memory) {
        return "GMX2";
    }

    /// @notice Update hedger configuration
    function updateConfig(
        address _exchangeRouter,
        address _reader,
        address _gmxUtils,
        uint256 _leverage,
        bytes32 _referralCode
    ) external onlyOwner {
        _updateConfig(
            _exchangeRouter,
            _reader,
            _gmxUtils,
            _leverage,
            _referralCode
        );
    }

    receive() external payable {}

    function _updateConfig(
        address _exchangeRouter,
        address _reader,
        address _gmxUtils,
        uint256 _leverage,
        bytes32 _referralCode
    ) private {
        leverage = _leverage;
        reader = _reader;
        exchangeRouter = _exchangeRouter;
        IOrderHandler orderHandler = IOrderHandler(
            IExchangeRouter(_exchangeRouter).orderHandler()
        );
        dataStore = address(IExchangeRouter(exchangeRouter).dataStore());

        (
            address marketToken,
            address indexToken,
            address longToken,
            address shortToken
        ) = IReader(reader).getMarket(dataStore, market);

        marketProps = Market.Props(
            marketToken,
            indexToken,
            longToken,
            shortToken
        );

        orderVault = address(orderHandler.orderVault());
        gmxOralce = address(orderHandler.oracle());
        ISwapHandler swapHandler = orderHandler.swapHandler();
        IReferralStorage referralStorage = orderHandler.referralStorage();
        gmxUtils = _gmxUtils;

        executOrderParamContracts = BaseOrderUtils.ExecuteOrderParamsContracts(
            IDataStore(dataStore),
            IEventEmitter(IExchangeRouter(exchangeRouter).eventEmitter()),
            IOrderVault(orderVault),
            IGmxOracle(gmxOralce),
            swapHandler,
            referralStorage
        );

        underlyingDecimals = IMarketToken(longToken).decimals();

        referralCode = _referralCode;
    }

    function afterOrderExecution(
        bytes32 key,
        Order.Props memory /* order */,
        EventUtils.EventLogData memory /* eventData */
    ) external {
        require(
            address(msg.sender) ==
                address(IExchangeRouter(exchangeRouter).orderHandler()),
            "!orderHandler"
        );
        require(pendingOrders[key] == true, "!order key");
        pendingOrders[key] = false;
        pendingOrdersCount = pendingOrdersCount - 1;

        if (pendingOrdersCount == 0) {
            _syncDelta();
        }

        //Maybe here and on cancle order we want to get information form the order
        emit GmxOrderExecuted(key);
    }

    function afterOrderCancellation(
        bytes32 key,
        Order.Props memory /* order */,
        EventUtils.EventLogData memory /* eventData */
    ) external {
        require(
            address(msg.sender) ==
                address(IExchangeRouter(exchangeRouter).orderHandler()),
            "!orderHandler"
        );
        require(pendingOrders[key] == true, "!order key");
        pendingOrders[key] = false;
        pendingOrdersCount = pendingOrdersCount - 1;

        collateralToken.safeTransfer(
            hedgedPool,
            collateralToken.balanceOf(address(this))
        );

        if (pendingOrdersCount == 0) {
            _syncDelta();
        }

        emit GmxOrderCanceled(key);
    }

    function afterOrderFrozen(
        bytes32 /* key */,
        Order.Props memory /* order */,
        EventUtils.EventLogData memory /* eventData */
    ) external {
        // We only use market orders which cannot be frozen they will instead be canceled
        // Reference for this in Gmx
        // https://github.com/gmx-io/gmx-synthetics/blob/77a2ff39f1414a105e8589d622bdb09ac3dd97d8/contracts/exchange/OrderHandler.sol#L232
    }

    // /// @notice Set maintenance buffer in percent (200 means 2x maintenance required by product)
    // function setMaintenanceBuffer(
    //     uint256 _maintenanceBuffer
    // ) external onlyOwner {
    //     maintenanceBuffer = _maintenanceBuffer;
    // }

    /// @notice Adjust perpetual position in order to hedge given delta exposure
    /// @param targetDelta Target delta of the hedge (1e8)
    /// @param indexTokenPrice minPrice from Gmx oracle multiplied by oracle decimals
    /// @param longTokenPrice minPrice from Gmx oracle multiplied by oracle decimals
    /// @return deltaDiff difference between the new delta and the old delta
    function hedge(
        int256 targetDelta,
        uint256 indexTokenPrice,
        uint256 longTokenPrice
    ) external payable onlyAuthorized returns (int256 deltaDiff) {
        MarketUtils.MarketPrices memory prices = MarketUtils.MarketPrices(
            Price.Props(indexTokenPrice, indexTokenPrice),
            Price.Props(longTokenPrice, longTokenPrice),
            Price.Props(
                IGmxOracle(gmxOralce).getStablePrice(
                    dataStore,
                    address(collateralToken)
                ),
                IGmxOracle(gmxOralce).getStablePrice(
                    dataStore,
                    address(collateralToken)
                )
            )
        );

        _syncDelta();

        deltaDiff = targetDelta - deltaCached;

        // calculate changes in long and short
        uint currentLong;
        uint currentShort;
        uint targetLong;
        uint targetShort;

        if (targetDelta >= 0) {
            targetLong = uint256(targetDelta);

            // need long hedge
            if (deltaCached >= 0) {
                currentLong = uint256(deltaCached);
            } else {
                currentShort = uint256(-deltaCached);
            }
        } else if (targetDelta < 0) {
            targetShort = uint256(-targetDelta);

            // need short hedge
            if (deltaCached <= 0) {
                currentShort = uint256(-deltaCached);
            } else {
                currentLong = uint256(deltaCached);
            }
        }

        _changePosition(
            currentLong,
            targetLong,
            currentShort,
            targetShort,
            prices
        );

        emit HedgeUpdated(deltaCached, targetDelta);

        deltaCached = targetDelta;

        return deltaDiff;
    }

    function sync() external onlyAuthorized returns (int256 collateralDiff) {
        collateralDiff = _sync();
        return collateralDiff;
    }

    function getDelta() external view returns (int256) {
        return deltaCached;
    }

    function getCollateralValue() external view returns (uint256) {
        MarketUtils.MarketPrices memory prices = _getMarketPrices();
        uint256 collateralValue;

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;

            // TODO: handle edge case where position value is below zero
            collateralValue += uint256(
                int256(position.collateralAmount()) +
                    _getPositinPnlCollateral(position, prices)
            );
        }

        return collateralValue;
    }

    /// @notice Get required collateral
    /// @return collateral shortfall (positive) or excess (negative)
    function getRequiredCollateral() external view returns (int256) {
        int256 requiredCollateral;

        MarketUtils.MarketPrices memory prices = _getMarketPrices();
        uint256 indexTokenPrice = prices.indexTokenPrice.min;

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;

            int256 marginCurrent = int256(position.collateralAmount()) +
                _getPositinPnlCollateral(position, prices);
            uint256 marginRequired = _getMarginRequired(
                position.sizeInTokens(),
                indexTokenPrice
            );

            requiredCollateral += int256(marginRequired) - marginCurrent;
        }

        return requiredCollateral;
    }

    /// @notice Withdraw excess collateral or deposit more
    /// @return collateralDiff deposit (positive) or withdrawal (negative) amount
    function _sync() internal returns (int collateralDiff) {
        // sync delta
        _syncDelta();

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        MarketUtils.MarketPrices memory prices = _getMarketPrices();
        uint256 indexTokenPrice = prices.indexTokenPrice.min;

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;
            int256 marginCurrent;

            marginCurrent =
                int256(position.collateralAmount()) +
                _getPositinPnlCollateral(position, prices);

            uint256 marginRequired = _getMarginRequired(
                position.sizeInTokens(),
                indexTokenPrice
            );

            if (int256(marginRequired) > marginCurrent) {
                uint256 acceptablePrice = _getAcceptablePrice(
                    indexTokenPrice,
                    true,
                    isLong
                );

                // deposit
                uint256 depositAmount = uint256(
                    int256(marginRequired) - marginCurrent
                );
                _depositCollateral(isLong, depositAmount, acceptablePrice);
                collateralDiff += int256(depositAmount);
            } else if (int256(marginRequired) < marginCurrent) {
                uint256 acceptablePrice = _getAcceptablePrice(
                    indexTokenPrice,
                    false,
                    isLong
                );

                // withdraw
                uint256 withdrawAmount = uint256(marginCurrent) -
                    marginRequired;
                _withdrawCollateral(isLong, withdrawAmount, acceptablePrice);
                collateralDiff -= int256(withdrawAmount);
            }
        }

        emit Synced(collateralDiff);

        return collateralDiff;
    }

    /// @notice sync cached delta value
    function _syncDelta() internal noPendingOrders {
        int256 totalSizeInTokens;

        (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        ) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            Position.Props memory position = isLong
                ? longPosition
                : shortPosition;

            uint256 sizeInTokens = position.sizeInTokens();
            require(
                sizeInTokens == 0 || totalSizeInTokens == 0,
                "two non-zero positions"
            );

            totalSizeInTokens += isLong
                ? int256(sizeInTokens)
                : -int256(sizeInTokens);
        }

        deltaCached =
            (totalSizeInTokens * int256(10 ** SIREN_DECIMALS)) /
            int256(10 ** underlyingDecimals);
    }

    function _getPositionInformation()
        internal
        view
        returns (
            Position.Props memory longPosition,
            Position.Props memory shortPosition
        )
    {
        Position.Props[] memory allPositions = IReader(reader)
            .getAccountPositions(IDataStore(dataStore), address(this), 0, 2);
        for (uint256 i; i < allPositions.length; i++) {
            if (allPositions[i].flags.isLong == true) {
                longPosition = allPositions[i];
            } else {
                shortPosition = allPositions[i];
            }
        }

        if (longPosition.addresses.account == address(0)) {
            longPosition.flags.isLong = true;
            longPosition.addresses.account = address(this);
            longPosition.addresses.market = market;
            longPosition.addresses.collateralToken = address(collateralToken);
        }

        if (shortPosition.addresses.account == address(0)) {
            shortPosition.addresses.account = address(this);
            shortPosition.addresses.market = market;
            shortPosition.addresses.collateralToken = address(collateralToken);
        }

        return (longPosition, shortPosition);
    }

    function _getPositinPnlCollateral(
        Position.Props memory position,
        MarketUtils.MarketPrices memory prices
    ) internal view returns (int256) {
        if (position.sizeInTokens() == 0) {
            return 0;
        }
        bytes32 key = _getPositionKey(position.isLong());

        (int256 positionPnlUsd, , ) = IReader(reader).getPositionPnlUsd(
            IDataStore(dataStore),
            marketProps,
            prices,
            key,
            0
        );

        // convert to collateral
        positionPnlUsd =
            positionPnlUsd /
            int256((10 ** (GMX_DECIMALS - collateralDecimals)));

        return (positionPnlUsd);
    }

    //Internal Helper Functions

    //Do we need this or can we just set this in the init function
    function _createOrderParamAddresses()
        internal
        view
        returns (IOrderUtils.CreateOrderParamsAddresses memory)
    {
        //SwapPath for this I think should always be usdc->collateralToken if thats the case we can set this in init
        address[] memory swapPath;
        return
            IOrderUtils.CreateOrderParamsAddresses(
                address(hedgedPool),
                address(this),
                address(this),
                market,
                address(collateralToken),
                swapPath
            );
    }

    function _orderParamAddresses()
        internal
        view
        returns (Order.Addresses memory)
    {
        address[] memory swapPath;
        return
            Order.Addresses(
                address(this),
                address(this),
                address(this),
                address(this),
                market,
                address(collateralToken),
                swapPath
            );
    }

    function _createOrderParamNumbers(
        uint256 sizeDeltaUSD,
        uint256 initialCollateralDeltaAmount,
        uint256 minOutputAmount,
        uint256 acceptablePrice,
        uint256 executionFee
    ) internal pure returns (IOrderUtils.CreateOrderParamsNumbers memory) {
        return
            IOrderUtils.CreateOrderParamsNumbers(
                sizeDeltaUSD,
                initialCollateralDeltaAmount,
                0,
                acceptablePrice,
                executionFee,
                300000, // callback gas limit
                minOutputAmount
            );
    }

    function _orderParamNumbers(
        uint256 sizeDeltaUSD,
        uint256 initialCollateralDeltaAmount,
        uint256 minOutputAmount,
        uint256 acceptablePrice,
        Order.OrderType orderType
    ) internal view returns (Order.Numbers memory) {
        uint256 executionFee = _calculateExecutionFee();

        return
            Order.Numbers(
                orderType,
                Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
                sizeDeltaUSD,
                initialCollateralDeltaAmount,
                0,
                acceptablePrice,
                executionFee,
                0,
                minOutputAmount,
                block.number
            );
    }

    function _createMarketOrder(
        IOrderUtils.CreateOrderParamsAddresses memory createOrderParamAddresses,
        IOrderUtils.CreateOrderParamsNumbers memory createOrderParamNumbers,
        Order.OrderType orderType,
        Order.DecreasePositionSwapType decreasePositionSwap,
        bool isLong,
        bool shouldUnwrapNativeToken
    ) internal returns (bytes32) {
        bytes32 key = IExchangeRouter(exchangeRouter).createOrder(
            IOrderUtils.CreateOrderParams(
                createOrderParamAddresses,
                createOrderParamNumbers,
                orderType,
                decreasePositionSwap,
                isLong,
                shouldUnwrapNativeToken,
                referralCode
            )
        );
        return key;
    }

    function _sendCollateral(uint256 collateralAmount) internal {
        if (collateralAmount == 0) return;

        collateralToken.safeTransferFrom(
            hedgedPool,
            address(this),
            collateralAmount
        );
        IERC20(address(collateralToken)).approve(
            IExchangeRouter(exchangeRouter).router(),
            collateralAmount
        );
        IExchangeRouter(exchangeRouter).sendTokens(
            address(collateralToken),
            orderVault,
            collateralAmount
        );
    }

    struct ChangePositionVars {
        Position.Props longPosition;
        Position.Props shortPosition;
    }

    function _changePosition(
        uint256 currentLong,
        uint256 targetLong,
        uint256 currentShort,
        uint256 targetShort,
        MarketUtils.MarketPrices memory prices
    ) internal {
        ChangePositionVars memory vars;

        (vars.longPosition, vars.shortPosition) = _getPositionInformation();

        for (uint posType; posType < 2; posType++) {
            bool isLong = posType == 0;

            uint256 currentPos = isLong ? currentLong : currentShort;
            uint256 targetPos = isLong ? targetLong : targetShort;

            if (targetPos == currentPos) continue;

            uint256 price = prices.indexTokenPrice.pickPrice(isLong);

            uint256 acceptablePrice = _getAcceptablePrice(
                price,
                targetPos > currentPos,
                isLong
            );

            Position.Props memory position = isLong
                ? vars.longPosition
                : vars.shortPosition;
            int256 marginCurrent;

            marginCurrent =
                int256(position.collateralAmount()) +
                _getPositinPnlCollateral(position, prices);

            uint256 marginRequired = _getMarginRequired(
                (targetPos * (10 ** underlyingDecimals)) /
                    (10 ** SIREN_DECIMALS),
                price
            );

            if (targetPos > currentPos) {
                // increase position

                //First get the sizeInTokens of the position
                uint256 initialCollateralDelta;
                if (marginRequired > uint256(marginCurrent)) {
                    initialCollateralDelta = uint256(
                        marginRequired - uint256(marginCurrent)
                    );
                }

                uint256 sizeDeltaUsd = ((targetPos - currentPos) *
                    price *
                    (10 ** underlyingDecimals)) / (10 ** SIREN_DECIMALS);

                //Adjust for slippage
                uint256 executionPrice = _calculateAdjustedExecutionPrice(
                    position,
                    prices,
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    acceptablePrice,
                    Order.OrderType.MarketIncrease
                );

                sizeDeltaUsd =
                    ((targetPos - currentPos) *
                        executionPrice *
                        (10 ** underlyingDecimals)) /
                    (10 ** SIREN_DECIMALS);

                _gmxPositionIncrease(
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    acceptablePrice,
                    _calculateExecutionFee()
                );
            } else if (targetPos < currentPos) {
                // decrease position
                uint256 initialCollateralDelta;
                if (marginRequired < uint256(marginCurrent)) {
                    initialCollateralDelta =
                        uint256(marginCurrent) -
                        marginRequired;
                }

                uint256 sizeDeltaUsd = (position.sizeInUsd() *
                    (currentPos - targetPos)) / currentPos;

                _gmxPositionDecrease(
                    isLong,
                    sizeDeltaUsd,
                    initialCollateralDelta,
                    acceptablePrice,
                    _calculateExecutionFee()
                );
            }
        }
    }

    /// @notice Deposit collateral to a product
    function _depositCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        if (amount == 0) return;

        uint256 poolBalance = IHedgedPool(hedgedPool).getCollateralBalance();
        if (amount > poolBalance) {
            // pool doesn't have enough collateral, move all we can
            amount = poolBalance;
        }

        _gmxDepositCollateral(isLong, amount, acceptablePrice);
    }

    /// @notice Withdraw collateral from a product
    /// @dev It withdraws directly to the hedged pool
    function _withdrawCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        if (amount == 0) return;

        _gmxWithdrawCollateral(isLong, amount, acceptablePrice);
    }

    function _gmxPositionIncrease(
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 initialCollateralDelta,
        uint256 acceptablePrice,
        uint256 executionFee
    ) internal {
        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUsd,
                initialCollateralDelta,
                0,
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );
        _sendCollateral(initialCollateralDelta);

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketIncrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxIncreaseOrderCreated(key, isLong);
    }

    function _gmxPositionDecrease(
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 initialCollateralDelta,
        uint256 acceptablePrice,
        uint256 executionFee
    ) internal {
        uint256 minOutputAmount = 0;
        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUsd,
                initialCollateralDelta,
                minOutputAmount,
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketDecrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxDecreaseOrderCreated(key, isLong);
    }

    function _gmxDepositCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        uint256 sizeDeltaUSD = 0;
        uint256 initialCollateralDeltaAmount = 0;
        uint256 minOutputAmount = 0;

        uint256 executionFee = _calculateExecutionFee();

        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUSD,
                initialCollateralDeltaAmount,
                minOutputAmount,
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );
        _sendCollateral(amount);

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketIncrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxDepositOrderCreated(key, isLong);
    }

    function _gmxWithdrawCollateral(
        bool isLong,
        uint256 amount,
        uint256 acceptablePrice
    ) internal {
        uint256 executionFee = _calculateExecutionFee();

        uint256 minOutputAmount = 0;
        uint256 sizeDeltaUSD = 0;
        IOrderUtils.CreateOrderParamsAddresses
            memory createOrderParamAddresses = _createOrderParamAddresses();

        IOrderUtils.CreateOrderParamsNumbers
            memory createOrderParamNumbers = _createOrderParamNumbers(
                sizeDeltaUSD,
                amount,
                minOutputAmount, // have to find a way to calcualte the minOutputAmount
                acceptablePrice,
                executionFee
            );

        IExchangeRouter(exchangeRouter).sendWnt{value: executionFee}(
            orderVault,
            executionFee
        );

        bytes32 key = _createMarketOrder(
            createOrderParamAddresses,
            createOrderParamNumbers,
            Order.OrderType.MarketDecrease,
            Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
            isLong,
            false
        );

        pendingOrders[key] = true;
        pendingOrdersCount = pendingOrdersCount + 1;

        emit GmxWithdrawlOrderCreated(key, isLong);
    }

    function _calculateAdjustedExecutionPrice(
        Position.Props memory position,
        MarketUtils.MarketPrices memory prices,
        bool isLong,
        uint256 sizeDeltaUsd,
        uint256 initialCollateralDelta,
        uint256 acceptablePrice,
        Order.OrderType orderType
    ) internal view returns (uint256) {
        PositionUtils.UpdatePositionParams
            memory updateOrderParams = PositionUtils.UpdatePositionParams(
                executOrderParamContracts,
                marketProps,
                Order.Props(
                    _orderParamAddresses(),
                    _orderParamNumbers(
                        sizeDeltaUsd,
                        initialCollateralDelta,
                        0,
                        acceptablePrice,
                        orderType
                    ),
                    Order.Flags(isLong, false, false)
                ),
                bytes32(0),
                position,
                bytes32(0),
                Order.SecondaryOrderType.None
            );

        (, , , uint256 executionPrice) = IGmxUtils(gmxUtils).getExecutionPrice(
            updateOrderParams,
            prices.indexTokenPrice
        );

        return executionPrice;
    }

    function _getPositionKey(bool isLong) internal view returns (bytes32) {
        bytes32 key = keccak256(
            abi.encode(address(this), market, collateralToken, isLong)
        );
        return key;
    }

    function _getMarginRequired(
        uint256 size, // in underlyingDecimals
        uint256 price
    ) internal view returns (uint256) {
        return
            (size * price) /
            leverage /
            (10 ** (GMX_DECIMALS - collateralDecimals));
    }

    // increase order:
    //     - long: executionPrice should be smaller than acceptablePrice
    //     - short: executionPrice should be larger than acceptablePrice

    // decrease order:
    //     - long: executionPrice should be larger than acceptablePrice
    //     - short: executionPrice should be smaller than acceptablePrice
    function _getAcceptablePrice(
        uint256 price,
        bool isIncrease,
        bool isLong
    ) internal pure returns (uint256) {
        uint256 priceDiff = (price * ACCEPTABLE_PRICE_THRESHOLD) / 100;
        if (isIncrease) {
            if (isLong) {
                return price + priceDiff;
            } else {
                return price - priceDiff;
            }
        } else {
            if (isLong) {
                return price - priceDiff;
            } else {
                return price + priceDiff;
            }
        }
    }

    function _getMarketPrices()
        internal
        view
        returns (MarketUtils.MarketPrices memory)
    {
        uint256 indexTokenPrice;
        uint256 longTokenPrice;
        uint256 shortTokenPrice;
        bool hasPrice;
        (hasPrice, indexTokenPrice) = IGmxUtils(gmxUtils).getPriceFeedPrice(
            dataStore,
            marketProps.indexToken
        );
        require(hasPrice, "!indexTokenPrice");

        (hasPrice, longTokenPrice) = IGmxUtils(gmxUtils).getPriceFeedPrice(
            dataStore,
            marketProps.longToken
        );
        require(hasPrice, "!longTokenPrice");

        (hasPrice, shortTokenPrice) = IGmxUtils(gmxUtils).getPriceFeedPrice(
            dataStore,
            marketProps.shortToken
        );
        require(hasPrice, "!shortTokenPrice");

        return (
            MarketUtils.MarketPrices(
                Price.Props(indexTokenPrice, indexTokenPrice),
                Price.Props(longTokenPrice, longTokenPrice),
                Price.Props(shortTokenPrice, shortTokenPrice)
            )
        );
    }

    function _calculateExecutionFee() internal view returns (uint256) {
        // Send entire balance as execution fee, the excess will be refunded
        return tx.gasprice * ORDER_GAS_LIMIT;
    }

    function transfer(address to, uint256 amount) public onlyOwner {
        payable(to).transfer(amount);
    }

    function resetPendingOrder() public onlyOwner {
        pendingOrdersCount = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@equilibria/perennial/contracts/interfaces/IPerennialLens.sol";
// import "@equilibria/perennial/contracts/interfaces/IProduct.sol";

// import "../../interfaces/IHedger.sol";
// import "../../interfaces/IHedgedPool.sol";

// /// @title Perennial protocol perpetual hedger
// /// @notice Hedges pool delta by trading perpetual contracts
contract Perennial1Hedger {
    //     event HedgeUpdated(int256 oldDelta, int256 newDelta);
    //     event Synced(int256 collateralDiff);
    //     uint256 private constant USDC_OFFSET = 1e12;
    //     // Perennial positions are 1e18, siren delta is 1e8
    //     uint256 private constant DELTA_OFFSET = 1e10;
    //     address public hedgedPool;
    //     Token6 public USDC;
    //     IProduct public productLong;
    //     IProduct public productShort;
    //     IMultiInvoker public multiInvoker;
    //     IPerennialLens public lens;
    //     int256 private deltaCached;
    //     uint256 public maintenanceBuffer;
    //     /// @notice Minimum collateral required for perpetual account
    //     uint256 private constant MIN_COLLATERAL = 100e18;
    //     modifier onlyAuthorized() {
    //         require(
    //             msg.sender == hedgedPool ||
    //                 IHedgedPool(hedgedPool).keepers(msg.sender) ||
    //                 msg.sender == owner(),
    //             "!authorized"
    //         );
    //         _;
    //     }
    //     function __PerennialHedger_init(
    //         address _hedgedPool,
    //         address _productLong,
    //         address _productShort,
    //         address _multiInvoker,
    //         address _lens
    //     ) external initializer {
    //         hedgedPool = _hedgedPool;
    //         productLong = IProduct(_productLong);
    //         productShort = IProduct(_productShort);
    //         multiInvoker = IMultiInvoker(_multiInvoker);
    //         lens = IPerennialLens(_lens);
    //         address collateralToken = address(
    //             IHedgedPool(hedgedPool).collateralToken()
    //         );
    //         // Verify that pool is using USDC
    //         require(
    //             collateralToken ==
    //                 Token6.unwrap(IMultiInvoker(multiInvoker).USDC()),
    //             "Invalid collateral token"
    //         );
    //         USDC = Token6.wrap(collateralToken);
    //         // Max-approve multi invoker
    //         USDC.approve(address(multiInvoker));
    //         maintenanceBuffer = 200; // 2x protocol-required maintenance
    //         __Ownable_init();
    //         __AccessControl_init();
    //     }
    //     function hedgerType() external pure returns (string memory) {
    //         return "PERENNIAL1";
    //     }
    //     /// @notice Update hedger configuration
    //     function updateConfig(
    //         address _productLong,
    //         address _productShort,
    //         address _multiInvoker,
    //         address _lens
    //     ) external onlyOwner {
    //         // remove token approval
    //         USDC.approve(address(multiInvoker), UFixed18.wrap(0));
    //         productLong = IProduct(_productLong);
    //         productShort = IProduct(_productShort);
    //         multiInvoker = IMultiInvoker(_multiInvoker);
    //         lens = IPerennialLens(_lens);
    //         // max-approve new multi invoker
    //         USDC.approve(address(multiInvoker));
    //     }
    //     /// @notice Set maintenance buffer in percent (200 means 2x maintenance required by product)
    //     function setMaintenanceBuffer(
    //         uint256 _maintenanceBuffer
    //     ) external onlyOwner {
    //         maintenanceBuffer = _maintenanceBuffer;
    //     }
    //     /// @notice Adjust perpetual position in order to hedge given delta exposure
    //     /// @param targetDelta Target delta of the hedge (1e8)
    //     /// @return deltaDiff difference between the new delta and the old delta
    //     function hedge(
    //         int256 targetDelta
    //     ) external onlyAuthorized returns (int256 deltaDiff) {
    //         _syncDelta();
    //         // get current hedge delta
    //         deltaDiff = targetDelta - deltaCached;
    //         // TODO: add check to avoid hedging very small changes
    //         // calculate changes in long and short
    //         uint currentLong;
    //         uint currentShort;
    //         uint targetLong;
    //         uint targetShort;
    //         if (targetDelta >= 0) {
    //             targetLong = uint256(targetDelta) * DELTA_OFFSET;
    //             // need long hedge
    //             if (deltaCached >= 0) {
    //                 currentLong = uint256(deltaCached) * DELTA_OFFSET;
    //             } else {
    //                 currentShort = uint256(-deltaCached) * DELTA_OFFSET;
    //             }
    //         } else if (targetDelta < 0) {
    //             targetShort = uint256(-targetDelta) * DELTA_OFFSET;
    //             // need short hedge
    //             if (deltaCached <= 0) {
    //                 currentShort = uint256(-deltaCached) * DELTA_OFFSET;
    //             } else {
    //                 currentLong = uint256(deltaCached) * DELTA_OFFSET;
    //             }
    //         }
    //         // TODO: better edge case handling (e.g. insufficient collateral)
    //         // Update positions
    //         _changePosition(productLong, currentLong, targetLong);
    //         _changePosition(productShort, currentShort, targetShort);
    //         emit HedgeUpdated(deltaCached, targetDelta);
    //         deltaCached = targetDelta;
    //         return deltaDiff;
    //     }
    //     /// @notice Get current hedge delta
    //     function getDelta() external view returns (int256) {
    //         return deltaCached;
    //     }
    //     /// @notice Get current collateral balance used for maintenance
    //     function getCollateralValue() external returns (uint256) {
    //         return
    //             (UFixed18.unwrap(lens.collateral(address(this), productLong)) +
    //                 UFixed18.unwrap(lens.collateral(address(this), productShort))) /
    //             USDC_OFFSET;
    //     }
    //     /// @notice Get required collateral
    //     /// @return collateral shortfall (positive) or excess (negative)
    //     function getRequiredCollateral() external returns (int256) {
    //         return
    //             (_getRequiredCollateral(productLong) +
    //                 _getRequiredCollateral(productShort)) / int256(USDC_OFFSET);
    //     }
    //     /// @notice Withdraw excess collateral or deposit more
    //     /// @return collateralDiff deposit (positive) or withdrawal (negative) amount
    //     function sync() external onlyAuthorized returns (int256 collateralDiff) {
    //         return _sync();
    //     }
    //     function _sync() internal returns (int256 collateralDiff) {
    //         int256 collateralDiffLong = _getRequiredCollateral(productLong);
    //         int256 collateralDiffShort = _getRequiredCollateral(productShort);
    //         collateralDiff = collateralDiffLong + collateralDiffShort;
    //         // move collateral to/from products
    //         _moveCollateral(productLong, collateralDiffLong);
    //         _moveCollateral(productShort, collateralDiffShort);
    //         // sync delta
    //         _syncDelta();
    //         emit Synced(collateralDiff);
    //         return collateralDiff;
    //     }
    //     /// @notice sync cached delta value
    //     function _syncDelta() internal {
    //         Position memory positionLong = productLong.position(address(this));
    //         PrePosition memory preLong = productLong.pre(address(this));
    //         Position memory positionShort = productShort.position(address(this));
    //         PrePosition memory preShort = productShort.pre(address(this));
    //         deltaCached =
    //             (int256(UFixed18.unwrap(positionLong.taker)) +
    //                 int256(UFixed18.unwrap(preLong.openPosition.taker)) -
    //                 int256(UFixed18.unwrap(preLong.closePosition.taker)) -
    //                 int256(UFixed18.unwrap(positionShort.taker)) -
    //                 int256(UFixed18.unwrap(preShort.openPosition.taker)) +
    //                 int256(UFixed18.unwrap(preShort.closePosition.taker))) /
    //             int256(DELTA_OFFSET);
    //     }
    //     /// @notice get collateral requirement
    //     /// @return collateral shortfall (positive) or excess (negative)
    //     function _getRequiredCollateral(
    //         IProduct product
    //     ) internal returns (int256) {
    //         // get safe maintenance
    //         uint256 maintenance = (UFixed18.unwrap(
    //             lens.maintenance(address(this), product)
    //         ) * maintenanceBuffer) / 100;
    //         // ensure resulting collateral is above minimum
    //         if (maintenance > 0 && maintenance < MIN_COLLATERAL) {
    //             maintenance = MIN_COLLATERAL;
    //         }
    //         // get already deposited collateral
    //         uint256 collateral = UFixed18.unwrap(
    //             lens.collateral(address(this), product)
    //         );
    //         if (collateral > maintenance) {
    //             // excess
    //             return -int256(collateral - maintenance);
    //         } else {
    //             // shortfall
    //             return int256(maintenance - collateral);
    //         }
    //     }
    //     function _changePosition(
    //         IProduct product,
    //         uint256 currentPos,
    //         uint256 targetPos
    //     ) internal {
    //         if (targetPos == currentPos) return;
    //         uint256 collateral = UFixed18.unwrap(
    //             lens.collateral(address(this), product)
    //         );
    //         if (targetPos > currentPos) {
    //             // increase position
    //             uint256 maintenance = (UFixed18.unwrap(
    //                 lens.maintenanceRequired(
    //                     address(this),
    //                     product,
    //                     UFixed18.wrap(targetPos)
    //                 )
    //             ) * maintenanceBuffer) / 100;
    //             // ensure resulting collateral is above minimum
    //             if (maintenance < MIN_COLLATERAL) {
    //                 maintenance = MIN_COLLATERAL;
    //             }
    //             if (maintenance > collateral) {
    //                 _depositCollateral(product, maintenance - collateral);
    //             }
    //             product.openTake(UFixed18.wrap(targetPos - currentPos));
    //         } else {
    //             // reduce position
    //             product.closeTake(UFixed18.wrap(currentPos - targetPos));
    //             uint256 maintenance = (UFixed18.unwrap(
    //                 lens.maintenance(address(this), product)
    //             ) * maintenanceBuffer) / 100;
    //             // ensure resulting collateral is above minimum
    //             if (maintenance > 0 && maintenance < MIN_COLLATERAL) {
    //                 maintenance = MIN_COLLATERAL;
    //             }
    //             if (maintenance < collateral) {
    //                 _withdrawCollateral(product, collateral - maintenance);
    //             }
    //         }
    //     }
    //     /// @notice Move collateral to/from a product
    //     /// @param product product address
    //     /// @param collateralDiff deposit (positive) or withdrawal (negative) amount
    //     function _moveCollateral(IProduct product, int256 collateralDiff) internal {
    //         if (collateralDiff == 0) return;
    //         if (collateralDiff > 0) {
    //             // deposit
    //             _depositCollateral(product, uint256(collateralDiff));
    //         } else {
    //             // withdraw
    //             _withdrawCollateral(product, uint256(-collateralDiff));
    //         }
    //     }
    //     /// @notice Deposit collateral to a product
    //     function _depositCollateral(IProduct product, uint256 amount) internal {
    //         if (amount == 0) return;
    //         // check if pool has enough collateral
    //         uint256 poolBalance = IHedgedPool(hedgedPool).getCollateralBalance() *
    //             USDC_OFFSET;
    //         if (amount > poolBalance) {
    //             // pool doesn't have enough collateral, move all we can
    //             amount = poolBalance;
    //         }
    //         USDC.pull(hedgedPool, UFixed18.wrap(amount), true);
    //         IMultiInvoker.Invocation[]
    //             memory invocations = new IMultiInvoker.Invocation[](1);
    //         invocations[0] = IMultiInvoker.Invocation(
    //             IMultiInvoker.PerennialAction.WRAP_AND_DEPOSIT,
    //             abi.encode(address(this), product, amount)
    //         );
    //         IMultiInvoker(multiInvoker).invoke(invocations);
    //     }
    //     /// @notice Withdraw collateral from a product
    //     /// @dev It withdraws directly to the hedged pool
    //     function _withdrawCollateral(IProduct product, uint256 amount) internal {
    //         if (amount == 0) return;
    //         IMultiInvoker.Invocation[]
    //             memory invocations = new IMultiInvoker.Invocation[](1);
    //         // withdraw
    //         invocations[0] = IMultiInvoker.Invocation(
    //             IMultiInvoker.PerennialAction.WITHDRAW_AND_UNWRAP,
    //             abi.encode(hedgedPool, product, amount)
    //         );
    //         IMultiInvoker(multiInvoker).invoke(invocations);
    //     }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IMarket.sol";
import "@equilibria/perennial-v2/contracts/interfaces/IMarketFactory.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {PositionLib, Position} from "@equilibria/perennial-v2/contracts/types/Position.sol";
import "@equilibria/perennial-v2-oracle/contracts/interfaces/IOracle.sol";
import "@equilibria/perennial-v2-extensions/contracts/interfaces/IMultiInvoker.sol";
import "@equilibria/perennial-v2/contracts/types/OracleVersion.sol";
import "../../interfaces/IHedger.sol";
import "../../interfaces/IHedgedPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IV3SwapRouter} from "@uniswap/swap-router-contracts/contracts/interfaces/ISwapRouter02.sol";
import {IOracle as GammaOracle} from "../../interfaces/IGamma.sol";

/// @title Perennial protocol perpetual hedger
/// @notice Hedges pool delta by trading perpetual contracts
contract Perennial2Hedger is
    IHedger,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    using SafeERC20 for IERC20;
    using Strings for bytes;

    // Perennial positions are 1e6, siren delta is 1e8
    uint256 private constant DELTA_OFFSET = 1e2;

    // Constant Decimals
    uint256 private constant PERENNIAL_POSITION_DECIMALS = 6;
    uint256 private constant SIREN_DECIMALS = 8;
    uint256 private constant PRICE_FEED_DECIMALS = 8;
    uint256 private constant COLLATERAL_DECIMALS = 6;

    /// @notice Minimum collateral required for perpetual account in perennial is 15 dollars
    uint256 private constant MIN_COLLATERAL = 20e6;

    //Magic value for perennial
    uint256 constant NO_OP_VALUE = type(uint256).max;
    int256 constant WITHDRAW_MAGIC_VALUE_NON_TRIGGER = type(int256).min;
    int64 constant WITHDRAW_MAGIC_VALUE = type(int64).min;

    //PLACE_ORDER operations
    uint8 constant SIDE_WITHDRAW = 3;
    int8 constant COMPARISON_GTE = 1;

    uint256 public underlying_decimals;

    int256 private deltaCached;

    uint256 public executionFee;

    uint256 private leverage;

    // 5 percent price buffer
    uint256 public perennialPercentPriceBuffer;

    //Fees for PLACE_ORDER
    uint256 public withdrawFee;
    uint256 public depositFee;

    address public hedgedPool;

    IMarket public market;

    IOracle public oracle;

    IMultiInvoker public multiInvoker;

    // Perenn
    IERC20 public perennialCollateral;
    IERC20 public hedgedPoolCollateral;

    address public pythFactory;

    // this is a bytes price feed for pyth oracle
    // https://pyth.network/price-feeds
    //Change name of this to pythPriceFeedID
    bytes32 public priceFeedId;

    address public marketFactory;

    IPyth public pythPriceFeed;

    address public swapRouter;

    address public gammaOracle;

    IERC20Metadata public underlyingAsset;

    struct InterfaceFee {
        uint256 amount;
        address receiver;
        bool unwrap;
    }

    /// @notice NPM was out of date so we had to include the triggerOrder from the perennial contract directly
    struct TriggerOrder {
        uint8 side;
        int8 comparison;
        UFixed6 fee;
        Fixed6 price;
        Fixed6 delta;
        InterfaceFee interfaceFee1;
        InterfaceFee interfaceFee2;
    }

    event HedgeUpdated(int256 oldDelta, int256 newDelta);

    event Synced(int256 collateralDiff);

    // create magic value for max and min

    modifier onlyAuthorized() {
        require(
            msg.sender == hedgedPool ||
                IHedgedPool(hedgedPool).keepers(msg.sender) ||
                msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }
    /// @notice Initialize the hedger
    /// @param _hedgedPool Address of the hedged pool
    /// @param _market Address of the market - perennial market for each underlying - https://docs.perennial.finance/protocol-info/markets-and-vaults
    /// @param _multiInvoker Address of the multi invoker - perennial multi invoker
    /// @param _oracle Address of the oracle - perennial oracle
    /// @param _pythFactory Address of the pyth factory - perennial pyth factory
    /// @param _priceFeedId Price feed id - pyth netowkr price feed id https://pyth.network/developers/price-feed-ids#pyth-evm-stable ( need to validate they work with perennial before imple)
    /// @param _marketFactory Address of the market factory - perennial market factory
    /// @param _pythPriceFeed Address of the pyth price feed - address that comes from the pyth network https://docs.pyth.network/price-feeds/contract-addresses/evm
    /// @param _perennialCollateral Address of the perennial collateral - bridged usdc ( this will not be needed after they upgrade to allow usdc)
    /// @param _swapRouter Address of the uniswap swap router - needed because perennial uses bridged usdc and use use usdc
    function __Perennial2Hedger_init(
        address _hedgedPool,
        address _market,
        address _multiInvoker,
        address _oracle,
        address _pythFactory,
        bytes32 _priceFeedId,
        address _marketFactory,
        address _pythPriceFeed,
        address _perennialCollateral,
        address _swapRouter,
        address _gammaOracle,
        address _underlyingAsset
    ) external payable initializer {
        _updateConfig(
            _hedgedPool,
            _market,
            _multiInvoker,
            _oracle,
            _pythFactory,
            _priceFeedId,
            _marketFactory,
            _pythPriceFeed,
            _perennialCollateral,
            _swapRouter,
            _gammaOracle,
            _underlyingAsset
        );

        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](1);
        invocations[0] = IMultiInvoker.Invocation(
            IMultiInvoker.PerennialAction.APPROVE,
            abi.encode(_market)
        );
        executionFee = 1;

        IMultiInvoker(multiInvoker).invoke{value: executionFee}(invocations);

        IMarketFactory(marketFactory).updateOperator(_multiInvoker, true);

        __Ownable_init();
        __AccessControl_init();
    }

    function hedgerType() external pure returns (string memory) {
        return "PERENNIAL2";
    }

    /// @notice Update hedger configuration
    function updateConfig(
        address _hedgedPool,
        address _market,
        address _multiInvoker,
        address _oracle,
        address _pythFactory,
        bytes32 _priceFeedId,
        address _marketFactory,
        address _pythPriceFeed,
        address _perennialCollateral,
        address _swapRouter,
        address _gammaOracle,
        address _underlyingAsset
    ) external onlyOwner {
        _updateConfig(
            _hedgedPool,
            _market,
            _multiInvoker,
            _oracle,
            _pythFactory,
            _priceFeedId,
            _marketFactory,
            _pythPriceFeed,
            _perennialCollateral,
            _swapRouter,
            _gammaOracle,
            _underlyingAsset
        );
    }

    function _updateConfig(
        address _hedgedPool,
        address _market,
        address _multiInvoker,
        address _oracle,
        address _pythFactory,
        bytes32 _priceFeedId,
        address _marketFactory,
        address _pythPriceFeed,
        address _perennialCollateral,
        address _swapRouter,
        address _gammaOracle,
        address _underlyingAsset
    ) internal {
        hedgedPool = _hedgedPool;
        market = IMarket(_market);
        multiInvoker = IMultiInvoker(_multiInvoker);
        oracle = IOracle(_oracle);
        pythFactory = _pythFactory;
        priceFeedId = _priceFeedId;
        marketFactory = _marketFactory;
        swapRouter = _swapRouter;
        pythPriceFeed = IPyth(_pythPriceFeed);
        gammaOracle = _gammaOracle;
        underlyingAsset = IERC20Metadata(_underlyingAsset);

        //Perennial Collateral = bridged usdc
        perennialCollateral = IERC20(_perennialCollateral);
        hedgedPoolCollateral = IHedgedPool(hedgedPool).collateralToken();

        leverage = 5;

        withdrawFee = 5e6;
        depositFee = 20e6;

        perennialPercentPriceBuffer = 5;

        {
            underlying_decimals = underlyingAsset.decimals();
        }
    }

    /// @notice Adjust perpetual position in order to hedge given delta exposure
    /// @param targetDelta Target delta of the hedge (1e8)
    /// @param signedPrice Signed price feed
    /// @param version Version of the price feed publishTime - 4s
    /// @param underlyingPrice Price of the underlying asset in 1e8 from pyth network
    /// @return deltaDiff difference between the new delta and the old delta
    function hedge(
        int256 targetDelta,
        bytes calldata signedPrice,
        uint256 version,
        uint256 underlyingPrice
    ) external payable onlyAuthorized returns (int256 deltaDiff) {
        if (targetDelta == 0) {
            revert("Cannot hedge to 0 use hedgeToZero");
        }

        _syncDelta();

        _noOpInvokeInternal(signedPrice, version);

        // get current hedge delta
        deltaDiff = targetDelta - deltaCached;
        // TODO: add check to avoid hedging very small changes

        // calculate changes in long and short
        uint currentLong;
        uint currentShort;
        uint targetLong;
        uint targetShort;

        if (targetDelta >= 0) {
            // Perennial is in 1e6 for positions
            // SIREN Is in 1e8
            targetLong = uint256(targetDelta) / DELTA_OFFSET;
            // need long hedge
            if (deltaCached >= 0) {
                currentLong = uint256(deltaCached) / DELTA_OFFSET;
            } else {
                currentShort = uint256(-deltaCached) / DELTA_OFFSET;
            }
        } else if (targetDelta < 0) {
            targetShort = uint256(-targetDelta) / DELTA_OFFSET;

            // need short hedge
            if (deltaCached <= 0) {
                currentShort = uint256(-deltaCached) / DELTA_OFFSET;
            } else {
                currentLong = uint256(deltaCached) / DELTA_OFFSET;
            }
        }

        // TODO: better edge case handling (e.g. insufficient collateral)

        // Update positions
        _changePosition(
            currentLong,
            targetLong,
            currentShort,
            targetShort,
            signedPrice,
            version,
            underlyingPrice
        );

        emit HedgeUpdated(deltaCached, targetDelta);

        //Setting this here is okay to save on gas
        deltaCached = targetDelta;

        return deltaDiff;
    }

    /// @param signedPrice Signed price feed
    /// @param version Version of the price feed publishTime - 4s
    /// @param underlyingPrice Price of the underlying asset in 1e8 from pyth network
    /// @return deltaDiff difference between the new delta and the old delta
    function hedgeToZero(
        bytes calldata signedPrice,
        uint256 version,
        uint256 underlyingPrice
    ) external payable onlyAuthorized returns (int256 deltaDiff) {
        (uint256 currentLong, uint256 currentShort) = _getPositionInformation();

        // Update positions
        _updatePositionToZero(
            currentLong,
            currentShort,
            signedPrice,
            version,
            underlyingPrice
        );

        emit HedgeUpdated(deltaCached, 0);

        //Setting this here is okay to save on gas
        deltaCached = 0;

        return deltaDiff;
    }

    /// @notice Withdraw excess collateral or deposit more
    /// @return collateralDiff deposit (positive) or withdrawal (negative) amount
    function sync() external onlyAuthorized returns (int256 collateralDiff) {
        collateralDiff = _sync();
        return collateralDiff;
    }

    /// @notice Get current hedge delta
    function getDelta() external view returns (int256) {
        return deltaCached;
    }

    /// @notice Get current hedge delta
    function getCollateralValue() external returns (uint256) {
        _getMarketUpdateNoOP();

        market.update(
            address(this),
            UFixed6.wrap(NO_OP_VALUE),
            UFixed6.wrap(NO_OP_VALUE),
            UFixed6.wrap(NO_OP_VALUE),
            Fixed6.wrap(0),
            false
        );

        Local memory local = market.locals(address(this));
        return uint256(Fixed6.unwrap(local.collateral));
    }

    // /// @notice Get required collateral
    function getRequiredCollateral() external returns (int256 collateralDiff) {
        //Get the price of the underlying asset from our oracle and convert to 1e8
        uint256 price = GammaOracle(gammaOracle).getPrice(
            address(underlyingAsset)
        );

        (collateralDiff, ) = _getRequiredCollateral(price);
        return collateralDiff;
    }

    /// @notice Get maintenance required from perennial
    /// @return maintenance
    function getMaintenanceRequired() external returns (uint256) {
        _getMarketUpdateNoOP();

        Local memory local = market.locals(address(this));
        Position memory position = market.positions(address(this));
        RiskParameter memory riskParameter = market.riskParameter();
        (OracleVersion memory oracleVersion, ) = oracle.status();

        uint256 maintenance = uint256(
            UFixed6.unwrap(
                PositionLib.maintenance(position, oracleVersion, riskParameter)
            )
        );

        return maintenance;
    }

    /// @notice Get required collateral
    /// @return collateral shortfall (positive) or excess (negative)
    function _getRequiredCollateral(
        uint256 price
    ) internal returns (int256, int256) {
        _getMarketUpdateNoOP();

        Local memory local = market.locals(address(this));
        Position memory position = market.positions(address(this));
        RiskParameter memory riskParameter = market.riskParameter();
        (OracleVersion memory oracleVersion, ) = oracle.status();

        int256 collateral = Fixed6.unwrap(local.collateral);
        int256 marginRequired = 0;
        if (UFixed6.unwrap(position.long) > 0) {
            //Perennial
            marginRequired = int256(
                _getMarginRequired(
                    (UFixed6.unwrap(position.long) *
                        (10 ** underlying_decimals)) /
                        (10 ** PERENNIAL_POSITION_DECIMALS),
                    price
                )
            );
        }
        if (UFixed6.unwrap(position.short) > 0) {
            marginRequired = int256(
                _getMarginRequired(
                    (UFixed6.unwrap(position.short) *
                        (10 ** underlying_decimals)) /
                        (10 ** PERENNIAL_POSITION_DECIMALS),
                    price
                )
            );
        }

        if (
            marginRequired < int256(MIN_COLLATERAL) &&
            (UFixed6.unwrap(position.short) > 0 ||
                UFixed6.unwrap(position.long) > 0)
        ) {
            marginRequired = int256(MIN_COLLATERAL);
        }

        int256 collateralDiff = marginRequired - collateral;

        return (collateralDiff, collateral);
    }

    /// @notice Withdraw excess collateral or deposit more
    /// @return collateralDiff deposit (positive) or withdrawal (negative) amount
    function _sync() internal returns (int256 collateralDiff) {
        // sync delta
        _syncDelta();

        //Get the price of the underlying asset from our oracle and assume it is in 1e8
        uint256 price = GammaOracle(gammaOracle).getPrice(
            address(underlyingAsset)
        );

        (int256 collateralDiff, int256 collateral) = _getRequiredCollateral(
            price
        );

        //We would be withdrawing all collateral so need it set to magic value
        if (collateralDiff == -collateral) {
            collateralDiff = WITHDRAW_MAGIC_VALUE;
        } else {
            if (collateralDiff > 0) {
                collateralDiff =
                    collateralDiff +
                    int256(UFixed6.unwrap(market.parameter().settlementFee));
            }
        }

        _updateCollateral(collateralDiff, price);

        //Swap and withdraw all the collateral we can
        _withdrawCollateral(
            int256(perennialCollateral.balanceOf(address(this)))
        );

        uint256 hedgedPoolCollateralBalance = hedgedPoolCollateral.balanceOf(
            address(this)
        );
        if (hedgedPoolCollateralBalance > 0) {
            hedgedPoolCollateral.safeTransfer(
                hedgedPool,
                hedgedPoolCollateralBalance
            );
        }

        emit Synced(collateralDiff);

        return collateralDiff;
    }

    /// @notice sync cached delta value
    function _syncDelta() internal {
        int256 totalSizeInTokens;

        (
            uint256 longPosition,
            uint256 shortPosition
        ) = _getPositionInformation();
        //Positions are going to be in 1e6
        if (longPosition != 0) {
            totalSizeInTokens = int256(longPosition);
        }
        if (shortPosition != 0) {
            totalSizeInTokens = -int256(shortPosition);
        }

        deltaCached =
            (totalSizeInTokens * int256(10 ** SIREN_DECIMALS)) /
            int256(10 ** PERENNIAL_POSITION_DECIMALS);
    }

    /// @notice Change position
    /// @param currentLong Current long position 1e6
    /// @param targetLong Target long position 1e6
    /// @param currentShort Current short position 1e6
    /// @param targetShort Target short position 1e6
    /// @param signedPrice Signed price feed
    /// @param version Version of the price feed
    /// @param underlyingPrice Price of the underlying asset in 1e8
    function _changePosition(
        uint256 currentLong,
        uint256 targetLong,
        uint256 currentShort,
        uint256 targetShort,
        bytes calldata signedPrice,
        uint256 version,
        uint256 underlyingPrice
    ) internal {
        // update
        Local memory local = market.locals(address(this));
        Position memory position = market.positions(address(this));

        int256 collateral = Fixed6.unwrap(local.collateral);

        uint256 marginRequired;

        if (targetLong != 0) {
            marginRequired = _getMarginRequired(
                (targetLong * (10 ** underlying_decimals)) /
                    (10 ** PERENNIAL_POSITION_DECIMALS),
                underlyingPrice
            );
        }
        if (targetShort != 0) {
            marginRequired = _getMarginRequired(
                (targetShort * (10 ** underlying_decimals)) /
                    (10 ** PERENNIAL_POSITION_DECIMALS),
                underlyingPrice
            );
        }
        if (marginRequired != 0) {
            marginRequired =
                marginRequired +
                UFixed6.unwrap(market.parameter().settlementFee);
        }

        if (marginRequired < MIN_COLLATERAL) {
            marginRequired = MIN_COLLATERAL;
        }
        // If we are only editing a short position side and not switching
        if (currentLong == 0 && targetLong == 0) {
            targetLong = NO_OP_VALUE;
        }

        // If we are only editing a long position side and not switching
        if (currentShort == 0 && targetShort == 0) {
            targetShort = NO_OP_VALUE;
        }

        _updatePosition(
            targetLong,
            targetShort,
            int256(marginRequired) - collateral,
            signedPrice,
            version,
            ((underlyingPrice * (10 ** COLLATERAL_DECIMALS)) /
                (10 ** PRICE_FEED_DECIMALS))
        );
    }

    /// @notice Update position
    /// @param newLong New long position
    /// @param newShort New short position
    /// @param amount Amount to deposit or withdraw
    /// @param signedPrice Signed price feed
    /// @param version Version of the price feed
    /// @param underlyingPrice Price of the underlying asset in 1e6
    function _updatePosition(
        uint256 newLong,
        uint256 newShort,
        int256 amount,
        bytes calldata signedPrice,
        uint256 version,
        uint256 underlyingPrice
    ) internal {
        if (amount == 0) return;

        if (amount > 0) {
            amount = _prepareDepositCollateral(amount);
        }

        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](1);

        InterfaceFee memory interfaceFee1 = InterfaceFee({
            amount: 0,
            receiver: address(0),
            unwrap: false
        });

        {
            bytes32[] memory ids = new bytes32[](1);
            ids[0] = priceFeedId;

            //We are not switching sides so we can just update the position
            invocations[0] = _createUpdatePositionInvocation(
                newLong,
                newShort,
                amount,
                interfaceFee1
            );
        }

        IMultiInvoker(multiInvoker).invoke{value: executionFee}(invocations);

        if (amount < 0) {
            _withdrawCollateral(
                int256(perennialCollateral.balanceOf(address(this)))
            );
        }
    }

    function _updatePositionToZero(
        uint256 currentLong,
        uint256 currentShort,
        bytes calldata signedPrice,
        uint256 version,
        uint256 underlyingPrice
    ) internal {
        if (currentLong == 0 && currentShort == 0) {
            return;
        }

        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](2);

        InterfaceFee memory interfaceFee1 = InterfaceFee({
            amount: 0,
            receiver: address(0),
            unwrap: false
        });

        {
            bytes32[] memory ids = new bytes32[](1);
            ids[0] = priceFeedId;

            //Commit price for position change
            invocations[0] = IMultiInvoker.Invocation(
                IMultiInvoker.PerennialAction.COMMIT_PRICE,
                //(address oracleProviderFactory, value,  ids,  version, data, revertOnFailure)
                abi.encode(
                    pythFactory,
                    executionFee,
                    ids,
                    version,
                    signedPrice,
                    true
                )
            );

            if (currentLong == 0) {
                //IF we switch from short to long we must close short then open long with trigger
                invocations[1] = _createUpdatePositionInvocation(
                    NO_OP_VALUE,
                    0,
                    0,
                    interfaceFee1
                );
            } else if (currentShort == 0) {
                //IF we switch from long to short we must close short then open short with trigger
                invocations[1] = _createUpdatePositionInvocation(
                    0,
                    NO_OP_VALUE,
                    0,
                    interfaceFee1
                );
            }
        }

        IMultiInvoker(multiInvoker).invoke{value: executionFee}(invocations);
    }

    /// @notice Update collateral
    /// @param amount Amount to deposit or withdraw
    /// @param price Price of the underlying in 1e6
    function _updateCollateral(int256 amount, uint256 price) internal {
        if (amount == 0) return;

        InterfaceFee memory interfaceFee1 = InterfaceFee({
            amount: 0,
            receiver: address(0),
            unwrap: false
        });
        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](1);
        // DEposit is safe so we can do a update_position
        if (amount > 0) {
            amount = _prepareDepositCollateral(amount);

            bytes32[] memory ids = new bytes32[](1);
            ids[0] = priceFeedId;

            invocations[0] = _createUpdatePositionInvocation(
                NO_OP_VALUE,
                NO_OP_VALUE,
                amount,
                interfaceFee1
            );
        } else {
            int256 triggerPrice = int256(
                (((price - (price * perennialPercentPriceBuffer) / 100)) *
                    (10 ** COLLATERAL_DECIMALS)) / (10 ** PRICE_FEED_DECIMALS)
            );

            //Error on the side of being over collateralized for withdrawing
            amount = amount + int256(withdrawFee);
            invocations[0] = _createTriggerOrderInvocation(
                withdrawFee,
                triggerPrice,
                amount,
                interfaceFee1,
                SIDE_WITHDRAW,
                COMPARISON_GTE
            );
        }

        IMultiInvoker(multiInvoker).invoke{value: executionFee}(invocations);
    }

    /// @notice Create a trigger order invocation
    /// @param side Side of the trigger order
    /// @param comparison Comparison of the trigger order
    /// @param fee Fee of the trigger order
    /// @param price Price of the trigger order
    /// @param delta Delta of the trigger order
    /// @param interfaceFee Interface fee
    /// @return Invocation
    function _createTriggerOrderInvocation(
        uint256 fee,
        int256 price,
        int256 delta,
        InterfaceFee memory interfaceFee,
        uint8 side,
        int8 comparison
    ) internal returns (IMultiInvoker.Invocation memory) {
        // Add trigger order to decrease position fully
        TriggerOrder memory triggerOrder = TriggerOrder({
            side: side, // 0 = maker, 1 = long, 2 = short, 3 = collateral withdraw
            comparison: comparison, // -2 = lt, -1 = lte, 0 = eq, 1 = gte, 2 = gt
            fee: UFixed6.wrap(fee), // the max you are willing to pay for execution on chain
            price: Fixed6.wrap(price), //int256(underlyingPrice - perennialPriceBuffer), // Set the buffer to be less than the actual expected price we just submitted
            delta: Fixed6.wrap(delta), // For long / short this is the change in position, for collateral this is the amount to withdraw
            interfaceFee1: interfaceFee,
            interfaceFee2: interfaceFee
        });
        return
            IMultiInvoker.Invocation(
                IMultiInvoker.PerennialAction.PLACE_ORDER,
                // IMarket market, TriggerOrder memory order
                abi.encode(market, triggerOrder)
            );
    }

    /// @notice Create an update position invocation
    /// @param newLong New long position
    /// @param newShort New short position
    /// @param amount Amount to deposit or withdraw
    /// @param interfaceFee Interface fee
    /// @return Invocation
    function _createUpdatePositionInvocation(
        uint256 newLong,
        uint256 newShort,
        int256 amount,
        InterfaceFee memory interfaceFee
    ) internal returns (IMultiInvoker.Invocation memory) {
        return
            IMultiInvoker.Invocation(
                IMultiInvoker.PerennialAction.UPDATE_POSITION,
                // (
                //     IMarket market,
                //     UFixed6 newMaker,
                //     UFixed6 newLong,
                //     UFixed6 newShort,
                //     Fixed6 collateral,
                //     bool wrap,
                //     InterfaceFee memory interfaceFee1,
                //     InterfaceFee memory interfaceFee2
                // )
                abi.encode(
                    market,
                    NO_OP_VALUE,
                    newLong,
                    newShort,
                    amount,
                    true,
                    interfaceFee,
                    interfaceFee
                )
            );
    }

    function _prepareDepositCollateral(
        int256 amount
    ) internal returns (int256) {
        require(amount > 0, "Amount must be greater than 0");

        int256 transferAmount = amount;

        int256 bufferExactOut = (transferAmount / 2000);

        uint256 swappedAmount;

        //Collateral in USDC non bridged
        int256 poolBalance = int256(
            IHedgedPool(hedgedPool).getCollateralBalance()
        );
        int256 currentBalance = int256(
            hedgedPoolCollateral.balanceOf((address(this)))
        );

        bool maxAmount = false;
        if (currentBalance < transferAmount + bufferExactOut) {
            transferAmount = transferAmount + bufferExactOut - currentBalance;

            // WE need to add case where we dont have enough collateral for the target position... in this case we cant hedge or need to update our "target" position on the
            if (transferAmount > poolBalance) {
                // pool doesn't have enough collateral, move all we can
                transferAmount = poolBalance;
                maxAmount = true;
            }
        }

        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to achieve a better swap.

        //If a deposit set the token to be swapped to be the collateral token
        int256 actualAmount;
        if (!maxAmount) {
            hedgedPoolCollateral.safeTransferFrom(
                hedgedPool,
                address(this),
                uint256(transferAmount)
            );
            // Gives us a buffer
            // this gives us 10 + 0.2% buffer

            uint256 maxAmountIn = uint256(amount + bufferExactOut);
            hedgedPoolCollateral.approve(address(swapRouter), maxAmountIn);

            IV3SwapRouter.ExactOutputSingleParams memory params = IV3SwapRouter
                .ExactOutputSingleParams({
                    tokenIn: address(hedgedPoolCollateral),
                    tokenOut: address(perennialCollateral),
                    fee: 100,
                    recipient: address(this),
                    amountOut: uint256(amount),
                    amountInMaximum: maxAmountIn,
                    sqrtPriceLimitX96: 0
                });

            // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
            uint256 actualAmountIn = IV3SwapRouter(swapRouter)
                .exactOutputSingle(params);

            // For exact output swaps, the amountIn may not have all been spent.
            // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
            if (actualAmountIn < maxAmountIn) {
                hedgedPoolCollateral.approve(address(swapRouter), 0);
                hedgedPoolCollateral.safeTransfer(
                    hedgedPool,
                    maxAmountIn - actualAmountIn
                );
            }
            actualAmount = amount;
        }

        if (maxAmount) {
            hedgedPoolCollateral.safeTransferFrom(
                hedgedPool,
                address(this),
                uint256(transferAmount)
            );

            uint256 swapAmount = uint256(transferAmount + currentBalance);

            if (swapAmount == 0) {
                return 0;
            }

            uint256 minAmountOut = swapAmount - (swapAmount / 2000);

            hedgedPoolCollateral.approve(address(swapRouter), swapAmount);

            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
                .ExactInputSingleParams({
                    tokenIn: address(hedgedPoolCollateral),
                    tokenOut: address(perennialCollateral),
                    fee: 100,
                    recipient: address(this),
                    amountIn: swapAmount,
                    amountOutMinimum: minAmountOut,
                    sqrtPriceLimitX96: 0
                });

            // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
            actualAmount = int256(
                IV3SwapRouter(swapRouter).exactInputSingle(params)
            );
        }

        perennialCollateral.approve(
            address(multiInvoker),
            uint256(actualAmount)
        );
        return actualAmount;
    }

    function _withdrawCollateral(int256 amount) internal returns (int256) {
        if (amount == 0) return 0;

        // this gives us 10 + 0.2% buffer
        uint256 minAmountOut = uint256(amount - (amount / 2000));
        // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.

        // Approve the router to spend perennialCollateral.
        perennialCollateral.approve(swapRouter, uint256(amount));

        IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
                tokenIn: address(perennialCollateral),
                tokenOut: address(hedgedPoolCollateral),
                fee: 100,
                recipient: hedgedPool,
                amountIn: uint256(amount),
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        return int256(IV3SwapRouter(swapRouter).exactInputSingle(params));
    }

    /// @notice Get required margin for a position
    /// @param size Position size in underlyingDecimals
    /// @param price Price of the underlying in 1e8
    /// @return marginRequired Required margin in 1e6
    function _getMarginRequired(
        uint256 size,
        uint256 price
    ) internal view returns (uint256) {
        return
            ((((size * price) / leverage)) * (10 ** COLLATERAL_DECIMALS)) /
            (10 ** (underlying_decimals + PRICE_FEED_DECIMALS));
    }

    /// @notice Get current position information
    function _getPositionInformation()
        internal
        returns (uint256 longPosition, uint256 shortPosition)
    {
        _getMarketUpdateNoOP();

        Position memory position = market.positions(address(this));
        return (UFixed6.unwrap(position.long), UFixed6.unwrap(position.short));
    }

    /// @notice Run a no op market update to get the current state
    function _getMarketUpdateNoOP() internal {
        market.update(
            address(this),
            UFixed6.wrap(NO_OP_VALUE),
            UFixed6.wrap(NO_OP_VALUE),
            UFixed6.wrap(NO_OP_VALUE),
            Fixed6.wrap(0),
            false
        );
    }

    /// @notice Execute an order on perennial
    /// @param nonce nonce of the order
    /// @param account account to execute the order
    /// We will not be using this right away we will be using it after perrenial is updated to v2.2 and allows for lower execution feees on PLACE_ORDER
    /// Once this is done we will be able to set an irrational keeper and execute orders without a fee
    function executeOrder(
        uint256 nonce,
        address account,
        bytes calldata signedPrice,
        uint256 version
    ) external payable onlyOwner {
        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](2);
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = priceFeedId;

        //Commit price for position change
        invocations[0] = IMultiInvoker.Invocation(
            IMultiInvoker.PerennialAction.COMMIT_PRICE,
            //(address oracleProviderFactory, value,  ids,  version, data, revertOnFailure)
            abi.encode(
                pythFactory,
                executionFee,
                ids,
                version,
                signedPrice,
                true
            )
        );

        invocations[1] = IMultiInvoker.Invocation(
            IMultiInvoker.PerennialAction.EXEC_ORDER,
            abi.encode(account, market, nonce)
        );
        IMultiInvoker(multiInvoker).invoke{value: msg.value}(invocations);
    }

    /// @notice Withdraw all collateral from the hedger to the pool( right now there is no way for us to send collateral directly to the pool)
    function withdrawAllCollateral() external onlyAuthorized {
        uint256 balanceOfCollateral = perennialCollateral.balanceOf(
            address(this)
        );

        // min out should be 1000 balanceOfCollateral - (balanceOfCollateral * 0.2%)
        //all these tokens should be 1e6 so we need to divide by 1e6
        _withdrawCollateral(int256(balanceOfCollateral));
    }

    /// @notice Withdraw all positions from perennial
    function withdrawAllPositions(
        bytes calldata signedPrice,
        uint256 version,
        uint256 underlyingPrice
    ) external payable onlyAuthorized {
        require(deltaCached == 0, "Cached Delta is not 0!");

        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](2);

        InterfaceFee memory interfaceFee1 = InterfaceFee({
            amount: 0,
            receiver: address(0),
            unwrap: false
        });

        {
            bytes32[] memory ids = new bytes32[](1);
            ids[0] = priceFeedId;

            //Commit price for position change
            invocations[0] = IMultiInvoker.Invocation(
                IMultiInvoker.PerennialAction.COMMIT_PRICE,
                //(address oracleProviderFactory, value,  ids,  version, data, revertOnFailure)
                abi.encode(
                    pythFactory,
                    executionFee,
                    ids,
                    version,
                    signedPrice,
                    true
                )
            );

            //We are not switching sides so we can just update the position
            invocations[1] = _createUpdatePositionInvocation(
                NO_OP_VALUE,
                NO_OP_VALUE,
                WITHDRAW_MAGIC_VALUE_NON_TRIGGER,
                interfaceFee1
            );
        }

        IMultiInvoker(multiInvoker).invoke{value: executionFee}(invocations);
        uint256 balanceOfCollateral = perennialCollateral.balanceOf(
            address(this)
        );
        _withdrawCollateral(int256(balanceOfCollateral));
    }

    function depositCollateral(
        bytes calldata signedPrice,
        uint256 version,
        int256 amount
    ) external payable onlyOwner {
        require(amount > 0, "Amount must be greater than 0");

        uint256 balanceOfCollateral = perennialCollateral.balanceOf(
            address(this)
        );
        if (amount > int256(balanceOfCollateral)) {
            amount = _prepareDepositCollateral(amount);
        }

        perennialCollateral.approve(address(multiInvoker), uint256(amount));

        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](2);
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = priceFeedId;

        //Commit price for position change
        invocations[0] = IMultiInvoker.Invocation(
            IMultiInvoker.PerennialAction.COMMIT_PRICE,
            //(address oracleProviderFactory, value,  ids,  version, data, revertOnFailure)
            abi.encode(
                pythFactory,
                executionFee,
                ids,
                version,
                signedPrice,
                true
            )
        );

        invocations[1] = _createUpdatePositionInvocation(
            NO_OP_VALUE,
            NO_OP_VALUE,
            amount,
            InterfaceFee({amount: 0, receiver: address(0), unwrap: false})
        );
        IMultiInvoker(multiInvoker).invoke{value: msg.value}(invocations);
    }
    function noOpInvokeExternal(
        bytes calldata signedPrice,
        uint256 version
    ) external payable onlyOwner {
        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](2);
        bytes32[] memory ids = new bytes32[](1);
        ids[0] = priceFeedId;

        //Commit price for position change
        invocations[0] = IMultiInvoker.Invocation(
            IMultiInvoker.PerennialAction.COMMIT_PRICE,
            //(address oracleProviderFactory, value,  ids,  version, data, revertOnFailure)
            abi.encode(
                pythFactory,
                executionFee,
                ids,
                version,
                signedPrice,
                true
            )
        );
        InterfaceFee memory interfaceFee1 = InterfaceFee({
            amount: 0,
            receiver: address(0),
            unwrap: false
        });
        //We are not switching sides so we can just update the position
        invocations[1] = _createUpdatePositionInvocation(
            NO_OP_VALUE,
            NO_OP_VALUE,
            0,
            interfaceFee1
        );

        IMultiInvoker(multiInvoker).invoke{value: msg.value}(invocations);
    }

    function _noOpInvokeInternal(
        bytes calldata signedPrice,
        uint256 version
    ) internal {
        IMultiInvoker.Invocation[]
            memory invocations = new IMultiInvoker.Invocation[](2);

        InterfaceFee memory interfaceFee1 = InterfaceFee({
            amount: 0,
            receiver: address(0),
            unwrap: false
        });

        {
            bytes32[] memory ids = new bytes32[](1);
            ids[0] = priceFeedId;

            //Commit price for position change
            invocations[0] = IMultiInvoker.Invocation(
                IMultiInvoker.PerennialAction.COMMIT_PRICE,
                //(address oracleProviderFactory, value,  ids,  version, data, revertOnFailure)
                abi.encode(
                    pythFactory,
                    executionFee,
                    ids,
                    version,
                    signedPrice,
                    false
                )
            );

            //We are not switching sides so we can just update the position
            invocations[1] = _createUpdatePositionInvocation(
                NO_OP_VALUE,
                NO_OP_VALUE,
                0,
                interfaceFee1
            );
        }

        IMultiInvoker(multiInvoker).invoke{value: executionFee}(invocations);
    }
    function setLeverage(uint256 _leverage) external onlyOwner {
        leverage = _leverage;
    }

    function setFees(
        uint256 _withdrawFee,
        uint256 _depositFee,
        uint256 _perennialPercentPriceBuffer
    ) external onlyOwner {
        withdrawFee = _withdrawFee;
        depositFee = _depositFee;
        perennialPercentPriceBuffer = _perennialPercentPriceBuffer;
    }

    function setUnderlyingAsset(address _underlyingAsset) external onlyOwner {
        underlyingAsset = IERC20Metadata(_underlyingAsset);
    }

    function setOracle(address _gammaOracle) external onlyOwner {
        gammaOracle = _gammaOracle;
    }

    function setExecutionFee(uint256 _executionFee) external onlyOwner {
        executionFee = _executionFee;
    }

    function approveUniswapCallback(address _callBack) external onlyOwner {
        hedgedPoolCollateral.approve(_callBack, type(uint256).max);
    }

    function setPythFactory(address _pythFactory) external onlyOwner {
        pythFactory = _pythFactory;
    }

    receive() external payable {}
    // Fallback function in case receive() isn't applicable.
    fallback() external payable {
        // emit Received(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IHedgedPool} from "../interfaces/IHedgedPool.sol";
import {IHedger} from "../interfaces/IHedger.sol";
import {ILpManager} from "../interfaces/ILpManager.sol";
import {ITradeExecutor} from "../interfaces/ITradeExecutor.sol";
import {IAddressBook} from "../interfaces/IAddressBook.sol";
import {IController, IOtoken, GammaTypes, IOracle} from "../interfaces/IGamma.sol";

contract Lens {
    struct PoolInfo {
        uint256 freeCollateral; // collateral available as liquidity in the pool
        uint256 totalCollateral; // free collateral plus any cash allocated for pending withdrawals (should be used for pricePerShare calculation)
        uint256 sharesSupply; // total supply of pool shares
        address[] underlyings; // list of underlying assets supported by the pool
        uint256[] hedgeCollateralValue; // total collateral value inside of the hedge for each underlying
        int256[] hedgeRequiredCollateral; // collateral shortfall (positive) or excess (negative) in the hedge for each underlying
        int256[] hedgeDeltas; // hedge delta for each underlying
        uint256[] vaultCollateral; // collateral locked inside options vaults (0 for longs)
        string[] optionSymbols; // all options symbols
        int256[] optionBalances; // all options balances: positive (long), negative (short)
        uint256[] optionsExpiryPrices; // for expired options expiry prices if available
        bool[] optionsExpiryPricesFinalized; // for expired options whether expiry price is finalized (past dispute period)
    }

    struct LocalVars {
        IHedgedPool pool;
        IAddressBook addressBook;
        ILpManager lpManager;
        IController controller;
        IOracle oracle;
        ITradeExecutor tradeExecutor;
    }

    /// @notice returns the pool info for a given pool
    /// @dev call this function using callStatic
    /// @param poolAddress the address of the pool
    /// @return poolInfo the pool info
    function getPoolInfo(
        address poolAddress
    ) external returns (PoolInfo memory) {
        LocalVars memory vars;
        vars.pool = IHedgedPool(poolAddress);
        vars.addressBook = vars.pool.addressBook();
        vars.lpManager = ILpManager(vars.addressBook.getLpManager());
        vars.controller = IController(vars.addressBook.getController());
        vars.oracle = IOracle(vars.addressBook.getOracle());
        vars.tradeExecutor = ITradeExecutor(
            vars.addressBook.getTradeExecutor()
        );

        PoolInfo memory poolInfo;

        uint256 collateralBalance = vars.pool.collateralToken().balanceOf(
            poolAddress
        );

        // exludes pending withdrawals (use this for pool available liquidity)
        poolInfo.freeCollateral =
            collateralBalance -
            vars.lpManager.getCashLocked(poolAddress, true);
        // includes pending withdrawals (use this for total pool value)
        poolInfo.totalCollateral =
            collateralBalance -
            vars.lpManager.getCashLocked(poolAddress, false);
        poolInfo.sharesSupply = IERC20Metadata(address(vars.pool))
            .totalSupply();

        poolInfo.underlyings = vars.pool.getAllUnderlyings();
        poolInfo.hedgeCollateralValue = new uint256[](
            poolInfo.underlyings.length
        );
        poolInfo.hedgeRequiredCollateral = new int256[](
            poolInfo.underlyings.length
        );
        poolInfo.hedgeDeltas = new int256[](poolInfo.underlyings.length);
        poolInfo.vaultCollateral = new uint256[](poolInfo.underlyings.length);

        for (uint i = 0; i < poolInfo.underlyings.length; i++) {
            address underlying = poolInfo.underlyings[i];
            address hedger = vars.pool.hedgers(underlying);
            poolInfo.hedgeCollateralValue[i] = IHedger(hedger)
                .getCollateralValue();
            poolInfo.hedgeRequiredCollateral[i] = IHedger(hedger)
                .getRequiredCollateral();
            poolInfo.hedgeDeltas[i] = IHedger(hedger).getDelta();

            GammaTypes.Vault memory vault = vars.controller.getVault(
                poolAddress,
                vars.tradeExecutor.marginVaults(
                    address(vars.pool),
                    underlying,
                    0
                )
            );
            if (vault.collateralAmounts.length > 0)
                poolInfo.vaultCollateral[i] = vault.collateralAmounts[0];
        }

        address[] memory oTokens = vars.pool.getActiveOTokens();
        poolInfo.optionSymbols = new string[](oTokens.length);
        poolInfo.optionBalances = new int256[](oTokens.length);
        poolInfo.optionsExpiryPrices = new uint256[](oTokens.length);
        poolInfo.optionsExpiryPricesFinalized = new bool[](oTokens.length);
        for (uint i = 0; i < oTokens.length; i++) {
            address oToken = oTokens[i];
            poolInfo.optionSymbols[i] = IERC20Metadata(oToken).symbol();

            uint vaultId = vars.tradeExecutor.marginVaults(
                address(vars.pool),
                IOtoken(oToken).underlyingAsset(),
                0
            );
            uint oTokenIndex = vars.controller.getOtokenIndex(
                address(vars.pool),
                vaultId,
                oToken
            );
            GammaTypes.Vault memory vault = vars.controller.getVault(
                address(vars.pool),
                vaultId
            );

            poolInfo.optionBalances[i] =
                int256(vault.longAmounts[oTokenIndex]) -
                int256(vault.shortAmounts[oTokenIndex]);

            // return expiry price for expired options
            if (IOtoken(oToken).expiryTimestamp() <= block.timestamp) {
                (
                    poolInfo.optionsExpiryPrices[i],
                    poolInfo.optionsExpiryPricesFinalized[i]
                ) = vars.oracle.getExpiryPrice(
                    IOtoken(oToken).underlyingAsset(),
                    IOtoken(oToken).expiryTimestamp()
                );
            }
        }

        return poolInfo;
    }
}

pragma solidity 0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./LpManagerStorage.sol";

// TODO: make upgradeble

/// @title Accounting of LP deposits and withdrawals
/// @notice Manages LP deposits and withdrawals in a weekly round-based system.
/// * Deposits *
/// LP can request to deposit capital into the pool. When the price per share is determined that capital is released into the pool
/// and new LP shares are minted. LP can redeem their LP shares at any time in the future.
/// * Withdrawals *
/// LPs can request to withdraw capital from the pool. Cash can be added for withdrawal during the round and made available
/// for withdrawals at the end of the round when the price of share is known. Any unfilled shares are rolled to the next round.
contract LpManager is Initializable, LpManagerStorageV1 {
    /// @notice Emitted when LP deposits
    event DepositRequested(
        address pool,
        address lp,
        uint256 amount,
        uint256 roundId
    );

    /// @notice Emitted when LP requests a withdrawal
    event WithdrawalRequested(
        address pool,
        address lp,
        uint256 shares,
        uint256 roundId
    );

    /// @notice Emitted when LP withdraws cash
    event CashWithdrawal(
        address pool,
        address lp,
        uint256 cash,
        uint256 shares
    );

    /// @notice Emitted when LP cancels their pending deposit
    event PendingDepositCancelled(address pool, address lp, uint256 amount);

    /// @notice Emitted when LP redeems shares from processed deposits
    event SharesRedeemed(address pool, address lp, uint256 amount);

    /// @notice Emitted when round is closed
    event WithdrawalRoundClosed(
        address pool,
        uint256 roundId,
        uint256 pricePerShare
    );

    event DepositRoundClosed(
        address pool,
        uint256 roundId,
        uint256 pricePerShare
    );

    /// @notice Emitted when cash is added to the current round
    event CashAdded(
        address pool,
        uint256 roundId,
        uint256 cashAmount,
        uint256 shareAmount
    );

    /// @notice Emitted when pending cash is added for withdrawal
    event PendingCashAdded(address pool, uint256 roundId, uint256 cashAmount);

    function __LpManager_init() external initializer {}

    /// @notice Close the current withdrawal round and start the next one, roll any unfilled shares to the next round
    /// @param pricePerShare final price per share * 1e8
    function closeWithdrawalRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesRemoved) {
        require(pricePerShare > 0, "!price");

        address poolAddress = msg.sender;

        uint256 roundId = withdrawalRoundId[poolAddress];
        WithdrawalRound storage previousRound = withdrawalRounds[poolAddress][
            roundId
        ];

        // process pending withdrawal cash
        uint256 cashNeeded = ((previousRound.sharesTotal -
            previousRound.sharesFilled) * pricePerShare) / 1e8;
        // return any excess cash
        if (previousRound.cashPending > cashNeeded) {
            previousRound.cashPending = cashNeeded;
        }

        // mark cash as ready for withdrawal
        uint256 pendingShares = (previousRound.cashPending * 1e8) /
            pricePerShare;
        previousRound.cash += previousRound.cashPending;
        previousRound.cashPending = 0;

        // update filled shares
        previousRound.sharesFilled += pendingShares;

        // increment current roundId
        withdrawalRoundId[poolAddress] += 1;

        WithdrawalRound storage newRound = withdrawalRounds[poolAddress][
            roundId + 1
        ];
        // roll unfulfilled shares to the new round
        newRound.sharesTotal +=
            previousRound.sharesTotal -
            previousRound.sharesFilled;
        newRound.lockedCash = previousRound.lockedCash + previousRound.cash;

        emit WithdrawalRoundClosed(poolAddress, roundId, pricePerShare);

        return pendingShares;
    }

    /// @notice Close the current deposit round and start the next one
    /// @param pricePerShare final price per share * 1e8
    function closeDepositRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesAdded) {
        require(pricePerShare > 0, "!price");

        address poolAddress = msg.sender;

        uint256 roundId = depositRoundId[poolAddress];
        DepositRound storage previousRound = depositRounds[poolAddress][
            roundId
        ];

        // store share price
        previousRound.pricePerShare = pricePerShare;

        sharesAdded = (previousRound.pendingAmount * 1e8) / pricePerShare;

        // increment current roundId
        depositRoundId[poolAddress] += 1;

        emit DepositRoundClosed(poolAddress, roundId, pricePerShare);

        return sharesAdded;
    }

    /// @notice Add cash with known price per share
    function addPricedCash(uint256 cashAmount, uint256 shareAmount) external {
        require(cashAmount > 0, "!cashAmount");
        require(shareAmount > 0, "!shareAmount");

        address pool = msg.sender;
        uint256 roundId = withdrawalRoundId[pool];
        WithdrawalRound storage round = withdrawalRounds[pool][roundId];
        require(
            shareAmount <= round.sharesTotal - round.sharesFilled,
            "too many shares"
        );

        round.cash += cashAmount;
        round.sharesFilled += shareAmount;

        emit CashAdded(pool, roundId, cashAmount, shareAmount);
    }

    /// @notice Add pending cash for which price per share is not known yet
    function addPendingCash(uint256 cashAmount) external {
        require(cashAmount > 0, "cashAmount is 0");

        address pool = msg.sender;

        uint256 roundId = withdrawalRoundId[pool];

        WithdrawalRound storage round = withdrawalRounds[pool][roundId];
        require(round.sharesTotal - round.sharesFilled > 0, "all filled");

        round.cashPending += cashAmount;

        emit PendingCashAdded(pool, roundId, cashAmount);
    }

    /// @notice Request withdrawal
    function requestWithdrawal(
        address lpAddress,
        uint256 sharesAmount
    ) external {
        address pool = msg.sender;

        // request withdrawal in the next round
        uint256 roundId = withdrawalRoundId[pool];
        WithdrawalRound storage round = withdrawalRounds[pool][roundId];

        // process previous withdrawal requests
        Withdrawal storage withdrawal = withdrawals[pool][lpAddress];
        (
            uint256 sharesRedeemable,
            uint256 sharesOutstanding,
            uint256 cashRedeemable
        ) = getWithdrawalStatus(pool, lpAddress);
        withdrawal.roundId = roundId;
        withdrawal.unredeemedCash = cashRedeemable;
        withdrawal.unredeemedShares = sharesRedeemable;
        withdrawal.shares = sharesOutstanding + sharesAmount;

        // store new shares
        round.sharesTotal += sharesAmount;

        emit WithdrawalRequested(pool, lpAddress, sharesAmount, roundId);
    }

    /// @notice Request deposit
    function requestDeposit(address lpAddress, uint256 cashAmount) external {
        require(cashAmount > 0, "!cashAmount");
        address pool = msg.sender;

        uint256 roundId = depositRoundId[pool];
        DepositRound storage round = depositRounds[pool][roundId];
        round.pendingAmount += cashAmount;

        Deposit storage deposit = deposits[pool][lpAddress];

        // process previous round deposits if any
        if (deposit.amount > 0 && deposit.roundId < roundId) {
            DepositRound memory pastRound = depositRounds[pool][
                deposit.roundId
            ];
            // if round is priced, record unredeemed tokens
            deposit.unredeemedShares +=
                (deposit.amount * 1e8) /
                pastRound.pricePerShare;
            deposit.amount = 0;
        }

        deposit.roundId = roundId;
        deposit.amount += cashAmount;

        emit DepositRequested(pool, lpAddress, cashAmount, roundId);
    }

    /// @notice Withdraw available cash from a withdrawal request
    function withdrawCash(
        address lpAddress
    ) external returns (uint256, uint256) {
        address pool = msg.sender;

        Withdrawal storage withdrawal = withdrawals[pool][lpAddress];

        require(withdrawal.shares > 0, "LP has no withdrawal requests");

        (
            uint256 sharesRedeemable,
            uint256 sharesOutstanding,
            uint256 cashRedeemable
        ) = getWithdrawalStatus(pool, lpAddress);

        uint256 roundId = withdrawalRoundId[pool];
        withdrawal.shares = sharesOutstanding;
        withdrawal.roundId = sharesOutstanding > 0 ? roundId : 0;
        withdrawal.unredeemedCash = 0;
        withdrawal.unredeemedShares = 0;

        if (cashRedeemable > 0) {
            WithdrawalRound storage round = withdrawalRounds[pool][roundId];
            round.lockedCash -= cashRedeemable;

            // emit event
            emit CashWithdrawal(
                pool,
                lpAddress,
                cashRedeemable,
                sharesRedeemable
            );
        }

        return (cashRedeemable, sharesRedeemable);
    }

    /// @notice Cancel pending unprocessed deposit
    function cancelPendingDeposit(address lpAddress, uint256 amount) external {
        address pool = msg.sender;
        uint256 roundId = depositRoundId[pool];
        // withdraw pending deposits
        Deposit storage deposit = deposits[pool][lpAddress];
        if (deposit.roundId == roundId) {
            require(deposit.amount >= amount, "!pending amount");

            deposit.amount -= amount;

            DepositRound storage round = depositRounds[pool][roundId];
            round.pendingAmount -= amount;

            emit PendingDepositCancelled(pool, lpAddress, amount);
        } else {
            revert("!pending deposit");
        }
    }

    /// @notice Redeem LP shares from processed deposits
    function redeemShares(address lpAddress) external returns (uint256) {
        address pool = msg.sender;
        (uint256 cashPending, uint256 sharesRedeemable) = getDepositStatus(
            pool,
            lpAddress
        );

        Deposit storage deposit = deposits[pool][lpAddress];

        if (sharesRedeemable > 0) {
            deposit.unredeemedShares = 0;

            emit SharesRedeemed(pool, lpAddress, sharesRedeemable);
        }

        if (cashPending == 0) {
            // reset deposit state
            deposit.roundId = 0;
            deposit.amount = 0;
            deposit.unredeemedShares = 0;
        }

        return sharesRedeemable;
    }

    /// @notice Get number of unfilled shares in the current withdrawal round
    function getUnfilledShares(
        address poolAddress
    ) external view returns (uint256) {
        WithdrawalRound memory round = withdrawalRounds[poolAddress][
            withdrawalRoundId[poolAddress]
        ];
        return round.sharesTotal - round.sharesFilled;
    }

    /// @notice Get amount of cash locked in a pool for pending withdrawals and unprocessed deposits
    function getCashLocked(
        address poolAddress,
        bool includePendingWithdrawals
    ) external view returns (uint256) {
        WithdrawalRound memory withdrawalRound = withdrawalRounds[poolAddress][
            withdrawalRoundId[poolAddress]
        ];
        DepositRound memory depositRound = depositRounds[poolAddress][
            depositRoundId[poolAddress]
        ];

        // pending deposits and available withdrawals should be excluded from pool reserves
        uint256 amount = depositRound.pendingAmount +
            withdrawalRound.lockedCash +
            withdrawalRound.cash;

        if (includePendingWithdrawals) {
            // pending withdrawals should be included for pool asset value calculation,
            // because associated LP shares still exist,
            // but it should be excluded from available liquidity
            amount += withdrawalRound.cashPending;
        }

        return amount;
    }

    /// @notice Get number of unfilled shares in the current round
    function getWithdrawalStatus(
        address poolAddress,
        address lpAddress
    )
        public
        view
        returns (
            uint256 sharesRedeemable,
            uint256 sharesOutstanding,
            uint256 cashRedeemable
        )
    {
        Withdrawal memory withdrawal = withdrawals[poolAddress][lpAddress];
        // LP has no withdrawal requests
        if (withdrawal.shares == 0) return (0, 0, 0);

        uint256 currentRound = withdrawalRoundId[poolAddress];
        sharesOutstanding = withdrawal.shares;
        cashRedeemable = withdrawal.unredeemedCash;
        sharesRedeemable = withdrawal.unredeemedShares;

        for (uint256 i = withdrawal.roundId; i < currentRound; i++) {
            WithdrawalRound memory round = withdrawalRounds[poolAddress][i];

            // stop if no more shares outstanding
            if (sharesOutstanding == 0) break;

            cashRedeemable +=
                (sharesOutstanding * round.cash) /
                round.sharesTotal;

            // remove redeemed shares
            uint256 sharesDiff = (sharesOutstanding * round.sharesFilled) /
                round.sharesTotal;
            sharesRedeemable += sharesDiff;
            sharesOutstanding -= sharesDiff;
        }
    }

    /// @notice Get status of LP deposits
    function getDepositStatus(
        address poolAddress,
        address lpAddress
    ) public view returns (uint256 cashPending, uint256 sharesRedeemable) {
        Deposit memory deposit = deposits[poolAddress][lpAddress];
        sharesRedeemable = deposit.unredeemedShares;

        if (deposit.roundId == depositRoundId[poolAddress]) {
            // has pending deposit
            cashPending = deposit.amount;
        } else {
            uint256 pricePerShare = depositRounds[poolAddress][deposit.roundId]
                .pricePerShare;

            if (pricePerShare > 0) {
                sharesRedeemable += (deposit.amount * 1e8) / pricePerShare;
            }
        }
    }
}

pragma solidity 0.8.18;

import "../interfaces/ILpManager.sol";

abstract contract LpManagerStorageV1 is ILpManager {
    struct WithdrawalRound {
        uint256 sharesTotal; // total shares awaiting withdrawals
        uint256 sharesFilled; // withdrawal shares that can be withdrawn
        uint256 cash; // cash available to be withdrawn after round closes
        uint256 cashPending; // cash locked, but not priced yet, always 0 for a closed round
        uint256 lockedCash; // total amount of cash locked from previous rounds
    }

    struct DepositRound {
        uint256 pendingAmount; // total pending deposits
        uint256 pricePerShare; // round price per share * 1e8
    }

    struct Withdrawal {
        uint256 roundId;
        uint256 shares;
        uint256 unredeemedShares;
        uint256 unredeemedCash;
    }

    struct Deposit {
        uint256 roundId;
        uint256 amount;
        uint256 unredeemedShares;
    }

    // pool address => current withdrawal roundId
    mapping(address => uint256) public withdrawalRoundId;

    // pool address => current deposit roundId
    mapping(address => uint256) public depositRoundId;

    // withdrawal requests
    // pool address => lp address => Withdrawal
    mapping(address => mapping(address => Withdrawal)) public withdrawals;

    // deposits
    // pool address => lp address => Deposit
    mapping(address => mapping(address => Deposit)) public deposits;

    // pool address => roundId => withdrawal round data
    mapping(address => mapping(uint256 => WithdrawalRound))
        public withdrawalRounds;

    // pool address => roundId => deposit round data
    mapping(address => mapping(uint256 => DepositRound)) public depositRounds;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "../interfaces/IOrderUtil.sol";

/**
 * @title Order Util
 * @notice Order nonce tracking and signature check
 */
contract OrderUtil is IOrderUtil, EIP712("SirenOrder", "1.0") {
    bytes32 internal constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Order(address poolAddress,",
                "address underlying,",
                "address referrer,",
                "uint256 validUntil,",
                "uint256 nonce,",
                "OptionLeg[] legs",
                ")",
                "OptionLeg(uint256 strike,uint256 expiration,bool isPut,int256 amount,int256 premium,uint256 fee)"
            )
        );

    bytes32 internal constant OPTION_LEG_TYPEHASH =
        keccak256(
            "OptionLeg(uint256 strike,uint256 expiration,bool isPut,int256 amount,int256 premium,uint256 fee)"
        );

    // EIP191 header for use in EIP712 signatures
    bytes internal constant EIP191_HEADER = "\x19\x01";

    /**
     * @notice Double mapping of signers to nonce groups to nonce states
     * @dev The nonce group is computed as nonce / 256, so each group of 256 sequential nonces uses the same key
     * @dev The nonce states are encoded as 256 bits, for each nonce in the group 0 means available and 1 means used
     */
    mapping(address => mapping(uint256 => uint256)) internal _nonceGroups;

    // Mapping of signer addresses to an optionally set minimum valid nonce
    mapping(address => uint256) public _signatoryMinimumNonce;

    /**
     * @notice Validates and processes order and returns its signatory
     * @param order Order
     * @return signer and coSigners
     */
    function processOrder(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners) {
        // Validate the signer side of the swap
        (signer, coSigners) = _checkValidOrder(order, _domainSeparatorV4());
        return (signer, coSigners);
    }

    /**
     * @notice Cancel one or more nonces
     * @dev Cancelled nonces are marked as used
     * @dev Emits a Cancel event
     * @dev Out of gas may occur in arrays of length > 400
     * @param nonces uint256[] List of nonces to cancel
     */
    function cancel(uint256[] calldata nonces) external {
        for (uint256 i = 0; i < nonces.length; i++) {
            uint256 nonce = nonces[i];
            _markNonceAsUsed(msg.sender, nonce);
            emit Cancel(nonce, msg.sender);
        }
    }

    /**
     * @notice Cancels all orders below a nonce value
     * @dev Emits a CancelUpTo event
     * @param minimumNonce uint256 Minimum valid nonce
     */
    function cancelUpTo(uint256 minimumNonce) external {
        _signatoryMinimumNonce[msg.sender] = minimumNonce;
        emit CancelUpTo(minimumNonce, msg.sender);
    }

    /**
     * @notice Returns true if the nonce has been used
     * @param signer address Address of the signer
     * @param nonce uint256 Nonce being checked
     */
    function nonceUsed(
        address signer,
        uint256 nonce
    ) public view returns (bool) {
        uint256 groupKey = nonce / 256;
        uint256 indexInGroup = nonce % 256;
        return (_nonceGroups[signer][groupKey] >> indexInGroup) & 1 == 1;
    }

    /**
     * @notice Marks a nonce as used for the given signatory
     * @param signatory  address Address of the signer for which to mark the nonce as used
     * @param nonce uint256 Nonce to be marked as used
     */
    function _markNonceAsUsed(address signatory, uint256 nonce) internal {
        uint256 groupKey = nonce / 256;
        uint256 indexInGroup = nonce % 256;
        uint256 group = _nonceGroups[signatory][groupKey];

        // Revert if nonce is already used
        if ((group >> indexInGroup) & 1 == 1) {
            revert NonceAlreadyUsed(nonce);
        }

        _nonceGroups[signatory][groupKey] =
            group |
            (uint256(1) << indexInGroup);
    }

    /**
     * @notice Tests whether signature and signer are valid
     * @param order Order to validate
     * @param domainSeparator bytes32
     */
    function _checkValidOrder(
        Order calldata order,
        bytes32 domainSeparator
    ) internal returns (address signer, address[] memory coSigners) {
        // Ensure the validUntil is not passed
        if (order.validUntil <= block.timestamp) revert OrderExpired();

        // Get the order hash
        bytes32 hash = _getOrderHash(order, domainSeparator);

        // Recover the signatory from the hash and signature
        signer = _getSignatory(hash, order.signature);

        // Ensure the signatory is not null
        if (signer == address(0)) revert SignatureInvalid();

        // Get co-signers
        coSigners = new address[](order.coSignatures.length);
        for (uint i = 0; i < order.coSignatures.length; i++) {
            address coSigner = _getSignatory(hash, order.coSignatures[i]);
            if (coSigner != address(0)) coSigners[i] = coSigner;
        }

        // Ensure the nonce is not yet used and if not mark it used
        _markNonceAsUsed(signer, order.nonce);

        // Ensure the nonce is not below the minimum nonce set by cancelUpTo
        if (order.nonce < _signatoryMinimumNonce[signer]) revert NonceTooLow();

        return (signer, coSigners);
    }

    /**
     * @notice Hash an order into bytes32
     * @dev EIP-191 header and domain separator included
     * @param order Order The order to be hashed
     * @param domainSeparator bytes32
     * @return bytes32 A keccak256 abi.encodePacked value
     */
    function _getOrderHash(
        Order calldata order,
        bytes32 domainSeparator
    ) internal pure returns (bytes32) {
        bytes32[] memory optionLegsEncoded = new bytes32[](order.legs.length);
        for (uint i = 0; i < order.legs.length; i++) {
            OptionLeg memory leg = order.legs[i];
            optionLegsEncoded[i] = keccak256(
                abi.encode(
                    OPTION_LEG_TYPEHASH,
                    leg.strike,
                    leg.expiration,
                    leg.isPut,
                    leg.amount,
                    leg.premium,
                    leg.fee
                )
            );
        }

        return
            keccak256(
                abi.encodePacked(
                    EIP191_HEADER,
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            ORDER_TYPEHASH,
                            order.poolAddress,
                            order.underlying,
                            order.referrer,
                            order.validUntil,
                            order.nonce,
                            keccak256(abi.encodePacked(optionLegsEncoded))
                        )
                    )
                )
            );
    }

    /**
     * @notice Recover the signatory from a signature
     * @param hash bytes32
     * @param signature Signature
     */
    function _getSignatory(
        bytes32 hash,
        Signature calldata signature
    ) internal pure returns (address) {
        return ecrecover(hash, signature.v, signature.r, signature.s);
    }

    /**
     * @notice Recover the signatory from a signature
     * @dev Don not use in contracts, only for off-chain use
     * @param order bytes32
     */
    function getSigners(
        Order calldata order
    ) external view returns (address signer, address[] memory coSigners) {
        // Get the order hash
        bytes32 hash = _getOrderHash(order, _domainSeparatorV4());

        // Recover the signatory from the hash and signature
        signer = _getSignatory(hash, order.signature);

        // Get co-signers
        coSigners = new address[](order.coSignatures.length);
        for (uint i = 0; i < order.coSignatures.length; i++) {
            address coSigner = _getSignatory(hash, order.coSignatures[i]);
            if (coSigner != address(0)) coSigners[i] = coSigner;
        }

        return (signer, coSigners);
    }
}

// SPDX-License-Identifier: None

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/IHedgedPool.sol";
import "../interfaces/IAddressBook.sol";
import "../libs/OpynLib.sol";
import "../interfaces/IOrderUtil.sol";
import "../libs/Math.sol";
import "../interfaces/CustomErrors.sol";
import {IOtoken, GammaTypes, IController, IOtokenFactory, IMarginCalculator} from "../interfaces/IGamma.sol";

// Change this contract to a portfolio manager
contract TradeExecutor is OwnableUpgradeable, ERC1155Holder {
    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    uint256 public MARGIN_BUFFER_PERCENT;

    IAddressBook public addressBook;

    /// @notice underlying => trader => vaultId[]
    mapping(address => mapping(address => uint256[])) public marginVaults;

    /// @dev List of permitted pool addresses
    mapping(address => bool) public authorizedPools;

    event MarginVaultOpened(
        address indexed trader,
        address underlying,
        uint256 vaultId
    );

    event AuthorizedPoolSet(address indexed pool, bool isAuthorized);

    function __TradeExecutor_init(
        address _addresBookAddress
    ) public initializer {
        addressBook = IAddressBook(_addresBookAddress);
        MARGIN_BUFFER_PERCENT = 115; // 15% buffer

        __Ownable_init();
    }

    /// Initialize the contract, and create an lpToken to track ownership
    function setAddressBook(address _addresBookAddress) external onlyOwner {
        addressBook = IAddressBook(_addresBookAddress);
    }

    struct LocalVars {
        IController controller;
        IMarginCalculator calculator;
        IOtokenFactory otokenFactory;
        IOrderUtil.Order order;
        address marginPoolAddress;
        IERC20 strikeAsset;
        IERC20 collateralAsset;
        uint8 collateralDecimals;
        uint256 underlyingPrice;
        uint256 poolMargin;
        uint256 numLongs;
        uint256 numShorts;
        uint256 totalFee;
        int256 traderCashflow; // >0 trader vault receives, <0 trader vault pays
        address[] oTokens;
        uint256 longCounter;
        uint256 shortCounter;
        uint256 poolVaultId;
        address traderAddress;
        uint256 traderDeposit;
        uint256 traderVaultId;
        int256 traderExposureBeforeCalls;
        int256 traderExposureBeforePuts;
        int256 poolExposureBeforeCalls;
        int256 poolExposureBeforePuts;
    }

    /// @notice executes a trade from a maker pool
    /// @param order the order to execute
    /// @param poolVaultId the vaultId of the pool
    /// @param traderAddress the address of the trader
    /// @param traderDeposit the amount of collateral to deposit
    /// @param traderVaultId the vaultId of the trader
    /// @param autoCreateVault whether to create a vault for the trader if it doesn't exist
    function executeTrade(
        IOrderUtil.Order calldata order,
        uint256 poolVaultId,
        address traderAddress,
        uint256 traderDeposit,
        uint256 traderVaultId,
        bool autoCreateVault
    ) external returns (address[] memory, uint256, int256, int256) {
        require(authorizedPools[msg.sender], "not authorized pool");

        require(
            traderVaultId > 0 || (autoCreateVault && traderVaultId == 0),
            "!vaultId"
        );

        LocalVars memory vars;

        vars.order = order;
        vars.poolVaultId = poolVaultId;
        vars.traderAddress = traderAddress;
        vars.traderDeposit = traderDeposit;
        vars.traderVaultId = traderVaultId;

        // calculate margin required for long legs of the order
        vars.controller = IController(addressBook.getController());
        vars.calculator = IMarginCalculator(addressBook.getMarginCalculator());
        vars.otokenFactory = IOtokenFactory(addressBook.getOtokenFactory());
        vars.marginPoolAddress = addressBook.getMarginPool();

        vars.strikeAsset = IHedgedPool(vars.order.poolAddress).strikeToken();
        vars.collateralAsset = IHedgedPool(vars.order.poolAddress)
            .collateralToken();
        vars.collateralDecimals = IERC20MetadataUpgradeable(
            address(vars.collateralAsset)
        ).decimals();
        vars.underlyingPrice = IOracle(addressBook.getOracle()).getPrice(
            vars.order.underlying
        );

        vars.oTokens = new address[](vars.order.legs.length);

        vars.traderCashflow = int256(traderDeposit);

        for (uint256 i; i < vars.order.legs.length; i++) {
            IOrderUtil.OptionLeg memory leg = vars.order.legs[i];

            if (leg.amount > 0) {
                vars.numLongs++;
                vars.poolMargin +=
                    (vars.calculator.getNakedMarginRequired(
                        vars.order.underlying,
                        address(vars.strikeAsset),
                        address(vars.collateralAsset),
                        uint256(leg.amount),
                        leg.strike,
                        vars.underlyingPrice,
                        leg.expiration,
                        vars.collateralDecimals,
                        leg.isPut
                    ) * MARGIN_BUFFER_PERCENT) /
                    100;
            } else {
                vars.numShorts++;
            }

            // create oTokens if required
            vars.oTokens[i] = OpynLib.findOrCreateOToken(
                address(vars.otokenFactory),
                vars.order.underlying,
                address(vars.strikeAsset),
                address(vars.collateralAsset),
                leg.strike,
                leg.expiration,
                leg.isPut,
                false
            );

            vars.traderCashflow += -leg.premium - int256(leg.fee);
            vars.totalFee += leg.fee;
        }

        // open vault if needed
        if (autoCreateVault) {
            vars.traderVaultId = _openMarginVault(
                vars.traderAddress,
                vars.order.underlying
            );
        }

        (vars.traderExposureBeforeCalls, vars.traderExposureBeforePuts) = vars
            .controller
            .getVaultExposure(vars.traderAddress, vars.traderVaultId);
        (vars.poolExposureBeforeCalls, vars.poolExposureBeforePuts) = vars
            .controller
            .getVaultExposure(msg.sender, vars.poolVaultId);

        // operate1: deposit collateral, mint otokens for long legs of order (pool's vault)
        IController.ActionArgs[] memory actions1 = new IController.ActionArgs[](
            vars.numLongs + (vars.poolMargin > 0 ? 1 : 0)
        );
        // operate2: deposit collateral, deposit otokens, mint otokens for short legs of order (trader's vault)
        IController.ActionArgs[] memory actions2 = new IController.ActionArgs[](
            (autoCreateVault ? 0 : 1) +
                vars.numLongs +
                vars.numShorts +
                (vars.traderCashflow != 0 ? 1 : 0)
        );
        // operate3: deposit short trader oTokens into pool's vault
        IController.ActionArgs[] memory actions3 = new IController.ActionArgs[](
            vars.numShorts
        );

        uint actions2IndexStart = 0;
        if (!autoCreateVault) {
            actions2IndexStart = 1;
            actions2[0] = IController.ActionArgs(
                IController.ActionType.SettleVault,
                vars.traderAddress, // owner
                vars.traderAddress, // to
                address(0),
                vars.traderVaultId,
                0,
                0,
                ""
            );
        }

        // deposit collateral into pool's vault
        if (vars.poolMargin > 0) {
            if (vars.collateralAsset.balanceOf(msg.sender) < vars.poolMargin) {
                revert CustomErrors.NotEnoughLiquidity();
            }

            actions1[actions1.length - 1] = IController.ActionArgs(
                IController.ActionType.DepositCollateral,
                msg.sender, // owner
                msg.sender, // address to transfer from
                address(vars.collateralAsset),
                vars.poolVaultId,
                vars.poolMargin,
                0,
                ""
            );
        }

        // if vars.traderCashflow is > 0 (trader receives):
        // * deposit the premium into trader's vault
        // if vars.traderCashflow is < 0 (trader pays):
        // * take as much as we can from traders collateral
        // * withdraw the rest from the vault

        // deposit collateral into trader's vault
        if (vars.traderCashflow > 0) {
            vars.collateralAsset.safeTransferFrom(
                msg.sender,
                address(this),
                uint256(vars.traderCashflow)
            );
            vars.collateralAsset.safeApprove(
                vars.marginPoolAddress,
                uint256(vars.traderCashflow)
            );
            actions2[actions2.length - 1] = IController.ActionArgs(
                IController.ActionType.DepositCollateral,
                vars.traderAddress, // owner
                address(this), // address to transfer from
                address(vars.collateralAsset),
                vars.traderVaultId,
                uint256(vars.traderCashflow),
                0,
                ""
            );
        } else if (vars.traderCashflow < 0) {
            actions2[actions2.length - 1] = IController.ActionArgs(
                IController.ActionType.WithdrawCollateral,
                vars.traderAddress, // owner
                msg.sender, // address to transfer to
                address(vars.collateralAsset),
                vars.traderVaultId,
                uint256(-vars.traderCashflow),
                0,
                ""
            );
        }

        for (uint256 i; i < vars.order.legs.length; i++) {
            if (vars.order.legs[i].amount > 0) {
                // long
                // mint options only checking margin required for the mint,
                // but not entire portfolio to save gas
                actions1[vars.longCounter] = IController.ActionArgs(
                    IController.ActionType.MintShortOptionLazy,
                    msg.sender,
                    address(this),
                    address(vars.oTokens[i]),
                    vars.poolVaultId,
                    uint256(vars.order.legs[i].amount),
                    0,
                    ""
                );
                IERC20(vars.oTokens[i]).approve(
                    vars.marginPoolAddress,
                    uint256(vars.order.legs[i].amount)
                );
                actions2[vars.longCounter + actions2IndexStart] = IController
                    .ActionArgs(
                        IController.ActionType.DepositLongOption,
                        vars.traderAddress, // owner
                        address(this), // address to transfer from
                        vars.oTokens[i], // option address
                        vars.traderVaultId, // vaultId
                        uint256(vars.order.legs[i].amount), // amount
                        0, //index
                        "" //data
                    );

                vars.longCounter++;
            } else {
                // short
                actions2[
                    vars.numLongs + vars.shortCounter + actions2IndexStart
                ] = IController.ActionArgs(
                    IController.ActionType.MintShortOption,
                    vars.traderAddress,
                    address(this),
                    address(vars.oTokens[i]),
                    vars.traderVaultId,
                    uint256(-vars.order.legs[i].amount),
                    0,
                    ""
                );
                IERC20(vars.oTokens[i]).approve(
                    vars.marginPoolAddress,
                    uint256(-vars.order.legs[i].amount)
                );
                actions3[vars.shortCounter] = IController.ActionArgs(
                    IController.ActionType.DepositLongOption,
                    msg.sender, // owner
                    address(this), // address to transfer from
                    address(vars.oTokens[i]), // option address
                    vars.poolVaultId, // vaultId
                    uint256(-vars.order.legs[i].amount), // amount
                    0, //index
                    "" //data
                );

                vars.shortCounter++;
            }
        }

        if (actions1.length > 0) vars.controller.operate(actions1);
        if (actions2.length > 0) vars.controller.operate(actions2);
        if (actions3.length > 0) vars.controller.operate(actions3);

        (int256 traderExposureCalls, int256 traderExposurePuts) = vars
            .controller
            .getVaultExposure(vars.traderAddress, vars.traderVaultId);
        (int256 poolExposureCalls, int256 poolExposurePuts) = vars
            .controller
            .getVaultExposure(msg.sender, vars.poolVaultId);

        // amount of shorts added (+) or removed (-) from trader
        int256 traderShortDiffCalls = Math.min(
            vars.traderExposureBeforeCalls,
            0
        ) - Math.min(traderExposureCalls, 0);
        int256 traderShortDiffPuts = Math.min(
            vars.traderExposureBeforePuts,
            0
        ) - Math.min(traderExposurePuts, 0);

        return (
            vars.oTokens,
            vars.totalFee,
            poolExposureCalls -
                vars.poolExposureBeforeCalls -
                traderShortDiffCalls,
            poolExposurePuts - vars.poolExposureBeforePuts - traderShortDiffPuts
        );
    }

    /// @notice Open a new margin vault for user
    /// @param _underlyingAsset Address of the underlying asset
    /// @param _collateralDepositAmount Amount of collateral to deposit into the vault
    /// @param _collateralAsset Address of the collateral asset (can be set to address(0) if deposit amount is 0)
    function openMarginVault(
        address _underlyingAsset,
        uint256 _collateralDepositAmount,
        address _collateralAsset
    ) external returns (uint256 vaultId) {
        require(
            _collateralDepositAmount == 0 || _collateralAsset != address(0),
            "!collateralAsset"
        );

        vaultId = _openMarginVault(msg.sender, _underlyingAsset);

        if (_collateralDepositAmount > 0) {
            IController controller = IController(addressBook.getController());

            IController.ActionArgs[]
                memory actions = new IController.ActionArgs[](1);
            actions[0] = IController.ActionArgs(
                IController.ActionType.DepositCollateral,
                msg.sender, // owner
                msg.sender, // address to transfer from
                address(_collateralAsset),
                vaultId,
                _collateralDepositAmount,
                0,
                ""
            );

            controller.operate(actions);
        }

        return vaultId;
    }

    function _openMarginVault(
        address _owner,
        address _underlyingAsset
    ) internal returns (uint256 vaultId) {
        IController controller = IController(addressBook.getController());
        vaultId = controller.getAccountVaultCounter(_owner) + 1;

        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );
        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            _owner,
            address(0),
            address(0),
            vaultId,
            0,
            0,
            ""
        );

        controller.operate(actions);

        marginVaults[_owner][_underlyingAsset].push(vaultId);

        emit MarginVaultOpened(_owner, _underlyingAsset, vaultId);

        return vaultId;
    }

    /// @notice Get margin vault ids for a user
    /// @param _owner Address of the user
    /// @param _underlyingAsset Address of the underlying asset
    /// @param _index Index of the margin vault
    /// @return vaultId The margin vault id (0 if it doesn't exist)
    function getMarginVaultId(
        address _owner,
        address _underlyingAsset,
        uint256 _index
    ) external view returns (uint256) {
        if (_index >= marginVaults[_owner][_underlyingAsset].length) {
            return 0;
        }
        return marginVaults[_owner][_underlyingAsset][_index];
    }

    function setAuthorizedPool(
        address _pool,
        bool _isAuthorized
    ) external onlyOwner {
        authorizedPools[_pool] = _isAuthorized;
        emit AuthorizedPoolSet(_pool, _isAuthorized);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';

pragma solidity 0.8.18;

interface CustomErrors {
    error AlreadyInitialized();
    error NotSettled();
    error InsufficientBalance();
    error ZeroValue();
    error NotEnoughLiquidity();
    error SeriesExpired();
    error InvalidPoolAddress();
    error InvalidFee();
    error Unauthorized();
    error InvalidArgument();
    error ExpiryNotSupported();
    error SeriesPerExpiryLimitExceeded();
    error StrikeTooHigh(uint256 maxStrike);
    error StrikeTooLow(uint256 minStrike);
    error StrikeInvalidIncrement();
    error InvalidUnderlying();
    error OrderNotSupported();
    error InvalidOrder();
    error InvalidPricePerShare();
    error NoAccessKey();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IAddressBookGamma} from "./IGamma.sol";

interface IAddressBook is IAddressBookGamma {
    event OpynAddressBookUpdated(address indexed newAddress);
    event LpManagerUpdated(address indexed newAddress);
    event OrderUtilUpdated(address indexed newAddress);
    event FeeCollectorUpdated(address indexed newAddress);
    event LensUpdated(address indexed newAddress);
    event TradeExecutorUpdated(address indexed newAddress);
    event PerennialMultiInvokerUpdated(address indexed newAddress);
    event PerennialLensUpdated(address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;

    function getAddress(bytes32 id) external view returns (address);

    function setOpynAddressBook(address opynAddressBookAddress) external;

    function setLpManager(address lpManagerlAddress) external;

    function setOrderUtil(address orderUtilAddress) external;

    function getOpynAddressBook() external view returns (address);

    function getLpManager() external view returns (address);

    function getOrderUtil() external view returns (address);

    function getFeeCollector() external view returns (address);

    function getLens() external view returns (address);

    function getTradeExecutor() external view returns (address);

    function getPerennialMultiInvoker() external view returns (address);

    function getPerennialLens() external view returns (address);

    function getAccessKey() external view returns (address);
}

pragma solidity 0.8.18;

interface IFeeCollector {
    function collectFee(
        address feeAsset,
        uint256 feeAmount,
        address referrer
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library GammaTypes {
    // vault is a struct of 6 arrays that describe a position a user has, a user can have multiple vaults.
    struct Vault {
        // addresses of oTokens
        address[] oTokens;
        // addresses of other ERC-20s a user has deposited as collateral in this vault
        address[] collateralAssets;
        // quantity of oTokens minted/written for each oToken address
        uint256[] shortAmounts;
        // quantity of oTokens owned and held in the vault for each oToken address
        uint256[] longAmounts;
        // quantity of ERC-20 deposited as collateral in the vault for each ERC-20 address in collateralAssets
        uint256[] collateralAmounts;
        // min strike in the vault
        uint256 minStrike;
        // max strike in the vault
        uint256 maxStrike;
        // min expiry in the vault
        uint256 minExpiry;
        // max expiry in the vault
        uint256 maxExpiry;
        // vault net notional exposure
        int256 netExposureCalls;
        int256 netExposurePuts;
    }
}

interface IAddressBookGamma {
    /* Getters */

    function getOtokenImpl() external view returns (address);

    function getOtokenFactory() external view returns (address);

    function getWhitelist() external view returns (address);

    function getController() external view returns (address);

    function getOracle() external view returns (address);

    function getMarginPool() external view returns (address);

    function getMarginCalculator() external view returns (address);

    function getLiquidationManager() external view returns (address);

    function getAddress(bytes32 _id) external view returns (address);

    function getAccessKey() external view returns (address);
}

interface IOtoken {
    function underlyingAsset() external view returns (address);

    function strikeAsset() external view returns (address);

    function collateralAsset() external view returns (address);

    function strikePrice() external view returns (uint256);

    function expiryTimestamp() external view returns (uint256);

    function isPut() external view returns (bool);
}

interface IOtokenFactory {
    function getOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    function createOtoken(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external returns (address);

    function getTargetOtokenAddress(
        address _underlyingAsset,
        address _strikeAsset,
        address _collateralAsset,
        uint256 _strikePrice,
        uint256 _expiry,
        bool _isPut
    ) external view returns (address);

    event OtokenCreated(
        address tokenAddress,
        address creator,
        address indexed underlying,
        address indexed strike,
        address indexed collateral,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut
    );
}

interface IController {
    // possible actions that can be performed
    enum ActionType {
        OpenVault,
        MintShortOption,
        BurnShortOption,
        DepositLongOption,
        WithdrawLongOption,
        DepositCollateral,
        WithdrawCollateral,
        SettleVault,
        Redeem,
        Call,
        Liquidate,
        MintShortOptionLazy,
        WithdrawLongOptionLazy
    }

    struct ActionArgs {
        // type of action that is being performed on the system
        ActionType actionType;
        // address of the account owner
        address owner;
        // address which we move assets from or to (depending on the action type)
        address secondAddress;
        // asset that is to be transfered
        address asset;
        // index of the vault that is to be modified (if any)
        uint256 vaultId;
        // amount of asset that is to be transfered
        uint256 amount;
        // each vault can hold multiple short / long / collateral assets
        // but we are restricting the scope to only 1 of each in this version
        // in future versions this would be the index of the short / long / collateral asset that needs to be modified
        uint256 index;
        // any other data that needs to be passed in for arbitrary function calls
        bytes data;
    }

    struct RedeemArgs {
        // address to which we pay out the oToken proceeds
        address receiver;
        // oToken that is to be redeemed
        address otoken;
        // amount of oTokens that is to be redeemed
        uint256 amount;
    }

    function getPayout(
        address _otoken,
        uint256 _amount
    ) external view returns (uint256);

    function operate(
        ActionArgs[] calldata _actions
    ) external returns (bool, uint256);

    function getAccountVaultCounter(
        address owner
    ) external view returns (uint256);

    function oracle() external view returns (address);

    function getVault(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory);

    function getVaultWithDetails(
        address _owner,
        uint256 _vaultId
    ) external view returns (GammaTypes.Vault memory, uint256);

    function getProceed(
        address _owner,
        uint256 _vaultId
    ) external view returns (uint256);

    function isSettlementAllowed(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _expiry
    ) external view returns (bool);

    function hasExpired(address _otoken) external view returns (bool);

    function setOperator(address _operator, bool _isOperator) external;

    function getOtokenIndex(
        address _owner,
        uint256 _vaultId,
        address _oToken
    ) external view returns (uint256);

    function getVaultExposure(
        address _owner,
        uint256 _vaultId
    ) external view returns (int256, int256);

    function isLiquidatable(
        address _owner,
        uint256 _vaultId
    ) external view returns (bool, uint256, uint256, uint256, uint256);
}

interface IMarginCalculator {
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256);

    function getExcessCollateral(
        GammaTypes.Vault calldata _vault
    ) external view returns (uint256 netValue, bool isExcess);

    function getLongLiquidationPrice(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _longAmount,
        uint256 _strikePrice,
        uint256 _longExpiryTimestamp,
        bool _isPut
    ) external view returns (uint256);

    function getShortLiquidationPrice(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _shortExpiryTimestamp,
        bool _isPut
    ) external view returns (uint256);

    struct FixedPointInt {
        int256 value;
    }

    function getMarginRequired(
        GammaTypes.Vault memory _vault
    ) external view returns (FixedPointInt memory, FixedPointInt memory);

    function setCollateralDust(address _collateral, uint256 _dust) external;
}

interface INakedMarginCalculator {
    function getNakedMarginRequired(
        address _underlying,
        address _strike,
        address _collateral,
        uint256 _shortAmount,
        uint256 _strikePrice,
        uint256 _underlyingPrice,
        uint256 _shortExpiryTimestamp,
        uint256 _collateralDecimals,
        bool _isPut
    ) external view returns (uint256);
}

interface IOracle {
    function isLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function isDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (bool);

    function getExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp
    ) external view returns (uint256, bool);

    function getDisputer() external view returns (address);

    function getPricer(address _asset) external view returns (address);

    function getPrice(address _asset) external view returns (uint256);

    function getPricerLockingPeriod(
        address _pricer
    ) external view returns (uint256);

    function getPricerDisputePeriod(
        address _pricer
    ) external view returns (uint256);

    function getChainlinkRoundData(
        address _asset,
        uint80 _roundId
    ) external view returns (uint256, uint256);

    // Non-view function

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external;
}

interface OpynPricerInterface {
    function getPrice() external view returns (uint256);

    function getHistoricalPrice(
        uint80 _roundId
    ) external view returns (uint256, uint256);
}

//  SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint amountIn;
        uint minOut;
        uint sizeDelta;
        bool isLong;
        uint acceptablePrice;
        uint executionFee;
        uint blockNumber;
        uint blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint collateralDelta;
        uint sizeDelta;
        bool isLong;
        address receiver;
        uint acceptablePrice;
        uint minOut;
        uint executionFee;
        uint blockNumber;
        uint blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function increasePositionRequests(
        bytes32 key
    )
        external
        view
        returns (
            address account,
            address[] memory,
            address,
            uint amountIn,
            uint,
            uint,
            bool,
            uint,
            uint,
            uint,
            uint,
            bool,
            address
        );

    function decreasePositionRequests(
        bytes32 key
    )
        external
        view
        returns (
            address account,
            address[] memory,
            address,
            uint,
            uint,
            bool,
            address,
            uint,
            uint,
            uint,
            uint,
            uint,
            bool,
            address
        );

    function vault() external view returns (address);

    function callbackGasLimit() external view returns (uint);

    function minExecutionFee() external view returns (uint);

    function increasePositionRequestKeysStart() external returns (uint);

    function decreasePositionRequestKeysStart() external returns (uint);

    function executeIncreasePositions(
        uint _count,
        address payable _executionFeeReceiver
    ) external;

    function executeDecreasePositions(
        uint _count,
        address payable _executionFeeReceiver
    ) external;

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint _amountIn,
        uint _minOut,
        uint _sizeDelta,
        bool _isLong,
        uint _acceptablePrice,
        uint _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint _collateralDelta,
        uint _sizeDelta,
        bool _isLong,
        address _receiver,
        uint _acceptablePrice,
        uint _minOut,
        uint _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address _executionFeeReceiver
    ) external returns (bool);

    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);
}

interface IVault {
    function PRICE_PRECISION() external view returns (uint);

    function FUNDING_RATE_PRECISION() external view returns (uint);

    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(
        address _account,
        address _router
    ) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(
        address _token
    ) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDG(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(
        address _token
    ) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(uint256 _sizeDelta) external view returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);
}

interface IRouter {
    function addPlugin(address _plugin) external;

    function pluginTransfer(
        address _token,
        address _account,
        address _receiver,
        uint _amount
    ) external;

    function pluginIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint _sizeDelta,
        bool _isLong
    ) external;

    function pluginDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint _collateralDelta,
        uint _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint);

    function swap(
        address[] memory _path,
        uint _amountIn,
        uint _minOut,
        address _receiver
    ) external;

    function approvePlugin(address _plugin) external;
}

interface IPositionRouterCallbackReceiver {
    function gmxPositionCallback(
        bytes32 positionKey,
        bool isExecuted,
        bool isIncrease
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IOrderUtils {
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
        Order.OrderType orderType;
        Order.DecreasePositionSwapType decreasePositionSwapType;
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

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be canceled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be canceled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be canceled if the position cannot be decreased at the acceptablePrice
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

    struct SetPricesParams {
        uint256 signerInfo;
        address[] tokens;
        uint256[] compactedMinOracleBlockNumbers;
        uint256[] compactedMaxOracleBlockNumbers;
        uint256[] compactedOracleTimestamps;
        uint256[] compactedDecimals;
        uint256[] compactedMinPrices;
        uint256[] compactedMinPricesIndexes;
        uint256[] compactedMaxPrices;
        uint256[] compactedMaxPricesIndexes;
        bytes[] signatures;
        address[] priceFeedTokens;
    }

    function executeOrder(
        bytes32 key,
        IOrderUtils.SetPricesParams calldata oracleParams
    ) external;
}

interface IExchangeRouter {
    function createOrder(
        IOrderUtils.CreateOrderParams calldata params
    ) external returns (bytes32);

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external;

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external;

    function router() external view returns (address);

    function dataStore() external view returns (IDataStore);

    function eventEmitter() external view returns (IEventEmitter);

    function orderHandler() external view returns (IOrderHandler);
}

interface IReader {
    function getPosition(
        IDataStore dataStore,
        bytes32 key
    ) external view returns (Position.Props memory);

    function getAccountPositions(
        IDataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (Position.Props[] memory);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function getOrder(
        address dataStore,
        bytes32 key
    ) external view returns (Order.Props memory);

    function getMarket(
        address dataStore,
        address key
    ) external view returns (address, address, address, address);

    function getPositionPnlUsd(
        IDataStore dataStore,
        Market.Props memory market,
        MarketUtils.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);
}

// https://docs.gmx.io/docs/api/contracts-v2
interface IDataStore {

}

// borrowing fees for position require only a borrowingFactor to track
// an example on how this works is if the global cumulativeBorrowingFactor is 10020%
// a position would be opened with borrowingFactor as 10020%
// after some time, if the cumulativeBorrowingFactor is updated to 10025% the position would
// owe 5% of the position size as borrowing fees
// the total pending borrowing fees of all positions is factored into the calculation of the pool value for LPs
// when a position is increased or decreased, the pending borrowing fees for the position is deducted from the position's
// collateral and transferred into the LP pool
//
// the same borrowing fee factor tracking cannot be applied for funding fees as those calculations consider pending funding fees
// based on the fiat value of the position sizes
//
// for example, if the price of the longToken is $2000 and a long position owes $200 in funding fees, the opposing short position
// claims the funding fees of 0.1 longToken ($200), if the price of the longToken changes to $4000 later, the long position would
// only owe 0.05 longToken ($200)
// this would result in differences between the amounts deducted and amounts paid out, for this reason, the actual token amounts
// to be deducted and to be paid out need to be tracked instead
//
// for funding fees, there are four values to consider:
// 1. long positions with market.longToken as collateral
// 2. long positions with market.shortToken as collateral
// 3. short positions with market.longToken as collateral
// 4. short positions with market.shortToken as collateral
library Position {
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

    function market(Props memory props) internal pure returns (address) {
        return props.addresses.market;
    }

    function collateralToken(
        Props memory props
    ) internal pure returns (address) {
        return props.addresses.collateralToken;
    }

    function sizeInUsd(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeInUsd;
    }

    function sizeInTokens(Props memory props) internal pure returns (uint256) {
        return props.numbers.sizeInTokens;
    }

    function collateralAmount(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.collateralAmount;
    }

    function borrowingFactor(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.borrowingFactor;
    }

    function fundingFeeAmountPerSize(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.fundingFeeAmountPerSize;
    }

    function longTokenClaimableFundingAmountPerSize(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.longTokenClaimableFundingAmountPerSize;
    }

    function shortTokenClaimableFundingAmountPerSize(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.shortTokenClaimableFundingAmountPerSize;
    }

    function increasedAtBlock(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.increasedAtBlock;
    }

    function decreasedAtBlock(
        Props memory props
    ) internal pure returns (uint256) {
        return props.numbers.decreasedAtBlock;
    }

    function isLong(Props memory props) internal pure returns (bool) {
        return props.flags.isLong;
    }
}

library Order {
    using Order for Props;

    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be canceled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be canceled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be canceled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    // to help further differentiate orders
    enum SecondaryOrderType {
        None,
        Adl
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

library Market {
    // @param marketToken address of the market token for the market
    // @param indexToken address of the index token for the market
    // @param longToken address of the long token for the market
    // @param shortToken address of the short token for the market
    // @param data for any additional data
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

library ReaderUtils {
    struct BaseFundingValues {
        MarketUtils.PositionType fundingFeeAmountPerSize;
        MarketUtils.PositionType claimableFundingAmountPerSize;
    }
}

library GasUtils {
    // function adjustGasLimitForEstimate(IDataStore dataStore, uint256 estimatedGasLimit) internal view returns (uint256);
    // function estimateExecuteOrderGasLimit(IDataStore dataStore, Order.Props memory order) internal view returns (uint256);
}

library MarketUtils {
    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    // @dev struct to store the prices of tokens of a market
    // @param indexTokenPrice price of the market's index token
    // @param longTokenPrice price of the market's long token
    // @param shortTokenPrice price of the market's short token
    struct MarketPrices {
        Price.Props indexTokenPrice;
        Price.Props longTokenPrice;
        Price.Props shortTokenPrice;
    }

    // @dev struct for the result of the getNextFundingAmountPerSize call
    // @param longsPayShorts whether longs pay shorts or shorts pay longs
    // @param fundingFeeAmountPerSizeDelta funding fee amount per size delta values
    // @param claimableFundingAmountPerSize claimable funding per size delta values
    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct GetNextFundingAmountPerSizeCache {
        PositionType openInterest;
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 durationInSeconds;
        uint256 diffUsd;
        uint256 totalOpenInterest;
        uint256 sizeOfLargerSide;
        uint256 fundingUsd;
        uint256 fundingUsdForLongCollateral;
        uint256 fundingUsdForShortCollateral;
    }

    struct GetExpectedMinTokenBalanceCache {
        uint256 poolAmount;
        uint256 swapImpactPoolAmount;
        uint256 claimableCollateralAmount;
        uint256 claimableFeeAmount;
        uint256 claimableUiFeeAmount;
        uint256 affiliateRewardAmount;
    }
}

library PositionUtils {
    // @dev UpdatePositionParams struct used in increasePosition and decreasePosition
    // to avoid stack too deep errors
    //
    // @param contracts BaseOrderUtils.ExecuteOrderParamsContracts
    // @param market the values of the trading market
    // @param order the decrease position order
    // @param orderKey the key of the order
    // @param position the order's position
    // @param positionKey the key of the order's position
    struct UpdatePositionParams {
        BaseOrderUtils.ExecuteOrderParamsContracts contracts;
        Market.Props market;
        Order.Props order;
        bytes32 orderKey;
        Position.Props position;
        bytes32 positionKey;
        Order.SecondaryOrderType secondaryOrderType;
    }
}

library BaseOrderUtils {
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
        Order.OrderType orderType;
        Order.DecreasePositionSwapType decreasePositionSwapType;
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

    // @dev ExecuteOrderParams struct used in executeOrder to avoid stack
    // too deep errors
    //
    // @param contracts ExecuteOrderParamsContracts
    // @param key the key of the order to execute
    // @param order the order to execute
    // @param swapPathMarkets the market values of the markets in the swapPath
    // @param minOracleBlockNumbers the min oracle block numbers
    // @param maxOracleBlockNumbers the max oracle block numbers
    // @param market market values of the trading market
    // @param keeper the keeper sending the transaction
    // @param startingGas the starting gas
    // @param secondaryOrderType the secondary order type
    struct ExecuteOrderParams {
        ExecuteOrderParamsContracts contracts;
        bytes32 key;
        Order.Props order;
        Market.Props[] swapPathMarkets;
        uint256[] minOracleBlockNumbers;
        uint256[] maxOracleBlockNumbers;
        Market.Props market;
        address keeper;
        uint256 startingGas;
        Order.SecondaryOrderType secondaryOrderType;
    }

    // @param dataStore IDataStore
    // @param eventEmitter EventEmitter
    // @param orderVault OrderVault
    // @param oracle Oracle
    // @param swapHandler SwapHandler
    // @param referralStorage IReferralStorage
    struct ExecuteOrderParamsContracts {
        IDataStore dataStore;
        IEventEmitter eventEmitter;
        IOrderVault orderVault;
        IGmxOracle oracle;
        ISwapHandler swapHandler;
        IReferralStorage referralStorage;
    }
}

library Price {
    // @param min the min price
    // @param max the max price
    struct Props {
        uint256 min;
        uint256 max;
    }

    // @dev check if a price is empty
    // @param props Props
    // @return whether a price is empty
    function isEmpty(Props memory props) internal pure returns (bool) {
        return props.min == 0 || props.max == 0;
    }

    // @dev get the average of the min and max values
    // @param props Props
    // @return the average of the min and max values
    function midPrice(Props memory props) internal pure returns (uint256) {
        return (props.max + props.min) / 2;
    }

    // @dev pick either the min or max value
    // @param props Props
    // @param maximize whether to pick the min or max value
    // @return either the min or max value
    function pickPrice(
        Props memory props,
        bool maximize
    ) internal pure returns (uint256) {
        return maximize ? props.max : props.min;
    }

    // @dev pick the min or max price depending on whether it is for a long or short position
    // and whether the pending pnl should be maximized or not
    // @param props Props
    // @param isLong whether it is for a long or short position
    // @param maximize whether the pnl should be maximized or not
    // @return the min or max price
    function pickPriceForPnl(
        Props memory props,
        bool isLong,
        bool maximize
    ) internal pure returns (uint256) {
        // for long positions, pick the larger price to maximize pnl
        // for short positions, pick the smaller price to maximize pnl
        if (isLong) {
            return maximize ? props.max : props.min;
        }

        return maximize ? props.min : props.max;
    }
}

interface IGmxUtils {
    function getExecutionPrice(
        PositionUtils.UpdatePositionParams memory params,
        Price.Props memory indexTokenPrice
    ) external view returns (int256, int256, uint256, uint256);

    function getPriceFeedPrice(
        address dataStore,
        address token
    ) external view returns (bool, uint256);
}

interface IEventEmitter {}

interface IGmxOracle {
    function getStablePrice(
        address dataStore,
        address token
    ) external view returns (uint256);
}

interface ISwapHandler {}

interface IReferralStorage {}

interface IOrderVault {}

interface IOrderHandler {
    function orderVault() external view returns (IOrderVault);

    function swapHandler() external view returns (ISwapHandler);

    function oracle() external view returns (IGmxOracle);

    function referralStorage() external view returns (IReferralStorage);
}

interface IMarketToken {
    function decimals() external view returns (uint8);
}

interface IOrderCallbackReceiver {
    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) external;

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) external;

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(
        bytes32 key,
        Order.Props memory order,
        EventUtils.EventLogData memory eventData
    ) external;
}

library EventUtils {
    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }
    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }
    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }
    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IOrderUtil.sol";
import {IAddressBook} from "./IAddressBook.sol";

interface IHedgedPool {
    function addressBook() external view returns (IAddressBook);

    function getCollateralBalance() external view returns (uint256);

    function strikeToken() external view returns (IERC20);

    function collateralToken() external view returns (IERC20);

    function getAllUnderlyings() external view returns (address[] memory);

    function getActiveOTokens() external view returns (address[] memory);

    function hedgers(address underlying) external view returns (address);

    function trade(
        IOrderUtil.Order calldata order,
        uint256 traderDeposit,
        uint256 traderVaultId,
        bool autoCreateVault
    ) external;

    function keepers(address keeper) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface IHedger {
    function sync() external returns (int256 collateralDiff);

    function getDelta() external view returns (int256);

    function getCollateralValue() external returns (uint256);

    function getRequiredCollateral() external returns (int256);

    function hedgerType() external pure returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "./IOrderUtil.sol";

interface ILiquidator {
    function liquidateShort(
        uint256 vaultId,
        address vaultOwner,
        IOrderUtil.Order calldata order
    ) external;

    function liquidateLong(
        uint256 vaultId,
        address vaultOwner,
        IOrderUtil.Order calldata order
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

interface ILpManager {
    function depositRoundId(
        address poolAddress
    ) external view returns (uint256);

    function withdrawalRoundId(
        address poolAddress
    ) external view returns (uint256);

    function getCashLocked(
        address poolAddress,
        bool includePendingWithdrawals
    ) external view returns (uint256);

    function getUnfilledShares(
        address poolAddress
    ) external view returns (uint256);

    function getWithdrawalStatus(
        address poolAddress,
        address lpAddress
    )
        external
        view
        returns (
            uint256 sharesRedeemable,
            uint256 sharesOutstanding,
            uint256 cashRedeemable
        );

    function getDepositStatus(
        address poolAddress,
        address lpAddress
    ) external view returns (uint256 cashPending, uint256 sharesRedeemable);

    function closeWithdrawalRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesRemoved);

    function closeDepositRound(
        uint256 pricePerShare
    ) external returns (uint256 sharesAdded);

    function addPendingCash(uint256 cashAmount) external;

    function addPricedCash(uint256 cashAmount, uint256 shareAmount) external;

    function requestWithdrawal(
        address lpAddress,
        uint256 sharesAmount
    ) external;

    function requestDeposit(address lpAddress, uint256 cashAmount) external;

    function redeemShares(address lpAddress) external returns (uint256);

    function withdrawCash(
        address lpAddress
    ) external returns (uint256, uint256);

    function cancelPendingDeposit(address lpAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IOrderUtil {
    struct Order {
        address poolAddress;
        address underlying;
        address referrer;
        uint256 validUntil;
        uint256 nonce;
        OptionLeg[] legs;
        Signature signature;
        Signature[] coSignatures;
    }

    struct OptionLeg {
        uint256 strike;
        uint256 expiration;
        bool isPut;
        int256 amount;
        int256 premium;
        uint256 fee;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event Cancel(uint256 indexed nonce, address indexed signerWallet);

    event CancelUpTo(uint256 indexed nonce, address indexed signerWallet);

    error InvalidAdapters();
    error OrderExpired();
    error NonceTooLow();
    error NonceAlreadyUsed(uint256);
    error SenderInvalid();
    error SignatureInvalid();
    error SignerInvalid();
    error TokenKindUnknown();
    error Unauthorized();

    /**
     * @notice Validates order and returns its signatory
     * @param order Order
     */
    function processOrder(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);

    /**
     * @notice Cancel one or more open orders by nonce
     * @param nonces uint256[]
     */
    function cancel(uint256[] calldata nonces) external;

    /**
     * @notice Cancels all orders below a nonce value
     * @dev These orders can be made active by reducing the minimum nonce
     * @param minimumNonce uint256
     */
    function cancelUpTo(uint256 minimumNonce) external;

    function nonceUsed(address, uint256) external view returns (bool);

    function getSigners(
        Order calldata order
    ) external returns (address signer, address[] memory coSigners);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../interfaces/IOrderUtil.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITradeExecutor {
    function marginVaults(
        address owner,
        address underlying,
        uint256 index
    ) external view returns (uint256);

    function executeTrade(
        IOrderUtil.Order calldata order,
        uint256 poolVaultId,
        address traderAddress,
        uint256 traderDeposit,
        uint256 traderVaultId,
        bool autoCreateVault
    ) external returns (address[] memory, uint256, int256, int256);

    function openMarginVault(
        address _underlyingAsset,
        uint256 _collateralDepositAmount,
        address _collateralAsset
    ) external returns (uint256 vaultId);

    function getMarginVaultId(
        address _owner,
        address _underlyingAsset,
        uint256 _index
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IUniSwapV3Pool {
    function flash(
        address recipient,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "./Math.sol";

// a library for performing various date operations
library Dates {
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    int constant OFFSET19700101 = 2440588;

    // Credit: https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary/blob/master/contracts/BokkyPooBahsDateTimeLibrary.sol
    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(
        uint _days
    ) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int _month = (80 * L) / 2447;
        int _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    /// @notice Returns the given timestamp date, but aligned to the prior 8am UTC dateOffset in the past
    /// unless the timestamp is exactly 8am UTC, in which case it will return the same
    /// value as the timestamp. If _dateOffset is 1 day then this function
    /// will align on every day at 8am, and if its 1 week it will align on every Friday 8am UTC
    /// @param _timestamp a block time (seconds past epoch)
    /// @return the block time of the prior (or current) 8am UTC date, dateOffset in the past
    function get8amAligned(
        uint256 _timestamp,
        uint256 _dateOffset
    ) internal pure returns (uint256) {
        require(
            _dateOffset == 1 weeks || _dateOffset == 1 days,
            "Invalid dateOffset"
        );

        uint256 numOffsetsSinceEpochStart = _timestamp / _dateOffset;

        // this will get us the timestamp of the Thursday midnight date prior to _timestamp if
        // dateOffset equals 1 week, or it will get us the timestamp of midnight of the previous
        // day if dateOffset equals 1 day. We rely on Solidity's integral rounding in the line above
        uint256 timestampRoundedDown = numOffsetsSinceEpochStart * _dateOffset;

        if (_dateOffset == 1 days) {
            uint256 eightHoursAligned = timestampRoundedDown + 8 hours;
            if (eightHoursAligned > _timestamp) {
                return eightHoursAligned - 1 days;
            } else {
                return eightHoursAligned;
            }
        } else {
            uint256 fridayEightHoursAligned = timestampRoundedDown +
                (1 days + 8 hours);
            if (fridayEightHoursAligned > _timestamp) {
                return fridayEightHoursAligned - 1 weeks;
            } else {
                return fridayEightHoursAligned;
            }
        }
    }

    /// @notice Check whether an expiration date is within the weekly, monthly and quarterly allowed expirations
    /// @param _now current timestamp
    /// @param _expiry date being validated
    /// @param _numMonths include last Friday of up to _numMonths in the future (1 includes end of the current months)
    /// @param _numQuarters include last Friday of up to _numQuarters in the future (0 - no quarterly, 1 includes the current quarter)
    function isValidExpiry(
        uint256 _now,
        uint256 _expiry,
        uint8 _numMonths,
        uint8 _numQuarters,
        bool allowDailyExpiration
    ) internal pure returns (bool) {
        // check the date is in the future
        if (_expiry < _now) return false;

        if (_expiry - _now < 86400) {
            if (
                allowDailyExpiration &&
                _expiry == get8amAligned(_expiry, 1 days)
            ) return true;
        }
        // check the date is Friday 8am UTC
        if (_expiry != get8amAligned(_expiry, 1 weeks)) return false;

        // check 2 weeklys
        if (_expiry - _now <= 1209600) return true;

        // check last friday of month
        (uint expiryYear, uint expiryMonth, ) = _daysToDate(
            _expiry / SECONDS_PER_DAY
        );
        (, uint nextWeekMonthExpiry, ) = _daysToDate(
            (_expiry + 1 weeks) / SECONDS_PER_DAY
        );

        // not last friday
        if (expiryMonth == nextWeekMonthExpiry) return false;

        (uint currentYear, uint currentMonth, ) = _daysToDate(
            _now / SECONDS_PER_DAY
        );

        // prevent underflow
        if (expiryYear > currentYear)
            expiryMonth += 12 * (expiryYear - currentYear);

        // if current date is after the last friday of the month, increment current month
        uint prevFriday = get8amAligned(_now, 1 weeks);
        (, uint nextWeekMonthCurrent, ) = _daysToDate(
            (prevFriday + 1 weeks) / SECONDS_PER_DAY
        );
        if (nextWeekMonthCurrent != currentMonth) {
            currentMonth += 1;
            if (currentMonth > 12) currentYear += 1;
        }

        // check quarterlys (dec, mar, jun, sep)
        if (
            (expiryMonth % 3 == 0) &&
            ((expiryMonth - currentMonth) / 3 + 1 <= _numQuarters)
        ) return true;

        // check monthlys
        if (expiryMonth - currentMonth + 1 <= _numMonths) return true;

        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

// a library for performing various math operations

library Math {
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) return a;
        return b;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    function abs(int256 x) internal pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        if (a < b) return a;
        return b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        if (a > b) return a;
        return b;
    }
}

// SPDX-License-Identifier: None

pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IOtoken, IOracle, GammaTypes, IController, IOtokenFactory, IMarginCalculator} from "../interfaces/IGamma.sol";
import "../libs/Math.sol";

library OpynLib {
    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    /// @notice Settle Vault post-expiration
    function settle(
        address controller,
        uint256 vaultId
    ) external returns (bool, uint256) {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.SettleVault,
            address(this), // owner
            address(this), // address to transfer to
            address(0), // not used
            vaultId, // vaultId
            0, // not used
            0, // not used
            "" // not used
        );

        return IController(controller).operate(actions);
    }

    /// @notice Redeem expired long option
    function redeem(
        address controller,
        address oToken,
        uint256 amount
    ) external {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.Redeem,
            address(0), // not used
            address(this), // address to send profits to
            oToken, // address of otoken
            0, // not used
            amount, // otoken balance
            0, // not used
            "" // not used
        );
        IController(controller).operate(actions);
    }

    /// @notice open margin vault
    function openVault(address controller) external returns (uint256 vaultId) {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        vaultId =
            (IController(controller).getAccountVaultCounter(address(this))) +
            1;

        actions[0] = IController.ActionArgs(
            IController.ActionType.OpenVault,
            address(this), // owner
            address(this), // receiver
            address(0), // asset, otoken
            vaultId, // vaultId
            0, // amount
            0, //index
            "" //data
        );

        IController(controller).operate(actions);

        return vaultId;
    }

    /// @notice add short position to a vault
    function createShort(
        address controller,
        uint256 vaultId,
        address oToken,
        uint256 oTokenIndex,
        uint256 amount,
        address collateralAsset,
        uint256 depositAmount
    ) external returns (bool, uint256) {
        IController.ActionArgs[] memory actions;
        if (depositAmount == 0) {
            // no collateral to deposit
            actions = new IController.ActionArgs[](1);

            actions[0] = IController.ActionArgs(
                IController.ActionType.MintShortOption,
                address(this), // owner
                address(this), // address to transfer to
                oToken, // option address
                vaultId, // vaultId
                amount, // amount
                oTokenIndex, //index
                "" //data
            );
        } else {
            actions = new IController.ActionArgs[](2);

            actions[0] = IController.ActionArgs(
                IController.ActionType.DepositCollateral,
                address(this), // owner
                address(this), // address to transfer from
                collateralAsset, // deposited asset
                vaultId, // vaultId
                depositAmount, // amount
                0, //index
                "" //data
            );

            actions[1] = IController.ActionArgs(
                IController.ActionType.MintShortOption,
                address(this), // owner
                address(this), // address to transfer to
                oToken, // option address
                vaultId, // vaultId
                amount, // amount
                oTokenIndex, //index
                "" //data
            );
        }

        return IController(controller).operate(actions);
    }

    /// @notice Withdraw collateral from vault
    function withdrawCollateral(
        address controller,
        uint256 vaultId,
        address collateralAsset,
        uint256 withdrawalAmount
    ) public returns (bool, uint256) {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            collateralAsset, // withdrawn asset
            vaultId, // vaultId
            withdrawalAmount, // amount
            0, //index
            "" //data
        );

        return IController(controller).operate(actions);
    }

    /// @notice Deposit collateral into vault
    function depositCollateral(
        address controller,
        uint256 vaultId,
        address collateralAsset,
        uint256 depositAmount
    ) public returns (bool, uint256) {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        actions[0] = IController.ActionArgs(
            IController.ActionType.DepositCollateral,
            address(this), // owner
            address(this), // address to transfer from
            collateralAsset, // deposited asset
            vaultId, // vaultId
            depositAmount, // amount
            0, //index
            "" //data
        );

        return IController(controller).operate(actions);
    }

    /// @notice deposit long into the vault
    function depositLong(
        address controller,
        address marginPool,
        uint256 vaultId,
        address oToken,
        uint256 oTokenIndex,
        uint256 amount
    ) external returns (bool, uint256) {
        IController.ActionArgs[] memory actions = new IController.ActionArgs[](
            1
        );

        // approve oToken to be transferred
        IERC20(oToken).approve(marginPool, amount);

        actions[0] = IController.ActionArgs(
            IController.ActionType.DepositLongOption,
            address(this), // owner
            address(this), // address to transfer from
            oToken, // option address
            vaultId, // vaultId
            amount, // amount
            oTokenIndex, //index
            "" //data
        );

        return IController(controller).operate(actions);
    }

    /// @notice withdraw long from the vault
    function withdrawLong(
        address controller,
        uint256 vaultId,
        address oToken,
        uint256 oTokenIndex,
        uint256 amount,
        address collateralAsset,
        uint256 depositAmount
    ) internal returns (bool, uint256) {
        IController.ActionArgs[] memory actions;
        if (depositAmount == 0) {
            // no collateral to deposit
            actions = new IController.ActionArgs[](1);

            actions[0] = IController.ActionArgs(
                IController.ActionType.WithdrawLongOption,
                address(this), // owner
                address(this), // address to transfer to
                oToken, // option address
                vaultId, // vaultId
                amount, // amount
                oTokenIndex, //index
                "" //data
            );
        } else {
            // deposit collateral to match margin shortfall
            actions = new IController.ActionArgs[](2);

            actions[0] = IController.ActionArgs(
                IController.ActionType.DepositCollateral,
                address(this), // owner
                address(this), // address to transfer from
                collateralAsset, // deposited asset
                vaultId, // vaultId
                depositAmount, // amount
                0, //index
                "" //data
            );

            actions[1] = IController.ActionArgs(
                IController.ActionType.WithdrawLongOption,
                address(this), // owner
                address(this), // address to transfer to
                oToken, // option address
                vaultId, // vaultId
                amount, // amount
                oTokenIndex, //index
                "" //data
            );
        }

        return IController(controller).operate(actions);
    }

    /// @notice find oToken or create it if doesn't exist
    function findOrCreateOToken(
        address factory,
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiry,
        bool isPut,
        bool mustExist
    ) external returns (address oToken) {
        oToken = IOtokenFactory(factory).getOtoken(
            underlyingAsset,
            strikeAsset,
            collateralAsset,
            strikePrice,
            expiry,
            isPut
        );

        if (oToken == address(0)) {
            require(!mustExist, "oToken doesn't exist");

            oToken = IOtokenFactory(factory).createOtoken(
                underlyingAsset,
                strikeAsset,
                collateralAsset,
                strikePrice,
                expiry,
                isPut
            );
        }

        return oToken;
    }

    enum MARGIN_UPDATE_TYPE {
        EXCESS,
        SHORTFALL,
        ALL
    }

    function syncVaultMargin(
        address controller,
        address marginCalculator,
        address collateralToken,
        uint256 vaultId,
        MARGIN_UPDATE_TYPE updateType,
        uint256 availableCollateral,
        uint256 maxHealthPercent,
        uint256 minHealthPercent
    ) external returns (int256 collateralChange) {
        GammaTypes.Vault memory vault = IController(controller).getVault(
            address(this),
            vaultId
        );

        // vault is empty, skip
        if (vault.collateralAmounts.length == 0) return 0;

        (uint256 netValue, bool isExcess) = IMarginCalculator(marginCalculator)
            .getExcessCollateral(vault);

        // keep 10%-15% of collateral as buffer
        if (
            isExcess &&
            netValue > (vault.collateralAmounts[0] * maxHealthPercent) / 100
        ) {
            // excess, withdraw collateral
            if (
                updateType == MARGIN_UPDATE_TYPE.EXCESS ||
                updateType == MARGIN_UPDATE_TYPE.ALL
            ) {
                // if all collateral is excess - withdraw all,
                // otherwise withdraw excess of 15%
                uint256 withdrawAmount = netValue == vault.collateralAmounts[0]
                    ? vault.collateralAmounts[0]
                    : netValue -
                        ((vault.collateralAmounts[0] * maxHealthPercent) / 100);

                withdrawCollateral(
                    controller,
                    vaultId,
                    collateralToken,
                    withdrawAmount
                );

                collateralChange += int256(withdrawAmount);
            }
        } else if (
            (isExcess &&
                netValue <
                (vault.collateralAmounts[0] * minHealthPercent) / 100) ||
            (!isExcess && netValue > 0)
        ) {
            // shortfall, deposit collateral
            if (
                updateType == MARGIN_UPDATE_TYPE.SHORTFALL ||
                updateType == MARGIN_UPDATE_TYPE.ALL
            ) {
                // deposit to target 15% excess collateral
                uint256 depositAmount = isExcess
                    ? (vault.collateralAmounts[0] * maxHealthPercent) /
                        100 -
                        netValue
                    : (vault.collateralAmounts[0] * maxHealthPercent) /
                        100 +
                        netValue;

                // limit deposit amount by collateral balance
                depositAmount = Math.min(depositAmount, availableCollateral);

                depositCollateral(
                    controller,
                    vaultId,
                    collateralToken,
                    depositAmount
                );
                collateralChange -= int256(netValue);
            }
        }
    }
}

// SPDX-License-Identifier: None

pragma solidity >=0.8.18;

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "hardhat/console.sol";

library UniSwapLib {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    function computeAddress(
        address factory,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    // @return amountIn The amount of DAI actually spent in the swap.
    function swapExactOutputSingle(
        uint256 amountOut,
        uint256 amountInMaximum,
        address tokenIn,
        address tokenOut,
        address swapAddress
    ) external returns (uint256 amountIn) {
        // Approve the router to spend the specifed `amountInMaximum` of DAI.
        // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
        TransferHelper.safeApprove(tokenIn, swapAddress, amountInMaximum);
        console.logAddress(address(this));
        ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
            .ExactOutputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 100,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
        amountIn = ISwapRouter(swapAddress).exactOutputSingle(params);

        // For exact output swaps, the amountInMaximum may not have all been spent.
        // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
        if (amountIn < amountInMaximum) {
            TransferHelper.safeApprove(tokenIn, swapAddress, 0);
        }
    }
}

// SPDX-License-Identifier: None

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IAddressBook.sol";
import {IMarginCalculator, IController, IOtokenFactory, IOracle, IOtoken} from "../interfaces/IGamma.sol";
import {IOrderUtil} from "../interfaces/IOrderUtil.sol";
import {IHedgedPool} from "../interfaces/IHedgedPool.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/ILiquidator.sol";

// Change this contract to a portfolio manager
contract Liquidator is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155Holder,
    ILiquidator
{
    /// Use safe ERC20 functions for any token transfers since people don't follow the ERC20 standard */
    using SafeERC20 for IERC20;

    IAddressBook public addressBook;
    IHedgedPool public hedgedPool;
    IMarginCalculator public marginCalculator;

    event AuthorizedPoolSet(address indexed pool, bool isAuthorized);

    uint256 constant OTOKEN_AMOUNT = 1e8;
    uint256 constant OTOKEN_DECIMALS = 1e8;

    // TODO: maybe add flash loans onto another contract?
    function __Liqudatior_init(
        address _addressBookAddress,
        address _hedgedPool
    ) public initializer {
        hedgedPool = IHedgedPool(_hedgedPool);
        addressBook = IAddressBook(_addressBookAddress);
        marginCalculator = IMarginCalculator(addressBook.getMarginCalculator());
        address tradeExecutor = addressBook.getTradeExecutor();

        IController(addressBook.getController()).setOperator(
            tradeExecutor,
            true
        );

        __Ownable_init();
    }

    /// Initialize the contract, and create an lpToken to track ownership
    function setAddressBook(address _addresBookAddress) external onlyOwner {
        addressBook = IAddressBook(_addresBookAddress);
    }

    modifier onlyAuthorized() {
        require(
            IHedgedPool(hedgedPool).keepers(msg.sender) ||
                msg.sender == owner(),
            "!authorized"
        );
        _;
    }

    /// @notice liquidates a short postion that is undercollateralized
    /// @dev   1. Perform a trade to aquire a long otoken
    ///           b. Now get the new tokenAmount we need to liquidate( this needs to happen if we are performing a liquidation on the pool)
    ///        2. Withdraw the long otoken from the pool
    ///        3. Perform liuidation on the vault using the otoken
    ///        4. Transfer the balance of the vault to the msg sender
    /// @param vaultId id of the vault we are liquidating
    /// @param vaultOwner owner of vault we are liquidating
    /// @param order Order struct containing order parameters
    function liquidateShort(
        uint256 vaultId,
        address vaultOwner,
        IOrderUtil.Order calldata order
    ) external onlyAuthorized {
        require(order.legs.length == 1, "Order must have only one leg");
        require(order.legs[0].amount > 0, "Order must be a buy");

        // TraderDeposit = premium + fee
        uint256 traderDeposit = uint256(order.legs[0].premium) +
            order.legs[0].fee;

        address collateralAsset = address(
            IHedgedPool(order.poolAddress).collateralToken()
        );

        uint256 liquidateAmount = uint256(order.legs[0].amount);

        // Transfer funds from user to liquidation vault
        IERC20(collateralAsset).safeTransferFrom(
            msg.sender,
            address(this),
            traderDeposit
        );

        // First get the marginvault for the liqudation vault
        uint256 liquidatorVaultId = ITradeExecutor(
            addressBook.getTradeExecutor()
        ).getMarginVaultId(address(this), order.underlying, 0);

        if (liquidatorVaultId == 0) {
            liquidatorVaultId = openMarginVaultSelf(order.underlying);
        }

        IERC20(collateralAsset).approve(order.poolAddress, traderDeposit);

        // Buy otoken from pool
        IHedgedPool(order.poolAddress).trade(
            order,
            traderDeposit,
            liquidatorVaultId,
            false
        );

        address otoken = IOtokenFactory(addressBook.getOtokenFactory())
            .getOtoken(
                order.underlying,
                address(IHedgedPool(order.poolAddress).strikeToken()),
                collateralAsset,
                order.legs[0].strike,
                order.legs[0].expiration,
                order.legs[0].isPut
            );

        IController.ActionArgs[]
            memory liquidateAction = new IController.ActionArgs[](2);

        // Second Withdrawl collateral to liquidator contract address
        liquidateAction[0] = IController.ActionArgs(
            IController.ActionType.WithdrawLongOption,
            address(this), // owner
            address(this), // address to transfer from
            otoken,
            liquidatorVaultId,
            uint256(order.legs[0].amount),
            0,
            ""
        );
        liquidateAction[1] = IController.ActionArgs(
            IController.ActionType.Liquidate,
            vaultOwner, // owner
            address(this), // address to transfer from
            otoken,
            vaultId,
            liquidateAmount,
            0,
            ""
        );

        IController(addressBook.getController()).operate(liquidateAction);

        //Require that the collateral is more or equal than the trader deposit
        require(
            traderDeposit <= IERC20(collateralAsset).balanceOf(address(this)),
            "Trader deposit must be less than the collateral balance in margin vault"
        );

        //balance of the contract is sent back to the user
        IERC20(collateralAsset).safeTransfer(
            msg.sender,
            IERC20(collateralAsset).balanceOf(address(this))
        );
    }

    /// @notice liquidates a long postion of a vault that is undercollateralized
    /// @dev   1. Perform liuidation on the vault using the otoken
    ///        2. Deposit Long OToken into vault
    ///        3. Perform Trade to sell otoken to the pool
    ///        4. Withdrawl collateral to the contract from vault
    ///        5. Transfer the balance of the vault to the msg sender
    /// @param vaultId id of the vault we are liquidating
    /// @param vaultOwner owner of vault we are liquidating
    /// @param order Order struct containing order parameters
    function liquidateLong(
        uint256 vaultId, // vault to be liquidted
        address vaultOwner, // vault owner of liqudiating vault
        IOrderUtil.Order calldata order
    ) external onlyAuthorized {
        // Require the order has only one leg and the leg amount is < 0 then it means its a buy
        require(order.legs.length == 1, "Order must have only one leg");
        require(order.legs[0].amount < 0, "Order must be a sell");

        uint256 expiryTimeStamp = order.legs[0].expiration;
        address collateralAsset = address(
            IHedgedPool(order.poolAddress).collateralToken()
        );

        uint256 amount = uint256(order.legs[0].amount * -1);

        // This is the traders deposit
        uint256 traderDeposit = IMarginCalculator(
            addressBook.getMarginCalculator()
        ).getLongLiquidationPrice(
                order.underlying,
                address(IHedgedPool(order.poolAddress).strikeToken()),
                collateralAsset,
                amount,
                order.legs[0].strike,
                expiryTimeStamp,
                order.legs[0].isPut
            );

        uint256 liquidatorVaultId = ITradeExecutor(
            addressBook.getTradeExecutor()
        ).getMarginVaultId(msg.sender, order.underlying, 0);

        if (liquidatorVaultId == 0) {
            liquidatorVaultId = openMarginVaultSelf(order.underlying);
        }

        // Transfer funds from user to liquidation vault
        IERC20(collateralAsset).safeTransferFrom(
            msg.sender,
            address(this),
            traderDeposit
        );

        // Liquidate
        // The deposit the long otoken into the margin vault
        IERC20(collateralAsset).approve(
            addressBook.getMarginPool(),
            traderDeposit
        );
        address otoken = IOtokenFactory(addressBook.getOtokenFactory())
            .getOtoken(
                order.underlying,
                address(IHedgedPool(order.poolAddress).strikeToken()),
                collateralAsset,
                order.legs[0].strike,
                order.legs[0].expiration,
                order.legs[0].isPut
            );

        IERC20(otoken).approve(addressBook.getMarginPool(), amount);

        IController.ActionArgs[]
            memory liquidateAction = new IController.ActionArgs[](2);
        liquidateAction[0] = IController.ActionArgs(
            IController.ActionType.Liquidate,
            vaultOwner, // owner
            address(this), // address to transfer from
            otoken,
            vaultId,
            amount,
            0,
            ""
        );
        liquidateAction[1] = IController.ActionArgs(
            IController.ActionType.DepositLongOption,
            address(this), // owner
            address(this), // address to transfer from
            otoken,
            liquidatorVaultId,
            amount,
            0,
            ""
        );

        IController(addressBook.getController()).operate(liquidateAction);

        IERC20(otoken).approve(order.poolAddress, amount);
        // Use trade executor to buy otoken
        IHedgedPool(order.poolAddress).trade(
            order,
            0,
            liquidatorVaultId,
            false
        );

        // Withdraw collateral from margin vault to the contract
        IController.ActionArgs[]
            memory withdrawAction = new IController.ActionArgs[](1);
        withdrawAction[0] = IController.ActionArgs(
            IController.ActionType.WithdrawCollateral,
            address(this), // owner
            address(this), // address to transfer to
            collateralAsset,
            liquidatorVaultId,
            IController(addressBook.getController())
                .getVault(address(this), liquidatorVaultId)
                .collateralAmounts[0],
            0,
            ""
        );

        IController(addressBook.getController()).operate(withdrawAction);

        require(
            traderDeposit <= IERC20(collateralAsset).balanceOf(address(this)),
            "Trader deposit must be less than the collateral balance in margin vault"
        );

        // Send balance of vault to the msg sender so they can profit
        IERC20(collateralAsset).safeTransfer(
            msg.sender,
            IERC20(collateralAsset).balanceOf(address(this))
        );
    }

    function shortLiquidationAmount(
        address oTokenAddress,
        address vaultOwner,
        uint256 vaultId,
        uint256 oTokenIndex
    ) public view returns (uint256 liquidateAmount) {
        uint256 totalDebtScaled = getTotalDebtScaled(vaultOwner, vaultId);
        address underlyingAsset = IOtoken(oTokenAddress).underlyingAsset();
        address strikeAsset = IOtoken(oTokenAddress).strikeAsset();
        address collateralAsset = IOtoken(oTokenAddress).collateralAsset();
        uint256 strikePrice = IOtoken(oTokenAddress).strikePrice();
        uint256 expiryTimestamp = IOtoken(oTokenAddress).expiryTimestamp();
        bool isPut = IOtoken(oTokenAddress).isPut();

        liquidateAmount = (totalDebtScaled /
            (getNakedMarginRequired(
                underlyingAsset,
                strikeAsset,
                collateralAsset,
                strikePrice,
                expiryTimestamp,
                isPut
            ) -
                IMarginCalculator(addressBook.getMarginCalculator())
                    .getShortLiquidationPrice(
                        underlyingAsset,
                        strikeAsset,
                        collateralAsset,
                        OTOKEN_AMOUNT,
                        strikePrice,
                        expiryTimestamp,
                        isPut
                    )));
        if (
            liquidateAmount >
            IController(addressBook.getController())
                .getVault(vaultOwner, vaultId)
                .shortAmounts[oTokenIndex]
        ) {
            liquidateAmount = IController(addressBook.getController())
                .getVault(vaultOwner, vaultId)
                .shortAmounts[oTokenIndex];
        }
        return liquidateAmount;
    }

    function longLiquidationAmount(
        address oTokenAddress,
        address vaultOwner,
        uint256 vaultId,
        uint256 oTokenIndex
    ) public view returns (uint256) {
        uint256 totalDebtScaled = getTotalDebtScaled(vaultOwner, vaultId);

        address underlyingAsset = IOtoken(oTokenAddress).underlyingAsset();
        address strikeAsset = IOtoken(oTokenAddress).strikeAsset();
        address collateralAsset = IOtoken(oTokenAddress).collateralAsset();
        uint256 strikePrice = IOtoken(oTokenAddress).strikePrice();
        uint256 expiryTimestamp = IOtoken(oTokenAddress).expiryTimestamp();
        bool isPut = IOtoken(oTokenAddress).isPut();

        uint256 liquidateAmount = (totalDebtScaled /
            IMarginCalculator(addressBook.getMarginCalculator())
                .getLongLiquidationPrice(
                    underlyingAsset,
                    strikeAsset,
                    collateralAsset,
                    OTOKEN_AMOUNT,
                    strikePrice,
                    expiryTimestamp,
                    isPut
                ));
        if (
            liquidateAmount >
            IController(addressBook.getController())
                .getVault(vaultOwner, vaultId)
                .longAmounts[oTokenIndex]
        ) {
            liquidateAmount = IController(addressBook.getController())
                .getVault(vaultOwner, vaultId)
                .longAmounts[oTokenIndex];
        }
        return liquidateAmount;
    }

    function getNakedMarginRequired(
        address underlyingAsset,
        address strikeAsset,
        address collateralAsset,
        uint256 strikePrice,
        uint256 expiryTimestamp,
        bool isPut
    ) internal view returns (uint256) {
        return
            IMarginCalculator(addressBook.getMarginCalculator())
                .getNakedMarginRequired(
                    underlyingAsset,
                    strikeAsset,
                    collateralAsset,
                    OTOKEN_AMOUNT,
                    strikePrice,
                    IOracle(addressBook.getOracle()).getPrice(underlyingAsset),
                    expiryTimestamp,
                    IERC20MetadataUpgradeable(collateralAsset).decimals(),
                    isPut
                );
    }

    function getTotalDebtScaled(
        address vaultOwner,
        uint256 vaultId
    ) internal view returns (uint256) {
        (bool isUnderCollatAfter, uint256 totalDebt, , , ) = IController(
            addressBook.getController()
        ).isLiquidatable(vaultOwner, vaultId);

        require(isUnderCollatAfter, "Vault is not undercollateralized");
        return totalDebt * OTOKEN_DECIMALS;
    }

    function openMarginVault(
        address underlying
    ) public onlyOwner returns (uint256 vaultId) {
        address collateralAsset = address(
            IHedgedPool(address(hedgedPool)).collateralToken()
        );
        vaultId = ITradeExecutor(addressBook.getTradeExecutor())
            .openMarginVault(address(underlying), 0, collateralAsset);
        return vaultId;
    }

    function openMarginVaultSelf(
        address underlying
    ) internal returns (uint256 vaultId) {
        address collateralAsset = address(
            IHedgedPool(address(hedgedPool)).collateralToken()
        );
        vaultId = ITradeExecutor(addressBook.getTradeExecutor())
            .openMarginVault(address(underlying), 0, collateralAsset);
        return vaultId;
    }
}

// Make a base solidity contract outline

// SPDX-License-Identifier: None

pragma solidity 0.8.18;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/ITradeExecutor.sol";
import "../interfaces/IAddressBook.sol";
import {IMarginCalculator, IController, IOtokenFactory, IOracle, IOtoken} from "../interfaces/IGamma.sol";
import {IOrderUtil} from "../interfaces/IOrderUtil.sol";
import {IHedgedPool} from "../interfaces/IHedgedPool.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../libs/UniSwapLib.sol";
import {IUniSwapV3Pool} from "../interfaces/IUniSwapV3Pool.sol";
import "../interfaces/ILiquidator.sol";

// Change this contract to a portfolio manager
contract LiquidatorVault is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC1155Holder
{
    address private FACTORY;
    ILiquidator public liquidator;
    address public swapRouterAddress;

    /// @notice Hedgers for each underlying
    mapping(address => bool) public pools;
    mapping(address => uint24) public poolFees;

    struct FlashCallbackData {
        uint amount0;
        uint amount1;
        address caller;
        IERC20 token0;
        IERC20 token1;
        bool liquidateLong;
        uint256 vaultId;
        address vaultOwner;
        IOrderUtil.Order order;
    }

    // TODO: maybe add flash loans onto another contract?
    function __LiquidatorVault_init(
        address _uniSwapPoolFactoryAddress,
        address _liquidatorAddress,
        address _swapRouterAddress
    ) public initializer {
        FACTORY = _uniSwapPoolFactoryAddress;
        liquidator = ILiquidator(_liquidatorAddress);
        swapRouterAddress = _swapRouterAddress;

        __Ownable_init();
    }

    function flashLiquidate(
        uint amount0,
        uint amount1,
        address _token0,
        address _token1,
        bool _liquidateLong,
        uint256 _vaultId,
        address _vaultOwner,
        IOrderUtil.Order memory _order,
        address poolAddress
    ) external {
        bytes memory data = abi.encode(
            FlashCallbackData({
                amount0: amount0,
                amount1: amount1,
                caller: msg.sender,
                token0: IERC20(_token0),
                token1: IERC20(_token1),
                liquidateLong: _liquidateLong,
                vaultId: _vaultId,
                vaultOwner: _vaultOwner,
                order: _order
            })
        );
        IUniSwapV3Pool(poolAddress).flash(
            address(this),
            amount0,
            amount1,
            data
        );
    }

    function uniswapV3FlashCallback(
        uint fee0,
        uint fee1,
        bytes calldata data
    ) external {
        require(pools[msg.sender] == true, "not authorized");

        FlashCallbackData memory decoded = abi.decode(
            data,
            (FlashCallbackData)
        );
        uint256 traderApproval = uint256(decoded.order.legs[0].premium) +
            decoded.order.legs[0].fee;

        IERC20 token;
        uint amount;
        if (fee0 > 0) {
            token = decoded.token0;
            amount = decoded.amount0 + fee0;
        } else {
            token = decoded.token1;
            amount = decoded.amount1 + fee1;
        }
        token.approve(address(liquidator), traderApproval);

        if (decoded.liquidateLong == true) {
            liquidator.liquidateLong(
                decoded.vaultId,
                decoded.vaultOwner,
                decoded.order
            );
        } else {
            liquidator.liquidateShort(
                decoded.vaultId,
                decoded.vaultOwner,
                decoded.order
            );
        }

        // Repay borrow
        token.transfer(address(msg.sender), amount);
        token.transfer(decoded.caller, token.balanceOf(address(this)));
    }

    function getPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) public view returns (address) {
        UniSwapLib.PoolKey memory poolKey = UniSwapLib.getPoolKey(
            _token0,
            _token1,
            _fee
        );
        return UniSwapLib.computeAddress(FACTORY, poolKey);
    }

    function addPool(
        address _token0,
        address _token1,
        uint24 _fee
    ) external onlyOwner {
        address pool = getPool(_token0, _token1, _fee);

        pools[pool] = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract SirenAccessKey is ERC1155, Ownable, ERC1155Supply {
    // If true, only the owner can transfer tokens
    bool onlyOwnerTransfer;

    // Only the owner can transfer tokens if onlyOwnerTransfer is true
    modifier onlyOwnerTransferable() {
        if (onlyOwnerTransfer == true) {
            _checkOwner();
        }
        _;
    }

    constructor() ERC1155("") {
        onlyOwnerTransfer = true;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function mintMultiple(
        address[] memory accounts,
        uint256 id,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        require(
            accounts.length == amounts.length,
            "accessKey: accounts and amounts length mismatch"
        );
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], id, amounts[i], data);
        }
    }

    function burn(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _burn(account, id, amount);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _burnBatch(account, ids, amounts);
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) onlyOwnerTransferable {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function setOnlyOwnerTransfer(bool _onlyOwnerTransfer) public onlyOwner {
        onlyOwnerTransfer = _onlyOwnerTransfer;
    }
}

contract ArbGasInfo {
    function getL1BaseFeeEstimate() external view returns (uint256) {
        return 104064612142;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IOracle} from "../interfaces/IGamma.sol";
import {OpynPricerInterface} from "../interfaces/IGamma.sol";

/**
 * @notice A Pricer contract for one asset as reported by Chainlink
 */
contract ChainlinkPricer is OpynPricerInterface {
    using SafeMath for uint256;

    /// @dev base decimals
    uint256 internal constant BASE = 8;

    /// @notice chainlink response decimals
    uint256 public aggregatorDecimals;

    /// @notice the opyn oracle address
    IOracle public oracle;
    /// @notice the aggregator for an asset
    AggregatorV3Interface public aggregator;

    /// @notice asset that this pricer will a get price for
    address public asset;
    /// @notice bot address that is allowed to call setExpiryPriceInOracle
    address public bot;

    /**
     * @param _bot priveleged address that can call setExpiryPriceInOracle
     * @param _asset asset that this pricer will get a price for
     * @param _aggregator Chainlink aggregator contract for the asset
     * @param _oracle Opyn Oracle address
     */
    constructor(
        address _bot,
        address _asset,
        address _aggregator,
        address _oracle
    ) {
        require(
            _bot != address(0),
            "ChainLinkPricer: Cannot set 0 address as bot"
        );
        require(
            _oracle != address(0),
            "ChainLinkPricer: Cannot set 0 address as oracle"
        );
        require(
            _aggregator != address(0),
            "ChainLinkPricer: Cannot set 0 address as aggregator"
        );

        bot = _bot;
        oracle = IOracle(_oracle);
        aggregator = AggregatorV3Interface(_aggregator);
        asset = _asset;

        aggregatorDecimals = uint256(aggregator.decimals());
    }

    /**
     * @notice set the expiry price in the oracle, can only be called by Bot address
     * @dev a roundId must be provided to confirm price validity, which is the first Chainlink price provided after the expiryTimestamp
     * @param _expiryTimestamp expiry to set a price for
     * @param _roundId the first roundId after expiryTimestamp
     */
    function setExpiryPriceInOracle(
        uint256 _expiryTimestamp,
        uint80 _roundId
    ) external {
        (, int256 price, , uint256 roundTimestamp, ) = aggregator.getRoundData(
            _roundId
        );

        require(
            _expiryTimestamp <= roundTimestamp,
            "ChainLinkPricer: roundId not first after expiry"
        );
        require(price >= 0, "ChainLinkPricer: invalid price");

        if (msg.sender != bot) {
            bool isCorrectRoundId;
            uint80 previousRoundId = uint80(uint256(_roundId).sub(1));

            while (!isCorrectRoundId) {
                (, , , uint256 previousRoundTimestamp, ) = aggregator
                    .getRoundData(previousRoundId);

                if (previousRoundTimestamp == 0) {
                    require(
                        previousRoundId > 0,
                        "ChainLinkPricer: Invalid previousRoundId"
                    );
                    previousRoundId = previousRoundId - 1;
                } else if (previousRoundTimestamp > _expiryTimestamp) {
                    revert(
                        "ChainLinkPricer: previousRoundId not last before expiry"
                    );
                } else {
                    isCorrectRoundId = true;
                }
            }
        }

        oracle.setExpiryPrice(asset, _expiryTimestamp, uint256(price));
    }

    /**
     * @notice get the live price for the asset
     * @dev overides the getPrice function in OpynPricerInterface
     * @return price of the asset in USD, scaled by 1e8
     */
    function getPrice() external view override returns (uint256) {
        (, int256 answer, , , ) = aggregator.latestRoundData();
        require(answer > 0, "ChainLinkPricer: price is lower than 0");
        // chainlink's answer is already 1e8
        return _scaleToBase(uint256(answer));
    }

    /**
     * @notice get historical chainlink price
     * @param _roundId chainlink round id
     * @return round price and timestamp
     */
    function getHistoricalPrice(
        uint80 _roundId
    ) external view override returns (uint256, uint256) {
        (, int256 price, , uint256 roundTimestamp, ) = aggregator.getRoundData(
            _roundId
        );
        return (_scaleToBase(uint256(price)), roundTimestamp);
    }

    /**
     * @notice scale aggregator response to base decimals (1e8)
     * @param _price aggregator price
     * @return price scaled to 1e8
     */
    function _scaleToBase(uint256 _price) internal view returns (uint256) {
        if (aggregatorDecimals > BASE) {
            uint256 exp = aggregatorDecimals.sub(BASE);
            _price = _price.div(10 ** exp);
        } else if (aggregatorDecimals < BASE) {
            uint256 exp = BASE.sub(aggregatorDecimals);
            _price = _price.mul(10 ** exp);
        }

        return _price;
    }
}

pragma solidity >=0.8.0;

import "../libs/Dates.sol";

contract DatesTest {
    function get8amAligned(
        uint256 _timestamp,
        uint256 _dateOffset
    ) external pure returns (uint256) {
        return Dates.get8amAligned(_timestamp, _dateOffset);
    }

    function isValidExpiry(
        uint256 _now,
        uint256 _expiry,
        uint8 _numMonths,
        uint8 _numQuarters,
        bool allowDailyExpiration
    ) external pure returns (bool) {
        return
            Dates.isValidExpiry(
                _now,
                _expiry,
                _numMonths,
                _numQuarters,
                allowDailyExpiration
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.18;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

/// @notice This contract is used for testing purposes only. It is a mock Chainlink Aggregator that
/// allows us to set the latest answer and add new rounds.
contract MockChainlinkAggregator is AggregatorV2V3Interface {
    uint8 internal priceDecimals;

    struct Round {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    mapping(uint80 => Round) internal rounds;
    uint80 nextRoundId;

    constructor(uint8 _priceDecimals) public {
        priceDecimals = _priceDecimals;
    }

    function setLatestAnswer(int256 _latestAnswer) public {
        addRound(_latestAnswer, block.timestamp + 10, block.timestamp + 10);
    }

    function addRound(
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt
    ) public {
        Round memory round = Round(
            nextRoundId,
            answer,
            startedAt,
            updatedAt,
            nextRoundId
        );
        rounds[nextRoundId] = round;
        nextRoundId++;
    }

    function addRoundWithId(
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt
    ) public {
        require(roundId >= nextRoundId, "roundId should increase");
        Round memory round = Round(
            roundId,
            answer,
            startedAt,
            updatedAt,
            roundId
        );
        rounds[roundId] = round;
        nextRoundId = roundId + 1;
    }

    function decimals() public view returns (uint8) {
        return priceDecimals;
    }

    // just put something here, it's not used during tests
    function description() public view returns (string memory) {
        return "ETH/USD";
    }

    // just put something here, it's not used during tests
    function version() public view returns (uint256) {
        return 3;
    }

    // This function is never used for testing, so just use arbitrary return values. Only
    // latestRoundData gets used for testing
    function getRoundData(
        uint80 _roundId
    )
        public
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        Round memory round = rounds[_roundId];
        return (
            round.roundId,
            round.answer,
            round.startedAt,
            round.updatedAt,
            round.answeredInRound
        );
    }

    function latestRoundData()
        public
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return getRoundData(nextRoundId - 1);
    }

    function getAnswer(uint256 roundId) external view returns (int256) {
        return rounds[uint80(roundId)].answer;
    }

    function getTimestamp(uint256 roundId) external view returns (uint256) {
        return rounds[uint80(roundId)].updatedAt;
    }

    function latestAnswer() external view returns (int256) {
        return rounds[nextRoundId - 1].answer;
    }

    function latestRound() external view returns (uint256) {
        return nextRoundId - 1;
    }

    function latestTimestamp() external view returns (uint256) {
        return rounds[nextRoundId - 1].updatedAt;
    }

    function reset() public {
        for (uint80 i = 0; i < nextRoundId; i++) {
            rounds[i] = Round(0, 0, 0, 0, 0);
        }

        nextRoundId = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice This contract is used for testing purposes only. It is a mock Chainlink Aggregator that
/// allows us to set the latest answer and add new rounds.
contract MockHedgePool is Ownable {
    IERC20 public collateralToken;

    address hedger;
    mapping(address => bool) public keepers;

    constructor(address _collateralToken, address _hedger) public {
        collateralToken = IERC20(_collateralToken);
        hedger = _hedger;
        collateralToken.approve(hedger, type(uint256).max);
        keepers[msg.sender] = true;
    }

    /// @notice Available liquidity in the pool (excludes pending deposits and withdrawals)
    function getCollateralBalance() public view returns (uint256) {
        return collateralToken.balanceOf(address(this));
    }

    /// @notice Set hedger address for an underlying
    function setHedger(address hedgerAddress) external onlyOwner {
        hedger = hedgerAddress;
        collateralToken.approve(hedger, type(uint256).max);
    }

    function withdrawCollateral() external onlyOwner {
        collateralToken.transfer(
            msg.sender,
            collateralToken.balanceOf(address(this))
        );
    }

    function setCollateralToken(address _collateralToken) external onlyOwner {
        collateralToken = IERC20(_collateralToken);
        collateralToken.approve(hedger, type(uint256).max);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "../interfaces/IHedger.sol";

/// @title Mock hedger for testing
contract MockHedger is IHedger {
    uint256 private collateralValue;
    int256 private requiredCollateral;
    int256 private delta;

    function hedgerType() external pure returns (string memory) {
        return "MOCK";
    }

    function setCollateralValue(uint256 _collateralValue) external {
        collateralValue = _collateralValue;
    }

    function getCollateralValue() external view override returns (uint256) {
        return collateralValue;
    }

    function hedge(int256 _delta) external returns (int256 deltaDiff) {
        deltaDiff = _delta - delta;
        delta = _delta;

        return deltaDiff;
    }

    function getDelta() external view returns (int256) {
        return delta;
    }

    function sync() external returns (int256 collateralDiff) {
        return 0;
    }

    function setRequiredCollateral(int256 _requiredCollateral) external {
        requiredCollateral = _requiredCollateral;
    }

    function getRequiredCollateral() external view returns (int256) {
        return requiredCollateral;
    }
}

import {IOracle} from "../interfaces/IGamma.sol";

contract MockOracle is IOracle {
    uint256 public price;
    function isLockingPeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view override returns (bool) {
        return true;
    }

    function isDisputePeriodOver(
        address _asset,
        uint256 _expiryTimestamp
    ) external view override returns (bool) {
        return true;
    }

    function getExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp
    ) external view override returns (uint256, bool) {
        return (0, true);
    }

    function getDisputer() external view override returns (address) {
        return address(0);
    }

    function getPricer(
        address _asset
    ) external view override returns (address) {
        return address(0);
    }

    function getPrice(address _asset) external view override returns (uint256) {
        return price;
    }

    function getPricerLockingPeriod(
        address _pricer
    ) external view override returns (uint256) {
        return 0;
    }

    function getPricerDisputePeriod(
        address _pricer
    ) external view override returns (uint256) {
        return 0;
    }

    function getChainlinkRoundData(
        address _asset,
        uint80 _roundId
    ) external view override returns (uint256, uint256) {
        return (0, 0);
    }

    function setExpiryPrice(
        address _asset,
        uint256 _expiryTimestamp,
        uint256 _price
    ) external override {
        return;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// Adapted from @openzeppelin/contracts-ethereum-package/contracts/presets/ERC20PresetMinterBurner.sol

/**
 * ERC20 token for testing
 */
contract SimpleToken is AccessControl, ERC20Burnable {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @dev the number of decimals for this ERC20's human readable numeric
    uint8 internal numDecimals;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `BURNER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        numDecimals = _decimals;

        address deployer = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, deployer);

        _setupRole(MINTER_ROLE, deployer);
        _setupRole(BURNER_ROLE, deployer);
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public {
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "ERC20PresetMinterBurner: must have minter role to mint"
        );
        _mint(to, amount);
    }

    /**
     * @dev Burns tokens from any account.
     *
     * Requirements:
     *
     * - the caller must have the `BURNER_ROLE`.
     * - target account must have the balance to burn
     */
    function burn(address account, uint256 amount) public {
        require(
            hasRole(BURNER_ROLE, _msgSender()),
            "ERC20PresetMinterBurner: must have burner role to admin burn"
        );
        _burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function decimals() public view override(ERC20) returns (uint8) {
        return numDecimals;
    }

    function totalSupply() public view override(ERC20) returns (uint256) {
        return super.totalSupply();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;

    function _sendLogPayloadImplementation(bytes memory payload) internal view {
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            pop(
                staticcall(
                    gas(),
                    consoleAddress,
                    add(payload, 32),
                    mload(payload),
                    0,
                    0
                )
            )
        }
    }

    function _castToPure(
      function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castToPure(_sendLogPayloadImplementation)(payload);
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }
    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}