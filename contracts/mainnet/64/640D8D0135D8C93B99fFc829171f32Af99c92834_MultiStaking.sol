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

pragma solidity ^0.8.0;

interface ISnapshottable {
    function snapshot() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

abstract contract OnlyWhitelisted is Ownable {
    mapping(uint8 => mapping(address => bool)) public isWhitelisted;

    event WhitelistedAdded(address indexed whitelister, uint8 tier);
    event WhitelistedRemoved(address indexed whitelister, uint8 tier);

    uint8 public constant WHITELIST_DEFAULT = 0;
    uint8 public constant WHITELIST_ADMIN = 1;
    uint8 private nextId = 2;

    constructor() {
        isWhitelisted[WHITELIST_DEFAULT][_msgSender()] = true;
        isWhitelisted[WHITELIST_ADMIN][_msgSender()] = true;
    }


    function consumeNextId() internal returns (uint8) {
        require(nextId != type(uint8).max, "OnlyWhitelisted: no more ids available");
        uint8 id = nextId;
        nextId++;
        return id;
    }
    

    modifier onlyWhitelisted() {
        require(isWhitelisted[WHITELIST_DEFAULT][_msgSender()], "OnlyWhitelisted: caller is not whitelisted");
        _;
    }
    modifier onlyWhitelistedTier(uint8 _tier) {
        require(isWhitelisted[_tier][_msgSender()], "OnlyWhitelisted: caller is not whitelisted for this tier");
        _;
    }
    modifier onlyAdmin() {
        require(isWhitelisted[WHITELIST_ADMIN][_msgSender()] || _msgSender() == owner(), "OnlyWhitelisted: caller is not an admin");
        _;
    }


    function setWhitelisted(address _whitelister, bool _state) public virtual onlyAdmin {
        setWhitelisted(_whitelister, WHITELIST_DEFAULT, _state);
    }
    function setWhitelisted(address _whitelister, uint8 _tier, bool _state) public virtual onlyAdmin {
        require(isWhitelisted[_tier][_whitelister] != _state, "OnlyWhitelisted: target is already a whitelister");
        isWhitelisted[_tier][_whitelister] = _state;
        if (_state) {
            emit WhitelistedAdded(_whitelister, _tier);
        } else {
            emit WhitelistedRemoved(_whitelister, _tier);
        }
    }
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../../legacy/staking/ISnapshottable.sol';

pragma solidity ^0.8.0;


struct UserStake {
    uint256 amount;
    uint256 depositBlock;
    uint256 withdrawBlock;
    uint256 emergencyWithdrawalBlock;
}


interface IMultiStaking is ISnapshottable {
    function baseToken() external view returns (IERC20);

    function getStake(address account, IERC20 _token) external view returns (UserStake memory);
    function token() external view returns (IERC20);
    function penalty(IERC20 _token) external view returns (uint256);
    function isTokenWhitelisted(IERC20 token) external view returns (bool);
    function isAllTokensWhitelisted() external view returns (bool);

    function stake(IERC20 _token, uint256 _amount) external;

    function stakeFor(address _account, uint256 _amount) external;
    function stakeFor(address _account, IERC20 _token, uint256 _amount) external;

    function withdraw(IERC20 _token, uint256 _amount) external;

    function emergencyWithdraw(IERC20 _token, uint256 _amount) external;

    function sendPenalty(address to, IERC20 _token) external returns (uint256);

    function getVestedTokens(address user, IERC20 _token) external view returns (uint256);

    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256);

    function getWithdrawable(address user, IERC20 _token) external view returns (uint256);

    function getEmergencyWithdrawPenalty(address user, IERC20 _token) external view returns (uint256);

    function getVestedTokensPercentage(address user, IERC20 _token) external view returns (uint256);
    
    function getWithdrawablePercentage(address user, IERC20 _token) external view returns (uint256);

    function getEmergencyWithdrawPenaltyPercentage(address user, IERC20 _token) external view returns (uint256);

    function getEmergencyWithdrawPenaltyAmountReturned(address user, IERC20 _token, uint256 amount) external view returns (uint256);

    function getStakersCount() external view returns (uint256);
    function getStakersCount(IERC20 _token) external view returns (uint256);

    function getStakers(uint256 idx) external view returns (address);
    function getStakers(IERC20 _token, uint256 idx) external view returns (address);

    function userTokens(address user, uint256 idx) external view returns (IERC20);
    function getUserTokens(address user) external view returns (IERC20[] memory);

    function tokens(uint256 idx) external view returns (IERC20);
    function tokensLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../../legacy/staking/ISnapshottable.sol';

pragma solidity ^0.8.0;

/**
 * @title IStakingPerTierController
 * @dev Minimal interface for staking that StakeValuator requires
 */
interface IStakingPerStakeValuator is ISnapshottable {
    function stakeFor(address _account, uint256 _amount) external;
    function getUserTokens(address user) external view returns (IERC20[] memory);
    function getVestedTokens(address user, IERC20 token) external view returns (uint256);
    function getVestedTokensAtSnapshot(address user, IERC20 _token, uint256 blockNumber) external view returns (uint256);
    function getStakers(uint256 idx) external view returns (address);
    function getStakersCount() external view returns (uint256);
    function token() external view returns (IERC20);
    function tokens(uint256 idx) external view returns (IERC20);
    function tokensLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';

pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

contract Interpolating {
    using SafeMath for uint256;

    struct Interpolation {
        uint256 startOffset;
        uint256 endOffset;
        uint256 startScale;
        uint256 endScale;
    }
    uint256 public constant INTERPOLATION_DIVISOR = 1000000;


    function lerp(uint256 startOffset, uint256 endOffset, uint256 startScale, uint256 endScale, uint256 current) public pure returns (uint256) {
        if (endOffset <= startOffset) {
            // If the end is less than or equal to the start, then the value is always endValue.
            return endScale;
        }

        if (current <= startOffset) {
            // If the current value is less than or equal to the start, then the value is always startValue.
            return startScale;
        }

        if (current >= endOffset) {
            // If the current value is greater than or equal to the end, then the value is always endValue.
            return endScale;
        }

        uint256 range = endOffset.sub(startOffset);
        if (endScale > startScale) {
            // normal increasing value
            return current.sub(startOffset).mul(endScale.sub(startScale)).div(range).add(startScale);
        } else {
            // decreasing value requires different calculation
            return endOffset.sub(current).mul(startScale.sub(endScale)).div(range).add(endScale);
        }
    }

    function lerpValue(Interpolation memory data, uint256 current, uint256 value) public pure returns (uint256) {
        return lerp(data.startOffset, data.endOffset, data.startScale, data.endScale, current).mul(value).div(INTERPOLATION_DIVISOR);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import { OnlyWhitelisted } from "../OnlyWhitelisted.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';
import { Interpolating } from './Interpolating.sol';
import { UserStake, IMultiStaking } from './interfaces/IMultiStaking.sol';
import { ISnapshottable } from '../legacy/staking/ISnapshottable.sol';
import { IStakingPerStakeValuator } from './interfaces/IStakingPerStakeValuator.sol';
//import { SafeERC20 } from '../libraries/SafeERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


contract MultiStaking is OnlyWhitelisted, Interpolating, IStakingPerStakeValuator {
    using SafeMath for uint256;

    // the amount of the tokens used for calculation may need to mature over time
    Interpolation public tokenVesting;
    // over time some of the tokens may be available for early withdrawal
    Interpolation public withdrawalVesting;
    // there may be a penalty for withdrawing everything early
    Interpolation public emergencyWithdrawPenaltyVesting;

    mapping(IERC20 => bool) public isTokenWhitelisted;
    mapping(IERC20 => uint256) public minimumStakeToBeListed;

    // token => user => data
    mapping(IERC20 => mapping(address => UserStake)) public stakes;
    // token => 
    mapping(IERC20 => address[]) public stakers;
    // token => 
    mapping(address => bool) public isPenaltyCollector;

    // token => user => bool
    mapping(IERC20 => mapping(address => bool)) inTokenStakers;
    // user => bool
    mapping(address => bool) public inAllStakers;
    address[] public allStakers;
    mapping(address => IERC20[]) public userTokens;

    IERC20 public baseToken;

    // what tokens are active in the contract
    IERC20[] public tokens;
    mapping(IERC20 => bool) public isTokenAdded;

    // how much penalty is available to withdraw per token
    mapping(IERC20 => uint256) public penalty;
    //uint256 public minimumStakeToBeListed; // how much token is required to be listed in the stakers variable

    uint256[] public snapshotBlockNumbers;
    // blockNumber => user => => token => amount
    mapping(uint256 => mapping(address => mapping(IERC20 => uint256))) public snapshots;
    // blockNumber => bool
    mapping(uint256 => bool) public snapshotExists;
    // user => blockNumber
    mapping(address => uint256) public lastSnapshotBlockNumbers;

    uint8 public WITHDRAWER_TIER;
    uint8 public MIGRATOR_TIER;
    uint8 public TOKEN_WHITELISTER_TIER;
    uint8 public SNAPSHOTTER_TIER;
    uint8 public PENALTY_COLLECTOR_TIER;

    event Staked(address indexed account, IERC20 token, uint256 amount, uint256 stakingTime);
    event Withdrawn(address indexed account, IERC20 token, uint256 amount);
    event EmergencyWithdrawn(address indexed account, IERC20 token, uint256 amount, uint256 penalty);
    event Migrated(address indexed account, IERC20 token, uint256 amount, address destination);
    event TokenWhitelistChanged(IERC20 indexed token, bool state);
    event Snapshot(uint256 blockNumber);


    constructor(IERC20 _token, uint256 vestingLength, uint256 _minimumStakeToBeListed) {
        require(address(_token) != address(0), "Token address cannot be 0x0");

        // eliminate the possibility of a real snapshot at idx 0
        snapshotBlockNumbers.push(0);

        baseToken = _token;
        trackToken(_token);
        isTokenWhitelisted[_token] = true;
        minimumStakeToBeListed[_token] = _minimumStakeToBeListed;

        // by default emergency withdrawal penalty matures from 80% to 0%
        setEmergencyWithdrawPenalty(Interpolation(0, vestingLength, INTERPOLATION_DIVISOR.mul(8).div(10), 0));
        // by default withdrawals mature from 0% to 100%
        setWithdrawalVesting(Interpolation(0, vestingLength, 0, INTERPOLATION_DIVISOR));
        // by default calculation token amount is fully mature immediately
        setTokenVesting(Interpolation(0, 0, INTERPOLATION_DIVISOR, INTERPOLATION_DIVISOR));

        WITHDRAWER_TIER = consumeNextId();
        MIGRATOR_TIER = consumeNextId();
        TOKEN_WHITELISTER_TIER = consumeNextId();
        SNAPSHOTTER_TIER = consumeNextId();
        PENALTY_COLLECTOR_TIER = consumeNextId();
    }


    ///////////////////////////////////////
    // Core functionality
    ///////////////////////////////////////

    function getStake(address _account, IERC20 _token) public view returns (UserStake memory) {
        return stakes[_token][_account];
    }
    function stake(IERC20 _token, uint256 _amount) public {
        return _stake(msg.sender, msg.sender, _token, _amount);
    }
    function stakeFor(address _account, uint256 _amount) public {
        return stakeFor(_account, baseToken, _amount);
    }
    function stakeFor(address _account, IERC20 _token, uint256 _amount) public {
        return _stake(msg.sender, _account, _token, _amount);
    }
    function _stake(address from, address account, IERC20 _token, uint256 amount) internal tokenIsWhitelisted(_token) {
        require(amount > 0, "Amount must be greater than 0");

        trackToken(_token);

        _updateSnapshots(0, type(uint256).max, account);

        uint256 allowance = _token.allowance(from, address(this));
        require(allowance >= amount, "Check the token allowance");

        UserStake memory userStake = stakes[_token][account];
        uint256 preStakeAmount = userStake.amount;

        // to prevent dust attacks, only add user as staker if they cross the stake threshold
        uint256 minimum = minimumStakeToBeListed[_token];
        if (minimum == 0) {
            minimum = (10**IERC20Metadata(address(_token)).decimals()).div(100); // 1%
        }
        if (preStakeAmount.add(amount) >= minimum) {
            // ensure user isn't already in the list
            if (!inTokenStakers[_token][account]) {
                // track which tokens are relevant for a user
                userTokens[account].push(_token);

                // track which addresses are staking for a token
                stakers[_token].push(account);

                inTokenStakers[_token][account] = true;
            }

            if (!inAllStakers[account]) {
                allStakers.push(account);
                inAllStakers[account] = true;
            }
        }

        if (userStake.amount == 0) {
            // default case
            userStake.amount = amount;
            userStake.depositBlock = block.number;
            userStake.withdrawBlock = block.number;
            userStake.emergencyWithdrawalBlock = block.number;
        } else {
            // An attacker could potentially stake token into a target account and
            //  to mess with their emergency withdrawal ratios. If we normalize the
            //  deposit time and the emergency withdrawal settings are reasonable,
            //  the victim is not negatively affected and the attacker just loses
            //  funds.

            // lerp the blocks based on existing amount vs added amount
            userStake.depositBlock =             lerp(0, userStake.amount.add(amount), userStake.depositBlock,             block.number, userStake.amount);
            userStake.withdrawBlock =            lerp(0, userStake.amount.add(amount), userStake.withdrawBlock,            block.number, userStake.amount);
            userStake.emergencyWithdrawalBlock = lerp(0, userStake.amount.add(amount), userStake.emergencyWithdrawalBlock, block.number, userStake.amount);
            userStake.amount = userStake.amount.add(amount);
        }
        stakes[_token][account] = userStake;

        emit Staked(account, _token, amount, block.timestamp);

        SafeERC20.safeTransferFrom(_token, from, address(this), amount);
    }

    function updateSnapshots(uint256 startIdx, uint256 endIdx) external {
        _updateSnapshots(startIdx, endIdx, msg.sender);
    }
    function _updateSnapshots(uint256 startIdx, uint256 endIdx, address account) internal {
        if (snapshotBlockNumbers.length == 0) {
            return; // early abort
        }

        require(endIdx > startIdx, "endIdx must be greater than startIdx");
        uint256 lastSnapshotBlockNumber = lastSnapshotBlockNumbers[account];
        uint256 lastBlockNumber = snapshotBlockNumbers[uint256(snapshotBlockNumbers.length).sub(1)];

        // iterate backwards through snapshots
        if (snapshotBlockNumbers.length < endIdx) {
            endIdx = uint256(snapshotBlockNumbers.length).sub(1);
        }
        // ensure snapshots aren't skipped
        require(startIdx == 0 || snapshotBlockNumbers[startIdx.sub(1)] <= lastSnapshotBlockNumber, "Can't skip snapshots");
        for (uint256 i = endIdx;  i > startIdx;  --i) {
            uint256 blockNumber = snapshotBlockNumbers[i];

            if (lastSnapshotBlockNumber >= blockNumber) {
                break; // done with user
            }

            // user => token => amount
            mapping(address => mapping(IERC20 => uint256)) storage _snapshot = snapshots[blockNumber];

            // for each token, update the vested amount
            IERC20[] memory _userTokens = userTokens[account];
            for (uint256 j = 0;  j < _userTokens.length;  ++j) {
                IERC20 _token = _userTokens[j];
                _snapshot[account][_token] = _calculateVestedTokensAt(account, _token, blockNumber);
            }
        }

        // set user as updated
        lastSnapshotBlockNumbers[account] = lastBlockNumber;
    }
    function snapshot() external onlyWhitelistedTier(SNAPSHOTTER_TIER) {
        if (!snapshotExists[block.number]) {
            snapshotBlockNumbers.push(block.number);
            snapshotExists[block.number] = true;
            emit Snapshot(block.number);
        }
    }
    function withdraw(IERC20 _token, uint256 _amount) public {
        _updateSnapshots(0, type(uint256).max, msg.sender);
        return _withdraw(msg.sender, _token, _amount, true, msg.sender);
    }
    function withdrawFor(address[] memory _account, IERC20 _token, uint256[] memory _amount) external onlyWhitelistedTier(WITHDRAWER_TIER) {
        require(_account.length == _amount.length, "Account and amount arrays must be the same length");
        for (uint256 i = 0;  i < _account.length;  ++i) {
            _updateSnapshots(0, type(uint256).max, _account[i]);
            _withdraw(_account[i], _token, _amount[i], false, _account[i]);
        }
    }
    function migrateFor(address[] memory _account, IERC20 _token, uint256[] memory _amount, address _destination) external onlyWhitelistedTier(MIGRATOR_TIER) {
        require(_account.length == _amount.length, "Account and amount arrays must be the same length");
        for (uint256 i = 0;  i < _account.length;  ++i) {
            _updateSnapshots(0, type(uint256).max, _account[i]);
            _withdraw(_account[i], _token, _amount[i], false, _destination);
        }
    }
    function _withdraw(address _account, IERC20 _token, uint256 _amount, bool _respectLimits, address _destination) internal {
        require(_amount > 0, "Amount must be greater than 0");

        // cap to deal with frontend rounding errors
        UserStake memory userStake = stakes[_token][_account];
        if (userStake.amount < _amount) {
            _amount = userStake.amount;
        }

        uint256 withdrawableAmount = getWithdrawable(_account, _token);
        if (!_respectLimits) {
            // if we don't respect limits, we can withdraw the entire user's amount
            withdrawableAmount = userStake.amount;
        }
        require(withdrawableAmount >= _amount, "Insufficient withdrawable balance");

        userStake.amount = userStake.amount.sub(_amount);
        uint256 endBlock = Math.min(block.number, userStake.withdrawBlock.add(withdrawalVesting.endOffset));
        userStake.withdrawBlock = lerp(0, withdrawableAmount, userStake.withdrawBlock, endBlock, _amount);
        stakes[_token][_account] = userStake;

        if (_destination != _account) {
            // the user was migrated, not withdrawn
            emit Migrated(_account, _token, _amount, _destination);
        } else {
            emit Withdrawn(_account, _token, _amount);
        }

        SafeERC20.safeTransfer(_token, _destination, _amount);
    }

    function emergencyWithdraw(IERC20 _token, uint256 _amount) public {
        return _emergencyWithdraw(msg.sender, _token, _amount);
    }
    function _emergencyWithdraw(address account, IERC20 _token, uint256 _amount) internal {
        require(_amount > 0, "Amount must be greater than 0");

        // cap to deal with frontend rounding errors
        UserStake memory userStake = stakes[_token][account];
        if (userStake.amount < _amount) {
            _amount = userStake.amount;
        }

        // max out the normal withdrawable first out of respect for the user
        uint256 withdrawableAmount = getWithdrawable(account, _token);
        if (withdrawableAmount > 0) {
            if (withdrawableAmount >= _amount) {
                return _withdraw(account, _token, _amount, true, account);
            } else {
                _withdraw(account, _token, withdrawableAmount, true, account);
                _amount = _amount.sub(withdrawableAmount);
            }
            // update data after the withdraw
            userStake = stakes[_token][account];
        }

        // figure out the numbers for the emergency withdraw
        require(userStake.amount <= _amount, "Insufficient emergency-withdrawable balance");
        userStake.amount = userStake.amount.sub(_amount);
        uint256 returnedAmount = getEmergencyWithdrawPenaltyAmountReturned(account, _token, _amount);
        uint256 _penalty = _amount.sub(returnedAmount);
        uint256 endBlock = Math.min(block.number, userStake.emergencyWithdrawalBlock.add(emergencyWithdrawPenaltyVesting.endOffset));
        userStake.emergencyWithdrawalBlock = lerp(0, userStake.amount, userStake.emergencyWithdrawalBlock, endBlock, _amount);

        // account for the penalty
        penalty[_token] = penalty[_token].add(_penalty);
        stakes[_token][account] = userStake;

        emit EmergencyWithdrawn(account, _token, _amount, _penalty);

        SafeERC20.safeTransfer(_token, account, returnedAmount);
    }


    ///////////////////////////////////////
    // Housekeeping
    ///////////////////////////////////////

    function trackToken(IERC20 _token) internal {
        if (!isTokenAdded[_token]) {
            tokens.push(_token);
            isTokenAdded[_token] = true;
        }
    }
    modifier tokenIsWhitelisted(IERC20 _token) {
        require(isTokenWhitelisted[IERC20(address(0))] || isTokenWhitelisted[_token], "Token is not whitelisted");
        _;
    }
    function setTokenWhitelist(IERC20[] memory _token, bool[] memory _state, uint256[] memory _minimumStakeToBeListed) external onlyWhitelistedTier(TOKEN_WHITELISTER_TIER) {
        require(_token.length == _state.length, "Token and state arrays must be the same length");
        for (uint256 i = 0;  i < _token.length;  ++i) {
            IERC20 token_ = _token[i];
            isTokenWhitelisted[token_] = _state[i];
            minimumStakeToBeListed[token_] = _minimumStakeToBeListed[i];

            trackToken(token_);

            emit TokenWhitelistChanged(token_, _state[i]);
        }
    }
    function setTokenVesting(Interpolation memory _value) public onlyOwner {
        tokenVesting = _value;
    }
    function setWithdrawalVesting(Interpolation memory _value) public onlyOwner {
        withdrawalVesting = _value;
    }
    function setEmergencyWithdrawPenalty(Interpolation memory _value) public onlyOwner {
        emergencyWithdrawPenaltyVesting = _value;
    }
    function sendPenalty(address to, IERC20 _token) external onlyWhitelistedTier(PENALTY_COLLECTOR_TIER) returns (uint256) {
        uint256 _amount = penalty[_token];
        penalty[_token] = 0;

        SafeERC20.safeTransfer(_token, to, _amount);

        return _amount;
    }
    /*
    function setMinimumStakeToBeListed(uint256 _minimumStakeToBeListed) external onlyOwner {
        minimumStakeToBeListed = _minimumStakeToBeListed;
    }
    */
    function getAllStakers() external view returns (address[] memory) {
        return allStakers;
    }
    function getStakersCount() external view returns (uint256) {
        return allStakers.length;
    }
    function getStakersCount(IERC20 _token) external view returns (uint256) {
        return stakers[_token].length;
    }
    function getStakers(uint256 idx) external view returns (address) {
        return allStakers[idx];
    }
    function getStakers(IERC20 _token, uint256 idx) external view returns (address) {
        return stakers[_token][idx];
    }


    ///////////////////////////////////////
    // View functions
    ///////////////////////////////////////

    function getAllTokens() external view returns (IERC20[] memory) {
        return tokens;
    }
    function tokensLength() external view returns (uint256) {
        return tokens.length;
    }
    function isAllTokensWhitelisted() external view returns (bool) {
        return isTokenWhitelisted[IERC20(address(0))];
    }
    function getUserTokens(address _user) external view returns (IERC20[] memory) {
        IERC20[] memory result = userTokens[_user];
        if (result.length == 0) {
            // default to baseToken
            result = new IERC20[](1);
            result[0] = baseToken;
        }
        return result;
    }
    function token() external view returns (IERC20) {
        return baseToken;
    }
    function _calculateVestedTokensAt(address user, IERC20 _token, uint256 blockNumber) internal view returns (uint256 result) {
        if (blockNumber < stakes[_token][user].depositBlock) {
            // ideally this should never happen but as a safety precaution..
            return 0;
        }

        return lerpValue(tokenVesting, blockNumber.sub(stakes[_token][user].depositBlock), stakes[_token][user].amount);
    }
    function getVestedTokensAtSnapshot(address user, IERC20 _token, uint256 blockNumber) external view returns (uint256) {
        // we don't enforce snapshots, to avoid breaking things completely in case of an issue
        //require(snapshotExists[blockNumber], "No snapshot exists for this block");

        // is the user snapshotted for this?
        if (lastSnapshotBlockNumbers[user] >= blockNumber) {
            // use the snapshot
            return snapshots[blockNumber][user][_token];
        }

        // no snapshot so we calculate the snapshot as it would have been at that time in the past
        return _calculateVestedTokensAt(user, _token, blockNumber);
    }
    function getVestedTokens(address user, IERC20 _token) external view returns (uint256) {
        return _calculateVestedTokensAt(user, _token, block.number);
    }
    function getWithdrawable(address user, IERC20 _token) public view returns (uint256) {
        return lerpValue(withdrawalVesting, block.number.sub(stakes[_token][user].withdrawBlock), stakes[_token][user].amount);
    }
    function getTotalStake(address user, IERC20 _token) public view returns (uint256) {
        return stakes[_token][user].amount;
    }
    function getEmergencyWithdrawPenalty(address user, IERC20 _token) external view returns (uint256) {
        // account for allowed withdrawal
        uint256 _amount = stakes[_token][user].amount;
        uint256 withdrawable = getWithdrawable(user, _token);
        if (_amount <= withdrawable) {
            return 0;
        }
        _amount = _amount.sub(withdrawable);
        return lerpValue(emergencyWithdrawPenaltyVesting, block.number.sub(stakes[_token][user].withdrawBlock), _amount);
    }
    function getVestedTokensPercentage(address user, IERC20 _token) public view returns (uint256) {
        return lerpValue(tokenVesting, block.number.sub(stakes[_token][user].depositBlock), INTERPOLATION_DIVISOR);
    }
    function getWithdrawablePercentage(address user, IERC20 _token) public view returns (uint256) {
        return lerpValue(withdrawalVesting, block.number.sub(stakes[_token][user].withdrawBlock), INTERPOLATION_DIVISOR);
    }
    function getEmergencyWithdrawPenaltyPercentage(address user, IERC20 _token) public view returns (uint256) {
        // We could account for allowed withdrawal here, but it is likely to cause confusion. It is accounted for elsewhere.
        uint rawValue = lerpValue(emergencyWithdrawPenaltyVesting, block.number.sub(stakes[_token][user].withdrawBlock), INTERPOLATION_DIVISOR);
        return rawValue;

        // IGNORED: adjust for allowed withdrawal
    }
    function getEmergencyWithdrawPenaltyAmountReturned(address user, IERC20 _token, uint256 _amount) public view returns (uint256) {
        // account for allowed withdrawal
        uint256 withdrawable = getWithdrawable(user, _token);
        if (_amount <= withdrawable) {
            return _amount;
        }
        _amount = _amount.sub(withdrawable);
        return _amount.sub(lerpValue(emergencyWithdrawPenaltyVesting, block.number.sub(stakes[_token][user].withdrawBlock), _amount)).add(withdrawable);
    }
}