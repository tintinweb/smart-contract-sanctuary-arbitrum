// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
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
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

import {AggregatorInterface} from "./AggregatorInterface.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
// Chainlink Contracts v0.8
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.17;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : (getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow);

            
            
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

import {IOracleProxy} from "./IOracleProxy.sol";

/**
 * @title IChainlinkV2V3OracleProxy
 * @author Covenant Labs
 * @notice Defines the interface for the Covenant chainlink v2v3 oracle proxy
 **/
interface IChainlinkV2V3OracleProxy is IOracleProxy {
    /**
     * @notice Returns the chainlink oracle address for token0
     * @return The chainlink oracle address
     **/
    function ORACLE_SOURCE_TOKEN0() external view returns (address);

    /**
     * @notice Returns the chainlink oracle address for token1
     * @return The chainlink oracle address
     **/
    function ORACLE_SOURCE_TOKEN1() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.7;

/**
 * @title IOracleProxy
 * @author Amorphous
 * @notice Defines the basic interface for a Covenant price oracle proxy.
 **/
interface IOracleProxy {
    /**
     * @notice Returns the token0 currency
     * @return The address of the token0 contract
     **/
    function TOKEN0() external view returns (address);

    /**
     * @notice Returns the token1 currency
     * @return The address of the token1 contract
     **/
    function TOKEN1() external view returns (address);

    /**
     * @notice Returns the base currency given the asset
     * @param asset is the address of the asset
     * @return The address of the base currency given the asset adress
     **/
    function getBaseCurrency(address asset) external view returns (address);

    /**
     * @notice Gets the avg tick of asset price vs base currency price
     * @return The avg price tick of the asset in base currency
     **/
    function getAvgTick(
        address asset,
        uint32 beginLookbackTime,
        uint32 endLookbackTime
    ) external view returns (int24);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @author Covenant Labs
 * @notice Defines the error messages emitted by the different contracts of the Covenant protocol
 */
library Errors {
    string public constant LOCKED = "0"; // 'Guild is locked'
    string public constant NOT_CONTRACT = "1"; // 'Address is not a contract'
    string public constant AMOUNT_NEED_TO_BE_GREATER = "2"; // 'A greater amount needed for action'
    string public constant TRANSFER_FAIL = "3"; // 'Failed to transfer'
    string public constant NOT_APPROVED = "4"; // 'Not approved'
    string public constant NOT_ENOUGH_BALANCE = "5"; // 'Not enough balance'
    string public constant ASSET_NEEDS_TO_BE_APPROVED = "6"; // 'Asset needs to be whitelisted'
    string public constant OPERATION_NOT_SUPPORTED = "7"; // 'Operation not supported'
    string public constant OPERATION_NOT_AUTHORIZED = "8"; // 'Operation not authorized, not enough permissions for the operation'
    string public constant REFINANCE_INVALID_TIMESTAMP = "9"; // 'The current block has a timestamp that is older vs that last refinance'
    string public constant NOT_ENOUGH_COLLATERAL = "10"; // 'Not enough collateral'
    string public constant AMOUNT_NEED_TO_MORE_THAN_ZERO = "11"; // '"Your asset amount must be greater then you are trying to deposit"'
    string public constant CANNOT_BURN_MORE_THAN_CURRENT_DEBT = "12"; // "Amount exceeds current debt level"
    string public constant UNHEALTHY_POSITION = "13"; // Users position is currently higher than liquidation threshold
    string public constant CANNOT_LIQUIDATE_HEALTHY = "14"; // Cannot liqudate healthy users position
    string public constant WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE = "15"; // Amount exceeds max withdrawable amount
    string public constant HELPER_INSUFFICIENT_FUNDS = "16"; // Internal error, insufficient funds to place on dex as requested
    string public constant AMOUNT_NEEDS_TO_EQUAL_COLLATERAL_VALUE = "17"; // Amount needs to be the same to exchange money for collateral
    string public constant AMOUNT_NEEDS_TO_LOWER_THAN_DEBT = "18"; // Amount needs to be lower than current debt level
    string public constant NOT_ENOUGH_Z_TOKENS = "19"; // "Not enough zTokens in account"
    string public constant PRICE_LIMIT_OUT_OF_BOUNDS = "20"; // "PerpetualDebt.sol - price limit initialization out of bounds"
    string public constant PRICE_LIMIT_ERROR = "21"; // "PerpetualDebt.sol - price limit min larger than max"
    string public constant ACL_ADMIN_CANNOT_BE_ZERO = "22"; // "ACLManager.sol - cannot set a 0x0 address as admin"
    string public constant INVALID_ADDRESSES_PROVIDER_ID = "23"; // "GuildAddressesProviderRegistry.sol - cannot set ID 0"
    string public constant ADDRESSES_PROVIDER_NOT_REGISTERED = "24"; // 'GuildAddressesProviderRegistry.sol - Guild addresses provider is not registered'
    string public constant INVALID_ADDRESSES_PROVIDER = "25"; // 'The address of the guild addresses provider is invalid'
    string public constant ADDRESSES_PROVIDER_ALREADY_ADDED = "26"; // 'GuildAddressesProviderRegistry.sol - Reserve has already been added to collateral list'
    string public constant CALLER_NOT_GUILD_ADMIN = "27"; // 'The caller of the function is not a guild admin'
    string public constant CALLER_NOT_EMERGENCY_ADMIN = "28"; // 'The caller of the function is not an emergency admin'
    string public constant CALLER_NOT_GUILD_OR_EMERGENCY_ADMIN = "29"; // 'The caller of the function is not a guild or emergency admin'
    string public constant CALLER_NOT_RISK_OR_GUILD_ADMIN = "30"; // 'The caller of the function is not a risk or guild admin'
    string public constant TRANSFER_INVALID_SENDER = "31"; // 'ERC20: Cannot send from address 0'
    string public constant TRANSFER_INVALID_RECEIVER = "32"; // 'ERC20: Cannot send to address 0'
    string public constant CALLER_MUST_BE_GUILD = "33"; // 'The caller of the function must be the guild'
    string public constant GUILD_ADDRESSES_DO_NOT_MATCH = "34"; // 'Incorrect Guild address when initializing token'
    string public constant PERPETUAL_DEBT_ALREADY_INITIALIZED = "35"; // 'Perpetual Debt structure already initialized'
    string public constant DEX_ORACLE_ALREADY_INITIALIZED = "36"; // 'Dex Oracle structure already initialized'
    string public constant DEX_ORACLE_POOL_NOT_INITIALIZED = "37"; // 'Dex pool should be initialized before Dex oracle'
    string public constant CALLER_NOT_GUILD_CONFIGURATOR = "38"; // 'The caller of the function is not the guild configurator contract'
    string public constant COLLATERAL_ALREADY_ADDED = "39"; // 'Collateral has already been added to collateral list'
    string public constant NO_MORE_COLLATERALS_ALLOWED = "40"; // 'Maximum amount of collaterals in the guild reached'
    string public constant INVALID_LTV = "41"; // 'Invalid ltv parameter for the collateral'
    string public constant INVALID_LIQ_THRESHOLD = "42"; // 'Invalid liquidity threshold parameter for the collateral'
    string public constant INVALID_LIQ_BONUS = "43"; // 'Invalid liquidity bonus parameter for the collateral'
    string public constant INVALID_DECIMALS = "44"; // 'Invalid decimals parameter of the underlying asset of the collateral'
    string public constant INVALID_SUPPLY_CAP = "45"; // 'Invalid supply cap for the collateral'
    string public constant INVALID_PROTOCOL_DISTRIBUTION_FEE = "46"; // 'Invalid protocol distribution fee for the perpetual debt'
    string public constant ZERO_ADDRESS_NOT_VALID = "47"; // 'Zero address not valid'
    string public constant COLLATERAL_NOT_LISTED = "48"; // 'Collateral is not listed (not initialized or has been dropped)'
    string public constant COLLATERAL_BALANCE_IS_ZERO = "49"; // 'The collateral balance is 0'
    string public constant LTV_VALIDATION_FAILED = "50"; // 'Ltv validation failed'
    string public constant HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "51"; // 'Health factor is lower than the liquidation threshold'
    string public constant COLLATERAL_CANNOT_COVER_NEW_BORROW = "52"; // 'There is not enough collateral to cover a new borrow'
    string public constant INVALID_COLLATERAL_PARAMS = "53"; //'Invalid risk parameters for the collateral'
    string public constant INVALID_AMOUNT = "54"; // 'Amount must be greater than 0'
    string public constant NOT_ENOUGH_AVAILABLE_USER_BALANCE = "55"; //'User cannot withdraw more than the available balance'
    string public constant COLLATERAL_INACTIVE = "56"; //'Action requires an active collateral'
    string public constant SUPPLY_CAP_EXCEEDED = "57"; // 'Supply cap is exceeded'
    string public constant ACL_MANAGER_NOT_SET = "58"; // 'The ACL Manager has not been set for the addresses provider'
    string public constant ARRAY_SIZE_MISMATCH = "59"; // 'The arrays are of different sizes'
    string public constant DEX_POOL_DOES_NOT_CONTAIN_ASSET_PAIR = "60"; // 'The dex pool does not contain pricing info for token pair'
    string public constant ASSET_NOT_TRACKED_IN_ORACLE = "61"; // 'The asset is not tracked by the pricing oracle'
    string public constant INVALID_MINT_CAP = "62"; //  'Invalid mint cap for the perpetual debt'
    string public constant DEBT_PAUSED = "63"; //  'Action requires a non-paused debt'
    string public constant HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "64"; // 'Action requires health factor to be below liquidation threshold'
    string public constant COLLATERAL_CANNOT_BE_LIQUIDATED = "65"; // 'The collateral chosen cannot be liquidated'
    string public constant USER_HAS_NO_DEBT = "66"; // 'User has no debt to be liquidated'
    string public constant INSUFFICIENT_CREDIT_DELEGATION = "67"; //  'Insufficient credit delegation to 3rd party borrower'
    string public constant INSUFFICIENT_TOKENIN_FOR_TARGET_TOKENOUT = "68"; //  'Insufficient tokenIn to swap for target tokenOut value'
    string public constant COLLATERAL_FROZEN = "69"; // 'Action cannot be performed because the collateral is frozen'
    string public constant COLLATERAL_PAUSED = "70"; // 'Action cannot be performed because the collateral is paused'
    string public constant PERPETUAL_DEBT_FROZEN = "71"; // 'Action cannot be performed because the perpetual debt is frozen'
    string public constant PERPETUAL_DEBT_PAUSED = "72"; // 'Action cannot be performed because the perpetual debt is paused'
    string public constant TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE = "73"; // 'Account does not have sufficient allowance to transfer on behalf of other account'
    string public constant NEGATIVE_ALLOWANCE_NOT_ALLOWED = "74"; // 'Cannot allocate negative value for allowances'
    string public constant INSUFFICIENT_BALANCE_TO_BURN = "75"; // 'Cannot burn more than amount in balance'
    string public constant TRANSFER_EXCEEDS_BALANCE = "76"; // 'ERC20: Transfer amount exceeds balance'
    string public constant PERPETUAL_DEBT_CAP_EXCEEDED = "77"; // 'Perpetual debt cap is exceeded'
    string public constant NEGATIVE_DELEGATION_NOT_ALLOWED = "78"; // 'Cannot allocate negative value for delegation allowances'
    string public constant ORACLE_LOOKBACKPERIOD_IS_ZERO = "79"; // 'Collateral oracle should have lookback period greater than 0'
    string public constant ORACLE_CARDINALITY_IS_ZERO = "80"; // 'Collateral oracle should have pool cardinality greater than 0'
    string public constant ORACLE_CARDINALITY_MONOTONICALLY_INCREASES = "81"; // The cardinality of the oracle is monotonically increasing and cannot bet lowered
    string public constant ORACLE_ASSET_MISMATCH = "82"; // Asset in oracle does not match proxy asset address
    string public constant ORACLE_BASE_CURRENCY_MISMATCH = "83"; // Base currency in oracle does not match proxy base currency address
    string public constant NO_ORACLE_PROXY_PRICE_SOURCE = "84"; // Oracle proxy does not have a price source
    string public constant CANNOT_BE_ZERO = "85"; // The value cannot be 0
    string public constant REQUIRES_OVERRIDE = "86"; // Function requires override
    string public constant GUILD_MISMATCH = "87"; // Function requires override
    string public constant ORACLE_PROXY_TOKENS_NOT_SET_PROPERLY = "88"; // Function requires override
    string public constant POSITIVE_COLLATERAL_BALANCE = "89"; // Cannot only perform action if guild balance is positive
    string public constant INVALID_ROLE = "90"; // Role exceeds MAX_LIMIT
    string public constant MAX_NUM_ROLES_EXCEEDED = "91"; // Role can't exceed MAX_NUM_OF_ROLES
    string public constant INVALID_PROTOCOL_SERVICE_FEE = "92"; // Protocol service fee larger than max allowed
    string public constant INVALID_PROTOCOL_MINT_FEE = "93"; // Protocol mint fee larger than max allowed
    string public constant PRICE_ORACLE_SENTINEL_CHECK_FAILED = "94"; // PriceOracleSentinel check failed
    string public constant LOOKBACK_PERIOD_IS_NOT_ZERO = "95"; // lookback period must be 0
    string public constant LOOKBACK_PERIOD_END_LT_START = "96"; // lookbackPeriodEnd can't be less than lookbackPeriodStart
    string public constant PRICE_CANNOT_BE_ZERO = "97"; // Oracle price cannot be zero
    string public constant INVALID_PROTOCOL_SWAP_FEE = "98"; // Protocol swap fee larger than max allowed
    string public constant COLLATERAL_CANNOT_COVER_EXISTING_BORROW = "99"; // 'Collateral remaining after withdrawal would not cover existing borrow'
    string public constant CALLER_NOT_GUILD_OR_GUILD_ADMIN = "A0"; // 'The caller of the function is not the guild or guild admin'
    string public constant NOT_ENOUGH_MONEY_IN_GUILD_TO_SWAP = "A1"; // 'There is not enough money in the Guild treasury for a successfull swap and debt burn'
    string public constant MONEY_DOES_NOT_MATCH = "A2"; // 'Guild or Oracle cannot be initialized with a Money token that differs from the other.
    string public constant ORACLE_ADDRESS_CANNOT_BE_ZERO = "A3"; // 'A valid address needs to be used when updating the Oracle
    string public constant ORACLE_NOT_SET = "A4"; // 'An oracle has not been registered with guildAddressProvider

    string public constant OWNABLE_ONLY_OWNER = "Ownable: caller is not the owner";
}

// SPDX-License-Identifier: MIT
// Notice: license change Jan 27, 2023
pragma solidity 0.8.17;

/**
 * @title WadRayMath library
 * @author Aave (not rayPow)
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

    function ray() internal pure returns (uint256) {
        return RAY;
    }

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    function halfRay() internal pure returns (uint256) {
        return HALF_RAY;
    }

    function halfWad() internal pure returns (uint256) {
        return HALF_WAD;
    }

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
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
                revert(0, 0)
            }

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
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
                revert(0, 0)
            }

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
            if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
                revert(0, 0)
            }

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
            if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
                revert(0, 0)
            }

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
            if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
                b := add(b, 1)
            }
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

            if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
                revert(0, 0)
            }
        }
    }

    /**
     * @dev Calculates x to the power of n (x^n)
     * @dev Power calculated through a loop of binary powers.  Not optimized.
     * @param x ray
     * @param n unsigned integer
     * @return z x^n
     **/
    function rayPow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rayMul(x, x);

            if (n % 2 != 0) {
                z = rayMul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {OracleProxyCommon} from "./OracleProxyCommon.sol";
import {IOracleProxy} from "../../../interfaces/IOracleProxy.sol";
import {IChainlinkV2V3OracleProxy} from "../../../interfaces/IChainlinkV2V3OracleProxy.sol";
import {IERC20Detailed} from "../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {AggregatorV2V3Interface} from "../../../dependencies/chainlink/AggregatorV2V3Interface.sol";
import {TickMath} from "../../../dependencies/uniswap-v3-core/libraries/TickMath.sol";
import {WadRayMath} from "../../libraries/math/WadRayMath.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title ChainlinkAggregatorV2V3InterfaceOracleProxy v1.1
 * @author Covenant Labs
 * @notice Implements the logic to read prices from chainlink oracles
 **/

contract ChainlinkV2V3OracleProxy is OracleProxyCommon, IChainlinkV2V3OracleProxy {
    using WadRayMath for uint256;

    address public immutable ORACLE_SOURCE_TOKEN0;
    address public immutable ORACLE_SOURCE_TOKEN1;

    /**
     * @notice Initializes a CovenantPriceOracle structure
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     * @param oracleSourceTokenA The chainlink contract implementing the AggregatorInterface for tokenA
     * @param oracleSourceTokenB The chainlink contract implementing the AggregatorInterface for tokenB
     **/
    constructor(
        address tokenA,
        address tokenB,
        address oracleSourceTokenA,
        address oracleSourceTokenB
    ) OracleProxyCommon(tokenA, tokenB) {
        ORACLE_SOURCE_TOKEN0 = (tokenA < tokenB) ? oracleSourceTokenA : oracleSourceTokenB;
        ORACLE_SOURCE_TOKEN1 = (tokenA < tokenB) ? oracleSourceTokenB : oracleSourceTokenA;
    }

    /// @inheritdoc IOracleProxy
    function getAvgTick(
        address asset,
        uint32,
        uint32
    ) external view returns (int24 avgTick_) {
        require((asset == TOKEN0 || asset == TOKEN1), Errors.ORACLE_ASSET_MISMATCH);

        /*
         * This function converts Chainlink Oracle prices to Uniswap v3 ticks via sqrtPriceX96 ratios of Token1/Token
         * Chainlink oracle proxies can either have 1 source (i.e. if one of the oracle proxy tokens is WETH) or 2 sources (otherwise)
         *  - In the case of 2 Chainlink oracle sources, we must divide (Price_Token_1 / Price_Token_0) and normalize to account for the decimal units of the oracles & tokens
         *  - In the case of 1 Chainlink oracle source, the other (non-existant) oracle source price is assumed to be 1 (e.g. ETH/WETH has a price of 1)
         *
         * We use the following formula to convert prices to priceX96:
         *   PriceX96_of_Token1/Token0 = (Price_Token_1 / Price_Token_0) * (10^Oracle_0_Decimals * 10^Token_0_Decimals) / (10^Oracle_1_decimals * 10^Token_1_Decimals) * 2^96
         *
         * We can leverage the following formula to convert between sqrtPriceX96 and ticks: (see: TickMath.getTickAtSqrtRatio(sqrtPriceX96))
         *   sqrtPriceX96 = 1.0001 ^ tick
         *
         * Note: since we pass in priceX96 instead of sqrtPriceX96 to TickMath.getTickAtSqrtRatio() we must divide the result by 2 -- i.e. tick = log(priceX96 ^ 1/2) * log(1.0001) = (log(priceX96) * log(1.0001)) / 2
         */

        // fetch token decimals
        uint8 token0Decimals = IERC20Detailed(TOKEN0).decimals();
        uint8 token1Decimals = IERC20Detailed(TOKEN1).decimals();
        uint8 oracle0Decimals = (ORACLE_SOURCE_TOKEN0 == address(0))
            ? token0Decimals
            : AggregatorV2V3Interface(ORACLE_SOURCE_TOKEN0).decimals();
        uint8 oracle1Decimals = (ORACLE_SOURCE_TOKEN1 == address(0))
            ? token1Decimals
            : AggregatorV2V3Interface(ORACLE_SOURCE_TOKEN1).decimals();

        // fetch token0 price
        uint256 priceToken0;
        if (ORACLE_SOURCE_TOKEN0 == address(0)) {
            priceToken0 = 10**oracle0Decimals;
        } else {
            int256 priceToken0Int = AggregatorV2V3Interface(ORACLE_SOURCE_TOKEN0).latestAnswer();
            require(priceToken0Int > 0, Errors.PRICE_CANNOT_BE_ZERO);
            priceToken0 = uint256(priceToken0Int);
        }

        // fetch token1 price
        uint256 priceToken1;
        if (ORACLE_SOURCE_TOKEN1 == address(0)) {
            priceToken1 = 10**oracle1Decimals;
        } else {
            int256 priceToken1Int = AggregatorV2V3Interface(ORACLE_SOURCE_TOKEN1).latestAnswer();
            require(priceToken1Int > 0, Errors.PRICE_CANNOT_BE_ZERO);
            priceToken1 = uint256(priceToken1Int);
        }

        int8 allDecimals = int8(token0Decimals + oracle0Decimals) - int8(oracle1Decimals + token1Decimals);
        uint256 priceX96 = priceToken1 * (1 << 96);
        if (allDecimals >= 0) {
            priceX96 *= 10**(uint8(allDecimals));
        } else {
            priceX96 /= 10**(uint8(-allDecimals));
        }
        priceX96 /= priceToken0;

        // calculate tick from priceX96
        avgTick_ = TickMath.getTickAtSqrtRatio(uint160(priceX96)) / 2;

        // Adjust rate if asset == baseCurrency
        if (asset == TOKEN0) {
            avgTick_ = -avgTick_;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IOracleProxy} from "../../../interfaces/IOracleProxy.sol";
import {Errors} from "../../libraries/helpers/Errors.sol";

/**
 * @title OracleProxy v1.1
 * @author Covenant Labs
 * @notice Implements the shared logic for oracle proxies
 **/

abstract contract OracleProxyCommon is IOracleProxy {
    address public immutable TOKEN0;
    address public immutable TOKEN1;

    /**
     * @notice Initializes a OracleProxy structure
     * @param tokenA The address of tokenA
     * @param tokenB The address of tokenB
     **/
    constructor(address tokenA, address tokenB) {
        // Set values
        TOKEN0 = (tokenA < tokenB) ? tokenA : tokenB;
        TOKEN1 = (tokenA < tokenB) ? tokenB : tokenA;
    }

    /// @inheritdoc IOracleProxy
    function getBaseCurrency(address asset) external view returns (address) {
        require(asset == TOKEN0 || asset == TOKEN1, Errors.ORACLE_ASSET_MISMATCH);
        if (asset == TOKEN0) {
            return TOKEN1;
        } else {
            return TOKEN0;
        }
    }
}