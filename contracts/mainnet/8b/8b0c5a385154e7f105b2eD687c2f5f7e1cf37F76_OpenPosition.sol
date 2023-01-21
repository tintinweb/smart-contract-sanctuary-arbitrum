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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Decimal } from "../libraries/LibDecimal.sol";
import { ConstantsStorage } from "./ConstantsStorage.sol";
import { IConstantsEvents } from "./IConstantsEvents.sol";

library ConstantsInternal {
    using ConstantsStorage for ConstantsStorage.Layout;
    using Decimal for Decimal.D256;

    uint256 private constant PERCENT_BASE = 1e18;
    uint256 private constant PRECISION = 1e18;

    /* ========== VIEWS ========== */

    function getPrecision() internal pure returns (uint256) {
        return PRECISION;
    }

    function getPercentBase() internal pure returns (uint256) {
        return PERCENT_BASE;
    }

    function getCollateral() internal view returns (address) {
        return ConstantsStorage.layout().collateral;
    }

    function getLiquidationFee() internal view returns (Decimal.D256 memory) {
        return Decimal.ratio(ConstantsStorage.layout().liquidationFee, PERCENT_BASE);
    }

    function getProtocolLiquidationShare() internal view returns (Decimal.D256 memory) {
        return Decimal.ratio(ConstantsStorage.layout().protocolLiquidationShare, PERCENT_BASE);
    }

    function getCVA() internal view returns (Decimal.D256 memory) {
        return Decimal.ratio(ConstantsStorage.layout().cva, PERCENT_BASE);
    }

    function getRequestTimeout() internal view returns (uint256) {
        return ConstantsStorage.layout().requestTimeout;
    }

    function getMaxOpenPositionsCross() internal view returns (uint256) {
        return ConstantsStorage.layout().maxOpenPositionsCross;
    }

    /* ========== SETTERS ========== */

    function setCollateral(address collateral) internal {
        ConstantsStorage.layout().collateral = collateral;
    }

    function setLiquidationFee(uint256 liquidationFee) internal {
        ConstantsStorage.layout().liquidationFee = liquidationFee;
    }

    function setProtocolLiquidationShare(uint256 protocolLiquidationShare) internal {
        ConstantsStorage.layout().protocolLiquidationShare = protocolLiquidationShare;
    }

    function setCVA(uint256 cva) internal {
        ConstantsStorage.layout().cva = cva;
    }

    function setRequestTimeout(uint256 requestTimeout) internal {
        ConstantsStorage.layout().requestTimeout = requestTimeout;
    }

    function setMaxOpenPositionsCross(uint256 maxOpenPositionsCross) internal {
        ConstantsStorage.layout().maxOpenPositionsCross = maxOpenPositionsCross;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

library ConstantsStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.constants.storage");

    struct Layout {
        address collateral;
        uint256 liquidationFee;
        uint256 protocolLiquidationShare;
        uint256 cva;
        uint256 requestTimeout;
        uint256 maxOpenPositionsCross;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IConstantsEvents {
    event SetCollateral(address oldAddress, address newAddress);
    event SetLiquidationFee(uint256 oldFee, uint256 newFee);
    event SetProtocolLiquidationShare(uint256 oldShare, uint256 newShare);
    event SetCVA(uint256 oldCVA, uint256 newCVA);
    event SetRequestTimeout(uint256 oldTimeout, uint256 newTimeout);
    event SetMaxOpenPositionsCross(uint256 oldMax, uint256 newMax);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

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

    uint256 constant BASE = 10 ** 18;

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

    function sub(D256 memory self, uint256 b, string memory reason) internal pure returns (D256 memory) {
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

    function sub(D256 memory self, D256 memory b, string memory reason) internal pure returns (D256 memory) {
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

    function getPartial(uint256 target, uint256 numerator, uint256 denominator) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

enum MarketType {
    FOREX,
    METALS,
    ENERGIES,
    INDICES,
    STOCKS,
    COMMODITIES,
    BONDS,
    ETFS,
    CRYPTO
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Decimal } from "../libraries/LibDecimal.sol";
import { ConstantsInternal } from "../constants/ConstantsInternal.sol";
import { MarketsStorage, Market } from "./MarketsStorage.sol";
import { MasterStorage } from "../master-agreement/MasterStorage.sol";

library MarketsInternal {
    using MarketsStorage for MarketsStorage.Layout;
    using MasterStorage for MasterStorage.Layout;
    using Decimal for Decimal.D256;

    /* ========== VIEWS ========== */

    function getMarkets() internal view returns (Market[] memory markets) {
        return getMarketsInRange(1, MarketsStorage.layout().marketList.length);
    }

    function getMarketById(uint256 marketId) internal view returns (Market memory market) {
        return MarketsStorage.layout().marketMap[marketId];
    }

    function getMarketsByIds(uint256[] memory marketIds) internal view returns (Market[] memory markets) {
        markets = new Market[](marketIds.length);
        for (uint256 i = 0; i < marketIds.length; i++) {
            markets[i] = MarketsStorage.layout().marketMap[marketIds[i]];
        }
    }

    function getMarketsInRange(uint256 start, uint256 end) internal view returns (Market[] memory markets) {
        uint256 length = end - start + 1;
        markets = new Market[](length);

        for (uint256 i = 0; i < length; i++) {
            markets[i] = MarketsStorage.layout().marketMap[start + i];
        }
    }

    function getMarketsLength() internal view returns (uint256 length) {
        return MarketsStorage.layout().marketList.length;
    }

    function getMarketFromPositionId(uint256 positionId) internal view returns (Market memory market) {
        uint256 marketId = MasterStorage.layout().allPositionsMap[positionId].marketId;
        market = MarketsStorage.layout().marketMap[marketId];
    }

    function getMarketsFromPositionIds(uint256[] calldata positionIds) internal view returns (Market[] memory markets) {
        markets = new Market[](positionIds.length);
        for (uint256 i = 0; i < positionIds.length; i++) {
            uint256 marketId = MasterStorage.layout().allPositionsMap[positionIds[i]].marketId;
            markets[i] = MarketsStorage.layout().marketMap[marketId];
        }
    }

    function getMarketProtocolFee(uint256 marketId) internal view returns (Decimal.D256 memory) {
        uint256 fee = MarketsStorage.layout().marketMap[marketId].protocolFee;
        return Decimal.ratio(fee, ConstantsInternal.getPercentBase());
    }

    function isValidMarketId(uint256 marketId) internal pure returns (bool) {
        return marketId > 0;
    }

    function isActiveMarket(uint256 marketId) internal view returns (bool) {
        return MarketsStorage.layout().marketMap[marketId].active;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { MarketType } from "../libraries/LibEnums.sol";

struct Market {
    uint256 marketId;
    string identifier;
    MarketType marketType;
    bool active;
    string baseCurrency;
    string quoteCurrency;
    string symbol;
    bytes32 muonPriceFeedId;
    bytes32 fundingRateId;
    uint256 protocolFee;
}

library MarketsStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.markets.storage");

    struct Layout {
        mapping(uint256 => Market) marketMap;
        Market[] marketList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { Side } from "../libraries/LibEnums.sol";
import { Decimal } from "../libraries/LibDecimal.sol";
import { PositionPrice } from "../oracle/OracleStorage.sol";
import { ConstantsInternal } from "../constants/ConstantsInternal.sol";
import { MarketsInternal } from "../markets/MarketsInternal.sol";
import { MasterStorage, Position } from "./MasterStorage.sol";

library MasterCalculators {
    using Decimal for Decimal.D256;
    using MasterStorage for MasterStorage.Layout;

    /**
     * @notice Returns the UPnL for a specific position.
     * @dev This is a naive function, inputs can not be trusted. Use cautiously.
     */
    function calculateUPnLIsolated(
        uint256 positionId,
        uint256 bidPrice,
        uint256 askPrice
    ) internal view returns (int256 uPnLA, int256 uPnLB) {
        MasterStorage.Layout storage s = MasterStorage.layout();
        Position memory position = s.allPositionsMap[positionId];

        (uPnLA, uPnLB) = _calculateUPnLIsolated(
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
    function calculateUPnLCross(
        PositionPrice[] memory positionPrices,
        address party
    ) internal view returns (int256 uPnLCross) {
        return _calculateUPnLCross(positionPrices, party);
    }

    function calculateProtocolFeeAmount(uint256 marketId, uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(MarketsInternal.getMarketProtocolFee(marketId)).asUint256();
    }

    function calculateLiquidationFeeAmount(uint256 notionalUsd) internal view returns (uint256) {
        return Decimal.from(notionalUsd).mul(ConstantsInternal.getLiquidationFee()).asUint256();
    }

    function calculateCVAAmount(uint256 notionalSize) internal view returns (uint256) {
        return Decimal.from(notionalSize).mul(ConstantsInternal.getCVA()).asUint256();
    }

    function calculateCrossMarginHealth(
        address party,
        int256 uPnLCross
    ) internal view returns (Decimal.D256 memory ratio) {
        MasterStorage.Layout storage s = MasterStorage.layout();

        uint256 lockedMargin = s.crossLockedMargin[party];
        uint256 openPositions = s.openPositionsCrossLength[party];

        if (lockedMargin == 0 && openPositions == 0) {
            return Decimal.ratio(1, 1);
        } else if (lockedMargin == 0) {
            return Decimal.zero();
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

    /* ========== PRIVATE ========== */

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
    ) private pure returns (int256 uPnLA, int256 uPnLB) {
        if (currentBalanceUnits == 0) return (0, 0);

        uint256 precision = ConstantsInternal.getPrecision();
        if (side == Side.BUY) {
            require(bidPrice != 0, "Oracle bidPrice is invalid");
            int256 notionalIsolatedA = int256((currentBalanceUnits * bidPrice) / precision);
            uPnLA = notionalIsolatedA - int256(initialNotionalUsd);
        } else {
            require(askPrice != 0, "Oracle askPrice is invalid");
            int256 notionalIsolatedA = int256((currentBalanceUnits * askPrice) / precision);
            uPnLA = int256(initialNotionalUsd) - notionalIsolatedA;
        }

        return (uPnLA, -uPnLA);
    }

    /**
     * @notice Returns the UPnL of a party across all his open positions.
     * @dev This is a naive function, inputs can NOT be trusted. Use cautiously.
     * @dev positionPrices can have an incorrect length.
     * @dev positionPrices can have an arbitrary order.
     * @dev positionPrices can contain forged duplicates.
     */
    function _calculateUPnLCross(
        PositionPrice[] memory positionPrices,
        address party
    ) private view returns (int256 uPnLCrossA) {
        MasterStorage.Layout storage s = MasterStorage.layout();

        for (uint256 i = 0; i < positionPrices.length; i++) {
            uint256 positionId = positionPrices[i].positionId;
            uint256 bidPrice = positionPrices[i].bidPrice;
            uint256 askPrice = positionPrices[i].askPrice;

            Position memory position = s.allPositionsMap[positionId];
            require(position.partyA == party, "PositionId mismatch");

            (int256 _uPnLIsolatedA, ) = _calculateUPnLIsolated(
                position.side,
                position.currentBalanceUnits,
                position.initialNotionalUsd,
                bidPrice,
                askPrice
            );

            uPnLCrossA += _uPnLIsolatedA;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { PositionType, OrderType, HedgerMode, Side } from "../libraries/LibEnums.sol";

enum RequestForQuoteState {
    NEW,
    CANCELED,
    ACCEPTED
}

enum PositionState {
    OPEN,
    MARKET_CLOSE_REQUESTED,
    LIMIT_CLOSE_REQUESTED,
    LIMIT_CLOSE_ACTIVE,
    CLOSED,
    LIQUIDATED
    // TODO: add cancel limit close
}

struct RequestForQuote {
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
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
    uint256 lockedMarginA;
    uint256 protocolFee;
    uint256 liquidationFee;
    uint256 cva;
    uint256 minExpectedUnits;
    uint256 maxExpectedUnits;
    address affiliate;
}

struct Position {
    uint256 creationTimestamp;
    uint256 mutableTimestamp;
    uint256 positionId;
    bytes16 uuid;
    PositionState state;
    PositionType positionType;
    uint256 marketId;
    address partyA;
    address partyB;
    Side side;
    uint256 lockedMarginA;
    uint256 lockedMarginB;
    uint256 protocolFeePaid;
    uint256 liquidationFee;
    uint256 cva;
    uint256 currentBalanceUnits;
    uint256 initialNotionalUsd;
    address affiliate;
}

library MasterStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.master.agreement.storage");

    struct Layout {
        // Balances
        mapping(address => uint256) accountBalances;
        mapping(address => uint256) marginBalances;
        mapping(address => uint256) crossLockedMargin;
        mapping(address => uint256) crossLockedMarginReserved; // TODO: rename this to lockedMarginReserved
        // RequestForQuotes
        mapping(uint256 => RequestForQuote) requestForQuotesMap;
        uint256 requestForQuotesLength;
        mapping(address => uint256) crossRequestForQuotesLength;
        // Positions
        mapping(uint256 => Position) allPositionsMap;
        uint256 allPositionsLength;
        mapping(address => uint256) openPositionsIsolatedLength; // DEPRECATED
        mapping(address => uint256) openPositionsCrossLength;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

interface IOpenEvents {
    event RequestForQuoteNew(uint256 indexed rfqId, address partyA, address partyB);
    event RequestForQuoteCanceled(uint256 indexed rfqId, address partyA, address partyB);
    event OpenPosition(
        uint256 indexed rfqId,
        uint256 indexed positionId,
        address partyA,
        address partyB,
        uint256 amountUnits,
        uint256 avgPriceUsd
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { PositionType, OrderType, HedgerMode, Side } from "../../libraries/LibEnums.sol";
import { MarketsInternal } from "../../markets/MarketsInternal.sol";
import { ConstantsInternal } from "../../constants/ConstantsInternal.sol";
import { MasterStorage, RequestForQuote, RequestForQuoteState, Position, PositionState } from "../MasterStorage.sol";
import { MasterCalculators } from "../MasterCalculators.sol";
import { IOpenEvents } from "./IOpenEvents.sol";

abstract contract OpenBase is IOpenEvents {
    using MasterStorage for MasterStorage.Layout;

    function _onRequestForQuote(
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
        uint256 maxExpectedUnits,
        address affiliate
    ) internal returns (RequestForQuote memory rfq) {
        MasterStorage.Layout storage s = MasterStorage.layout();

        // This inherently validates the existence of a market as well.
        require(MarketsInternal.isActiveMarket(marketId), "Market not active");

        if (positionType == PositionType.CROSS) {
            uint256 numOpenPositionsCross = s.openPositionsCrossLength[partyA];
            uint256 numOpenRfqsCross = s.crossRequestForQuotesLength[partyA];
            require(
                numOpenPositionsCross + numOpenRfqsCross < ConstantsInternal.getMaxOpenPositionsCross(),
                "Max open positions cross reached"
            );
        }

        require(usdAmountToSpend > 0, "Amount cannot be zero");
        uint256 notionalUsd = usdAmountToSpend * leverage;
        uint256 protocolFee = MasterCalculators.calculateProtocolFeeAmount(marketId, notionalUsd);
        uint256 liquidationFee = MasterCalculators.calculateLiquidationFeeAmount(notionalUsd);
        uint256 cva = MasterCalculators.calculateCVAAmount(notionalUsd);
        uint256 amount = usdAmountToSpend + protocolFee + liquidationFee + cva;

        require(amount <= s.marginBalances[partyA], "Insufficient margin balance");
        s.marginBalances[partyA] -= amount;
        s.crossLockedMarginReserved[partyA] += amount; // TODO: rename this to lockedMarginReserved

        // Create the RFQ
        uint256 currentRfqId = s.requestForQuotesLength + 1;
        rfq = RequestForQuote({
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp,
            rfqId: currentRfqId,
            state: RequestForQuoteState.NEW,
            positionType: positionType,
            orderType: orderType,
            partyA: partyA,
            partyB: partyB,
            hedgerMode: hedgerMode,
            marketId: marketId,
            side: side,
            notionalUsd: notionalUsd,
            lockedMarginA: usdAmountToSpend,
            protocolFee: protocolFee,
            liquidationFee: liquidationFee,
            cva: cva,
            minExpectedUnits: minExpectedUnits,
            maxExpectedUnits: maxExpectedUnits,
            affiliate: affiliate
        });

        s.requestForQuotesMap[currentRfqId] = rfq;
        s.requestForQuotesLength++;

        // Increase the number of active RFQs
        if (positionType == PositionType.CROSS) {
            s.crossRequestForQuotesLength[partyA]++;
        }
    }

    function _openPositionMarket(
        address partyB,
        uint256 rfqId,
        uint256 filledAmountUnits,
        bytes16 uuid,
        uint256 lockedMarginB
    ) internal returns (Position memory position) {
        MasterStorage.Layout storage s = MasterStorage.layout();
        RequestForQuote storage rfq = s.requestForQuotesMap[rfqId];

        require(rfq.state == RequestForQuoteState.NEW, "Invalid RFQ state");
        require(rfq.minExpectedUnits <= filledAmountUnits, "Invalid min filled amount");
        require(rfq.maxExpectedUnits >= filledAmountUnits, "Invalid max filled amount");

        // Update the RFQ
        _updateRequestForQuoteState(rfq, RequestForQuoteState.ACCEPTED);

        // Create the Position
        uint256 currentPositionId = s.allPositionsLength + 1;
        position = Position({
            creationTimestamp: block.timestamp,
            mutableTimestamp: block.timestamp,
            positionId: currentPositionId,
            uuid: uuid,
            state: PositionState.OPEN,
            positionType: rfq.positionType,
            marketId: rfq.marketId,
            partyA: rfq.partyA,
            partyB: rfq.partyB,
            side: rfq.side,
            lockedMarginA: rfq.lockedMarginA,
            lockedMarginB: lockedMarginB,
            protocolFeePaid: rfq.protocolFee,
            liquidationFee: rfq.liquidationFee,
            cva: rfq.cva,
            currentBalanceUnits: filledAmountUnits,
            initialNotionalUsd: rfq.notionalUsd,
            affiliate: rfq.affiliate
        });

        // Update global mappings
        s.allPositionsMap[currentPositionId] = position;
        s.allPositionsLength++;

        // Transfer partyA's collateral
        uint256 deductableMarginA = rfq.lockedMarginA + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.crossLockedMarginReserved[rfq.partyA] -= deductableMarginA; // TODO: rename this to lockedMarginReserved

        // Transfer partyB's collateral
        uint256 deductableMarginB = lockedMarginB + rfq.liquidationFee + rfq.cva; // hedger doesn't pay protocolFee
        require(deductableMarginB <= s.marginBalances[partyB], "Insufficient margin balance");
        s.marginBalances[partyB] -= deductableMarginB;

        // Collect the fee paid by partyA
        s.accountBalances[address(this)] += rfq.protocolFee;

        if (rfq.positionType == PositionType.CROSS) {
            // Increase the number of open positions
            s.openPositionsCrossLength[rfq.partyA]++;

            // Decrease the number of active RFQs
            s.crossRequestForQuotesLength[rfq.partyA]--;

            // Lock margins
            s.crossLockedMargin[rfq.partyA] += rfq.lockedMarginA;
            s.crossLockedMargin[partyB] += lockedMarginB;
        }
    }

    function _updateRequestForQuoteState(RequestForQuote storage rfq, RequestForQuoteState state) internal {
        rfq.state = state;
        rfq.mutableTimestamp = block.timestamp;
    }

    function _cancelRequestForQuote(RequestForQuote memory rfq) internal {
        MasterStorage.Layout storage s = MasterStorage.layout();

        // Return user funds
        uint256 reservedMargin = rfq.lockedMarginA + rfq.protocolFee + rfq.liquidationFee + rfq.cva;
        s.crossLockedMarginReserved[rfq.partyA] -= reservedMargin; // TODO: rename this to lockedMarginReserved
        s.marginBalances[rfq.partyA] += reservedMargin;

        // Decrease the number of active RFQs
        if (rfq.positionType == PositionType.CROSS) {
            s.crossRequestForQuotesLength[rfq.partyA]--;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

import { OrderType, HedgerMode } from "../../libraries/LibEnums.sol";
import { MasterStorage, RequestForQuote, Position } from "../MasterStorage.sol";
import { OpenBase } from "./OpenBase.sol";

contract OpenPosition is OpenBase {
    using MasterStorage for MasterStorage.Layout;

    function openPosition(
        uint256 rfqId,
        uint256 filledAmountUnits,
        uint256 avgPriceUsd,
        bytes16 uuid,
        uint256 lockedMarginB
    ) external returns (Position memory position) {
        RequestForQuote storage rfq = MasterStorage.layout().requestForQuotesMap[rfqId];

        if (rfq.hedgerMode == HedgerMode.SINGLE && rfq.orderType == OrderType.MARKET) {
            position = _openPositionMarketSingle(rfq, filledAmountUnits, uuid, lockedMarginB);
        } else {
            revert("Other modes not implemented yet");
        }

        emit OpenPosition(rfq.rfqId, position.positionId, rfq.partyA, rfq.partyB, filledAmountUnits, avgPriceUsd);
    }

    function _openPositionMarketSingle(
        RequestForQuote memory rfq,
        uint256 filledAmountUnits,
        bytes16 uuid,
        uint256 lockedMarginB
    ) private returns (Position memory position) {
        require(rfq.partyB == msg.sender, "Invalid party");
        return _openPositionMarket(msg.sender, rfq.rfqId, filledAmountUnits, uuid, lockedMarginB);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.16;

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct PositionPrice {
    uint256 positionId;
    uint256 bidPrice;
    uint256 askPrice;
}

library OracleStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("diamond.standard.oracle.storage");

    struct Layout {
        uint256 muonAppId;
        bytes muonAppCID;
        PublicKey muonPublicKey;
        address muonGatewaySigner;
        uint256 signatureExpiryPeriod;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}