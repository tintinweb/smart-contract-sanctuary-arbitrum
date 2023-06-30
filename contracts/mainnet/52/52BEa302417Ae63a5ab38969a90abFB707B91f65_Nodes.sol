// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './Nodes.sol';
import './lib/StringUtils.sol';
import './interfaces/IBeets.sol';

contract Batch {
    address public masterOwner;
    mapping(address => uint8) public owners;
    Nodes public nodes;
    uint8 public constant TOTAL_FEE = 150; //1.50%
    uint256[] public auxStack;
    BatchSwapStep[] private batchSwapStep;

    struct Function {
        string recipeId;
        string id;
        string functionName;
        address user;
        bytes arguments;
        bool hasNext;
    }

    struct BatchSwapStruct {
        bytes32[] poolId;
        uint256[] assetInIndex;
        uint256[] assetOutIndex;
        uint256[] amount;
    }

    struct SplitStruct {
        IAsset[] firstTokens;
        IAsset[] secondTokens;
        uint256 amount;
        uint256[] percentageAndAmountsOutMin;
        uint8[] providers;
        BatchSwapStruct batchSwapStepFirstToken;
        BatchSwapStruct batchSwapStepSecondToken;
        string firstHasNext;
        string secondHasNext;
    }

    event AddFundsForTokens(string indexed recipeId, string indexed id, address tokenInput, uint256 amount);
    event AddFundsForFTM(string indexed recipeId, string indexed id, uint256 amount);
    event Split(string indexed recipeId, string indexed id, address tokenInput, uint256 amountIn, address tokenOutput1, uint256 amountOutToken1, address tokenOutput2, uint256 amountOutToken2);
    event SwapTokens(string indexed recipeId, string indexed id, address tokenInput, uint256 amountIn, address tokenOutput, uint256 amountOut);
    event Liquidate(string indexed recipeId, string indexed id, address tokenInput, uint256 amountIn, address tokenOutput, uint256 amountOut);
    event SendToWallet(string indexed recipeId, string indexed id, address tokenOutput, uint256 amountOut);
    event lpDeposited(string indexed recipeId, string indexed id, address lpToken, uint256 amount);
    event ttDeposited(string indexed recipeId, string indexed id, address ttVault, uint256 lpAmount, uint256 amount);
    event DepositOnNestedStrategy(string indexed recipeId, string indexed id, address vaultAddress, uint256 amount);
    event WithdrawFromNestedStrategy(string indexed recipeId, string indexed id, address vaultAddress, uint256 amountShares, address tokenDesired, uint256 amountDesired);
    event lpWithdrawed(string indexed recipeId, string indexed id, address lpToken, uint256 amountLp, address tokenDesired, uint256 amountTokenDesired);
    event ttWithdrawed(string indexed recipeId, string indexed id, uint256 lpAmount, address ttVault, uint256 amountTt, address tokenDesired, uint256 amountTokenDesired, uint256 rewardAmount);

    constructor(address masterOwner_) {
        masterOwner = masterOwner_;
    }

    modifier onlyMasterOwner() {
        require(msg.sender == masterOwner, 'You must be the owner.');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == masterOwner || owners[msg.sender] == 1, 'You must be the owner.');
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), 'This function is internal.');
        _;
    }

    function setNodeContract(Nodes _nodes) public onlyMasterOwner {
        nodes = _nodes;
    }

    function addOwners(address[] memory owners_) public onlyMasterOwner {
        require(owners_.length > 0, 'The array must have at least one address.');

        for (uint8 i = 0; i < owners_.length; i++) {
            require(owners_[i] != address(0), 'Invalid address.');

            if (owners[owners_[i]] == 0) owners[owners_[i]] = 1;
        }
    }

    function removeOwners(address[] memory owners_) public onlyMasterOwner {
        require(owners_.length > 0, 'The array must have at least one address.');

        for (uint8 i = 0; i < owners_.length; i++) {
            if (owners[owners_[i]] == 1) owners[owners_[i]] = 0;
        }
    }

    function batchFunctions(Function[] memory _functions) public onlyOwner {
        for (uint256 i = 0; i < _functions.length; i++) {
            (bool success, ) = address(this).call(abi.encodeWithSignature(_functions[i].functionName, _functions[i]));
            if (!success) revert();
        }
        if (auxStack.length > 0) deleteAuxStack();
    }

    function deleteAuxStack() private {
        uint256 arrayLength_ = auxStack.length;
        for (uint8 i; i < arrayLength_; i++) {
            auxStack.pop();
        }
    }

    function deleteBatchSwapStep() private {
        uint256 arrayLength_ = batchSwapStep.length;
        for (uint8 i; i < arrayLength_; i++) {
            batchSwapStep.pop();
        }
    }

    function createBatchSwapObject(BatchSwapStruct memory batchSwapStruct_) private returns(BatchSwapStep[] memory newBatchSwapStep) {
        for(uint16 x; x < batchSwapStruct_.poolId.length; x++) {
            BatchSwapStep memory batchSwapStep_;
            batchSwapStep_.poolId = batchSwapStruct_.poolId[x];
            batchSwapStep_.assetInIndex = batchSwapStruct_.assetInIndex[x];
            batchSwapStep_.assetOutIndex = batchSwapStruct_.assetOutIndex[x];
            batchSwapStep_.amount = batchSwapStruct_.amount[x];
            batchSwapStep_.userData = bytes("0x");
            batchSwapStep.push(batchSwapStep_);
        }
        newBatchSwapStep = batchSwapStep;
        deleteBatchSwapStep();
    }

    function addFundsForTokens(Function memory args) public onlySelf {
        (IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint8 provider_,
        BatchSwapStruct memory batchSwapStruct_) = abi.decode(args.arguments, (IAsset[], uint256, uint256, uint8, BatchSwapStruct));

        BatchSwapStep[] memory batchSwapStep_;
        if(provider_ == 1) {
            batchSwapStep_ = createBatchSwapObject(batchSwapStruct_);
        }

        uint256 amount = nodes.addFundsForTokens(args.user, tokens_, amount_, amountOutMin_, provider_, batchSwapStep_);
        
        if (args.hasNext) {
            auxStack.push(amount);
        }

        emit AddFundsForTokens(args.recipeId, args.id, address(tokens_[0]), amount);
    }

    function addFundsForFTM(Function memory args) public onlySelf {
        uint256 amount_ = abi.decode(args.arguments, (uint256));
        uint256 _fee = ((amount_ * TOTAL_FEE) / 10000);
        amount_ -= _fee;
        if (args.hasNext) {
            auxStack.push(amount_);
        }

        emit AddFundsForFTM(args.recipeId, args.id, amount_);
    }

    function swapTokens(Function memory args) public onlySelf {
        (IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        BatchSwapStruct memory batchSwapStruct_,
        uint8 provider_) = abi.decode(args.arguments, (IAsset[], uint256, uint256, BatchSwapStruct, uint8));
        
        if (auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        BatchSwapStep[] memory batchSwapStep_;
        if(provider_ == 1) {
            batchSwapStep_ = createBatchSwapObject(batchSwapStruct_);
        }

        uint256 amountOut = nodes.swapTokens(args.user, provider_, tokens_, amount_, amountOutMin_, batchSwapStep_);
        if (args.hasNext) {
            auxStack.push(amountOut);
        }

        emit SwapTokens(args.recipeId, args.id, address(tokens_[0]), amount_, address(tokens_[tokens_.length - 1]), amountOut);
    }

    function split(Function memory args) public onlySelf {
        (SplitStruct memory splitStruct_) = abi.decode(args.arguments, (SplitStruct));

        if (auxStack.length > 0) {
            splitStruct_.amount = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        BatchSwapStep[] memory batchSwapStepFirstToken_;
        if(splitStruct_.providers[0] == 1) {
            batchSwapStepFirstToken_ = createBatchSwapObject(splitStruct_.batchSwapStepFirstToken);
        }

        BatchSwapStep[] memory batchSwapStepSecondToken_;
        if(splitStruct_.providers[1] == 1) {
            batchSwapStepSecondToken_ = createBatchSwapObject(splitStruct_.batchSwapStepSecondToken);
        }

        bytes memory data = abi.encode(args.user, splitStruct_.firstTokens, splitStruct_.secondTokens, splitStruct_.amount, splitStruct_.percentageAndAmountsOutMin, splitStruct_.providers);
        uint256[] memory amountOutTokens = nodes.split(data, batchSwapStepFirstToken_, batchSwapStepSecondToken_);

        if (StringUtils.equal(splitStruct_.firstHasNext, 'y')) {
            auxStack.push(amountOutTokens[0]);
        }
        if (StringUtils.equal(splitStruct_.secondHasNext, 'y')) {
           auxStack.push(amountOutTokens[1]);
        }

        emit Split(args.recipeId, args.id, address(splitStruct_.firstTokens[0]), splitStruct_.amount, address(splitStruct_.firstTokens[splitStruct_.firstTokens.length - 1]), amountOutTokens[0], address(splitStruct_.secondTokens[splitStruct_.secondTokens.length - 1]), amountOutTokens[1]);
    }

    function depositOnLp(Function memory args) public onlySelf {
        (bytes32 poolId_,
        address lpToken_,
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256 amountOutMin0_,
        uint256 amountOutMin1_,
        uint8 provider_) = abi.decode(args.arguments, (bytes32, address, address[], uint256[], uint256, uint256, uint8));

        if(auxStack.length > 0) {
            if(provider_ == 0) {
                amounts_[0] = auxStack[auxStack.length - 2];
                amounts_[1] = auxStack[auxStack.length - 1];
                auxStack.pop();
                auxStack.pop();
            } else {
                amounts_[0] = auxStack[auxStack.length - 1];
                auxStack.pop();
            }
        }

        uint256 lpRes = nodes.depositOnLp(
            args.user,
            poolId_,
            lpToken_,
            provider_,
            tokens_,
            amounts_,
            amountOutMin0_,
            amountOutMin1_
        );

        if (args.hasNext) {
            auxStack.push(lpRes);
        }

        emit lpDeposited(args.recipeId, args.id, lpToken_, lpRes);
    }

    function withdrawFromLp(Function memory args) public onlySelf {
        (bytes32 poolId_,
        address lpToken_,
        address[] memory tokens_,
        uint256[] memory amountsOutMin_,
        uint256 amount_,
        uint8 provider_) = abi.decode(args.arguments, (bytes32, address, address[], uint256[], uint256, uint8));

        if (auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        uint256 amountTokenDesired = nodes.withdrawFromLp(args.user, poolId_, lpToken_, provider_, tokens_, amountsOutMin_, amount_);
        
        if (args.hasNext) {
            auxStack.push(amountTokenDesired);
        }

        address tokenOut_;
        if(provider_ == 0) {
            tokenOut_ = tokens_[2];
        } else {
            tokenOut_ = tokens_[0];
        }

        emit lpWithdrawed(
            args.recipeId,
            args.id,
            lpToken_,
            amount_,
            tokenOut_,
            amountTokenDesired
        );
    }

    function depositOnNestedStrategy(Function memory args) public onlySelf {
        (address token_,
        address vaultAddress_,
        uint256 amount_,
        uint8 provider_) = abi.decode(args.arguments, (address, address, uint256, uint8));

        if (auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        uint256 sharesAmount_ = nodes.depositOnNestedStrategy(args.user, token_, vaultAddress_, amount_, provider_);

        if (args.hasNext) {
            auxStack.push(sharesAmount_);
        }

        emit DepositOnNestedStrategy(args.recipeId, args.id, vaultAddress_, sharesAmount_);
    }

    function withdrawFromNestedStrategy(Function memory args) public onlySelf {
        (address tokenOut_,
        address vaultAddress_,
        uint256 amount_,
        uint8 provider_) = abi.decode(args.arguments, (address, address, uint256, uint8));

        if (auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        uint256 amountTokenDesired_ = nodes.withdrawFromNestedStrategy(args.user, tokenOut_, vaultAddress_, amount_, provider_);

        if (args.hasNext) {
            auxStack.push(amountTokenDesired_);
        }

        emit WithdrawFromNestedStrategy(args.recipeId, args.id, vaultAddress_, amount_, tokenOut_, amountTokenDesired_);
    }

    function depositOnFarm(Function memory args) public onlySelf {
        (address lpToken_,
        address tortleVault_,
        address[] memory tokens_,
        uint256 amount0_,
        uint256 amount1_,
        uint8 provider_) = abi.decode(args.arguments, (address, address, address[], uint256, uint256, uint8));

        uint256[] memory result_ = nodes.depositOnFarmTokens(args.user, lpToken_, tortleVault_, tokens_, amount0_, amount1_, auxStack, provider_);
        while (result_[0] != 0) {
            auxStack.pop();
            result_[0]--;
        }

        emit ttDeposited(args.recipeId, args.id, tortleVault_, result_[2], result_[1]); // ttVault address and ttAmount
        if (args.hasNext) {
            auxStack.push(result_[1]);
        }
    }

    function withdrawFromFarm(Function memory args) public onlySelf {
        (address lpToken_,
        address tortleVault_,
        address[] memory tokens_,
        uint256 amountOutMin_,
        uint256 amount_,
        uint8 provider_) = abi.decode(args.arguments, (address, address, address[], uint256, uint256, uint8));

        if (auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        (uint256 amountLp, uint256 rewardAmount, uint256 amountTokenDesired) = nodes.withdrawFromFarm(args.user, lpToken_, tortleVault_, tokens_, amountOutMin_, amount_, provider_);
        
        if (args.hasNext) {
            auxStack.push(amountTokenDesired);
        }

        emit ttWithdrawed(
            args.recipeId,
            args.id,
            amountLp,
            tortleVault_,
            amount_,
            tokens_[2],
            amountTokenDesired,
            rewardAmount
        );
    }

    function sendToWallet(Function memory args) public onlySelf {
        (IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint256 addFundsAmountWPercentage_,
        uint8 provider_,
        BatchSwapStruct memory batchSwapStruct_) = abi.decode(args.arguments, (IAsset[], uint256, uint256, uint256, uint8, BatchSwapStruct));

        if (auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }

        BatchSwapStep[] memory batchSwapStep_;
        if(provider_ == 1) {
            batchSwapStep_ = createBatchSwapObject(batchSwapStruct_);
        }

        uint256 amount = nodes.sendToWallet(args.user, tokens_, amount_, amountOutMin_, addFundsAmountWPercentage_, provider_, batchSwapStep_);

        emit SendToWallet(args.recipeId, args.id, address(tokens_[0]), amount);
    }

    function liquidate(Function memory args) public onlySelf {
        (IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint256 liquidateAmountWPercentage_,
        uint8 provider_,
        BatchSwapStruct memory batchSwapStruct_) = abi.decode(args.arguments, (IAsset[], uint256, uint256, uint256, uint8, BatchSwapStruct));

        if(auxStack.length > 0) {
            amount_ = auxStack[auxStack.length - 1];
            auxStack.pop();
        }
        
        BatchSwapStep[] memory batchSwapStep_;
        if(provider_ == 1) {
            batchSwapStep_ = createBatchSwapObject(batchSwapStruct_);
        }

        uint256 amountOut = nodes.liquidate(args.user, tokens_, amount_, amountOutMin_, liquidateAmountWPercentage_, provider_, batchSwapStep_);

        emit Liquidate(args.recipeId, args.id, address(tokens_[0]), amount_, address(tokens_[tokens_.length - 1]), amountOut);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IAsset.sol";

enum SwapKind { GIVEN_IN, GIVEN_OUT }

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

struct JoinPoolRequest {
    IAsset[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
}

struct ExitPoolRequest {
    IAsset[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
}

interface IBeets {
    function swapTokens(IAsset[] memory tokens_, BatchSwapStep[] memory batchSwapStep_) external returns(uint256 amountOut);
    function queryBatchSwap(SwapKind kind, BatchSwapStep[] memory swaps, IAsset[] memory assets, FundManagement memory funds) external returns (int256[] memory assetDeltas);
    function batchSwap(SwapKind kind, BatchSwapStep[] memory swaps, IAsset[] memory assets, FundManagement memory funds, int256[] memory limits, uint256 deadline) external payable returns (int256[] memory assetDeltas);
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;
    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IDepositsBeets {

    function getBptAddress(bytes32 poolId_) external view returns(address bptAddress);
    function joinPool(bytes32 poolId_, address[] memory tokens_, uint256[] memory amountsIn_) external returns(address bptAddress, uint256 bptAmount_);
    function exitPool(bytes32 poolId_, address bptToken_, address[] memory tokens_, uint256[] memory minAmountsOut_, uint256 bptAmount_) external returns(uint256 amountTokenDesired);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IFarmsUni {

    function addLiquidity(
        IUniswapV2Router02 router_,
        address token0_,
        address token1_,
        uint256 amount0_,
        uint256 amount1_,
        uint256 amountOutMin0_,
        uint256 amountOutMin1_
    ) external returns (uint256 amount0f, uint256 amount1f, uint256 lpRes);

    function withdrawLpAndSwap(
        address swapsUni_,
        address lpToken_,
        address[] memory tokens_,
        uint256 amountOutMin_,
        uint256 amountLp_
    ) external returns (uint256 amountTokenDesired);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IFirstTypeNestedStrategies {
    function deposit(address user_, address token_, address vaultAddress_, uint256 amount_, address nodesContract_) external returns (uint256 sharesAmount);
    function withdraw(address user_, address tokenOut_, address vaultAddress_, uint256 sharesAmount_, address nodesContract_) external returns (uint256 amountTokenDesired);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ISwapsUni {
    function swapTokens(address _tokenIn, uint256 _amount, address _tokenOut, uint256 _amountOutMin) external returns (uint256);
    function getRouter(address _token0, address _token1) external view returns(IUniswapV2Router02);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITortleVault is IERC20 {
    function getPricePerFullShare() external view returns (uint256);

    function deposit(address user, uint256 amount) external returns (uint256);

    function withdraw(address user, uint256 shares) external returns (uint256, uint256);

    function token() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

library AddressToUintIterableMap {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';

abstract contract ReentrancyGuard is Initializable {
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

    function initialize() public initializer {
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

pragma solidity ^0.8.13;

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b)
        private
        pure
        returns (int256)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint256 minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint256 i = 0; i < minLength; i++)
            if (a[i] < b[i]) return -1;
            else if (a[i] > b[i]) return 1;
        if (a.length < b.length) return -1;
        else if (a.length > b.length) return 1;
        else return 0;
    }

    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b)
        public
        pure
        returns (bool)
    {
        return compare(_a, _b) == 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/Babylonian.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import './lib/AddressToUintIterableMap.sol';
import './interfaces/ITortleVault.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IWETH.sol';
import './SwapsUni.sol';
import './selectRoute/SelectSwapRoute.sol';
import './selectRoute/SelectLPRoute.sol';
import './selectRoute/SelectNestedRoute.sol';
import './Batch.sol';

error Nodes__InsufficientBalance();
error Nodes__EmptyArray();
error Nodes__InvalidArrayLength();
error Nodes__TransferFailed();
error Nodes__DepositOnLPInvalidLPToken();
error Nodes__DepositOnLPInsufficientT0Funds();
error Nodes__DepositOnLPInsufficientT1Funds();
error Nodes__DepositOnNestedStrategyInsufficientFunds();
error Nodes__WithdrawFromNestedStrategyInsufficientShares();
error Nodes__DepositOnFarmTokensInsufficientT0Funds();
error Nodes__DepositOnFarmTokensInsufficientT1Funds();
error Nodes__WithdrawFromLPInsufficientFunds();
error Nodes__WithdrawFromFarmInsufficientFunds();

contract Nodes is Initializable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using AddressToUintIterableMap for AddressToUintIterableMap.Map;

    address public owner;
    address public tortleDojos;
    address public tortleTreasury;
    address public tortleDevFund;
    SwapsUni public swapsUni;
    SelectSwapRoute public selectSwapRoute;
    SelectLPRoute public selectLPRoute;
    SelectNestedRoute public selectNestedRoute;
    Batch private batch;
    address private WFTM;
    address public usdc;

    uint8 public constant INITIAL_TOTAL_FEE = 50; // 0.50%
    uint16 public constant PERFORMANCE_TOTAL_FEE = 500; // 5%
    uint16 public constant DOJOS_FEE = 3333; // 33.33%
    uint16 public constant TREASURY_FEE = 4666; // 46.66%
    uint16 public constant DEV_FUND_FEE = 2000; // 20%

    mapping(address => AddressToUintIterableMap.Map) private balance;

    event AddFunds(address tokenInput, uint256 amount);
    event AddFundsForFTM(string indexed recipeId, address tokenInput, uint256 amount);
    event Swap(address tokenInput, uint256 amountIn, address tokenOutput, uint256 amountOut);
    event Split(address tokenOutput1, uint256 amountOutToken1, address tokenOutput2, uint256 amountOutToken2);
    event DepositOnLP(uint256 lpAmount);
    event WithdrawFromLP(uint256 amountTokenDesired);
    event DepositOnNestedStrategy(address vaultAddress, uint256 sharesAmount);
    event WithdrawFromNestedStrategy(address tokenOut, uint256 amountTokenDesired);
    event DepositOnFarm(uint256 ttAmount, uint256 lpBalance);
    event WithdrawFromFarm(address tokenDesided, uint256 amountTokenDesired, uint256 rewardAmount);
    event Liquidate(address tokenOutput, uint256 amountOut);
    event SendToWallet(address tokenOutput, uint256 amountOut);
    event RecoverAll(address tokenOut, uint256 amountOut);

    modifier onlyOwner() {
        require(msg.sender == owner || msg.sender == address(batch) || msg.sender == address(this), 'You must be the owner.');
        _;
    }

    function initializeConstructor(
        address owner_,
        SwapsUni swapsUni_,
        SelectSwapRoute selectSwapRoute_,
        SelectLPRoute selectLPRoute_,
        SelectNestedRoute selectNestedRoute_,
        Batch batch_,
        address tortleDojos_,
        address tortleTrasury_,
        address tortleDevFund_,
        address wftm_,
        address usdc_
    ) public initializer {
        owner = owner_;
        swapsUni = swapsUni_;
        selectSwapRoute = selectSwapRoute_;
        selectLPRoute = selectLPRoute_;
        selectNestedRoute = selectNestedRoute_;
        batch = batch_;
        tortleDojos = tortleDojos_;
        tortleTreasury = tortleTrasury_;
        tortleDevFund = tortleDevFund_;
        WFTM = wftm_;
        usdc = usdc_;
    }

    function setBatch(Batch batch_) public onlyOwner {
        batch = batch_;
    }

    function setSwapsUni(SwapsUni swapsUni_) public onlyOwner {
        swapsUni = swapsUni_;
    }

    function setSelectSwapRoute(SelectSwapRoute selectSwapRoute_) public onlyOwner {
        selectSwapRoute = selectSwapRoute_;
    }

    function setSelectLPRoute(SelectLPRoute selectLPRoute_) public onlyOwner {
        selectLPRoute = selectLPRoute_;
    }

    function setSelectNestedRoute(SelectNestedRoute selectNestedRoute_) public onlyOwner {
        selectNestedRoute = selectNestedRoute_;
    }

    function setTortleDojos(address tortleDojos_) public onlyOwner {
        tortleDojos = tortleDojos_;
    }

    function setTortleTreasury(address tortleTreasury_) public onlyOwner {
        tortleTreasury = tortleTreasury_;
    }

    function setTortleDevFund(address tortleDevFund_) public onlyOwner {
        tortleDevFund = tortleDevFund_;
    }

    /**
    * @notice Function used to charge the correspoding fees (returns the amount - fees).
    * @param tokens_ Addresses of the tokens used as fees.
    * @param amount_ Amount of the token that is wanted to calculate its fees.
    * @param feeAmount_ Percentage of fees to be charged.
    */
    function _chargeFees(
        address user_,
        IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint256 feeAmount_,
        uint8 provider_,
        BatchSwapStep[] memory batchSwapStep_
    ) private returns (uint256) {
        uint256 amountFee_ = mulScale(amount_, feeAmount_, 10000);
        uint256 dojosTokens_;
        uint256 treasuryTokens_;
        uint256 devFundTokens_;

        if (address(tokens_[0]) == usdc) {
            dojosTokens_ = mulScale(amountFee_, DOJOS_FEE, 10000);
            treasuryTokens_ = mulScale(amountFee_, TREASURY_FEE, 10000);
            devFundTokens_ = mulScale(amountFee_, DEV_FUND_FEE, 10000);
        } else {
            increaseBalance(user_, address(tokens_[0]), amountFee_);
            uint256 amountSwap_ = swapTokens(user_, provider_, tokens_, amountFee_, amountOutMin_, batchSwapStep_);
            decreaseBalance(user_, address(tokens_[tokens_.length - 1]), amountSwap_);
            dojosTokens_ = amountSwap_ / 3;
            treasuryTokens_ = mulScale(amountSwap_, 2000, 10000);
            devFundTokens_= amountSwap_ - (dojosTokens_ + treasuryTokens_);
        }

        IERC20(usdc).safeTransfer(tortleDojos, dojosTokens_);
        IERC20(usdc).safeTransfer(tortleTreasury, treasuryTokens_);
        IERC20(usdc).safeTransfer(tortleDevFund, devFundTokens_);

        return amount_ - amountFee_;
    }

    function _chargeFeesForWFTM(uint256 amount_) private returns (uint256) {
        uint256 amountFee_ = mulScale(amount_, INITIAL_TOTAL_FEE, 10000);

        _approve(WFTM, address(swapsUni), amountFee_);
        uint256 _amountSwap = swapsUni.swapTokens(WFTM, amountFee_, usdc, 0);

        uint256 dojosTokens_ = _amountSwap / 3;
        uint256 treasuryTokens_ = mulScale(_amountSwap, 2000, 10000);
        uint256 devFundTokens_= _amountSwap - (dojosTokens_ + treasuryTokens_);

        IERC20(usdc).safeTransfer(tortleDojos, dojosTokens_);
        IERC20(usdc).safeTransfer(tortleTreasury, treasuryTokens_);
        IERC20(usdc).safeTransfer(tortleDevFund, devFundTokens_);

        return amount_ - amountFee_;
    }

    /**
     * @notice Function that allows to add funds to the contract to execute the recipes.
     * @param user_ Address of the user who will deposit the tokens.
     * @param tokens_ Addresses of the tokens to be deposited.
     * @param amount_ Amount of tokens to be deposited.
     */
    function addFundsForTokens(
        address user_,
        IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint8 provider_,
        BatchSwapStep[] memory batchSwapStep_
    ) public nonReentrant returns (uint256 amount) {
        if (amount_ <= 0) revert Nodes__InsufficientBalance();

        address tokenIn_ = address(tokens_[0]);

        uint256 balanceBefore = IERC20(tokenIn_).balanceOf(address(this));
        IERC20(tokenIn_).safeTransferFrom(user_, address(this), amount_);
        uint256 balanceAfter = IERC20(tokenIn_).balanceOf(address(this));
        if (balanceAfter <= balanceBefore) revert Nodes__TransferFailed();

        amount = _chargeFees(user_, tokens_, balanceAfter - balanceBefore, amountOutMin_, INITIAL_TOTAL_FEE, provider_, batchSwapStep_);
        increaseBalance(user_, tokenIn_, amount);

        emit AddFunds(tokenIn_, amount);
    }

    /**
    * @notice Function that allows to add funds to the contract to execute the recipes.
    * @param user_ Address of the user who will deposit the tokens.
    */
    function addFundsForFTM(address user_, string memory recipeId_) public payable nonReentrant returns (address token, uint256 amount) {
        if (msg.value <= 0) revert Nodes__InsufficientBalance();

        IWETH(WFTM).deposit{value: msg.value}();

        uint256 amount_ = _chargeFeesForWFTM(msg.value);
        increaseBalance(user_, WFTM, amount_);

        emit AddFundsForFTM(recipeId_, WFTM, amount_);
        return (WFTM, amount_);
    }

    /**
     * @notice Function that allows to send X amount of tokens and returns the token you want.
     * @param user_ Address of the user running the node.
     * @param provider_ Provider used for swapping tokens.
     * @param tokens_ Array of tokens to be swapped.
     * @param amount_ Amount of Tokens to be swapped.
     * @param amountOutMin_ Minimum amounts you want to use.
     * @param batchSwapStep_ Array of structs required by beets provider.
     */
    function swapTokens(
        address user_,
        uint8 provider_,
        IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        BatchSwapStep[] memory batchSwapStep_
    ) public onlyOwner returns (uint256 amountOut) {
        address tokenIn_ = address(tokens_[0]);
        address tokenOut_ = address(tokens_[tokens_.length - 1]);

        uint256 _userBalance = getBalance(user_, IERC20(tokenIn_));
        if (amount_ > _userBalance) revert Nodes__InsufficientBalance();

        if (tokenIn_ != tokenOut_) {
            _approve(tokenIn_, address(selectSwapRoute), amount_);
            amountOut = selectSwapRoute.swapTokens(tokens_, amount_, amountOutMin_, batchSwapStep_, provider_);

            decreaseBalance(user_, tokenIn_, amount_);
            increaseBalance(user_, tokenOut_, amountOut);
        } else amountOut = amount_;

        emit Swap(tokenIn_, amount_, tokenOut_, amountOut);
    }

    /**
    * @notice Function that divides the token you send into two tokens according to the percentage you select.
    * @param args_ user, firstTokens, secondTokens, amount, percentageFirstToken, amountOutMinFirst_, amountOutMinSecond_, providers, batchSwapStepFirstToken, batchSwapStepSecondToken.
    */
    function split(
        bytes calldata args_,
        BatchSwapStep[] memory batchSwapStepFirstToken_,
        BatchSwapStep[] memory batchSwapStepSecondToken_
    ) public onlyOwner returns (uint256[] memory amountOutTokens) {
        (address user_, 
        IAsset[] memory firstTokens_, 
        IAsset[] memory secondTokens_, 
        uint256 amount_,
        uint256[] memory percentageAndAmountsOutMin_,
        uint8[] memory providers_
        ) = abi.decode(args_, (address, IAsset[], IAsset[], uint256, uint256[], uint8[]));

        if (amount_ > getBalance(user_, IERC20(address(firstTokens_[0])))) revert Nodes__InsufficientBalance();

        uint256 firstTokenAmount_ = mulScale(amount_, percentageAndAmountsOutMin_[0], 10000);
        
        amountOutTokens = new uint256[](2);
        amountOutTokens[0] = swapTokens(user_, providers_[0], firstTokens_, firstTokenAmount_, percentageAndAmountsOutMin_[1], batchSwapStepFirstToken_);
        amountOutTokens[1] = swapTokens(user_, providers_[1], secondTokens_, (amount_ - firstTokenAmount_), percentageAndAmountsOutMin_[2], batchSwapStepSecondToken_);

        emit Split(address(firstTokens_[firstTokens_.length - 1]), amountOutTokens[0], address(secondTokens_[secondTokens_.length - 1]), amountOutTokens[1]);
    }

    /**
    * @notice Function used to deposit tokens on a lpPool and get lptoken
    * @param user_ Address of the user.
    * @param poolId_ Beets pool id.
    * @param lpToken_ Address of the lpToken.
    * @param tokens_ Addresses of tokens that are going to be deposited.
    * @param amounts_ Amounts of tokens.
    * @param amountOutMin0_ Minimum amount of token0.
    * @param amountOutMin0_ Minimum amount of token1.
    */
    function depositOnLp(
        address user_,
        bytes32 poolId_,
        address lpToken_,
        uint8 provider_,
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256 amountOutMin0_,
        uint256 amountOutMin1_
    ) external nonReentrant onlyOwner returns (uint256 lpAmount) {

        for (uint8 i = 0; i < tokens_.length; i++) {
            if (amounts_[i] > getBalance(user_, IERC20(tokens_[i]))) revert Nodes__DepositOnLPInsufficientT0Funds();
            _approve(tokens_[i], address(selectLPRoute), amounts_[i]);
        }

        (uint256[] memory amountsOut, uint256 amountIn, address lpToken, uint256 numTokensOut) = selectLPRoute.depositOnLP(poolId_, lpToken_, provider_, tokens_, amounts_, amountOutMin0_, amountOutMin1_);

        for (uint8 i = 0; i < numTokensOut; i++) {
            decreaseBalance(user_, tokens_[i], amountsOut[i]);
            increaseBalance(user_, lpToken, amountIn);
        }
        lpAmount = amountIn;
        emit DepositOnLP(lpAmount);
    }

    /**
    * @notice Function used to withdraw tokens from a LPfarm
    * @param user_ Address of the user.
    * @param poolId_ Beets pool id.
    * @param lpToken_ Address of the lpToken.
    * @param tokens_ Addresses of tokens that are going to be deposited.
    * @param amountsOutMin_ Minimum amounts to be withdrawed.
    * @param amount_ Amount of LPTokens desired to withdraw.
    */
    function withdrawFromLp(
        address user_,
        bytes32 poolId_,
        address lpToken_,
        uint8 provider_,
        address[] memory tokens_,
        uint256[] memory amountsOutMin_,
        uint256 amount_
    ) external nonReentrant onlyOwner returns (uint256 amountTokenDesired) {

        if (amount_ > getBalance(user_, IERC20(lpToken_))) revert Nodes__WithdrawFromLPInsufficientFunds(); // check what to do with bp token
        _approve(lpToken_, address(selectLPRoute), amount_);

        address tokenDesired;
        (tokenDesired, amountTokenDesired) = selectLPRoute.withdrawFromLp(poolId_, lpToken_, provider_, tokens_, amountsOutMin_, amount_);

        decreaseBalance(user_, lpToken_, amount_);
        increaseBalance(user_, tokenDesired, amountTokenDesired);

        emit WithdrawFromLP(amountTokenDesired);
    }

    /**
    * @notice Function used to withdraw tokens from a LPfarm
    * @param user_ Address of the user.
    * @param token_ Input token to deposit on the vault
    * @param vaultAddress_ Address of the vault.
    * @param amount_ Amount of LPTokens desired to withdraw.
    * @param provider_ Type of Nested strategies.
    */
    function depositOnNestedStrategy(
        address user_,
        address token_, 
        address vaultAddress_, 
        uint256 amount_,
        uint8 provider_
    ) external nonReentrant onlyOwner returns (uint256 sharesAmount) {
        if (amount_ > getBalance(user_, IERC20(token_))) revert Nodes__DepositOnNestedStrategyInsufficientFunds();

        _approve(token_, address(selectNestedRoute), amount_);
        sharesAmount = selectNestedRoute.deposit(user_, token_, vaultAddress_, amount_, provider_);

        decreaseBalance(user_, token_, amount_);
        increaseBalance(user_, vaultAddress_, sharesAmount);

        emit DepositOnNestedStrategy(vaultAddress_, sharesAmount);
    }

    /**
    * @notice Function used to withdraw tokens from a LPfarm
    * @param user_ Address of the user.
    * @param tokenOut_ Output token to withdraw from the vault
    * @param vaultAddress_ Address of the vault.
    * @param sharesAmount_ Amount of Vault share tokens desired to withdraw.
    * @param provider_ Type of Nested strategies.
    */
    function withdrawFromNestedStrategy(
        address user_,
        address tokenOut_, 
        address vaultAddress_, 
        uint256 sharesAmount_,
        uint8 provider_
    ) external nonReentrant onlyOwner returns (uint256 amountTokenDesired) {
        if (sharesAmount_ > getBalance(user_, IERC20(vaultAddress_))) revert Nodes__WithdrawFromNestedStrategyInsufficientShares();

        _approve(vaultAddress_, address(selectNestedRoute), sharesAmount_);
        amountTokenDesired = selectNestedRoute.withdraw(user_, tokenOut_, vaultAddress_, sharesAmount_, provider_);

        decreaseBalance(user_, vaultAddress_, sharesAmount_);
        increaseBalance(user_, tokenOut_, amountTokenDesired);

        emit WithdrawFromNestedStrategy(tokenOut_, amountTokenDesired);
    }

    /**
    * @notice Function used to deposit tokens on a farm
    * @param user Address of the user.
    * @param lpToken_ Address of the LP Token.
    * @param tortleVault_ Address of the tortle vault where we are going to deposit.
    * @param tokens_ Addresses of tokens that are going to be deposited.
    * @param amount0_ Amount of token 0.
    * @param amount1_ Amount of token 1.
    * @param auxStack Contains information of the amounts that are going to be deposited.
    */
    function depositOnFarmTokens(
        address user,
        address lpToken_,
        address tortleVault_,
        address[] memory tokens_,
        uint256 amount0_,
        uint256 amount1_,
        uint256[] memory auxStack,
        uint8 provider_
    ) external nonReentrant onlyOwner returns (uint256[] memory result) {
        result = new uint256[](3);
        if (auxStack.length > 0) {
            amount0_ = auxStack[auxStack.length - 2];
            amount1_ = auxStack[auxStack.length - 1];
            result[0] = 2;
        }

        if (amount0_ > getBalance(user, IERC20(tokens_[0]))) revert Nodes__DepositOnFarmTokensInsufficientT0Funds();
        if (amount1_ > getBalance(user, IERC20(tokens_[1]))) revert Nodes__DepositOnFarmTokensInsufficientT1Funds();

        _approve(tokens_[0], address(selectLPRoute), amount0_);
        _approve(tokens_[1], address(selectLPRoute), amount1_);
        (uint256 amount0f_, uint256 amount1f_, uint256 lpBal_) = selectLPRoute.depositOnFarmTokens(lpToken_, tokens_, amount0_, amount1_, provider_);

        _approve(lpToken_, tortleVault_, lpBal_);
        uint256 ttAmount = ITortleVault(tortleVault_).deposit(user, lpBal_);

        decreaseBalance(user, tokens_[0], amount0f_);
        decreaseBalance(user, tokens_[1], amount1f_);
        increaseBalance(user, tortleVault_, ttAmount);

        result[1] = ttAmount;
        result[2] = lpBal_;

        emit DepositOnFarm(ttAmount, lpBal_);
    }

    /**
    * @notice Function used to withdraw tokens from a farm
    * @param user Address of the user.
    * @param lpToken_ Address of the LP Token.
    * @param tortleVault_ Address of the tortle vault where we are going to deposit.
    * @param tokens_ Addresses of tokens that are going to be deposited.
    * @param amountOutMin_ Minimum amount to be withdrawed.
    * @param amount_ Amount of tokens desired to withdraw.
    */
    function withdrawFromFarm(
        address user,
        address lpToken_,
        address tortleVault_,
        address[] memory tokens_,
        uint256 amountOutMin_,
        uint256 amount_, 
        uint8 provider_
    ) external nonReentrant onlyOwner returns (uint256 amountLp, uint256 rewardAmount, uint256 amountTokenDesired) {
        if (amount_ > getBalance(user, IERC20(tortleVault_))) revert Nodes__WithdrawFromFarmInsufficientFunds();

        (uint256 rewardAmount_, uint256 amountLp_) = ITortleVault(tortleVault_).withdraw(user, amount_);
        rewardAmount = rewardAmount_;
        amountLp = amountLp_;
        decreaseBalance(user, tortleVault_, amount_);

        _approve(lpToken_, address(selectLPRoute), amountLp_);
        amountTokenDesired = selectLPRoute.withdrawFromFarm(lpToken_, tokens_, amountOutMin_, amountLp_, provider_);

        increaseBalance(user, tokens_[2], amountTokenDesired);

        emit WithdrawFromFarm(tokens_[2], amountTokenDesired, rewardAmount);
    }

    /**
    * @notice Function that allows to liquidate all tokens in your account by swapping them to a specific token.
    * @param user_ Address of the user whose tokens are to be liquidated.
    * @param tokens_ Array of tokens input.
    * @param amount_ Array of amounts.
    * @param amountOutMin_ Minimum amount you wish to receive.
    * @param liquidateAmountWPercentage_ AddFunds amount with percentage.
    */
    function liquidate(
        address user_,
        IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint256 liquidateAmountWPercentage_,
        uint8 provider_,
        BatchSwapStep[] memory batchSwapStep_
    ) public onlyOwner returns (uint256 amountOut) {
        address tokenIn_ = address(tokens_[0]);
        address tokenOut_ = address(tokens_[tokens_.length - 1]);

        uint256 userBalance_ = getBalance(user_, IERC20(tokenIn_));
        if (userBalance_ < amount_) revert Nodes__InsufficientBalance();

        int256 profitAmount_ = int256(amount_) - int256(liquidateAmountWPercentage_);

        if (profitAmount_ > 0) {
            uint256 amountWithoutFees_ = _chargeFees(user_, tokens_, uint256(profitAmount_), amountOutMin_, PERFORMANCE_TOTAL_FEE, provider_, batchSwapStep_);
            uint256 amountFees_ = uint256(profitAmount_) - amountWithoutFees_;
            decreaseBalance(user_, tokenIn_, amountFees_);
            amount_ = (amount_ - uint256(profitAmount_)) + amountWithoutFees_;
        }

        amountOut = swapTokens(user_, provider_, tokens_, amount_, amountOutMin_, batchSwapStep_);

        decreaseBalance(user_, tokenOut_, amountOut);

        if(tokenOut_ == WFTM) {
            IWETH(WFTM).withdraw(amountOut);
            payable(user_).transfer(amountOut);
        } else {
            IERC20(tokenOut_).safeTransfer(user_, amountOut); 
        }

        emit Liquidate(tokenOut_, amountOut);
    }

    /**
    * @notice Function that allows to withdraw tokens to the user's wallet.
    * @param user_ Address of the user who wishes to remove the tokens.
    * @param tokens_ Token to be withdrawn.
    * @param amount_ Amount of tokens to be withdrawn.
    * @param addFundsAmountWPercentage_ AddFunds amount with percentage.
    */
    function sendToWallet(
        address user_,
        IAsset[] memory tokens_,
        uint256 amount_,
        uint256 amountOutMin_,
        uint256 addFundsAmountWPercentage_,
        uint8 provider_,
        BatchSwapStep[] memory batchSwapStep_
    ) public nonReentrant onlyOwner returns (uint256) {
        address tokenOut_ = address(tokens_[0]);
        uint256 _userBalance = getBalance(user_, IERC20(tokenOut_));
        if (_userBalance < amount_) revert Nodes__InsufficientBalance();

        decreaseBalance(user_, tokenOut_, amount_);

        int256 profitAmount_ = int256(amount_) - int256(addFundsAmountWPercentage_);

        if (profitAmount_ > 0) amount_ = (amount_ - uint256(profitAmount_)) + _chargeFees(user_, tokens_, uint256(profitAmount_), amountOutMin_, PERFORMANCE_TOTAL_FEE, provider_, batchSwapStep_);

        if (tokenOut_ == WFTM) {
            IWETH(WFTM).withdraw(amount_);
            payable(user_).transfer(amount_);
        } else IERC20(tokenOut_).safeTransfer(user_, amount_);

        emit SendToWallet(tokenOut_, amount_);
        return amount_;
    }

    /**
     * @notice Emergency function that allows to recover all tokens in the state they are in.
     * @param _tokens Array of the tokens to be withdrawn.
     * @param _amounts Array of the amounts to be withdrawn.
     */
    function recoverAll(IERC20[] memory _tokens, uint256[] memory _amounts) public nonReentrant {
        if (_tokens.length <= 0) revert Nodes__EmptyArray();
        if (_tokens.length != _amounts.length) revert Nodes__InvalidArrayLength();

        for (uint256 _i = 0; _i < _tokens.length; _i++) {
            IERC20 _tokenAddress = _tokens[_i];

            uint256 _userBalance = getBalance(msg.sender, _tokenAddress);
            if (_userBalance < _amounts[_i]) revert Nodes__InsufficientBalance();

            if(address(_tokenAddress) == WFTM) {
                IWETH(WFTM).withdraw(_amounts[_i]);
                payable(msg.sender).transfer(_amounts[_i]);
            } else _tokenAddress.safeTransfer(msg.sender, _amounts[_i]);
            
            decreaseBalance(msg.sender, address(_tokenAddress), _amounts[_i]);

            emit RecoverAll(address(_tokenAddress), _amounts[_i]);
        }
    }

    /**
     * @notice Approve of a token
     * @param token Address of the token wanted to be approved
     * @param spender Address that is wanted to be approved to spend the token
     * @param amount Amount of the token that is wanted to be approved.
     */
    function _approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    /**
     * @notice Calculate the percentage of a number.
     * @param x Number.
     * @param y Percentage of number.
     * @param scale Division.
     */
    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }

    /**
    * @notice Function that allows you to see the balance you have in the contract of a specific token.
    * @param _user Address of the user who will deposit the tokens.
    * @param _token Contract of the token from which the balance is to be obtained.
    */
    function getBalance(address _user, IERC20 _token) public view returns (uint256) {
        return balance[_user].get(address(_token));
    }

    /**
     * @notice Increase balance of a token for a user
     * @param _user Address of the user that is wanted to increase its balance of a token
     * @param _token Address of the token that is wanted to be increased
     * @param _amount Amount of the token that is wanted to be increased
     */
    function increaseBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        uint256 _userBalance = getBalance(_user, IERC20(_token));
        _userBalance += _amount;
        balance[_user].set(address(_token), _userBalance);
    }

    /**
     * @notice Decrease balance of a token for a user
     * @param _user Address of the user that is wanted to decrease its balance of a token
     * @param _token Address of the token that is wanted to be decreased
     * @param _amount Amount of the token that is wanted to be decreased
     */
    function decreaseBalance(
        address _user,
        address _token,
        uint256 _amount
    ) private {
        uint256 _userBalance = getBalance(_user, IERC20(_token));
        if (_userBalance < _amount) revert Nodes__InsufficientBalance();

        _userBalance -= _amount;
        balance[_user].set(address(_token), _userBalance);
    }

    
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../lib/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "../interfaces/ISwapsUni.sol";
import "../interfaces/IFarmsUni.sol";
import "../interfaces/IDepositsBeets.sol";

error SelectLPRoute__DepositOnLPInvalidLPToken();
contract SelectLPRoute is Ownable {
    using SafeERC20 for IERC20;

    address immutable swapsUni;
    address immutable farmsUni;
    address immutable depositsBeets;
    address private nodes;

    modifier onlyAllowed() {
        require(msg.sender == owner() || msg.sender == nodes, 'You must be the owner.');
        _;
    }

    constructor(address farmsUni_, address swapsUni_, address depositsBeets_ ) {
        farmsUni = farmsUni_;
        swapsUni = swapsUni_;
        depositsBeets = depositsBeets_;
    }

    function setNodes(address nodes_) public onlyAllowed {
        nodes = nodes_;
    }

    function depositOnLP(
        bytes32 poolId_,
        address lpToken_,
        uint8 provider_,
        address[] memory tokens_,
        uint256[] memory amounts_,
        uint256 amountOutMin0_,
        uint256 amountOutMin1_) public onlyAllowed returns (uint256[] memory amountsOut, uint256 amountIn, address lpToken, uint256 numTokensOut){
        if (provider_ == 0) { // spookySwap
            IERC20(tokens_[0]).safeTransferFrom(msg.sender, address(this), amounts_[0]);
            IERC20(tokens_[1]).safeTransferFrom(msg.sender, address(this), amounts_[1]);
            _approve(tokens_[0], address(farmsUni), amounts_[0]);
            _approve(tokens_[1], address(farmsUni), amounts_[1]);

            IUniswapV2Router02 router = ISwapsUni(swapsUni).getRouter(tokens_[0], tokens_[1]);
            if (lpToken_ != IUniswapV2Factory(IUniswapV2Router02(router).factory()).getPair(tokens_[0], tokens_[1])) revert  SelectLPRoute__DepositOnLPInvalidLPToken();
            amountsOut = new uint256[](2);
            (amountsOut[0], amountsOut[1], amountIn) = IFarmsUni(farmsUni).addLiquidity(router, tokens_[0], tokens_[1], amounts_[0], amounts_[1], amountOutMin0_, amountOutMin1_);
            lpToken = lpToken_;
            numTokensOut = 2;
        } else { // beets
            IERC20(tokens_[0]).safeTransferFrom(msg.sender, address(this), amounts_[0]);
            _approve(tokens_[0], address(depositsBeets), amounts_[0]);
            (lpToken, amountIn) = IDepositsBeets(depositsBeets).joinPool(poolId_, tokens_, amounts_);
            amountsOut = new uint256[](1);
            amountsOut[0] = amounts_[0];
            numTokensOut = 1;
        }
        IERC20(lpToken).safeTransfer(msg.sender, amountIn);
        }
    function withdrawFromLp(
        bytes32 poolId_,
        address lpToken_,
        uint8 provider_,
        address[] memory tokens_,
        uint256[] memory amountsOutMin_,
        uint256 amount_
    ) public onlyAllowed returns(address tokenDesired, uint256 amountTokenDesired) {
        IERC20(lpToken_).safeTransferFrom(msg.sender, address(this), amount_);
        if (provider_ == 0) { // spookySwap
            _approve(lpToken_, address(farmsUni), amount_);
            amountTokenDesired = IFarmsUni(farmsUni).withdrawLpAndSwap(address(swapsUni), lpToken_, tokens_, amountsOutMin_[0], amount_);
            tokenDesired = tokens_[2];
         } else { // beets
            _approve(lpToken_, address(depositsBeets), amount_);
            amountTokenDesired = IDepositsBeets(depositsBeets).exitPool(poolId_, lpToken_, tokens_, amountsOutMin_, amount_);
            tokenDesired = tokens_[0];
         }
        IERC20(tokenDesired).safeTransfer(msg.sender, amountTokenDesired);
    }

    function depositOnFarmTokens(
        address lpToken_,
        address[] memory tokens_,
        uint256 amount0_,
        uint256 amount1_,
        uint8 provider_
    ) public onlyAllowed returns(uint256 amount0f_, uint256 amount1f_, uint256 lpBal_) {
        IERC20(tokens_[0]).safeTransferFrom(msg.sender, address(this), amount0_);
        IERC20(tokens_[1]).safeTransferFrom(msg.sender, address(this), amount1_);
        if (provider_ == 0) { // spooky
            IUniswapV2Router02 router = ISwapsUni(address(swapsUni)).getRouter(tokens_[0], tokens_[1]);
            _approve(tokens_[0], address(farmsUni), amount0_);
            _approve(tokens_[1], address(farmsUni), amount1_);
            (amount0f_, amount1f_, lpBal_) = IFarmsUni(farmsUni).addLiquidity(router, tokens_[0], tokens_[1], amount0_, amount1_, 0, 0);
        }
        IERC20(lpToken_).safeTransfer(msg.sender, lpBal_);
    }

    function withdrawFromFarm(
        address lpToken_,
        address[] memory tokens_,
        uint256 amountOutMin_,
        uint256 amountLp_,
        uint256 provider_
    ) public onlyAllowed returns (uint256 amountTokenDesired) {
        IERC20(lpToken_).safeTransferFrom(msg.sender, address(this), amountLp_);
        if (provider_ == 0) { // spooky
        _approve(lpToken_, address(farmsUni), amountLp_);
        amountTokenDesired = IFarmsUni(farmsUni).withdrawLpAndSwap(address(swapsUni), lpToken_, tokens_, amountOutMin_, amountLp_);
        }
        IERC20(tokens_[2]).safeTransfer(msg.sender, amountTokenDesired);
    }

    /**
     * @notice Approve of a token
     * @param token_ Address of the token wanted to be approved
     * @param spender_ Address that is wanted to be approved to spend the token
     * @param amount_ Amount of the token that is wanted to be approved.
     */
    function _approve(address token_, address spender_, uint256 amount_) internal {
        IERC20(token_).safeApprove(spender_, 0);
        IERC20(token_).safeApprove(spender_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IFirstTypeNestedStrategies.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

contract SelectNestedRoute is Ownable {
    using SafeERC20 for IERC20;

    address immutable firstTypeNestedStrategies;
    address private nodes;

    modifier onlyAllowed() {
        require(msg.sender == owner() || msg.sender == nodes, 'You must be the owner.');
        _;
    }

    constructor(address firstTypeNestedStrategies_) {
        firstTypeNestedStrategies = firstTypeNestedStrategies_;
    }

    function setNodes(address nodes_) public onlyOwner {
        nodes = nodes_;
    }

    /**
     * @param provider_ Value: 0 - Yearn and Reaper nested strategies
    */
    function deposit(address user_, address token_, address vaultAddress_, uint256 amount_, uint8 provider_) external onlyAllowed returns (uint256 sharesAmount) {
        IERC20(token_).safeTransferFrom(msg.sender, address(this), amount_);
        if (provider_ == 0) {
            _approve(token_, address(firstTypeNestedStrategies), amount_);
            sharesAmount = IFirstTypeNestedStrategies(firstTypeNestedStrategies).deposit(user_, token_, vaultAddress_, amount_, msg.sender);
        }
    }

    /**
     * @param provider_ Value: 0 - Yearn and Reaper nested strategies
    */
    function withdraw(address user_, address tokenOut_, address vaultAddress_, uint256 sharesAmount_, uint8 provider_) external onlyAllowed returns (uint256 amountTokenDesired) {
        IERC20(vaultAddress_).safeTransferFrom(msg.sender, address(this), sharesAmount_);
        if (provider_ == 0) {
            _approve(vaultAddress_, address(firstTypeNestedStrategies), sharesAmount_);
            amountTokenDesired = IFirstTypeNestedStrategies(firstTypeNestedStrategies).withdraw(user_, tokenOut_, vaultAddress_, sharesAmount_, msg.sender);
        }
    }

    /**
     * @notice Approve of a token
     * @param token_ Address of the token wanted to be approved
     * @param spender_ Address that is wanted to be approved to spend the token
     * @param amount_ Amount of the token that is wanted to be approved.
     */
    function _approve(address token_, address spender_, uint256 amount_) internal {
        IERC20(token_).safeApprove(spender_, 0);
        IERC20(token_).safeApprove(spender_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../lib/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/access/Ownable.sol';
import "../interfaces/IBeets.sol";
import "../interfaces/ISwapsUni.sol";
import "../interfaces/IAsset.sol";

contract SelectSwapRoute is Ownable {
    using SafeERC20 for IERC20;

    address immutable swapsUni;
    address immutable swapsBeets;
    address private nodes;

     modifier onlyAllowed() {
        require(msg.sender == owner() || msg.sender == nodes, 'You must be the owner.');
        _;
    }
    constructor(address swapsUni_, address swapsBeets_) {
        swapsUni = swapsUni_;
        swapsBeets = swapsBeets_;
    }

    function setNodes(address nodes_) public onlyAllowed {
        nodes = nodes_;
    }

    function swapTokens(IAsset[] memory tokens_, uint256 amount_, uint256 amountOutMin_, BatchSwapStep[] memory batchSwapStep_, uint8 provider_) public onlyAllowed returns(uint256 amountOut) {
        address tokenIn_ = address(tokens_[0]);
        address tokenOut_ = address(tokens_[tokens_.length - 1]);
        IERC20(tokenIn_).safeTransferFrom(msg.sender, address(this), amount_);

        if (provider_ == 0) {
            _approve(tokenIn_, address(swapsUni), amount_);
            amountOut = ISwapsUni(swapsUni).swapTokens(tokenIn_, amount_, tokenOut_, amountOutMin_);
        } else {
            _approve(tokenIn_, address(swapsBeets), amount_);
            batchSwapStep_[0].amount = amount_;
            amountOut = IBeets(swapsBeets).swapTokens(tokens_, batchSwapStep_);
        }
        IERC20(tokenOut_).safeTransfer(msg.sender, amountOut);
    }

    /**
     * @notice Approve of a token
     * @param token_ Address of the token wanted to be approved
     * @param spender_ Address that is wanted to be approved to spend the token
     * @param amount_ Amount of the token that is wanted to be approved.
     */
    function _approve(address token_, address spender_, uint256 amount_) internal {
        IERC20(token_).safeApprove(spender_, 0);
        IERC20(token_).safeApprove(spender_, amount_);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./lib/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

error SwapsUni_PairDoesNotExist();

contract SwapsUni is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable owner;
    address private immutable FTM;
    address private immutable USDC;
    address private immutable ETH;
    address[] public routers;

    constructor(address _owner, address _usdc, address _eth, address[] memory _routers) {
        owner = _owner;
        routers = _routers;
        FTM = IUniswapV2Router02(_routers[0]).WETH();
        USDC = _usdc;
        ETH = _eth;
    }

    /**
     * @notice Calculate the percentage of a number.
     * @param x Number.
     * @param y Percentage of number.
     * @param scale Division.
     */
    function mulScale(
        uint256 x,
        uint256 y,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 a = x / scale;
        uint256 b = x % scale;
        uint256 c = y / scale;
        uint256 d = y % scale;

        return a * c * scale + a * d + b * c + (b * d) / scale;
    }

    /**
     * @notice Function that allows to send X amount of tokens and returns the token you want.
     * @param _tokenIn Address of the token to be swapped.
     * @param _amount Amount of Tokens to be swapped.
     * @param _tokenOut Contract of the token you wish to receive.
     * @param _amountOutMin Minimum amount you wish to receive.
     */
    function swapTokens(
        address _tokenIn,
        uint256 _amount,
        address _tokenOut,
        uint256 _amountOutMin
    ) public nonReentrant returns (uint256 _amountOut) {
        IUniswapV2Router02 routerIn = getRouterOneToken(_tokenIn);
        IUniswapV2Router02 routerOut = getRouterOneToken(_tokenOut);

        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amount);

        address[] memory path;
        uint256[] memory amountsOut;

        if(_tokenIn != FTM && routerIn != routerOut) {
            IERC20(_tokenIn).safeApprove(address(routerIn), _amount);

            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = FTM;

            amountsOut = routerIn.swapExactTokensForTokens(
                _amount,
                _amountOutMin,
                path,
                address(this),
                block.timestamp
            );

            _amount = amountsOut[amountsOut.length - 1];
            _tokenIn = FTM;
        }

        IERC20(_tokenIn).safeApprove(address(routerOut), 0);
        IERC20(_tokenIn).safeApprove(address(routerOut), _amount);

        if(_tokenIn != _tokenOut) {
            address tokenInPool_ = _getTokenPool(_tokenIn, routerOut);
            address tokenOutPool_ = _getTokenPool(_tokenOut, routerOut);
            if (_tokenIn == tokenOutPool_ || _tokenOut == tokenInPool_) {
                path = new address[](2);
                path[0] = _tokenIn;
                path[1] = _tokenOut;
            } else if(tokenInPool_ != tokenOutPool_) {
                path = new address[](4);
                path[0] = _tokenIn;
                path[1] = tokenInPool_;
                path[2] = tokenOutPool_;
                path[3] = _tokenOut;
            } else {
                path = new address[](3);
                path[0] = _tokenIn;
                path[1] = tokenInPool_;
                path[2] = _tokenOut;
            }
            
            amountsOut = routerOut.swapExactTokensForTokens(
                _amount,
                _amountOutMin,
                path,
                address(msg.sender),
                block.timestamp
            );

            _amountOut = amountsOut[amountsOut.length - 1];
        } else {
            _amountOut = _amount;
            IERC20(_tokenIn).safeTransfer(msg.sender, _amountOut);
        }
    }

    /**
    * @notice Function used to, given a token, get wich pool has more liquidity (FTM or UDSC)
    * @param _token  Address of input token
    * @param _router Router used to get pair tokens information
    */
    function _getTokenPool(address _token, IUniswapV2Router02 _router) internal view returns(address tokenPool) {
        address wftmTokenLp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).getPair(FTM, _token);
        address usdcTokenLp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).getPair(USDC, _token);
        address wftmUsdcLp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).getPair(FTM, USDC);
        address ethTokenLp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).getPair(ETH, _token);
        address wftmEthLp = IUniswapV2Factory(IUniswapV2Router02(_router).factory()).getPair(FTM, ETH);
        
        uint256 reservePairA1_;
        uint256 reservePairA2_;
        uint256 reserveWftm_;
        uint256 usdcToWftmAmount_;
        uint256 ethToWftmAmount_;
        address firstToken_;

        if(wftmTokenLp != address(0)) { 
            (reservePairA1_, reservePairA2_, ) = IUniswapV2Pair(wftmTokenLp).getReserves(); 
            firstToken_ = IUniswapV2Pair(wftmTokenLp).token0(); 
            if (FTM == firstToken_) { reserveWftm_ = reservePairA1_; } 
            else { reserveWftm_ = reservePairA2_; }
        }
        
        if(usdcTokenLp != address(0)) {
            uint256 reserveUsdc_;
            (reservePairA1_,reservePairA2_, ) = IUniswapV2Pair(usdcTokenLp).getReserves();
            firstToken_ = IUniswapV2Pair(usdcTokenLp).token0(); 
            if (USDC == firstToken_){ reserveUsdc_ = reservePairA1_; } 
            else { reserveUsdc_ = reservePairA2_; }

            (reservePairA1_,reservePairA2_,)  = IUniswapV2Pair(wftmUsdcLp).getReserves();
            usdcToWftmAmount_ = IUniswapV2Router02(_router).getAmountOut(reserveUsdc_, reservePairA1_, reservePairA2_);
        }

        if(ETH != FTM && ethTokenLp != address(0)) {
            uint256 reserveEth_;
            (reservePairA1_,reservePairA2_, ) = IUniswapV2Pair(ethTokenLp).getReserves();
            firstToken_ = IUniswapV2Pair(ethTokenLp).token0(); 
            if (ETH == firstToken_) { reserveEth_ = reservePairA1_; } 
            else { reserveEth_ = reservePairA2_; }

           (reservePairA1_,reservePairA2_, )  = IUniswapV2Pair(wftmEthLp).getReserves();
            ethToWftmAmount_ = IUniswapV2Router02(_router).getAmountOut(reserveEth_, reservePairA2_, reservePairA1_);
        }
        tokenPool = getTokenOutpool(reserveWftm_, usdcToWftmAmount_, ethToWftmAmount_);
    }

    /**
    * @notice Internal function used to, given reserves, calcualte the higher one
    */
    function getTokenOutpool(uint256 reserveWftm_, uint256 usdcToWftmAmount_, uint256  ethToWftmAmount_) internal view returns(address tokenPool) {
        if((reserveWftm_ >= usdcToWftmAmount_) && (reserveWftm_ >= ethToWftmAmount_)) {
            tokenPool = FTM;
        } else if (reserveWftm_ >= usdcToWftmAmount_) {
            if (reserveWftm_ < ethToWftmAmount_) {
                tokenPool = ETH;
            } else {
                tokenPool = FTM;
            }
        } else if (reserveWftm_ >= ethToWftmAmount_) {
            if (reserveWftm_ < usdcToWftmAmount_) {
                tokenPool = USDC;
            } else {
                tokenPool = FTM;
            }
        } else {
            if (ethToWftmAmount_ >= usdcToWftmAmount_) {
                tokenPool = ETH;
            } else { 
                tokenPool = USDC;
            }
        }
    }

    /**
    * @notice Function used to get a router of 2 tokens. It tries to get its main router
    * @param _token0 Address of the first token
    * @param _token1 Address of the second token
    */
    function getRouter(address _token0, address _token1) public view returns(IUniswapV2Router02 router) {
        address pairToken0;
        address pairToken1;
        for(uint8 i = 0; i < routers.length; i++) {
            if(_token0 == FTM || _token1 == FTM){
                router = IUniswapV2Router02(routers[i]);
                break;
            } else {
                pairToken0 = IUniswapV2Factory(IUniswapV2Router02(routers[i]).factory()).getPair(_token0, FTM);
                if(pairToken0 != address(0)) {
                    pairToken1 = IUniswapV2Factory(IUniswapV2Router02(routers[i]).factory()).getPair(_token1, FTM);
                }
            }
            if(pairToken1 != address(0)) {
                router = IUniswapV2Router02(routers[i]);
            }
        }

        if (address(router) == address(0)) revert SwapsUni_PairDoesNotExist();
    }

    /**
    * @notice Function used to get the router of a tokens. It tries to get its main router.
    * @param _token Address of the token
    */
    function getRouterOneToken(address _token) public view returns(IUniswapV2Router02 router) {
        address pair;
        for(uint8 i = 0; i < routers.length; i++) {
            if(_token == FTM){
                router = IUniswapV2Router02(routers[i]);
                break;
            } else {
                pair = IUniswapV2Factory(IUniswapV2Router02(routers[i]).factory()).getPair(_token, FTM);
                if(pair == address(0)) {
                    pair = IUniswapV2Factory(IUniswapV2Router02(routers[i]).factory()).getPair(_token, USDC);
                }
            }
            if(pair != address(0)) {
                router = IUniswapV2Router02(routers[i]);
            }
        }

        if (address(router) == address(0)) revert SwapsUni_PairDoesNotExist();
    }

    receive() external payable {}
}