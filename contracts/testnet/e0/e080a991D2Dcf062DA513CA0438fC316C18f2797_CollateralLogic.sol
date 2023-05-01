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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library AddressUpgradeable {
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
pragma solidity ^0.8.0;

import "../libraries/PriceConvertor.sol";
import "../pool/IPool.sol";
import "../synth/IERC20X.sol";
import "../synthex/ISyntheX.sol";
import "../libraries/Errors.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../utils/interfaces/IWETH.sol";

library CollateralLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event CollateralParamsUpdated(address indexed asset, uint cap, uint baseLTV, uint liqThreshold, uint liqBonus, bool isEnabled);
    
    event CollateralEntered(address indexed user, address indexed collateral);
    event CollateralExited(address indexed user, address indexed collateral);
    
    event Deposit(address indexed user, address indexed asset, uint256 amount);
    event Withdraw(address indexed user, address indexed asset, uint256 amount);

    /**
     * @notice Enable a collateral
     * @param _collateral The address of the collateral
     */
    function enterCollateral(
        address _collateral,
        mapping(address => DataTypes.Collateral) storage collaterals,
        mapping(address => mapping(address => bool)) storage accountMembership,
        mapping(address => address[]) storage accountCollaterals
    ) public {
        // get collateral pool
        DataTypes.Collateral storage collateral = collaterals[_collateral];

        require(collateral.isActive, Errors.ASSET_NOT_ACTIVE);

        // ensure that the user is not already in the pool
        require(!accountMembership[_collateral][msg.sender], Errors.ACCOUNT_ALREADY_ENTERED);
        // enable account's collateral membership
        accountMembership[_collateral][msg.sender] = true;
        // add to account's collateral list
        accountCollaterals[msg.sender].push(_collateral);

        emit CollateralEntered(msg.sender, _collateral);
    }

    /**
     * @notice Exit a collateral
     * @param _collateral The address of the collateral
     */
    function exitCollateral(
        address _collateral,
        mapping(address => mapping(address => bool)) storage accountMembership,
        mapping(address => address[]) storage accountCollaterals
    ) public {
        accountMembership[_collateral][msg.sender] = false;
        // remove from list
        for (uint i = 0; i < accountCollaterals[msg.sender].length; i++) {
            if (accountCollaterals[msg.sender][i] == _collateral) {
                accountCollaterals[msg.sender][i] = accountCollaterals[msg.sender][accountCollaterals[msg.sender].length - 1];
                accountCollaterals[msg.sender].pop();

                emit CollateralExited(msg.sender, _collateral); 
                break;
            }
        }
    }

    function depositETH(
        address _account,
        address WETH_ADDRESS,
        uint _amount,
        mapping(address => DataTypes.Collateral) storage collaterals,
        mapping(address => mapping(address => bool)) storage accountMembership,
        mapping(address => mapping(address => uint)) storage accountCollateralBalance,
        mapping(address => address[]) storage accountCollaterals
    ) public {
        // wrap ETH
        IWETH(WETH_ADDRESS).deposit{value: _amount}();
        // deposit collateral
        depositInternal(
            _account,
            WETH_ADDRESS,
            _amount,
            collaterals,
            accountMembership,
            accountCollateralBalance,
            accountCollaterals
        );
    }

    function depositWithPermit(
        address _account,
        address _collateral,
        uint _amount,
        uint _approval, 
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        mapping(address => DataTypes.Collateral) storage collaterals,
        mapping(address => mapping(address => bool)) storage accountMembership,
        mapping(address => mapping(address => uint)) storage accountCollateralBalance,
        mapping(address => address[]) storage accountCollaterals
    ) public {
        // permit approval
        IERC20PermitUpgradeable(_collateral).permit(msg.sender, address(this), _approval, _deadline, _v, _r, _s);
        // deposit collateral
        depositERC20(_account, _collateral, _amount, collaterals, accountMembership, accountCollateralBalance, accountCollaterals);
    }

    function depositERC20(
        address _account,
        address _collateral,
        uint _amount,
        mapping(address => DataTypes.Collateral) storage collaterals,
        mapping(address => mapping(address => bool)) storage accountMembership,
        mapping(address => mapping(address => uint)) storage accountCollateralBalance,
        mapping(address => address[]) storage accountCollaterals
    ) public {
        // transfer in collateral
        IERC20Upgradeable(_collateral).transferFrom(msg.sender, address(this), _amount);
        // deposit collateral
        depositInternal(
            _account,
            _collateral,
            _amount,
            collaterals,
            accountMembership,
            accountCollateralBalance,
            accountCollaterals
        );
    }

    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     */
    function depositInternal(
        address _account,
        address _collateral,
        uint _amount,
        mapping(address => DataTypes.Collateral) storage collaterals,
        mapping(address => mapping(address => bool)) storage accountMembership,
        mapping(address => mapping(address => uint)) storage accountCollateralBalance,
        mapping(address => address[]) storage accountCollaterals
    ) public {
        // get collateral market
        DataTypes.Collateral storage collateral = collaterals[_collateral];
        // ensure collateral is globally enabled
        require(collateral.isActive, Errors.ASSET_NOT_ACTIVE);

        // ensure user has entered the market
        if(!accountMembership[_collateral][_account]){
            enterCollateral(
                _collateral,
                collaterals,
                accountMembership,
                accountCollaterals
            );
        }
        
        // Update balance
        accountCollateralBalance[_account][_collateral] += _amount;

        // Update collateral supply
        collateral.totalDeposits += _amount;
        require(collateral.totalDeposits <= collateral.cap, Errors.EXCEEDED_MAX_CAPACITY);

        // emit event
        emit Deposit(_account, _collateral, _amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  Withdraw                                  */
    /* -------------------------------------------------------------------------- */
    
    /**
     * @notice Deposit collateral
     * @param _collateral The address of the erc20 collateral
     * @param _amount The amount of collateral to deposit
     */
    function withdraw(
        address _collateral,
        uint _amount,
        mapping(address => DataTypes.Collateral) storage collaterals,
        mapping(address => mapping(address => uint)) storage accountCollateralBalance
    ) public {
        require(_amount > 0, Errors.ZERO_AMOUNT);
        // Process withdraw
        DataTypes.Collateral storage supply = collaterals[_collateral];
        // check deposit balance
        uint depositBalance = accountCollateralBalance[msg.sender][_collateral];
        // allow only upto their deposit balance
        require(depositBalance >= _amount, Errors.INSUFFICIENT_BALANCE);
        // Update balance
        accountCollateralBalance[msg.sender][_collateral] = depositBalance - _amount;
        // Update collateral supply
        supply.totalDeposits -= _amount;
        // Emit successful event
        emit Withdraw(msg.sender, _collateral, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/oracle/IPriceOracle.sol";

library DataTypes {
    struct Synth {
        bool isActive;
        bool isDisabled;
        uint256 mintFee;
        uint256 burnFee;
    }

    /// @notice Collateral data structure
    struct Collateral {
        bool isActive;         // Checks if collateral is enabled
        uint256 cap;            // Maximum amount of collateral that can be deposited
        uint256 totalDeposits;  // Total amount of collateral deposited
        uint256 baseLTV;        // Base loan to value ratio (in bps) 80% = 8000
        uint256 liqThreshold;   // Liquidation threshold (in bps) 90% = 9000
        uint256 liqBonus;       // Liquidation bonus (in bps) 105% = 10500
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct AccountLiquidity {
        int256 liquidity;
        uint256 collateral;
        uint256 debt;
    }

    struct VarsLiquidity {
        IPriceOracle oracle;
        address collateral;
        uint price;
        address[] _accountPools;
    }

    struct Vars_Mint {
        uint amountPlusFeeUSD;
        uint _borrowCapacity;
        address[] tokens;
        uint[] prices;
    }

    struct Vars_Burn {
        uint amountUSD;
        uint debt;
        address[] tokens;
        uint[] prices;
    }

    struct Vars_Liquidate {
        AccountLiquidity liq;
        Collateral collateral;
        uint ltv;
        address[] tokens;
        uint[] prices;
        uint amountUSD;
        uint debtUSD;
        uint amountOut;
        uint penalty;
        uint refundOut;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author SyntheX
 * @notice Defines the error messages emitted by the different contracts of SyntheX
 */
library Errors {
  string public constant CALLER_NOT_L0_ADMIN = '1'; // 'The caller of the function is not a pool admin'
  string public constant CALLER_NOT_L1_ADMIN = '2'; // 'The caller of the function is not an emergency admin'
  string public constant CALLER_NOT_L2_ADMIN = '3'; // 'The caller of the function is not a pool or emergency admin'
  string public constant ASSET_NOT_ENABLED = '4'; // 'The collateral is not enabled
  string public constant ACCOUNT_ALREADY_ENTERED = '5'; // 'The account has already entered the collateral
  string public constant INSUFFICIENT_COLLATERAL = '6'; // 'The account has insufficient collateral
  string public constant ZERO_AMOUNT = '7'; // 'The amount is zero
  string public constant EXCEEDED_MAX_CAPACITY = '8'; // 'The amount exceeds the maximum capacity
  string public constant INSUFFICIENT_BALANCE = '9'; // 'The account has insufficient balance
  string public constant ASSET_NOT_ACTIVE = '10'; // 'The synth is not enabled
  string public constant ASSET_NOT_FOUND = '11'; // 'The synth is not enabled
  string public constant INSUFFICIENT_DEBT = '12'; // 'The account has insufficient debt'
  string public constant INVALID_ARGUMENT = '13'; // 'The argument is invalid'
  string public constant ASSET_ALREADY_ADDED = '14'; // 'The asset is already added'
  string public constant NOT_AUTHORIZED = '15'; // 'The caller is not authorized'
  string public constant TRANSFER_FAILED = '16'; // 'The transfer failed'
  string public constant ACCOUNT_BELOW_LIQ_THRESHOLD = '17'; // 'The account is below the liquidation threshold'
  string public constant ACCOUNT_NOT_ENTERED = '18'; // 'The account has not entered the collateral'

  string public constant NOT_ENOUGH_SYX_TO_UNLOCK = '19'; // 'Not enough SYX to unlock'
  string public constant REQUEST_ALREADY_EXISTS = '20'; // 'Request already exists'
  string public constant REQUEST_DOES_NOT_EXIST = '21'; // 'Request does not exist'
  string public constant UNLOCK_NOT_STARTED = '22'; // 'Unlock not started'

  string public constant TOKEN_NOT_SUPPORTED = '23';
  string public constant ADDRESS_IS_CONTRACT = '24';
  string public constant INVALID_MERKLE_PROOF = '25';
  string public constant INVALID_TIME = '26';
  string public constant INVALID_AMOUNT = '27';
  string public constant INVALID_ADDRESS = '28';

  string public constant TIME_NOT_STARTED = '29';
  string public constant TIME_ENDED = '30';
  string public constant WITHDRAWING_MORE_THAN_ALLOWED = '31';
  string public constant ADDRESS_IS_NOT_CONTRACT = '32';

  string public constant ALREADY_SET = '33';
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/oracle/IPriceOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title PriceConvertor
 * @notice PriceConvertor contract to convert token prices
 */
library PriceConvertor {
    using SafeMath for uint256;
    
    uint constant public PRICE_PRECISION = 1e8;
    
    /**
     * Transfer tokens from one address to another
     * @param amount Amount of token 1 to transfer
     * @param t1Price Price of token 1
     * @param t2Price Price of token 2
     */
    function t1t2(uint amount, uint t1Price, uint t2Price) internal pure returns(uint) {
        return amount.mul(t1Price).div(t2Price);
    }

    /**
     * Token amount to USD amount
     * @param amount Amount of token to convert
     * @param price Price of token
     */
    function toUSD(uint amount, uint price) internal pure returns(uint){
        return amount.mul(price).div(PRICE_PRECISION);
    }

    /**
     * USD amount to token amount
     * @param amount Amount of USD to convert
     * @param price Price of token
     */
    function toToken(uint amount, uint price) internal pure returns(uint){
        return amount.mul(PRICE_PRECISION).div(price);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/oracle/IPriceOracle.sol";
import "./PoolStorage.sol";

abstract contract IPool {

    function enterCollateral(address _collateral) external virtual;
    function exitCollateral(address _collateral, bytes[] memory priceUpdateData) external virtual;

    function deposit(address _collateral, uint _amount, address _account) external virtual;
    function depositWithPermit(
        address _collateral, 
        uint _amount,
        address _account,
        uint _approval,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual;
    function depositETH(address _account) external virtual payable;
    function withdraw(address _collateral, uint _amount, bool unwrap, bytes[] memory priceUpdateData) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                               Admin Functions                              */
    /* -------------------------------------------------------------------------- */
    function updateSynth(address _synth, DataTypes.Synth memory _params) external virtual;
    function updateCollateral(address _collateral, DataTypes.Collateral memory _params) external virtual;
    function removeSynth(address _synth) external virtual;
    function addSynth(address _synth, DataTypes.Synth memory _params) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                               View Functions                               */
    /* -------------------------------------------------------------------------- */
    function getAccountLiquidity(address _account) external virtual view returns(DataTypes.AccountLiquidity memory liq);
    function getTotalDebtUSD() external virtual view returns(uint totalDebt);
    function getUserDebtUSD(address _account) external virtual view returns(uint);
    function supportsInterface(bytes4 interfaceId) external virtual view returns (bool);

    /* -------------------------------------------------------------------------- */
    /*                              Internal Functions                            */
    /* -------------------------------------------------------------------------- */
    function mint(address _synth, uint _amount, address _to, bytes[] memory priceUpdateData) external virtual returns(uint);
    function burn(address _synth, uint _amount, bytes[] memory priceUpdateData) external virtual returns(uint);
    function swap(address _synthIn, uint _amount, address _synthOut, DataTypes.SwapKind _kind, address _to, bytes[] memory priceUpdateData) external virtual returns(uint[2] memory);
    function liquidate(address _synthIn, address _account, uint _amountIn, address _outAsset, bytes[] memory priceUpdateData) external virtual;

    /* -------------------------------------------------------------------------- */
    /*                                 Events                                     */
    /* -------------------------------------------------------------------------- */
    event IssuerAllocUpdated(uint issuerAlloc);
    event PriceOracleUpdated(address indexed priceOracle);
    event FeeTokenUpdated(address indexed feeToken);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../utils/oracle/IPriceOracle.sol";
import "../libraries/DataTypes.sol";

abstract contract PoolStorage {
    /// @notice The address of the price oracle
    IPriceOracle public priceOracle;

    /// @notice Issuer allocation (%) of fee
    uint public issuerAlloc;

    /// @notice Basis points constant. 10000 basis points * 1e18 = 100%
    uint public constant BASIS_POINTS = 10000;
    uint public constant SCALER = 1e18;

    address public WETH_ADDRESS;

    /// @notice The synth token used to pass on to vault as fee
    address public feeToken;

    /// @notice If synth is enabled
    mapping(address => DataTypes.Synth) public synths;
    /// @notice The list of synths in the pool. Needed to calculate total debt
    address[] public synthsList;

    /// @notice Collateral asset addresses. User => Collateral => Balance
    mapping(address => mapping(address => uint256)) public accountCollateralBalance;
    /// @notice Checks in account has entered the market
    // market -> account -> isMember
    mapping(address => mapping(address => bool)) public accountMembership;
    /// @notice Collaterals the user has deposited
    mapping(address => address[]) public accountCollaterals;

    /// @notice Mapping from collateral asset address to collateral data
    mapping(address => DataTypes.Collateral) public collaterals;

    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20X is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function flashFee(address token, uint256 amount) external view returns (uint256);

    function maxFlashLoan(address token) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;
import "../utils/oracle/IPriceOracle.sol";

abstract contract ISyntheX {

    function claimReward(
        address[] memory _rewardTokens,
        address holder,
        address[] memory _pools
    ) external virtual;

    function getRewardsAccrued(
        address[] memory _rewardTokens,
        address holder,
        address[] memory _pools
    ) external virtual returns (uint256[] memory);

    function distribute(uint256 _totalSupply)
        external 
        virtual;

    function distribute(
        address _account,
        uint256 _totalSupply,
        uint256 _balance
    ) external virtual;

    // ERC165
    function supportsInterface(bytes4 interfaceId)
        external
        virtual
        view
        returns (bool);

    event SetPoolRewardSpeed(
        address indexed rewardToken,
        address indexed pool,
        uint256 speed
    );
    event DistributedReward(
        address[] rewardTokens,
        address indexed pool,
        address _account,
        uint256[] accountDelta,
        uint256[] rewardIndex
    );

    function vault() external virtual view returns(address);

    function isL0Admin(address _account) external virtual view returns (bool);

    function isL1Admin(address _account) external virtual view returns (bool);

    function isL2Admin(address _account) external virtual view returns (bool);
}

// SPDX-License-Identifier: MIT

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address to, uint value) external returns (bool);
    function approve(address guy, uint wad) external returns (bool);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter
 * @author Aave
 * @notice Interface for the Aave price oracle.
 */
interface IPriceOracleGetter {
  /**
   * @notice Returns the base currency address
   * @dev Address 0x0 is reserved for USD as base currency.
   * @return Returns the base currency address.
   */
  function BASE_CURRENCY() external view returns (address);

  /**
   * @notice Returns the base currency unit
   * @dev 1 ether for ETH, 1e8 for USD.
   * @return Returns the base currency unit.
   */
  function BASE_CURRENCY_UNIT() external view returns (uint);

  /**
   * @notice Returns the asset price in the base currency
   * @param asset The address of the asset
   * @return The price of the asset
   */
  function getAssetPrice(address asset) external view returns (uint);
}

/**
 * @title IPriceOracle interface
 * @dev IAaveOracle without the address provider 
 * @author Aave
 * @notice Defines the basic interface for the Aave Oracle
 */
interface IPriceOracle is IPriceOracleGetter {
  /**
   * @dev Emitted after the base currency is set
   * @param baseCurrency The base currency of used for price quotes
   * @param baseCurrencyUnit The unit of the base currency
   */
  event BaseCurrencySet(address indexed baseCurrency, uint256 baseCurrencyUnit);

  /**
   * @dev Emitted after the price source of an asset is updated
   * @param asset The address of the asset
   * @param source The price source of the asset
   */
  event AssetSourceUpdated(address indexed asset, address indexed source);

  /**
   * @dev Emitted after the address of fallback oracle is updated
   * @param fallbackOracle The address of the fallback oracle
   */
  event FallbackOracleUpdated(address indexed fallbackOracle);

  /**
   * @notice Sets or replaces price sources of assets
   * @param assets The addresses of the assets
   * @param sources The addresses of the price sources
   */
  function setAssetSources(address[] calldata assets, address[] calldata sources) external;

  /**
   * @notice Sets the fallback oracle
   * @param fallbackOracle The address of the fallback oracle
   */
  function setFallbackOracle(address fallbackOracle) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetsPrices(address[] calldata assets) external view returns (uint[] memory);

  /**
   * @notice Returns the address of the source for an asset address
   * @param asset The address of the asset
   * @return The address of the source
   */
  function getSourceOfAsset(address asset) external view returns (address);

  /**
   * @notice Returns the address of the fallback oracle
   * @return The address of the fallback oracle
   */
  function getFallbackOracle() external view returns (address);

  /**
   * @notice Updates the prices of the assets passed as parameter
   */
  function updatePrices(bytes[] calldata pythUpdateData) external;
}