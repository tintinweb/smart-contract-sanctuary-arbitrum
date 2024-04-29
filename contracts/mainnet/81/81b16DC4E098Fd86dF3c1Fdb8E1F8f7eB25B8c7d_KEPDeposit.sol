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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ILendingVault {

  /* ======================= STRUCTS ========================= */

  struct Borrower {
    // Debt share of the borrower in this vault
    uint256 debt;
    // The last timestamp borrower borrowed from this vault
    uint256 lastUpdatedAt;
  }

  struct InterestRate {
    // Base interest rate which is the y-intercept when utilization rate is 0 in 1e18
    uint256 baseRate;
    // Multiplier of utilization rate that gives the slope of the interest rate in 1e18
    uint256 multiplier;
    // Multiplier after hitting a specified utilization point (kink2) in 1e18
    uint256 jumpMultiplier;
    // Utilization point at which the interest rate is fixed in 1e18
    uint256 kink1;
    // Utilization point at which the jump multiplier is applied in 1e18
    uint256 kink2;
  }

  function totalBorrows() external view returns (uint256);
  function totalAsset() external view returns (uint256);
  function totalAvailableAsset() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function lvTokenValue() external view returns (uint256);
  function borrowAPRPerBorrower(address borrower) external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address borrower) external view returns (uint256);
  function approvedBorrower(address borrower) external view returns (bool);
  function approvedBorrowers() external view returns (address[] memory);
  function depositNative(uint256 assetAmt, uint256 minSharesAmt) payable external;
  function deposit(uint256 assetAmt, uint256 minSharesAmt) external;
  function withdraw(uint256 sharesAmt, uint256 minAssetAmt) external;
  function borrow(uint256 assetAmt) external;
  function repay(uint256 repayAmt) external;
  function withdrawReserve(uint256 assetAmt) external;
  function updatePerformanceFee(uint256 newPerformanceFee) external;
  function updateInterestRate(
    address borrower,
    InterestRate memory newInterestRate
  ) external;
  function approveBorrower(address borrower) external;
  function revokeBorrower(address borrower) external;
  function emergencyRepay(uint256 repayAmt, address defaulter) external;
  function emergencyPause() external;
  function emergencyResume() external;
  function updateMaxCapacity(uint256 newMaxCapacity) external;
  function updateMaxInterestRate(
    address borrower,
    InterestRate memory newMaxInterestRate
  ) external;
  function updateTreasury(address newTreasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IChainlinkOracle {
  function consult(address token) external view returns (int256 price, uint8 decimals);
  function consultIn18Decimals(address token) external view returns (uint256 price);
  function addTokenPriceFeed(address token, address feed) external;
  function addTokenMaxDelay(address token, uint256 maxDelay) external;
  function updateTokenToDenominatorToken(address token, address dt) external;
  function emergencyPause() external;
  function emergencyResume() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { KEPTypes } from  "../../../strategy/kep/KEPTypes.sol";

interface IKEPVault {
  function store() external view returns (KEPTypes.Store memory);
  function deposit(KEPTypes.DepositParams memory dp) external;
  function depositNative(KEPTypes.DepositParams memory dp) external payable;

  function withdraw(KEPTypes.WithdrawParams memory wp) external;

  function rebalanceAdd(
    KEPTypes.RebalanceAddParams memory rap
  ) external;

  function rebalanceRemove(
    KEPTypes.RebalanceRemoveParams memory rrp
  ) external;

  function compound(KEPTypes.CompoundParams memory cp) external;

  function emergencyPause() external;
  function emergencyRepay() external;
  function emergencyBorrow() external;
  function emergencyResume() external;
  function emergencyClose() external;
  function emergencyWithdraw(uint256 shareAmt) external;
  function emergencyStatusChange(KEPTypes.Status status) external;

  function updateTreasury(address treasury) external;
  function updateSwapRouter(address swapRouter) external;
  function updateLendingVaults(address newTokenBLendingVault) external;
  function updateFeePerSecond(uint256 feePerSecond) external;
  function updateParameterLimits(
    uint256 newLeverage,
    uint256 debtRatioStepThreshold,
    uint256 debtRatioUpperLimit,
    uint256 debtRatioLowerLimit,
    int256 deltaUpperLimit,
    int256 deltaLowerLimit
  ) external;
  function updateMinVaultSlippage(uint256 minVaultSlippage) external;
  function updateSwapSlippage(uint256 swapSlippage) external;
  function updateChainlinkOracle(address addr) external;

  function updateMinAssetValue(uint256 value) external;
  function updateMaxAssetValue(uint256 value) external;

  function mintFee() external;
  function mint(address to, uint256 amt) external;
  function burn(address to, uint256 amt) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ISwap {
  struct SwapParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in; in token decimals
    uint256 amountIn;
    // Amount of token out; in token decimals
    uint256 amountOut;
    // Slippage tolerance swap; e.g. 3 = 0.03%
    uint256 slippage;
    // Swap deadline timestamp
    uint256 deadline;
  }

  function swapExactTokensForTokens(
    SwapParams memory sp
  ) external returns (uint256);

  function swapTokensForExactTokens(
    SwapParams memory sp
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IWNT {
  function balanceOf(address user) external returns (uint);
  function approve(address to, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function deposit() external payable;
  function withdraw(uint amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Errors } from "../../utils/Errors.sol";
import { KEPTypes } from "./KEPTypes.sol";
import { KEPReader } from "./KEPReader.sol";

/**
  * @title KEPChecks
  * @author Steadefi
  * @notice Re-usable library functions for require function checks for Steadefi leveraged vaults
*/
library KEPChecks {

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice Checks before native token deposit
    * @param self KEPTypes.Store
    * @param dp KEPTypes.DepositParams
  */
  function beforeNativeDepositChecks(
    KEPTypes.Store storage self,
    KEPTypes.DepositParams memory dp
  ) external view {
    if (dp.token != address(self.WNT))
      revert Errors.InvalidNativeTokenAddress();

    if (dp.amt == 0) revert Errors.EmptyDepositAmount();
  }

  /**
    * @notice Checks before token deposit
    * @param self KEPTypes.Store
    * @param depositValue USD value in 1e18
  */
  function beforeDepositChecks(
    KEPTypes.Store storage self,
    uint256 depositValue
  ) external view {
    if (self.status != KEPTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (
      self.depositCache.depositParams.token != address(self.LRT) &&
      self.depositCache.depositParams.token != address(self.WNT) &&
      self.depositCache.depositParams.token != address(self.LST) &&
      self.depositCache.depositParams.token != address(self.tokenB)
    ) {
      revert Errors.InvalidDepositToken();
    }

    if (self.depositCache.depositParams.amt == 0)
      revert Errors.InsufficientDepositAmount();

    if (self.depositCache.depositParams.slippage < self.minVaultSlippage)
      revert Errors.InsufficientVaultSlippageAmount();

    if (depositValue == 0)
      revert Errors.InsufficientDepositValue();

    if (depositValue < self.minAssetValue)
      revert Errors.InsufficientDepositValue();

    if (depositValue > self.maxAssetValue)
      revert Errors.ExcessiveDepositValue();

    if (depositValue > KEPReader.additionalCapacity(self))
      revert Errors.InsufficientLendingLiquidity();

    if (KEPReader.equityValue(self) == 0 && IERC20(address(self.vault)).totalSupply() > 0)
      revert Errors.DepositNotAllowedWhenEquityIsZero();
  }

  /**
    * @notice Checks after deposit
    * @param self KEPTypes.Store
  */
  function afterDepositChecks(
    KEPTypes.Store storage self
  ) external view {
    // Guards: revert if lrtAmt did not increase at all
    if (KEPReader.lrtAmt(self) <= self.depositCache.healthParams.lrtAmtBefore)
      revert Errors.InsufficientLPTokensMinted();

    // Guards: check that debt ratio is within step change range
    if (!_isWithinStepChange(
      self.depositCache.healthParams.debtRatioBefore,
      KEPReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Slippage: Check whether user received enough shares as expected
    if (self.depositCache.sharesToUser < self.depositCache.minSharesAmt)
      revert Errors.InsufficientSharesMinted();
  }

  /**
    * @notice Checks before vault withdrawal
    * @param self KEPTypes.Store

  */
  function beforeWithdrawChecks(
    KEPTypes.Store storage self
  ) external view {
    if (self.status != KEPTypes.Status.Open)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (self.withdrawCache.withdrawParams.shareAmt == 0)
      revert Errors.EmptyWithdrawAmount();

    if (
      self.withdrawCache.withdrawParams.shareAmt >
      IERC20(address(self.vault)).balanceOf(self.withdrawCache.user)
    ) revert Errors.InsufficientWithdrawBalance();

    if (self.withdrawCache.withdrawValue > self.maxAssetValue)
      revert Errors.ExcessiveWithdrawValue();

    if (self.withdrawCache.withdrawParams.slippage < self.minVaultSlippage)
      revert Errors.InsufficientVaultSlippageAmount();
  }

  /**
    * @notice Checks after token withdrawal
    * @param self KEPTypes.Store
  */
  function afterWithdrawChecks(
    KEPTypes.Store storage self
  ) external view {
    // Guards: revert if lpAmt did not decrease at all
    if (KEPReader.lrtAmt(self) >= self.withdrawCache.healthParams.lrtAmtBefore)
      revert Errors.InsufficientLPTokensBurned();

    // Guards: revert if equity did not decrease at all
    if (
      self.withdrawCache.healthParams.equityAfter >=
      self.withdrawCache.healthParams.equityBefore
    ) revert Errors.InvalidEquityAfterWithdraw();

    // Guards: check that debt ratio is within step change range
    if (!_isWithinStepChange(
      self.withdrawCache.healthParams.debtRatioBefore,
      KEPReader.debtRatio(self),
      self.debtRatioStepThreshold
    )) revert Errors.InvalidDebtRatio();

    // Check that user received enough assets as expected
    if (self.withdrawCache.assetsToUser < self.withdrawCache.minAssetsAmt)
      revert Errors.InsufficientAssetsReceived();
  }

  /**
    * @notice Checks before rebalancing
    * @param self KEPTypes.Store
    * @param rebalanceType KEPTypes.RebalanceType
  */
  function beforeRebalanceChecks(
    KEPTypes.Store storage self,
    KEPTypes.RebalanceType rebalanceType
  ) external view {
    if (
      self.status != KEPTypes.Status.Open &&
      self.status != KEPTypes.Status.Rebalance_Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();

    // Check that rebalance type is Delta or Debt
    // And then check that rebalance conditions are met
    // Note that Delta rebalancing requires vault's delta strategy to be Neutral as well
    if (rebalanceType == KEPTypes.RebalanceType.Delta && self.delta == KEPTypes.Delta.Neutral) {
      if (
        self.rebalanceCache.healthParams.deltaBefore <= self.deltaUpperLimit &&
        self.rebalanceCache.healthParams.deltaBefore >= self.deltaLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    } else if (rebalanceType == KEPTypes.RebalanceType.Debt) {
      if (
        self.rebalanceCache.healthParams.debtRatioBefore <= self.debtRatioUpperLimit &&
        self.rebalanceCache.healthParams.debtRatioBefore >= self.debtRatioLowerLimit
      ) revert Errors.InvalidRebalancePreConditions();
    } else {
       revert Errors.InvalidRebalanceParameters();
    }
  }

  /**
    * @notice Checks after rebalancing add or remove
    * @param self KEPTypes.Store
  */
  function afterRebalanceChecks(
    KEPTypes.Store storage self
  ) external view {
    // Guards: check that delta is within limits for Neutral strategy
    if (self.delta == KEPTypes.Delta.Neutral) {
      int256 _delta = KEPReader.delta(self);

      if (
        _delta > self.deltaUpperLimit ||
        _delta < self.deltaLowerLimit
      ) revert Errors.InvalidDelta();
    }

    // Guards: check that debt is within limits for Long/Neutral strategy
    uint256 _debtRatio = KEPReader.debtRatio(self);

    if (
      _debtRatio > self.debtRatioUpperLimit ||
      _debtRatio < self.debtRatioLowerLimit
    ) revert Errors.InvalidDebtRatio();
  }

  /**
    * @notice Checks before compound
    * @param self KEPTypes.Store
  */
  function beforeCompoundChecks(
    KEPTypes.Store storage self
  ) external view {
    if (
      self.status != KEPTypes.Status.Open
    ) revert Errors.NotAllowedInCurrentVaultStatus();

    if (self.compoundCache.depositValue == 0)
      revert Errors.InsufficientDepositAmount();
  }

  /**
    * @notice Checks before emergency pausing of vault
    * @param self KEPTypes.Store
  */
  function beforeEmergencyPauseChecks(
    KEPTypes.Store storage self
  ) external view {
    if (
      self.status == KEPTypes.Status.Paused ||
      self.status == KEPTypes.Status.Resume ||
      self.status == KEPTypes.Status.Repaid ||
      self.status == KEPTypes.Status.Closed
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency repaying of vault
    * @param self KEPTypes.Store
  */
  function beforeEmergencyRepayChecks(
    KEPTypes.Store storage self
  ) external view {
    if (self.status != KEPTypes.Status.Paused)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency re-borrowing assets of vault
    * @param self KEPTypes.Store
  */
  function beforeEmergencyBorrowChecks(
    KEPTypes.Store storage self
  ) external view {
    if (self.status != KEPTypes.Status.Repaid)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before resuming vault
    * @param self KEPTypes.Store
  */
  function beforeEmergencyResumeChecks (
    KEPTypes.Store storage self
  ) external view {
    if (self.status != KEPTypes.Status.Paused)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before emergency closure of vault
    * @param self KEPTypes.Store
  */
  function beforeEmergencyCloseChecks (
    KEPTypes.Store storage self
  ) external view {
    if (self.status != KEPTypes.Status.Repaid)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before a withdrawal during emergency closure
    * @param self KEPTypes.Store
    * @param shareAmt Amount of shares to burn
  */
  function beforeEmergencyWithdrawChecks(
    KEPTypes.Store storage self,
    uint256 shareAmt
  ) external view {
    if (self.status != KEPTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();

    if (shareAmt == 0)
      revert Errors.EmptyWithdrawAmount();

    if (shareAmt > IERC20(address(self.vault)).balanceOf(msg.sender))
      revert Errors.InsufficientWithdrawBalance();
  }

  /**
    * @notice Checks before emergency status change
    * @param self KEPTypes.Store
  */
  function beforeEmergencyStatusChangeChecks(
    KEPTypes.Store storage self
  ) external view {
    if (
      self.status == KEPTypes.Status.Open ||
      self.status == KEPTypes.Status.Deposit ||
      self.status == KEPTypes.Status.Withdraw ||
      self.status == KEPTypes.Status.Closed
    ) revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /**
    * @notice Checks before shares are minted
    * @param self KEPTypes.Store
  */
  function beforeMintFeeChecks(
    KEPTypes.Store storage self
  ) external view {
    if (self.status == KEPTypes.Status.Paused || self.status == KEPTypes.Status.Closed)
      revert Errors.NotAllowedInCurrentVaultStatus();
  }

  /* ================== INTERNAL FUNCTIONS =================== */

  /**
    * @notice Check if values are within threshold range
    * @param valueBefore Previous value
    * @param valueAfter New value
    * @param threshold Tolerance threshold; 100 = 1%
    * @return boolean Whether value after is within threshold range
  */
  function _isWithinStepChange(
    uint256 valueBefore,
    uint256 valueAfter,
    uint256 threshold
  ) internal pure returns (bool) {
    // To bypass initial vault deposit
    if (valueBefore == 0)
      return true;

    return (
      valueAfter >= valueBefore * (10000 - threshold) / 10000 &&
      valueAfter <= valueBefore * (10000 + threshold) / 10000
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { KEPTypes } from "./KEPTypes.sol";
import { KEPReader } from "./KEPReader.sol";
import { KEPChecks } from "./KEPChecks.sol";
import { KEPManager } from "./KEPManager.sol";

/**
  * @title KEPDeposit
  * @author Steadefi
  * @notice Re-usable library functions for deposit operations for Steadefi leveraged vaults
*/
library KEPDeposit {

  using SafeERC20 for IERC20;

  /* ======================= CONSTANTS ======================= */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event DepositCompleted(
    address indexed user,
    uint256 shareAmt,
    uint256 equityBefore,
    uint256 equityAfter
  );

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice @inheritdoc GMXVault
    * @param self KEPTypes.Store
    * @param isNative Boolean as to whether user is depositing native asset (e.g. ETH, AVAX, etc.)
  */
  function deposit(
    KEPTypes.Store storage self,
    KEPTypes.DepositParams memory dp,
    bool isNative
  ) external {
    KEPTypes.DepositCache memory _dc;

    _dc.user = payable(msg.sender);

    KEPTypes.HealthParams memory _hp;

    _dc.healthParams.equityBefore = KEPReader.equityValue(self);
    _dc.healthParams.lrtAmtBefore = KEPReader.lrtAmt(self);
    _dc.healthParams.debtRatioBefore = KEPReader.debtRatio(self);
    _dc.healthParams.deltaBefore = KEPReader.delta(self);

    _dc.healthParams = _hp;
    _dc.depositParams = dp;

    // Transfer deposited assets from user to vault
    if (isNative) {
      KEPChecks.beforeNativeDepositChecks(self, dp);

      self.WNT.deposit{ value: dp.amt }();
    } else {
      IERC20(dp.token).safeTransferFrom(msg.sender, address(this), dp.amt);
    }

    // If LRT deposited, no swap needed; simply add it to LRT amt in depositCache
    // If deposited is not LRT and WNT, we swap it for WNT and get the depositValue
    uint256 wntToSwapToLRTAmt;

    if (dp.token != address(self.LRT) && dp.token != address(self.WNT)) {
      ISwap.SwapParams memory _sp;

      _sp.tokenIn = dp.token;
      _sp.tokenOut = address(self.WNT);
      _sp.amountIn = dp.amt;
      _sp.slippage = self.swapSlippage;
      _sp.deadline = dp.deadline;

      // Replace the deposit params with swapped values
      wntToSwapToLRTAmt = KEPManager.swapExactTokensForTokens(self, _sp);

      _dc.depositValue = KEPReader.convertToUsdValue(
        self,
        address(self.WNT),
        wntToSwapToLRTAmt
      );
    } else if (dp.token == address(self.LRT)) {
       _dc.lrtAmt = dp.amt;

      _dc.depositValue = KEPReader.convertToUsdValue(
        self,
        address(self.LRT),
        dp.amt
      );
    } else {
      _dc.depositValue = KEPReader.convertToUsdValue(
        self,
        address(dp.token),
        dp.amt
      );
    }

    self.depositCache = _dc;

    KEPChecks.beforeDepositChecks(self, _dc.depositValue);

    // Calculate minimum amount of shares expected based on deposit value
    // and vault slippage value passed in. We calculate this after `beforeDepositChecks()`
    // to ensure the vault slippage passed in meets the `minVaultSlippage`
    _dc.minSharesAmt = KEPReader.valueToShares(
      self,
      _dc.depositValue,
      _dc.healthParams.equityBefore
    ) * (10000 - dp.slippage) / 10000;

    self.status = KEPTypes.Status.Deposit;

    // Borrow assets and restake/swap for LRT
    uint256 _borrowTokenBAmt = KEPManager.calcBorrow(self, _dc.depositValue);

    _dc.borrowParams.borrowTokenBAmt = _borrowTokenBAmt;

    KEPManager.borrow(self, _borrowTokenBAmt);

    // Swap borrowed token for WNT first
    ISwap.SwapParams memory _sp2;

    _sp2.tokenIn = address(self.tokenB);
    _sp2.tokenOut = address(self.WNT);
    _sp2.amountIn = _borrowTokenBAmt;
    _sp2.slippage = self.swapSlippage;
    _sp2.deadline = dp.deadline;

    wntToSwapToLRTAmt += KEPManager.swapExactTokensForTokens(self, _sp2);

    // Swap WNT for LRT
    ISwap.SwapParams memory _sp3;

    _sp3.tokenIn = address(self.WNT);
    _sp3.tokenOut = address(self.LRT);
    _sp3.amountIn = wntToSwapToLRTAmt;
    _sp3.slippage = self.swapSlippage;
    _sp3.deadline = dp.deadline;

    _dc.lrtAmt += KEPManager.swapExactTokensForTokens(self, _sp3);

    // Add to vault's total LRT amount
    self.lrtAmt += _dc.lrtAmt;

    // Store equityAfter and shareToUser values in DepositCache
    _dc.healthParams.equityAfter = KEPReader.equityValue(self);

    _dc.sharesToUser = KEPReader.valueToShares(
      self,
      _dc.healthParams.equityAfter - _dc.healthParams.equityBefore,
      _dc.healthParams.equityBefore
    );

    self.depositCache = _dc;

    KEPChecks.afterDepositChecks(self);

    self.vault.mintFee();

    // Mint shares to depositor
    self.vault.mint(_dc.user, _dc.sharesToUser);

    self.status = KEPTypes.Status.Open;

    emit DepositCompleted(
      _dc.user,
      _dc.sharesToUser,
      _dc.healthParams.equityBefore,
      _dc.healthParams.equityAfter
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { KEPTypes } from "./KEPTypes.sol";
import { KEPReader } from "./KEPReader.sol";
import { KEPWorker } from "./KEPWorker.sol";

/**
  * @title KEPManager
  * @author Steadefi
  * @notice Re-usable library functions for calculations and operations of borrows, repays, swaps
  * adding and removal of liquidity to yield source
*/
library KEPManager {

  using SafeERC20 for IERC20;

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event BorrowSuccess(uint256 borrowTokenBAmt);
  event RepaySuccess(uint256 repayTokenBAmt);

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice Calculate amount of tokenA and tokenB to borrow
    * @param self KEPTypes.Store
    * @param depositValue USD value in 1e18
  */
  function calcBorrow(
    KEPTypes.Store storage self,
    uint256 depositValue
  ) external view returns (uint256) {
    // Calculate final position value based on deposit value
    uint256 _positionValue = depositValue * self.leverage / SAFE_MULTIPLIER;

    // Obtain the value to borrow
    uint256 _borrowValue = _positionValue - depositValue;

    uint256 _tokenBDecimals = IERC20Metadata(address(self.tokenB)).decimals();

    uint256 _borrowTokenBAmt = _borrowValue
      * SAFE_MULTIPLIER
      / KEPReader.convertToUsdValue(self, address(self.tokenB), 10**(_tokenBDecimals))
      / (10 ** (18 - _tokenBDecimals));

    return _borrowTokenBAmt;
  }

  /**
    * @notice Calculate amount of tokenB to repay based on token shares ratio being withdrawn
    * @param self KEPTypes.Store
    * @param shareRatio Amount of vault token shares relative to total supply in 1e18
  */
  function calcRepay(
    KEPTypes.Store storage self,
    uint256 shareRatio
  ) external view returns (uint256) {
    uint256 tokenBDebtAmt = KEPReader.debtAmt(self);

    uint256 _repayTokenBAmt = shareRatio * tokenBDebtAmt / SAFE_MULTIPLIER;

    return _repayTokenBAmt;
  }

  /**
    * @notice Calculate maximum amount of tokenIn allowed when swapping for an exact
    * amount of tokenOut as a form of slippage protection
    * @dev We slightly buffer amountOut here with swapSlippage to account for fees, etc.
    * @param self KEPTypes.Store
    * @param tokenIn Address of tokenIn
    * @param tokenOut Address of tokenOut
    * @param amountOut Amt of tokenOut wanted
    * @param slippage Slippage in 1e4
    * @return amountInMaximum in 1e18
  */
  function calcAmountInMaximum(
    KEPTypes.Store storage self,
    address tokenIn,
    address tokenOut,
    uint256 amountOut,
    uint256 slippage
  ) external view returns (uint256) {
    // Value of token out wanted in 1e18
    uint256 _tokenOutValue = amountOut
      * self.chainlinkOracle.consultIn18Decimals(tokenOut)
      / (10 ** IERC20Metadata(tokenOut).decimals());

    // Maximum amount in in 1e18
    uint256 _amountInMaximum = _tokenOutValue
      * SAFE_MULTIPLIER
      / self.chainlinkOracle.consultIn18Decimals(tokenIn)
      * (10000 + slippage) / 10000;

    // If tokenIn asset decimals is less than 18, e.g. USDC,
    // we need to normalize the decimals of _amountInMaximum
    if (IERC20Metadata(tokenIn).decimals() < 18)
      _amountInMaximum /= 10 ** (18 - IERC20Metadata(tokenIn).decimals());

    return _amountInMaximum;
  }

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @notice Borrow tokens from lending vaults
    * @param self KEPTypes.Store
    * @param borrowTokenBAmt Amount of tokenB to borrow in token decimals
  */
  function borrow(
    KEPTypes.Store storage self,
    uint256 borrowTokenBAmt
  ) public {
    if (borrowTokenBAmt > 0) {
      self.tokenBLendingVault.borrow(borrowTokenBAmt);
    }

    emit BorrowSuccess(borrowTokenBAmt);
  }

  /**
    * @notice Repay tokens to lending vaults
    * @param self KEPTypes.Store
    * @param repayTokenBAmt Amount of tokenB to repay in token decimals
  */
  function repay(
    KEPTypes.Store storage self,
    uint256 repayTokenBAmt
  ) public {
    if (repayTokenBAmt > 0) {
      self.tokenBLendingVault.repay(repayTokenBAmt);
    }

    emit RepaySuccess(repayTokenBAmt);
  }

  /**
    * @notice Swap exact amount of tokenIn for as many possible amount of tokenOut
    * @param self KEPTypes.Store
    * @param sp ISwap.SwapParams
    * @return amountOut in token decimals
  */
  function swapExactTokensForTokens(
    KEPTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    if (sp.amountIn > 0) {
      return KEPWorker.swapExactTokensForTokens(self, sp);
    } else {
      return 0;
    }
  }

  /**
    * @notice Swap as little posible tokenIn for exact amount of tokenOut
    * @param self KEPTypes.Store
    * @param sp ISwap.SwapParams
    * @return amountIn in token decimals
  */
  function swapTokensForExactTokens(
    KEPTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    if (sp.amountIn > 0) {
      return KEPWorker.swapTokensForExactTokens(self, sp);
    } else {
      return 0;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { KEPTypes } from "./KEPTypes.sol";

/**
  * @title KEPReader
  * @author Steadefi
  * @notice Re-usable library functions for reading data and values for Steadefi leveraged vaults
*/
library KEPReader {

  using SafeCast for uint256;

  /* =================== CONSTANTS FUNCTIONS ================= */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ===================== VIEW FUNCTIONS ==================== */

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function svTokenValue(KEPTypes.Store storage self) public view returns (uint256) {
    uint256 equityValue_ = equityValue(self);
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    return equityValue_ * SAFE_MULTIPLIER / (totalSupply_ + pendingFee(self));
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function pendingFee(KEPTypes.Store storage self) public view returns (uint256) {
    uint256 totalSupply_ = IERC20(address(self.vault)).totalSupply();
    uint256 _secondsFromLastCollection = block.timestamp - self.lastFeeCollected;
    return (totalSupply_ * self.feePerSecond * _secondsFromLastCollection) / SAFE_MULTIPLIER;
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function valueToShares(
    KEPTypes.Store storage self,
    uint256 value,
    uint256 currentEquity
  ) public view returns (uint256) {
    uint256 _sharesSupply = IERC20(address(self.vault)).totalSupply() + pendingFee(self);
    if (_sharesSupply == 0 || currentEquity == 0) return value;
    return value * _sharesSupply / currentEquity;
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function convertToUsdValue(
    KEPTypes.Store storage self,
    address token,
    uint256 amt
  ) public view returns (uint256) {
    return (amt * self.chainlinkOracle.consultIn18Decimals(token))
      / (10 ** IERC20Metadata(token).decimals());
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function assetValue(KEPTypes.Store storage self) public view returns (uint256) {
    return convertToUsdValue(
      self,
      address(self.LRT),
      lrtAmt(self)
    );
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function debtValue(KEPTypes.Store storage self) public view returns (uint256) {
    uint256 _tokenBDebtAmt = debtAmt(self);
    return convertToUsdValue(self, address(self.tokenB), _tokenBDebtAmt);
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function equityValue(KEPTypes.Store storage self) public view returns (uint256) {
    uint256 _assetValue = assetValue(self);
    uint256 _debtValue = debtValue(self);

    // in underflow condition return 0
    unchecked {
      if (_assetValue < _debtValue) return 0;
      return _assetValue - _debtValue;
    }
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function assetAmt(KEPTypes.Store storage self) public view returns (uint256) {
    return lrtAmt(self);
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function debtAmt(KEPTypes.Store storage self) public view returns (uint256) {
    return self.tokenBLendingVault.maxRepay(address(self.vault));
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function lrtAmt(KEPTypes.Store storage self) public view returns (uint256) {
    return self.lrtAmt;
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function leverage(KEPTypes.Store storage self) public view returns (uint256) {
    if (assetValue(self) == 0 || equityValue(self) == 0) return 0;
    return assetValue(self) * SAFE_MULTIPLIER / equityValue(self);
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function delta(KEPTypes.Store storage self) public view returns (int256) {
    uint256 _lrtAmt = assetAmt(self);
    uint256 _tokenBDebtAmt = debtAmt(self);
    uint256 equityValue_ = equityValue(self);

    if (_lrtAmt == 0 && _tokenBDebtAmt == 0) return 0;
    if (equityValue_ == 0) return 0;

    bool _isPositive = _lrtAmt >= _tokenBDebtAmt;

    uint256 _unsignedDelta = _isPositive ?
      _lrtAmt - _tokenBDebtAmt :
      _tokenBDebtAmt - _lrtAmt;

    int256 signedDelta = (_unsignedDelta
      * self.chainlinkOracle.consultIn18Decimals(address(self.tokenB))
      / equityValue_).toInt256();

    if (_isPositive) return signedDelta;
    else return -signedDelta;
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function debtRatio(KEPTypes.Store storage self) public view returns (uint256) {
    uint256 _tokenBDebtValue = debtValue(self);
    if (assetValue(self) == 0) return 0;
    return _tokenBDebtValue * SAFE_MULTIPLIER / assetValue(self);
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function additionalCapacity(KEPTypes.Store storage self) public view returns (uint256) {
    uint256 _additionalCapacity;

    // As LRT strategies only borrow 1 asset, Delta Long and Neutral
    // both have similar calculation processes
    if (
      self.delta == KEPTypes.Delta.Long ||
      self.delta == KEPTypes.Delta.Neutral
    ) {
      _additionalCapacity = convertToUsdValue(
        self,
        address(self.tokenB),
        self.tokenBLendingVault.totalAvailableAsset()
      ) * SAFE_MULTIPLIER / (self.leverage - 1e18);
    }

    return _additionalCapacity;
  }

  /**
    * @notice @inheritdoc KEPVault
    * @param self KEPTypes.Store
  */
  function capacity(KEPTypes.Store storage self) public view returns (uint256) {
    return additionalCapacity(self) + equityValue(self);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IWNT } from "../../interfaces/tokens/IWNT.sol";
import { ILendingVault } from "../../interfaces/lending/ILendingVault.sol";
import { IKEPVault } from "../../interfaces/strategy/kep/IKEPVault.sol";
import { IChainlinkOracle } from "../../interfaces/oracles/IChainlinkOracle.sol";
import { ISwap } from "../../interfaces/swap/ISwap.sol";

/**
  * @title KEPTypes
  * @author Steadefi
  * @notice Re-usable library of Types struct definitions for Steadefi leveraged vaults
*/
library KEPTypes {

  /* ======================= STRUCTS ========================= */

  struct Store {
    // Status of the vault
    Status status;
    // Amount of LRT that vault accounts for as total assets
    uint256 lrtAmt;
    // Timestamp when vault last collected management fee
    uint256 lastFeeCollected;

    // Target leverage of the vault in 1e18
    uint256 leverage;
    // Delta strategy
    Delta delta;
    // Management fee per second in % in 1e18
    uint256 feePerSecond;
    // Treasury address
    address treasury;

    // Guards: change threshold for debtRatio change after deposit/withdraw
    uint256 debtRatioStepThreshold; // in 1e4; e.g. 500 = 5%
    // Guards: upper limit of debt ratio after rebalance
    uint256 debtRatioUpperLimit; // in 1e18; 69e16 = 0.69 = 69%
    // Guards: lower limit of debt ratio after rebalance
    uint256 debtRatioLowerLimit; // in 1e18; 61e16 = 0.61 = 61%
    // Guards: upper limit of delta after rebalance
    int256 deltaUpperLimit; // in 1e18; 15e16 = 0.15 = +15%
    // Guards: lower limit of delta after rebalance
    int256 deltaLowerLimit; // in 1e18; -15e16 = -0.15 = -15%
    // Guards: Minimum vault slippage for vault shares/assets in 1e4; e.g. 100 = 1%
    uint256 minVaultSlippage;
    // Slippage for swaps in 1e4; e.g. 100 = 1%
    uint256 swapSlippage;
    // Minimum asset value per vault deposit/withdrawal
    uint256 minAssetValue;
    // Maximum asset value per vault deposit/withdrawal
    uint256 maxAssetValue;

    // Token to borrow for this strategy
    IERC20 tokenB;
    // LRT of this strategy
    IERC20 LRT;
    // Native token for this chain (i.e. ETH)
    IWNT WNT;
    // LST for this chain
    IERC20 LST;
    // Reward token (e.g. ARB)
    IERC20 rewardToken;

    // Token B lending vault
    ILendingVault tokenBLendingVault;

    // Vault address
    IKEPVault vault;

    // Chainlink Oracle contract address
    IChainlinkOracle chainlinkOracle;

    // Swap router for this vault
    ISwap swapRouter;

    // DepositCache
    DepositCache depositCache;
    // WithdrawCache
    WithdrawCache withdrawCache;
    // RebalanceCache
    RebalanceCache rebalanceCache;
    // CompoundCache
    CompoundCache compoundCache;
  }

  struct DepositCache {
    // Address of user
    address payable user;
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // Minimum amount of shares expected in 1e18
    uint256 minSharesAmt;
    // Actual amount of shares minted in 1e18
    uint256 sharesToUser;
    // Amount of LRT that vault received in 1e18
    uint256 lrtAmt;
    // DepositParams
    DepositParams depositParams;
    // BorrowParams
    BorrowParams borrowParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct WithdrawCache {
    // Address of user
    address payable user;
    // Ratio of shares out of total supply of shares to burn
    uint256 shareRatio;
    // Amount of LRT to remove liquidity from
    uint256 lrtAmt;
    // Withdrawal value in 1e18
    uint256 withdrawValue;
    // Minimum amount of assets that user receives
    uint256 minAssetsAmt;
    // Actual amount of assets that user receives
    uint256 assetsToUser;
    // Amount of tokenB that vault received in 1e18
    uint256 tokenBReceived;
    // WithdrawParams
    WithdrawParams withdrawParams;
    // RepayParams
    RepayParams repayParams;
    // HealthParams
    HealthParams healthParams;
  }

  struct CompoundCache {
    // Deposit value (USD) in 1e18
    uint256 depositValue;
    // CompoundParams
    CompoundParams compoundParams;
  }

  struct RebalanceCache {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // BorrowParams
    BorrowParams borrowParams;
    // LRT amount to remove in 1e18
    uint256 lrtAmtToRemove;
    // HealthParams
    HealthParams healthParams;
  }

  struct DepositParams {
    // Address of token depositing; can be tokenA, tokenB or lrt
    address token;
    // Amount of token to deposit in token decimals
    uint256 amt;
    // Slippage tolerance for swaps; e.g. 3 = 0.03%
    uint256 slippage;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct WithdrawParams {
    // Amount of shares to burn in 1e18
    uint256 shareAmt;
    // Slippage tolerance for removing liquidity; e.g. 3 = 0.03%
    uint256 slippage;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct CompoundParams {
    // Address of token in
    address tokenIn;
    // Address of token out
    address tokenOut;
    // Amount of token in
    uint256 amtIn;
    // Timestamp for deadline for this transaction to complete
    uint256 deadline;
  }

  struct RebalanceAddParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // BorrowParams
    BorrowParams borrowParams;
  }

  struct RebalanceRemoveParams {
    // RebalanceType (Delta or Debt)
    RebalanceType rebalanceType;
    // LRT amount to remove in 1e18
    uint256 lrtAmtToRemove;
  }

  struct BorrowParams {
    // Amount of tokenB to borrow in tokenB decimals
    uint256 borrowTokenBAmt;
  }

  struct RepayParams {
    // Amount of tokenB to repay in tokenB decimals
    uint256 repayTokenBAmt;
  }

  struct HealthParams {
    // USD value of equity in 1e18
    uint256 equityBefore;
    // Debt ratio in 1e18
    uint256 debtRatioBefore;
    // Delta in 1e18
    int256 deltaBefore;
    // LRT token balance in 1e18
    uint256 lrtAmtBefore;
    // USD value of equity in 1e18
    uint256 equityAfter;
    // svToken value before in 1e18
    uint256 svTokenValueBefore;
    // // svToken value after in 1e18
    uint256 svTokenValueAfter;
  }

  struct AddLiquidityParams {
    // Amount of tokenB to add liquidity
    uint256 tokenBAmt;
  }

  struct RemoveLiquidityParams {
    // Amount of LRT to remove liquidity
    uint256 lrtAmt;
  }

  /* ========== ENUM ========== */

  enum Status {
    // 0) Vault is open
    Open,
    // 1) User is depositing to vault
    Deposit,
    // 2) User deposit to vault failure
    Deposit_Failed,
    // 3) User is withdrawing from vault
    Withdraw,
    // 4) User withdrawal from vault failure
    Withdraw_Failed,
    // 5) Vault is rebalancing delta or debt  with more hedging
    Rebalance_Add,
    // 6) Vault is rebalancing delta or debt with less hedging
    Rebalance_Remove,
    // 7) Vault has rebalanced but still requires more rebalancing
    Rebalance_Open,
    // 8) Vault is compounding
    Compound,
    // 9) Vault is paused
    Paused,
    // 10) Vault is repaying
    Repay,
    // 11) Vault has repaid all debt after pausing
    Repaid,
    // 12) Vault is resuming
    Resume,
    // 13) Vault is closed after repaying debt
    Closed
  }

  enum Delta {
    // Neutral delta strategy; aims to hedge tokenA exposure
    Neutral,
    // Long delta strategy; aims to correlate with tokenA exposure
    Long,
    // Short delta strategy; aims to overhedge tokenA exposure
    Short
  }

  enum RebalanceType {
    // Rebalance delta; mostly borrowing/repay tokenA
    Delta,
    // Rebalance debt ratio; mostly borrowing/repay tokenB
    Debt
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISwap } from  "../../interfaces/swap/ISwap.sol";
import { KEPTypes } from "./KEPTypes.sol";

library KEPWorker {

  /* ====================== CONSTANTS ======================== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;

  /* ======================== EVENTS ========================= */

  event ExactTokensForTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );
  event TokensForExactTokensSwapped(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 amountOut,
    uint256 slippage,
    uint256 deadline
  );

  /* ================== MUTATIVE FUNCTIONS =================== */

  /**
    * @dev Swap exact amount of tokenIn for as many amount of tokenOut
    * @param self Vault store data
    * @param sp ISwap.SwapParams
    * @return amountOut Amount of tokens out in token decimals
  */
  function swapExactTokensForTokens(
    KEPTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    IERC20(sp.tokenIn).approve(address(self.swapRouter), sp.amountIn);

    emit ExactTokensForTokensSwapped(
      sp.tokenIn,
      sp.tokenOut,
      sp.amountIn,
      sp.amountOut,
      sp.slippage,
      sp.deadline
    );

    return self.swapRouter.swapExactTokensForTokens(sp);
  }

  /**
    * @dev Swap as little tokenIn for exact amount of tokenOut
    * @param self Vault store data
    * @param sp ISwap.SwapParams
    * @return amountIn Amount of tokens in in token decimals
  */
  function swapTokensForExactTokens(
    KEPTypes.Store storage self,
    ISwap.SwapParams memory sp
  ) external returns (uint256) {
    IERC20(sp.tokenIn).approve(address(self.swapRouter), sp.amountIn);

    emit TokensForExactTokensSwapped(
      sp.tokenIn,
      sp.tokenOut,
      sp.amountIn,
      sp.amountOut,
      sp.slippage,
      sp.deadline
    );

    return self.swapRouter.swapTokensForExactTokens(sp);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library Errors {

  /* ===================== AUTHORIZATION ===================== */

  error OnlyKeeperAllowed();
  error OnlyVaultAllowed();
  error OnlyBorrowerAllowed();
  error OnlyYieldBoosterAllowed();
  error OnlyMinterAllowed();
  error OnlyTokenManagerAllowed();

  /* ======================== GENERAL ======================== */

  error ZeroAddressNotAllowed();
  error TokenDecimalsMustBeLessThan18();
  error ReceiverNotApproved();

  /* ========================= ORACLE ======================== */

  error NoTokenPriceFeedAvailable();
  error FrozenTokenPriceFeed();
  error BrokenTokenPriceFeed();
  error TokenPriceFeedMaxDelayMustBeGreaterOrEqualToZero();
  error TokenPriceFeedMaxDeviationMustBeGreaterOrEqualToZero();
  error InvalidTokenInLPPool();
  error InvalidReservesInLPPool();
  error OrderAmountOutMustBeGreaterThanZero();
  error SequencerDown();
  error GracePeriodNotOver();

  /* ======================== LENDING ======================== */

  error InsufficientBorrowAmount();
  error InsufficientRepayAmount();
  error BorrowerAlreadyApproved();
  error BorrowerAlreadyRevoked();
  error InsufficientLendingLiquidity();
  error InsufficientAssetsBalance();
  error InterestRateModelExceeded();

  /* ===================== VAULT GENERAL ===================== */

  error InvalidExecutionFeeAmount();
  error InsufficientExecutionFeeAmount();
  error InsufficientVaultSlippageAmount();
  error NotAllowedInCurrentVaultStatus();
  error AddressIsBlocked();

  /* ===================== VAULT DEPOSIT ===================== */

  error EmptyDepositAmount();
  error InvalidDepositToken();
  error InsufficientDepositAmount();
  error InsufficientDepositValue();
  error ExcessiveDepositValue();
  error InvalidNativeDepositAmountValue();
  error InsufficientSharesMinted();
  error InsufficientCapacity();
  error OnlyNonNativeDepositToken();
  error InvalidNativeTokenAddress();
  error DepositNotAllowedWhenEquityIsZero();
  error DepositAndExecutionFeeDoesNotMatchMsgValue();
  error DepositCancellationCallback();

  /* ===================== VAULT WITHDRAW ==================== */

  error EmptyWithdrawAmount();
  error InvalidWithdrawToken();
  error InsufficientWithdrawAmount();
  error ExcessiveWithdrawValue();
  error InsufficientWithdrawBalance();
  error InvalidEquityAfterWithdraw();
  error InsufficientAssetsReceived();
  error WithdrawNotAllowedInSameDepositBlock();
  error WithdrawalCancellationCallback();
  error NoAssetsToEmergencyRefund();

  /* ==================== VAULT REBALANCE ==================== */

  error InvalidDebtRatio();
  error InvalidDelta();
  error InsufficientLPTokensMinted();
  error InsufficientLPTokensBurned();
  error InvalidRebalancePreConditions();
  error InvalidRebalanceParameters();

  /* ==================== VAULT CALLBACKS ==================== */

  error InvalidCallbackHandler();

  /* ========================= FARMS ========================== */

  error FarmDoesNotExist();
  error FarmNotActive();
  error EndTimeMustBeGreaterThanCurrentTime();
  error MaxMultiplierMustBeGreaterThan1x();
  error InsufficientRewardsBalance();
  error InvalidRate();
  error InvalidEsSDYSplit();

  /* ========================= TOKENS ========================= */

  error RedeemEntryDoesNotExist();
  error InvalidRedeemAmount();
  error InvalidRedeemDuration();
  error VestingPeriodNotOver();
  error InvalidAmount();
  error UnauthorisedAllocateAmount();
  error InvalidRatioValues();
  error DeallocationFeeTooHigh();
  error TransferNotAllowed();
  error InvalidUpdateTransferWhitelistAddress();

  /* ========================= BRIDGE ========================= */

  error OnlyNetworkAllowed();
  error InvalidFeeToken();
  error InsufficientFeeTokenBalance();

  /* ========================= CLAIMS ========================= */

  error AddressAlreadyClaimed();
  error MerkleVerificationFailed();

  /* ========================= DISITRBUTOR ========================= */

  error InvalidNumberOfVaults();
}