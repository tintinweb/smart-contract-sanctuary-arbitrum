// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract ComptrollerInterface {
    /// @notice Indicator that this is a Comptroller contract (for inspection)
    bool public constant isComptroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) virtual external returns (uint[] memory);
    function exitMarket(address cToken) virtual external returns (uint);

    /*** Policy Hooks ***/

    function mintAllowed(address cToken, address minter, uint mintAmount) virtual external returns (uint);
    function mintVerify(address cToken, address minter, uint mintAmount, uint mintTokens) virtual external;

    function redeemAllowed(address cToken, address redeemer, uint redeemTokens) virtual external returns (uint);
    function redeemVerify(address cToken, address redeemer, uint redeemAmount, uint redeemTokens) virtual external;

    function borrowAllowed(address cToken, address borrower, uint borrowAmount) virtual external returns (uint);
    function borrowVerify(address cToken, address borrower, uint borrowAmount) virtual external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint repayAmount,
        uint borrowerIndex) virtual external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount) virtual external returns (uint);
    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount,
        uint seizeTokens) virtual external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external returns (uint);
    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint seizeTokens) virtual external;

    function transferAllowed(address cToken, address src, address dst, uint transferTokens) virtual external returns (uint);
    function transferVerify(address cToken, address src, address dst, uint transferTokens) virtual external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint repayAmount) virtual external view returns (uint, uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./ComptrollerInterface.sol";
import "./InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";

contract CTokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-cToken operations
     */
    ComptrollerInterface public comptroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint public totalSupply;

    // Official record of token balances for each account
    mapping (address => uint) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping (address => mapping (address => uint)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint principal;
        uint interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract CTokenInterface is CTokenStorage {
    /**
     * @notice Indicator that this is a CToken contract (for inspection)
     */
    bool public constant isCToken = true;


    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint cashPrior, uint interestAccumulated, uint borrowIndex, uint totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint mintAmount, uint mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint redeemAmount, uint redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint borrowAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint repayAmount, uint accountBorrows, uint totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint repayAmount, address cTokenCollateral, uint seizeTokens);


    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(ComptrollerInterface oldComptroller, ComptrollerInterface newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint oldReserveFactorMantissa, uint newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint addAmount, uint newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint reduceAmount, uint newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint amount);


    /*** User Interface ***/

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);
    function approve(address spender, uint amount) virtual external returns (bool);
    function allowance(address owner, address spender) virtual external view returns (uint);
    function balanceOf(address owner) virtual external view returns (uint);
    function balanceOfUnderlying(address owner) virtual external returns (uint);
    function getAccountSnapshot(address account) virtual external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() virtual external view returns (uint);
    function supplyRatePerBlock() virtual external view returns (uint);
    function totalBorrowsCurrent() virtual external returns (uint);
    function borrowBalanceCurrent(address account) virtual external returns (uint);
    function borrowBalanceStored(address account) virtual external view returns (uint);
    function exchangeRateCurrent() virtual external returns (uint);
    function exchangeRateStored() virtual external view returns (uint);
    function getCash() virtual external view returns (uint);
    function accrueInterest() virtual external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) virtual external returns (uint);


    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) virtual external returns (uint);
    function _acceptAdmin() virtual external returns (uint);
    function _setComptroller(ComptrollerInterface newComptroller) virtual external returns (uint);
    function _setReserveFactor(uint newReserveFactorMantissa) virtual external returns (uint);
    function _reduceReserves(uint reduceAmount) virtual external returns (uint);
    function _setInterestRateModel(InterestRateModel newInterestRateModel) virtual external returns (uint);
}

contract CErc20Storage {
    /**
     * @notice Underlying asset for this CToken
     */
    address public underlying;
}

abstract contract CErc20Interface is CErc20Storage {

    /*** User Interface ***/

    function mint(uint mintAmount) virtual external returns (uint);
    function redeem(uint redeemTokens) virtual external returns (uint);
    function redeemUnderlying(uint redeemAmount) virtual external returns (uint);
    function borrow(uint borrowAmount) virtual external returns (uint);
    function repayBorrow(uint repayAmount) virtual external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) virtual external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) virtual external returns (uint);
    function sweepToken(EIP20NonStandardInterface token) virtual external;


    /*** Admin Functions ***/

    function _addReserves(uint addAmount) virtual external returns (uint);
}

contract CDelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract CDelegatorInterface is CDelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(address implementation_, bool allowResign, bytes memory becomeImplementationData) virtual external;
}

abstract contract CDelegateInterface is CDelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) virtual external;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() virtual external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      */
    function transferFrom(address src, address dst, uint256 amount) external;

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      * @return success Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return remaining The number of tokens allowed to be spent
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract ComptrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
      * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
      * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
      **/
    event Failure(uint error, uint info, uint detail);

    /**
      * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
      */
    function fail(Error err, FailureInfo info) internal returns (uint) {
        emit Failure(uint(err), uint(info), 0);

        return uint(err);
    }

    /**
      * @dev use this when reporting an opaque error from an upgradeable collaborator contract
      */
    function failOpaque(Error err, FailureInfo info, uint opaqueError) internal returns (uint) {
        emit Failure(uint(err), uint(info), opaqueError);

        return uint(err);
    }
}

contract TokenErrorReporter {
    uint public constant NO_ERROR = 0; // support legacy return codes

    error TransferComptrollerRejection(uint256 errorCode);
    error TransferNotAllowed();
    error TransferNotEnough();
    error TransferTooMuch();

    error MintComptrollerRejection(uint256 errorCode);
    error MintFreshnessCheck();

    error RedeemComptrollerRejection(uint256 errorCode);
    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();

    error BorrowComptrollerRejection(uint256 errorCode);
    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowComptrollerRejection(uint256 errorCode);
    error RepayBorrowFreshnessCheck();

    error LiquidateComptrollerRejection(uint256 errorCode);
    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();
    error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

    error LiquidateSeizeComptrollerRejection(uint256 errorCode);
    error LiquidateSeizeLiquidatorIsBorrower();

    error AcceptAdminPendingAdminCheck();

    error SetComptrollerOwnerCheck();
    error SetPendingAdminOwnerCheck();

    error SetReserveFactorAdminCheck();
    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesAdminCheck();
    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelOwnerCheck();
    error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
  * @title Compound's InterestRateModel Interface
  * @author Compound
  */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
      * @notice Calculates the current borrow interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @return The borrow rate per block (as a percentage, and scaled by 1e18)
      */
    function getBorrowRate(uint cash, uint borrows, uint reserves) virtual external view returns (uint);

    /**
      * @notice Calculates the current supply interest rate per block
      * @param cash The total amount of cash the market has
      * @param borrows The total amount of borrows the market has outstanding
      * @param reserves The total amount of reserves the market has
      * @param reserveFactorMantissa The current reserve factor the market has
      * @return The supply rate per block (as a percentage, and scaled by 1e18)
      */
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) virtual external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBathBuddy {
    /// @notice Releases the withdrawer's relative share of all vested tokens directly to them with their withdrawal
    /// @dev function that only the single, permissioned bathtoken can call that rewards a user their accrued rewards
    ///            for a given token during the current rewards period ongoing on bathBuddy
    function getReward(IERC20 token, address recipient) external;

    // Determines a user rewards
    // Note, uses share logic from bathToken
    function earned(address account, address token)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBathToken is IERC20 {
    function removeFilledTradeAmount(uint256 amt) external;

    function cancel(uint256 id, uint256 amt) external;

    function placeOffer(
        uint256 pay_amt,
        IERC20 pay_gem,
        uint256 buy_amt,
        IERC20 buy_gem
    ) external returns (uint256);

    function rebalance(
        address destination,
        address filledAssetToRebalance,
        uint256 stratTakeProportion,
        uint256 rebalAmt
    ) external;

    function approveMarket() external;

    function asset() external view returns (address assetTokenAddress); //4626

    // Storage var that hold rewards tokens
    function bathBuddy() external view returns (address);

    function setBathBuddy(address newBathHouse) external;

    function underlyingToken() external returns (IERC20 erc20);

    function bathHouse() external returns (address admin);

    function setBathHouse(address newBathHouse) external;

    function setMarket(address newRubiconMarket) external;

    function setBonusToken(address newBonusToken) external;

    function setFeeBPS(uint256 _feeBPS) external;

    function setFeeTo(address _feeTo) external;

    function RubiconMarketAddress() external returns (address market);

    function outstandingAmount() external returns (uint256 amount);

    function underlyingBalance() external view returns (uint256);

    function deposit(uint256 amount) external returns (uint256 shares);

    function deposit(uint256 assets, address receiver)
        external
        returns (uint256 shares);

    function withdraw(uint256 shares) external returns (uint256 amount);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

interface IWETH {
    function allowance(address from, address to) external view returns(uint256);
    
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function approve(address guy, uint256 wad) external returns (bool);
}

/// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title RubiconMarket.sol
/// @notice Please see the repository for this code at https://github.com/RubiconDeFi/rubicon-protocol-v1;
/// @notice This contract is a derivative work, and spiritual continuation, of the open-source work from Oasis DEX: https://github.com/OasisDEX/oasis

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice DSAuth events for authentication schema
contract DSAuthEvents {
    /// event LogSetAuthority(address indexed authority); /// TODO: this event is not used in the contract, remove?
    event LogSetOwner(address indexed owner);
}

/// @notice DSAuth library for setting owner of the contract
/// @dev Provides the auth modifier for authenticated function calls
contract DSAuth is DSAuthEvents {
    address public owner;

    function setOwner(address owner_) external auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    modifier auth() {
        require(isAuthorized(msg.sender), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src) internal view returns (bool) {
        if (src == owner) {
            return true;
        } else {
            return false;
        }
    }
}

/// @notice DSMath library for safe math without integer overflow/underflow
contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}

/// @notice Events contract for logging trade activity on Rubicon Market
/// @dev Provides the key event logs that are used in all core functionality of exchanging on the Rubicon Market
contract EventfulMarket {
    event LogItemUpdate(uint256 id);

    /// TODO: double check it is sound logic to kill this event
    /// event LogTrade(
    ///     uint256 pay_amt,
    ///     address indexed pay_gem,
    ///     uint256 buy_amt,
    ///     address indexed buy_gem
    /// );

    /// event LogMake(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     uint128 pay_amt,
    ///     uint128 buy_amt,
    ///     uint64 timestamp
    /// );

    event emitOffer(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt
    );

    /// TODO: double check it is sound logic to kill this event
    /// event LogBump(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     uint128 pay_amt,
    ///     uint128 buy_amt,
    ///     uint64 timestamp
    /// );

    /// event LogTake(
    ///     bytes32 id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     address indexed taker,
    ///     uint128 take_amt,
    ///     uint128 give_amt,
    ///     uint64 timestamp
    /// );

    event emitTake(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        address taker,
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint128 take_amt,
        uint128 give_amt
    );

    /// event LogKill(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     address indexed maker,
    ///     IERC20 pay_gem,
    ///     IERC20 buy_gem,
    ///     uint128 pay_amt,
    ///     uint128 buy_amt,
    ///     uint64 timestamp
    /// );

    event emitCancel(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker,
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint128 pay_amt,
        uint128 buy_amt
    );

    /// TODO: double check it is sound logic to kill this event
    /// event LogInt(string lol, uint256 input);

    /// event FeeTake(
    ///     bytes32 indexed id,
    ///     bytes32 indexed pair,
    ///     IERC20 asset,
    ///     address indexed taker,
    ///     address feeTo,
    ///     uint256 feeAmt,
    ///     uint64 timestamp
    /// );

    /// TODO: we will need to make sure this emit is included in any taker pay maker scenario
    event emitFee(
        bytes32 indexed id,
        address indexed taker,
        address indexed feeTo,
        bytes32 pair,
        IERC20 asset,
        uint256 feeAmt
    );

    /// event OfferDeleted(bytes32 indexed id);

    event emitDelete(
        bytes32 indexed id,
        bytes32 indexed pair,
        address indexed maker
    );
}

/// @notice Core trading logic for ERC-20 pairs, an orderbook, and transacting of tokens
/// @dev This contract holds the core ERC-20 / ERC-20 offer, buy, and cancel logic
contract SimpleMarket is EventfulMarket, DSMath {
    using SafeERC20 for IERC20;

    uint256 public last_offer_id;

    /// @dev The mapping that makes up the core orderbook of the exchange
    mapping(uint256 => OfferInfo) public offers;

    bool locked;

    /// @dev This parameter is in basis points
    uint256 internal feeBPS;

    /// @dev This parameter provides the address to which fees are sent
    address internal feeTo;

    bytes32 internal constant MAKER_FEE_SLOT = keccak256("WOB_MAKER_FEE");

    struct OfferInfo {
        uint256 pay_amt;
        IERC20 pay_gem;
        uint256 buy_amt;
        IERC20 buy_gem;
        address recipient;
        uint64 timestamp;
        address owner;
    }

    /// @notice Modifier that insures an order exists and is properly in the orderbook
    modifier can_buy(uint256 id) virtual {
        require(isActive(id));
        _;
    }

    // /// @notice Modifier that checks the user to make sure they own the offer and its valid before they attempt to cancel it
    modifier can_cancel(uint256 id) virtual {
        require(isActive(id));
        require(
            (msg.sender == getOwner(id)) ||
                (msg.sender == getRecipient(id) && getOwner(id) == address(0))
        );
        _;
    }

    modifier can_offer() virtual {
        _;
    }

    modifier synchronized() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    /// @notice get makerFee value
    function makerFee() public view returns (uint256) {
        return StorageSlot.getUint256Slot(MAKER_FEE_SLOT).value;
    }

    function isActive(uint256 id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function getOwner(uint256 id) public view returns (address owner) {
        return offers[id].owner;
    }

    function getRecipient(uint256 id) public view returns (address owner) {
        return offers[id].recipient;
    }

    function getOffer(
        uint256 id
    ) public view returns (uint256, IERC20, uint256, IERC20) {
        OfferInfo memory _offer = offers[id];
        return (_offer.pay_amt, _offer.pay_gem, _offer.buy_amt, _offer.buy_gem);
    }

    /// @notice Accept a given `quantity` of an offer. Transfers funds from caller/taker to offer maker, and from market to caller/taker.
    /// @notice The fee for taker trades is paid in this function.
    function buy(
        uint256 id,
        uint256 quantity
    ) public virtual can_buy(id) synchronized returns (bool) {
        OfferInfo memory _offer = offers[id];
        uint256 spend = mul(quantity, _offer.buy_amt) / _offer.pay_amt;

        require(uint128(spend) == spend, "spend is not an int");
        require(uint128(quantity) == quantity, "quantity is not an int");

        ///@dev For backwards semantic compatibility.
        if (
            quantity == 0 ||
            spend == 0 ||
            quantity > _offer.pay_amt ||
            spend > _offer.buy_amt
        ) {
            return false;
        }

        offers[id].pay_amt = sub(_offer.pay_amt, quantity);
        offers[id].buy_amt = sub(_offer.buy_amt, spend);

        /// @dev Fee logic added on taker trades
        uint256 fee = mul(spend, feeBPS) / 100_000;

        _offer.buy_gem.safeTransferFrom(msg.sender, feeTo, fee);

        // taker pay maker 0_0
        if (makerFee() > 0) {
            uint256 mFee = mul(spend, makerFee()) / 100_000;

            /// @dev Handle the v1 -> v2 migration case where if owner == address(0) we transfer this fee to _offer.recipient
            if (_offer.owner == address(0) && getRecipient(id) != address(0)) {
                _offer.buy_gem.safeTransferFrom(
                    msg.sender,
                    _offer.recipient,
                    mFee
                );
            } else {
                _offer.buy_gem.safeTransferFrom(msg.sender, _offer.owner, mFee);
            }

            emit emitFee(
                bytes32(id),
                msg.sender,
                _offer.owner,
                keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
                _offer.buy_gem,
                mFee
            );
        }
        _offer.buy_gem.safeTransferFrom(msg.sender, _offer.recipient, spend);

        _offer.pay_gem.safeTransfer(msg.sender, quantity);

        emit LogItemUpdate(id);

        /// emit LogTake(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
        ///     _offer.owner,
        ///     _offer.pay_gem,
        ///     _offer.buy_gem,
        ///     msg.sender,
        ///     uint128(quantity),
        ///     uint128(spend),
        ///     uint64(block.timestamp)
        /// );

        emit emitTake(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner != address(0) ? _offer.owner : _offer.recipient,
            msg.sender,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(quantity),
            uint128(spend)
        );

        /// emit FeeTake(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
        ///     _offer.buy_gem,
        ///     msg.sender,
        ///     feeTo,
        ///     fee,
        ///     uint64(block.timestamp)
        /// );

        emit emitFee(
            bytes32(id),
            msg.sender,
            feeTo,
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.buy_gem,
            fee
        );

        /// TODO: double check it is sound logic to kill this event
        /// emit LogTrade(
        ///     quantity,
        ///     address(_offer.pay_gem),
        ///     spend,
        ///     address(_offer.buy_gem)
        /// );

        if (offers[id].pay_amt == 0) {
            delete offers[id];
            /// emit OfferDeleted(bytes32(id));

            emit emitDelete(
                bytes32(id),
                keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
                _offer.owner != address(0) ? _offer.owner : _offer.recipient
            );
        }

        return true;
    }

    /// @notice Allows the caller to cancel the offer if it is their own.
    /// @notice This function refunds the offer to the maker.
    function cancel(
        uint256 id
    ) public virtual can_cancel(id) synchronized returns (bool success) {
        OfferInfo memory _offer = offers[id];
        delete offers[id];

        /// @dev V1 orders after V2 upgrade will point to address(0) in owner
        _offer.owner == address(0)
            ? _offer.pay_gem.safeTransfer(_offer.recipient, _offer.pay_amt)
            : _offer.pay_gem.safeTransfer(_offer.owner, _offer.pay_amt);

        emit LogItemUpdate(id);
        /// emit LogKill(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
        ///     _offer.owner,
        ///     _offer.pay_gem,
        ///     _offer.buy_gem,
        ///     uint128(_offer.pay_amt),
        ///     uint128(_offer.buy_amt)
        /// );

        emit emitCancel(
            bytes32(id),
            keccak256(abi.encodePacked(_offer.pay_gem, _offer.buy_gem)),
            _offer.owner != address(0) ? _offer.owner : _offer.recipient,
            _offer.pay_gem,
            _offer.buy_gem,
            uint128(_offer.pay_amt),
            uint128(_offer.buy_amt)
        );

        success = true;
    }

    /// @notice Key function to make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 pay_amt,
        IERC20 pay_gem,
        uint256 buy_amt,
        IERC20 buy_gem,
        address owner,
        address recipient
    ) public virtual can_offer synchronized returns (uint256 id) {
        require(uint128(pay_amt) == pay_amt);
        require(uint128(buy_amt) == buy_amt);
        require(pay_amt > 0);
        require(pay_gem != IERC20(address(0))); /// @dev Note, modified from: require(pay_gem != IERC20(0x0)) which compiles in 0.7.6
        require(buy_amt > 0);
        require(buy_gem != IERC20(address(0))); /// @dev Note, modified from: require(buy_gem != IERC20(0x0)) which compiles in 0.7.6
        require(pay_gem != buy_gem);
        require(owner != address(0), "Zero owner address");
        require(recipient != address(0), "Zero recipient address");

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.recipient = recipient;
        info.owner = owner;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        pay_gem.safeTransferFrom(msg.sender, address(this), pay_amt);

        emit LogItemUpdate(id);

        /// emit LogMake(
        ///     bytes32(id),
        ///     keccak256(abi.encodePacked(pay_gem, buy_gem)),
        ///     msg.sender,
        ///     pay_gem,
        ///     buy_gem,
        ///     uint128(pay_amt),
        ///     uint128(buy_amt),
        ///     uint64(block.timestamp)
        /// );

        emit emitOffer(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt)
        );
    }

    function _next_id() internal returns (uint256) {
        last_offer_id++;
        return last_offer_id;
    }

    // Fee logic
    function getFeeBPS() public view returns (uint256) {
        return feeBPS;
    }
}

/// @notice Expiring market is a Simple Market with a market lifetime.
/// @dev When the close_time has been reached, offers can only be cancelled (offer and buy will throw).
contract ExpiringMarket is DSAuth, SimpleMarket {
    bool public stopped;

    /// @dev After close_time has been reached, no new offers are allowed.
    modifier can_offer() override {
        require(!isClosed());
        _;
    }

    /// @dev After close, no new buys are allowed.
    modifier can_buy(uint256 id) override {
        require(isActive(id));
        require(!isClosed());
        _;
    }

    /// @dev After close, anyone can cancel an offer.
    modifier can_cancel(uint256 id) virtual override {
        require(isActive(id));
        require(
            (msg.sender == getOwner(id)) ||
                isClosed() ||
                (msg.sender == getRecipient(id) && getOwner(id) == address(0))
        );
        _;
    }

    function isClosed() public pure returns (bool closed) {
        return false;
    }

    function getTime() public view returns (uint64) {
        return uint64(block.timestamp);
    }

    function stop() external auth {
        stopped = true;
    }
}

contract DSNote {
    event LogNote(
        bytes4 indexed sig,
        address indexed guy,
        bytes32 indexed foo,
        bytes32 indexed bar,
        uint256 wad,
        bytes fax
    ) anonymous;

    modifier note() {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);

        _;
    }
}

contract MatchingEvents {
    /// event LogBuyEnabled(bool isEnabled); /// TODO: this event is not used in the contract, remove?
    event LogMinSell(address pay_gem, uint256 min_amount);
    /// event LogMatchingEnabled(bool isEnabled); /// TODO: this event is not used in the contract, remove?
    event LogUnsortedOffer(uint256 id);
    event LogSortedOffer(uint256 id);
    /// event LogInsert(address keeper, uint256 id); /// TODO: this event is not used in the contract, remove?
    event LogDelete(address keeper, uint256 id);
    event LogMatch(uint256 id, uint256 amount);
}

/// @notice The core Rubicon Market smart contract
/// @notice This contract is based on the original open-source work done by OasisDEX under the Apache License 2.0
/// @dev This contract inherits the key trading functionality from SimpleMarket
contract RubiconMarket is MatchingEvents, ExpiringMarket, DSNote {
    bool public buyEnabled = true; //buy enabled TODO: review this decision!
    bool public matchingEnabled = true; //true: enable matching,

    /// @dev Below is variable to allow for a proxy-friendly constructor
    bool public initialized;

    /// @dev unused deprecated variable for applying a token distribution on top of a trade
    bool public AqueductDistributionLive;
    /// @dev unused deprecated variable for applying a token distribution of this token on top of a trade
    address public AqueductAddress;

    struct sortInfo {
        uint256 next; //points to id of next higher offer
        uint256 prev; //points to id of previous lower offer
        uint256 delb; //the blocknumber where this entry was marked for delete
    }
    mapping(uint256 => sortInfo) public _rank; //doubly linked lists of sorted offer ids
    mapping(address => mapping(address => uint256)) public _best; //id of the highest offer for a token pair
    mapping(address => mapping(address => uint256)) public _span; //number of offers stored for token pair in sorted orderbook
    mapping(address => uint256) public _dust; //minimum sell amount for a token to avoid dust offers
    mapping(uint256 => uint256) public _near; //next unsorted offer id
    uint256 public _head; //first unsorted offer id
    uint256 public dustId; // id of the latest offer marked as dust

    // *** MAPPING TO CHECK POTENTIALLY BLACKLISTED TOKENS ***
    mapping(address => bool) public tokenRequiresBlacklistCheck;

    /// @dev Proxy-safe initialization of storage
    function initialize(address _feeTo) public {
        require(!initialized, "contract is already initialized");
        require(_feeTo != address(0));

        /// @notice The market fee recipient
        feeTo = _feeTo;

        owner = msg.sender;
        emit LogSetOwner(msg.sender);

        /// @notice The starting fee on taker trades in basis points
        feeBPS = 1;

        initialized = true;
        matchingEnabled = true;
        buyEnabled = true;
    }

    // // After close, anyone can cancel an offer
    modifier can_cancel(uint256 id) override {
        require(isActive(id), "Offer was deleted or taken, or never existed.");
        require(
            isClosed() ||
                msg.sender == getOwner(id) ||
                id == dustId ||
                (msg.sender == getRecipient(id) && getOwner(id) == address(0)),
            "Offer can not be cancelled because user is not owner, and market is open, and offer sells required amount of tokens."
        );
        _;
    }

    // ---- Public entrypoints ---- //
    // simplest offer entry-point
    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem //maker (ask) buy which token
    ) public can_offer returns (uint256) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                0,
                true,
                msg.sender,
                msg.sender
            );
    }

    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint pos, //position to insert offer, 0 should be used if unknown
        bool rounding
    ) external can_offer returns (uint256) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                pos,
                rounding,
                msg.sender,
                msg.sender
            );
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        address owner,
        address recipient
    ) external can_offer returns (uint256) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                pos,
                true,
                owner,
                recipient
            );
    }

    function offer(
        uint256 pay_amt,
        IERC20 pay_gem,
        uint256 buy_amt,
        IERC20 buy_gem,
        address owner,
        address recipient
    ) public override can_offer returns (uint) {
        return
            offer(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                0,
                true,
                owner,
                recipient
            );
    }

    function setTokenRequiresBlacklistCheck(
        address token,
        bool requiresCheck
    ) external auth {
        tokenRequiresBlacklistCheck[token] = requiresCheck;
    }

    function offer(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        bool matching, //match "close enough" orders?
        address _owner, // owner of the offer
        address recipient // recipient of the offer's fill
    ) public can_offer returns (uint256) {
        require(!locked, "Reentrancy attempt");
        require(_dust[address(pay_gem)] <= pay_amt);

        if (tokenRequiresBlacklistCheck[address(buy_gem)]) {
            require(
                !_addressIsBlacklisted(address(buy_gem), _owner, recipient)
            );
        }

        /// @dev currently matching is perma-enabled
        // if (matchingEnabled) {
        return
            _matcho(
                pay_amt,
                pay_gem,
                buy_amt,
                buy_gem,
                pos,
                matching,
                _owner,
                recipient
            );
        // }
        // return super.offer(pay_amt, pay_gem, buy_amt, buy_gem);
    }

    //Transfers funds from caller to offer maker, and from market to caller.
    function buy(
        uint256 id,
        uint256 amount
    ) public override can_buy(id) returns (bool) {
        require(!locked, "Reentrancy attempt");

        function(uint256, uint256) returns (bool) fn = matchingEnabled
            ? _buys
            : super.buy;

        return fn(id, amount);
    }

    // Cancel an offer. Refunds offer maker.
    function cancel(
        uint256 id
    ) public override can_cancel(id) returns (bool success) {
        require(!locked, "Reentrancy attempt");
        if (matchingEnabled) {
            if (isOfferSorted(id)) {
                require(_unsort(id));
            } else {
                require(_hide(id), "can't hide");
            }
        }
        return super.cancel(id); //delete the offer.
    }

    // *** Batch Functionality ***
    /// @notice Batch offer functionality - multuple offers in a single transaction
    function batchOffer(
        uint[] calldata payAmts,
        address[] calldata payGems,
        uint[] calldata buyAmts,
        address[] calldata buyGems
    ) external {
        require(
            payAmts.length == payGems.length &&
                payAmts.length == buyAmts.length &&
                payAmts.length == buyGems.length,
            "Array lengths do not match"
        );
        for (uint i = 0; i < payAmts.length; i++) {
            offer(
                payAmts[i],
                IERC20(payGems[i]),
                buyAmts[i],
                IERC20(buyGems[i])
            );
        }
    }

    /// @notice Cancel multiple offers in a single transaction
    function batchCancel(uint[] calldata ids) external {
        for (uint i = 0; i < ids.length; i++) {
            cancel(ids[i]);
        }
    }

    /// @notice Update outstanding offers to new offers, in a batch, in a single transaction
    function batchRequote(
        uint[] calldata ids,
        uint[] calldata payAmts,
        address[] calldata payGems,
        uint[] calldata buyAmts,
        address[] calldata buyGems
    ) external {
        require(
            payAmts.length == payGems.length &&
                payAmts.length == ids.length &&
                payAmts.length == buyAmts.length &&
                payAmts.length == buyGems.length,
            "Array lengths do not match"
        );
        for (uint i = 0; i < ids.length; i++) {
            cancel(ids[i]);
            offer(
                payAmts[i],
                IERC20(payGems[i]),
                buyAmts[i],
                IERC20(buyGems[i])
            );
        }
    }

    //deletes _rank [id]
    //  Function should be called by keepers.
    function del_rank(uint256 id) external returns (bool) {
        require(!locked);

        require(
            !isActive(id) &&
                _rank[id].delb != 0 &&
                _rank[id].delb < block.number - 10
        );
        delete _rank[id];
        emit LogDelete(msg.sender, id);
        return true;
    }

    //set the minimum sell amount for a token
    //    Function is used to avoid "dust offers" that have
    //    very small amount of tokens to sell, and it would
    //    cost more gas to accept the offer, than the value
    //    of tokens received.
    function setMinSell(
        IERC20 pay_gem, //token to assign minimum sell amount to
        uint256 dust //maker (ask) minimum sell amount
    ) external auth note returns (bool) {
        _dust[address(pay_gem)] = dust;
        emit LogMinSell(address(pay_gem), dust);
        return true;
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        IERC20 pay_gem //token for which minimum sell amount is queried
    ) external view returns (uint256) {
        return _dust[address(pay_gem)];
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(
        IERC20 sell_gem,
        IERC20 buy_gem
    ) public view returns (uint256) {
        return _best[address(sell_gem)][address(buy_gem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint256 id) public view returns (uint256) {
        return _rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint256 id) external view returns (uint256) {
        return _rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(
        IERC20 sell_gem,
        IERC20 buy_gem
    ) public view returns (uint256) {
        return _span[address(sell_gem)][address(buy_gem)];
    }

    //get the first unsorted offer that was inserted by a contract
    //      Contracts can't calculate the insertion position of their offer because it is not an O(1) operation.
    //      Their offers get put in the unsorted list of offers.
    //      Keepers can calculate the insertion position offchain and pass it to the insert() function to insert
    //      the unsorted offer into the sorted list. Unsorted offers will not be matched, but can be bought with buy().
    function getFirstUnsortedOffer() public view returns (uint256) {
        return _head;
    }

    //get the next unsorted offer
    //      Can be used to cycle through all the unsorted offers.
    function getNextUnsortedOffer(uint256 id) public view returns (uint256) {
        return _near[id];
    }

    function isOfferSorted(uint256 id) public view returns (bool) {
        return
            _rank[id].next != 0 ||
            _rank[id].prev != 0 ||
            _best[address(offers[id].pay_gem)][address(offers[id].buy_gem)] ==
            id;
    }

    function sellAllAmount(
        IERC20 pay_gem,
        uint256 pay_amt,
        IERC20 buy_gem,
        uint256 min_fill_amount
    ) external returns (uint256 fill_amt) {
        require(!locked);

        uint256 offerId;
        while (pay_amt > 0) {
            //while there is amount to sell
            offerId = getBestOffer(buy_gem, pay_gem); //Get the best offer for the token pair
            require(offerId != 0, "0 offerId"); //Fails if there are not more offers

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (
                mul(pay_amt, 1 ether) <
                wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
            ) {
                break; //We consider that all amount is sold
            }
            if (pay_amt >= offers[offerId].buy_amt) {
                //If amount to sell is higher or equal than current offer amount to buy
                fill_amt = add(fill_amt, offers[offerId].pay_amt); //Add amount bought to acumulator
                pay_amt = sub(pay_amt, offers[offerId].buy_amt); //Decrease amount to sell
                buy((offerId), uint128(offers[offerId].pay_amt)); //We take the whole offer
            } else {
                // if lower
                uint256 baux = rmul(
                    mul(pay_amt, 10 ** 9),
                    rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
                ) / 10 ** 9;
                fill_amt = add(fill_amt, baux); //Add amount bought to acumulator
                buy((offerId), uint128(baux)); //We take the portion of the offer that we need
                pay_amt = 0; //All amount is sold
            }
        }
        require(fill_amt >= min_fill_amount, "min_fill_amount isn't filled");
    }

    function buyAllAmount(
        IERC20 buy_gem,
        uint256 buy_amt,
        IERC20 pay_gem,
        uint256 max_fill_amount
    ) external returns (uint256 fill_amt) {
        require(!locked);
        uint256 offerId;
        while (buy_amt > 0) {
            //Meanwhile there is amount to buy
            offerId = getBestOffer(buy_gem, pay_gem); //Get the best offer for the token pair
            require(offerId != 0, "offerId == 0");

            // There is a chance that buy_amt is smaller than 1 wei of the other token
            if (
                mul(buy_amt, 1 ether) <
                wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
            ) {
                break; //We consider that all amount is sold
            }
            if (buy_amt >= offers[offerId].pay_amt) {
                //If amount to buy is higher or equal than current offer amount to sell
                fill_amt = add(fill_amt, offers[offerId].buy_amt); //Add amount sold to acumulator
                buy_amt = sub(buy_amt, offers[offerId].pay_amt); //Decrease amount to buy
                buy((offerId), uint128(offers[offerId].pay_amt)); //We take the whole offer
            } else {
                //if lower
                fill_amt = add(
                    fill_amt,
                    rmul(
                        mul(buy_amt, 10 ** 9),
                        rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
                    ) / 10 ** 9
                ); //Add amount sold to acumulator
                buy((offerId), uint128(buy_amt)); //We take the portion of the offer that we need
                buy_amt = 0; //All amount is bought
            }
        }
        require(
            fill_amt <= max_fill_amount,
            "fill_amt exceeds max_fill_amount"
        );
    }

    function calculateFees(
        uint256 amount,
        bool isPay /// @param denote direction
    ) public view returns (uint256 _amount) {
        // Add fee amount
        if (isPay) {
            _amount = amount;
            _amount += mul(amount, feeBPS) / 100_000;

            if (makerFee() > 0) {
                _amount += mul(amount, makerFee()) / 100_000;
            }
        }
        // Reduce fee amount
        else {
            _amount = amount;
            _amount -= mul(amount, feeBPS) / 100_000;

            if (makerFee() > 0) {
                _amount -= mul(amount, makerFee()) / 100_000;
            }
        }
    }

    /// @return buy_amt - fill with fee deducted
    /// @return approvalAmount - amount user should approve for interaction
    function getBuyAmountWithFee(
        IERC20 buy_gem,
        IERC20 pay_gem,
        uint256 pay_amt
    ) external view returns (uint256 buy_amt, uint256 approvalAmount) {
        uint modifiedAmount = calculateFees(pay_amt, false);
        buy_amt = (getBuyAmount(buy_gem, pay_gem, modifiedAmount));

        approvalAmount = pay_amt;
        return (buy_amt, approvalAmount);
    }

    /// @return fill_amt - fill amount without fee!
    function getBuyAmount(
        IERC20 buy_gem,
        IERC20 pay_gem,
        uint256 pay_amt
    ) public view returns (uint256 fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem); //Get best offer for the token pair
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt); //Add amount to buy accumulator
            pay_amt = sub(pay_amt, offers[offerId].buy_amt); //Decrease amount to pay
            if (pay_amt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0); //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(
            fill_amt,
            rmul(
                mul(pay_amt, 10 ** 9),
                rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)
            ) / 10 ** 9
        ); //Add proportional amount of last offer to buy accumulator
    }

    /// @return pay_amt - fill with fee deducted
    /// @return approvalAmount - amount user should approve for interaction
    function getPayAmountWithFee(
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint256 buy_amt
    ) public view returns (uint256 pay_amt, uint256 approvalAmount) {
        uint modifiedAmount = calculateFees(buy_amt, true);
        pay_amt = (getPayAmount(pay_gem, buy_gem, modifiedAmount));

        approvalAmount = pay_amt;
        return (pay_amt, approvalAmount);
    }

    function getPayAmount(
        IERC20 pay_gem,
        IERC20 buy_gem,
        uint256 buy_amt
    ) public view returns (uint256 fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem); //Get best offer for the token pair
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt); //Add amount to pay accumulator
            buy_amt = sub(buy_amt, offers[offerId].pay_amt); //Decrease amount to buy
            if (buy_amt > 0) {
                //If we still need more offers
                offerId = getWorseOffer(offerId); //We look for the next best offer
                require(offerId != 0); //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(
            fill_amt,
            rmul(
                mul(buy_amt, 10 ** 9),
                rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)
            ) / 10 ** 9
        ); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    function _isBlacklistedWithSelector(
        address _token,
        address _user,
        bytes4 _selector
    ) internal view returns (bool) {
        (bool success, bytes memory result) = _token.staticcall{gas: 5000}(
            abi.encodeWithSelector(_selector, _user)
        );
        return success && abi.decode(result, (bool));
    }

    function _addressIsBlacklisted(
        address _token,
        address _owner,
        address _recipient
    ) internal view returns (bool) {
        bytes4 blacklistSelector1 = bytes4(keccak256("isBlacklisted(address)"));
        bytes4 blacklistSelector2 = bytes4(keccak256("isBlackListed(address)"));

        return (_isBlacklistedWithSelector(
            _token,
            _owner,
            blacklistSelector1
        ) ||
            _isBlacklistedWithSelector(_token, _owner, blacklistSelector2) ||
            _isBlacklistedWithSelector(
                _token,
                _recipient,
                blacklistSelector1
            ) ||
            _isBlacklistedWithSelector(_token, _recipient, blacklistSelector2));
    }

    function _buys(uint256 id, uint256 amount) internal returns (bool) {
        require(buyEnabled);
        if (amount == offers[id].pay_amt) {
            if (isOfferSorted(id)) {
                //offers[id] must be removed from sorted list because all of it is bought
                _unsort(id);
            } else {
                _hide(id);
            }
        }

        require(super.buy(id, amount));

        // If offer has become dust during buy, we cancel it
        if (
            isActive(id) &&
            offers[id].pay_amt < _dust[address(offers[id].pay_gem)]
        ) {
            dustId = id; //enable current msg.sender to call cancel(id)
            cancel(id);
        }
        return true;
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint256 id) internal view returns (uint256) {
        require(id > 0);

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint256 top = _best[pay_gem][buy_gem];
        uint256 old_top = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint256 id, uint256 pos) internal view returns (uint256) {
        require(id > 0);

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);
        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if (_isPricedLtOrEq(id, pos)) {
                uint256 old_pos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

                // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

    //return true if offers[low] priced less than or equal to offers[high]
    function _isPricedLtOrEq(
        uint256 low, //lower priced offer's id
        uint256 high //higher priced offer's id
    ) internal view returns (bool) {
        return
            mul(offers[low].buy_amt, offers[high].pay_amt) >=
            mul(offers[high].buy_amt, offers[low].pay_amt);
    }

    //these variables are global only because of solidity local variable limit

    //match offers with taker offer, and execute token transactions
    function _matcho(
        uint256 t_pay_amt, //taker sell how much
        IERC20 t_pay_gem, //taker sell which token
        uint256 t_buy_amt, //taker buy how much
        IERC20 t_buy_gem, //taker buy which token
        uint256 pos, //position id
        bool rounding, //match "close enough" orders?
        address owner,
        address recipient
    ) internal returns (uint256 id) {
        uint256 best_maker_id; //highest maker id
        uint256 t_buy_amt_old; //taker buy how much saved
        uint256 m_buy_amt; //maker offer wants to buy this much token
        uint256 m_pay_amt; //maker offer wants to sell this much token

        // there is at least one offer stored for token pair
        while (_best[address(t_buy_gem)][address(t_pay_gem)] > 0) {
            best_maker_id = _best[address(t_buy_gem)][address(t_pay_gem)];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has t_pay_amt and m_pay_amt at +1 away from
            // their "correct" values and m_buy_amt and t_buy_amt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (
                mul(m_buy_amt, t_buy_amt) >
                mul(t_pay_amt, m_pay_amt) +
                    (
                        rounding
                            ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt
                            : 0
                    )
            ) {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            buy(best_maker_id, min(m_pay_amt, t_buy_amt));
            emit LogMatch(id, min(m_pay_amt, t_buy_amt));
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (
            t_buy_amt > 0 &&
            t_pay_amt > 0 &&
            t_pay_amt >= _dust[address(t_pay_gem)]
        ) {
            //new offer should be created
            id = super.offer(
                t_pay_amt,
                t_pay_gem,
                t_buy_amt,
                t_buy_gem,
                owner,
                recipient
            );
            //insert offer into the sorted list
            _sort(id, pos);
        }
    }

    //put offer into the sorted list
    function _sort(
        uint256 id, //maker (ask) id
        uint256 pos //position to insert into
    ) internal {
        require(isActive(id));

        IERC20 buy_gem = offers[id].buy_gem;
        IERC20 pay_gem = offers[id].pay_gem;
        uint256 prev_id; //maker (ask) id

        pos = pos == 0 ||
            offers[pos].pay_gem != pay_gem ||
            offers[pos].buy_gem != buy_gem ||
            !isOfferSorted(pos)
            ? _find(id)
            : _findpos(id, pos);

        if (pos != 0) {
            //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {
            //offers[id] is the highest offer
            prev_id = _best[address(pay_gem)][address(buy_gem)];
            _best[address(pay_gem)][address(buy_gem)] = id;
        }

        if (prev_id != 0) {
            //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prev_id));
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[address(pay_gem)][address(buy_gem)]++;
        emit LogSortedOffer(id);
    }

    // Remove offer from the sorted list (does not cancel offer)
    function _unsort(
        uint256 id //id of maker (ask) offer to remove from sorted list
    ) internal returns (bool) {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0);

        require(
            _rank[id].delb == 0 && //assert id is in the sorted list
                isOfferSorted(id)
        );

        if (id != _best[pay_gem][buy_gem]) {
            // offers[id] is not the highest offer
            require(_rank[_rank[id].next].prev == id);
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {
            //offers[id] is the highest offer
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {
            //offers[id] is not the lowest offer
            require(_rank[_rank[id].prev].next == id);
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number; //mark _rank[id] for deletion
        return true;
    }

    //Hide offer from the unsorted order book (does not cancel offer)
    function _hide(
        uint256 id //id of maker offer to remove from unsorted list
    ) internal returns (bool) {
        uint256 uid = _head; //id of an offer in unsorted offers list
        uint256 pre = uid; //id of previous offer in unsorted offers list

        require(!isOfferSorted(id), "offer sorted"); //make sure offer id is not in sorted offers list

        if (_head == id) {
            //check if offer is first offer in unsorted offers list
            _head = _near[id]; //set head to new first unsorted offer
            _near[id] = 0; //delete order from unsorted order list
            return true;
        }
        while (uid > 0 && uid != id) {
            //find offer in unsorted order list
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {
            //did not find offer id in unsorted offers list
            return false;
        }
        _near[pre] = _near[id]; //set previous unsorted offer to point to offer after offer id
        _near[id] = 0; //delete order from unsorted order list
        return true;
    }

    function setFeeBPS(uint256 _newFeeBPS) external auth returns (bool) {
        feeBPS = _newFeeBPS;
        return true;
    }

    function setMakerFee(uint256 _newMakerFee) external auth returns (bool) {
        StorageSlot.getUint256Slot(MAKER_FEE_SLOT).value = _newMakerFee;
        return true;
    }

    function setFeeTo(address newFeeTo) external auth returns (bool) {
        require(newFeeTo != address(0));
        feeTo = newFeeTo;
        return true;
    }

    function getFeeTo() external view returns (address) {
        return feeTo;
    }

    // *** Admin only function to remove blacklisted offers, if needed
    /// @dev If a user places orders in the book and then later becomes blacklisted, we need a way to handle that for no DOS by removing the order
    function cancelBlacklistedOffer(uint256 id) external auth synchronized {
        OfferInfo memory _offer = offers[id];

        // owner or recipient MUST be blacklisted in buy_gem OR pay_gem
        bool isBlacklisted = _addressIsBlacklisted(
            address(_offer.pay_gem),
            _offer.owner,
            _offer.recipient
        ) ||
            _addressIsBlacklisted(
                address(_offer.buy_gem),
                _offer.owner,
                _offer.recipient
            );
        require(isBlacklisted, "neither owner nor recipient is blacklisted");

        // remove order from the sorted list
        require(_unsort(id));
        // delete offer manually
        // not returning tokens back to the bad guy
        delete offers[id];
    }
}

// SPDX-License-Identifier: MIT

/// @author rubicon.eth
/// @notice This contract is a router to interact with the low-level functions present in RubiconMarket and Pools
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../compound-v2-fork/CTokenInterfaces.sol";
import "../interfaces/IBathToken.sol";
import "../interfaces/IBathBuddy.sol";
import "../interfaces/IWETH.sol";
import "../RubiconMarket.sol";

///@dev this contract is a high-level router that utilizes Rubicon smart contracts to provide
///@dev added convenience and functionality when interacting with the Rubicon protocol
contract RubiconRouter {
    // Libs
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Storage vars
    address public RubiconMarketAddress;
    address payable public wethAddress;
    bool public started;
    /// @dev track when users make offers with/for the native asset so we can permission the cancelling of those orders
    mapping(address => uint256[]) public userNativeAssetOrders;
    bool locked;

    /// event LogNote(string, uint256); /// TODO: this event is not used in the contract, remove?

    /// event LogSwap(
    ///     uint256 inputAmount,
    ///     address inputERC20,
    ///     uint256 hurdleBuyAmtMin,
    ///     address targetERC20,
    ///     bytes32 indexed pair,
    ///     uint256 realizedFill,
    ///     address recipient
    /// );

    // Events
    event emitSwap(
        address indexed recipient,
        address indexed inputERC20,
        address indexed targetERC20,
        bytes32 pair,
        uint256 inputAmount,
        uint256 realizedFill,
        uint256 hurdleBuyAmtMin
    );

    // Modifiers
    /// @dev beGoneReentrantScum
    modifier beGoneReentrantScum() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }

    //============================= RECEIVE ETH =============================

    receive() external payable {}

    fallback() external payable {}

    //============================= PROXY-INIT =============================

    function startErUp(address _theTrap, address payable _weth) external {
        require(!started);
        RubiconMarketAddress = _theTrap;
        wethAddress = _weth;
        started = true;
    }

    //============================= VIEW =============================

    /// @notice iterate through all baseToken/tokens[i] offers of maker
    /// @param baseToken - token pa_amt of which was sent to the market
    /// @param tokens - all the quote tokens for baseToken
    /// @param maker - owner of the offers
    /// @return balanceInBook - total balance of the baseToken of the maker in the market
    /// @return balance - balance of the baseToken of the maker
    function getMakerBalance(
        IERC20 baseToken,
        IERC20[] calldata tokens,
        address maker
    ) public view returns (uint256 balanceInBook, uint256 balance) {
        // find all active offers
        for (uint256 i = 0; i < tokens.length; ++i) {
            balanceInBook += getMakerBalanceInPair(baseToken, tokens[i], maker);
        }
        balance = baseToken.balanceOf(maker);
    }

    /// @notice get total pay_amt of maker across all the offers in asset/quote pair
    function getMakerBalanceInPair(
        IERC20 asset,
        IERC20 quote,
        address maker
    ) public view returns (uint256 balance) {
        uint256[] memory offerIDs = getOfferIDsFromPair(asset, quote);
        RubiconMarket market = RubiconMarket(RubiconMarketAddress);

        for (uint256 i = 0; i < offerIDs.length; ++i) {
            (uint256 pay_amt, , , , , , address owner) = market.offers(
                offerIDs[i]
            );

            if (owner == maker) {
                balance += pay_amt;
            }
            // else go to the next offer
        }
    }

    /// @notice Get all the outstanding orders from both sides of the order book for a given pair
    /// @dev The asset/quote pair ordering will affect return values - asset should be the top of the pair: for example, (ETH, USDC, 10) will return (10 best ETH asks, 10 best USDC bids, 10)
    /// @param asset the IERC20 token that represents the ask/sell side of the order book
    /// @param quote the IERC20 token that represents the bid/buy side of the order book
    function getBookFromPair(
        IERC20 asset,
        IERC20 quote
    ) public view returns (uint256[3][] memory asks, uint256[3][] memory bids) {
        asks = getOffersFromPair(asset, quote);
        bids = getOffersFromPair(quote, asset);
    }

    /// @notice inspect one side of the order book
    function getOffersFromPair(
        IERC20 tokenIn,
        IERC20 tokenOut
    ) public view returns (uint256[3][] memory offers) {
        (uint256 size, uint256 bestOfferID) = getBookDepth(tokenIn, tokenOut);

        offers = new uint256[3][](size);
        RubiconMarket market = RubiconMarket(RubiconMarketAddress);

        uint256 lastOffer = bestOfferID;

        for (uint256 index = 0; index < size; index++) {
            if (lastOffer == 0) {
                break;
            }

            (uint256 pay_amt, , uint256 buy_amt, ) = market.getOffer(lastOffer);

            offers[index] = [pay_amt, buy_amt, lastOffer];
            // update lastOffer with next best offer
            lastOffer = RubiconMarket(RubiconMarketAddress).getWorseOffer(
                lastOffer
            );
        }
    }

    /// @notice returns all offer ids from tokenIn/tokenOut pair
    function getOfferIDsFromPair(
        IERC20 tokenIn,
        IERC20 tokenOut
    ) public view returns (uint256[] memory IDs) {
        (uint256 size, uint256 lastOffer) = getBookDepth(tokenIn, tokenOut);
        RubiconMarket market = RubiconMarket(RubiconMarketAddress);
        IDs = new uint256[](size);

        for (uint256 i = 0; i < size; ++i) {
            if (lastOffer == 0) {
                break;
            }

            IDs[i] = lastOffer;

            // update lastOffer with next best offer
            lastOffer = market.getWorseOffer(lastOffer);
        }
    }

    /// @notice get depth of the one side of the order-book
    function getBookDepth(
        IERC20 tokenIn,
        IERC20 tokenOut
    ) public view returns (uint256 depth, uint256 bestOfferID) {
        RubiconMarket market = RubiconMarket(RubiconMarketAddress);
        bestOfferID = market.getBestOffer(tokenIn, tokenOut);
        depth = market.getOfferCount(tokenIn, tokenOut);
    }

    /// @dev this function returns the best offer for a pair's id and info
    function getBestOfferAndInfo(
        address asset,
        address quote
    )
        public
        view
        returns (
            uint256, //id
            uint256,
            IERC20,
            uint256,
            IERC20
        )
    {
        address _market = RubiconMarketAddress;
        uint256 offer = RubiconMarket(_market).getBestOffer(
            IERC20(asset),
            IERC20(quote)
        );
        (
            uint256 pay_amt,
            IERC20 pay_gem,
            uint256 buy_amt,
            IERC20 buy_gem
        ) = RubiconMarket(_market).getOffer(offer);
        return (offer, pay_amt, pay_gem, buy_amt, buy_gem);
    }

    /// @dev this function takes the same parameters of swap and returns the expected amount
    function getExpectedSwapFill(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route // First address is what is being payed, Last address is what is being bought
    ) public view returns (uint256 currentAmount) {
        address _market = RubiconMarketAddress;

        for (uint256 i = 0; i < route.length - 1; i++) {
            (address input, address output) = (route[i], route[i + 1]);
            uint256 _pay = i == 0 ? pay_amt : currentAmount;

            // fee here should be excluded
            uint256 wouldBeFillAmount = RubiconMarket(_market).getBuyAmount(
                IERC20(output),
                IERC20(input),
                _pay
            );
            currentAmount = wouldBeFillAmount;
        }
        require(currentAmount >= buy_amt_min, "didnt clear buy_amt_min");
    }

    /// @dev this function takes the same parameters of multiswap and returns the expected amount
    function getExpectedMultiswapFill(
        uint256[] memory pay_amts,
        uint256[] memory buy_amt_mins,
        address[][] memory routes
    ) public view returns (uint256 outputAmount) {
        address _market = RubiconMarketAddress;

        address input;
        address output;
        uint256 currentAmount;

        for (uint256 i = 0; i < routes.length; ++i) {
            // loopinloop
            for (uint256 n = 0; n < routes[i].length - 1; ++n) {
                (input, output) = (routes[i][n], routes[i][n + 1]);

                uint256 _pay = n == 0 ? pay_amts[i] : currentAmount;

                // fee here should be excluded
                uint256 wouldBeFillAmount = RubiconMarket(_market).getBuyAmount(
                    IERC20(output),
                    IERC20(input),
                    _pay
                );
                currentAmount = wouldBeFillAmount;
            }
            require(
                currentAmount >= buy_amt_mins[i],
                "didnt clear buy_amt_min"
            );
            outputAmount += currentAmount;
        }
    }

    /// @notice A function that returns the index of uid from array
    /// @dev uid must be in array for the purposes of this contract to enforce outstanding trades per strategist are tracked correctly
    /// @dev can be used to check if a value is in a given array, and at what index
    function getIndexFromElement(
        uint256 uid,
        uint256[] storage array
    ) internal view returns (uint256 _index) {
        bool assigned = false;
        for (uint256 index = 0; index < array.length; index++) {
            if (uid == array[index]) {
                _index = index;
                assigned = true;
                return _index;
            }
        }
        require(assigned, "Didnt Find that element in live list, cannot scrub");
    }

    /// @dev View function to query a user's rewards they can claim via claimAllUserBonusTokens
    function checkClaimAllUserBonusTokens(
        address user,
        address[] memory targetBathTokens,
        address token
    ) public view returns (uint256 earnedAcrossPools) {
        for (uint256 index = 0; index < targetBathTokens.length; index++) {
            address targetBT = targetBathTokens[index];
            address targetBathBuddy = IBathToken(targetBT).bathBuddy();
            uint256 earned = IBathBuddy(targetBathBuddy).earned(user, token);
            earnedAcrossPools += earned;
        }
    }

    //============================= SWAP =============================

    function multiswap(
        address[][] memory routes,
        uint256[] memory pay_amts,
        uint256[] memory buy_amts_min,
        address to
    ) public {
        for (uint256 i = 0; i < routes.length; ++i) {
            swap(pay_amts[i], buy_amts_min[i], routes[i], to);
        }
    }

    /// @dev This function lets a user swap from route[0] -> route[last] at some minimum expected rate
    /// @dev pay_amt - amount to be swapped away from msg.sender of *first address in path*
    /// @dev buy_amt_min - target minimum received of *last address in path*
    function swap(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] memory route, // First address is what is being payed, Last address is what is being bought
        address to
    ) public returns (uint256) {
        //**User must approve this contract first**
        //transfer needed amount here first
        IERC20(route[0]).safeTransferFrom(msg.sender, address(this), pay_amt);

        // uint modifiedPayAmount = _calcAmountAfterFee(pay_amt, false);
        return _swap(pay_amt, buy_amt_min, route, to);
    }

    // ** Native ETH Wrapper Functions **
    /// @dev WETH wrapper functions to obfuscate WETH complexities from ETH holders
    function buyAllAmountWithETH(
        IERC20 buy_gem,
        uint256 buy_amt,
        uint256 max_fill_amount
    ) external payable beGoneReentrantScum returns (uint256 fill) {
        address _weth = address(wethAddress);
        uint256 _before = IERC20(_weth).balanceOf(address(this));
        require(
            msg.value == max_fill_amount,
            "must send as much ETH as max_fill_amount"
        );
        IWETH(wethAddress).deposit{value: max_fill_amount}(); // Pay with native ETH -> WETH

        if (
            IWETH(wethAddress).allowance(address(this), RubiconMarketAddress) <
            max_fill_amount
        ) {
            approveAssetOnMarket(wethAddress);
        }

        // An amount in WETH
        fill = RubiconMarket(RubiconMarketAddress).buyAllAmount(
            buy_gem,
            buy_amt,
            IERC20(wethAddress),
            max_fill_amount
        );
        IERC20(buy_gem).safeTransfer(msg.sender, fill);

        uint256 _after = IERC20(_weth).balanceOf(address(this));
        uint256 delta = _after - _before;

        // Return unspent coins to sender
        if (delta > 0) {
            IWETH(wethAddress).withdraw(delta);
            // msg.sender.transfer(delta);
            (bool success, ) = msg.sender.call{value: delta}("");
            require(success, "Transfer failed.");
        }
    }

    // Paying IERC20 to buy native ETH
    function buyAllAmountForETH(
        uint256 buy_amt,
        IERC20 pay_gem,
        uint256 max_fill_amount
    ) external beGoneReentrantScum returns (uint256 fill) {
        uint256 _before = pay_gem.balanceOf(address(this));
        IERC20(pay_gem).safeTransferFrom(
            msg.sender,
            address(this),
            max_fill_amount
        ); //transfer pay here

        if (
            pay_gem.allowance(address(this), RubiconMarketAddress) <
            max_fill_amount
        ) {
            approveAssetOnMarket(address(pay_gem));
        }

        fill = RubiconMarket(RubiconMarketAddress).buyAllAmount(
            IERC20(wethAddress),
            buy_amt,
            pay_gem,
            max_fill_amount
        );
        // the actual amount we get in the WETH form
        buy_amt = _calcAmountAfterFee(buy_amt, false);
        IWETH(wethAddress).withdraw(buy_amt); // Fill in WETH

        uint256 _after = pay_gem.balanceOf(address(this));
        uint256 _delta = _after - _before;

        // Return unspent coins to sender
        if (_delta > 0) {
            IERC20(pay_gem).safeTransfer(msg.sender, _delta);
        }

        // msg.sender.transfer(buy_amt); // Return native ETH
        (bool success, ) = msg.sender.call{value: buy_amt}("");
        require(success, "Transfer failed.");

        return fill;
    }

    function swapWithETH(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route, // First address is what is being payed, Last address is what is being bought
        address to
    ) external payable returns (uint256) {
        require(route[0] == wethAddress, "Initial value in path not WETH");
        require(
            msg.value == pay_amt,
            "must send enough native ETH to pay as weth and account for fee"
        );
        IWETH(wethAddress).deposit{value: pay_amt}();

        return _swap(pay_amt, buy_amt_min, route, to);
    }

    function swapForETH(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] calldata route // First address is what is being payed, Last address is what is being bought
    ) external beGoneReentrantScum returns (uint256 fill) {
        require(
            route[route.length - 1] == wethAddress,
            "target of swap is not WETH"
        );

        IERC20(route[0]).safeTransferFrom(msg.sender, address(this), pay_amt);

        fill = _swap(pay_amt, buy_amt_min, route, address(this));

        IWETH(wethAddress).withdraw(fill);
        // msg.sender.transfer(fill);
        (bool success, ) = msg.sender.call{value: fill}("");
        require(success, "Transfer failed.");
    }

    //============================= OFFERS =============================

    // Pay in native ETH
    function offerWithETH(
        uint256 pay_amt, //maker (ask) sell how much
        // IERC20 nativeETH, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        IERC20 buy_gem, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        address recipient // the recipient of the fill
    ) external payable returns (uint256) {
        require(
            msg.value == pay_amt,
            "didnt send enough native ETH for WETH offer"
        );

        uint256 _before = IERC20(buy_gem).balanceOf(address(this));

        IWETH(wethAddress).deposit{value: pay_amt}();

        if (
            IWETH(wethAddress).allowance(address(this), RubiconMarketAddress) <
            pay_amt
        ) {
            approveAssetOnMarket(wethAddress);
        }
        uint256 id = RubiconMarket(RubiconMarketAddress).offer(
            pay_amt,
            IERC20(wethAddress),
            buy_amt,
            buy_gem,
            pos,
            address(this), // router is owner of the offer
            recipient
        );

        // Track the user's order so they can cancel it
        userNativeAssetOrders[msg.sender].push(id);

        uint256 _after = IERC20(buy_gem).balanceOf(address(this));
        if (_after > _before) {
            //return any potential fill amount on the offer
            IERC20(buy_gem).safeTransfer(recipient, _after - _before);
        }
        return id;
    }

    // Pay in native ETH
    function offerForETH(
        uint256 pay_amt, //maker (ask) sell how much
        IERC20 pay_gem, //maker (ask) sell which token
        uint256 buy_amt, //maker (ask) buy how much
        // IERC20 nativeETH, //maker (ask) buy which token
        uint256 pos, //position to insert offer, 0 should be used if unknown
        address recipient // the recipient of the fill
    ) external beGoneReentrantScum returns (uint256) {
        IERC20(pay_gem).safeTransferFrom(msg.sender, address(this), pay_amt);

        uint256 _before = IERC20(wethAddress).balanceOf(address(this));

        if (pay_gem.allowance(address(this), RubiconMarketAddress) < pay_amt) {
            approveAssetOnMarket(address(pay_gem));
        }

        uint256 id = RubiconMarket(RubiconMarketAddress).offer(
            pay_amt,
            pay_gem,
            buy_amt,
            IERC20(wethAddress),
            pos,
            address(this), // router is owner of an offer
            recipient
        );

        // Track the user's order so they can cancel it
        userNativeAssetOrders[msg.sender].push(id);

        uint256 _after = IERC20(wethAddress).balanceOf(address(this));
        if (_after > _before) {
            //return any potential fill amount on the offer as native ETH
            uint256 delta = _after - _before;
            IWETH(wethAddress).withdraw(delta);
            // msg.sender.transfer(delta);
            (bool success, ) = payable(recipient).call{value: delta}("");
            require(success, "Transfer failed.");
        }

        return id;
    }

    // Cancel an offer made in WETH
    function cancelForETH(
        uint256 id
    ) external beGoneReentrantScum returns (bool outcome) {
        uint256 indexOrFail = getIndexFromElement(
            id,
            userNativeAssetOrders[msg.sender]
        );
        /// @dev Verify that the offer the user is trying to cancel is their own
        require(
            userNativeAssetOrders[msg.sender][indexOrFail] == id,
            "You did not provide an Id for an offer you own"
        );

        (uint256 pay_amt, IERC20 pay_gem, , ) = RubiconMarket(
            RubiconMarketAddress
        ).getOffer(id);
        require(
            address(pay_gem) == wethAddress,
            "trying to cancel a non WETH order"
        );
        // Cancel order and receive WETH here in amount of pay_amt
        outcome = RubiconMarket(RubiconMarketAddress).cancel(id);
        IWETH(wethAddress).withdraw(pay_amt);
        // msg.sender.transfer(pay_amt);
        (bool success, ) = msg.sender.call{value: pay_amt}("");
        require(success, "Transfer failed.");
    }

    //============================= POOLS =============================

    // Deposit native ETH -> WETH pool
    function depositWithETH(
        uint256 amount,
        address bathToken,
        address to
    ) external payable beGoneReentrantScum returns (uint256 newShares) {
        address target = CErc20Storage(bathToken).underlying();
        require(target == wethAddress, "target pool not weth pool");
        require(msg.value == amount, "didnt send enough eth");

        if (IERC20(target).allowance(address(this), bathToken) == 0) {
            IERC20(target).safeApprove(bathToken, amount);
        }

        IWETH(wethAddress).deposit{value: amount}();
        IERC20(wethAddress).approve(bathToken, amount);
        require(CErc20Interface(bathToken).mint(amount) == 0, "mint failed");

        newShares = IERC20(bathToken).balanceOf(address(this));
        /// @dev v2 bathTokens shouldn't be sent to this contract from anywhere other than this function
        IERC20(bathToken).safeTransfer(to, newShares);
        require(
            IERC20(bathToken).balanceOf(address(this)) == 0,
            "bath tokens stuck"
        );
    }

    // Withdraw native ETH <- WETH pool
    function withdrawForETH(
        uint256 shares,
        address bathToken
    ) external beGoneReentrantScum returns (uint256 withdrawnWETH) {
        address target = CErc20Storage(bathToken).underlying();
        require(target == wethAddress, "target pool not weth pool");

        uint256 startingWETHBalance = IERC20(wethAddress).balanceOf(
            address(this)
        );

        IERC20(bathToken).transferFrom(msg.sender, address(this), shares);
        require(
            CErc20Interface(bathToken).redeem(shares) == 0,
            "redeem failed"
        );

        uint256 postWithdrawWETH = IERC20(wethAddress).balanceOf(address(this));
        require(postWithdrawWETH > startingWETHBalance);

        withdrawnWETH = postWithdrawWETH.sub(startingWETHBalance);
        IWETH(wethAddress).withdraw(withdrawnWETH);

        //Send back withdrawn native eth to sender
        // msg.sender.transfer(withdrawnWETH);
        (bool success, ) = msg.sender.call{value: withdrawnWETH}("");
        require(success, "Transfer failed.");
    }

    //============================= HELPERS =============================

    // function for infinite approvals of Rubicon Market
    function approveAssetOnMarket(address toApprove) internal {
        require(
            started &&
                RubiconMarketAddress != address(this) &&
                RubiconMarketAddress != address(0),
            "Router not initialized"
        );
        // Approve exchange
        IERC20(toApprove).safeApprove(RubiconMarketAddress, type(uint256).max);
    }

    //============================= INTERNALS =============================

    // Internal function requires that ERC20s are here before execution
    function _swap(
        uint256 pay_amt,
        uint256 buy_amt_min,
        address[] memory route, // First address is what is being payed, Last address is what is being bought
        address to // Recipient of swap outputs!
    ) internal returns (uint256) {
        require(route.length > 1, "Not enough hop destinations!");

        address _market = RubiconMarketAddress;
        uint256 currentAmount;

        for (uint256 i = 0; i < route.length - 1; ++i) {
            (address input, address output) = (route[i], route[i + 1]);

            uint256 _pay = i == 0 ? pay_amt : currentAmount;

            if (IERC20(input).allowance(address(this), _market) < _pay) {
                approveAssetOnMarket(input);
            }

            // fillAmount already with fee deducted
            uint256 fillAmount = RubiconMarket(_market).sellAllAmount(
                IERC20(input),
                _calcAmountAfterFee(_pay, false),
                IERC20(output),
                0 //naively assume no fill_amt here for loop purposes?
            );

            currentAmount = fillAmount;
        }
        require(currentAmount >= buy_amt_min, "didnt clear buy_amt_min");

        // send tokens back to sender if not keeping here
        if (to != address(this)) {
            IERC20(route[route.length - 1]).safeTransfer(to, currentAmount);
        }

        /// emit LogSwap(
        ///     pay_amt,
        ///     route[0],
        ///     buy_amt_min,
        ///     route[route.length - 1],
        ///     keccak256(abi.encodePacked(route[0], route[route.length - 1])),
        ///     currentAmount,
        ///     to
        /// );

        emit emitSwap(
            to,
            route[0],
            route[route.length - 1],
            keccak256(abi.encodePacked(route[0], route[route.length - 1])),
            pay_amt,
            currentAmount,
            buy_amt_min
        );

        return currentAmount;
    }

    function _calcAmountAfterFee(
        uint256 amount,
        bool direction
    ) internal view returns (uint256) {
        return RubiconMarket(RubiconMarketAddress).calculateFees(amount, direction);
    }
}