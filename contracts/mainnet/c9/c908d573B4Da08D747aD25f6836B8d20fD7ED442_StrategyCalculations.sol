// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
pragma solidity ^0.8.0;

/// @title AggregatorV3Interface
/// @notice Interface for Chainlink Aggregator V3
interface AggregatorV3Interface {
    /// @notice Returns the number of decimals used by the price feed
    /// @return The number of decimals
    function decimals() external view returns (uint8);

    /// @notice Returns a description of the price feed
    /// @return The description of the price feed
    function description() external view returns (string memory);

    /// @notice Returns the version number of the price feed
    /// @return The version number
    function version() external view returns (uint256);

    /// @notice Returns the latest answer from the price feed
    /// @return The latest answer
    function latestAnswer() external view returns (int256);

    /// @notice Returns the data for the latest round of the price feed
    /// @return roundId The ID of the latest round
    /// @return answer The latest answer
    /// @return startedAt The timestamp when the latest round started
    /// @return updatedAt The timestamp when the latest round was last updated
    /// @return answeredInRound The ID of the round when the latest answer was computed
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title IERC20
/// @notice Interface for the ERC20 token contract
interface IERC20 is IERC20Upgradeable {
    /// @notice Returns the number of decimals used by the token
    /// @return The number of decimals
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    ) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IUniswapRouterV3
/// @notice Interface for the Uniswap V3 Router contract
interface IUniswapRouterV3 {
    /// @notice Parameters for single-token exact input swaps
    struct ExactInputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the output tokens
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /// @notice Parameters for multi-hop exact input swaps
    struct ExactInputParams {
        bytes path; // The path of tokens to swap
        address recipient; // The address to receive the output tokens
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the input tokens
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path; // The path of tokens to swap (reversed)
        address recipient; // The address to receive the input tokens
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

/// @title IUniswapRouterV3WithDeadline
/// @notice Interface for the Uniswap V3 Router contract with deadline support
interface IUniswapRouterV3WithDeadline {
    /// @notice Parameters for single-token exact input swaps

    struct ExactInputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the output tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path; // The path of tokens to swap
        address recipient; // The address to receive the output tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountIn; // The exact amount of input tokens to swap
        uint256 amountOutMinimum; // The minimum acceptable amount of output tokens to receive
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn; // The address of the input token
        address tokenOut; // The address of the output token
        uint24 fee; // The fee level of the pool
        address recipient; // The address to receive the input tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
        uint160 sqrtPriceLimitX96; // The square root of the price limit in the Uniswap pool
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path; // The path of tokens to swap (reversed)
        address recipient; // The address to receive the input tokens
        uint256 deadline; // The deadline for the swap
        uint256 amountOut; // The exact amount of output tokens to receive
        uint256 amountInMaximum; // The maximum acceptable amount of input tokens to swap
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IConvexBooster
/// @notice Interface for the Convex Booster contract
interface IConvexBooster {
    /// @notice Deposits funds into the booster
    /// @param pid The pool ID
    /// @param amount The amount to deposit
    /// @param stake Flag indicating whether to stake the deposited funds
    /// @return True if the deposit was successful
    function deposit(uint256 pid, uint256 amount, bool stake) external returns (bool);

    /// @notice Earmarks rewards for the specified pool
    /// @param _pid The pool ID
    function earmarkRewards(uint256 _pid) external;

    /// @notice Retrieves information about a pool
    /// @param pid The pool ID
    /// @return lptoken The LP token address
    /// @return token The token address
    /// @return gauge The gauge address
    /// @return crvRewards The CRV rewards address
    /// @return stash The stash address
    /// @return shutdown Flag indicating if the pool is shutdown
    function poolInfo(
        uint256 pid
    )
        external
        view
        returns (
            address lptoken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );
}

/// @title IConvexBoosterL2
/// @notice Interface for the Convex Booster L2 contract
interface IConvexBoosterL2 {
    /// @notice Deposits funds into the L2 booster
    /// @param _pid The pool ID
    /// @param _amount The amount to deposit
    /// @return True if the deposit was successful
    function deposit(uint256 _pid, uint256 _amount) external returns (bool);

    /// @notice Deposits all available funds into the L2 booster
    /// @param _pid The pool ID
    /// @return True if the deposit was successful
    function depositAll(uint256 _pid) external returns (bool);

    /// @notice Retrieves information about a pool
    /// @param pid The pool ID
    /// @return lptoken The LP token address
    /// @return gauge The gauge address
    /// @return rewards The rewards address
    /// @return shutdown Flag indicating if the pool is shutdown
    /// @return factory The curve factory address used to create the pool
    function poolInfo(
        uint256 pid
    )
        external
        view
        returns (
            address lptoken, //the curve lp token
            address gauge, //the curve gauge
            address rewards, //the main reward/staking contract
            bool shutdown, //is this pool shutdown?
            address factory //a reference to the curve factory used to create this pool (needed for minting crv)
        );
}

/// @title IConvexRewardPool
/// @notice Interface for the Convex Reward Pool contract
interface IConvexRewardPool {
    /// @notice Struct containing information about an earned reward
    struct EarnedData {
        address token;
        uint256 amount;
    }

    /// @notice Retrieves the balance of the specified account
    /// @param account The account address
    /// @return The account balance
    function balanceOf(address account) external view returns (uint256);

    /// @notice Retrieves the claimable rewards for the specified account
    /// @param _account The account address
    /// @return claimable An array of EarnedData representing the claimable rewards
    function earned(address _account) external returns (EarnedData[] memory claimable);

    /// @notice Retrieves the period finish timestamp
    /// @return The period finish timestamp
    function periodFinish() external view returns (uint256);

    /// @notice Claims the available rewards for the caller
    function getReward() external;

    /// @notice Claims the available rewards for the specified account
    /// @param _account The account address
    /// @param _claimExtras Flag indicating whether to claim extra rewards
    function getReward(address _account, bool _claimExtras) external;

    /// @notice Claims the available rewards for the specified account
    /// @param _account The account address
    function getReward(address _account) external;

    /// @notice Withdraws and unwraps the specified amount of tokens
    /// @param _amount The amount to withdraw and unwrap
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAndUnwrap(uint256 _amount, bool claim) external;

    /// @notice Withdraws all funds and unwraps the tokens
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAllAndUnwrap(bool claim) external;

    /// @notice Withdraws the specified amount of tokens
    /// @param _amount The amount to withdraw
    /// @param _claim Flag indicating whether to claim rewards
    function withdraw(uint256 _amount, bool _claim) external;

    /// @notice Withdraws all funds
    /// @param claim Flag indicating whether to claim rewards
    function withdrawAll(bool claim) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title ICurveSwap
/// @notice Interface for the CurveSwap contract
interface ICurveSwap {
    /// @notice Retrieves the fee applied by the CurveSwap contract
    /// @return The fee amount
    function fee() external view returns (uint256);

    /// @notice Retrieves the admin fee applied by the CurveSwap contract
    /// @return The admin fee amount
    function admin_fee() external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to mint or burn for a given token input or output amounts
    /// @param amounts The token input or output amounts
    /// @param is_deposit Boolean indicating if it's a deposit or withdrawal operation
    /// @return The calculated amount of LP tokens
    function calc_token_amount(
        uint256[2] memory amounts,
        bool is_deposit
    ) external view returns (uint256);

    /// @notice Removes liquidity from the CurveSwap contract
    /// @param _burn_amount The amount of LP tokens to burn
    /// @param _min_amounts The minimum acceptable token amounts to receive
    /// @return The actual amounts received after removing liquidity
    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] memory _min_amounts
    ) external returns (uint256[2] memory);

    /// @notice Removes liquidity from the CurveSwap contract for a single token
    /// @param token_amount The amount of the token to remove
    /// @param i The index of the token in the pool
    /// @param min_amount The minimum acceptable token amount to receive
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    /// @notice Calculates the amount of tokens to receive when withdrawing a single token from the CurveSwap contract
    /// @param tokenAmount The LP amount to withdraw
    /// @param i The index of the token in the pool
    /// @return The calculated amount of tokens to receive
    function calc_withdraw_one_coin(uint256 tokenAmount, int128 i) external view returns (uint256);

    /// @notice Retrieves the address of a token in the CurveSwap pool by its index
    /// @param arg0 The index of the token in the pool
    /// @return The address of the token
    function coins(uint256 arg0) external view returns (address);

    /// @notice Retrieves the virtual price of the CurveSwap pool
    /// @return The virtual price
    function get_virtual_price() external view returns (uint256);

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract with an option to use underlying tokens
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    /// @param _use_underlying Boolean indicating whether to use underlying tokens
    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[2] memory amounts,
        uint256 min_mint_amount
    ) external;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract with an option to use underlying tokens
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    /// @param _use_underlying Boolean indicating whether to use underlying tokens
    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool _use_underlying
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[3] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[4] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[5] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[5] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Adds liquidity to the CurveSwap contract
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(uint256[6] memory amounts, uint256 min_mint_amount) external payable;

    /// @notice Adds liquidity to the CurveSwap contract for a specific pool
    /// @param _pool The address of the pool to add liquidity to
    /// @param amounts The amounts of tokens to add as liquidity
    /// @param min_mint_amount The minimum acceptable amount of LP tokens to mint
    function add_liquidity(
        address _pool,
        uint256[6] memory amounts,
        uint256 min_mint_amount
    ) external payable;

    /// @notice Exchanges tokens on the CurveSwap contract
    /// @param i The index of the input token in the pool
    /// @param j The index of the output token in the pool
    /// @param dx The amount of the input token to exchange
    /// @param min_dy The minimum acceptable amount of the output token to receive
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IGaugeFactory
/// @notice Interface for the Gauge Factory
interface IGaugeFactory {
    /// @notice Mints a gauge token
    /// @param _gauge The address of the gauge to be minted
    function mint(address _gauge) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title ISuperAdmin
/// @dev Interface for managing the super admin role.
interface ISuperAdmin {
    /// @dev Emitted when the super admin role is transferred.
    /// @param oldAdmin The address of the old super admin.
    /// @param newAdmin The address of the new super admin.
    event SuperAdminTransfer(address oldAdmin, address newAdmin);

    /// @notice Returns the address of the super admin.
    /// @return The address of the super admin.
    function superAdmin() external view returns (address);

    /// @notice Checks if the caller is a valid super admin.
    /// @param caller The address to check.
    function isValidSuperAdmin(address caller) external view;

    /// @notice Transfers the super admin role to a new address.
    /// @param _superAdmin The address of the new super admin.
    function transferSuperAdmin(address _superAdmin) external;
}

/// @title IAdminStructure
/// @dev Interface for managing admin roles.
interface IAdminStructure is ISuperAdmin {
    /// @dev Emitted when an admin is added.
    /// @param admin The address of the added admin.
    event AddedAdmin(address admin);

    /// @dev Emitted when an admin is removed.
    /// @param admin The address of the removed admin.
    event RemovedAdmin(address admin);

    /// @notice Checks if the caller is a valid admin.
    /// @param caller The address to check.
    function isValidAdmin(address caller) external view;

    /// @notice Checks if an account is an admin.
    /// @param account The address to check.
    /// @return A boolean indicating if the account is an admin.
    function isAdmin(address account) external view returns (bool);

    /// @notice Adds multiple addresses as admins.
    /// @param _admins The addresses to add as admins.
    function addAdmins(address[] memory _admins) external;

    /// @notice Removes multiple addresses from admins.
    /// @param _admins The addresses to remove from admins.
    function removeAdmins(address[] memory _admins) external;

    /// @notice Returns all the admin addresses.
    /// @return An array of admin addresses.
    function getAllAdmins() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/// @title IStrategyCalculations
/// @notice Interface for the Strategy Calculations contract
/// @dev This interface provides functions for performing various calculations related to the strategy.
interface IStrategyCalculations {
    /// @return The address of the Admin Structure contract
    function adminStructure() external view returns (address);

    /// @return The address of the Strategy contract
    function strategy() external view returns (address);

    /// @return The address of the Quoter contract
    function quoter() external view returns (address);

    /// @dev Constant for representing 100 (100%)
    /// @return The value of 100
    function ONE_HUNDRED() external pure returns (uint256);

    /// @notice Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum amount of tokens to receive from Curve
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _token The token to estimate the deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external view returns (uint256);

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 estimate);

    /// @notice Estimates the deposit details for a specific token and amount
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return amountWant The minimum amount of tokens to get on the curve deposit
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 amountWant);

    /// @notice Estimates the withdrawal details for a specific user, token, maximum amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return withdrawable The minimum amount of tokens to get after the withdrawal
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 withdrawable);

    /// @notice Estimates the rewards details for a specific user, token, amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return claimable The minimum amount of tokens to get after the claim of rewards
    function estimateRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 claimable);

    /// @notice Estimates the total claimable rewards for all users using a specific token and slippage
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return claimable The total claimable amount of tokens
    function estimateAllUsersRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 claimable);

    /// @dev Returns the amount of tokens deposited by a specific user in the indicated token
    /// @param _user The address of the user.
    /// @param _token The address of the token.
    /// @return The amount of tokens deposited by the user.
    function userDeposit(address _user, address _token) external view returns (uint256);

    /// @dev Returns the total amount of tokens deposited in the strategy in the indicated token
    /// @param _token The address of the token.
    /// @return The total amount of tokens deposited.
    function totalDeposits(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum amount of tokens to swap from a specific fromToken to toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @return The minimum amount of tokens to swap
    function getAutomaticSwapMin(address _fromToken, address _toToken) external returns (uint256);

    /// @notice Retrieves the minimum amount of LP tokens to obtained from a curve deposit
    /// @param _depositAmount The amount to deposit
    /// @return The minimum amount of LP tokens to obtained from the deposit on curve
    function getAutomaticCurveMinLp(uint256 _depositAmount) external returns (uint256);

    /// @notice Retrieves the balance of a specific token held by the Strategy
    /// @param _token The address of the token
    /// @return The token balance
    function _getTokenBalance(address _token) external view returns (uint256);

    /// @notice Retrieves the minimum value between a specific amount and a slippage percentage
    /// @param _amount The amount
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum value
    function _getMinimum(uint256 _amount, uint256 _slippage) external pure returns (uint256);

    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) external view returns (uint256[2] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "./IStrategyCalculations.sol";

/// @title IStrategyConvexL2
/// @notice Interface for the Convex L2 Strategy contract
interface IStrategyConvexL2 {
    /// @dev Struct representing a pool token
    struct PoolToken {
        bool isAllowed; /// Flag indicating if the token is allowed
        uint8 index; /// Index of the token
    }

    /// @dev Struct representing an oracle
    struct Oracle {
        address token; /// Token address
        address oracle; /// Oracle address
    }

    /// @dev Struct representing default slippages
    struct DefaultSlippages {
        uint256 curve; /// Default slippage for Curve swaps
        uint256 uniswap; /// Default slippage for Uniswap swaps
    }

    /// @dev Struct representing reward information
    struct RewardInfo {
        address[] tokens; /// Array of reward tokens
        uint256[] minAmount; /// Array of minimum reward amounts
    }

    /// @dev Enum representing fee types
    enum FeeType {
        MANAGEMENT, /// Management fee
        PERFORMANCE /// Performance fee
    }

    /// @dev Event emitted when a harvest is executed
    /// @param harvester The address of the harvester
    /// @param amount The amount harvested
    /// @param wantBal The balance of the want token after the harvest
    event Harvested(address indexed harvester, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when a deposit is made
    /// @param user The address of the user
    /// @param token The address of the token deposited
    /// @param wantBal The balance of the want token generated with the deposit
    event Deposit(address user, address token, uint256 wantBal);

    /// @dev Event emitted when a withdrawal is made
    /// @param user The address of the user
    /// @param token The address of the token being withdrawn
    /// @param amount The amount withdrawn
    /// @param wantBal The balance of the want token after the withdrawal
    event Withdraw(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when rewards are claimed
    /// @param user The address of the user
    /// @param token The address of the reward token
    /// @param amount The amount of rewards claimed
    /// @param wantBal The balance of the want token after claiming rewards
    event ClaimedRewards(address user, address token, uint256 amount, uint256 wantBal);

    /// @dev Event emitted when fees are charged
    /// @param feeType The type of fee (Management or Performance)
    /// @param amount The amount of fees charged
    /// @param feeRecipient The address of the fee recipient
    event ChargedFees(FeeType indexed feeType, uint256 amount, address feeRecipient);

    /// @dev Event emitted when allowed tokens are edited
    /// @param token The address of the token
    /// @param status The new status (true or false)
    event EditedAllowedTokens(address token, bool status);

    /// @dev Event emitted when the pause status is changed
    /// @param status The new pause status (true or false)
    event PauseStatusChanged(bool status);

    /// @dev Event emitted when a swap path is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param path The swap path
    event SetPath(address from, address to, bytes path);

    /// @dev Event emitted when a swap route is set
    /// @param from The address of the token to swap from
    /// @param to The address of the token to swap to
    /// @param route The swap route
    event SetRoute(address from, address to, address[] route);

    /// @dev Event emitted when an oracle is set
    /// @param token The address of the token
    /// @param oracle The address of the oracle
    event SetOracle(address token, address oracle);

    /// @dev Event emitted when the slippage value is set
    /// @param oldValue The old slippage value
    /// @param newValue The new slippage value
    /// @param kind The kind of slippage (Curve or Uniswap)
    event SetSlippage(uint256 oldValue, uint256 newValue, string kind);

    /// @dev Event emitted when the minimum amount to harvest is changed
    /// @param token The address of the token
    /// @param minimum The new minimum amount to harvest
    event MinimumToHarvestChanged(address token, uint256 minimum);

    /// @dev Event emitted when a reward token is added
    /// @param token The address of the reward token
    /// @param minimum The minimum amount of the reward token
    event AddedRewardToken(address token, uint256 minimum);

    /// @dev Event emitted when a panic is executed
    event PanicExecuted();
}

/// @title IStrategyConvexL2Extended
/// @notice Extended interface for the Convex L2 Strategy contract
interface IStrategyConvexL2Extended is IStrategyConvexL2 {
    /// @dev Returns the address of the pool contract
    /// @return The address of the pool contract
    function pool() external view returns (address);

    /// @dev Returns the address of the calculations contract
    /// @return The address of the calculations contract
    function calculations() external view returns (IStrategyCalculations);

    /// @dev Returns the address of the admin structure contract
    /// @return The address of the admin structure contract
    function adminStructure() external view returns (address);

    /// @dev Deposits tokens into the strategy
    /// @param _token The address of the token to deposit
    /// @param _user The address of the user
    /// @param _minWant The minimum amount of want tokens to get from curve
    function deposit(address _token, address _user, uint256 _minWant) external;

    /// @dev Executes the harvest operation, it is also the function compound, reinvests rewards
    function harvest() external;

    /// @dev Executes a panic operation, withdraws all the rewards from convex
    function panic() external;

    /// @dev Pauses the strategy, pauses deposits
    function pause() external;

    /// @dev Unpauses the strategy
    function unpause() external;

    /// @dev Withdraws tokens from the strategy
    /// @param _user The address of the user
    /// @param _amount The amount of tokens to withdraw
    /// @param _token The address of the token to withdraw
    /// @param _minCurveOutput The minimum LP output from Curve
    function withdraw(
        address _user,
        uint256 _amount,
        address _token,
        uint256 _minCurveOutput
    ) external;

    /// @dev Claims rewards for the user
    /// @param _user The address of the user
    /// @param _token The address of the reward token
    /// @param _amount The amount of rewards to claim
    /// @param _minCurveOutput The minimum LP token output from Curve swap
    function claimRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _minCurveOutput
    ) external;

    /// @dev Returns the address of the reward pool contract
    /// @return The address of the reward pool contract
    function rewardPool() external view returns (address);

    /// @dev Returns the address of the deposit token
    /// @return The address of the deposit token
    function depositToken() external view returns (address);

    /// @dev Checks if a token is allowed for deposit
    /// @param token The address of the token
    /// @return isAllowed True if the token is allowed, false otherwise
    /// @return index The index of the token
    function allowedDepositTokens(address token) external view returns (bool, uint8);

    /// @dev Returns the swap path for a token pair
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @return The swap path
    function paths(address _from, address _to) external view returns (bytes memory);

    /// @dev Returns the want deposit amount of a user in the deposit token
    /// @param _user The address of the user
    /// @return The deposit amount for the user
    function userWantDeposit(address _user) external view returns (uint256);

    /// @dev Returns the total want deposits in the strategy
    /// @return The total deposits in the strategy
    function totalWantDeposits() external view returns (uint256);

    /// @dev Returns the oracle address for a token
    /// @param _token The address of the token
    /// @return The oracle address
    function oracle(address _token) external view returns (address);

    /// @dev Returns the default slippage for Curve swaps used in harvest
    /// @return The default slippage for Curve swaps
    function defaultSlippageCurve() external view returns (uint256);

    /// @dev Returns the default slippage for Uniswap swaps used in harvest
    /// @return The default slippage for Uniswap swaps
    function defaultSlippageUniswap() external view returns (uint256);

    /// @dev Returns the want token
    /// @return The want token
    function want() external view returns (IERC20Upgradeable);

    /// @dev Returns the balance of the strategy held in the strategy
    /// @return The balance of the strategy
    function balanceOf() external view returns (uint256);

    /// @dev Returns the balance of the want token held in the strategy
    /// @return The balance of the want token
    function balanceOfWant() external view returns (uint256);

    /// @dev Returns the balance of want in the strategy
    /// @return The balance of the pool
    function balanceOfPool() external view returns (uint256);

    /// @dev Returns the pause status of the strategy
    /// @return True if the strategy is paused, false otherwise
    function paused() external view returns (bool);

    /// @dev Returns the address of the Uniswap router
    /// @return The address of the Uniswap router
    function unirouter() external view returns (address);

    /// @dev Returns the address of the vault contract
    /// @return The address of the vault contract
    function vault() external view returns (address);

    /// @dev Returns the address of Uniswap V2 router
    /// @return The address of Uniswap V2 router
    function unirouterV2() external view returns (address);

    /// @dev Returns the address of Uniswap V3 router
    /// @return The address of Uniswap V3 router
    function unirouterV3() external view returns (address);

    /// @dev Returns the performance fee
    /// @return The performance fee
    function performanceFee() external view returns (uint256);

    /// @dev Returns the management fee
    /// @return The management fee
    function managementFee() external view returns (uint256);

    /// @dev Returns the performance fee recipient
    /// @return The performance fee recipient
    function performanceFeeRecipient() external view returns (address);

    /// @dev Returns the management fee recipient
    /// @return The management fee recipient
    function managementFeeRecipient() external view returns (address);

    /// @dev Returns the fee cap
    /// @return The fee cap
    function FEE_CAP() external view returns (uint256);

    /// @dev Returns the constant value of 100
    /// @return The constant value of 100
    function ONE_HUNDRED() external view returns (uint256);

    /// @dev Sets the performance fee
    /// @param _fee The new performance fee
    function setPerformanceFee(uint256 _fee) external;

    /// @dev Sets the management fee
    /// @param _fee The new management fee
    function setManagementFee(uint256 _fee) external;

    /// @dev Sets the performance fee recipient
    /// @param recipient The new performance fee recipient
    function setPerformanceFeeRecipient(address recipient) external;

    /// @dev Sets the management fee recipient
    /// @param recipient The new management fee recipient
    function setManagementFeeRecipient(address recipient) external;

    /// @dev Sets the vault contract
    /// @param _vault The address of the vault contract
    function setVault(address _vault) external;

    /// @dev Sets the Uniswap V2 router address
    /// @param _unirouterV2 The address of the Uniswap V2 router
    function setUnirouterV2(address _unirouterV2) external;

    /// @dev Sets the Uniswap V3 router address
    /// @param _unirouterV3 The address of the Uniswap V3 router
    function setUnirouterV3(address _unirouterV3) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interfaces/common/IQuorter.sol";
import "../../interfaces/chainlink/AggregatorV3Interface.sol";
import "../../interfaces/common/IERC20.sol";
import "../../interfaces/common/IQuorter.sol";
import "../../interfaces/convex/IConvex.sol";
import "../../interfaces/curve/ICurveSwap.sol";
import "../../interfaces/curve/IGaugeFactory.sol";
import "../../utils/UniV3Actions.sol";
import "../../interfaces/dollet/IAdminStructure.sol";
import { IStrategyConvexL2Extended as IStrategyConvex } from "../../interfaces/dollet/IStrategyConvexL2.sol";

/// @title StrategyCalculations contract for calculating strategy-related values
contract StrategyCalculations is Initializable {
    /// @notice Address of the admin structure contract
    IAdminStructure public adminStructure;
    /// @notice Address of the strategy contract
    IStrategyConvex public strategy;
    /// @notice Address of the quoter contract
    IQuoter public quoter;

    /// @notice Constant for representing 100 (100%)
    uint256 public constant ONE_HUNDRED = 100 ether;

    /// @dev Initializes the StrategyCalculations contract
    /// @param _strategy The address of the StrategyConvex contract
    /// @param _quoter The address of the Quoter contract
    /// @param _adminStructure The address of the AdminStructure contract
    function initialize(
        IStrategyConvex _strategy,
        IQuoter _quoter,
        IAdminStructure _adminStructure
    ) public initializer {
        require(address(_strategy) != address(0), "ZeroStrategy");
        require(address(_quoter) != address(0), "ZeroQuoter");
        require(address(_adminStructure) != address(0), "ZeroAdminStructure");
        strategy = _strategy;
        quoter = _quoter;
        adminStructure = _adminStructure;
    }

    /// @dev Sets the Quoter contract address
    /// @param _quoter The address of the Quoter contract
    function setQuoter(IQuoter _quoter) external {
        adminStructure.isValidSuperAdmin(msg.sender);
        require(address(_quoter) != address(0), "ZeroQuoter");
        quoter = _quoter;
    }

    /// @dev Sets the StrategyConvex contract address
    /// @param _strategy The address of the StrategyConvex contract
    function setStrategy(IStrategyConvex _strategy) external {
        adminStructure.isValidSuperAdmin(msg.sender);
        require(address(_strategy) != address(0), "ZeroStrategy");
        strategy = _strategy;
    }

    /// @notice Estimates the deposit details for a specific token and amount
    /// @param _token The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return amountWant The minimum amount of LP tokens to get from curve deposit
    function estimateDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 amountWant) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        amountWant = calculateCurveDeposit(_token, _amount, _slippage);
    }

    /// @notice Estimates the withdrawal details for a specific user, token, maximum amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to withdraw
    /// @param _maxAmount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return withdrawable The minimum amount of tokens to get after the withdrawal
    function estimateWithdrawal(
        address _user,
        address _token,
        uint256 _maxAmount,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 withdrawable) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        uint256 maxClaim = calculateCurveMinWithdrawal(_token, _maxAmount, _slippage);
        minCurveOutput = maxClaim;
        uint256 _userDeposit = strategy.userWantDeposit(_user);
        uint256 _rewards = 0;
        if (_userDeposit < _maxAmount) {
            uint256 rewardsPercentage = ((_maxAmount - _userDeposit) * 1e18) / _maxAmount;
            _rewards = (maxClaim * rewardsPercentage) / 1e18;
        }
        uint256 depositMinusRewards = maxClaim - _rewards;
        uint256 _managementFee = strategy.managementFee();
        uint256 feeAmount = (depositMinusRewards * _managementFee) / ONE_HUNDRED;
        withdrawable = maxClaim - feeAmount;
    }

    /// @notice Estimates the rewards details for a specific user, token, amount, and slippage
    /// @param _user The address of the user
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return minCurveOutput The minimum amount of tokens to get from the curve withdrawal
    /// @return claimable The minimum amount of tokens to get after the claim of rewards
    function estimateRewards(
        address _user,
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 minCurveOutput, uint256 claimable) {
        return _estimateRewards(_token, _amount, _slippage, strategy.userWantDeposit(_user));
    }

    /// @notice Estimates the total claimable rewards for all users using a specific token and slippage
    /// @param _token The address of the token to calculate rewards for
    /// @param _amount The amount of tokens
    /// @param _slippage The allowed slippage percentage
    /// @return claimable The total claimable amount of tokens
    function estimateAllUsersRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) external returns (uint256 claimable) {
        (, claimable) = _estimateRewards(_token, _amount, _slippage, strategy.totalWantDeposits());
    }

    /**
     * @dev Returns the amount of tokens deposited by a specific user in the indicated token
     * @param _user The address of the user.
     * @param _token The address of the token.
     * @return The amount of tokens deposited by the user.
     */
    function userDeposit(address _user, address _token) external view returns (uint256) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        uint256 userWant = strategy.userWantDeposit(_user);
        if (userWant == 0) return 0;
        return calculateCurveMinWithdrawal(_token, userWant, 0);
    }

    /**
     * @dev Returns the total amount of tokens deposited in the strategy in the indicated token
     * @param _token The address of the token.
     * @return The total amount of tokens deposited.
     */
    function totalDeposits(address _token) external view returns (uint256) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        uint256 totalWant = strategy.totalWantDeposits();
        if (totalWant == 0) return 0;
        return calculateCurveMinWithdrawal(_token, totalWant, 0);
    }

    /// @notice Retrieves the minimum amount of tokens to swap from a specific fromToken to toToken
    /// @param _fromToken The address of the token to swap from
    /// @param _toToken The address of the token to swap to
    /// @return The minimum amount of tokens to swap
    function getAutomaticSwapMin(
        address _fromToken,
        address _toToken
    ) external view returns (uint256) {
        AggregatorV3Interface _oracleFrom = AggregatorV3Interface(strategy.oracle(_fromToken));
        AggregatorV3Interface _oracleTo = AggregatorV3Interface(strategy.oracle(_toToken));
        uint256 fromTokenPrice = (uint256(_oracleFrom.latestAnswer()) * 1e18) /
            (10 ** _oracleFrom.decimals());
        uint256 toTokenPrice = (uint256(_oracleTo.latestAnswer()) * 1e18) /
            (10 ** _oracleTo.decimals());
        uint256 minAmount = (fromTokenPrice * _getTokenBalance(_fromToken)) / toTokenPrice / 1e12;
        return (minAmount * (ONE_HUNDRED - strategy.defaultSlippageUniswap())) / ONE_HUNDRED;
    }

    /// @notice Retrieves the minimum amount of LP tokens to obtained from a curve deposit
    /// @param _depositAmount The amount to deposit
    /// @return The minimum amount of LP tokens to obtained from the deposit on curve
    function getAutomaticCurveMinLp(uint256 _depositAmount) external view returns (uint256) {
        address _depositToken = strategy.depositToken();
        AggregatorV3Interface _oracle = AggregatorV3Interface(strategy.oracle(_depositToken));
        uint256 oneTokenPrice = (uint256(_oracle.latestAnswer()) * 1e18) /
            (10 ** _oracle.decimals());
        uint256 depositUsdPrice = (_depositAmount * oneTokenPrice) /
            (10 ** IERC20(_depositToken).decimals());
        uint256 depositUsdPriceWithSlippage = (depositUsdPrice *
            (ONE_HUNDRED - strategy.defaultSlippageCurve())) / ONE_HUNDRED;
        return
            (depositUsdPriceWithSlippage * 1e18) / ICurveSwap(strategy.pool()).get_virtual_price();
    }

    /// @notice Estimates the amount of tokens to swap from one token to another
    /// @param _from The address of the token to swap from
    /// @param _to The address of the token to swap to
    /// @param _amount The amount of tokens to swap
    /// @param _slippage The allowed slippage percentage
    /// @return estimate The estimated amount of tokens to receive after the swap
    function estimateSwap(
        address _from,
        address _to,
        uint256 _amount,
        uint256 _slippage
    ) public returns (uint256 estimate) {
        if (_from == _to) return _amount;
        uint256 amountOut = quoter.quoteExactInput(strategy.paths(_from, _to), _amount);
        return _getMinimum(amountOut, _slippage);
    }

    /// @notice Calculates the minimum amount of tokens to receive from Curve for a specific token and maximum amount
    /// @param _token The address of the token to withdraw
    /// @param _amount The maximum amount of tokens to withdraw
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum amount of tokens to receive from Curve
    function calculateCurveMinWithdrawal(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) public view returns (uint256) {
        (, uint8 index) = strategy.allowedDepositTokens(_token);
        uint256 amount = ICurveSwap(strategy.pool()).calc_withdraw_one_coin(
            _amount,
            int128(uint128(index))
        );
        return _getMinimum(amount, _slippage);
    }

    /// @notice Calculates the amount of LP tokens to get on curve deposit
    /// @param _amount The amount of tokens to deposit
    /// @param _slippage The allowed slippage percentage
    /// @return The amount of LP tokens to get
    function calculateCurveDeposit(
        address _token,
        uint256 _amount,
        uint256 _slippage
    ) public view returns (uint256) {
        uint256[2] memory amounts = getCurveAmounts(_token, _amount);
        uint256 calcAmount = ICurveSwap(strategy.pool()).calc_token_amount(amounts, true);
        return _getMinimum(calcAmount, _slippage);
    }

    /// @notice Formats the array input for curve
    /// @param _depositToken The address of the deposit token
    /// @param _amount The amount to deposit
    /// @return amounts An array of token amounts to use in curve
    function getCurveAmounts(
        address _depositToken,
        uint256 _amount
    ) public view returns (uint256[2] memory amounts) {
        (, uint8 index) = strategy.allowedDepositTokens(_depositToken);
        amounts[index] = _amount;
    }

    /// @dev Estimates the rewards for a specific token and amount, taking into account slippage and deposit amount.
    /// @param _token The address of the token for which rewards are being estimated
    /// @param _amount The amount of tokens being considered
    /// @param _slippage The slippage percentage to consider
    /// @param _depositAmount The total deposit amount in the strategy
    /// @return minCurveOutput The minimum output from the Curve pool
    /// @return claimable The claimable rewards for the specified token and amount
    function _estimateRewards(
        address _token,
        uint256 _amount,
        uint256 _slippage,
        uint256 _depositAmount
    ) private returns (uint256 minCurveOutput, uint256 claimable) {
        (bool isAllowed, ) = strategy.allowedDepositTokens(_token);
        require(isAllowed, "TokenNotAllowed");
        if (
            _depositAmount == 0 ||
            _amount == 0 ||
            strategy.balanceOf() == 0 ||
            _depositAmount >= _amount
        ) return (0, 0);
        uint256 rewards = _amount - _depositAmount;
        minCurveOutput = calculateCurveMinWithdrawal(_token, rewards, _slippage);
        claimable = minCurveOutput;
    }

    /// @notice Retrieves the balance of a specific token held by the Strategy
    /// @param _token The address of the token
    /// @return The token balance
    function _getTokenBalance(address _token) private view returns (uint256) {
        return IERC20Upgradeable(_token).balanceOf(address(strategy));
    }

    /// @notice Retrieves the minimum value between a specific amount and a slippage percentage
    /// @param _amount The amount
    /// @param _slippage The allowed slippage percentage
    /// @return The minimum value
    function _getMinimum(uint256 _amount, uint256 _slippage) private pure returns (uint256) {
        return _amount - ((_amount * _slippage) / ONE_HUNDRED);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../interfaces/common/IUniswapRouterV3.sol";
import "../interfaces/common/IUniswapRouterV3WithDeadline.sol";

/// @title UniV3Actions
/// @dev Library for Uniswap V3 actions.

library UniV3Actions {
    /// @dev Performs a Uniswap V3 swap with a deadline.
    /// @param _router The address of the Uniswap V3 router.
    /// @param _path The path of tokens for the swap.
    /// @param _amount The input amount for the swap.
    /// @param _amountOutMinimum The minimum amount of output tokens expected from the swap.
    /// @return amountOut The amount of output tokens received from the swap.
    function swapV3WithDeadline(
        address _router,
        bytes memory _path,
        uint256 _amount,
        uint256 _amountOutMinimum
    ) internal returns (uint256 amountOut) {
        IUniswapRouterV3WithDeadline.ExactInputParams
            memory swapParams = IUniswapRouterV3WithDeadline.ExactInputParams({
                path: _path,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: _amountOutMinimum
            });
        return IUniswapRouterV3WithDeadline(_router).exactInput(swapParams);
    }
}