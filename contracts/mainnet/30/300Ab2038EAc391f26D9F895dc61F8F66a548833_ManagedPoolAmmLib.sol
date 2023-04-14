// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @notice Interface for ExternalWeightedMath, a contract-wrapper for Weighted Math, Joins and Exits.
 */
interface IExternalWeightedMath {
    /**
     * @dev See `WeightedMath._calculateInvariant`.
     */
    function calculateInvariant(uint256[] memory normalizedWeights, uint256[] memory balances)
        external
        pure
        returns (uint256);

    /**
     * @dev See `WeightedMath._calcOutGivenIn`.
     */
    function calcOutGivenIn(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountIn
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcInGivenOut`.
     */
    function calcInGivenOut(
        uint256 balanceIn,
        uint256 weightIn,
        uint256 balanceOut,
        uint256 weightOut,
        uint256 amountOut
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcBptOutGivenExactTokensIn`.
     */
    function calcBptOutGivenExactTokensIn(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcBptOutGivenExactTokenIn`.
     */
    function calcBptOutGivenExactTokenIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcTokenInGivenExactBptOut`.
     */
    function calcTokenInGivenExactBptOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcAllTokensInGivenExactBptOut`.
     */
    function calcAllTokensInGivenExactBptOut(
        uint256[] memory balances,
        uint256 bptAmountOut,
        uint256 totalBPT
    ) external pure returns (uint256[] memory);

    /**
     * @dev See `WeightedMath._calcBptInGivenExactTokensOut`.
     */
    function calcBptInGivenExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory amountsOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcBptInGivenExactTokenOut`.
     */
    function calcBptInGivenExactTokenOut(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 amountOut,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcTokenOutGivenExactBptIn`.
     */
    function calcTokenOutGivenExactBptIn(
        uint256 balance,
        uint256 normalizedWeight,
        uint256 bptAmountIn,
        uint256 bptTotalSupply,
        uint256 swapFeePercentage
    ) external pure returns (uint256);

    /**
     * @dev See `WeightedMath._calcTokensOutGivenExactBptIn`.
     */
    function calcTokensOutGivenExactBptIn(
        uint256[] memory balances,
        uint256 bptAmountIn,
        uint256 totalBPT
    ) external pure returns (uint256[] memory);

    /**
     * @dev See `WeightedMath._calcBptOutAddToken`.
     */
    function calcBptOutAddToken(uint256 totalSupply, uint256 normalizedWeight) external pure returns (uint256);

    /**
     * @dev See `WeightedJoinsLib.joinExactTokensInForBPTOut`.
     */
    function joinExactTokensInForBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);

    /**
     * @dev See `WeightedJoinsLib.joinTokenInForExactBPTOut`.
     */
    function joinTokenInForExactBPTOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);

    /**
     * @dev See `WeightedJoinsLib.joinAllTokensInForExactBPTOut`.
     */
    function joinAllTokensInForExactBPTOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) external pure returns (uint256 bptAmountOut, uint256[] memory amountsIn);

    /**
     * @dev See `WeightedExitsLib.exitExactBPTInForTokenOut`.
     */
    function exitExactBPTInForTokenOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);

    /**
     * @dev See `WeightedExitsLib.exitExactBPTInForTokensOut`.
     */
    function exitExactBPTInForTokensOut(
        uint256[] memory balances,
        uint256 totalSupply,
        bytes memory userData
    ) external pure returns (uint256 bptAmountIn, uint256[] memory amountsOut);

    /**
     * @dev See `WeightedExitsLib.exitBPTInForExactTokensOut`.
     */
    function exitBPTInForExactTokensOut(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        uint256 swapFeePercentage,
        bytes memory userData
    ) external pure returns (uint256, uint256[] memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "../solidity-utils/openzeppelin/IERC20.sol";

library WeightedPoolUserData {
    // In order to preserve backwards compatibility, make sure new join and exit kinds are added at the end of the enum.
    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT, ALL_TOKENS_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    function joinKind(bytes memory self) internal pure returns (JoinKind) {
        return abi.decode(self, (JoinKind));
    }

    function exitKind(bytes memory self) internal pure returns (ExitKind) {
        return abi.decode(self, (ExitKind));
    }

    // Joins

    function initialAmountsIn(bytes memory self) internal pure returns (uint256[] memory amountsIn) {
        (, amountsIn) = abi.decode(self, (JoinKind, uint256[]));
    }

    function exactTokensInForBptOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsIn, uint256 minBPTAmountOut)
    {
        (, amountsIn, minBPTAmountOut) = abi.decode(self, (JoinKind, uint256[], uint256));
    }

    function tokenInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut, uint256 tokenIndex) {
        (, bptAmountOut, tokenIndex) = abi.decode(self, (JoinKind, uint256, uint256));
    }

    function allTokensInForExactBptOut(bytes memory self) internal pure returns (uint256 bptAmountOut) {
        (, bptAmountOut) = abi.decode(self, (JoinKind, uint256));
    }

    // Exits

    function exactBptInForTokenOut(bytes memory self) internal pure returns (uint256 bptAmountIn, uint256 tokenIndex) {
        (, bptAmountIn, tokenIndex) = abi.decode(self, (ExitKind, uint256, uint256));
    }

    function exactBptInForTokensOut(bytes memory self) internal pure returns (uint256 bptAmountIn) {
        (, bptAmountIn) = abi.decode(self, (ExitKind, uint256));
    }

    function bptInForExactTokensOut(bytes memory self)
        internal
        pure
        returns (uint256[] memory amountsOut, uint256 maxBPTAmountIn)
    {
        (, amountsOut, maxBPTAmountIn) = abi.decode(self, (ExitKind, uint256[], uint256));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// solhint-disable

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(
    bool condition,
    uint256 errorCode,
    bytes3 prefix
) pure {
    if (!condition) _revert(errorCode, prefix);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 * Uses the default 'BAL' prefix for the error code
 */
function _revert(uint256 errorCode) pure {
    _revert(errorCode, 0x42414c); // This is the raw byte representation of "BAL"
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode, bytes3 prefix) pure {
    uint256 prefixUint = uint256(uint24(prefix));
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAL#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string.
        // We first append the '#' character (0x23) to the prefix. In the case of 'BAL', it results in 0x42414c23 ('BAL#')
        // Then, we shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).
        let formattedPrefix := shl(24, add(0x23, shl(8, prefixUint)))

        let revertReason := shl(200, add(formattedPrefix, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Math
    uint256 internal constant ADD_OVERFLOW = 0;
    uint256 internal constant SUB_OVERFLOW = 1;
    uint256 internal constant SUB_UNDERFLOW = 2;
    uint256 internal constant MUL_OVERFLOW = 3;
    uint256 internal constant ZERO_DIVISION = 4;
    uint256 internal constant DIV_INTERNAL = 5;
    uint256 internal constant X_OUT_OF_BOUNDS = 6;
    uint256 internal constant Y_OUT_OF_BOUNDS = 7;
    uint256 internal constant PRODUCT_OUT_OF_BOUNDS = 8;
    uint256 internal constant INVALID_EXPONENT = 9;

    // Input
    uint256 internal constant OUT_OF_BOUNDS = 100;
    uint256 internal constant UNSORTED_ARRAY = 101;
    uint256 internal constant UNSORTED_TOKENS = 102;
    uint256 internal constant INPUT_LENGTH_MISMATCH = 103;
    uint256 internal constant ZERO_TOKEN = 104;
    uint256 internal constant INSUFFICIENT_DATA = 105;

    // Shared pools
    uint256 internal constant MIN_TOKENS = 200;
    uint256 internal constant MAX_TOKENS = 201;
    uint256 internal constant MAX_SWAP_FEE_PERCENTAGE = 202;
    uint256 internal constant MIN_SWAP_FEE_PERCENTAGE = 203;
    uint256 internal constant MINIMUM_BPT = 204;
    uint256 internal constant CALLER_NOT_VAULT = 205;
    uint256 internal constant UNINITIALIZED = 206;
    uint256 internal constant BPT_IN_MAX_AMOUNT = 207;
    uint256 internal constant BPT_OUT_MIN_AMOUNT = 208;
    uint256 internal constant EXPIRED_PERMIT = 209;
    uint256 internal constant NOT_TWO_TOKENS = 210;
    uint256 internal constant DISABLED = 211;

    // Pools
    uint256 internal constant MIN_AMP = 300;
    uint256 internal constant MAX_AMP = 301;
    uint256 internal constant MIN_WEIGHT = 302;
    uint256 internal constant MAX_STABLE_TOKENS = 303;
    uint256 internal constant MAX_IN_RATIO = 304;
    uint256 internal constant MAX_OUT_RATIO = 305;
    uint256 internal constant MIN_BPT_IN_FOR_TOKEN_OUT = 306;
    uint256 internal constant MAX_OUT_BPT_FOR_TOKEN_IN = 307;
    uint256 internal constant NORMALIZED_WEIGHT_INVARIANT = 308;
    uint256 internal constant INVALID_TOKEN = 309;
    uint256 internal constant UNHANDLED_JOIN_KIND = 310;
    uint256 internal constant ZERO_INVARIANT = 311;
    uint256 internal constant ORACLE_INVALID_SECONDS_QUERY = 312;
    uint256 internal constant ORACLE_NOT_INITIALIZED = 313;
    uint256 internal constant ORACLE_QUERY_TOO_OLD = 314;
    uint256 internal constant ORACLE_INVALID_INDEX = 315;
    uint256 internal constant ORACLE_BAD_SECS = 316;
    uint256 internal constant AMP_END_TIME_TOO_CLOSE = 317;
    uint256 internal constant AMP_ONGOING_UPDATE = 318;
    uint256 internal constant AMP_RATE_TOO_HIGH = 319;
    uint256 internal constant AMP_NO_ONGOING_UPDATE = 320;
    uint256 internal constant STABLE_INVARIANT_DIDNT_CONVERGE = 321;
    uint256 internal constant STABLE_GET_BALANCE_DIDNT_CONVERGE = 322;
    uint256 internal constant RELAYER_NOT_CONTRACT = 323;
    uint256 internal constant BASE_POOL_RELAYER_NOT_CALLED = 324;
    uint256 internal constant REBALANCING_RELAYER_REENTERED = 325;
    uint256 internal constant GRADUAL_UPDATE_TIME_TRAVEL = 326;
    uint256 internal constant SWAPS_DISABLED = 327;
    uint256 internal constant CALLER_IS_NOT_LBP_OWNER = 328;
    uint256 internal constant PRICE_RATE_OVERFLOW = 329;
    uint256 internal constant INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED = 330;
    uint256 internal constant WEIGHT_CHANGE_TOO_FAST = 331;
    uint256 internal constant LOWER_GREATER_THAN_UPPER_TARGET = 332;
    uint256 internal constant UPPER_TARGET_TOO_HIGH = 333;
    uint256 internal constant UNHANDLED_BY_LINEAR_POOL = 334;
    uint256 internal constant OUT_OF_TARGET_RANGE = 335;
    uint256 internal constant UNHANDLED_EXIT_KIND = 336;
    uint256 internal constant UNAUTHORIZED_EXIT = 337;
    uint256 internal constant MAX_MANAGEMENT_SWAP_FEE_PERCENTAGE = 338;
    uint256 internal constant UNHANDLED_BY_MANAGED_POOL = 339;
    uint256 internal constant UNHANDLED_BY_PHANTOM_POOL = 340;
    uint256 internal constant TOKEN_DOES_NOT_HAVE_RATE_PROVIDER = 341;
    uint256 internal constant INVALID_INITIALIZATION = 342;
    uint256 internal constant OUT_OF_NEW_TARGET_RANGE = 343;
    uint256 internal constant FEATURE_DISABLED = 344;
    uint256 internal constant UNINITIALIZED_POOL_CONTROLLER = 345;
    uint256 internal constant SET_SWAP_FEE_DURING_FEE_CHANGE = 346;
    uint256 internal constant SET_SWAP_FEE_PENDING_FEE_CHANGE = 347;
    uint256 internal constant CHANGE_TOKENS_DURING_WEIGHT_CHANGE = 348;
    uint256 internal constant CHANGE_TOKENS_PENDING_WEIGHT_CHANGE = 349;
    uint256 internal constant MAX_WEIGHT = 350;
    uint256 internal constant UNAUTHORIZED_JOIN = 351;
    uint256 internal constant MAX_MANAGEMENT_AUM_FEE_PERCENTAGE = 352;
    uint256 internal constant FRACTIONAL_TARGET = 353;
    uint256 internal constant ADD_OR_REMOVE_BPT = 354;
    uint256 internal constant INVALID_CIRCUIT_BREAKER_BOUNDS = 355;
    uint256 internal constant CIRCUIT_BREAKER_TRIPPED = 356;
    uint256 internal constant MALICIOUS_QUERY_REVERT = 357;
    uint256 internal constant JOINS_EXITS_DISABLED = 358;

    // Lib
    uint256 internal constant REENTRANCY = 400;
    uint256 internal constant SENDER_NOT_ALLOWED = 401;
    uint256 internal constant PAUSED = 402;
    uint256 internal constant PAUSE_WINDOW_EXPIRED = 403;
    uint256 internal constant MAX_PAUSE_WINDOW_DURATION = 404;
    uint256 internal constant MAX_BUFFER_PERIOD_DURATION = 405;
    uint256 internal constant INSUFFICIENT_BALANCE = 406;
    uint256 internal constant INSUFFICIENT_ALLOWANCE = 407;
    uint256 internal constant ERC20_TRANSFER_FROM_ZERO_ADDRESS = 408;
    uint256 internal constant ERC20_TRANSFER_TO_ZERO_ADDRESS = 409;
    uint256 internal constant ERC20_MINT_TO_ZERO_ADDRESS = 410;
    uint256 internal constant ERC20_BURN_FROM_ZERO_ADDRESS = 411;
    uint256 internal constant ERC20_APPROVE_FROM_ZERO_ADDRESS = 412;
    uint256 internal constant ERC20_APPROVE_TO_ZERO_ADDRESS = 413;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_ALLOWANCE = 414;
    uint256 internal constant ERC20_DECREASED_ALLOWANCE_BELOW_ZERO = 415;
    uint256 internal constant ERC20_TRANSFER_EXCEEDS_BALANCE = 416;
    uint256 internal constant ERC20_BURN_EXCEEDS_ALLOWANCE = 417;
    uint256 internal constant SAFE_ERC20_CALL_FAILED = 418;
    uint256 internal constant ADDRESS_INSUFFICIENT_BALANCE = 419;
    uint256 internal constant ADDRESS_CANNOT_SEND_VALUE = 420;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_INT256 = 421;
    uint256 internal constant GRANT_SENDER_NOT_ADMIN = 422;
    uint256 internal constant REVOKE_SENDER_NOT_ADMIN = 423;
    uint256 internal constant RENOUNCE_SENDER_NOT_ALLOWED = 424;
    uint256 internal constant BUFFER_PERIOD_EXPIRED = 425;
    uint256 internal constant CALLER_IS_NOT_OWNER = 426;
    uint256 internal constant NEW_OWNER_IS_ZERO = 427;
    uint256 internal constant CODE_DEPLOYMENT_FAILED = 428;
    uint256 internal constant CALL_TO_NON_CONTRACT = 429;
    uint256 internal constant LOW_LEVEL_CALL_FAILED = 430;
    uint256 internal constant NOT_PAUSED = 431;
    uint256 internal constant ADDRESS_ALREADY_ALLOWLISTED = 432;
    uint256 internal constant ADDRESS_NOT_ALLOWLISTED = 433;
    uint256 internal constant ERC20_BURN_EXCEEDS_BALANCE = 434;
    uint256 internal constant INVALID_OPERATION = 435;
    uint256 internal constant CODEC_OVERFLOW = 436;
    uint256 internal constant IN_RECOVERY_MODE = 437;
    uint256 internal constant NOT_IN_RECOVERY_MODE = 438;
    uint256 internal constant INDUCED_FAILURE = 439;
    uint256 internal constant EXPIRED_SIGNATURE = 440;
    uint256 internal constant MALFORMED_SIGNATURE = 441;
    uint256 internal constant SAFE_CAST_VALUE_CANT_FIT_UINT64 = 442;
    uint256 internal constant UNHANDLED_FEE_TYPE = 443;
    uint256 internal constant BURN_FROM_ZERO = 444;

    // Vault
    uint256 internal constant INVALID_POOL_ID = 500;
    uint256 internal constant CALLER_NOT_POOL = 501;
    uint256 internal constant SENDER_NOT_ASSET_MANAGER = 502;
    uint256 internal constant USER_DOESNT_ALLOW_RELAYER = 503;
    uint256 internal constant INVALID_SIGNATURE = 504;
    uint256 internal constant EXIT_BELOW_MIN = 505;
    uint256 internal constant JOIN_ABOVE_MAX = 506;
    uint256 internal constant SWAP_LIMIT = 507;
    uint256 internal constant SWAP_DEADLINE = 508;
    uint256 internal constant CANNOT_SWAP_SAME_TOKEN = 509;
    uint256 internal constant UNKNOWN_AMOUNT_IN_FIRST_SWAP = 510;
    uint256 internal constant MALCONSTRUCTED_MULTIHOP_SWAP = 511;
    uint256 internal constant INTERNAL_BALANCE_OVERFLOW = 512;
    uint256 internal constant INSUFFICIENT_INTERNAL_BALANCE = 513;
    uint256 internal constant INVALID_ETH_INTERNAL_BALANCE = 514;
    uint256 internal constant INVALID_POST_LOAN_BALANCE = 515;
    uint256 internal constant INSUFFICIENT_ETH = 516;
    uint256 internal constant UNALLOCATED_ETH = 517;
    uint256 internal constant ETH_TRANSFER = 518;
    uint256 internal constant CANNOT_USE_ETH_SENTINEL = 519;
    uint256 internal constant TOKENS_MISMATCH = 520;
    uint256 internal constant TOKEN_NOT_REGISTERED = 521;
    uint256 internal constant TOKEN_ALREADY_REGISTERED = 522;
    uint256 internal constant TOKENS_ALREADY_SET = 523;
    uint256 internal constant TOKENS_LENGTH_MUST_BE_2 = 524;
    uint256 internal constant NONZERO_TOKEN_BALANCE = 525;
    uint256 internal constant BALANCE_TOTAL_OVERFLOW = 526;
    uint256 internal constant POOL_NO_TOKENS = 527;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_BALANCE = 528;

    // Fees
    uint256 internal constant SWAP_FEE_PERCENTAGE_TOO_HIGH = 600;
    uint256 internal constant FLASH_LOAN_FEE_PERCENTAGE_TOO_HIGH = 601;
    uint256 internal constant INSUFFICIENT_FLASH_LOAN_FEE_AMOUNT = 602;
    uint256 internal constant AUM_FEE_PERCENTAGE_TOO_HIGH = 603;

    // FeeSplitter
    uint256 internal constant SPLITTER_FEE_PERCENTAGE_TOO_HIGH = 700;

    // Misc
    uint256 internal constant UNIMPLEMENTED = 998;
    uint256 internal constant SHOULD_NOT_HAPPEN = 999;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";

// solhint-disable no-inline-assembly

library ComposablePoolLib {
    using FixedPoint for uint256;

    /**
     * @notice Returns a slice of the original array, with the BPT token address removed.
     * @dev *This mutates the original array*, which should not be used anymore after calling this function.
     * It's recommended to call this function such that the calling function either immediately returns or overwrites
     * the original array variable so it cannot be accessed.
     */
    function dropBptFromTokens(IERC20[] memory registeredTokens) internal pure returns (IERC20[] memory tokens) {
        assembly {
            // An array's memory representation is a 32 byte word for the length followed by 32 byte words for
            // each element, with the stack variable pointing to the length. Since there's no memory deallocation,
            // and we are free to mutate the received array, the cheapest way to remove the first element is to
            // create a new subarray by overwriting the first element with a reduced length, and moving the pointer
            // forward to that position.
            //
            // Original:
            // [ length ] [ data[0] ] [ data[1] ] [ ... ]
            // ^ pointer
            //
            // Modified:
            // [ length ] [ length - 1 ] [ data[1] ] [ ... ]
            //                ^ pointer
            //
            // Note that this can only be done if the element to remove is the first one, which is one of the reasons
            // why Composable Pools register BPT as the first token.
            mstore(add(registeredTokens, 32), sub(mload(registeredTokens), 1))
            tokens := add(registeredTokens, 32)
        }
    }

    /**
     * @notice Returns the virtual supply, and a slice of the original balances array with the BPT balance removed.
     * @dev *This mutates the original array*, which should not be used anymore after calling this function.
     * It's recommended to call this function such that the calling function either immediately returns or overwrites
     * the original array variable so it cannot be accessed.
     */
    function dropBptFromBalances(uint256 totalSupply, uint256[] memory registeredBalances)
        internal
        pure
        returns (uint256 virtualSupply, uint256[] memory balances)
    {
        virtualSupply = totalSupply.sub(registeredBalances[0]);
        assembly {
            // See dropBptFromTokens for a detailed explanation of how this works.
            mstore(add(registeredBalances, 32), sub(mload(registeredBalances), 1))
            balances := add(registeredBalances, 32)
        }
    }

    /**
     * @notice Returns slices of the original arrays, with the BPT token address and balance removed.
     * @dev *This mutates the original arrays*, which should not be used anymore after calling this function.
     * It's recommended to call this function such that the calling function either immediately returns or overwrites
     * the original array variable so it cannot be accessed.
     */
    function dropBpt(IERC20[] memory registeredTokens, uint256[] memory registeredBalances)
        internal
        pure
        returns (IERC20[] memory tokens, uint256[] memory balances)
    {
        assembly {
            // See dropBptFromTokens for a detailed explanation of how this works
            mstore(add(registeredTokens, 32), sub(mload(registeredTokens), 1))
            tokens := add(registeredTokens, 32)

            mstore(add(registeredBalances, 32), sub(mload(registeredBalances), 1))
            balances := add(registeredBalances, 32)
        }
    }

    /**
     * @notice Returns the passed array prepended with a zero element.
     */
    function prependZeroElement(uint256[] memory array) internal pure returns (uint256[] memory prependedArray) {
        prependedArray = new uint256[](array.length + 1);
        for (uint256 i = 0; i < array.length; i++) {
            prependedArray[i + 1] = array[i];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

/**
 * @dev Building block for performing access control on external functions.
 *
 * This contract is used via the `authenticate` modifier (or the `_authenticateCaller` function), which can be applied
 * to external functions to only make them callable by authorized accounts.
 *
 * Derived contracts must implement the `_canPerform` function, which holds the actual access control logic.
 */
abstract contract Authentication is IAuthentication {
    bytes32 private immutable _actionIdDisambiguator;

    /**
     * @dev The main purpose of the `actionIdDisambiguator` is to prevent accidental function selector collisions in
     * multi contract systems.
     *
     * There are two main uses for it:
     *  - if the contract is a singleton, any unique identifier can be used to make the associated action identifiers
     *    unique. The contract's own address is a good option.
     *  - if the contract belongs to a family that shares action identifiers for the same functions, an identifier
     *    shared by the entire family (and no other contract) should be used instead.
     */
    constructor(bytes32 actionIdDisambiguator) {
        _actionIdDisambiguator = actionIdDisambiguator;
    }

    /**
     * @dev Reverts unless the caller is allowed to call this function. Should only be applied to external functions.
     */
    modifier authenticate() {
        _authenticateCaller();
        _;
    }

    /**
     * @dev Reverts unless the caller is allowed to call the entry point function.
     */
    function _authenticateCaller() internal view {
        bytes32 actionId = getActionId(msg.sig);
        _require(_canPerform(actionId, msg.sender), Errors.SENDER_NOT_ALLOWED);
    }

    function getActionId(bytes4 selector) public view override returns (bytes32) {
        // Each external function is dynamically assigned an action identifier as the hash of the disambiguator and the
        // function selector. Disambiguation is necessary to avoid potential collisions in the function selectors of
        // multiple contracts.
        return keccak256(abi.encodePacked(_actionIdDisambiguator, selector));
    }

    function _canPerform(bytes32 actionId, address user) internal view virtual returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

library InputHelpers {
    function ensureInputLengthMatch(uint256 a, uint256 b) internal pure {
        _require(a == b, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureInputLengthMatch(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure {
        _require(a == b && b == c, Errors.INPUT_LENGTH_MISMATCH);
    }

    function ensureArrayIsSorted(IERC20[] memory array) internal pure {
        address[] memory addressArray;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addressArray := array
        }
        ensureArrayIsSorted(addressArray);
    }

    function ensureArrayIsSorted(address[] memory array) internal pure {
        if (array.length < 2) {
            return;
        }

        address previous = array[0];
        for (uint256 i = 1; i < array.length; ++i) {
            address current = array[i];
            _require(previous < current, Errors.UNSORTED_ARRAY);
            previous = current;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "../math/FixedPoint.sol";
import "../math/Math.sol";
import "../openzeppelin/ERC20.sol";
import "./InputHelpers.sol";

// solhint-disable

// To simplify Pool logic, all token balances and amounts are normalized to behave as if the token had 18 decimals.
// e.g. When comparing DAI (18 decimals) and USDC (6 decimals), 1 USDC and 1 DAI would both be represented as 1e18,
// whereas without scaling 1 USDC would be represented as 1e6.
// This allows us to not consider differences in token decimals in the internal Pool maths, simplifying it greatly.

// Single Value

/**
 * @dev Applies `scalingFactor` to `amount`, resulting in a larger or equal value depending on whether it needed
 * scaling or not.
 */
function _upscale(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    // Upscale rounding wouldn't necessarily always go in the same direction: in a swap for example the balance of
    // token in should be rounded up, and that of token out rounded down. This is the only place where we round in
    // the same direction for all amounts, as the impact of this rounding is expected to be minimal.
    return FixedPoint.mulDown(amount, scalingFactor);
}

/**
 * @dev Reverses the `scalingFactor` applied to `amount`, resulting in a smaller or equal value depending on
 * whether it needed scaling or not. The result is rounded down.
 */
function _downscaleDown(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    return FixedPoint.divDown(amount, scalingFactor);
}

/**
 * @dev Reverses the `scalingFactor` applied to `amount`, resulting in a smaller or equal value depending on
 * whether it needed scaling or not. The result is rounded up.
 */
function _downscaleUp(uint256 amount, uint256 scalingFactor) pure returns (uint256) {
    return FixedPoint.divUp(amount, scalingFactor);
}

// Array

/**
 * @dev Same as `_upscale`, but for an entire array. This function does not return anything, but instead *mutates*
 * the `amounts` array.
 */
function _upscaleArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.mulDown(amounts[i], scalingFactors[i]);
    }
}

/**
 * @dev Same as `_downscaleDown`, but for an entire array. This function does not return anything, but instead
 * *mutates* the `amounts` array.
 */
function _downscaleDownArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.divDown(amounts[i], scalingFactors[i]);
    }
}

/**
 * @dev Same as `_downscaleUp`, but for an entire array. This function does not return anything, but instead
 * *mutates* the `amounts` array.
 */
function _downscaleUpArray(uint256[] memory amounts, uint256[] memory scalingFactors) pure {
    uint256 length = amounts.length;
    InputHelpers.ensureInputLengthMatch(length, scalingFactors.length);

    for (uint256 i = 0; i < length; ++i) {
        amounts[i] = FixedPoint.divUp(amounts[i], scalingFactors[i]);
    }
}

function _computeScalingFactor(IERC20 token) view returns (uint256) {
    // Tokens that don't implement the `decimals` method are not supported.
    uint256 tokenDecimals = ERC20(address(token)).decimals();

    // Tokens with more than 18 decimals are not supported.
    uint256 decimalsDifference = Math.sub(18, tokenDecimals);
    return FixedPoint.ONE * 10**decimalsDifference;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

import "../math/Math.sol";

/**
 * @dev Library for encoding and decoding values stored inside a 256 bit word. Typically used to pack multiple values in
 * a single storage slot, saving gas by performing less storage accesses.
 *
 * Each value is defined by its size and the least significant bit in the word, also known as offset. For example, two
 * 128 bit values may be encoded in a word by assigning one an offset of 0, and the other an offset of 128.
 *
 * We could use Solidity structs to pack values together in a single storage slot instead of relying on a custom and
 * error-prone library, but unfortunately Solidity only allows for structs to live in either storage, calldata or
 * memory. Because a memory struct uses not just memory but also a slot in the stack (to store its memory location),
 * using memory for word-sized values (i.e. of 256 bits or less) is strictly less gas performant, and doesn't even
 * prevent stack-too-deep issues. This is compounded by the fact that Balancer contracts typically are memory-intensive,
 * and the cost of accesing memory increases quadratically with the number of allocated words. Manual packing and
 * unpacking is therefore the preferred approach.
 */
library WordCodec {
    // solhint-disable no-inline-assembly

    // Masks are values with the least significant N bits set. They can be used to extract an encoded value from a word,
    // or to insert a new one replacing the old.
    uint256 private constant _MASK_1 = 2**(1) - 1;
    uint256 private constant _MASK_192 = 2**(192) - 1;

    // In-place insertion

    /**
     * @dev Inserts an unsigned integer of bitLength, shifted by an offset, into a 256 bit word,
     * replacing the old value. Returns the new word.
     */
    function insertUint(
        bytes32 word,
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32 result) {
        _validateEncodingParams(value, offset, bitLength);
        // Equivalent to:
        // uint256 mask = (1 << bitLength) - 1;
        // bytes32 clearedWord = bytes32(uint256(word) & ~(mask << offset));
        // result = clearedWord | bytes32(value << offset);
        assembly {
            let mask := sub(shl(bitLength, 1), 1)
            let clearedWord := and(word, not(shl(offset, mask)))
            result := or(clearedWord, shl(offset, value))
        }
    }

    /**
     * @dev Inserts a signed integer shifted by an offset into a 256 bit word, replacing the old value. Returns
     * the new word.
     *
     * Assumes `value` can be represented using `bitLength` bits.
     */
    function insertInt(
        bytes32 word,
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        uint256 mask = (1 << bitLength) - 1;
        bytes32 clearedWord = bytes32(uint256(word) & ~(mask << offset));
        // Integer values need masking to remove the upper bits of negative values.
        return clearedWord | bytes32((uint256(value) & mask) << offset);
    }

    // Encoding

    /**
     * @dev Encodes an unsigned integer shifted by an offset. Ensures value fits within
     * `bitLength` bits.
     *
     * The return value can be ORed bitwise with other encoded values to form a 256 bit word.
     */
    function encodeUint(
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        return bytes32(value << offset);
    }

    /**
     * @dev Encodes a signed integer shifted by an offset.
     *
     * The return value can be ORed bitwise with other encoded values to form a 256 bit word.
     */
    function encodeInt(
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (bytes32) {
        _validateEncodingParams(value, offset, bitLength);

        uint256 mask = (1 << bitLength) - 1;
        // Integer values need masking to remove the upper bits of negative values.
        return bytes32((uint256(value) & mask) << offset);
    }

    // Decoding

    /**
     * @dev Decodes and returns an unsigned integer with `bitLength` bits, shifted by an offset, from a 256 bit word.
     */
    function decodeUint(
        bytes32 word,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = uint256(word >> offset) & ((1 << bitLength) - 1);
        assembly {
            result := and(shr(offset, word), sub(shl(bitLength, 1), 1))
        }
    }

    /**
     * @dev Decodes and returns a signed integer with `bitLength` bits, shifted by an offset, from a 256 bit word.
     */
    function decodeInt(
        bytes32 word,
        uint256 offset,
        uint256 bitLength
    ) internal pure returns (int256 result) {
        int256 maxInt = int256((1 << (bitLength - 1)) - 1);
        uint256 mask = (1 << bitLength) - 1;

        int256 value = int256(uint256(word >> offset) & mask);
        // In case the decoded value is greater than the max positive integer that can be represented with bitLength
        // bits, we know it was originally a negative integer. Therefore, we mask it to restore the sign in the 256 bit
        // representation.
        //
        // Equivalent to:
        // result = value > maxInt ? (value | int256(~mask)) : value;
        assembly {
            result := or(mul(gt(value, maxInt), not(mask)), value)
        }
    }

    // Special cases

    /**
     * @dev Decodes and returns a boolean shifted by an offset from a 256 bit word.
     */
    function decodeBool(bytes32 word, uint256 offset) internal pure returns (bool result) {
        // Equivalent to:
        // result = (uint256(word >> offset) & 1) == 1;
        assembly {
            result := and(shr(offset, word), 1)
        }
    }

    /**
     * @dev Inserts a 192 bit value shifted by an offset into a 256 bit word, replacing the old value.
     * Returns the new word.
     *
     * Assumes `value` can be represented using 192 bits.
     */
    function insertBits192(
        bytes32 word,
        bytes32 value,
        uint256 offset
    ) internal pure returns (bytes32) {
        bytes32 clearedWord = bytes32(uint256(word) & ~(_MASK_192 << offset));
        return clearedWord | bytes32((uint256(value) & _MASK_192) << offset);
    }

    /**
     * @dev Inserts a boolean value shifted by an offset into a 256 bit word, replacing the old value. Returns the new
     * word.
     */
    function insertBool(
        bytes32 word,
        bool value,
        uint256 offset
    ) internal pure returns (bytes32 result) {
        // Equivalent to:
        // bytes32 clearedWord = bytes32(uint256(word) & ~(1 << offset));
        // bytes32 referenceInsertBool = clearedWord | bytes32(uint256(value ? 1 : 0) << offset);
        assembly {
            let clearedWord := and(word, not(shl(offset, 1)))
            result := or(clearedWord, shl(offset, value))
        }
    }

    // Helpers

    function _validateEncodingParams(
        uint256 value,
        uint256 offset,
        uint256 bitLength
    ) private pure {
        _require(offset < 256, Errors.OUT_OF_BOUNDS);
        // We never accept 256 bit values (which would make the codec pointless), and the larger the offset the smaller
        // the maximum bit length.
        _require(bitLength >= 1 && bitLength <= Math.min(255, 256 - offset), Errors.OUT_OF_BOUNDS);

        // Testing unsigned values for size is straightforward: their upper bits must be cleared.
        _require(value >> bitLength == 0, Errors.CODEC_OVERFLOW);
    }

    function _validateEncodingParams(
        int256 value,
        uint256 offset,
        uint256 bitLength
    ) private pure {
        _require(offset < 256, Errors.OUT_OF_BOUNDS);
        // We never accept 256 bit values (which would make the codec pointless), and the larger the offset the smaller
        // the maximum bit length.
        _require(bitLength >= 1 && bitLength <= Math.min(255, 256 - offset), Errors.OUT_OF_BOUNDS);

        // Testing signed values for size is a bit more involved.
        if (value >= 0) {
            // For positive values, we can simply check that the upper bits are clear. Notice we remove one bit from the
            // length for the sign bit.
            _require(value >> (bitLength - 1) == 0, Errors.CODEC_OVERFLOW);
        } else {
            // Negative values can receive the same treatment by making them positive, with the caveat that the range
            // for negative values in two's complement supports one more value than for the positive case.
            _require(Math.abs(value + 1) >> (bitLength - 1) == 0, Errors.CODEC_OVERFLOW);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

import "./LogExpMath.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    // solhint-disable no-inline-assembly

    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant TWO = 2 * ONE;
    uint256 internal constant FOUR = 4 * ONE;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 product = a * b;
        _require(a == 0 || product / a == b, Errors.MUL_OVERFLOW);

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = product == 0 ? 0 : ((product - 1) / FixedPoint.ONE) + 1;
        assembly {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);

        uint256 aInflated = a * ONE;
        _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

        return aInflated / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        uint256 aInflated = a * ONE;
        _require(a == 0 || aInflated / a == ONE, Errors.DIV_INTERNAL); // mul overflow

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = a == 0 ? 0 : (a * FixedPoint.ONE - 1) / b + 1;
        assembly {
            result := mul(iszero(iszero(aInflated)), add(div(sub(aInflated, 1), b), 1))
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            if (raw < maxError) {
                return 0;
            } else {
                return sub(raw, maxError);
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            return add(raw, maxError);
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (x < ONE) ? (ONE - x) : 0;
        assembly {
            result := mul(lt(x, ONE), sub(ONE, x))
        }
    }
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2**254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        if (y == 0) {
            // We solve the 0^0 indetermination by making it equal one.
            return uint256(ONE_18);
        }

        if (x == 0) {
            return 0;
        }

        // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
        // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
        // x^y = exp(y * ln(x)).

        // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
        _require(x >> 255 == 0, Errors.X_OUT_OF_BOUNDS);
        int256 x_int256 = int256(x);

        // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
        // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

        // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
        _require(y < MILD_EXPONENT_BOUND, Errors.Y_OUT_OF_BOUNDS);
        int256 y_int256 = int256(y);

        int256 logx_times_y;
        if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
            int256 ln_36_x = _ln_36(x_int256);

            // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
            // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
            // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
            // (downscaled) last 18 decimals.
            logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
        } else {
            logx_times_y = _ln(x_int256) * y_int256;
        }
        logx_times_y /= ONE_18;

        // Finally, we compute exp(y * ln(x)) to arrive at x^y
        _require(
            MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
            Errors.PRODUCT_OUT_OF_BOUNDS
        );

        return uint256(exp(logx_times_y));
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        _require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, Errors.INVALID_EXPONENT);

        if (x < 0) {
            // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
            // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
            // Fixed point division requires multiplying by ONE_18.
            return ((ONE_18 * ONE_18) / exp(-x));
        }

        // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
        // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
        // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
        // decomposition.
        // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
        // decomposition, which will be lower than the smallest x_n.
        // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
        // We mutate x by subtracting x_n, making it the remainder of the decomposition.

        // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
        // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
        // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
        // decomposition.

        // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
        // it and compute the accumulated product.

        int256 firstAN;
        if (x >= x0) {
            x -= x0;
            firstAN = a0;
        } else if (x >= x1) {
            x -= x1;
            firstAN = a1;
        } else {
            firstAN = 1; // One with no decimal places
        }

        // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
        // smaller terms.
        x *= 100;

        // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
        // one. Recall that fixed point multiplication requires dividing by ONE_20.
        int256 product = ONE_20;

        if (x >= x2) {
            x -= x2;
            product = (product * a2) / ONE_20;
        }
        if (x >= x3) {
            x -= x3;
            product = (product * a3) / ONE_20;
        }
        if (x >= x4) {
            x -= x4;
            product = (product * a4) / ONE_20;
        }
        if (x >= x5) {
            x -= x5;
            product = (product * a5) / ONE_20;
        }
        if (x >= x6) {
            x -= x6;
            product = (product * a6) / ONE_20;
        }
        if (x >= x7) {
            x -= x7;
            product = (product * a7) / ONE_20;
        }
        if (x >= x8) {
            x -= x8;
            product = (product * a8) / ONE_20;
        }
        if (x >= x9) {
            x -= x9;
            product = (product * a9) / ONE_20;
        }

        // x10 and x11 are unnecessary here since we have high enough precision already.

        // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
        // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

        int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
        int256 term; // Each term in the sum, where the nth term is (x^n / n!).

        // The first term is simply x.
        term = x;
        seriesSum += term;

        // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
        // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

        term = ((term * x) / ONE_20) / 2;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 3;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 4;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 5;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 6;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 7;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 8;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 9;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 10;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 11;
        seriesSum += term;

        term = ((term * x) / ONE_20) / 12;
        seriesSum += term;

        // 12 Taylor terms are sufficient for 18 decimal precision.

        // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
        // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
        // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
        // and then drop two digits to return an 18 decimal value.

        return (((product * seriesSum) / ONE_20) * firstAN) / 100;
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

        // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
        // upscaling.

        int256 logBase;
        if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
            logBase = _ln_36(base);
        } else {
            logBase = _ln(base) * ONE_18;
        }

        int256 logArg;
        if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
            logArg = _ln_36(arg);
        } else {
            logArg = _ln(arg) * ONE_18;
        }

        // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
        return (logArg * ONE_18) / logBase;
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        // The real natural logarithm is not defined for negative numbers or zero.
        _require(a > 0, Errors.OUT_OF_BOUNDS);
        if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
            return _ln_36(a) / ONE_18;
        } else {
            return _ln(a);
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        if (a < ONE_18) {
            // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
            // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
            // Fixed point division requires multiplying by ONE_18.
            return (-_ln((ONE_18 * ONE_18) / a));
        }

        // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
        // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
        // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
        // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
        // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
        // decomposition, which will be lower than the smallest a_n.
        // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
        // We mutate a by subtracting a_n, making it the remainder of the decomposition.

        // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
        // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
        // ONE_18 to convert them to fixed point.
        // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
        // by it and compute the accumulated sum.

        int256 sum = 0;
        if (a >= a0 * ONE_18) {
            a /= a0; // Integer, not fixed point division
            sum += x0;
        }

        if (a >= a1 * ONE_18) {
            a /= a1; // Integer, not fixed point division
            sum += x1;
        }

        // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
        sum *= 100;
        a *= 100;

        // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

        if (a >= a2) {
            a = (a * ONE_20) / a2;
            sum += x2;
        }

        if (a >= a3) {
            a = (a * ONE_20) / a3;
            sum += x3;
        }

        if (a >= a4) {
            a = (a * ONE_20) / a4;
            sum += x4;
        }

        if (a >= a5) {
            a = (a * ONE_20) / a5;
            sum += x5;
        }

        if (a >= a6) {
            a = (a * ONE_20) / a6;
            sum += x6;
        }

        if (a >= a7) {
            a = (a * ONE_20) / a7;
            sum += x7;
        }

        if (a >= a8) {
            a = (a * ONE_20) / a8;
            sum += x8;
        }

        if (a >= a9) {
            a = (a * ONE_20) / a9;
            sum += x9;
        }

        if (a >= a10) {
            a = (a * ONE_20) / a10;
            sum += x10;
        }

        if (a >= a11) {
            a = (a * ONE_20) / a11;
            sum += x11;
        }

        // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
        // that converges rapidly for values of `a` close to one - the same one used in ln_36.
        // Let z = (a - 1) / (a + 1).
        // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
        // division by ONE_20.
        int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
        int256 z_squared = (z * z) / ONE_20;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_20;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_20;
        seriesSum += num / 11;

        // 6 Taylor terms are sufficient for 36 decimal precision.

        // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
        seriesSum *= 2;

        // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
        // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
        // value.

        return (sum + seriesSum) / 100;
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
        // worthwhile.

        // First, we transform x to a 36 digit fixed point value.
        x *= ONE_18;

        // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
        // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

        // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
        // division by ONE_36.
        int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
        int256 z_squared = (z * z) / ONE_36;

        // num is the numerator of the series: the z^(2 * n + 1) term
        int256 num = z;

        // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
        int256 seriesSum = num;

        // In each step, the numerator is multiplied by z^2
        num = (num * z_squared) / ONE_36;
        seriesSum += num / 3;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 5;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 7;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 9;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 11;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 13;

        num = (num * z_squared) / ONE_36;
        seriesSum += num / 15;

        // 8 Taylor terms are sufficient for 36 decimal precision.

        // All that remains is multiplying by 2 (non fixed point).
        return seriesSum * 2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow checks.
 * Adapted from OpenZeppelin's SafeMath library.
 */
library Math {
    // solhint-disable no-inline-assembly

    /**
     * @dev Returns the absolute value of a signed integer.
     */
    function abs(int256 a) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = a > 0 ? uint256(a) : uint256(-a)
        assembly {
            let s := sar(255, a)
            result := sub(xor(a, s), s)
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers of 256 bits, reverting on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        _require((b >= 0 && c >= a) || (b < 0 && c < a), Errors.ADD_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers of 256 bits, reverting on overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b <= a, Errors.SUB_OVERFLOW);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        _require((b >= 0 && c <= a) || (b < 0 && c > a), Errors.SUB_OVERFLOW);
        return c;
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to:
        // result = (a < b) ? b : a;
        assembly {
            result := sub(a, mul(sub(a, b), lt(a, b)))
        }
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256 result) {
        // Equivalent to `result = (a < b) ? a : b`
        assembly {
            result := sub(a, mul(sub(a, b), gt(a, b)))
        }
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        _require(a == 0 || c / a == b, Errors.MUL_OVERFLOW);
        return c;
    }

    function div(
        uint256 a,
        uint256 b,
        bool roundUp
    ) internal pure returns (uint256) {
        return roundUp ? divUp(a, b) : divDown(a, b);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        _require(b != 0, Errors.ZERO_DIVISION);
        return a / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        _require(b != 0, Errors.ZERO_DIVISION);

        // Equivalent to:
        // result = a == 0 ? 0 : 1 + (a - 1) / b;
        assembly {
            result := mul(iszero(iszero(a)), add(1, div(sub(a, 1), b)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";

import "./SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}. The total supply should only be read using this function
     *
     * Can be overridden by derived contracts to store the total supply in a different way (e.g. packed with other
     * storage values).
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Sets a new value for the total supply. It should only be set using this function.
     *
     * * Can be overridden by derived contracts to store the total supply in a different way (e.g. packed with other
     * storage values).
     */
    function _setTotalSupply(uint256 value) internal virtual {
        _totalSupply = value;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_ALLOWANCE)
        );
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
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(subtractedValue, Errors.ERC20_DECREASED_ALLOWANCE_BELOW_ZERO)
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        _require(sender != address(0), Errors.ERC20_TRANSFER_FROM_ZERO_ADDRESS);
        _require(recipient != address(0), Errors.ERC20_TRANSFER_TO_ZERO_ADDRESS);

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, Errors.ERC20_TRANSFER_EXCEEDS_BALANCE);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), account, amount);

        _setTotalSupply(totalSupply().add(amount));
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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
        _require(account != address(0), Errors.ERC20_BURN_FROM_ZERO_ADDRESS);

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, Errors.ERC20_BURN_EXCEEDS_BALANCE);
        _setTotalSupply(totalSupply().sub(amount));
        emit Transfer(account, address(0), amount);
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
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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
    ) internal virtual {
        // solhint-disable-previous-line no-empty-blocks
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        _require(c >= a, Errors.ADD_OVERFLOW);

        return c;
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
        return sub(a, b, Errors.SUB_OVERFLOW);
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        uint256 errorCode
    ) internal pure returns (uint256) {
        _require(b <= a, errorCode);
        uint256 c = a - b;

        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

/**
 * @title Circuit Breaker Library
 * @notice Library for logic and functions related to circuit breakers.
 */
library CircuitBreakerLib {
    using FixedPoint for uint256;

    /**
     * @notice Single-sided check for whether a lower or upper circuit breaker would trip in the given pool state.
     * @dev Compute the current BPT price from the input parameters, and compare it to the given bound to determine
     * whether the given post-operation pool state is within the circuit breaker bounds.
     * @param virtualSupply - the post-operation totalSupply (including protocol fees, etc.)
     * @param weight - the normalized weight of the token we are checking.
     * @param balance - the post-operation token balance (including swap fees, etc.). It must be an 18-decimal
     * floating point number, adjusted by the scaling factor of the token.
     * @param boundBptPrice - the BPT price at the limit (lower or upper) of the allowed trading range.
     * @param isLowerBound - true if the boundBptPrice represents the lower bound.
     * @return - boolean flag for whether the breaker has been tripped.
     */
    function hasCircuitBreakerTripped(
        uint256 virtualSupply,
        uint256 weight,
        uint256 balance,
        uint256 boundBptPrice,
        bool isLowerBound
    ) internal pure returns (bool) {
        // A bound price of 0 means that no breaker is set.
        if (boundBptPrice == 0) {
            return false;
        }

        // Round down for lower bound checks, up for upper bound checks
        uint256 currentBptPrice = Math.div(Math.mul(virtualSupply, weight), balance, !isLowerBound);

        return isLowerBound ? currentBptPrice < boundBptPrice : currentBptPrice > boundBptPrice;
    }

    /**
     * @notice Convert a bound to a BPT price ratio
     * @param bound - The bound percentage.
     * @param weight - The current normalized token weight.
     * @param isLowerBound - A flag indicating whether this is for a lower bound.
     */
    function calcAdjustedBound(
        uint256 bound,
        uint256 weight,
        bool isLowerBound
    ) external pure returns (uint256 boundRatio) {
        // To be conservative and protect LPs, round up for the lower bound, and down for the upper bound.
        boundRatio = (isLowerBound ? FixedPoint.powUp : FixedPoint.powDown)(bound, weight.complement());
    }

    /**
     * @notice Convert a BPT price ratio to a BPT price bound
     * @param boundRatio - The cached bound ratio
     * @param bptPrice - The BPT price stored at the time the breaker was set.
     * @param isLowerBound - A flag indicating whether this is for a lower bound.
     */
    function calcBptPriceBoundary(
        uint256 boundRatio,
        uint256 bptPrice,
        bool isLowerBound
    ) internal pure returns (uint256 boundBptPrice) {
        // To be conservative and protect LPs, round up for the lower bound, and down for the upper bound.
        boundBptPrice = (isLowerBound ? FixedPoint.mulUp : FixedPoint.mulDown)(bptPrice, boundRatio);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

pragma solidity ^0.7.0;

// solhint-disable not-rely-on-time

library GradualValueChange {
    using FixedPoint for uint256;

    function getInterpolatedValue(
        uint256 startValue,
        uint256 endValue,
        uint256 startTime,
        uint256 endTime
    ) internal view returns (uint256) {
        uint256 pctProgress = calculateValueChangeProgress(startTime, endTime);

        return interpolateValue(startValue, endValue, pctProgress);
    }

    function resolveStartTime(uint256 startTime, uint256 endTime) internal view returns (uint256 resolvedStartTime) {
        // If the start time is in the past, "fast forward" to start now
        // This avoids discontinuities in the value curve. Otherwise, if you set the start/end times with
        // only 10% of the period in the future, the value would immediately jump 90%
        resolvedStartTime = Math.max(block.timestamp, startTime);

        _require(resolvedStartTime <= endTime, Errors.GRADUAL_UPDATE_TIME_TRAVEL);
    }

    function interpolateValue(
        uint256 startValue,
        uint256 endValue,
        uint256 pctProgress
    ) internal pure returns (uint256) {
        if (pctProgress >= FixedPoint.ONE || startValue == endValue) return endValue;
        if (pctProgress == 0) return startValue;

        if (startValue > endValue) {
            uint256 delta = pctProgress.mulDown(startValue - endValue);
            return startValue - delta;
        } else {
            uint256 delta = pctProgress.mulDown(endValue - startValue);
            return startValue + delta;
        }
    }

    /**
     * @dev Returns a fixed-point number representing how far along the current value change is, where 0 means the
     * change has not yet started, and FixedPoint.ONE means it has fully completed.
     */
    function calculateValueChangeProgress(uint256 startTime, uint256 endTime) internal view returns (uint256) {
        if (block.timestamp >= endTime) {
            return FixedPoint.ONE;
        } else if (block.timestamp <= startTime) {
            return 0;
        }

        // No need for SafeMath as it was checked right above: endTime > block.timestamp > startTime
        uint256 totalSeconds = endTime - startTime;
        uint256 secondsElapsed = block.timestamp - startTime;

        // We don't need to consider zero division here as this is covered above.
        return secondsElapsed.divDown(totalSeconds);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/math/FixedPoint.sol";
import "@balancer-labs/v2-solidity-utils/contracts/math/Math.sol";

/**
 * @dev Library for compressing and decompressing numbers by using smaller types.
 * All values are 18 decimal fixed-point numbers, so heavier compression (fewer bits)
 * results in fewer decimals.
 */
library ValueCompression {
    /**
     * @notice Returns the maximum potential error when compressing and decompressing a value to a certain bit length.
     * @dev During compression, the range [0, maxUncompressedValue] is mapped onto the range [0, maxCompressedValue].
     * Each increment in compressed space then corresponds to an increment of maxUncompressedValue / maxCompressedValue
     * in uncompressed space. This granularity is the maximum error when decompressing a compressed value.
     */
    function maxCompressionError(uint256 bitLength, uint256 maxUncompressedValue) internal pure returns (uint256) {
        // It's not meaningful to compress 1-bit values (2 bits is also a bit silly, but theoretically possible).
        // 255 would likewise not be very helpful, but is technically valid.
        _require(bitLength >= 2 && bitLength <= 255, Errors.OUT_OF_BOUNDS);

        uint256 maxCompressedValue = (1 << bitLength) - 1;
        return Math.divUp(maxUncompressedValue, maxCompressedValue);
    }

    /**
     * @dev Compress a 256 bit value into `bitLength` bits.
     * To compress a value down to n bits, you first "normalize" it over the full input range.
     * For instance, if the maximum value were 10_000, and the `value` is 2_000, it would be
     * normalized to 0.2.
     *
     * Finally, "scale" that normalized value into the output range: adapting [0, maxUncompressedValue]
     * to [0, max n-bit value]. For n=8 bits, the max value is 255, so 0.2 corresponds to 51.
     * Likewise, for 16 bits, 0.2 would be stored as 13_107.
     */
    function compress(
        uint256 value,
        uint256 bitLength,
        uint256 maxUncompressedValue
    ) internal pure returns (uint256) {
        // It's not meaningful to compress 1-bit values (2 bits is also a bit silly, but theoretically possible).
        // 255 would likewise not be very helpful, but is technically valid.
        _require(bitLength >= 2 && bitLength <= 255, Errors.OUT_OF_BOUNDS);
        // The value cannot exceed the input range, or the compression would not "fit" in the output range.
        _require(value <= maxUncompressedValue, Errors.OUT_OF_BOUNDS);

        // There is another way this can fail: maxUncompressedValue * value can overflow, if either or both
        // are too big. Essentially, the maximum bitLength will be about 256 - (# bits needed for maxUncompressedValue).
        // It's not worth it to test for this: the caller is responsible for many things anyway, notably ensuring
        // compress and decompress are called with the same arguments, and packing the resulting value properly
        // (the most common use is to assist in packing several variables into a 256-bit word).

        uint256 maxCompressedValue = (1 << bitLength) - 1;

        return Math.divDown(Math.mul(value, maxCompressedValue), maxUncompressedValue);
    }

    /**
     * @dev Reverse a compression operation, and restore the 256 bit value from a compressed value of
     * length `bitLength`. The compressed value is in the range [0, 2^(bitLength) - 1], and we are mapping
     * it back onto the uncompressed range [0, maxUncompressedValue].
     *
     * It is very important that the bitLength and maxUncompressedValue arguments are the
     * same for compress and decompress, or the results will be meaningless. This must be validated
     * externally.
     */
    function decompress(
        uint256 value,
        uint256 bitLength,
        uint256 maxUncompressedValue
    ) internal pure returns (uint256) {
        // It's not meaningful to compress 1-bit values (2 bits is also a bit silly, but theoretically possible).
        // 255 would likewise not be very helpful, but is technically valid.
        _require(bitLength >= 2 && bitLength <= 255, Errors.OUT_OF_BOUNDS);
        uint256 maxCompressedValue = (1 << bitLength) - 1;
        // The value must not exceed the maximum compressed value (2**(bitLength) - 1), or it will exceed the max
        // uncompressed value.
        _require(value <= maxCompressedValue, Errors.OUT_OF_BOUNDS);

        return Math.divDown(Math.mul(value, maxUncompressedValue), maxCompressedValue);
    }

    // Special case overloads

    /**
     * @dev It is very common for the maximum value to be one: Weighted Pool weights, for example.
     * Overload for this common case, passing FixedPoint.ONE to the general `compress` function.
     */
    function compress(uint256 value, uint256 bitLength) internal pure returns (uint256) {
        return compress(value, bitLength, FixedPoint.ONE);
    }

    /**
     * @dev It is very common for the maximum value to be one: Weighted Pool weights, for example.
     * Overload for this common case, passing FixedPoint.ONE to the general `decompress` function.
     */
    function decompress(uint256 value, uint256 bitLength) internal pure returns (uint256) {
        return decompress(value, bitLength, FixedPoint.ONE);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-solidity-utils/contracts/helpers/WordCodec.sol";

import "../lib/ValueCompression.sol";
import "../lib/CircuitBreakerLib.sol";

/**
 * @title Circuit Breaker Storage Library
 * @notice Library for storing and manipulating state related to circuit breakers.
 * @dev The intent of circuit breakers is to halt trading of a given token if its value changes drastically -
 * in either direction - with respect to other tokens in the pool. For instance, a stablecoin might de-peg
 * and go to zero. With no safeguards, arbitrageurs could drain the pool by selling large amounts of the
 * token to the pool at inflated internal prices.
 *
 * The circuit breaker mechanism establishes a "safe trading range" for each token, expressed in terms of
 * the BPT price. Both lower and upper bounds can be set, and if a trade would result in moving the BPT price
 * of any token involved in the operation outside that range, the breaker is "tripped", and the operation
 * should revert. Each token is independent, since some might have very "tight" valid trading ranges, such as
 * stablecoins, and others are more volatile.
 *
 * The BPT price of a token is defined as the amount of BPT that could be redeemed for a single token.
 * For instance, in an 80/20 pool with a total supply of 1000, the 80% token accounts for 800 BPT. So each
 * token would be worth 800 / token balance. The formula is then: total supply * token weight / token balance.
 * (Note that this only applies *if* the pool is balanced (a condition that cannot be checked by the pool without
 * accessing price oracles.)
 *
 * We need to use the BPT price as the measure to ensure we account for the change relative to the rest of
 * the pool, which could have many other tokens. The drop detected by circuit breakers is analogous to
 * impermanent loss: it is relative to the performance of the other tokens. If the entire market tanks and
 * all token balances go down together, the *relative* change would be zero, and the breaker would not be
 * triggered: even though the external price might have dropped 50 or 70%. It is only the *relative* movement
 * compared to the rest of the pool that matters.
 *
 * If we have tokens A, B, and C, If A drops 20% and B and C are unchanged, that's a simple 20% drop for A.
 * However, if A is unchanged and C increases 25%, that would also be a 20% "drop" for A 1 / 1.25 = 0.8.
 * The breaker might register a 20% drop even if both go up - if our target token lags the market. For
 * instance, if A goes up 60% and B and C double, 1.6 / 2 = 0.8.
 *
 * Since BPT prices are not intuitive - and there is a very non-linear relationship between "spot" prices and
 * BPT prices - circuit breakers are set using simple percentages. Intuitively, a lower bound of 0.8 means the
 * token can lose 20% of its value before triggering the circuit breaker, and an upper bound of 3.0 means it
 * can triple before being halted. These percentages are then transformed into BPT prices for comparison to the
 * "reference" state of the pool when the circuit breaker was set.
 *
 * Prices can change in two ways: arbitrage traders responding to external price movement can change the balances,
 * or an ongoing gradual weight update (or change in pool composition) can change the weights. In order to isolate
 * the balance changes due to price movement, the bounds are dynamic, adjusted for the current weight.
 */
library CircuitBreakerStorageLib {
    using ValueCompression for uint256;
    using FixedPoint for uint256;
    using WordCodec for bytes32;

    // Store circuit breaker information per token
    // When the circuit breaker is set, the caller passes in the lower and upper bounds (expressed as percentages),
    // the current BPT price, and the normalized weight. The weight is bound by 1e18, and fits in ~60 bits, so there
    // is no need for compression. We store the weight in 64 bits, just to use round numbers for all the bit lengths.
    //
    // We then store the current BPT price, and compute and cache the adjusted lower and upper bounds at the current
    // weight. When multiplied by the stored BPT price, the adjusted bounds define the BPT price trading range: the
    // "runtime" BPT prices can be directly compared to these BPT price bounds.
    //
    // Since the price bounds need to be adjusted for the token weight, in general these adjusted bounds would be
    // computed every time. However, if the weight of the token has not changed since the circuit breaker was set,
    // the adjusted bounds cache can still be used, avoiding a heavy computation.
    //
    // [        32 bits       |        32 bits       |  96 bits  |     64 bits      |   16 bits   |   16 bits   |
    // [ adjusted upper bound | adjusted lower bound | BPT price | reference weight | upper bound | lower bound |
    // |MSB                                                                                                  LSB|
    uint256 private constant _LOWER_BOUND_OFFSET = 0;
    uint256 private constant _UPPER_BOUND_OFFSET = _LOWER_BOUND_OFFSET + _BOUND_WIDTH;
    uint256 private constant _REFERENCE_WEIGHT_OFFSET = _UPPER_BOUND_OFFSET + _BOUND_WIDTH;
    uint256 private constant _BPT_PRICE_OFFSET = _REFERENCE_WEIGHT_OFFSET + _REFERENCE_WEIGHT_WIDTH;
    uint256 private constant _ADJUSTED_LOWER_BOUND_OFFSET = _BPT_PRICE_OFFSET + _BPT_PRICE_WIDTH;
    uint256 private constant _ADJUSTED_UPPER_BOUND_OFFSET = _ADJUSTED_LOWER_BOUND_OFFSET + _ADJUSTED_BOUND_WIDTH;

    uint256 private constant _REFERENCE_WEIGHT_WIDTH = 64;
    uint256 private constant _BPT_PRICE_WIDTH = 96;
    uint256 private constant _BOUND_WIDTH = 16;
    uint256 private constant _ADJUSTED_BOUND_WIDTH = 32;

    // We allow the bounds to range over two orders of magnitude: 0.1 - 10. The maximum upper bound is set to 10.0
    // in 18-decimal floating point, since this fits in 64 bits, and can be shifted down to 16 bit precision without
    // much loss. Since compression would lose a lot of precision for values close to 0, we also constrain the lower
    // bound to a minimum value >> 0.
    //
    // Since the adjusted bounds are (bound percentage)**(1 - weight), and weights are stored normalized, the
    // maximum normalized weight is 1 - minimumWeight, which is 0.99 ~ 1. Therefore the adjusted bounds are likewise
    // constrained to 10**1 ~ 10. So we can use this as the maximum value of both the raw percentage and
    // weight-adjusted percentage bounds.
    uint256 private constant _MIN_BOUND_PERCENTAGE = 1e17; // 0.1 in 18-decimal fixed point

    uint256 private constant _MAX_BOUND_PERCENTAGE = 10e18; // 10.0 in 18-decimal fixed point

    // Since we know the bounds fit into 64 bits, simply shifting them down to fit in 16 bits is not only faster than
    // the compression and decompression operations, but generally less lossy.
    uint256 private constant _BOUND_SHIFT_BITS = 64 - _BOUND_WIDTH;

    /**
     * @notice Returns the BPT price, reference weight, and the lower and upper percentage bounds for a given token.
     * @dev If an upper or lower bound value is zero, it means there is no circuit breaker in that direction for the
     * given token.
     * @param circuitBreakerState - The bytes32 state of the token of interest.
     */
    function getCircuitBreakerFields(bytes32 circuitBreakerState)
        internal
        pure
        returns (
            uint256 bptPrice,
            uint256 referenceWeight,
            uint256 lowerBound,
            uint256 upperBound
        )
    {
        bptPrice = circuitBreakerState.decodeUint(_BPT_PRICE_OFFSET, _BPT_PRICE_WIDTH);
        referenceWeight = circuitBreakerState.decodeUint(_REFERENCE_WEIGHT_OFFSET, _REFERENCE_WEIGHT_WIDTH);
        // Decompress the bounds by shifting left.
        lowerBound = circuitBreakerState.decodeUint(_LOWER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS;
        upperBound = circuitBreakerState.decodeUint(_UPPER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS;
    }

    /**
     * @notice Returns a dynamic lower or upper BPT price bound for a given token, at the current weight.
     * @dev The current BPT price of the token can be directly compared to this value, to determine whether
     * the breaker should be tripped. If a bound is 0, it means there is no circuit breaker in that direction
     * for this token: there might be a lower bound, but no upper bound. If the current BPT price is less than
     * the lower bound, or greater than the non-zero upper bound, the transaction should revert.
     *
     * These BPT price bounds are dynamically adjusted by a non-linear factor dependent on the weight.
     * In general: lower/upper BPT price bound = bptPrice * "weight adjustment". The weight adjustment is
     * given as: (boundaryPercentage)**(1 - weight).
     *
     * For instance, given the 80/20 BAL/WETH pool with a 90% lower bound, the weight complement would be
     * (1 - 0.8) = 0.2, so the lower adjusted bound would be (0.9 ** 0.2) ~ 0.9791. For the WETH token at 20%,
     * the bound would be (0.9 ** 0.8) ~ 0.9192.
     *
     * With unequal weights (assuming a balanced pool), the balance of a higher-weight token will respond less
     * to a proportional change in spot price than a lower weight token, which we might call "balance inertia".
     *
     * If the external price drops, all else being equal, the pool would be arbed until the percent drop in spot
     * price equaled the external price drop. Since during this process the *internal* pool price would be
     * above market, the arbers would sell cheap tokens to our poor unwitting pool at inflated prices, raising
     * the balance of the depreciating token, and lowering the balance of another token (WETH in this example).
     *
     * Using weighted math, and assuming for simplicity that the sum of all weights is 1, you can compute the
     * amountIn ratio for the arb trade as: (1/priceRatio) ** (1 - weight). For our 0.9 ratio and a weight of
     * 0.8, this is ~ 1.0213. So if you had 8000 tokens before, the ending balance would be 8000*1.0213 ~ 8170.
     * Note that the higher the weight, the lower this ratio is. That means the counterparty token is going
     * out proportionally faster than the arb token is coming in: hence the non-linear relationship between
     * spot price and BPT price.
     *
     * If we call the initial balance B0, and set k = (1/priceRatio) ** (1 - weight), the post-arb balance is
     * given by: B1 = k * B0. Since the BPTPrice0 = totalSupply*weight/B0, and BPTPrice1 = totalSupply*weight/B1,
     * we can combine these equations to compute the BPT price ratio BPTPrice1/BPTPrice0 = 1/k; BPT1 = BPT0/k.
     * So we see that the "conversion factor" between the spot price ratio and BPT Price ratio can be written
     * as above BPT1 = BPT0 * (1/k), or more simply: (BPT price) * (priceRatio)**(1 - weight).
     *
     * Another way to think of it is in terms of "BPT Value". Assuming a balanced pool, a token with a weight
     * of 80% represents 80% of the value of the BPT. An uncorrelated drop in that token's value would drop
     * the value of LP shares much faster than a similar drop in the value of a 20% token. Whatever the value
     * of the bound percentage, as the adjustment factor - B ** (1 - weight) - approaches 1, less adjustment
     * is necessary: it tracks the relative price movement more closely. Intuitively, this is wny we use the
     * complement of the weight. Higher weight = lower exponent = adjustment factor closer to 1.0 = "faster"
     * tracking of value changes.
     *
     * If the value of the weight has not changed, we can use the cached adjusted bounds stored when the breaker
     * was set. Otherwise, we need to calculate them.
     *
     * As described in the general comments above, the weight adjustment calculation attempts to isolate changes
     * in the balance due to arbitrageurs responding to external prices, from internal price changes caused by
     * weight changes. There is a non-linear relationship between "spot" price changes and BPT price changes.
     * This calculation transforms one into the other.
     * @param circuitBreakerState - The bytes32 state of the token of interest.
     * @param currentWeight - The token's current normalized weight.
     * @param isLowerBound - Flag indicating whether this is the lower bound.
     * @return - lower or upper bound BPT price, which can be directly compared against the current BPT price.
     */
    function getBptPriceBound(
        bytes32 circuitBreakerState,
        uint256 currentWeight,
        bool isLowerBound
    ) internal pure returns (uint256) {
        uint256 bound = circuitBreakerState.decodeUint(
            isLowerBound ? _LOWER_BOUND_OFFSET : _UPPER_BOUND_OFFSET,
            _BOUND_WIDTH
        ) << _BOUND_SHIFT_BITS;

        if (bound == 0) {
            return 0;
        }
        // Retrieve the BPT price and reference weight passed in when the circuit breaker was set.
        uint256 bptPrice = circuitBreakerState.decodeUint(_BPT_PRICE_OFFSET, _BPT_PRICE_WIDTH);
        uint256 referenceWeight = circuitBreakerState.decodeUint(_REFERENCE_WEIGHT_OFFSET, _REFERENCE_WEIGHT_WIDTH);

        uint256 boundRatio;

        if (currentWeight == referenceWeight) {
            // If the weight hasn't changed since the circuit breaker was set, we can use the precomputed
            // adjusted bounds.
            boundRatio = circuitBreakerState
                .decodeUint(
                isLowerBound ? _ADJUSTED_LOWER_BOUND_OFFSET : _ADJUSTED_UPPER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            )
                .decompress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE);
        } else {
            // The weight has changed, so we retrieve the raw percentage bounds and do the full calculation.
            // Decompress the bounds by shifting left.
            boundRatio = CircuitBreakerLib.calcAdjustedBound(bound, currentWeight, isLowerBound);
        }

        // Use the adjusted bounds (either cached or computed) to calculate the BPT price bounds.
        return CircuitBreakerLib.calcBptPriceBoundary(boundRatio, bptPrice, isLowerBound);
    }

    /**
     * @notice Sets the reference BPT price, normalized weight, and upper and lower bounds for a token.
     * @dev If a bound is zero, it means there is no circuit breaker in that direction for the given token.
     * @param bptPrice: The BPT price of the token at the time the circuit breaker is set. The BPT Price
     * of a token is generally given by: supply * weight / balance.
     * @param referenceWeight: This is the current normalized weight of the token.
     * @param lowerBound: The value of the lower bound, expressed as a percentage.
     * @param upperBound: The value of the upper bound, expressed as a percentage.
     */
    function setCircuitBreaker(
        uint256 bptPrice,
        uint256 referenceWeight,
        uint256 lowerBound,
        uint256 upperBound
    ) internal pure returns (bytes32) {
        // It's theoretically not required for the lower bound to be < 1, but it wouldn't make much sense otherwise:
        // the circuit breaker would immediately trip. Note that this explicitly allows setting either to 0, disabling
        // the circuit breaker for the token in that direction.
        _require(
            lowerBound == 0 || (lowerBound >= _MIN_BOUND_PERCENTAGE && lowerBound <= FixedPoint.ONE),
            Errors.INVALID_CIRCUIT_BREAKER_BOUNDS
        );
        _require(upperBound <= _MAX_BOUND_PERCENTAGE, Errors.INVALID_CIRCUIT_BREAKER_BOUNDS);
        _require(upperBound == 0 || upperBound >= lowerBound, Errors.INVALID_CIRCUIT_BREAKER_BOUNDS);

        // Set the reference parameters: BPT price of the token, and the reference weight.
        bytes32 circuitBreakerState = bytes32(0).insertUint(bptPrice, _BPT_PRICE_OFFSET, _BPT_PRICE_WIDTH).insertUint(
            referenceWeight,
            _REFERENCE_WEIGHT_OFFSET,
            _REFERENCE_WEIGHT_WIDTH
        );

        // Add the lower and upper percentage bounds. Compress by shifting right.
        circuitBreakerState = circuitBreakerState
            .insertUint(lowerBound >> _BOUND_SHIFT_BITS, _LOWER_BOUND_OFFSET, _BOUND_WIDTH)
            .insertUint(upperBound >> _BOUND_SHIFT_BITS, _UPPER_BOUND_OFFSET, _BOUND_WIDTH);

        // Precompute and store the adjusted bounds, used to convert percentage bounds to BPT price bounds.
        // If the weight has not changed since the breaker was set, we can use the precomputed values directly,
        // and avoid a heavy computation.
        uint256 adjustedLowerBound = CircuitBreakerLib.calcAdjustedBound(lowerBound, referenceWeight, true);
        uint256 adjustedUpperBound = CircuitBreakerLib.calcAdjustedBound(upperBound, referenceWeight, false);

        // Finally, insert these computed adjusted bounds, and return the complete set of fields.
        return
            circuitBreakerState
                .insertUint(
                adjustedLowerBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_LOWER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            )
                .insertUint(
                adjustedUpperBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_UPPER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            );
    }

    /**
     * @notice Update the cached adjusted bounds, given a new weight.
     * @dev This might be used when weights are adjusted, pre-emptively updating the cache to improve performance
     * of operations after the weight change completes. Note that this does not update the BPT price: this is still
     * relative to the last call to `setCircuitBreaker`. The intent is only to optimize the automatic bounds
     * adjustments due to changing weights.
     */
    function updateAdjustedBounds(bytes32 circuitBreakerState, uint256 newReferenceWeight)
        internal
        pure
        returns (bytes32)
    {
        uint256 adjustedLowerBound = CircuitBreakerLib.calcAdjustedBound(
            circuitBreakerState.decodeUint(_LOWER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS,
            newReferenceWeight,
            true
        );
        uint256 adjustedUpperBound = CircuitBreakerLib.calcAdjustedBound(
            circuitBreakerState.decodeUint(_UPPER_BOUND_OFFSET, _BOUND_WIDTH) << _BOUND_SHIFT_BITS,
            newReferenceWeight,
            false
        );

        // Replace the reference weight.
        bytes32 result = circuitBreakerState.insertUint(
            newReferenceWeight,
            _REFERENCE_WEIGHT_OFFSET,
            _REFERENCE_WEIGHT_WIDTH
        );

        // Update the cached adjusted bounds.
        return
            result
                .insertUint(
                adjustedLowerBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_LOWER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            )
                .insertUint(
                adjustedUpperBound.compress(_ADJUSTED_BOUND_WIDTH, _MAX_BOUND_PERCENTAGE),
                _ADJUSTED_UPPER_BOUND_OFFSET,
                _ADJUSTED_BOUND_WIDTH
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;

import "@balancer-labs/v2-interfaces/contracts/pool-weighted/IExternalWeightedMath.sol";
import "@balancer-labs/v2-interfaces/contracts/pool-weighted/WeightedPoolUserData.sol";

import "@balancer-labs/v2-pool-utils/contracts/lib/ComposablePoolLib.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/Authentication.sol";

import "../managed/CircuitBreakerStorageLib.sol";
import "./ManagedPoolTokenStorageLib.sol";
import "./ManagedPoolStorageLib.sol";

library ManagedPoolAmmLib {
    using FixedPoint for uint256;
    using WeightedPoolUserData for bytes;

    enum BoundCheckKind { LOWER, UPPER, BOTH }

    function joinPool(
        uint256[] memory balances,
        bytes memory userData,
        uint256 actualSupply,
        uint256[] memory scalingFactors,
        uint256[] memory normalizedWeights,
        bytes32 poolState,
        bytes32[] memory circuitBreakerStates,
        IExternalWeightedMath weightedMath
    ) external view returns (uint256 bptAmountOut, uint256[] memory amountsIn) {
        _upscaleArray(balances, scalingFactors);

        (bptAmountOut, amountsIn) = _doJoin(
            balances,
            normalizedWeights,
            scalingFactors,
            actualSupply,
            userData,
            poolState,
            weightedMath
        );

        checkCircuitBreakers(
            actualSupply.add(bptAmountOut),
            circuitBreakerStates,
            balances,
            amountsIn,
            normalizedWeights,
            true
        );

        // amountsIn are amounts entering the Pool, so we round up.
        _downscaleUpArray(amountsIn, scalingFactors);

        // The Vault expects an array of amounts which includes BPT so prepend an empty element to this array.
        amountsIn = ComposablePoolLib.prependZeroElement(amountsIn);
    }

    /**
     * @dev Dispatch code which decodes the provided userdata to perform the specified join type.
     */
    function _doJoin(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        bytes memory userData,
        bytes32 poolState,
        IExternalWeightedMath weightedMath
    ) private view returns (uint256, uint256[] memory) {
        // Check whether joins are enabled.
        _require(ManagedPoolStorageLib.getJoinExitEnabled(poolState), Errors.JOINS_EXITS_DISABLED);

        WeightedPoolUserData.JoinKind kind = userData.joinKind();

        // If swaps are disabled, only proportional joins are allowed. All others involve implicit swaps, and alter
        // token prices.
        _require(
            ManagedPoolStorageLib.getSwapEnabled(poolState) ||
                kind == WeightedPoolUserData.JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT,
            Errors.INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED
        );

        if (kind == WeightedPoolUserData.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT) {
            return
                weightedMath.joinExactTokensInForBPTOut(
                    balances,
                    normalizedWeights,
                    scalingFactors,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else if (kind == WeightedPoolUserData.JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT) {
            return
                weightedMath.joinTokenInForExactBPTOut(
                    balances,
                    normalizedWeights,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else if (kind == WeightedPoolUserData.JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT) {
            return weightedMath.joinAllTokensInForExactBPTOut(balances, totalSupply, userData);
        } else {
            _revert(Errors.UNHANDLED_JOIN_KIND);
        }
    }

    function exitPool(
        uint256[] memory balances,
        bytes memory userData,
        uint256 actualSupply,
        uint256[] memory scalingFactors,
        uint256[] memory normalizedWeights,
        bytes32 poolState,
        bytes32[] memory circuitBreakerStates,
        IExternalWeightedMath weightedMath
    ) external view returns (uint256 bptAmountIn, uint256[] memory amountsOut) {
        _upscaleArray(balances, scalingFactors);

        (bptAmountIn, amountsOut) = _doExit(
            balances,
            normalizedWeights,
            scalingFactors,
            actualSupply,
            userData,
            poolState,
            weightedMath
        );

        // Do not check circuit breakers on proportional exits, which do not change BPT prices.
        if (userData.exitKind() != WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            checkCircuitBreakers(
                actualSupply.sub(bptAmountIn),
                circuitBreakerStates,
                balances,
                amountsOut,
                normalizedWeights,
                false
            );
        }

        // amountsOut are amounts exiting the Pool, so we round down.
        _downscaleDownArray(amountsOut, scalingFactors);

        // The Vault expects an array of amounts which includes BPT so prepend an empty element to this array.
        amountsOut = ComposablePoolLib.prependZeroElement(amountsOut);
    }

    function _doExit(
        uint256[] memory balances,
        uint256[] memory normalizedWeights,
        uint256[] memory scalingFactors,
        uint256 totalSupply,
        bytes memory userData,
        bytes32 poolState,
        IExternalWeightedMath weightedMath
    ) private view returns (uint256, uint256[] memory) {
        // Check whether exits are enabled. Recovery mode exits are not blocked by this check, since they are routed
        // through a different codepath at the base pool layer.
        _require(ManagedPoolStorageLib.getJoinExitEnabled(poolState), Errors.JOINS_EXITS_DISABLED);

        WeightedPoolUserData.ExitKind kind = userData.exitKind();

        // If swaps are disabled, only proportional exits are allowed. All others involve implicit swaps, and alter
        // token prices.
        _require(
            ManagedPoolStorageLib.getSwapEnabled(poolState) ||
                kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
            Errors.INVALID_JOIN_EXIT_KIND_WHILE_SWAPS_DISABLED
        );

        // Note that we do not check the LP allowlist here. LPs must always be able to exit the pool,
        // and enforcing the allowlist would allow the manager to perform DOS attacks on LPs.

        if (kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT) {
            return
                weightedMath.exitExactBPTInForTokenOut(
                    balances,
                    normalizedWeights,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else if (kind == WeightedPoolUserData.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT) {
            return weightedMath.exitExactBPTInForTokensOut(balances, totalSupply, userData);
        } else if (kind == WeightedPoolUserData.ExitKind.BPT_IN_FOR_EXACT_TOKENS_OUT) {
            return
                weightedMath.exitBPTInForExactTokensOut(
                    balances,
                    normalizedWeights,
                    scalingFactors,
                    totalSupply,
                    ManagedPoolStorageLib.getSwapFeePercentage(poolState),
                    userData
                );
        } else {
            _revert(Errors.UNHANDLED_EXIT_KIND);
        }
    }

    /**
     * @dev Check circuit breakers for a set of tokens. The given virtual supply is what it will be post-operation:
     * this includes any pending external fees, and the amount of BPT exchanged (swapped, minted, or burned) in the
     * current operation.
     *
     * We pass in the tokens, upscaled balances, and weights necessary to compute BPT prices, then check the circuit
     * breakers. Unlike a straightforward token swap, where we know the direction the BPT price will move, once the
     * virtual supply changes, all bets are off. To be safe, we need to check both directions for all tokens.
     *
     * It does attempt to short circuit quickly if there is no bound set.
     */
    function checkCircuitBreakers(
        uint256 actualSupply,
        bytes32[] memory circuitBreakerStates,
        uint256[] memory balances,
        uint256[] memory amounts,
        uint256[] memory normalizedWeights,
        bool isJoin
    ) public pure {
        for (uint256 i = 0; i < balances.length; i++) {
            uint256 finalBalance = (isJoin ? FixedPoint.add : FixedPoint.sub)(balances[i], amounts[i]);

            // Since we cannot be sure which direction the BPT price of the token has moved,
            // we must check both the lower and upper bounds.
            checkCircuitBreaker(
                BoundCheckKind.BOTH,
                circuitBreakerStates[i],
                actualSupply,
                finalBalance,
                normalizedWeights[i]
            );
        }
    }

    // Check the appropriate circuit breaker(s) according to the BoundCheckKind.
    function checkCircuitBreaker(
        BoundCheckKind checkKind,
        bytes32 circuitBreakerState,
        uint256 actualSupply,
        uint256 balance,
        uint256 weight
    ) public pure {
        if (checkKind == BoundCheckKind.LOWER || checkKind == BoundCheckKind.BOTH) {
            checkOneSidedCircuitBreaker(circuitBreakerState, actualSupply, balance, weight, true);
        }

        if (checkKind == BoundCheckKind.UPPER || checkKind == BoundCheckKind.BOTH) {
            checkOneSidedCircuitBreaker(circuitBreakerState, actualSupply, balance, weight, false);
        }
    }

    // Check either the lower or upper bound circuit breaker for the given token.
    function checkOneSidedCircuitBreaker(
        bytes32 circuitBreakerState,
        uint256 actualSupply,
        uint256 balance,
        uint256 weight,
        bool isLowerBound
    ) public pure {
        uint256 bound = CircuitBreakerStorageLib.getBptPriceBound(circuitBreakerState, weight, isLowerBound);

        _require(
            !CircuitBreakerLib.hasCircuitBreakerTripped(actualSupply, weight, balance, bound, isLowerBound),
            Errors.CIRCUIT_BREAKER_TRIPPED
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-solidity-utils/contracts/helpers/WordCodec.sol";

import "../lib/GradualValueChange.sol";

/**
 * @title Managed Pool Storage Library
 * @notice Library for manipulating a bitmap used for commonly used Pool state in ManagedPool.
 */
library ManagedPoolStorageLib {
    using WordCodec for bytes32;

    /* solhint-disable max-line-length */
    // Store non-token-based values:
    // Start/end timestamps for gradual weight and swap fee updates
    // Start/end values of the swap fee
    // Flags for the LP allowlist, enabling/disabling trading, enabling/disabling joins and exits, and recovery mode
    //
    // [     1 bit      |   1 bit  |  1 bit  |   1 bit   |    62 bits   |     62 bits    |    32 bits   |     32 bits    | 32 bits |  32 bits  ]
    // [ join-exit flag | recovery | LP flag | swap flag | end swap fee | start swap fee | end fee time | start fee time | end wgt | start wgt ]
    // |MSB                                                                                                                                 LSB|
    /* solhint-enable max-line-length */
    uint256 private constant _WEIGHT_START_TIME_OFFSET = 0;
    uint256 private constant _WEIGHT_END_TIME_OFFSET = _WEIGHT_START_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_START_TIME_OFFSET = _WEIGHT_END_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_END_TIME_OFFSET = _SWAP_FEE_START_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_START_PCT_OFFSET = _SWAP_FEE_END_TIME_OFFSET + _TIMESTAMP_WIDTH;
    uint256 private constant _SWAP_FEE_END_PCT_OFFSET = _SWAP_FEE_START_PCT_OFFSET + _SWAP_FEE_PCT_WIDTH;
    uint256 private constant _SWAP_ENABLED_OFFSET = _SWAP_FEE_END_PCT_OFFSET + _SWAP_FEE_PCT_WIDTH;
    uint256 private constant _MUST_ALLOWLIST_LPS_OFFSET = _SWAP_ENABLED_OFFSET + 1;
    uint256 private constant _RECOVERY_MODE_OFFSET = _MUST_ALLOWLIST_LPS_OFFSET + 1;
    uint256 private constant _JOIN_EXIT_ENABLED_OFFSET = _RECOVERY_MODE_OFFSET + 1;

    uint256 private constant _TIMESTAMP_WIDTH = 32;
    // 2**60 ~= 1.1e18 so this is sufficient to store the full range of potential swap fees.
    uint256 private constant _SWAP_FEE_PCT_WIDTH = 62;

    // Getters

    /**
     * @notice Returns whether the Pool allows regular joins and exits (recovery exits not included).
     * @param poolState - The byte32 state of the Pool.
     */
    function getJoinExitEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_JOIN_EXIT_ENABLED_OFFSET);
    }

    /**
     * @notice Returns whether the Pool is currently in Recovery Mode.
     * @param poolState - The byte32 state of the Pool.
     */
    function getRecoveryModeEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_RECOVERY_MODE_OFFSET);
    }

    /**
     * @notice Returns whether the Pool currently allows swaps (and by extension, non-proportional joins/exits).
     * @param poolState - The byte32 state of the Pool.
     */
    function getSwapEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_SWAP_ENABLED_OFFSET);
    }

    /**
     * @notice Returns whether addresses must be allowlisted to add liquidity to the Pool.
     * @param poolState - The byte32 state of the Pool.
     */
    function getLPAllowlistEnabled(bytes32 poolState) internal pure returns (bool) {
        return poolState.decodeBool(_MUST_ALLOWLIST_LPS_OFFSET);
    }

    /**
     * @notice Returns the percentage progress through the current gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @return pctProgress - A 18 decimal fixed-point value corresponding to how far to interpolate between the start
     * and end weights. 0 represents the start weight and 1 represents the end weight (with values >1 being clipped).
     */
    function getGradualWeightChangeProgress(bytes32 poolState) internal view returns (uint256) {
        (uint256 startTime, uint256 endTime) = getWeightChangeFields(poolState);

        return GradualValueChange.calculateValueChangeProgress(startTime, endTime);
    }

    /**
     * @notice Returns the start and end timestamps of the current gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @param startTime - The timestamp at which the current gradual weight change started/will start.
     * @param endTime - The timestamp at which the current gradual weight change finished/will finish.
     */
    function getWeightChangeFields(bytes32 poolState) internal pure returns (uint256 startTime, uint256 endTime) {
        startTime = poolState.decodeUint(_WEIGHT_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        endTime = poolState.decodeUint(_WEIGHT_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
    }

    /**
     * @notice Returns the current value of the swap fee percentage.
     * @dev Computes the current swap fee percentage, which can change every block if a gradual swap fee
     * update is in progress.
     * @param poolState - The byte32 state of the Pool.
     */
    function getSwapFeePercentage(bytes32 poolState) internal view returns (uint256) {
        (
            uint256 startTime,
            uint256 endTime,
            uint256 startSwapFeePercentage,
            uint256 endSwapFeePercentage
        ) = getSwapFeeFields(poolState);

        return
            GradualValueChange.getInterpolatedValue(startSwapFeePercentage, endSwapFeePercentage, startTime, endTime);
    }

    /**
     * @notice Returns the start and end timestamps of the current gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @return startTime - The timestamp at which the current gradual swap fee change started/will start.
     * @return endTime - The timestamp at which the current gradual swap fee change finished/will finish.
     * @return startSwapFeePercentage - The swap fee value at the start of the current gradual swap fee change.
     * @return endSwapFeePercentage - The swap fee value at the end of the current gradual swap fee change.
     */
    function getSwapFeeFields(bytes32 poolState)
        internal
        pure
        returns (
            uint256 startTime,
            uint256 endTime,
            uint256 startSwapFeePercentage,
            uint256 endSwapFeePercentage
        )
    {
        startTime = poolState.decodeUint(_SWAP_FEE_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        endTime = poolState.decodeUint(_SWAP_FEE_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
        startSwapFeePercentage = poolState.decodeUint(_SWAP_FEE_START_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
        endSwapFeePercentage = poolState.decodeUint(_SWAP_FEE_END_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
    }

    // Setters

    /**
     * @notice Sets the "Joins/Exits enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether Joins and Exits are to be enabled.
     */
    function setJoinExitEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _JOIN_EXIT_ENABLED_OFFSET);
    }

    /**
     * @notice Sets the "Recovery Mode enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether Recovery Mode is to be enabled.
     */
    function setRecoveryModeEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _RECOVERY_MODE_OFFSET);
    }

    /**
     * @notice Sets the "swaps enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether swaps are to be enabled.
     */
    function setSwapEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _SWAP_ENABLED_OFFSET);
    }

    /**
     * @notice Sets the "LP allowlist enabled" flag to `enabled`.
     * @param poolState - The byte32 state of the Pool.
     * @param enabled - A boolean flag for whether the LP allowlist is to be enforced.
     */
    function setLPAllowlistEnabled(bytes32 poolState, bool enabled) internal pure returns (bytes32) {
        return poolState.insertBool(enabled, _MUST_ALLOWLIST_LPS_OFFSET);
    }

    /**
     * @notice Sets the start and end times of a gradual weight change.
     * @param poolState - The byte32 state of the Pool.
     * @param startTime - The timestamp at which the gradual weight change is to start.
     * @param endTime - The timestamp at which the gradual weight change is to finish.
     */
    function setWeightChangeData(
        bytes32 poolState,
        uint256 startTime,
        uint256 endTime
    ) internal pure returns (bytes32) {
        poolState = poolState.insertUint(startTime, _WEIGHT_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        return poolState.insertUint(endTime, _WEIGHT_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
    }

    /**
     * @notice Sets the start and end times of a gradual swap fee change.
     * @param poolState - The byte32 state of the Pool.
     * @param startTime - The timestamp at which the gradual swap fee change is to start.
     * @param endTime - The timestamp at which the gradual swap fee change is to finish.
     * @param startSwapFeePercentage - The desired swap fee value at the start of the gradual swap fee change.
     * @param endSwapFeePercentage - The desired swap fee value at the end of the gradual swap fee change.
     */
    function setSwapFeeData(
        bytes32 poolState,
        uint256 startTime,
        uint256 endTime,
        uint256 startSwapFeePercentage,
        uint256 endSwapFeePercentage
    ) internal pure returns (bytes32) {
        poolState = poolState.insertUint(startTime, _SWAP_FEE_START_TIME_OFFSET, _TIMESTAMP_WIDTH);
        poolState = poolState.insertUint(endTime, _SWAP_FEE_END_TIME_OFFSET, _TIMESTAMP_WIDTH);
        poolState = poolState.insertUint(startSwapFeePercentage, _SWAP_FEE_START_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
        return poolState.insertUint(endSwapFeePercentage, _SWAP_FEE_END_PCT_OFFSET, _SWAP_FEE_PCT_WIDTH);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/openzeppelin/IERC20.sol";
import "@balancer-labs/v2-solidity-utils/contracts/helpers/WordCodec.sol";
import "@balancer-labs/v2-solidity-utils/contracts/openzeppelin/ERC20.sol";

import "../lib/GradualValueChange.sol";

/**
 * @title Managed Pool Token Library
 * @notice Library for manipulating bitmaps used for storing token-related state in ManagedPool.
 * @dev
 *
 * This library stores all token weights in a normalized format, meaning they add up to 100% (1.0 in 18 decimal fixed
 * point format).
 */
library ManagedPoolTokenStorageLib {
    using WordCodec for bytes32;
    using FixedPoint for uint256;

    // Store token-based values:
    // Each token's scaling factor (encoded as the scaling factor's exponent / token decimals).
    // Each token's starting and ending normalized weights.
    // [ 123 bits |  5 bits  |     64 bits     |     64 bits       |
    // [  unused  | decimals | end norm weight | start norm weight |
    // |MSB                                                     LSB|
    uint256 private constant _START_NORM_WEIGHT_OFFSET = 0;
    uint256 private constant _END_NORM_WEIGHT_OFFSET = _START_NORM_WEIGHT_OFFSET + _NORM_WEIGHT_WIDTH;
    uint256 private constant _DECIMAL_DIFF_OFFSET = _END_NORM_WEIGHT_OFFSET + _NORM_WEIGHT_WIDTH;

    uint256 private constant _NORM_WEIGHT_WIDTH = 64;
    uint256 private constant _DECIMAL_DIFF_WIDTH = 5;

    // Getters

    /**
     * @notice Returns the token's scaling factor.
     * @param tokenState - The byte32 state of the token of interest.
     */
    function getTokenScalingFactor(bytes32 tokenState) internal pure returns (uint256) {
        uint256 decimalsDifference = tokenState.decodeUint(_DECIMAL_DIFF_OFFSET, _DECIMAL_DIFF_WIDTH);

        // This is equivalent to `10**(18+decimalsDifference)` but this form optimizes for 18 decimal tokens.
        return FixedPoint.ONE * 10**decimalsDifference;
    }

    /**
     * @notice Returns the token weight, interpolated between the starting and ending weights.
     * @param tokenState - The byte32 state of the token of interest.
     * @param pctProgress - A 18 decimal fixed-point value corresponding to how far to interpolate between the start
     * and end weights. 0 represents the start weight and 1 represents the end weight (with values >1 being clipped).
     */
    function getTokenWeight(bytes32 tokenState, uint256 pctProgress) internal pure returns (uint256) {
        return
            GradualValueChange.interpolateValue(
                tokenState.decodeUint(_START_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH),
                tokenState.decodeUint(_END_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH),
                pctProgress
            );
    }

    /**
     * @notice Returns the token's starting and ending weights.
     * @param tokenState - The byte32 state of the token of interest.
     * @return normalizedStartWeight - The starting normalized weight of the token.
     * @return normalizedEndWeight - The ending normalized weight of the token.
     */
    function getTokenStartAndEndWeights(bytes32 tokenState)
        internal
        pure
        returns (uint256 normalizedStartWeight, uint256 normalizedEndWeight)
    {
        normalizedStartWeight = tokenState.decodeUint(_START_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH);
        normalizedEndWeight = tokenState.decodeUint(_END_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH);
    }

    // Setters

    /**
     * @notice Updates a token's starting and ending weights.
     * @dev Initiate a gradual weight change between the given starting and ending values.
     * @param tokenState - The byte32 state of the token of interest.
     * @param normalizedStartWeight - The current normalized weight of the token.
     * @param normalizedEndWeight - The desired final normalized weight of the token.
     */
    function setTokenWeight(
        bytes32 tokenState,
        uint256 normalizedStartWeight,
        uint256 normalizedEndWeight
    ) internal pure returns (bytes32) {
        return
            tokenState.insertUint(normalizedStartWeight, _START_NORM_WEIGHT_OFFSET, _NORM_WEIGHT_WIDTH).insertUint(
                normalizedEndWeight,
                _END_NORM_WEIGHT_OFFSET,
                _NORM_WEIGHT_WIDTH
            );
    }

    /**
     * @notice Writes the token's scaling factor into the token state.
     * @dev To save space, we store the scaling factor as the difference between 18 and the token's decimals,
     * and compute the "raw" scaling factor on the fly.
     * We segregated this function to avoid unnecessary external calls. Token decimals do not change, so we
     * only need to call this once per token: either from the constructor, for the initial set of tokens, or
     * when adding a new token.
     * @param tokenState - The byte32 state of the token of interest.
     * @param token - The ERC20 token of interest.
     */
    function setTokenScalingFactor(bytes32 tokenState, IERC20 token) internal view returns (bytes32) {
        // Tokens that don't implement the `decimals` method are not supported.
        // Tokens with more than 18 decimals are not supported
        return
            tokenState.insertUint(
                uint256(18).sub(ERC20(address(token)).decimals()),
                _DECIMAL_DIFF_OFFSET,
                _DECIMAL_DIFF_WIDTH
            );
    }

    /**
     * @notice Initializes the token state for a new token.
     * @dev Since weights must be fixed during add/remove operations, we only need to supply a single normalized weight.
     * @param token - The ERC20 token of interest.
     * @param normalizedWeight - The normalized weight of the token.
     */
    function initializeTokenState(IERC20 token, uint256 normalizedWeight) internal view returns (bytes32 tokenState) {
        tokenState = setTokenScalingFactor(bytes32(0), token);
        tokenState = setTokenWeight(tokenState, normalizedWeight, normalizedWeight);
    }
}