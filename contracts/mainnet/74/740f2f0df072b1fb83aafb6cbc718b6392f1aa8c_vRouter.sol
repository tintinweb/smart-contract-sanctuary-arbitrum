/**
 *Submitted for verification at Arbiscan.io on 2024-06-26
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;




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

// File: @uniswap/lib/contracts/libraries/TransferHelper.sol



pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// File: contracts/types.sol



pragma solidity 0.8.26;

struct MaxTradeAmountParams {
    uint256 fee;
    uint256 balance0;
    uint256 balance1;
    uint256 vBalance0;
    uint256 vBalance1;
    uint256 reserveRatioFactor;
    uint256 priceFeeFactor;
    uint256 maxReserveRatio;
    uint256 reserves;
    uint256 reservesBaseValueSum;
}

struct VirtualPoolModel {
    uint24 fee;
    address token0;
    address token1;
    uint256 balance0;
    uint256 balance1;
    address commonToken;
    address jkPair;
    address ikPair;
}

struct VirtualPoolTokens {
    address jk0;
    address jk1;
    address ik0;
    address ik1;
}

struct ExchangeReserveCallbackParams {
    address jkPair1;
    address ikPair1;
    address jkPair2;
    address ikPair2;
    address caller;
    uint256 flashAmountOut;
}

struct SwapCallbackData {
    address caller;
    uint256 tokenInMax;
    uint ETHValue;
    address jkPool;
}

struct PoolCreationDefaults {
    address factory;
    address token0;
    address token1;
    uint16 fee;
    uint16 vFee;
    uint256 maxReserveRatio;
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
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
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// File: contracts/interfaces/IvPair.sol



pragma solidity 0.8.26;


interface IvPair {
    event Mint(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        uint lpTokens,
        uint poolLPTokens
    );

    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to,
        uint256 totalSupply
    );

    event Swap(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address indexed to
    );

    event SwapReserve(
        address indexed sender,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        address ikPool,
        address indexed to
    );

    event AllowListChanged(address[] tokens);

    event vSync(uint112 balance0, uint112 balance1);

    event ReserveSync(address asset, uint256 balance, uint256 rRatio);

    event FeeChanged(uint16 fee, uint16 vFee);

    event ReserveThresholdChanged(uint256 newThreshold);

    event BlocksDelayChanged(uint256 _newBlocksDelay);

    event ReserveRatioWarningThresholdChanged(
        uint256 _newReserveRatioWarningThreshold
    );

    function fee() external view returns (uint16);

    function vFee() external view returns (uint16);

    function setFee(uint16 _fee, uint16 _vFee) external;

    function swapNative(
        uint256 amountOut,
        address tokenOut,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function swapReserveToNative(
        uint256 amountOut,
        address ikPair,
        address to,
        bytes calldata data
    ) external returns (uint256 _amountIn);

    function swapNativeToReserve(
        uint256 amountOut,
        address ikPair,
        address to,
        uint256 incentivesLimitPct,
        bytes calldata data
    ) external returns (address _token, uint256 _leftovers);

    function liquidateReserve(
        address reserveToken,
        address nativePool
    ) external;

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function setAllowList(address[] memory _allowList) external;

    function allowListMap(address _token) external view returns (bool allowed);

    function calculateReserveRatio() external view returns (uint256 rRatio);

    function setMaxReserveThreshold(uint256 threshold) external;

    function setReserveRatioWarningThreshold(uint256 threshold) external;

    function setBlocksDelay(uint128 _newBlocksDelay) external;

    function emergencyToggle() external;

    function allowListLength() external view returns (uint);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function pairBalance0() external view returns (uint112);

    function pairBalance1() external view returns (uint112);

    function maxReserveRatio() external view returns (uint256);

    function getBalances() external view returns (uint112, uint112);

    function lastSwapBlock() external view returns (uint128);

    function blocksDelay() external view returns (uint128);

    function getTokens() external view returns (address, address);

    function reservesBaseValue(
        address reserveAddress
    ) external view returns (uint256);

    function reserves(address reserveAddress) external view returns (uint256);

    function reservesBaseValueSum() external view returns (uint256);

    function reserveRatioFactor() external pure returns (uint256);
}

// File: contracts/interfaces/IvSwapPoolDeployer.sol



pragma solidity 0.8.26;

/// @title An interface for a contract that is capable of deploying Uniswap V3 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IvSwapPoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function poolCreationDefaults()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint16 fee,
            uint16 vFee,
            uint256 maxReserveRatio
        );
}

// File: contracts/interfaces/IvPairFactory.sol



pragma solidity 0.8.26;

interface IvPairFactory {
    event PairCreated(
        address poolAddress,
        address factory,
        address token0,
        address token1,
        uint16 fee,
        uint16 vFee,
        uint256 maxReserveRatio
    );

    event DefaultAllowListChanged(address[] allowList);

    event FactoryNewAdmin(address newAdmin);
    event FactoryNewPendingAdmin(address newPendingAdmin);

    event FactoryNewEmergencyAdmin(address newEmergencyAdmin);
    event FactoryNewPendingEmergencyAdmin(address newPendingEmergencyAdmin);

    event ExchangeReserveAddressChanged(address newExchangeReserve);

    event FactoryVPoolManagerChanged(address newVPoolManager);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address);

    function pairs(
        address tokenA,
        address tokenB
    ) external view returns (address);

    function setDefaultAllowList(address[] calldata _defaultAllowList) external;

    function allPairs(uint256 index) external view returns (address);

    function allPairsLength() external view returns (uint256);

    function vPoolManager() external view returns (address);

    function admin() external view returns (address);

    function emergencyAdmin() external view returns (address);

    function pendingEmergencyAdmin() external view returns (address);

    function setPendingEmergencyAdmin(address newEmergencyAdmin) external;

    function acceptEmergencyAdmin() external;

    function pendingAdmin() external view returns (address);

    function setPendingAdmin(address newAdmin) external;

    function setVPoolManagerAddress(address _vPoolManager) external;

    function acceptAdmin() external;

    function exchangeReserves() external view returns (address);

    function setExchangeReservesAddress(address _exchangeReserves) external;
}

// File: contracts/interfaces/IvPoolManager.sol



pragma solidity 0.8.26;


interface IvPoolManager {
    function pairFactory() external view returns (address);

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) external view returns (VirtualPoolModel memory vPool);

    function getVirtualPools(
        address token0,
        address token1
    ) external view returns (VirtualPoolModel[] memory vPools);

    function updateVirtualPoolBalances(
        address jkPair,
        address ikPair,
        uint256 balance0,
        uint256 balance1
    ) external;
}

// File: contracts/interfaces/IvFlashSwapCallback.sol



pragma solidity 0.8.26;

interface IvFlashSwapCallback {
    function vFlashSwapCallback(
        address tokenIn,
        address tokenOut,
        uint256 requiredBackAmount,
        bytes calldata data
    ) external;
}

// File: @openzeppelin/contracts/utils/math/SafeCast.sol


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

// File: contracts/libraries/vSwapLibrary.sol



pragma solidity 0.8.26;





library vSwapLibrary {
    uint24 internal constant PRICE_FEE_FACTOR = 10 ** 3;

    //find common token and assign to ikToken1 and jkToken1
    function findCommonToken(
        address ikToken0,
        address ikToken1,
        address jkToken0,
        address jkToken1
    ) internal pure returns (VirtualPoolTokens memory vPoolTokens) {
        (
            vPoolTokens.ik0,
            vPoolTokens.ik1,
            vPoolTokens.jk0,
            vPoolTokens.jk1
        ) = (ikToken0 == jkToken0)
            ? (ikToken1, ikToken0, jkToken1, jkToken0)
            : (ikToken0 == jkToken1)
            ? (ikToken1, ikToken0, jkToken0, jkToken1)
            : (ikToken1 == jkToken0)
            ? (ikToken0, ikToken1, jkToken1, jkToken0)
            : (ikToken0, ikToken1, jkToken0, jkToken1); //default
    }

    function calculateVPool(
        uint256 ikTokenABalance,
        uint256 ikTokenBBalance,
        uint256 jkTokenABalance,
        uint256 jkTokenBBalance
    ) internal pure returns (VirtualPoolModel memory vPool) {
        vPool.balance0 =
            (ikTokenABalance * Math.min(ikTokenBBalance, jkTokenBBalance)) /
            Math.max(ikTokenBBalance, 1);

        vPool.balance1 =
            (jkTokenABalance * Math.min(ikTokenBBalance, jkTokenBBalance)) /
            Math.max(jkTokenBBalance, 1);
    }

    function getAmountIn(
        uint256 amountOut,
        uint256 pairBalanceIn,
        uint256 pairBalanceOut,
        uint256 fee
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = (pairBalanceIn * amountOut) * PRICE_FEE_FACTOR;
        uint256 denominator = (pairBalanceOut - amountOut) * fee;
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 pairBalanceIn,
        uint256 pairBalanceOut,
        uint256 fee
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn * fee;
        uint256 numerator = amountInWithFee * pairBalanceOut;
        uint256 denominator = (pairBalanceIn * PRICE_FEE_FACTOR) +
            amountInWithFee;
        amountOut = numerator / denominator;
    }

    function quote(
        uint256 amountA,
        uint256 balanceA,
        uint256 balanceB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'VSWAP: INSUFFICIENT_AMOUNT');
        require(balanceA > 0 && balanceB > 0, 'VSWAP: INSUFFICIENT_LIQUIDITY');
        amountB = (amountA * balanceB) / balanceA;
    }

    function sortBalances(
        address tokenIn,
        address baseToken,
        uint256 pairBalance0,
        uint256 pairBalance1
    ) internal pure returns (uint256 _balance0, uint256 _balance1) {
        (_balance0, _balance1) = baseToken == tokenIn
            ? (pairBalance0, pairBalance1)
            : (pairBalance1, pairBalance0);
    }

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) internal view returns (VirtualPoolModel memory vPool) {
        require(
            block.number >=
                IvPair(ikPair).lastSwapBlock() + IvPair(ikPair).blocksDelay(),
            'VSWAP: LOCKED_VPOOL'
        );

        (address jk0, address jk1) = IvPair(jkPair).getTokens();
        (address ik0, address ik1) = IvPair(ikPair).getTokens();

        VirtualPoolTokens memory vPoolTokens = findCommonToken(
            ik0,
            ik1,
            jk0,
            jk1
        );

        require(
            (vPoolTokens.ik0 != vPoolTokens.jk0) &&
                (vPoolTokens.ik1 == vPoolTokens.jk1),
            'VSWAP: INVALID_VPOOL'
        );

        (uint256 ikBalance0, uint256 ikBalance1) = IvPair(ikPair).getBalances();

        (uint256 jkBalance0, uint256 jkBalance1) = IvPair(jkPair).getBalances();

        vPool = calculateVPool(
            vPoolTokens.ik0 == ik0 ? ikBalance0 : ikBalance1,
            vPoolTokens.ik0 == ik0 ? ikBalance1 : ikBalance0,
            vPoolTokens.jk0 == jk0 ? jkBalance0 : jkBalance1,
            vPoolTokens.jk0 == jk0 ? jkBalance1 : jkBalance0
        );

        vPool.token0 = vPoolTokens.ik0;
        vPool.token1 = vPoolTokens.jk0;
        vPool.commonToken = vPoolTokens.ik1;

        require(
            IvPair(jkPair).allowListMap(vPool.token0),
            'VSWAP: NOT_ALLOWED'
        );

        vPool.fee = IvPair(jkPair).vFee();

        vPool.jkPair = jkPair;
        vPool.ikPair = ikPair;
    }

    /** @dev The function is used to calculate maximum virtual trade amount for
     * swapReserveToNative. The maximum amount that can be traded is such that
     * after the swap reserveRatio will be equal to maxReserveRatio:
     *
     * (reserveBaseValueSum + newReserveBaseValue(vPool.token0)) * reserveRatioFactor / (2 * balance0) = maxReserveRatio,
     * where balance0 is the balance of token0 after the swap (i.e. oldBalance0 + amountOut),
     *       reserveBaseValueSum is SUM(reserveBaseValue[i]) without reserveBaseValue(vPool.token0)
     *       newReserveBaseValue(vPool.token0) is reserveBaseValue(vPool.token0) after the swap
     *
     * amountOut can be expressed through amountIn:
     * amountOut = (amountIn * fee * vBalance1) / (amountIn * fee + vBalance0 * priceFeeFactor)
     *
     * reserveBaseValue(vPool.token0) can be expessed as:
     * if vPool.token1 == token0:
     *     reserveBaseValue(vPool.token0) = reserves[vPool.token0] * vBalance1 / vBalance0
     * else:
     *     reserveBaseValue(vPool.token0) = (reserves[vPool.token0] * vBalance1 * balance0) / (vBalance0 * balance1)
     *
     * Given all that we have two equations for finding maxAmountIn:
     * if vPool.token1 == token0:
     *     Ax^2 + Bx + C = 0,
     *     where A = fee * reserveRatioFactor * vBalance1,
     *           B = vBalance0 * (-2 * balance0 * fee * maxReserveRatio + vBalance1 *
     *              (2 * fee * maxReserveRatio + priceFeeFactor * reserveRatioFactor) +
     *              fee * reserveRatioFactor * reservesBaseValueSum) +
     *              fee * reserves * reserveRatioFactor * vBalance1,
     *           C = -priceFeeFactor * balance0 * (2 * balance0 * maxReserveRatio * vBalance0 -
     *              reserveRatioFactor * (reserves * vBalance1 + reservesBaseValueSum * vBalance0));
     * if vPool.token1 == token1:
     *     x = balance1 * vBalance0 * (2 * balance0 * maxReserveRatio - reserveRatioFactor * reservesBaseValueSum) /
     *          (balance0 * reserveRatioFactor * vBalance1)
     *
     * In the first case, we solve quadratic equation using Newton method.
     */
    function getMaxVirtualTradeAmountRtoN(
        VirtualPoolModel memory vPool
    ) internal view returns (uint256) {
        // The function works if and only if the following constraints are
        // satisfied:
        //      1. all balances are positive and less than or equal to 10^32
        //      2. reserves are non-negative and less than or equal to 10^32
        //      3. 0 < vBalance1 <= balance0 (or balance1 depending on trade)
        //      4. priceFeeFactor == 10^3
        //      5. reserveRatioFactor == 10^5
        //      6. 0 < fee <= priceFeeFactor
        //      7. 0 < maxReserveRatio <= reserveRatioFactor
        //      8. reserveBaseValueSum <= 2 * balance0 * maxReserveRatio (see
        //          reserve ratio formula in vPair.calculateReserveRatio())
        MaxTradeAmountParams memory params;

        params.fee = uint256(vPool.fee);
        params.balance0 = IvPair(vPool.jkPair).pairBalance0();
        params.balance1 = IvPair(vPool.jkPair).pairBalance1();
        params.vBalance0 = vPool.balance0;
        params.vBalance1 = vPool.balance1;
        params.reserveRatioFactor = IvPair(vPool.jkPair).reserveRatioFactor();
        params.priceFeeFactor = uint256(PRICE_FEE_FACTOR);
        params.maxReserveRatio = IvPair(vPool.jkPair).maxReserveRatio();
        params.reserves = IvPair(vPool.jkPair).reserves(vPool.token0);
        params.reservesBaseValueSum =
            IvPair(vPool.jkPair).reservesBaseValueSum() -
            IvPair(vPool.jkPair).reservesBaseValue(vPool.token0);

        require(
            params.balance0 > 0 && params.balance0 <= 10 ** 32,
            'invalid balance0'
        );
        require(
            params.balance1 > 0 && params.balance1 <= 10 ** 32,
            'invalid balance1'
        );
        require(
            params.vBalance0 > 0 && params.vBalance0 <= 10 ** 32,
            'invalid vBalance0'
        );
        require(
            params.vBalance1 > 0 && params.vBalance1 <= 10 ** 32,
            'invalid vBalance1'
        );
        require(params.priceFeeFactor == 10 ** 3, 'invalid priceFeeFactor');
        require(
            params.reserveRatioFactor == 10 ** 5,
            'invalid reserveRatioFactor'
        );
        require(
            params.fee > 0 && params.fee <= params.priceFeeFactor,
            'invalid fee'
        );
        require(
            params.maxReserveRatio > 0 &&
                params.maxReserveRatio <= params.reserveRatioFactor,
            'invalid maxReserveRatio'
        );

        // reserves are full, the answer is 0
        if (
            params.reservesBaseValueSum >
            2 * params.balance0 * params.maxReserveRatio
        ) return 0;

        int256 maxAmountIn;
        if (IvPair(vPool.jkPair).token0() == vPool.token1) {
            require(params.vBalance1 <= params.balance0, 'invalid vBalance1');
            unchecked {
                // a = R * v1 <= 10^5 * v1 = 10^5 * v1 <= 10^37
                uint256 a = params.vBalance1 * params.reserveRatioFactor;
                // b = v0 * (-2 * b0 * M + v1 * (2 * M + R * F / f) + R * s) + r * R * v1 <=
                //  <= v0 * (-2 * b0 * M + b0 * (2 * M + 10^8) + 10^5 * s) + 10^5 * r * v1 =
                //   = v0 * (10^8 * b0 + 10^5 * s) + 10^5 * r * v1 =
                //   = 10^5 * (v0 * (10^3 * b0 + s) + r * v1) <=
                //  <= 10^5 * (v0 * (10^3 * b0 + 2 * b0 * M) + r * v1) <=
                //  <= 10^5 * (v0 * (10^3 * b0 + 2 * 10^5 * b0) + r * v1) =
                //   = 10^5 * (v0 * b0 * (2 * 10^5 + 10^3) + r * v1) <=
                //  <= 10^5 * (10^64 * 2 * 10^5 + 10^64) <= 2 * 10^74
                int256 b = int256(params.vBalance0) *
                    (-2 *
                        int256(params.balance0 * params.maxReserveRatio) +
                        int256(
                            params.vBalance1 *
                                (2 *
                                    params.maxReserveRatio +
                                    (params.priceFeeFactor *
                                        params.reserveRatioFactor) /
                                    params.fee) +
                                params.reserveRatioFactor *
                                params.reservesBaseValueSum
                        )) +
                    int256(
                        params.reserves *
                            params.reserveRatioFactor *
                            params.vBalance1
                    );
                // we split C into c1 * c2 to fit in uint256
                // c1 = F * v0 / f <= 10^3 * v0 <= 10^35
                uint256 c1 = (params.priceFeeFactor * params.vBalance0) /
                    params.fee;
                // c2 = 2 * b0 * M * v0 - R * (r * v1 + s * v0) <=
                //   <= [r and s can be zero] <=
                //   <= 2 * 10^5 * b0 * v0 - 0 <= 2 * 10^69
                //
                // -c2 = R * (r * v1 + s * v0) - 2 * b0 * M * v0 <=
                //    <= 10^5 * (r * v1 + 2 * b0 * M * v0) - 2 * b0 * M * v0 =
                //     = 10^5 * r * v1 + 2 * b0 * M * v0 * (10^5 - 1) <=
                //    <= 10^5 * 10^32 * 10^32 + 2 * 10^32 * 10^5 * 10^32 * 10^5 <=
                //    <= 10^69 + 2 * 10^74 <= 2 * 10^74
                //
                // |c2| <= 2 * 10^74
                int256 c2 = 2 *
                    int256(
                        params.balance0 *
                            params.maxReserveRatio *
                            params.vBalance0
                    ) -
                    int256(
                        params.reserveRatioFactor *
                            (params.reserves *
                                params.vBalance1 +
                                params.reservesBaseValueSum *
                                params.vBalance0)
                    );

                (bool negativeC, uint256 uc2) = (
                    c2 < 0 ? (false, uint256(-c2)) : (true, uint256(c2))
                );

                // according to Newton's method:
                // x_{n+1} = x_n - f(x_n) / f'(x_n) =
                //         = x_n - (Ax_n^2 + Bx_n + c1 * c2) / (2Ax_n + B) =
                //         = (2Ax_n^2 + Bx_n - Ax_n^2 - Bx_n - c1 * c2) / (2Ax_n + B) =
                //         = (Ax_n^2 - c1 * c2) / (2Ax_n + B) =
                //         = Ax_n^2 / (2Ax_n + B) - c1 * c2 / (2Ax_n + B)
                // initial approximation: maxAmountIn always <= vb0
                maxAmountIn = int256(params.vBalance0);
                // derivative = 2 * a * x + b =
                //    = 2 * R * f * v1 * x + v0 * (-2 * b0 * f * M + v1 * (2 * f * M + R * F) + f * R * s) + f * r * R * v1 <=
                //   <= 2 * 10^40 * 10^32 + 2 * 10^76 <= 2 * 10^76
                int256 derivative = int256(2 * a) * maxAmountIn + b;

                (bool negativeDerivative, uint256 uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                // maxAmountIn * maxAmountIn <= vb0 * vb0 <= 10^64
                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;

                derivative = int256(2 * a) * maxAmountIn + b;

                (negativeDerivative, uDerivative) = (
                    derivative < 0
                        ? (true, uint256(-derivative))
                        : (false, uint256(derivative))
                );

                maxAmountIn = (
                    negativeC
                        ? SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) + SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                        : SafeCast.toInt256(
                            Math.mulDiv(
                                a,
                                uint256(maxAmountIn * maxAmountIn),
                                uDerivative
                            )
                        ) - SafeCast.toInt256(Math.mulDiv(c1, uc2, uDerivative))
                );

                if (negativeDerivative) maxAmountIn = -maxAmountIn;
            }
        } else {
            unchecked {
                require(
                    params.vBalance1 <= params.balance1,
                    'invalid vBalance1'
                );
                maxAmountIn =
                    SafeCast.toInt256(
                        Math.mulDiv(
                            params.balance1 * params.vBalance0,
                            2 *
                                params.balance0 *
                                params.maxReserveRatio -
                                params.reserveRatioFactor *
                                params.reservesBaseValueSum,
                            params.balance0 *
                                params.reserveRatioFactor *
                                params.vBalance1
                        )
                    ) -
                    SafeCast.toInt256(params.reserves);
            }
        }
        assert(maxAmountIn >= 0);
        return uint256(maxAmountIn);
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;


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

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
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
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

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
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
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
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
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
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.20;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 value) public virtual {
        _burn(_msgSender(), value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, deducting from
     * the caller's allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `value`.
     */
    function burnFrom(address account, uint256 value) public virtual {
        _spendAllowance(account, _msgSender(), value);
        _burn(account, value);
    }
}

// File: @openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/presets/ERC20PresetFixedSupply.sol)
pragma solidity ^0.8.0;


/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply, address owner) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

// File: contracts/vSwapERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.26;





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
contract vSwapERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private constant _name = 'Virtuswap-LP';
    string private constant _symbol = 'VSWAPLP';

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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
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
    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
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
    function approve(
        address spender,
        uint256 amount
    ) external virtual override returns (bool) {
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
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external virtual returns (bool) {
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
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) external virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            'ERC20: decreased allowance below zero'
        );
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
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            'ERC20: transfer amount exceeds balance'
        );
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
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

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
            require(
                currentAllowance >= amount,
                'ERC20: insufficient allowance'
            );
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

// File: contracts/vPair.sol



pragma solidity 0.8.26;












contract vPair is IvPair, vSwapERC20, ReentrancyGuard {
    uint24 internal constant BASE_FACTOR = 1000;
    uint24 internal constant MINIMUM_LIQUIDITY = BASE_FACTOR;
    uint24 internal constant RESERVE_RATIO_FACTOR = BASE_FACTOR * 100;

    address public immutable factory;
    address public immutable override token0;
    address public immutable override token1;

    uint112 public override pairBalance0;
    uint112 public override pairBalance1;
    uint16 public override fee;
    uint16 public override vFee;

    uint128 public override lastSwapBlock;
    uint128 public override blocksDelay;

    uint256 public override reservesBaseValueSum;
    uint256 public override maxReserveRatio;
    uint256 public reserveRatioWarningThreshold;

    address[] public allowList;
    mapping(address => bool) public override allowListMap;
    bool public closed;

    mapping(address => uint256) public override reservesBaseValue;
    mapping(address => uint256) public override reserves;

    function _onlyFactoryAdmin() internal view {
        require(
            msg.sender == IvPairFactory(factory).admin() ||
                msg.sender == factory,
            'OA'
        );
    }

    modifier onlyFactoryAdmin() {
        _onlyFactoryAdmin();
        _;
    }

    modifier onlyEmergencyAdmin() {
        require(msg.sender == IvPairFactory(factory).emergencyAdmin(), 'OE');
        _;
    }

    modifier isOpen() {
        require(!closed, 'C');
        _;
    }

    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    function fetchBalance(address token) internal view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSignature('balanceOf(address)', address(this))
        );
        require(success && data.length >= 32, 'FBF');
        return abi.decode(data, (uint256));
    }

    constructor() {
        (
            factory,
            token0,
            token1,
            fee,
            vFee,
            maxReserveRatio
        ) = IvSwapPoolDeployer(msg.sender).poolCreationDefaults();
        reserveRatioWarningThreshold = 1900;
        blocksDelay = 40;
    }

    function _update(uint112 balance0, uint112 balance1) internal {
        lastSwapBlock = uint128(block.number);

        (pairBalance0, pairBalance1) = (balance0, balance1);

        emit vSync(balance0, balance1);
    }

    function getBalances()
        external
        view
        override
        returns (uint112 _balance0, uint112 _balance1)
    {
        return (pairBalance0, pairBalance1);
    }

    function getTokens()
        external
        view
        override
        returns (address _token0, address _token1)
    {
        return (token0, token1);
    }

    function swapNative(
        uint256 amountOut,
        address tokenOut,
        address to,
        bytes calldata data
    ) external override nonReentrant isOpen returns (uint256 _amountIn) {
        require(to > address(0) && to != token0 && to != token1, 'IT');
        require(tokenOut == token0 || tokenOut == token1, 'NNT');
        require(amountOut > 0, 'IAO');

        address _tokenIn = tokenOut == token0 ? token1 : token0;

        (uint256 _balanceIn, uint256 _balanceOut) = vSwapLibrary.sortBalances(
            _tokenIn,
            token0,
            pairBalance0,
            pairBalance1
        );

        require(amountOut < _balanceOut, 'AOE');

        SafeERC20.safeTransfer(IERC20(tokenOut), to, amountOut);

        uint256 requiredAmountIn = vSwapLibrary.getAmountIn(
            amountOut,
            _balanceIn,
            _balanceOut,
            fee
        );

        if (data.length > 0) {
            IvFlashSwapCallback(msg.sender).vFlashSwapCallback(
                _tokenIn,
                tokenOut,
                requiredAmountIn,
                data
            );
        }

        _amountIn = fetchBalance(_tokenIn) - _balanceIn;

        require(_amountIn > 0 && _amountIn >= requiredAmountIn, 'IIA');

        {
            //avoid stack too deep
            bool _isTokenIn0 = _tokenIn == token0;

            _update(
                uint112(
                    _isTokenIn0
                        ? _balanceIn + _amountIn
                        : _balanceOut - amountOut
                ),
                uint112(
                    _isTokenIn0
                        ? _balanceOut - amountOut
                        : _balanceIn + _amountIn
                )
            );
        }

        emit Swap(
            msg.sender,
            _tokenIn,
            tokenOut,
            requiredAmountIn,
            amountOut,
            to
        );
    }

    function swapNativeToReserve(
        uint256 amountOut,
        address ikPair,
        address to,
        uint256 incentivesLimitPct,
        bytes calldata data
    )
        external
        override
        nonReentrant
        isOpen
        returns (address _leftoverToken, uint256 _leftoverAmount)
    {
        require(msg.sender == IvPairFactory(factory).exchangeReserves(), 'OA');
        require(to > address(0) && to != token0 && to != token1, 'IT');

        VirtualPoolModel memory vPool = IvPoolManager(
            IvPairFactory(factory).vPoolManager()
        ).getVirtualPool(ikPair, address(this));

        // validate ikPair with factory
        require(
            IvPairFactory(factory).pairs(vPool.token1, vPool.commonToken) ==
                ikPair,
            'IIKP'
        );
        require(
            amountOut <= vPool.balance1 && amountOut <= reserves[vPool.token1],
            'AOE'
        );
        require(allowListMap[vPool.token1], 'TNW');
        require(vPool.token0 == token0 || vPool.token0 == token1, 'NNT');

        SafeERC20.safeTransfer(IERC20(vPool.token1), to, amountOut);
        uint256 requiredAmountIn = vSwapLibrary.quote(
            amountOut,
            vPool.balance1,
            vPool.balance0
        );

        if (data.length > 0)
            IvFlashSwapCallback(msg.sender).vFlashSwapCallback(
                vPool.token0,
                vPool.token1,
                requiredAmountIn,
                data
            );

        {
            // scope to avoid stack too deep errors
            uint256 balanceDiff = fetchBalance(vPool.token0) -
                (vPool.token0 == token0 ? pairBalance0 : pairBalance1);
            require(balanceDiff >= requiredAmountIn, 'IBD');
            (_leftoverAmount, _leftoverToken) = (
                Math.min(
                    balanceDiff - requiredAmountIn,
                    (balanceDiff * incentivesLimitPct) / 100
                ),
                vPool.token0
            );
            if (_leftoverAmount > 0) {
                SafeERC20.safeTransfer(
                    IERC20(_leftoverToken),
                    msg.sender,
                    _leftoverAmount
                );
            }
            IvPoolManager(IvPairFactory(factory).vPoolManager())
                .updateVirtualPoolBalances(
                    ikPair,
                    address(this),
                    vPool.balance0 + balanceDiff - _leftoverAmount,
                    vPool.balance1 - amountOut
                );
        }

        {
            // scope to avoid stack too deep errors
            // //update reserve balance in the equivalent of token0 value
            uint256 reserveTokenBalance = fetchBalance(vPool.token1);
            // //re-calculate price of reserve asset in token0 for the whole pool balance
            uint256 _reserveBaseValue = reserveTokenBalance > 0
                ? vSwapLibrary.quote(
                    reserveTokenBalance,
                    vPool.balance1,
                    vPool.balance0
                )
                : 0;

            if (_reserveBaseValue > 0 && vPool.token0 == token1) {
                //if tokenOut is not token0 we should quote it to token0 value
                _reserveBaseValue = vSwapLibrary.quote(
                    _reserveBaseValue,
                    pairBalance1,
                    pairBalance0
                );
            }
            unchecked {
                reservesBaseValueSum += _reserveBaseValue;
                reservesBaseValueSum -= reservesBaseValue[vPool.token1];
            }
            reservesBaseValue[vPool.token1] = _reserveBaseValue;
            //update reserve balance
            reserves[vPool.token1] = reserveTokenBalance;
        }

        _update(uint112(fetchBalance(token0)), uint112(fetchBalance(token1)));

        emit ReserveSync(
            vPool.token1,
            reserves[vPool.token1],
            calculateReserveRatio()
        );
        emit SwapReserve(
            msg.sender,
            vPool.token0,
            vPool.token1,
            requiredAmountIn,
            amountOut,
            ikPair,
            to
        );
    }

    function allowListLength() external view returns (uint) {
        return allowList.length;
    }

    function liquidateReserve(
        address reserveToken,
        address nativePool
    ) external override nonReentrant {
        require(
            (msg.sender == IvPairFactory(factory).admin() &&
                calculateReserveRatio() >= reserveRatioWarningThreshold) ||
                msg.sender == IvPairFactory(factory).emergencyAdmin(),
            'OA'
        );
        require(allowListMap[reserveToken], 'TNW');

        (address nativeToken0, address nativeToken1) = IvPair(nativePool)
            .getTokens();
        (uint256 nativeBalance0, uint256 nativeBalance1) = IvPair(nativePool)
            .getBalances();
        if (nativeToken0 != reserveToken) {
            (nativeToken0, nativeToken1) = (nativeToken1, nativeToken0);
            (nativeBalance0, nativeBalance1) = (nativeBalance1, nativeBalance0);
        }
        uint256 reserveAmount = reserves[reserveToken];

        require(
            (nativeToken1 == token0 || nativeToken1 == token1) &&
                IvPairFactory(factory).pairs(reserveToken, nativeToken1) ==
                nativePool,
            'INP'
        );

        unchecked {
            reservesBaseValueSum -= reservesBaseValue[reserveToken];
        }
        reservesBaseValue[reserveToken] = 0;
        reserves[reserveToken] = 0;

        SafeERC20.safeTransfer(IERC20(reserveToken), nativePool, reserveAmount);
        IvPair(nativePool).swapNative(
            vSwapLibrary.getAmountOut(
                reserveAmount,
                nativeBalance0,
                nativeBalance1,
                IvPair(nativePool).fee()
            ),
            nativeToken1,
            address(this),
            new bytes(0)
        );

        _update(uint112(fetchBalance(token0)), uint112(fetchBalance(token1)));

        emit ReserveSync(reserveToken, 0, calculateReserveRatio());
    }

    function swapReserveToNative(
        uint256 amountOut,
        address ikPair,
        address to,
        bytes calldata data
    ) external override nonReentrant isOpen returns (uint256 amountIn) {
        require(amountOut > 0, 'IAO');
        require(to > address(0) && to != token0 && to != token1, 'IT');

        VirtualPoolModel memory vPool = IvPoolManager(
            IvPairFactory(factory).vPoolManager()
        ).getVirtualPool(address(this), ikPair);

        // validate ikPair with factory
        require(
            IvPairFactory(factory).pairs(vPool.token0, vPool.commonToken) ==
                ikPair,
            'IIKP'
        );

        require(amountOut < vPool.balance1, 'AOE');

        uint256 requiredAmountIn = vSwapLibrary.getAmountIn(
            amountOut,
            vPool.balance0,
            vPool.balance1,
            vFee
        );

        SafeERC20.safeTransfer(IERC20(vPool.token1), to, amountOut);

        if (data.length > 0)
            IvFlashSwapCallback(msg.sender).vFlashSwapCallback(
                vPool.token0,
                vPool.token1,
                requiredAmountIn,
                data
            );

        uint256 tokenInBalance = fetchBalance(vPool.token0);
        amountIn = tokenInBalance - reserves[vPool.token0];

        require(amountIn >= requiredAmountIn, 'IIA');

        {
            //update reserve balance in the equivalent of token0 value
            //re-calculate price of reserve asset in token0 for the whole pool blance
            uint256 _reserveBaseValue = vSwapLibrary.quote(
                tokenInBalance,
                vPool.balance0,
                vPool.balance1
            );

            if (vPool.token1 == token1) {
                //if tokenOut is not token0 we should quote it to token0 value
                _reserveBaseValue = vSwapLibrary.quote(
                    _reserveBaseValue,
                    pairBalance1,
                    pairBalance0
                );
            }

            unchecked {
                reservesBaseValueSum += _reserveBaseValue;
                reservesBaseValueSum -= reservesBaseValue[vPool.token0];
            }
            reservesBaseValue[vPool.token0] = _reserveBaseValue;
        }

        //update reserve balance
        reserves[vPool.token0] = tokenInBalance;

        _update(uint112(fetchBalance(token0)), uint112(fetchBalance(token1)));

        uint256 reserveRatio = calculateReserveRatio();
        require(reserveRatio <= maxReserveRatio, 'TBPT'); // reserve amount goes beyond pool threshold

        IvPoolManager(IvPairFactory(factory).vPoolManager())
            .updateVirtualPoolBalances(
                address(this),
                ikPair,
                vPool.balance0 + amountIn,
                vPool.balance1 - amountOut
            );

        emit ReserveSync(vPool.token0, tokenInBalance, reserveRatio);

        emit SwapReserve(
            msg.sender,
            vPool.token0,
            vPool.token1,
            requiredAmountIn,
            amountOut,
            ikPair,
            to
        );
    }

    function calculateReserveRatio()
        public
        view
        override
        returns (uint256 rRatio)
    {
        uint256 _pairBalance0 = pairBalance0;
        rRatio = _pairBalance0 > 0
            ? (reservesBaseValueSum * RESERVE_RATIO_FACTOR) /
                (_pairBalance0 << 1)
            : 0;
    }

    function mint(
        address to
    ) external override nonReentrant isOpen returns (uint256 liquidity) {
        (uint256 _pairBalance0, uint256 _pairBalance1) = (
            pairBalance0,
            pairBalance1
        );
        uint256 currentBalance0 = fetchBalance(token0);
        uint256 currentBalance1 = fetchBalance(token1);
        uint256 amount0 = currentBalance0 - _pairBalance0;
        uint256 amount1 = currentBalance1 - _pairBalance1;

        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply_) / _pairBalance0,
                (amount1 * totalSupply_) / _pairBalance1
            );
        }

        //substract reserve ratio PCT from minted liquidity tokens amount
        uint256 reserveRatio = calculateReserveRatio();

        liquidity =
            (liquidity * RESERVE_RATIO_FACTOR) /
            (RESERVE_RATIO_FACTOR + reserveRatio);

        require(liquidity > 0, 'ILM');

        _mint(to, liquidity);

        _update(uint112(currentBalance0), uint112(currentBalance1));
        emit Mint(to, amount0, amount1, liquidity, totalSupply());
    }

    function burn(
        address to
    )
        external
        override
        nonReentrant
        returns (uint256 amount0, uint256 amount1)
    {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        uint256 balance0 = fetchBalance(_token0);
        uint256 balance1 = fetchBalance(_token1);
        uint256 liquidity = fetchBalance(address(this));

        uint256 totalSupply_ = totalSupply();
        amount0 = (balance0 * liquidity) / totalSupply_;
        amount1 = (balance1 * liquidity) / totalSupply_;

        require(amount0 > 0 && amount1 > 0, 'ILB');

        _burn(address(this), liquidity);
        SafeERC20.safeTransfer(IERC20(_token0), to, amount0);
        SafeERC20.safeTransfer(IERC20(_token1), to, amount1);

        //distribute reserve tokens and update reserve ratios
        uint256 _currentReserveRatio = calculateReserveRatio();
        if (_currentReserveRatio > 0) {
            for (uint256 i = 0; i < allowList.length; ++i) {
                address _wlI = allowList[i];
                uint256 reserveBalance = reserves[_wlI];

                if (reserveBalance > 0) {
                    uint256 reserveAmountOut = (reserveBalance * liquidity) /
                        totalSupply_;

                    SafeERC20.safeTransfer(IERC20(_wlI), to, reserveAmountOut);

                    uint256 reserveBaseValuewlI = reservesBaseValue[_wlI]; //gas saving

                    reservesBaseValue[_wlI] =
                        reserveBaseValuewlI -
                        ((reserveBaseValuewlI * liquidity) / totalSupply_);

                    unchecked {
                        reservesBaseValueSum += reservesBaseValue[_wlI];
                        reservesBaseValueSum -= reserveBaseValuewlI;
                    }

                    reserves[_wlI] = reserveBalance - reserveAmountOut;
                }
            }
        }

        balance0 = fetchBalance(_token0);
        balance1 = fetchBalance(_token1);

        _update(uint112(balance0), uint112(balance1));
        emit Burn(msg.sender, amount0, amount1, to, totalSupply());
    }

    function setAllowList(address[] memory _allowList) external override {
        require(
            msg.sender == factory ||
                msg.sender == IvPairFactory(factory).admin() ||
                msg.sender == IvPairFactory(factory).emergencyAdmin(),
            'OA'
        );
        for (uint i = 1; i < _allowList.length; ++i) {
            require(
                _allowList[i] > _allowList[i - 1],
                'allow list must be unique and sorted'
            );
        }

        address[] memory _oldWL = allowList;
        for (uint256 i = 0; i < _oldWL.length; ++i)
            allowListMap[_oldWL[i]] = false;

        //set new allowList
        allowList = _allowList;
        address token0_ = token0;
        address token1_ = token1;
        uint256 newReservesBaseValueSum;
        for (uint256 i = 0; i < _allowList.length; ++i)
            if (_allowList[i] != token0_ && _allowList[i] != token1_) {
                allowListMap[_allowList[i]] = true;
                newReservesBaseValueSum += reservesBaseValue[_allowList[i]];
            }
        reservesBaseValueSum = newReservesBaseValueSum;

        emit AllowListChanged(_allowList);
    }

    function setFee(
        uint16 _fee,
        uint16 _vFee
    ) external override onlyFactoryAdmin {
        require(_fee > 0 && _vFee > 0 && _fee < 1000 && _vFee < 1000, 'IFC');
        fee = _fee;
        vFee = _vFee;

        emit FeeChanged(_fee, _vFee);
    }

    function setMaxReserveThreshold(
        uint256 threshold
    ) external override onlyFactoryAdmin {
        require(threshold > 0, 'IRT');
        maxReserveRatio = threshold;
        emit ReserveThresholdChanged(threshold);
    }

    function setReserveRatioWarningThreshold(
        uint256 _reserveRatioWarningThreshold
    ) external override onlyEmergencyAdmin {
        require(_reserveRatioWarningThreshold <= maxReserveRatio, 'IRWT');
        reserveRatioWarningThreshold = _reserveRatioWarningThreshold;
        emit ReserveRatioWarningThresholdChanged(_reserveRatioWarningThreshold);
    }

    function emergencyToggle() external override onlyEmergencyAdmin {
        closed = !closed;
    }

    function setBlocksDelay(uint128 _newBlocksDelay) external override {
        require(
            msg.sender == IvPairFactory(factory).emergencyAdmin() ||
                msg.sender == IvPairFactory(factory).admin(),
            'OA'
        );
        blocksDelay = _newBlocksDelay;
        emit BlocksDelayChanged(_newBlocksDelay);
    }

    function reserveRatioFactor() external pure override returns (uint256) {
        return RESERVE_RATIO_FACTOR;
    }
}

// File: contracts/interfaces/IMulticall.sol



pragma solidity 0.8.26;

// copied from @uniswap/v3-periphery/contracts/interfaces/IMulticall.sol, only updated Solidity version

/// @title Multicall interface
/// @author Uniswap Labs
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// File: contracts/base/Multicall.sol



pragma solidity 0.8.26;


// copied from @uniswap/v3-periphery/contracts/base/Multicall.sol, only updated Solidity version

/// @title Multicall
/// @author Uniswap Labs
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// File: contracts/libraries/PoolAddress.sol



pragma solidity 0.8.26;

/// @title Provides functions for deriving a pool address from the factory and token
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0x637bc1e6555f050fef1c3804f2f03647a960ac0a39ac52c519c3c6d9da312ae0;

    function orderAddresses(
        address tokenA,
        address tokenB
    ) internal pure returns (address token0, address token1) {
        return (tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA));
    }

    function getSalt(
        address tokenA,
        address tokenB
    ) internal pure returns (bytes32 salt) {
        (address token0, address token1) = orderAddresses(tokenA, tokenB);
        salt = keccak256(abi.encode(token0, token1));
    }

    function computeAddress(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address pool) {
        bytes32 _salt = getSalt(token0, token1);

        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            factory,
                            _salt,
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// File: contracts/interfaces/IvRouter.sol



pragma solidity 0.8.26;


interface IvRouter {
    event RouterFactoryChanged(address newFactoryAddress);

    function changeFactory(address _factory) external;

    function factory() external view returns (address);

    function WETH9() external view returns (address);

    function swapExactETHForTokens(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETH(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external;

    function swapETHForExactTokens(
        address[] memory path,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external payable;

    function swapTokensForExactETH(
        address[] memory path,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external;

    function swapReserveETHForExactTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external payable;

    function swapReserveTokensForExactETH(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external;

    function swapReserveExactTokensForETH(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external;

    function swapReserveExactETHForTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external payable;

    function swapTokensForExactTokens(
        address[] memory path,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external;

    function swapReserveTokensForExactTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external;

    function swapReserveExactTokensForTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external;

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            address pairAddress,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountOut(
        address tokenA,
        address tokenB,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getAmountIn(
        address tokenA,
        address tokenB,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function quote(
        address inputToken,
        address outputToken,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getVirtualAmountIn(
        address jkPair,
        address ikPair,
        uint256 amountOut
    ) external view returns (uint256 amountIn);

    function getVirtualAmountOut(
        address jkPair,
        address ikPair,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) external view returns (VirtualPoolModel memory vPool);

    function getVirtualPools(
        address token0,
        address token1
    ) external view returns (VirtualPoolModel[] memory vPools);

    function getMaxVirtualTradeAmountRtoN(
        address jkPair,
        address ikPair
    ) external view returns (uint256 maxAmountIn);
}

// File: contracts/interfaces/external/IWETH9.sol

pragma solidity 0.8.26;


/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// File: contracts/vRouter.sol



pragma solidity 0.8.26;














contract vRouter is IvRouter, Multicall {
    address public override factory;
    address public immutable override WETH9;

    modifier _onlyFactoryAdmin() {
        require(
            msg.sender == IvPairFactory(factory).admin(),
            'VSWAP:ONLY_ADMIN'
        );
        _;
    }

    modifier notAfter(uint256 deadline) {
        require(deadline >= block.timestamp, 'VSWAP:EXPIRED');
        _;
    }

    constructor(address _factory, address _WETH9) {
        WETH9 = _WETH9;
        factory = _factory;
    }

    receive() external payable {
        require(msg.sender == WETH9, 'Not WETH9');
    }

    function getPairAddress(
        address tokenA,
        address tokenB
    ) internal view returns (address) {
        return PoolAddress.computeAddress(factory, tokenA, tokenB);
    }

    function getPair(
        address tokenA,
        address tokenB
    ) internal view returns (IvPair) {
        return IvPair(getPairAddress(tokenA, tokenB));
    }

    function unwrapTransferETH(address to, uint256 amount) internal {
        IWETH9(WETH9).withdraw(amount);
        (bool success, ) = to.call{value: amount}('');
        require(success, 'VSWAP: TRANSFER FAILED');
    }

    function getAmountsIn(
        address[] memory path,
        uint256 amountOut
    ) public view returns (uint[] memory amountsIn) {
        amountsIn = new uint[](path.length);
        amountsIn[amountsIn.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; --i) {
            amountsIn[i - 1] = getAmountIn(path[i - 1], path[i], amountsIn[i]);
        }
    }

    function getAmountsOut(
        address[] memory path,
        uint256 amountIn
    ) public view returns (uint[] memory amountsOut) {
        amountsOut = new uint[](path.length);
        amountsOut[0] = amountIn;
        for (uint i = 1; i < amountsOut.length; ++i) {
            amountsOut[i] = getAmountOut(
                path[i - 1],
                path[i],
                amountsOut[i - 1]
            );
        }
    }

    function swapExactETHForTokens(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external payable override notAfter(deadline) {
        require(path[0] == WETH9, 'VSWAP: INPUT TOKEN MUST BE WETH9');
        uint[] memory amountsOut = getAmountsOut(path, amountIn);
        require(
            amountsOut[amountsOut.length - 1] >= minAmountOut,
            'VSWAP: INSUFFICIENT_INPUT_AMOUNT'
        );
        transferETHInput(amountsOut[0], getPairAddress(path[0], path[1]));
        swap(path, amountsOut, to);
    }

    function swapExactTokensForETH(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        require(
            path[path.length - 1] == WETH9,
            'VSWAP: OUTPUT TOKEN MUST BE WETH9'
        );
        uint[] memory amountsOut = getAmountsOut(path, amountIn);
        require(
            amountsOut[amountsOut.length - 1] >= minAmountOut,
            'VSWAP: INSUFFICIENT_INPUT_AMOUNT'
        );
        transferInput(path[0], amountsOut[0], getPairAddress(path[0], path[1]));
        swap(path, amountsOut, address(this));
        unwrapTransferETH(to, amountsOut[amountsOut.length - 1]);
    }

    function swapETHForExactTokens(
        address[] memory path,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external payable override notAfter(deadline) {
        require(path[0] == WETH9, 'VSWAP: INPUT TOKEN MUST BE WETH9');
        uint[] memory amountsIn = getAmountsIn(path, amountOut);
        require(amountsIn[0] <= maxAmountIn, 'VSWAP: REQUIRED_AMOUNT_EXCEEDS');
        transferETHInput(amountsIn[0], getPairAddress(path[0], path[1]));
        swap(path, amountsIn, to);
    }

    function swapTokensForExactETH(
        address[] memory path,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        require(
            path[path.length - 1] == WETH9,
            'VSWAP: OUTPUT TOKEN MUST BE WETH9'
        );
        uint[] memory amountsIn = getAmountsIn(path, amountOut);
        require(amountsIn[0] <= maxAmountIn, 'VSWAP: REQUIRED_AMOUNT_EXCEEDS');
        transferInput(path[0], amountsIn[0], getPairAddress(path[0], path[1]));
        swap(path, amountsIn, address(this));
        unwrapTransferETH(to, amountsIn[amountsIn.length - 1]);
    }

    function swapReserveETHForExactTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external payable override notAfter(deadline) {
        (address ik0, address ik1) = IvPair(ikPair).getTokens();
        address tokenIn = ik0 == commonToken ? ik1 : ik0;
        require(tokenIn == WETH9, 'VSWAP: INPUT TOKEN MUST BE WETH9');
        address jkAddress = getPairAddress(tokenOut, commonToken);
        uint256 amountIn = getVirtualAmountIn(jkAddress, ikPair, amountOut);
        require(amountIn <= maxAmountIn, 'VSWAP: REQUIRED_VINPUT_EXCEED');
        transferETHInput(amountIn, jkAddress);
        swapReserve(amountOut, jkAddress, ikPair, to);
    }

    function swapReserveTokensForExactETH(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        require(tokenOut == WETH9, 'VSWAP: OUTPUT TOKEN MUST BE WETH9');
        (address ik0, address ik1) = IvPair(ikPair).getTokens();
        address tokenIn = ik0 == commonToken ? ik1 : ik0;
        address jkAddress = getPairAddress(tokenOut, commonToken);
        uint256 amountIn = getVirtualAmountIn(jkAddress, ikPair, amountOut);
        require(amountIn <= maxAmountIn, 'VSWAP: REQUIRED_VINPUT_EXCEED');
        transferInput(tokenIn, amountIn, jkAddress);
        swapReserve(amountOut, jkAddress, ikPair, address(this));
        unwrapTransferETH(to, amountOut);
    }

    function swapReserveExactTokensForETH(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        require(tokenOut == WETH9, 'VSWAP: OUTPUT TOKEN MUST BE WETH9');
        (address ik0, address ik1) = IvPair(ikPair).getTokens();
        address tokenIn = ik0 == commonToken ? ik1 : ik0;
        address jkAddress = getPairAddress(tokenOut, commonToken);
        uint256 amountOut = getVirtualAmountOut(jkAddress, ikPair, amountIn);
        require(
            amountOut >= minAmountOut,
            'VSWAP: INSUFFICIENT_VOUTPUT_AMOUNT'
        );
        transferInput(tokenIn, amountIn, jkAddress);
        swapReserve(amountOut, jkAddress, ikPair, address(this));
        unwrapTransferETH(to, amountOut);
    }

    function swapReserveExactETHForTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external payable override notAfter(deadline) {
        (address ik0, address ik1) = IvPair(ikPair).getTokens();
        address tokenIn = ik0 == commonToken ? ik1 : ik0;
        require(tokenIn == WETH9, 'VSWAP: INPUT TOKEN MUST BE WETH9');
        address jkAddress = getPairAddress(tokenOut, commonToken);
        uint256 amountOut = getVirtualAmountOut(jkAddress, ikPair, amountIn);
        require(
            amountOut >= minAmountOut,
            'VSWAP: INSUFFICIENT_VOUTPUT_AMOUNT'
        );
        transferETHInput(amountIn, jkAddress);
        swapReserve(amountOut, jkAddress, ikPair, to);
    }

    function swapTokensForExactTokens(
        address[] memory path,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        uint[] memory amountsIn = getAmountsIn(path, amountOut);
        require(amountsIn[0] <= maxAmountIn, 'VSWAP: REQUIRED_AMOUNT_EXCEEDS');
        transferInput(path[0], amountsIn[0], getPairAddress(path[0], path[1]));
        swap(path, amountsIn, to);
    }

    function swapExactTokensForTokens(
        address[] memory path,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        uint[] memory amountsOut = getAmountsOut(path, amountIn);
        require(
            amountsOut[amountsOut.length - 1] >= minAmountOut,
            'VSWAP: INSUFFICIENT_INPUT_AMOUNT'
        );
        transferInput(path[0], amountsOut[0], getPairAddress(path[0], path[1]));
        swap(path, amountsOut, to);
    }

    function swapReserveTokensForExactTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountOut,
        uint256 maxAmountIn,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        (address ik0, address ik1) = IvPair(ikPair).getTokens();
        address tokenIn = ik0 == commonToken ? ik1 : ik0;
        address jkAddress = getPairAddress(tokenOut, commonToken);
        uint256 amountIn = getVirtualAmountIn(jkAddress, ikPair, amountOut);
        require(amountIn <= maxAmountIn, 'VSWAP: REQUIRED_VINPUT_EXCEED');
        transferInput(tokenIn, amountIn, jkAddress);
        swapReserve(amountOut, jkAddress, ikPair, to);
    }

    function swapReserveExactTokensForTokens(
        address tokenOut,
        address commonToken,
        address ikPair,
        uint256 amountIn,
        uint256 minAmountOut,
        address to,
        uint256 deadline
    ) external override notAfter(deadline) {
        (address ik0, address ik1) = IvPair(ikPair).getTokens();
        address tokenIn = ik0 == commonToken ? ik1 : ik0;
        address jkAddress = getPairAddress(tokenOut, commonToken);
        uint256 amountOut = getVirtualAmountOut(jkAddress, ikPair, amountIn);
        require(
            amountOut >= minAmountOut,
            'VSWAP: INSUFFICIENT_VOUTPUT_AMOUNT'
        );
        transferInput(tokenIn, amountIn, jkAddress);
        swapReserve(amountOut, jkAddress, ikPair, to);
    }

    function transferETHInput(uint amountIn, address pair) internal {
        require(
            address(this).balance >= amountIn,
            'VSWAP: INSUFFICIENT_ETH_INPUT_AMOUNT'
        );
        IWETH9(WETH9).deposit{value: amountIn}();
        SafeERC20.safeTransfer(IERC20(WETH9), pair, amountIn);
    }

    function refundETH() external payable {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success, 'VSWAP: TRANSFER FAILED');
    }

    function transferInput(
        address token,
        uint amountIn,
        address pair
    ) internal {
        SafeERC20.safeTransferFrom(IERC20(token), msg.sender, pair, amountIn);
    }

    function swap(
        address[] memory path,
        uint[] memory amounts,
        address to
    ) internal {
        for (uint i = 0; i < path.length - 1; ++i) {
            getPair(path[i], path[i + 1]).swapNative(
                amounts[i + 1],
                path[i + 1],
                i == path.length - 2
                    ? to
                    : getPairAddress(path[i + 1], path[i + 2]),
                new bytes(0)
            );
        }
    }

    function swapReserve(
        uint amountOut,
        address jkAddress,
        address ikAddress,
        address to
    ) internal {
        IvPair(jkAddress).swapReserveToNative(
            amountOut,
            ikAddress,
            to,
            new bytes(0)
        );
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB, address pairAddress) {
        pairAddress = IvPairFactory(factory).pairs(tokenA, tokenB);
        // create the pair if it doesn't exist yet
        if (pairAddress == address(0))
            pairAddress = IvPairFactory(factory).createPair(tokenA, tokenB);

        (uint256 reserve0, uint256 reserve1) = IvPair(pairAddress)
            .getBalances();

        (reserve0, reserve1) = vSwapLibrary.sortBalances(
            IvPair(pairAddress).token0(),
            tokenA,
            reserve0,
            reserve1
        );

        if (reserve0 == 0 && reserve1 == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = vSwapLibrary.quote(
                amountADesired,
                reserve0,
                reserve1
            );

            if (amountBOptimal <= amountBDesired) {
                require(
                    amountBOptimal >= amountBMin,
                    'VSWAP: INSUFFICIENT_B_AMOUNT'
                );
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = vSwapLibrary.quote(
                    amountBDesired,
                    reserve1,
                    reserve0
                );

                assert(amountAOptimal <= amountADesired);
                require(
                    amountAOptimal >= amountAMin,
                    'VSWAP: INSUFFICIENT_A_AMOUNT'
                );
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        notAfter(deadline)
        returns (
            uint256 amountA,
            uint256 amountB,
            address pairAddress,
            uint256 liquidity
        )
    {
        (amountA, amountB, pairAddress) = _addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        SafeERC20.safeTransferFrom(
            IERC20(tokenA),
            msg.sender,
            pairAddress,
            amountA
        );
        SafeERC20.safeTransferFrom(
            IERC20(tokenB),
            msg.sender,
            pairAddress,
            amountB
        );

        liquidity = IvPair(pairAddress).mint(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        override
        notAfter(deadline)
        returns (uint256 amountA, uint256 amountB)
    {
        address pairAddress = getPairAddress(tokenA, tokenB);

        SafeERC20.safeTransferFrom(
            IERC20(pairAddress),
            msg.sender,
            pairAddress,
            liquidity
        );

        (amountA, amountB) = IvPair(pairAddress).burn(to);

        require(amountA >= amountAMin, 'VSWAP: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'VSWAP: INSUFFICIENT_B_AMOUNT');
    }

    function getVirtualAmountIn(
        address jkPair,
        address ikPair,
        uint256 amountOut
    ) public view override returns (uint256 amountIn) {
        VirtualPoolModel memory vPool = getVirtualPool(jkPair, ikPair);

        amountIn = vSwapLibrary.getAmountIn(
            amountOut,
            vPool.balance0,
            vPool.balance1,
            vPool.fee
        );
    }

    function getVirtualAmountOut(
        address jkPair,
        address ikPair,
        uint256 amountIn
    ) public view override returns (uint256 amountOut) {
        VirtualPoolModel memory vPool = getVirtualPool(jkPair, ikPair);

        amountOut = vSwapLibrary.getAmountOut(
            amountIn,
            vPool.balance0,
            vPool.balance1,
            vPool.fee
        );
    }

    function getVirtualPools(
        address token0,
        address token1
    ) external view override returns (VirtualPoolModel[] memory vPools) {
        vPools = IvPoolManager(IvPairFactory(factory).vPoolManager())
            .getVirtualPools(token0, token1);
    }

    function getVirtualPool(
        address jkPair,
        address ikPair
    ) public view override returns (VirtualPoolModel memory vPool) {
        vPool = IvPoolManager(IvPairFactory(factory).vPoolManager())
            .getVirtualPool(jkPair, ikPair);
    }

    function quote(
        address inputToken,
        address outputToken,
        uint256 amountIn
    ) external view override returns (uint256 amountOut) {
        IvPair pair = getPair(inputToken, outputToken);

        (uint256 balance0, uint256 balance1) = pair.getBalances();

        (balance0, balance1) = vSwapLibrary.sortBalances(
            inputToken,
            pair.token0(),
            balance0,
            balance1
        );

        amountOut = vSwapLibrary.quote(amountIn, balance0, balance1);
    }

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) public view virtual override returns (uint256 amountOut) {
        IvPair pair = getPair(tokenIn, tokenOut);

        (uint256 balance0, uint256 balance1) = pair.getBalances();

        (balance0, balance1) = vSwapLibrary.sortBalances(
            tokenIn,
            pair.token0(),
            balance0,
            balance1
        );

        amountOut = vSwapLibrary.getAmountOut(
            amountIn,
            balance0,
            balance1,
            pair.fee()
        );
    }

    function getAmountIn(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) public view virtual override returns (uint256 amountIn) {
        IvPair pair = getPair(tokenIn, tokenOut);
        (uint256 balance0, uint256 balance1) = IvPair(pair).getBalances();

        (balance0, balance1) = vSwapLibrary.sortBalances(
            tokenIn,
            pair.token0(),
            balance0,
            balance1
        );

        amountIn = vSwapLibrary.getAmountIn(
            amountOut,
            balance0,
            balance1,
            pair.fee()
        );
    }

    function getMaxVirtualTradeAmountRtoN(
        address jkPair,
        address ikPair
    ) external view override returns (uint256 maxAmountIn) {
        VirtualPoolModel memory vPool = getVirtualPool(jkPair, ikPair);
        maxAmountIn = vSwapLibrary.getMaxVirtualTradeAmountRtoN(vPool);
    }

    function changeFactory(
        address _factory
    ) external override _onlyFactoryAdmin {
        require(
            _factory > address(0) && _factory != factory,
            'VSWAP:INVALID_FACTORY'
        );
        factory = _factory;

        emit RouterFactoryChanged(_factory);
    }
}