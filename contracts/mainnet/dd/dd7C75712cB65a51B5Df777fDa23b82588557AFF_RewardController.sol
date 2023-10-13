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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

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
pragma solidity >=0.6.12;

interface IRebateEstimator {
    function getRebate(address account) external view returns (uint64);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IRewardController {
    function depositReward(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISnapshottable {
    function snapshot() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from './ISnapshottable.sol';

interface ITimeWeightedAveragePricer is ISnapshottable {
    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);

    /**
     * @dev Calculates the current price based on the stored samples.
     * @return The current price as a uint256.
     */
    function calculateToken0Price() external view returns (uint256);

    /**
     * @dev Returns the current price of token0, denominated in token1.
     * @return The current price as a uint256.
     */
    function getToken0Price() external view returns (uint256);

    /**
     * @dev Returns the current price of token1, denominated in token0.
     * @return The current price as a uint256.
     */
    function getToken1Price() external view returns (uint256);

    function getToken0Value(uint256 amount) external view returns (uint256);
    function getToken0ValueAtSnapshot(uint256 _blockNumber, uint256 amount) external view returns (uint256);

    function getToken1Value(uint256 amount) external view returns (uint256);

    /**
     * @dev Returns the block number of the oldest sample.
     * @return The block number of the oldest sample as a uint256.
     */
    function getOldestSampleBlock() external view returns (uint256);

    /**
     * @dev Returns the current price if the oldest sample is still considered fresh.
     * @return The current price as a uint256.
     */
    function getToken0FreshPrice() external view returns (uint256);

    /**
     * @dev Returns the current price if the oldest sample is still considered fresh.
     * @return The current price as a uint256.
     */
    function getToken1FreshPrice() external view returns (uint256);

    /**
     * @dev Returns the next sample index given the current index and sample count.
     * @param i The current sample index.
     * @param max The maximum number of samples.
     * @return The next sample index as a uint64.
     */
    function calculateNext(uint64 i, uint64 max) external pure returns (uint64);

    /**
     * @dev Returns the previous sample index given the current index and sample count.
     * @param i The current sample index.
     * @param max The maximum number of samples.
     * @return The previous sample index as a uint64.
     */
    function calculatePrev(uint64 i, uint64 max) external pure returns (uint64);

    /**
     * @dev Samples the current spot price of the token pair from all pools.
     * @return A boolean indicating whether the price was sampled or not.
     */
    function samplePrice() external returns (bool);

    /**
     * @dev Samples the current spot price of the token pair from all pools, throwing if the previous sample was too recent.
     */
    function enforcedSamplePrice() external;

    /**
     * @dev Calculates the spot price of the token pair from all pools.
     * @return The spot price as a uint256.
     */
    function calculateToken0SpotPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import '../oasis/interfaces/IRebateEstimator.sol';
import { IStakingPerTierController } from '../../staking/interfaces/IStakingPerTierController.sol';
import { ITimeWeightedAveragePricer } from './ITimeWeightedAveragePricer.sol';
import { ISnapshottable } from './ISnapshottable.sol';


struct RebateTier {
    uint256 value;
    uint64 rebate;
    uint24 dexShareFactor;
}


contract TierController is Ownable, IRebateEstimator, ISnapshottable {
    using SafeMath for uint256;

    uint24 public constant FACTOR_DIVISOR = 100000;

    IStakingPerTierController public staking;
    ITimeWeightedAveragePricer public pricer;
    RebateTier[] public rebateTiers;
    address public token;
    IRebateEstimator internal rebateAlternatives;

    mapping (address => bool) public isSnapshotter;


    constructor(
        address _token,
        address _staking,
        address _pricer,
        RebateTier[] memory _rebateTiers
    ) {
        token = _token;
        setPricer(ITimeWeightedAveragePricer(_pricer));
        setStaking(IStakingPerTierController(_staking));
        setTiers(_rebateTiers);
    }


    ///////////////////////////////////////
    // View functions
    ///////////////////////////////////////

    function tierToHumanReadable(RebateTier memory tier) public view returns (uint256[] memory output) {
        output = new uint256[](3);
        output[0] = uint256(tier.value).div(10**IERC20Metadata(address(pricer.token1())).decimals());
        output[1] = tier.rebate;
        output[2] = uint256(tier.dexShareFactor).div(10);
    }
    function getHumanReadableTiers() public view returns (uint256[][] memory output) {
        output = new uint256[][](uint256(rebateTiers.length));
        uint256 invI = 0;
        for (int256 i = int256(rebateTiers.length) - 1;  i >= 0;  --i) {
            output[invI] = tierToHumanReadable(rebateTiers[uint256(i)]);
            invI = invI.add(1);
        }
    }
    function getAllTiers() public view returns (RebateTier[] memory) {
        return rebateTiers;
    }
    function getTierCount() public view returns (uint8) {
        return uint8(rebateTiers.length);
    }
    function getUserTokenValue(address account) public view returns (uint256) {
        uint256 vestedTokens = staking.getVestedTokens(account);
        uint256 value = pricer.getToken0Value(vestedTokens);
        return value;
    }
    function getUserTokenValue(uint256 _blockNumber, address _account) public view returns (uint256) {
        uint256 _vestedTokens = staking.getVestedTokensAtSnapshot(_account, _blockNumber);
        uint256 _value = pricer.getToken0ValueAtSnapshot(_blockNumber, _vestedTokens);
        return _value;
    }
    function getHumanReadableTier(address account) public view returns (uint256, uint[] memory) {
        (uint256 i, RebateTier memory tier) = getTier(account);
        return (i, tierToHumanReadable(tier));
    }
    function getTier(address account) public view returns (uint8, RebateTier memory) {
        uint8 idx = getTierIdx(account);
        return (idx, rebateTiers[idx]);
    }
    function getTierIdx(address account) public view returns (uint8) {
        uint256 value = getUserTokenValue(account);
        uint8 len = uint8(rebateTiers.length);
        for (uint8 i = 0; i < len; i++) {
            if (value >= rebateTiers[i].value) {
                return i;
            }
        }

        // this should be logically impossible
        require(false, "TierController: no rebate tier applicable");
        return 0; // to make compiler happy
    }
    function getTierIdx(uint256 _blockNumber, address _account) public view returns (uint8) {
        uint256 value = getUserTokenValue(_blockNumber, _account);
        uint8 len = uint8(rebateTiers.length);
        for (uint8 i = 0; i < len; i++) {
            if (value >= rebateTiers[i].value) {
                return i;
            }
        }

        // this should be logically impossible
        require(false, "TierController: no rebate tier applicable");
        return 0; // to make compiler happy
    }
    function getDexShareFactor(address account) public view returns (uint24) {
        uint256 i;
        RebateTier memory tier;
        (i, tier) = getTier(account);
        return tier.dexShareFactor;
    }
    function getRebate(address account) external override view returns (uint64) {
        uint64 rebateAlternative = 0;
        if (address(rebateAlternatives) != address(0)) {
            rebateAlternative = rebateAlternatives.getRebate(account);
        }

        uint256 i;
        RebateTier memory tier;
        (i, tier) = getTier(account);

        return uint64(Math.max(tier.rebate, rebateAlternative));
    }


    ///////////////////////////////////////
    // Housekeeping
    ///////////////////////////////////////

    function snapshot() external onlySnapshotter override {
        pricer.snapshot();
        staking.snapshot();
    }
    function setSnapshotter(address _snapshotter, bool _state) external onlyOwner {
        isSnapshotter[_snapshotter] = _state;
    }
    modifier onlySnapshotter() {
        require(isSnapshotter[msg.sender], "Only snapshotter can call this function");
        _;
    }

    function setPricer(ITimeWeightedAveragePricer _pricer) public onlyOwner {
        require(address(_pricer) != address(0), "TierController: pricer contract cannot be 0x0");
        require(token == address(_pricer.token0()), "TierController: staking token mismatch 1");
        pricer = _pricer;
    }
    function setStaking(IStakingPerTierController _staking) public onlyOwner {
        require(address(_staking) != address(0), "TierController: staking contract cannot be 0x0");
        require(token == address(_staking.token()), "TierController: staking token mismatch 2");
        staking = _staking;
    }
    function setOwner(address _newOwner) external onlyOwner {
        transferOwnership(_newOwner);
    }
    function setRebateAlternatives(IRebateEstimator _rebateAlternatives) external onlyOwner {
        rebateAlternatives = _rebateAlternatives;
    }
    function setTiers(RebateTier[] memory _rebateTiers) public onlyOwner {
        require(_rebateTiers.length > 0, "TierController: rebate tiers list cannot be empty");
        require(_rebateTiers[_rebateTiers.length - 1].value == 0, "TierController: last rebate tier value must be 0");
        require(_rebateTiers.length < type(uint8).max, "TierController: rebate tiers list too long");
        require(_rebateTiers.length == rebateTiers.length || rebateTiers.length == 0, "TierController: can't change number of tiers");

        delete rebateTiers;
        for (uint256 i = 0; i < _rebateTiers.length; i++) {
            require(_rebateTiers[i].rebate <= 10000, "TierController: rebate must be 10000 or less");

            if (i > 0) {
                require(_rebateTiers[i].value < _rebateTiers[i.sub(1)].value, "TierController: rebate tiers list is not sorted in descending order");
            }
            require(_rebateTiers[i].dexShareFactor <= FACTOR_DIVISOR, "TierController: dex share factors must not exceed FACTOR_DIVISOR");

            // set inside loop because not supported by compiler to copy whole array in one
            rebateTiers.push(_rebateTiers[i]);
        }
        require(rebateTiers[0].dexShareFactor == FACTOR_DIVISOR, "TierController: dex share factors must max out at FACTOR_DIVISOR");
    }
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../../legacy/staking/ISnapshottable.sol';

pragma solidity ^0.8.0;

/**
 * @title IStakingPerRewardController
 * @dev Minimal interface for staking that RewardController requires
 */
interface IStakingPerRewardController {
    function getStakersCount() external view returns (uint256);
    function getStakers(uint256 idx) external view returns (address);
    function stakeFor(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ISnapshottable } from '../../legacy/staking/ISnapshottable.sol';

pragma solidity ^0.8.0;

/**
 * @title IStakingPerTierController
 * @dev Minimal interface for staking that TierController requires
 */
interface IStakingPerTierController is ISnapshottable {
    function getVestedTokens(address user) external view returns (uint256);
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256);
    function token() external view returns (IERC20);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { IERC20Metadata } from '@openzeppelin/contracts/interfaces/IERC20Metadata.sol';
import { SafeMath } from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import { TierController } from '../legacy/staking/TierController.sol';
import { IStakingPerRewardController } from './interfaces/IStakingPerRewardController.sol';
import { IRewardController } from '../legacy/staking/IRewardController.sol';


struct PhaseInfo {
    uint256 startBlock;
    uint256 endBlock;
    uint256 totalReward;
    uint256 claimedReward;
}


contract RewardController is Ownable, IRewardController {
    using SafeMath for uint256;

    // configuration
    IERC20Metadata immutable public token;
    TierController immutable public tierController;
    IStakingPerRewardController immutable public staking;
    uint256 public phaseLength;
    uint256 public expiryLength;
    address public expiryRecipient;

    // phase state
    PhaseInfo[] public phases;
    PhaseInfo public currentPhase;
    // phase => user => claimed
    mapping(uint256 => mapping(address => uint256)) public userRewardClaimed;
    // phase => tier => count
    mapping(uint256 => uint32[]) public tierCounts;
    // phase => tier => amount
    mapping(uint256 => uint256[]) public tierAmounts;

    // tier count state
    uint256 public defaultTierCountSteps = 100;
    uint256 public phaseBeingUpdated = 0;
    uint256 public nextAddressIdx;
    mapping(address => uint256) public addressCountedAtPhase;
    bool public updateDone = true;


    constructor(IERC20Metadata _token, TierController _tierController, IStakingPerRewardController _staking, uint256 _phaseLength, uint256 _expiryLength, address _expiryRecipient) {
        require(address(_token) != address(0), "Token address cannot be 0x0");
        token = _token;

        require(address(_tierController) != address(0), "TierController address cannot be 0x0");
        tierController = _tierController;

        require(address(_staking) != address(0), "Staking address cannot be 0x0");
        staking = _staking;

        setExpiryLength(_expiryLength);
        setPhaseLength(_phaseLength);
        setExpiryRecipient(_expiryRecipient);

        currentPhase.startBlock = block.number;
        
        // push a dummy phase to make the math easier
        phases.push(PhaseInfo(0, block.number, 0, 0));
    }


    ///////////////////////////////////////
    // Core functionality
    ///////////////////////////////////////

    function tryClosePhase() public returns (uint256, bool) {
        bool updateTriggered = false;
        if (updateDone && block.number >= currentPhase.startBlock.add(phaseLength)) {
            currentPhase.endBlock = block.number;
            phases.push(currentPhase);
            updateTriggered = true;

            currentPhase = PhaseInfo(block.number, 0, 0, 0);

            tierController.snapshot();

            // reset tier counting
            phaseBeingUpdated = phases.length.sub(1);
            nextAddressIdx = 0;
            updateDone = false;
        }

        trySummarizeTierCounts();

        return (phaseBeingUpdated, !updateTriggered); // return the 'current phase', and true if all is done (no update triggered)
    }
    function trySummarizeTierCounts() public returns (bool) {
        return _trySummarizeTierCounts(defaultTierCountSteps);
    }
    function _trySummarizeTierCounts(uint256 _tierCountSteps) public returns (bool) {
        if (updateDone) {
            return true; // signal we are done
        }

        // what is the total subscription to each tier?
        uint256 _end = nextAddressIdx+_tierCountSteps;
        uint256 _addressCount = staking.getStakersCount();
        uint8 _tierCount = tierController.getTierCount();
        uint256 i;
        uint32[] memory _tierAdditions = new uint32[](tierController.getTierCount());
        for (i = nextAddressIdx;  i < _end && i < _addressCount;  ++i) {
            address account = staking.getStakers(i);

            // prevent double counting
            if (addressCountedAtPhase[account] == phaseBeingUpdated) {
                continue;
            }
            addressCountedAtPhase[account] = phaseBeingUpdated;

            // account for this user
            uint256 userTier = tierController.getTierIdx(phases[phases.length-1].endBlock, account);
            for (uint256 j = userTier;  j < _tierCount;  ++j) {
                require(_tierAdditions[j] < type(uint32).max, "Tier count overflow");
                _tierAdditions[j] += 1;
            }
        }

        // save results
        uint32[] storage _innerTierCount = tierCounts[phaseBeingUpdated];
        for (uint256 tier = 0;  tier < _tierAdditions.length;  ++tier) {
            if (_innerTierCount.length <= tier) {
                _innerTierCount.push(_tierAdditions[tier]);
            } else if (_tierAdditions[tier] > 0) {
                require(uint256(_innerTierCount[tier]).add(_tierAdditions[tier]) < type(uint32).max, "Tier count overflow 2");
                _innerTierCount[tier] += _tierAdditions[tier];
            }
        }
        nextAddressIdx = i;
        // did we finish?
        updateDone = i >= _addressCount;

        if (updateDone) {
            setTierAmounts();
        }

        return updateDone;
    }
    function setTierAmounts() internal {
        require(updateDone, "Cannot set tier amounts while updating");

        // calculate passforward per tier first
        uint256 _totalAmount = phases[phaseBeingUpdated].totalReward;
        uint256 passforwardAmountPerTier = 0;
        uint8 _tierCount = tierController.getTierCount();
        require(_tierCount > 0, "There has to be tiers");
        uint24 _FACTOR_DIVISOR = tierController.FACTOR_DIVISOR();
        uint24 _lastDexShareFactor = _FACTOR_DIVISOR;

        // calculate how much a user is owed based on their share of the tiers
        uint256 _passforwardAmount = 0;
        uint8 _lastPassforwardTier = 0;
        uint256[] storage _tierAmountsSub = tierAmounts[phaseBeingUpdated];
        require(_tierCount > 0, "There has to be tiers");
        while (_tierAmountsSub.length < _tierCount) {
            _tierAmountsSub.push(0);
        }

        for (uint8 _tier = 0;  _tier < uint256(_tierCount).sub(1);  ++_tier) {
            uint32 _usersAtTier = tierCounts[phaseBeingUpdated][_tier];

            uint24 _nextDexShareFactor;
            { // stack depth
                uint256 _discardedA;
                uint64 _discardedB;
                (_discardedA, _discardedB, _nextDexShareFactor) = tierController.rebateTiers(uint256(_tier).add(1));
            }
            uint256 _tierAmount = _totalAmount.mul(_lastDexShareFactor - _nextDexShareFactor).div(_FACTOR_DIVISOR);
            _lastDexShareFactor = _nextDexShareFactor;

            // if nobody is at this tier, then everyone below a share of that reward
            if (_usersAtTier == 0) {
                _passforwardAmount = _passforwardAmount.add(_tierAmount);
                _lastPassforwardTier = _tier;
                if (uint256(_lastPassforwardTier).add(2) != _tierCount) { // prevent div-by-zero
                    passforwardAmountPerTier = _passforwardAmount.div(uint256(_tierCount).sub(uint256(_lastPassforwardTier).add(2)));
                }

                // store result
                _tierAmountsSub[_tier] = 0;
            } else {
                // calculate and store the amount for this tier
                uint256  _tierAmountWithPassforward = _tierAmount.add(passforwardAmountPerTier);
                _tierAmountsSub[_tier] = _tierAmountWithPassforward.div(_usersAtTier);
            }
        }
    }
    function depositReward(uint256 amount) external {
        tryClosePhase();

        if (amount == 0) {
            return;
        }

        SafeERC20.safeTransferFrom(token, msg.sender, address(this), amount);
        currentPhase.totalReward = currentPhase.totalReward.add(amount);
    }
    function claimRewards(bool _withdrawIfTrue) external returns (uint256) {
        tryClosePhase();

        // iterate backwards over all phases
        uint256 totalReward = 0;
        for (uint256 i = phases.length;  i > 0;  i--) {
            // if the phase has expired, end loop
            if (isPhaseExpired(i - 1)) {
                break;
            }

            totalReward += claimRewardForPhase(i - 1, _withdrawIfTrue);
        }

        return totalReward;
    }
    function claimRewardForPhase(uint256 _phaseIdx, bool _withdrawIfTrue) public returns (uint256) {
        PhaseInfo storage phase = phases[_phaseIdx];

        // how much is the user eligible for?
        uint256 userReward = getEligibleRewardForPhase(_phaseIdx, msg.sender);
        if (userReward == 0) {
            return 0; // early abort
        }

        mapping(address => uint256) storage _userRewardClaimed = userRewardClaimed[_phaseIdx];
        userReward = userReward.sub(_userRewardClaimed[msg.sender]);
        if (userReward == 0) {
            return 0;
        }
        if (userReward > phase.totalReward.sub(phase.claimedReward)) {
            // this should never happen, but just in case
            userReward = phase.totalReward.sub(phase.claimedReward);
        }


        // send the user their reward
        _userRewardClaimed[msg.sender] = _userRewardClaimed[msg.sender].add(userReward);
        phase.claimedReward = phase.claimedReward.add(userReward);
        require(phase.claimedReward <= phase.totalReward, "Claimed too much");
        // allow reinvest as default, withdraw as an option
        if (_withdrawIfTrue) {
            SafeERC20.safeTransfer(token, msg.sender, userReward);
        } else {
            IERC20(token).approve(address(staking), userReward);
            staking.stakeFor(msg.sender, userReward);
        }

        return userReward;
    }
    function getEligibleRewardForPhase(uint256 _phaseIdx, address _account) public view returns (uint256) {
        if (_phaseIdx == 0) {
            return 0; // no rewards for the dummy phase
        }

        // only claim for phases we have the tiers for
        if (_phaseIdx > phaseBeingUpdated || (_phaseIdx == phaseBeingUpdated && !updateDone)) {
            return 0; // not yet finalized
        }

        // there's no reward if the phase is expired
        if (isPhaseExpired(_phaseIdx)) {
            return 0;
        }

        // calculate how much a user is owed based on their share of the tiers
        uint8 _userTier = tierController.getTierIdx(phases[_phaseIdx].endBlock, _account);
        uint8 _tierCount = tierController.getTierCount();
        uint256 _userAmount = 0;
        for (uint8 _tier = 0;  _tierCount > _tier;  ++_tier) {
            if (_tier < _userTier) {
                continue; // user isn't at this tier, skip further processing
            }

            // if the user is at this tier, then they get a share of that reward
            _userAmount = _userAmount.add(tierAmounts[_phaseIdx][_tier]);
        }

        return _userAmount.sub(userRewardClaimed[_phaseIdx][_account]);
    }
    function reclaimExpiredRewards() external returns (uint256) {
        require(expiryRecipient != address(0), "No expiry recipient set");

        // iterate over phases
        uint256 _result = 0;
        for (uint256 _phaseIdx = 0;  _phaseIdx < phases.length;  ++_phaseIdx) {
            if (!isPhaseExpired(_phaseIdx)) {
                continue;
            }

            PhaseInfo storage phase = phases[_phaseIdx];
            uint256 _amount = phase.totalReward.sub(phase.claimedReward);
            if (_amount > 0) {
                _result = _result.add(_amount);
                phase.claimedReward = phase.claimedReward.add(_amount);
                SafeERC20.safeTransfer(token, expiryRecipient, _amount);
            }
        }

        return _result;
    }


    ///////////////////////////////////////
    // View functions
    ///////////////////////////////////////

    function blocksUntilNextPhase() public view returns (uint256) {
        uint256 blocksSinceLastPhase = uint256(block.number).sub(getLastPhaseStart());
        if (blocksSinceLastPhase >= phaseLength) {
            return 0;
        } else {
            return phaseLength.sub(blocksSinceLastPhase);
        }
    }
    function getPastPhaseTotalReward() external view returns (uint256) {
        // get all rewards ever
        uint256 _result = 0;
        for (uint256 i = 0; i < phases.length; i++) {
            _result = _result.add(phases[i].totalReward);
        }
        return _result;
    }
    function getNextPhaseEstimatedReward() external view returns (uint256) {
        // get estimated total reward from next phase

        // is the phase done?
        if (getLastPhaseStart().add(phaseLength) <= block.number) {
            return currentPhase.totalReward;
        }

        if (block.number == getLastPhaseStart()) {
            return 0; // prevent divide by zero
        }

        // calculate the estimated reward
        return currentPhase.totalReward.mul(phaseLength).div(block.number.sub(getLastPhaseStart()));
    }
    function getClaimableRewardUser(address account) external view returns (uint256) {
        // get user available reward from finished phases
        uint256 _result = 0;
        for (uint256 _phaseIdx = 0;  _phaseIdx < phases.length;  ++_phaseIdx) {
            _result = _result.add(getEligibleRewardForPhase(_phaseIdx, account));
        }
        return _result;
    }
    function getPastPhaseTotalRewardUser(address account) external view returns (uint256) {
        // get all rewards ever for a specific address
        uint256 _result = 0;
        for (uint256 _phaseIdx = 0;  _phaseIdx < phases.length;  ++_phaseIdx) {
            _result = _result.add(userRewardClaimed[_phaseIdx][account]);
        }
        return _result;
    }
    function getPhaseCount() external view returns (uint256) {
        return phases.length;
    }
    function getLastPhaseStart() public view returns (uint256) {
        return currentPhase.startBlock;
    }


    ///////////////////////////////////////
    // Housekeeping
    ///////////////////////////////////////

    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner cannot be 0x0");

        transferOwnership(_newOwner);
    }
    function setPhaseLength(uint256 _phaseLength) public onlyOwner {
        require(_phaseLength > 0, "Phase length must be greater than 0");
        require(block.number > _phaseLength, 'Phase length too long');
        require(expiryLength > _phaseLength, 'Phase length longer than expiry length');
        phaseLength = _phaseLength;
    }
    function setExpiryLength(uint256 _expiryLength) public onlyOwner {
        require(block.number > _expiryLength, 'Expiry length too long');
        require(_expiryLength > phaseLength, 'Phase length longer than expiry length');
        expiryLength = _expiryLength;
    }
    function setExpiryRecipient(address _expiryRecipient) public onlyOwner {
        require(_expiryRecipient != address(0), "Expiry recipient cannot be 0x0");
        expiryRecipient = _expiryRecipient;
    }
    function setDefaultTierCountSteps(uint256 _defaultTierCountSteps) public onlyOwner {
        defaultTierCountSteps = _defaultTierCountSteps;
    }
    function isPhaseExpired(uint256 _phaseIdx) public view returns (bool) {
        return phases[_phaseIdx].endBlock.add(expiryLength) <= block.number;
    }
}