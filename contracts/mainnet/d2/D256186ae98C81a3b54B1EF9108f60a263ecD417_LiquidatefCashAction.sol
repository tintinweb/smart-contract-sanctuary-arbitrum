// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {StorageLayoutV1} from "../../global/StorageLayoutV1.sol";
import {Constants} from "../../global/Constants.sol";
import {nTokenHandler} from "../../internal/nToken/nTokenHandler.sol";

abstract contract ActionGuards is StorageLayoutV1 {
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        require(reentrancyStatus == 0);

        // Initialize the guard to a non-zero value, see the OZ reentrancy guard
        // description for why this is more gas efficient:
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
        reentrancyStatus = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(reentrancyStatus != _ENTERED); // dev: reentered

        // Any calls to nonReentrant after this point will fail
        reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        reentrancyStatus = _NOT_ENTERED;
    }

    // These accounts cannot receive deposits, transfers, fCash or any other
    // types of value transfers.
    function requireValidAccount(address account) internal view {
        require(account != address(0));
        require(account != Constants.FEE_RESERVE);
        require(account != Constants.SETTLEMENT_RESERVE);
        require(account != address(this));
        (
            uint256 isNToken,
            /* incentiveAnnualEmissionRate */,
            /* lastInitializedTime */,
            /* assetArrayLength */,
            /* parameters */
        ) = nTokenHandler.getNTokenContext(account);
        require(isNToken == 0);

        // NOTE: we do not check the pCash proxy here. Unlike the nToken, the pCash proxy
        // is a pure proxy and does not actually hold any assets. Any assets transferred
        // to the pCash proxy will be lost.
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _checkValidCurrency(uint16 currencyId) internal view {
        require(0 < currencyId && currencyId <= maxCurrencyId, "Invalid currency id");
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    AccountContext,
    PrimeRate,
    LiquidationFactors
} from "../../global/Types.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

import {ActionGuards} from "./ActionGuards.sol";
import {AccountContextHandler} from "../../internal/AccountContextHandler.sol";
import {LiquidatefCash} from "../../internal/liquidation/LiquidatefCash.sol";
import {LiquidationHelpers} from "../../internal/liquidation/LiquidationHelpers.sol";
import {BalanceHandler} from "../../internal/balances/BalanceHandler.sol";
import {PrimeRateLib} from "../../internal/pCash/PrimeRateLib.sol";

import {FreeCollateralExternal} from "../FreeCollateralExternal.sol";
import {SettleAssetsExternal} from "../SettleAssetsExternal.sol";

contract LiquidatefCashAction is ActionGuards {
    using AccountContextHandler for AccountContext;
    using PrimeRateLib for PrimeRate;
    using SafeInt256 for int256;

    /// @notice Calculates fCash local liquidation amounts, may settle account so this can be called off
    // chain using a static call
    /// @param liquidateAccount account to liquidate
    /// @param localCurrency local currency to liquidate
    /// @param fCashMaturities array of fCash maturities in the local currency to purchase, must be
    /// ordered descending
    /// @param maxfCashLiquidateAmounts max notional of fCash to liquidate in corresponding maturity,
    /// zero will represent no maximum
    /// @return an array of the notional amounts of fCash to transfer, corresponding to fCashMaturities
    /// @return amount of local currency required from the liquidator
    function calculatefCashLocalLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external nonReentrant returns (int256[] memory, int256) {
        uint256 blockTime = block.timestamp;
        LiquidatefCash.fCashContext memory c =
            _liquidateLocal(
                liquidateAccount,
                localCurrency,
                fCashMaturities,
                maxfCashLiquidateAmounts,
                blockTime
            );

        return (c.fCashNotionalTransfers, c.localPrimeCashFromLiquidator);
    }

    /// @notice Liquidates fCash using local currency
    /// @param liquidateAccount account to liquidate
    /// @param localCurrency local currency to liquidate
    /// @param fCashMaturities array of fCash maturities in the local currency to purchase, must be ordered
    /// descending
    /// @param maxfCashLiquidateAmounts max notional of fCash to liquidate in corresponding maturity,
    /// zero will represent no maximum
    /// @return an array of the notional amounts of fCash to transfer, corresponding to fCashMaturities
    /// @return amount of local currency required from the liquidator
    function liquidatefCashLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external payable nonReentrant returns (int256[] memory, int256) {
        require(fCashMaturities.length > 0);
        uint256 blockTime = block.timestamp;
        LiquidatefCash.fCashContext memory c =
            _liquidateLocal(
                liquidateAccount,
                localCurrency,
                fCashMaturities,
                maxfCashLiquidateAmounts,
                blockTime
            );

        LiquidatefCash.finalizefCashLiquidation(
            liquidateAccount,
            msg.sender,
            localCurrency,
            localCurrency,
            fCashMaturities,
            c
        );

        return (c.fCashNotionalTransfers, c.localPrimeCashFromLiquidator);
    }

    /// @notice Calculates fCash cross currency liquidation, can be called via staticcall off chain
    /// @param liquidateAccount account to liquidate
    /// @param localCurrency local currency to liquidate
    /// @param fCashCurrency currency of fCash to purchase
    /// @param fCashMaturities array of fCash maturities in the local currency to purchase, must be ordered
    /// descending
    /// @param maxfCashLiquidateAmounts max notional of fCash to liquidate in corresponding maturity, zero
    /// will represent no maximum
    /// @return an array of the notional amounts of fCash to transfer, corresponding to fCashMaturities
    /// @return amount of local currency required from the liquidator
    function calculatefCashCrossCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external nonReentrant returns (int256[] memory, int256) {
        uint256 blockTime = block.timestamp;
        LiquidatefCash.fCashContext memory c =
            _liquidateCrossCurrency(
                liquidateAccount,
                localCurrency,
                fCashCurrency,
                fCashMaturities,
                maxfCashLiquidateAmounts,
                blockTime
            );

        return (c.fCashNotionalTransfers, c.localPrimeCashFromLiquidator);
    }

    /// @notice Liquidates fCash across local to collateral currency
    /// @param liquidateAccount account to liquidate
    /// @param localCurrency local currency to liquidate
    /// @param fCashCurrency currency of fCash to purchase
    /// @param fCashMaturities array of fCash maturities in the local currency to purchase, must be ordered
    /// descending
    /// @param maxfCashLiquidateAmounts max notional of fCash to liquidate in corresponding maturity, zero
    /// will represent no maximum
    /// @return an array of the notional amounts of fCash to transfer, corresponding to fCashMaturities
    /// @return amount of local currency required from the liquidator
    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external payable nonReentrant returns (int256[] memory, int256) {
        require(fCashMaturities.length > 0);
        uint256 blockTime = block.timestamp;

        LiquidatefCash.fCashContext memory c =
            _liquidateCrossCurrency(
                liquidateAccount,
                localCurrency,
                fCashCurrency,
                fCashMaturities,
                maxfCashLiquidateAmounts,
                blockTime
            );

        LiquidatefCash.finalizefCashLiquidation(
            liquidateAccount,
            msg.sender,
            localCurrency,
            fCashCurrency,
            fCashMaturities,
            c
        );

        return (c.fCashNotionalTransfers, c.localPrimeCashFromLiquidator);
    }

    function _liquidateLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts,
        uint256 blockTime
    ) private returns (LiquidatefCash.fCashContext memory) {
        require(fCashMaturities.length == maxfCashLiquidateAmounts.length);
        LiquidatefCash.fCashContext memory c;
        (c.accountContext, c.factors, c.portfolio) = LiquidationHelpers.preLiquidationActions(
            liquidateAccount,
            localCurrency,
            0
        );

        // prettier-ignore
        (
            int256 cashBalance,
            /* int256 nTokenBalance */,
            /* uint256 lastClaimTime */,
            /* uint256 accountIncentiveDebt */
        ) = BalanceHandler.getBalanceStorage(liquidateAccount, localCurrency, c.factors.localPrimeRate);
        // Cash balance is used if liquidating negative fCash
        c.localCashBalanceUnderlying = c.factors.localPrimeRate.convertToUnderlying(cashBalance);
        c.fCashNotionalTransfers = new int256[](fCashMaturities.length);

        LiquidatefCash.liquidatefCashLocal(
            liquidateAccount,
            localCurrency,
            fCashMaturities,
            maxfCashLiquidateAmounts,
            c,
            blockTime
        );

        return c;
    }

    function _liquidateCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts,
        uint256 blockTime
    ) private returns (LiquidatefCash.fCashContext memory) {
        require(fCashMaturities.length == maxfCashLiquidateAmounts.length); // dev: fcash maturity length mismatch
        LiquidatefCash.fCashContext memory c;
        (c.accountContext, c.factors, c.portfolio) = LiquidationHelpers.preLiquidationActions(
            liquidateAccount,
            localCurrency,
            fCashCurrency
        );
        c.fCashNotionalTransfers = new int256[](fCashMaturities.length);

        LiquidatefCash.liquidatefCashCrossCurrency(
            liquidateAccount,
            fCashCurrency,
            fCashMaturities,
            maxfCashLiquidateAmounts,
            c,
            blockTime
        );

        return c;
    }

    /// @notice Get a list of deployed library addresses (sorted by library name)
    function getLibInfo() external pure returns (address, address) {
        return (address(FreeCollateralExternal), address(SettleAssetsExternal));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import "../global/Deployments.sol";
import "../external/SettleAssetsExternal.sol";
import "../internal/AccountContextHandler.sol";
import "../internal/valuation/FreeCollateral.sol";

/// @title Externally deployed library for free collateral calculations
library FreeCollateralExternal {
    using AccountContextHandler for AccountContext;
    // Grace period after a sequencer downtime has occurred
    uint256 internal constant SEQUENCER_UPTIME_GRACE_PERIOD = 1 hours;

    function _checkSequencer() private view {
        // See: https://docs.chain.link/data-feeds/l2-sequencer-feeds/
        if (address(Deployments.SEQUENCER_UPTIME_ORACLE) != address(0)) {
            (
                /*uint80 roundID*/,
                int256 answer,
                uint256 startedAt,
                /*uint256 updatedAt*/,
                /*uint80 answeredInRound*/
            ) = Deployments.SEQUENCER_UPTIME_ORACLE.latestRoundData();
            require(answer == 0, "Sequencer Down");
            require(SEQUENCER_UPTIME_GRACE_PERIOD < block.timestamp - startedAt, "Sequencer Grace Period");
        }
    }

    /// @notice Returns the ETH denominated free collateral of an account, represents the amount of
    /// debt that the account can incur before liquidation. If an account's assets need to be settled this
    /// will revert, either settle the account or use the off chain SDK to calculate free collateral.
    /// @dev Called via the Views.sol method to return an account's free collateral. Does not work
    /// for the nToken, the nToken does not have an account context.
    /// @param account account to calculate free collateral for
    /// @return total free collateral in ETH w/ 8 decimal places
    /// @return array of net local values in asset values ordered by currency id
    function getFreeCollateralView(address account)
        external
        view
        returns (int256, int256[] memory)
    {
        AccountContext memory accountContext = AccountContextHandler.getAccountContext(account);
        // The internal free collateral function does not account for settled assets. The Notional SDK
        // can calculate the free collateral off chain if required at this point.
        require(!accountContext.mustSettleAssets(), "Assets not settled");
        return FreeCollateral.getFreeCollateralView(account, accountContext, block.timestamp);
    }

    /// @notice Calculates free collateral and will revert if it falls below zero. If the account context
    /// must be updated due to changes in debt settings, will update. Cannot check free collateral if assets
    /// need to be settled first.
    /// @dev Cannot be called directly by users, used during various actions that require an FC check. Must be
    /// called before the end of any transaction for accounts where FC can decrease.
    /// @param account account to calculate free collateral for
    function checkFreeCollateralAndRevert(address account) external {
        // Prevents new debt positions from being initiated if the sequencer is down, only applies to L2 environments
        // like Arbitrum and Optimism where this is a concern. Accounts with no risk do not get a free
        // collateral check and will bypass this check.
        _checkSequencer();

        AccountContext memory accountContext = AccountContextHandler.getAccountContext(account);
        require(!accountContext.mustSettleAssets(), "Assets not settled");

        (int256 ethDenominatedFC, bool updateContext) =
            FreeCollateral.getFreeCollateralStateful(account, accountContext, block.timestamp);

        if (updateContext) {
            accountContext.setAccountContext(account);
        }

        require(ethDenominatedFC >= 0, "Insufficient free collateral");
    }

    /// @notice Calculates liquidation factors for an account
    /// @dev Only called internally by liquidation actions, does some initial validation of currencies. If a currency is
    /// specified that the account does not have, a asset available figure of zero will be returned. If this is the case then
    /// liquidation actions will revert.
    /// @dev an ntoken account will return 0 FC and revert if called
    /// @param account account to liquidate
    /// @param localCurrencyId currency that the debts are denominated in
    /// @param collateralCurrencyId collateral currency to liquidate against, set to zero in the case of local currency liquidation
    /// @return accountContext the accountContext of the liquidated account
    /// @return factors struct of relevant factors for liquidation
    /// @return portfolio the portfolio array of the account (bitmap accounts will return an empty array)
    function getLiquidationFactors(
        address account,
        uint256 localCurrencyId,
        uint256 collateralCurrencyId
    )
        external
        returns (
            AccountContext memory accountContext,
            LiquidationFactors memory factors,
            PortfolioAsset[] memory portfolio
        )
    {
        // Prevents new liquidations from being initiated if the sequencer is down, only applies to L2 environments
        // like Arbitrum and Optimism where this is a concern.
        _checkSequencer();

        accountContext = AccountContextHandler.getAccountContext(account);
        if (accountContext.mustSettleAssets()) {
            accountContext = SettleAssetsExternal.settleAccount(account, accountContext);
        }

        if (accountContext.isBitmapEnabled()) {
            // A bitmap currency can only ever hold debt in this currency
            require(localCurrencyId == accountContext.bitmapCurrencyId);
        }

        (factors, portfolio) = FreeCollateral.getLiquidationFactors(
            account,
            accountContext,
            block.timestamp,
            localCurrencyId,
            collateralCurrencyId
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import "../global/LibStorage.sol";
import "../internal/nToken/nTokenHandler.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @notice Deployed library for migration of incentives from the old (inaccurate) calculation
 * to a newer, more accurate calculation based on SushiSwap MasterChef math. The more accurate
 * calculation is inside `Incentives.sol` and this library holds the legacy calculation. System
 * migration code can be found in `MigrateIncentivesFix.sol`
 */
library MigrateIncentives {
    using SafeMath for uint256;

    /// @notice Calculates the claimable incentives for a particular nToken and account in the
    /// previous regime. This should only ever be called ONCE for an account / currency combination
    /// to get the incentives accrued up until the migration date.
    function migrateAccountFromPreviousCalculation(
        address tokenAddress,
        uint256 nTokenBalance,
        uint256 lastClaimTime,
        uint256 lastClaimIntegralSupply
    ) external view returns (uint256) {
        (
            uint256 finalEmissionRatePerYear,
            uint256 finalTotalIntegralSupply,
            uint256 finalMigrationTime
        ) = _getMigratedIncentiveValues(tokenAddress);

        // This if statement should never be true but we return 0 just in case
        if (lastClaimTime == 0 || lastClaimTime >= finalMigrationTime) return 0;

        // No overflow here, checked above. All incentives are claimed up until finalMigrationTime
        // using the finalTotalIntegralSupply. Both these values are set on migration and will not
        // change.
        uint256 timeSinceMigration = finalMigrationTime - lastClaimTime;

        // (timeSinceMigration * INTERNAL_TOKEN_PRECISION * finalEmissionRatePerYear) / YEAR
        uint256 incentiveRate =
            timeSinceMigration
                .mul(uint256(Constants.INTERNAL_TOKEN_PRECISION))
                // Migration emission rate is stored as is, denominated in whole tokens
                .mul(finalEmissionRatePerYear).mul(uint256(Constants.INTERNAL_TOKEN_PRECISION))
                .div(Constants.YEAR);

        // Returns the average supply using the integral of the total supply.
        uint256 avgTotalSupply = finalTotalIntegralSupply.sub(lastClaimIntegralSupply).div(timeSinceMigration);
        if (avgTotalSupply == 0) return 0;

        uint256 incentivesToClaim = nTokenBalance.mul(incentiveRate).div(avgTotalSupply);
        // incentiveRate has a decimal basis of 1e16 so divide by token precision to reduce to 1e8
        incentivesToClaim = incentivesToClaim.div(uint256(Constants.INTERNAL_TOKEN_PRECISION));

        return incentivesToClaim;
    }

    function _getMigratedIncentiveValues(
        address tokenAddress
    ) private view returns (
        uint256 finalEmissionRatePerYear,
        uint256 finalTotalIntegralSupply,
        uint256 finalMigrationTime
    ) {
        mapping(address => nTokenTotalSupplyStorage_deprecated) storage store = LibStorage.getDeprecatedNTokenTotalSupplyStorage();
        nTokenTotalSupplyStorage_deprecated storage d_nTokenStorage = store[tokenAddress];

        // The total supply value is overridden as emissionRatePerYear during the initialization
        finalEmissionRatePerYear = d_nTokenStorage.totalSupply;
        finalTotalIntegralSupply = d_nTokenStorage.integralTotalSupply;
        finalMigrationTime = d_nTokenStorage.lastSupplyChangeTime;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {Constants} from "../../global/Constants.sol";
import {Deployments} from "../../global/Deployments.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

import {IERC4626} from "../../../interfaces/IERC4626.sol";
import {NotionalProxy} from "../../../interfaces/notional/NotionalProxy.sol";
import {IERC20 as IERC20WithDecimals} from "../../../interfaces/IERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/Initializable.sol";

interface ITransferEmitter {
    function emitTransfer(address from, address to, uint256 amount) external;
    function emitMintOrBurn(address account, int256 netBalance) external;
    function emitMintTransferBurn(
        address minter, address burner, uint256 mintAmount, uint256 transferAndBurnAmount
    ) external;
    function emitfCashTradeTransfers(
        address account, address nToken, int256 accountToNToken, uint256 cashToReserve
    ) external;
}

/// @notice Each nToken will have its own proxy contract that forwards calls to the main Notional
/// proxy where all the storage is located. There are two types of nToken proxies: regular nToken
/// and staked nToken proxies which both implement ERC20 standards. Each nToken proxy is an upgradeable
/// beacon contract so that methods they proxy can be extended in the future.
/// @dev The first four nTokens deployed (ETH, DAI, USDC, WBTC) have non-upgradeable nToken proxy
/// contracts and are not easily upgraded. This may change in the future but requires a lot of testing
/// and may break backwards compatibility with integrations.
abstract contract BaseERC4626Proxy is IERC20, IERC4626, Initializable, ITransferEmitter {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;

    event ProxyRenamed();

    /*** IMMUTABLES [SET ON IMPLEMENTATION] ***/
    
    /// @notice Inherits from Constants.INTERNAL_TOKEN_PRECISION
    uint8 public constant decimals = 8;

    /// @notice Precision for exchangeRate()
    uint256 public constant EXCHANGE_RATE_PRECISION = 1e18;

    /// @notice Address of the notional proxy, proxies only have access to a subset of the methods
    NotionalProxy public immutable NOTIONAL;

    /*** STORAGE SLOTS [SET ONCE ON EACH PROXY] ***/

    /// @notice Will be "[Staked] nToken {Underlying Token}.name()", therefore "USD Coin" will be
    /// "nToken USD Coin" for the regular nToken and "Staked nToken USD Coin" for the staked version.
    string public name;

    /// @notice Will be "[s]n{Underlying Token}.symbol()", therefore "USDC" will be "nUSDC"
    string public symbol;

    /// @notice Currency id that this nToken refers to
    uint16 public currencyId;

    /// @notice Native underlying decimal places
    uint8 public nativeDecimals;

    /// @notice ERC20 underlying token referred to as the "asset" in IERC4626
    address public underlying;

    /*** END STORAGE SLOTS ***/

    constructor(NotionalProxy notional_
    // Initializer modifier is used here to prevent attackers from re-initializing the
    // implementation. No real attack vector here since there is no ownership modification
    // on the implementation but this is best practice.
    ) initializer { 
        NOTIONAL = notional_;
    }

    modifier onlyNotional() {
        require(msg.sender == address(NOTIONAL), "Unauthorized");
        _;
    }

    function initialize(
        uint16 currencyId_,
        address underlying_,
        string memory underlyingName_,
        string memory underlyingSymbol_
    ) external onlyNotional initializer {
        currencyId = currencyId_;

        (string memory namePrefix, string memory symbolPrefix) = _getPrefixes();
        name = string(abi.encodePacked(namePrefix, " ", underlyingName_));
        symbol = string(abi.encodePacked(symbolPrefix, underlyingSymbol_));

        if (underlying_ == Constants.ETH_ADDRESS) {
            // Use WETH for underlying in the case of ETH, no approval to Notional is
            // necessary since WETH is redeemed here
            underlying = address(Deployments.WETH);
        } else {
            underlying = underlying_;
            // Allows Notional to transfer from proxy
            SafeERC20.safeApprove(IERC20(underlying), address(NOTIONAL), type(uint256).max);
        }

        nativeDecimals = IERC20WithDecimals(underlying).decimals();
        require(nativeDecimals < 36);
    }

    function rename(
        string memory underlyingName_,
        string memory underlyingSymbol_
    ) external {
        require(msg.sender == NOTIONAL.owner());
        (string memory namePrefix, string memory symbolPrefix) = _getPrefixes();
        name = string(abi.encodePacked(namePrefix, " ", underlyingName_));
        symbol = string(abi.encodePacked(symbolPrefix, underlyingSymbol_));
        emit ProxyRenamed();
    }

    /// @notice Allows ERC20 transfer events to be emitted from the proper address so that
    /// wallet tools can properly track balances.
    function emitTransfer(address from, address to, uint256 amount) external override onlyNotional {
        emit Transfer(from, to, amount);
    }

    /// @notice Convenience method for minting and burning
    function emitMintOrBurn(address account, int256 netBalance) external override onlyNotional {
        if (netBalance < 0) {
            // Burn
            emit Transfer(account, address(0), uint256(netBalance.neg()));
        } else {
            // Mint
            emit Transfer(address(0), account, uint256(netBalance));
        }
    }

    /// @notice Convenience method for mint, transfer and burn. Used in vaults to record margin deposits and
    /// withdraws.
    function emitMintTransferBurn(
        address minter, address burner, uint256 mintAmount, uint256 transferAndBurnAmount
    ) external override onlyNotional {
        emit Transfer(address(0), minter, mintAmount);
        emit Transfer(minter, burner, transferAndBurnAmount);
        emit Transfer(burner, address(0), transferAndBurnAmount);
    }

    /// @notice Only used on pCash when fCash is traded.
    function emitfCashTradeTransfers(
        address account, address nToken, int256 accountToNToken, uint256 cashToReserve
    ) external override onlyNotional {
        if (accountToNToken < 0) {
            emit Transfer(account, nToken, uint256(accountToNToken.abs()));
        } else {
            emit Transfer(nToken, account, uint256(accountToNToken));
        }
        emit Transfer(account, Constants.FEE_RESERVE, cashToReserve);
    }

    /// @notice Returns the asset token reference by IERC4626, uses the underlying token as the asset
    /// for ERC4626 so that it is compatible with more use cases.
    function asset() external override view returns (address) { return underlying; }

    /// @notice Returns the total present value of the nTokens held in native underlying token precision
    function totalAssets() public override view returns (uint256 totalManagedAssets) {
        totalManagedAssets = _getTotalValueExternal();
    }

    /// @notice Converts an underlying token to an nToken denomination
    function convertToShares(uint256 assets) public override view returns (uint256 shares) {
        return assets.mul(EXCHANGE_RATE_PRECISION).div(exchangeRate());
    }

    /// @notice Converts nToken denomination to underlying denomination
    function convertToAssets(uint256 shares) public override view returns (uint256 assets) {
        return exchangeRate().mul(shares).div(EXCHANGE_RATE_PRECISION);
    }

    /// @notice Gets the max underlying supply
    function maxDeposit(address /*receiver*/) public override view returns (uint256 maxAssets) {
        // Both nTokens and pCash tokens are limited by the max underlying supply
        (
            /* */,
            /* */,
            uint256 maxUnderlyingSupply,
            uint256 currentUnderlyingSupply
        ) = NOTIONAL.getPrimeFactors(currencyId, block.timestamp);

        if (maxUnderlyingSupply == 0) {
            return type(uint256).max;
        } else if (maxUnderlyingSupply <= currentUnderlyingSupply) {
            return 0;
        } else {
            // No overflow here
            return (maxUnderlyingSupply - currentUnderlyingSupply)
                .mul(10 ** nativeDecimals)
                .div(uint256(Constants.INTERNAL_TOKEN_PRECISION));
        }
    }

    /// @notice Gets the max underlying supply and converts it to shares
    function maxMint(address /*receiver*/) external override view returns (uint256 maxShares) {
        uint256 maxAssets = maxDeposit(address(0));
        if (maxAssets == type(uint256).max) return maxAssets;

        return convertToShares(maxAssets);
    }

    function maxRedeem(address owner) external override view returns (uint256 maxShares) {
        return _balanceOf(owner);
    }

    function maxWithdraw(address owner) external override view returns (uint256 maxAssets) {
        return convertToAssets(_balanceOf(owner));
    }

    /// @notice Deposits are based on the conversion rate assets to shares
    function previewDeposit(uint256 assets) external override view returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Mints are based on the conversion rate from shares to assets
    function previewMint(uint256 shares) public override view returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Return value is an over-estimation of the assets that the user will receive via redemptions,
    /// this method does not account for slippage and potential illiquid residuals. This method is not completely
    /// ERC4626 compliant in that sense.
    /// @dev Redemptions of nToken shares to underlying assets will experience slippage which is
    /// not easily calculated. In some situations, slippage may be so great that the shares are not able
    /// to be redeemed purely via the ERC4626 method and would require the account to call nTokenRedeem on
    /// AccountAction and take on illiquid fCash residuals.
    function previewRedeem(uint256 shares) external view override returns (uint256 assets) {
        return convertToAssets(shares);
    }

    /// @notice Return value is an under-estimation of the shares that the user will need to redeem to raise assets,
    /// this method does not account for slippage and potential illiquid residuals. This method is not completely
    /// ERC4626 compliant in that sense.
    function previewWithdraw(uint256 assets) public view override returns (uint256 shares) {
        return convertToShares(assets);
    }

    /// @notice Deposits assets into nToken for the receiver's account. Requires that the ERC4626 token has
    /// approval to transfer assets from the msg.sender directly to Notional.
    function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
        uint256 msgValue;
        (assets, msgValue) = _transferAssets(assets);
        shares = _mint(assets, msgValue, receiver);

        emit Transfer(address(0), receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /// @notice Deposits assets into nToken for the receiver's account. Requires that the ERC4626 token has
    /// approval to transfer assets from the msg.sender directly to Notional.
    function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
        uint256 msgValue;
        assets = previewMint(shares);
        (assets, msgValue) = _transferAssets(assets);
        
        uint256 shares_ = _mint(assets, msgValue, receiver);

        emit Transfer(address(0), receiver, shares_);
        emit Deposit(msg.sender, receiver, assets, shares_);
    }

    function _transferAssets(uint256 assets) private returns (uint256 assetsActual, uint256 msgValue) {
        // NOTE: this results in double transfer of assets from the msg.sender to the proxy,
        // then from the proxy to Notional
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(underlying), msg.sender, address(this), assets);
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

        // Get the most accurate accounting of the assets transferred
        assetsActual = balanceAfter.sub(balanceBefore);

        if (currencyId == Constants.ETH_CURRENCY_ID) {
            // Unwrap WETH and set the msgValue
            Deployments.WETH.withdraw(assetsActual);
            msgValue = assetsActual;
        } else {
            msgValue = 0;
        }
    }

    /// @notice Redeems assets from the owner and sends them to the receiver. WARNING: the assets provided as a value here
    /// will not be what the method actually redeems due to estimation issues.
    function withdraw(uint256 assets, address receiver, address owner) external override returns (uint256 shares) {
        // NOTE: this will return an under-estimated amount for assets so the end amount of assets redeemed will
        // be less than specified.
        shares = previewWithdraw(assets);
        uint256 balance = _balanceOf(owner);
        if (shares > balance) shares = balance;

        // NOTE: if msg.sender != owner allowance checks must be done in_redeem
        uint256 assetsFinal = _redeem(shares, receiver, owner);
        emit Transfer(owner, address(0), shares);

        // NOTE: the assets emitted here will be the correct value, but will not match what was provided.
        emit Withdraw(msg.sender, receiver, owner, assetsFinal, shares);
    }

    /// @notice Redeems the specified amount of nTokens (shares) for some amount of assets.
    function redeem(uint256 shares, address receiver, address owner) external override returns (uint256 assets) {
        // NOTE: if msg.sender != owner allowance checks must be done in_redeem
        uint256 assetsFinal = _redeem(shares, receiver, owner);
        emit Transfer(owner, address(0), shares);
        emit Withdraw(msg.sender, receiver, owner, assetsFinal, shares);

        return assetsFinal;
    }

    function exchangeRate() public view returns (uint256 rate) {
        uint256 totalValueExternal = _getTotalValueExternal();
        uint256 supply = _totalSupply();
        // Exchange Rate from token to Underlying in EXCHANGE_RATE_PRECISION is:
        // 1 token = totalValueExternal * EXCHANGE_RATE_PRECISION / totalSupply
        rate = totalValueExternal.mul(EXCHANGE_RATE_PRECISION).div(supply);
    }

    /** Required ERC20 Methods */
    function balanceOf(address account) external view override returns (uint256) {
        return _balanceOf(account);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply();
    }

    function allowance(address account, address spender) external view override returns (uint256) {
        return _allowance(account, spender);
    }

    function approve(address spender, uint256 amount) external override returns (bool ret) {
        ret = _approve(spender, amount);
        if (ret) emit Approval(msg.sender, spender, amount);
    }

    function transfer(address to, uint256 amount) external override returns (bool ret) {
        // Emit transfer preemptively for Emitter parsing logic.
        emit Transfer(msg.sender, to, amount);
        ret = _transfer(to, amount);
        require(ret);
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool ret) {
        // Emit transfer preemptively for Emitter parsing logic.
        emit Transfer(from, to, amount);
        ret = _transferFrom(from, to, amount);
        require(ret);
    }

    /** Virtual methods **/
    function _balanceOf(address account) internal view virtual returns (uint256 balance);
    function _totalSupply() internal view virtual returns (uint256 supply);
    function _allowance(address account, address spender) internal view virtual returns (uint256);
    function _approve(address spender, uint256 amount) internal virtual returns (bool);
    function _transfer(address to, uint256 amount) internal virtual returns (bool);
    function _transferFrom(address from, address to, uint256 amount) internal virtual returns (bool);

    /// @notice Hardcoded prefixes for the token name
    function _getPrefixes() internal pure virtual returns (string memory namePrefix, string memory symbolPrefix);
    function _getTotalValueExternal() internal view virtual returns (uint256 totalValueExternal);
    function _mint(uint256 assets, uint256 msgValue, address receiver) internal virtual returns (uint256 tokensMinted);
    function _redeem(uint256 shares, address receiver, address owner) internal virtual returns (uint256 assets);

    // This is here for safety, but inheriting contracts should never declare storage anyway
    uint256[40] __gap;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    AccountContext,
    PrimeRate,
    PortfolioAsset,
    PortfolioState,
    SettleAmount
} from "../global/Types.sol";
import {Constants} from "../global/Constants.sol";
import {SafeInt256} from "../math/SafeInt256.sol";

import {Emitter} from "../internal/Emitter.sol";
import {AccountContextHandler} from "../internal/AccountContextHandler.sol";
import {PortfolioHandler} from "../internal/portfolio/PortfolioHandler.sol";
import {TransferAssets} from "../internal/portfolio/TransferAssets.sol";
import {BalanceHandler} from "../internal/balances/BalanceHandler.sol";
import {SettlePortfolioAssets} from "../internal/settlement/SettlePortfolioAssets.sol";
import {SettleBitmapAssets} from "../internal/settlement/SettleBitmapAssets.sol";
import {PrimeRateLib} from "../internal/pCash/PrimeRateLib.sol";

/// @notice External library for settling assets and portfolio management
library SettleAssetsExternal {
    using SafeInt256 for int256;
    using PortfolioHandler for PortfolioState;
    using AccountContextHandler for AccountContext;

    event AccountSettled(address indexed account);

    /// @notice Settles an account, returns the new account context object after settlement.
    /// @dev The memory location of the account context object is not the same as the one returned.
    function settleAccount(
        address account,
        AccountContext memory accountContext
    ) external returns (AccountContext memory) {
        // Defensive check to ensure that this is a valid settlement
        require(accountContext.mustSettleAssets());
        return _settleAccount(account, accountContext);
    }

    /// @notice Transfers a set of assets from one account to the other.
    /// @dev This method does not check free collateral, even though it may be required. The calling
    /// method is responsible for ensuring that free collateral is checked.
    /// @dev Called from LiquidatefCash#_transferAssets, ERC1155Action#_transfer
    function transferAssets(
        address fromAccount,
        address toAccount,
        AccountContext memory fromContextBefore,
        AccountContext memory toContextBefore,
        PortfolioAsset[] memory assets
    ) external returns (
        AccountContext memory fromContextAfter,
        AccountContext memory toContextAfter
    ) {
        // Emit events before notional amounts are inverted in place
        Emitter.emitBatchTransferfCash(fromAccount, toAccount, assets);

        toContextAfter = _settleAndPlaceAssets(toAccount, toContextBefore, assets);

        // Will flip the sign of notional in the assets array in memory
        TransferAssets.invertNotionalAmountsInPlace(assets);

        fromContextAfter = _settleAndPlaceAssets(fromAccount, fromContextBefore, assets);
    }

    /// @notice Places the assets in the account whether it is holding a bitmap or
    /// normal array type portfolio. Will revert if account has not been settled.
    /// @dev Called from AccountAction#nTokenRedeem
    function placeAssetsInAccount(
        address account,
        address fromAccount,
        AccountContext memory accountContext,
        PortfolioAsset[] memory assets
    ) external returns (AccountContext memory) {
        Emitter.emitBatchTransferfCash(fromAccount, account, assets);
        return TransferAssets.placeAssetsInAccount(account, accountContext, assets);
    }

    /// @notice Stores a portfolio state and returns the updated context
    /// @dev Called from BatchAction
    function storeAssetsInPortfolioState(
        address account,
        AccountContext memory accountContext,
        PortfolioState memory state
    ) external returns (AccountContext memory) {
        accountContext.storeAssetsAndUpdateContext(account, state);
        // NOTE: this account context returned is in a different memory location than
        // the one passed in.
        return accountContext;
    }

    /// @notice Transfers cash from a vault account to a vault liquidator
    /// @dev Called from VaultLiquidationAction#liquidateVaultCashBalance
    /// @return true if free collateral must be checked on the liquidator
    function transferCashToVaultLiquidator(
        address liquidator,
        address vault,
        address account,
        uint16 currencyId,
        uint256 maturity,
        int256 fCashToVault,
        int256 cashToLiquidator
    ) external returns (bool) {
        AccountContext memory context = AccountContextHandler.getAccountContext(liquidator);
        PortfolioAsset[] memory assets = new PortfolioAsset[](1);
        assets[0].currencyId = currencyId;
        assets[0].maturity = maturity;
        assets[0].assetType = Constants.FCASH_ASSET_TYPE;
        assets[0].notional = fCashToVault.neg();

        context = _settleAndPlaceAssets(liquidator, context, assets);

        BalanceHandler.setBalanceStorageForfCashLiquidation(
            liquidator,
            context,
            currencyId,
            cashToLiquidator,
            PrimeRateLib.buildPrimeRateStateful(currencyId)
        );

        context.setAccountContext(liquidator);

        // The vault is transferring prime cash to the liquidator in exchange for cash.
        Emitter.emitTransferPrimeCash(vault, liquidator, currencyId, cashToLiquidator);
        // fCashToVault is positive here. The liquidator will transfer fCash to the vault
        // and the vault will burn it to repay negative fCash debt.
        Emitter.emitTransferfCash(liquidator, vault, currencyId, maturity, fCashToVault);
        // The account will burn its debt and vault cash
        Emitter.emitVaultAccountCashBurn(
            account, vault, currencyId, maturity, fCashToVault, cashToLiquidator
        );
        
        // A free collateral check is required here because the liquidator is receiving cash
        // and transferring out fCash. It's possible that the collateral value of the fCash
        // is larger than the cash transferred in. Cannot check debt in this library since it
        // creates a circular dependency with FreeCollateralExternal. Done in VaultLiquidationAction
        return context.hasDebt != 0x00;
    }

    function _settleAccount(
        address account,
        AccountContext memory accountContext
    ) private returns (AccountContext memory) {
        SettleAmount[] memory settleAmounts;
        PortfolioState memory portfolioState;

        if (accountContext.isBitmapEnabled()) {
            PrimeRate memory presentPrimeRate = PrimeRateLib
                .buildPrimeRateStateful(accountContext.bitmapCurrencyId);

            (int256 positiveSettledCash, int256 negativeSettledCash, uint256 blockTimeUTC0) =
                SettleBitmapAssets.settleBitmappedCashGroup(
                    account,
                    accountContext.bitmapCurrencyId,
                    accountContext.nextSettleTime,
                    block.timestamp,
                    presentPrimeRate
                );
            require(blockTimeUTC0 < type(uint40).max); // dev: block time utc0 overflow
            accountContext.nextSettleTime = uint40(blockTimeUTC0);

            settleAmounts = new SettleAmount[](1);
            settleAmounts[0] = SettleAmount({
                currencyId: accountContext.bitmapCurrencyId,
                positiveSettledCash: positiveSettledCash,
                negativeSettledCash: negativeSettledCash,
                presentPrimeRate: presentPrimeRate
            });
        } else {
            portfolioState = PortfolioHandler.buildPortfolioState(
                account, accountContext.assetArrayLength, 0
            );
            settleAmounts = SettlePortfolioAssets.settlePortfolio(account, portfolioState, block.timestamp);
            accountContext.storeAssetsAndUpdateContextForSettlement(
                account, portfolioState
            );
        }

        BalanceHandler.finalizeSettleAmounts(account, accountContext, settleAmounts);

        emit AccountSettled(account);

        return accountContext;
    }

    function _settleAndPlaceAssets(
        address account,
        AccountContext memory context,
        PortfolioAsset[] memory assets
    ) private returns (AccountContext memory) {
        if (context.mustSettleAssets()) {
            context = _settleAccount(account, context);
        }

        return TransferAssets.placeAssetsInAccount(account, context, assets);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/// @title All shared constants for the Notional system should be declared here.
library Constants {
    uint8 internal constant CETH_DECIMAL_PLACES = 8;

    // Token precision used for all internal balances, TokenHandler library ensures that we
    // limit the dust amount caused by precision mismatches
    int256 internal constant INTERNAL_TOKEN_PRECISION = 1e8;
    uint256 internal constant INCENTIVE_ACCUMULATION_PRECISION = 1e18;

    // ETH will be initialized as the first currency
    uint256 internal constant ETH_CURRENCY_ID = 1;
    uint8 internal constant ETH_DECIMAL_PLACES = 18;
    int256 internal constant ETH_DECIMALS = 1e18;
    address internal constant ETH_ADDRESS = address(0);
    // Used to prevent overflow when converting decimal places to decimal precision values via
    // 10**decimalPlaces. This is a safe value for int256 and uint256 variables. We apply this
    // constraint when storing decimal places in governance.
    uint256 internal constant MAX_DECIMAL_PLACES = 36;

    // Address of the account where fees are collected
    address internal constant FEE_RESERVE = 0x0000000000000000000000000000000000000FEE;
    // Address of the account where settlement funds are collected, this is only
    // used for off chain event tracking.
    address internal constant SETTLEMENT_RESERVE = 0x00000000000000000000000000000000000005e7;

    // Most significant bit
    bytes32 internal constant MSB =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    // Each bit set in this mask marks where an active market should be in the bitmap
    // if the first bit refers to the reference time. Used to detect idiosyncratic
    // fcash in the nToken accounts
    bytes32 internal constant ACTIVE_MARKETS_MASK = (
        MSB >> ( 90 - 1) | // 3 month
        MSB >> (105 - 1) | // 6 month
        MSB >> (135 - 1) | // 1 year
        MSB >> (147 - 1) | // 2 year
        MSB >> (183 - 1) | // 5 year
        MSB >> (211 - 1) | // 10 year
        MSB >> (251 - 1)   // 20 year
    );

    // Basis for percentages
    int256 internal constant PERCENTAGE_DECIMALS = 100;
    // Min Buffer Scale and Buffer Scale are used in ExchangeRate to increase the maximum
    // possible buffer values at the higher end of the uint8 range.
    int256 internal constant MIN_BUFFER_SCALE = 150;
    int256 internal constant BUFFER_SCALE = 10;
    // Max number of traded markets, also used as the maximum number of assets in a portfolio array
    uint256 internal constant MAX_TRADED_MARKET_INDEX = 7;
    // Max number of fCash assets in a bitmap, this is based on the gas costs of calculating free collateral
    // for a bitmap portfolio
    uint256 internal constant MAX_BITMAP_ASSETS = 20;
    uint256 internal constant FIVE_MINUTES = 300;

    // Internal date representations, note we use a 6/30/360 week/month/year convention here
    uint256 internal constant DAY = 86400;
    // We use six day weeks to ensure that all time references divide evenly
    uint256 internal constant WEEK = DAY * 6;
    uint256 internal constant MONTH = WEEK * 5;
    uint256 internal constant QUARTER = MONTH * 3;
    uint256 internal constant YEAR = QUARTER * 4;
    
    // These constants are used in DateTime.sol
    uint256 internal constant DAYS_IN_WEEK = 6;
    uint256 internal constant DAYS_IN_MONTH = 30;
    uint256 internal constant DAYS_IN_QUARTER = 90;

    // Offsets for each time chunk denominated in days
    uint256 internal constant MAX_DAY_OFFSET = 90;
    uint256 internal constant MAX_WEEK_OFFSET = 360;
    uint256 internal constant MAX_MONTH_OFFSET = 2160;
    uint256 internal constant MAX_QUARTER_OFFSET = 7650;

    // Offsets for each time chunk denominated in bits
    uint256 internal constant WEEK_BIT_OFFSET = 90;
    uint256 internal constant MONTH_BIT_OFFSET = 135;
    uint256 internal constant QUARTER_BIT_OFFSET = 195;

    // Number of decimal places that rates are stored in, equals 100%
    int256 internal constant RATE_PRECISION = 1e9;
    // Used for prime cash scalars
    uint256 internal constant SCALAR_PRECISION = 1e18;
    // Used in prime rate lib
    int256 internal constant DOUBLE_SCALAR_PRECISION = 1e36;
    // One basis point in RATE_PRECISION terms
    uint256 internal constant BASIS_POINT = uint256(RATE_PRECISION / 10000);
    // Used to when calculating the amount to deleverage of a market when minting nTokens
    uint256 internal constant DELEVERAGE_BUFFER = 300 * BASIS_POINT;
    // Used for scaling cash group factors
    uint256 internal constant FIVE_BASIS_POINTS = 5 * BASIS_POINT;
    // Used for residual purchase incentive and cash withholding buffer
    uint256 internal constant TEN_BASIS_POINTS = 10 * BASIS_POINT;
    // Used for max oracle rate
    uint256 internal constant FIFTEEN_BASIS_POINTS = 15 * BASIS_POINT;
    // Used in max rate calculations
    uint256 internal constant MAX_LOWER_INCREMENT = 150;
    uint256 internal constant MAX_LOWER_INCREMENT_VALUE = 150 * 25 * BASIS_POINT;
    uint256 internal constant TWENTY_FIVE_BASIS_POINTS = 25 * BASIS_POINT;
    uint256 internal constant ONE_HUNDRED_FIFTY_BASIS_POINTS = 150 * BASIS_POINT;

    // This is the ABDK64x64 representation of RATE_PRECISION
    // RATE_PRECISION_64x64 = ABDKMath64x64.fromUint(RATE_PRECISION)
    int128 internal constant RATE_PRECISION_64x64 = 0x3b9aca000000000000000000;

    uint8 internal constant FCASH_ASSET_TYPE          = 1;
    // Liquidity token asset types are 1 + marketIndex (where marketIndex is 1-indexed)
    uint8 internal constant MIN_LIQUIDITY_TOKEN_INDEX = 2;
    uint8 internal constant MAX_LIQUIDITY_TOKEN_INDEX = 8;
    uint8 internal constant VAULT_SHARE_ASSET_TYPE    = 9;
    uint8 internal constant VAULT_DEBT_ASSET_TYPE     = 10;
    uint8 internal constant VAULT_CASH_ASSET_TYPE     = 11;
    // Used for tracking legacy nToken assets
    uint8 internal constant LEGACY_NTOKEN_ASSET_TYPE  = 12;

    // Account context flags
    bytes1 internal constant HAS_ASSET_DEBT           = 0x01;
    bytes1 internal constant HAS_CASH_DEBT            = 0x02;
    bytes2 internal constant ACTIVE_IN_PORTFOLIO      = 0x8000;
    bytes2 internal constant ACTIVE_IN_BALANCES       = 0x4000;
    bytes2 internal constant UNMASK_FLAGS             = 0x3FFF;
    uint16 internal constant MAX_CURRENCIES           = uint16(UNMASK_FLAGS);

    // Equal to 100% of all deposit amounts for nToken liquidity across fCash markets.
    int256 internal constant DEPOSIT_PERCENT_BASIS    = 1e8;

    // nToken Parameters: there are offsets in the nTokenParameters bytes6 variable returned
    // in nTokenHandler. Each constant represents a position in the byte array.
    uint8 internal constant LIQUIDATION_HAIRCUT_PERCENTAGE = 0;
    uint8 internal constant CASH_WITHHOLDING_BUFFER = 1;
    uint8 internal constant RESIDUAL_PURCHASE_TIME_BUFFER = 2;
    uint8 internal constant PV_HAIRCUT_PERCENTAGE = 3;
    uint8 internal constant RESIDUAL_PURCHASE_INCENTIVE = 4;

    // Liquidation parameters
    // Default percentage of collateral that a liquidator is allowed to liquidate, will be higher if the account
    // requires more collateral to be liquidated
    int256 internal constant DEFAULT_LIQUIDATION_PORTION = 40;
    // Percentage of local liquidity token cash claim delivered to the liquidator for liquidating liquidity tokens
    int256 internal constant TOKEN_REPO_INCENTIVE_PERCENT = 30;

    // Pause Router liquidation enabled states
    bytes1 internal constant LOCAL_CURRENCY_ENABLED = 0x01;
    bytes1 internal constant COLLATERAL_CURRENCY_ENABLED = 0x02;
    bytes1 internal constant LOCAL_FCASH_ENABLED = 0x04;
    bytes1 internal constant CROSS_CURRENCY_FCASH_ENABLED = 0x08;

    // Requires vault accounts to enter a position for a minimum of 1 min
    // to mitigate strange behavior where accounts may enter and exit using
    // flash loans or other MEV type behavior.
    uint256 internal constant VAULT_ACCOUNT_MIN_TIME = 1 minutes;

    // Placeholder constant to mark the variable rate prime cash maturity
    uint40 internal constant PRIME_CASH_VAULT_MATURITY = type(uint40).max;

    // This represents the maximum percent change allowed before and after 
    // a rebalancing. 100_000 represents a 0.01% change
    // as a result of rebalancing. We should expect to never lose value as
    // a result of rebalancing, but some rounding errors may exist as a result
    // of redemption and deposit.
    int256 internal constant REBALANCING_UNDERLYING_DELTA_PERCENT = 100_000;

    // Ensures that the minimum total underlying held by the contract continues
    // to accrue interest so that money market oracle rates are properly updated
    // between rebalancing. With a minimum rebalancing cool down time of 6 hours
    // we would be able to detect at least 1 unit of accrual at 8 decimal precision
    // at an interest rate of 2.8 basis points (0.0288%) with 0.05e8 minimum balance
    // held in a given token.
    //
    //                          MIN_ACCRUAL * (86400 / REBALANCING_COOL_DOWN_HOURS)
    // MINIMUM_INTEREST_RATE =  ---------------------------------------------------
    //                                     MINIMUM_UNDERLYING_BALANCE
    int256 internal constant MIN_TOTAL_UNDERLYING_VALUE = 0.05e8;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

import {WETH9} from "../../interfaces/WETH9.sol";
import {IUpgradeableBeacon} from "../proxy/beacon/IBeacon.sol";
import {AggregatorV2V3Interface} from "../../interfaces/chainlink/AggregatorV2V3Interface.sol";

/// @title Hardcoded deployed contracts are listed here. These are hardcoded to reduce
/// gas costs for immutable addresses. They must be updated per environment that Notional
/// is deployed to.
library Deployments {
    uint256 internal constant MAINNET = 1;
    uint256 internal constant ARBITRUM_ONE = 42161;
    uint256 internal constant LOCAL = 1337;

    // MAINNET: 0xCFEAead4947f0705A14ec42aC3D44129E1Ef3eD5
    // address internal constant NOTE_TOKEN_ADDRESS = 0xCFEAead4947f0705A14ec42aC3D44129E1Ef3eD5;
    // ARBITRUM: 0x019bE259BC299F3F653688c7655C87F998Bc7bC1
    address internal constant NOTE_TOKEN_ADDRESS = 0x019bE259BC299F3F653688c7655C87F998Bc7bC1;

    // MAINNET: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
    // WETH9 internal constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    // ARBITRUM: 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    WETH9 internal constant WETH = WETH9(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    // OPTIMISM: 0x4200000000000000000000000000000000000006

    // Chainlink L2 Sequencer Uptime: https://docs.chain.link/data-feeds/l2-sequencer-feeds/
    // MAINNET: NOT SET
    // AggregatorV2V3Interface internal constant SEQUENCER_UPTIME_ORACLE = AggregatorV2V3Interface(address(0));
    // ARBITRUM: 0xFdB631F5EE196F0ed6FAa767959853A9F217697D
    AggregatorV2V3Interface internal constant SEQUENCER_UPTIME_ORACLE = AggregatorV2V3Interface(0xFdB631F5EE196F0ed6FAa767959853A9F217697D);

    enum BeaconType {
        NTOKEN,
        PCASH,
        PDEBT,
        WRAPPED_FCASH
    }

    // NOTE: these are temporary Beacon addresses
    IUpgradeableBeacon internal constant NTOKEN_BEACON = IUpgradeableBeacon(0xc4FD259b816d081C8bdd22D6bbd3495DB1573DB7);
    IUpgradeableBeacon internal constant PCASH_BEACON = IUpgradeableBeacon(0x1F681977aF5392d9Ca5572FB394BC4D12939A6A9);
    IUpgradeableBeacon internal constant PDEBT_BEACON = IUpgradeableBeacon(0xDF08039c0af34E34660aC7c2705C0Da953247640);
    IUpgradeableBeacon internal constant WRAPPED_FCASH_BEACON = IUpgradeableBeacon(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    // TODO: this will be set to the timestamp of the final settlement time in notional v2,
    // no assets can be settled prior to this date once the notional v3 upgrade is enabled.
    uint256 internal constant NOTIONAL_V2_FINAL_SETTLEMENT = 0;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Types.sol";
import "./Constants.sol";
import "../../interfaces/notional/IRewarder.sol";
import "../../interfaces/aave/ILendingPool.sol";

library LibStorage {

    /// @dev Offset for the initial slot in lib storage, gives us this number of storage slots
    /// available in StorageLayoutV1 and all subsequent storage layouts that inherit from it.
    uint256 private constant STORAGE_SLOT_BASE = 1000000;
    /// @dev Set to MAX_TRADED_MARKET_INDEX * 2, Solidity does not allow assigning constants from imported values
    uint256 private constant NUM_NTOKEN_MARKET_FACTORS = 14;
    /// @dev Maximum limit for portfolio asset array, this has been reduced from 16 in the previous version. No
    /// account has hit the theoretical limit and it would not possible for them to since accounts do not hold
    /// liquidity tokens (only the nToken does).
    uint256 internal constant MAX_PORTFOLIO_ASSETS = 8;

    /// @dev Storage IDs for storage buckets. Each id maps to an internal storage
    /// slot used for a particular mapping
    ///     WARNING: APPEND ONLY
    enum StorageId {
        Unused,
        AccountStorage,
        nTokenContext,
        nTokenAddress,
        nTokenDeposit,
        nTokenInitialization,
        Balance,
        Token,
        SettlementRate_deprecated,
        CashGroup,
        Market,
        AssetsBitmap,
        ifCashBitmap,
        PortfolioArray,
        // WARNING: this nTokenTotalSupply storage object was used for a buggy version
        // of the incentives calculation. It should only be used for accounts who have
        // not claimed before the migration
        nTokenTotalSupply_deprecated,
        AssetRate_deprecated,
        ExchangeRate,
        nTokenTotalSupply,
        SecondaryIncentiveRewarder,
        LendingPool,
        VaultConfig,
        VaultState,
        VaultAccount,
        VaultBorrowCapacity,
        VaultSecondaryBorrow,
        // With the upgrade to prime cash vaults, settled assets is no longer required
        // for the vault calculation. Do not remove this or other storage slots will be
        // broken.
        VaultSettledAssets_deprecated,
        VaultAccountSecondaryDebtShare,
        ActiveInterestRateParameters,
        NextInterestRateParameters,
        PrimeCashFactors,
        PrimeSettlementRates,
        PrimeCashHoldingsOracles,
        TotalfCashDebtOutstanding,
        pCashAddress,
        pDebtAddress,
        pCashTransferAllowance,
        RebalancingTargets,
        RebalancingContext,
        StoredTokenBalances
    }

    /// @dev Mapping from an account address to account context
    function getAccountStorage() internal pure 
        returns (mapping(address => AccountContext) storage store) 
    {
        uint256 slot = _getStorageSlot(StorageId.AccountStorage);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from an nToken address to nTokenContext
    function getNTokenContextStorage() internal pure
        returns (mapping(address => nTokenContext) storage store) 
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenContext);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to nTokenAddress
    function getNTokenAddressStorage() internal pure
        returns (mapping(uint256 => address) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenAddress);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to uint32 fixed length array of
    /// deposit factors. Deposit shares and leverage thresholds are stored striped to
    /// reduce the number of storage reads.
    function getNTokenDepositStorage() internal pure
        returns (mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenDeposit);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to fixed length array of initialization factors,
    /// stored striped like deposit shares.
    function getNTokenInitStorage() internal pure
        returns (mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenInitialization);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to currencyId to it's balance storage for that currency
    function getBalanceStorage() internal pure
        returns (mapping(address => mapping(uint256 => BalanceStorage)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.Balance);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to a boolean for underlying or asset token to
    /// the TokenStorage
    function getTokenStorage() internal pure
        returns (mapping(uint256 => mapping(bool => TokenStorage)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.Token);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to maturity to its corresponding SettlementRate
    function getSettlementRateStorage_deprecated() internal pure
        returns (mapping(uint256 => mapping(uint256 => SettlementRateStorage)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.SettlementRate_deprecated);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to maturity to its tightly packed cash group parameters
    function getCashGroupStorage() internal pure
        returns (mapping(uint256 => bytes32) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.CashGroup);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from currency id to maturity to settlement date for a market
    function getMarketStorage() internal pure
        returns (mapping(uint256 => mapping(uint256 => mapping(uint256 => MarketStorage))) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.Market);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to currency id to its assets bitmap
    function getAssetsBitmapStorage() internal pure
        returns (mapping(address => mapping(uint256 => bytes32)) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AssetsBitmap);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to currency id to its maturity to its corresponding ifCash balance
    function getifCashBitmapStorage() internal pure
        returns (mapping(address => mapping(uint256 => mapping(uint256 => ifCashStorage))) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.ifCashBitmap);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from account to its fixed length array of portfolio assets
    function getPortfolioArrayStorage() internal pure
        returns (mapping(address => PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS]) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.PortfolioArray);
        assembly { store.slot := slot }
    }

    function getDeprecatedNTokenTotalSupplyStorage() internal pure
        returns (mapping(address => nTokenTotalSupplyStorage_deprecated) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenTotalSupply_deprecated);
        assembly { store.slot := slot }
    }

    /// @dev Mapping from nToken address to its total supply values
    function getNTokenTotalSupplyStorage() internal pure
        returns (mapping(address => nTokenTotalSupplyStorage) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.nTokenTotalSupply);
        assembly { store.slot := slot }
    }

    /// @dev Returns the exchange rate between an underlying currency and asset for trading
    /// and free collateral. Mapping is from currency id to rate storage object.
    function getAssetRateStorage_deprecated() internal pure
        returns (mapping(uint256 => AssetRateStorage) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.AssetRate_deprecated);
        assembly { store.slot := slot }
    }

    /// @dev Returns the exchange rate between an underlying currency and ETH for free
    /// collateral purposes. Mapping is from currency id to rate storage object.
    function getExchangeRateStorage() internal pure
        returns (mapping(uint256 => ETHRateStorage) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.ExchangeRate);
        assembly { store.slot := slot }
    }

    /// @dev Returns the address of a secondary incentive rewarder for an nToken if it exists
    function getSecondaryIncentiveRewarder() internal pure
        returns (mapping(address => IRewarder) storage store)
    {
        uint256 slot = _getStorageSlot(StorageId.SecondaryIncentiveRewarder);
        assembly { store.slot := slot }
    }

    /// @dev Returns the address of the lending pool
    function getLendingPool() internal pure returns (LendingPoolStorage storage store) {
        uint256 slot = _getStorageSlot(StorageId.LendingPool);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for an VaultConfig, mapping is from vault address to VaultConfig object
    function getVaultConfig() internal pure returns (
        mapping(address => VaultConfigStorage) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.VaultConfig);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for an VaultState, mapping is from vault address to maturity to VaultState object
    function getVaultState() internal pure returns (
        mapping(address => mapping(uint256 => VaultStateStorage)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.VaultState);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for an VaultAccount, mapping is from account address to vault address to VaultAccount object
    function getVaultAccount() internal pure returns (
        mapping(address => mapping(address => VaultAccountStorage)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.VaultAccount);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for a VaultBorrowCapacity, mapping is from vault address to currency to BorrowCapacity object
    function getVaultBorrowCapacity() internal pure returns (
        mapping(address => mapping(uint256 => VaultBorrowCapacityStorage)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.VaultBorrowCapacity);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for an VaultAccount, mapping is from account address to vault address to maturity to
    /// currencyId to VaultStateStorage object, only totalDebt, totalPrimeCash, and isSettled are used for
    /// vault secondary borrows, but this allows code to be shared.
    function getVaultSecondaryBorrow() internal pure returns (
        mapping(address => mapping(uint256 => mapping(uint256 => VaultStateStorage))) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.VaultSecondaryBorrow);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for an VaultAccount, mapping is from account address to vault address
    function getVaultAccountSecondaryDebtShare() internal pure returns (
        mapping(address => mapping(address => VaultAccountSecondaryDebtShareStorage)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.VaultAccountSecondaryDebtShare);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for currently active InterestRateParameters,
    /// mapping is from a currency id to a bytes32[2] array of parameters
    function getActiveInterestRateParameters() internal pure returns (
        mapping(uint256 => bytes32[2]) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.ActiveInterestRateParameters);
        assembly { store.slot := slot }
    }

    /// @dev Returns object for the next set of InterestRateParameters,
    /// mapping is from a currency id to a bytes32[2] array of parameters
    function getNextInterestRateParameters() internal pure returns (
        mapping(uint256 => bytes32[2]) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.NextInterestRateParameters);
        assembly { store.slot := slot }
    }

    /// @dev Returns mapping from currency id to PrimeCashFactors
    function getPrimeCashFactors() internal pure returns (
        mapping(uint256 => PrimeCashFactorsStorage) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.PrimeCashFactors);
        assembly { store.slot := slot }
    }

    /// @dev Returns mapping from currency to maturity to PrimeSettlementRates
    function getPrimeSettlementRates() internal pure returns (
        mapping(uint256 => mapping(uint256 => PrimeSettlementRateStorage)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.PrimeSettlementRates);
        assembly { store.slot := slot }
    }

    /// @dev Returns mapping from currency to an external oracle that reports the
    /// total underlying value for prime cash
    function getPrimeCashHoldingsOracle() internal pure returns (
        mapping(uint256 => PrimeCashHoldingsOracle) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.PrimeCashHoldingsOracles);
        assembly { store.slot := slot }
    }

    /// @dev Returns mapping from currency to maturity to total fCash debt outstanding figure.
    function getTotalfCashDebtOutstanding() internal pure returns (
        mapping(uint256 => mapping(uint256 => TotalfCashDebtStorage)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.TotalfCashDebtOutstanding);
        assembly { store.slot := slot }
    }

    /// @dev Returns mapping from currency to pCash proxy address
    function getPCashAddressStorage() internal pure returns (
        mapping(uint256 => address) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.pCashAddress);
        assembly { store.slot := slot }
    }

    function getPDebtAddressStorage() internal pure returns (
        mapping(uint256 => address) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.pDebtAddress);
        assembly { store.slot := slot }
    }

    /// @dev Returns mapping for pCash ERC20 transfer allowances
    function getPCashTransferAllowance() internal pure returns (
        // owner => spender => currencyId => transferAllowance
        mapping(address => mapping(address => mapping(uint16 => uint256))) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.pCashTransferAllowance);
        assembly { store.slot := slot }
    }

    function getRebalancingTargets() internal pure returns (
        mapping(uint16 => mapping(address => uint8)) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.RebalancingTargets);
        assembly { store.slot := slot }
    }

    function getRebalancingContext() internal pure returns (
        mapping(uint16 => RebalancingContextStorage) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.RebalancingContext);
        assembly { store.slot := slot }
    }

    function getStoredTokenBalances() internal pure returns (
        mapping(address => uint256) storage store
    ) {
        uint256 slot = _getStorageSlot(StorageId.StoredTokenBalances);
        assembly { store.slot := slot }        
    }

    /// @dev Get the storage slot given a storage ID.
    /// @param storageId An entry in `StorageId`
    /// @return slot The storage slot.
    function _getStorageSlot(StorageId storageId)
        private
        pure
        returns (uint256 slot)
    {
        // This should never overflow with a reasonable `STORAGE_SLOT_EXP`
        // because Solidity will do a range check on `storageId` during the cast.
        return uint256(storageId) + STORAGE_SLOT_BASE;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

/**
 * @notice Storage layout for the system. Do not change this file once deployed, future storage
 * layouts must inherit this and increment the version number.
 */
contract StorageLayoutV1 {
    // The current maximum currency id
    uint16 internal maxCurrencyId;
    // Sets the state of liquidations being enabled during a paused state. Each of the four lower
    // bits can be turned on to represent one of the liquidation types being enabled.
    bytes1 internal liquidationEnabledState;
    // Set to true once the system has been initialized
    bool internal hasInitialized;

    /* Authentication Mappings */
    // This is set to the timelock contract to execute governance functions
    address public owner;
    // This is set to an address of a router that can only call governance actions
    address public pauseRouter;
    // This is set to an address of a router that can only call governance actions
    address public pauseGuardian;
    // On upgrades this is set in the case that the pause router is used to pass the rollback check
    address internal rollbackRouterImplementation;

    // A blanket allowance for a spender to transfer any of an account's nTokens. This would allow a user
    // to set an allowance on all nTokens for a particular integrating contract system.
    // owner => spender => transferAllowance
    mapping(address => mapping(address => uint256)) internal nTokenWhitelist;
    // Individual transfer allowances for nTokens used for ERC20
    // owner => spender => currencyId => transferAllowance
    mapping(address => mapping(address => mapping(uint16 => uint256))) internal nTokenAllowance;

    // Transfer operators
    // Mapping from a global ERC1155 transfer operator contract to an approval value for it
    mapping(address => bool) internal globalTransferOperator;
    // Mapping from an account => operator => approval status for that operator. This is a specific
    // approval between two addresses for ERC1155 transfers.
    mapping(address => mapping(address => bool)) internal accountAuthorizedTransferOperator;
    // Approval for a specific contract to use the `batchBalanceAndTradeActionWithCallback` method in
    // BatchAction.sol, can only be set by governance
    mapping(address => bool) internal authorizedCallbackContract;

    // Reverse mapping from token addresses to currency ids, only used for referencing in views
    // and checking for duplicate token listings.
    mapping(address => uint16) internal tokenAddressToCurrencyId;

    // Reentrancy guard
    uint256 internal reentrancyStatus;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../../interfaces/notional/IPrimeCashHoldingsOracle.sol";
import "../../interfaces/notional/AssetRateAdapter.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
///  - aToken: Aave interest bearing tokens
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable,
    aToken
}

/// @notice Specifies the different trade action types in the system. Each trade action type is
/// encoded in a tightly packed bytes32 object. Trade action type is the first big endian byte of the
/// 32 byte trade action object. The schemas for each trade action type are defined below.
enum TradeActionType {
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 minImpliedRate, uint120 unused)
    Lend,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 fCashAmount, uint32 maxImpliedRate, uint128 unused)
    Borrow,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 primeCashAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    AddLiquidity,
    // (uint8 TradeActionType, uint8 MarketIndex, uint88 tokenAmount, uint32 minImpliedRate, uint32 maxImpliedRate, uint88 unused)
    RemoveLiquidity,
    // (uint8 TradeActionType, uint32 Maturity, int88 fCashResidualAmount, uint128 unused)
    PurchaseNTokenResidual,
    // (uint8 TradeActionType, address CounterpartyAddress, int88 fCashAmountToSettle)
    SettleCashDebt
}

/// @notice Specifies different deposit actions that can occur during BalanceAction or BalanceActionWithTrades
enum DepositActionType {
    // No deposit action
    None,
    // Deposit asset cash, depositActionAmount is specified in asset cash external precision
    DepositAsset,
    // Deposit underlying tokens that are mintable to asset cash, depositActionAmount is specified in underlying token
    // external precision
    DepositUnderlying,
    // Deposits specified asset cash external precision amount into an nToken and mints the corresponding amount of
    // nTokens into the account
    DepositAssetAndMintNToken,
    // Deposits specified underlying in external precision, mints asset cash, and uses that asset cash to mint nTokens
    DepositUnderlyingAndMintNToken,
    // Redeems an nToken balance to asset cash. depositActionAmount is specified in nToken precision. Considered a deposit action
    // because it deposits asset cash into an account. If there are fCash residuals that cannot be sold off, will revert.
    RedeemNToken,
    // Converts specified amount of asset cash balance already in Notional to nTokens. depositActionAmount is specified in
    // Notional internal 8 decimal precision.
    ConvertCashToNToken
}

/// @notice Used internally for PortfolioHandler state
enum AssetStorageState {
    NoChange,
    Update,
    Delete,
    RevertIfStored
}

/****** Calldata objects ******/

/// @notice Defines a batch lending action
struct BatchLend {
    uint16 currencyId;
    // True if the contract should try to transfer underlying tokens instead of asset tokens
    bool depositUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/// @notice Defines a balance action for batchAction
struct BalanceAction {
    // Deposit action to take (if any)
    DepositActionType actionType;
    uint16 currencyId;
    // Deposit action amount must correspond to the depositActionType, see documentation above.
    uint256 depositActionAmount;
    // Withdraw an amount of asset cash specified in Notional internal 8 decimal precision
    uint256 withdrawAmountInternalPrecision;
    // If set to true, will withdraw entire cash balance. Useful if there may be an unknown amount of asset cash
    // residual left from trading.
    bool withdrawEntireCashBalance;
    // If set to true, will redeem asset cash to the underlying token on withdraw.
    bool redeemToUnderlying;
}

/// @notice Defines a balance action with a set of trades to do as well
struct BalanceActionWithTrades {
    DepositActionType actionType;
    uint16 currencyId;
    uint256 depositActionAmount;
    uint256 withdrawAmountInternalPrecision;
    bool withdrawEntireCashBalance;
    bool redeemToUnderlying;
    // Array of tightly packed 32 byte objects that represent trades. See TradeActionType documentation
    bytes32[] trades;
}

/****** In memory objects ******/
/// @notice Internal object that represents settled cash balances
struct SettleAmount {
    uint16 currencyId;
    int256 positiveSettledCash;
    int256 negativeSettledCash;
    PrimeRate presentPrimeRate;
}

/// @notice Internal object that represents a token
struct Token {
    address tokenAddress;
    bool hasTransferFee;
    int256 decimals;
    TokenType tokenType;
    uint256 deprecated_maxCollateralBalance;
}

/// @notice Internal object that represents an nToken portfolio
struct nTokenPortfolio {
    CashGroupParameters cashGroup;
    PortfolioState portfolioState;
    int256 totalSupply;
    int256 cashBalance;
    uint256 lastInitializedTime;
    bytes6 parameters;
    address tokenAddress;
}

/// @notice Internal object used during liquidation
struct LiquidationFactors {
    address account;
    // Aggregate free collateral of the account denominated in ETH underlying, 8 decimal precision
    int256 netETHValue;
    // Amount of net local currency asset cash before haircuts and buffers available
    int256 localPrimeAvailable;
    // Amount of net collateral currency asset cash before haircuts and buffers available
    int256 collateralAssetAvailable;
    // Haircut value of nToken holdings denominated in asset cash, will be local or collateral nTokens based
    // on liquidation type
    int256 nTokenHaircutPrimeValue;
    // nToken parameters for calculating liquidation amount
    bytes6 nTokenParameters;
    // ETH exchange rate from local currency to ETH
    ETHRate localETHRate;
    // ETH exchange rate from collateral currency to ETH
    ETHRate collateralETHRate;
    // Asset rate for the local currency, used in cross currency calculations to calculate local asset cash required
    PrimeRate localPrimeRate;
    // Used during currency liquidations if the account has liquidity tokens
    CashGroupParameters collateralCashGroup;
    // Used during currency liquidations if it is only a calculation, defaults to false
    bool isCalculation;
}

/// @notice Internal asset array portfolio state
struct PortfolioState {
    // Array of currently stored assets
    PortfolioAsset[] storedAssets;
    // Array of new assets to add
    PortfolioAsset[] newAssets;
    uint256 lastNewAssetIndex;
    // Holds the length of stored assets after accounting for deleted assets
    uint256 storedAssetLength;
}

/// @notice In memory ETH exchange rate used during free collateral calculation.
struct ETHRate {
    // The decimals (i.e. 10^rateDecimalPlaces) of the exchange rate, defined by the rate oracle
    int256 rateDecimals;
    // The exchange rate from base to ETH (if rate invert is required it is already done)
    int256 rate;
    // Amount of buffer as a multiple with a basis of 100 applied to negative balances.
    int256 buffer;
    // Amount of haircut as a multiple with a basis of 100 applied to positive balances
    int256 haircut;
    // Liquidation discount as a multiple with a basis of 100 applied to the exchange rate
    // as an incentive given to liquidators.
    int256 liquidationDiscount;
}

/// @notice Internal object used to handle balance state during a transaction
struct BalanceState {
    uint16 currencyId;
    // Cash balance stored in balance state at the beginning of the transaction
    int256 storedCashBalance;
    // nToken balance stored at the beginning of the transaction
    int256 storedNTokenBalance;
    // The net cash change as a result of asset settlement or trading
    int256 netCashChange;
    // Amount of prime cash to redeem and withdraw from the system
    int256 primeCashWithdraw;
    // Net token transfers into or out of the account
    int256 netNTokenTransfer;
    // Net token supply change from minting or redeeming
    int256 netNTokenSupplyChange;
    // The last time incentives were claimed for this currency
    uint256 lastClaimTime;
    // Accumulator for incentives that the account no longer has a claim over
    uint256 accountIncentiveDebt;
    // Prime rate for converting prime cash balances
    PrimeRate primeRate;
}

/// @dev Asset rate used to convert between underlying cash and asset cash
struct Deprecated_AssetRateParameters {
    // Address of the asset rate oracle
    AssetRateAdapter rateOracle;
    // The exchange rate from base to quote (if invert is required it is already done)
    int256 rate;
    // The decimals of the underlying, the rate converts to the underlying decimals
    int256 underlyingDecimals;
}

/// @dev Cash group when loaded into memory
struct CashGroupParameters {
    uint16 currencyId;
    uint256 maxMarketIndex;
    PrimeRate primeRate;
    bytes32 data;
}

/// @dev A portfolio asset when loaded in memory
struct PortfolioAsset {
    // Asset currency id
    uint16 currencyId;
    uint256 maturity;
    // Asset type, fCash or liquidity token.
    uint256 assetType;
    // fCash amount or liquidity token amount
    int256 notional;
    // Used for managing portfolio asset state
    uint256 storageSlot;
    // The state of the asset for when it is written to storage
    AssetStorageState storageState;
}

/// @dev Market object as represented in memory
struct MarketParameters {
    bytes32 storageSlot;
    uint256 maturity;
    // Total amount of fCash available for purchase in the market.
    int256 totalfCash;
    // Total amount of cash available for purchase in the market.
    int256 totalPrimeCash;
    // Total amount of liquidity tokens (representing a claim on liquidity) in the market.
    int256 totalLiquidity;
    // This is the previous annualized interest rate in RATE_PRECISION that the market traded
    // at. This is used to calculate the rate anchor to smooth interest rates over time.
    uint256 lastImpliedRate;
    // Time lagged version of lastImpliedRate, used to value fCash assets at market rates while
    // remaining resistent to flash loan attacks.
    uint256 oracleRate;
    // This is the timestamp of the previous trade
    uint256 previousTradeTime;
}

/****** Storage objects ******/

/// @dev Token object in storage:
///  20 bytes for token address
///  1 byte for hasTransferFee
///  1 byte for tokenType
///  1 byte for tokenDecimals
///  9 bytes for maxCollateralBalance (may not always be set)
struct TokenStorage {
    // Address of the token
    address tokenAddress;
    // Transfer fees will change token deposit behavior
    bool hasTransferFee;
    TokenType tokenType;
    uint8 decimalPlaces;
    uint72 deprecated_maxCollateralBalance;
}

/// @dev Exchange rate object as it is represented in storage, total storage is 25 bytes.
struct ETHRateStorage {
    // Address of the rate oracle
    AggregatorV2V3Interface rateOracle;
    // The decimal places of precision that the rate oracle uses
    uint8 rateDecimalPlaces;
    // True of the exchange rate must be inverted
    bool mustInvert;
    // NOTE: both of these governance values are set with BUFFER_DECIMALS precision
    // Amount of buffer to apply to the exchange rate for negative balances.
    uint8 buffer;
    // Amount of haircut to apply to the exchange rate for positive balances
    uint8 haircut;
    // Liquidation discount in percentage point terms, 106 means a 6% discount
    uint8 liquidationDiscount;
}

/// @dev Asset rate oracle object as it is represented in storage, total storage is 21 bytes.
struct AssetRateStorage {
    // Address of the rate oracle
    AssetRateAdapter rateOracle;
    // The decimal places of the underlying asset
    uint8 underlyingDecimalPlaces;
}

/// @dev Governance parameters for a cash group, total storage is 9 bytes + 7 bytes for liquidity token haircuts
/// and 7 bytes for rate scalars, total of 23 bytes. Note that this is stored packed in the storage slot so there
/// are no indexes stored for liquidityTokenHaircuts or rateScalars, maxMarketIndex is used instead to determine the
/// length.
struct CashGroupSettings {
    // Index of the AMMs on chain that will be made available. Idiosyncratic fCash
    // that is dated less than the longest AMM will be tradable.
    uint8 maxMarketIndex;
    // Time window in 5 minute increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // Absolute maximum discount factor as a discount from 1e9, specified in five basis points
    // subtracted from 1e9
    uint8 maxDiscountFactor5BPS;
    // Share of the fees given to the protocol, denominated in percentage
    uint8 reserveFeeShare;
    // Debt buffer specified in 5 BPS increments
    uint8 debtBuffer25BPS;
    // fCash haircut specified in 5 BPS increments
    uint8 fCashHaircut25BPS;
    // Minimum oracle interest rates for fCash per market, specified in 25 bps increments
    uint8 minOracleRate25BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationfCashHaircut25BPS;
    // If an account has fCash that is being liquidated, this is the discount that the liquidator can purchase it for
    uint8 liquidationDebtBuffer25BPS;
    // Max oracle rate specified in 25bps increments as a discount from the max rate in the market.
    uint8 maxOracleRate25BPS;
}

/// @dev Holds account level context information used to determine settlement and
/// free collateral actions. Total storage is 28 bytes
struct AccountContext {
    // Used to check when settlement must be triggered on an account
    uint40 nextSettleTime;
    // For lenders that never incur debt, we use this flag to skip the free collateral check.
    bytes1 hasDebt;
    // Length of the account's asset array
    uint8 assetArrayLength;
    // If this account has bitmaps set, this is the corresponding currency id
    uint16 bitmapCurrencyId;
    // 9 total active currencies possible (2 bytes each)
    bytes18 activeCurrencies;
    // If this is set to true, the account can borrow variable prime cash and incur
    // negative cash balances inside BatchAction. This does not impact the settlement
    // of negative fCash to prime cash which will happen regardless of this setting. This
    // exists here mainly as a safety setting to ensure that accounts do not accidentally
    // incur negative cash balances.
    bool allowPrimeBorrow;
}

/// @dev Holds nToken context information mapped via the nToken address, total storage is
/// 16 bytes
struct nTokenContext {
    // Currency id that the nToken represents
    uint16 currencyId;
    // Annual incentive emission rate denominated in WHOLE TOKENS (multiply by
    // INTERNAL_TOKEN_PRECISION to get the actual rate)
    uint32 incentiveAnnualEmissionRate;
    // The last block time at utc0 that the nToken was initialized at, zero if it
    // has never been initialized
    uint32 lastInitializedTime;
    // Length of the asset array, refers to the number of liquidity tokens an nToken
    // currently holds
    uint8 assetArrayLength;
    // Each byte is a specific nToken parameter
    bytes5 nTokenParameters;
    // Reserved bytes for future usage
    bytes15 _unused;
    // Set to true if a secondary rewarder is set
    bool hasSecondaryRewarder;
}

/// @dev Holds account balance information, total storage 32 bytes
struct BalanceStorage {
    // Number of nTokens held by the account
    uint80 nTokenBalance;
    // Last time the account claimed their nTokens
    uint32 lastClaimTime;
    // Incentives that the account no longer has a claim over
    uint56 accountIncentiveDebt;
    // Cash balance of the account
    int88 cashBalance;
}

/// @dev Holds information about a settlement rate, total storage 25 bytes
struct SettlementRateStorage {
    uint40 blockTime;
    uint128 settlementRate;
    uint8 underlyingDecimalPlaces;
}

/// @dev Holds information about a market, total storage is 42 bytes so this spans
/// two storage words
struct MarketStorage {
    // Total fCash in the market
    uint80 totalfCash;
    // Total asset cash in the market
    uint80 totalPrimeCash;
    // Last annualized interest rate the market traded at
    uint32 lastImpliedRate;
    // Last recorded oracle rate for the market
    uint32 oracleRate;
    // Last time a trade was made
    uint32 previousTradeTime;
    // This is stored in slot + 1
    uint80 totalLiquidity;
}

struct InterestRateParameters {
    // First kink for the utilization rate in RATE_PRECISION
    uint256 kinkUtilization1;
    // Second kink for the utilization rate in RATE_PRECISION
    uint256 kinkUtilization2;
    // First kink interest rate in RATE_PRECISION
    uint256 kinkRate1;
    // Second kink interest rate in RATE_PRECISION
    uint256 kinkRate2;
    // Max interest rate in RATE_PRECISION
    uint256 maxRate;
    // Minimum fee charged in RATE_PRECISION
    uint256 minFeeRate;
    // Maximum fee charged in RATE_PRECISION
    uint256 maxFeeRate;
    // Percentage of the interest rate that will be applied as a fee
    uint256 feeRatePercent;
}

// Specific interest rate curve settings for each market
struct InterestRateCurveSettings {
    // First kink for the utilization rate, specified as a percentage
    // between 1-100
    uint8 kinkUtilization1;
    // Second kink for the utilization rate, specified as a percentage
    // between 1-100
    uint8 kinkUtilization2;
    // Interest rate at the first kink, set as 1/256 units from the kink
    // rate max
    uint8 kinkRate1;
    // Interest rate at the second kink, set as 1/256 units from the kink
    // rate max
    uint8 kinkRate2;
    // Max interest rate, set in units in 25bps increments less than or equal to 150
    // and 150bps increments from 151 to 255.
    uint8 maxRateUnits;
    // Minimum fee charged in basis points
    uint8 minFeeRate5BPS;
    // Maximum fee charged in basis points
    uint8 maxFeeRate25BPS;
    // Percentage of the interest rate that will be applied as a fee
    uint8 feeRatePercent;
}

struct ifCashStorage {
    // Notional amount of fCash at the slot, limited to int128 to allow for
    // future expansion
    int128 notional;
}

/// @dev A single portfolio asset in storage, total storage of 19 bytes
struct PortfolioAssetStorage {
    // Currency Id for the asset
    uint16 currencyId;
    // Maturity of the asset
    uint40 maturity;
    // Asset type (fCash or Liquidity Token marker)
    uint8 assetType;
    // Notional
    int88 notional;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes. This is the deprecated version
struct nTokenTotalSupplyStorage_deprecated {
    // Total supply of the nToken
    uint96 totalSupply;
    // Integral of the total supply used for calculating the average total supply
    uint128 integralTotalSupply;
    // Last timestamp the supply value changed, used for calculating the integralTotalSupply
    uint32 lastSupplyChangeTime;
}

/// @dev nToken total supply factors for the nToken, includes factors related
/// to claiming incentives, total storage 32 bytes.
struct nTokenTotalSupplyStorage {
    // Total supply of the nToken
    uint96 totalSupply;
    // How many NOTE incentives should be issued per nToken in 1e18 precision
    uint128 accumulatedNOTEPerNToken;
    // Last timestamp when the accumulation happened
    uint32 lastAccumulatedTime;
}

/// @dev Used in view methods to return account balances in a developer friendly manner
struct AccountBalance {
    uint16 currencyId;
    int256 cashBalance;
    int256 nTokenBalance;
    uint256 lastClaimTime;
    uint256 accountIncentiveDebt;
}

struct VaultConfigParams {
    uint16 flags;
    uint16 borrowCurrencyId;
    uint256 minAccountBorrowSize;
    uint16 minCollateralRatioBPS;
    uint8 feeRate5BPS;
    uint8 liquidationRate;
    uint8 reserveFeeShare;
    uint8 maxBorrowMarketIndex;
    uint16 maxDeleverageCollateralRatioBPS;
    uint16[2] secondaryBorrowCurrencies;
    uint16 maxRequiredAccountCollateralRatioBPS;
    uint256[2] minAccountSecondaryBorrow;
    uint8 excessCashLiquidationBonus;
}

struct VaultConfigStorage {
    // Vault Flags (documented in VaultConfiguration.sol)
    uint16 flags;
    // Primary currency the vault borrows in
    uint16 borrowCurrencyId;
    // Specified in whole tokens in 1e8 precision, allows a 4.2 billion min borrow size
    uint32 minAccountBorrowSize;
    // Minimum collateral ratio for a vault specified in basis points, valid values are greater than 10_000
    // where the largest minimum collateral ratio is 65_536 which is much higher than anything reasonable.
    uint16 minCollateralRatioBPS;
    // Allows up to a 12.75% annualized fee
    uint8 feeRate5BPS;
    // A percentage that represents the share of the cash raised that will go to the liquidator
    uint8 liquidationRate;
    // A percentage of the fee given to the protocol
    uint8 reserveFeeShare;
    // Maximum market index where a vault can borrow from
    uint8 maxBorrowMarketIndex;
    // Maximum collateral ratio that a liquidator can push a an account to during deleveraging
    uint16 maxDeleverageCollateralRatioBPS;
    // An optional list of secondary borrow currencies
    uint16[2] secondaryBorrowCurrencies;
    // Required collateral ratio for accounts to stay inside a vault, prevents accounts
    // from "free riding" on vaults. Enforced on entry and exit, not on deleverage.
    uint16 maxRequiredAccountCollateralRatioBPS;
    // Specified in whole tokens in 1e8 precision, allows a 4.2 billion min borrow size
    uint32[2] minAccountSecondaryBorrow;
    // Specified as a percent discount off the exchange rate of the excess cash that will be paid to
    // the liquidator during liquidateExcessVaultCash
    uint8 excessCashLiquidationBonus;
    // 8 bytes left
}

struct VaultBorrowCapacityStorage {
    // Total fCash across all maturities that caps the borrow capacity
    uint80 maxBorrowCapacity;
    // Total fCash debt across all maturities
    uint80 totalfCashDebt;
}

struct VaultAccountSecondaryDebtShareStorage {
    // Maturity for the account's secondary borrows. This is stored separately from
    // the vault account maturity to ensure that we have access to the proper state
    // during a roll borrow position. It should never be allowed to deviate from the
    // vaultAccount.maturity value (unless it is cleared to zero).
    uint40 maturity;
    // Account debt for the first secondary currency in either fCash or pCash denomination
    uint80 accountDebtOne;
    // Account debt for the second secondary currency in either fCash or pCash denomination
    uint80 accountDebtTwo;
}

struct VaultConfig {
    address vault;
    uint16 flags;
    uint16 borrowCurrencyId;
    int256 minAccountBorrowSize;
    int256 feeRate;
    int256 minCollateralRatio;
    int256 liquidationRate;
    int256 reserveFeeShare;
    uint256 maxBorrowMarketIndex;
    int256 maxDeleverageCollateralRatio;
    uint16[2] secondaryBorrowCurrencies;
    PrimeRate primeRate;
    int256 maxRequiredAccountCollateralRatio;
    int256[2] minAccountSecondaryBorrow;
    int256 excessCashLiquidationBonus;
}

/// @notice Represents a Vault's current borrow and collateral state
struct VaultStateStorage {
    // This represents the total amount of borrowing in the vault for the current
    // vault term. If the vault state is the prime cash maturity, this is stored in
    // prime cash debt denomination, if fCash then it is stored in internal underlying.
    uint80 totalDebt;
    // The total amount of prime cash in the pool held as a result of emergency settlement
    uint80 deprecated_totalPrimeCash;
    // Total vault shares in this maturity
    uint80 totalVaultShares;
    // Set to true if a vault's debt position has been migrated to the prime cash vault
    bool isSettled;
    // NOTE: 8 bits left
    // ----- This breaks into a new storage slot -------    
    // The total amount of strategy tokens held in the pool
    uint80 deprecated_totalStrategyTokens;
    // Valuation of a strategy token at settlement
    int80 deprecated_settlementStrategyTokenValue;
    // NOTE: 96 bits left
}

/// @notice Represents the remaining assets in a vault post settlement
struct Deprecated_VaultSettledAssetsStorage {
    // Remaining strategy tokens that have not been withdrawn
    uint80 remainingStrategyTokens;
    // Remaining asset cash that has not been withdrawn
    int80 remainingPrimeCash;
}

struct VaultState {
    uint256 maturity;
    // Total debt is always denominated in underlying on the stack
    int256 totalDebtUnderlying;
    uint256 totalVaultShares;
    bool isSettled;
}

/// @notice Represents an account's position within an individual vault
struct VaultAccountStorage {
    // Total amount of debt for the account in the primary borrowed currency.
    // If the account is borrowing prime cash, this is stored in prime cash debt
    // denomination, if fCash then it is stored in internal underlying.
    uint80 accountDebt;
    // Vault shares that the account holds
    uint80 vaultShares;
    // Maturity when the vault shares and fCash will mature
    uint40 maturity;
    // Last time when a vault was entered or exited, used to ensure that vault accounts do not
    // flash enter/exit. While there is no specified attack vector here, we can use it to prevent
    // an entire class of attacks from happening without reducing UX.
    // NOTE: in the original version this value was set to the block.number, however, in this
    // version it is being changed to time based. On ETH mainnet block heights are much smaller
    // than block times, accounts that migrate from lastEntryBlockHeight => lastUpdateBlockTime
    // will not see any issues with entering / exiting the protocol.
    uint32 lastUpdateBlockTime;
    // ----------------  Second Storage Slot ----------------------
    // Cash balances held by the vault account as a result of lending at zero interest or due
    // to deleveraging (liquidation). In the previous version of leveraged vaults, accounts would
    // simply lend at zero interest which was not a problem. However, with vaults being able to
    // discount fCash to present value, lending at zero percent interest may have an adverse effect
    // on the account's collateral position (i.e. lending at zero puts them further into danger).
    // Holding cash against debt will eliminate that risk, making vault liquidation more similar to
    // regular Notional liquidation.
    uint80 primaryCash;
    uint80 secondaryCashOne;
    uint80 secondaryCashTwo;
}

struct VaultAccount {
    // On the stack, account debts are always in underlying
    int256 accountDebtUnderlying;
    uint256 maturity;
    uint256 vaultShares;
    address account;
    // This cash balance is used just within a transaction to track deposits
    // and withdraws for an account. Must be zeroed by the time we store the account
    int256 tempCashBalance;
    uint256 lastUpdateBlockTime;
}

// Used to hold vault account liquidation factors in memory
struct VaultAccountHealthFactors {
    // Account's calculated collateral ratio
    int256 collateralRatio;
    // Total outstanding debt across all borrowed currencies in primary
    int256 totalDebtOutstandingInPrimary;
    // Total value of vault shares in underlying denomination
    int256 vaultShareValueUnderlying;
    // Debt outstanding in local currency denomination after present value and
    // account cash held netting applied. Can be positive if the account holds cash
    // in excess of debt.
    int256[3] netDebtOutstanding;
}

// PrimeCashInterestRateParameters take up 16 bytes, this takes up 32 bytes so we
// can expand another 16 bytes to increase the storage slots a bit....
struct PrimeCashFactorsStorage {
    // Storage slot 1 [Prime Supply Factors, 248 bytes]
    uint40 lastAccrueTime;
    uint88 totalPrimeSupply;
    uint88 lastTotalUnderlyingValue;
    // Overflows at 429% interest using RATE_PRECISION
    uint32 oracleSupplyRate;
    bool allowDebt;

    // Storage slot 2 [Prime Debt Factors, 256 bytes]
    uint88 totalPrimeDebt;
    // Each one of these values below is stored as a FloatingPoint32 value which
    // gives us approx 7 digits of precision for each value. Because these are used
    // to maintain supply and borrow caps, they are not required to be exact.
    uint32 maxUnderlyingSupply;
    uint128 _reserved;
    // Reserving the next 128 bytes for future use in case we decide to implement debt
    // caps on a currency. In that case, we will need to track the total fcash overall
    // and subtract the total debt held in vaults.
    // uint32 maxUnderlyingDebt;
    // uint32 totalfCashDebtOverall;
    // uint32 totalfCashDebtInVaults;
    // uint32 totalPrimeDebtInVaults;
    // 8 bytes left
    
    // Storage slot 3 [Prime Scalars, 240 bytes]
    // Scalars are stored in 18 decimal precision (i.e. double rate precision) and uint80
    // maxes out at approx 1,210,000e18
    // ln(1,210,000) = rate * years = 14
    // Approx 46 years at 30% interest
    // Approx 233 years at 6% interest
    uint80 underlyingScalar;
    uint80 supplyScalar;
    uint80 debtScalar;
    // The time window in 5 min increments that the rate oracle will be averaged over
    uint8 rateOracleTimeWindow5Min;
    // 8 bytes left
}

struct PrimeCashFactors {
    uint256 lastAccrueTime;
    uint256 totalPrimeSupply;
    uint256 totalPrimeDebt;
    uint256 oracleSupplyRate;
    uint256 lastTotalUnderlyingValue;
    uint256 underlyingScalar;
    uint256 supplyScalar;
    uint256 debtScalar;
    uint256 rateOracleTimeWindow;
}

struct PrimeRate {
    int256 supplyFactor;
    int256 debtFactor;
    uint256 oracleSupplyRate;
}

struct PrimeSettlementRateStorage {
    uint80 supplyScalar;
    uint80 debtScalar;
    uint80 underlyingScalar;
    bool isSet;
}

struct PrimeCashHoldingsOracle {
   IPrimeCashHoldingsOracle oracle; 
}

// Per currency rebalancing context
struct RebalancingContextStorage {
    // Holds the previous supply factor to calculate the oracle money market rate
    uint128 previousSupplyFactorAtRebalance;
    // Rebalancing has a cool down period that sets the time averaging of the oracle money market rate
    uint40 rebalancingCooldownInSeconds;
    uint40 lastRebalanceTimestampInSeconds;
    // 48 bytes left
}

struct TotalfCashDebtStorage {
    uint80 totalfCashDebt;
    // These two variables are used to track fCash lend at zero
    // edge conditions for leveraged vaults.
    uint80 fCashDebtHeldInSettlementReserve;
    uint80 primeCashHeldInSettlementReserve;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {AccountContext, LibStorage} from "../global/LibStorage.sol";
import {Constants} from "../global/Constants.sol";
import {PortfolioState, PortfolioAsset} from "../global/Types.sol";
import {DateTime} from "./markets/DateTime.sol";
import {PrimeCashExchangeRate} from "./pCash/PrimeCashExchangeRate.sol";
import {PortfolioHandler} from "./portfolio/PortfolioHandler.sol";
import {SafeInt256} from "../math/SafeInt256.sol";

library AccountContextHandler {
    using SafeInt256 for int256;
    using PortfolioHandler for PortfolioState;

    bytes18 private constant TURN_OFF_PORTFOLIO_FLAGS = 0x7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
    event AccountContextUpdate(address indexed account);

    /// @notice Returns the account context of a given account
    function getAccountContext(address account) internal view returns (AccountContext memory) {
        mapping(address => AccountContext) storage store = LibStorage.getAccountStorage();
        return store[account];
    }

    /// @notice Sets the account context of a given account
    function setAccountContext(AccountContext memory accountContext, address account) internal {
        mapping(address => AccountContext) storage store = LibStorage.getAccountStorage();
        store[account] = accountContext;
        emit AccountContextUpdate(account);
    }

    function isBitmapEnabled(AccountContext memory accountContext) internal pure returns (bool) {
        return accountContext.bitmapCurrencyId != 0;
    }

    /// @notice Enables a bitmap type portfolio for an account. A bitmap type portfolio allows
    /// an account to hold more fCash than a normal portfolio, except only in a single currency.
    /// Once enabled, it cannot be disabled or changed. An account can only enable a bitmap if
    /// it has no assets or debt so that we ensure no assets are left stranded.
    /// @param accountContext refers to the account where the bitmap will be enabled
    /// @param currencyId the id of the currency to enable
    /// @param blockTime the current block time to set the next settle time
    function enableBitmapForAccount(
        AccountContext memory accountContext,
        uint16 currencyId,
        uint256 blockTime
    ) internal pure {
        require(!isBitmapEnabled(accountContext), "Cannot change bitmap");
        require(0 < currencyId && currencyId <= Constants.MAX_CURRENCIES, "Invalid currency id");

        // Account cannot have assets or debts
        require(accountContext.assetArrayLength == 0, "Cannot have assets");
        require(accountContext.hasDebt == 0x00, "Cannot have debt");

        // Ensure that the active currency is set to false in the array so that there is no double
        // counting during FreeCollateral
        setActiveCurrency(accountContext, currencyId, false, Constants.ACTIVE_IN_BALANCES);
        accountContext.bitmapCurrencyId = currencyId;

        // Setting this is required to initialize the assets bitmap
        uint256 nextSettleTime = DateTime.getTimeUTC0(blockTime);
        require(nextSettleTime < type(uint40).max); // dev: blockTime overflow
        accountContext.nextSettleTime = uint40(nextSettleTime);
    }

    /// @notice Returns true if the context needs to settle
    function mustSettleAssets(AccountContext memory accountContext) internal view returns (bool) {
        uint256 blockTime = block.timestamp;

        if (isBitmapEnabled(accountContext)) {
            // nextSettleTime will be set to utc0 after settlement so we
            // settle if this is strictly less than utc0
            return accountContext.nextSettleTime < DateTime.getTimeUTC0(blockTime);
        } else {
            // 0 value occurs on an uninitialized account
            // Assets mature exactly on the blockTime (not one second past) so in this
            // case we settle on the block timestamp
            return 0 < accountContext.nextSettleTime && accountContext.nextSettleTime <= blockTime;
        }
    }

    /// @notice Checks if a currency id (uint16 max) is in the 9 slots in the account
    /// context active currencies list.
    /// @dev NOTE: this may be more efficient as a binary search since we know that the array
    /// is sorted
    function isActiveInBalances(AccountContext memory accountContext, uint256 currencyId)
        internal
        pure
        returns (bool)
    {
        require(currencyId != 0 && currencyId <= Constants.MAX_CURRENCIES); // dev: invalid currency id
        bytes18 currencies = accountContext.activeCurrencies;

        if (accountContext.bitmapCurrencyId == currencyId) return true;

        while (currencies != 0x00) {
            uint256 cid = uint16(bytes2(currencies) & Constants.UNMASK_FLAGS);
            if (cid == currencyId) {
                // Currency found, return if it is active in balances or not
                return bytes2(currencies) & Constants.ACTIVE_IN_BALANCES == Constants.ACTIVE_IN_BALANCES;
            }

            currencies = currencies << 16;
        }

        return false;
    }

    /// @notice Iterates through the active currency list and removes, inserts or does nothing
    /// to ensure that the active currency list is an ordered byte array of uint16 currency ids
    /// that refer to the currencies that an account is active in.
    ///
    /// This is called to ensure that currencies are active when the account has a non zero cash balance,
    /// a non zero nToken balance or a portfolio asset.
    function setActiveCurrency(
        AccountContext memory accountContext,
        uint256 currencyId,
        bool isActive,
        bytes2 flags
    ) internal pure {
        require(0 < currencyId && currencyId <= Constants.MAX_CURRENCIES); // dev: invalid currency id

        // If the bitmapped currency is already set then return here. Turning off the bitmap currency
        // id requires other logical handling so we will do it elsewhere.
        if (isActive && accountContext.bitmapCurrencyId == currencyId) return;

        bytes18 prefix;
        bytes18 suffix = accountContext.activeCurrencies;
        uint256 shifts;

        /// There are six possible outcomes from this search:
        /// 1. The currency id is in the list
        ///      - it must be set to active, do nothing
        ///      - it must be set to inactive, shift suffix and concatenate
        /// 2. The current id is greater than the one in the search:
        ///      - it must be set to active, append to prefix and then concatenate the suffix,
        ///        ensure that we do not lose the last 2 bytes if set.
        ///      - it must be set to inactive, it is not in the list, do nothing
        /// 3. Reached the end of the list:
        ///      - it must be set to active, check that the last two bytes are not set and then
        ///        append to the prefix
        ///      - it must be set to inactive, do nothing
        while (suffix != 0x00) {
            uint256 cid = uint256(uint16(bytes2(suffix) & Constants.UNMASK_FLAGS));
            // if matches and isActive then return, already in list
            if (cid == currencyId && isActive) {
                // set flag and return
                accountContext.activeCurrencies =
                    accountContext.activeCurrencies |
                    (bytes18(flags) >> (shifts * 16));
                return;
            }

            // if matches and not active then shift suffix to remove
            if (cid == currencyId && !isActive) {
                // turn off flag, if both flags are off then remove
                suffix = suffix & ~bytes18(flags);
                if (bytes2(suffix) & ~Constants.UNMASK_FLAGS == 0x0000) suffix = suffix << 16;
                accountContext.activeCurrencies = prefix | (suffix >> (shifts * 16));
                return;
            }

            // if greater than and isActive then insert into prefix
            if (cid > currencyId && isActive) {
                prefix = prefix | (bytes18(bytes2(uint16(currencyId)) | flags) >> (shifts * 16));
                // check that the total length is not greater than 9, meaning that the last
                // two bytes of the active currencies array should be zero
                require((accountContext.activeCurrencies << 128) == 0x00); // dev: AC: too many currencies

                // append the suffix
                accountContext.activeCurrencies = prefix | (suffix >> ((shifts + 1) * 16));
                return;
            }

            // if past the point of the currency id and not active, not in list
            if (cid > currencyId && !isActive) return;

            prefix = prefix | (bytes18(bytes2(suffix)) >> (shifts * 16));
            suffix = suffix << 16;
            shifts += 1;
        }

        // If reached this point and not active then return
        if (!isActive) return;

        // if end and isActive then insert into suffix, check max length
        require(shifts < 9); // dev: AC: too many currencies
        accountContext.activeCurrencies =
            prefix |
            (bytes18(bytes2(uint16(currencyId)) | flags) >> (shifts * 16));
    }

    function _clearPortfolioActiveFlags(bytes18 activeCurrencies) internal pure returns (bytes18) {
        bytes18 result;
        // This is required to clear the suffix as we append below
        bytes18 suffix = activeCurrencies & TURN_OFF_PORTFOLIO_FLAGS;
        uint256 shifts;

        // This loop will append all currencies that are active in balances into the result.
        while (suffix != 0x00) {
            if (bytes2(suffix) & Constants.ACTIVE_IN_BALANCES == Constants.ACTIVE_IN_BALANCES) {
                // If any flags are active, then append.
                result = result | (bytes18(bytes2(suffix)) >> shifts);
                shifts += 16;
            }
            suffix = suffix << 16;
        }

        return result;
    }

    function storeAssetsAndUpdateContextForSettlement(
        AccountContext memory accountContext,
        address account,
        PortfolioState memory portfolioState
    ) internal {
        // During settlement, we do not update fCash debt outstanding
        _storeAssetsAndUpdateContext(accountContext, account, portfolioState);
    }

    function storeAssetsAndUpdateContext(
        AccountContext memory accountContext,
        address account,
        PortfolioState memory portfolioState
    ) internal {
        (
            PortfolioAsset[] memory initialPortfolio,
            uint256[] memory initialIds
        ) = PortfolioHandler.getSortedPortfolioWithIds(
            account,
            accountContext.assetArrayLength
        );

        _storeAssetsAndUpdateContext(accountContext, account, portfolioState);

        (
            PortfolioAsset[] memory finalPortfolio,
            uint256[] memory finalIds
        ) = PortfolioHandler.getSortedPortfolioWithIds(
            account,
            accountContext.assetArrayLength
        );

        uint256 i = 0; // initial counter
        uint256 f = 0; // final counter
        while (i < initialPortfolio.length || f < finalPortfolio.length) {
            // Use uint256.max to signify that the end of the array has been reached. The max
            // id space is much less than this, so any elements in the other array will trigger
            // the proper if condition. Based on the while condition above, one of iID or fID
            // will be a valid portfolio id.
            uint256 iID = i < initialIds.length ? initialIds[i] : type(uint256).max;
            uint256 fID = f < finalIds.length ? finalIds[f] : type(uint256).max;

            // Inside this loop, it is guaranteed that there are no duplicate ids within
            // initialIds and finalIds. Therefore, we are looking for one of three possibilities:
            //  - iID == fID
            //  - iID is not in finalIds (deleted)
            //  - fID is not in initialIds (added)
            if (iID == fID) {
                // if id[i] == id[j] and both fCash, compare debt
                if (initialPortfolio[i].assetType == Constants.FCASH_ASSET_TYPE) {
                    PrimeCashExchangeRate.updateTotalfCashDebtOutstanding(
                        account,
                        initialPortfolio[i].currencyId,
                        initialPortfolio[i].maturity,
                        initialPortfolio[i].notional,
                        finalPortfolio[f].notional
                    );
                }
                i = i == initialIds.length ? i : i + 1;
                f = f == finalIds.length ? f : f + 1;
            } else if (iID < fID) {
                // Initial asset deleted
                if (initialPortfolio[i].assetType == Constants.FCASH_ASSET_TYPE) {
                    PrimeCashExchangeRate.updateTotalfCashDebtOutstanding(
                        account,
                        initialPortfolio[i].currencyId,
                        initialPortfolio[i].maturity,
                        initialPortfolio[i].notional,
                        0 // asset deleted, final notional is zero
                    );
                }
                i = i == initialIds.length ? i : i + 1;
            } else if (fID < iID) {
                // Final asset added
                if (finalPortfolio[f].assetType == Constants.FCASH_ASSET_TYPE) {
                    PrimeCashExchangeRate.updateTotalfCashDebtOutstanding(
                        account,
                        finalPortfolio[f].currencyId,
                        finalPortfolio[f].maturity,
                        0, // asset added, initial notional is zero
                        finalPortfolio[f].notional
                    );
                }
                f = f == finalIds.length ? f : f + 1;
            }
        }
    }

    /// @notice Stores a portfolio array and updates the account context information, this method should
    /// be used whenever updating a portfolio array except in the case of nTokens
    function _storeAssetsAndUpdateContext(
        AccountContext memory accountContext,
        address account,
        PortfolioState memory portfolioState
    ) private {
        // Each of these parameters is recalculated based on the entire array of assets in store assets,
        // regardless of whether or not they have been updated.
        (bool hasDebt, bytes32 portfolioCurrencies, uint8 assetArrayLength, uint40 nextSettleTime) =
            portfolioState.storeAssets(account);
        accountContext.nextSettleTime = nextSettleTime;
        require(mustSettleAssets(accountContext) == false); // dev: cannot store matured assets
        accountContext.assetArrayLength = assetArrayLength;
        require(assetArrayLength <= uint8(LibStorage.MAX_PORTFOLIO_ASSETS)); // dev: max assets allowed

        // Sets the hasDebt flag properly based on whether or not portfolio has asset debt, meaning
        // a negative fCash balance.
        if (hasDebt) {
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_ASSET_DEBT;
        } else {
            // Turns off the ASSET_DEBT flag
            accountContext.hasDebt = accountContext.hasDebt & ~Constants.HAS_ASSET_DEBT;
        }

        // Clear the active portfolio active flags and they will be recalculated in the next step
        accountContext.activeCurrencies = _clearPortfolioActiveFlags(accountContext.activeCurrencies);

        uint256 lastCurrency;
        while (portfolioCurrencies != 0) {
            // Portfolio currencies will not have flags, it is just an byte array of all the currencies found
            // in a portfolio. They are appended in a sorted order so we can compare to the previous currency
            // and only set it if they are different.
            uint256 currencyId = uint16(bytes2(portfolioCurrencies));
            if (currencyId != lastCurrency) {
                setActiveCurrency(accountContext, currencyId, true, Constants.ACTIVE_IN_PORTFOLIO);
            }
            lastCurrency = currencyId;

            portfolioCurrencies = portfolioCurrencies << 16;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    BalanceState,
    BalanceStorage,
    SettleAmount,
    TokenType,
    AccountContext,
    PrimeRate,
    Token
} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {FloatingPoint} from "../../math/FloatingPoint.sol";

import {Emitter} from "../Emitter.sol";
import {nTokenHandler} from "../nToken/nTokenHandler.sol";
import {AccountContextHandler} from "../AccountContextHandler.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {PrimeCashExchangeRate} from "../pCash/PrimeCashExchangeRate.sol";

import {TokenHandler} from "./TokenHandler.sol";
import {Incentives} from "./Incentives.sol";

library BalanceHandler {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;
    using TokenHandler for Token;
    using AccountContextHandler for AccountContext;
    using PrimeRateLib for PrimeRate;

    /// @notice Emitted when reserve balance is updated
    event ReserveBalanceUpdated(uint16 indexed currencyId, int256 newBalance);
    /// @notice Emitted when reserve balance is harvested
    event ExcessReserveBalanceHarvested(uint16 indexed currencyId, int256 harvestAmount);

    /// @notice Exists to maintain compatibility for asset token deposits that existed before
    /// prime cash. After prime cash, Notional will no longer list new asset cash tokens. Asset
    /// cash listed prior to the prime cash migration will be redeemed immediately to underlying
    /// and this method will return how much underlying that represents.
    function depositDeprecatedAssetToken(
        BalanceState memory balanceState,
        address account,
        int256 assetAmountExternal
    ) internal returns (int256 primeCashDeposited) {
        if (assetAmountExternal == 0) return 0;
        require(assetAmountExternal > 0); // dev: deposit asset token amount negative
        Token memory assetToken = TokenHandler.getDeprecatedAssetToken(balanceState.currencyId);
        require(assetToken.tokenAddress != address(0));

        // Aave tokens will not be listed prior to the prime cash migration, if NonMintable tokens
        // are minted then assetTokenTransferred is the underlying.
        if (
            assetToken.tokenType == TokenType.cToken ||
            assetToken.tokenType == TokenType.cETH
        ) {
            primeCashDeposited = assetToken.depositDeprecatedAssetToken(
                balanceState.currencyId,
                // Overflow checked above
                uint256(assetAmountExternal),
                account,
                balanceState.primeRate
            );
            balanceState.netCashChange = balanceState.netCashChange.add(primeCashDeposited);
        } else if (assetToken.tokenType == TokenType.NonMintable) {
            // In this case, no redemption is necessary and the non mintable token maps
            // 1-1 with the underlying token. Deprecated non-mintable tokens will never be ETH so
            // the returnExcessWrapped flag is set to false.
            primeCashDeposited = depositUnderlyingToken(balanceState, account, assetAmountExternal, false);
        } else {
            revert();
        }
    }

    /// @notice Marks some amount of underlying token to be transferred. Transfers will be
    /// finalized inside _finalizeTransfer unless forceTransfer is set to true
    function depositUnderlyingToken(
        BalanceState memory balanceState,
        address account,
        int256 underlyingAmountExternal,
        bool returnExcessWrapped
    ) internal returns (int256 primeCashDeposited) {
        if (underlyingAmountExternal == 0) return 0;
        require(underlyingAmountExternal > 0); // dev: deposit underlying token negative

        // Transfer the tokens and credit the balance state with the
        // amount of prime cash deposited.
        (/* actualTransfer */, primeCashDeposited) = TokenHandler.depositUnderlyingExternal(
            account,
            balanceState.currencyId,
            underlyingAmountExternal,
            balanceState.primeRate,
            returnExcessWrapped // if true, returns any excess ETH as WETH
        );
        balanceState.netCashChange = balanceState.netCashChange.add(primeCashDeposited);
    }

    /// @notice Finalize collateral liquidation, checkAllowPrimeBorrow is set to false to force
    /// a negative collateral cash balance if required.
    function finalizeCollateralLiquidation(
        BalanceState memory balanceState,
        address account,
        AccountContext memory accountContext
    ) internal {
        require(balanceState.primeCashWithdraw == 0);
        _finalize(balanceState, account, accountContext, false, false);
    }

    /// @notice Calls finalize without any withdraws. Allows the withdrawWrapped flag to be hardcoded to false.
    function finalizeNoWithdraw(
        BalanceState memory balanceState,
        address account,
        AccountContext memory accountContext
    ) internal {
        require(balanceState.primeCashWithdraw == 0);
        _finalize(balanceState, account, accountContext, false, true);
    }

    /// @notice Finalizes an account's balances with withdraws, returns the actual amount of underlying tokens transferred
    /// back to the account
    function finalizeWithWithdraw(
        BalanceState memory balanceState,
        address account,
        AccountContext memory accountContext,
        bool withdrawWrapped
    ) internal returns (int256 transferAmountExternal) {
        return _finalize(balanceState, account, accountContext, withdrawWrapped, true);
    }

    /// @notice Finalizes an account's balances, handling any transfer logic required
    /// @dev This method SHOULD NOT be used for nToken accounts, for that use setBalanceStorageForNToken
    /// as the nToken is limited in what types of balances it can hold.
    function  _finalize(
        BalanceState memory balanceState,
        address account,
        AccountContext memory accountContext,
        bool withdrawWrapped,
        bool checkAllowPrimeBorrow
    ) private returns (int256 transferAmountExternal) {
        bool mustUpdate;

        // Transfer amount is checked inside finalize transfers in case when converting to external we
        // round down to zero. This returns the actual net transfer in internal precision as well.
        transferAmountExternal = TokenHandler.withdrawPrimeCash(
            account,
            balanceState.currencyId,
            balanceState.primeCashWithdraw,
            balanceState.primeRate,
            withdrawWrapped // if true, withdraws ETH as WETH
        );

        // No changes to total cash after this point
        int256 totalCashChange = balanceState.netCashChange.add(balanceState.primeCashWithdraw);

        if (
            checkAllowPrimeBorrow &&
            totalCashChange < 0 &&
            balanceState.storedCashBalance.add(totalCashChange) < 0
        ) {
            // If the total cash change is negative and it causes the stored cash balance to become negative,
            // the account must allow prime debt. This is a safety check to ensure that accounts do not
            // accidentally borrow variable through a withdraw or a batch transaction.
            
            // Accounts can still incur negative cash during fCash settlement, that will bypass this check.
            
            // During liquidation, liquidated accounts never have negative total cash change figures except
            // in the case of negative local fCash liquidation. In that situation, setBalanceStorageForfCashLiquidation
            // will be called instead.

            // During liquidation, liquidators may have negative net cash change a token has transfer fees, however, in
            // LiquidationHelpers.finalizeLiquidatorLocal they are not allowed to go into debt.
            require(accountContext.allowPrimeBorrow, "No Prime Borrow");
        }


        if (totalCashChange != 0) {
            balanceState.storedCashBalance = balanceState.storedCashBalance.add(totalCashChange);
            mustUpdate = true;
        }

        if (balanceState.netNTokenTransfer != 0 || balanceState.netNTokenSupplyChange != 0) {
            // Final nToken balance is used to calculate the account incentive debt
            int256 finalNTokenBalance = balanceState.storedNTokenBalance
                .add(balanceState.netNTokenTransfer)
                .add(balanceState.netNTokenSupplyChange);
            // Ensure that nToken balances never become negative
            require(finalNTokenBalance >= 0, "Neg nToken");

            // overflow checked above
            Incentives.claimIncentives(balanceState, account, uint256(finalNTokenBalance));
            balanceState.storedNTokenBalance = finalNTokenBalance;
            mustUpdate = true;
        }

        if (mustUpdate) {
            _setBalanceStorage(
                account,
                balanceState.currencyId,
                balanceState.storedCashBalance,
                balanceState.storedNTokenBalance,
                balanceState.lastClaimTime,
                balanceState.accountIncentiveDebt,
                balanceState.primeRate
            );
        }

        accountContext.setActiveCurrency(
            balanceState.currencyId,
            // Set active currency to true if either balance is non-zero
            balanceState.storedCashBalance != 0 || balanceState.storedNTokenBalance != 0,
            Constants.ACTIVE_IN_BALANCES
        );

        if (balanceState.storedCashBalance < 0) {
            // NOTE: HAS_CASH_DEBT cannot be extinguished except by a free collateral check where all balances
            // are examined
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_CASH_DEBT;
        }
    }

    /**
     * @notice A special balance storage method for fCash liquidation to reduce the bytecode size.
     */
    function setBalanceStorageForfCashLiquidation(
        address account,
        AccountContext memory accountContext,
        uint16 currencyId,
        int256 netPrimeCashChange,
        PrimeRate memory primeRate
    ) internal {
        (int256 cashBalance, int256 nTokenBalance, uint256 lastClaimTime, uint256 accountIncentiveDebt) =
            getBalanceStorage(account, currencyId, primeRate);

        int256 newCashBalance = cashBalance.add(netPrimeCashChange);
        // If a cash balance is negative already we cannot put an account further into debt. In this case
        // the netCashChange must be positive so that it is coming out of debt.
        if (newCashBalance < 0) {
            require(netPrimeCashChange > 0, "Neg Cash");
            // NOTE: HAS_CASH_DEBT cannot be extinguished except by a free collateral check
            // where all balances are examined. In this case the has cash debt flag should
            // already be set (cash balances cannot get more negative) but we do it again
            // here just to be safe.
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_CASH_DEBT;
        }

        bool isActive = newCashBalance != 0 || nTokenBalance != 0;
        accountContext.setActiveCurrency(currencyId, isActive, Constants.ACTIVE_IN_BALANCES);

        _setBalanceStorage(
            account,
            currencyId,
            newCashBalance,
            nTokenBalance,
            lastClaimTime,
            accountIncentiveDebt,
            primeRate
        );
    }

    /// @notice Helper method for settling the output of the SettleAssets method
    function finalizeSettleAmounts(
        address account,
        AccountContext memory accountContext,
        SettleAmount[] memory settleAmounts
    ) internal {
        // Mapping from account to its various currency stores
        mapping(uint256 => BalanceStorage) storage store = LibStorage.getBalanceStorage()[account];

        for (uint256 i = 0; i < settleAmounts.length; i++) {
            SettleAmount memory amt = settleAmounts[i];
            if (amt.positiveSettledCash == 0 && amt.negativeSettledCash == 0) continue;

            PrimeRate memory pr = settleAmounts[i].presentPrimeRate;
            BalanceStorage storage balanceStorage = store[amt.currencyId];

            int256 previousCashBalance = pr.convertFromStorage(balanceStorage.cashBalance);
            int256 nTokenBalance = balanceStorage.nTokenBalance;

            int256 newStoredCashBalance = pr.convertToStorageInSettlement(
                account,
                amt.currencyId,
                previousCashBalance,
                amt.positiveSettledCash,
                amt.negativeSettledCash
            );
            balanceStorage.cashBalance = newStoredCashBalance.toInt88();

            accountContext.setActiveCurrency(
                amt.currencyId,
                newStoredCashBalance != 0 || nTokenBalance != 0,
                Constants.ACTIVE_IN_BALANCES
            );

            if (newStoredCashBalance < 0) {
                accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_CASH_DEBT;
            }
        }
    }

    /// @notice Special method for setting balance storage for nToken
    function setBalanceStorageForNToken(
        address nTokenAddress,
        uint16 currencyId,
        int256 cashBalance
    ) internal {
        _setPositiveCashBalance(nTokenAddress, currencyId, cashBalance);
    }

    /// @notice Asses a fee or a refund to the nToken for leveraged vaults
    function incrementVaultFeeToNToken(uint16 currencyId, int256 fee) internal {
        require(fee >= 0); // dev: invalid fee
        address nTokenAddress = nTokenHandler.nTokenAddress(currencyId);
        int256 cashBalance = getPositiveCashBalance(nTokenAddress, currencyId);
        cashBalance = cashBalance.add(fee);
        _setPositiveCashBalance(nTokenAddress, currencyId, cashBalance);
    }

    /// @notice increments fees to the reserve
    function incrementFeeToReserve(uint16 currencyId, int256 fee) internal {
        require(fee >= 0); // dev: invalid fee
        // prettier-ignore
        int256 totalReserve = getPositiveCashBalance(Constants.FEE_RESERVE, currencyId);
        totalReserve = totalReserve.add(fee);
        _setPositiveCashBalance(Constants.FEE_RESERVE, currencyId, totalReserve);
    }

    /// @notice harvests excess reserve balance
    function harvestExcessReserveBalance(uint16 currencyId, int256 reserve, int256 assetInternalRedeemAmount) internal {
        // parameters are validated by the caller
        reserve = reserve.subNoNeg(assetInternalRedeemAmount);
        _setPositiveCashBalance(Constants.FEE_RESERVE, currencyId, reserve);
        // Transfer event is emitted in Treasury Action
        emit ExcessReserveBalanceHarvested(currencyId, assetInternalRedeemAmount);
    }

    /// @notice sets the reserve balance, see TreasuryAction.setReserveCashBalance
    function setReserveCashBalance(uint16 currencyId, int256 newBalance) internal {
        require(newBalance >= 0); // dev: invalid balance
        int256 previousBalance = getPositiveCashBalance(Constants.FEE_RESERVE, currencyId);
        _setPositiveCashBalance(Constants.FEE_RESERVE, currencyId, newBalance);
        Emitter.emitMintOrBurnPrimeCash(Constants.FEE_RESERVE, currencyId, newBalance.sub(previousBalance));
    }

    function getPositiveCashBalance(
        address account,
        uint16 currencyId
    ) internal view returns (int256 cashBalance) {
        mapping(address => mapping(uint256 => BalanceStorage)) storage store = LibStorage.getBalanceStorage();
        BalanceStorage storage balanceStorage = store[account][currencyId];
        cashBalance = balanceStorage.cashBalance;
        // Positive cash balances do not require prime rate conversion
        require(cashBalance >= 0);
    }

    /// @notice Sets cash balances for special system accounts that can only ever have positive
    /// cash balances (and nothing else). Because positive prime cash balances do not require any
    /// adjustments this does not require a PrimeRate object
    function _setPositiveCashBalance(address account, uint16 currencyId, int256 newCashBalance) internal {
        require(newCashBalance >= 0); // dev: invalid balance
        mapping(address => mapping(uint256 => BalanceStorage)) storage store = LibStorage.getBalanceStorage();
        BalanceStorage storage balanceStorage = store[account][currencyId];
        balanceStorage.cashBalance = newCashBalance.toInt88();
    }

    /// @notice Sets internal balance storage.
    function _setBalanceStorage(
        address account,
        uint16 currencyId,
        int256 cashBalance,
        int256 nTokenBalance,
        uint256 lastClaimTime,
        uint256 accountIncentiveDebt,
        PrimeRate memory pr
    ) internal {
        mapping(address => mapping(uint256 => BalanceStorage)) storage store = LibStorage.getBalanceStorage();
        BalanceStorage storage balanceStorage = store[account][currencyId];

        if (lastClaimTime == 0) {
            // In this case the account has migrated and we set the accountIncentiveDebt
            // The maximum NOTE supply is 100_000_000e8 (1e16) which is less than 2^56 (7.2e16) so we should never
            // encounter an overflow for accountIncentiveDebt
            require(accountIncentiveDebt <= type(uint56).max); // dev: account incentive debt overflow
            balanceStorage.accountIncentiveDebt = uint56(accountIncentiveDebt);
        } else {
            // In this case the last claim time has not changed and we do not update the last integral supply
            // (stored in the accountIncentiveDebt position)
            require(lastClaimTime == balanceStorage.lastClaimTime);
        }

        balanceStorage.lastClaimTime = lastClaimTime.toUint32();
        balanceStorage.nTokenBalance = nTokenBalance.toUint().toUint80();

        balanceStorage.cashBalance = pr.convertToStorageNonSettlementNonVault(
            account,
            currencyId,
            balanceStorage.cashBalance, // previous stored value
            cashBalance // signed cash balance
        ).toInt88();
    }

    /// @notice Gets internal balance storage, nTokens are stored alongside cash balances
    function getBalanceStorage(
        address account,
        uint16 currencyId,
        PrimeRate memory pr
    ) internal view returns (
        int256 cashBalance,
        int256 nTokenBalance,
        uint256 lastClaimTime,
        uint256 accountIncentiveDebt
    ) {
        mapping(address => mapping(uint256 => BalanceStorage)) storage store = LibStorage.getBalanceStorage();
        BalanceStorage storage balanceStorage = store[account][currencyId];

        nTokenBalance = balanceStorage.nTokenBalance;
        lastClaimTime = balanceStorage.lastClaimTime;
        if (lastClaimTime > 0) {
            // NOTE: this is only necessary to support the deprecated integral supply values, which are stored
            // in the accountIncentiveDebt slot
            accountIncentiveDebt = FloatingPoint.unpackFromBits(balanceStorage.accountIncentiveDebt);
        } else {
            accountIncentiveDebt = balanceStorage.accountIncentiveDebt;
        }

        cashBalance = pr.convertFromStorage(balanceStorage.cashBalance);
    }
        
    /// @notice Loads a balance state memory object
    /// @dev Balance state objects occupy a lot of memory slots, so this method allows
    /// us to reuse them if possible
    function _loadBalanceState(
        BalanceState memory balanceState,
        address account,
        uint16 currencyId,
        AccountContext memory accountContext
    ) private view {
        require(0 < currencyId && currencyId <= Constants.MAX_CURRENCIES); // dev: invalid currency id
        balanceState.currencyId = currencyId;

        if (accountContext.isActiveInBalances(currencyId)) {
            (
                balanceState.storedCashBalance,
                balanceState.storedNTokenBalance,
                balanceState.lastClaimTime,
                balanceState.accountIncentiveDebt
            ) = getBalanceStorage(account, currencyId, balanceState.primeRate);
        } else {
            balanceState.storedCashBalance = 0;
            balanceState.storedNTokenBalance = 0;
            balanceState.lastClaimTime = 0;
            balanceState.accountIncentiveDebt = 0;
        }

        balanceState.netCashChange = 0;
        balanceState.primeCashWithdraw = 0;
        balanceState.netNTokenTransfer = 0;
        balanceState.netNTokenSupplyChange = 0;
    }

    /// @notice Used when manually claiming incentives in nTokenAction. Also sets the balance state
    /// to storage to update the accountIncentiveDebt. lastClaimTime will be set to zero as accounts
    /// are migrated to the new incentive calculation
    function claimIncentivesManual(BalanceState memory balanceState, address account)
        internal
        returns (uint256 incentivesClaimed)
    {
        incentivesClaimed = Incentives.claimIncentives(
            balanceState,
            account,
            balanceState.storedNTokenBalance.toUint()
        );

        _setBalanceStorage(
            account,
            balanceState.currencyId,
            balanceState.storedCashBalance,
            balanceState.storedNTokenBalance,
            balanceState.lastClaimTime,
            balanceState.accountIncentiveDebt,
            balanceState.primeRate
        );
    }

    function loadBalanceState(
        BalanceState memory balanceState,
        address account,
        uint16 currencyId,
        AccountContext memory accountContext
    ) internal {
        balanceState.primeRate = PrimeRateLib.buildPrimeRateStateful(currencyId);
        _loadBalanceState(balanceState, account, currencyId, accountContext);
    }

    function loadBalanceStateView(
        BalanceState memory balanceState,
        address account,
        uint16 currencyId,
        AccountContext memory accountContext
    ) internal view {
        (balanceState.primeRate, /* */) = PrimeCashExchangeRate.getPrimeCashRateView(currencyId, block.timestamp);
        _loadBalanceState(balanceState, account, currencyId, accountContext);
    }

    function getBalanceStorageView(
        address account,
        uint16 currencyId,
        uint256 blockTime
    ) internal view returns (
        int256 cashBalance,
        int256 nTokenBalance,
        uint256 lastClaimTime,
        uint256 accountIncentiveDebt
    ) {
        (PrimeRate memory pr, /* */) = PrimeCashExchangeRate.getPrimeCashRateView(currencyId, blockTime);
        return getBalanceStorage(account, currencyId, pr);
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    BalanceState
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";

import {TokenHandler} from "./TokenHandler.sol";
import {nTokenHandler} from "../nToken/nTokenHandler.sol";
import {nTokenSupply} from "../nToken/nTokenSupply.sol";

import {MigrateIncentives} from "../../external/MigrateIncentives.sol";
import {IRewarder} from "../../../interfaces/notional/IRewarder.sol";

library Incentives {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;

    /// @notice Calculates the total incentives to claim including those claimed under the previous
    /// less accurate calculation. Once an account is migrated it will only claim incentives under
    /// the more accurate regime
    function calculateIncentivesToClaim(
        BalanceState memory balanceState,
        address tokenAddress,
        uint256 accumulatedNOTEPerNToken,
        uint256 finalNTokenBalance
    ) internal view returns (uint256 incentivesToClaim) {
        if (balanceState.lastClaimTime > 0) {
            // If lastClaimTime is set then the account had incentives under the
            // previous regime. Will calculate the final amount of incentives to claim here
            // under the previous regime.
            incentivesToClaim = MigrateIncentives.migrateAccountFromPreviousCalculation(
                tokenAddress,
                balanceState.storedNTokenBalance.toUint(),
                balanceState.lastClaimTime,
                // In this case the accountIncentiveDebt is stored as lastClaimIntegralSupply under
                // the old calculation
                balanceState.accountIncentiveDebt
            );

            // This marks the account as migrated and lastClaimTime will no longer be used
            balanceState.lastClaimTime = 0;
            // This value will be set immediately after this, set this to zero so that the calculation
            // establishes a new baseline.
            balanceState.accountIncentiveDebt = 0;
        }

        // If an account was migrated then they have no accountIncentivesDebt and should accumulate
        // incentives based on their share since the new regime calculation started.
        // If an account is just initiating their nToken balance then storedNTokenBalance will be zero
        // and they will have no incentives to claim.
        // This calculation uses storedNTokenBalance which is the balance of the account up until this point,
        // this is important to ensure that the account does not claim for nTokens that they will mint or
        // redeem on a going forward basis.

        // The calculation below has the following precision:
        //   storedNTokenBalance (INTERNAL_TOKEN_PRECISION)
        //   MUL accumulatedNOTEPerNToken (INCENTIVE_ACCUMULATION_PRECISION)
        //   DIV INCENTIVE_ACCUMULATION_PRECISION
        //  = INTERNAL_TOKEN_PRECISION - (accountIncentivesDebt) INTERNAL_TOKEN_PRECISION
        incentivesToClaim = incentivesToClaim.add(
            balanceState.storedNTokenBalance.toUint()
                .mul(accumulatedNOTEPerNToken)
                .div(Constants.INCENTIVE_ACCUMULATION_PRECISION)
                .sub(balanceState.accountIncentiveDebt)
        );

        // Update accountIncentivesDebt denominated in INTERNAL_TOKEN_PRECISION which marks the portion
        // of the accumulatedNOTE that the account no longer has a claim over. Use the finalNTokenBalance
        // here instead of storedNTokenBalance to mark the overall incentives claim that the account
        // does not have a claim over. We do not aggregate this value with the previous accountIncentiveDebt
        // because accumulatedNOTEPerNToken is already an aggregated value.

        // The calculation below has the following precision:
        //   finalNTokenBalance (INTERNAL_TOKEN_PRECISION)
        //   MUL accumulatedNOTEPerNToken (INCENTIVE_ACCUMULATION_PRECISION)
        //   DIV INCENTIVE_ACCUMULATION_PRECISION
        //   = INTERNAL_TOKEN_PRECISION
        balanceState.accountIncentiveDebt = finalNTokenBalance
            .mul(accumulatedNOTEPerNToken)
            .div(Constants.INCENTIVE_ACCUMULATION_PRECISION);
    }

    /// @notice Incentives must be claimed every time nToken balance changes.
    /// @dev BalanceState.accountIncentiveDebt is updated in place here
    function claimIncentives(
        BalanceState memory balanceState,
        address account,
        uint256 finalNTokenBalance
    ) internal returns (uint256 incentivesToClaim) {
        uint256 blockTime = block.timestamp;
        address tokenAddress = nTokenHandler.nTokenAddress(balanceState.currencyId);
        // This will updated the nToken storage and return what the accumulatedNOTEPerNToken
        // is up until this current block time in 1e18 precision
        uint256 accumulatedNOTEPerNToken = nTokenSupply.changeNTokenSupply(
            tokenAddress,
            balanceState.netNTokenSupplyChange,
            blockTime
        );

        incentivesToClaim = calculateIncentivesToClaim(
            balanceState,
            tokenAddress,
            accumulatedNOTEPerNToken,
            finalNTokenBalance
        );

        // If a secondary incentive rewarder is set, then call it
        IRewarder rewarder = nTokenHandler.getSecondaryRewarder(tokenAddress);
        if (address(rewarder) != address(0)) {
            rewarder.claimRewards(
                account,
                balanceState.currencyId,
                // When this method is called from finalize, the storedNTokenBalance has not
                // been updated to finalNTokenBalance yet so this is the balance before the change.
                balanceState.storedNTokenBalance.toUint(),
                finalNTokenBalance,
                // When the rewarder is called, totalSupply has been updated already so may need to
                // adjust its calculation using the net supply change figure here. Supply change
                // may be zero when nTokens are transferred.
                balanceState.netNTokenSupplyChange,
                incentivesToClaim
            );
        }

        if (incentivesToClaim > 0) TokenHandler.transferIncentive(account, incentivesToClaim);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {Token} from "../../../global/Types.sol";
import {SafeUint256} from "../../../math/SafeUint256.sol";

import {GenericToken} from "./GenericToken.sol";

import {CErc20Interface} from "../../../../interfaces/compound/CErc20Interface.sol";
import {CEtherInterface} from "../../../../interfaces/compound/CEtherInterface.sol";
import {IERC20} from "../../../../interfaces/IERC20.sol";

library CompoundHandler {
    using SafeUint256 for uint256;

    // Return code for cTokens that represents no error
    uint256 internal constant COMPOUND_RETURN_CODE_NO_ERROR = 0;

    function redeemCETH(
        Token memory assetToken,
        uint256 assetAmountExternal
    ) internal returns (uint256 underlyingAmountExternal) {
        uint256 startingBalance = address(this).balance;

        uint256 success = CErc20Interface(assetToken.tokenAddress).redeem(assetAmountExternal);
        require(success == COMPOUND_RETURN_CODE_NO_ERROR, "Redeem");

        uint256 endingBalance = address(this).balance;

        underlyingAmountExternal = endingBalance.sub(startingBalance);
    }

    function redeem(
        Token memory assetToken,
        Token memory underlyingToken,
        uint256 assetAmountExternal
    ) internal returns (uint256 underlyingAmountExternal) {
        uint256 startingBalance = IERC20(underlyingToken.tokenAddress).balanceOf(address(this));

        uint256 success = CErc20Interface(assetToken.tokenAddress).redeem(assetAmountExternal);
        require(success == COMPOUND_RETURN_CODE_NO_ERROR, "Redeem");

        uint256 endingBalance = IERC20(underlyingToken.tokenAddress).balanceOf(address(this));

        underlyingAmountExternal = endingBalance.sub(startingBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import {Deployments} from "../../../global/Deployments.sol";
import {IEIP20NonStandard} from "../../../../interfaces/IEIP20NonStandard.sol";
import {SafeUint256} from "../../../math/SafeUint256.sol";

library GenericToken {
    using SafeUint256 for uint256;

    event LowLevelCallFailed(address indexed target, uint256 msgValue, bytes callData, string revertMessage);

    function transferNativeTokenOut(
        address account,
        uint256 amount,
        bool withdrawWrapped
    ) internal {
        // Native token withdraws are processed using .transfer() which is may not work
        // for certain contracts that do not implement receive() with minimal gas requirements.
        // Prior to the prime cash upgrade, these contracts could withdraw cETH, however, post
        // upgrade they no longer have this option. For these contracts, wrap the Native token
        // (i.e. WETH) and transfer that as an ERC20 instead.
        if (withdrawWrapped) {
            Deployments.WETH.deposit{value: amount}();
            safeTransferOut(address(Deployments.WETH), account, amount);
        } else {
            // TODO: consider using .call with a manual amount of gas forwarding
            payable(account).transfer(amount);
        }
    }

    function safeTransferOut(
        address token,
        address account,
        uint256 amount
    ) internal {
        IEIP20NonStandard(token).transfer(account, amount);
        checkReturnCode();
    }

    function safeTransferIn(
        address token,
        address account,
        uint256 amount
    ) internal returns (uint256) {
        uint256 startingBalance = IEIP20NonStandard(token).balanceOf(address(this));

        IEIP20NonStandard(token).transferFrom(account, address(this), amount);
        checkReturnCode();

        uint256 endingBalance = IEIP20NonStandard(token).balanceOf(address(this));

        return endingBalance.sub(startingBalance);
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        IEIP20NonStandard(token).transferFrom(from, to, amount);
        checkReturnCode();
    }

    function executeLowLevelCall(
        address target,
        uint256 msgValue,
        bytes memory callData,
        bool allowFailure
    ) internal returns (bool) {
        (bool status, bytes memory returnData) = target.call{value: msgValue}(callData);
        if (!allowFailure) {
            require(status, checkRevertMessage(returnData));
        } else {
            emit LowLevelCallFailed(target, msgValue, callData, checkRevertMessage(returnData));
        }
        return status;
    }

    function checkRevertMessage(bytes memory returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (returnData.length < 68) return "Silent Revert";

        assembly {
            // Slice the sighash.
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string)); // All that remains is the revert string
    }

    function checkReturnCode() internal pure {
        bool success;
        uint256[1] memory result;
        assembly {
            switch returndatasize()
                case 0 {
                    // This is a non-standard ERC-20
                    success := 1 // set success to true
                }
                case 32 {
                    // This is a compliant ERC-20
                    returndatacopy(result, 0, 32)
                    success := mload(result) // Set `success = returndata` of external call
                }
                default {
                    // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }

        require(success, "ERC20");
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    Token,
    TokenType,
    TokenStorage,
    PrimeRate
} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {Constants} from "../../global/Constants.sol";
import {Deployments} from "../../global/Deployments.sol";

import {Emitter} from "../Emitter.sol";
import {PrimeCashExchangeRate} from "../pCash/PrimeCashExchangeRate.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";

import {CompoundHandler} from "./protocols/CompoundHandler.sol";
import {GenericToken} from "./protocols/GenericToken.sol";

import {IERC20} from "../../../interfaces/IERC20.sol";
import {IPrimeCashHoldingsOracle, RedeemData} from "../../../interfaces/notional/IPrimeCashHoldingsOracle.sol";

/// @notice Handles all external token transfers and events
library TokenHandler {
    using SafeInt256 for int256;
    using SafeUint256 for uint256;
    using PrimeRateLib for PrimeRate;

    function getDeprecatedAssetToken(uint256 currencyId) internal view returns (Token memory) {
        return _getToken(currencyId, false);
    }

    function getUnderlyingToken(uint256 currencyId) internal view returns (Token memory) {
        return _getToken(currencyId, true);
    }

    /// @notice Gets token data for a particular currency id, if underlying is set to true then returns
    /// the underlying token. (These may not always exist)
    function _getToken(uint256 currencyId, bool underlying) private view returns (Token memory) {
        mapping(uint256 => mapping(bool => TokenStorage)) storage store = LibStorage.getTokenStorage();
        TokenStorage storage tokenStorage = store[currencyId][underlying];

        return
            Token({
                tokenAddress: tokenStorage.tokenAddress,
                hasTransferFee: tokenStorage.hasTransferFee,
                // No overflow, restricted on storage
                decimals: int256(10**tokenStorage.decimalPlaces),
                tokenType: tokenStorage.tokenType,
                deprecated_maxCollateralBalance: 0
            });
    }

    /// @notice Sets a token for a currency id. After the prime cash migration, only
    /// underlying tokens may be set by this method.
    function setToken(uint256 currencyId, TokenStorage memory tokenStorage) internal {
        mapping(uint256 => mapping(bool => TokenStorage)) storage store = LibStorage.getTokenStorage();

        if (tokenStorage.tokenType == TokenType.Ether && currencyId == Constants.ETH_CURRENCY_ID) {
            // Hardcoded parameters for ETH just to make sure we don't get it wrong.
            TokenStorage storage ts = store[currencyId][true];
            ts.tokenAddress = address(0);
            ts.hasTransferFee = false;
            ts.tokenType = TokenType.Ether;
            ts.decimalPlaces = Constants.ETH_DECIMAL_PLACES;

            return;
        }

        // Check token address
        require(tokenStorage.tokenAddress != address(0), "TH: address is zero");
        // Once a token is set we cannot override it. In the case that we do need to do change a token address
        // then we should explicitly upgrade this method to allow for a token to be changed.
        Token memory token = _getToken(currencyId, true);
        require(
            token.tokenAddress == tokenStorage.tokenAddress || token.tokenAddress == address(0),
            "TH: token cannot be reset"
        );

        require(0 < tokenStorage.decimalPlaces 
            && tokenStorage.decimalPlaces <= Constants.MAX_DECIMAL_PLACES, "TH: invalid decimals");

        // Validate token type
        require(tokenStorage.tokenType != TokenType.Ether); // dev: ether can only be set once
        // Only underlying tokens allowed after migration
        require(tokenStorage.tokenType == TokenType.UnderlyingToken); // dev: only underlying token

        // Underlying is always true.
        store[currencyId][true] = tokenStorage;
    }

    /**
     * @notice Transfers a deprecated asset token into Notional and redeems it for underlying,
     * updates prime cash supply and returns the total prime cash to add to the account.
     * @param assetToken asset token to redeem
     * @param currencyId the currency id of the token
     * @param assetAmountExternal the amount to transfer in asset token denomination and external precision
     * @param primeRate the prime rate for the given currency
     * @param account the address of the account to transfer from
     * @return primeCashDeposited the amount of prime cash to mint back to the account
     */
    function depositDeprecatedAssetToken(
        Token memory assetToken,
        uint16 currencyId,
        uint256 assetAmountExternal,
        address account,
        PrimeRate memory primeRate
    ) internal returns (int256 primeCashDeposited) {
        // Transfer the asset token into the contract
        assetAmountExternal = GenericToken.safeTransferIn(
            assetToken.tokenAddress, account, assetAmountExternal
        );

        Token memory underlyingToken = getUnderlyingToken(currencyId);
        int256 underlyingExternalAmount;
        // Only cTokens will be listed at the time of the migration. Redeem
        // those cTokens to underlying (to be held by the Notional contract)
        // and then run the post transfer update
        if (assetToken.tokenType == TokenType.cETH) {
            underlyingExternalAmount = CompoundHandler.redeemCETH(
                assetToken, assetAmountExternal
            ).toInt();
        } else if (assetToken.tokenType == TokenType.cToken) {
            underlyingExternalAmount = CompoundHandler.redeem(
                assetToken, underlyingToken, assetAmountExternal
            ).toInt();
        } else {
            // No other asset token variants can be called here.
            revert();
        }
        
        primeCashDeposited = _postTransferPrimeCashUpdate(
            account, currencyId, underlyingExternalAmount, underlyingToken, primeRate
        );
    }

    /// @notice Deposits an exact amount of underlying tokens to mint the specified amount of prime cash.
    /// @param account account to transfer tokens from
    /// @param currencyId the associated currency id
    /// @param primeCashToMint the amount of prime cash to mint
    /// @param primeRate the current accrued prime rate
    /// @param returnNativeTokenWrapped if true, return excess msg.value ETH payments as WETH
    /// @return actualTransferExternal the actual amount of tokens transferred in external precision
    function depositExactToMintPrimeCash(
        address account,
        uint16 currencyId,
        int256 primeCashToMint,
        PrimeRate memory primeRate,
        bool returnNativeTokenWrapped
    ) internal returns (int256 actualTransferExternal) {
        if (primeCashToMint == 0) return 0;
        require(primeCashToMint > 0);
        Token memory underlying = getUnderlyingToken(currencyId);
        int256 netTransferExternal = convertToUnderlyingExternalWithAdjustment(
            underlying, 
            primeRate.convertToUnderlying(primeCashToMint) 
        );

        int256 netPrimeSupplyChange;
        (actualTransferExternal, netPrimeSupplyChange) = depositUnderlyingExternal(
            account, currencyId, netTransferExternal, primeRate, returnNativeTokenWrapped
        );

        // Ensures that the prime cash minted is positive and always greater than
        // the amount of prime cash that will be credited to the depositor. Any dust
        // amounts here will accrue to the protocol. primeCashToMint is asserted to be
        // positive so if netPrimeSupplyChange is negative (which it should never be),
        // then this will revert as well.
        int256 diff = netPrimeSupplyChange - primeCashToMint;
        require(0 <= diff); // dev: diff above zero
    }

    /// @notice Deposits an amount of underlying tokens to mint prime cash
    /// @param account account to transfer tokens from
    /// @param currencyId the associated currency id
    /// @param _underlyingExternalDeposit the amount of underlying tokens to deposit
    /// @param primeRate the current accrued prime rate
    /// @param returnNativeTokenWrapped if true, return excess msg.value ETH payments as WETH
    /// @return actualTransferExternal the actual amount of tokens transferred in external precision
    /// @return netPrimeSupplyChange the amount of prime supply created
    function depositUnderlyingExternal(
        address account,
        uint16 currencyId,
        int256 _underlyingExternalDeposit,
        PrimeRate memory primeRate,
        bool returnNativeTokenWrapped
    ) internal returns (int256 actualTransferExternal, int256 netPrimeSupplyChange) {
        uint256 underlyingExternalDeposit = _underlyingExternalDeposit.toUint();
        if (underlyingExternalDeposit == 0) return (0, 0);

        Token memory underlying = getUnderlyingToken(currencyId);
        if (underlying.tokenType == TokenType.Ether) {
            // Underflow checked above
            if (underlyingExternalDeposit < msg.value) {
                // Transfer any excess ETH back to the account
                GenericToken.transferNativeTokenOut(
                    account, msg.value - underlyingExternalDeposit, returnNativeTokenWrapped
                );
            } else {
                require(underlyingExternalDeposit == msg.value, "ETH Balance");
            }

            actualTransferExternal = _underlyingExternalDeposit;
        } else {
            // In the case of deposits, we use a balance before and after check
            // to ensure that we record the proper balance change.
            actualTransferExternal = GenericToken.safeTransferIn(
                underlying.tokenAddress, account, underlyingExternalDeposit
            ).toInt();
        }

        netPrimeSupplyChange = _postTransferPrimeCashUpdate(
            account, currencyId, actualTransferExternal, underlying, primeRate
        );
    }

    /// @notice Withdraws an amount of prime cash and returns it to the account as underlying tokens
    /// @param account account to transfer tokens to
    /// @param currencyId the associated currency id
    /// @param primeCashToWithdraw the amount of prime cash to burn
    /// @param primeRate the current accrued prime rate
    /// @param withdrawWrappedNativeToken if true, return ETH as WETH
    /// @return netTransferExternal the amount of underlying tokens withdrawn in native precision, this is
    /// negative to signify that tokens have left the protocol
    function withdrawPrimeCash(
        address account,
        uint16 currencyId,
        int256 primeCashToWithdraw,
        PrimeRate memory primeRate,
        bool withdrawWrappedNativeToken
    ) internal returns (int256 netTransferExternal) {
        if (primeCashToWithdraw == 0) return 0;
        require(primeCashToWithdraw < 0);

        Token memory underlying = getUnderlyingToken(currencyId);
        netTransferExternal = convertToExternal(
            underlying, 
            primeRate.convertToUnderlying(primeCashToWithdraw) 
        );

        // Overflow not possible due to int256
        uint256 withdrawAmount = uint256(netTransferExternal.neg());
        _redeemMoneyMarketIfRequired(currencyId, underlying, withdrawAmount);

        if (underlying.tokenType == TokenType.Ether) {
            GenericToken.transferNativeTokenOut(account, withdrawAmount, withdrawWrappedNativeToken);
        } else {
            GenericToken.safeTransferOut(underlying.tokenAddress, account, withdrawAmount);
        }

        _postTransferPrimeCashUpdate(account, currencyId, netTransferExternal, underlying, primeRate);
    }

    /// @notice Prime cash holdings may be in underlying tokens or they may be held in other money market
    /// protocols like Compound, Aave or Euler. If there is insufficient underlying tokens to withdraw on
    /// the contract, this method will redeem money market tokens in order to gain sufficient underlying
    /// to withdraw from the contract.
    /// @param currencyId associated currency id
    /// @param underlying underlying token information
    /// @param withdrawAmountExternal amount of underlying to withdraw in external token precision
    function _redeemMoneyMarketIfRequired(
        uint16 currencyId,
        Token memory underlying,
        uint256 withdrawAmountExternal
    ) private {
        // If there is sufficient balance of the underlying to withdraw from the contract
        // immediately, just return.
        mapping(address => uint256) storage store = LibStorage.getStoredTokenBalances();
        uint256 currentBalance = store[underlying.tokenAddress];
        if (withdrawAmountExternal <= currentBalance) return;

        IPrimeCashHoldingsOracle oracle = PrimeCashExchangeRate.getPrimeCashHoldingsOracle(currencyId);
        // Redemption data returns an array of contract calls to make from the Notional proxy (which
        // is holding all of the money market tokens).
        (RedeemData[] memory data) = oracle.getRedemptionCalldata(withdrawAmountExternal - currentBalance);

        // This is the total expected underlying that we should redeem after all redemption calls
        // are executed.
        (/* */, uint256 totalUnderlyingRedeemed) = executeMoneyMarketRedemptions(underlying, data);

        // Ensure that we have sufficient funds before we exit
        require(withdrawAmountExternal <= currentBalance.add(totalUnderlyingRedeemed)); // dev: insufficient redeem
    }

    /// @notice Every time tokens are transferred into or out of the protocol, the prime supply
    /// and total underlying held must be updated.
    function _postTransferPrimeCashUpdate(
        address account,
        uint16 currencyId,
        int256 netTransferUnderlyingExternal,
        Token memory underlyingToken,
        PrimeRate memory primeRate
    ) private returns (int256 netPrimeSupplyChange) {
        int256 netUnderlyingChange = convertToInternal(underlyingToken, netTransferUnderlyingExternal);

        netPrimeSupplyChange = primeRate.convertFromUnderlying(netUnderlyingChange);

        Emitter.emitMintOrBurnPrimeCash(account, currencyId, netPrimeSupplyChange);
        PrimeCashExchangeRate.updateTotalPrimeSupply(currencyId, netPrimeSupplyChange, netUnderlyingChange);

        _updateNetStoredTokenBalance(underlyingToken.tokenAddress, netTransferUnderlyingExternal);
    }

    function convertToInternal(Token memory token, int256 amount) internal pure returns (int256) {
        // If token decimals > INTERNAL_TOKEN_PRECISION:
        //  on deposit: resulting dust will accumulate to protocol
        //  on withdraw: protocol may lose dust amount. However, withdraws are only calculated based
        //    on a conversion from internal token precision to external token precision so therefore dust
        //    amounts cannot be specified for withdraws.
        // If token decimals < INTERNAL_TOKEN_PRECISION then this will add zeros to the
        // end of amount and will not result in dust.
        if (token.decimals == Constants.INTERNAL_TOKEN_PRECISION) return amount;
        return amount.mul(Constants.INTERNAL_TOKEN_PRECISION).div(token.decimals);
    }

    function convertToExternal(Token memory token, int256 amount) internal pure returns (int256) {
        if (token.decimals == Constants.INTERNAL_TOKEN_PRECISION) return amount;
        // If token decimals > INTERNAL_TOKEN_PRECISION then this will increase amount
        // by adding a number of zeros to the end and will not result in dust.
        // If token decimals < INTERNAL_TOKEN_PRECISION:
        //  on deposit: Deposits are specified in external token precision and there is no loss of precision when
        //      tokens are converted from external to internal precision
        //  on withdraw: this calculation will round down such that the protocol retains the residual cash balance
        return amount.mul(token.decimals).div(Constants.INTERNAL_TOKEN_PRECISION);
    }

    /// @notice Converts a token to an underlying external amount with adjustments for rounding errors when depositing
    function convertToUnderlyingExternalWithAdjustment(
        Token memory token,
        int256 underlyingInternalAmount
    ) internal pure returns (int256 underlyingExternalAmount) {
        if (token.decimals < Constants.INTERNAL_TOKEN_PRECISION) {
            // If external < 8, we could truncate down and cause an off by one error, for example we need
            // 1.00000011 cash and we deposit only 1.000000, missing 11 units. Therefore, we add a unit at the
            // lower precision (external) to get around off by one errors
            underlyingExternalAmount = convertToExternal(token, underlyingInternalAmount).add(1);
        } else {
            // If external > 8, we may not mint enough asset tokens because in the case of 1e18 precision 
            // an off by 1 error at 1e8 precision is 1e10 units of the underlying token. In this case we
            // add 1 at the internal precision which has the effect of rounding up by 1e10
            underlyingExternalAmount = convertToExternal(token, underlyingInternalAmount.add(1));
        }
    }

    /// @notice Convenience method for getting the balance using a token object
    function balanceOf(Token memory token, address account) internal view returns (uint256) {
        if (token.tokenType == TokenType.Ether) {
            return account.balance;
        } else {
            return IERC20(token.tokenAddress).balanceOf(account);
        }
    }

    function transferIncentive(address account, uint256 tokensToTransfer) internal {
        GenericToken.safeTransferOut(Deployments.NOTE_TOKEN_ADDRESS, account, tokensToTransfer);
    }

    /// @notice It is critical that this method measures and records the balanceOf changes before and after
    /// every token change. If not, then external donations can affect the valuation of pCash and pDebt
    /// tokens which may be exploitable.
    /// @param redeemData parameters from the prime cash holding oracle
    function executeMoneyMarketRedemptions(
        Token memory underlyingToken,
        RedeemData[] memory redeemData
    ) internal returns (bool hasFailure, uint256 totalUnderlyingRedeemed) {
        for (uint256 i; i < redeemData.length; i++) {
            RedeemData memory data = redeemData[i];
            // Measure the token balance change if the `assetToken` value is set in the
            // current redemption data struct. 
            uint256 oldAssetBalance = IERC20(data.assetToken).balanceOf(address(this));

            // Measure the underlying balance change before and after the call.
            uint256 oldUnderlyingBalance = balanceOf(underlyingToken, address(this));
            
            // Some asset tokens may require multiple calls to redeem if there is an unstake
            // or redemption from WETH involved. We only measure the asset token balance change
            // on the final redemption call, as dictated by the prime cash holdings oracle.
            for (uint256 j; j < data.targets.length; j++) {
                // Allow low level calls to revert
                if (!GenericToken.executeLowLevelCall(data.targets[j], 0, data.callData[j], true)) {
                    hasFailure = true;
                }
            }

            // Ensure that we get sufficient underlying on every redemption
            uint256 newUnderlyingBalance = balanceOf(underlyingToken, address(this));
            uint256 underlyingBalanceChange = newUnderlyingBalance.sub(oldUnderlyingBalance);
            // If the call is not the final redemption, then expectedUnderlying should
            // be set to zero.
            require(data.expectedUnderlying <= underlyingBalanceChange);
        
            // Measure and update the asset token
            uint256 newAssetBalance = IERC20(data.assetToken).balanceOf(address(this));
            require(newAssetBalance <= oldAssetBalance);
            updateStoredTokenBalance(data.assetToken, oldAssetBalance, newAssetBalance);

            // Update the total value with the net change
            totalUnderlyingRedeemed = totalUnderlyingRedeemed.add(underlyingBalanceChange);

            // totalUnderlyingRedeemed is always positive or zero.
            updateStoredTokenBalance(underlyingToken.tokenAddress, oldUnderlyingBalance, newUnderlyingBalance);
        }
    }

    function updateStoredTokenBalance(address token, uint256 oldBalance, uint256 newBalance) internal {
        mapping(address => uint256) storage store = LibStorage.getStoredTokenBalances();
        uint256 storedBalance = store[token];
        // The stored balance must always be less than or equal to the previous balance of. oldBalance
        // will be larger in the case when there is a donation or dust value present. If stored balance somehow
        // goes above the oldBalance then there is a critical issue in the protocol.
        require(storedBalance <= oldBalance);
        int256 netBalanceChange = newBalance.toInt().sub(oldBalance.toInt());
        store[token] = int256(storedBalance).add(netBalanceChange).toUint();
    }

    function _updateNetStoredTokenBalance(address token, int256 netBalanceChange) private {
        mapping(address => uint256) storage store = LibStorage.getStoredTokenBalances();
        uint256 storedBalance = store[token];
        store[token] = int256(storedBalance).add(netBalanceChange).toUint();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PortfolioAsset,
    VaultAccount,
    VaultConfig,
    VaultAccountStorage,
    PrimeRate
} from "../global/Types.sol";
import {Constants} from "../global/Constants.sol";
import {LibStorage} from "../global/LibStorage.sol";

import {PrimeRateLib} from "./pCash/PrimeRateLib.sol";
import {SafeInt256} from "../math/SafeInt256.sol";
import {SafeUint256} from "../math/SafeUint256.sol";

import {ITransferEmitter} from "../external/proxies/BaseERC4626Proxy.sol";

/**
 * @notice Controls all event emissions for the protocol so that off chain block explorers can properly
 * index Notional internal accounting. Notional V3 will emit events for these tokens:
 * 
 * ERC20 (emits Transfer via proxy):
 *  - nToken (one nToken contract per currency that has fCash enabled)
 *  - pCash (one pCash contract per listed underlying token)
 *  - pDebt (one pDebt contract per pCash token that allows debt)
 *
 * ERC1155 (emitted from address(this)):
 *  - Positive fCash (represents a positive fCash balance)
 *      ID: [bytes23(0), uint8(0), uint16(currencyId), uint40(maturity), uint8(FCASH_ASSET_TYPE)]
 *  - Negative fCash (v3, represents a negative fCash balance)
 *      ID: [bytes23(0), uint8(1), uint16(currencyId), uint40(maturity), uint8(FCASH_ASSET_TYPE)]
 *  - Vault Share Units (v3, represents a share of a leveraged vault)
 *      ID: [bytes5(0), bytes20(vaultAddress), uint16(currencyId), uint40(maturity), uint8(VAULT_SHARE_ASSET_TYPE)]
 *  - Vault Debt Units (v3, represents debt owed to a leveraged vault)
 *      ID: [bytes5(0), bytes20(vaultAddress), uint16(currencyId), uint40(maturity), uint8(VAULT_DEBT_ASSET_TYPE)]
 *  - Vault Cash Units (v3, represents cash held on a leveraged vault account after liquidation)
 *      ID: [bytes5(0), bytes20(vaultAddress), uint16(currencyId), uint40(maturity), uint8(VAULT_CASH_ASSET_TYPE)]
 *  - Legacy nToken (v3, emitted for legacy nToken transfers)
 *      ID: [bytes23(0), uint8(0), uint16(currencyId), uint40(0), uint8(LEGACY_NTOKEN_ASSET_TYPE)]
 *
 *  - NOTE: Liquidity Token ids are not valid within the Notional V3 schema since they are only held by the nToken
 *    and never transferred.
 */
library Emitter {
    using SafeInt256 for int256;
    using SafeUint256 for uint256;

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    uint256 private constant MATURITY_OFFSET        = 8;
    uint256 private constant CURRENCY_OFFSET        = 48;
    uint256 private constant VAULT_ADDRESS_OFFSET   = 64;

    uint256 private constant FCASH_FLAG_OFFSET      = 64;
    uint256 private constant NEGATIVE_FCASH_MASK    = 1 << 64;

    function decodeCurrencyId(uint256 id) internal pure returns (uint16) {
        return uint16(id >> CURRENCY_OFFSET);
    }

    function isfCash(uint256 id) internal pure returns (bool) {
        return uint8(id) == Constants.FCASH_ASSET_TYPE;
    }

    function encodeId(
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType,
        address vaultAddress,
        bool isfCashDebt
    ) internal pure returns (uint256 id) {
        if (assetType == Constants.FCASH_ASSET_TYPE) {
            return encodefCashId(currencyId, maturity, isfCashDebt ? int256(-1) : int256(1));
        } else if (
            assetType == Constants.VAULT_CASH_ASSET_TYPE ||
            assetType == Constants.VAULT_SHARE_ASSET_TYPE ||
            assetType == Constants.VAULT_DEBT_ASSET_TYPE
        ) {
            return _encodeVaultId(vaultAddress, currencyId, maturity, assetType);
        } else if (assetType == Constants.LEGACY_NTOKEN_ASSET_TYPE) {
            return _legacyNTokenId(currencyId);
        }

        revert();
    }

    function decodeId(uint256 id) internal pure returns (
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType,
        address vaultAddress,
        bool isfCashDebt
    ) {
        assetType   = uint8(id);
        maturity    = uint40(id >> MATURITY_OFFSET);
        currencyId  = uint16(id >> CURRENCY_OFFSET);

        if (assetType == Constants.FCASH_ASSET_TYPE) {
            isfCashDebt = uint8(id >> FCASH_FLAG_OFFSET) == 1;
        } else {
            vaultAddress = address(id >> VAULT_ADDRESS_OFFSET);
        }
    }

    function encodefCashId(uint16 currencyId, uint256 maturity, int256 amount) internal pure returns (uint256 id) {
        require(currencyId <= Constants.MAX_CURRENCIES);
        require(maturity <= type(uint40).max);
        id = _posfCashId(currencyId, maturity);
        if (amount < 0) id = id | NEGATIVE_FCASH_MASK;
    }

    function decodefCashId(uint256 id) internal pure returns (uint16 currencyId, uint256 maturity, bool isfCashDebt) {
        // If the id is not of an fCash asset type, return zeros
        if (uint8(id) != Constants.FCASH_ASSET_TYPE) return (0, 0, false);

        maturity    = uint40(id >> MATURITY_OFFSET);
        currencyId  = uint16(id >> CURRENCY_OFFSET);
        isfCashDebt   = uint8(id >> FCASH_FLAG_OFFSET) == 1;
    }

    function _encodeVaultId(
        address vault,
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType
    ) private pure returns (uint256 id) {
        return uint256(
            (bytes32(uint256(vault)) << VAULT_ADDRESS_OFFSET) |
            (bytes32(uint256(currencyId)) << CURRENCY_OFFSET) |
            (bytes32(maturity) << MATURITY_OFFSET)            |
            (bytes32(assetType))
        );
    }

    function decodeVaultId(uint256 id) internal pure returns (
        uint256 assetType,
        uint16 currencyId,
        uint256 maturity,
        address vaultAddress
    ) {
        assetType   = uint8(id);
        // If the asset type is below this it is not a valid vault asset id
        if (assetType < Constants.VAULT_SHARE_ASSET_TYPE) return (0, 0, 0, address(0));

        maturity    = uint40(id >> MATURITY_OFFSET);
        currencyId  = uint16(id >> CURRENCY_OFFSET);
        vaultAddress = address(id >> VAULT_ADDRESS_OFFSET);
    }


    function _posfCashId(uint16 currencyId, uint256 maturity) internal pure returns (uint256 id) {
        return uint256(
            (bytes32(uint256(currencyId)) << CURRENCY_OFFSET) |
            (bytes32(maturity) << MATURITY_OFFSET)            |
            (bytes32(uint256(Constants.FCASH_ASSET_TYPE)))
        );
    }

    function _legacyNTokenId(uint16 currencyId) internal pure returns (uint256 id) {
        return uint256(
            (bytes32(uint256(currencyId)) << CURRENCY_OFFSET) |
            (bytes32(uint256(Constants.LEGACY_NTOKEN_ASSET_TYPE)))
        );
    }

    function _isLegacyNToken(uint16 currencyId) internal pure returns (bool) {
        uint256 id;
        assembly {
            id := chainid()
        }

        // The first four currencies on mainnet are legacy nTokens.
        return id == 1 && currencyId <= 4;
    }

    function _getPrimeProxy(bool isDebt, uint16 currencyId) private view returns (ITransferEmitter) {
        return isDebt ? 
            ITransferEmitter(LibStorage.getPDebtAddressStorage()[currencyId]) :
            ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
    }

    function _fCashPair(
        uint16 currencyId, uint256 maturity, int256 amount
    ) private pure returns (uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](2);
        uint256 id = _posfCashId(currencyId, maturity);
        ids[0] = id;
        ids[1] = id | NEGATIVE_FCASH_MASK;

        uint256[] memory values = new uint256[](2);
        values[0] = uint256(amount.abs());
        values[1] = uint256(amount.abs());

        return (ids, values);
    }

    /// @notice Emits a pair of fCash mints. fCash is only ever created or destroyed via these pairs and then
    /// the positive side is bought or sold.
    function emitChangefCashLiquidity(
        address account, uint16 currencyId, uint256 maturity, int256 netDebtChange
    ) internal {
        (uint256[] memory ids, uint256[] memory values) = _fCashPair(currencyId, maturity, netDebtChange);
        address from; address to;
        if (netDebtChange < 0) from = account; // burning
        else to = account; // minting
        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    /// @notice Transfers positive fCash between accounts
    function emitTransferfCash(
        address from, address to, uint16 currencyId, uint256 maturity, int256 amount
    ) internal {
        if (amount == 0) return;
        uint256 id = _posfCashId(currencyId, maturity);
        // If the amount is negative, then swap the direction of the transfer. We only ever emit
        // transfers of positive fCash. Negative fCash is minted on an account and never transferred.
        if (amount < 0) (from, to) = (to, from);

        emit TransferSingle(msg.sender, from, to, id, uint256(amount.abs()));
    }

    function emitBatchTransferfCash(
        address from, address to, PortfolioAsset[] memory assets
    ) internal {
        uint256 len = assets.length;
        // Emit single events since it's unknown if all of the notional values are positive or negative.
        for (uint256 i; i < len; i++) {
            emitTransferfCash(from, to, assets[i].currencyId, assets[i].maturity, assets[i].notional);
        }
    }

    /// @notice When fCash is settled, cash or debt is transferred from the "settlement reserve" to the account
    /// and the settled fCash is burned.
    function emitSettlefCash(
        address account, uint16 currencyId, uint256 maturity, int256 fCashSettled, int256 pCashOrDebtValue
    ) internal {
        // Settlement is the only time when negative fCash is burned directly without destroying the
        // opposing positive fCash pair.
        uint256 id = _posfCashId(currencyId, maturity);
        if (fCashSettled < 0) id = id | NEGATIVE_FCASH_MASK;
        emit TransferSingle(msg.sender, account, address(0), id, uint256(fCashSettled.abs()));

        // NOTE: zero values will emit a pCash event
        ITransferEmitter proxy = _getPrimeProxy(pCashOrDebtValue < 0, currencyId);
        proxy.emitTransfer(Constants.SETTLEMENT_RESERVE, account, uint256(pCashOrDebtValue.abs()));
    }

    /// @notice Emits events to reconcile off chain accounting for the edge condition when
    /// leveraged vaults lend at zero interest.
    function emitSettlefCashDebtInReserve(
        uint16 currencyId,
        uint256 maturity,
        int256 fCashDebtInReserve,
        int256 settledPrimeCash,
        int256 excessCash
    ) internal {
        uint256 id = _posfCashId(currencyId, maturity) | NEGATIVE_FCASH_MASK;
        emit TransferSingle(msg.sender, Constants.SETTLEMENT_RESERVE, address(0), id, uint256(fCashDebtInReserve.abs()));
        // The settled prime debt doesn't exist in this case since we don't add the debt to the
        // total prime debt so we just "burn" the prime cash that only exists in an off chain accounting context.
        emitMintOrBurnPrimeCash(Constants.SETTLEMENT_RESERVE, currencyId, settledPrimeCash);
        if (excessCash > 0) {
            // Any excess prime cash in reserve is "transferred" to the fee reserve
            emitTransferPrimeCash(Constants.SETTLEMENT_RESERVE, Constants.FEE_RESERVE, currencyId, excessCash);
        }
    }

    /// @notice During an fCash trade, cash is transferred between the account and then nToken. When borrowing,
    /// cash is transferred from the nToken to the account. During lending, the opposite happens. The fee reserve
    /// always accrues a positive amount of cash.
    function emitfCashMarketTrade(
        address account,
        uint16 currencyId,
        uint256 maturity,
        int256 fCashPurchased,
        int256 cashToAccount,
        int256 cashToReserve
    ) internal {
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        address nToken = LibStorage.getNTokenAddressStorage()[currencyId];
        // If account == nToken then this is a lending transaction when the account is
        // over leveraged. Still emit the transfer so we can record how much the lending cost and how
        // much fCash was purchased.

        // Do this calculation so it properly represents that the account is paying the fee to the
        // reserve. When borrowing, the account will receive the full cash balance and then transfer
        // some amount to the reserve. When lending, the account will transfer the cash to reserve and
        // the remainder will be transferred to the nToken.
        int256 accountToNToken = cashToAccount.add(cashToReserve);
        cashProxy.emitfCashTradeTransfers(account, nToken, accountToNToken, cashToReserve.toUint());

        // When lending (fCashPurchased > 0), the nToken transfers positive fCash to the
        // account. When the borrowing (fCashPurchased < 0), the account transfers positive fCash to the
        // nToken. emitTransferfCash will flip the from and to accordingly.
        emitTransferfCash(nToken, account, currencyId, maturity, fCashPurchased);
    }

    /// @notice When underlying tokens are deposited, prime cash is minted. When underlying tokens are
    /// withdrawn, prime cash is burned.
    function emitMintOrBurnPrimeCash(
        address account, uint16 currencyId, int256 netPrimeCash
    ) internal {
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        cashProxy.emitMintOrBurn(account, netPrimeCash);
    }

    function emitTransferPrimeCash(
        address from, address to, uint16 currencyId, int256 primeCashTransfer
    ) internal {
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        // This can happen during fCash liquidation where the liquidator receives cash for negative fCash
        if (primeCashTransfer < 0) (to, from) = (from, to);
        cashProxy.emitTransfer(from, to, uint256(primeCashTransfer.abs()));
    }

    function emitTransferNToken(
        address from, address to, uint16 currencyId, int256 netNTokenTransfer
    ) internal {
        address nToken = LibStorage.getNTokenAddressStorage()[currencyId];
        // No scenario where this occurs, but have it here just in case
        if (netNTokenTransfer < 0) (to, from) = (from, to);
        uint256 value = uint256(netNTokenTransfer.abs());
        if (_isLegacyNToken(currencyId)) {
            // Legacy nToken contracts do not have an emit method so use an ERC1155 instead
            emit TransferSingle(msg.sender, from, to, _legacyNTokenId(currencyId), value);
        } else {
            ITransferEmitter(nToken).emitTransfer(from, to, value);
        }
    }

    /// @notice When prime debt is created, an offsetting pair of prime cash and prime debt tokens are
    /// created (similar to fCash liquidity) and the prime cash tokens are burned (withdrawn) or transferred
    /// in exchange for nTokens or fCash. The opposite occurs when prime debt is repaid. Prime cash is burned
    /// in order to repay prime debt.
    function emitBorrowOrRepayPrimeDebt(
        address account, uint16 currencyId, int256 netPrimeSupplyChange, int256 netPrimeDebtChange
    ) internal {
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        ITransferEmitter debtProxy = ITransferEmitter(LibStorage.getPDebtAddressStorage()[currencyId]);
        debtProxy.emitMintOrBurn(account, netPrimeDebtChange);
        cashProxy.emitMintOrBurn(account, netPrimeSupplyChange);
    }

    /// @notice Some amount of prime cash is deposited in order to mint nTokens.
    function emitNTokenMint(
        address account, address nToken, uint16 currencyId, int256 primeCashDeposit, int256 tokensToMint
    ) internal {
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        if (tokensToMint > 0 && primeCashDeposit > 0) {
            cashProxy.emitTransfer(account, nToken, uint256(primeCashDeposit));
            if (_isLegacyNToken(currencyId)) {
                // Legacy nToken contracts do not have an emit method so use an ERC1155 instead
                emit TransferSingle(msg.sender, address(0), account, _legacyNTokenId(currencyId), tokensToMint.toUint());
            } else {
                ITransferEmitter(nToken).emitMintOrBurn(account, tokensToMint);
            }
        }
    }

    /// @notice Some amount of prime cash is transferred to the account in exchange for nTokens burned.
    /// fCash may also be transferred to the account but that is handled in a different method.
    function emitNTokenBurn(
        address account, uint16 currencyId, int256 primeCashRedeemed, int256 tokensToBurn
    ) internal {
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        address nToken = LibStorage.getNTokenAddressStorage()[currencyId];

        if (primeCashRedeemed > 0 && tokensToBurn > 0) {
            cashProxy.emitTransfer(nToken, account, uint256(primeCashRedeemed));
            if (_isLegacyNToken(currencyId)) {
                // Legacy nToken contracts do not have an emit method so use an ERC1155 instead
                emit TransferSingle(msg.sender, account, address(0), _legacyNTokenId(currencyId), tokensToBurn.abs().toUint());
            } else {
                ITransferEmitter(nToken).emitMintOrBurn(account, tokensToBurn.neg());
            }
        }
    }

    function emitVaultFeeTransfers(
        address vault, uint16 currencyId, int256 nTokenFee, int256 reserveFee
    ) internal{
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        address nToken = LibStorage.getNTokenAddressStorage()[currencyId];
        // These are emitted in the reverse order from the fCash trade transfers so that we can identify it as
        // vault fee transfers off chain.
        cashProxy.emitTransfer(vault, Constants.FEE_RESERVE, reserveFee.toUint());
        cashProxy.emitTransfer(vault, address(nToken), nTokenFee.toUint());
    }

    /// @notice Detects changes to a vault account and properly emits vault debt, vault shares and vault cash events.
    function emitVaultAccountChanges(
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        VaultAccountStorage memory prior,
        uint256 newDebtStorageValue
    ) internal {
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        uint256 baseId = _encodeVaultId(vaultConfig.vault, vaultConfig.borrowCurrencyId, prior.maturity, 0);
        ids[0] = baseId | Constants.VAULT_DEBT_ASSET_TYPE;
        ids[1] = baseId | Constants.VAULT_SHARE_ASSET_TYPE;

        if (vaultAccount.maturity == 0 || (prior.maturity != 0 && prior.maturity != vaultAccount.maturity)) {
            // Account has been closed, settled or rolled to a new maturity. Emit burn events for the prior maturity's data.
            values[0] = prior.accountDebt;
            values[1] = prior.vaultShares;
            emit TransferBatch(msg.sender, vaultAccount.account, address(0), ids, values);
        } else if (vaultAccount.maturity == prior.maturity) {
            // Majority of the time, vault accounts will either burn or mint vault shares and debt at the same time. However,
            // when an account sells vault shares to pay down a secondary debt without paying down any primary
            // debt in the prime maturity, the debt may increase while the vault shares decreases. In this case, two TransferBatch
            // events will be fired. One will be the burn of the vault shares and the second will be the mint of the vault debt.
            bool isBurn = newDebtStorageValue < prior.accountDebt || vaultAccount.vaultShares < prior.vaultShares;
            if (isBurn) {
                values[0] = newDebtStorageValue < uint256(prior.accountDebt) ? prior.accountDebt - newDebtStorageValue : 0;
                values[1] = uint256(prior.vaultShares).sub(vaultAccount.vaultShares);
                emit TransferBatch(msg.sender, vaultAccount.account, address(0), ids, values);
            }

            if (!isBurn || prior.accountDebt < newDebtStorageValue) {
                values[0] = newDebtStorageValue.sub(prior.accountDebt);
                values[1] = prior.vaultShares < vaultAccount.vaultShares ? vaultAccount.vaultShares.sub(prior.vaultShares) : 0;
                emit TransferBatch(msg.sender, address(0), vaultAccount.account, ids, values);
            }
        }

        if (vaultAccount.maturity != 0 && prior.maturity != vaultAccount.maturity) {
            // Need to mint the shares for the new vault maturity, this may be a new entrant into
            // the vault or the vault account rolling to a new maturity
            baseId = _encodeVaultId(vaultConfig.vault, vaultConfig.borrowCurrencyId, vaultAccount.maturity, 0);
            ids[0] = baseId | Constants.VAULT_DEBT_ASSET_TYPE;
            ids[1] = baseId | Constants.VAULT_SHARE_ASSET_TYPE;
            values[0] = newDebtStorageValue;
            values[1] = vaultAccount.vaultShares;
            emit TransferBatch(msg.sender, address(0), vaultAccount.account, ids, values);
        }

        if (prior.primaryCash != 0) {
            // Cash must always be burned in this method from the prior maturity
            emit TransferSingle(
                msg.sender,
                vaultAccount.account,
                address(0),
                baseId | Constants.VAULT_CASH_ASSET_TYPE,
                prior.primaryCash
            );
        }

    }

    /// @notice Emits events during a vault deleverage, where a vault account receives cash and loses
    /// vault shares as a result.
    function emitVaultDeleverage(
        address liquidator,
        address account,
        address vault,
        uint16 currencyId,
        uint256 maturity,
        int256 depositAmountPrimeCash,
        uint256 vaultSharesToLiquidator,
        PrimeRate memory pr
    ) internal {
        // Liquidator transfer prime cash to vault
        emitTransferPrimeCash(liquidator, vault, currencyId, depositAmountPrimeCash);
        uint256 baseId = _encodeVaultId(vault, currencyId, maturity, 0);
        
        // Mints vault cash to the account in the same amount as prime cash if it is
        // an fCash maturity
        if (maturity == Constants.PRIME_CASH_VAULT_MATURITY) {
            // Convert this to prime debt basis
            int256 primeDebtStorage = PrimeRateLib.convertToStorageValue(pr, depositAmountPrimeCash.neg()).neg();
            if (primeDebtStorage == -1) primeDebtStorage = 0;

            emit TransferSingle(
                msg.sender,
                account,
                address(0),
                baseId | Constants.VAULT_DEBT_ASSET_TYPE,
                primeDebtStorage.toUint()
            );
        } else {
            emit TransferSingle(
                msg.sender,
                address(0),
                account,
                baseId | Constants.VAULT_CASH_ASSET_TYPE,
                depositAmountPrimeCash.toUint()
            );
        }

        // Transfer vault shares to the liquidator
        emit TransferSingle(
            msg.sender, account, liquidator, baseId | Constants.VAULT_SHARE_ASSET_TYPE, vaultSharesToLiquidator
        );
    }

    /// @notice Emits events for primary cash burned on a vault account.
    function emitVaultAccountCashBurn(
        address account,
        address vault,
        uint16 currencyId,
        uint256 maturity,
        int256 fCash,
        int256 vaultCash
    ) internal {
        uint256 baseId = _encodeVaultId(vault, currencyId, maturity, 0);
        uint256[] memory ids = new uint256[](2);
        uint256[] memory values = new uint256[](2);
        ids[0] = baseId | Constants.VAULT_DEBT_ASSET_TYPE;
        ids[1] = baseId | Constants.VAULT_CASH_ASSET_TYPE;
        values[0] = fCash.toUint();
        values[1] = vaultCash.toUint();
        emit TransferBatch(msg.sender, account, address(0), ids, values);
    }

    /// @notice A set of spurious events to record a direct transfer between vaults and an account
    /// during entering and exiting vaults.
    function emitVaultMintTransferBurn(
        address minter, address burner, uint16 currencyId, uint256 mintAmount, uint256 transferAndBurnAmount
    ) internal{
        ITransferEmitter cashProxy = ITransferEmitter(LibStorage.getPCashAddressStorage()[currencyId]);
        // During vault entry, the account (minter) will deposit mint amount and transfer the
        // entirety of it to the vault (burner) who will then withdraw it all into the strategy (burn).

        // During vault exit, the vault (minter) will "receive" sufficient cash to repay debt and
        // some additional profits to the account. The vault will "transferAndBurn" the profits
        // to the account. The cash for repayment to Notional will be transferred into fCash markets
        // or used to burn prime supply debt. These events will be emitted separately.

        cashProxy.emitMintTransferBurn(minter, burner, mintAmount, transferAndBurnAmount);
    }

    function emitVaultMintOrBurnCash(
        address account,
        address vault,
        uint16 currencyId,
        uint256 maturity,
        int256 netVaultCash
    ) internal {
        if (netVaultCash == 0) return;
        uint256 id = _encodeVaultId(vault, currencyId, maturity, Constants.VAULT_CASH_ASSET_TYPE);
        address from; address to;
        if (netVaultCash < 0) {
            // Burn
            from = account; to = address(0);
        } else {
            // Mint
            from = address(0); to = account;
        }

        uint256 value = uint256(netVaultCash.abs());
        emit TransferSingle(msg.sender, from, to, id, value);
    }

    /// @notice Emits an event where the vault borrows or repays secondary debt
    function emitVaultSecondaryDebt(
        address account,
        address vault,
        uint16 currencyId,
        uint256 maturity,
        int256 vaultDebtAmount
    ) internal {
        if (vaultDebtAmount == 0) return;
        address from;
        address to;
        uint256 id = _encodeVaultId(vault, currencyId, maturity, Constants.VAULT_DEBT_ASSET_TYPE);

        if (vaultDebtAmount > 0) {
            // Debt amounts are negative, burning when positive
            from = account; to = address(0);
         } else {
            // Minting when negative
            from = address(0); to = account;
         }

        emit TransferSingle(msg.sender, from, to, id, uint256(vaultDebtAmount.abs()));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    ETHRate,
    PortfolioAsset,
    CashGroupParameters,
    PortfolioState,
    Token,
    AccountContext,
    PrimeRate,
    LiquidationFactors
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";

import {Emitter} from "../Emitter.sol";
import {AssetHandler} from "../valuation/AssetHandler.sol";
import {CashGroup} from "../markets/CashGroup.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {TokenHandler} from "../balances/TokenHandler.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";
import {ExchangeRate} from "../valuation/ExchangeRate.sol";
import {PortfolioHandler} from "../portfolio/PortfolioHandler.sol";
import {BitmapAssetsHandler} from "../portfolio/BitmapAssetsHandler.sol";

import {AccountContextHandler} from "../AccountContextHandler.sol";
import {LiquidationHelpers} from "./LiquidationHelpers.sol";

import {FreeCollateralExternal} from "../../external/FreeCollateralExternal.sol";
import {SettleAssetsExternal} from "../../external/SettleAssetsExternal.sol";

library LiquidatefCash {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;
    using ExchangeRate for ETHRate;
    using AssetHandler for PortfolioAsset;
    using CashGroup for CashGroupParameters;
    using PrimeRateLib for PrimeRate;
    using AccountContextHandler for AccountContext;
    using TokenHandler for Token;

    event LiquidatefCashEvent(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 fCashCurrency,
        int256 netLocalFromLiquidator,
        uint256[] fCashMaturities,
        int256[] fCashNotionalTransfer
    );

    /// @notice Calculates the risk adjusted and liquidation discount factors used when liquidating fCash. The
    /// The risk adjusted discount factor is used to value fCash, the liquidation discount factor is used to 
    /// calculate the price of the fCash asset at a discount to the risk adjusted factor.
    /// @dev During local fCash liquidation, collateralCashGroup will be set to the local currency cash group
    function _calculatefCashDiscounts(
        LiquidationFactors memory factors,
        uint256 maturity,
        uint256 blockTime,
        bool isNotionalPositive
    ) private view returns (int256 riskAdjustedDiscountFactor, int256 liquidationDiscountFactor) {
        uint256 oracleRate = factors.collateralCashGroup.calculateOracleRate(maturity, blockTime);

        if (isNotionalPositive) {
            // This is the discount factor used to calculate the fCash present value during free collateral
            riskAdjustedDiscountFactor = AssetHandler.getRiskAdjustedfCashDiscount(
                factors.collateralCashGroup, maturity, blockTime
            );

            // This is the discount factor that liquidators get to purchase fCash at, will be larger than
            // the risk adjusted discount factor.
            liquidationDiscountFactor = AssetHandler.getDiscountFactor(
                maturity.sub(blockTime),
                oracleRate.add(factors.collateralCashGroup.getLiquidationfCashHaircut())
            );
        } else {
            riskAdjustedDiscountFactor = AssetHandler.getRiskAdjustedDebtDiscount(
                factors.collateralCashGroup, maturity, blockTime
            );

            uint256 buffer = factors.collateralCashGroup.getLiquidationDebtBuffer();
            liquidationDiscountFactor = AssetHandler.getDiscountFactor(
                maturity.sub(blockTime),
                oracleRate < buffer ? 0 : oracleRate.sub(buffer)
            );
        }
    }

    /// @notice Returns the fCashNotional for a given account, currency and maturity.
    /// @return the notional amount
    function _getfCashNotional(
        address liquidateAccount,
        fCashContext memory context,
        uint256 currencyId,
        uint256 maturity
    ) private view returns (int256) {
        if (context.accountContext.bitmapCurrencyId == currencyId) {
            return
                BitmapAssetsHandler.getifCashNotional(liquidateAccount, currencyId, maturity);
        }

        PortfolioAsset[] memory portfolio = context.portfolio.storedAssets;
        // Loop backwards through the portfolio since we require fCash maturities to be sorted
        // descending
        for (uint256 i = portfolio.length; (i--) > 0;) {
            PortfolioAsset memory asset = portfolio[i];
            if (
                asset.currencyId == currencyId &&
                asset.assetType == Constants.FCASH_ASSET_TYPE &&
                asset.maturity == maturity
            ) {
                return asset.notional;
            }
        }

        // If asset is not found then we return zero instead of failing in the case that a previous
        // liquidation has already liquidated the specified fCash asset. This liquidation can continue
        // to the next specified fCash asset.
        return 0;
    }

    struct fCashContext {
        AccountContext accountContext;
        LiquidationFactors factors;
        PortfolioState portfolio;
        int256 localCashBalanceUnderlying;
        int256 underlyingBenefitRequired;
        int256 localPrimeCashFromLiquidator;
        int256 liquidationDiscount;
        int256[] fCashNotionalTransfers;
    }

    /// @notice Allows the liquidator to purchase fCash in the same currency that a debt is denominated in. It's
    /// also possible that there is no debt in the local currency, in that case the liquidated account will gain the
    /// benefit of the difference between the discounted fCash value and the cash
    function liquidatefCashLocal(
        address liquidateAccount,
        uint256 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts,
        fCashContext memory c,
        uint256 blockTime
    ) internal view {
        // If local asset available == 0 then there is nothing that this liquidation can do.
        require(c.factors.localPrimeAvailable != 0);

        // If local available is positive then we can trade fCash to cash to increase the total free
        // collateral of the account. Local available will always increase due to the removal of the haircut
        // on fCash assets as they are converted to cash. The increase will be the difference between the
        // risk adjusted haircut value and the liquidation value. Note that negative fCash assets can also be
        // liquidated via this method, the liquidator will receive negative fCash and cash as a result -- in effect
        // they will be borrowing at a discount to the oracle rate.
        c.underlyingBenefitRequired = LiquidationHelpers.calculateLocalLiquidationUnderlyingRequired(
            c.factors.localPrimeAvailable,
            c.factors.netETHValue,
            c.factors.localETHRate
        );

        for (uint256 i = 0; i < fCashMaturities.length; i++) {
            // Require that fCash maturities are sorted descending. This ensures that a maturity can only
            // be specified exactly once. It also ensures that the longest dated assets (most risky) are
            // liquidated first.
            if (i > 0) require(fCashMaturities[i - 1] > fCashMaturities[i]);

            int256 notional =
                _getfCashNotional(liquidateAccount, c, localCurrency, fCashMaturities[i]);
            // If a notional balance is negative, ensure that there is some local cash balance to
            // purchase for the liquidation. Allow a zero cash balance so that the loop continues even if
            // all of the cash balance has been transferred.
            if (notional < 0) require(c.localCashBalanceUnderlying >= 0); // dev: insufficient cash balance
            if (notional == 0) continue;

            // If notional > 0 then liquidation discount > risk adjusted discount
            //    this is because the liquidation oracle rate < risk adjusted oracle rate
            // If notional < 0 then liquidation discount < risk adjusted discount
            //    this is because the liquidation oracle rate > risk adjusted oracle rate
            (int256 riskAdjustedDiscountFactor, int256 liquidationDiscountFactor) =
                _calculatefCashDiscounts(c.factors, fCashMaturities[i], blockTime, notional > 0);

            // The benefit to the liquidated account is the difference between the liquidation discount factor
            // and the risk adjusted discount factor:
            // localCurrencyBenefit = fCash * (liquidationDiscountFactor - riskAdjustedDiscountFactor)
            // fCash = localCurrencyBenefit / (liquidationDiscountFactor - riskAdjustedDiscountFactor)
            // abs is used here to ensure positive values
            c.fCashNotionalTransfers[i] = c.underlyingBenefitRequired
            // NOTE: Governance should be set such that these discount factors are unlikely to be zero. It's
            // possible that the interest rates are so low or that the fCash asset is very close to maturity
            // that this situation can occur. In this case, there would be almost zero benefit to liquidating
            // the particular fCash asset.
                .divInRatePrecision(liquidationDiscountFactor.sub(riskAdjustedDiscountFactor).abs());

            // fCashNotionalTransfers[i] is always positive at this point. The max liquidate amount is
            // calculated using the absolute value of the notional amount to ensure that the inequalities
            // operate properly inside calculateLiquidationAmount.
            c.fCashNotionalTransfers[i] = LiquidationHelpers.calculateLiquidationAmount(
                c.fCashNotionalTransfers[i], // liquidate amount required
                notional.abs(), // max total balance
                SafeInt256.toInt(maxfCashLiquidateAmounts[i]) // user specified maximum
            );

            // This is the price the liquidator pays of the fCash that has been liquidated
            int256 fCashLiquidationValueUnderlying =
                c.fCashNotionalTransfers[i].mulInRatePrecision(liquidationDiscountFactor);

            if (notional < 0) {
                // In the case of negative notional amounts, limit the amount of liquidation to the local cash
                // balance in underlying so that the liquidated account does not incur a negative cash balance.
                if (fCashLiquidationValueUnderlying > c.localCashBalanceUnderlying) {
                    // We know that all these values are positive at this point.
                    c.fCashNotionalTransfers[i] = c.fCashNotionalTransfers[i]
                        .mul(c.localCashBalanceUnderlying)
                        .div(fCashLiquidationValueUnderlying);
                    fCashLiquidationValueUnderlying = c.localCashBalanceUnderlying;
                }

                // Flip the sign when the notional is negative
                c.fCashNotionalTransfers[i] = c.fCashNotionalTransfers[i].neg();
                // When the notional is negative, cash balance will be transferred to the liquidator instead of
                // being provided by the liquidator.
                fCashLiquidationValueUnderlying = fCashLiquidationValueUnderlying.neg();
            }

            // NOTE: localPrimeCashFromLiquidator is actually in underlying terms during this loop, it is converted to asset terms just once
            // at the end of the loop to limit loss of precision
            c.localPrimeCashFromLiquidator = c.localPrimeCashFromLiquidator.add(
                fCashLiquidationValueUnderlying
            );
            c.localCashBalanceUnderlying = c.localCashBalanceUnderlying.add(
                fCashLiquidationValueUnderlying
            );

            // Deduct the total benefit gained from liquidating this fCash position
            c.underlyingBenefitRequired = c.underlyingBenefitRequired.sub(
                c.fCashNotionalTransfers[i]
                    .mulInRatePrecision(liquidationDiscountFactor.sub(riskAdjustedDiscountFactor))
                    .abs()
            );

            // Once the underlying benefit is reduced below zero then we have liquidated a sufficient amount
            if (c.underlyingBenefitRequired <= 0) break;
        }

        // Convert local to purchase to asset terms for transfers
        c.localPrimeCashFromLiquidator = c.factors.localPrimeRate.convertFromUnderlying(
            c.localPrimeCashFromLiquidator
        );
    }

    /// @notice Allows the liquidator to purchase fCash in a different currency that a debt is denominated in.
    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint256 collateralCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts,
        fCashContext memory c,
        uint256 blockTime
    ) internal view {
        require(c.factors.localPrimeAvailable < 0); // dev: no local debt
        require(c.factors.collateralAssetAvailable > 0); // dev: no collateral assets

        {
            // NOTE: underlying benefit is return in asset terms from this function, convert it to underlying
            // for the purposes of this method. The underlyingBenefitRequired is denominated in collateral currency
            // and equivalent to convertToCollateral(netETHValue.neg()).
            (c.underlyingBenefitRequired, c.liquidationDiscount) = LiquidationHelpers
                .calculateCrossCurrencyFactors(c.factors);
            c.underlyingBenefitRequired = c.factors.collateralCashGroup.primeRate.convertToUnderlying(
                c.underlyingBenefitRequired
            );
        }

        for (uint256 i = 0; i < fCashMaturities.length; i++) {
            // Require that fCash maturities are sorted descending. This ensures that a maturity can only
            // be specified exactly once. It also ensures that the longest dated assets (most risky) are
            // liquidated first.
            if (i > 0) require(fCashMaturities[i - 1] > fCashMaturities[i]);

            int256 notional =
                _getfCashNotional(liquidateAccount, c, collateralCurrency, fCashMaturities[i]);
            if (notional == 0) continue;
            require(notional > 0); // dev: invalid fcash asset

            c.fCashNotionalTransfers[i] = _calculateCrossCurrencyfCashToLiquidate(
                c,
                fCashMaturities[i],
                blockTime,
                SafeInt256.toInt(maxfCashLiquidateAmounts[i]),
                notional
            );

            if (
                c.underlyingBenefitRequired <= 0 ||
                // These two factors will be capped and floored at zero inside `_limitPurchaseByAvailableAmounts`
                c.factors.collateralAssetAvailable == 0 ||
                c.factors.localPrimeAvailable == 0
            ) break;
        }
    }

    function _calculateCrossCurrencyfCashToLiquidate(
        fCashContext memory c,
        uint256 maturity,
        uint256 blockTime,
        int256 maxfCashLiquidateAmount,
        int256 notional
    ) private view returns (int256) {
        (int256 riskAdjustedDiscountFactor, int256 liquidationDiscountFactor) =
            _calculatefCashDiscounts(c.factors, maturity, blockTime, true);

        // collateralPurchased = fCashToLiquidate * fCashDiscountFactor
        // (see: _calculateCollateralToRaise)
        // collateralBenefit = collateralPurchased * (localBuffer / liquidationDiscount - collateralHaircut)
        // totalBenefit = fCashBenefit + collateralBenefit
        // totalBenefit = fCashToLiquidate * (liquidationDiscountFactor - riskAdjustedDiscountFactor) +
        //      fCashToLiquidate * liquidationDiscountFactor * (localBuffer / liquidationDiscount - collateralHaircut)
        // totalBenefit = fCashToLiquidate * [
        //      (liquidationDiscountFactor - riskAdjustedDiscountFactor) +
        //      (liquidationDiscountFactor * (localBuffer / liquidationDiscount - collateralHaircut))
        // ]
        // fCashToLiquidate = totalBenefit / [
        //      (liquidationDiscountFactor - riskAdjustedDiscountFactor) +
        //      (liquidationDiscountFactor * (localBuffer / liquidationDiscount - collateralHaircut))
        // ]
        int256 benefitDivisor;
        {
            // prettier-ignore
            int256 termTwo = (
                    c.factors.localETHRate.buffer.mul(Constants.PERCENTAGE_DECIMALS).div(
                        c.liquidationDiscount
                    )
                ).sub(c.factors.collateralETHRate.haircut);
            termTwo = liquidationDiscountFactor.mul(termTwo).div(Constants.PERCENTAGE_DECIMALS);
            int256 termOne = liquidationDiscountFactor.sub(riskAdjustedDiscountFactor);
            benefitDivisor = termOne.add(termTwo);
        }

        int256 fCashToLiquidate =
            c.underlyingBenefitRequired.divInRatePrecision(benefitDivisor);

        fCashToLiquidate = LiquidationHelpers.calculateLiquidationAmount(
            fCashToLiquidate,
            notional,
            maxfCashLiquidateAmount
        );

        // Ensures that local available does not go above zero and collateral available does not go below zero
        int256 localPrimeCashFromLiquidator;
        (fCashToLiquidate, localPrimeCashFromLiquidator) = _limitPurchaseByAvailableAmounts(
            c,
            liquidationDiscountFactor,
            riskAdjustedDiscountFactor,
            fCashToLiquidate
        );

        // inverse of initial fCashToLiquidate calculation above
        // totalBenefit = fCashToLiquidate * [
        //      (liquidationDiscountFactor - riskAdjustedDiscountFactor) +
        //      (liquidationDiscountFactor * (localBuffer / liquidationDiscount - collateralHaircut))
        // ]
        int256 benefitGainedUnderlying = fCashToLiquidate.mulInRatePrecision(benefitDivisor);

        c.underlyingBenefitRequired = c.underlyingBenefitRequired.sub(benefitGainedUnderlying);
        c.localPrimeCashFromLiquidator = c.localPrimeCashFromLiquidator.add(
            localPrimeCashFromLiquidator
        );

        return fCashToLiquidate;
    }

    /// @dev Limits the fCash purchase to ensure that collateral available and local available do not go below zero,
    /// in both those cases the liquidated account would incur debt
    function _limitPurchaseByAvailableAmounts(
        fCashContext memory c,
        int256 liquidationDiscountFactor,
        int256 riskAdjustedDiscountFactor,
        int256 fCashToLiquidate
    ) private pure returns (int256, int256) {
        // The collateral value of the fCash is discounted back to PV given the liquidation discount factor,
        // this is the discounted value that the liquidator will purchase it at.
        int256 fCashLiquidationUnderlyingPV = fCashToLiquidate.mulInRatePrecision(liquidationDiscountFactor);
        int256 fCashRiskAdjustedUnderlyingPV = fCashToLiquidate.mulInRatePrecision(riskAdjustedDiscountFactor);

        // Ensures that collateralAssetAvailable does not go below zero
        int256 collateralUnderlyingAvailable =
            c.factors.collateralCashGroup.primeRate.convertToUnderlying(c.factors.collateralAssetAvailable);
        if (fCashRiskAdjustedUnderlyingPV > collateralUnderlyingAvailable) {
            // If inside this if statement then all collateralAssetAvailable should be coming from fCashRiskAdjustedPV
            // collateralAssetAvailable = fCashRiskAdjustedPV
            // collateralAssetAvailable = fCashToLiquidate * riskAdjustedDiscountFactor
            // fCashToLiquidate = collateralAssetAvailable / riskAdjustedDiscountFactor
            fCashToLiquidate = collateralUnderlyingAvailable.divInRatePrecision(riskAdjustedDiscountFactor);

            fCashRiskAdjustedUnderlyingPV = collateralUnderlyingAvailable;

            // Recalculate the PV at the new liquidation amount
            fCashLiquidationUnderlyingPV = fCashToLiquidate.mulInRatePrecision(liquidationDiscountFactor);
        }

        int256 localPrimeCashFromLiquidator;
        (fCashToLiquidate, localPrimeCashFromLiquidator) = LiquidationHelpers.calculateLocalToPurchase(
            c.factors,
            c.liquidationDiscount,
            fCashLiquidationUnderlyingPV,
            fCashToLiquidate
        );

        // As we liquidate here the local available and collateral available will change. Update values accordingly so
        // that the limits will be hit on subsequent iterations.
        c.factors.collateralAssetAvailable = c.factors.collateralAssetAvailable.subNoNeg(
            c.factors.collateralCashGroup.primeRate.convertFromUnderlying(fCashRiskAdjustedUnderlyingPV)
        );
        // Cannot have a negative value here, local asset available should always increase as a result of
        // cross currency liquidation.
        require(localPrimeCashFromLiquidator >= 0);
        c.factors.localPrimeAvailable = c.factors.localPrimeAvailable.add(
            localPrimeCashFromLiquidator
        );

        return (fCashToLiquidate, localPrimeCashFromLiquidator);
    }

    /**
     * @notice Finalizes fCash liquidation for both local and cross currency liquidation.
     * @dev Since fCash liquidation only ever results in transfers of cash and fCash we
     * don't use BalanceHandler.finalize here to save some bytecode space (desperately
     * needed for this particular contract.) We use a special function just for fCash
     * liquidation to update the cash balance on the liquidated account.
     */
    function finalizefCashLiquidation(
        address liquidateAccount,
        address liquidator,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        fCashContext memory c
    ) internal returns (int256[] memory, int256) {
        Token memory token = TokenHandler.getUnderlyingToken(localCurrency);
        AccountContext memory liquidatorContext = AccountContextHandler.getAccountContext(liquidator);
        int256 netLocalFromLiquidator = c.localPrimeCashFromLiquidator;
        PrimeRate memory primeRate = PrimeRateLib.buildPrimeRateStateful(localCurrency);

        if (token.hasTransferFee && netLocalFromLiquidator > 0) {
            // If a token has a transfer fee then it must have been deposited prior to the liquidation
            // or else we won't be able to net off the correct amount. We also require that the account
            // does not have debt so that we do not have to run a free collateral check here
            require(liquidatorContext.hasDebt == 0x00, "Has debt"); // dev: token has transfer fee, no liquidator balance

            // Net off the cash balance for the liquidator. If the cash balance goes negative here then it will revert.
            BalanceHandler.setBalanceStorageForfCashLiquidation(
                liquidator,
                liquidatorContext,
                localCurrency,
                netLocalFromLiquidator.neg(),
                primeRate
            );
        } else if (netLocalFromLiquidator > 0) {
            // In any other case, do a token transfer for the liquidator (either into or out of Notional)
            // and do not credit any cash balance. That will be done just for the liquidated account.
            TokenHandler.depositExactToMintPrimeCash(
                liquidator,
                localCurrency,
                netLocalFromLiquidator,
                primeRate,
                false // ETH will be returned natively to the liquidator
            );
        } else {
            // In negative fCash liquidation, netLocalFromLiquidator < 0, meaning the liquidator is paid
            // cash and will receive it in their cash balance. This ensures that there is greater likelihood
            // of passing a free collateral check. Negative fCash liquidation is profitable from a PnL perspective
            // but will not necessarily increase the free collateral of the liquidator due to fCash discounts
            // and haircuts.
            BalanceHandler.setBalanceStorageForfCashLiquidation(
                liquidator,
                liquidatorContext,
                localCurrency,
                netLocalFromLiquidator.neg(),
                primeRate
            );
        }

        // If netLocalFromLiquidator < 0, will flip the from and to addresses
        Emitter.emitTransferPrimeCash(liquidator, liquidateAccount, localCurrency, netLocalFromLiquidator);

        BalanceHandler.setBalanceStorageForfCashLiquidation(
            liquidateAccount,
            c.accountContext,
            localCurrency,
            netLocalFromLiquidator,
            primeRate
        );

        bool liquidatorIncursDebt;
        (liquidatorIncursDebt, liquidatorContext) =
            _transferAssets(
                liquidateAccount,
                liquidator,
                liquidatorContext,
                fCashCurrency,
                fCashMaturities,
                c
            );

        emit LiquidatefCashEvent(
            liquidateAccount,
            liquidator,
            localCurrency,
            fCashCurrency,
            c.localPrimeCashFromLiquidator,
            fCashMaturities,
            c.fCashNotionalTransfers
        );

        liquidatorContext.setAccountContext(liquidator);
        c.accountContext.setAccountContext(liquidateAccount);

        // If the liquidator takes on debt as a result of the liquidation and has debt in their portfolio
        // then they must have a free collateral check. It's possible for the liquidator to skip this if the
        // negative fCash incurred from the liquidation nets off against an existing fCash position.
        if (liquidatorIncursDebt && liquidatorContext.hasDebt != 0x00) {
            FreeCollateralExternal.checkFreeCollateralAndRevert(liquidator);
        }

        return (c.fCashNotionalTransfers, c.localPrimeCashFromLiquidator);
    }

    function _transferAssets(
        address liquidateAccount,
        address liquidator,
        AccountContext memory liquidatorContext,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        fCashContext memory c
    ) private returns (bool, AccountContext memory) {
        (PortfolioAsset[] memory assets, bool liquidatorIncursDebt) =
            _makeAssetArray(fCashCurrency, fCashMaturities, c.fCashNotionalTransfers);

        (c.accountContext, liquidatorContext) = SettleAssetsExternal.transferAssets(
            liquidateAccount,
            liquidator,
            c.accountContext,
            liquidatorContext,
            assets
        );

        return (liquidatorIncursDebt, liquidatorContext);
    }

    function _makeAssetArray(
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        int256[] memory fCashNotionalTransfers
    ) private pure returns (PortfolioAsset[] memory, bool) {
        require(fCashMaturities.length == fCashNotionalTransfers.length);

        PortfolioAsset[] memory assets = new PortfolioAsset[](fCashMaturities.length);
        bool liquidatorIncursDebt = false;
        for (uint256 i = 0; i < fCashMaturities.length; i++) {
            PortfolioAsset memory asset = assets[i];
            asset.currencyId = fCashCurrency;
            asset.assetType = Constants.FCASH_ASSET_TYPE;
            asset.notional = fCashNotionalTransfers[i];
            asset.maturity = fCashMaturities[i];

            if (asset.notional < 0) liquidatorIncursDebt = true;
        }

        return (assets, liquidatorIncursDebt);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    ETHRate,
    BalanceState,
    PrimeRate,
    AccountContext,
    Token,
    PortfolioAsset,
    LiquidationFactors,
    PortfolioState
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

import {Emitter} from "../Emitter.sol";
import {AccountContextHandler} from "../AccountContextHandler.sol";
import {ExchangeRate} from "../valuation/ExchangeRate.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";
import {TokenHandler} from "../balances/TokenHandler.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {FreeCollateralExternal} from "../../external/FreeCollateralExternal.sol";

library LiquidationHelpers {
    using SafeInt256 for int256;
    using ExchangeRate for ETHRate;
    using BalanceHandler for BalanceState;
    using PrimeRateLib for PrimeRate;
    using AccountContextHandler for AccountContext;
    using TokenHandler for Token;

    /// @notice Settles accounts and returns liquidation factors for all of the liquidation actions. Also
    /// returns the account context and portfolio state post settlement. All liquidation actions will start
    /// here to get their required preconditions met.
    function preLiquidationActions(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency
    )
        internal
        returns (
            AccountContext memory,
            LiquidationFactors memory,
            PortfolioState memory
        )
    {
        // Cannot liquidate yourself
        require(msg.sender != liquidateAccount);
        require(localCurrency != 0);
        // Collateral currency must be unset or not equal to the local currency
        require(collateralCurrency != localCurrency);
        (
            AccountContext memory accountContext,
            LiquidationFactors memory factors,
            PortfolioAsset[] memory portfolio
        ) =
            FreeCollateralExternal.getLiquidationFactors(
                liquidateAccount,
                localCurrency,
                collateralCurrency
            );
        // Set the account context here to ensure that the context is up to date during
        // calculation methods
        accountContext.setAccountContext(liquidateAccount);

        PortfolioState memory portfolioState =
            PortfolioState({
                storedAssets: portfolio,
                newAssets: new PortfolioAsset[](0),
                lastNewAssetIndex: 0,
                storedAssetLength: portfolio.length
            });

        return (accountContext, factors, portfolioState);
    }

    /// @notice We allow liquidators to purchase up to Constants.DEFAULT_LIQUIDATION_PORTION percentage of collateral
    /// assets during liquidation to recollateralize an account as long as it does not also put the account
    /// further into negative free collateral (i.e. constraints on local available and collateral available).
    /// Additionally, we allow the liquidator to specify a maximum amount of collateral they would like to
    /// purchase so we also enforce that limit here.
    /// @param liquidateAmountRequired this is the amount required by liquidation to get back to positive free collateral
    /// @param maxTotalBalance the maximum total balance of the asset the account has
    /// @param userSpecifiedMaximum the maximum amount the liquidator is willing to purchase
    function calculateLiquidationAmount(
        int256 liquidateAmountRequired,
        int256 maxTotalBalance,
        int256 userSpecifiedMaximum
    ) internal pure returns (int256) {
        // By default, the liquidator is allowed to purchase at least to `defaultAllowedAmount`
        // if `liquidateAmountRequired` is less than `defaultAllowedAmount`.
        int256 defaultAllowedAmount =
            maxTotalBalance.mul(Constants.DEFAULT_LIQUIDATION_PORTION).div(
                Constants.PERCENTAGE_DECIMALS
            );

        int256 result = liquidateAmountRequired;

        // Limit the purchase amount by the max total balance, we cannot purchase
        // more than what is available.
        if (liquidateAmountRequired > maxTotalBalance) {
            result = maxTotalBalance;
        }

        // Allow the liquidator to go up to the default allowed amount which is always
        // less than the maxTotalBalance
        if (liquidateAmountRequired < defaultAllowedAmount) {
            result = defaultAllowedAmount;
        }

        if (userSpecifiedMaximum > 0 && result > userSpecifiedMaximum) {
            // Do not allow liquidation above the user specified maximum
            result = userSpecifiedMaximum;
        }

        return result;
    }

    /// @notice Calculates the amount of underlying benefit required for local currency and fCash
    /// liquidations. Uses the netETHValue converted back to local currency to maximize the benefit
    /// gained from local liquidations.
    /// @return the amount of underlying asset required
    function calculateLocalLiquidationUnderlyingRequired(
        int256 localPrimeAvailable,
        int256 netETHValue,
        ETHRate memory localETHRate
    ) internal pure returns (int256) {
            // Formula in both cases requires dividing by the haircut or buffer:
            // convertToLocal(netFCShortfallInETH) = localRequired * haircut
            // convertToLocal(netFCShortfallInETH) / haircut = localRequired
            //
            // convertToLocal(netFCShortfallInETH) = localRequired * buffer
            // convertToLocal(netFCShortfallInETH) / buffer = localRequired
            int256 multiple = localPrimeAvailable > 0 ? localETHRate.haircut : localETHRate.buffer;

            // Multiple will equal zero when the haircut is zero, in this case localAvailable > 0 but
            // liquidating a currency that is haircut to zero will have no effect on the netETHValue.
            require(multiple > 0); // dev: cannot liquidate haircut asset

            // netETHValue must be negative to be inside liquidation
            return localETHRate.convertETHTo(netETHValue.neg())
                    .mul(Constants.PERCENTAGE_DECIMALS)
                    .div(multiple);
    }

    /// @dev Calculates factors when liquidating across two currencies
    function calculateCrossCurrencyFactors(LiquidationFactors memory factors)
        internal
        pure
        returns (int256 collateralDenominatedFC, int256 liquidationDiscount)
    {
        collateralDenominatedFC = factors.collateralCashGroup.primeRate.convertFromUnderlying(
            factors
                .collateralETHRate
                // netETHValue must be negative to be in liquidation
                .convertETHTo(factors.netETHValue.neg())
        );

        liquidationDiscount = SafeInt256.max(
            factors.collateralETHRate.liquidationDiscount,
            factors.localETHRate.liquidationDiscount
        );
    }

    /// @notice Calculates the local to purchase in cross currency liquidations. Ensures that local to purchase
    /// is not so large that the account is put further into debt.
    /// @return
    ///     collateralBalanceToSell: the amount of collateral balance to be sold to the liquidator (it can either
    ///     be asset cash in the case of currency liquidations or fcash in the case of cross currency fcash liquidation,
    ///     this is scaled by a unitless proportion in the method).
    ///     localAssetFromLiquidator: the amount of asset cash from the liquidator
    function calculateLocalToPurchase(
        LiquidationFactors memory factors,
        int256 liquidationDiscount,
        int256 collateralUnderlyingPresentValue,
        int256 collateralBalanceToSell
    ) internal pure returns (int256, int256) {
        // Converts collateral present value to the local amount along with the liquidation discount.
        // localPurchased = collateralToSell / (exchangeRate * liquidationDiscount)
        int256 localUnderlyingFromLiquidator =
            collateralUnderlyingPresentValue
                .mul(Constants.PERCENTAGE_DECIMALS)
                .mul(factors.localETHRate.rateDecimals)
                .div(ExchangeRate.exchangeRate(factors.localETHRate, factors.collateralETHRate))
                .div(liquidationDiscount);

        int256 localAssetFromLiquidator =
            factors.localPrimeRate.convertFromUnderlying(localUnderlyingFromLiquidator);
        // localPrimeAvailable must be negative in cross currency liquidations
        int256 maxLocalAsset = factors.localPrimeAvailable.neg();

        if (localAssetFromLiquidator > maxLocalAsset) {
            // If the local to purchase will flip the sign of localPrimeAvailable then the calculations
            // for the collateral purchase amounts will be thrown off. The positive portion of localPrimeAvailable
            // has to have a haircut applied. If this haircut reduces the localPrimeAvailable value below
            // the collateralAssetValue then this may actually decrease overall free collateral.
            collateralBalanceToSell = collateralBalanceToSell
                .mul(maxLocalAsset)
                .div(localAssetFromLiquidator);

            localAssetFromLiquidator = maxLocalAsset;
        }

        return (collateralBalanceToSell, localAssetFromLiquidator);
    }

    function finalizeLiquidatorLocal(
        address liquidator,
        address liquidateAccount,
        uint16 localCurrencyId,
        int256 netLocalFromLiquidator,
        int256 netLocalNTokens
    ) internal returns (AccountContext memory) {
        // Liquidator must deposit netLocalFromLiquidator, in the case of a repo discount then the
        // liquidator will receive some positive amount
        Token memory token = TokenHandler.getUnderlyingToken(localCurrencyId);
        AccountContext memory liquidatorContext =
            AccountContextHandler.getAccountContext(liquidator);
        BalanceState memory liquidatorLocalBalance;
        liquidatorLocalBalance.loadBalanceState(liquidator, localCurrencyId, liquidatorContext);
        // netLocalFromLiquidator is always positive. Liquidity token liquidation allows for a negative
        // netLocalFromLiquidator, but we do not allow regular accounts to hold liquidity tokens so those
        // liquidations are not possible.
        require(netLocalFromLiquidator > 0);

        if (token.hasTransferFee) {
            // If a token has a transfer fee then it must have been deposited prior to the liquidation
            // or else we won't be able to net off the correct amount. We also require that the account
            // does not have debt so that we do not have to run a free collateral check here
            require(
                liquidatorLocalBalance.storedCashBalance >= netLocalFromLiquidator &&
                    liquidatorContext.hasDebt == 0x00,
                "No cash"
            ); // dev: token has transfer fee, no liquidator balance
            liquidatorLocalBalance.netCashChange = netLocalFromLiquidator.neg();
        } else {
            TokenHandler.depositExactToMintPrimeCash(
                liquidator,
                localCurrencyId,
                netLocalFromLiquidator,
                liquidatorLocalBalance.primeRate,
                false // excess ETH is returned to liquidator natively
            );
        }

        Emitter.emitTransferPrimeCash(liquidator, liquidateAccount, localCurrencyId, netLocalFromLiquidator);
        if (netLocalNTokens > 0) Emitter.emitTransferNToken(liquidateAccount, liquidator, localCurrencyId, netLocalNTokens);

        liquidatorLocalBalance.netNTokenTransfer = netLocalNTokens;
        liquidatorLocalBalance.finalizeNoWithdraw(liquidator, liquidatorContext);

        return liquidatorContext;
    }

    function finalizeLiquidatorCollateral(
        address liquidator,
        AccountContext memory liquidatorContext,
        address liquidateAccount,
        uint16 collateralCurrencyId,
        int256 netCollateralToLiquidator,
        int256 netCollateralNTokens,
        bool withdrawCollateral,
        bool redeemToUnderlying
    ) internal returns (AccountContext memory) {
        require(redeemToUnderlying, "Deprecated: Redeem to cToken");
        BalanceState memory balance;
        balance.loadBalanceState(liquidator, collateralCurrencyId, liquidatorContext);
        balance.netCashChange = netCollateralToLiquidator;

        if (netCollateralToLiquidator != 0) Emitter.emitTransferPrimeCash(liquidateAccount, liquidator, collateralCurrencyId, netCollateralToLiquidator);
        if (netCollateralNTokens != 0) Emitter.emitTransferNToken(liquidateAccount, liquidator, collateralCurrencyId, netCollateralNTokens);

        if (withdrawCollateral) {
            // This will net off the cash balance
            balance.primeCashWithdraw = netCollateralToLiquidator.neg();
        }

        balance.netNTokenTransfer = netCollateralNTokens;
        // Liquidator will always receive native ETH
        balance.finalizeWithWithdraw(liquidator, liquidatorContext, false);

        return liquidatorContext;
    }

    function finalizeLiquidatedLocalBalance(
        address liquidateAccount,
        uint16 localCurrency,
        AccountContext memory accountContext,
        int256 netLocalFromLiquidator
    ) internal {
        BalanceState memory balance;
        balance.loadBalanceState(liquidateAccount, localCurrency, accountContext);
        balance.netCashChange = netLocalFromLiquidator;
        balance.finalizeNoWithdraw(liquidateAccount, accountContext);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    CashGroupParameters,
    CashGroupSettings,
    MarketParameters,
    PrimeRate
} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";

import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {PrimeCashExchangeRate} from "../pCash/PrimeCashExchangeRate.sol";
import {Market} from "./Market.sol";
import {DateTime} from "./DateTime.sol";

library CashGroup {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;
    using Market for MarketParameters;

    // Bit number references for each parameter in the 32 byte word (0-indexed)
    uint256 private constant MARKET_INDEX_BIT = 31;
    uint256 private constant RATE_ORACLE_TIME_WINDOW_BIT = 30;
    uint256 private constant MAX_DISCOUNT_FACTOR_BIT = 29;
    uint256 private constant RESERVE_FEE_SHARE_BIT = 28;
    uint256 private constant DEBT_BUFFER_BIT = 27;
    uint256 private constant FCASH_HAIRCUT_BIT = 26;
    uint256 private constant MIN_ORACLE_RATE_BIT = 25;
    uint256 private constant LIQUIDATION_FCASH_HAIRCUT_BIT = 24;
    uint256 private constant LIQUIDATION_DEBT_BUFFER_BIT = 23;
    uint256 private constant MAX_ORACLE_RATE_BIT = 22;

    // Offsets for the bytes of the different parameters
    uint256 private constant MARKET_INDEX = (31 - MARKET_INDEX_BIT) * 8;
    uint256 private constant RATE_ORACLE_TIME_WINDOW = (31 - RATE_ORACLE_TIME_WINDOW_BIT) * 8;
    uint256 private constant MAX_DISCOUNT_FACTOR = (31 - MAX_DISCOUNT_FACTOR_BIT) * 8;
    uint256 private constant RESERVE_FEE_SHARE = (31 - RESERVE_FEE_SHARE_BIT) * 8;
    uint256 private constant DEBT_BUFFER = (31 - DEBT_BUFFER_BIT) * 8;
    uint256 private constant FCASH_HAIRCUT = (31 - FCASH_HAIRCUT_BIT) * 8;
    uint256 private constant MIN_ORACLE_RATE = (31 - MIN_ORACLE_RATE_BIT) * 8;
    uint256 private constant LIQUIDATION_FCASH_HAIRCUT = (31 - LIQUIDATION_FCASH_HAIRCUT_BIT) * 8;
    uint256 private constant LIQUIDATION_DEBT_BUFFER = (31 - LIQUIDATION_DEBT_BUFFER_BIT) * 8;
    uint256 private constant MAX_ORACLE_RATE = (31 - MAX_ORACLE_RATE_BIT) * 8;

    function _get25BPSValue(CashGroupParameters memory cashGroup, uint256 offset) private pure returns (uint256) {
        return uint256(uint8(uint256(cashGroup.data >> offset))) * Constants.TWENTY_FIVE_BASIS_POINTS;
    }

    function getMinOracleRate(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return _get25BPSValue(cashGroup, MIN_ORACLE_RATE);
    }

    function getMaxOracleRate(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return _get25BPSValue(cashGroup, MAX_ORACLE_RATE);
    }

    /// @notice fCash haircut for valuation denominated in rate precision with five basis point increments
    function getfCashHaircut(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return _get25BPSValue(cashGroup, FCASH_HAIRCUT);
    }

    /// @notice fCash debt buffer for valuation denominated in rate precision with five basis point increments
    function getDebtBuffer(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return _get25BPSValue(cashGroup, DEBT_BUFFER);
    }

    /// @notice Haircut for positive fCash during liquidation denominated rate precision
    function getLiquidationfCashHaircut(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return _get25BPSValue(cashGroup, LIQUIDATION_FCASH_HAIRCUT);
    }

    /// @notice Haircut for negative fCash during liquidation denominated rate precision
    function getLiquidationDebtBuffer(CashGroupParameters memory cashGroup) internal pure returns (uint256) {
        return _get25BPSValue(cashGroup, LIQUIDATION_DEBT_BUFFER);
    }

    function getMaxDiscountFactor(CashGroupParameters memory cashGroup)
        internal pure returns (int256)
    {
        uint256 maxDiscountFactor = uint256(uint8(uint256(cashGroup.data >> MAX_DISCOUNT_FACTOR))) * Constants.FIVE_BASIS_POINTS;
        // Overflow/Underflow is not possible due to storage size limits
        return Constants.RATE_PRECISION - int256(maxDiscountFactor);
    }

    /// @notice Percentage of the total trading fee that goes to the reserve
    function getReserveFeeShare(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (int256)
    {
        return uint8(uint256(cashGroup.data >> RESERVE_FEE_SHARE));
    }

    /// @notice Time window factor for the rate oracle denominated in seconds with five minute increments.
    function getRateOracleTimeWindow(CashGroupParameters memory cashGroup)
        internal
        pure
        returns (uint256)
    {
        // This is denominated in 5 minute increments in storage
        return uint256(uint8(uint256(cashGroup.data >> RATE_ORACLE_TIME_WINDOW))) * Constants.FIVE_MINUTES;
    }

    function loadMarket(
        CashGroupParameters memory cashGroup,
        MarketParameters memory market,
        uint256 marketIndex,
        bool needsLiquidity,
        uint256 blockTime
    ) internal view {
        require(1 <= marketIndex && marketIndex <= cashGroup.maxMarketIndex, "Invalid market");
        uint256 maturity =
            DateTime.getReferenceTime(blockTime).add(DateTime.getTradedMarket(marketIndex));

        market.loadMarket(
            cashGroup.currencyId,
            maturity,
            blockTime,
            needsLiquidity,
            getRateOracleTimeWindow(cashGroup)
        );
    }

    /// @notice Returns the linear interpolation between two market rates. The formula is
    /// slope = (longMarket.oracleRate - shortMarket.oracleRate) / (longMarket.maturity - shortMarket.maturity)
    /// interpolatedRate = slope * (assetMaturity - shortMarket.maturity) + shortMarket.oracleRate
    function interpolateOracleRate(
        uint256 shortMaturity,
        uint256 longMaturity,
        uint256 shortRate,
        uint256 longRate,
        uint256 assetMaturity
    ) internal pure returns (uint256) {
        require(shortMaturity < assetMaturity); // dev: cash group interpolation error, short maturity
        require(assetMaturity < longMaturity); // dev: cash group interpolation error, long maturity

        // It's possible that the rates are inverted where the short market rate > long market rate and
        // we will get an underflow here so we check for that
        if (longRate >= shortRate) {
            return
                (longRate - shortRate)
                    .mul(assetMaturity - shortMaturity)
                // No underflow here, checked above
                    .div(longMaturity - shortMaturity)
                    .add(shortRate);
        } else {
            // In this case the slope is negative so:
            // interpolatedRate = shortMarket.oracleRate - slope * (assetMaturity - shortMarket.maturity)
            // NOTE: this subtraction should never overflow, the linear interpolation between two points above zero
            // cannot go below zero
            return
                shortRate.sub(
                    // This is reversed to keep it it positive
                    (shortRate - longRate)
                        .mul(assetMaturity - shortMaturity)
                    // No underflow here, checked above
                        .div(longMaturity - shortMaturity)
                );
        }
    }

    function calculateRiskAdjustedfCashOracleRate(
        CashGroupParameters memory cashGroup,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (uint256 oracleRate) {
        oracleRate = calculateOracleRate(cashGroup, maturity, blockTime);

        oracleRate = oracleRate.add(getfCashHaircut(cashGroup));
        uint256 minOracleRate = getMinOracleRate(cashGroup);

        if (oracleRate < minOracleRate) oracleRate = minOracleRate;
    }

    function calculateRiskAdjustedDebtOracleRate(
        CashGroupParameters memory cashGroup,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (uint256 oracleRate) {
        oracleRate = calculateOracleRate(cashGroup, maturity, blockTime);

        uint256 debtBuffer = getDebtBuffer(cashGroup);
        // If the adjustment exceeds the oracle rate we floor the oracle rate at zero,
        // We don't want to require the account to hold more than absolutely required.
        if (oracleRate <= debtBuffer) return 0;

        oracleRate = oracleRate - debtBuffer;
        uint256 maxOracleRate = getMaxOracleRate(cashGroup);

        if (maxOracleRate < oracleRate) oracleRate = maxOracleRate;
    }
    
    function calculateOracleRate(
        CashGroupParameters memory cashGroup,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (uint256 oracleRate) {
        (uint256 marketIndex, bool idiosyncratic) =
            DateTime.getMarketIndex(cashGroup.maxMarketIndex, maturity, blockTime);
        uint256 timeWindow = getRateOracleTimeWindow(cashGroup);

        if (!idiosyncratic) {
            oracleRate = Market.getOracleRate(cashGroup.currencyId, maturity, timeWindow, blockTime);
        } else {
            uint256 referenceTime = DateTime.getReferenceTime(blockTime);
            // DateTime.getMarketIndex returns the market that is past the maturity if idiosyncratic
            uint256 longMaturity = referenceTime.add(DateTime.getTradedMarket(marketIndex));
            uint256 longRate =
                Market.getOracleRate(cashGroup.currencyId, longMaturity, timeWindow, blockTime);

            uint256 shortRate;
            uint256 shortMaturity;
            if (marketIndex == 1) {
                // In this case the short market is the annualized asset supply rate
                shortMaturity = blockTime;
                shortRate = cashGroup.primeRate.oracleSupplyRate;
            } else {
                // Minimum value for marketIndex here is 2
                shortMaturity = referenceTime.add(DateTime.getTradedMarket(marketIndex - 1));

                shortRate = Market.getOracleRate(
                    cashGroup.currencyId,
                    shortMaturity,
                    timeWindow,
                    blockTime
                );
            }

            oracleRate = interpolateOracleRate(shortMaturity, longMaturity, shortRate, longRate, maturity);
        }
    }

    function _getCashGroupStorageBytes(uint256 currencyId) private view returns (bytes32 data) {
        mapping(uint256 => bytes32) storage store = LibStorage.getCashGroupStorage();
        return store[currencyId];
    }

    /// @dev Helper method for validating maturities in ERC1155Action
    function getMaxMarketIndex(uint256 currencyId) internal view returns (uint8) {
        bytes32 data = _getCashGroupStorageBytes(currencyId);
        return uint8(data[MARKET_INDEX_BIT]);
    }

    /// @notice Checks all cash group settings for invalid values and sets them into storage
    function setCashGroupStorage(uint256 currencyId, CashGroupSettings memory cashGroup)
        internal
    {
        // Due to the requirements of the yield curve we do not allow a cash group to have solely a 3 month market.
        // The reason is that borrowers will not have a further maturity to roll from their 3 month fixed to a 6 month
        // fixed. It also complicates the logic in the nToken initialization method. Additionally, we cannot have cash
        // groups with 0 market index, it has no effect.
        require(2 <= cashGroup.maxMarketIndex && cashGroup.maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX);
        require(cashGroup.reserveFeeShare <= Constants.PERCENTAGE_DECIMALS);
        // Max discount factor must be set to a non-zero value
        require(0 < cashGroup.maxDiscountFactor5BPS);
        require(cashGroup.minOracleRate25BPS < cashGroup.maxOracleRate25BPS);
        // This is required so that fCash liquidation can proceed correctly
        require(cashGroup.liquidationfCashHaircut25BPS < cashGroup.fCashHaircut25BPS);
        require(cashGroup.liquidationDebtBuffer25BPS < cashGroup.debtBuffer25BPS);

        // Market indexes cannot decrease or they will leave fCash assets stranded in the future with no valuation curve
        uint8 previousMaxMarketIndex = getMaxMarketIndex(currencyId);
        require(previousMaxMarketIndex <= cashGroup.maxMarketIndex);

        // Per cash group settings
        bytes32 data =
            (bytes32(uint256(cashGroup.maxMarketIndex)) |
                (bytes32(uint256(cashGroup.rateOracleTimeWindow5Min)) << RATE_ORACLE_TIME_WINDOW) |
                (bytes32(uint256(cashGroup.maxDiscountFactor5BPS)) << MAX_DISCOUNT_FACTOR) |
                (bytes32(uint256(cashGroup.reserveFeeShare)) << RESERVE_FEE_SHARE) |
                (bytes32(uint256(cashGroup.debtBuffer25BPS)) << DEBT_BUFFER) |
                (bytes32(uint256(cashGroup.fCashHaircut25BPS)) << FCASH_HAIRCUT) |
                (bytes32(uint256(cashGroup.minOracleRate25BPS)) << MIN_ORACLE_RATE) |
                (bytes32(uint256(cashGroup.liquidationfCashHaircut25BPS)) << LIQUIDATION_FCASH_HAIRCUT) |
                (bytes32(uint256(cashGroup.liquidationDebtBuffer25BPS)) << LIQUIDATION_DEBT_BUFFER) |
                (bytes32(uint256(cashGroup.maxOracleRate25BPS)) << MAX_ORACLE_RATE)
        );

        mapping(uint256 => bytes32) storage store = LibStorage.getCashGroupStorage();
        store[currencyId] = data;
    }

    /// @notice Deserialize the cash group storage bytes into a user friendly object
    function deserializeCashGroupStorage(uint256 currencyId)
        internal
        view
        returns (CashGroupSettings memory)
    {
        bytes32 data = _getCashGroupStorageBytes(currencyId);
        uint8 maxMarketIndex = uint8(data[MARKET_INDEX_BIT]);

        return
            CashGroupSettings({
                maxMarketIndex: maxMarketIndex,
                rateOracleTimeWindow5Min: uint8(data[RATE_ORACLE_TIME_WINDOW_BIT]),
                maxDiscountFactor5BPS: uint8(data[MAX_DISCOUNT_FACTOR_BIT]),
                reserveFeeShare: uint8(data[RESERVE_FEE_SHARE_BIT]),
                debtBuffer25BPS: uint8(data[DEBT_BUFFER_BIT]),
                fCashHaircut25BPS: uint8(data[FCASH_HAIRCUT_BIT]),
                minOracleRate25BPS: uint8(data[MIN_ORACLE_RATE_BIT]),
                liquidationfCashHaircut25BPS: uint8(data[LIQUIDATION_FCASH_HAIRCUT_BIT]),
                liquidationDebtBuffer25BPS: uint8(data[LIQUIDATION_DEBT_BUFFER_BIT]),
                maxOracleRate25BPS: uint8(data[MAX_ORACLE_RATE_BIT])
            });
    }

    function buildCashGroup(uint16 currencyId, PrimeRate memory primeRate)
        internal view returns (CashGroupParameters memory) 
    {
        bytes32 data = _getCashGroupStorageBytes(currencyId);
        uint256 maxMarketIndex = uint8(data[MARKET_INDEX_BIT]);

        return
            CashGroupParameters({
                currencyId: currencyId,
                maxMarketIndex: maxMarketIndex,
                primeRate: primeRate,
                data: data
            });
    }

    /// @notice Builds a cash group using a view version of the asset rate
    function buildCashGroupView(uint16 currencyId)
        internal
        view
        returns (CashGroupParameters memory)
    {
        (PrimeRate memory primeRate, /* */) = PrimeCashExchangeRate.getPrimeCashRateView(currencyId, block.timestamp);
        return buildCashGroup(currencyId, primeRate);
    }

    /// @notice Builds a cash group using a stateful version of the asset rate
    function buildCashGroupStateful(uint16 currencyId)
        internal
        returns (CashGroupParameters memory)
    {
        PrimeRate memory primeRate = PrimeRateLib.buildPrimeRateStateful(currencyId);
        return buildCashGroup(currencyId, primeRate);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {Constants} from "../../global/Constants.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";

library DateTime {
    using SafeUint256 for uint256;

    /// @notice Returns the current reference time which is how all the AMM dates are calculated.
    function getReferenceTime(uint256 blockTime) internal pure returns (uint256) {
        require(blockTime >= Constants.QUARTER);
        return blockTime - (blockTime % Constants.QUARTER);
    }

    /// @notice Truncates a date to midnight UTC time
    function getTimeUTC0(uint256 time) internal pure returns (uint256) {
        require(time >= Constants.DAY);
        return time - (time % Constants.DAY);
    }

    /// @notice These are the predetermined market offsets for trading
    /// @dev Markets are 1-indexed because the 0 index means that no markets are listed for the cash group.
    function getTradedMarket(uint256 index) internal pure returns (uint256) {
        if (index == 1) return Constants.QUARTER;
        if (index == 2) return 2 * Constants.QUARTER;
        if (index == 3) return Constants.YEAR;
        if (index == 4) return 2 * Constants.YEAR;
        if (index == 5) return 5 * Constants.YEAR;
        if (index == 6) return 10 * Constants.YEAR;
        if (index == 7) return 20 * Constants.YEAR;

        revert("Invalid index");
    }

    /// @notice Determines if the maturity falls on one of the valid on chain market dates.
    function isValidMarketMaturity(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (bool) {
        require(maxMarketIndex > 0, "CG: no markets listed");
        require(maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX, "CG: market index bound");

        if (maturity % Constants.QUARTER != 0) return false;
        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            if (maturity == tRef.add(DateTime.getTradedMarket(i))) return true;
        }

        return false;
    }

    /// @notice Determines if an idiosyncratic maturity is valid and returns the bit reference that is the case.
    function isValidMaturity(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (bool) {
        uint256 tRef = DateTime.getReferenceTime(blockTime);
        uint256 maxMaturity = tRef.add(DateTime.getTradedMarket(maxMarketIndex));
        // Cannot trade past max maturity
        if (maturity > maxMaturity) return false;

        // prettier-ignore
        (/* */, bool isValid) = DateTime.getBitNumFromMaturity(blockTime, maturity);
        return isValid;
    }

    /// @notice Returns the market index for a given maturity, if the maturity is idiosyncratic
    /// will return the nearest market index that is larger than the maturity.
    /// @return uint marketIndex, bool isIdiosyncratic
    function getMarketIndex(
        uint256 maxMarketIndex,
        uint256 maturity,
        uint256 blockTime
    ) internal pure returns (uint256, bool) {
        require(maxMarketIndex > 0);
        require(maxMarketIndex <= Constants.MAX_TRADED_MARKET_INDEX);
        uint256 tRef = DateTime.getReferenceTime(blockTime);

        for (uint256 i = 1; i <= maxMarketIndex; i++) {
            uint256 marketMaturity = tRef.add(DateTime.getTradedMarket(i));
            // If market matches then is not idiosyncratic
            if (marketMaturity == maturity) return (i, false);
            // Returns the market that is immediately greater than the maturity
            if (marketMaturity > maturity) return (i, true);
        }

        revert();
    }

    /// @notice Given a bit number and the reference time of the first bit, returns the bit number
    /// of a given maturity.
    /// @return bitNum and a true or false if the maturity falls on the exact bit
    function getBitNumFromMaturity(uint256 blockTime, uint256 maturity)
        internal
        pure
        returns (uint256, bool)
    {
        uint256 blockTimeUTC0 = getTimeUTC0(blockTime);

        // Maturities must always divide days evenly
        if (maturity % Constants.DAY != 0) return (0, false);
        // Maturity cannot be in the past
        if (blockTimeUTC0 >= maturity) return (0, false);

        // Overflow check done above
        // daysOffset has no remainders, checked above
        uint256 daysOffset = (maturity - blockTimeUTC0) / Constants.DAY;

        // These if statements need to fall through to the next one
        if (daysOffset <= Constants.MAX_DAY_OFFSET) {
            return (daysOffset, true);
        } else if (daysOffset <= Constants.MAX_WEEK_OFFSET) {
            // (daysOffset - MAX_DAY_OFFSET) is the days overflow into the week portion, must be > 0
            // (blockTimeUTC0 % WEEK) / DAY is the offset into the week portion
            // This returns the offset from the previous max offset in days
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_DAY_OFFSET +
                    (blockTimeUTC0 % Constants.WEEK) /
                    Constants.DAY;
            
            return (
                // This converts the offset in days to its corresponding bit position, truncating down
                // if it does not divide evenly into DAYS_IN_WEEK
                Constants.WEEK_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_WEEK,
                (offsetInDays % Constants.DAYS_IN_WEEK) == 0
            );
        } else if (daysOffset <= Constants.MAX_MONTH_OFFSET) {
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_WEEK_OFFSET +
                    (blockTimeUTC0 % Constants.MONTH) /
                    Constants.DAY;

            return (
                Constants.MONTH_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_MONTH,
                (offsetInDays % Constants.DAYS_IN_MONTH) == 0
            );
        } else if (daysOffset <= Constants.MAX_QUARTER_OFFSET) {
            uint256 offsetInDays =
                daysOffset -
                    Constants.MAX_MONTH_OFFSET +
                    (blockTimeUTC0 % Constants.QUARTER) /
                    Constants.DAY;

            return (
                Constants.QUARTER_BIT_OFFSET + offsetInDays / Constants.DAYS_IN_QUARTER,
                (offsetInDays % Constants.DAYS_IN_QUARTER) == 0
            );
        }

        // This is the maximum 1-indexed bit num, it is never valid because it is beyond the 20
        // year max maturity
        return (256, false);
    }

    /// @notice Given a bit number and a block time returns the maturity that the bit number
    /// should reference. Bit numbers are one indexed.
    function getMaturityFromBitNum(uint256 blockTime, uint256 bitNum)
        internal
        pure
        returns (uint256)
    {
        require(bitNum != 0); // dev: cash group get maturity from bit num is zero
        require(bitNum <= 256); // dev: cash group get maturity from bit num overflow
        uint256 blockTimeUTC0 = getTimeUTC0(blockTime);
        uint256 firstBit;

        if (bitNum <= Constants.WEEK_BIT_OFFSET) {
            return blockTimeUTC0 + bitNum * Constants.DAY;
        } else if (bitNum <= Constants.MONTH_BIT_OFFSET) {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_DAY_OFFSET * Constants.DAY -
                // This backs up to the day that is divisible by a week
                (blockTimeUTC0 % Constants.WEEK);
            return firstBit + (bitNum - Constants.WEEK_BIT_OFFSET) * Constants.WEEK;
        } else if (bitNum <= Constants.QUARTER_BIT_OFFSET) {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_WEEK_OFFSET * Constants.DAY -
                (blockTimeUTC0 % Constants.MONTH);
            return firstBit + (bitNum - Constants.MONTH_BIT_OFFSET) * Constants.MONTH;
        } else {
            firstBit =
                blockTimeUTC0 +
                Constants.MAX_MONTH_OFFSET * Constants.DAY -
                (blockTimeUTC0 % Constants.QUARTER);
            return firstBit + (bitNum - Constants.QUARTER_BIT_OFFSET) * Constants.QUARTER;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {LibStorage} from "../../global/LibStorage.sol";
import {
    InterestRateCurveSettings,
    InterestRateParameters,
    CashGroupParameters,
    MarketParameters,
    PrimeRate
} from "../../global/Types.sol";
import {CashGroup} from "./CashGroup.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {ABDKMath64x64} from "../../math/ABDKMath64x64.sol";

library InterestRateCurve {
    using SafeInt256 for int256;
    using SafeUint256 for uint256;
    using CashGroup for CashGroupParameters;
    using PrimeRateLib for PrimeRate;

    uint8 private constant PRIME_CASH_OFFSET = 0;
    uint8 private constant PRIME_CASH_SHIFT = 192;

    uint256 private constant KINK_UTILIZATION_1_BYTE = 0;
    uint256 private constant KINK_UTILIZATION_2_BYTE = 1;
    uint256 private constant MAX_RATE_BYTE           = 2;
    uint256 private constant KINK_RATE_1_BYTE        = 3;
    uint256 private constant KINK_RATE_2_BYTE        = 4;
    uint256 private constant MIN_FEE_RATE_BYTE       = 5;
    uint256 private constant MAX_FEE_RATE_BYTE       = 6;
    uint256 private constant FEE_RATE_PERCENT_BYTE   = 7;

    uint256 private constant KINK_UTILIZATION_1_BIT = KINK_UTILIZATION_1_BYTE * 8;
    uint256 private constant KINK_UTILIZATION_2_BIT = KINK_UTILIZATION_2_BYTE * 8;
    uint256 private constant MAX_RATE_BIT           = MAX_RATE_BYTE * 8;
    uint256 private constant KINK_RATE_1_BIT        = KINK_RATE_1_BYTE * 8;
    uint256 private constant KINK_RATE_2_BIT        = KINK_RATE_2_BYTE * 8;
    uint256 private constant MIN_FEE_RATE_BIT       = MIN_FEE_RATE_BYTE * 8;
    uint256 private constant MAX_FEE_RATE_BIT       = MAX_FEE_RATE_BYTE * 8;
    uint256 private constant FEE_RATE_PERCENT_BIT   = FEE_RATE_PERCENT_BYTE * 8;

    /// @notice Returns the marketIndex byte offset.
    /// @dev marketIndex = 0 is unused for fCash markets (they are 1-indexed). In the storage
    /// slot the marketIndex = 0 space is reserved for the prime cash borrow curve
    function _getMarketIndexOffset(uint256 marketIndex) private pure returns (uint8 offset) {
        require(0 < marketIndex);
        require(marketIndex <= Constants.MAX_TRADED_MARKET_INDEX);
        offset = uint8(marketIndex < 4 ? marketIndex : marketIndex - 4) * 8;
    }

    function _getfCashInterestRateParams(
        uint16 currencyId,
        uint256 marketIndex,
        mapping(uint256 => bytes32[2]) storage store
    ) private view returns (InterestRateParameters memory i) {
        uint8 offset = _getMarketIndexOffset(marketIndex);
        bytes32 data = store[currencyId][marketIndex < 4 ? 0 : 1];
        return unpackInterestRateParams(offset, data);
    }

    function calculateMaxRate(uint8 maxRateByte) internal pure returns (uint256) {
        // Max rate values are in 25 bps increments up to 150 units. Above 150 they are in 150 bps
        // increments. This results in a max rate of 195%. This allows more precision at lower max
        // rate values and a higher range for large max rate values.
        return Constants.MAX_LOWER_INCREMENT < maxRateByte ?
            (Constants.MAX_LOWER_INCREMENT_VALUE +
                (maxRateByte - Constants.MAX_LOWER_INCREMENT) * Constants.ONE_HUNDRED_FIFTY_BASIS_POINTS) :
            maxRateByte * Constants.TWENTY_FIVE_BASIS_POINTS;
    }

    function unpackInterestRateParams(
        uint8 offset,
        bytes32 data
    ) internal pure returns (InterestRateParameters memory i) {
        // Kink utilization is stored as a value less than 100 and on the stack it is
        // in RATE_PRECISION where RATE_PRECISION = 100
        i.kinkUtilization1 = uint256(uint8(data[offset + KINK_UTILIZATION_1_BYTE])) * uint256(Constants.RATE_PRECISION)
            / uint256(Constants.PERCENTAGE_DECIMALS);
        i.kinkUtilization2 = uint256(uint8(data[offset + KINK_UTILIZATION_2_BYTE])) * uint256(Constants.RATE_PRECISION)
            / uint256(Constants.PERCENTAGE_DECIMALS);
        i.maxRate = calculateMaxRate(uint8(data[offset + MAX_RATE_BYTE]));
        // Kink Rates are stored as 1/256 increments of maxRate, this allows governance
        // to set more precise kink rates relative to how how interest rates can go
        i.kinkRate1 = uint256(uint8(data[offset + KINK_RATE_1_BYTE])) * i.maxRate / 256;
        i.kinkRate2 = uint256(uint8(data[offset + KINK_RATE_2_BYTE])) * i.maxRate / 256;

        // Fee rates are stored in basis points
        i.minFeeRate = uint256(uint8(data[offset + MIN_FEE_RATE_BYTE])) * uint256(Constants.FIVE_BASIS_POINTS);
        i.maxFeeRate = uint256(uint8(data[offset + MAX_FEE_RATE_BYTE])) * uint256(Constants.TWENTY_FIVE_BASIS_POINTS);
        i.feeRatePercent = uint256(uint8(data[offset + FEE_RATE_PERCENT_BYTE]));
    }

    function packInterestRateParams(InterestRateCurveSettings memory settings) internal pure returns (bytes32) {
        require(settings.kinkUtilization1 < settings.kinkUtilization2);
        require(settings.kinkUtilization2 <= 100);
        require(settings.kinkRate1 < settings.kinkRate2);
        require(settings.minFeeRate5BPS * Constants.FIVE_BASIS_POINTS <= settings.maxFeeRate25BPS * Constants.TWENTY_FIVE_BASIS_POINTS);
        require(settings.feeRatePercent < 100);

        return (
            bytes32(uint256(settings.kinkUtilization1)) << 56 - KINK_UTILIZATION_1_BIT |
            bytes32(uint256(settings.kinkUtilization2)) << 56 - KINK_UTILIZATION_2_BIT |
            bytes32(uint256(settings.maxRateUnits))     << 56 - MAX_RATE_BIT           |
            bytes32(uint256(settings.kinkRate1))        << 56 - KINK_RATE_1_BIT        |
            bytes32(uint256(settings.kinkRate2))        << 56 - KINK_RATE_2_BIT        |
            bytes32(uint256(settings.minFeeRate5BPS))   << 56 - MIN_FEE_RATE_BIT       |
            bytes32(uint256(settings.maxFeeRate25BPS))  << 56 - MAX_FEE_RATE_BIT       |
            bytes32(uint256(settings.feeRatePercent))   << 56 - FEE_RATE_PERCENT_BIT
        );
    }

    function _setInterestRateParameters(
        bytes32 data,
        uint8 offset,
        InterestRateCurveSettings memory settings
    ) internal pure returns (bytes32) {
        // Does checks against interest rate params inside
        bytes32 packedSettings = packInterestRateParams(settings);
        packedSettings = (packedSettings << offset);

        // Use the mask to clear the previous settings
        bytes32 mask = ~(bytes32(uint256(type(uint64).max)) << offset);
        return (data & mask) | packedSettings;
    }

    function setNextInterestRateParameters(
        uint16 currencyId,
        uint256 marketIndex,
        InterestRateCurveSettings memory settings
    ) internal {
        bytes32[2] storage nextStorage = LibStorage.getNextInterestRateParameters()[currencyId];
        // 256 - 64 bits puts the offset at 192 bits (64 bits is how wide each set of interest
        // rate parameters is)
        uint8 shift = PRIME_CASH_SHIFT - _getMarketIndexOffset(marketIndex) * 8;
        uint8 slot = marketIndex < 4 ? 0 : 1;

        nextStorage[slot] = _setInterestRateParameters(nextStorage[slot], shift, settings);
    }

    function getActiveInterestRateParameters(
        uint16 currencyId,
        uint256 marketIndex
    ) internal view returns (InterestRateParameters memory i) {
        return _getfCashInterestRateParams(
            currencyId,
            marketIndex,
            LibStorage.getActiveInterestRateParameters()
        );
    }

    function getNextInterestRateParameters(
        uint16 currencyId,
        uint256 marketIndex
    ) internal view returns (InterestRateParameters memory i) {
        return _getfCashInterestRateParams(
            currencyId,
            marketIndex,
            LibStorage.getNextInterestRateParameters()
        );
    }

    function getPrimeCashInterestRateParameters(
        uint16 currencyId
    ) internal view returns (InterestRateParameters memory i) {
        bytes32 data = LibStorage.getActiveInterestRateParameters()[currencyId][0];
        return unpackInterestRateParams(PRIME_CASH_OFFSET, data);
    }

    /// @notice Sets prime cash interest rate parameters, which are always in active storage
    /// at left most bytes8 slot. This corresponds to marketIndex = 0 which is unused by fCash
    /// markets.
    function setPrimeCashInterestRateParameters(
        uint16 currencyId,
        InterestRateCurveSettings memory settings
    ) internal {
        bytes32[2] storage activeStorage = LibStorage.getActiveInterestRateParameters()[currencyId];
        bytes32[2] storage nextStorage = LibStorage.getNextInterestRateParameters()[currencyId];
        // Set the settings in both active and next. On the next market roll the prime cash parameters
        // will be preserved
        activeStorage[0] = _setInterestRateParameters(activeStorage[0], PRIME_CASH_SHIFT, settings);
        nextStorage[0] = _setInterestRateParameters(nextStorage[0], PRIME_CASH_SHIFT, settings);
    }

    function setActiveInterestRateParameters(uint16 currencyId) internal {
        // Whenever we set the active interest rate parameters, we just copy the next
        // values into the active storage values.
        bytes32[2] storage nextStorage = LibStorage.getNextInterestRateParameters()[currencyId];
        bytes32[2] storage activeStorage = LibStorage.getActiveInterestRateParameters()[currencyId];
        activeStorage[0] = nextStorage[0];
        activeStorage[1] = nextStorage[1];
    }

    /// @notice Oracle rate protects against short term price manipulation. Time window will be set to a value
    /// on the order of minutes to hours. This is to protect fCash valuations from market manipulation. For example,
    /// a trader could use a flash loan to dump a large amount of cash into the market and depress interest rates.
    /// Since we value fCash in portfolios based on these rates, portfolio values will decrease and they may then
    /// be liquidated.
    ///
    /// Oracle rates are calculated when the values are loaded from storage.
    ///
    /// The oracle rate is a lagged weighted average over a short term price window. If we are past
    /// the short term window then we just set the rate to the lastImpliedRate, otherwise we take the
    /// weighted average:
    ///     lastInterestRatePreTrade * (currentTs - previousTs) / timeWindow +
    ///         oracleRatePrevious * (1 - (currentTs - previousTs) / timeWindow)
    function updateRateOracle(
        uint256 lastUpdateTime,
        uint256 lastInterestRate,
        uint256 oracleRate,
        uint256 rateOracleTimeWindow,
        uint256 blockTime
    ) internal pure returns (uint256 newOracleRate) {
        require(rateOracleTimeWindow > 0); // dev: update rate oracle, time window zero

        // This can occur when using a view function get to a market state in the past
        if (lastUpdateTime > blockTime) return lastInterestRate;

        uint256 timeDiff = blockTime.sub(lastUpdateTime);
        // If past the time window just return the lastInterestRate
        if (timeDiff > rateOracleTimeWindow) return lastInterestRate;

        // (currentTs - previousTs) / timeWindow
        uint256 lastTradeWeight = timeDiff.divInRatePrecision(rateOracleTimeWindow);

        // 1 - (currentTs - previousTs) / timeWindow
        uint256 oracleWeight = uint256(Constants.RATE_PRECISION).sub(lastTradeWeight);

        // lastInterestRatePreTrade * lastTradeWeight + oracleRatePrevious * oracleWeight
        newOracleRate =
            (lastInterestRate.mul(lastTradeWeight).add(oracleRate.mul(oracleWeight)))
                .div(uint256(Constants.RATE_PRECISION));
    }

    /// @notice Returns the utilization for an fCash market:
    /// (totalfCash +/- fCashToAccount) / (totalfCash + totalCash)
    function getfCashUtilization(
        int256 fCashToAccount,
        int256 totalfCash,
        int256 totalCashUnderlying
    ) internal pure returns (uint256 utilization) {
        require(totalfCash >= 0);
        require(totalCashUnderlying >= 0);
        utilization = totalfCash.subNoNeg(fCashToAccount)
            .divInRatePrecision(totalCashUnderlying.add(totalfCash))
            .toUint();
    }

    /// @notice Returns the preFeeInterestRate given interest rate parameters and utilization
    function getInterestRate(
        InterestRateParameters memory irParams,
        uint256 utilization
    ) internal pure returns (uint256 preFeeInterestRate) {
        // If this is not set, then assume that the rate parameters have not been initialized
        // and revert.
        require(irParams.maxRate > 0);
        // Do not allow trading past 100% utilization, revert for safety here to prevent
        // underflows, however in calculatefCashTrade we check this explicitly to prevent
        // a revert. nToken redemption relies on the behavior that calculateTrade returns 0
        // during an unsuccessful trade.
        require(utilization <= uint256(Constants.RATE_PRECISION));

        if (utilization <= irParams.kinkUtilization1) {
            // utilization * kinkRate1 / kinkUtilization1
            preFeeInterestRate = utilization
                .mul(irParams.kinkRate1)
                .div(irParams.kinkUtilization1);
        } else if (utilization <= irParams.kinkUtilization2) {
            // (utilization - kinkUtilization1) * (kinkRate2 - kinkRate1) 
            // ---------------------------------------------------------- + kinkRate1
            //            (kinkUtilization2 - kinkUtilization1)
            preFeeInterestRate = (utilization - irParams.kinkUtilization1) // underflow checked
                .mul(irParams.kinkRate2 - irParams.kinkRate1) // underflow checked by definition
                .div(irParams.kinkUtilization2 - irParams.kinkUtilization1) // underflow checked by definition
                .add(irParams.kinkRate1);
        } else {
            // (utilization - kinkUtilization2) * (maxRate - kinkRate2) 
            // ---------------------------------------------------------- + kinkRate2
            //                  (1 - kinkUtilization2)
            preFeeInterestRate = (utilization - irParams.kinkUtilization2) // underflow checked
                .mul(irParams.maxRate - irParams.kinkRate2) // underflow checked by definition
                .div(uint256(Constants.RATE_PRECISION) - irParams.kinkUtilization2) // underflow checked by definition
                .add(irParams.kinkRate2);
        }
    }

    /// @notice Calculates a market utilization via the interest rate, is the
    /// inverse of getInterestRate
    function getUtilizationFromInterestRate(
        InterestRateParameters memory irParams,
        uint256 interestRate
    ) internal pure returns (uint256 utilization) {
        // If this is not set, then assume that the rate parameters have not been initialized
        // and revert.
        require(irParams.maxRate > 0);

        if (interestRate <= irParams.kinkRate1) {
            // interestRate * kinkUtilization1 / kinkRate1
            utilization = interestRate
                .mul(irParams.kinkUtilization1)
                .div(irParams.kinkRate1);
        } else if (interestRate <= irParams.kinkRate2) {
            // (interestRate - kinkRate1) * (kinkUtilization2 - kinkUtilization1) 
            // ------------------------------------------------------------------   + kinkUtilization1
            //                  (kinkRate2 - kinkRate1)
            utilization = (interestRate - irParams.kinkRate1) // underflow checked
                .mul(irParams.kinkUtilization2 - irParams.kinkUtilization1) // underflow checked by definition
                .div(irParams.kinkRate2 - irParams.kinkRate1) // underflow checked by definition
                .add(irParams.kinkUtilization1);
        } else {
            // NOTE: in this else block, it is possible for interestRate > maxRate and therefore this
            // method will return a utilization greater than 100%. During initialize markets, if this condition
            // exists then the utilization will be marked down to the leverage threshold which is by definition
            // less than 100% utilization.

            // (interestRate - kinkRate2) * (1 - kinkUtilization2)
            // -----------------------------------------------------  + kinkUtilization2
            //                  (maxRate - kinkRate2)
            utilization = (interestRate - irParams.kinkRate2) // underflow checked
                .mul(uint256(Constants.RATE_PRECISION) - irParams.kinkUtilization2) // underflow checked by definition
                .div(irParams.maxRate - irParams.kinkRate2) // underflow checked by definition
                .add(irParams.kinkUtilization2);
        }
    }

    /// @notice Applies fees to an interest rate
    /// @param irParams contains the relevant fee parameters
    /// @param preFeeInterestRate the interest rate before the fee
    /// @param isBorrow if true, the fee increases the rate, else it decreases the rate
    /// @return postFeeInterestRate the interest rate with a fee applied, floored at zero
    function getPostFeeInterestRate(
        InterestRateParameters memory irParams,
        uint256 preFeeInterestRate,
        bool isBorrow
    ) internal pure returns (uint256 postFeeInterestRate) {
        uint256 feeRate = preFeeInterestRate.mul(irParams.feeRatePercent).div(uint256(Constants.PERCENTAGE_DECIMALS));
        if (feeRate < irParams.minFeeRate) feeRate = irParams.minFeeRate;
        if (feeRate > irParams.maxFeeRate) feeRate = irParams.maxFeeRate;

        if (isBorrow) {
            // Borrows increase the interest rate, it is ok for the feeRate to exceed the maxRate here.
            postFeeInterestRate = preFeeInterestRate.add(feeRate);
        } else {
            // Lending decreases the interest rate, do not allow the postFeeInterestRate to underflow
            postFeeInterestRate = feeRate > preFeeInterestRate ? 0 : (preFeeInterestRate - feeRate);
        }
    }

    /// @notice Calculates the asset cash amount the results from trading fCashToAccount with the market. A positive
    /// fCashToAccount is equivalent of lending, a negative is borrowing. Updates the market state in memory.
    /// @param market the current market state
    /// @param cashGroup cash group configuration parameters
    /// @param fCashToAccount the fCash amount that will be deposited into the user's portfolio. The net change
    /// to the market is in the opposite direction.
    /// @param timeToMaturity number of seconds until maturity
    /// @param marketIndex the relevant tenor of the market to trade on
    /// @return netPrimeCashToAccount amount of asset cash to credit or debit to an account
    /// @return primeCashToReserve amount of cash to credit to the reserve (always positive)
    /// @return postFeeInterestRate
    function calculatefCashTrade(
        MarketParameters memory market,
        CashGroupParameters memory cashGroup,
        int256 fCashToAccount,
        uint256 timeToMaturity,
        uint256 marketIndex
    ) internal view returns (int256 netPrimeCashToAccount, int256 primeCashToReserve, uint256 postFeeInterestRate) {
        // Market index must be greater than zero
        require(marketIndex > 0);
        // We return false if there is not enough fCash to support this trade.
        // if fCashToAccount > 0 and totalfCash - fCashToAccount <= 0 then the trade will fail
        // if fCashToAccount < 0 and totalfCash > 0 then this will always pass
        if (market.totalfCash <= fCashToAccount) return (0, 0, 0);

        InterestRateParameters memory irParams = getActiveInterestRateParameters(cashGroup.currencyId, marketIndex);
        int256 totalCashUnderlying = cashGroup.primeRate.convertToUnderlying(market.totalPrimeCash);

        // returns the net cash amounts to apply to each of the three relevant balances.
        // TODO: pass down the post fee interest rate here
        int256 netUnderlyingToAccount;
        int256 netUnderlyingToMarket;
        int256 netUnderlyingToReserve;
        (
            netUnderlyingToAccount,
            netUnderlyingToMarket,
            netUnderlyingToReserve,
            postFeeInterestRate
        ) = _getNetCashAmountsUnderlying(
            irParams,
            market,
            cashGroup,
            totalCashUnderlying,
            fCashToAccount,
            timeToMaturity
        );

        // Signifies a failed net cash amount calculation
        if (netUnderlyingToAccount == 0) return (0, 0, 0);

        {
            // Do not allow utilization to go above 100 on trading, calculate the utilization after
            // the trade has taken effect, meaning that fCash changes and cash changes are applied to
            // the market totals.
            market.totalfCash = market.totalfCash.subNoNeg(fCashToAccount);
            totalCashUnderlying = totalCashUnderlying.add(netUnderlyingToMarket);

            uint256 utilization = getfCashUtilization(0, market.totalfCash, totalCashUnderlying);
            if (utilization > uint256(Constants.RATE_PRECISION)) return (0, 0, 0);

            uint256 newPreFeeImpliedRate = getInterestRate(irParams, utilization);

            // It's technically possible that the implied rate is actually exactly zero we will still
            // fail in this case. If this does happen we may assume that markets are not initialized.
            if (newPreFeeImpliedRate == 0) return (0, 0, 0);

            // Saves the preFeeInterestRate and fCash
            market.lastImpliedRate = newPreFeeImpliedRate;
        }

        (netPrimeCashToAccount, primeCashToReserve) = _setNewMarketState(
            market,
            cashGroup.primeRate,
            netUnderlyingToAccount,
            netUnderlyingToMarket,
            netUnderlyingToReserve
        );
    }

    /// @notice Returns net underlying cash amounts to the account, the market and the reserve.
    /// @return postFeeCashToAccount this is a positive or negative amount of cash change to the account
    /// @return netUnderlyingToMarket this is a positive or negative amount of cash change in the market
    /// @return cashToReserve this is always a positive amount of cash accrued to the reserve
    function _getNetCashAmountsUnderlying(
        InterestRateParameters memory irParams,
        MarketParameters memory market,
        CashGroupParameters memory cashGroup,
        int256 totalCashUnderlying,
        int256 fCashToAccount,
        uint256 timeToMaturity
    ) private pure returns (
        int256 postFeeCashToAccount,
        int256 netUnderlyingToMarket,
        int256 cashToReserve,
        uint256 postFeeInterestRate
    ) {
        uint256 utilization = getfCashUtilization(fCashToAccount, market.totalfCash, totalCashUnderlying);
        // Do not allow utilization to go above 100 on trading
        if (utilization > uint256(Constants.RATE_PRECISION)) return (0, 0, 0, 0);
        uint256 preFeeInterestRate = getInterestRate(irParams, utilization);

        int256 preFeeCashToAccount = fCashToAccount.divInRatePrecision(
            getfCashExchangeRate(preFeeInterestRate, timeToMaturity)
        ).neg();

        postFeeInterestRate = getPostFeeInterestRate(irParams, preFeeInterestRate, fCashToAccount < 0);
        postFeeCashToAccount = fCashToAccount.divInRatePrecision(
            getfCashExchangeRate(postFeeInterestRate, timeToMaturity)
        ).neg();

        require(postFeeCashToAccount <= preFeeCashToAccount);
        // Both pre fee cash to account and post fee cash to account are either negative (lending) or positive
        // (borrowing). Fee will be positive or zero as a result.
        int256 fee = preFeeCashToAccount.sub(postFeeCashToAccount);

        cashToReserve = fee.mul(cashGroup.getReserveFeeShare()).div(Constants.PERCENTAGE_DECIMALS);

        // This inequality must hold inside given the fees:
        //  netToMarket + cashToReserve + postFeeCashToAccount = 0

        // Example: Lending
        // Pre Fee Cash: -97 ETH
        // Post Fee Cash: -100 ETH
        // Fee: 3 ETH
        // To Reserve: 1 ETH
        // Net To Market = 99 ETH
        // 99 + 1 - 100 == 0

        // Example: Borrowing
        // Pre Fee Cash: 100 ETH
        // Post Fee Cash: 97 ETH
        // Fee: 3 ETH
        // To Reserve: 1 ETH
        // Net To Market = -98 ETH
        // 97 + 1 - 98 == 0

        // Therefore:
        //  netToMarket = - cashToReserve - postFeeCashToAccount
        //  netToMarket = - (cashToReserve + postFeeCashToAccount)

        netUnderlyingToMarket = (postFeeCashToAccount.add(cashToReserve)).neg();
    }

    /// @notice Sets the new market state
    /// @return netAssetCashToAccount: the positive or negative change in asset cash to the account
    /// @return assetCashToReserve: the positive amount of cash that accrues to the reserve
    function _setNewMarketState(
        MarketParameters memory market,
        PrimeRate memory primeRate,
        int256 netUnderlyingToAccount,
        int256 netUnderlyingToMarket,
        int256 netUnderlyingToReserve
    ) private view returns (int256, int256) {
        int256 netPrimeCashToMarket = primeRate.convertFromUnderlying(netUnderlyingToMarket);
        // Set storage checks that total prime cash is above zero
        market.totalPrimeCash = market.totalPrimeCash.add(netPrimeCashToMarket);

        // Sets the trade time for the next oracle update
        market.previousTradeTime = block.timestamp;
        int256 primeCashToReserve = primeRate.convertFromUnderlying(netUnderlyingToReserve);
        int256 netPrimeCashToAccount = primeRate.convertFromUnderlying(netUnderlyingToAccount);
        return (netPrimeCashToAccount, primeCashToReserve);
    }

    /// @notice Converts an interest rate to an exchange rate given a time to maturity. The
    /// formula is E = e^rt
    function getfCashExchangeRate(
        uint256 interestRate,
        uint256 timeToMaturity
    ) internal pure returns (int256 exchangeRate) {
        int128 expValue =
            ABDKMath64x64.fromUInt(interestRate.mul(timeToMaturity).div(Constants.YEAR));
        int128 expValueScaled = ABDKMath64x64.div(expValue, Constants.RATE_PRECISION_64x64);
        int128 expResult = ABDKMath64x64.exp(expValueScaled);
        int128 expResultScaled = ABDKMath64x64.mul(expResult, Constants.RATE_PRECISION_64x64);

        exchangeRate = ABDKMath64x64.toInt(expResultScaled);
    }

    /// @notice Uses secant method to converge on an fCash amount given the amount
    /// of cash. The relation between cash and fCash is:
    /// f(fCash) = cashAmount * exchangeRatePostFee(fCash) + fCash = 0
    /// where exchangeRatePostFee = e ^ (interestRatePostFee * timeToMaturity)
    ///       and interestRatePostFee = interestRateFunc(utilization)
    ///       and utilization = (totalfCash - fCashToAccount) / (totalfCash + totalCash)
    ///
    /// interestRateFunc is guaranteed to be monotonic and continuous, however, it is not
    /// differentiable therefore we must use the secant method instead of Newton's method.
    ///
    /// Secant method is:
    ///                          x_1 - x_0
    ///  x_n = x_1 - f(x_1) * ---------------
    ///                       f(x_1) - f(x_0)
    ///
    ///  break when (x_n - x_1) < maxDelta
    ///
    /// The initial guesses for x_0 and x_1 depend on the direction of the trade.
    ///     netUnderlyingToAccount > 0, then fCashToAccount < 0 and the interest rate will increase
    ///         therefore x_0 = f @ current utilization and x_1 = f @ max utilization
    ///     netUnderlyingToAccount < 0, then fCashToAccount > 0 and the interest rate will decrease
    ///         therefore x_0 = f @ min utilization and x_1 = f @ current utilization
    ///
    /// These initial guesses will ensure that the method converges to a root (if one exists).
    function getfCashGivenCashAmount(
        InterestRateParameters memory irParams,
        int256 totalfCash,
        int256 netUnderlyingToAccount,
        int256 totalCashUnderlying,
        uint256 timeToMaturity
    ) internal pure returns (int256) {
        require(netUnderlyingToAccount != 0);
        // Cannot borrow more than total cash underlying
        require(netUnderlyingToAccount <= totalCashUnderlying, "Over Market Limit");

        int256 fCash_0;
        int256 fCash_1;
        {
            // Calculate fCash rate at the current mid point
            int256 currentfCashExchangeRate = _calculatePostFeeExchangeRate(
                irParams,
                totalfCash,
                totalCashUnderlying,
                timeToMaturity,
                netUnderlyingToAccount > 0 ? int256(-1) : int256(1) // set this such that we get the correct fee direction
            );

            if (netUnderlyingToAccount < 0) {
                // Lending
                // Minimum guess is lending at 0% interest, which means receiving fCash 1-1
                // with underlying cash amounts
                fCash_0 = netUnderlyingToAccount.neg();
                fCash_1 = netUnderlyingToAccount.mulInRatePrecision(currentfCashExchangeRate).neg();
            } else {
                // Borrowing
                fCash_0 = netUnderlyingToAccount.mulInRatePrecision(currentfCashExchangeRate).neg();
                fCash_1 = netUnderlyingToAccount.mulInRatePrecision(
                    getfCashExchangeRate(irParams.maxRate, timeToMaturity)
                ).neg();
            }
        }

        int256 diff_0 = _calculateDiff(
            irParams,
            totalfCash,
            totalCashUnderlying,
            fCash_0,
            timeToMaturity,
            netUnderlyingToAccount
        );

        for (uint8 i = 0; i < 250; i++) {
            int256 fCashDelta = (fCash_1 - fCash_0);
            if (fCashDelta == 0) return fCash_1;
            int256 diff_1 = _calculateDiff(
                irParams,
                totalfCash,
                totalCashUnderlying,
                fCash_1,
                timeToMaturity,
                netUnderlyingToAccount
            );
            int256 fCash_n = fCash_1.sub(diff_1.mul(fCashDelta).div(diff_1.sub(diff_0)));

            // Assign new values for next comparison
            (fCash_1, fCash_0) = (fCash_n, fCash_1);
            diff_0 = diff_1;
        }

        revert("No convergence");
    }

    function _calculateDiff(
        InterestRateParameters memory irParams,
        int256 totalfCash,
        int256 totalCashUnderlying,
        int256 fCashToAccount,
        uint256 timeToMaturity,
        int256 netUnderlyingToAccount
    ) private pure returns (int256) {
        int256 exchangeRate =  _calculatePostFeeExchangeRate(
            irParams,
            totalfCash,
            totalCashUnderlying,
            timeToMaturity,
            fCashToAccount
        );

        return fCashToAccount.add(netUnderlyingToAccount.mulInRatePrecision(exchangeRate));
    }

    function _calculatePostFeeExchangeRate(
        InterestRateParameters memory irParams,
        int256 totalfCash,
        int256 totalCashUnderlying,
        uint256 timeToMaturity,
        int256 fCashToAccount
    ) private pure returns (int256) {
        uint256 preFeeInterestRate = getInterestRate(
            irParams,
            getfCashUtilization(fCashToAccount, totalfCash, totalCashUnderlying)
        );
        uint256 postFeeInterestRate = getPostFeeInterestRate(irParams, preFeeInterestRate, fCashToAccount < 0);

        return getfCashExchangeRate(postFeeInterestRate, timeToMaturity);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    MarketStorage,
    MarketParameters,
    CashGroupParameters
} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";

import {Emitter} from "../Emitter.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";
import {DateTime} from "./DateTime.sol";
import {InterestRateCurve} from "./InterestRateCurve.sol";

library Market {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;

    /// @notice Add liquidity to a market, assuming that it is initialized. If not then
    /// this method will revert and the market must be initialized first.
    /// Return liquidityTokens and negative fCash to the portfolio
    function addLiquidity(MarketParameters memory market, int256 primeCash)
        internal
        returns (int256 liquidityTokens, int256 fCash)
    {
        require(market.totalLiquidity > 0, "M: zero liquidity");
        if (primeCash == 0) return (0, 0);
        require(primeCash > 0); // dev: negative asset cash

        liquidityTokens = market.totalLiquidity.mul(primeCash).div(market.totalPrimeCash);
        // No need to convert this to underlying, primeCash / totalPrimeCash is a unitless proportion.
        fCash = market.totalfCash.mul(primeCash).div(market.totalPrimeCash);

        market.totalLiquidity = market.totalLiquidity.add(liquidityTokens);
        market.totalfCash = market.totalfCash.add(fCash);
        market.totalPrimeCash = market.totalPrimeCash.add(primeCash);
        _setMarketStorageForLiquidity(market);
        // Flip the sign to represent the LP's net position
        fCash = fCash.neg();
    }

    /// @notice Remove liquidity from a market, assuming that it is initialized.
    /// Return primeCash and positive fCash to the portfolio
    function removeLiquidity(MarketParameters memory market, int256 tokensToRemove)
        internal
        returns (int256 primeCash, int256 fCash)
    {
        if (tokensToRemove == 0) return (0, 0);
        require(tokensToRemove > 0); // dev: negative tokens to remove

        primeCash = market.totalPrimeCash.mul(tokensToRemove).div(market.totalLiquidity);
        fCash = market.totalfCash.mul(tokensToRemove).div(market.totalLiquidity);

        market.totalLiquidity = market.totalLiquidity.subNoNeg(tokensToRemove);
        market.totalfCash = market.totalfCash.subNoNeg(fCash);
        market.totalPrimeCash = market.totalPrimeCash.subNoNeg(primeCash);

        _setMarketStorageForLiquidity(market);
    }

    function executeTrade(
        MarketParameters memory market,
        address account,
        CashGroupParameters memory cashGroup,
        int256 fCashToAccount,
        uint256 timeToMaturity,
        uint256 marketIndex
    ) internal returns (int256 netPrimeCash, uint256 postFeeInterestRate) {
        int256 netPrimeCashToReserve;
        (netPrimeCash, netPrimeCashToReserve, postFeeInterestRate) = InterestRateCurve.calculatefCashTrade(
            market,
            cashGroup,
            fCashToAccount,
            timeToMaturity,
            marketIndex
        );

        // A zero net prime cash value means that the trade has failed and we should not update the market state
        if (netPrimeCash != 0) {
            MarketStorage storage marketStorage = _getMarketStoragePointer(market);
            _setMarketStorage(
                marketStorage,
                market.totalfCash,
                market.totalPrimeCash,
                market.lastImpliedRate,
                market.oracleRate,
                market.previousTradeTime
            );
            BalanceHandler.incrementFeeToReserve(cashGroup.currencyId, netPrimeCashToReserve);

            Emitter.emitfCashMarketTrade(
                account, cashGroup.currencyId, market.maturity, fCashToAccount, netPrimeCash, netPrimeCashToReserve
            );
        }
    }

    function getOracleRate(
        uint256 currencyId,
        uint256 maturity,
        uint256 rateOracleTimeWindow,
        uint256 blockTime
    ) internal view returns (uint256) {
        mapping(uint256 => mapping(uint256 => 
            mapping(uint256 => MarketStorage))) storage store = LibStorage.getMarketStorage();
        uint256 settlementDate = DateTime.getReferenceTime(blockTime) + Constants.QUARTER;
        MarketStorage storage marketStorage = store[currencyId][maturity][settlementDate];

        uint256 lastImpliedRate = marketStorage.lastImpliedRate;
        uint256 oracleRate = marketStorage.oracleRate;
        uint256 previousTradeTime = marketStorage.previousTradeTime;

        // If the oracle rate is set to zero this can only be because the markets have past their settlement
        // date but the new set of markets has not yet been initialized. This means that accounts cannot be liquidated
        // during this time, but market initialization can be called by anyone so the actual time that this condition
        // exists for should be quite short.
        require(oracleRate > 0, "Market not initialized");

        return
            InterestRateCurve.updateRateOracle(
                previousTradeTime,
                lastImpliedRate,
                oracleRate,
                rateOracleTimeWindow,
                blockTime
            );
    }

    /// @notice Reads a market object directly from storage. `loadMarket` should be called instead of this method
    /// which ensures that the rate oracle is set properly.
    function _loadMarketStorage(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        bool needsLiquidity,
        uint256 settlementDate
    ) private view {
        // Market object always uses the most current reference time as the settlement date
        mapping(uint256 => mapping(uint256 => 
            mapping(uint256 => MarketStorage))) storage store = LibStorage.getMarketStorage();
        MarketStorage storage marketStorage = store[currencyId][maturity][settlementDate];
        bytes32 slot;
        assembly {
            slot := marketStorage.slot
        }

        market.storageSlot = slot;
        market.maturity = maturity;
        market.totalfCash = marketStorage.totalfCash;
        market.totalPrimeCash = marketStorage.totalPrimeCash;
        market.lastImpliedRate = marketStorage.lastImpliedRate;
        market.oracleRate = marketStorage.oracleRate;
        market.previousTradeTime = marketStorage.previousTradeTime;

        if (needsLiquidity) {
            market.totalLiquidity = marketStorage.totalLiquidity;
        } else {
            market.totalLiquidity = 0;
        }
    }

    function _getMarketStoragePointer(
        MarketParameters memory market
    ) private pure returns (MarketStorage storage marketStorage) {
        bytes32 slot = market.storageSlot;
        assembly {
            marketStorage.slot := slot
        }
    }

    function _setMarketStorageForLiquidity(MarketParameters memory market) internal {
        MarketStorage storage marketStorage = _getMarketStoragePointer(market);
        // Oracle rate does not change on liquidity
        uint32 storedOracleRate = marketStorage.oracleRate;

        _setMarketStorage(
            marketStorage,
            market.totalfCash,
            market.totalPrimeCash,
            market.lastImpliedRate,
            storedOracleRate,
            market.previousTradeTime
        );

        _setTotalLiquidity(marketStorage, market.totalLiquidity);
    }

    function setMarketStorageForInitialize(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 settlementDate
    ) internal {
        // On initialization we have not yet calculated the storage slot so we get it here.
        mapping(uint256 => mapping(uint256 => 
            mapping(uint256 => MarketStorage))) storage store = LibStorage.getMarketStorage();
        MarketStorage storage marketStorage = store[currencyId][market.maturity][settlementDate];

        _setMarketStorage(
            marketStorage,
            market.totalfCash,
            market.totalPrimeCash,
            market.lastImpliedRate,
            market.oracleRate,
            market.previousTradeTime
        );

        _setTotalLiquidity(marketStorage, market.totalLiquidity);
    }

    function _setTotalLiquidity(
        MarketStorage storage marketStorage,
        int256 totalLiquidity
    ) internal {
        require(totalLiquidity >= 0 && totalLiquidity <= type(uint80).max); // dev: market storage totalLiquidity overflow
        marketStorage.totalLiquidity = uint80(totalLiquidity);
    }

    function _setMarketStorage(
        MarketStorage storage marketStorage,
        int256 totalfCash,
        int256 totalPrimeCash,
        uint256 lastImpliedRate,
        uint256 oracleRate,
        uint256 previousTradeTime
    ) private {
        require(totalfCash >= 0 && totalfCash <= type(uint80).max); // dev: storage totalfCash overflow
        require(totalPrimeCash >= 0 && totalPrimeCash <= type(uint80).max); // dev: storage totalPrimeCash overflow
        require(0 < lastImpliedRate && lastImpliedRate <= type(uint32).max); // dev: storage lastImpliedRate overflow
        require(0 < oracleRate && oracleRate <= type(uint32).max); // dev: storage oracleRate overflow
        require(0 <= previousTradeTime && previousTradeTime <= type(uint32).max); // dev: storage previous trade time overflow

        marketStorage.totalfCash = uint80(totalfCash);
        marketStorage.totalPrimeCash = uint80(totalPrimeCash);
        marketStorage.lastImpliedRate = uint32(lastImpliedRate);
        marketStorage.oracleRate = uint32(oracleRate);
        marketStorage.previousTradeTime = uint32(previousTradeTime);
    }

    /// @notice Creates a market object and ensures that the rate oracle time window is updated appropriately.
    function loadMarket(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime,
        bool needsLiquidity,
        uint256 rateOracleTimeWindow
    ) internal view {
        // Always reference the current settlement date
        uint256 settlementDate = DateTime.getReferenceTime(blockTime) + Constants.QUARTER;
        loadMarketWithSettlementDate(
            market,
            currencyId,
            maturity,
            blockTime,
            needsLiquidity,
            rateOracleTimeWindow,
            settlementDate
        );
    }

    /// @notice Creates a market object and ensures that the rate oracle time window is updated appropriately, this
    /// is mainly used in the InitializeMarketAction contract.
    function loadMarketWithSettlementDate(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime,
        bool needsLiquidity,
        uint256 rateOracleTimeWindow,
        uint256 settlementDate
    ) internal view {
        _loadMarketStorage(market, currencyId, maturity, needsLiquidity, settlementDate);

        market.oracleRate = InterestRateCurve.updateRateOracle(
            market.previousTradeTime,
            market.lastImpliedRate,
            market.oracleRate,
            rateOracleTimeWindow,
            blockTime
        );
    }

    function loadSettlementMarket(
        MarketParameters memory market,
        uint256 currencyId,
        uint256 maturity,
        uint256 settlementDate
    ) internal view {
        _loadMarketStorage(market, currencyId, maturity, true, settlementDate);
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PrimeRate,
    nTokenPortfolio,
    CashGroupParameters,
    MarketParameters,
    PortfolioAsset
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {Bitmap} from "../../math/Bitmap.sol";

import {BitmapAssetsHandler} from "../portfolio/BitmapAssetsHandler.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {CashGroup} from "../markets/CashGroup.sol";
import {DateTime} from "../markets/DateTime.sol";
import {AssetHandler} from "../valuation/AssetHandler.sol";

import {nTokenHandler} from "./nTokenHandler.sol";

library nTokenCalculations {
    using Bitmap for bytes32;
    using SafeInt256 for int256;
    using PrimeRateLib for PrimeRate;
    using CashGroup for CashGroupParameters;

    /// @notice Returns the nToken present value denominated in asset terms.
    function getNTokenPrimePV(nTokenPortfolio memory nToken, uint256 blockTime)
        internal
        view
        returns (int256)
    {
        {
            uint256 nextSettleTime = nTokenHandler.getNextSettleTime(nToken);
            // If the first asset maturity has passed (the 3 month), this means that all the LTs must
            // be settled except the 6 month (which is now the 3 month). We don't settle LTs except in
            // initialize markets so we calculate the cash value of the portfolio here.
            if (nextSettleTime <= blockTime) {
                // NOTE: this condition should only be present for a very short amount of time, which is the window between
                // when the markets are no longer tradable at quarter end and when the new markets have been initialized.
                // We time travel back to one second before maturity to value the liquidity tokens. Although this value is
                // not strictly correct the different should be quite slight. We do this to ensure that free collateral checks
                // for withdraws and liquidations can still be processed. If this condition persists for a long period of time then
                // the entire protocol will have serious problems as markets will not be tradable.
                blockTime = nextSettleTime - 1;
            }
        }

        // This is the total value in liquid assets
        (int256 totalAssetValueInMarkets, /* int256[] memory netfCash */) = getNTokenMarketValue(nToken, blockTime);

        // Then get the total value in any idiosyncratic fCash residuals (if they exist)
        bytes32 ifCashBits = getNTokenifCashBits(
            nToken.tokenAddress,
            nToken.cashGroup.currencyId,
            nToken.lastInitializedTime,
            blockTime,
            nToken.cashGroup.maxMarketIndex
        );

        int256 ifCashResidualUnderlyingPV = 0;
        if (ifCashBits != 0) {
            // Non idiosyncratic residuals have already been accounted for
            (ifCashResidualUnderlyingPV, /* hasDebt */) = BitmapAssetsHandler.getNetPresentValueFromBitmap(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.lastInitializedTime,
                blockTime,
                nToken.cashGroup,
                false, // nToken present value calculation does not use risk adjusted values
                ifCashBits
            );
        }

        // Return the total present value denominated in asset terms
        return totalAssetValueInMarkets
            .add(nToken.cashGroup.primeRate.convertFromUnderlying(ifCashResidualUnderlyingPV))
            .add(nToken.cashBalance);
    }

    /**
     * @notice Handles the case when liquidity tokens should be withdrawn in proportion to their amounts
     * in the market. This will be the case when there is no idiosyncratic fCash residuals in the nToken
     * portfolio.
     * @param nToken portfolio object for nToken
     * @param nTokensToRedeem amount of nTokens to redeem
     * @param tokensToWithdraw array of liquidity tokens to withdraw from each market, proportional to
     * the account's share of the total supply
     * @param netfCash an empty array to hold net fCash values calculated later when the tokens are actually
     * withdrawn from markets
     */
    function _getProportionalLiquidityTokens(
        nTokenPortfolio memory nToken,
        int256 nTokensToRedeem
    ) private pure returns (int256[] memory tokensToWithdraw, int256[] memory netfCash) {
        uint256 numMarkets = nToken.portfolioState.storedAssets.length;
        tokensToWithdraw = new int256[](numMarkets);
        netfCash = new int256[](numMarkets);

        for (uint256 i = 0; i < numMarkets; i++) {
            int256 totalTokens = nToken.portfolioState.storedAssets[i].notional;
            tokensToWithdraw[i] = totalTokens.mul(nTokensToRedeem).div(nToken.totalSupply);
        }
    }

    /**
     * @notice Returns the number of liquidity tokens to withdraw from each market if the nToken
     * has idiosyncratic residuals during nToken redeem. In this case the redeemer will take
     * their cash from the rest of the fCash markets, redeeming around the nToken.
     * @param nToken portfolio object for nToken
     * @param nTokensToRedeem amount of nTokens to redeem
     * @param blockTime block time
     * @param ifCashBits the bits in the bitmap that represent ifCash assets
     * @return tokensToWithdraw array of tokens to withdraw from each corresponding market
     * @return netfCash array of netfCash amounts to go back to the account
     */
    function getLiquidityTokenWithdraw(
        nTokenPortfolio memory nToken,
        int256 nTokensToRedeem,
        uint256 blockTime,
        bytes32 ifCashBits
    ) internal view returns (int256[] memory, int256[] memory) {
        // If there are no ifCash bits set then this will just return the proportion of all liquidity tokens
        if (ifCashBits == 0) return _getProportionalLiquidityTokens(nToken, nTokensToRedeem);

        (
            int256 totalPrimeValueInMarkets,
            int256[] memory netfCash
        ) = getNTokenMarketValue(nToken, blockTime);
        int256[] memory tokensToWithdraw = new int256[](netfCash.length);

        // NOTE: this total portfolio asset value does not include any cash balance the nToken may hold.
        // The redeemer will always get a proportional share of this cash balance and therefore we don't
        // need to account for it here when we calculate the share of liquidity tokens to withdraw. We are
        // only concerned with the nToken's portfolio assets in this method.
        int256 totalPortfolioAssetValue;
        {
            // Returns the risk adjusted net present value for the idiosyncratic residuals
            (int256 underlyingPV, /* hasDebt */) = BitmapAssetsHandler.getNetPresentValueFromBitmap(
                nToken.tokenAddress,
                nToken.cashGroup.currencyId,
                nToken.lastInitializedTime,
                blockTime,
                nToken.cashGroup,
                true, // use risk adjusted here to assess a penalty for withdrawing around the residual
                ifCashBits
            );

            // NOTE: we do not include cash balance here because the account will always take their share
            // of the cash balance regardless of the residuals
            totalPortfolioAssetValue = totalPrimeValueInMarkets.add(
                nToken.cashGroup.primeRate.convertFromUnderlying(underlyingPV)
            );
        }

        // Loops through each liquidity token and calculates how much the redeemer can withdraw to get
        // the requisite amount of present value after adjusting for the ifCash residual value that is
        // not accessible via redemption.
        for (uint256 i = 0; i < tokensToWithdraw.length; i++) {
            int256 totalTokens = nToken.portfolioState.storedAssets[i].notional;
            // Redeemer's baseline share of the liquidity tokens based on total supply:
            //      redeemerShare = totalTokens * nTokensToRedeem / totalSupply
            // Scalar factor to account for residual value (need to inflate the tokens to withdraw
            // proportional to the value locked up in ifCash residuals):
            //      scaleFactor = totalPortfolioAssetValue / totalPrimeValueInMarkets
            // Final math equals:
            //      tokensToWithdraw = redeemerShare * scalarFactor
            //      tokensToWithdraw = (totalTokens * nTokensToRedeem * totalPortfolioAssetValue)
            //         / (totalPrimeValueInMarkets * totalSupply)
            tokensToWithdraw[i] = totalTokens
                .mul(nTokensToRedeem)
                .mul(totalPortfolioAssetValue);

            tokensToWithdraw[i] = tokensToWithdraw[i]
                .div(totalPrimeValueInMarkets)
                .div(nToken.totalSupply);

            // This is the share of net fcash that will be credited back to the account
            netfCash[i] = netfCash[i].mul(tokensToWithdraw[i]).div(totalTokens);
        }

        return (tokensToWithdraw, netfCash);
    }

    /// @notice Returns the value of all the liquid assets in an nToken portfolio which are defined by
    /// the liquidity tokens held in each market and their corresponding fCash positions. The formula
    /// can be described as:
    /// totalPrimeValue = sum_per_liquidity_token(cashClaim + presentValue(netfCash))
    ///     where netfCash = fCashClaim + fCash
    ///     and fCash refers the the fCash position at the corresponding maturity
    function getNTokenMarketValue(nTokenPortfolio memory nToken, uint256 blockTime)
        internal
        view
        returns (int256 totalPrimeValue, int256[] memory netfCash)
    {
        uint256 numMarkets = nToken.portfolioState.storedAssets.length;
        netfCash = new int256[](numMarkets);

        MarketParameters memory market;
        for (uint256 i = 0; i < numMarkets; i++) {
            // Load the corresponding market into memory
            nToken.cashGroup.loadMarket(market, i + 1, true, blockTime);
            PortfolioAsset memory liquidityToken = nToken.portfolioState.storedAssets[i];
            uint256 maturity = liquidityToken.maturity;

            // Get the fCash claims and fCash assets. We do not use haircut versions here because
            // nTokenRedeem does not require it and getNTokenPV does not use it (a haircut is applied
            // at the end of the calculation to the entire PV instead).
            (int256 primeCashClaim, int256 fCashClaim) = AssetHandler.getCashClaims(liquidityToken, market);

            // fCash is denominated in underlying
            netfCash[i] = fCashClaim.add(
                BitmapAssetsHandler.getifCashNotional(
                    nToken.tokenAddress,
                    nToken.cashGroup.currencyId,
                    maturity
                )
            );

            // This calculates for a single liquidity token:
            // primeCashClaim + convertToPrimeCash(pv(netfCash))
            int256 netPrimeValueInMarket = primeCashClaim.add(
                nToken.cashGroup.primeRate.convertFromUnderlying(
                    AssetHandler.getPresentfCashValue(
                        netfCash[i],
                        maturity,
                        blockTime,
                        // No need to call cash group for oracle rate, it is up to date here
                        // and we are assured to be referring to this market.
                        market.oracleRate
                    )
                )
            );

            // Calculate the running total
            totalPrimeValue = totalPrimeValue.add(netPrimeValueInMarket);
        }
    }

    /// @notice Returns just the bits in a bitmap that are idiosyncratic
    function getNTokenifCashBits(
        address tokenAddress,
        uint256 currencyId,
        uint256 lastInitializedTime,
        uint256 blockTime,
        uint256 maxMarketIndex
    ) internal view returns (bytes32) {
        // If max market index is less than or equal to 2, there are never ifCash assets by construction
        if (maxMarketIndex <= 2) return bytes32(0);
        bytes32 assetsBitmap = BitmapAssetsHandler.getAssetsBitmap(tokenAddress, currencyId);
        // Handles the case when there are no assets at the first initialization
        if (assetsBitmap == 0) return assetsBitmap;

        uint256 tRef = DateTime.getReferenceTime(blockTime);

        if (tRef == lastInitializedTime) {
            // This is a more efficient way to turn off ifCash assets in the common case when the market is
            // initialized immediately
            return assetsBitmap & ~(Constants.ACTIVE_MARKETS_MASK);
        } else {
            // In this branch, initialize markets has occurred past the time above. It would occur in these
            // two scenarios (both should be exceedingly rare):
            // 1. initializing a cash group with 3+ markets for the first time (not beginning on the tRef)
            // 2. somehow initialize markets has been delayed for more than 24 hours
            for (uint i = 1; i <= maxMarketIndex; i++) {
                // In this loop we get the maturity of each active market and turn off the corresponding bit
                // one by one. It is less efficient than the option above.
                uint256 maturity = tRef + DateTime.getTradedMarket(i);
                (uint256 bitNum, /* */) = DateTime.getBitNumFromMaturity(lastInitializedTime, maturity);
                assetsBitmap = assetsBitmap.setBit(bitNum, false);
            }

            return assetsBitmap;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    nTokenContext,
    nTokenPortfolio
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

import {BitmapAssetsHandler} from "../portfolio/BitmapAssetsHandler.sol";
import {PortfolioHandler} from "../portfolio/PortfolioHandler.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";
import {CashGroup} from "../markets/CashGroup.sol";
import {DateTime} from "../markets/DateTime.sol";

import {nTokenSupply} from "./nTokenSupply.sol";
import {IRewarder} from "../../../interfaces/notional/IRewarder.sol";

library nTokenHandler {
    using SafeInt256 for int256;

    /// @dev Mirror of the value in LibStorage, solidity compiler does not allow assigning
    /// two constants to each other.
    uint256 private constant NUM_NTOKEN_MARKET_FACTORS = 14;

    /// @notice Returns an account context object that is specific to nTokens.
    function getNTokenContext(address tokenAddress)
        internal
        view
        returns (
            uint16 currencyId,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            uint8 assetArrayLength,
            bytes5 parameters
        )
    {
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];

        currencyId = context.currencyId;
        incentiveAnnualEmissionRate = context.incentiveAnnualEmissionRate;
        lastInitializedTime = context.lastInitializedTime;
        assetArrayLength = context.assetArrayLength;
        parameters = context.nTokenParameters;
    }

    /// @notice Returns the nToken token address for a given currency
    function nTokenAddress(uint256 currencyId) internal view returns (address tokenAddress) {
        mapping(uint256 => address) storage store = LibStorage.getNTokenAddressStorage();
        return store[currencyId];
    }

    /// @notice Called by governance to set the nToken token address and its reverse lookup. Cannot be
    /// reset once this is set.
    function setNTokenAddress(uint16 currencyId, address tokenAddress) internal {
        mapping(uint256 => address) storage addressStore = LibStorage.getNTokenAddressStorage();
        require(addressStore[currencyId] == address(0), "PT: token address exists");

        mapping(address => nTokenContext) storage contextStore = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = contextStore[tokenAddress];
        require(context.currencyId == 0, "PT: currency exists");

        // This will initialize all other context slots to zero
        context.currencyId = currencyId;
        addressStore[currencyId] = tokenAddress;
    }

    /// @notice Set nToken token collateral parameters
    function setNTokenCollateralParameters(
        address tokenAddress,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) internal {
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];

        require(liquidationHaircutPercentage <= Constants.PERCENTAGE_DECIMALS, "Invalid haircut");
        // The pv haircut percentage must be less than the liquidation percentage or else liquidators will not
        // get profit for liquidating nToken.
        require(pvHaircutPercentage < liquidationHaircutPercentage, "Invalid pv haircut");
        // Ensure that the cash withholding buffer is greater than the residual purchase incentive or
        // the nToken may not have enough cash to pay accounts to buy its negative ifCash
        require(residualPurchaseIncentive10BPS <= cashWithholdingBuffer10BPS, "Invalid discounts");

        bytes5 parameters =
            (bytes5(uint40(residualPurchaseIncentive10BPS)) |
            (bytes5(uint40(pvHaircutPercentage)) << 8) |
            (bytes5(uint40(residualPurchaseTimeBufferHours)) << 16) |
            (bytes5(uint40(cashWithholdingBuffer10BPS)) << 24) |
            (bytes5(uint40(liquidationHaircutPercentage)) << 32));

        // Set the parameters
        context.nTokenParameters = parameters;
    }

    /// @notice Sets a secondary rewarder contract on an nToken so that incentives can come from a different
    /// contract, aside from the native NOTE token incentives.
    function setSecondaryRewarder(
        uint16 currencyId,
        IRewarder rewarder
    ) internal {
        address tokenAddress = nTokenAddress(currencyId);
        // nToken must exist for a secondary rewarder
        require(tokenAddress != address(0));
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];

        // Setting the rewarder to address(0) will disable it. We use a context setting here so that
        // we can save a storage read before getting the rewarder
        context.hasSecondaryRewarder = (address(rewarder) != address(0));
        LibStorage.getSecondaryIncentiveRewarder()[tokenAddress] = rewarder;
    }

    /// @notice Returns the secondary rewarder if it is set
    function getSecondaryRewarder(address tokenAddress) internal view returns (IRewarder) {
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];
        
        if (context.hasSecondaryRewarder) {
            return LibStorage.getSecondaryIncentiveRewarder()[tokenAddress];
        } else {
            return IRewarder(address(0));
        }
    }

    function setArrayLengthAndInitializedTime(
        address tokenAddress,
        uint8 arrayLength,
        uint256 lastInitializedTime
    ) internal {
        require(lastInitializedTime >= 0 && uint256(lastInitializedTime) < type(uint32).max); // dev: next settle time overflow
        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];
        context.lastInitializedTime = uint32(lastInitializedTime);
        context.assetArrayLength = arrayLength;
    }

    /// @notice Returns the array of deposit shares and leverage thresholds for nTokens
    function getDepositParameters(uint256 currencyId, uint256 maxMarketIndex)
        internal
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds)
    {
        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenDepositStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage depositParameters = store[currencyId];
        (depositShares, leverageThresholds) = _getParameters(depositParameters, maxMarketIndex);
    }

    /// @notice Sets the deposit parameters
    /// @dev We pack the values in alternating between the two parameters into either one or two
    // storage slots depending on the number of markets. This is to save storage reads when we use the parameters.
    function setDepositParameters(
        uint256 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) internal {
        require(
            depositShares.length <= Constants.MAX_TRADED_MARKET_INDEX,
            "PT: deposit share length"
        );
        require(depositShares.length == leverageThresholds.length, "PT: leverage share length");

        uint256 shareSum;
        for (uint256 i; i < depositShares.length; i++) {
            // This cannot overflow in uint 256 with 9 max slots
            shareSum = shareSum + depositShares[i];
            require(
                leverageThresholds[i] > 0 && leverageThresholds[i] < Constants.RATE_PRECISION,
                "PT: leverage threshold"
            );
        }

        // Total deposit share must add up to 100%
        require(shareSum == uint256(Constants.DEPOSIT_PERCENT_BASIS), "PT: deposit shares sum");

        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenDepositStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage depositParameters = store[currencyId];
        _setParameters(depositParameters, depositShares, leverageThresholds);
    }

    /// @notice Sets the initialization parameters for the markets, these are read only when markets
    /// are initialized
    function setInitializationParameters(
        uint256 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) internal {
        require(annualizedAnchorRates.length <= Constants.MAX_TRADED_MARKET_INDEX, "PT: annualized anchor rates length");
        require(proportions.length == annualizedAnchorRates.length, "PT: proportions length");

        for (uint256 i; i < proportions.length; i++) {
            // Anchor rates are no longer used and must always be set to zero
            require(annualizedAnchorRates[i] == 0);
            // Proportions must be between zero and the rate precision
            require(
                proportions[i] > 0 && proportions[i] < Constants.RATE_PRECISION,
                "PT: invalid proportion"
            );
        }

        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenInitStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage initParameters = store[currencyId];
        _setParameters(initParameters, annualizedAnchorRates, proportions);
    }

    /// @notice Returns the array of initialization parameters for a given currency.
    function getInitializationParameters(uint256 currencyId, uint256 maxMarketIndex)
        internal
        view
        returns (int256[] memory proportions)
    {
        mapping(uint256 => uint32[NUM_NTOKEN_MARKET_FACTORS]) storage store = LibStorage.getNTokenInitStorage();
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage initParameters = store[currencyId];

        // NOTE: annualized anchor rates are deprecated as a result of the liquidity curve change
        (/* annualizedAnchorRates */, proportions) = _getParameters(initParameters, maxMarketIndex);
    }

    function _getParameters(
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage slot,
        uint256 maxMarketIndex
    ) private view returns (int256[] memory, int256[] memory) {
        uint256 index = 0;
        int256[] memory array1 = new int256[](maxMarketIndex);
        int256[] memory array2 = new int256[](maxMarketIndex);
        for (uint256 i; i < maxMarketIndex; i++) {
            array1[i] = slot[index];
            index++;
            array2[i] = slot[index];
            index++;
        }

        return (array1, array2);
    }

    function _setParameters(
        uint32[NUM_NTOKEN_MARKET_FACTORS] storage slot,
        uint32[] calldata array1,
        uint32[] calldata array2
    ) private {
        uint256 index = 0;
        for (uint256 i = 0; i < array1.length; i++) {
            slot[index] = array1[i];
            index++;

            slot[index] = array2[i];
            index++;
        }
    }

    function loadNTokenPortfolioNoCashGroup(nTokenPortfolio memory nToken, uint16 currencyId)
        internal
        view
    {
        nToken.tokenAddress = nTokenAddress(currencyId);
        // prettier-ignore
        (
            /* currencyId */,
            /* incentiveRate */,
            uint256 lastInitializedTime,
            uint8 assetArrayLength,
            bytes5 parameters
        ) = getNTokenContext(nToken.tokenAddress);

        // prettier-ignore
        (
            uint256 totalSupply,
            /* accumulatedNOTEPerNToken */,
            /* lastAccumulatedTime */
        ) = nTokenSupply.getStoredNTokenSupplyFactors(nToken.tokenAddress);

        nToken.lastInitializedTime = lastInitializedTime;
        nToken.totalSupply = int256(totalSupply);
        nToken.parameters = parameters;

        nToken.portfolioState = PortfolioHandler.buildPortfolioState(
            nToken.tokenAddress,
            assetArrayLength,
            0
        );

        nToken.cashBalance = BalanceHandler.getPositiveCashBalance(nToken.tokenAddress, currencyId);
    }

    /// @notice Uses buildCashGroupStateful
    function loadNTokenPortfolioStateful(nTokenPortfolio memory nToken, uint16 currencyId)
        internal
    {
        loadNTokenPortfolioNoCashGroup(nToken, currencyId);
        nToken.cashGroup = CashGroup.buildCashGroupStateful(currencyId);
    }

    /// @notice Uses buildCashGroupView
    function loadNTokenPortfolioView(nTokenPortfolio memory nToken, uint16 currencyId)
        internal
        view
    {
        loadNTokenPortfolioNoCashGroup(nToken, currencyId);
        nToken.cashGroup = CashGroup.buildCashGroupView(currencyId);
    }

    /// @notice Returns the next settle time for the nToken which is 1 quarter away
    function getNextSettleTime(nTokenPortfolio memory nToken) internal pure returns (uint256) {
        if (nToken.lastInitializedTime == 0) return 0;
        return DateTime.getReferenceTime(nToken.lastInitializedTime) + Constants.QUARTER;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    nTokenTotalSupplyStorage,
    nTokenContext
} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {nTokenHandler} from "./nTokenHandler.sol";

library nTokenSupply {
    using SafeInt256 for int256;
    using SafeUint256 for uint256;

    /// @notice Retrieves stored nToken supply and related factors. Do not use accumulatedNOTEPerNToken for calculating
    /// incentives! Use `getUpdatedAccumulatedNOTEPerNToken` instead.
    function getStoredNTokenSupplyFactors(address tokenAddress)
        internal
        view
        returns (
            uint256 totalSupply,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        )
    {
        mapping(address => nTokenTotalSupplyStorage) storage store = LibStorage.getNTokenTotalSupplyStorage();
        nTokenTotalSupplyStorage storage nTokenStorage = store[tokenAddress];
        totalSupply = nTokenStorage.totalSupply;
        // NOTE: DO NOT USE THIS RETURNED VALUE FOR CALCULATING INCENTIVES. The accumulatedNOTEPerNToken
        // must be updated given the block time. Use `getUpdatedAccumulatedNOTEPerNToken` instead
        accumulatedNOTEPerNToken = nTokenStorage.accumulatedNOTEPerNToken;
        lastAccumulatedTime = nTokenStorage.lastAccumulatedTime;
    }

    /// @notice Returns the updated accumulated NOTE per nToken for calculating incentives
    function getUpdatedAccumulatedNOTEPerNToken(address tokenAddress, uint256 blockTime)
        internal view
        returns (
            uint256 totalSupply,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        )
    {
        (
            totalSupply,
            accumulatedNOTEPerNToken,
            lastAccumulatedTime
        ) = getStoredNTokenSupplyFactors(tokenAddress);

        // nToken totalSupply is never allowed to drop to zero but we check this here to avoid
        // divide by zero errors during initialization. Also ensure that lastAccumulatedTime is not
        // zero to avoid a massive accumulation amount on initialization.
        if (blockTime > lastAccumulatedTime && lastAccumulatedTime > 0 && totalSupply > 0) {
            // prettier-ignore
            (
                /* currencyId */,
                uint256 emissionRatePerYear,
                /* initializedTime */,
                /* assetArrayLength */,
                /* parameters */
            ) = nTokenHandler.getNTokenContext(tokenAddress);

            uint256 additionalNOTEAccumulatedPerNToken = _calculateAdditionalNOTE(
                // Emission rate is denominated in whole tokens, scale to 1e8 decimals here
                emissionRatePerYear.mul(uint256(Constants.INTERNAL_TOKEN_PRECISION)),
                // Time since last accumulation (overflow checked above)
                blockTime - lastAccumulatedTime,
                totalSupply
            );

            accumulatedNOTEPerNToken = accumulatedNOTEPerNToken.add(additionalNOTEAccumulatedPerNToken);
            require(accumulatedNOTEPerNToken < type(uint128).max); // dev: accumulated NOTE overflow
        }
    }

    /// @notice additionalNOTEPerNToken accumulated since last accumulation time in 1e18 precision
    function _calculateAdditionalNOTE(
        uint256 emissionRatePerYear,
        uint256 timeSinceLastAccumulation,
        uint256 totalSupply
    )
        private
        pure
        returns (uint256)
    {
        // If we use 18 decimal places as the accumulation precision then we will overflow uint128 when
        // a single nToken has accumulated 3.4 x 10^20 NOTE tokens. This isn't possible since the max
        // NOTE that can accumulate is 10^16 (100 million NOTE in 1e8 precision) so we should be safe
        // using 18 decimal places and uint128 storage slot

        // timeSinceLastAccumulation (SECONDS)
        // accumulatedNOTEPerSharePrecision (1e18)
        // emissionRatePerYear (INTERNAL_TOKEN_PRECISION)
        // DIVIDE BY
        // YEAR (SECONDS)
        // totalSupply (INTERNAL_TOKEN_PRECISION)
        return timeSinceLastAccumulation
            .mul(Constants.INCENTIVE_ACCUMULATION_PRECISION)
            .mul(emissionRatePerYear)
            .div(Constants.YEAR)
            // totalSupply > 0 is checked in the calling function
            .div(totalSupply);
    }

    /// @notice Updates the nToken token supply amount when minting or redeeming.
    /// @param tokenAddress address of the nToken
    /// @param netChange positive or negative change to the total nToken supply
    /// @param blockTime current block time
    /// @return accumulatedNOTEPerNToken updated to the given block time
    function changeNTokenSupply(
        address tokenAddress,
        int256 netChange,
        uint256 blockTime
    ) internal returns (uint256) {
        (
            uint256 totalSupply,
            uint256 accumulatedNOTEPerNToken,
            /* uint256 lastAccumulatedTime */
        ) = getUpdatedAccumulatedNOTEPerNToken(tokenAddress, blockTime);

        // Update storage variables
        mapping(address => nTokenTotalSupplyStorage) storage store = LibStorage.getNTokenTotalSupplyStorage();
        nTokenTotalSupplyStorage storage nTokenStorage = store[tokenAddress];

        int256 newTotalSupply = int256(totalSupply).add(netChange);
        // We allow newTotalSupply to equal zero here even though it is prevented from being redeemed down to
        // exactly zero by other internal logic inside nTokenRedeem. This is meant to be purely an overflow check.
        require(0 <= newTotalSupply && uint256(newTotalSupply) < type(uint96).max); // dev: nToken supply overflow

        nTokenStorage.totalSupply = uint96(newTotalSupply);
        // NOTE: overflow checked inside getUpdatedAccumulatedNOTEPerNToken so that behavior here mirrors what
        // the user would see if querying the view function
        nTokenStorage.accumulatedNOTEPerNToken = uint128(accumulatedNOTEPerNToken);

        require(blockTime < type(uint32).max); // dev: block time overflow
        nTokenStorage.lastAccumulatedTime = uint32(blockTime);

        return accumulatedNOTEPerNToken;
    }

    /// @notice Called by governance to set the new emission rate
    function setIncentiveEmissionRate(address tokenAddress, uint32 newEmissionsRate, uint256 blockTime) internal {
        // Ensure that the accumulatedNOTEPerNToken updates to the current block time before we update the
        // emission rate
        changeNTokenSupply(tokenAddress, 0, blockTime);

        mapping(address => nTokenContext) storage store = LibStorage.getNTokenContextStorage();
        nTokenContext storage context = store[tokenAddress];
        context.incentiveAnnualEmissionRate = newEmissionsRate;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {
    PrimeCashHoldingsOracle,
    PrimeCashFactorsStorage,
    PrimeCashFactors,
    PrimeRate,
    InterestRateParameters,
    InterestRateCurveSettings,
    BalanceState,
    TotalfCashDebtStorage
} from "../../global/Types.sol";
import {FloatingPoint} from "../../math/FloatingPoint.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

import {Emitter} from "../Emitter.sol";
import {InterestRateCurve} from "../markets/InterestRateCurve.sol";
import {TokenHandler} from "../balances/TokenHandler.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";

import {IPrimeCashHoldingsOracle} from "../../../interfaces/notional/IPrimeCashHoldingsOracle.sol";
import {IERC20} from "../../../interfaces/IERC20.sol";

library PrimeCashExchangeRate {
    using SafeInt256 for int256;
    using SafeUint256 for uint256;
    using InterestRateCurve for InterestRateParameters;

    event PrimeProxyDeployed(uint16 indexed currencyId, address proxy, bool isCashProxy);

    /// @notice Emits every time interest is accrued
    event PrimeCashInterestAccrued(
        uint16 indexed currencyId,
        uint256 underlyingScalar,
        uint256 supplyScalar,
        uint256 debtScalar
    );

    event PrimeCashCurveChanged(uint16 indexed currencyId);

    event PrimeCashHoldingsOracleUpdated(uint16 indexed currencyId, address oracle);

    /// @dev Reads prime cash factors from storage
    function getPrimeCashFactors(
        uint16 currencyId
    ) internal view returns (PrimeCashFactors memory p) {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        p.lastAccrueTime = s.lastAccrueTime;
        p.totalPrimeSupply = s.totalPrimeSupply;
        p.totalPrimeDebt = s.totalPrimeDebt;
        p.oracleSupplyRate = s.oracleSupplyRate;
        p.lastTotalUnderlyingValue = s.lastTotalUnderlyingValue;
        p.underlyingScalar = s.underlyingScalar;
        p.supplyScalar = s.supplyScalar;
        p.debtScalar = s.debtScalar;
        p.rateOracleTimeWindow = s.rateOracleTimeWindow5Min * 5 minutes;
    }

    function setProxyAddress(uint16 currencyId, address proxy, bool isCashProxy) internal {
        mapping(uint256 => address) storage store = isCashProxy ?
            LibStorage.getPCashAddressStorage() : LibStorage.getPDebtAddressStorage();

        // Cannot reset proxy address once set
        require(store[currencyId]== address(0)); // dev: proxy exists
        store[currencyId] = proxy;

        emit PrimeProxyDeployed(currencyId, proxy, isCashProxy);
    }

    function getCashProxyAddress(uint16 currencyId) internal view returns (address proxy) {
        proxy = LibStorage.getPCashAddressStorage()[currencyId];
    }

    function getDebtProxyAddress(uint16 currencyId) internal view returns (address proxy) {
        proxy = LibStorage.getPDebtAddressStorage()[currencyId];
    }

    function updatePrimeCashHoldingsOracle(
        uint16 currencyId,
        IPrimeCashHoldingsOracle oracle
    ) internal {
        // Set the prime cash holdings oracle first so that getTotalUnderlying will succeed
        PrimeCashHoldingsOracle storage s = LibStorage.getPrimeCashHoldingsOracle()[currencyId];
        s.oracle = oracle;

        emit PrimeCashHoldingsOracleUpdated(currencyId, address(oracle));
    }

    function getPrimeCashHoldingsOracle(uint16 currencyId) internal view returns (IPrimeCashHoldingsOracle) {
        PrimeCashHoldingsOracle storage s = LibStorage.getPrimeCashHoldingsOracle()[currencyId];
        return s.oracle;
    }

    /// @notice Returns the total value in underlying internal precision held by the
    /// Notional contract across actual underlying balances and any external money
    /// market tokens held.
    /// @dev External oracles allow:
    ///    - injection of mock oracles while testing
    ///    - adding additional protocols without having to upgrade the entire system
    ///    - reduces expensive storage reads, oracles can store the holdings information
    ///      in immutable variables which are compiled into bytecode and do not require SLOAD calls
    /// NOTE: stateful version is required for CompoundV2's accrueInterest method.
    function getTotalUnderlyingStateful(uint16 currencyId) internal returns (uint256) {
        (/* */, uint256 internalPrecision) = getPrimeCashHoldingsOracle(currencyId)
            .getTotalUnderlyingValueStateful();
        return internalPrecision;
    }

    function getTotalUnderlyingView(uint16 currencyId) internal view returns (uint256) {
        (/* */, uint256 internalPrecision) = getPrimeCashHoldingsOracle(currencyId)
            .getTotalUnderlyingValueView();
        return internalPrecision;
    }

    /// @notice Only called once during listing currencies to initialize the token balance storage. After this
    /// point the token balance storage will only be updated based on the net changes before and after deposits,
    /// withdraws, and treasury rebalancing. This is done so that donations to the protocol will not affect the
    /// valuation of prime cash.
    function initTokenBalanceStorage(uint16 currencyId, IPrimeCashHoldingsOracle oracle) internal {
        address[] memory holdings = oracle.holdings();
        address underlying = oracle.underlying();

        uint256 newBalance = currencyId == Constants.ETH_CURRENCY_ID ? 
            address(this).balance :
            IERC20(underlying).balanceOf(address(this));

        // prevBalanceOf is set to zero to ensure that this token balance has not been initialized yet
        TokenHandler.updateStoredTokenBalance(underlying, 0, newBalance);

        for (uint256 i; i < holdings.length; i++) {
            newBalance = IERC20(holdings[i]).balanceOf(address(this));
            TokenHandler.updateStoredTokenBalance(holdings[i], 0, newBalance);
        }
    }

    function initPrimeCashCurve(
        uint16 currencyId,
        uint88 totalPrimeSupply,
        InterestRateCurveSettings memory debtCurve,
        IPrimeCashHoldingsOracle oracle,
        bool allowDebt,
        uint8 rateOracleTimeWindow5Min
    ) internal {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        
        // Set the prime cash holdings oracle first so that getTotalUnderlying will succeed
        updatePrimeCashHoldingsOracle(currencyId, oracle);

        // Cannot re-initialize after the first time
        require(s.lastAccrueTime == 0);

        // Cannot initialize with zero supply balance or will be unable
        // to accrue the scalar the first time. Practically speaking, this
        // means that some dust amount of supply must be donated to the
        // reserve in order to initialize the prime cash market.
        require(0 < totalPrimeSupply);

        // Total underlying also cannot be initialized at zero or the underlying
        // scalar will be unable to accrue.
        uint256 currentTotalUnderlying = getTotalUnderlyingStateful(currencyId);
        require(0 < currentTotalUnderlying);

        s.lastAccrueTime = block.timestamp.toUint40();
        s.supplyScalar = uint80(Constants.SCALAR_PRECISION);
        s.debtScalar = uint80(Constants.SCALAR_PRECISION);
        s.totalPrimeSupply = totalPrimeSupply;
        s.allowDebt = allowDebt;
        s.rateOracleTimeWindow5Min = rateOracleTimeWindow5Min;

        s.underlyingScalar = currentTotalUnderlying
            .divInScalarPrecision(totalPrimeSupply).toUint80();
        s.lastTotalUnderlyingValue = currentTotalUnderlying.toUint88();

        // Total prime debt must be initialized at zero which implies an oracle supply
        // rate of zero (oracle supply rate here only applies to the prime cash supply).
        s.totalPrimeDebt = 0;
        s.oracleSupplyRate = 0;

        InterestRateCurve.setPrimeCashInterestRateParameters(currencyId, debtCurve);
        emit PrimeCashCurveChanged(currencyId);
    }

    function doesAllowPrimeDebt(uint16 currencyId) internal view returns (bool) {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        return s.allowDebt;
    }

    /// @notice Turns on prime cash debt. Cannot be turned off once set to true.
    function allowPrimeDebt(uint16 currencyId) internal {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        s.allowDebt = true;
    }

    function setRateOracleTimeWindow(uint16 currencyId, uint8 rateOracleTimeWindow5min) internal {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        s.rateOracleTimeWindow5Min = rateOracleTimeWindow5min;
    }

    function setMaxUnderlyingSupply(uint16 currencyId, uint256 maxUnderlyingSupply) internal returns (uint256 unpackedSupply) {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        s.maxUnderlyingSupply = FloatingPoint.packTo32Bits(maxUnderlyingSupply);
        unpackedSupply = FloatingPoint.unpackFromBits(uint256(s.maxUnderlyingSupply));
    }

    /// @notice Updates prime cash interest rate curve after initialization,
    /// called via governance
    function updatePrimeCashCurve(
        uint16 currencyId,
        InterestRateCurveSettings memory debtCurve
    ) internal {
        // Ensure that rates are accrued up to the current block before we change the
        // interest rate curve.
        getPrimeCashRateStateful(currencyId, block.timestamp);
        InterestRateCurve.setPrimeCashInterestRateParameters(currencyId, debtCurve);

        emit PrimeCashCurveChanged(currencyId);
    }

    /// @notice Sets the prime cash scalars on every accrual
    function _setPrimeCashFactorsOnAccrue(
        uint16 currencyId,
        uint256 primeSupplyToReserve,
        PrimeCashFactors memory p
    ) private {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        s.lastAccrueTime = p.lastAccrueTime.toUint40();
        s.underlyingScalar = p.underlyingScalar.toUint80();
        s.supplyScalar = p.supplyScalar.toUint80();
        s.debtScalar = p.debtScalar.toUint80();
        // totalPrimeSupply already includes the primeSupplyToReserve
        s.totalPrimeSupply = p.totalPrimeSupply.toUint88();
        s.totalPrimeDebt = p.totalPrimeDebt.toUint88();
        s.lastTotalUnderlyingValue = p.lastTotalUnderlyingValue.toUint88();
        s.oracleSupplyRate = p.oracleSupplyRate.toUint32();

        // Adds prime debt fees to the reserve
        if (primeSupplyToReserve > 0) {
            int256 primeSupply = primeSupplyToReserve.toInt();
            BalanceHandler.incrementFeeToReserve(currencyId, primeSupply);
            Emitter.emitMintOrBurnPrimeCash(Constants.FEE_RESERVE, currencyId, primeSupply);
        }

        emit PrimeCashInterestAccrued(
            currencyId, p.underlyingScalar, p.supplyScalar, p.debtScalar
        );
    }

    /// @notice Updates prime debt when borrowing occurs. Whenever borrowing occurs, prime
    /// supply also increases accordingly to mark that some lender in the system will now
    /// receive the accrued interest from the borrowing. This method will be called on two
    /// occasions:
    ///     - when a negative cash balance is stored outside of settlement 
    ///     - when fCash balances are settled (at the global level)
    function updateTotalPrimeDebt(
        address account,
        uint16 currencyId,
        int256 netPrimeDebtChange,
        int256 netPrimeSupplyChange
    ) internal {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        // This must always be true or we cannot update cash balances.
        require(s.lastAccrueTime == block.timestamp);

        // updateTotalPrimeDebt is only called in two scenarios:
        //  - when a negative cash balance is stored
        //  - when fCash settlement rates are set
        // Neither should be possible if allowDebt is false, fCash can only
        // be created once GovernanceAction.enableCashGroup is called and that
        // will trigger allowDebt to be set. allowDebt cannot be set to false once
        // it is set to true.
        require(s.allowDebt);

        int256 newTotalPrimeDebt = int256(uint256(s.totalPrimeDebt))
            .add(netPrimeDebtChange);
        
        // When totalPrimeDebt increases, totalPrimeSupply will also increase, no underflow
        // to zero occurs. Utilization will not exceed 100% since both values increase at the
        // same rate.

        // When totalPrimeDebt decreases, totalPrimeSupply will also decrease, but since
        // utilization is not allowed to exceed 100%, totalPrimeSupply will not go negative
        // here.
        int256 newTotalPrimeSupply = int256(uint256(s.totalPrimeSupply))
            .add(netPrimeSupplyChange);

        // PrimeRateLib#convertToStorageValue subtracts 1 from the value therefore may cause uint
        // to underflow. Clears the negative dust balance back to zero.
        if (-10 < newTotalPrimeDebt && newTotalPrimeDebt < 0) newTotalPrimeDebt = 0;
        if (-10 < newTotalPrimeSupply && newTotalPrimeSupply < 0) newTotalPrimeSupply = 0;

        s.totalPrimeDebt = newTotalPrimeDebt.toUint().toUint88();
        s.totalPrimeSupply = newTotalPrimeSupply.toUint().toUint88();

        Emitter.emitBorrowOrRepayPrimeDebt(account, currencyId, netPrimeSupplyChange, netPrimeDebtChange);
        _checkInvariant(s);
    }

    /// @notice Updates prime supply whenever tokens enter or exit the system.
    function updateTotalPrimeSupply(
        uint16 currencyId,
        int256 netPrimeSupplyChange,
        int256 netUnderlyingChange
    ) internal {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        // This must always be true or we cannot update cash balances.
        require(s.lastAccrueTime == block.timestamp);
        int256 newTotalPrimeSupply = int256(uint256(s.totalPrimeSupply))
            .add(netPrimeSupplyChange);
        int256 newLastTotalUnderlyingValue = int256(uint256(s.lastTotalUnderlyingValue))
            .add(netUnderlyingChange);

        require(Constants.MIN_TOTAL_UNDERLYING_VALUE <= newLastTotalUnderlyingValue); // dev: min underlying

        // lastTotalUnderlyingValue cannot be negative since we cannot hold a negative
        // balance, if that occurs then this will revert.
        s.lastTotalUnderlyingValue = newLastTotalUnderlyingValue.toUint().toUint88();

        // On deposits, total prime supply will increase. On withdraws, total prime supply
        // will decrease. It cannot decrease below the total underlying tokens held (which
        // itself is floored at zero). If total underlying tokens held is zero, then either
        // there is no supply or the prime cash market is at 100% utilization.
        s.totalPrimeSupply = newTotalPrimeSupply.toUint().toUint88();

        _checkInvariant(s);
    }

    function _checkInvariant(PrimeCashFactorsStorage storage s) private view {
        int256 supply = int256(s.supplyScalar).mul(s.underlyingScalar).mul(s.totalPrimeSupply);
        int256 debt = int256(s.debtScalar).mul(s.underlyingScalar).mul(s.totalPrimeDebt);
        // Adding 1 here ensures that any balances below 1e36 that will round off will not cause
        // invariant failures.
        int256 underlying = int256(s.lastTotalUnderlyingValue + 1).mul(Constants.DOUBLE_SCALAR_PRECISION);
        require(supply.sub(debt) <= underlying); // dev: invariant failed
    }

    function getTotalfCashDebtOutstanding(
        uint16 currencyId,
        uint256 maturity
    ) internal view returns (int256) {
        mapping(uint256 => mapping(uint256 => TotalfCashDebtStorage)) storage store = LibStorage.getTotalfCashDebtOutstanding();
        return -int256(store[currencyId][maturity].totalfCashDebt);
    }

    function updateSettlementReserveForVaultsLendingAtZero(
        address vault,
        uint16 currencyId,
        uint256 maturity,
        int256 primeCashToReserve,
        int256 fCashToLend
    ) internal {
        mapping(uint256 => mapping(uint256 => TotalfCashDebtStorage)) storage store = LibStorage.getTotalfCashDebtOutstanding();
        TotalfCashDebtStorage storage s = store[currencyId][maturity];

        // Increase both figures (fCashDebt held is positive in storage)
        s.fCashDebtHeldInSettlementReserve = fCashToLend.toUint()
            .add(s.fCashDebtHeldInSettlementReserve).toUint80();
        s.primeCashHeldInSettlementReserve = primeCashToReserve.toUint()
            .add(s.primeCashHeldInSettlementReserve).toUint80();

        Emitter.emitTransferPrimeCash(vault, Constants.SETTLEMENT_RESERVE, currencyId, primeCashToReserve);
        // Minting fCash liquidity on the settlement reserve
        Emitter.emitChangefCashLiquidity(Constants.SETTLEMENT_RESERVE, currencyId, maturity, fCashToLend);
        // Positive fCash is transferred to the vault (the vault will burn it)
        Emitter.emitTransferfCash(Constants.SETTLEMENT_RESERVE, vault, currencyId, maturity, fCashToLend);
    }

    function updateTotalfCashDebtOutstanding(
        address account,
        uint16 currencyId,
        uint256 maturity,
        int256 initialfCashAmount,
        int256 finalfCashAmount
    ) internal {
        int256 netDebtChange = initialfCashAmount.negChange(finalfCashAmount);
        if (netDebtChange == 0) return;

        mapping(uint256 => mapping(uint256 => TotalfCashDebtStorage)) storage store = LibStorage.getTotalfCashDebtOutstanding();
        // No overflow due to storage size
        int256 totalDebt = -int256(store[currencyId][maturity].totalfCashDebt);
        // Total fCash Debt outstanding is negative, netDebtChange is a positive signed value
        // (i.e. netDebtChange > 0 is more debt, not less)
        int256 newTotalDebt = totalDebt.sub(netDebtChange);
        require(newTotalDebt <= 0);
        store[currencyId][maturity].totalfCashDebt = newTotalDebt.neg().toUint().toUint80();

        // Throughout the entire Notional system, negative fCash is only created when
        // when an fCash pair is minted in this method. Negative fCash is never "transferred"
        // in the system, only positive side of the fCash tokens are bought and sold.

        // When net debt changes, we emit a burn of fCash liquidity as the total debt in the
        // system has decreased.

        // When fCash debt is created (netDebtChange increases) we must mint an fCash
        // pair to ensure that total positive fCash equals total negative fCash. This
        // occurs when minting nTokens, initializing new markets, and if an account
        // transfers fCash via ERC1155 to a negative balance (effectively an OTC market
        // making operation).
        Emitter.emitChangefCashLiquidity(account, currencyId, maturity, netDebtChange);
    }

    function getPrimeInterestRates(
        uint16 currencyId,
        PrimeCashFactors memory factors
    ) internal view returns (
        uint256 annualDebtRatePreFee,
        uint256 annualDebtRatePostFee,
        uint256 annualSupplyRate
    ) {
        // Utilization is calculated in underlying terms:
        //  utilization = accruedDebtUnderlying / accruedSupplyUnderlying
        //  (totalDebt * underlyingScalar * debtScalar) / 
        //      (totalSupply * underlyingScalar * supplyScalar)
        //
        // NOTE: underlyingScalar cancels out in both numerator and denominator
        uint256 utilization;
        if (factors.totalPrimeSupply > 0) {
            // Avoid divide by zero error, supplyScalar is monotonic and initialized to 1
            utilization = factors.totalPrimeDebt.mul(factors.debtScalar)
                .divInRatePrecision(factors.totalPrimeSupply.mul(factors.supplyScalar));
        }
        InterestRateParameters memory i = InterestRateCurve.getPrimeCashInterestRateParameters(currencyId);
        
        annualDebtRatePreFee = i.getInterestRate(utilization);
        // If utilization is zero, then the annualDebtRate will be zero (as defined in the
        // interest rate curve). If we get the post fee interest rate, then the annual debt
        // rate will show some small amount and cause the debt scalar to accrue.
        if (utilization > 0) {
            // Debt rates are always "borrow" and therefore increase the interest rate
            annualDebtRatePostFee = i.getPostFeeInterestRate(annualDebtRatePreFee, true);
        }

        // Lenders receive the borrow interest accrued amortized over the total supply:
        // (annualDebtRatePreFee * totalUnderlyingDebt) / totalUnderlyingSupply,
        // this is effectively the utilization calculated above.
        if (factors.totalPrimeSupply > 0) {
            annualSupplyRate = annualDebtRatePreFee.mulInRatePrecision(utilization);
        }
    }

    /// @notice If there are fees that accrue to the reserve due to a difference in the debt rate pre fee
    /// and the debt rate post fee, calculate the amount of prime supply that goes to the reserve here.
    /// The total prime supply to the reserve is the difference in the debt scalar pre and post fee applied
    /// to the total prime debt.
    function _getScalarIncrease(
        uint16 currencyId,
        uint256 blockTime,
        PrimeCashFactors memory prior
    ) private view returns (
        uint256 debtScalarWithFee,
        uint256 newSupplyScalar,
        uint256 primeSupplyToReserve,
        uint256 annualSupplyRate
    ) {
        uint256 annualDebtRatePreFee;
        uint256 annualDebtRatePostFee;
        (annualDebtRatePreFee, annualDebtRatePostFee, annualSupplyRate) = getPrimeInterestRates(currencyId, prior);

        // Interest rates need to be scaled up to scalar precision, so we scale the time since last
        // accrue by RATE_PRECISION to save some calculations.
        // if lastAccrueTime > blockTime, will revert
        uint256 scaledTimeSinceLastAccrue = uint256(Constants.RATE_PRECISION)
            .mul(blockTime.sub(prior.lastAccrueTime));

        debtScalarWithFee = prior.debtScalar.mulInScalarPrecision(
            Constants.SCALAR_PRECISION.add(
                // No division underflow
                annualDebtRatePostFee.mul(scaledTimeSinceLastAccrue) / Constants.YEAR
            )
        );

        newSupplyScalar = prior.supplyScalar.mulInScalarPrecision(
            Constants.SCALAR_PRECISION.add(
                // No division underflow
                annualSupplyRate.mul(scaledTimeSinceLastAccrue) / Constants.YEAR
            )
        );

        // If the debt rates are the same pre and post fee, then no prime supply will be sent to the reserve.
        if (annualDebtRatePreFee == annualDebtRatePostFee) {
            return (debtScalarWithFee, newSupplyScalar, 0, annualSupplyRate);
        }

        // Calculate the increase in the debt scalar:
        // debtScalarIncrease = debtScalarWithFee - debtScalarWithoutFee
        uint256 debtScalarNoFee = prior.debtScalar.mulInScalarPrecision(
            Constants.SCALAR_PRECISION.add(
                // No division underflow
                annualDebtRatePreFee.mul(scaledTimeSinceLastAccrue) / Constants.YEAR
            )
        );
        uint256 debtScalarIncrease = debtScalarWithFee.sub(debtScalarNoFee);
        // Total prime debt paid to the reserve is:
        //  underlyingToReserve = totalPrimeDebt * debtScalarIncrease * underlyingScalar / SCALAR_PRECISION^2
        //  primeSupplyToReserve = (underlyingToReserve * SCALAR_PRECISION^2) / (supplyScalar * underlyingScalar)
        //
        //  Combining and cancelling terms results in:
        //  primeSupplyToReserve = (totalPrimeDebt * debtScalarIncrease) / supplyScalar
        primeSupplyToReserve = prior.totalPrimeDebt.mul(debtScalarIncrease).div(newSupplyScalar);
    }

    /// @notice Accrues interest to the prime cash supply scalar and debt scalar
    /// up to the current block time.
    /// @return PrimeCashFactors prime cash factors accrued up to current time
    /// @return uint256 prime supply to the reserve
    function _updatePrimeCashScalars(
        uint16 currencyId,
        PrimeCashFactors memory prior,
        uint256 currentUnderlyingValue,
        uint256 blockTime
    ) private view returns (PrimeCashFactors memory, uint256) {
        uint256 primeSupplyToReserve;
        uint256 annualSupplyRate;
        (
            prior.debtScalar,
            prior.supplyScalar,
            primeSupplyToReserve,
            annualSupplyRate
        ) = _getScalarIncrease(currencyId, blockTime, prior);

        // Prime supply is added in memory here. In getPrimeCashStateful, the actual storage values
        // will increase as well.
        prior.totalPrimeSupply = prior.totalPrimeSupply.add(primeSupplyToReserve);

        // Accrue the underlyingScalar, which represents interest earned via
        // external money market protocols.
        {
            // NOTE: this subtract reverts if this is negative. This is possible in two conditions:
            //  - the underlying value was not properly updated on the last exit
            //  - there is a misreporting in an external protocol, either due to logic error
            //    or some incident that requires a haircut to lenders
            uint256 underlyingInterestRate;

            if (prior.lastTotalUnderlyingValue > 0) {
                // If lastTotalUnderlyingValue == 0 (meaning we have no tokens held), then the
                // underlying interest rate is exactly zero and we avoid a divide by zero error.
                underlyingInterestRate = currentUnderlyingValue.sub(prior.lastTotalUnderlyingValue)
                    .divInScalarPrecision(prior.lastTotalUnderlyingValue);
            }

            prior.underlyingScalar = prior.underlyingScalar
                .mulInScalarPrecision(Constants.SCALAR_PRECISION.add(underlyingInterestRate));
            prior.lastTotalUnderlyingValue = currentUnderlyingValue;
        }

        // Update the last accrue time
        prior.lastAccrueTime = blockTime;

        return (prior, primeSupplyToReserve);
    }

    /// @notice Gets current prime cash exchange rates without setting anything
    /// in storage. Should ONLY be used for off-chain interaction.
    function getPrimeCashRateView(
        uint16 currencyId,
        uint256 blockTime
    ) internal view returns (PrimeRate memory rate, PrimeCashFactors memory factors) {
        factors = getPrimeCashFactors(currencyId);

        // Only accrue if the block time has increased
        if (factors.lastAccrueTime < blockTime) {
            uint256 currentUnderlyingValue = getTotalUnderlyingView(currencyId);
            (factors, /* primeSupplyToReserve */) = _updatePrimeCashScalars(
                currencyId, factors, currentUnderlyingValue, blockTime
            );
        } else {
            require(factors.lastAccrueTime == blockTime); // dev: revert invalid blocktime
        }

        rate = PrimeRate({
            supplyFactor: factors.supplyScalar.mul(factors.underlyingScalar).toInt(),
            debtFactor: factors.debtScalar.mul(factors.underlyingScalar).toInt(),
            oracleSupplyRate: factors.oracleSupplyRate
        });
    }

    /// @notice Gets current prime cash exchange rates and writes to storage.
    function getPrimeCashRateStateful(
        uint16 currencyId,
        uint256 blockTime
    ) internal returns (PrimeRate memory rate) {
        PrimeCashFactors memory factors = getPrimeCashFactors(currencyId);

        // Only accrue if the block time has increased
        if (factors.lastAccrueTime < blockTime) {
            uint256 primeSupplyToReserve;
            uint256 currentUnderlyingValue = getTotalUnderlyingStateful(currencyId);
            (factors, primeSupplyToReserve) = _updatePrimeCashScalars(
                currencyId, factors, currentUnderlyingValue, blockTime
            );
            _setPrimeCashFactorsOnAccrue(currencyId, primeSupplyToReserve, factors);
        } else {
            require(factors.lastAccrueTime == blockTime); // dev: revert invalid blocktime
        }

        rate = PrimeRate({
            supplyFactor: factors.supplyScalar.mul(factors.underlyingScalar).toInt(),
            debtFactor: factors.debtScalar.mul(factors.underlyingScalar).toInt(),
            oracleSupplyRate: factors.oracleSupplyRate
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PrimeRate,
    PrimeCashFactors,
    PrimeCashFactorsStorage,
    PrimeSettlementRateStorage,
    MarketParameters,
    TotalfCashDebtStorage
} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {Deployments} from "../../global/Deployments.sol";

import {FloatingPoint} from "../../math/FloatingPoint.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

import {Emitter} from "../Emitter.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";
import {nTokenHandler} from "../nToken/nTokenHandler.sol";
import {PrimeCashExchangeRate} from "./PrimeCashExchangeRate.sol";
import {Market} from "../markets/Market.sol";

library PrimeRateLib {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;
    using Market for MarketParameters;

    /// @notice Emitted when a settlement rate is set
    event SetPrimeSettlementRate(
        uint256 indexed currencyId,
        uint256 indexed maturity,
        int256 supplyFactor,
        int256 debtFactor
    );

    /// Prime cash balances are stored differently than they are used on the stack
    /// and in memory. On the stack, all prime cash balances (positive and negative) are fungible
    /// with each other and denominated in prime cash supply terms. In storage, negative prime cash
    /// (i.e. prime cash debt) is is stored in different terms so that it can properly accrue interest
    /// over time. In other words, positive prime cash balances are static (non-rebasing), but negative
    /// prime cash balances are monotonically increasing (i.e. rebasing) over time. This is because a
    /// negative prime cash balance represents an ever increasing amount of positive prime cash owed.
    ///
    /// Math is as follows:
    ///   positivePrimeSupply * supplyFactor = underlying
    ///   negativePrimeDebt * debtFactor = underlying
    ///
    /// Setting them equal:
    ///   positivePrimeSupply * supplyFactor = negativePrimeDebt * debtFactor
    ///
    ///   positivePrimeSupply = (negativePrimeDebt * debtFactor) / supplyFactor
    ///   negativePrimeDebt = (positivePrimeSupply * supplyFactor) / debtFactor
    
    /// @notice Converts stored cash balance into a signed value in prime supply
    /// terms (see comment above)
    function convertFromStorage(
        PrimeRate memory pr,
        int256 storedCashBalance
    ) internal pure returns (int256 signedPrimeSupplyValue) {
        if (storedCashBalance >= 0) {
            return storedCashBalance;
        } else {
            // Convert negative stored cash balance to signed prime supply value
            // signedPrimeSupply = (negativePrimeDebt * debtFactor) / supplyFactor

            // cashBalance is stored as int88, debt factor is uint80 * uint80 so there
            // is no chance of phantom overflow (88 + 80 + 80 = 248) on mul
            return storedCashBalance.mul(pr.debtFactor).div(pr.supplyFactor);
        }
    }

    function convertSettledfCashView(
        PrimeRate memory presentPrimeRate,
        uint16 currencyId,
        uint256 maturity,
        int256 fCashBalance,
        uint256 blockTime
    ) internal view returns (int256 signedPrimeSupplyValue) {
        PrimeRate memory settledPrimeRate = buildPrimeRateSettlementView(currencyId, maturity, blockTime);
        (signedPrimeSupplyValue, /* */) = _convertSettledfCash(presentPrimeRate, settledPrimeRate, fCashBalance);
    }

    function convertSettledfCashInVault(
        uint16 currencyId,
        uint256 maturity,
        int256 fCashBalance,
        address vault
    ) internal returns (int256 settledPrimeStorageValue) {
        (PrimeRate memory settledPrimeRate, bool isSet) = _getPrimeSettlementRate(currencyId, maturity);
        // Requires that the vault has a settlement rate set first. This means that markets have been
        // initialized already. Vaults cannot have idiosyncratic borrow dates so relying on market initialization
        // is safe.
        require(isSet); // dev: settlement rate unset

        // This is exactly how much prime debt the vault owes at settlement.
        settledPrimeStorageValue = convertUnderlyingToDebtStorage(settledPrimeRate, fCashBalance);

        // Only emit the settle fcash event for the vault, not individual accounts
        if (vault != address(0)) {
            Emitter.emitSettlefCash(
                vault, currencyId, maturity, fCashBalance, settledPrimeStorageValue
            );
        }
    }

    /// @notice Converts settled fCash to the current signed prime supply value
    function convertSettledfCash(
        PrimeRate memory presentPrimeRate,
        address account,
        uint16 currencyId,
        uint256 maturity,
        int256 fCashBalance,
        uint256 blockTime
    ) internal returns (int256 signedPrimeSupplyValue) {
        PrimeRate memory settledPrimeRate = buildPrimeRateSettlementStateful(currencyId, maturity, blockTime);

        int256 settledPrimeStorageValue;
        (signedPrimeSupplyValue, settledPrimeStorageValue) = _convertSettledfCash(
            presentPrimeRate, settledPrimeRate, fCashBalance
        );

        // Allows vault accounts to suppress this event because it is not relevant to them
        if (account != address(0)) {
            Emitter.emitSettlefCash(
                account, currencyId, maturity, fCashBalance, settledPrimeStorageValue
            );
        }
    }

    /// @notice Converts an fCash balance to a signed prime supply value.
    /// @return signedPrimeSupplyValue the current (signed) prime cash value of the fCash 
    /// @return settledPrimeStorageValue the storage value of the fCash at settlement, used for
    /// emitting events only
    function _convertSettledfCash(
        PrimeRate memory presentPrimeRate,
        PrimeRate memory settledPrimeRate,
        int256 fCashBalance
    ) private pure returns (int256 signedPrimeSupplyValue, int256 settledPrimeStorageValue) {
        // These values are valid at the time of settlement.
        signedPrimeSupplyValue = convertFromUnderlying(settledPrimeRate, fCashBalance);
        settledPrimeStorageValue = convertToStorageValue(settledPrimeRate, signedPrimeSupplyValue);

        // If the signed prime supply value is negative, we need to accrue interest on the
        // debt up to the present from the settled prime rate. This simulates storing the
        // the debt, reading the debt from storage and then accruing interest up to the
        // current time. This is only required for debt values.
        // debtSharesAtSettlement = signedPrimeSupplyValue * settled.supplyFactor / settled.debtFactor
        // currentSignedPrimeSupplyValue = debtSharesAtSettlement * present.debtFactor / present.supplyFactor
        if (signedPrimeSupplyValue < 0) {
            // Divide between multiplication actions to protect against a phantom overflow at 256 due
            // to the two mul in the numerator.
            signedPrimeSupplyValue = signedPrimeSupplyValue
                .mul(settledPrimeRate.supplyFactor)
                .div(settledPrimeRate.debtFactor)
                .mul(presentPrimeRate.debtFactor)
                .div(presentPrimeRate.supplyFactor)
                // subtract one to protect protocol against rounding errors in division operations
                .sub(1);
        }
    }

    function convertToStorageValue(
        PrimeRate memory pr,
        int256 signedPrimeSupplyValueToStore
    ) internal pure returns (int256 newStoredCashBalance) {
        newStoredCashBalance = signedPrimeSupplyValueToStore >= 0 ?
            signedPrimeSupplyValueToStore :
            // negativePrimeDebt = (signedPrimeSupply * supplyFactor) / debtFactor
            // subtract one to increase debt and protect protocol against rounding errors
            signedPrimeSupplyValueToStore.mul(pr.supplyFactor).div(pr.debtFactor).sub(1);
    }

    /// @notice Updates total prime debt during settlement if debts are repaid by cash
    /// balances.
    /// @param pr current prime rate
    /// @param currencyId currency id this prime rate refers to
    /// @param previousSignedCashBalance the previous signed supply value of the stored cash balance
    /// @param positiveSettledCash amount of positive cash balances that have settled
    /// @param negativeSettledCash amount of negative cash balances that have settled
    function convertToStorageInSettlement(
        PrimeRate memory pr,
        address account,
        uint16 currencyId,
        int256 previousSignedCashBalance,
        int256 positiveSettledCash,
        int256 negativeSettledCash
    ) internal returns (int256 newStoredCashBalance) {
        // The new cash balance is the sum of all the balances converted to a proper storage value
        int256 endSignedBalance = previousSignedCashBalance.add(positiveSettledCash).add(negativeSettledCash);
        newStoredCashBalance = convertToStorageValue(pr, endSignedBalance);

        // At settlement, the total prime debt outstanding is increased by the total fCash debt
        // outstanding figure in `_settleTotalfCashDebts`. This figure, however, is not aware of
        // individual accounts that have sufficient cash (or matured fCash) to repay a settled debt.
        // An example of the scenario would be an account with:
        //      +100 units of ETH cash balance, -50 units of matured fETH
        //
        // At settlement the total ETH debt outstanding is set to -50 ETH, causing an increase in
        // prime cash utilization and an increase to the prime cash debt rate. If this account settled
        // exactly at maturity, they would have +50 units of ETH cash balance and have accrued zero
        // additional variable rate debt. However, since the the smart contract is not made aware of this
        // without an explicit settlement transaction, it will continue to accrue interest to prime cash
        // suppliers (meaning that this account is paying variable interest on its -50 units of matured
        // fETH until it actually issues a settlement transaction).
        //
        // The effect of this is that the account will be paying the spread between the prime cash supply
        // interest rate and the prime debt interest rate for the period where it is not settled. If the
        // account remains un-settled for long enough, it will slowly creep into insolvency (i.e. once the
        // debt is greater than the cash, the account is insolvent). However, settlement transactions are
        // permission-less and only require the payment of a minor gas cost so anyone can settle an account
        // to stop the accrual of the variable rate debt and prevent an insolvency.
        //
        // The variable debt accrued by this account up to present time must be paid and is calculated
        // in `_convertSettledfCash`. The logic below will detect the netPrimeDebtChange based on the
        // cash balances and settled amounts and properly update the total prime debt figure accordingly.

        // Only need to update total prime debt when there is a debt repayment via existing cash balances
        // or positive settled cash. In all other cases, settled prime debt or existing prime debt are
        // already captured by the total prime debt figure.
        require(0 <= positiveSettledCash);
        require(negativeSettledCash <= 0);

        if (0 < previousSignedCashBalance) {
            positiveSettledCash = previousSignedCashBalance.add(positiveSettledCash);
        } else {
            negativeSettledCash = previousSignedCashBalance.add(negativeSettledCash);
        }

        int256 netPrimeSupplyChange;
        if (negativeSettledCash.neg() < positiveSettledCash) {
            // All of the negative settled cash is repaid
            netPrimeSupplyChange = negativeSettledCash;
        } else {
            // Positive cash portion of the debt is repaid
            netPrimeSupplyChange = positiveSettledCash.neg();
        }

        // netPrimeSupplyChange should always be negative or zero at this point
        if (netPrimeSupplyChange < 0) {
            int256 netPrimeDebtChange = netPrimeSupplyChange.mul(pr.supplyFactor).div(pr.debtFactor);

            PrimeCashExchangeRate.updateTotalPrimeDebt(
                account,
                currencyId,
                netPrimeDebtChange,
                netPrimeSupplyChange
            );
        }
    }

    /// @notice Converts signed prime supply value into a stored prime cash balance
    /// value, converting negative prime supply values into prime debt values if required.
    /// Also, updates totalPrimeDebt based on the net change in storage values. Should not
    /// be called during settlement.
    function convertToStorageNonSettlementNonVault(
        PrimeRate memory pr,
        address account,
        uint16 currencyId,
        int256 previousStoredCashBalance,
        int256 signedPrimeSupplyValueToStore
    ) internal returns (int256 newStoredCashBalance) {
        newStoredCashBalance = convertToStorageValue(pr, signedPrimeSupplyValueToStore);
        updateTotalPrimeDebt(
            pr,
            account,
            currencyId,
            // This will return 0 if both cash balances are positive.
            previousStoredCashBalance.negChange(newStoredCashBalance)
        );
    }

    /// @notice Updates totalPrimeDebt given the change to the stored cash balance
    function updateTotalPrimeDebt(
        PrimeRate memory pr,
        address account,
        uint16 currencyId,
        int256 netPrimeDebtChange
    ) internal {
        if (netPrimeDebtChange != 0) {
            // Whenever prime debt changes, prime supply must also change to the same degree in
            // its own denomination. This marks the position of some lender in the system who
            // will receive the repayment of the debt change.
            // NOTE: total prime supply will also change when tokens enter or exit the system.
            int256 netPrimeSupplyChange = netPrimeDebtChange.mul(pr.debtFactor).div(pr.supplyFactor);

            PrimeCashExchangeRate.updateTotalPrimeDebt(
                account,
                currencyId,
                netPrimeDebtChange,
                netPrimeSupplyChange
            );
        }
    }

    /// @notice Converts a prime cash balance to underlying (both in internal 8
    /// decimal precision).
    function convertToUnderlying(
        PrimeRate memory pr,
        int256 primeCashBalance
    ) internal pure returns (int256) {
        return primeCashBalance.mul(pr.supplyFactor).div(Constants.DOUBLE_SCALAR_PRECISION);
    }

    /// @notice Converts underlying to a prime cash balance (both in internal 8
    /// decimal precision).
    function convertFromUnderlying(
        PrimeRate memory pr,
        int256 underlyingBalance
    ) internal pure returns (int256) {
        return underlyingBalance.mul(Constants.DOUBLE_SCALAR_PRECISION).div(pr.supplyFactor);
    }

    function convertDebtStorageToUnderlying(
        PrimeRate memory pr,
        int256 debtStorage
    ) internal pure returns (int256) {
        // debtStorage must be negative
        require(debtStorage < 1);
        if (debtStorage == 0) return 0;

        return debtStorage.mul(pr.debtFactor).div(Constants.DOUBLE_SCALAR_PRECISION).sub(1);
    }

    function convertUnderlyingToDebtStorage(
        PrimeRate memory pr,
        int256 underlying
    ) internal pure returns (int256) {
        // Floor dust balances at zero to prevent the following require check from reverting
        if (0 <= underlying && underlying < 10) return 0;
        require(underlying < 0);
        // underlying debt is specified as a negative number and therefore subtract
        // one to protect the protocol against rounding errors
        return underlying.mul(Constants.DOUBLE_SCALAR_PRECISION).div(pr.debtFactor).sub(1);
    }
    
    /// @notice Returns a prime rate object accrued up to the current time and updates
    /// values in storage.
    function buildPrimeRateStateful(
        uint16 currencyId
    ) internal returns (PrimeRate memory) {
        return PrimeCashExchangeRate.getPrimeCashRateStateful(currencyId, block.timestamp);
    }

    /// @notice Returns a prime rate object for settlement at a particular maturity
    function buildPrimeRateSettlementView(
        uint16 currencyId,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (PrimeRate memory pr) {
        bool isSet;
        (pr, isSet) = _getPrimeSettlementRate(currencyId, maturity);
        
        if (!isSet) {
            // Return the current cash rate if settlement rate not found
            (pr, /* */) = PrimeCashExchangeRate.getPrimeCashRateView(currencyId, blockTime);
        }
    }

    /// @notice Returns a prime rate object for settlement at a particular maturity,
    /// and sets both accrued values and the settlement rate (if not set already).
    function buildPrimeRateSettlementStateful(
        uint16 currencyId,
        uint256 maturity,
        uint256 blockTime
    ) internal returns (PrimeRate memory pr) {
        bool isSet;
        (pr, isSet) = _getPrimeSettlementRate(currencyId, maturity);

        if (!isSet) {
            pr = _setPrimeSettlementRate(currencyId, maturity, blockTime);
        }
    }

    /// @notice Loads the settlement rate from storage or uses the current rate if it
    /// has not yet been set.
    function _getPrimeSettlementRate(
        uint16 currencyId,
        uint256 maturity
    ) private view returns (PrimeRate memory pr, bool isSet) {
        mapping(uint256 => mapping(uint256 =>
            PrimeSettlementRateStorage)) storage store = LibStorage.getPrimeSettlementRates();
        PrimeSettlementRateStorage storage rateStorage = store[currencyId][maturity];
        isSet = rateStorage.isSet;

        // If the settlement rate is not set, then this method will return zeros
        if (isSet) {
            uint256 underlyingScalar = rateStorage.underlyingScalar;
            pr.supplyFactor = int256(uint256(rateStorage.supplyScalar).mul(underlyingScalar));
            pr.debtFactor = int256(uint256(rateStorage.debtScalar).mul(underlyingScalar));
        }
    }

    function _setPrimeSettlementRate(
        uint16 currencyId,
        uint256 maturity,
        uint256 blockTime
    ) private returns (PrimeRate memory pr) {
        // Accrues prime rates up to current time and sets them
        pr = PrimeCashExchangeRate.getPrimeCashRateStateful(currencyId, blockTime);
        // These are the accrued factors
        PrimeCashFactors memory factors = PrimeCashExchangeRate.getPrimeCashFactors(currencyId);

        mapping(uint256 => mapping(uint256 =>
            PrimeSettlementRateStorage)) storage store = LibStorage.getPrimeSettlementRates();
        PrimeSettlementRateStorage storage rateStorage = store[currencyId][maturity];

        require(Deployments.NOTIONAL_V2_FINAL_SETTLEMENT < maturity); // dev: final settlement
        require(factors.lastAccrueTime == blockTime); // dev: did not accrue
        require(0 < blockTime); // dev: zero block time
        require(maturity <= blockTime); // dev: settlement rate timestamp
        require(0 < pr.supplyFactor); // dev: settlement rate zero
        require(0 < pr.debtFactor); // dev: settlement rate zero

        rateStorage.underlyingScalar = factors.underlyingScalar.toUint80();
        rateStorage.supplyScalar = factors.supplyScalar.toUint80();
        rateStorage.debtScalar = factors.debtScalar.toUint80();
        rateStorage.isSet = true;

        _settleTotalfCashDebts(currencyId, maturity, pr);

        emit SetPrimeSettlementRate(
            currencyId,
            maturity,
            pr.supplyFactor,
            pr.debtFactor
        );
    }

    function _settleTotalfCashDebts(
        uint16 currencyId,
        uint256 maturity,
        PrimeRate memory settlementRate
    ) private {
        mapping(uint256 => mapping(uint256 => TotalfCashDebtStorage)) storage store = LibStorage.getTotalfCashDebtOutstanding();
        TotalfCashDebtStorage storage s = store[currencyId][maturity];
        int256 totalDebt = -int256(s.totalfCashDebt);
        
        // The nToken must be settled first via InitializeMarkets if there is any liquidity
        // in the matching market (if one exists).
        MarketParameters memory market;
        market.loadSettlementMarket(currencyId, maturity, maturity);
        require(market.totalLiquidity == 0, "Must init markets");

        // totalDebt is negative, but netPrimeSupplyChange and netPrimeDebtChange must both be positive
        // since we are increasing the total debt load.
        int256 netPrimeSupplyChange = convertFromUnderlying(settlementRate, totalDebt.neg());
        int256 netPrimeDebtChange = convertUnderlyingToDebtStorage(settlementRate, totalDebt).neg();

        // The settlement reserve will receive all of the prime debt initially and each account
        // will receive prime cash or prime debt as they settle individually.
        PrimeCashExchangeRate.updateTotalPrimeDebt(
            Constants.SETTLEMENT_RESERVE, currencyId, netPrimeDebtChange, netPrimeSupplyChange
        );

        // This is purely done to fully reconcile off chain accounting with the edge condition where
        // leveraged vaults lend at zero interest. In this code block, no prime debt is created or
        // destroyed (the totalfCashDebt figure above does not include fCashDebt held in settlement
        // reserve). Only prime cash held in reserve is burned to repay the settled debt. Excess cash
        // is sent to the fee reserve.
        int256 fCashDebtInReserve = -int256(s.fCashDebtHeldInSettlementReserve);
        int256 primeCashInReserve = int256(s.primeCashHeldInSettlementReserve);
        if (fCashDebtInReserve < 0 || 0 < primeCashInReserve) {
            int256 settledDebtInPrimeCash = convertFromUnderlying(settlementRate, fCashDebtInReserve);
            // 0 < primeCashInReserve 0 and settledDebtInPrimeCash < 0
            int256 excessCash = primeCashInReserve.add(settledDebtInPrimeCash);
            if (0 < excessCash) {
                BalanceHandler.incrementFeeToReserve(currencyId, excessCash);
            } 

            Emitter.emitSettlefCashDebtInReserve(
                currencyId, maturity, fCashDebtInReserve, settledDebtInPrimeCash, excessCash
            );
        }

        // Clear the storage slot, no longer needed
        delete store[currencyId][maturity];
    }

    /// @notice Checks whether or not a currency has exceeded its total prime supply cap. Used to
    /// prevent some listed currencies to be used as collateral above a threshold where liquidations
    /// can be safely done on chain.
    /// @dev Called during deposits in AccountAction and BatchAction. Supply caps are not checked
    /// during settlement, liquidation and withdraws.
    function checkSupplyCap(PrimeRate memory pr, uint16 currencyId) internal view {
        (uint256 maxUnderlyingSupply, uint256 totalUnderlyingSupply) = getSupplyCap(pr, currencyId);
        if (maxUnderlyingSupply == 0) return;

        require(totalUnderlyingSupply <= maxUnderlyingSupply, "Over Supply Cap");
    }

    function getSupplyCap(
        PrimeRate memory pr,
        uint16 currencyId
    ) internal view returns (uint256 maxUnderlyingSupply, uint256 totalUnderlyingSupply) {
        PrimeCashFactorsStorage storage s = LibStorage.getPrimeCashFactors()[currencyId];
        maxUnderlyingSupply = FloatingPoint.unpackFromBits(s.maxUnderlyingSupply);
        // No potential for overflow due to storage size
        int256 totalPrimeSupply = int256(uint256(s.totalPrimeSupply));
        totalUnderlyingSupply = convertToUnderlying(pr, totalPrimeSupply).toUint();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PrimeRate,
    CashGroupParameters,
    AccountContext,
    PortfolioAsset,
    ifCashStorage
} from "../../global/Types.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {Bitmap} from "../../math/Bitmap.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";

import {AccountContextHandler} from "../AccountContextHandler.sol";
import {CashGroup} from "../markets/CashGroup.sol";
import {DateTime} from "../markets/DateTime.sol";
import {AssetHandler} from "../valuation/AssetHandler.sol";
import {PrimeCashExchangeRate} from "../pCash/PrimeCashExchangeRate.sol";

library BitmapAssetsHandler {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;
    using Bitmap for bytes32;
    using CashGroup for CashGroupParameters;
    using AccountContextHandler for AccountContext;

    function getAssetsBitmap(address account, uint256 currencyId) internal view returns (bytes32 assetsBitmap) {
        mapping(address => mapping(uint256 => bytes32)) storage store = LibStorage.getAssetsBitmapStorage();
        return store[account][currencyId];
    }

    function setAssetsBitmap(
        address account,
        uint256 currencyId,
        bytes32 assetsBitmap
    ) internal {
        require(assetsBitmap.totalBitsSet() <= Constants.MAX_BITMAP_ASSETS, "Over max assets");
        mapping(address => mapping(uint256 => bytes32)) storage store = LibStorage.getAssetsBitmapStorage();
        store[account][currencyId] = assetsBitmap;
    }

    function getifCashNotional(
        address account,
        uint256 currencyId,
        uint256 maturity
    ) internal view returns (int256 notional) {
        mapping(address => mapping(uint256 =>
            mapping(uint256 => ifCashStorage))) storage store = LibStorage.getifCashBitmapStorage();
        return store[account][currencyId][maturity].notional;
    }

    /// @notice Adds multiple assets to a bitmap portfolio
    function addMultipleifCashAssets(
        address account,
        AccountContext memory accountContext,
        PortfolioAsset[] memory assets
    ) internal {
        require(accountContext.isBitmapEnabled()); // dev: bitmap currency not set
        uint16 currencyId = accountContext.bitmapCurrencyId;

        for (uint256 i; i < assets.length; i++) {
            PortfolioAsset memory asset = assets[i];
            if (asset.notional == 0) continue;

            require(asset.currencyId == currencyId); // dev: invalid asset in set ifcash assets
            require(asset.assetType == Constants.FCASH_ASSET_TYPE); // dev: invalid asset in set ifcash assets
            int256 finalNotional;

            finalNotional = addifCashAsset(
                account,
                currencyId,
                asset.maturity,
                accountContext.nextSettleTime,
                asset.notional
            );

            if (finalNotional < 0)
                accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_ASSET_DEBT;
        }
    }

    /// @notice Add an ifCash asset in the bitmap and mapping. Updates the bitmap in memory
    /// but not in storage.
    /// @return the updated assets bitmap and the final notional amount
    function addifCashAsset(
        address account,
        uint16 currencyId,
        uint256 maturity,
        uint256 nextSettleTime,
        int256 notional
    ) internal returns (int256) {
        bytes32 assetsBitmap = getAssetsBitmap(account, currencyId);
        mapping(address => mapping(uint256 =>
            mapping(uint256 => ifCashStorage))) storage store = LibStorage.getifCashBitmapStorage();
        ifCashStorage storage fCashSlot = store[account][currencyId][maturity];
        (uint256 bitNum, bool isExact) = DateTime.getBitNumFromMaturity(nextSettleTime, maturity);
        require(isExact); // dev: invalid maturity in set ifcash asset

        if (assetsBitmap.isBitSet(bitNum)) {
            // Bit is set so we read and update the notional amount
            int256 initialNotional = fCashSlot.notional;
            int256 finalNotional = notional.add(initialNotional);
            fCashSlot.notional = finalNotional.toInt128();

            PrimeCashExchangeRate.updateTotalfCashDebtOutstanding(
                account, currencyId, maturity, initialNotional, finalNotional
            );

            // If the new notional is zero then turn off the bit
            if (finalNotional == 0) {
                assetsBitmap = assetsBitmap.setBit(bitNum, false);
            }

            setAssetsBitmap(account, currencyId, assetsBitmap);
            return finalNotional;
        }

        if (notional != 0) {
            // Bit is not set so we turn it on and update the mapping directly, no read required.
            fCashSlot.notional = notional.toInt128();

            PrimeCashExchangeRate.updateTotalfCashDebtOutstanding(
                account,
                currencyId,
                maturity,
                0, // bit was not set, so initial notional value is zero
                notional
            );

            assetsBitmap = assetsBitmap.setBit(bitNum, true);
            setAssetsBitmap(account, currencyId, assetsBitmap);
        }

        return notional;
    }

    /// @notice Returns the present value of an asset
    function getPresentValue(
        address account,
        uint256 currencyId,
        uint256 maturity,
        uint256 blockTime,
        CashGroupParameters memory cashGroup,
        bool riskAdjusted
    ) internal view returns (int256) {
        int256 notional = getifCashNotional(account, currencyId, maturity);

        // In this case the asset has matured and the total value is just the notional amount
        if (maturity <= blockTime) {
            return notional;
        } else {
            if (riskAdjusted) {
                return AssetHandler.getRiskAdjustedPresentfCashValue(
                    cashGroup, notional, maturity, blockTime
                );
            } else {
                uint256 oracleRate = cashGroup.calculateOracleRate(maturity, blockTime);
                return AssetHandler.getPresentfCashValue(
                    notional,
                    maturity,
                    blockTime,
                    oracleRate
                );
            }
        }
    }

    function getNetPresentValueFromBitmap(
        address account,
        uint256 currencyId,
        uint256 nextSettleTime,
        uint256 blockTime,
        CashGroupParameters memory cashGroup,
        bool riskAdjusted,
        bytes32 assetsBitmap
    ) internal view returns (int256 totalValueUnderlying, bool hasDebt) {
        uint256 bitNum = assetsBitmap.getNextBitNum();

        while (bitNum != 0) {
            uint256 maturity = DateTime.getMaturityFromBitNum(nextSettleTime, bitNum);
            int256 pv = getPresentValue(
                account,
                currencyId,
                maturity,
                blockTime,
                cashGroup,
                riskAdjusted
            );
            totalValueUnderlying = totalValueUnderlying.add(pv);

            if (pv < 0) hasDebt = true;

            // Turn off the bit and look for the next one
            assetsBitmap = assetsBitmap.setBit(bitNum, false);
            bitNum = assetsBitmap.getNextBitNum();
        }
    }

    /// @notice Get the net present value of all the ifCash assets
    function getifCashNetPresentValue(
        address account,
        uint256 currencyId,
        uint256 nextSettleTime,
        uint256 blockTime,
        CashGroupParameters memory cashGroup,
        bool riskAdjusted
    ) internal view returns (int256 totalValueUnderlying, bool hasDebt) {
        bytes32 assetsBitmap = getAssetsBitmap(account, currencyId);
        return getNetPresentValueFromBitmap(
            account,
            currencyId,
            nextSettleTime,
            blockTime,
            cashGroup,
            riskAdjusted,
            assetsBitmap
        );
    }

    /// @notice Returns the ifCash assets as an array
    function getifCashArray(
        address account,
        uint16 currencyId,
        uint256 nextSettleTime
    ) internal view returns (PortfolioAsset[] memory) {
        bytes32 assetsBitmap = getAssetsBitmap(account, currencyId);
        uint256 index = assetsBitmap.totalBitsSet();
        PortfolioAsset[] memory assets = new PortfolioAsset[](index);
        index = 0;

        uint256 bitNum = assetsBitmap.getNextBitNum();
        while (bitNum != 0) {
            uint256 maturity = DateTime.getMaturityFromBitNum(nextSettleTime, bitNum);
            int256 notional = getifCashNotional(account, currencyId, maturity);

            PortfolioAsset memory asset = assets[index];
            asset.currencyId = currencyId;
            asset.maturity = maturity;
            asset.assetType = Constants.FCASH_ASSET_TYPE;
            asset.notional = notional;
            index += 1;

            // Turn off the bit and look for the next one
            assetsBitmap = assetsBitmap.setBit(bitNum, false);
            bitNum = assetsBitmap.getNextBitNum();
        }

        return assets;
    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PortfolioState,
    PortfolioAsset,
    PortfolioAssetStorage,
    AssetStorageState
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {TransferAssets} from "./TransferAssets.sol";
import {AssetHandler} from "../valuation/AssetHandler.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

/// @notice Handles the management of an array of assets including reading from storage, inserting
/// updating, deleting and writing back to storage.
library PortfolioHandler {
    using SafeInt256 for int256;
    using AssetHandler for PortfolioAsset;

    // Mirror of LibStorage.MAX_PORTFOLIO_ASSETS
    uint256 private constant MAX_PORTFOLIO_ASSETS = 8;

    /// @notice Primarily used by the TransferAssets library
    function addMultipleAssets(PortfolioState memory portfolioState, PortfolioAsset[] memory assets)
        internal
        pure
    {
        for (uint256 i = 0; i < assets.length; i++) {
            PortfolioAsset memory asset = assets[i];
            if (asset.notional == 0) continue;

            addAsset(
                portfolioState,
                asset.currencyId,
                asset.maturity,
                asset.assetType,
                asset.notional
            );
        }
    }

    function _mergeAssetIntoArray(
        PortfolioAsset[] memory assetArray,
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType,
        int256 notional
    ) private pure returns (bool) {
        for (uint256 i = 0; i < assetArray.length; i++) {
            PortfolioAsset memory asset = assetArray[i];
            if (
                asset.assetType != assetType ||
                asset.currencyId != currencyId ||
                asset.maturity != maturity
            ) continue;

            // Either of these storage states mean that some error in logic has occurred, we cannot
            // store this portfolio
            require(
                asset.storageState != AssetStorageState.Delete &&
                asset.storageState != AssetStorageState.RevertIfStored
            ); // dev: portfolio handler deleted storage

            int256 newNotional = asset.notional.add(notional);
            // Liquidity tokens cannot be reduced below zero.
            if (AssetHandler.isLiquidityToken(assetType)) {
                require(newNotional >= 0); // dev: portfolio handler negative liquidity token balance
            }

            require(newNotional >= type(int88).min && newNotional <= type(int88).max); // dev: portfolio handler notional overflow

            asset.notional = newNotional;
            asset.storageState = AssetStorageState.Update;

            return true;
        }

        return false;
    }

    /// @notice Adds an asset to a portfolio state in memory (does not write to storage)
    /// @dev Ensures that only one version of an asset exists in a portfolio (i.e. does not allow two fCash assets of the same maturity
    /// to exist in a single portfolio). Also ensures that liquidity tokens do not have a negative notional.
    function addAsset(
        PortfolioState memory portfolioState,
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType,
        int256 notional
    ) internal pure {
        if (
            // Will return true if merged
            _mergeAssetIntoArray(
                portfolioState.storedAssets,
                currencyId,
                maturity,
                assetType,
                notional
            )
        ) return;

        if (portfolioState.lastNewAssetIndex > 0) {
            bool merged = _mergeAssetIntoArray(
                portfolioState.newAssets,
                currencyId,
                maturity,
                assetType,
                notional
            );
            if (merged) return;
        }

        // At this point if we have not merged the asset then append to the array
        // Cannot remove liquidity that the portfolio does not have
        if (AssetHandler.isLiquidityToken(assetType)) {
            require(notional >= 0); // dev: portfolio handler negative liquidity token balance
        }
        require(notional >= type(int88).min && notional <= type(int88).max); // dev: portfolio handler notional overflow

        // Need to provision a new array at this point
        if (portfolioState.lastNewAssetIndex == portfolioState.newAssets.length) {
            portfolioState.newAssets = _extendNewAssetArray(portfolioState.newAssets);
        }

        // Otherwise add to the new assets array. It should not be possible to add matching assets in a single transaction, we will
        // check this again when we write to storage. Assigning to memory directly here, do not allocate new memory via struct.
        PortfolioAsset memory newAsset = portfolioState.newAssets[portfolioState.lastNewAssetIndex];
        newAsset.currencyId = currencyId;
        newAsset.maturity = maturity;
        newAsset.assetType = assetType;
        newAsset.notional = notional;
        newAsset.storageState = AssetStorageState.NoChange;
        portfolioState.lastNewAssetIndex += 1;
    }

    /// @dev Extends the new asset array if it is not large enough, this is likely to get a bit expensive if we do
    /// it too much
    function _extendNewAssetArray(PortfolioAsset[] memory newAssets)
        private
        pure
        returns (PortfolioAsset[] memory)
    {
        // Double the size of the new asset array every time we have to extend to reduce the number of times
        // that we have to extend it. This will go: 0, 1, 2, 4, 8 (probably stops there).
        uint256 newLength = newAssets.length == 0 ? 1 : newAssets.length * 2;
        PortfolioAsset[] memory extendedArray = new PortfolioAsset[](newLength);
        for (uint256 i = 0; i < newAssets.length; i++) {
            extendedArray[i] = newAssets[i];
        }

        return extendedArray;
    }

    /// @notice Takes a portfolio state and writes it to storage.
    /// @dev This method should only be called directly by the nToken. Account updates to portfolios should happen via
    /// the storeAssetsAndUpdateContext call in the AccountContextHandler.sol library.
    /// @return updated variables to update the account context with
    ///     hasDebt: whether or not the portfolio has negative fCash assets
    ///     portfolioActiveCurrencies: a byte32 word with all the currencies in the portfolio
    ///     uint8: the length of the storage array
    ///     uint40: the new nextSettleTime for the portfolio
    function storeAssets(PortfolioState memory portfolioState, address account)
        internal
        returns (
            bool,
            bytes32,
            uint8,
            uint40
        )
    {
        bool hasDebt;
        // NOTE: cannot have more than 16 assets or this byte object will overflow. Max assets is
        // set to 7 and the worst case during liquidation would be 7 liquidity tokens that generate
        // 7 additional fCash assets for a total of 14 assets. Although even in this case all assets
        // would be of the same currency so it would not change the end result of the active currency
        // calculation.
        bytes32 portfolioActiveCurrencies;
        uint256 nextSettleTime;

        for (uint256 i = 0; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.storedAssets[i];
            // NOTE: this is to prevent the storage of assets that have been modified in the AssetHandler
            // during valuation.
            require(asset.storageState != AssetStorageState.RevertIfStored);

            // Mark any zero notional assets as deleted
            if (asset.storageState != AssetStorageState.Delete && asset.notional == 0) {
                deleteAsset(portfolioState, i);
            }
        }

        // First delete assets from asset storage to maintain asset storage indexes
        for (uint256 i = 0; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.storedAssets[i];

            if (asset.storageState == AssetStorageState.Delete) {
                // Delete asset from storage
                uint256 currentSlot = asset.storageSlot;
                assembly {
                    sstore(currentSlot, 0x00)
                }
            } else {
                if (asset.storageState == AssetStorageState.Update) {
                    PortfolioAssetStorage storage assetStorage;
                    uint256 currentSlot = asset.storageSlot;
                    assembly {
                        assetStorage.slot := currentSlot
                    }

                    _storeAsset(asset, assetStorage);
                }

                // Update portfolio context for every asset that is in storage, whether it is
                // updated in storage or not.
                (hasDebt, portfolioActiveCurrencies, nextSettleTime) = _updatePortfolioContext(
                    asset,
                    hasDebt,
                    portfolioActiveCurrencies,
                    nextSettleTime
                );
            }
        }

        // Add new assets
        uint256 assetStorageLength = portfolioState.storedAssetLength;
        mapping(address => 
            PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS]) storage store = LibStorage.getPortfolioArrayStorage();
        PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS] storage storageArray = store[account];
        for (uint256 i = 0; i < portfolioState.newAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.newAssets[i];
            if (asset.notional == 0) continue;
            require(
                asset.storageState != AssetStorageState.Delete &&
                asset.storageState != AssetStorageState.RevertIfStored
            ); // dev: store assets deleted storage

            (hasDebt, portfolioActiveCurrencies, nextSettleTime) = _updatePortfolioContext(
                asset,
                hasDebt,
                portfolioActiveCurrencies,
                nextSettleTime
            );

            _storeAsset(asset, storageArray[assetStorageLength]);
            assetStorageLength += 1;
        }

        // 16 is the maximum number of assets or portfolio active currencies will overflow its
        // 32 bytes size given 2 bytes per currency
        require(assetStorageLength <= 16); // dev: active currencies bytes32 overflow
        require(nextSettleTime <= type(uint40).max); // dev: portfolio return value overflow
        return (
            hasDebt,
            portfolioActiveCurrencies,
            uint8(assetStorageLength),
            uint40(nextSettleTime)
        );
    }

    /// @notice Updates context information during the store assets method
    function _updatePortfolioContext(
        PortfolioAsset memory asset,
        bool hasDebt,
        bytes32 portfolioActiveCurrencies,
        uint256 nextSettleTime
    )
        private
        pure
        returns (
            bool,
            bytes32,
            uint256
        )
    {
        uint256 settlementDate = asset.getSettlementDate();
        // Tis will set it to the minimum settlement date
        if (nextSettleTime == 0 || nextSettleTime > settlementDate) {
            nextSettleTime = settlementDate;
        }
        hasDebt = hasDebt || asset.notional < 0;

        require(uint16(uint256(portfolioActiveCurrencies)) == 0); // dev: portfolio active currencies overflow
        portfolioActiveCurrencies = 
            (portfolioActiveCurrencies >> 16) | 
            (bytes32(uint256(asset.currencyId)) << 240);

        return (hasDebt, portfolioActiveCurrencies, nextSettleTime);
    }

    /// @dev Encodes assets for storage
    function _storeAsset(
        PortfolioAsset memory asset,
        PortfolioAssetStorage storage assetStorage
    ) internal {
        require(0 < asset.currencyId && asset.currencyId <= Constants.MAX_CURRENCIES); // dev: encode asset currency id overflow
        require(0 < asset.maturity && asset.maturity <= type(uint40).max); // dev: encode asset maturity overflow
        require(0 < asset.assetType && asset.assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX); // dev: encode asset type invalid
        require(type(int88).min <= asset.notional && asset.notional <= type(int88).max); // dev: encode asset notional overflow

        assetStorage.currencyId = uint16(asset.currencyId);
        assetStorage.maturity = uint40(asset.maturity);
        assetStorage.assetType = uint8(asset.assetType);
        assetStorage.notional = int88(asset.notional);
    }

    /// @notice Deletes an asset from a portfolio
    /// @dev This method should only be called during settlement, assets can only be removed from a portfolio before settlement
    /// by adding the offsetting negative position
    function deleteAsset(PortfolioState memory portfolioState, uint256 index) internal pure {
        require(index < portfolioState.storedAssets.length); // dev: stored assets bounds
        require(portfolioState.storedAssetLength > 0); // dev: stored assets length is zero
        PortfolioAsset memory assetToDelete = portfolioState.storedAssets[index];
        require(
            assetToDelete.storageState != AssetStorageState.Delete &&
            assetToDelete.storageState != AssetStorageState.RevertIfStored
        ); // dev: cannot delete asset

        portfolioState.storedAssetLength -= 1;

        uint256 maxActiveSlotIndex;
        uint256 maxActiveSlot;
        // The max active slot is the last storage slot where an asset exists, it's not clear where this will be in the
        // array so we search for it here.
        for (uint256 i; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory a = portfolioState.storedAssets[i];
            if (a.storageSlot > maxActiveSlot && a.storageState != AssetStorageState.Delete) {
                maxActiveSlot = a.storageSlot;
                maxActiveSlotIndex = i;
            }
        }

        if (index == maxActiveSlotIndex) {
            // In this case we are deleting the asset with the max storage slot so no swap is necessary.
            assetToDelete.storageState = AssetStorageState.Delete;
            return;
        }

        // Swap the storage slots of the deleted asset with the last non-deleted asset in the array. Mark them accordingly
        // so that when we call store assets they will be updated appropriately
        PortfolioAsset memory assetToSwap = portfolioState.storedAssets[maxActiveSlotIndex];
        (
            assetToSwap.storageSlot,
            assetToDelete.storageSlot
        ) = (
            assetToDelete.storageSlot,
            assetToSwap.storageSlot
        );
        assetToSwap.storageState = AssetStorageState.Update;
        assetToDelete.storageState = AssetStorageState.Delete;
    }

    /// @notice Returns a portfolio array, will be sorted
    function getSortedPortfolio(address account, uint8 assetArrayLength)
        internal view returns (PortfolioAsset[] memory assets) {
        (assets, /* */) = getSortedPortfolioWithIds(account, assetArrayLength);
    }

    function getSortedPortfolioWithIds(address account, uint8 assetArrayLength)
        internal view returns (PortfolioAsset[] memory assets, uint256[] memory ids) {
        assets = _loadAssetArray(account, assetArrayLength);
        ids = _sortInPlace(assets);
    }

    /// @notice Builds a portfolio array from storage. The new assets hint parameter will
    /// be used to provision a new array for the new assets. This will increase gas efficiency
    /// so that we don't have to make copies when we extend the array.
    function buildPortfolioState(
        address account,
        uint8 assetArrayLength,
        uint256 newAssetsHint
    ) internal view returns (PortfolioState memory) {
        PortfolioState memory state;
        if (assetArrayLength == 0) return state;

        state.storedAssets = getSortedPortfolio(account, assetArrayLength);
        state.storedAssetLength = assetArrayLength;
        state.newAssets = new PortfolioAsset[](newAssetsHint);

        return state;
    }

    function _sortId(uint16 currencyId, uint256 maturity, uint256 assetType) private pure returns (uint256) {
        return uint256(
            (bytes32(uint256(currencyId)) << 48) |
                (bytes32(uint256(uint40(maturity))) << 8) |
                bytes32(uint256(uint8(assetType)))
        );
    }

    function _sortInPlace(
        PortfolioAsset[] memory assets
    ) private pure returns (uint256[] memory ids) {
        uint256 length = assets.length;
        ids = new uint256[](length);
        for (uint256 k; k < length; k++) {
            PortfolioAsset memory asset = assets[k];
            // Prepopulate the ids to calculate just once
            ids[k] = _sortId(asset.currencyId, asset.maturity, asset.assetType);
        }

        // Uses insertion sort 
        uint256 i = 1;
        while (i < length) {
            uint256 j = i;
            while (j > 0 && ids[j - 1] > ids[j]) {
                // Swap j - 1 and j
                (ids[j - 1], ids[j]) = (ids[j], ids[j - 1]);
                (assets[j - 1], assets[j]) = (assets[j], assets[j - 1]);
                j--;
            }
            i++;
        }
    }

    function _loadAssetArray(address account, uint8 length)
        private
        view
        returns (PortfolioAsset[] memory)
    {
        // This will overflow the storage pointer
        require(length <= MAX_PORTFOLIO_ASSETS);

        mapping(address => 
            PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS]) storage store = LibStorage.getPortfolioArrayStorage();
        PortfolioAssetStorage[MAX_PORTFOLIO_ASSETS] storage storageArray = store[account];
        PortfolioAsset[] memory assets = new PortfolioAsset[](length);

        for (uint256 i = 0; i < length; i++) {
            PortfolioAssetStorage storage assetStorage = storageArray[i];
            PortfolioAsset memory asset = assets[i];
            uint256 slot;
            assembly {
                slot := assetStorage.slot
            }

            asset.currencyId = assetStorage.currencyId;
            asset.maturity = assetStorage.maturity;
            asset.assetType = assetStorage.assetType;
            asset.notional = assetStorage.notional;
            asset.storageSlot = slot;
        }

        return assets;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PortfolioState,
    PortfolioAsset,
    AccountContext
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {PortfolioHandler} from "./PortfolioHandler.sol";
import {BitmapAssetsHandler} from "./BitmapAssetsHandler.sol";
import {AccountContextHandler} from "../AccountContextHandler.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";

/// @notice Helper library for transferring assets from one portfolio to another
library TransferAssets {
    using AccountContextHandler for AccountContext;
    using PortfolioHandler for PortfolioState;
    using SafeInt256 for int256;

    /// @dev Used to flip the sign of assets to decrement the `from` account that is sending assets
    function invertNotionalAmountsInPlace(PortfolioAsset[] memory assets) internal pure {
        for (uint256 i; i < assets.length; i++) {
            assets[i].notional = assets[i].notional.neg();
        }
    }

    /// @dev Useful method for hiding the logic of updating an account. WARNING: the account
    /// context returned from this method may not be the same memory location as the account
    /// context provided if the account is settled.
    function placeAssetsInAccount(
        address account,
        AccountContext memory accountContext,
        PortfolioAsset[] memory assets
    ) internal returns (AccountContext memory) {
        // If an account has assets that require settlement then placing assets inside it
        // may cause issues.
        require(!accountContext.mustSettleAssets(), "Account must settle");

        if (accountContext.isBitmapEnabled()) {
            // Adds fCash assets into the account and finalized storage
            BitmapAssetsHandler.addMultipleifCashAssets(account, accountContext, assets);
        } else {
            PortfolioState memory portfolioState = PortfolioHandler.buildPortfolioState(
                account,
                accountContext.assetArrayLength,
                assets.length
            );
            // This will add assets in memory
            portfolioState.addMultipleAssets(assets);
            // This will store assets and update the account context in memory
            accountContext.storeAssetsAndUpdateContext(account, portfolioState);
        }

        return accountContext;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {PrimeRate, ifCashStorage} from "../../global/Types.sol";
import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {Bitmap} from "../../math/Bitmap.sol";

import {DateTime} from "../markets/DateTime.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {BitmapAssetsHandler} from "../portfolio/BitmapAssetsHandler.sol";

/**
 * Settles a bitmap portfolio by checking for all matured fCash assets and turning them into cash
 * at the prevailing settlement rate. It will also update the asset bitmap to ensure that it continues
 * to correctly reference all actual maturities. fCash asset notional values are stored in *absolute* 
 * time terms and bitmap bits are *relative* time terms based on the bitNumber and the stored oldSettleTime.
 * Remapping bits requires converting the old relative bit numbers to new relative bit numbers based on
 * newSettleTime and the absolute times (maturities) that the previous bitmap references.
 */
library SettleBitmapAssets {
    using PrimeRateLib for PrimeRate;
    using SafeInt256 for int256;
    using Bitmap for bytes32;

    /// @notice Given a bitmap for a cash group and timestamps, will settle all assets
    /// that have matured and remap the bitmap to correspond to the current time.
    function settleBitmappedCashGroup(
        address account,
        uint16 currencyId,
        uint256 oldSettleTime,
        uint256 blockTime,
        PrimeRate memory presentPrimeRate
    ) internal returns (int256 positiveSettledCash, int256 negativeSettledCash, uint256 newSettleTime) {
        bytes32 bitmap = BitmapAssetsHandler.getAssetsBitmap(account, currencyId);

        // This newSettleTime will be set to the new `oldSettleTime`. The bits between 1 and
        // `lastSettleBit` (inclusive) will be shifted out of the bitmap and settled. The reason
        // that lastSettleBit is inclusive is that it refers to newSettleTime which always less
        // than the current block time.
        newSettleTime = DateTime.getTimeUTC0(blockTime);
        // If newSettleTime == oldSettleTime lastSettleBit will be zero
        require(newSettleTime >= oldSettleTime); // dev: new settle time before previous

        // Do not need to worry about validity, if newSettleTime is not on an exact bit we will settle up until
        // the closest maturity that is less than newSettleTime.
        (uint256 lastSettleBit, /* isValid */) = DateTime.getBitNumFromMaturity(oldSettleTime, newSettleTime);
        if (lastSettleBit == 0) return (0, 0, newSettleTime);

        // Returns the next bit that is set in the bitmap
        uint256 nextBitNum = bitmap.getNextBitNum();
        while (nextBitNum != 0 && nextBitNum <= lastSettleBit) {
            uint256 maturity = DateTime.getMaturityFromBitNum(oldSettleTime, nextBitNum);
            int256 settledPrimeCash = _settlefCashAsset(account, currencyId, maturity, blockTime, presentPrimeRate);

            // Split up positive and negative amounts so that total prime debt can be properly updated later
            if (settledPrimeCash > 0) {
                positiveSettledCash = positiveSettledCash.add(settledPrimeCash);
            } else {
                negativeSettledCash = negativeSettledCash.add(settledPrimeCash);
            }

            // Turn the bit off now that it is settled
            bitmap = bitmap.setBit(nextBitNum, false);
            nextBitNum = bitmap.getNextBitNum();
        }

        bytes32 newBitmap;
        while (nextBitNum != 0) {
            uint256 maturity = DateTime.getMaturityFromBitNum(oldSettleTime, nextBitNum);
            (uint256 newBitNum, bool isValid) = DateTime.getBitNumFromMaturity(newSettleTime, maturity);
            require(isValid); // dev: invalid new bit num

            newBitmap = newBitmap.setBit(newBitNum, true);

            // Turn the bit off now that it is remapped
            bitmap = bitmap.setBit(nextBitNum, false);
            nextBitNum = bitmap.getNextBitNum();
        }

        BitmapAssetsHandler.setAssetsBitmap(account, currencyId, newBitmap);
    }

    /// @dev Stateful settlement function to settle a bitmapped asset. Deletes the
    /// asset from storage after calculating it.
    function _settlefCashAsset(
        address account,
        uint16 currencyId,
        uint256 maturity,
        uint256 blockTime,
        PrimeRate memory presentPrimeRate
    ) private returns (int256 signedPrimeSupplyValue) {
        mapping(address => mapping(uint256 =>
            mapping(uint256 => ifCashStorage))) storage store = LibStorage.getifCashBitmapStorage();
        int256 notional = store[account][currencyId][maturity].notional;
        
        // Gets the current settlement rate or will store a new settlement rate if it does not
        // yet exist.
        signedPrimeSupplyValue = presentPrimeRate.convertSettledfCash(
            account, currencyId, maturity, notional, blockTime
        );

        delete store[account][currencyId][maturity];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {SettleAmount, AssetStorageState, PrimeRate} from "../../global/Types.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {Constants} from "../../global/Constants.sol";

import {PortfolioAsset, AssetHandler} from "../valuation/AssetHandler.sol";
import {Market, MarketParameters} from "../markets/Market.sol";
import {PortfolioState, PortfolioHandler} from "../portfolio/PortfolioHandler.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";

library SettlePortfolioAssets {
    using SafeInt256 for int256;
    using PrimeRateLib for PrimeRate;
    using Market for MarketParameters;
    using PortfolioHandler for PortfolioState;
    using AssetHandler for PortfolioAsset;

    /// @dev Returns a SettleAmount array for the assets that will be settled
    function _getSettleAmountArray(
        PortfolioState memory portfolioState,
        uint256 blockTime
    ) private returns (SettleAmount[] memory) {
        uint256 currenciesSettled;
        uint16 lastCurrencyId = 0;
        if (portfolioState.storedAssets.length == 0) return new SettleAmount[](0);

        // Loop backwards so "lastCurrencyId" will be set to the first currency in the portfolio
        // NOTE: if this contract is ever upgraded to Solidity 0.8+ then this i-- will underflow and cause
        // a revert, must wrap in an unchecked.
        for (uint256 i = portfolioState.storedAssets.length; (i--) > 0;) {
            PortfolioAsset memory asset = portfolioState.storedAssets[i];
            // Assets settle on exactly blockTime
            if (asset.getSettlementDate() > blockTime) continue;

            // Assume that this is sorted by cash group and maturity, currencyId = 0 is unused so this
            // will work for the first asset
            if (lastCurrencyId != asset.currencyId) {
                lastCurrencyId = asset.currencyId;
                currenciesSettled++;
            }
        }

        // Actual currency ids will be set as we loop through the portfolio and settle assets
        SettleAmount[] memory settleAmounts = new SettleAmount[](currenciesSettled);
        if (currenciesSettled > 0) {
            settleAmounts[0].currencyId = lastCurrencyId;
            settleAmounts[0].presentPrimeRate = PrimeRateLib.buildPrimeRateStateful(lastCurrencyId);
        }

        return settleAmounts;
    }

    /// @notice Settles a portfolio array
    function settlePortfolio(
        address account,
        PortfolioState memory portfolioState,
        uint256 blockTime
    ) internal returns (SettleAmount[] memory) {
        SettleAmount[] memory settleAmounts = _getSettleAmountArray(portfolioState, blockTime);
        if (settleAmounts.length == 0) return settleAmounts;
        uint256 settleAmountIndex;

        for (uint256 i; i < portfolioState.storedAssets.length; i++) {
            PortfolioAsset memory asset = portfolioState.storedAssets[i];
            // Settlement date is on block time exactly
            if (asset.getSettlementDate() > blockTime) continue;

            // On the first loop the lastCurrencyId is already set.
            if (settleAmounts[settleAmountIndex].currencyId != asset.currencyId) {
                // New currency in the portfolio
                settleAmountIndex += 1;
                settleAmounts[settleAmountIndex].currencyId = asset.currencyId;
                settleAmounts[settleAmountIndex].presentPrimeRate =
                    PrimeRateLib.buildPrimeRateStateful(asset.currencyId);
            }
            SettleAmount memory sa = settleAmounts[settleAmountIndex];

            // Only the nToken is allowed to hold liquidity tokens
            require(asset.assetType == Constants.FCASH_ASSET_TYPE);
            // Gets or sets the settlement rate, only do this before settling fCash
            int256 primeCash = sa.presentPrimeRate.convertSettledfCash(
                account, asset.currencyId, asset.maturity, asset.notional, blockTime
            );
            portfolioState.deleteAsset(i);

            // Positive and negative settled cash are not net off in this method, they have to be
            // split up in order to properly update the total prime debt outstanding figure.
            if (primeCash > 0) {
                sa.positiveSettledCash = sa.positiveSettledCash.add(primeCash);
            } else {
                sa.negativeSettledCash = sa.negativeSettledCash.add(primeCash);
            }
        }

        return settleAmounts;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PrimeRate,
    CashGroupParameters,
    PortfolioAsset,
    MarketParameters
} from "../../global/Types.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {SafeUint256} from "../../math/SafeUint256.sol";
import {ABDKMath64x64} from "../../math/ABDKMath64x64.sol";
import {Constants} from "../../global/Constants.sol";

import {DateTime} from "../markets/DateTime.sol";
import {CashGroup} from "../markets/CashGroup.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {PortfolioHandler} from "../portfolio/PortfolioHandler.sol";

library AssetHandler {
    using SafeUint256 for uint256;
    using SafeInt256 for int256;
    using CashGroup for CashGroupParameters;
    using PrimeRateLib for PrimeRate;

    function isLiquidityToken(uint256 assetType) internal pure returns (bool) {
        return
            assetType >= Constants.MIN_LIQUIDITY_TOKEN_INDEX &&
            assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX;
    }

    /// @notice Liquidity tokens settle every 90 days (not at the designated maturity). This method
    /// calculates the settlement date for any PortfolioAsset.
    function getSettlementDate(PortfolioAsset memory asset) internal pure returns (uint256) {
        require(asset.assetType > 0 && asset.assetType <= Constants.MAX_LIQUIDITY_TOKEN_INDEX); // dev: settlement date invalid asset type
        // 3 month tokens and fCash tokens settle at maturity
        if (asset.assetType <= Constants.MIN_LIQUIDITY_TOKEN_INDEX) return asset.maturity;

        uint256 marketLength = DateTime.getTradedMarket(asset.assetType - 1);
        // Liquidity tokens settle at tRef + 90 days. The formula to get a maturity is:
        // maturity = tRef + marketLength
        // Here we calculate:
        // tRef = (maturity - marketLength) + 90 days
        return asset.maturity.sub(marketLength).add(Constants.QUARTER);
    }

    /// @notice Returns the continuously compounded discount rate given an oracle rate and a time to maturity.
    /// The formula is: e^(-rate * timeToMaturity).
    function getDiscountFactor(uint256 timeToMaturity, uint256 oracleRate)
        internal
        pure
        returns (int256)
    {
        int128 expValue =
            ABDKMath64x64.fromUInt(oracleRate.mul(timeToMaturity).div(Constants.YEAR));
        expValue = ABDKMath64x64.div(expValue, Constants.RATE_PRECISION_64x64);
        expValue = ABDKMath64x64.exp(ABDKMath64x64.neg(expValue));
        expValue = ABDKMath64x64.mul(expValue, Constants.RATE_PRECISION_64x64);
        int256 discountFactor = ABDKMath64x64.toInt(expValue);

        return discountFactor;
    }

    /// @notice Present value of an fCash asset without any risk adjustments.
    function getPresentfCashValue(
        int256 notional,
        uint256 maturity,
        uint256 blockTime,
        uint256 oracleRate
    ) internal pure returns (int256) {
        if (notional == 0) return 0;

        // NOTE: this will revert if maturity < blockTime. That is the correct behavior because we cannot
        // discount matured assets.
        uint256 timeToMaturity = maturity.sub(blockTime);
        int256 discountFactor = getDiscountFactor(timeToMaturity, oracleRate);

        require(discountFactor <= Constants.RATE_PRECISION); // dev: get present value invalid discount factor
        return notional.mulInRatePrecision(discountFactor);
    }

    function getRiskAdjustedfCashDiscount(
        CashGroupParameters memory cashGroup,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (int256 discountFactor) {
        uint256 oracleRate = cashGroup.calculateRiskAdjustedfCashOracleRate(maturity, blockTime);
        discountFactor = getDiscountFactor(maturity.sub(blockTime), oracleRate);
        int256 maxDiscountFactor = cashGroup.getMaxDiscountFactor();
        if (maxDiscountFactor < discountFactor) discountFactor = maxDiscountFactor;
    }

    function getRiskAdjustedDebtDiscount(
        CashGroupParameters memory cashGroup,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (int256 discountFactor) {
        uint256 oracleRate = cashGroup.calculateRiskAdjustedDebtOracleRate(maturity, blockTime);
        discountFactor = oracleRate == 0 ? 
            // Short circuit the expensive calculation if the oracle rate is floored to zero here.
            Constants.RATE_PRECISION :
            getDiscountFactor(maturity.sub(blockTime), oracleRate);
    }

    /// @notice Present value of an fCash asset with risk adjustments. Positive fCash value will be discounted more
    /// heavily than the oracle rate given and vice versa for negative fCash.
    function getRiskAdjustedPresentfCashValue(
        CashGroupParameters memory cashGroup,
        int256 notional,
        uint256 maturity,
        uint256 blockTime
    ) internal view returns (int256) {
        if (notional == 0) return 0;

        int256 discountFactor = notional > 0 ?
            getRiskAdjustedfCashDiscount(cashGroup, maturity, blockTime) :
            getRiskAdjustedDebtDiscount(cashGroup, maturity, blockTime);

        require(discountFactor <= Constants.RATE_PRECISION); // dev: get risk adjusted pv, invalid discount factor
        return notional.mulInRatePrecision(discountFactor);
    }

    /// @notice Returns the non haircut claims on cash and fCash by the liquidity token.
    function getCashClaims(PortfolioAsset memory token, MarketParameters memory market)
        internal
        pure
        returns (int256 primeCash, int256 fCash)
    {
        require(isLiquidityToken(token.assetType) && token.notional >= 0); // dev: invalid asset, get cash claims

        primeCash = market.totalPrimeCash.mul(token.notional).div(market.totalLiquidity);
        fCash = market.totalfCash.mul(token.notional).div(market.totalLiquidity);
    }

    /// @notice Returns present value of all assets in the cash group as prime cash and the updated
    /// portfolio index where the function has ended.
    /// @return the value of the cash group in asset cash
    function getNetCashGroupValue(
        PortfolioAsset[] memory assets,
        CashGroupParameters memory cashGroup,
        uint256 blockTime,
        uint256 portfolioIndex
    ) internal view returns (int256, uint256) {
        int256 presentValueInPrime;
        int256 presentValueUnderlying;

        uint256 j = portfolioIndex;
        for (; j < assets.length; j++) {
            PortfolioAsset memory a = assets[j];
            if (a.assetType != Constants.FCASH_ASSET_TYPE) continue;
            // If we hit a different currency id then we've accounted for all assets in this currency
            // j will mark the index where we don't have this currency anymore
            if (a.currencyId != cashGroup.currencyId) break;

            int256 pv = getRiskAdjustedPresentfCashValue(cashGroup, a.notional, a.maturity, blockTime);
            presentValueUnderlying = presentValueUnderlying.add(pv);
        }

        presentValueInPrime = presentValueInPrime.add(
            cashGroup.primeRate.convertFromUnderlying(presentValueUnderlying)
        );

        return (presentValueInPrime, j);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {LibStorage} from "../../global/LibStorage.sol";
import {Constants} from "../../global/Constants.sol";
import {ETHRate, ETHRateStorage} from "../../global/Types.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {AggregatorV2V3Interface} from "../../../interfaces/chainlink/AggregatorV2V3Interface.sol";

library ExchangeRate {
    using SafeInt256 for int256;

    /// @notice Converts a balance to ETH from a base currency. Buffers or haircuts are
    /// always applied in this method.
    /// @param er exchange rate object from base to ETH
    /// @return the converted balance denominated in ETH with Constants.INTERNAL_TOKEN_PRECISION
    function convertToETH(ETHRate memory er, int256 balance) internal pure returns (int256) {
        int256 multiplier = balance > 0 ? er.haircut : er.buffer;

        // We are converting internal balances here so we know they have INTERNAL_TOKEN_PRECISION decimals
        // internalDecimals * rateDecimals * multiplier /  (rateDecimals * multiplierDecimals)
        // Therefore the result is in ethDecimals
        int256 result =
            balance.mul(er.rate).mul(multiplier).div(Constants.PERCENTAGE_DECIMALS).div(
                er.rateDecimals
            );

        return result;
    }

    /// @notice Converts the balance denominated in ETH to the equivalent value in a base currency.
    /// Buffers and haircuts ARE NOT applied in this method.
    /// @param er exchange rate object from base to ETH
    /// @param balance amount (denominated in ETH) to convert
    function convertETHTo(ETHRate memory er, int256 balance) internal pure returns (int256) {
        // We are converting internal balances here so we know they have INTERNAL_TOKEN_PRECISION decimals
        // internalDecimals * rateDecimals / rateDecimals
        int256 result = balance.mul(er.rateDecimals).div(er.rate);

        return result;
    }

    /// @notice Calculates the exchange rate between two currencies via ETH. Returns the rate denominated in
    /// base exchange rate decimals: (baseRateDecimals * quoteRateDecimals) / quoteRateDecimals
    /// @param baseER base exchange rate struct
    /// @param quoteER quote exchange rate struct
    function exchangeRate(ETHRate memory baseER, ETHRate memory quoteER)
        internal
        pure
        returns (int256)
    {
        return baseER.rate.mul(quoteER.rateDecimals).div(quoteER.rate);
    }

    /// @notice Returns an ETHRate object used to calculate free collateral
    function buildExchangeRate(uint256 currencyId) internal view returns (ETHRate memory) {
        mapping(uint256 => ETHRateStorage) storage store = LibStorage.getExchangeRateStorage();
        ETHRateStorage storage ethStorage = store[currencyId];

        int256 rateDecimals;
        int256 rate;
        if (currencyId == Constants.ETH_CURRENCY_ID) {
            // ETH rates will just be 1e18, but will still have buffers, haircuts,
            // and liquidation discounts
            rateDecimals = Constants.ETH_DECIMALS;
            rate = Constants.ETH_DECIMALS;
        } else {
            // prettier-ignore
            (
                /* roundId */,
                rate,
                /* uint256 startedAt */,
                /* updatedAt */,
                /* answeredInRound */
            ) = ethStorage.rateOracle.latestRoundData();
            require(rate > 0);

            // No overflow, restricted on storage
            rateDecimals = int256(10**ethStorage.rateDecimalPlaces);
            if (ethStorage.mustInvert) {
                rate = rateDecimals.mul(rateDecimals).div(rate);
            }
        }

        int256 buffer = ethStorage.buffer;
        if (buffer > Constants.MIN_BUFFER_SCALE) {
            // Buffers from 100 to 150 are 1-1 (i.e. a buffer of 150 is a 150% increase)
            // in the debt amount. Buffers from 151 to 255 are scaled by a multiple of 10
            // units to allow for much higher buffers at the outer limits. A stored
            // buffer value of 151 = 150 + 10 = 160.
            // The max buffer value of of 255 = 150 + 105 * 10 = 1200.

            // No possibility of overflows due to storage size and constant definition
            buffer = (buffer - Constants.MIN_BUFFER_SCALE) * Constants.BUFFER_SCALE 
                + Constants.MIN_BUFFER_SCALE;
        }

        return
            ETHRate({
                rateDecimals: rateDecimals,
                rate: rate,
                buffer: buffer,
                haircut: ethStorage.haircut,
                liquidationDiscount: ethStorage.liquidationDiscount
            });
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {
    PrimeRate,
    CashGroupParameters,
    PortfolioAsset,
    ETHRate,
    AccountContext,
    nTokenPortfolio,
    MarketParameters,
    LiquidationFactors
} from "../../global/Types.sol";
import {Constants} from "../../global/Constants.sol";
import {SafeInt256} from "../../math/SafeInt256.sol";
import {Bitmap} from "../../math/Bitmap.sol";

import {CashGroup} from "../markets/CashGroup.sol";
import {AccountContextHandler} from "../AccountContextHandler.sol";
import {BalanceHandler} from "../balances/BalanceHandler.sol";
import {PrimeRateLib} from "../pCash/PrimeRateLib.sol";
import {PrimeCashExchangeRate} from "../pCash/PrimeCashExchangeRate.sol";
import {PortfolioHandler} from "../portfolio/PortfolioHandler.sol";
import {BitmapAssetsHandler} from "../portfolio/BitmapAssetsHandler.sol";
import {nTokenHandler} from "../nToken/nTokenHandler.sol";
import {nTokenCalculations} from "../nToken/nTokenCalculations.sol";

import {ExchangeRate} from "./ExchangeRate.sol";
import {AssetHandler} from "./AssetHandler.sol";

library FreeCollateral {
    using SafeInt256 for int256;
    using Bitmap for bytes;
    using ExchangeRate for ETHRate;
    using PrimeRateLib for PrimeRate;
    using AccountContextHandler for AccountContext;
    using nTokenHandler for nTokenPortfolio;

    /// @dev This is only used within the library to clean up the stack
    struct FreeCollateralFactors {
        int256 netETHValue;
        bool updateContext;
        uint256 portfolioIndex;
        CashGroupParameters cashGroup;
        PortfolioAsset[] portfolio;
        PrimeRate primeRate;
        nTokenPortfolio nToken;
    }

    /// @notice Checks if an asset is active in the portfolio
    function _isActiveInPortfolio(bytes2 currencyBytes) private pure returns (bool) {
        return currencyBytes & Constants.ACTIVE_IN_PORTFOLIO == Constants.ACTIVE_IN_PORTFOLIO;
    }

    /// @notice Checks if currency balances are active in the account returns them if true
    /// @return cash balance, nTokenBalance
    function _getCurrencyBalances(
        address account,
        bytes2 currencyBytes,
        PrimeRate memory primeRate
    ) private view returns (int256, int256) {
        if (currencyBytes & Constants.ACTIVE_IN_BALANCES == Constants.ACTIVE_IN_BALANCES) {
            uint16 currencyId = uint16(currencyBytes & Constants.UNMASK_FLAGS);
            // prettier-ignore
            (
                int256 cashBalance,
                int256 nTokenBalance,
                /* lastClaimTime */,
                /* accountIncentiveDebt */
            ) = BalanceHandler.getBalanceStorage(account, currencyId, primeRate);

            return (cashBalance, nTokenBalance);
        }

        return (0, 0);
    }

    /// @notice Calculates the nToken asset value with a haircut set by governance
    /// @return the value of the account's nTokens after haircut, the nToken parameters
    function _getNTokenHaircutPrimePV(
        CashGroupParameters memory cashGroup,
        nTokenPortfolio memory nToken,
        int256 tokenBalance,
        uint256 blockTime
    ) internal view returns (int256, bytes6) {
        nToken.loadNTokenPortfolioNoCashGroup(cashGroup.currencyId);
        nToken.cashGroup = cashGroup;

        int256 nTokenPrimePV = nTokenCalculations.getNTokenPrimePV(nToken, blockTime);

        // (tokenBalance * nTokenValue * haircut) / totalSupply
        int256 nTokenHaircutPrimePV =
            tokenBalance
                .mul(nTokenPrimePV)
                .mul(uint8(nToken.parameters[Constants.PV_HAIRCUT_PERCENTAGE]))
                .div(Constants.PERCENTAGE_DECIMALS)
                .div(nToken.totalSupply);

        // nToken.parameters is returned for use in liquidation
        return (nTokenHaircutPrimePV, nToken.parameters);
    }

    /// @notice Calculates portfolio and/or nToken values while using the supplied cash groups and
    /// markets. The reason these are grouped together is because they both require storage reads of the same
    /// values.
    function _getPortfolioAndNTokenAssetValue(
        FreeCollateralFactors memory factors,
        int256 nTokenBalance,
        uint256 blockTime
    )
        private
        view
        returns (
            int256 netPortfolioValue,
            int256 nTokenHaircutPrimeValue,
            bytes6 nTokenParameters
        )
    {
        // If the next asset matches the currency id then we need to calculate the cash group value
        if (
            factors.portfolioIndex < factors.portfolio.length &&
            factors.portfolio[factors.portfolioIndex].currencyId == factors.cashGroup.currencyId
        ) {
            // netPortfolioValue is in asset cash
            (netPortfolioValue, factors.portfolioIndex) = AssetHandler.getNetCashGroupValue(
                factors.portfolio,
                factors.cashGroup,
                blockTime,
                factors.portfolioIndex
            );
        } else {
            netPortfolioValue = 0;
        }

        if (nTokenBalance > 0) {
            (nTokenHaircutPrimeValue, nTokenParameters) = _getNTokenHaircutPrimePV(
                factors.cashGroup,
                factors.nToken,
                nTokenBalance,
                blockTime
            );
        } else {
            nTokenHaircutPrimeValue = 0;
            nTokenParameters = 0;
        }
    }

    /// @notice Returns balance values for the bitmapped currency
    function _getBitmapBalanceValue(
        address account,
        uint256 blockTime,
        AccountContext memory accountContext,
        FreeCollateralFactors memory factors
    )
        private
        view
        returns (
            int256 cashBalance,
            int256 nTokenHaircutPrimeValue,
            bytes6 nTokenParameters
        )
    {
        int256 nTokenBalance;
        // prettier-ignore
        (
            cashBalance,
            nTokenBalance, 
            /* lastClaimTime */,
            /* accountIncentiveDebt */
        ) = BalanceHandler.getBalanceStorage(
            account,
            accountContext.bitmapCurrencyId,
            factors.cashGroup.primeRate
        );

        if (nTokenBalance > 0) {
            (nTokenHaircutPrimeValue, nTokenParameters) = _getNTokenHaircutPrimePV(
                factors.cashGroup,
                factors.nToken,
                nTokenBalance,
                blockTime
            );
        } else {
            nTokenHaircutPrimeValue = 0;
        }
    }

    /// @notice Returns portfolio value for the bitmapped currency
    function _getBitmapPortfolioValue(
        address account,
        uint256 blockTime,
        AccountContext memory accountContext,
        FreeCollateralFactors memory factors
    ) private view returns (int256) {
        (int256 netPortfolioValueUnderlying, bool bitmapHasDebt) =
            BitmapAssetsHandler.getifCashNetPresentValue(
                account,
                accountContext.bitmapCurrencyId,
                accountContext.nextSettleTime,
                blockTime,
                factors.cashGroup,
                true // risk adjusted
            );

        // Turns off has debt flag if it has changed
        bool contextHasAssetDebt =
            accountContext.hasDebt & Constants.HAS_ASSET_DEBT == Constants.HAS_ASSET_DEBT;
        if (bitmapHasDebt && !contextHasAssetDebt) {
            // Turn on has debt
            accountContext.hasDebt = accountContext.hasDebt | Constants.HAS_ASSET_DEBT;
            factors.updateContext = true;
        } else if (!bitmapHasDebt && contextHasAssetDebt) {
            // Turn off has debt
            accountContext.hasDebt = accountContext.hasDebt & ~Constants.HAS_ASSET_DEBT;
            factors.updateContext = true;
        }

        // Return asset cash value
        return factors.cashGroup.primeRate.convertFromUnderlying(netPortfolioValueUnderlying);
    }

    function _updateNetETHValue(
        uint256 currencyId,
        int256 netLocalAssetValue,
        FreeCollateralFactors memory factors
    ) private view returns (ETHRate memory) {
        ETHRate memory ethRate = ExchangeRate.buildExchangeRate(currencyId);
        // Converts to underlying first, ETH exchange rates are in underlying
        factors.netETHValue = factors.netETHValue.add(
            ethRate.convertToETH(factors.primeRate.convertToUnderlying(netLocalAssetValue))
        );

        return ethRate;
    }

    /// @notice Stateful version of get free collateral, returns the total net ETH value and true or false if the account
    /// context needs to be updated.
    function getFreeCollateralStateful(
        address account,
        AccountContext memory accountContext,
        uint256 blockTime
    ) internal returns (int256, bool) {
        FreeCollateralFactors memory factors;
        bool hasCashDebt;

        if (accountContext.isBitmapEnabled()) {
            factors.cashGroup = CashGroup.buildCashGroupStateful(accountContext.bitmapCurrencyId);

            // prettier-ignore
            (
                int256 netCashBalance,
                int256 nTokenHaircutPrimeValue,
                /* nTokenParameters */
            ) = _getBitmapBalanceValue(account, blockTime, accountContext, factors);
            if (netCashBalance < 0) hasCashDebt = true;

            int256 portfolioAssetValue =
                _getBitmapPortfolioValue(account, blockTime, accountContext, factors);
            int256 netLocalAssetValue =
                netCashBalance.add(nTokenHaircutPrimeValue).add(portfolioAssetValue);

            factors.primeRate = factors.cashGroup.primeRate;
            _updateNetETHValue(accountContext.bitmapCurrencyId, netLocalAssetValue, factors);
        } else {
            factors.portfolio = PortfolioHandler.getSortedPortfolio(
                account,
                accountContext.assetArrayLength
            );
        }

        bytes18 currencies = accountContext.activeCurrencies;
        while (currencies != 0) {
            bytes2 currencyBytes = bytes2(currencies);
            uint16 currencyId = uint16(currencyBytes & Constants.UNMASK_FLAGS);
            // Explicitly ensures that bitmap currency cannot be double counted
            require(currencyId != accountContext.bitmapCurrencyId);

            factors.primeRate = PrimeRateLib.buildPrimeRateStateful(currencyId);
            
            (int256 netLocalAssetValue, int256 nTokenBalance) =
                _getCurrencyBalances(account, currencyBytes, factors.primeRate);
            if (netLocalAssetValue < 0) hasCashDebt = true;

            if (_isActiveInPortfolio(currencyBytes) || nTokenBalance > 0) {
                factors.cashGroup = CashGroup.buildCashGroupStateful(currencyId);

                // prettier-ignore
                (
                    int256 netPortfolioAssetValue,
                    int256 nTokenHaircutPrimeValue,
                    /* nTokenParameters */
                ) = _getPortfolioAndNTokenAssetValue(factors, nTokenBalance, blockTime);
                netLocalAssetValue = netLocalAssetValue
                    .add(netPortfolioAssetValue)
                    .add(nTokenHaircutPrimeValue);
            }

            _updateNetETHValue(currencyId, netLocalAssetValue, factors);
            currencies = currencies << 16;
        }

        // Free collateral is the only method that examines all cash balances for an account at once. If there is no cash debt (i.e.
        // they have been repaid or settled via more debt) then this will turn off the flag. It's possible that this flag is out of
        // sync temporarily after a cash settlement and before the next free collateral check. The only downside for that is forcing
        // an account to do an extra free collateral check to turn off this setting.
        if (
            accountContext.hasDebt & Constants.HAS_CASH_DEBT == Constants.HAS_CASH_DEBT &&
            !hasCashDebt
        ) {
            accountContext.hasDebt = accountContext.hasDebt & ~Constants.HAS_CASH_DEBT;
            factors.updateContext = true;
        }

        return (factors.netETHValue, factors.updateContext);
    }

    /// @notice View version of getFreeCollateral, does not use the stateful version of build cash group and skips
    /// all the update context logic.
    function getFreeCollateralView(
        address account,
        AccountContext memory accountContext,
        uint256 blockTime
    ) internal view returns (int256, int256[] memory) {
        FreeCollateralFactors memory factors;
        uint256 netLocalIndex;
        int256[] memory netLocalAssetValues = new int256[](10);

        if (accountContext.isBitmapEnabled()) {
            factors.cashGroup = CashGroup.buildCashGroupView(accountContext.bitmapCurrencyId);

            // prettier-ignore
            (
                int256 netCashBalance,
                int256 nTokenHaircutPrimeValue,
                /* nTokenParameters */
            ) = _getBitmapBalanceValue(account, blockTime, accountContext, factors);
            int256 portfolioAssetValue =
                _getBitmapPortfolioValue(account, blockTime, accountContext, factors);

            netLocalAssetValues[netLocalIndex] = netCashBalance
                .add(nTokenHaircutPrimeValue)
                .add(portfolioAssetValue);
            factors.primeRate = factors.cashGroup.primeRate;
            _updateNetETHValue(
                accountContext.bitmapCurrencyId,
                netLocalAssetValues[netLocalIndex],
                factors
            );

            netLocalIndex++;
        } else {
            factors.portfolio = PortfolioHandler.getSortedPortfolio(
                account,
                accountContext.assetArrayLength
            );
        }

        bytes18 currencies = accountContext.activeCurrencies;
        while (currencies != 0) {
            bytes2 currencyBytes = bytes2(currencies);
            uint16 currencyId = uint16(currencyBytes & Constants.UNMASK_FLAGS);
            // Explicitly ensures that bitmap currency cannot be double counted
            require(currencyId != accountContext.bitmapCurrencyId);
            int256 nTokenBalance;
            (factors.primeRate, /* */) = PrimeCashExchangeRate.getPrimeCashRateView(currencyId, blockTime);

            (netLocalAssetValues[netLocalIndex], nTokenBalance) = _getCurrencyBalances(
                account,
                currencyBytes,
                factors.primeRate
            );

            if (_isActiveInPortfolio(currencyBytes) || nTokenBalance > 0) {
                factors.cashGroup = CashGroup.buildCashGroupView(currencyId);
                // prettier-ignore
                (
                    int256 netPortfolioValue,
                    int256 nTokenHaircutPrimeValue,
                    /* nTokenParameters */
                ) = _getPortfolioAndNTokenAssetValue(factors, nTokenBalance, blockTime);

                netLocalAssetValues[netLocalIndex] = netLocalAssetValues[netLocalIndex]
                    .add(netPortfolioValue)
                    .add(nTokenHaircutPrimeValue);
            }

            _updateNetETHValue(currencyId, netLocalAssetValues[netLocalIndex], factors);
            netLocalIndex++;
            currencies = currencies << 16;
        }

        return (factors.netETHValue, netLocalAssetValues);
    }

    /// @notice Calculates the net value of a currency within a portfolio, this is a bit
    /// convoluted to fit into the stack frame
    function _calculateLiquidationAssetValue(
        FreeCollateralFactors memory factors,
        LiquidationFactors memory liquidationFactors,
        bytes2 currencyBytes,
        bool setLiquidationFactors,
        uint256 blockTime
    ) private returns (int256) {
        uint16 currencyId = uint16(currencyBytes & Constants.UNMASK_FLAGS);
        factors.primeRate = PrimeRateLib.buildPrimeRateStateful(currencyId);
        (int256 netLocalAssetValue, int256 nTokenBalance) =
            _getCurrencyBalances(liquidationFactors.account, currencyBytes, factors.primeRate);

        if (_isActiveInPortfolio(currencyBytes) || nTokenBalance > 0) {
            factors.cashGroup = CashGroup.buildCashGroupStateful(currencyId);
            (int256 netPortfolioValue, int256 nTokenHaircutPrimeValue, bytes6 nTokenParameters) =
                _getPortfolioAndNTokenAssetValue(factors, nTokenBalance, blockTime);

            netLocalAssetValue = netLocalAssetValue
                .add(netPortfolioValue)
                .add(nTokenHaircutPrimeValue);

            // If collateralCurrencyId is set to zero then this is a local currency liquidation
            if (setLiquidationFactors) {
                liquidationFactors.collateralCashGroup = factors.cashGroup;
                liquidationFactors.nTokenParameters = nTokenParameters;
                liquidationFactors.nTokenHaircutPrimeValue = nTokenHaircutPrimeValue;
            }
        }

        return netLocalAssetValue;
    }

    /// @notice A version of getFreeCollateral used during liquidation to save off necessary additional information.
    function getLiquidationFactors(
        address account,
        AccountContext memory accountContext,
        uint256 blockTime,
        uint256 localCurrencyId,
        uint256 collateralCurrencyId
    ) internal returns (LiquidationFactors memory, PortfolioAsset[] memory) {
        FreeCollateralFactors memory factors;
        LiquidationFactors memory liquidationFactors;
        // This is only set to reduce the stack size
        liquidationFactors.account = account;

        if (accountContext.isBitmapEnabled()) {
            factors.cashGroup = CashGroup.buildCashGroupStateful(accountContext.bitmapCurrencyId);
            (int256 netCashBalance, int256 nTokenHaircutPrimeValue, bytes6 nTokenParameters) =
                _getBitmapBalanceValue(account, blockTime, accountContext, factors);
            int256 portfolioBalance =
                _getBitmapPortfolioValue(account, blockTime, accountContext, factors);

            int256 netLocalAssetValue =
                netCashBalance.add(nTokenHaircutPrimeValue).add(portfolioBalance);
            factors.primeRate = factors.cashGroup.primeRate;
            ETHRate memory ethRate =
                _updateNetETHValue(accountContext.bitmapCurrencyId, netLocalAssetValue, factors);

            // If the bitmap currency id can only ever be the local currency where debt is held.
            // During enable bitmap we check that the account has no assets in their portfolio and
            // no cash debts.
            if (accountContext.bitmapCurrencyId == localCurrencyId) {
                liquidationFactors.localPrimeAvailable = netLocalAssetValue;
                liquidationFactors.localETHRate = ethRate;
                liquidationFactors.localPrimeRate = factors.primeRate;

                // This will be the case during local currency or local fCash liquidation
                if (collateralCurrencyId == 0) {
                    // If this is local fCash liquidation, the cash group information is required
                    // to calculate fCash haircuts and buffers.
                    liquidationFactors.collateralCashGroup = factors.cashGroup;
                    liquidationFactors.nTokenHaircutPrimeValue = nTokenHaircutPrimeValue;
                    liquidationFactors.nTokenParameters = nTokenParameters;
                }
            }
        } else {
            factors.portfolio = PortfolioHandler.getSortedPortfolio(
                account,
                accountContext.assetArrayLength
            );
        }

        bytes18 currencies = accountContext.activeCurrencies;
        while (currencies != 0) {
            bytes2 currencyBytes = bytes2(currencies);

            // This next bit of code here is annoyingly structured to get around stack size issues
            bool setLiquidationFactors;
            {
                uint256 tempId = uint256(uint16(currencyBytes & Constants.UNMASK_FLAGS));
                // Explicitly ensures that bitmap currency cannot be double counted
                require(tempId != accountContext.bitmapCurrencyId);
                setLiquidationFactors =
                    (tempId == localCurrencyId && collateralCurrencyId == 0) ||
                    tempId == collateralCurrencyId;
            }
            int256 netLocalAssetValue =
                _calculateLiquidationAssetValue(
                    factors,
                    liquidationFactors,
                    currencyBytes,
                    setLiquidationFactors,
                    blockTime
                );

            uint256 currencyId = uint256(uint16(currencyBytes & Constants.UNMASK_FLAGS));
            ETHRate memory ethRate = _updateNetETHValue(currencyId, netLocalAssetValue, factors);

            if (currencyId == collateralCurrencyId) {
                // Ensure that this is set even if the cash group is not loaded, it will not be
                // loaded if the account only has a cash balance and no nTokens or assets
                liquidationFactors.collateralCashGroup.primeRate = factors.primeRate;
                liquidationFactors.collateralAssetAvailable = netLocalAssetValue;
                liquidationFactors.collateralETHRate = ethRate;
            } else if (currencyId == localCurrencyId) {
                // This branch will not be entered if bitmap is enabled
                liquidationFactors.localPrimeAvailable = netLocalAssetValue;
                liquidationFactors.localETHRate = ethRate;
                liquidationFactors.localPrimeRate = factors.primeRate;
                // If this is local fCash liquidation, the cash group information is required
                // to calculate fCash haircuts and buffers and it will have been set in
                // _calculateLiquidationAssetValue above because the account must have fCash assets,
                // there is no need to set cash group in this branch.
            }

            currencies = currencies << 16;
        }

        liquidationFactors.netETHValue = factors.netETHValue;
        require(liquidationFactors.netETHValue < 0, "Sufficient collateral");

        // Refetch the portfolio if it exists, AssetHandler.getNetCashValue updates values in memory to do fCash
        // netting which will make further calculations incorrect.
        if (accountContext.assetArrayLength > 0) {
            factors.portfolio = PortfolioHandler.getSortedPortfolio(
                account,
                accountContext.assetArrayLength
            );
        }

        return (liquidationFactors, factors.portfolio);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.5.0 || ^0.6.0 || ^0.7.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    return int64 (x >> 64);
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    require (x <= 0x7FFFFFFFFFFFFFFF);
    return int128 (x << 64);
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    require (x >= 0);
    return uint64 (x >> 64);
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    int256 result = x >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    return int256 (x) << 64;
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) + y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) - y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    int256 result = int256(x) * y >> 64;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    if (x == MIN_64x64) {
      require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
        y <= 0x1000000000000000000000000000000000000000000000000);
      return -y << 63;
    } else {
      bool negativeResult = false;
      if (x < 0) {
        x = -x;
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint256 absoluteResult = mulu (x, uint256 (y));
      if (negativeResult) {
        require (absoluteResult <=
          0x8000000000000000000000000000000000000000000000000000000000000000);
        return -int256 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <=
          0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int256 (absoluteResult);
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    if (y == 0) return 0;

    require (x >= 0);

    uint256 lo = (uint256 (x) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
    uint256 hi = uint256 (x) * (y >> 128);

    require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    hi <<= 64;

    require (hi <=
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
    return hi + lo;
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    require (y != 0);
    int256 result = (int256 (x) << 64) / y;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    require (y != 0);

    bool negativeResult = false;
    if (x < 0) {
      x = -x; // We rely on overflow behavior here
      negativeResult = true;
    }
    if (y < 0) {
      y = -y; // We rely on overflow behavior here
      negativeResult = !negativeResult;
    }
    uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
    if (negativeResult) {
      require (absoluteResult <= 0x80000000000000000000000000000000);
      return -int128 (absoluteResult); // We rely on overflow behavior here
    } else {
      require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return int128 (absoluteResult); // We rely on overflow behavior here
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    require (y != 0);
    uint128 result = divuu (x, y);
    require (result <= uint128 (MAX_64x64));
    return int128 (result);
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return -x;
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    require (x != MIN_64x64);
    return x < 0 ? -x : x;
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    require (x != 0);
    int256 result = int256 (0x100000000000000000000000000000000) / x;
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    return int128 ((int256 (x) + int256 (y)) >> 1);
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    int256 m = int256 (x) * int256 (y);
    require (m >= 0);
    require (m <
        0x4000000000000000000000000000000000000000000000000000000000000000);
    return int128 (sqrtu (uint256 (m)));
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    bool negative = x < 0 && y & 1 == 1;

    uint256 absX = uint128 (x < 0 ? -x : x);
    uint256 absResult;
    absResult = 0x100000000000000000000000000000000;

    if (absX <= 0x10000000000000000) {
      absX <<= 63;
      while (y != 0) {
        if (y & 0x1 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x2 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x4 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        if (y & 0x8 != 0) {
          absResult = absResult * absX >> 127;
        }
        absX = absX * absX >> 127;

        y >>= 4;
      }

      absResult >>= 64;
    } else {
      uint256 absXShift = 63;
      if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
      if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
      if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
      if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
      if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
      if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

      uint256 resultShift = 0;
      while (y != 0) {
        require (absXShift < 64);

        if (y & 0x1 != 0) {
          absResult = absResult * absX >> 127;
          resultShift += absXShift;
          if (absResult > 0x100000000000000000000000000000000) {
            absResult >>= 1;
            resultShift += 1;
          }
        }
        absX = absX * absX >> 127;
        absXShift <<= 1;
        if (absX >= 0x100000000000000000000000000000000) {
            absX >>= 1;
            absXShift += 1;
        }

        y >>= 1;
      }

      require (resultShift < 64);
      absResult >>= 64 - resultShift;
    }
    int256 result = negative ? -int256 (absResult) : int256 (absResult);
    require (result >= MIN_64x64 && result <= MAX_64x64);
    return int128 (result);
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    require (x >= 0);
    return int128 (sqrtu (uint256 (x) << 64));
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    require (x > 0);

    int256 msb = 0;
    int256 xc = x;
    if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
    if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
    if (xc >= 0x10000) { xc >>= 16; msb += 16; }
    if (xc >= 0x100) { xc >>= 8; msb += 8; }
    if (xc >= 0x10) { xc >>= 4; msb += 4; }
    if (xc >= 0x4) { xc >>= 2; msb += 2; }
    if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

    int256 result = msb - 64 << 64;
    uint256 ux = uint256 (x) << uint256 (127 - msb);
    for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
      ux *= ux;
      uint256 b = ux >> 255;
      ux >>= 127 + b;
      result += bit * int256 (b);
    }

    return int128 (result);
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    require (x > 0);

    return int128 (
        uint256 (log_2 (x)) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128);
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    uint256 result = 0x80000000000000000000000000000000;

    if (x & 0x8000000000000000 > 0)
      result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
    if (x & 0x4000000000000000 > 0)
      result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
    if (x & 0x2000000000000000 > 0)
      result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
    if (x & 0x1000000000000000 > 0)
      result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
    if (x & 0x800000000000000 > 0)
      result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
    if (x & 0x400000000000000 > 0)
      result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
    if (x & 0x200000000000000 > 0)
      result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
    if (x & 0x100000000000000 > 0)
      result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
    if (x & 0x80000000000000 > 0)
      result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
    if (x & 0x40000000000000 > 0)
      result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
    if (x & 0x20000000000000 > 0)
      result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
    if (x & 0x10000000000000 > 0)
      result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
    if (x & 0x8000000000000 > 0)
      result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
    if (x & 0x4000000000000 > 0)
      result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
    if (x & 0x2000000000000 > 0)
      result = result * 0x1000162E525EE054754457D5995292026 >> 128;
    if (x & 0x1000000000000 > 0)
      result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
    if (x & 0x800000000000 > 0)
      result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
    if (x & 0x400000000000 > 0)
      result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
    if (x & 0x200000000000 > 0)
      result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
    if (x & 0x100000000000 > 0)
      result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
    if (x & 0x80000000000 > 0)
      result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
    if (x & 0x40000000000 > 0)
      result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
    if (x & 0x20000000000 > 0)
      result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
    if (x & 0x10000000000 > 0)
      result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
    if (x & 0x8000000000 > 0)
      result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
    if (x & 0x4000000000 > 0)
      result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
    if (x & 0x2000000000 > 0)
      result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
    if (x & 0x1000000000 > 0)
      result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
    if (x & 0x800000000 > 0)
      result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
    if (x & 0x400000000 > 0)
      result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
    if (x & 0x200000000 > 0)
      result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
    if (x & 0x100000000 > 0)
      result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
    if (x & 0x80000000 > 0)
      result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
    if (x & 0x40000000 > 0)
      result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
    if (x & 0x20000000 > 0)
      result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
    if (x & 0x10000000 > 0)
      result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
    if (x & 0x8000000 > 0)
      result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
    if (x & 0x4000000 > 0)
      result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
    if (x & 0x2000000 > 0)
      result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
    if (x & 0x1000000 > 0)
      result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
    if (x & 0x800000 > 0)
      result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
    if (x & 0x400000 > 0)
      result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
    if (x & 0x200000 > 0)
      result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
    if (x & 0x100000 > 0)
      result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
    if (x & 0x80000 > 0)
      result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
    if (x & 0x40000 > 0)
      result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
    if (x & 0x20000 > 0)
      result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
    if (x & 0x10000 > 0)
      result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
    if (x & 0x8000 > 0)
      result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
    if (x & 0x4000 > 0)
      result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
    if (x & 0x2000 > 0)
      result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
    if (x & 0x1000 > 0)
      result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
    if (x & 0x800 > 0)
      result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
    if (x & 0x400 > 0)
      result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
    if (x & 0x200 > 0)
      result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
    if (x & 0x100 > 0)
      result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
    if (x & 0x80 > 0)
      result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
    if (x & 0x40 > 0)
      result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
    if (x & 0x20 > 0)
      result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
    if (x & 0x10 > 0)
      result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
    if (x & 0x8 > 0)
      result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
    if (x & 0x4 > 0)
      result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
    if (x & 0x2 > 0)
      result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
    if (x & 0x1 > 0)
      result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

    result >>= uint256 (63 - (x >> 64));
    require (result <= uint256 (MAX_64x64));

    return int128 (result);
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    require (x < 0x400000000000000000); // Overflow

    if (x < -0x400000000000000000) return 0; // Underflow

    return exp_2 (
        int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    require (y != 0);

    uint256 result;

    if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      result = (x << 64) / y;
    else {
      uint256 msb = 192;
      uint256 xc = x >> 192;
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 hi = result * (y >> 128);
      uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

      uint256 xh = x >> 192;
      uint256 xl = x << 64;

      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here
      lo = hi << 128;
      if (xl < lo) xh -= 1;
      xl -= lo; // We rely on overflow behavior here

      assert (xh == hi >> 128);

      result += xl / y;
    }

    require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
    return uint128 (result);
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    if (x == 0) return 0;
    else {
      uint256 xx = x;
      uint256 r = 1;
      if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
      if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
      if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
      if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
      if (xx >= 0x100) { xx >>= 8; r <<= 4; }
      if (xx >= 0x10) { xx >>= 4; r <<= 2; }
      if (xx >= 0x8) { r <<= 1; }
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1;
      r = (r + x / r) >> 1; // Seven iterations should be enough
      uint256 r1 = x / r;
      return uint128 (r < r1 ? r : r1);
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import {Constants} from "../global/Constants.sol";

/// @notice Helper methods for bitmaps, they are big-endian and 1-indexed.
library Bitmap {

    /// @notice Set a bit on or off in a bitmap, index is 1-indexed
    function setBit(
        bytes32 bitmap,
        uint256 index,
        bool setOn
    ) internal pure returns (bytes32) {
        require(index >= 1 && index <= 256); // dev: set bit index bounds

        if (setOn) {
            return bitmap | (Constants.MSB >> (index - 1));
        } else {
            return bitmap & ~(Constants.MSB >> (index - 1));
        }
    }

    /// @notice Check if a bit is set
    function isBitSet(bytes32 bitmap, uint256 index) internal pure returns (bool) {
        require(index >= 1 && index <= 256); // dev: set bit index bounds
        return ((bitmap << (index - 1)) & Constants.MSB) == Constants.MSB;
    }

    /// @notice Count the total bits set
    function totalBitsSet(bytes32 bitmap) internal pure returns (uint256) {
        uint256 x = uint256(bitmap);
        x = (x & 0x5555555555555555555555555555555555555555555555555555555555555555) + (x >> 1 & 0x5555555555555555555555555555555555555555555555555555555555555555);
        x = (x & 0x3333333333333333333333333333333333333333333333333333333333333333) + (x >> 2 & 0x3333333333333333333333333333333333333333333333333333333333333333);
        x = (x & 0x0707070707070707070707070707070707070707070707070707070707070707) + (x >> 4);
        x = (x & 0x000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F) + (x >> 8 & 0x000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F);
        x = x + (x >> 16);
        x = x + (x >> 32);
        x = x  + (x >> 64);
        return (x & 0xFF) + (x >> 128 & 0xFF);
    }

    // Does a binary search over x to get the position of the most significant bit
    function getMSB(uint256 x) internal pure returns (uint256 msb) {
        // If x == 0 then there is no MSB and this method will return zero. That would
        // be the same as the return value when x == 1 (MSB is zero indexed), so instead
        // we have this require here to ensure that the values don't get mixed up.
        require(x != 0); // dev: get msb zero value
        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 0x2) msb += 1; // No need to shift xc anymore
    }

    /// @dev getMSB returns a zero indexed bit number where zero is the first bit counting
    /// from the right (little endian). Asset Bitmaps are counted from the left (big endian)
    /// and one indexed.
    function getNextBitNum(bytes32 bitmap) internal pure returns (uint256 bitNum) {
        // Short circuit the search if bitmap is all zeros
        if (bitmap == 0x00) return 0;

        return 255 - getMSB(uint256(bitmap)) + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import {Bitmap} from "./Bitmap.sol";
import {SafeInt256} from "./SafeInt256.sol";
import {SafeUint256} from "./SafeUint256.sol";

/**
 * Packs an uint value into a "floating point" storage slot. Used for storing
 * lastClaimIntegralSupply values in balance storage. For these values, we don't need
 * to maintain exact precision but we don't want to be limited by storage size overflows.
 *
 * A floating point value is defined by the 48 most significant bits and an 8 bit number
 * of bit shifts required to restore its precision. The unpacked value will always be less
 * than the packed value with a maximum absolute loss of precision of (2 ** bitShift) - 1.
 */
library FloatingPoint {
    using SafeInt256 for int256;
    using SafeUint256 for uint256;

    function packTo56Bits(uint256 value) internal pure returns (uint56) {
        uint256 bitShift;
        // If the value is over the uint48 max value then we will shift it down
        // given the index of the most significant bit. We store this bit shift 
        // in the least significant byte of the 56 bit slot available.
        if (value > type(uint48).max) bitShift = (Bitmap.getMSB(value) - 47);

        uint256 shiftedValue = value >> bitShift;
        return uint56((shiftedValue << 8) | bitShift);
    }

    function packTo32Bits(uint256 value) internal pure returns (uint32) {
        uint256 bitShift;
        // If the value is over the uint24 max value then we will shift it down
        // given the index of the most significant bit. We store this bit shift 
        // in the least significant byte of the 32 bit slot available.
        if (value > type(uint24).max) bitShift = (Bitmap.getMSB(value) - 23);

        uint256 shiftedValue = value >> bitShift;
        return uint32((shiftedValue << 8) | bitShift);
    }

    function unpackFromBits(uint256 value) internal pure returns (uint256) {
        // The least significant 8 bits will be the amount to bit shift
        uint256 bitShift = uint256(uint8(value));
        return ((value >> 8) << bitShift);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import {Constants} from "../global/Constants.sol";

library SafeInt256 {
    int256 private constant _INT256_MIN = type(int256).min;

    /// @dev Returns the multiplication of two signed integers, reverting on
    /// overflow.

    /// Counterpart to Solidity's `*` operator.

    /// Requirements:

    /// - Multiplication cannot overflow.

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        c = a * b;
        if (a == -1) require (b == 0 || c / b == a);
        else require (a == 0 || c / a == b);
    }

    /// @dev Returns the integer division of two signed integers. Reverts on
    /// division by zero. The result is rounded towards zero.

    /// Counterpart to Solidity's `/` operator. Note: this function uses a
    /// `revert` opcode (which leaves remaining gas untouched) while Solidity
    /// uses an invalid opcode to revert (consuming all remaining gas).

    /// Requirements:

    /// - The divisor cannot be zero.

    function div(int256 a, int256 b) internal pure returns (int256 c) {
        require(!(b == -1 && a == _INT256_MIN)); // dev: int256 div overflow
        // NOTE: solidity will automatically revert on divide by zero
        c = a / b;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        //  taken from uniswap v3
        require((z = x - y) <= x == (y >= 0));
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    function neg(int256 x) internal pure returns (int256 y) {
        return mul(-1, x);
    }

    function abs(int256 x) internal pure returns (int256) {
        if (x < 0) return neg(x);
        else return x;
    }

    function subNoNeg(int256 x, int256 y) internal pure returns (int256 z) {
        z = sub(x, y);
        require(z >= 0); // dev: int256 sub to negative

        return z;
    }

    /// @dev Calculates x * RATE_PRECISION / y while checking overflows
    function divInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, Constants.RATE_PRECISION), y);
    }

    /// @dev Calculates x * y / RATE_PRECISION while checking overflows
    function mulInRatePrecision(int256 x, int256 y) internal pure returns (int256) {
        return div(mul(x, y), Constants.RATE_PRECISION);
    }

    function toUint(int256 x) internal pure returns (uint256) {
        require(x >= 0);
        return uint256(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

    function toInt80(int256 x) internal pure returns (int80) {
        require (int256(type(int80).min) <= x && x <= int256(type(int80).max)); // dev: toInt overflow
        return int80(x);
    }

    function toInt88(int256 x) internal pure returns (int88) {
        require (int256(type(int88).min) <= x && x <= int256(type(int88).max)); // dev: toInt overflow
        return int88(x);
    }

    function toInt128(int256 x) internal pure returns (int128) {
        require (int256(type(int128).min) <= x && x <= int256(type(int128).max)); // dev: toInt overflow
        return int128(x);
    }

    function max(int256 x, int256 y) internal pure returns (int256) {
        return x > y ? x : y;
    }

    function min(int256 x, int256 y) internal pure returns (int256) {
        return x < y ? x : y;
    }

    /// @notice Returns the net change in negative signed values, used for
    /// determining the (positive) amount of debt change
    function negChange(int256 start, int256 end) internal pure returns (int256) {
        // No change in these two scenarios
        if (start == end || (start >= 0 && end >= 0)) return 0;
        if (start <= 0 && 0 < end) {
            // Negative portion has been eliminated so the net change on the
            // negative side is start (i.e. a reduction in the negative balance)
            return start;
        } else if (end <= 0 && 0 < start) {
            // Entire negative portion has been created so the net change on the
            // negative side is -end (i.e. an increase in the negative balance)
            return neg(end);
        } else if (start <= 0 && end <= 0) {
            // There is some net change in the negative amounts.
            // If start < end then this is negative, debt has been reduced
            // If end < start then this is positive, debt has been increased
            return sub(start, end);
        }

        // Should never get to this point
        revert();
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;

import {Constants} from "../global/Constants.sol";

library SafeUint256 {
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
        require(c >= a);
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
        require(b <= a);
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
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
        require(b > 0);
        return a % b;
    }

    function divInRatePrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return div(mul(x, uint256(Constants.RATE_PRECISION)), y);
    }

    function mulInRatePrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return div(mul(x, y), uint256(Constants.RATE_PRECISION));
    }

    function divInScalarPrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return div(mul(x, Constants.SCALAR_PRECISION), y);
    }

    function mulInScalarPrecision(uint256 x, uint256 y) internal pure returns (uint256) {
        return div(mul(x, y), Constants.SCALAR_PRECISION);
    }

    function toUint8(uint256 x) internal pure returns (uint8) {
        require(x <= type(uint8).max);
        return uint8(x);
    }

    function toUint32(uint256 x) internal pure returns (uint32) {
        require(x <= type(uint32).max);
        return uint32(x);
    }

    function toUint40(uint256 x) internal pure returns (uint40) {
        require(x <= type(uint40).max);
        return uint40(x);
    }

    function toUint48(uint256 x) internal pure returns (uint48) {
        require(x <= type(uint48).max);
        return uint48(x);
    }

    function toUint56(uint256 x) internal pure returns (uint56) {
        require(x <= type(uint56).max);
        return uint56(x);
    }

    function toUint72(uint256 x) internal pure returns (uint72) {
        require(x <= type(uint72).max);
        return uint72(x);
    }
    
    function toUint80(uint256 x) internal pure returns (uint80) {
        require(x <= type(uint80).max);
        return uint80(x);
    }

    function toUint88(uint256 x) internal pure returns (uint88) {
        require(x <= type(uint88).max);
        return uint88(x);
    }

    function toUint104(uint256 x) internal pure returns (uint104) {
        require(x <= type(uint104).max);
        return uint104(x);
    }

    function toUint112(uint256 x) internal pure returns (uint112) {
        require(x <= type(uint112).max);
        return uint112(x);
    }

    function toUint128(uint256 x) internal pure returns (uint128) {
        require(x <= type(uint128).max);
        return uint128(x);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require (x <= uint256(type(int256).max)); // dev: toInt overflow
        return int256(x);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (proxy/beacon/IBeacon.sol)

pragma solidity >=0.7.6;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

interface IUpgradeableBeacon is IBeacon {
    function upgradeTo(address newImplementation) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

struct LendingPoolStorage {
  ILendingPool lendingPool;
}

interface ILendingPool {

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (ReserveData memory);

  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {NONE, STABLE, VARIABLE}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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
pragma solidity >=0.6.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.7.6;

import "./CTokenInterface.sol";

interface CErc20Interface {

    /*** User Interface ***/

    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
    function liquidateBorrow(address borrower, uint repayAmount, CTokenInterface cTokenCollateral) external returns (uint);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.7.6;

interface CEtherInterface {
    function mint() external payable;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity >=0.7.6;

interface CTokenInterface {

    /*** User Interface ***/

    function underlying() external view returns (address);
    function totalSupply() external view returns (uint256);
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
    function accrualBlockNumber() external view returns (uint256);
    function totalBorrows() external view returns (uint256);
    function totalReserves() external view returns (uint256);
    function interestRateModel() external view returns (address);
    function reserveFactorMantissa() external view returns (uint256);
    function initialExchangeRateMantissa() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface IEIP20NonStandard {

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance
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

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `approve` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved
      */
    function approve(address spender, uint256 amount) external;

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.7.6;

interface IERC4626 {
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is "managed" by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the "per-user" price-per-share, and instead should reflect the
     * "average-user's" price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the "per-user" price-per-share, and instead should reflect the
     * "average-user's" price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;

/// @notice Used as a wrapper for tokens that are interest bearing for an
/// underlying token. Follows the cToken interface, however, can be adapted
/// for other interest bearing tokens.
interface AssetRateAdapter {
    function token() external view returns (address);

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function underlying() external view returns (address);

    function getExchangeRateStateful() external returns (int256);

    function getExchangeRateView() external view returns (int256);

    function getAnnualizedSupplyRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.0;
pragma abicoder v2;

struct DepositData {
    address[] targets;
    bytes[] callData;
    uint256[] msgValue;
    uint256 underlyingDepositAmount;
    address assetToken;
}

struct RedeemData {
    address[] targets;
    bytes[] callData;
    uint256 expectedUnderlying;
    address assetToken;
}

interface IPrimeCashHoldingsOracle {
    /// @notice Returns a list of the various holdings for the prime cash
    /// currency
    function holdings() external view returns (address[] memory);

    /// @notice Returns the underlying token that all holdings can be redeemed
    /// for.
    function underlying() external view returns (address);
    
    /// @notice Returns the native decimal precision of the underlying token
    function decimals() external view returns (uint8);

    /// @notice Returns the total underlying held by the caller in all the
    /// listed holdings
    function getTotalUnderlyingValueStateful() external returns (
        uint256 nativePrecision,
        uint256 internalPrecision
    );

    function getTotalUnderlyingValueView() external view returns (
        uint256 nativePrecision,
        uint256 internalPrecision
    );

    /// @notice Returns calldata for how to withdraw an amount
    function getRedemptionCalldata(uint256 withdrawAmount) external view returns (
        RedeemData[] memory redeemData
    );

    function holdingValuesInUnderlying() external view returns (uint256[] memory);

    function getRedemptionCalldataForRebalancing(
        address[] calldata _holdings, 
        uint256[] calldata withdrawAmounts
    ) external view returns (
        RedeemData[] memory redeemData
    );

    function getDepositCalldataForRebalancing(
        address[] calldata _holdings, 
        uint256[] calldata depositAmounts
    ) external view returns (
        DepositData[] memory depositData
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

interface IRewarder {
    function claimRewards(
        address account,
        uint16 currencyId,
        uint256 nTokenBalanceBefore,
        uint256 nTokenBalanceAfter,
        int256  netNTokenSupplyChange,
        uint256 NOTETokensClaimed
    ) external;
}

// SPDX-License-Identifier: GPL-v3
pragma solidity >=0.7.6;
pragma abicoder v2;

import {
    VaultConfigParams,
    VaultConfigStorage,
    VaultConfig,
    VaultState,
    VaultAccount,
    VaultAccountHealthFactors,
    PrimeRate
} from "../../contracts/global/Types.sol";

interface IVaultAction {
    /// @notice Emitted when a new vault is listed or updated
    event VaultUpdated(address indexed vault, bool enabled, uint80 maxPrimaryBorrowCapacity);
    /// @notice Emitted when a vault's status is updated
    event VaultPauseStatus(address indexed vault, bool enabled);
    /// @notice Emitted when a vault's deleverage status is updated
    event VaultDeleverageStatus(address indexed vaultAddress, bool disableDeleverage);
    /// @notice Emitted when a secondary currency borrow capacity is updated
    event VaultUpdateSecondaryBorrowCapacity(address indexed vault, uint16 indexed currencyId, uint80 maxSecondaryBorrowCapacity);
    /// @notice Emitted when the borrow capacity on a vault changes
    event VaultBorrowCapacityChange(address indexed vault, uint16 indexed currencyId, uint256 totalUsedBorrowCapacity);

    /// @notice Emitted when a vault executes a secondary borrow
    event VaultSecondaryTransaction(
        address indexed vault,
        address indexed account,
        uint16 indexed currencyId,
        uint256 maturity,
        int256 netUnderlyingDebt,
        int256 netPrimeSupply
    );

    /** Vault Action Methods */

    /// @notice Governance only method to whitelist a particular vault
    function updateVault(
        address vaultAddress,
        VaultConfigParams memory vaultConfig,
        uint80 maxPrimaryBorrowCapacity
    ) external;

    /// @notice Governance only method to pause a particular vault
    function setVaultPauseStatus(
        address vaultAddress,
        bool enable
    ) external;

    function setVaultDeleverageStatus(
        address vaultAddress,
        bool disableDeleverage
    ) external;

    /// @notice Governance only method to set the borrow capacity
    function setMaxBorrowCapacity(
        address vaultAddress,
        uint80 maxVaultBorrowCapacity
    ) external;

    /// @notice Governance only method to update a vault's secondary borrow capacity
    function updateSecondaryBorrowCapacity(
        address vaultAddress,
        uint16 secondaryCurrencyId,
        uint80 maxBorrowCapacity
    ) external;

    function borrowSecondaryCurrencyToVault(
        address account,
        uint256 maturity,
        uint256[2] calldata underlyingToBorrow,
        uint32[2] calldata maxBorrowRate,
        uint32[2] calldata minRollLendRate
    ) external returns (int256[2] memory underlyingTokensTransferred);

    function repaySecondaryCurrencyFromVault(
        address account,
        uint256 maturity,
        uint256[2] calldata underlyingToRepay,
        uint32[2] calldata minLendRate
    ) external payable returns (int256[2] memory underlyingDepositExternal);

    function settleSecondaryBorrowForAccount(address vault, address account) external;
}

interface IVaultAccountAction {
    /**
     * @notice Borrows a specified amount of fCash in the vault's borrow currency and deposits it
     * all plus the depositAmountExternal into the vault to mint strategy tokens.
     *
     * @param account the address that will enter the vault
     * @param vault the vault to enter
     * @param depositAmountExternal some amount of additional collateral in the borrowed currency
     * to be transferred to vault
     * @param maturity the maturity to borrow at
     * @param fCash amount to borrow
     * @param maxBorrowRate maximum interest rate to borrow at
     * @param vaultData additional data to pass to the vault contract
     */
    function enterVault(
        address account,
        address vault,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint256 fCash,
        uint32 maxBorrowRate,
        bytes calldata vaultData
    ) external payable returns (uint256 strategyTokensAdded);

    /**
     * @notice Re-enters the vault at a longer dated maturity. The account's existing borrow
     * position will be closed and a new borrow position at the specified maturity will be
     * opened. All strategy token holdings will be rolled forward.
     *
     * @param account the address that will reenter the vault
     * @param vault the vault to reenter
     * @param fCashToBorrow amount of fCash to borrow in the next maturity
     * @param maturity new maturity to borrow at
     */
    function rollVaultPosition(
        address account,
        address vault,
        uint256 fCashToBorrow,
        uint256 maturity,
        uint256 depositAmountExternal,
        uint32 minLendRate,
        uint32 maxBorrowRate,
        bytes calldata enterVaultData
    ) external payable returns (uint256 strategyTokensAdded);

    /**
     * @notice Prior to maturity, allows an account to withdraw their position from the vault. Will
     * redeem some number of vault shares to the borrow currency and close the borrow position by
     * lending `fCashToLend`. Any shortfall in cash from lending will be transferred from the account,
     * any excess profits will be transferred to the account.
     *
     * Post maturity, will net off the account's debt against vault cash balances and redeem all remaining
     * strategy tokens back to the borrowed currency and transfer the profits to the account.
     *
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param vaultSharesToRedeem amount of vault tokens to exit, only relevant when exiting pre-maturity
     * @param fCashToLend amount of fCash to lend
     * @param minLendRate the minimum rate to lend at
     * @param exitVaultData passed to the vault during exit
     * @return underlyingToReceiver amount of underlying tokens returned to the receiver on exit
     */
    function exitVault(
        address account,
        address vault,
        address receiver,
        uint256 vaultSharesToRedeem,
        uint256 fCashToLend,
        uint32 minLendRate,
        bytes calldata exitVaultData
    ) external payable returns (uint256 underlyingToReceiver);

    function settleVaultAccount(address account, address vault) external;
}

interface IVaultLiquidationAction {
    event VaultDeleverageAccount(
        address indexed vault,
        address indexed account,
        uint16 currencyId,
        uint256 vaultSharesToLiquidator,
        int256 depositAmountPrimeCash
    );

    event VaultLiquidatorProfit(
        address indexed vault,
        address indexed account,
        address indexed liquidator,
        uint256 vaultSharesToLiquidator,
        bool transferSharesToLiquidator
    );
    
    event VaultAccountCashLiquidation(
        address indexed vault,
        address indexed account,
        address indexed liquidator,
        uint16 currencyId,
        int256 fCashDeposit,
        int256 cashToLiquidator
    );

    /**
     * @notice If an account is below the minimum collateral ratio, this method wil deleverage (liquidate)
     * that account. `depositAmountExternal` in the borrow currency will be transferred from the liquidator
     * and used to offset the account's debt position. The liquidator will receive either vaultShares or
     * cash depending on the vault's configuration.
     * @param account the address that will exit the vault
     * @param vault the vault to enter
     * @param liquidator the address that will receive profits from liquidation
     * @param depositAmountPrimeCash amount of cash to deposit
     * @return vaultSharesFromLiquidation amount of vaultShares received from liquidation
     */
    function deleverageAccount(
        address account,
        address vault,
        address liquidator,
        uint16 currencyIndex,
        int256 depositUnderlyingInternal
    ) external payable returns (uint256 vaultSharesFromLiquidation, int256 depositAmountPrimeCash);

    function liquidateVaultCashBalance(
        address account,
        address vault,
        address liquidator,
        uint256 currencyIndex,
        int256 fCashDeposit
    ) external returns (int256 cashToLiquidator);

    function liquidateExcessVaultCash(
        address account,
        address vault,
        address liquidator,
        uint256 excessCashIndex,
        uint256 debtIndex,
        uint256 _depositUnderlyingInternal
    ) external payable returns (int256 cashToLiquidator);
}

interface IVaultAccountHealth {
    function getVaultAccountHealthFactors(address account, address vault) external view returns (
        VaultAccountHealthFactors memory h,
        int256[3] memory maxLiquidatorDepositUnderlying,
        uint256[3] memory vaultSharesToLiquidator
    );

    function calculateDepositAmountInDeleverage(
        uint256 currencyIndex,
        VaultAccount memory vaultAccount,
        VaultConfig memory vaultConfig,
        VaultState memory vaultState,
        int256 depositUnderlyingInternal
    ) external returns (int256 depositInternal, uint256 vaultSharesToLiquidator, PrimeRate memory);

    function getfCashRequiredToLiquidateCash(
        uint16 currencyId,
        uint256 maturity,
        int256 vaultAccountCashBalance
    ) external view returns (int256 fCashRequired, int256 discountFactor);

    function checkVaultAccountCollateralRatio(address vault, address account) external;

    function getVaultAccount(address account, address vault) external view returns (VaultAccount memory);
    function getVaultAccountWithFeeAccrual(
        address account, address vault
    ) external view returns (VaultAccount memory, int256 accruedPrimeVaultFeeInUnderlying);

    function getVaultConfig(address vault) external view returns (VaultConfig memory vaultConfig);

    function getBorrowCapacity(address vault, uint16 currencyId) external view returns (
        uint256 currentPrimeDebtUnderlying,
        uint256 totalfCashDebt,
        uint256 maxBorrowCapacity
    );

    function getSecondaryBorrow(address vault, uint16 currencyId, uint256 maturity) 
        external view returns (int256 totalDebt);

    /// @notice View method to get vault state
    function getVaultState(address vault, uint256 maturity) external view returns (VaultState memory vaultState);

    function getVaultAccountSecondaryDebt(address account, address vault) external view returns (
        uint256 maturity,
        int256[2] memory accountSecondaryDebt,
        int256[2] memory accountSecondaryCashHeld
    );

    function signedBalanceOfVaultTokenId(address account, uint256 id) external view returns (int256);
}

interface IVaultController is IVaultAccountAction, IVaultAction, IVaultLiquidationAction, IVaultAccountHealth {}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface nERC1155Interface {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function signedBalanceOf(address account, uint256 id) external view returns (int256);

    function signedBalanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (int256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external payable;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external payable;

    function decodeToAssets(uint256[] calldata ids, uint256[] calldata amounts)
        external
        view
        returns (PortfolioAsset[] memory);

    function encodeToId(
        uint16 currencyId,
        uint40 maturity,
        uint8 assetType
    ) external pure returns (uint256 id);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalCalculations {
    function calculateNTokensToMint(uint16 currencyId, uint88 amountToDepositExternalPrecision)
        external
        view
        returns (uint256);

    function nTokenPresentValueAssetDenominated(uint16 currencyId) external view returns (int256);

    function nTokenPresentValueUnderlyingDenominated(uint16 currencyId)
        external
        view
        returns (int256);

    function convertNTokenToUnderlying(uint16 currencyId, int256 nTokenBalance) external view returns (int256);

    function getfCashAmountGivenCashAmount(
        uint16 currencyId,
        int88 netCashToAccount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256);

    function getCashAmountGivenfCashAmount(
        uint16 currencyId,
        int88 fCashAmount,
        uint256 marketIndex,
        uint256 blockTime
    ) external view returns (int256, int256);

    function nTokenGetClaimableIncentives(address account, uint256 blockTime)
        external
        view
        returns (uint256);

    function getPresentfCashValue(
        uint16 currencyId,
        uint256 maturity,
        int256 notional,
        uint256 blockTime,
        bool riskAdjusted
    ) external view returns (int256 presentValue);

    function getMarketIndex(
        uint256 maturity,
        uint256 blockTime
    ) external pure returns (uint8 marketIndex);

    function getfCashLendFromDeposit(
        uint16 currencyId,
        uint256 depositAmountExternal,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashAmount,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getfCashBorrowFromPrincipal(
        uint16 currencyId,
        uint256 borrowedAmountExternal,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime,
        bool useUnderlying
    ) external view returns (
        uint88 fCashDebt,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getDepositFromfCashLend(
        uint16 currencyId,
        uint256 fCashAmount,
        uint256 maturity,
        uint32 minLendRate,
        uint256 blockTime
    ) external view returns (
        uint256 depositAmountUnderlying,
        uint256 depositAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function getPrincipalFromfCashBorrow(
        uint16 currencyId,
        uint256 fCashBorrow,
        uint256 maturity,
        uint32 maxBorrowRate,
        uint256 blockTime
    ) external view returns (
        uint256 borrowAmountUnderlying,
        uint256 borrowAmountAsset,
        uint8 marketIndex,
        bytes32 encodedTrade
    );

    function convertCashBalanceToExternal(
        uint16 currencyId,
        int256 cashBalanceInternal,
        bool useUnderlying
    ) external view returns (int256);

    function convertUnderlyingToPrimeCash(
        uint16 currencyId,
        int256 underlyingExternal
    ) external view returns (int256);

    function convertSettledfCash(
        uint16 currencyId,
        uint256 maturity,
        int256 fCashBalance,
        uint256 blockTime
    ) external view returns (int256 signedPrimeSupplyValue);

    function accruePrimeInterest(
        uint16 currencyId
    ) external returns (PrimeRate memory pr, PrimeCashFactors memory);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Deployments.sol";
import "../../contracts/global/Types.sol";
import "../../interfaces/chainlink/AggregatorV2V3Interface.sol";
import "../../interfaces/notional/NotionalGovernance.sol";
import "../../interfaces/notional/IRewarder.sol";
import "../../interfaces/aave/ILendingPool.sol";

interface NotionalGovernance {
    event ListCurrency(uint16 newCurrencyId);
    event UpdateETHRate(uint16 currencyId);
    event UpdateAssetRate(uint16 currencyId);
    event UpdateCashGroup(uint16 currencyId);
    event DeployNToken(uint16 currencyId, address nTokenAddress);
    event UpdateDepositParameters(uint16 currencyId);
    event UpdateInitializationParameters(uint16 currencyId);
    event UpdateTokenCollateralParameters(uint16 currencyId);
    event UpdateGlobalTransferOperator(address operator, bool approved);
    event UpdateAuthorizedCallbackContract(address operator, bool approved);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseRouterAndGuardianUpdated(address indexed pauseRouter, address indexed pauseGuardian);
    event UpdateSecondaryIncentiveRewarder(uint16 indexed currencyId, address rewarder);
    event UpdateInterestRateCurve(uint16 indexed currencyId, uint8 indexed marketIndex);
    event UpdateMaxUnderlyingSupply(uint16 indexed currencyId, uint256 maxUnderlyingSupply);
    event PrimeProxyDeployed(uint16 indexed currencyId, address proxy, bool isCashProxy);

    function transferOwnership(address newOwner, bool direct) external;

    function claimOwnership() external;

    function upgradeBeacon(Deployments.BeaconType proxy, address newBeacon) external;

    function setPauseRouterAndGuardian(address pauseRouter_, address pauseGuardian_) external;

    function listCurrency(
        TokenStorage calldata underlyingToken,
        ETHRateStorage memory ethRate,
        InterestRateCurveSettings calldata primeDebtCurve,
        IPrimeCashHoldingsOracle primeCashHoldingsOracle,
        bool allowPrimeCashDebt,
        uint8 rateOracleTimeWindow5Min,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external returns (uint16 currencyId);

    function enableCashGroup(
        uint16 currencyId,
        CashGroupSettings calldata cashGroup,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external;

    function updateDepositParameters(
        uint16 currencyId,
        uint32[] calldata depositShares,
        uint32[] calldata leverageThresholds
    ) external;

    function updateInitializationParameters(
        uint16 currencyId,
        uint32[] calldata annualizedAnchorRates,
        uint32[] calldata proportions
    ) external;


    function updateTokenCollateralParameters(
        uint16 currencyId,
        uint8 residualPurchaseIncentive10BPS,
        uint8 pvHaircutPercentage,
        uint8 residualPurchaseTimeBufferHours,
        uint8 cashWithholdingBuffer10BPS,
        uint8 liquidationHaircutPercentage
    ) external;

    function updateCashGroup(uint16 currencyId, CashGroupSettings calldata cashGroup) external;

    function updateInterestRateCurve(
        uint16 currencyId,
        uint8[] calldata marketIndices,
        InterestRateCurveSettings[] calldata settings
    ) external;

    function setMaxUnderlyingSupply(
        uint16 currencyId,
        uint256 maxUnderlyingSupply
    ) external;

    function updatePrimeCashHoldingsOracle(
        uint16 currencyId,
        IPrimeCashHoldingsOracle primeCashHoldingsOracle
    ) external;

    function updatePrimeCashCurve(
        uint16 currencyId,
        InterestRateCurveSettings calldata primeDebtCurve
    ) external;

    function enablePrimeDebt(
        uint16 currencyId,
        string calldata underlyingName,
        string calldata underlyingSymbol
    ) external;

    function updateETHRate(
        uint16 currencyId,
        AggregatorV2V3Interface rateOracle,
        bool mustInvert,
        uint8 buffer,
        uint8 haircut,
        uint8 liquidationDiscount
    ) external;

    function updateAuthorizedCallbackContract(address operator, bool approved) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";
import "./nTokenERC20.sol";
import "./nERC1155Interface.sol";
import "./NotionalGovernance.sol";
import "./NotionalCalculations.sol";
import "./NotionalViews.sol";
import "./NotionalTreasury.sol";
import {IVaultController} from "./IVaultController.sol";

interface NotionalProxy is
    nTokenERC20,
    nERC1155Interface,
    NotionalGovernance,
    NotionalTreasury,
    NotionalCalculations,
    NotionalViews,
    IVaultController
{
    /** User trading events */
    event MarketsInitialized(uint16 currencyId);
    event SweepCashIntoMarkets(uint16 currencyId, int256 cashIntoMarkets);

    /// @notice Emitted once when incentives are migrated
    event IncentivesMigrated(
        uint16 currencyId,
        uint256 migrationEmissionRate,
        uint256 finalIntegralTotalSupply,
        uint256 migrationTime
    );
    /// @notice Emitted whenever an account context has updated
    event AccountContextUpdate(address indexed account);
    /// @notice Emitted when an account has assets that are settled
    event AccountSettled(address indexed account);

    /* Liquidation Events */
    event LiquidateLocalCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        int256 netLocalFromLiquidator
    );

    event LiquidateCollateralCurrency(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 collateralCurrencyId,
        int256 netLocalFromLiquidator,
        int256 netCollateralTransfer,
        int256 netNTokenTransfer
    );

    event LiquidatefCashEvent(
        address indexed liquidated,
        address indexed liquidator,
        uint16 localCurrencyId,
        uint16 fCashCurrency,
        int256 netLocalFromLiquidator,
        uint256[] fCashMaturities,
        int256[] fCashNotionalTransfer
    );

    event SetPrimeSettlementRate(
        uint256 indexed currencyId,
        uint256 indexed maturity,
        int256 supplyFactor,
        int256 debtFactor
    );

    /// @notice Emits every time interest is accrued
    event PrimeCashInterestAccrued(
        uint16 indexed currencyId,
        uint256 underlyingScalar,
        uint256 supplyScalar,
        uint256 debtScalar
    );

    event PrimeCashCurveChanged(uint16 indexed currencyId);

    event PrimeCashHoldingsOracleUpdated(uint16 indexed currencyId, address oracle);

    /** UUPS Upgradeable contract calls */
    function upgradeTo(address newImplementation) external;

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable;

    function getImplementation() external view returns (address);

    function owner() external view returns (address);

    function pauseRouter() external view returns (address);

    function pauseGuardian() external view returns (address);

    /** Initialize Markets Action */
    function initializeMarkets(uint16 currencyId, bool isFirstInit) external;

    function sweepCashIntoMarkets(uint16 currencyId) external;

    /** Account Action */
    function nTokenRedeem(
        address redeemer,
        uint16 currencyId,
        uint96 tokensToRedeem_,
        bool sellTokenAssets,
        bool acceptResidualAssets
    ) external returns (int256);

    function enablePrimeBorrow(bool allowPrimeBorrow) external;

    function enableBitmapCurrency(uint16 currencyId) external;

    function settleAccount(address account) external;

    function depositUnderlyingToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external payable returns (uint256);

    function depositAssetToken(
        address account,
        uint16 currencyId,
        uint256 amountExternalPrecision
    ) external returns (uint256);

    function withdraw(
        uint16 currencyId,
        uint88 amountInternalPrecision,
        bool redeemToUnderlying
    ) external returns (uint256);

    /** Batch Action */
    function batchBalanceAction(address account, BalanceAction[] calldata actions) external payable;

    function batchBalanceAndTradeAction(address account, BalanceActionWithTrades[] calldata actions)
        external
        payable;

    function batchBalanceAndTradeActionWithCallback(
        address account,
        BalanceActionWithTrades[] calldata actions,
        bytes calldata callbackData
    ) external payable;

    function batchLend(address account, BatchLend[] calldata actions) external;

    /** Liquidation Action */
    function calculateLocalCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256);

    function liquidateLocalCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint96 maxNTokenLiquidation
    ) external payable returns (int256, int256);

    function calculateCollateralCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation
    ) external returns (int256, int256, int256);

    function liquidateCollateralCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 collateralCurrency,
        uint128 maxCollateralLiquidation,
        uint96 maxNTokenLiquidation,
        bool withdrawCollateral,
        bool redeemToUnderlying
    ) external payable returns (int256, int256, int256);

    function calculatefCashLocalLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashLocal(
        address liquidateAccount,
        uint16 localCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external payable returns (int256[] memory, int256);

    function calculatefCashCrossCurrencyLiquidation(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external returns (int256[] memory, int256);

    function liquidatefCashCrossCurrency(
        address liquidateAccount,
        uint16 localCurrency,
        uint16 fCashCurrency,
        uint256[] calldata fCashMaturities,
        uint256[] calldata maxfCashLiquidateAmounts
    ) external payable returns (int256[] memory, int256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface NotionalTreasury {
    event UpdateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate);

    struct RebalancingTargetConfig {
        address holding;
        uint8 target;
    }

    /// @notice Emitted when reserve balance is updated
    event ReserveBalanceUpdated(uint16 indexed currencyId, int256 newBalance);
    /// @notice Emitted when reserve balance is harvested
    event ExcessReserveBalanceHarvested(uint16 indexed currencyId, int256 harvestAmount);
    /// @dev Emitted when treasury manager is updated
    event TreasuryManagerChanged(address indexed previousManager, address indexed newManager);
    /// @dev Emitted when reserve buffer value is updated
    event ReserveBufferUpdated(uint16 currencyId, uint256 bufferAmount);

    event RebalancingTargetsUpdated(uint16 currencyId, RebalancingTargetConfig[] targets);

    event RebalancingCooldownUpdated(uint16 currencyId, uint40 cooldownTimeInSeconds);

    event CurrencyRebalanced(uint16 currencyId, uint256 supplyFactor, uint256 annualizedInterestRate);

    function claimCOMPAndTransfer(address[] calldata ctokens) external returns (uint256);

    function transferReserveToTreasury(uint16[] calldata currencies)
        external
        returns (uint256[] memory);

    function setTreasuryManager(address manager) external;

    function setReserveBuffer(uint16 currencyId, uint256 amount) external;

    function setReserveCashBalance(uint16 currencyId, int256 reserveBalance) external;

    function setRebalancingTargets(uint16 currencyId, RebalancingTargetConfig[] calldata targets) external;

    function setRebalancingCooldown(uint16 currencyId, uint40 cooldownTimeInSeconds) external;

    function rebalance(uint16[] calldata currencyId) external;

    function updateIncentiveEmissionRate(uint16 currencyId, uint32 newEmissionRate) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

import "../../contracts/global/Types.sol";

interface NotionalViews {
    function getMaxCurrencyId() external view returns (uint16);

    function getCurrencyId(address tokenAddress) external view returns (uint16 currencyId);

    function getCurrency(uint16 currencyId)
        external
        view
        returns (Token memory assetToken, Token memory underlyingToken);

    function getRateStorage(uint16 currencyId)
        external
        view
        returns (ETHRateStorage memory ethRate, AssetRateStorage memory assetRate);

    function getCurrencyAndRates(uint16 currencyId)
        external
        view
        returns (
            Token memory assetToken,
            Token memory underlyingToken,
            ETHRate memory ethRate,
            Deprecated_AssetRateParameters memory assetRate
        );

    function getCashGroup(uint16 currencyId) external view returns (CashGroupSettings memory);

    function getCashGroupAndAssetRate(uint16 currencyId)
        external
        view
        returns (CashGroupSettings memory cashGroup, Deprecated_AssetRateParameters memory assetRate);

    function getInterestRateCurve(uint16 currencyId) external view returns (
        InterestRateParameters[] memory nextInterestRateCurve,
        InterestRateParameters[] memory activeInterestRateCurve
    );

    function getInitializationParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory annualizedAnchorRates, int256[] memory proportions);

    function getDepositParameters(uint16 currencyId)
        external
        view
        returns (int256[] memory depositShares, int256[] memory leverageThresholds);

    function nTokenAddress(uint16 currencyId) external view returns (address);

    function pCashAddress(uint16 currencyId) external view returns (address);

    function pDebtAddress(uint16 currencyId) external view returns (address);

    function getNoteToken() external view returns (address);

    function getOwnershipStatus() external view returns (address owner, address pendingOwner);

    function getGlobalTransferOperatorStatus(address operator)
        external
        view
        returns (bool isAuthorized);

    function getAuthorizedCallbackContractStatus(address callback)
        external
        view
        returns (bool isAuthorized);

    function getSecondaryIncentiveRewarder(uint16 currencyId)
        external
        view
        returns (address incentiveRewarder);

    function getPrimeFactors(uint16 currencyId, uint256 blockTime) external view returns (
        PrimeRate memory primeRate,
        PrimeCashFactors memory factors,
        uint256 maxUnderlyingSupply,
        uint256 totalUnderlyingSupply
    );

    function getPrimeFactorsStored(uint16 currencyId) external view returns (PrimeCashFactors memory);

    function getPrimeCashHoldingsOracle(uint16 currencyId) external view returns (address);

    function getPrimeInterestRateCurve(uint16 currencyId) external view returns (InterestRateParameters memory);

    function getPrimeInterestRate(uint16 currencyId) external view returns (
        uint256 annualDebtRatePreFee,
        uint256 annualDebtRatePostFee,
        uint256 annualSupplyRate
    );

    function getTotalfCashDebtOutstanding(uint16 currencyId, uint256 maturity) external view returns (
        int256 totalfCashDebt,
        int256 fCashDebtHeldInSettlementReserve,
        int256 primeCashHeldInSettlementReserve
    );

    function getSettlementRate(uint16 currencyId, uint40 maturity)
        external
        view
        returns (PrimeRate memory);

    function getMarket(
        uint16 currencyId,
        uint256 maturity,
        uint256 settlementDate
    ) external view returns (MarketParameters memory);

    function getActiveMarkets(uint16 currencyId) external view returns (MarketParameters[] memory);

    function getActiveMarketsAtBlockTime(uint16 currencyId, uint32 blockTime)
        external
        view
        returns (MarketParameters[] memory);

    function getReserveBalance(uint16 currencyId) external view returns (int256 reserveBalance);

    function getNTokenPortfolio(address tokenAddress)
        external
        view
        returns (PortfolioAsset[] memory liquidityTokens, PortfolioAsset[] memory netfCashAssets);

    function getNTokenAccount(address tokenAddress)
        external
        view
        returns (
            uint16 currencyId,
            uint256 totalSupply,
            uint256 incentiveAnnualEmissionRate,
            uint256 lastInitializedTime,
            bytes5 nTokenParameters,
            int256 cashBalance,
            uint256 accumulatedNOTEPerNToken,
            uint256 lastAccumulatedTime
        );

    function getAccount(address account)
        external
        view
        returns (
            AccountContext memory accountContext,
            AccountBalance[] memory accountBalances,
            PortfolioAsset[] memory portfolio
        );

    function getAccountContext(address account) external view returns (AccountContext memory);

    function getAccountPrimeDebtBalance(uint16 currencyId, address account) external view returns (
        int256 debtBalance
    );

    function getAccountBalance(uint16 currencyId, address account)
        external
        view
        returns (
            int256 cashBalance,
            int256 nTokenBalance,
            uint256 lastClaimTime
        );

    function getBalanceOfPrimeCash(
        uint16 currencyId,
        address account
    ) external view returns (int256 cashBalance);

    function getAccountPortfolio(address account) external view returns (PortfolioAsset[] memory);

    function getfCashNotional(
        address account,
        uint16 currencyId,
        uint256 maturity
    ) external view returns (int256);

    function getAssetsBitmap(address account, uint16 currencyId) external view returns (bytes32);

    function getFreeCollateral(address account) external view returns (int256, int256[] memory);

    function getTreasuryManager() external view returns (address);

    function getReserveBuffer(uint16 currencyId) external view returns (uint256);

    function getRebalancingTarget(uint16 currencyId, address holding) external view returns (uint8);

    function getRebalancingCooldown(uint16 currencyId) external view returns (uint40);

    function getStoredTokenBalances(address[] calldata tokens) external view returns (uint256[] memory balances);

    function decodeERC1155Id(uint256 id) external view returns (
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType,
        address vaultAddress,
        bool isfCashDebt
    );

    function encode(
        uint16 currencyId,
        uint256 maturity,
        uint256 assetType,
        address vaultAddress,
        bool isfCashDebt
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface nTokenERC20 {
    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function nTokenTotalSupply(address nTokenAddress) external view returns (uint256);

    function nTokenBalanceOf(uint16 currencyId, address account) external view returns (uint256);

    function nTokenTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function pCashTransferAllowance(
        uint16 currencyId,
        address owner,
        address spender
    ) external view returns (uint256);

    function nTokenTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function pCashTransferApprove(
        uint16 currencyId,
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool);

    function nTokenTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pCashTransfer(
        uint16 currencyId,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function pCashTransferFrom(
        uint16 currencyId,
        address spender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function nTokenTransferApproveAll(address spender, uint256 amount) external returns (bool);

    function nTokenClaimIncentives() external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;

interface WETH9 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external returns (bool);
}