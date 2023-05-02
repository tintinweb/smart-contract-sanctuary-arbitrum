// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import "../../math/SafeInt256.sol";
import "../../../interfaces/chainlink/AggregatorV2V3Interface.sol";

contract ChainlinkAdapter is AggregatorV2V3Interface {
    using SafeInt256 for int256;
    uint8 public override constant decimals = 18;
    uint256 public override constant version = 1;
    int256 public constant rateDecimals = 10**18;

    string public override description;
    // Grace period after a sequencer downtime has occurred
    uint256 public constant SEQUENCER_UPTIME_GRACE_PERIOD = 1 hours;

    AggregatorV2V3Interface public immutable baseToUSDOracle;
    int256 public immutable baseToUSDDecimals;
    AggregatorV2V3Interface public immutable quoteToUSDOracle;
    int256 public immutable quoteToUSDDecimals;
    bool public immutable invertBase;
    bool public immutable invertQuote;
    AggregatorV2V3Interface public immutable sequencerUptimeOracle;

    constructor (
        AggregatorV2V3Interface baseToUSDOracle_,
        AggregatorV2V3Interface quoteToUSDOracle_,
        bool invertBase_,
        bool invertQuote_,
        string memory description_,
        AggregatorV2V3Interface sequencerUptimeOracle_
    ) {
        description = description_;
        baseToUSDOracle = baseToUSDOracle_;
        quoteToUSDOracle = quoteToUSDOracle_;
        uint8 _baseDecimals = baseToUSDOracle_.decimals();
        uint8 _quoteDecimals = quoteToUSDOracle_.decimals();

        require(_baseDecimals <= 18);
        require(_quoteDecimals <= 18);

        baseToUSDDecimals = int256(10**_baseDecimals);
        quoteToUSDDecimals = int256(10**_quoteDecimals);
        invertBase = invertBase_;
        invertQuote = invertQuote_;
        sequencerUptimeOracle = sequencerUptimeOracle_;
    }

    function _checkSequencer() private view {
        // See: https://docs.chain.link/data-feeds/l2-sequencer-feeds/
        if (address(sequencerUptimeOracle) != address(0)) {
            (
                /*uint80 roundID*/,
                int256 answer,
                uint256 startedAt,
                /*uint256 updatedAt*/,
                /*uint80 answeredInRound*/
            ) = sequencerUptimeOracle.latestRoundData();
            require(answer == 0, "Sequencer Down");
            require(SEQUENCER_UPTIME_GRACE_PERIOD < block.timestamp - startedAt, "Sequencer Grace Period");
        }
    }

    function _calculateBaseToQuote() internal view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        _checkSequencer();

        int256 baseToUSD;
        (
            roundId,
            baseToUSD,
            startedAt,
            updatedAt,
            answeredInRound
        ) = baseToUSDOracle.latestRoundData();
        require(baseToUSD > 0, "Chainlink Rate Error");
        // Overflow and div by zero not possible
        if (invertBase) baseToUSD = (baseToUSDDecimals * baseToUSDDecimals) / baseToUSD;

        (
            /* roundId */,
            int256 quoteToUSD,
            /* uint256 startedAt */,
            /* updatedAt */,
            /* answeredInRound */
        ) = quoteToUSDOracle.latestRoundData();
        require(quoteToUSD > 0, "Chainlink Rate Error");
        if (invertQuote) quoteToUSD = (quoteToUSDDecimals * quoteToUSDDecimals) / quoteToUSD;

        // To convert from USDC/USD (base) and ETH/USD (quote) to USDC/ETH we do:
        // (USDC/USD * quoteDecimals * 1e18) / (ETH/USD * baseDecimals)
        answer = baseToUSD
            .mul(quoteToUSDDecimals)
            .mul(rateDecimals)
            .div(quoteToUSD)
            .div(baseToUSDDecimals);
    }

    function latestRoundData() external view override returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return _calculateBaseToQuote();
    }

    function latestAnswer() external view override returns (int256 answer) {
        (/* */, answer, /* */, /* */, /* */) = _calculateBaseToQuote();
    }

    function latestTimestamp() external view override returns (uint256 updatedAt) {
        (/* */, /* */, /* */, updatedAt, /* */) = _calculateBaseToQuote();
    }

    function latestRound() external view override returns (uint256 roundId) {
        (roundId, /* */, /* */, /* */, /* */) = _calculateBaseToQuote();
    }

    function getRoundData(uint80 /* _roundId */) external view override returns (
        uint80 /* roundId */,
        int256 /* answer */,
        uint256 /* startedAt */,
        uint256 /* updatedAt */,
        uint80 /* answeredInRound */
    ) {
        revert();
    }

    function getAnswer(uint256 /* roundId */) external view override returns (int256) { revert(); }
    function getTimestamp(uint256 /* roundId */) external view override returns (uint256) { revert(); }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/// @title All shared constants for the Notional system should be declared here.
library Constants {
    uint8 internal constant CETH_DECIMAL_PLACES = 8;

    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant INCENTIVE_ACCUMULATION_PRECISION = 1e18;

    // ETH will be initialized as the first currency
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint8 internal constant ETH_DECIMAL_PLACES = 18;
    int256 internal constant ETH_DECIMALS = 1e18;
    address internal constant ETH_ADDRESS = address(0);
    // Used to prevent overflow when converting decimal places to decimal precision values via
    // 10**decimalPlaces. This is a safe value for int256 and uint256 variables. We apply this
    // constraint when storing decimal places in governance.
    uint256 internal constant MAX_DECIMAL_PLACES = 36;

    // Address of the account where fees are collected
    address internal constant FEE_RESERVE = 0x0000000000000000000000000000000000000FEE;
    // Address of the account where settlement funds are collected, this is only
    // used for off chain event tracking.
    address internal constant SETTLEMENT_RESERVE = 0x00000000000000000000000000000000000005e7;

    // Most significant bit
    bytes32 internal constant MSB =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    // Each bit set in this mask marks where an active market should be in the bitmap
    // if the first bit refers to the reference time. Used to detect idiosyncratic
    // fcash in the nToken accounts
    bytes32 internal constant ACTIVE_MARKETS_MASK = (
        MSB >> ( 90 - 1) | // 3 month
        MSB >> (105 - 1) | // 6 month
        MSB >> (135 - 1) | // 1 year
        MSB >> (147 - 1) | // 2 year
        MSB >> (183 - 1) | // 5 year
        MSB >> (211 - 1) | // 10 year
        MSB >> (251 - 1)   // 20 year
    );

    // Basis for percentages
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    // Min Buffer Scale and Buffer Scale are used in ExchangeRate to increase the maximum
    // possible buffer values at the higher end of the uint8 range.
    int256 internal constant MIN_BUFFER_SCALE = 150;
    int256 internal constant BUFFER_SCALE = 10;
    // Max number of traded markets, also used as the maximum number of assets in a portfolio array
    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;
    // Max number of fCash assets in a bitmap, this is based on the gas costs of calculating free collateral
    // for a bitmap portfolio
    uint256 internal constant MAX_BITMAP_ASSETS = 20;
    uint256 internal constant FIVE_MINUTES = 300;

    // Internal date representations, note we use a 6/30/360 week/month/year convention here
    uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;
    
    // These constants are used in DateTime.sol
    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    // Offsets for each time chunk denominated in days
    uint256 internal constant MAX_DAY_OFFSET = 90;
    uint256 internal constant MAX_WEEK_OFFSET = 360;
    uint256 internal constant MAX_MONTH_OFFSET = 2160;
    uint256 internal constant MAX_QUARTER_OFFSET = 7650;

    // Offsets for each time chunk denominated in bits
    uint256 internal constant WEEK_BIT_OFFSET = 90;
    uint256 internal constant MONTH_BIT_OFFSET = 135;
    uint256 internal constant QUARTER_BIT_OFFSET = 195;

    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
    // Used for prime cash scalars
    uint256 internal constant SCALAR_PRECISION = 1e18;
    // Used in prime rate lib
    int256 internal constant DOUBLE_SCALAR_PRECISION = 1e36;
    // One basis point in RATE_PRECISION terms
    uint256 internal constant BASIS_POINT = uint256(RATE_PRECISION / 10000);
    // Used to when calculating the amount to deleverage of a market when minting nTokens
    uint256 internal constant DELEVERAGE_BUFFER = 300 * BASIS_POINT;
    // Used for scaling cash group factors
    uint256 internal constant FIVE_BASIS_POINTS = 5 * BASIS_POINT;
    // Used for residual purchase incentive and cash withholding buffer
    uint256 internal constant TEN_BASIS_POINTS = 10 * BASIS_POINT;
    // Used for max oracle rate
    uint256 internal constant FIFTEEN_BASIS_POINTS = 15 * BASIS_POINT;
    // Used in max rate calculations
    uint256 internal constant MAX_LOWER_INCREMENT = 150;
    uint256 internal constant MAX_LOWER_INCREMENT_VALUE = 150 * 25 * BASIS_POINT;
    uint256 internal constant TWENTY_FIVE_BASIS_POINTS = 25 * BASIS_POINT;
    uint256 internal constant ONE_HUNDRED_FIFTY_BASIS_POINTS = 150 * BASIS_POINT;

    // This is the ABDK64x64 representation of RATE_PRECISION
    // RATE_PRECISION_64x64 = ABDKMath64x64.fromUint(RATE_PRECISION)
    int128 internal constant RATE_PRECISION_64x64 = 0x3b9aca000000000000000000;

    uint8 internal constant FCASH_ASSET_TYPE          = 1;
    // Liquidity token asset types are 1 + marketIndex (where marketIndex is 1-indexed)
    uint8 internal constant MIN_LIQUIDITY_TOKEN_INDEX = 2;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;
    uint8 internal constant VAULT_SHARE_ASSET_TYPE    = 9;
    uint8 internal constant VAULT_DEBT_ASSET_TYPE     = 10;
    uint8 internal constant VAULT_CASH_ASSET_TYPE     = 11;
    // Used for tracking legacy nToken assets
    uint8 internal constant LEGACY_NTOKEN_ASSET_TYPE  = 12;

    // Account context flags
    bytes1 internal constant HAS_ASSET_DEBT           = 0x01;
    bytes1 internal constant HAS_CASH_DEBT            = 0x02;
    bytes2 internal constant ACTIVE_IN_PORTFOLIO      = 0x8000;
    bytes2 internal constant ACTIVE_IN_BALANCES       = 0x4000;
    bytes2 internal constant UNMASK_FLAGS             = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES           = uint16(UNMASK_FLAGS);

    // Equal to 100% of all deposit amounts for nToken liquidity across fCash markets.
    int256 internal constant DEPOSIT_PERCENT_BASIS    = 1e8;

    // nToken Parameters: there are offsets in the nTokenParameters bytes6 variable returned
    // in nTokenHandler. Each constant represents a position in the byte array.
    uint8 internal constant LIQUIDATION_HAIRCUT_PERCENTAGE = 0;
    uint8 internal constant CASH_WITHHOLDING_BUFFER = 1;
    uint8 internal constant RESIDUAL_PURCHASE_TIME_BUFFER = 2;
    uint8 internal constant PV_HAIRCUT_PERCENTAGE = 3;
    uint8 internal constant RESIDUAL_PURCHASE_INCENTIVE = 4;

    // Liquidation parameters
    // Default percentage of collateral that a liquidator is allowed to liquidate, will be higher if the account
    // requires more collateral to be liquidated
    int256 internal constant DEFAULT_LIQUIDATION_PORTION = 40;
    // Percentage of local liquidity token cash claim delivered to the liquidator for liquidating liquidity tokens
    int256 internal constant TOKEN_REPO_INCENTIVE_PERCENT = 30;

    // Pause Router liquidation enabled states
    bytes1 internal constant LOCAL_CURRENCY_ENABLED = 0x01;
    bytes1 internal constant COLLATERAL_CURRENCY_ENABLED = 0x02;
    bytes1 internal constant LOCAL_FCASH_ENABLED = 0x04;
    bytes1 internal constant CROSS_CURRENCY_FCASH_ENABLED = 0x08;

    // Requires vault accounts to enter a position for a minimum of 1 min
    // to mitigate strange behavior where accounts may enter and exit using
    // flash loans or other MEV type behavior.
    uint256 internal constant VAULT_ACCOUNT_MIN_TIME = 1 minutes;

    // Placeholder constant to mark the variable rate prime cash maturity
    uint40 internal constant PRIME_CASH_VAULT_MATURITY = type(uint40).max;

    // This represents the maximum difference in internal precision units
    // before and after a rebalancing. 10_000 represents 0.0001 units delta
    // as a result of rebalancing. We should expect to never lose value as
    // a result of rebalancing, but some rounding errors may exist as a result
    // of redemption and deposit.
    int256 internal constant REBALANCING_UNDERLYING_DELTA = 10_000;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import {Constants} from "../global/Constants.sol";

library SafeInt256 {
    int256 private constant _INT256_MIN = type(int256).min;

    /// @dev Returns the multiplication of two signed integers, reverting on
    /// overflow.

    /// Counterpart to Solidity's `*` operator.

    /// Requirements:

    /// - Multiplication cannot overflow.

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require (b == 0 || c / b == a);
        else require (a == 0 || c / a == b);
    }

    /// @dev Returns the integer division of two signed integers. Reverts on
    /// division by zero. The result is rounded towards zero.

    /// Counterpart to Solidity's `/` operator. Note: this function uses a
    /// `revert` opcode (which leaves remaining gas untouched) while Solidity
    /// uses an invalid opcode to revert (consuming all remaining gas).

    /// Requirements:

    /// - The divisor cannot be zero.

    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        //  taken from uniswap v3
        require((z = x - y) <= x == (y >= 0));
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    function neg(int256 x) internal pure returns (int256 y) {
        return mul(-1, x);
    }

    function abs(int256 x) internal pure returns (int256) {
        if (x < 0) return neg(x);
        else return x;
    }

    function subNoNeg(int256 x, int256 y) internal pure returns (int256 z) {
        z = sub(x, y);
        require(z >= 0); // dev: int256 sub to negative

        return z;
    }

    /// @dev Calculates x * RATE_PRECISION / y while checking overflows
    function divInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, Constants.RATE_PRECISION), y);
    }

    /// @dev Calculates x * y / RATE_PRECISION while checking overflows
    function mulInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, y), Constants.RATE_PRECISION);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function toInt80(int256 x) internal pure returns (int80) {
        require (int256(type(int80).min) <= x && x <= int256(type(int80).max)); // dev: toInt overflow
        return int80(x);
    }

    function toInt88(int256 x) internal pure returns (int88) {
        require (int256(type(int88).min) <= x && x <= int256(type(int88).max)); // dev: toInt overflow
        return int88(x);
    }

    function toInt128(int256 x) internal pure returns (int128) {
        require (int256(type(int128).min) <= x && x <= int256(type(int128).max)); // dev: toInt overflow
        return int128(x);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x > y ? x : y;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    /// @notice Returns the net change in negative signed values, used for
    /// determining the (positive) amount of debt change
    function negChange(int256 start, int256 end) internal pure returns (int256) {
        // No change in these two scenarios
        if (start == end || (start >= 0 && end >= 0)) return 0;
        if (start <= 0 && 0 < end) {
            // Negative portion has been eliminated so the net change on the
            // negative side is start (i.e. a reduction in the negative balance)
            return start;
        } else if (end <= 0 && 0 < start) {
            // Entire negative portion has been created so the net change on the
            // negative side is -end (i.e. an increase in the negative balance)
            return neg(end);
        } else if (start <= 0 && end <= 0) {
            // There is some net change in the negative amounts.
            // If start < end then this is negative, debt has been reduced
            // If end < start then this is positive, debt has been increased
            return sub(start, end);
        }

        // Should never get to this point
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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