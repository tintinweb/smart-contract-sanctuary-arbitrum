// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { Decimal } from "./libraries/LibDecimal.sol";
import { AppStorage, LibAppStorage } from "./libraries/LibAppStorage.sol";

library C {
    using Decimal for Decimal.D256;

    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    function getPrecision() internal pure returns (uint256) {
        return PRECISION;
    }

    function getPercentBase() internal pure returns (uint256) {
        return PERCENT_BASE;
    }

    function getCollateral() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.collateral;
    }

    function getMuon() internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muon;
    }

    function getMuonAppId() internal view returns (uint16) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.muonAppId;
    }

    function getMinimumRequiredSignatures() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.minimumRequiredSignatures;
    }

    function getProtocolFee() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.protocolFee, PERCENT_BASE);
    }

    function getLiquidationFee() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.liquidationFee, PERCENT_BASE);
    }

    function getProtocolLiquidationShare() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.protocolLiquidationShare, PERCENT_BASE);
    }

    function getCVA() internal view returns (Decimal.D256 memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return Decimal.ratio(s.constants.cva, PERCENT_BASE);
    }

    function getRequestTimeout() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.requestTimeout;
    }

    function getMaxOpenPositionsCross() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.constants.maxOpenPositionsCross;
    }

    function getChainId() internal view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({ value: 0 });
    }

    function one() internal pure returns (D256 memory) {
        return D256({ value: BASE });
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({ value: a.mul(BASE) });
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(a, BASE, b) });
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.mul(BASE)) });
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE)) });
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.mul(BASE), reason) });
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.mul(b) });
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({ value: self.value.div(b) });
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({ value: self.value });
        for (uint256 i = 1; i < b; ++i) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.add(b.value) });
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value) });
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({ value: self.value.sub(b.value, reason) });
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, b.value, BASE) });
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({ value: getPartial(self.value, BASE, b.value) });
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;
import "./LibEnums.sol";

struct Hedger {
    address addr;
    string[] pricingWssURLs;
    string[] marketsHttpsURLs;
}

struct Market {
    uint256 marketId;
    string identifier;
    MarketType marketType;
    TradingSession tradingSession;
    bool active;
    string baseCurrency;
    string quoteCurrency;
    string symbol;
    // TODO: bytes32 muonPriceFeedID;
    // TODO: bytes32 muonFundingRateFeedID;
}

struct RequestForQuote {
    uint256 rfqId;
    RequestForQuoteState state;
    PositionType positionType;
    OrderType orderType;
    address partyA;
    address partyB;
    HedgerMode hedgerMode;
    uint256 marketId;
    Side side;
    uint256 notionalUsd;
    uint16 leverageUsed;
    uint256 lockedMargin;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 cva;
    uint256 minExpectedUnits;
    uint256 maxExpectedUnits;
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
}

struct Fill {
    uint256 fillId;
    uint256 positionId;
    Side side;
    uint256 filledAmountUnits;
    uint256 avgPriceUsd;
    uint256 timestamp;
}

struct Position {
    uint256 positionId;
    PositionState state;
    PositionType positionType;
    uint256 marketId;
    address partyA;
    address partyB;
    uint16 leverageUsed;
    Side side;
    uint256 lockedMargin;
    uint256 protocolFeePaid;
    uint256 liquidationFee;
    uint256 cva;
    uint256 currentBalanceUnits;
    uint256 initialNotionalUsd;
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
}

struct Constants {
    address collateral;
    address muon;
    uint16 muonAppId;
    uint8 minimumRequiredSignatures;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 protocolLiquidationShare;
    uint256 cva;
    uint256 requestTimeout;
    uint256 maxOpenPositionsCross;
}

struct HedgersState {
    mapping(address => Hedger) _hedgerMap;
    Hedger[] _hedgerList;
}

struct MarketsState {
    mapping(uint256 => Market) _marketMap;
    Market[] _marketList;
}

struct MAState {
    // Balances
    mapping(address => uint256) _accountBalances;
    mapping(address => uint256) _marginBalances;
    mapping(address => uint256) _lockedMargin;
    mapping(address => uint256) _lockedMarginReserved;
    // RequestForQuotes
    mapping(uint256 => RequestForQuote) _requestForQuotesMap;
    uint256 _requestForQuotesLength;
    mapping(address => uint256[]) _openRequestForQuotesList;
    // Positions
    mapping(uint256 => Position) _allPositionsMap;
    uint256 _allPositionsLength;
    mapping(address => uint256[]) _openPositionsIsolatedList;
    mapping(address => uint256[]) _openPositionsCrossList;
    mapping(uint256 => Fill[]) _positionFills;
}

struct AppStorage {
    bool paused;
    uint128 pausedAt;
    uint256 reentrantStatus;
    address ownerCandidate;
    Constants constants;
    HedgersState hedgers;
    MarketsState markets;
    MAState ma;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

enum MarketType {
    FOREX,
    CRYPTO,
    STOCK
}

enum TradingSession {
    _24_7,
    _24_5
}

enum Side {
    BUY,
    SELL
}

enum HedgerMode {
    SINGLE,
    HYBRID,
    AUTO
}

enum OrderType {
    LIMIT,
    MARKET
}

enum PositionType {
    ISOLATED,
    CROSS
}

enum RequestForQuoteState {
    ORPHAN,
    CANCELATION_REQUESTED,
    CANCELED,
    REJECTED,
    ACCEPTED
}

enum PositionState {
    OPEN,
    MARKET_CLOSE_REQUESTED,
    MARKET_CLOSE_CANCELATION_REQUESTED,
    LIMIT_CLOSE_REQUESTED,
    LIMIT_CLOSE_CANCELATION_REQUESTED,
    LIMIT_CLOSE_ACTIVE,
    CLOSED,
    LIQUIDATED
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, RequestForQuote, Position } from "../../../libraries/LibAppStorage.sol";
import { LibHedgers } from "../../../libraries/LibHedgers.sol";
import { LibMaster } from "../../../libraries/LibMaster.sol";
import { C } from "../../../C.sol";
import "../../../libraries/LibEnums.sol";

contract OpenMarketSingleFacet {
    AppStorage internal s;

    event RequestOpenMarketSingle(address indexed partyA, uint256 indexed rfqId);
    event CancelOpenMarketSingle(address indexed partyA, uint256 indexed rfqId);
    event ForceCancelOpenMarketSingle(address indexed partyA, uint256 indexed rfqId);
    event AcceptCancelOpenMarketSingle(address indexed partyB, uint256 indexed rfqId);
    event RejectOpenMarketSingle(address indexed partyB, uint256 indexed rfqId);
    event FillOpenMarketSingle(address indexed partyB, uint256 indexed rfqId, uint256 indexed positionId);

    function requestOpenMarketSingle(
        address partyB,
        uint256 marketId,
        PositionType positionType,
        Side side,
        uint256 usdAmountToSpend,
        uint16 leverage,
        uint256[2] memory expectedUnits
    ) external returns (RequestForQuote memory rfq) {
        require(msg.sender != partyB, "Parties can not be the same");
        (bool validHedger, ) = LibHedgers.isValidHedger(partyB);
        require(validHedger, "Invalid hedger");

        if (positionType == PositionType.CROSS) {
            uint256 numOpenPositionsCross = s.ma._openPositionsCrossList[msg.sender].length;
            require(numOpenPositionsCross <= C.getMaxOpenPositionsCross(), "Max open positions cross reached");
        }

        rfq = LibMaster.onRequestForQuote(
            msg.sender,
            partyB,
            marketId,
            positionType,
            OrderType.MARKET,
            HedgerMode.SINGLE,
            side,
            usdAmountToSpend,
            leverage,
            expectedUnits[0],
            expectedUnits[1]
        );

        emit RequestOpenMarketSingle(msg.sender, rfq.rfqId);
    }

    function cancelOpenMarketSingle(uint256 rfqId) external {
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(rfq.partyA == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(rfq.state == RequestForQuoteState.ORPHAN, "Invalid RFQ state");

        rfq.state = RequestForQuoteState.CANCELATION_REQUESTED;
        rfq.mutableTimestamp = block.timestamp;

        emit CancelOpenMarketSingle(msg.sender, rfqId);
    }

    function forceCancelOpenMarketSingle(uint256 rfqId) public {
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(rfq.partyA == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(rfq.state == RequestForQuoteState.CANCELATION_REQUESTED, "Invalid RFQ state");
        require(rfq.mutableTimestamp + C.getRequestTimeout() < block.timestamp, "Request Timeout");

        // Update the RFQ state.
        rfq.state = RequestForQuoteState.CANCELED;
        rfq.mutableTimestamp = block.timestamp;

        // Update RFQ mapping.
        LibMaster.removeOpenRequestForQuote(rfq.partyA, rfqId);

        // Return the collateral to partyA.
        uint256 reservedMargin = rfq.lockedMargin + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.ma._lockedMarginReserved[msg.sender] -= reservedMargin;
        s.ma._marginBalances[msg.sender] += reservedMargin;

        emit ForceCancelOpenMarketSingle(msg.sender, rfqId);
    }

    function acceptCancelOpenMarketSingle(uint256 rfqId) external {
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(rfq.partyB == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(rfq.state == RequestForQuoteState.CANCELATION_REQUESTED, "Invalid RFQ state");

        // Update the RFQ state.
        rfq.state = RequestForQuoteState.CANCELED;
        rfq.mutableTimestamp = block.timestamp;

        // Update RFQ mapping.
        LibMaster.removeOpenRequestForQuote(rfq.partyA, rfqId);

        // Return the collateral to partyA.
        uint256 reservedMargin = rfq.lockedMargin + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.ma._lockedMarginReserved[rfq.partyA] -= reservedMargin;
        s.ma._marginBalances[rfq.partyA] += reservedMargin;

        emit AcceptCancelOpenMarketSingle(msg.sender, rfqId);
    }

    function rejectOpenMarketSingle(uint256 rfqId) external {
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(rfq.partyB == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");
        require(
            rfq.state == RequestForQuoteState.ORPHAN || rfq.state == RequestForQuoteState.CANCELATION_REQUESTED,
            "Invalid RFQ state"
        );

        // Update the RFQ
        rfq.state = RequestForQuoteState.REJECTED;
        rfq.mutableTimestamp = block.timestamp;

        // Update RFQ mapping.
        LibMaster.removeOpenRequestForQuote(rfq.partyA, rfqId);

        // Return the collateral to partyA
        uint256 reservedMargin = rfq.lockedMargin + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.ma._lockedMarginReserved[rfq.partyA] -= reservedMargin;
        s.ma._marginBalances[rfq.partyA] += reservedMargin;

        emit RejectOpenMarketSingle(msg.sender, rfqId);
    }

    function fillOpenMarketSingle(
        uint256 rfqId,
        uint256 filledAmountUnits,
        uint256 avgPriceUsd
    ) external returns (Position memory position) {
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(rfq.partyB == msg.sender, "Invalid party");
        require(rfq.hedgerMode == HedgerMode.SINGLE, "Invalid hedger mode");
        require(rfq.orderType == OrderType.MARKET, "Invalid order type");

        position = LibMaster.onFillOpenMarket(msg.sender, rfqId, filledAmountUnits, avgPriceUsd);

        emit FillOpenMarketSingle(msg.sender, rfqId, position.positionId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, Hedger } from "../libraries/LibAppStorage.sol";

library LibHedgers {
    function isValidHedger(address partyB) internal view returns (bool, Hedger memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Hedger memory hedger = s.hedgers._hedgerMap[partyB];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgerByAddressOrThrow(address partyB) internal view returns (Hedger memory) {
        (bool isValid, Hedger memory hedger) = isValidHedger(partyB);
        require(isValid, "Hedger is not valid");
        return hedger;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, RequestForQuote, Position, Fill } from "../libraries/LibAppStorage.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibMarkets } from "../libraries/LibMarkets.sol";
import { PositionPrice } from "../libraries/LibOracle.sol";
import { Decimal } from "../libraries/LibDecimal.sol";
import { C } from "../C.sol";
import "../libraries/LibEnums.sol";

library LibMaster {
    using Decimal for Decimal.D256;

    // --------------------------------//
    //---- INTERNAL WRITE FUNCTIONS ---//
    // --------------------------------//

    function onRequestForQuote(
        address partyA,
        address partyB,
        uint256 marketId,
        PositionType positionType,
        OrderType orderType,
        HedgerMode hedgerMode,
        Side side,
        uint256 usdAmountToSpend,
        uint16 leverage,
        uint256 minExpectedUnits,
        uint256 maxExpectedUnits
    ) internal returns (RequestForQuote memory rfq) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(LibMarkets.isValidMarketId(marketId), "Invalid market");

        uint256 notionalUsd = usdAmountToSpend * leverage;
        uint256 protocolFee = calculateProtocolFeeAmount(notionalUsd);
        uint256 liquidationFee = calculateLiquidationFeeAmount(notionalUsd);
        uint256 cva = calculateCVAAmount(notionalUsd);
        uint256 amount = usdAmountToSpend + protocolFee + liquidationFee + cva;

        require(amount <= s.ma._marginBalances[partyA], "Insufficient margin balance");
        s.ma._marginBalances[partyA] -= amount;
        s.ma._lockedMarginReserved[partyA] += amount;

        // Create the RFQ
        uint256 currentRfqId = s.ma._requestForQuotesLength + 1;
        rfq = RequestForQuote({
            rfqId: currentRfqId,
            state: RequestForQuoteState.ORPHAN,
            positionType: positionType,
            orderType: orderType,
            partyA: partyA,
            partyB: partyB,
            hedgerMode: hedgerMode,
            marketId: marketId,
            side: side,
            notionalUsd: notionalUsd,
            leverageUsed: leverage,
            lockedMargin: usdAmountToSpend,
            protocolFee: protocolFee,
            liquidationFee: liquidationFee,
            cva: cva,
            minExpectedUnits: minExpectedUnits,
            maxExpectedUnits: maxExpectedUnits,
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp
        });

        s.ma._requestForQuotesMap[currentRfqId] = rfq;
        s.ma._requestForQuotesLength++;
        s.ma._openRequestForQuotesList[partyA].push(currentRfqId);
    }

    function onFillOpenMarket(
        address partyB,
        uint256 rfqId,
        uint256 filledAmountUnits,
        uint256 avgPriceUsd
    ) internal returns (Position memory position) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        RequestForQuote storage rfq = s.ma._requestForQuotesMap[rfqId];

        require(
            rfq.state == RequestForQuoteState.ORPHAN || rfq.state == RequestForQuoteState.CANCELATION_REQUESTED,
            "Invalid RFQ state"
        );
        require(rfq.minExpectedUnits <= filledAmountUnits, "Invalid min filled amount");
        require(rfq.maxExpectedUnits >= filledAmountUnits, "Invalid max filled amount");

        // Update the RFQ
        rfq.state = RequestForQuoteState.ACCEPTED;
        rfq.mutableTimestamp = block.timestamp;

        // Update RFQ mapping.
        LibMaster.removeOpenRequestForQuote(rfq.partyA, rfqId);

        // Create the Position
        uint256 currentPositionId = s.ma._allPositionsLength + 1;
        position = Position({
            positionId: currentPositionId,
            state: PositionState.OPEN,
            positionType: rfq.positionType,
            marketId: rfq.marketId,
            partyA: rfq.partyA,
            partyB: rfq.partyB,
            leverageUsed: rfq.leverageUsed,
            side: rfq.side,
            lockedMargin: rfq.lockedMargin,
            protocolFeePaid: rfq.protocolFee,
            liquidationFee: rfq.liquidationFee,
            cva: rfq.cva,
            currentBalanceUnits: filledAmountUnits,
            initialNotionalUsd: rfq.notionalUsd,
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp
        });

        // Create the first Fill
        createFill(currentPositionId, rfq.side, filledAmountUnits, avgPriceUsd);

        // Update global mappings
        s.ma._allPositionsMap[currentPositionId] = position;
        s.ma._allPositionsLength++;

        // Transfer partyA's collateral
        uint256 deductableMarginA = rfq.lockedMargin + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.ma._lockedMarginReserved[rfq.partyA] -= deductableMarginA;

        // Transfer partyB's collateral
        uint256 deductableMarginB = rfq.lockedMargin + rfq.liquidationFee + rfq.cva; // hedger doesn't pay protocolFee
        require(deductableMarginB <= s.ma._marginBalances[partyB], "Insufficient margin balance");
        s.ma._marginBalances[partyB] -= deductableMarginB;

        // Distribute the fee paid by partyA
        s.ma._accountBalances[LibDiamond.contractOwner()] += rfq.protocolFee;

        if (rfq.positionType == PositionType.ISOLATED) {
            s.ma._openPositionsIsolatedList[rfq.partyA].push(currentPositionId);
            s.ma._openPositionsIsolatedList[partyB].push(currentPositionId);
        } else {
            s.ma._openPositionsCrossList[rfq.partyA].push(currentPositionId);
            s.ma._openPositionsIsolatedList[partyB].push(currentPositionId);

            // Lock margins
            s.ma._lockedMargin[rfq.partyA] += rfq.lockedMargin;
            s.ma._lockedMargin[partyB] += rfq.lockedMargin;
        }
    }

    function onFillCloseMarket(uint256 positionId, PositionPrice memory positionPrice) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position storage position = s.ma._allPositionsMap[positionId];

        uint256 price = position.side == Side.BUY ? positionPrice.bidPrice : positionPrice.askPrice;

        // Add the Fill
        createFill(positionId, position.side == Side.BUY ? Side.SELL : Side.BUY, position.currentBalanceUnits, price);

        // Calculate the PnL of PartyA
        (int256 pnlA, , ) = _calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Distribute the PnL accordingly
        if (position.positionType == PositionType.ISOLATED) {
            distributePnLIsolated(position.positionId, pnlA);
        } else {
            distributePnLCross(position.positionId, pnlA);
        }

        // Return parties their reserved liquidation fees
        s.ma._marginBalances[position.partyA] += (position.liquidationFee + position.cva);
        s.ma._marginBalances[position.partyB] += (position.liquidationFee + position.cva);

        // Update Position
        position.state = PositionState.CLOSED;
        position.currentBalanceUnits = 0;
        position.mutableTimestamp = block.timestamp;

        // Update mappings
        if (position.positionType == PositionType.ISOLATED) {
            removeOpenPositionIsolated(position.partyA, positionId);
            removeOpenPositionIsolated(position.partyB, positionId);
        } else {
            removeOpenPositionCross(position.partyA, positionId);
            removeOpenPositionIsolated(position.partyB, positionId);
        }
    }

    function distributePnLIsolated(uint256 positionId, int256 pnlA) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * Losing party pays for the PNL using the margin that was locked inside the position.
         */

        if (pnlA >= 0) {
            uint256 amount = uint256(pnlA);
            if (amount > position.lockedMargin) {
                s.ma._marginBalances[position.partyA] += position.lockedMargin * 2;
            } else {
                s.ma._marginBalances[position.partyA] += (position.lockedMargin + amount);
                s.ma._marginBalances[position.partyB] += (position.lockedMargin - amount);
            }
        } else {
            uint256 amount = uint256(-pnlA);
            if (amount > position.lockedMargin) {
                s.ma._marginBalances[position.partyB] += position.lockedMargin * 2;
            } else {
                s.ma._marginBalances[position.partyB] += (position.lockedMargin + amount);
                s.ma._marginBalances[position.partyA] += (position.lockedMargin - amount);
            }
        }
    }

    function distributePnLCross(uint256 positionId, int256 pnlA) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        /**
         * Winning party receives the PNL.
         * If partyA is the losing party: pays for the PNL using his lockedMargin.
         * If partyB is the losing party: pays for the PNL using his margin locked inside the position (he's isolated).
         */
        address partyA = position.partyA;
        address partyB = position.partyB;

        if (pnlA >= 0) {
            /**
             * PartyA will NOT receive his lockedMargin back,
             * he'll have to withdraw it manually. This has to do with the
             * risk of liquidation + the fact that his initially lockedMargin
             * could be greater than what he currently has locked.
             */
            uint256 amount = uint256(pnlA);
            if (amount > position.lockedMargin) {
                s.ma._marginBalances[position.partyA] += position.lockedMargin;
            } else {
                s.ma._marginBalances[position.partyA] += amount;
                s.ma._marginBalances[position.partyB] += (position.lockedMargin - amount);
            }
        } else {
            uint256 amount = uint256(-pnlA);
            if (s.ma._lockedMargin[partyA] < amount) {
                s.ma._marginBalances[partyB] += (s.ma._lockedMargin[partyA] + position.lockedMargin);
                s.ma._lockedMargin[partyA] = 0;
            } else {
                s.ma._marginBalances[partyB] += (amount + position.lockedMargin);
                s.ma._lockedMargin[partyA] -= amount;
            }
        }
    }

    function removeOpenRequestForQuote(address party, uint256 rfqId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        RequestForQuote memory rfq = s.ma._requestForQuotesMap[rfqId];
        require(
            rfq.state == RequestForQuoteState.CANCELED ||
                rfq.state == RequestForQuoteState.REJECTED ||
                rfq.state == RequestForQuoteState.ACCEPTED,
            "RFQ is still open"
        );

        int256 index = -1;
        for (uint256 i = 0; i < s.ma._openRequestForQuotesList[party].length; i++) {
            if (s.ma._openRequestForQuotesList[party][i] == rfqId) {
                index = int256(i);
                break;
            }
        }
        require(index != -1, "RFQ not found");

        s.ma._openRequestForQuotesList[party][uint256(index)] = s.ma._openRequestForQuotesList[party][
            s.ma._openRequestForQuotesList[party].length - 1
        ];
        s.ma._openRequestForQuotesList[party].pop();
    }

    function removeOpenPositionIsolated(address party, uint256 positionId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        int256 index = -1;
        for (uint256 i = 0; i < s.ma._openPositionsIsolatedList[party].length; i++) {
            if (s.ma._openPositionsIsolatedList[party][i] == positionId) {
                index = int256(i);
                break;
            }
        }
        require(index != -1, "Position not found");

        s.ma._openPositionsIsolatedList[party][uint256(index)] = s.ma._openPositionsIsolatedList[party][
            s.ma._openPositionsIsolatedList[party].length - 1
        ];
        s.ma._openPositionsIsolatedList[party].pop();
    }

    function removeOpenPositionCross(address party, uint256 positionId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        int256 index = -1;
        for (uint256 i = 0; i < s.ma._openPositionsCrossList[party].length; i++) {
            if (s.ma._openPositionsCrossList[party][i] == positionId) {
                index = int256(i);
                break;
            }
        }
        require(index != -1, "Position not found");

        s.ma._openPositionsCrossList[party][uint256(index)] = s.ma._openPositionsCrossList[party][
            s.ma._openPositionsCrossList[party].length - 1
        ];
        s.ma._openPositionsCrossList[party].pop();
    }

    function createFill(
        uint256 positionId,
        Side side,
        uint256 amount,
        uint256 price
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 fillId = s.ma._positionFills[positionId].length;
        Fill memory fill = Fill(fillId, positionId, side, amount, price, block.timestamp);
        s.ma._positionFills[positionId].push(fill);
    }

    // --------------------------------//
    //---- INTERNAL VIEW FUNCTIONS ----//
    // --------------------------------//

    function getOpenPositionsIsolated(address party) internal view returns (Position[] memory positions) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256[] memory positionIds = s.ma._openPositionsIsolatedList[party];

        positions = new Position[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            positions[i] = s.ma._allPositionsMap[positionIds[i]];
        }
    }

    function getOpenPositionsCross(address party) internal view returns (Position[] memory positions) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256[] memory positionIds = s.ma._openPositionsCrossList[party];

        positions = new Position[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            positions[i] = s.ma._allPositionsMap[positionIds[i]];
        }
    }

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function calculateUPnLIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal view returns (int256 uPnLA, int256 uPnLB) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];

        (uPnLA, uPnLB, ) = _calculateUPnLIsolated(
            position.side,
            position.currentBalanceUnits,
            position.initialNotionalUsd,
            bidPrice,
            askPrice
        );
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     *      Use Muon to verify inputs to prevent expensive computational costs.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function calculateUPnLCross(PositionPrice[] memory positionPrices, address party)
        internal
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        (uPnLCross, notionalCross) = _calculateUPnLCross(positionPrices, party);
    }

    function calculateProtocolFeeAmount(uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(C.getProtocolFee()).asUint256();
    }

    function calculateLiquidationFeeAmount(uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(C.getLiquidationFee()).asUint256();
    }

    function calculateCVAAmount(uint256 notionalSize) internal view returns (uint256) {
        return Decimal.from(notionalSize).mul(C.getCVA()).asUint256();
    }

    function calculateCrossMarginHealth(uint256 lockedMargin, int256 uPnLCross)
        internal
        pure
        returns (Decimal.D256 memory ratio)
    {
        if (lockedMargin == 0) {
            return Decimal.ratio(1, 1);
        }

        if (uPnLCross >= 0) {
            return Decimal.ratio(lockedMargin + uint256(uPnLCross), lockedMargin);
        }

        uint256 pnl = uint256(-uPnLCross);
        if (pnl >= lockedMargin) {
            return Decimal.zero();
        }

        ratio = Decimal.ratio(lockedMargin - pnl, lockedMargin);
    }

    function positionShouldBeLiquidatedIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    )
        internal
        view
        returns (
            bool shouldBeLiquidated,
            int256 pnlA,
            int256 pnlB
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Position is not isolated");
        (pnlA, pnlB) = calculateUPnLIsolated(positionId, bidPrice, askPrice);
        shouldBeLiquidated = pnlA <= 0
            ? uint256(pnlB) >= position.lockedMargin
            : uint256(pnlA) >= position.lockedMargin;
    }

    function partyShouldBeLiquidatedCross(address party, int256 uPnLCross) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return calculateCrossMarginHealth(s.ma._lockedMargin[party], uPnLCross).isZero();
    }

    // --------------------------------//
    //----- PRIVATE VIEW FUNCTIONS ----//
    // --------------------------------//

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function _calculateUPnLIsolated(
        Side side,
        uint256 currentBalanceUnits,
        uint256 initialNotionalUsd,
        uint256 bidPrice,
        uint256 askPrice
    )
        private
        pure
        returns (
            int256 uPnLA,
            int256 uPnLB,
            int256 notionalIsolated
        )
    {
        if (currentBalanceUnits == 0) return (0, 0, 0);

        uint256 precision = C.getPrecision();

        if (side == Side.BUY) {
            require(bidPrice != 0, "Oracle bidPrice is invalid");
            notionalIsolated = int256((currentBalanceUnits * bidPrice) / precision);
            uPnLA = notionalIsolated - int256(initialNotionalUsd);
        } else {
            require(askPrice != 0, "Oracle askPrice is invalid");
            notionalIsolated = int256((currentBalanceUnits * askPrice) / precision);
            uPnLA = int256(initialNotionalUsd) - notionalIsolated;
        }

        return (uPnLA, -uPnLA, notionalIsolated);
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     *      Use Muon to verify inputs to prevent expensive computational costs.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function _calculateUPnLCross(PositionPrice[] memory positionPrices, address party)
        private
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        Position[] memory openPositions = getOpenPositionsCross(party);

        if (openPositions.length == 0) {
            return (0, 0);
        }

        for (uint256 i = 0; i < positionPrices.length; i++) {
            uint256 positionId = positionPrices[i].positionId;
            uint256 bidPrice = positionPrices[i].bidPrice;
            uint256 askPrice = positionPrices[i].askPrice;

            Position memory position = s.ma._allPositionsMap[positionId];
            require(position.partyA == party || position.partyB == party, "PositionId mismatch");

            (int256 _uPnLIsolatedA, int256 _uPnLIsolatedB, int256 _notionalIsolated) = _calculateUPnLIsolated(
                position.side,
                position.currentBalanceUnits,
                position.initialNotionalUsd,
                bidPrice,
                askPrice
            );

            if (position.partyA == party) {
                uPnLCross += _uPnLIsolatedA;
            } else {
                uPnLCross += _uPnLIsolatedB;
            }

            notionalCross += _notionalIsolated;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwnerOrContract() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == address(this),
            "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition
                    .selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage } from "../libraries/LibAppStorage.sol";

library LibMarkets {
    function isValidMarketId(uint256 marketId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 length = s.markets._marketList.length;
        return marketId < length;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { SchnorrSign, IMuonV03 } from "../interfaces/IMuonV03.sol";
import { C } from "../C.sol";

struct PositionPrice {
    uint256 positionId;
    uint256 bidPrice;
    uint256 askPrice;
}

library LibOracle {
    using ECDSA for bytes32;

    /**
     * @notice Verify the binding of prices with the positionId
     */
    function verifyPositionPriceOrThrow(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) internal {
        require(sigs.length >= C.getMinimumRequiredSignatures(), "Insufficient signatures");

        bytes32 hash = keccak256(abi.encodePacked(C.getMuonAppId(), reqId, positionId, bidPrice, askPrice));
        IMuonV03 _muon = IMuonV03(C.getMuon());

        bool verified = _muon.verify(reqId, uint256(hash), sigs);
        require(verified, "Invalid signatures");
    }

    /**
     * @notice Verify the binding of prices with the positionIds
     * @dev The caller defines the positionIds and its order, Muon doesn't perform a check.
     * @dev Prices are valid by expiration, but the positionIds are valid per-block.
     */
    function verifyPositionPricesOrThrow(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) internal {
        require(sigs.length >= C.getMinimumRequiredSignatures(), "Insufficient signatures");

        bytes32 hash = keccak256(abi.encodePacked(C.getMuonAppId(), reqId, positionIds, bidPrices, askPrices));
        IMuonV03 _muon = IMuonV03(C.getMuon());

        bool verified = _muon.verify(reqId, uint256(hash), sigs);
        require(verified, "Invalid signatures");
    }

    function createPositionPrice(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal pure returns (PositionPrice memory positionPrice) {
        return PositionPrice(positionId, bidPrice, askPrice);
    }

    function createPositionPrices(
        uint256[] memory positionIds,
        uint256[] memory bidPrices,
        uint256[] memory askPrices
    ) internal pure returns (PositionPrice[] memory positionPrices) {
        require(
            positionPrices.length == bidPrices.length && positionPrices.length == askPrices.length,
            "Invalid position prices"
        );

        positionPrices = new PositionPrice[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            positionPrices[i] = PositionPrice(positionIds[i], bidPrices[i], askPrices[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
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
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

interface IMuonV03 {
    function verify(
        bytes calldata reqId,
        uint256 hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, RequestForQuote, Position, Fill } from "../../libraries/LibAppStorage.sol";
import { Decimal } from "../../libraries/LibDecimal.sol";
import { LibMaster } from "../../libraries/LibMaster.sol";
import { PositionPrice } from "../../libraries/LibOracle.sol";
import "../../libraries/LibEnums.sol";

contract MasterFacet {
    AppStorage internal s;

    function getRequestForQuote(uint256 rfqId) external view returns (RequestForQuote memory rfq) {
        return s.ma._requestForQuotesMap[rfqId];
    }

    function getRequestForQuotes(uint256[] calldata rfqIds) external view returns (RequestForQuote[] memory rfqs) {
        uint256 len = rfqIds.length;
        rfqs = new RequestForQuote[](len);

        for (uint256 i = 0; i < len; i++) {
            rfqs[i] = (s.ma._requestForQuotesMap[rfqIds[i]]);
        }
    }

    function getOpenRequestForQuoteIds(address party) external view returns (uint256[] memory rfqIds) {
        return s.ma._openRequestForQuotesList[party];
    }

    function getOpenRequestForQuotes(address party) external view returns (RequestForQuote[] memory rfqs) {
        uint256 len = s.ma._openRequestForQuotesList[party].length;
        rfqs = new RequestForQuote[](len);

        for (uint256 i = 0; i < len; i++) {
            rfqs[i] = (s.ma._requestForQuotesMap[s.ma._openRequestForQuotesList[party][i]]);
        }
    }

    function getPosition(uint256 positionId) external view returns (Position memory position) {
        return s.ma._allPositionsMap[positionId];
    }

    function getPositions(uint256[] calldata positionIds) external view returns (Position[] memory positions) {
        uint256 len = positionIds.length;
        positions = new Position[](len);

        for (uint256 i = 0; i < len; i++) {
            positions[i] = (s.ma._allPositionsMap[positionIds[i]]);
        }
    }

    function getOpenPositionsIsolated(address party) external view returns (Position[] memory openPositionsIsolated) {
        return LibMaster.getOpenPositionsIsolated(party);
    }

    function getOpenPositionsCross(address party) external view returns (Position[] memory openPositionsCross) {
        return LibMaster.getOpenPositionsCross(party);
    }

    function getOpenPositionIdsIsolated(address party) external view returns (uint256[] memory positionIds) {
        return s.ma._openPositionsIsolatedList[party];
    }

    function getOpenPositionIdsCross(address party) external view returns (uint256[] memory positionIds) {
        return s.ma._openPositionsCrossList[party];
    }

    function getPositionFills(uint256 positionId) external view returns (Fill[] memory fills) {
        return s.ma._positionFills[positionId];
    }

    function calculateUPnLIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) external view returns (int256 uPnLA, int256 uPnLB) {
        return LibMaster.calculateUPnLIsolated(positionId, bidPrice, askPrice);
    }

    function calculateUPnLCross(PositionPrice[] calldata positionPrices, address party)
        external
        view
        returns (int256 uPnLCross, int256 notionalCross)
    {
        return LibMaster.calculateUPnLCross(positionPrices, party);
    }

    function calculateProtocolFeeAmount(uint256 notionalSize) external view returns (uint256) {
        return LibMaster.calculateProtocolFeeAmount(notionalSize);
    }

    function calculateLiquidationFeeAmount(uint256 notionalSize) external view returns (uint256) {
        return LibMaster.calculateLiquidationFeeAmount(notionalSize);
    }

    function calculateCVAAmount(uint256 notionalSize) external view returns (uint256) {
        return LibMaster.calculateCVAAmount(notionalSize);
    }

    function calculateCrossMarginHealth(uint256 lockedMargin, int256 uPnL)
        external
        pure
        returns (Decimal.D256 memory ratio)
    {
        return LibMaster.calculateCrossMarginHealth(lockedMargin, uPnL);
    }

    function positionShouldBeLiquidatedIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    )
        external
        view
        returns (
            bool shouldLiquidated,
            int256 pnlA,
            int256 pnlB
        )
    {
        return LibMaster.positionShouldBeLiquidatedIsolated(positionId, bidPrice, askPrice);
    }

    function partyShouldBeLiquidatedCross(address party, int256 uPnLCross) external view returns (bool) {
        return LibMaster.partyShouldBeLiquidatedCross(party, uPnLCross);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, LibAppStorage, Position, Fill } from "../../../libraries/LibAppStorage.sol";
import { LibMaster } from "../../../libraries/LibMaster.sol";
import { LibOracle, SchnorrSign } from "../../../libraries/LibOracle.sol";
import { C } from "../../../C.sol";
import "../../../libraries/LibEnums.sol";

/**
 * Close a Position through a Market order.
 * @dev Can only be done via the original partyB (hedgerMode=Single).
 */
contract CloseMarketFacet {
    AppStorage internal s;

    event RequestCloseMarket(address indexed partyA, uint256 indexed positionId);
    event CancelCloseMarket(address indexed partyA, uint256 indexed positionId);
    event ForceCancelCloseMarket(address indexed partyA, uint256 indexed positionId);
    event AcceptCancelCloseMarket(address indexed partyB, uint256 indexed positionId);
    event RejectCloseMarket(address indexed partyB, uint256 indexed positionId);
    event FillCloseMarket(address indexed partyB, uint256 indexed positionId);

    function requestCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyA == msg.sender, "Invalid party");
        require(position.state == PositionState.OPEN, "Invalid position state");

        position.state = PositionState.MARKET_CLOSE_REQUESTED;
        position.mutableTimestamp = block.timestamp;

        emit RequestCloseMarket(msg.sender, positionId);
    }

    function cancelCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyA == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_REQUESTED, "Invalid position state");

        position.state = PositionState.MARKET_CLOSE_CANCELATION_REQUESTED;
        position.mutableTimestamp = block.timestamp;

        emit CancelCloseMarket(msg.sender, positionId);
    }

    function forceCancelCloseMarket(uint256 positionId) public {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyA == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_CANCELATION_REQUESTED, "Invalid position state");
        require(position.mutableTimestamp + C.getRequestTimeout() < block.timestamp, "Request Timeout");

        position.state = PositionState.OPEN;
        position.mutableTimestamp = block.timestamp;

        emit ForceCancelCloseMarket(msg.sender, positionId);
    }

    function acceptCancelCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyB == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_CANCELATION_REQUESTED, "Invalid position state");

        position.state = PositionState.OPEN;
        position.mutableTimestamp = block.timestamp;

        emit AcceptCancelCloseMarket(msg.sender, positionId);
    }

    function rejectCloseMarket(uint256 positionId) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyB == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_REQUESTED, "Invalid position state");

        position.state = PositionState.OPEN;
        position.mutableTimestamp = block.timestamp;

        emit RejectCloseMarket(msg.sender, positionId);
    }

    function fillCloseMarket(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external {
        Position storage position = s.ma._allPositionsMap[positionId];

        require(position.partyB == msg.sender, "Invalid party");
        require(position.state == PositionState.MARKET_CLOSE_REQUESTED, "Invalid position state");

        // Verify oracle signatures
        LibOracle.verifyPositionPriceOrThrow(positionId, bidPrice, askPrice, reqId, sigs);

        // Handle the fill
        LibMaster.onFillCloseMarket(positionId, LibOracle.createPositionPrice(positionId, bidPrice, askPrice));

        emit FillCloseMarket(msg.sender, positionId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage, Position, Fill } from "../../libraries/LibAppStorage.sol";
import { SchnorrSign } from "../../interfaces/IMuonV03.sol";
import { LibOracle, PositionPrice } from "../../libraries/LibOracle.sol";
import { LibMaster } from "../../libraries/LibMaster.sol";
import { LibHedgers } from "../../libraries/LibHedgers.sol";
import { Decimal } from "../../libraries/LibDecimal.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { C } from "../../C.sol";
import "../../libraries/LibEnums.sol";

contract LiquidationFacet {
    using Decimal for Decimal.D256;

    AppStorage internal s;

    /**
     * @dev Unlike a cross liquidation, we don't check for deficits here.
     *      Counterparties should put limit sell orders at the liquidation price
     *      of the user, in order to mitigate the deficit. Failure to do so
     *      would result in the counterParty paying for the deficit.
     */
    function liquidatePositionIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external {
        // Verify oracle signatures
        LibOracle.verifyPositionPriceOrThrow(positionId, bidPrice, askPrice, reqId, sigs);

        // Check if the position should be liquidated
        (bool shouldBeLiquidated, int256 pnlA, ) = LibMaster.positionShouldBeLiquidatedIsolated(
            positionId,
            bidPrice,
            askPrice
        );
        require(shouldBeLiquidated, "Not liquidatable");

        Position memory position = s.ma._allPositionsMap[positionId];
        require(position.positionType == PositionType.ISOLATED, "Position is not isolated");
        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");

        uint256 amount = (position.lockedMargin * 2) + (position.cva * 2) + position.liquidationFee;

        // If partyA is in a loss, then that means he's the one who needs to be liquidated
        if (pnlA < 0) {
            s.ma._marginBalances[position.partyB] += amount;
        } else {
            s.ma._marginBalances[position.partyA] += amount;
        }

        // Reward the liquidator
        s.ma._marginBalances[msg.sender] += position.liquidationFee;

        // Update mappings
        _updatePositionDataIsolated(positionId, LibOracle.createPositionPrice(positionId, bidPrice, askPrice));
    }

    // solhint-disable-next-line code-complexity
    function liquidatePartyCross(
        address party,
        uint256[] calldata positionIds,
        uint256[] calldata bidPrices,
        uint256[] calldata askPrices,
        bytes calldata reqId,
        SchnorrSign[] calldata sigs
    ) external {
        // Verify oracle signatures
        LibOracle.verifyPositionPricesOrThrow(positionIds, bidPrices, askPrices, reqId, sigs);

        // Check if all positionIds are provided by length
        require(positionIds.length == s.ma._openPositionsCrossList[party].length, "Invalid positionIds length");

        // Create structs for positionIds and prices
        PositionPrice[] memory positionPrices = LibOracle.createPositionPrices(positionIds, bidPrices, askPrices);

        /**
         * The below checks whether the party should be liquidated. We can do that based
         * on malicious inputs. If malicious then the next `for` loop will revert it.
         */
        (int256 uPnLCross, ) = LibMaster.calculateUPnLCross(positionPrices, party);
        bool shouldBeLiquidated = LibMaster.partyShouldBeLiquidatedCross(party, uPnLCross);
        require(shouldBeLiquidated, "Not liquidatable");

        /**
         * At this point the positionIds can still be malicious in nature. They can be:
         * - tied to a different party
         * - arbitrary positionIds
         * - no longer be valid (e.g. Muon is n-blocks behind)
         *
         * They can NOT:
         * - have a different length than the open positions list, see earlier `require`
         *
         * _calculateRealizedDistribution will catch & revert on any of the above issues.
         */
        uint256 received = 0;
        uint256 owed = 0;
        int256 lastPnL = 0;
        uint256 totalSingleLiquidationFees = 0;
        uint256 totalSingleCVA = 0;

        for (uint256 i = 0; i < positionPrices.length; i++) {
            (
                int256 pnl,
                uint256 r,
                uint256 o,
                uint256 singleLiquidationFee,
                uint256 singleCVA
            ) = _calculateRealizedDistribution(party, positionPrices[i]);
            received += r;
            owed += o;

            if (i != 0) {
                require(pnl <= lastPnL, "PNL must be in descending order");
            }
            lastPnL = pnl;
            totalSingleLiquidationFees += singleLiquidationFee;
            totalSingleCVA += singleCVA;
        }

        require(owed >= received, "Invalid realized distribution");
        uint256 deficit = owed - received;

        if (deficit < totalSingleLiquidationFees) {
            /// @dev See _distributePnLDeficitOne.
            Decimal.D256 memory liquidationFeeRatio = Decimal.ratio(
                totalSingleLiquidationFees - deficit,
                totalSingleLiquidationFees
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitOne(party, positionPrices[i], liquidationFeeRatio, msg.sender);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else if (deficit < totalSingleLiquidationFees + totalSingleCVA) {
            /// @dev See _distributePnLDeficitTwo.
            Decimal.D256 memory cvaRatio = Decimal.ratio(
                totalSingleLiquidationFees + totalSingleCVA - deficit,
                totalSingleCVA
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitTwo(party, positionPrices[i], cvaRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else if (deficit < totalSingleLiquidationFees + totalSingleCVA * 2) {
            /// @dev See _distributePnLDeficitThree.
            Decimal.D256 memory cvaRatio = Decimal.ratio(
                totalSingleLiquidationFees + (totalSingleCVA * 2) - deficit,
                totalSingleCVA
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitThree(party, positionPrices[i], cvaRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else if (deficit < totalSingleLiquidationFees * 2 + totalSingleCVA * 2) {
            /// @dev See _distributePnLDeficitFour.
            Decimal.D256 memory liquidationFeeRatio = Decimal.ratio(
                (totalSingleLiquidationFees * 2) + (totalSingleCVA * 2) - deficit,
                totalSingleLiquidationFees
            );
            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitFour(party, positionPrices[i], liquidationFeeRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        } else {
            /// @dev See _distributePnLDeficitFive.
            // The deficit is too high, winning counterparties will receive a reduced PNL.
            uint256 pendingDeficit = deficit - (totalSingleLiquidationFees * 2) + (totalSingleCVA * 2);
            Decimal.D256 memory pnlRatio = pendingDeficit >= received
                ? Decimal.ratio(0, 1) // Nobody gets ANY pnl.
                : Decimal.ratio(received - pendingDeficit, received);

            for (uint256 i = 0; i < positionPrices.length; i++) {
                _distributePnLDeficitFive(party, positionPrices[i], pnlRatio);
                _updatePositionDataCross(positionPrices[i].positionId, positionPrices[i]);
            }
        }

        // Ultimately, reset the liquidated party his lockedMargin.
        s.ma._lockedMargin[party] = 0;
    }

    function _calculateRealizedDistribution(address party, PositionPrice memory positionPrice)
        private
        view
        returns (
            int256 pnl,
            uint256 received,
            uint256 owed,
            uint256 singleLiquidationFee,
            uint256 singleCVA
        )
    {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");
        require(position.positionType == PositionType.CROSS, "Invalid position type");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        pnl = position.partyA == party ? pnlA : pnlB;

        if (pnl <= 0) {
            received = 0;
            owed = uint256(-pnl);
        } else {
            uint256 amount = uint256(pnl);
            // Counterparty is isolated
            received = amount > position.lockedMargin ? position.lockedMargin : amount;
            owed = 0;
        }

        singleLiquidationFee = position.liquidationFee;
        singleCVA = position.cva;
    }

    function _updatePositionDataIsolated(uint256 positionId, PositionPrice memory positionPrice) private {
        Position memory position = s.ma._allPositionsMap[positionId];

        _updatePositionDataBase(positionId, positionPrice);
        LibMaster.removeOpenPositionIsolated(position.partyA, position.positionId);
        LibMaster.removeOpenPositionIsolated(position.partyB, position.positionId);
    }

    function _updatePositionDataCross(uint256 positionId, PositionPrice memory positionPrice) private {
        Position memory position = s.ma._allPositionsMap[positionId];

        _updatePositionDataBase(positionId, positionPrice);
        LibMaster.removeOpenPositionCross(position.partyA, position.positionId);
        LibMaster.removeOpenPositionIsolated(position.partyB, position.positionId);
    }

    function _updatePositionDataBase(uint256 positionId, PositionPrice memory positionPrice) private {
        Position storage position = s.ma._allPositionsMap[positionId];

        // Add the Fill
        LibMaster.createFill(
            position.positionId,
            position.side == Side.BUY ? Side.SELL : Side.BUY,
            position.currentBalanceUnits,
            position.side == Side.BUY ? positionPrice.bidPrice : positionPrice.askPrice
        );

        // Update the position state
        position.state = PositionState.LIQUIDATED;
        position.currentBalanceUnits = 0;
        position.mutableTimestamp = block.timestamp;
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty
     *
     * - Deficit is covered by the liquidator, he earns the remainder.
     * - CounterParty gets his CVA back.
     * - CounterParty gets the CVA of the liquidated party.
     * - CounterParty gets his liquidationFee back.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitOne(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory liquidationFeeRatio,
        address liquidator
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = (position.cva * 2) + position.liquidationFee;

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }

        // Reward the liquidator + protocol
        uint256 liquidationFee = Decimal.mul(liquidationFeeRatio, position.liquidationFee).asUint256();
        uint256 protocolShare = Decimal.mul(C.getProtocolLiquidationShare(), liquidationFee).asUint256();
        s.ma._accountBalances[liquidator] += (liquidationFee - protocolShare);
        s.ma._accountBalances[LibDiamond.contractOwner()] += protocolShare;
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty + CVALiquidatedParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is covered by the liquidatedParty's CVA, the counterParty receives the remainder.
     * - CounterParty gets his CVA back.
     * - CounterParty gets his liquidationFee back.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitTwo(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory cvaRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = position.cva +
            Decimal.mul(cvaRatio, position.cva).asUint256() +
            position.liquidationFee;

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty + CVALiquidatedParty + CVACounterParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is not sufficiently covered by the liquidatedParty's CVA.
     * - Deficit is covered by the counterParty's CVA, he receives the remainder.
     * - CounterParty gets his liquidationFee back.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitThree(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory cvaRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = Decimal.mul(cvaRatio, position.cva).asUint256() + position.liquidationFee;

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }
    }

    /**
     * @notice Deficit < liquidationFeeLiquidatedParty + liquidationFeeCounterParty + CVALiquidatedParty + CVACounterParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is not sufficiently covered by the liquidatedParty's CVA.
     * - Deficit is not sufficiently covered by the counterParty's CVA.
     * - Deficit is covered by the counterParty's liquidationFee, he receives the remainder.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets the entire PnL.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitFour(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory liquidationFeeRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = Decimal.mul(liquidationFeeRatio, position.liquidationFee).asUint256();

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + uint256(-pnl) + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 marginReturned = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            uint256 amount = baseReturnAmount + marginReturned;
            s.ma._marginBalances[counterParty] += amount;
        }
    }

    /**
     * @notice Deficit > liquidationFeeLiquidatedParty + liquidationFeeCounterParty + CVALiquidatedParty + CVACounterParty
     *
     * - Deficit is not sufficiently covered by the liquidationFee, liquidator earns nothing.
     * - Deficit is not sufficiently covered by the liquidatedParty's CVA.
     * - Deficit is not sufficiently covered by the counterParty's CVA.
     * - Deficit is not sufficiently covered by the counterParty's liquidationFee.
     * - Deficit is covered by the counterParty's PNL.
     *
     * If PnLLiquidatedParty <= 0:
     * - counterParty gets a reduced amount of the PNL back.
     * - counterParty gets his lockedMargin back.
     *
     * If PnLLiquidatedParty > 0:
     * - counterParty gets (lockedMargin - PnLLiquidatedParty) back.
     */
    function _distributePnLDeficitFive(
        address party,
        PositionPrice memory positionPrice,
        Decimal.D256 memory pnlRatio
    ) private {
        Position storage position = s.ma._allPositionsMap[positionPrice.positionId];

        require(position.state != PositionState.LIQUIDATED, "Position already liquidated");
        require(position.partyA == party || position.partyB == party, "Invalid party");

        // Calculate the PnL of both parties.
        (int256 pnlA, int256 pnlB) = LibMaster.calculateUPnLIsolated(
            position.positionId,
            positionPrice.bidPrice,
            positionPrice.askPrice
        );

        // Extract our party's PNL
        int256 pnl = position.partyA == party ? pnlA : pnlB;

        address counterParty = position.partyA == party ? position.partyB : position.partyA;
        uint256 baseReturnAmount = Decimal.mul(pnlRatio, uint256(pnl)).asUint256();

        if (pnl <= 0) {
            uint256 amount = baseReturnAmount + position.lockedMargin;
            s.ma._marginBalances[counterParty] += amount;
        } else {
            uint256 amount = uint256(pnl) >= position.lockedMargin ? 0 : position.lockedMargin - uint256(pnl);
            s.ma._marginBalances[counterParty] += amount;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { AppStorage, LibAppStorage } from "../libraries/LibAppStorage.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondInit {
    function init(address _collateral, address _muon) external {
        // Initialize DiamondStorage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;

        // Initialize AppStorage
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.constants.collateral = _collateral;
        s.constants.muon = _muon;
        s.constants.muonAppId = 0;
        s.constants.minimumRequiredSignatures = 0;
        s.constants.protocolFee = 0.0005e18; // 0.05%
        s.constants.liquidationFee = 0.005e18; // 0.5%
        s.constants.protocolLiquidationShare = 0.1e18; // 10%
        s.constants.cva = 0.02e18; // 2%
        s.constants.requestTimeout = 2 minutes;
        s.constants.maxOpenPositionsCross = 10;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facets_ = new Facet[](selectorCount);
        // create an array for counting the number of selectors for each facet
        uint8[] memory numFacetSelectors = new uint8[](selectorCount);
        // total number of facets
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // find the functionSelectors array for selector and add selector to it
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facets_[facetIndex].facetAddress == facetAddress_) {
                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                    // probably will never have more than 256 functions from one facet contract
                    require(numFacetSelectors[facetIndex] < 255);
                    numFacetSelectors[facetIndex]++;
                    continueLoop = true;
                    break;
                }
            }
            // if functionSelectors array exists for selector then continue loop
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // create a new functionSelectors array for selector
            facets_[numFacets].facetAddress = facetAddress_;
            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);
            facets_[numFacets].functionSelectors[0] = selector;
            numFacetSelectors[numFacets] = 1;
            numFacets++;
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory _facetFunctionSelectors)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](selectorCount);
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (_facet == facetAddress_) {
                _facetFunctionSelectors[numSelectors] = selector;
                numSelectors++;
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        // create an array set to the maximum size possible
        facetAddresses_ = new address[](selectorCount);
        uint256 numFacets;
        // loop through function selectors
        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {
            bytes4 selector = ds.selectors[selectorIndex];
            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            bool continueLoop = false;
            // see if we have collected the address already and break out of loop if we have
            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                if (facetAddress_ == facetAddresses_[facetIndex]) {
                    continueLoop = true;
                    break;
                }
            }
            // continue loop if we already have the address
            if (continueLoop) {
                continueLoop = false;
                continue;
            }
            // include address
            facetAddresses_[numFacets] = facetAddress_;
            numFacets++;
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet address that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libraries/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";
import { AppStorage } from "./libraries/LibAppStorage.sol";

contract Diamond {
    AppStorage internal s;

    receive() external payable {}

    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facetAddressAndSelectorPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { Ownable } from "../utils/Ownable.sol";
import { AppStorage } from "../libraries/LibAppStorage.sol";

contract OwnershipFacet is Ownable {
    AppStorage internal s;

    function transferOwnership(address _newOwner) external onlyOwner {
        s.ownerCandidate = _newOwner;
    }

    function claimOwnership() external {
        require(s.ownerCandidate == msg.sender, "Ownership: Not candidate");
        LibDiamond.setContractOwner(msg.sender);
        delete s.ownerCandidate;
    }

    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }

    function ownerCandidate() external view returns (address ownerCandidate_) {
        ownerCandidate_ = s.ownerCandidate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibDiamond } from "../libraries/LibDiamond.sol";

abstract contract Ownable {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyOwnerOrContract() {
        LibDiamond.enforceIsOwnerOrContract();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { Ownable } from "../utils/Ownable.sol";
import { LibMarkets } from "../libraries/LibMarkets.sol";
import { AppStorage, Market } from "../libraries/LibAppStorage.sol";
import "../libraries/LibEnums.sol";

contract MarketsFacet is Ownable {
    AppStorage internal s;

    event CreateMarket(uint256 indexed marketId);
    event UpdateMarketStatus(uint256 indexed marketId, bool oldStatus, bool newStatus);

    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function createMarket(
        string memory identifier,
        MarketType marketType,
        TradingSession tradingSession,
        bool active,
        string memory baseCurrency,
        string memory quoteCurrency,
        string memory symbol
    ) external onlyOwner returns (Market memory market) {
        uint256 currentMarketId = s.markets._marketList.length + 1;
        market = Market(
            currentMarketId,
            identifier,
            marketType,
            tradingSession,
            active,
            baseCurrency,
            quoteCurrency,
            symbol
        );

        s.markets._marketMap[currentMarketId] = market;
        s.markets._marketList.push(market);

        emit CreateMarket(currentMarketId);
    }

    function updateMarketStatus(uint256 marketId, bool status) external onlyOwner {
        s.markets._marketMap[marketId].active = status;
        emit UpdateMarketStatus(marketId, !status, status);
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getMarketById(uint256 marketId) external view returns (Market memory market) {
        return s.markets._marketMap[marketId];
    }

    function getMarkets() external view returns (Market[] memory markets) {
        return s.markets._marketList;
    }

    function getMarketsLength() external view returns (uint256 length) {
        return s.markets._marketList.length;
    }

    function getMarketFromPositionId(uint256 positionId) external view returns (Market memory market) {
        uint256 marketId = s.ma._allPositionsMap[positionId].marketId;
        market = s.markets._marketMap[marketId];
    }

    function getMarketsFromPositionIds(uint256[] calldata positionIds) external view returns (Market[] memory markets) {
        markets = new Market[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 marketId = s.ma._allPositionsMap[positionIds[i]].marketId;
            markets[i] = s.markets._marketMap[marketId];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { Ownable } from "../utils/Ownable.sol";
import { AppStorage } from "../libraries/LibAppStorage.sol";
import { C } from "../C.sol";

contract ConstantsFacet is Ownable {
    AppStorage internal s;

    function setCollateral(address _collateral) external onlyOwner {
        s.constants.collateral = _collateral;
    }

    function setMuon(address _muon) external onlyOwner {
        s.constants.muon = _muon;
    }

    function setMuonAppId(uint16 _muonAppId) external onlyOwner {
        s.constants.muonAppId = _muonAppId;
    }

    function setMinimumRequiredSignatures(uint8 _minimumRequiredSignatures) external onlyOwner {
        s.constants.minimumRequiredSignatures = _minimumRequiredSignatures;
    }

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        s.constants.protocolFee = _protocolFee;
    }

    function setLiquidationFee(uint256 _liquidationFee) external onlyOwner {
        s.constants.liquidationFee = _liquidationFee;
    }

    function setProtocolLiquidationShare(uint256 _protocolLiquidationShare) external onlyOwner {
        s.constants.protocolLiquidationShare = _protocolLiquidationShare;
    }

    function setCVA(uint256 _cva) external onlyOwner {
        s.constants.cva = _cva;
    }

    function setRequestTimeout(uint256 _requestTimeout) external onlyOwner {
        s.constants.requestTimeout = _requestTimeout;
    }

    function setMaxOpenPositionsCross(uint256 _maxOpenPositionsCross) external onlyOwner {
        s.constants.maxOpenPositionsCross = _maxOpenPositionsCross;
    }

    //--- READ FUNCTIONS ---\\
    function getPrecision() external pure returns (uint256) {
        return C.getPrecision();
    }

    function getPercentBase() external pure returns (uint256) {
        return C.getPercentBase();
    }

    function getCollateral() external view returns (address) {
        return C.getCollateral();
    }

    function getMuon() external view returns (address) {
        return C.getMuon();
    }

    function getMuonAppId() external view returns (uint16) {
        return C.getMuonAppId();
    }

    function getMinimumRequiredSignatures() external view returns (uint8) {
        return C.getMinimumRequiredSignatures();
    }

    function getProtocolFee() external view returns (uint256) {
        return C.getProtocolFee().value;
    }

    function getLiquidationFee() external view returns (uint256) {
        return C.getLiquidationFee().value;
    }

    function getProtocolLiquidationShare() external view returns (uint256) {
        return C.getProtocolLiquidationShare().value;
    }

    function getCVA() external view returns (uint256) {
        return C.getCVA().value;
    }

    function getRequestTimeout() external view returns (uint256) {
        return C.getRequestTimeout();
    }

    function getMaxOpenPositionsCross() external view returns (uint256) {
        return C.getMaxOpenPositionsCross();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { LibHedgers } from "../libraries/LibHedgers.sol";
import { AppStorage, Hedger } from "../libraries/LibAppStorage.sol";

contract HedgersFacet {
    AppStorage internal s;

    event Enlist(address indexed hedger);
    event UpdatePricingURLs(address indexed hedger, string[] pricingURLs);
    event UpdateMarketsURLs(address indexed hedger, string[] marketsURLs);

    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function enlist(string[] calldata pricingWssURLs, string[] calldata marketsHttpsURLs)
        external
        returns (Hedger memory hedger)
    {
        require(msg.sender != address(0), "Invalid address");
        require(s.hedgers._hedgerMap[msg.sender].addr != msg.sender, "Hedger already exists");

        require(pricingWssURLs.length > 0, "pricingWebsocketURLs must be non-empty");
        require(marketsHttpsURLs.length > 0, "pricingWebsocketURLs must be non-empty");
        mustBeHTTPSOrThrow(marketsHttpsURLs);
        mustBeWSSOrThrow(pricingWssURLs);

        hedger = Hedger(msg.sender, pricingWssURLs, marketsHttpsURLs);
        s.hedgers._hedgerMap[msg.sender] = hedger;
        s.hedgers._hedgerList.push(hedger);

        emit Enlist(msg.sender);
    }

    function updatePricingWssURLs(string[] calldata _pricingWssURLs) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);

        require(hedger.addr == msg.sender, "Access Denied");
        require(_pricingWssURLs.length > 0, "pricingWssURLs must be non-empty");
        mustBeWSSOrThrow(_pricingWssURLs);

        s.hedgers._hedgerMap[msg.sender].pricingWssURLs = _pricingWssURLs;

        emit UpdatePricingURLs(msg.sender, _pricingWssURLs);
    }

    function updateMarketsHttpsURLs(string[] calldata _marketsHttpsURLs) external {
        Hedger memory hedger = LibHedgers.getHedgerByAddressOrThrow(msg.sender);

        require(hedger.addr == msg.sender, "Access Denied");
        require(_marketsHttpsURLs.length > 0, "marketsHttpsURLs must be non-empty");
        mustBeHTTPSOrThrow(_marketsHttpsURLs);

        s.hedgers._hedgerMap[msg.sender].marketsHttpsURLs = _marketsHttpsURLs;

        emit UpdateMarketsURLs(msg.sender, _marketsHttpsURLs);
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getHedgerByAddress(address addr) external view returns (bool success, Hedger memory hedger) {
        hedger = s.hedgers._hedgerMap[addr];
        return hedger.addr == address(0) ? (false, hedger) : (true, hedger);
    }

    function getHedgers() external view returns (Hedger[] memory hedgerList) {
        return s.hedgers._hedgerList;
    }

    function getHedgersLength() external view returns (uint256 length) {
        return s.hedgers._hedgerList.length;
    }

    // --------------------------------//
    //----- PRIVATE VIEW FUNCTIONS ----//
    // --------------------------------//

    function substringASCII(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) private pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function mustBeWSSOrThrow(string[] calldata urls) private pure {
        for (uint256 i = 0; i < urls.length; i++) {
            require(compareStrings(substringASCII(urls[i], 0, 6), "wss://"), "websocketURLs must be secure");
        }
    }

    function mustBeHTTPSOrThrow(string[] calldata urls) private pure {
        for (uint256 i = 0; i < urls.length; i++) {
            require(compareStrings(substringASCII(urls[i], 0, 8), "https://"), "httpsURLs must be secure");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";
import { C } from "../C.sol";
import { LibHedgers } from "../libraries/LibHedgers.sol";
import { LibOracle, PositionPrice } from "../libraries/LibOracle.sol";
import { LibMaster } from "../libraries/LibMaster.sol";
import { SchnorrSign } from "../interfaces/IMuonV03.sol";

contract AccountFacet is ReentrancyGuard {
    event Deposit(address indexed party, uint256 amount);
    event Withdraw(address indexed party, uint256 amount);
    event Allocate(address indexed party, uint256 amount);
    event Deallocate(address indexed party, uint256 amount);
    event AddFreeMargin(address indexed party, uint256 amount);
    event RemoveFreeMargin(address indexed party, uint256 amount);

    // --------------------------------//
    //----- PUBLIC WRITE FUNCTIONS ----//
    // --------------------------------//

    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _withdraw(msg.sender, amount);
    }

    function allocate(uint256 amount) external {
        _allocate(msg.sender, amount);
    }

    function deallocate(uint256 amount) external {
        _deallocate(msg.sender, amount);
    }

    function depositAndAllocate(uint256 amount) external {
        _deposit(msg.sender, amount);
        _allocate(msg.sender, amount);
    }

    function deallocateAndWithdraw(uint256 amount) external {
        _deallocate(msg.sender, amount);
        _withdraw(msg.sender, amount);
    }

    function addFreeMargin(uint256 amount) external {
        _addFreeMargin(msg.sender, amount);
    }

    function removeFreeMargin() external {
        _removeFreeMargin(msg.sender);
    }

    // --------------------------------//
    //----- PRIVATE WRITE FUNCTIONS ---//
    // --------------------------------//

    function _deposit(address party, uint256 amount) private nonReentrant {
        bool success = IERC20(C.getCollateral()).transferFrom(party, address(this), amount);
        require(success, "Failed to deposit collateral");
        s.ma._accountBalances[party] += amount;

        emit Deposit(party, amount);
    }

    function _withdraw(address party, uint256 amount) private nonReentrant {
        require(s.ma._accountBalances[party] >= amount, "Insufficient account balance");
        s.ma._accountBalances[party] -= amount;
        bool success = IERC20(C.getCollateral()).transfer(party, amount);
        require(success, "Failed to withdraw collateral");

        emit Withdraw(party, amount);
    }

    function _allocate(address party, uint256 amount) private nonReentrant {
        require(s.ma._accountBalances[party] >= amount, "Insufficient account balance");
        s.ma._accountBalances[party] -= amount;
        s.ma._marginBalances[party] += amount;

        emit Allocate(party, amount);
    }

    function _deallocate(address party, uint256 amount) private nonReentrant {
        require(s.ma._marginBalances[party] >= amount, "Insufficient margin balance");
        s.ma._marginBalances[party] -= amount;
        s.ma._accountBalances[party] += amount;

        emit Deallocate(party, amount);
    }

    function _addFreeMargin(address party, uint256 amount) private {
        require(s.ma._marginBalances[party] >= amount, "Insufficient margin balance");
        s.ma._marginBalances[party] -= amount;
        s.ma._lockedMargin[party] += amount;

        emit AddFreeMargin(party, amount);
    }

    function _removeFreeMargin(address party) private {
        require(s.ma._openPositionsCrossList[party].length == 0, "Removal denied");
        require(s.ma._lockedMargin[party] > 0, "No locked margin");

        uint256 amount = s.ma._lockedMargin[party];
        s.ma._lockedMargin[party] = 0;
        s.ma._marginBalances[party] += amount;

        emit RemoveFreeMargin(party, amount);
    }

    // --------------------------------//
    //----- PUBLIC VIEW FUNCTIONS -----//
    // --------------------------------//

    function getAccountBalance(address party) external view returns (uint256) {
        return s.ma._accountBalances[party];
    }

    function getMarginBalance(address party) external view returns (uint256) {
        return s.ma._marginBalances[party];
    }

    function getLockedMargin(address party) external view returns (uint256) {
        return s.ma._lockedMargin[party];
    }

    function getLockedMarginReserved(address party) external view returns (uint256) {
        return s.ma._lockedMarginReserved[party];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import { AppStorage } from "../libraries/LibAppStorage.sol";

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    AppStorage internal s;

    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICollateral is IERC20 {
    function mint(address to, uint256 amount) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FakeStablecoin is ERC20 {
    constructor() ERC20("FakeStablecoin", "FUSD") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}