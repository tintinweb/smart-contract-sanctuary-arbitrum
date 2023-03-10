// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

pragma solidity 0.8.13;

interface IChamSLIZ {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function deposit(uint256 _amount) external;
    function notifyFeeAmounts(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IDepositToken {
    function initialize(address _pool) external returns (bool);
    function mint(address _to, uint256 _value) external returns (bool);
    function burn(address _from, uint256 _value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFeeConfig {
    struct FeeCategory {
        uint256 total;
        uint256 co;
        uint256 call;
        uint256 strategist;
        string label;
        bool active;
    }
    function getFees(address strategy) external view returns (FeeCategory memory);
    function stratFeeId(address strategy) external view returns (uint256);
    function setStratFeeId(uint256 feeId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IRewardPool {
    function notifyRewardAmount() external;

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidLizardProxy {
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256 _tokenId);
    function increaseAmount(uint256 value) external;
    function increaseUnlockTime() external;
    function locked() external view returns (uint256 amount, uint256 endTime);
    function resetVote() external;
    function whitelist(address _token) external;
    function SLIZ() external returns (address);
    function ve() external returns (address);
    function solidVoter() external returns (address);
    function pause() external;
    function unpause() external;
    function release() external;
    function claimVeEmissions() external returns (uint256);
    function merge(uint256 _from) external;
    function vote(address[] calldata poolVote, int256[] calldata weights) external;
    function lpInitialized(address lp) external returns (bool);
    function router() external returns (address);

    function getBribeReward(address _lp) external;
    function getTradingFeeReward(address _lp) external;
    function getReward(address _lp) external;

    function tokenId() external view returns (uint256);
    function claimableReward(address _lp) external view returns (uint256);
    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _receiver, address _token, uint256 _amount) external;

    function totalDeposited(address _token) external view returns (uint);
    function totalLiquidityOfGauge(address _token) external view returns (uint);
    function votingBalance() external view returns (uint);
    function votingTotal() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidlyRouter {
    // Routes
    struct Routes {
        address from;
        address to;
        bool stable;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        bool stable, 
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable, 
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokensSimple(
        uint amountIn, 
        uint amountOutMin, 
        address tokenFrom, 
        address tokenTo,
        bool stable, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        Routes[] memory route, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

    function getAmountsOut(uint amountIn, Routes[] memory routes) external view returns (uint[] memory amounts);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        Routes[] calldata routes,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../interfaces/IRewardPool.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/ISolidLizardProxy.sol";
import "../interfaces/IDepositToken.sol";
import "../interfaces/IChamSLIZ.sol";
import "../interfaces/IFeeConfig.sol";
import "../lib/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LpDepositor is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable WETH;
    IERC20 public immutable SLIZ;
    IChamSLIZ public immutable chamSLIZ;
    ISolidLizardProxy public immutable proxy;
    IRewardPool public rewardPool;
    IFeeConfig public coFeeConfig;

    ISolidlyRouter public router;
    ISolidlyRouter.Routes[] public slizToWethRoute;

    address public immutable depositTokenImplementation;
    address public coFeeRecipient;
    address public polWallet;

    uint256 public pendingFeeSLIZ;
    uint256 public lastFeeTransfer;

    uint256 public constant MAX = 10000; // 100%
    uint256 public constant MAX_RATE = 1e18;

    bool public harvestOnDeposit;
    bool public useFixedBoostedFlag = true;
    uint256 public fixedBoostedPercent = 2000; // 20%
    uint256 public feeBoostedPercent = 2000; // 20%
    uint256 public rewardPoolRate = 2000; // 20%

    // pool -> deposit token
    mapping(address => address) public depositTokens;
    // user -> pool -> deposit amount
    mapping(address => mapping(address => uint256)) public userBalances;
    // pool -> total deposit amount
    mapping(address => uint256) public totalBalances;

    // pool -> integrals
    mapping(address => uint256) rewardIntegral;
    // user -> pool -> integrals
    mapping(address => mapping(address => uint256)) rewardIntegralFor;
    // user -> pool -> claimable
    mapping(address => mapping(address => uint256)) unclaimedRewards;

    event Deposit(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    event Claimed(
        address indexed caller,
        address indexed receiver,
        address[] tokens,
        uint256 slizAmount
    );

    event TransferDeposit(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event SetUseFixedBoostedFlag(bool _enabled);
    event SetFixedBoostedPercent(uint256 oldRate, uint256 newRate);
    event SetFeeBoostedPercent(uint256 oldRate, uint256 newRate);
    event SetHarvestOnDeposit(bool isEnabled);
    event SetCoFeeRecipient(address oldFeeRecipient, address newFeeRecipient);
    event SetFeeId(uint256 newFeeId);
    event SetRewardPoolRate(uint256 oldRewardPoolRate, uint256 newRewardPoolRate);
    event SetRewardPool(IRewardPool oldRewardPool, IRewardPool newRewardPool);
    event SetPolWallet(address oldValue, address newValue);
    event SetRouterAndRoute(
        ISolidlyRouter _router,
        ISolidlyRouter.Routes[] _route
    );

    constructor(
        IERC20 _WETH,
        IERC20 _SLIZ,
        ISolidLizardProxy _proxy,
        IChamSLIZ _chamSLIZ,
        IRewardPool _rewardPool,
        IFeeConfig _coFeeConfig,
        address _coFeeRecipient,
        address _depositTokenImplementation,
        address _polWallet,
        ISolidlyRouter _router,
        ISolidlyRouter.Routes[] memory _slizToWethRoute
    ) {
        WETH = _WETH;
        SLIZ = _SLIZ;
        proxy = _proxy;
        chamSLIZ = _chamSLIZ;
        rewardPool = _rewardPool;
        coFeeConfig = _coFeeConfig;
        coFeeRecipient = _coFeeRecipient;
        depositTokenImplementation = _depositTokenImplementation;
        polWallet = _polWallet;
        for (uint i; i < _slizToWethRoute.length; i++) {
            slizToWethRoute.push(_slizToWethRoute[i]);
        }
        router = _router;
        SLIZ.approve(address(chamSLIZ), type(uint256).max);
        SLIZ.approve(address(_router), type(uint256).max);
    }

    function claimable(address _user, address[] calldata _tokens) external view returns (uint256[] memory) {
        uint256[] memory pending = new uint256[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 totalClaimable = proxy.claimableReward(token);
            pending[i] = unclaimedRewards[_user][token];
            uint256 balance = userBalances[_user][token];
            if (balance == 0) continue;

            uint256 integralReward = rewardIntegral[token];
            uint256 total = totalBalances[token];
            if (total > 0) {
                uint256 reward = totalClaimable;
                uint256 fee = reward * fixedBoostedPercent / MAX;
                if (!useFixedBoostedFlag) {
                    uint256 boostedRatio = calculateBoostedRatio(token);
                    fee = (reward * feeBoostedPercent * (boostedRatio - MAX_RATE)) / (MAX * boostedRatio);
                }

                reward = reward - fee;
                integralReward = integralReward + MAX_RATE * reward / total;
            }

            uint256 integralRewardFor = rewardIntegralFor[_user][token];
            if (integralRewardFor < integralReward) {
                pending[i] = pending[i] + balance * (integralReward - integralRewardFor) / MAX_RATE;
            }
        }

        return pending;
    }

    function deposit(address _user, address _token, uint256 _amount) external {
        require(proxy.lpInitialized(_token), "LpDepositor: TOKEN_DEPOSIT_INVALID");
        IERC20(_token).safeTransferFrom(msg.sender, address(proxy), _amount);

        uint256 balance = userBalances[_user][_token];
        uint256 total = totalBalances[_token];
        
        if (harvestOnDeposit) {
            address[] memory _tokens = new address[](1);
            _tokens[0] = _token;
            claim(msg.sender, _tokens);
        }

        proxy.deposit(_token, _amount);
        userBalances[_user][_token] = balance + _amount;
        totalBalances[_token] = total + _amount;

        address depositToken = depositTokens[_token];
        if (depositToken == address(0)) {
            depositToken = _deployDepositToken(_token);
            depositTokens[_token] = depositToken;
        }
        IDepositToken(depositToken).mint(_user, _amount);
        emit Deposit(msg.sender, _user, _token, _amount);
    }

    function withdraw(address _receiver, address _token, uint256 _amount) external {
        uint256 balance = userBalances[msg.sender][_token];
        uint256 total = totalBalances[_token];
        require(balance >= _amount, "LpDepositor: withdraw amount exceeds balance");

        address[] memory _tokens = new address[](1);
        _tokens[0] = _token;
        claim(_receiver, _tokens);
        
        userBalances[msg.sender][_token] = balance - _amount;
        totalBalances[_token] = total - _amount;

        address depositToken = depositTokens[_token];
        IDepositToken(depositToken).burn(msg.sender, _amount);

        proxy.withdraw(_receiver, _token, _amount);
        emit Withdraw(msg.sender, _receiver, _token, _amount);
    }

    /**
        @notice Claim pending SLIZ rewards
        @param _receiver Account to send claimed rewards to
        @param _tokens List of LP tokens to claim for
    */
    function claim(address _receiver, address[] memory _tokens) public {
        uint256 unclaimedReward = 0;
        for (uint i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            uint256 before = SLIZ.balanceOf(address(this));
            proxy.getReward(token);
            uint256 reward = SLIZ.balanceOf(address(this)) - before;

            if (reward > 0) {
                _updateIntegrals(msg.sender, token, userBalances[msg.sender][token], totalBalances[token], reward);
                unclaimedReward = unclaimedReward + unclaimedRewards[msg.sender][token];
            }
            delete unclaimedRewards[msg.sender][token];
        }

        if (unclaimedReward > 0) {
            SLIZ.safeTransfer(_receiver, unclaimedReward);
        }

        emit Claimed(msg.sender, _receiver, _tokens, unclaimedReward);
    }

    function transferDeposit(address _token, address _from, address _to, uint256 _amount) external returns (bool) {
        require(msg.sender == depositTokens[_token], "LpDepositor: FORBIDDEN");

        uint256 total = totalBalances[_token];
        uint256 balance = userBalances[_from][_token];
        require(balance >= _amount, "LpDepositor: transfer amount exceeds balance");

        uint256 before = SLIZ.balanceOf(address(this));
        proxy.getReward(_token);
        uint256 reward = SLIZ.balanceOf(address(this)) - before;
        _updateIntegrals(_from, _token, balance, total, reward);
        userBalances[_from][_token] = balance - _amount;

        balance = userBalances[_to][_token];
        _updateIntegrals(_to, _token, balance, total - _amount, 0);
        userBalances[_to][_token] = balance + _amount;
        emit TransferDeposit(_token, _from, _to, _amount);
        return true;
    }

    function pushPendingProtocolFees() public {
        lastFeeTransfer = block.timestamp;
        uint256 slizPendingFee = pendingFeeSLIZ;
        if (slizPendingFee > 0) {
            pendingFeeSLIZ = 0;
            uint256 slizBalance = SLIZ.balanceOf(address(this));
            if (slizPendingFee > slizBalance) slizPendingFee = slizBalance;
            _chargeFees(slizPendingFee);
        }
    }

    function setUseFixedBoostedFlag(bool _isEnable) external onlyOwner {
        useFixedBoostedFlag = _isEnable;
        emit SetUseFixedBoostedFlag(_isEnable);
    }

    function setFixedBoostedPercent(uint256 _rate) external onlyOwner {
        // validation from 0-20%
        require(_rate <= 2000, "LpDepositor: OUT_OF_RANGE");
        emit SetFixedBoostedPercent(fixedBoostedPercent, _rate);
        fixedBoostedPercent = _rate;
    }

    function setFeeBoostedPercent(uint256 _rate) external onlyOwner {
        // validation from 0-50%
        require(_rate <= 5000, "LpDepositor: OUT_OF_RANGE");
        emit SetFeeBoostedPercent(feeBoostedPercent, _rate);
        feeBoostedPercent = _rate;
    }

    function setHarvestOnDeposit(bool _harvestOnDeposit) external onlyOwner {
        harvestOnDeposit = _harvestOnDeposit;
        emit SetHarvestOnDeposit(_harvestOnDeposit);
    }

    // Set our router to exchange our rewards, also update new route.
    function setRouterAndRoute(
        ISolidlyRouter _router,
        ISolidlyRouter.Routes[] calldata _route
    ) external onlyOwner {
        uint256 slizToWethRouteLength = slizToWethRoute.length;
        for (uint i; i < slizToWethRouteLength; i++) slizToWethRoute.pop();
        for (uint i; i < _route.length; i++) slizToWethRoute.push(_route[i]);
        router = _router;
        SLIZ.approve(address(_router), type(uint256).max);
        emit SetRouterAndRoute(_router, _route);
    }

    function setFeeId(uint256 feeId) external onlyOwner {
        coFeeConfig.setStratFeeId(feeId);
        emit SetFeeId(feeId);
    }

    function setCoFeeRecipient(address _coFeeRecipient) external onlyOwner {
        emit SetCoFeeRecipient(coFeeRecipient, _coFeeRecipient);
        coFeeRecipient = _coFeeRecipient;
    }

    function setPolWallet(address _polWallet) external onlyOwner {
        emit SetPolWallet(polWallet, _polWallet);
        polWallet = _polWallet;
    }

    function setRewardPool(IRewardPool _rewardPool) external onlyOwner {
        emit SetRewardPool(rewardPool, _rewardPool);
        rewardPool = _rewardPool;
    }

    function setRewardPoolRate(uint256 _rewardPoolRate) external onlyOwner {
        require(_rewardPoolRate <= MAX, "LpDepositor: OUT_OF_RANGE");
        emit SetRewardPoolRate(rewardPoolRate, _rewardPoolRate);
        rewardPoolRate = _rewardPoolRate;
    }

    function calculateBoostedRatio(address _token) public view returns (uint256) {
        uint256 amountDeposited = proxy.totalDeposited(_token);
        uint256 amountBoostedInitial = amountDeposited * 4 / 10;
        uint256 amountBoostedExtra = (proxy.totalLiquidityOfGauge(_token) * proxy.votingBalance() * 6) / (10 * proxy.votingTotal());
        uint256 boostedRatio = Math.min(amountBoostedInitial + amountBoostedExtra, amountDeposited) * MAX_RATE / amountBoostedInitial;
        return boostedRatio;
    }

    function _deployDepositToken(address pool) internal returns (address token) {
        // taken from https://solidity-by-example.org/app/minimal-proxy/
        bytes20 targetBytes = bytes20(depositTokenImplementation);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            token := create(0, clone, 0x37)
        }
        IDepositToken(token).initialize(pool);
        return token;
    }

    function _updateIntegrals(
        address user,
        address pool,
        uint256 balance,
        uint256 total,
        uint256 reward
    ) internal {
        uint256 integralReward = rewardIntegral[pool];
        if (reward > 0) {
            uint256 fee = reward * fixedBoostedPercent / MAX;
            if (!useFixedBoostedFlag) {
                uint256 boostedRatio = calculateBoostedRatio(pool);
                fee = (reward * feeBoostedPercent * (boostedRatio - MAX_RATE)) / (MAX * boostedRatio);
            }
            reward = reward - fee;
            pendingFeeSLIZ = pendingFeeSLIZ + fee;

            integralReward = integralReward + MAX_RATE * reward / total;
            rewardIntegral[pool] = integralReward;
        }
        uint256 integralRewardFor = rewardIntegralFor[user][pool];
        if (integralRewardFor < integralReward) {
            unclaimedRewards[user][pool] = unclaimedRewards[user][pool] + balance * (integralReward - integralRewardFor) / MAX_RATE;
            rewardIntegralFor[user][pool] = integralReward;
        }

        if (lastFeeTransfer + 86400 < block.timestamp) {
            // once a day, transfer pending rewards
            // we only do this on updates to pools without extra incentives because each
            // operation can be gas intensive
            pushPendingProtocolFees();
        }
    }

    function _chargeFees(uint256 rewardAmount) internal {
        // Charge our fees here since we send CeThena to reward pool
        IFeeConfig.FeeCategory memory fees = coFeeConfig.getFees(address(this));
        uint256 feeAmount = (rewardAmount * fees.total) / 1e18;
        if (feeAmount > 0) {
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                feeAmount,
                0,
                slizToWethRoute,
                coFeeRecipient,
                block.timestamp
            );
        }

        chamSLIZ.deposit(rewardAmount - feeAmount);
        uint256 rewardRemainingAmount = chamSLIZ.balanceOf(address(this));
        if (rewardRemainingAmount > 0) {
           if (rewardPoolRate > 0) {
                uint256 rewardPoolAmount = rewardRemainingAmount * rewardPoolRate / MAX;
                chamSLIZ.transfer(address(rewardPool), rewardPoolAmount);
                rewardPool.notifyRewardAmount();
                rewardRemainingAmount = rewardRemainingAmount - rewardPoolAmount;
            }
            chamSLIZ.transfer(polWallet, rewardRemainingAmount);
        }
    }
}