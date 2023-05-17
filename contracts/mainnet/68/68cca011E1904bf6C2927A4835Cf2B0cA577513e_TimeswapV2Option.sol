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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for errors
/// @author Timeswap Labs
/// @dev Common error messages
library Error {
  /// @dev Reverts when input is zero.
  error ZeroInput();

  /// @dev Reverts when output is zero.
  error ZeroOutput();

  /// @dev Reverts when a value cannot be zero.
  error CannotBeZero();

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  error AlreadyHaveLiquidity(uint160 liquidity);

  /// @dev Reverts when a pool requires liquidity.
  error RequireLiquidity();

  /// @dev Reverts when a given address is the zero address.
  error ZeroAddress();

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  error IncorrectMaturity(uint256 maturity);

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactiveOption(uint256 strike, uint256 maturity);

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error InactivePool(uint256 strike, uint256 maturity);

  /// @dev Reverts when a liquidity token is inactive.
  error InactiveLiquidityTokenChoice();

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  error ZeroSqrtInterestRate(uint256 strike, uint256 maturity);

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error AlreadyMatured(uint256 maturity, uint96 blockTimestamp);

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  error StillActive(uint256 maturity, uint96 blockTimestamp);

  /// @dev Token amount not received.
  /// @param minuend The amount being subtracted.
  /// @param subtrahend The amount subtracting.
  error NotEnoughReceived(uint256 minuend, uint256 subtrahend);

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  error DeadlineReached(uint256 deadline);

  /// @dev Reverts when input is zero.
  function zeroInput() internal pure {
    revert ZeroInput();
  }

  /// @dev Reverts when output is zero.
  function zeroOutput() internal pure {
    revert ZeroOutput();
  }

  /// @dev Reverts when a value cannot be zero.
  function cannotBeZero() internal pure {
    revert CannotBeZero();
  }

  /// @dev Reverts when a pool already have liquidity.
  /// @param liquidity The liquidity amount that already existed in the pool.
  function alreadyHaveLiquidity(uint160 liquidity) internal pure {
    revert AlreadyHaveLiquidity(liquidity);
  }

  /// @dev Reverts when a pool requires liquidity.
  function requireLiquidity() internal pure {
    revert RequireLiquidity();
  }

  /// @dev Reverts when a given address is the zero address.
  function zeroAddress() internal pure {
    revert ZeroAddress();
  }

  /// @dev Reverts when the maturity given is not withing uint96.
  /// @param maturity The maturity being inquired.
  function incorrectMaturity(uint256 maturity) internal pure {
    revert IncorrectMaturity(maturity);
  }

  /// @dev Reverts when the maturity is already matured.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function alreadyMatured(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert AlreadyMatured(maturity, blockTimestamp);
  }

  /// @dev Reverts when the maturity is still active.
  /// @param maturity The maturity.
  /// @param blockTimestamp The current block timestamp.
  function stillActive(uint256 maturity, uint96 blockTimestamp) internal pure {
    revert StillActive(maturity, blockTimestamp);
  }

  /// @dev The deadline of a transaction has been reached.
  /// @param deadline The deadline set.
  function deadlineReached(uint256 deadline) internal pure {
    revert DeadlineReached(deadline);
  }

  /// @dev Reverts when an option of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  function inactiveOptionChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactiveOption(strike, maturity);
  }

  /// @dev Reverts when a pool of given strike and maturity is still inactive.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function inactivePoolChoice(uint256 strike, uint256 maturity) internal pure {
    revert InactivePool(strike, maturity);
  }

  /// @dev Reverts when the square root interest rate is zero.
  /// @param strike The chosen strike.
  /// @param maturity The chosen maturity.
  function zeroSqrtInterestRate(uint256 strike, uint256 maturity) internal pure {
    revert ZeroSqrtInterestRate(strike, maturity);
  }

  /// @dev Reverts when a liquidity token is inactive.
  function inactiveLiquidityTokenChoice() internal pure {
    revert InactiveLiquidityTokenChoice();
  }

  /// @dev Reverts when token amount not received.
  /// @param balance The balance amount being subtracted.
  /// @param balanceTarget The amount target.
  function checkEnough(uint256 balance, uint256 balanceTarget) internal pure {
    if (balance < balanceTarget) revert NotEnoughReceived(balance, balanceTarget);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Math} from "./Math.sol";

/// @title Library for math utils for uint512
/// @author Timeswap Labs
library FullMath {
  using Math for uint256;

  /// @dev Reverts when modulo by zero.
  error ModuloByZero();

  /// @dev Reverts when add512 overflows over uint512.
  /// @param addendA0 The least significant part of first addend.
  /// @param addendA1 The most significant part of first addend.
  /// @param addendB0 The least significant part of second addend.
  /// @param addendB1 The most significant part of second addend.
  error AddOverflow(uint256 addendA0, uint256 addendA1, uint256 addendB0, uint256 addendB1);

  /// @dev Reverts when sub512 underflows.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  error SubUnderflow(uint256 minuend0, uint256 minuend1, uint256 subtrahend0, uint256 subtrahend1);

  /// @dev Reverts when div512To256 overflows over uint256.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  error DivOverflow(uint256 dividend0, uint256 dividend1, uint256 divisor);

  /// @dev Reverts when mulDiv overflows over uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  error MulDivOverflow(uint256 multiplicand, uint256 multiplier, uint256 divisor);

  /// @dev Calculates the sum of two uint512 numbers.
  /// @notice Reverts on overflow over uint512.
  /// @param addendA0 The least significant part of addendA.
  /// @param addendA1 The most significant part of addendA.
  /// @param addendB0 The least significant part of addendB.
  /// @param addendB1 The most significant part of addendB.
  /// @return sum0 The least significant part of sum.
  /// @return sum1 The most significant part of sum.
  function add512(
    uint256 addendA0,
    uint256 addendA1,
    uint256 addendB0,
    uint256 addendB1
  ) internal pure returns (uint256 sum0, uint256 sum1) {
    uint256 carry;
    assembly {
      sum0 := add(addendA0, addendB0)
      carry := lt(sum0, addendA0)
      sum1 := add(add(addendA1, addendB1), carry)
    }

    if (carry == 0 ? addendA1 > sum1 : (sum1 == 0 || addendA1 > sum1 - 1))
      revert AddOverflow(addendA0, addendA1, addendB0, addendB1);
  }

  /// @dev Calculates the difference of two uint512 numbers.
  /// @notice Reverts on underflow.
  /// @param minuend0 The least significant part of minuend.
  /// @param minuend1 The most significant part of minuend.
  /// @param subtrahend0 The least significant part of subtrahend.
  /// @param subtrahend1 The most significant part of subtrahend.
  /// @return difference0 The least significant part of difference.
  /// @return difference1 The most significant part of difference.
  function sub512(
    uint256 minuend0,
    uint256 minuend1,
    uint256 subtrahend0,
    uint256 subtrahend1
  ) internal pure returns (uint256 difference0, uint256 difference1) {
    assembly {
      difference0 := sub(minuend0, subtrahend0)
      difference1 := sub(sub(minuend1, subtrahend1), lt(minuend0, subtrahend0))
    }

    if (subtrahend1 > minuend1 || (subtrahend1 == minuend1 && subtrahend0 > minuend0))
      revert SubUnderflow(minuend0, minuend1, subtrahend0, subtrahend1);
  }

  /// @dev Calculate the product of two uint256 numbers that may result to uint512 product.
  /// @notice Can never overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product0 The least significant part of product.
  /// @return product1 The most significant part of product.
  function mul512(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product0, uint256 product1) {
    assembly {
      let mm := mulmod(multiplicand, multiplier, not(0))
      product0 := mul(multiplicand, multiplier)
      product1 := sub(sub(mm, product0), lt(mm, product0))
    }
  }

  /// @dev Divide 2 to 256 power by the divisor.
  /// @dev Rounds down the result.
  /// @notice Reverts when divide by zero.
  /// @param divisor The divisor.
  /// @return quotient The quotient.
  function div256(uint256 divisor) private pure returns (uint256 quotient) {
    if (divisor == 0) revert Math.DivideByZero();
    assembly {
      quotient := add(div(sub(0, divisor), divisor), 1)
    }
  }

  /// @dev Compute 2 to 256 power modulo the given value.
  /// @notice Reverts when modulo by zero.
  /// @param value The given value.
  /// @return result The result.
  function mod256(uint256 value) private pure returns (uint256 result) {
    if (value == 0) revert ModuloByZero();
    assembly {
      result := mod(sub(0, value), value)
    }
  }

  /// @dev Divide a uint512 number by uint256 number to return a uint512 number.
  /// @dev Rounds down the result.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor
  ) private pure returns (uint256 quotient0, uint256 quotient1) {
    if (dividend1 == 0) quotient0 = dividend0.div(divisor, false);
    else {
      uint256 q = div256(divisor);
      uint256 r = mod256(divisor);
      while (dividend1 != 0) {
        (uint256 t0, uint256 t1) = mul512(dividend1, q);
        (quotient0, quotient1) = add512(quotient0, quotient1, t0, t1);
        (t0, t1) = mul512(dividend1, r);
        (dividend0, dividend1) = add512(t0, t1, dividend0, 0);
      }
      (quotient0, quotient1) = add512(quotient0, quotient1, dividend0.div(divisor, false), 0);
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient The quotient.
  function div512To256(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient) {
    uint256 quotient1;
    (quotient, quotient1) = div512(dividend0, dividend1, divisor);

    if (quotient1 != 0) revert DivOverflow(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient, divisor);
      if (dividend1 > productA1 || dividend0 > productA0) quotient++;
    }
  }

  /// @dev Divide a uint512 number by a uint256 number.
  /// @notice Skips div512 if dividend1 is zero.
  /// @param dividend0 The least significant part of dividend.
  /// @param dividend1 The most significant part of dividend.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @param quotient0 The least significant part of quotient.
  /// @param quotient1 The most significant part of quotient.
  function div512(
    uint256 dividend0,
    uint256 dividend1,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 quotient0, uint256 quotient1) {
    (quotient0, quotient1) = div512(dividend0, dividend1, divisor);

    if (roundUp) {
      (uint256 productA0, uint256 productA1) = mul512(quotient0, divisor);
      productA1 += (quotient1 * divisor);
      if (dividend1 > productA1 || dividend0 > productA0) {
        if (quotient0 == type(uint256).max) {
          quotient0 = 0;
          quotient1++;
        } else quotient0++;
      }
    }
  }

  /// @dev Multiply two uint256 number then divide it by a uint256 number.
  /// @notice Skips mulDiv if product of multiplicand and multiplier is uint256 number.
  /// @dev Reverts when result is greater than uint256.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @param divisor The divisor.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function mulDiv(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256 result) {
    (uint256 product0, uint256 product1) = mul512(multiplicand, multiplier);

    // Handle non-overflow cases, 256 by 256 division
    if (product1 == 0) return result = product0.div(divisor, roundUp);

    // Make sure the result is less than 2**256.
    // Also prevents divisor == 0
    if (divisor <= product1) revert MulDivOverflow(multiplicand, multiplier, divisor);

    unchecked {
      ///////////////////////////////////////////////
      // 512 by 256 division.
      ///////////////////////////////////////////////

      // Make division exact by subtracting the remainder from [product1 product0]
      // Compute remainder using mulmod
      uint256 remainder;
      assembly {
        remainder := mulmod(multiplicand, multiplier, divisor)
      }
      // Subtract 256 bit number from 512 bit number
      assembly {
        product1 := sub(product1, gt(remainder, product0))
        product0 := sub(product0, remainder)
      }

      // Factor powers of two out of divisor
      // Compute largest power of two divisor of divisor.
      // Always >= 1.
      uint256 twos;
      twos = (0 - divisor) & divisor;
      // Divide denominator by power of two
      assembly {
        divisor := div(divisor, twos)
      }

      // Divide [product1 product0] by the factors of two
      assembly {
        product0 := div(product0, twos)
      }
      // Shift in bits from product1 into product0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      product0 |= product1 * twos;

      // Invert divisor mod 2**256
      // Now that divisor is an odd number, it has an inverse
      // modulo 2**256 such that divisor * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, divisor * inv = 1 mod 2**4
      uint256 inv;
      inv = (3 * divisor) ^ 2;

      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - divisor * inv; // inverse mod 2**8
      inv *= 2 - divisor * inv; // inverse mod 2**16
      inv *= 2 - divisor * inv; // inverse mod 2**32
      inv *= 2 - divisor * inv; // inverse mod 2**64
      inv *= 2 - divisor * inv; // inverse mod 2**128
      inv *= 2 - divisor * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of divisor. This will give us the
      // correct result modulo 2**256. Since the preconditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and product1
      // is no longer required.
      result = product0 * inv;
    }

    if (roundUp && mulmod(multiplicand, multiplier, divisor) != 0) result++;
  }

  /// @dev Get the square root of a uint512 number.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The result.
  function sqrt512(uint256 value0, uint256 value1, bool roundUp) internal pure returns (uint256 result) {
    if (value1 == 0) result = value0.sqrt(roundUp);
    else {
      uint256 estimate = sqrt512Estimate(value0, value1, type(uint256).max);
      result = type(uint256).max;
      while (estimate < result) {
        result = estimate;
        estimate = sqrt512Estimate(value0, value1, estimate);
      }

      if (roundUp) {
        (uint256 product0, uint256 product1) = mul512(result, result);
        if (value1 > product1 || value0 > product0) result++;
      }
    }
  }

  /// @dev An iterative process of getting sqrt512 following Newtonian method.
  /// @param value0 The least significant of the number.
  /// @param value1 The most significant of the number.
  /// @param currentEstimate The current estimate of the iteration.
  /// @param estimate The new estimate of the iteration.
  function sqrt512Estimate(
    uint256 value0,
    uint256 value1,
    uint256 currentEstimate
  ) private pure returns (uint256 estimate) {
    uint256 r0 = div512To256(value0, value1, currentEstimate, false);
    uint256 r1;
    (r0, r1) = add512(r0, 0, currentEstimate, 0);
    estimate = div512To256(r0, r1, 2, false);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Library for math related utils
/// @author Timeswap Labs
library Math {
  /// @dev Reverts when divide by zero.
  error DivideByZero();
  error Overflow();

  /// @dev Add two uint256.
  /// @notice May overflow.
  /// @param addend1 The first addend.
  /// @param addend2 The second addend.
  /// @return sum The sum.
  function unsafeAdd(uint256 addend1, uint256 addend2) internal pure returns (uint256 sum) {
    unchecked {
      sum = addend1 + addend2;
    }
  }

  /// @dev Subtract two uint256.
  /// @notice May underflow.
  /// @param minuend The minuend.
  /// @param subtrahend The subtrahend.
  /// @return difference The difference.
  function unsafeSub(uint256 minuend, uint256 subtrahend) internal pure returns (uint256 difference) {
    unchecked {
      difference = minuend - subtrahend;
    }
  }

  /// @dev Multiply two uint256.
  /// @notice May overflow.
  /// @param multiplicand The multiplicand.
  /// @param multiplier The multiplier.
  /// @return product The product.
  function unsafeMul(uint256 multiplicand, uint256 multiplier) internal pure returns (uint256 product) {
    unchecked {
      product = multiplicand * multiplier;
    }
  }

  /// @dev Divide two uint256.
  /// @notice Reverts when divide by zero.
  /// @param dividend The dividend.
  /// @param divisor The divisor.
  //// @param roundUp Round up the result when true. Round down if false.
  /// @return quotient The quotient.
  function div(uint256 dividend, uint256 divisor, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend / divisor;

    if (roundUp && dividend % divisor != 0) quotient++;
  }

  /// @dev Shift right a uint256 number.
  /// @param dividend The dividend.
  /// @param divisorBit The divisor in bits.
  /// @param roundUp True if ceiling the result. False if floor the result.
  /// @return quotient The quotient.
  function shr(uint256 dividend, uint8 divisorBit, bool roundUp) internal pure returns (uint256 quotient) {
    quotient = dividend >> divisorBit;

    if (roundUp && dividend % (1 << divisorBit) != 0) quotient++;
  }

  /// @dev Gets the square root of a value.
  /// @param value The value being square rooted.
  /// @param roundUp Round up the result when true. Round down if false.
  /// @return result The resulting value of the square root.
  function sqrt(uint256 value, bool roundUp) internal pure returns (uint256 result) {
    if (value == type(uint256).max) return result = type(uint128).max;
    if (value == 0) return 0;
    unchecked {
      uint256 estimate = (value + 1) >> 1;
      result = value;
      while (estimate < result) {
        result = estimate;
        estimate = (value / estimate + estimate) >> 1;
      }
    }

    if (roundUp && result * result < value) result++;
  }

  /// @dev Gets the min of two uint256 number.
  /// @param value1 The first value to be compared.
  /// @param value2 The second value to be compared.
  /// @return result The min result.
  function min(uint256 value1, uint256 value2) internal pure returns (uint256 result) {
    return value1 < value2 ? value1 : value2;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FullMath} from "./FullMath.sol";

/// @title library for converting strike prices.
/// @dev When strike is greater than uint128, the base token is denominated as token0 (which is the smaller address token).
/// @dev When strike is uint128, the base token is denominated as token1 (which is the larger address).
library StrikeConversion {
  /// @dev When zeroToOne, converts a number in multiple of strike.
  /// @dev When oneToZero, converts a number in multiple of 1 / strike.
  /// @param amount The amount to be converted.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function convert(uint256 amount, uint256 strike, bool zeroToOne, bool roundUp) internal pure returns (uint256) {
    return
      zeroToOne
        ? FullMath.mulDiv(amount, strike, uint256(1) << 128, roundUp)
        : FullMath.mulDiv(amount, uint256(1) << 128, strike, roundUp);
  }

  /// @dev When toOne, converts a base denomination to token1 denomination.
  /// @dev When toZero, converts a base denomination to token0 denomination.
  /// @param amount The amount ot be converted. Token0 amount when zeroToOne. Token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param toOne ToOne if it is true, ToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function turn(uint256 amount, uint256 strike, bool toOne, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (toOne ? convert(amount, strike, true, roundUp) : amount)
        : (toOne ? amount : convert(amount, strike, false, roundUp));
  }

  /// @dev Combine and add token0Amount and token1Amount into base token amount.
  /// @param amount0 The token0 amount to be combined.
  /// @param amount1 The token1 amount to be combined.
  /// @param strike The strike multiple conversion.
  /// @param roundUp Round up the result when true. Round down if false.
  function combine(uint256 amount0, uint256 amount1, uint256 strike, bool roundUp) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? amount0 + convert(amount1, strike, false, roundUp)
        : amount1 + convert(amount0, strike, true, roundUp);
  }

  /// @dev When zeroToOne, given a larger base amount, and token0 amount, get the difference token1 amount.
  /// @dev When oneToZero, given a larger base amount, and toekn1 amount, get the difference token0 amount.
  /// @param base The larger base amount.
  /// @param amount The token0 amount when zeroToOne, the token1 amount when oneToZero.
  /// @param strike The strike multiple conversion.
  /// @param zeroToOne ZeroToOne if it is true. OneToZero if it is false.
  /// @param roundUp Round up the result when true. Round down if false.
  function dif(
    uint256 base,
    uint256 amount,
    uint256 strike,
    bool zeroToOne,
    bool roundUp
  ) internal pure returns (uint256) {
    return
      strike > type(uint128).max
        ? (zeroToOne ? convert(base - amount, strike, true, roundUp) : base - convert(amount, strike, false, !roundUp))
        : (zeroToOne ? base - convert(amount, strike, true, !roundUp) : convert(base - amount, strike, false, roundUp));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The three type of native token positions.
/// @dev Long0 is denominated as the underlying Token0.
/// @dev Long1 is denominated as the underlying Token1.
/// @dev When strike greater than uint128 then Short is denominated as Token0 (the base token denomination).
/// @dev When strike is uint128 then Short is denominated as Token1 (the base token denomination).
enum TimeswapV2OptionPosition {
  Long0,
  Long1,
  Short
}

/// @title library for position utils
/// @author Timeswap Labs
/// @dev Helper functions for the TimeswapOptionPosition enum.
library PositionLibrary {
  /// @dev Reverts when the given type of position is invalid.
  error InvalidPosition();

  /// @dev Checks that the position input is correct.
  /// @param position The position input.
  function check(TimeswapV2OptionPosition position) internal pure {
    if (uint256(position) >= 3) revert InvalidPosition();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev The different input for the mint transaction.
enum TimeswapV2OptionMint {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the burn transaction.
enum TimeswapV2OptionBurn {
  GivenTokensAndLongs,
  GivenShorts
}

/// @dev The different input for the swap transaction.
enum TimeswapV2OptionSwap {
  GivenToken0AndLong0,
  GivenToken1AndLong1
}

/// @dev The different input for the collect transaction.
enum TimeswapV2OptionCollect {
  GivenShort,
  GivenToken0,
  GivenToken1
}

/// @title library for transaction checks
/// @author Timeswap Labs
/// @dev Helper functions for the all enums in this module.
library TransactionLibrary {
  /// @dev Reverts when the given type of transaction is invalid.
  error InvalidTransaction();

  /// @dev checks that the given input is correct.
  /// @param transaction the mint transaction input.
  function check(TimeswapV2OptionMint transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the burn transaction input.
  function check(TimeswapV2OptionBurn transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the swap transaction input.
  function check(TimeswapV2OptionSwap transaction) internal pure {
    if (uint256(transaction) >= 2) revert InvalidTransaction();
  }

  /// @dev checks that the given input is correct.
  /// @param transaction the collect transaction input.
  function check(TimeswapV2OptionCollect transaction) internal pure {
    if (uint256(transaction) >= 3) revert InvalidTransaction();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionBurnCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#burn
/// @notice Any contract that calls ITimeswapV2Option#burn can optionally implement this interface.
interface ITimeswapV2OptionBurnCallback {
  /// @notice Called to `msg.sender` after initiating a burn from ITimeswapV2Option#burn.
  /// @dev In the implementation, you must have enough long0 positions, long1 positions, and short positions for the burn transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The token0 and token1 will already transferred to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionBurnCallback(
    TimeswapV2OptionBurnCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionCollectCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#collect
/// @notice Any contract that calls ITimeswapV2Option#collect can optionally implement this interface.
interface ITimeswapV2OptionCollectCallback {
  /// @notice Called to `msg.sender` after initiating a collect from ITimeswapV2Option#collect.
  /// @dev In the implementation, you must have enough short positions for the collect transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The token0 and token1 will already transferred to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionCollectCallback(
    TimeswapV2OptionCollectCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionMintCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#mint
/// @notice Any contract that calls ITimeswapV2Option#mint must implement this interface.
interface ITimeswapV2OptionMintCallback {
  /// @notice Called to `msg.sender` after initiating a mint from ITimeswapV2Option#mint.
  /// @dev In the implementation, you must transfer token0 and token1 for the mint transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions, long1 positions, and/or short positions will already minted to the recipients.
  /// @param param The parameter of the callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionMintCallback(
    TimeswapV2OptionMintCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionSwapCallbackParam} from "../../structs/CallbackParam.sol";

/// @title Callback for ITimeswapV2Option#swap
/// @notice Any contract that calls ITimeswapV2Option#swap must implement this interface.
interface ITimeswapV2OptionSwapCallback {
  /// @notice Called to `msg.sender` after initiating a swap from ITimeswapV2Option#swap.
  /// @dev In the implementation, you must transfer token0 for the swap transaction.
  /// The caller of this method must be checked to be a Timeswap V2 Option pair deployed by the canonical Timeswap V2 Factory.
  /// @dev The long0 positions or long1 positions will already minted to the recipients.
  /// @param param The param of the swap callback.
  /// @return data The bytes code returned from the callback.
  function timeswapV2OptionSwapCallback(
    TimeswapV2OptionSwapCallbackParam calldata param
  ) external returns (bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {TimeswapV2OptionPosition} from "../enums/Position.sol";
import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam} from "../structs/Param.sol";
import {StrikeAndMaturity} from "../structs/StrikeAndMaturity.sol";

/// @title An interface for a contract that deploys Timeswap V2 Option pair contracts
/// @notice A Timeswap V2 Option pair facilitates option mechanics between any two assets that strictly conform
/// to the ERC20 specification.
interface ITimeswapV2Option {
  /* ===== EVENT ===== */

  /// @dev Emits when a position is transferred.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param from The address of the caller of the transferPosition function.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  event TransferPosition(
    uint256 indexed strike,
    uint256 indexed maturity,
    address from,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  );

  /// @dev Emits when a mint transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param long0To The address of the recipient of long token0 position.
  /// @param long1To The address of the recipient of long token1 position.
  /// @param shortTo The address of the recipient of short position.
  /// @param token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @param shortAmount The amount of short minted.
  event Mint(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address long0To,
    address long1To,
    address shortTo,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a burn transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @param token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @param shortAmount The amount of short burnt.
  event Burn(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount,
    uint256 shortAmount
  );

  /// @dev Emits when a swap transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param tokenTo The address of the recipient of token0 or token1.
  /// @param longTo The address of the recipient of long token0 or long token1.
  /// @param isLong0toLong1 The direction of the swap. More information in the Transaction module.
  /// @param token0AndLong0Amount If the direction is from long0 to long1, the amount of token0 withdrawn and long0 burnt.
  /// If the direction is from long1 to long0, the amount of token0 deposited and long0 minted.
  /// @param token1AndLong1Amount If the direction is from long0 to long1, the amount of token1 deposited and long1 minted.
  /// If the direction is from long1 to long0, the amount of token1 withdrawn and long1 burnt.
  event Swap(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address tokenTo,
    address longTo,
    bool isLong0toLong1,
    uint256 token0AndLong0Amount,
    uint256 token1AndLong1Amount
  );

  /// @dev Emits when a collect transaction is called.
  /// @param strike The strike ratio of token1 per token0 of the option.
  /// @param maturity The maturity of the option.
  /// @param caller The address of the caller of the mint function.
  /// @param token0To The address of the recipient of token0.
  /// @param token1To The address of the recipient of token1.
  /// @param long0AndToken0Amount The amount of token0 withdrawn.
  /// @param long1Amount The sum of long0AndToken0Amount and this amount is the total short amount burnt.
  /// @param token1Amount The amount of token1 withdrawn.
  event Collect(
    uint256 indexed strike,
    uint256 indexed maturity,
    address indexed caller,
    address token0To,
    address token1To,
    uint256 long0AndToken0Amount,
    uint256 long1Amount,
    uint256 token1Amount
  );

  /* ===== VIEW ===== */

  /// @dev Returns the factory address that deployed this contract.
  function optionFactory() external view returns (address);

  /// @dev Returns the first ERC20 token address of the pair.
  function token0() external view returns (address);

  /// @dev Returns the second ERC20 token address of the pair.
  function token1() external view returns (address);

  /// @dev Get the strike and maturity of the option in the option enumeration list.
  /// @param id The chosen index.
  function getByIndex(uint256 id) external view returns (StrikeAndMaturity memory);

  /// @dev Number of options being interacted.
  function numberOfOptions() external view returns (uint256);

  /// @dev Returns the total position of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The total position.
  function totalPosition(
    uint256 strike,
    uint256 maturity,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /// @dev Returns the position of an owner of the option.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param owner The address of the owner of the position.
  /// @param position The type of position inquired. More information in the Position module.
  /// @return balance The user position.
  function positionOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    TimeswapV2OptionPosition position
  ) external view returns (uint256 balance);

  /* ===== UPDATE ===== */

  /// @dev Transfer position to another address.
  /// @param strike The strike ratio of token1 per token0 of the position.
  /// @param maturity The maturity of the position.
  /// @param to The address of the recipient of the position.
  /// @param position The type of position transferred. More information in the Position module.
  /// @param amount The amount of balance transferred.
  function transferPosition(
    uint256 strike,
    uint256 maturity,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) external;

  /// @dev Mint position.
  /// Mint long token0 position when token0 is deposited.
  /// Mint long token1 position when token1 is deposited.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the mint function.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  /// @return data The additional data return.
  function mint(
    TimeswapV2OptionMintParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev Burn short position.
  /// Withdraw token0, when long token0 is burnt.
  /// Withdraw token1, when long token1 is burnt.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the burn function.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    TimeswapV2OptionBurnParam calldata param
  )
    external
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data);

  /// @dev If the direction is from long token0 to long token1, burn long token0 and mint equivalent long token1,
  /// also deposit token1 and withdraw token0.
  /// If the direction is from long token1 to long token0, burn long token1 and mint equivalent long token0,
  /// also deposit token0 and withdraw token1.
  /// @dev Can only be called before the maturity of the pool.
  /// @param param The parameters for the swap function.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  /// @return data The additional data return.
  function swap(
    TimeswapV2OptionSwapParam calldata param
  ) external returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data);

  /// @dev Burn short position, withdraw token0 and token1.
  /// @dev Can only be called after the maturity of the pool.
  /// @param param The parameters for the collect function.
  /// @return token0Amount The amount of token0 withdrawn.
  /// @return token1Amount The amount of token1 withdrawn.
  /// @return shortAmount The amount of short burnt.
  function collect(
    TimeswapV2OptionCollectParam calldata param
  ) external returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title An interface for a contract that is capable of deploying Timeswap V2 Option
/// @notice A contract that constructs a pair must implement this to pass arguments to the pair.
/// @dev This is used to avoid having constructor arguments in the pair contract, which results in the init code hash
/// of the pair being constant allowing the CREATE2 address of the pair to be cheaply computed on-chain.
interface ITimeswapV2OptionDeployer {
  /* ===== VIEW ===== */

  /// @notice Get the parameters to be used in constructing the pair, set transiently during pair creation.
  /// @dev Called by the pair constructor to fetch the parameters of the pair.
  /// @return optionFactory The factory address.
  /// @param token0 The first ERC20 token address of the pair.
  /// @param token1 The second ERC20 token address of the pair.
  function parameter() external view returns (address optionFactory, address token0, address token1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {FullMath} from "@timeswap-labs/v2-library/contracts/FullMath.sol";

/// @title library for proportion utils
/// @author Timeswap Labs
library Proportion {
  /// @dev Get the balance proportion calculation.
  /// @notice Round down the result.
  /// @param multiplicand The multiplicand balance.
  /// @param multiplier The multiplier balance.
  /// @param divisor The divisor balance.
  function proportion(
    uint256 multiplicand,
    uint256 multiplier,
    uint256 divisor,
    bool roundUp
  ) internal pure returns (uint256) {
    return FullMath.mulDiv(multiplicand, multiplier, divisor, roundUp);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract.
contract NoDelegateCall {
  /* ===== ERROR ===== */

  /// @dev Reverts when called using delegatecall.
  error CannotBeDelegateCalled();

  /* ===== MODEL ===== */

  /// @dev The original address of this contract.
  address private immutable original;

  /* ===== INIT ===== */

  constructor() {
    // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
    // In other words, this variable won't change when it's checked at runtime.
    original = address(this);
  }

  /* ===== MODIFIER ===== */

  /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
  /// and the use of immutable means the address bytes are copied in every place the modifier is used.
  function checkNotDelegateCall() private view {
    if (address(this) != original) revert CannotBeDelegateCalled();
  }

  /// @notice Prevents delegatecall into the modified method
  modifier noDelegateCall() {
    checkNotDelegateCall();
    _;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev Parameter for the mint callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be deposited and the long0 amount minted.
/// @param token1AndLong1Amount The token1 amount to be deposited and the long1 amount minted.
/// @param shortAmount The short amount minted.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionMintCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the burn callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0AndLong0Amount The token0 amount to be withdrawn and the long0 amount burnt.
/// @param token1AndLong1Amount The token1 amount to be withdrawn and the long1 amount burnt.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionBurnCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  uint256 shortAmount;
  bytes data;
}

/// @dev Parameter for the swap callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param isLong0ToLong1 True when swapping long0 for long1. False when swapping long1 for long0.
/// @param token0AndLong0Amount If isLong0ToLong1 is true, the amount of long0 burnt and token0 to be withdrawn.
/// If isLong0ToLong1 is false, the amount of long0 minted and token0 to be deposited.
/// @param token1AndLong1Amount If isLong0ToLong1 is true, the amount of long1 withdrawn and token0 to be deposited.
/// If isLong0ToLong1 is false, the amount of long1 burnt and token1 to be withdrawn.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionSwapCallbackParam {
  uint256 strike;
  uint256 maturity;
  bool isLong0ToLong1;
  uint256 token0AndLong0Amount;
  uint256 token1AndLong1Amount;
  bytes data;
}

/// @dev Parameter for the collect callback.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param token0Amount The token0 amount to be withdrawn.
/// @param token1Amount The token1 amount to be withdrawn.
/// @param shortAmount The short amount burnt.
/// @param data The bytes code data sent to the callback.
struct TimeswapV2OptionCollectCallbackParam {
  uint256 strike;
  uint256 maturity;
  uint256 token0Amount;
  uint256 token1Amount;
  uint256 shortAmount;
  bytes data;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {StrikeConversion} from "@timeswap-labs/v2-library/contracts/StrikeConversion.sol";
import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";
import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";

import {Proportion} from "../libraries/Proportion.sol";

import {TimeswapV2OptionPosition, PositionLibrary} from "../enums/Position.sol";
import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The state per option of a given strike and maturity
/// @param totalLong0 The total amount of long token0 supply.
/// @param totalLong1 The total amount of long token1 supply.
/// @param long0 The mapping of addresses to long token0 owned.
/// @param long1 The mapping of addresses to long token1 owned.
/// @param short The mapping of addresses to short owned.
/// @notice The sum of strike converted totalLong0 and strike converted totalLong1 is the total amount of short token supply.
struct Option {
  uint256 totalLong0;
  uint256 totalLong1;
  mapping(address => uint256) long0;
  mapping(address => uint256) long1;
  mapping(address => uint256) short;
}

/// @title library for position utils
/// @author Timeswap Labs
/// @dev internal library handling important business logic of the option.
library OptionLibrary {
  using Math for uint256;
  using Proportion for uint256;

  /// @dev Get the total position of Long0, Long1, or Short.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param position The position being inquired.
  /// @return balance The total supply positions result.
  function totalPosition(
    Option storage option,
    uint256 strike,
    TimeswapV2OptionPosition position
  ) internal view returns (uint256 balance) {
    if (position == TimeswapV2OptionPosition.Long0) balance = option.totalLong0;
    else if (position == TimeswapV2OptionPosition.Long1) balance = option.totalLong1;
    else if (position == TimeswapV2OptionPosition.Short)
      balance = StrikeConversion.combine(option.totalLong0, option.totalLong1, strike, true);
  }

  /// @dev Get the position of Long0, Long1, or Short owned by an address.
  /// @param option The option struct stored.
  /// @param owner The owner being inquired upon.
  /// @param position The position being inquired.
  /// @return balance The total positions owned result.
  function positionOf(
    Option storage option,
    address owner,
    TimeswapV2OptionPosition position
  ) internal view returns (uint256 balance) {
    if (position == TimeswapV2OptionPosition.Long0) balance = option.long0[owner];
    else if (position == TimeswapV2OptionPosition.Long1) balance = option.long1[owner];
    else if (position == TimeswapV2OptionPosition.Short) balance = option.short[owner];
  }

  /// @dev Transfer position of Long0, Long1, or Short to an address.
  /// @param option The option struct stored.
  /// @param to The target recipient.
  /// @param position The position being inquired.
  /// @param amount The amount being transferred.
  function transferPosition(
    Option storage option,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) internal {
    if (position == TimeswapV2OptionPosition.Long0) {
      option.long0[msg.sender] -= amount;
      option.long0[to] += amount;
    } else if (position == TimeswapV2OptionPosition.Long1) {
      option.long1[to] += amount;
      option.long1[msg.sender] -= amount;
    } else if (position == TimeswapV2OptionPosition.Short) {
      option.short[msg.sender] -= amount;
      option.short[to] += amount;
    }
  }

  /// @dev Handles main mint logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param long0To The recipient of long0 token.
  /// @param long1To The recipient of long1 token.
  /// @param shortTo The recipient of short token.
  /// @param transaction The mint transaction type.
  /// @param amount0 The first amount based on transaction type.
  /// @param amount1 The second amount based on transaction type.
  /// @return token0AndLong0Amount The amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount The amount of token1 deposited and long1 minted.
  /// @return shortAmount The amount of short minted.
  function mint(
    Option storage option,
    uint256 strike,
    address long0To,
    address long1To,
    address shortTo,
    TimeswapV2OptionMint transaction,
    uint256 amount0,
    uint256 amount1
  ) internal returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount) {
    if (transaction == TimeswapV2OptionMint.GivenTokensAndLongs)
      shortAmount = StrikeConversion.combine(
        token0AndLong0Amount = amount0,
        token1AndLong1Amount = amount1,
        strike,
        false
      );
    else if (transaction == TimeswapV2OptionMint.GivenShorts) {
      shortAmount = amount0 + amount1;
      token0AndLong0Amount = StrikeConversion.turn(amount0, strike, false, true);
      token1AndLong1Amount = StrikeConversion.turn(amount1, strike, true, true);
    }

    if (token0AndLong0Amount != 0) {
      option.totalLong0 += token0AndLong0Amount;
      option.long0[long0To] += token0AndLong0Amount;
    }

    if (token1AndLong1Amount != 0) {
      option.totalLong1 += token1AndLong1Amount;
      option.long1[long1To] += token1AndLong1Amount;
    }

    option.short[shortTo] += shortAmount;

    // Checks overflow. Reverts when overflow.
    StrikeConversion.combine(option.totalLong0, option.totalLong1, strike, true);
  }

  /// @dev Handles main burn logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param transaction The burn transaction type.
  /// @param amount0 The first amount based on transaction type.
  /// @param amount1 The second amount based on transaction type.
  /// @return token0AndLong0Amount The amount of token0 withdrawn and long0 burnt.
  /// @return token1AndLong1Amount The amount of token1 withdrawn and long1 burnt.
  /// @return shortAmount The amount of short burnt.
  function burn(
    Option storage option,
    uint256 strike,
    TimeswapV2OptionBurn transaction,
    uint256 amount0,
    uint256 amount1
  ) internal returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount) {
    if (transaction == TimeswapV2OptionBurn.GivenTokensAndLongs)
      shortAmount = StrikeConversion.combine(
        token0AndLong0Amount = amount0,
        token1AndLong1Amount = amount1,
        strike,
        true
      );
    else if (transaction == TimeswapV2OptionBurn.GivenShorts) {
      shortAmount = amount0 + amount1;
      token0AndLong0Amount = StrikeConversion.turn(amount0, strike, false, false);
      token1AndLong1Amount = StrikeConversion.turn(amount1, strike, true, false);
    }

    option.totalLong0 -= token0AndLong0Amount;
    option.totalLong1 -= token1AndLong1Amount;
  }

  /// @dev Handles main mint logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param longTo The recipient of long0 or long1 token.
  /// @param isLong0ToLong1 True if transforming long0 for long1 and false if transforming long1 for long0.
  /// @param transaction The swap transaction type.
  /// @param amount The amount based on transaction type.
  /// @return token0AndLong0Amount If direction is Long0ToLong1, the amount of token0 withdrawn and long0 burnt.
  /// If direction is Long1ToLong0, the amount of token0 deposited and long0 minted.
  /// @return token1AndLong1Amount If direction is Long0ToLong1, the amount of token1 deposited and long1 minted.
  /// If direction is Long1ToLong0, the amount of token1 withdrawn and long1 burnt.
  function swap(
    Option storage option,
    uint256 strike,
    address longTo,
    bool isLong0ToLong1,
    TimeswapV2OptionSwap transaction,
    uint256 amount
  ) internal returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount) {
    if (transaction == TimeswapV2OptionSwap.GivenToken0AndLong0) {
      token0AndLong0Amount = amount;
      token1AndLong1Amount = StrikeConversion.convert(token0AndLong0Amount, strike, true, isLong0ToLong1);
    } else if (transaction == TimeswapV2OptionSwap.GivenToken1AndLong1) {
      token1AndLong1Amount = amount;
      token0AndLong0Amount = StrikeConversion.convert(token1AndLong1Amount, strike, false, !isLong0ToLong1);
    }

    if (isLong0ToLong1) {
      option.totalLong0 -= token0AndLong0Amount;
      option.totalLong1 += token1AndLong1Amount;
      option.long1[longTo] += token1AndLong1Amount;
    } else {
      option.totalLong1 -= token1AndLong1Amount;
      option.totalLong0 += token0AndLong0Amount;
      option.long0[longTo] += token0AndLong0Amount;
    }
  }

  /// @dev Handles main mint logic.
  /// @param option The option struct stored.
  /// @param strike The strike of the option.
  /// @param transaction The collect transaction type.
  /// @param amount The amount based on transaction type.
  /// @return token0Amount The token0 amount withdrawn.
  /// @return token1Amount The token1 amount withdrawn.
  /// @return shortAmount The short amount burnt.
  function collect(
    Option storage option,
    uint256 strike,
    TimeswapV2OptionCollect transaction,
    uint256 amount
  ) internal returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount) {
    uint256 denominator = StrikeConversion.combine(option.totalLong0, option.totalLong1, strike, true);

    if (transaction == TimeswapV2OptionCollect.GivenShort) {
      shortAmount = amount;
      token0Amount = shortAmount.proportion(option.totalLong0, denominator, false);
      token1Amount = shortAmount.proportion(option.totalLong1, denominator, false);
    } else if (transaction == TimeswapV2OptionCollect.GivenToken0) {
      token0Amount = amount;
      shortAmount = token0Amount.proportion(denominator, option.totalLong0, true);
      token1Amount = shortAmount.proportion(option.totalLong1, denominator, false);
    } else if (transaction == TimeswapV2OptionCollect.GivenToken1) {
      token1Amount = amount;
      shortAmount = token1Amount.proportion(denominator, option.totalLong1, true);
      token0Amount = shortAmount.proportion(option.totalLong0, denominator, false);
    }

    option.totalLong0 -= token0Amount;
    option.totalLong1 -= token1Amount;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "../enums/Transaction.sol";

/// @dev The parameter to call the mint function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param long0To The recipient of long0 positions.
/// @param long1To The recipient of long1 positions.
/// @param shortTo The recipient of short positions.
/// @param transaction The type of mint transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 deposited, and amount of long0 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 deposited, and amount of long1 position minted.
/// If transaction is givenShorts, the amount of short minted, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the mint callback.
struct TimeswapV2OptionMintParam {
  uint256 strike;
  uint256 maturity;
  address long0To;
  address long1To;
  address shortTo;
  TimeswapV2OptionMint transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the burn function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of burn transaction, more information in Transaction module.
/// @param amount0 If transaction is givenTokensAndLongs, the amount of token0 withdrawn, and amount of long0 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long0 positions.
/// @param amount1 If transaction is givenTokensAndLongs, the amount of token1 withdrawn, and amount of long1 position burnt.
/// If transaction is givenShorts, the amount of short burnt, where the equivalent strike converted amount is long1 positions.
/// @param data The data to be sent to the function, which will go to the burn callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionBurnParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionBurn transaction;
  uint256 amount0;
  uint256 amount1;
  bytes data;
}

/// @dev The parameter to call the swap function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param tokenTo The recipient of token0 when isLong0ToLong1 or token1 when isLong1ToLong0.
/// @param longTo The recipient of long1 positions when isLong0ToLong1 or long0 when isLong1ToLong0.
/// @param isLong0ToLong1 Transform long0 positions to long1 positions when true. Transform long1 positions to long0 positions when false.
/// @param transaction The type of swap transaction, more information in Transaction module.
/// @param amount If isLong0ToLong1 and transaction is GivenToken0AndLong0, this is the amount of token0 withdrawn, and the amount of long0 position burnt.
/// If isLong1ToLong0 and transaction is GivenToken0AndLong0, this is the amount of token0 to be deposited, and the amount of long0 position minted.
/// If isLong0ToLong1 and transaction is GivenToken1AndLong1, this is the amount of token1 to be deposited, and the amount of long1 position minted.
/// If isLong1ToLong0 and transaction is GivenToken1AndLong1, this is the amount of token1 withdrawn, and the amount of long1 position burnt.
/// @param data The data to be sent to the function, which will go to the swap callback.
struct TimeswapV2OptionSwapParam {
  uint256 strike;
  uint256 maturity;
  address tokenTo;
  address longTo;
  bool isLong0ToLong1;
  TimeswapV2OptionSwap transaction;
  uint256 amount;
  bytes data;
}

/// @dev The parameter to call the collect function.
/// @param strike The strike of the option.
/// @param maturity The maturity of the option.
/// @param token0To The recipient of token0 withdrawn.
/// @param token1To The recipient of token1 withdrawn.
/// @param transaction The type of collect transaction, more information in Transaction module.
/// @param amount If transaction is GivenShort, the amount of short position burnt.
/// If transaction is GivenToken0, the amount of token0 withdrawn.
/// If transaction is GivenToken1, the amount of token1 withdrawn.
/// @param data The data to be sent to the function, which will go to the collect callback.
/// @notice If data length is zero, skips the callback.
struct TimeswapV2OptionCollectParam {
  uint256 strike;
  uint256 maturity;
  address token0To;
  address token1To;
  TimeswapV2OptionCollect transaction;
  uint256 amount;
  bytes data;
}

library ParamLibrary {
  /// @dev Sanity checks
  /// @param param the parameter for mint transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionMintParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.shortTo == address(0)) Error.zeroAddress();
    if (param.long0To == address(0)) Error.zeroAddress();
    if (param.long1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for burn transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionBurnParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount0 == 0 && param.amount1 == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for swap transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionSwapParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity < blockTimestamp) Error.alreadyMatured(param.maturity, blockTimestamp);
    if (param.tokenTo == address(0)) Error.zeroAddress();
    if (param.longTo == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }

  /// @dev Sanity checks
  /// @param param the parameter for collect transaction.
  /// @param blockTimestamp the current block timestamp.
  function check(TimeswapV2OptionCollectParam memory param, uint96 blockTimestamp) internal pure {
    if (param.strike == 0) Error.zeroInput();
    if (param.maturity > type(uint96).max) Error.incorrectMaturity(param.maturity);
    if (param.maturity >= blockTimestamp) Error.stillActive(param.maturity, blockTimestamp);
    if (param.token0To == address(0)) Error.zeroAddress();
    if (param.token1To == address(0)) Error.zeroAddress();
    TransactionLibrary.check(param.transaction);
    if (param.amount == 0) Error.zeroInput();
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev Processing information required for interacting multiple options in a single contract.
/// @notice Since mint, burn, and swap are all flashable transactions.
/// When doing a mint transaction, do not burn or swap the newly minted positions,
/// or risk transaction failure.
/// When doing a swap transaction, do not burn or swap the newly swapped positions,
/// or risk transaction failure.
/// @notice For example, if only long0 is minted.
/// Then calling swap on that long0 position of the same strike and maturity can risk transaction failure.
/// If calling swap on long1 position received elsewhere, that will be fine.
/// If calling swap on long1 but different strike and maturity is fine as well.
/// @param strike The strike ratio of token1 per token0 of the option.
/// @param maturity The maturity of the option.
/// @param balance0Target The required balance of token0 to be held in the option.
/// @param balance1Target The required balance of token1 to be held in the option.
struct Process {
  uint256 strike;
  uint256 maturity;
  uint256 balance0Target;
  uint256 balance1Target;
}

library ProcessLibrary {
  /// @dev Revert when processing more than 16 processes.
  error ProccessOverload();

  /// @dev update process for managing how many tokens required from msg.sender.
  /// @dev reentrancy safety as well.
  /// @notice Can only process up to 16 proccesses. Will revert if more than 16.
  /// @param processing The current array of processes.
  /// @param token0Amount If isAddToken0 then token0 amount to be deposited, else the token0 amount withdrawn.
  /// @param token1Amount If isAddToken1 then token1 amount to be deposited, else the token1 amount withdrawn.
  /// @param isAddToken0 IsAddToken0 if true. IsSubToken0 if false.
  /// @param isAddToken1 IsAddToken1 if true. IsSubToken0 if false.
  function updateProcess(
    Process[] storage processing,
    uint256 token0Amount,
    uint256 token1Amount,
    bool isAddToken0,
    bool isAddToken1
  ) internal {
    if (processing.length > 16) revert ProccessOverload();

    for (uint256 i; i < processing.length; ) {
      Process storage process = processing[i];

      if (token0Amount != 0)
        process.balance0Target = isAddToken0
          ? process.balance0Target + token0Amount
          : process.balance0Target - token0Amount;

      if (token1Amount != 0)
        process.balance1Target = isAddToken1
          ? process.balance1Target + token1Amount
          : process.balance1Target - token1Amount;

      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

/// @dev A data with strike and maturity data.
/// @param strike The strike.
/// @param maturity The maturity.
struct StrikeAndMaturity {
  uint256 strike;
  uint256 maturity;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Math} from "@timeswap-labs/v2-library/contracts/Math.sol";
import {Error} from "@timeswap-labs/v2-library/contracts/Error.sol";

import {NoDelegateCall} from "./NoDelegateCall.sol";

import {ITimeswapV2Option} from "./interfaces/ITimeswapV2Option.sol";
import {ITimeswapV2OptionDeployer} from "./interfaces/ITimeswapV2OptionDeployer.sol";
import {ITimeswapV2OptionMintCallback} from "./interfaces/callbacks/ITimeswapV2OptionMintCallback.sol";
import {ITimeswapV2OptionBurnCallback} from "./interfaces/callbacks/ITimeswapV2OptionBurnCallback.sol";
import {ITimeswapV2OptionSwapCallback} from "./interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol";
import {ITimeswapV2OptionCollectCallback} from "./interfaces/callbacks/ITimeswapV2OptionCollectCallback.sol";

import {Option, OptionLibrary} from "./structs/Option.sol";
import {Process, ProcessLibrary} from "./structs/Process.sol";
import {StrikeAndMaturity} from "./structs/StrikeAndMaturity.sol";

import {TimeswapV2OptionPosition, PositionLibrary} from "./enums/Position.sol";
import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "./enums/Transaction.sol";

import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam, ParamLibrary} from "./structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionBurnCallbackParam, TimeswapV2OptionSwapCallbackParam, TimeswapV2OptionCollectCallbackParam} from "./structs/CallbackParam.sol";

/// @title Timeswap V2 Options for a given pair
/// @author Timeswap Labs
/// @notice Holds the option of all strikes and maturities.
contract TimeswapV2Option is ITimeswapV2Option, NoDelegateCall {
  using OptionLibrary for Option;
  using ProcessLibrary for Process[];
  using Math for uint256;
  using SafeERC20 for IERC20;

  /* ===== MODEL ===== */

  /// @inheritdoc ITimeswapV2Option
  address public immutable override optionFactory;
  /// @inheritdoc ITimeswapV2Option
  address public immutable override token0;
  /// @inheritdoc ITimeswapV2Option
  address public immutable override token1;

  /// @dev mapping of all option state for all strikes and maturities.
  mapping(uint256 => mapping(uint256 => Option)) private options;
  /// @dev Always start and end as an empty array for every transaction.
  /// Process the token requirement for every option interaction call.
  Process[] private processing;

  mapping(uint256 => mapping(uint256 => bool)) private hasInteracted;
  StrikeAndMaturity[] private listOfOptions;

  function addOptionEnumerationIfNecessary(uint256 strike, uint256 maturity) private {
    if (!hasInteracted[strike][maturity]) {
      hasInteracted[strike][maturity] = true;
      listOfOptions.push(StrikeAndMaturity({strike: strike, maturity: maturity}));
    }
  }

  /* ===== INIT ===== */

  constructor() NoDelegateCall() {
    (optionFactory, token0, token1) = ITimeswapV2OptionDeployer(msg.sender).parameter();
  }

  // Can be overridden for testing purposes.
  function blockTimestamp() internal view virtual returns (uint96) {
    return uint96(block.timestamp); // truncation is desired
  }

  /* ===== VIEW ===== */
  /// @inheritdoc ITimeswapV2Option
  function getByIndex(uint256 id) external view override returns (StrikeAndMaturity memory) {
    return listOfOptions[id];
  }

  /// @inheritdoc ITimeswapV2Option
  function numberOfOptions() external view override returns (uint256) {
    return listOfOptions.length;
  }

  /// @inheritdoc ITimeswapV2Option
  function totalPosition(
    uint256 strike,
    uint256 maturity,
    TimeswapV2OptionPosition position
  ) external view override returns (uint256) {
    return options[strike][maturity].totalPosition(strike, position);
  }

  /// @inheritdoc ITimeswapV2Option
  function positionOf(
    uint256 strike,
    uint256 maturity,
    address owner,
    TimeswapV2OptionPosition position
  ) external view override returns (uint256) {
    return options[strike][maturity].positionOf(owner, position);
  }

  /* ===== UPDATE ===== */

  /// @inheritdoc ITimeswapV2Option
  function transferPosition(
    uint256 strike,
    uint256 maturity,
    address to,
    TimeswapV2OptionPosition position,
    uint256 amount
  ) external override {
    if (!hasInteracted[strike][maturity]) Error.inactiveOptionChoice(strike, maturity);
    if (to == address(0)) Error.zeroAddress();
    if (amount == 0) Error.zeroInput();
    PositionLibrary.check(position);

    options[strike][maturity].transferPosition(to, position, amount);

    emit TransferPosition(strike, maturity, msg.sender, to, position, amount);
  }

  /// @inheritdoc ITimeswapV2Option
  function mint(
    TimeswapV2OptionMintParam calldata param
  )
    external
    override
    noDelegateCall
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data)
  {
    ParamLibrary.check(param, blockTimestamp());
    addOptionEnumerationIfNecessary(param.strike, param.maturity);

    Option storage option = options[param.strike][param.maturity];

    // does main mint logic calculation
    (token0AndLong0Amount, token1AndLong1Amount, shortAmount) = option.mint(
      param.strike,
      param.long0To,
      param.long1To,
      param.shortTo,
      param.transaction,
      param.amount0,
      param.amount1
    );

    // update token0 and token1 balance target for any previous concurrent option transactions.
    processing.updateProcess(token0AndLong0Amount, token1AndLong1Amount, true, true);

    // add a new process
    // stores the token0 and token1 balance target required from the msg.sender to achieve.
    Process storage currentProcess = (processing.push() = Process(
      param.strike,
      param.maturity,
      IERC20(token0).balanceOf(address(this)) + token0AndLong0Amount,
      IERC20(token1).balanceOf(address(this)) + token1AndLong1Amount
    ));

    // ask the msg.sender to transfer token0 and/or token1 to this contract.
    data = ITimeswapV2OptionMintCallback(msg.sender).timeswapV2OptionMintCallback(
      TimeswapV2OptionMintCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        token0AndLong0Amount: token0AndLong0Amount,
        token1AndLong1Amount: token1AndLong1Amount,
        shortAmount: shortAmount,
        data: param.data
      })
    );

    // check if the token0 balance target is achieved.
    if (token0AndLong0Amount != 0)
      Error.checkEnough(IERC20(token0).balanceOf(address(this)), currentProcess.balance0Target);

    // check if the token1 balance target is achieved.
    if (token1AndLong1Amount != 0)
      Error.checkEnough(IERC20(token1).balanceOf(address(this)), currentProcess.balance1Target);

    // finish the process.
    processing.pop();

    emit Mint(
      param.strike,
      param.maturity,
      msg.sender,
      param.long0To,
      param.long1To,
      param.shortTo,
      token0AndLong0Amount,
      token1AndLong1Amount,
      shortAmount
    );
  }

  /// @inheritdoc ITimeswapV2Option
  function burn(
    TimeswapV2OptionBurnParam calldata param
  )
    external
    override
    noDelegateCall
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data)
  {
    if (!hasInteracted[param.strike][param.maturity]) Error.inactiveOptionChoice(param.strike, param.maturity);
    ParamLibrary.check(param, blockTimestamp());

    Option storage option = options[param.strike][param.maturity];

    // does main burn logic calculation
    (token0AndLong0Amount, token1AndLong1Amount, shortAmount) = option.burn(
      param.strike,
      param.transaction,
      param.amount0,
      param.amount1
    );

    // update token0 and token1 balance target for any previous concurrent option transactions.
    processing.updateProcess(token0AndLong0Amount, token1AndLong1Amount, false, false);

    // transfer token0 amount to recipient.
    if (token0AndLong0Amount != 0) IERC20(token0).safeTransfer(param.token0To, token0AndLong0Amount);

    // transfer token1 amount to recipient.
    if (token1AndLong1Amount != 0) IERC20(token1).safeTransfer(param.token1To, token1AndLong1Amount);

    // skip callback if there is no data.
    if (param.data.length != 0)
      data = ITimeswapV2OptionBurnCallback(msg.sender).timeswapV2OptionBurnCallback(
        TimeswapV2OptionBurnCallbackParam({
          strike: param.strike,
          maturity: param.maturity,
          token0AndLong0Amount: token0AndLong0Amount,
          token1AndLong1Amount: token1AndLong1Amount,
          shortAmount: shortAmount,
          data: param.data
        })
      );

    option.long0[msg.sender] -= token0AndLong0Amount;
    option.long1[msg.sender] -= token1AndLong1Amount;
    option.short[msg.sender] -= shortAmount;

    emit Burn(
      param.strike,
      param.maturity,
      msg.sender,
      param.token0To,
      param.token1To,
      token0AndLong0Amount,
      token1AndLong1Amount,
      shortAmount
    );
  }

  /// @inheritdoc ITimeswapV2Option
  function swap(
    TimeswapV2OptionSwapParam calldata param
  )
    external
    override
    noDelegateCall
    returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data)
  {
    if (!hasInteracted[param.strike][param.maturity]) Error.inactiveOptionChoice(param.strike, param.maturity);
    ParamLibrary.check(param, blockTimestamp());

    Option storage option = options[param.strike][param.maturity];

    // does main swap logic calculation
    (token0AndLong0Amount, token1AndLong1Amount) = option.swap(
      param.strike,
      param.longTo,
      param.isLong0ToLong1,
      param.transaction,
      param.amount
    );

    // update token0 and token1 balance target for any previous concurrent option transactions.
    processing.updateProcess(token0AndLong0Amount, token1AndLong1Amount, !param.isLong0ToLong1, param.isLong0ToLong1);

    // add a new process
    // stores the token0 and token1 balance target required from the msg.sender to achieve.
    Process storage currentProcess = (processing.push() = Process(
      param.strike,
      param.maturity,
      param.isLong0ToLong1
        ? IERC20(token0).balanceOf(address(this)) - token0AndLong0Amount
        : IERC20(token0).balanceOf(address(this)) + token0AndLong0Amount,
      param.isLong0ToLong1
        ? IERC20(token1).balanceOf(address(this)) + token1AndLong1Amount
        : IERC20(token1).balanceOf(address(this)) - token1AndLong1Amount
    ));

    // transfer token to recipient.
    IERC20(param.isLong0ToLong1 ? token0 : token1).safeTransfer(
      param.tokenTo,
      param.isLong0ToLong1 ? token0AndLong0Amount : token1AndLong1Amount
    );

    // ask the msg.sender to transfer token0 or token1 to this contract.
    data = ITimeswapV2OptionSwapCallback(msg.sender).timeswapV2OptionSwapCallback(
      TimeswapV2OptionSwapCallbackParam({
        strike: param.strike,
        maturity: param.maturity,
        isLong0ToLong1: param.isLong0ToLong1,
        token0AndLong0Amount: token0AndLong0Amount,
        token1AndLong1Amount: token1AndLong1Amount,
        data: param.data
      })
    );

    // check if the token0 or token1 balance target is achieved.
    Error.checkEnough(
      IERC20(param.isLong0ToLong1 ? token1 : token0).balanceOf(address(this)),
      param.isLong0ToLong1 ? currentProcess.balance1Target : currentProcess.balance0Target
    );

    if (param.isLong0ToLong1) option.long0[msg.sender] -= token0AndLong0Amount;
    else option.long1[msg.sender] -= token1AndLong1Amount;

    // finish the process.
    processing.pop();

    emit Swap(
      param.strike,
      param.maturity,
      msg.sender,
      param.tokenTo,
      param.longTo,
      param.isLong0ToLong1,
      token0AndLong0Amount,
      token1AndLong1Amount
    );
  }

  /// @inheritdoc ITimeswapV2Option
  function collect(
    TimeswapV2OptionCollectParam calldata param
  )
    external
    override
    noDelegateCall
    returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data)
  {
    if (!hasInteracted[param.strike][param.maturity]) Error.inactiveOptionChoice(param.strike, param.maturity);
    ParamLibrary.check(param, blockTimestamp());

    Option storage option = options[param.strike][param.maturity];

    // does main collect logic calculation
    (token0Amount, token1Amount, shortAmount) = option.collect(param.strike, param.transaction, param.amount);

    // update token0 and token1 balance target for any previous concurrent option transactions.
    processing.updateProcess(token0Amount, token1Amount, false, false);

    // transfer token0 amount to recipient.
    if (token0Amount != 0) IERC20(token0).safeTransfer(param.token0To, token0Amount);

    // transfer token1 amount to recipient.
    if (token1Amount != 0) IERC20(token1).safeTransfer(param.token1To, token1Amount);

    // skip callback if there is no data.
    if (param.data.length != 0)
      data = ITimeswapV2OptionCollectCallback(msg.sender).timeswapV2OptionCollectCallback(
        TimeswapV2OptionCollectCallbackParam({
          strike: param.strike,
          maturity: param.maturity,
          token0Amount: token0Amount,
          token1Amount: token1Amount,
          shortAmount: shortAmount,
          data: param.data
        })
      );

    option.short[msg.sender] -= shortAmount;

    emit Collect(
      param.strike,
      param.maturity,
      msg.sender,
      param.token0To,
      param.token1To,
      token0Amount,
      token1Amount,
      shortAmount
    );
  }
}