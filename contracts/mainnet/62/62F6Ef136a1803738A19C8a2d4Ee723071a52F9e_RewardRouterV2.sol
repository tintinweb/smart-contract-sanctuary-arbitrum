// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUlpManager {
    function usdg() external view returns (address);
    function cooldownDuration() external returns (uint256);
    function getAumInUsdg(bool maximise) external view returns (uint256);
    function lastAddedAt(address _account) external returns (uint256);
    function addLiquidity(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minUlp) external returns (uint256);
    function addLiquidityForAccount(address _fundingAccount, address _account, address _token, uint256 _amount, uint256 _minUsdg, uint256 _minUlp) external returns (uint256);
    function removeLiquidity(address _tokenOut, uint256 _ulpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function removeLiquidityForAccount(address _account, address _tokenOut, uint256 _ulpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    // function setShortsTrackerAveragePriceWeight(uint256 _shortsTrackerAveragePriceWeight) external;
    function setCooldownDuration(uint256 _cooldownDuration) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
        return sub(a, b, "SafeMath: subtraction overflow");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

pragma solidity 0.6.12;

import "./IERC20.sol";
import "../math/SafeMath.sol";
import "../utils/Address.sol";

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

pragma solidity ^0.6.2;

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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);
    function cumulativeClaimAmounts(address _account) external view returns (uint256);
    function claimedAmounts(address _account) external view returns (uint256);
    function pairAmounts(address _account) external view returns (uint256);
    function getVestedAmount(address _account) external view returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";
import "../libraries/token/SafeERC20.sol";
import "../libraries/utils/ReentrancyGuard.sol";
import "../libraries/utils/Address.sol";

import "./interfaces/IRewardTracker.sol";
import "./interfaces/IVester.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IWETH.sol";
import "../core/interfaces/IUlpManager.sol";
import "../access/Governable.sol";

contract RewardRouterV2 is ReentrancyGuard, Governable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    bool public isInitialized;

    address public weth;

    address public unity;
    address public esUnity;
    address public bnUnity;

    address public ulp; // UNITY Liquidity Provider token

    address public stakedUnityTracker;
    address public bonusUnityTracker;
    address public feeUnityTracker;

    address public stakedUlpTracker;
    address public feeUlpTracker;

    address public ulpManager;

    address public unityVester;
    address public ulpVester;

    mapping (address => address) public pendingReceivers;

    event StakeUnity(address account, address token, uint256 amount);
    event UnstakeUnity(address account, address token, uint256 amount);

    event StakeUlp(address account, uint256 amount);
    event UnstakeUlp(address account, uint256 amount);

    receive() external payable {
        require(msg.sender == weth, "Router: invalid sender");
    }

    function initialize(
        address _weth,
        address _unity,
        address _esUnity,
        address _bnUnity,
        address _ulp,
        address _stakedUnityTracker,
        address _bonusUnityTracker,
        address _feeUnityTracker,
        address _feeUlpTracker,
        address _stakedUlpTracker,
        address _ulpManager,
        address _unityVester,
        address _ulpVester
    ) external onlyGov {
        require(!isInitialized, "RewardRouter: already initialized");
        isInitialized = true;

        weth = _weth;

        unity = _unity;
        esUnity = _esUnity;
        bnUnity = _bnUnity;

        ulp = _ulp;

        stakedUnityTracker = _stakedUnityTracker;
        bonusUnityTracker = _bonusUnityTracker;
        feeUnityTracker = _feeUnityTracker;

        feeUlpTracker = _feeUlpTracker;
        stakedUlpTracker = _stakedUlpTracker;

        ulpManager = _ulpManager;

        unityVester = _unityVester;
        ulpVester = _ulpVester;
    }

    // to help users who accidentally send their tokens to this contract
    function withdrawToken(address _token, address _account, uint256 _amount) external onlyGov {
        IERC20(_token).safeTransfer(_account, _amount);
    }

    function batchStakeUnityForAccount(address[] memory _accounts, uint256[] memory _amounts) external nonReentrant onlyGov {
        address _unity = unity;
        for (uint256 i = 0; i < _accounts.length; i++) {
            _stakeUnity(msg.sender, _accounts[i], _unity, _amounts[i]);
        }
    }

    function stakeUnityForAccount(address _account, uint256 _amount) external nonReentrant onlyGov {
        _stakeUnity(msg.sender, _account, unity, _amount);
    }

    function stakeUnity(uint256 _amount) external nonReentrant {
        _stakeUnity(msg.sender, msg.sender, unity, _amount);
    }

    function stakeEsUnity(uint256 _amount) external nonReentrant {
        _stakeUnity(msg.sender, msg.sender, esUnity, _amount);
    }

    function unstakeUnity(uint256 _amount) external nonReentrant {
        _unstakeUnity(msg.sender, unity, _amount, true);
    }

    function unstakeEsUnity(uint256 _amount) external nonReentrant {
        _unstakeUnity(msg.sender, esUnity, _amount, true);
    }

    function mintAndStakeUlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minUlp) external nonReentrant returns (uint256) {
        require(_amount > 0, "RewardRouter: invalid _amount");

        address account = msg.sender;
        uint256 ulpAmount = IUlpManager(ulpManager).addLiquidityForAccount(account, account, _token, _amount, _minUsdg, _minUlp);
        IRewardTracker(feeUlpTracker).stakeForAccount(account, account, ulp, ulpAmount);
        IRewardTracker(stakedUlpTracker).stakeForAccount(account, account, feeUlpTracker, ulpAmount);

        emit StakeUlp(account, ulpAmount);

        return ulpAmount;
    }

    function mintAndStakeUlpETH(uint256 _minUsdg, uint256 _minUlp) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "RewardRouter: invalid msg.value");

        IWETH(weth).deposit{value: msg.value}();
        IERC20(weth).approve(ulpManager, msg.value);

        address account = msg.sender;
        uint256 ulpAmount = IUlpManager(ulpManager).addLiquidityForAccount(address(this), account, weth, msg.value, _minUsdg, _minUlp);

        IRewardTracker(feeUlpTracker).stakeForAccount(account, account, ulp, ulpAmount);
        IRewardTracker(stakedUlpTracker).stakeForAccount(account, account, feeUlpTracker, ulpAmount);

        emit StakeUlp(account, ulpAmount);

        return ulpAmount;
    }

    function unstakeAndRedeemUlp(address _tokenOut, uint256 _ulpAmount, uint256 _minOut, address _receiver) external nonReentrant returns (uint256) {
        require(_ulpAmount > 0, "RewardRouter: invalid _ulpAmount");

        address account = msg.sender;
        IRewardTracker(stakedUlpTracker).unstakeForAccount(account, feeUlpTracker, _ulpAmount, account);
        IRewardTracker(feeUlpTracker).unstakeForAccount(account, ulp, _ulpAmount, account);
        uint256 amountOut = IUlpManager(ulpManager).removeLiquidityForAccount(account, _tokenOut, _ulpAmount, _minOut, _receiver);

        emit UnstakeUlp(account, _ulpAmount);

        return amountOut;
    }

    function unstakeAndRedeemUlpETH(uint256 _ulpAmount, uint256 _minOut, address payable _receiver) external nonReentrant returns (uint256) {
        require(_ulpAmount > 0, "RewardRouter: invalid _ulpAmount");

        address account = msg.sender;
        IRewardTracker(stakedUlpTracker).unstakeForAccount(account, feeUlpTracker, _ulpAmount, account);
        IRewardTracker(feeUlpTracker).unstakeForAccount(account, ulp, _ulpAmount, account);
        uint256 amountOut = IUlpManager(ulpManager).removeLiquidityForAccount(account, weth, _ulpAmount, _minOut, address(this));

        IWETH(weth).withdraw(amountOut);

        _receiver.sendValue(amountOut);

        emit UnstakeUlp(account, _ulpAmount);

        return amountOut;
    }

    function claim() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeUnityTracker).claimForAccount(account, account);
        IRewardTracker(feeUlpTracker).claimForAccount(account, account);

        IRewardTracker(stakedUnityTracker).claimForAccount(account, account);
        IRewardTracker(stakedUlpTracker).claimForAccount(account, account);
    }

    function claimEsUnity() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(stakedUnityTracker).claimForAccount(account, account);
        IRewardTracker(stakedUlpTracker).claimForAccount(account, account);
    }

    function claimFees() external nonReentrant {
        address account = msg.sender;

        IRewardTracker(feeUnityTracker).claimForAccount(account, account);
        IRewardTracker(feeUlpTracker).claimForAccount(account, account);
    }

    function compound() external nonReentrant {
        _compound(msg.sender);
    }

    function compoundForAccount(address _account) external nonReentrant onlyGov {
        _compound(_account);
    }

    function handleRewards(
        bool _shouldClaimUnity,
        bool _shouldStakeUnity,
        bool _shouldClaimEsUnity,
        bool _shouldStakeEsUnity,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external nonReentrant {
        address account = msg.sender;

        uint256 unityAmount = 0;
        if (_shouldClaimUnity) {
            uint256 unityAmount0 = IVester(unityVester).claimForAccount(account, account);
            uint256 unityAmount1 = IVester(ulpVester).claimForAccount(account, account);
            unityAmount = unityAmount0.add(unityAmount1);
        }

        if (_shouldStakeUnity && unityAmount > 0) {
            _stakeUnity(account, account, unity, unityAmount);
        }

        uint256 esUnityAmount = 0;
        if (_shouldClaimEsUnity) {
            uint256 esUnityAmount0 = IRewardTracker(stakedUnityTracker).claimForAccount(account, account);
            uint256 esUnityAmount1 = IRewardTracker(stakedUlpTracker).claimForAccount(account, account);
            esUnityAmount = esUnityAmount0.add(esUnityAmount1);
        }

        if (_shouldStakeEsUnity && esUnityAmount > 0) {
            _stakeUnity(account, account, esUnity, esUnityAmount);
        }

        if (_shouldStakeMultiplierPoints) {
            uint256 bnUnityAmount = IRewardTracker(bonusUnityTracker).claimForAccount(account, account);
            if (bnUnityAmount > 0) {
                IRewardTracker(feeUnityTracker).stakeForAccount(account, account, bnUnity, bnUnityAmount);
            }
        }

        if (_shouldClaimWeth) {
            if (_shouldConvertWethToEth) {
                uint256 weth0 = IRewardTracker(feeUnityTracker).claimForAccount(account, address(this));
                uint256 weth1 = IRewardTracker(feeUlpTracker).claimForAccount(account, address(this));

                uint256 wethAmount = weth0.add(weth1);
                IWETH(weth).withdraw(wethAmount);

                payable(account).sendValue(wethAmount);
            } else {
                IRewardTracker(feeUnityTracker).claimForAccount(account, account);
                IRewardTracker(feeUlpTracker).claimForAccount(account, account);
            }
        }
    }

    function batchCompoundForAccounts(address[] memory _accounts) external nonReentrant onlyGov {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _compound(_accounts[i]);
        }
    }

    function signalTransfer(address _receiver) external nonReentrant {
        require(IERC20(unityVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(ulpVester).balanceOf(msg.sender) == 0, "RewardRouter: sender has vested tokens");

        _validateReceiver(_receiver);
        pendingReceivers[msg.sender] = _receiver;
    }

    function acceptTransfer(address _sender) external nonReentrant {
        require(IERC20(unityVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");
        require(IERC20(ulpVester).balanceOf(_sender) == 0, "RewardRouter: sender has vested tokens");

        address receiver = msg.sender;
        require(pendingReceivers[_sender] == receiver, "RewardRouter: transfer not signalled");
        delete pendingReceivers[_sender];

        _validateReceiver(receiver);
        _compound(_sender);

        uint256 stakedUnity = IRewardTracker(stakedUnityTracker).depositBalances(_sender, unity);
        if (stakedUnity > 0) {
            _unstakeUnity(_sender, unity, stakedUnity, false);
            _stakeUnity(_sender, receiver, unity, stakedUnity);
        }

        uint256 stakedEsUnity = IRewardTracker(stakedUnityTracker).depositBalances(_sender, esUnity);
        if (stakedEsUnity > 0) {
            _unstakeUnity(_sender, esUnity, stakedEsUnity, false);
            _stakeUnity(_sender, receiver, esUnity, stakedEsUnity);
        }

        uint256 stakedBnUnity = IRewardTracker(feeUnityTracker).depositBalances(_sender, bnUnity);
        if (stakedBnUnity > 0) {
            IRewardTracker(feeUnityTracker).unstakeForAccount(_sender, bnUnity, stakedBnUnity, _sender);
            IRewardTracker(feeUnityTracker).stakeForAccount(_sender, receiver, bnUnity, stakedBnUnity);
        }

        uint256 esUnityBalance = IERC20(esUnity).balanceOf(_sender);
        if (esUnityBalance > 0) {
            IERC20(esUnity).transferFrom(_sender, receiver, esUnityBalance);
        }

        uint256 ulpAmount = IRewardTracker(feeUlpTracker).depositBalances(_sender, ulp);
        if (ulpAmount > 0) {
            IRewardTracker(stakedUlpTracker).unstakeForAccount(_sender, feeUlpTracker, ulpAmount, _sender);
            IRewardTracker(feeUlpTracker).unstakeForAccount(_sender, ulp, ulpAmount, _sender);

            IRewardTracker(feeUlpTracker).stakeForAccount(_sender, receiver, ulp, ulpAmount);
            IRewardTracker(stakedUlpTracker).stakeForAccount(receiver, receiver, feeUlpTracker, ulpAmount);
        }

        IVester(unityVester).transferStakeValues(_sender, receiver);
        IVester(ulpVester).transferStakeValues(_sender, receiver);
    }

    function _validateReceiver(address _receiver) private view {
        require(IRewardTracker(stakedUnityTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedUnityTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedUnityTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedUnityTracker.cumulativeRewards > 0");

        require(IRewardTracker(bonusUnityTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: bonusUnityTracker.averageStakedAmounts > 0");
        require(IRewardTracker(bonusUnityTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: bonusUnityTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeUnityTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeUnityTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeUnityTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeUnityTracker.cumulativeRewards > 0");

        require(IVester(unityVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: unityVester.transferredAverageStakedAmounts > 0");
        require(IVester(unityVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: unityVester.transferredCumulativeRewards > 0");

        require(IRewardTracker(stakedUlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: stakedUlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(stakedUlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: stakedUlpTracker.cumulativeRewards > 0");

        require(IRewardTracker(feeUlpTracker).averageStakedAmounts(_receiver) == 0, "RewardRouter: feeUlpTracker.averageStakedAmounts > 0");
        require(IRewardTracker(feeUlpTracker).cumulativeRewards(_receiver) == 0, "RewardRouter: feeUlpTracker.cumulativeRewards > 0");

        require(IVester(ulpVester).transferredAverageStakedAmounts(_receiver) == 0, "RewardRouter: unityVester.transferredAverageStakedAmounts > 0");
        require(IVester(ulpVester).transferredCumulativeRewards(_receiver) == 0, "RewardRouter: unityVester.transferredCumulativeRewards > 0");

        require(IERC20(unityVester).balanceOf(_receiver) == 0, "RewardRouter: unityVester.balance > 0");
        require(IERC20(ulpVester).balanceOf(_receiver) == 0, "RewardRouter: ulpVester.balance > 0");
    }

    function _compound(address _account) private {
        _compoundUnity(_account);
        _compoundUlp(_account);
    }

    function _compoundUnity(address _account) private {
        uint256 esUnityAmount = IRewardTracker(stakedUnityTracker).claimForAccount(_account, _account);
        if (esUnityAmount > 0) {
            _stakeUnity(_account, _account, esUnity, esUnityAmount);
        }

        uint256 bnUnityAmount = IRewardTracker(bonusUnityTracker).claimForAccount(_account, _account);
        if (bnUnityAmount > 0) {
            IRewardTracker(feeUnityTracker).stakeForAccount(_account, _account, bnUnity, bnUnityAmount);
        }
    }

    function _compoundUlp(address _account) private {
        uint256 esUnityAmount = IRewardTracker(stakedUlpTracker).claimForAccount(_account, _account);
        if (esUnityAmount > 0) {
            _stakeUnity(_account, _account, esUnity, esUnityAmount);
        }
    }

    function _stakeUnity(address _fundingAccount, address _account, address _token, uint256 _amount) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        IRewardTracker(stakedUnityTracker).stakeForAccount(_fundingAccount, _account, _token, _amount);
        IRewardTracker(bonusUnityTracker).stakeForAccount(_account, _account, stakedUnityTracker, _amount);
        IRewardTracker(feeUnityTracker).stakeForAccount(_account, _account, bonusUnityTracker, _amount);

        emit StakeUnity(_account, _token, _amount);
    }

    function _unstakeUnity(address _account, address _token, uint256 _amount, bool _shouldReduceBnUnity) private {
        require(_amount > 0, "RewardRouter: invalid _amount");

        uint256 balance = IRewardTracker(stakedUnityTracker).stakedAmounts(_account);

        IRewardTracker(feeUnityTracker).unstakeForAccount(_account, bonusUnityTracker, _amount, _account);
        IRewardTracker(bonusUnityTracker).unstakeForAccount(_account, stakedUnityTracker, _amount, _account);
        IRewardTracker(stakedUnityTracker).unstakeForAccount(_account, _token, _amount, _account);

        if (_shouldReduceBnUnity) {
            uint256 bnUnityAmount = IRewardTracker(bonusUnityTracker).claimForAccount(_account, _account);
            if (bnUnityAmount > 0) {
                IRewardTracker(feeUnityTracker).stakeForAccount(_account, _account, bnUnity, bnUnityAmount);
            }

            uint256 stakedBnUnity = IRewardTracker(feeUnityTracker).depositBalances(_account, bnUnity);
            if (stakedBnUnity > 0) {
                uint256 reductionAmount = stakedBnUnity.mul(_amount).div(balance);
                IRewardTracker(feeUnityTracker).unstakeForAccount(_account, bnUnity, reductionAmount, _account);
                IMintable(bnUnity).burn(_account, reductionAmount);
            }
        }

        emit UnstakeUnity(_account, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMintable {
    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}