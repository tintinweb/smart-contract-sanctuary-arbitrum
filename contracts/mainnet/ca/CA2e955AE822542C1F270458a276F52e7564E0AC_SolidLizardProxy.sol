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

interface IController {
    function veDist() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IMinter {
    function controller() external view returns (address);
    function updatePeriod() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IPairFactory {
    function allPairsLength() external view returns (uint);
    function isPair(address pair) external view returns (bool);
    function pairCodeHash() external pure returns (bytes32);
    function getPair(address tokenA, address token, bool stable) external view returns (address);
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pair);
    function claimFees() external returns (uint, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidLizardGauge {
    function balanceOf(address account) external view returns (uint);
    function claimFees() external returns (uint claimed0, uint claimed1);
    function deposit(uint amount, uint tokenId) external;
    function depositAll(uint amount) external;
    function earned(address reward, address account) external view returns (uint);
    function getReward(address account, address[] memory token) external;
    function withdraw(uint amount) external;
    function withdrawAll() external;
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISolidlyGauge {
    function getReward(uint256 tokenId, address[] memory rewards) external;
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

pragma solidity 0.8.13;

interface IVeDist {
    function claim(uint256 tokenId) external returns (uint);
    function claimable(uint _tokenId) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVeToken {
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256 _tokenId);
    function increaseAmount(uint256 tokenId, uint256 value) external;
    function increaseUnlockTime(uint256 tokenId, uint256 duration) external;
    function withdraw(uint256 tokenId) external;
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);
    function controller() external view returns (address);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
    function locked(uint256 tokenId) external view returns (uint256 amount, uint256 endTime);
    function token() external view returns (address);
    function merge(uint _from, uint _to) external;
    function transferFrom(address _from, address _to, uint _tokenId) external;
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IVoter {
    function vote(uint256 tokenId, address[] calldata poolVote, int256[] calldata weights) external;
    function whitelist(address token, uint256 tokenId) external;
    function reset(uint256 tokenId) external;
    function gauges(address lp) external view returns (address);
    function ve() external view returns (address);
    function minter() external view returns (address);
    function bribes(address gauge) external view returns (address);
    function votes(uint256 id, address lp) external view returns (uint256);
    function poolVote(uint256 id, uint256 index) external view returns (address);
    function lastVote(uint256 id) external view returns (uint256);
    function weights(address pool) external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IVeToken.sol";
import "../interfaces/IVoter.sol";
import "../interfaces/IVeDist.sol";
import "../interfaces/IMinter.sol";
import "../interfaces/IController.sol";
import "../interfaces/ISolidlyRouter.sol";
import "../interfaces/ISolidLizardGauge.sol";
import "../interfaces/ISolidlyGauge.sol";
import "../interfaces/IPairFactory.sol";

contract SolidLizardProxy is Ownable {
    using SafeERC20 for IERC20;

    // Voted Gauges
    struct Gauges {
        address bribe;
        address[] bribeTokens;
        address[] feeTokens;
        address[] rewardTokens;
    }

    IERC20 public immutable SLIZ;
    IVeToken public immutable ve;
    IVeDist public immutable veDist;
    IVoter public immutable solidVoter;
    ISolidlyRouter public router;

    address public lpDepositor;
    address public chamSLIZ;

    address public pendingLpDepositor;
    address public pendingChamSLIZ;
    uint256 public newAddressDeadline;

    uint256 public constant MAX_LOCK = 365 days * 4;
    uint256 public tokenId;

    mapping(address => bool) isApproved;

    mapping(address => Gauges) public gauges;
    mapping(address => bool) public lpInitialized;
    mapping(address => ISolidlyRouter.Routes[]) public routes;

    event SetAddresses(address _chamSLIZ, address lpDepositor);
    event AddedGauge(address bribe, address[] bribeTokens, address[] feeTokens, address[] rewardTokens);
    event AddedRewardToken(address token);
    event NewAddressesCommitted(address chamSLIZ, address lpDepositor, uint256 newAddressDeadline);

    constructor(IERC20 _SLIZ, IVoter _solidVoter, ISolidlyRouter _router) {
        SLIZ = _SLIZ;
        solidVoter = _solidVoter;
        ve = IVeToken(_solidVoter.ve());
        router = _router;

        IMinter _minter = IMinter(_solidVoter.minter());
        IController _controller = IController(_minter.controller());
        veDist = IVeDist(_controller.veDist());

        SLIZ.safeApprove(address(ve), type(uint256).max);
    }

    modifier onlyChamSLIZ() {
        require(msg.sender == chamSLIZ, "Proxy: FORBIDDEN");
        _;
    }

    modifier onlyLPDepositor() {
        require(msg.sender == lpDepositor, "Proxy: FORBIDDEN");
        _;
    }

    function setAddresses(
        address _chamSLIZ,
        address _lpDepositor
    ) external onlyOwner {
        require(address(chamSLIZ) == address(0), "Proxy: ALREADY_SET");
        chamSLIZ = _chamSLIZ;
        lpDepositor = _lpDepositor;

        emit SetAddresses(_chamSLIZ, _lpDepositor);
    }

    function createLock(
        uint256 _amount,
        uint256 _lock_duration
    ) external onlyChamSLIZ returns (uint256 _tokenId) {
        require(tokenId == 0, "ChamSlizStaker: ASSIGNED");
        _tokenId = ve.createLock(_amount, _lock_duration);
        tokenId = _tokenId;
    }

    function merge(uint256 _from) external {
        require(
            ve.ownerOf(_from) == address(this),
            "Proxy: OWNER_IS_NOT_PROXY"
        );
        ve.merge(_from, tokenId);
    }

    function increaseAmount(uint256 _amount) external onlyChamSLIZ {
        ve.increaseAmount(tokenId, _amount);
    }

    function increaseUnlockTime() external onlyChamSLIZ {
        ve.increaseUnlockTime(tokenId, MAX_LOCK);
    }

    function resetVote() external onlyChamSLIZ {
        solidVoter.reset(tokenId);
    }

    function release() external onlyChamSLIZ {
        uint256 before = SLIZ.balanceOf(address(this));
        ve.withdraw(tokenId);
        uint256 amount = SLIZ.balanceOf(address(this)) - before;
        if (amount > 0) SLIZ.safeTransfer(chamSLIZ, amount);
        tokenId = 0;
    }

    function whitelist(address _token) external onlyOwner {
        solidVoter.whitelist(_token, tokenId);
    }

    function locked() external view returns (uint256 amount, uint256 endTime) {
        return ve.locked(tokenId);
    }

    function pause() external onlyChamSLIZ {
        SLIZ.safeApprove(address(ve), 0);
    }

    function unpause() external onlyChamSLIZ {
        SLIZ.safeApprove(address(ve), type(uint256).max);
    }

    function deposit(address _token, uint256 _amount) external onlyLPDepositor {
        address gauge = solidVoter.gauges(_token);
        if (!isApproved[_token]) {
            IERC20(_token).safeApprove(address(gauge), type(uint256).max);
            isApproved[_token] = true;
        }

        ISolidLizardGauge(gauge).deposit(_amount, tokenId);
    }

    function withdraw(
        address _receiver,
        address _token,
        uint256 _amount
    ) external onlyLPDepositor {
        address gauge = solidVoter.gauges(_token);
        ISolidLizardGauge(gauge).withdraw(_amount);
        IERC20(_token).transfer(_receiver, _amount);
    }

    function claimVeEmissions() external onlyChamSLIZ returns (uint256) {
        return veDist.claim(tokenId);
    }

    function totalDeposited(address _token) external view returns (uint) {
        address gauge = solidVoter.gauges(_token);
        return ISolidLizardGauge(gauge).balanceOf(address(this));
    }

    function totalLiquidityOfGauge(
        address _token
    ) external view returns (uint) {
        address gauge = solidVoter.gauges(_token);
        return ISolidLizardGauge(gauge).totalSupply();
    }

    function votingBalance() external view returns (uint) {
        return ve.balanceOfNFT(tokenId);
    }

    function votingTotal() external view returns (uint) {
        return ve.totalSupply();
    }

    // Voting
    function vote(
        address[] calldata _tokenVote,
        int256[] calldata _weights
    ) external onlyChamSLIZ {
        solidVoter.vote(tokenId, _tokenVote, _weights);
    }

    // Add gauge
    function addGauge(
        address _lp,
        address[] calldata _bribeTokens,
        address[] calldata _feeTokens,
        address[] calldata _rewardTokens
    ) external onlyOwner {
        address gauge = solidVoter.gauges(_lp);
        gauges[_lp] = Gauges(
            solidVoter.bribes(gauge),
            _bribeTokens,
            _feeTokens,
            _rewardTokens
        );
        lpInitialized[_lp] = true;
        emit AddedGauge(solidVoter.bribes(gauge), _bribeTokens, _feeTokens, _rewardTokens);
    }

    // Delete a reward token
    function deleteRewardToken(address _token) external onlyOwner {
        delete routes[_token];
    }

    // Add multiple reward tokens
    function addMultipleRewardTokens(
        ISolidlyRouter.Routes[][] calldata _routes
    ) external onlyOwner {
        for (uint256 i; i < _routes.length; i++) {
            addRewardToken(_routes[i]);
        }
    }

    // Add a reward token
    function addRewardToken(
        ISolidlyRouter.Routes[] calldata _route
    ) public onlyOwner {
        address _rewardToken = _route[0].from;
        require(_rewardToken != address(SLIZ), "Proxy: ROUTE_FROM_IS_SLIZ");
        require(
            _route[_route.length - 1].to == address(SLIZ),
            "Proxy: ROUTE_TO_NOT_SLIZ"
        );
        for (uint256 i; i < _route.length; i++) {
            routes[_rewardToken].push(_route[i]);
        }
        IERC20(_rewardToken).approve(address(router), type(uint256).max);
        emit AddedRewardToken(_rewardToken);
    }

    function getBribeReward(address _lp) external onlyChamSLIZ {
        Gauges memory _gauges = gauges[_lp];
        ISolidlyGauge(_gauges.bribe).getReward(tokenId, _gauges.bribeTokens);

        for (uint256 i; i < _gauges.bribeTokens.length; ++i) {
            address bribeToken = _gauges.bribeTokens[i];
            uint256 tokenBal = IERC20(bribeToken).balanceOf(address(this));
            if (tokenBal > 0) {
                if (bribeToken == address(SLIZ) || bribeToken == address(chamSLIZ)) {
                    IERC20(bribeToken).safeTransfer(chamSLIZ, tokenBal);
                } else {
                    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        tokenBal,
                        0,
                        routes[bribeToken],
                        chamSLIZ,
                        block.timestamp
                    );
                }
            }
        }
    }

    function getTradingFeeReward(address _lp) external onlyChamSLIZ {
        Gauges memory _gauges = gauges[_lp];
        IPairFactory(_lp).claimFees();
        for (uint256 i; i < _gauges.feeTokens.length; ++i) {
            address feeToken = _gauges.feeTokens[i];
            uint256 tokenBal = IERC20(feeToken).balanceOf(address(this));
            if (tokenBal > 0) {
                if (feeToken == address(SLIZ) || feeToken == address(chamSLIZ)) {
                    IERC20(feeToken).safeTransfer(chamSLIZ, tokenBal);
                } else {
                    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        tokenBal,
                        0,
                        routes[feeToken],
                        chamSLIZ,
                        block.timestamp
                    );
                }
            }
        }
    }

    function claimableReward(address _lp) external view returns (uint256) {
        address gauge = solidVoter.gauges(_lp);
        Gauges memory _gauges = gauges[_lp];

        uint256 totalReward = 0;
        for (uint256 i; i < _gauges.rewardTokens.length; ++i) {
            address rewardToken = _gauges.rewardTokens[i];
            
            uint256 reward = ISolidLizardGauge(gauge).earned(rewardToken, address(this));
            if (reward > 0) {
                if (rewardToken != address(SLIZ)) {
                    uint256 rewardSLIZ = router.getAmountsOut(reward, routes[rewardToken])[routes[rewardToken].length];
                    totalReward = totalReward + rewardSLIZ;
                } else {
                    totalReward = totalReward + reward;
                }
            }
        }

        return totalReward;
    }

    function getReward(address _lp) external onlyLPDepositor {
        Gauges memory _gauges = gauges[_lp];
        address gauge = solidVoter.gauges(_lp);
        ISolidLizardGauge(gauge).getReward(address(this), _gauges.rewardTokens);

        for (uint256 i; i < _gauges.rewardTokens.length; ++i) {
            address rewardToken = _gauges.rewardTokens[i];
            uint256 tokenBal = IERC20(rewardToken).balanceOf(address(this));
            if (tokenBal > 0) {
                if (rewardToken != address(SLIZ)) {
                    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        tokenBal,
                        0,
                        routes[rewardToken],
                        lpDepositor,
                        block.timestamp
                    );
                } else SLIZ.safeTransfer(lpDepositor, tokenBal);
            }
        }
    }

    /**
        @notice Modify core protocol addresses
        @dev This will brick the existing deployment, it is only intended to be used in case
        of an emergency requiring a complete migration of the protocol. As an additional
        safety mechanism, there is a 7 day delay required between setting and applying
        the new addresses.
    */
    function setPendingAddresses(
        address _chamSLIZ,
        address _lpDepositor
    ) external onlyOwner {
        pendingLpDepositor = _lpDepositor;
        pendingChamSLIZ = _chamSLIZ;
        newAddressDeadline = block.timestamp + 86400 * 7;

        emit NewAddressesCommitted(_chamSLIZ, _lpDepositor, newAddressDeadline);
    }

    function applyPendingAddresses() external onlyOwner {
        require(newAddressDeadline != 0 && newAddressDeadline < block.timestamp, "Proxy: PENDING_TIME");
        chamSLIZ = pendingChamSLIZ;
        lpDepositor = pendingLpDepositor;

        emit SetAddresses(chamSLIZ, lpDepositor);
        rejectPendingAddresses();
    }

    function rejectPendingAddresses() public onlyOwner {
        pendingChamSLIZ = address(0);
        pendingLpDepositor = address(0);
        newAddressDeadline = 0;

        emit NewAddressesCommitted(address(0), address(0), 0);
    }
}