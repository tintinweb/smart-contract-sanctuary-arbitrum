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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
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

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

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

pragma solidity 0.8.12;

contract BConst {
	uint public constant BONE = 10 ** 18;

	uint public constant MIN_BOUND_TOKENS = 2;
	uint public constant MAX_BOUND_TOKENS = 8;

	uint public constant MIN_FEE = BONE / 10 ** 6;
	uint public constant MAX_FEE = BONE / 10;
	uint public constant EXIT_FEE = 0;

	uint public constant MIN_WEIGHT = BONE;
	uint public constant MAX_WEIGHT = BONE * 50;
	uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
	uint public constant MIN_BALANCE = BONE / 10 ** 12;

	uint public constant INIT_POOL_SUPPLY = BONE * 100;

	uint public constant MIN_BPOW_BASE = 1 wei;
	uint public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
	uint public constant BPOW_PRECISION = BONE / 10 ** 10;

	uint public constant MAX_IN_RATIO = BONE / 2;
	uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

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

pragma solidity 0.8.12;

import "./BConst.sol";

contract BNum is BConst {
	function btoi(uint a) internal pure returns (uint) {
		return a / BONE;
	}

	function bfloor(uint a) internal pure returns (uint) {
		return btoi(a) * BONE;
	}

	function badd(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		require(c >= a, "ERR_ADD_OVERFLOW");
		return c;
	}

	function bsub(uint a, uint b) internal pure returns (uint) {
		(uint c, bool flag) = bsubSign(a, b);
		require(!flag, "ERR_SUB_UNDERFLOW");
		return c;
	}

	function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
		if (a >= b) {
			return (a - b, false);
		} else {
			return (b - a, true);
		}
	}

	function bmul(uint a, uint b) internal pure returns (uint) {
		uint c0 = a * b;
		require(a == 0 || c0 / a == b, "ERR_MUL_OVERFLOW");
		uint c1 = c0 + (BONE / 2);
		require(c1 >= c0, "ERR_MUL_OVERFLOW");
		uint c2 = c1 / BONE;
		return c2;
	}

	function bdiv(uint a, uint b) internal pure returns (uint) {
		require(b != 0, "ERR_DIV_ZERO");
		uint c0 = a * BONE;
		require(a == 0 || c0 / a == BONE, "ERR_DIV_INTERNAL"); // bmul overflow
		uint c1 = c0 + (b / 2);
		require(c1 >= c0, "ERR_DIV_INTERNAL"); //  badd require
		uint c2 = c1 / b;
		return c2;
	}

	// DSMath.wpow
	function bpowi(uint a, uint n) internal pure returns (uint) {
		uint z = n % 2 != 0 ? a : BONE;

		for (n /= 2; n != 0; n /= 2) {
			a = bmul(a, a);

			if (n % 2 != 0) {
				z = bmul(z, a);
			}
		}
		return z;
	}

	// Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
	// Use `bpowi` for `b^e` and `bpowK` for k iterations
	// of approximation of b^0.w
	function bpow(uint base, uint exp) internal pure returns (uint) {
		require(base >= MIN_BPOW_BASE, "ERR_BPOW_BASE_TOO_LOW");
		require(base <= MAX_BPOW_BASE, "ERR_BPOW_BASE_TOO_HIGH");

		uint whole = bfloor(exp);
		uint remain = bsub(exp, whole);

		uint wholePow = bpowi(base, btoi(whole));

		if (remain == 0) {
			return wholePow;
		}

		uint partialResult = bpowApprox(base, remain, BPOW_PRECISION);
		return bmul(wholePow, partialResult);
	}

	function bpowApprox(uint base, uint exp, uint precision) internal pure returns (uint) {
		// term 0:
		uint a = exp;
		(uint x, bool xneg) = bsubSign(base, BONE);
		uint term = BONE;
		uint sum = term;
		bool negative = false;

		// term(k) = numer / denom
		//         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
		// each iteration, multiply previous term by (a-(k-1)) * x / k
		// continue until term is less than precision
		for (uint i = 1; term >= precision; i++) {
			uint bigK = i * BONE;
			(uint c, bool cneg) = bsubSign(a, bsub(bigK, BONE));
			term = bmul(term, bmul(c, x));
			term = bdiv(term, bigK);
			if (term == 0) break;

			if (xneg) negative = !negative;
			if (cneg) negative = !negative;
			if (negative) {
				sum = bsub(sum, term);
			} else {
				sum = badd(sum, term);
			}
		}

		return sum;
	}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";

contract ContextUpgradeable is Initializable {
	function __Context_init() internal onlyInitializing {}

	function __Context_init_unchained() internal onlyInitializing {}

	function _msgSender() internal view virtual returns (address payable) {
		return payable(msg.sender);
	}

	function _msgData() internal view virtual returns (bytes memory) {
		this;
		return msg.data;
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
	/**
	 * @dev Indicates that the contract has been initialized.
	 */
	bool private initialized;

	/**
	 * @dev Indicates that the contract is in the process of being initialized.
	 */
	bool private initializing;

	/**
	 * @dev Modifier to use in the initializer function of a contract.
	 */
	modifier initializer() {
		require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

		bool isTopLevelCall = !initializing;
		if (isTopLevelCall) {
			initializing = true;
			initialized = true;
		}

		_;

		if (isTopLevelCall) {
			initializing = false;
		}
	}

	/// @dev Returns true if and only if the function is running in the constructor
	function isConstructor() private view returns (bool) {
		// extcodesize checks the size of the code stored in an address, and
		// address returns the current address. Since the code is still not
		// deployed when running a constructor, any checks on its code size will
		// yield zero, making it an effective way to detect if a contract is
		// under construction or not.
		uint256 cs;
		//solium-disable-next-line
		assembly {
			cs := extcodesize(address())
		}
		return cs == 0;
	}

	modifier onlyInitializing() {
		require(initializing, "Initializable: contract is not initializing");
		_;
	}

	// Reserved storage space to allow for layout changes in the future.
	uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "./Initializable.sol";
import "./ContextUpgradeable.sol";

contract OwnableUpgradeable is Initializable, ContextUpgradeable {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	function __Ownable_init() internal onlyInitializing {
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal onlyInitializing {
		_transferOwnership(_msgSender());
	}

	function owner() public view virtual returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}

	function renounceOwnership() public virtual onlyOwner {
		_transferOwnership(address(0));
	}

	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");
		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}

	uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolHelper {
	function lpTokenAddr() external view returns (address);

	function zapWETH(uint256 amount) external returns (uint256);

	function zapTokens(uint256 _wethAmt, uint256 _rdntAmt) external returns (uint256);

	function quoteFromToken(uint256 tokenAmount) external view returns (uint256 optimalWETHAmount);

	function quoteWETH(uint256 lpAmount) external view returns (uint256 wethAmount);

	function getLpPrice(uint256 rdntPriceInEth) external view returns (uint256 priceInEth);

	function getReserves() external view returns (uint256 rdnt, uint256 weth, uint256 lpTokenSupply);

	function getPrice() external view returns (uint256 priceInEth);

	function quoteSwap(address _inToken, uint256 _wethAmount) external view returns (uint256 tokenAmount);

	function swapToWeth(address _inToken, uint256 _amount, uint256 _minAmountOut) external;
}

interface IBalancerPoolHelper is IPoolHelper {
	function initializePool(string calldata _tokenName, string calldata _tokenSymbol) external;
}

interface IUniswapPoolHelper is IPoolHelper {
	function initializePool() external;
}

interface ITestPoolHelper is IPoolHelper {
	function sell(uint256 _amount) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

interface IWETH {
	function balanceOf(address) external returns (uint256);

	function deposit() external payable;

	function withdraw(uint256) external;

	function approve(address guy, uint256 wad) external returns (bool);

	function transferFrom(address src, address dst, uint256 wad) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function allowance(address owner, address spender) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasePool is IERC20 {
	function getSwapFeePercentage() external view returns (uint256);

	function setSwapFeePercentage(uint256 swapFeePercentage) external;

	function setAssetManagerPoolConfig(IERC20 token, IAssetManager.PoolConfig memory poolConfig) external;

	function setPaused(bool paused) external;

	function getVault() external view returns (IVault);

	function getPoolId() external view returns (bytes32);

	function getOwner() external view returns (address);
}

interface IWeightedPoolFactory {
	function create(
		string memory name,
		string memory symbol,
		IERC20[] memory tokens,
		uint256[] memory weights,
		address[] memory rateProviders,
		uint256 swapFeePercentage,
		address owner
	) external returns (address);
}

interface IWeightedPool is IBasePool {
	function getSwapEnabled() external view returns (bool);

	function getNormalizedWeights() external view returns (uint256[] memory);

	function getGradualWeightUpdateParams()
		external
		view
		returns (uint256 startTime, uint256 endTime, uint256[] memory endWeights);

	function setSwapEnabled(bool swapEnabled) external;

	function updateWeightsGradually(uint256 startTime, uint256 endTime, uint256[] memory endWeights) external;

	function withdrawCollectedManagementFees(address recipient) external;

	enum JoinKind {
		INIT,
		EXACT_TOKENS_IN_FOR_BPT_OUT,
		TOKEN_IN_FOR_EXACT_BPT_OUT
	}
	enum ExitKind {
		EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
		EXACT_BPT_IN_FOR_TOKENS_OUT,
		BPT_IN_FOR_EXACT_TOKENS_OUT
	}
}

interface IAssetManager {
	struct PoolConfig {
		uint64 targetPercentage;
		uint64 criticalPercentage;
		uint64 feePercentage;
	}

	function setPoolConfig(bytes32 poolId, PoolConfig calldata config) external;
}

interface IAsset {}

interface IVault {
	function hasApprovedRelayer(address user, address relayer) external view returns (bool);

	function setRelayerApproval(address sender, address relayer, bool approved) external;

	event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

	function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

	function manageUserBalance(UserBalanceOp[] memory ops) external payable;

	struct UserBalanceOp {
		UserBalanceOpKind kind;
		IAsset asset;
		uint256 amount;
		address sender;
		address payable recipient;
	}

	enum UserBalanceOpKind {
		DEPOSIT_INTERNAL,
		WITHDRAW_INTERNAL,
		TRANSFER_INTERNAL,
		TRANSFER_EXTERNAL
	}
	event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);
	event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

	enum PoolSpecialization {
		GENERAL,
		MINIMAL_SWAP_INFO,
		TWO_TOKEN
	}

	function registerPool(PoolSpecialization specialization) external returns (bytes32);

	event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

	function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

	function registerTokens(bytes32 poolId, IERC20[] memory tokens, address[] memory assetManagers) external;

	event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

	function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

	event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

	function getPoolTokenInfo(
		bytes32 poolId,
		IERC20 token
	) external view returns (uint256 cash, uint256 managed, uint256 lastChangeBlock, address assetManager);

	function getPoolTokens(
		bytes32 poolId
	) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

	function joinPool(
		bytes32 poolId,
		address sender,
		address recipient,
		JoinPoolRequest memory request
	) external payable;

	struct JoinPoolRequest {
		IAsset[] assets;
		uint256[] maxAmountsIn;
		bytes userData;
		bool fromInternalBalance;
	}

	function exitPool(
		bytes32 poolId,
		address sender,
		address payable recipient,
		ExitPoolRequest memory request
	) external;

	struct ExitPoolRequest {
		IAsset[] assets;
		uint256[] minAmountsOut;
		bytes userData;
		bool toInternalBalance;
	}

	event PoolBalanceChanged(
		bytes32 indexed poolId,
		address indexed liquidityProvider,
		IERC20[] tokens,
		int256[] deltas,
		uint256[] protocolFeeAmounts
	);

	enum PoolBalanceChangeKind {
		JOIN,
		EXIT
	}

	enum SwapKind {
		GIVEN_IN,
		GIVEN_OUT
	}

	function swap(
		SingleSwap memory singleSwap,
		FundManagement memory funds,
		uint256 limit,
		uint256 deadline
	) external payable returns (uint256);

	struct SingleSwap {
		bytes32 poolId;
		SwapKind kind;
		IAsset assetIn;
		IAsset assetOut;
		uint256 amount;
		bytes userData;
	}

	function batchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds,
		int256[] memory limits,
		uint256 deadline
	) external payable returns (int256[] memory);

	struct BatchSwapStep {
		bytes32 poolId;
		uint256 assetInIndex;
		uint256 assetOutIndex;
		uint256 amount;
		bytes userData;
	}

	event Swap(
		bytes32 indexed poolId,
		IERC20 indexed tokenIn,
		IERC20 indexed tokenOut,
		uint256 amountIn,
		uint256 amountOut
	);
	struct FundManagement {
		address sender;
		bool fromInternalBalance;
		address payable recipient;
		bool toInternalBalance;
	}

	function queryBatchSwap(
		SwapKind kind,
		BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		FundManagement memory funds
	) external returns (int256[] memory assetDeltas);

	function managePoolBalance(PoolBalanceOp[] memory ops) external;

	struct PoolBalanceOp {
		PoolBalanceOpKind kind;
		bytes32 poolId;
		IERC20 token;
		uint256 amount;
	}

	enum PoolBalanceOpKind {
		WITHDRAW,
		DEPOSIT,
		UPDATE
	}
	event PoolBalanceManaged(
		bytes32 indexed poolId,
		address indexed assetManager,
		IERC20 indexed token,
		int256 cashDelta,
		int256 managedDelta
	);

	function setPaused(bool paused) external;
}

interface IBalancerQueries {
	function querySwap(
		IVault.SingleSwap memory singleSwap,
		IVault.FundManagement memory funds
	) external returns (uint256);

	function queryBatchSwap(
		IVault.SwapKind kind,
		IVault.BatchSwapStep[] memory swaps,
		IAsset[] memory assets,
		IVault.FundManagement memory funds
	) external returns (int256[] memory assetDeltas);

	function queryJoin(
		bytes32 poolId,
		address sender,
		address recipient,
		IVault.JoinPoolRequest memory request
	) external returns (uint256 bptOut, uint256[] memory amountsIn);

	function queryExit(
		bytes32 poolId,
		address sender,
		address recipient,
		IVault.ExitPoolRequest memory request
	) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Modified by Radiant Capital to accommodate different interface files
pragma solidity >=0.7.0 <0.9.0;

import "@balancer-labs/v2-interfaces/contracts/solidity-utils/helpers/BalancerErrors.sol";
import {IVault} from "../../../interfaces/balancer/IWeightedPoolFactory.sol";

library VaultReentrancyLib {
	/**
	 * @dev Ensure we are not in a Vault context when this function is called, by attempting a no-op internal
	 * balance operation. If we are already in a Vault transaction (e.g., a swap, join, or exit), the Vault's
	 * reentrancy protection will cause this function to revert.
	 *
	 * The exact function call doesn't really matter: we're just trying to trigger the Vault reentrancy check
	 * (and not hurt anything in case it works). An empty operation array with no specific operation at all works
	 * for that purpose, and is also the least expensive in terms of gas and bytecode size.
	 *
	 * Call this at the top of any function that can cause a state change in a pool and is either public itself,
	 * or called by a public function *outside* a Vault operation (e.g., join, exit, or swap).
	 *
	 * If this is *not* called in functions that are vulnerable to the read-only reentrancy issue described
	 * here (https://forum.balancer.fi/t/reentrancy-vulnerability-scope-expanded/4345), those functions are unsafe,
	 * and subject to manipulation that may result in loss of funds.
	 */
	function ensureNotInVaultContext(IVault vault) internal view {
		// Perform the following operation to trigger the Vault's reentrancy guard:
		//
		// IVault.UserBalanceOp[] memory noop = new IVault.UserBalanceOp[](0);
		// _vault.manageUserBalance(noop);
		//
		// However, use a static call so that it can be a view function (even though the function is non-view).
		// This allows the library to be used more widely, as some functions that need to be protected might be
		// view.
		//
		// This staticcall always reverts, but we need to make sure it doesn't fail due to a re-entrancy attack.
		// Staticcalls consume all gas forwarded to them on a revert caused by storage modification.
		// By default, almost the entire available gas is forwarded to the staticcall,
		// causing the entire call to revert with an 'out of gas' error.
		//
		// We set the gas limit to 10k for the staticcall to
		// avoid wasting gas when it reverts due to storage modification.
		// `manageUserBalance` is a non-reentrant function in the Vault, so calling it invokes `_enterNonReentrant`
		// in the `ReentrancyGuard` contract, reproduced here:
		//
		//    function _enterNonReentrant() private {
		//        // If the Vault is actually being reentered, it will revert in the first line, at the `_require` that
		//        // checks the reentrancy flag, with "BAL#400" (corresponding to Errors.REENTRANCY) in the revertData.
		//        // The full revertData will be: `abi.encodeWithSignature("Error(string)", "BAL#400")`.
		//        _require(_status != _ENTERED, Errors.REENTRANCY);
		//
		//        // If the Vault is not being reentered, the check above will pass: but it will *still* revert,
		//        // because the next line attempts to modify storage during a staticcall. However, this type of
		//        // failure results in empty revertData.
		//        _status = _ENTERED;
		//    }
		//
		// So based on this analysis, there are only two possible revertData values: empty, or abi.encoded BAL#400.
		//
		// It is of course much more bytecode and gas efficient to check for zero-length revertData than to compare it
		// to the encoded REENTRANCY revertData.
		//
		// While it should be impossible for the call to fail in any other way (especially since it reverts before
		// `manageUserBalance` even gets called), any other error would generate non-zero revertData, so checking for
		// empty data guards against this case too.

		(, bytes memory revertData) = address(vault).staticcall{gas: 10_000}(
			abi.encodeWithSelector(vault.manageUserBalance.selector, 0)
		);

		_require(revertData.length == 0, Errors.REENTRANCY);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {DustRefunder} from "./DustRefunder.sol";
import {BNum} from "../../../dependencies/math/BNum.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "../../../dependencies/openzeppelin/upgradeability/Initializable.sol";
import {OwnableUpgradeable} from "../../../dependencies/openzeppelin/upgradeability/OwnableUpgradeable.sol";

import {IBalancerPoolHelper} from "../../../interfaces/IPoolHelper.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";
import {IWeightedPoolFactory, IWeightedPool, IAsset, IVault, IBalancerQueries} from "../../../interfaces/balancer/IWeightedPoolFactory.sol";
import {VaultReentrancyLib} from "../../libraries/balancer-reentrancy/VaultReentrancyLib.sol";

/// @title Balance Pool Helper Contract
/// @author Radiant
contract BalancerPoolHelper is IBalancerPoolHelper, Initializable, OwnableUpgradeable, BNum, DustRefunder {
	using SafeERC20 for IERC20;

	error AddressZero();
	error PoolExists();
	error InsufficientPermission();
	error IdenticalAddresses();
	error ZeroAmount();
	error QuoteFail();

	address public inTokenAddr;
	address public outTokenAddr;
	address public wethAddr;
	address public lpTokenAddr;
	address public vaultAddr;
	bytes32 public poolId;
	address public lockZap;
	IWeightedPoolFactory public poolFactory;
	uint256 public constant RDNT_WEIGHT = 800000000000000000;
	uint256 public constant WETH_WEIGHT = 200000000000000000;
	uint256 public constant INITIAL_SWAP_FEE_PERCENTAGE = 1000000000000000;

	/// @notice In 80/20 pool, RDNT Weight is 4x of WETH weight
	uint256 public constant POOL_WEIGHT = 4;

	bytes32 public constant WBTC_WETH_USDC_POOL_ID = 0x64541216bafffeec8ea535bb71fbc927831d0595000100000000000000000002;
	bytes32 public constant DAI_USDT_USDC_POOL_ID = 0x1533a3278f3f9141d5f820a184ea4b017fce2382000000000000000000000016;
	address public constant REAL_WETH_ADDR = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

	address public constant BALANCER_QUERIES = 0xE39B5e3B6D74016b2F6A9673D7d7493B6DF549d5;

	address public constant USDT_ADDRESS = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
	address public constant DAI_ADDRESS = address(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
	address public constant USDC_ADDRESS = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

	/**
	 * @notice Initializer
	 * @param _inTokenAddr input token of the pool
	 * @param _outTokenAddr output token of the pool
	 * @param _wethAddr WETH address
	 * @param _vault Balancer Vault
	 * @param _poolFactory Balancer pool factory address
	 */
	function initialize(
		address _inTokenAddr,
		address _outTokenAddr,
		address _wethAddr,
		address _vault,
		IWeightedPoolFactory _poolFactory
	) external initializer {
		if (_inTokenAddr == address(0)) revert AddressZero();
		if (_outTokenAddr == address(0)) revert AddressZero();
		if (_wethAddr == address(0)) revert AddressZero();
		if (_vault == address(0)) revert AddressZero();
		if (address(_poolFactory) == address(0)) revert AddressZero();

		__Ownable_init();
		inTokenAddr = _inTokenAddr;
		outTokenAddr = _outTokenAddr;
		wethAddr = _wethAddr;
		vaultAddr = _vault;
		poolFactory = _poolFactory;
	}

	/**
	 * @notice Initialize a new pool.
	 * @param _tokenName Token name of lp token
	 * @param _tokenSymbol Token symbol of lp token
	 */
	function initializePool(string calldata _tokenName, string calldata _tokenSymbol) public onlyOwner {
		if (lpTokenAddr != address(0)) revert PoolExists();

		(address token0, address token1) = _sortTokens(inTokenAddr, outTokenAddr);

		IERC20[] memory tokens = new IERC20[](2);
		tokens[0] = IERC20(token0);
		tokens[1] = IERC20(token1);

		address[] memory rateProviders = new address[](2);
		rateProviders[0] = 0x0000000000000000000000000000000000000000;
		rateProviders[1] = 0x0000000000000000000000000000000000000000;

		uint256[] memory weights = new uint256[](2);

		if (token0 == outTokenAddr) {
			weights[0] = RDNT_WEIGHT;
			weights[1] = WETH_WEIGHT;
		} else {
			weights[0] = WETH_WEIGHT;
			weights[1] = RDNT_WEIGHT;
		}

		lpTokenAddr = poolFactory.create(
			_tokenName,
			_tokenSymbol,
			tokens,
			weights,
			rateProviders,
			INITIAL_SWAP_FEE_PERCENTAGE,
			address(this)
		);

		poolId = IWeightedPool(lpTokenAddr).getPoolId();

		IERC20 outToken = IERC20(outTokenAddr);
		IERC20 inToken = IERC20(inTokenAddr);
		IERC20 lp = IERC20(lpTokenAddr);
		IERC20 weth = IERC20(wethAddr);

		outToken.forceApprove(vaultAddr, type(uint256).max);
		inToken.forceApprove(vaultAddr, type(uint256).max);
		weth.approve(vaultAddr, type(uint256).max);

		IAsset[] memory assets = new IAsset[](2);
		assets[0] = IAsset(token0);
		assets[1] = IAsset(token1);

		uint256 inTokenAmt = inToken.balanceOf(address(this));
		uint256 outTokenAmt = outToken.balanceOf(address(this));

		uint256[] memory maxAmountsIn = new uint256[](2);
		if (token0 == inTokenAddr) {
			maxAmountsIn[0] = inTokenAmt;
			maxAmountsIn[1] = outTokenAmt;
		} else {
			maxAmountsIn[0] = outTokenAmt;
			maxAmountsIn[1] = inTokenAmt;
		}

		IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(
			assets,
			maxAmountsIn,
			abi.encode(0, maxAmountsIn),
			false
		);
		IVault(vaultAddr).joinPool(poolId, address(this), address(this), inRequest);
		uint256 liquidity = lp.balanceOf(address(this));
		lp.safeTransfer(msg.sender, liquidity);
	}

	/// @dev Return fair reserve amounts given spot reserves, weights, and fair prices.
	/// @param resA Reserve of the first asset
	/// @param resB Reserve of the second asset
	/// @param wA Weight of the first asset
	/// @param wB Weight of the second asset
	/// @param pxA Fair price of the first asset
	/// @param pxB Fair price of the second asset
	function _computeFairReserves(
		uint256 resA,
		uint256 resB,
		uint256 wA,
		uint256 wB,
		uint256 pxA,
		uint256 pxB
	) internal pure returns (uint256 fairResA, uint256 fairResB) {
		// NOTE: wA + wB = 1 (normalize weights)
		// constant product = resA^wA * resB^wB
		// constraints:
		// - fairResA^wA * fairResB^wB = constant product
		// - fairResA * pxA / wA = fairResB * pxB / wB
		// Solving equations:
		// --> fairResA^wA * (fairResA * (pxA * wB) / (wA * pxB))^wB = constant product
		// --> fairResA / r1^wB = constant product
		// --> fairResA = resA^wA * resB^wB * r1^wB
		// --> fairResA = resA * (resB/resA)^wB * r1^wB = resA * (r1/r0)^wB
		uint256 r0 = bdiv(resA, resB);
		uint256 r1 = bdiv(bmul(wA, pxB), bmul(wB, pxA));
		// fairResA = resA * (r1 / r0) ^ wB
		// fairResB = resB * (r0 / r1) ^ wA
		if (r0 > r1) {
			uint256 ratio = bdiv(r1, r0);
			fairResA = bmul(resA, bpow(ratio, wB));
			fairResB = bdiv(resB, bpow(ratio, wA));
		} else {
			uint256 ratio = bdiv(r0, r1);
			fairResA = bdiv(resA, bpow(ratio, wB));
			fairResB = bmul(resB, bpow(ratio, wA));
		}
	}

	/**
	 * @notice Calculates LP price
	 * @dev Return value decimal is 8
	 * @param rdntPriceInEth RDNT price in ETH
	 * @return priceInEth LP price in ETH
	 */
	function getLpPrice(uint256 rdntPriceInEth) public view returns (uint256 priceInEth) {
		IWeightedPool pool = IWeightedPool(lpTokenAddr);
		(address token0, ) = _sortTokens(inTokenAddr, outTokenAddr);
		(uint256 rdntBalance, uint256 wethBalance, ) = getReserves();
		uint256[] memory weights = pool.getNormalizedWeights();

		uint256 rdntWeight;
		uint256 wethWeight;

		if (token0 == outTokenAddr) {
			rdntWeight = weights[0];
			wethWeight = weights[1];
		} else {
			rdntWeight = weights[1];
			wethWeight = weights[0];
		}

		// RDNT in eth, 8 decis
		uint256 pxA = rdntPriceInEth;
		// ETH in eth, 8 decis
		uint256 pxB = 100000000;

		(uint256 fairResA, uint256 fairResB) = _computeFairReserves(
			rdntBalance,
			wethBalance,
			rdntWeight,
			wethWeight,
			pxA,
			pxB
		);
		// use fairReserveA and fairReserveB to compute LP token price
		// LP price = (fairResA * pxA + fairResB * pxB) / totalLPSupply
		priceInEth = (fairResA * pxA + fairResB * pxB) / pool.totalSupply();
	}

	/**
	 * @notice Returns RDNT price in WETH
	 * @return RDNT price
	 */
	function getPrice() public view returns (uint256) {
		address vaultAddress = vaultAddr;
		VaultReentrancyLib.ensureNotInVaultContext(IVault(vaultAddress));
		(IERC20[] memory tokens, uint256[] memory balances, ) = IVault(vaultAddress).getPoolTokens(poolId);
		uint256 rdntBalance = address(tokens[0]) == outTokenAddr ? balances[0] : balances[1];
		uint256 wethBalance = address(tokens[0]) == outTokenAddr ? balances[1] : balances[0];

		return (wethBalance * 1e8) / (rdntBalance / POOL_WEIGHT);
	}

	/**
	 * @notice Returns reserve information.
	 * @return rdnt RDNT amount
	 * @return weth WETH amount
	 * @return lpTokenSupply LP token supply
	 */
	function getReserves() public view returns (uint256 rdnt, uint256 weth, uint256 lpTokenSupply) {
		IERC20 lpToken = IERC20(lpTokenAddr);

		address vaultAddress = vaultAddr;
		VaultReentrancyLib.ensureNotInVaultContext(IVault(vaultAddress));
		(IERC20[] memory tokens, uint256[] memory balances, ) = IVault(vaultAddress).getPoolTokens(poolId);

		rdnt = address(tokens[0]) == outTokenAddr ? balances[0] : balances[1];
		weth = address(tokens[0]) == outTokenAddr ? balances[1] : balances[0];

		lpTokenSupply = lpToken.totalSupply();
	}

	/**
	 * @notice Add liquidity
	 * @param _wethAmt WETH amount
	 * @param _rdntAmt RDNT amount
	 * @return liquidity amount of LP token
	 */
	function _joinPool(uint256 _wethAmt, uint256 _rdntAmt) internal returns (uint256 liquidity) {
		(address token0, address token1) = _sortTokens(outTokenAddr, inTokenAddr);
		IAsset[] memory assets = new IAsset[](2);
		assets[0] = IAsset(token0);
		assets[1] = IAsset(token1);

		uint256[] memory maxAmountsIn = new uint256[](2);
		if (token0 == inTokenAddr) {
			maxAmountsIn[0] = _wethAmt;
			maxAmountsIn[1] = _rdntAmt;
		} else {
			maxAmountsIn[0] = _rdntAmt;
			maxAmountsIn[1] = _wethAmt;
		}

		bytes memory userDataEncoded = abi.encode(IWeightedPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT, maxAmountsIn, 0);
		IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(assets, maxAmountsIn, userDataEncoded, false);
		IVault(vaultAddr).joinPool(poolId, address(this), address(this), inRequest);

		IERC20 lp = IERC20(lpTokenAddr);
		liquidity = lp.balanceOf(address(this));
	}

	/**
	 * @notice Gets needed WETH for adding LP
	 * @param lpAmount LP amount
	 * @return wethAmount WETH amount
	 */
	function quoteWETH(uint256 lpAmount) public view override returns (uint256 wethAmount) {
		(address token0, address token1) = _sortTokens(outTokenAddr, inTokenAddr);
		IAsset[] memory assets = new IAsset[](2);
		assets[0] = IAsset(token0);
		assets[1] = IAsset(token1);

		uint256[] memory maxAmountsIn = new uint256[](2);
		uint256 enterTokenIndex;
		if (token0 == inTokenAddr) {
			enterTokenIndex = 0;
			maxAmountsIn[0] = type(uint256).max;
			maxAmountsIn[1] = 0;
		} else {
			enterTokenIndex = 1;
			maxAmountsIn[0] = 0;
			maxAmountsIn[1] = type(uint256).max;
		}

		bytes memory userDataEncoded = abi.encode(
			IWeightedPool.JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT,
			lpAmount,
			enterTokenIndex
		);
		IVault.JoinPoolRequest memory inRequest = IVault.JoinPoolRequest(assets, maxAmountsIn, userDataEncoded, false);

		(bool success, bytes memory data) = BALANCER_QUERIES.staticcall(
			abi.encodeCall(IBalancerQueries.queryJoin, (poolId, address(this), address(this), inRequest))
		);
		if (!success) revert QuoteFail();
		(, uint256[] memory amountsIn) = abi.decode(data, (uint256, uint256[]));
		return amountsIn[enterTokenIndex];
	}

	/**
	 * @notice Zap WETH
	 * @param amount to zap
	 * @return liquidity token amount
	 */
	function zapWETH(uint256 amount) public returns (uint256 liquidity) {
		if (msg.sender != lockZap) revert InsufficientPermission();
		IWETH(wethAddr).transferFrom(msg.sender, address(this), amount);
		liquidity = _joinPool(amount, 0);
		IERC20 lp = IERC20(lpTokenAddr);
		lp.safeTransfer(msg.sender, liquidity);
		_refundDust(outTokenAddr, wethAddr, msg.sender);
	}

	/**
	 * @notice Zap WETH and RDNT
	 * @param _wethAmt WETH amount
	 * @param _rdntAmt RDNT amount
	 * @return liquidity token amount
	 */
	function zapTokens(uint256 _wethAmt, uint256 _rdntAmt) public returns (uint256 liquidity) {
		if (msg.sender != lockZap) revert InsufficientPermission();
		IWETH(wethAddr).transferFrom(msg.sender, address(this), _wethAmt);
		IERC20(outTokenAddr).safeTransferFrom(msg.sender, address(this), _rdntAmt);

		liquidity = _joinPool(_wethAmt, _rdntAmt);
		IERC20 lp = IERC20(lpTokenAddr);
		lp.safeTransfer(msg.sender, liquidity);

		_refundDust(outTokenAddr, wethAddr, msg.sender);
	}

	/**
	 * @notice Sort tokens
	 */
	function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
		if (tokenA == tokenB) revert IdenticalAddresses();
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		if (token0 == address(0)) revert AddressZero();
	}

	/**
	 * @notice Calculate quote in WETH from token
	 * @param tokenAmount RDNT amount
	 * @return optimalWETHAmount WETH amount
	 */
	function quoteFromToken(uint256 tokenAmount) public view returns (uint256 optimalWETHAmount) {
		uint256 rdntPriceInEth = getPrice();
		uint256 p1 = rdntPriceInEth * 1e10;
		uint256 ethRequiredBeforeWeight = (tokenAmount * p1) / 1e18;
		optimalWETHAmount = ethRequiredBeforeWeight / POOL_WEIGHT;
	}

	/**
	 * @notice Set lockzap contract
	 */
	function setLockZap(address _lockZap) external onlyOwner {
		if (_lockZap == address(0)) revert AddressZero();
		lockZap = _lockZap;
	}

	/**
	 * @notice Calculate tokenAmount from WETH
	 * @param _inToken input token
	 * @param _wethAmount WETH amount
	 * @return tokenAmount token amount
	 */
	function quoteSwap(address _inToken, uint256 _wethAmount) public view override returns (uint256 tokenAmount) {
		IVault.SingleSwap memory singleSwap;
		singleSwap.poolId = poolId;
		singleSwap.kind = IVault.SwapKind.GIVEN_OUT;
		singleSwap.assetIn = IAsset(_inToken);
		singleSwap.assetOut = IAsset(wethAddr);
		singleSwap.amount = _wethAmount;
		singleSwap.userData = abi.encode(0);

		IVault.FundManagement memory funds;
		funds.sender = address(this);
		funds.fromInternalBalance = false;
		funds.recipient = payable(address(this));
		funds.toInternalBalance = false;

		(bool success, bytes memory data) = BALANCER_QUERIES.staticcall(
			abi.encodeCall(IBalancerQueries.querySwap, (singleSwap, funds))
		);
		if (!success) revert QuoteFail();
		uint256 amountIn = abi.decode(data, (uint256));
		return amountIn;
	}

	/**
	 * @notice Swaps tokens like USDC, DAI, USDT, WBTC to WETH
	 * @param _inToken address of the asset to swap
	 * @param _amount the amount of asset to swap
	 * @param _minAmountOut the minimum WETH amount to accept without reverting
	 */
	function swapToWeth(address _inToken, uint256 _amount, uint256 _minAmountOut) external {
		if (msg.sender != lockZap) revert InsufficientPermission();
		if (_inToken == address(0)) revert AddressZero();
		if (_amount == 0) revert ZeroAmount();
		bool isSingleSwap = true;
		if (_inToken == USDT_ADDRESS || _inToken == DAI_ADDRESS) {
			isSingleSwap = false;
		}

		if (!isSingleSwap) {
			uint256 usdcBalanceBefore = IERC20(USDC_ADDRESS).balanceOf(address(this));
			_swap(_inToken, USDC_ADDRESS, _amount, 0, DAI_USDT_USDC_POOL_ID, address(this));
			uint256 usdcBalanceAfter = IERC20(USDC_ADDRESS).balanceOf(address(this));
			_inToken = USDC_ADDRESS;
			_amount = usdcBalanceAfter - usdcBalanceBefore;
		}

		_swap(_inToken, REAL_WETH_ADDR, _amount, _minAmountOut, WBTC_WETH_USDC_POOL_ID, msg.sender);
	}

	/**
	 * @notice Swaps tokens using the Balancer swap function
	 * @param _inToken address of the asset to swap
	 * @param _outToken address of the asset to receieve
	 * @param _amount the amount of asset to swap
	 * @param _minAmountOut the minimum WETH amount to accept without reverting
	 * @param _poolId The ID of the pool to use for swapping
	 * @param _recipient the receiver of the outToken
	 */
	function _swap(
		address _inToken,
		address _outToken,
		uint256 _amount,
		uint256 _minAmountOut,
		bytes32 _poolId,
		address _recipient
	) internal {
		IVault.SingleSwap memory singleSwap;
		singleSwap.poolId = _poolId;
		singleSwap.kind = IVault.SwapKind.GIVEN_IN;
		singleSwap.assetIn = IAsset(_inToken);
		singleSwap.assetOut = IAsset(_outToken);
		singleSwap.amount = _amount;
		singleSwap.userData = abi.encode(0);

		IVault.FundManagement memory funds;
		funds.sender = address(this);
		funds.fromInternalBalance = false;
		funds.recipient = payable(address(_recipient));
		funds.toInternalBalance = false;

		uint256 currentAllowance = IERC20(_inToken).allowance(address(this), vaultAddr);
		if (_amount > currentAllowance) {
			IERC20(_inToken).forceApprove(vaultAddr, _amount);
		}
		IVault(vaultAddr).swap(singleSwap, funds, _minAmountOut, block.timestamp);
	}

	/**
	 * @notice Get swap fee percentage
	 */
	function getSwapFeePercentage() external view returns (uint256 fee) {
		IWeightedPool pool = IWeightedPool(lpTokenAddr);
		fee = pool.getSwapFeePercentage();
	}

	/**
	 * @notice Set swap fee percentage
	 */
	function setSwapFeePercentage(uint256 _fee) external onlyOwner {
		IWeightedPool pool = IWeightedPool(lpTokenAddr);
		pool.setSwapFeePercentage(_fee);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IWETH} from "../../../interfaces/IWETH.sol";

/// @title Dust Refunder Contract
/// @dev Refunds dust tokens remaining from zapping.
/// @author Radiant
contract DustRefunder {
	using SafeERC20 for IERC20;

	/**
	 * @notice Refunds RDNT and WETH.
	 * @param _rdnt RDNT address
	 * @param _weth WETH address
	 * @param _refundAddress Address for refund
	 */
	function _refundDust(address _rdnt, address _weth, address _refundAddress) internal {
		IERC20 rdnt = IERC20(_rdnt);
		IWETH weth = IWETH(_weth);

		uint256 dustWETH = weth.balanceOf(address(this));
		if (dustWETH > 0) {
			weth.transfer(_refundAddress, dustWETH);
		}
		uint256 dustRdnt = rdnt.balanceOf(address(this));
		if (dustRdnt > 0) {
			rdnt.safeTransfer(_refundAddress, dustRdnt);
		}
	}
}