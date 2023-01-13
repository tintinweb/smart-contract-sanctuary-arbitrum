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

import { MarketsInternal } from "./MarketsInternal.sol";
import { Market } from "./MarketsStorage.sol";

contract Markets {
    function getMarkets() external view returns (Market[] memory markets) {
        return MarketsInternal.getMarkets();
    }

    function getMarketById(uint256 marketId) external view returns (Market memory market) {
        return MarketsInternal.getMarketById(marketId);
    }

    function getMarketsByIds(uint256[] memory marketIds) external view returns (Market[] memory markets) {
        return MarketsInternal.getMarketsByIds(marketIds);
    }

    function getMarketsInRange(uint256 start, uint256 end) external view returns (Market[] memory markets) {
        return MarketsInternal.getMarketsInRange(start, end);
    }

    function getMarketsLength() external view returns (uint256 length) {
        return MarketsInternal.getMarketsLength();
    }

    function getMarketFromPositionId(uint256 positionId) external view returns (Market memory market) {
        return MarketsInternal.getMarketFromPositionId(positionId);
    }

    function getMarketsFromPositionIds(uint256[] calldata positionIds) external view returns (Market[] memory markets) {
        return MarketsInternal.getMarketsFromPositionIds(positionIds);
    }

    function getMarketProtocolFee(uint256 marketId) external view returns (uint256) {
        return MarketsInternal.getMarketProtocolFee(marketId).value;
    }

    function isValidMarketId(uint256 marketId) external pure returns (bool) {
        return MarketsInternal.isValidMarketId(marketId);
    }

    function isActiveMarket(uint256 marketId) external view returns (bool) {
        return MarketsInternal.isActiveMarket(marketId);
    }
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
        mapping(address => uint256) crossLockedMarginReserved;
        // RequestForQuotes
        mapping(uint256 => RequestForQuote) requestForQuotesMap;
        uint256 requestForQuotesLength;
        mapping(address => uint256) crossRequestForQuotesLength;
        // Positions
        mapping(uint256 => Position) allPositionsMap;
        uint256 allPositionsLength;
        mapping(address => uint256) openPositionsIsolatedLength;
        mapping(address => uint256) openPositionsCrossLength;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}