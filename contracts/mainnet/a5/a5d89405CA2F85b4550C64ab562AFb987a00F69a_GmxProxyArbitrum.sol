// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IERC20.sol";

interface IPair is IERC20 {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function mint(address to) external returns (uint256 liquidity);

    function sync() external;

    function stable() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../router/interfaces/IYakRouter.sol";

interface ISimpleRouter {
    error UnsupportedSwap(address _tokenIn, address _tokenOut);
    error InvalidConfiguration();

    struct SwapConfig {
        bool useYakSwapRouter;
        uint8 yakSwapMaxSteps;
        Path path;
    }

    struct Path {
        address[] adapters;
        address[] tokens;
    }

    function query(uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (FormattedOffer memory trade);

    function swap(FormattedOffer memory _trade) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IYakStrategy {
    function depositToken() external view returns (address);

    function depositFor(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.13;

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
pragma solidity 0.8.13;

import "./SafeERC20.sol";
import "../interfaces/IPair.sol";

library DexLibrary {
    using SafeERC20 for IERC20;

    bytes private constant zeroBytes = new bytes(0);
    uint256 public constant DEFAULT_SWAP_FEE = 30;
    uint public constant BIPS_DIVISOR = 10000;

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pair Pair used for swap
     * @return output amount
     */
    function swap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair pair
    ) internal returns (uint256) {
        return DexLibrary.swap(amountIn, fromToken, toToken, pair, DEFAULT_SWAP_FEE);
    }

    /**
     * @notice Swap directly through a Pair
     * @param amountIn input amount
     * @param fromToken address
     * @param toToken address
     * @param pair Pair used for swap
     * @return output amount
     */
    function swap(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair pair,
        uint256 swapFee
    ) internal returns (uint256) {
        (address token0, ) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        uint256 amountOut1 = 0;
        uint256 amountOut2 = getAmountOut(amountIn, reserve0, reserve1, swapFee);
        if (token0 != fromToken) (amountOut1, amountOut2) = (amountOut2, amountOut1);
        IERC20(fromToken).safeTransfer(address(pair), amountIn);
        pair.swap(amountOut1, amountOut2, address(this), zeroBytes);
        return amountOut2 > amountOut1 ? amountOut2 : amountOut1;
    }

    function checkSwapPairCompatibility(
        IPair pair,
        address tokenA,
        address tokenB
    ) internal pure returns (bool) {
        return
            (tokenA == pair.token0() || tokenA == pair.token1()) &&
            (tokenB == pair.token0() || tokenB == pair.token1()) &&
            tokenA != tokenB;
    }

    function estimateConversionThroughPair(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair swapPair
    ) internal view returns (uint256) {
        return DexLibrary.estimateConversionThroughPair(amountIn, fromToken, toToken, swapPair, DEFAULT_SWAP_FEE);
    }

    function estimateConversionThroughPair(
        uint256 amountIn,
        address fromToken,
        address toToken,
        IPair swapPair,
        uint256 swapFee
    ) internal view returns (uint256) {
        (address token0, ) = sortTokens(fromToken, toToken);
        (uint112 reserve0, uint112 reserve1, ) = swapPair.getReserves();
        if (token0 != fromToken) (reserve0, reserve1) = (reserve1, reserve0);
        return getAmountOut(amountIn, reserve0, reserve1, swapFee);
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev No price checks enforced
     * @param amount reward tokens
     * @return deposit tokens
     */
    function convertRewardTokensToDepositTokens(
        uint256 amount,
        address rewardToken,
        address depositToken,
        IPair swapPairToken0,
        IPair swapPairToken1
    ) internal returns (uint256) {
        return
            DexLibrary.convertRewardTokensToDepositTokens(
                amount,
                rewardToken,
                depositToken,
                swapPairToken0,
                DEFAULT_SWAP_FEE,
                swapPairToken1,
                DEFAULT_SWAP_FEE
            );
    }

    /**
     * @notice Converts reward tokens to deposit tokens
     * @dev No price checks enforced
     * @param amount reward tokens
     * @return deposit tokens
     */
    function convertRewardTokensToDepositTokens(
        uint256 amount,
        address rewardToken,
        address depositToken,
        IPair swapPairToken0,
        uint256 swapFeeToken0,
        IPair swapPairToken1,
        uint256 swapFeeToken1
    ) internal returns (uint256) {
        uint256 amountIn = amount / 2;
        require(amountIn > 0, "DexLibrary::_convertRewardTokensToDepositTokens");

        address token0 = IPair(depositToken).token0();
        uint256 amountOutToken0 = amountIn;
        if (rewardToken != token0) {
            amountOutToken0 = DexLibrary.swap(amountIn, rewardToken, token0, swapPairToken0, swapFeeToken0);
        }

        address token1 = IPair(depositToken).token1();
        uint256 amountOutToken1 = amountIn;
        if (rewardToken != token1) {
            amountOutToken1 = DexLibrary.swap(amountIn, rewardToken, token1, swapPairToken1, swapFeeToken1);
        }

        return DexLibrary.addLiquidity(depositToken, amountOutToken0, amountOutToken1);
    }

    /**
     * @notice Add liquidity directly through a Pair
     * @dev Checks adding the max of each token amount
     * @param depositToken address
     * @param maxAmountIn0 amount token0
     * @param maxAmountIn1 amount token1
     * @return liquidity tokens
     */
    function addLiquidity(
        address depositToken,
        uint256 maxAmountIn0,
        uint256 maxAmountIn1
    ) internal returns (uint256) {
        (uint112 reserve0, uint112 reserve1, ) = IPair(address(depositToken)).getReserves();
        uint256 amountIn1 = _quoteLiquidityAmountOut(maxAmountIn0, reserve0, reserve1);
        if (amountIn1 > maxAmountIn1) {
            amountIn1 = maxAmountIn1;
            maxAmountIn0 = _quoteLiquidityAmountOut(maxAmountIn1, reserve1, reserve0);
        }

        IERC20(IPair(depositToken).token0()).safeTransfer(depositToken, maxAmountIn0);
        IERC20(IPair(depositToken).token1()).safeTransfer(depositToken, amountIn1);
        return IPair(depositToken).mint(address(this));
    }

    /**
     * @notice Quote liquidity amount out
     * @param amountIn input tokens
     * @param reserve0 size of input asset reserve
     * @param reserve1 size of output asset reserve
     * @return liquidity tokens
     */
    function _quoteLiquidityAmountOut(
        uint256 amountIn,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256) {
        return (amountIn * reserve1) / reserve0;
    }

    /**
     * @notice Given two tokens, it'll return the tokens in the right order for the tokens pair
     * @dev TokenA must be different from TokenB, and both shouldn't be address(0), no validations
     * @param tokenA address
     * @param tokenB address
     * @return sorted tokens
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    /**
     * @notice Given an input amount of an asset and pair reserves, returns maximum output amount of the other asset
     * @param amountIn input asset
     * @param reserveIn size of input asset reserve
     * @param reserveOut size of output asset reserve
     * @return maximum output amount
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint256 swapFee
    ) internal pure returns (uint256) {
        uint256 amountInWithFee = amountIn * (BIPS_DIVISOR - swapFee);
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * BIPS_DIVISOR + amountInWithFee;
        return numerator / denominator;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.13;

import "../interfaces/IERC20.sol";
import "./Address.sol";

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

//       ╟╗                                                                      ╔╬
//       ╞╬╬                                                                    ╬╠╬
//      ╔╣╬╬╬                                                                  ╠╠╠╠╦
//     ╬╬╬╬╬╩                                                                  ╘╠╠╠╠╬
//    ║╬╬╬╬╬                                                                    ╘╠╠╠╠╬
//    ╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬      ╒╬╬╬╬╬╬╬╜   ╠╠╬╬╬╬╬╬╬         ╠╬╬╬╬╬╬╬    ╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╠
//    ╙╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬╕    ╬╬╬╬╬╬╬╜   ╣╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬   ╬╬╬╬╬╬╬╬╬╠╠╠╠╠╠╠╩
//     ╙╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬╬  ╔╬╬╬╬╬╬╬    ╔╠╠╠╬╬╬╬╬╬╬╬        ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬╬╬╬╬╠╠╠╠╝╙
//               ╘╣╬╬╬╬╬╬╬╬╬╬╬╬╬╬    ╒╠╠╠╬╠╬╩╬╬╬╬╬╬       ╠╬╬╬╬╬╬╬╣╬╬╬╬╬╬╬╙
//                 ╣╬╬╬╬╬╬╬╬╬╬╠╣     ╣╬╠╠╠╬╩ ╚╬╬╬╬╬╬      ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                  ╣╬╬╬╬╬╬╬╬╬╣     ╣╬╠╠╠╬╬   ╣╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╬╬╬╬╬╬╬
//                   ╟╬╬╬╬╬╬╬╩      ╬╬╠╠╠╠╬╬╬╬╬╬╬╬╬╬╬     ╠╬╬╬╬╬╬╬╠╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╒╬╬╠╠╬╠╠╬╬╬╬╬╬╬╬╬╬╬╬    ╠╬╬╬╬╬╬╬ ╣╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬     ╬╬╬╠╠╠╠╝╝╝╝╝╝╝╠╬╬╬╬╬╬   ╠╬╬╬╬╬╬╬  ╚╬╬╬╬╬╬╬╬
//                    ╬╬╬╬╬╬╬    ╣╬╬╬╬╠╠╩       ╘╬╬╬╬╬╬╬  ╠╬╬╬╬╬╬╬   ╙╬╬╬╬╬╬╬╬
//

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

struct Query {
    address adapter;
    address tokenIn;
    address tokenOut;
    uint256 amountOut;
}

struct Offer {
    bytes amounts;
    bytes adapters;
    bytes path;
    uint256 gasEstimate;
}

struct FormattedOffer {
    uint256[] amounts;
    address[] adapters;
    address[] path;
    uint256 gasEstimate;
}

struct Trade {
    uint256 amountIn;
    uint256 amountOut;
    address[] path;
    address[] adapters;
}

interface IYakRouter {
    event UpdatedTrustedTokens(address[] _newTrustedTokens);
    event UpdatedAdapters(address[] _newAdapters);
    event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee);
    event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer);
    event YakSwap(address indexed _tokenIn, address indexed _tokenOut, uint256 _amountIn, uint256 _amountOut);

    // admin
    function setTrustedTokens(address[] memory _trustedTokens) external;
    function setAdapters(address[] memory _adapters) external;
    function setFeeClaimer(address _claimer) external;
    function setMinFee(uint256 _fee) external;

    // misc
    function trustedTokensCount() external view returns (uint256);
    function adaptersCount() external view returns (uint256);

    // query

    function queryAdapter(uint256 _amountIn, address _tokenIn, address _tokenOut, uint8 _index)
        external
        returns (uint256);

    function queryNoSplit(uint256 _amountIn, address _tokenIn, address _tokenOut, uint8[] calldata _options)
        external
        view
        returns (Query memory);

    function queryNoSplit(uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (Query memory);

    function findBestPathWithGas(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint256 _maxSteps,
        uint256 _gasPrice
    ) external view returns (FormattedOffer memory);

    function findBestPath(uint256 _amountIn, address _tokenIn, address _tokenOut, uint256 _maxSteps)
        external
        view
        returns (FormattedOffer memory);

    // swap

    function swapNoSplit(Trade calldata _trade, address _to, uint256 _fee) external;

    function swapNoSplitFromAVAX(Trade calldata _trade, address _to, uint256 _fee) external payable;

    function swapNoSplitToAVAX(Trade calldata _trade, address _to, uint256 _fee) external;

    function swapNoSplitWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function swapNoSplitToAVAXWithPermit(
        Trade calldata _trade,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../../../interfaces/IYakStrategy.sol";
import "../../../lib/SafeERC20.sol";
import "../../../lib/DexLibrary.sol";
import "./../../../interfaces/ISimpleRouter.sol";

import "./interfaces/IGmxDepositor.sol";
import "./interfaces/IGmxRewardRouter.sol";
import "./interfaces/IGmxRewardTracker.sol";
import "./interfaces/IGmxProxy.sol";
import "./interfaces/IGlpManager.sol";
import "./interfaces/IGmxVault.sol";

library SafeProxy {
    function safeExecute(IGmxDepositor gmxDepositor, address target, uint256 value, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnValue) = gmxDepositor.execute(target, value, data);
        if (!success) revert("GmxProxy::safeExecute failed");
        return returnValue;
    }
}

contract GmxProxyArbitrum is IGmxProxy {
    using SafeProxy for IGmxDepositor;
    using SafeERC20 for IERC20;

    uint256 internal constant BIPS_DIVISOR = 10000;

    address internal constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address internal constant GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address internal constant sGLP = 0x5402B5F40310bDED796c7D0F3FF6683f5C0cFfdf;
    address internal constant esGMX = 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;
    uint256 internal constant USDG_PRICE_PRECISION = 1e30;

    address public devAddr;
    address public approvedStrategy;
    uint256 public maxEthSwapAmount;
    uint256 public minFeeDifference;

    IGmxDepositor public immutable override gmxDepositor;
    address public immutable override gmxRewardRouter;
    address public immutable glpMinter;
    ISimpleRouter internal immutable simpleRouter;

    address internal immutable gmxRewardTracker;
    address internal immutable glpRewardTracker;
    address internal immutable glpManager;
    address internal immutable vault;
    address internal immutable usdg;

    modifier onlyDev() {
        require(msg.sender == devAddr, "GmxProxy::onlyDev");
        _;
    }

    modifier onlyStrategy() {
        require(approvedStrategy == msg.sender, "GmxProxy:onlyStrategy");
        _;
    }

    constructor(
        address _gmxDepositor,
        address _gmxRewardRouter,
        address _gmxRewardRouterV2,
        address _simpleRouter,
        uint256 _maxEthSwapAmount,
        uint256 _minFeeDifference,
        address _devAddr
    ) {
        require(_devAddr > address(0), "GmxProxy::Invalid dev address provided");
        devAddr = _devAddr;
        gmxDepositor = IGmxDepositor(_gmxDepositor);
        gmxRewardRouter = _gmxRewardRouter;
        glpMinter = _gmxRewardRouterV2;
        gmxRewardTracker = IGmxRewardRouter(_gmxRewardRouter).stakedGmxTracker();
        glpRewardTracker = IGmxRewardRouter(_gmxRewardRouter).feeGlpTracker();
        glpManager = IGmxRewardRouter(_gmxRewardRouterV2).glpManager();
        vault = IGlpManager(glpManager).vault();
        usdg = IGmxVault(vault).usdg();
        simpleRouter = ISimpleRouter(_simpleRouter);
        maxEthSwapAmount = _maxEthSwapAmount;
        minFeeDifference = _minFeeDifference;
    }

    function updateDevAddr(address newValue) public onlyDev {
        require(newValue > address(0), "GmxProxy::Invalid dev address provided");
        devAddr = newValue;
    }

    function approveStrategy(address _strategy) external onlyDev {
        require(approvedStrategy == address(0), "GmxProxy::Strategy already defined");
        approvedStrategy = _strategy;
    }

    function updateMaxEthSwapAmount(uint256 _maxEthSwapAmount) external onlyDev {
        maxEthSwapAmount = _maxEthSwapAmount;
    }

    function updateMinFeeDifference(uint256 _minFeeDifference) external onlyDev {
        minFeeDifference = _minFeeDifference;
    }

    function stakeESGMX() external onlyDev {
        gmxDepositor.safeExecute(
            gmxRewardRouter,
            0,
            abi.encodeWithSignature("stakeEsGmx(uint256)", IERC20(esGMX).balanceOf(address(gmxDepositor)))
        );
    }

    function stakedESGMX() public view returns (uint256) {
        return IGmxRewardTracker(gmxRewardTracker).depositBalances(address(gmxDepositor), esGMX);
    }

    function vaultHasCapacity(address _token, uint256 _usdgAmount) internal view returns (bool) {
        uint256 usdgAmount = IGmxVault(vault).adjustForDecimals(_usdgAmount, _token, usdg);
        uint256 vaultUsdgAmount = IGmxVault(vault).usdgAmounts(_token);
        uint256 maxUsdgAmount = IGmxVault(vault).maxUsdgAmounts(_token);
        return maxUsdgAmount == 0 || vaultUsdgAmount + usdgAmount < maxUsdgAmount;
    }

    function buyAndStakeGlp(uint256 _amount) external override onlyStrategy returns (uint256) {
        address tokenIn = WETH;

        if (_amount < maxEthSwapAmount) {
            uint256 price = IGmxVault(vault).getMinPrice(WETH);
            uint256 usdgAmount = (_amount * price) / USDG_PRICE_PRECISION;
            uint256 mintFeeBasisPoints = IGmxVault(vault).mintBurnFeeBasisPoints();
            uint256 taxBasisPoints = IGmxVault(vault).taxBasisPoints();
            uint256 feeBasisPoints = vaultHasCapacity(WETH, usdgAmount)
                ? IGmxVault(vault).getFeeBasisPoints(WETH, usdgAmount, mintFeeBasisPoints, taxBasisPoints, true)
                : type(uint256).max;

            uint256 allWhiteListedTokensLength = IGmxVault(vault).allWhitelistedTokensLength();
            for (uint256 i = 0; i < allWhiteListedTokensLength; i++) {
                address whitelistedToken = IGmxVault(vault).allWhitelistedTokens(i);
                if (!vaultHasCapacity(whitelistedToken, usdgAmount)) continue;
                uint256 currentFeeBasisPoints = IGmxVault(vault).getFeeBasisPoints(
                    whitelistedToken, usdgAmount, mintFeeBasisPoints, taxBasisPoints, true
                );
                if (currentFeeBasisPoints + minFeeDifference < feeBasisPoints) {
                    feeBasisPoints = currentFeeBasisPoints;
                    tokenIn = whitelistedToken;
                }
            }

            if (tokenIn != WETH) {
                FormattedOffer memory offer = simpleRouter.query(_amount, WETH, tokenIn);
                IERC20(WETH).approve(address(simpleRouter), _amount);
                _amount = simpleRouter.swap(offer);
            }
        }

        IERC20(tokenIn).safeTransfer(address(gmxDepositor), _amount);
        gmxDepositor.safeExecute(tokenIn, 0, abi.encodeWithSignature("approve(address,uint256)", glpManager, _amount));
        bytes memory result = gmxDepositor.safeExecute(
            glpMinter,
            0,
            abi.encodeWithSignature("mintAndStakeGlp(address,uint256,uint256,uint256)", tokenIn, _amount, 0, 0)
        );
        gmxDepositor.safeExecute(tokenIn, 0, abi.encodeWithSignature("approve(address,uint256)", glpManager, 0));
        return toUint256(result, 0);
    }

    function withdrawGlp(uint256 _amount) external override onlyStrategy {
        _withdrawGlp(_amount);
    }

    function _withdrawGlp(uint256 _amount) private {
        gmxDepositor.safeExecute(sGLP, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount));
    }

    function pendingRewards() external view override returns (uint256) {
        return IGmxRewardTracker(IGmxRewardRouter(gmxRewardRouter).feeGlpTracker()).claimable(address(gmxDepositor));
    }

    function claimReward() external override onlyStrategy {
        gmxDepositor.safeExecute(
            gmxRewardRouter,
            0,
            abi.encodeWithSignature(
                "handleRewards(bool,bool,bool,bool,bool,bool,bool)", false, false, true, true, true, true, false
            )
        );
        uint256 reward = IERC20(WETH).balanceOf(address(gmxDepositor));
        gmxDepositor.safeExecute(WETH, 0, abi.encodeWithSignature("transfer(address,uint256)", msg.sender, reward));
    }

    function totalDeposits() external view override returns (uint256) {
        return IGmxRewardTracker(glpRewardTracker).stakedAmounts(address(gmxDepositor));
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGlpManager {
    function vault() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGmxDepositor {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function setGmxProxy(address _proxy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IGmxDepositor.sol";

interface IGmxProxy {
    function gmxDepositor() external view returns (IGmxDepositor);

    function gmxRewardRouter() external view returns (address);

    function buyAndStakeGlp(uint256 _amount) external returns (uint256);

    function withdrawGlp(uint256 _amount) external;

    function pendingRewards() external view returns (uint256);

    function claimReward() external;

    function totalDeposits() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGmxRewardRouter {
    function stakedGmxTracker() external view returns (address);

    function bonusGmxTracker() external view returns (address);

    function feeGmxTracker() external view returns (address);

    function stakedGlpTracker() external view returns (address);

    function feeGlpTracker() external view returns (address);

    function glpManager() external view returns (address);

    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);

    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
        external
        returns (uint256);

    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGmxRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);

    function stakedAmounts(address _account) external view returns (uint256);

    function updateRewards() external;

    function stake(address _depositToken, uint256 _amount) external;

    function stakeForAccount(
        address _fundingAccount,
        address _account,
        address _depositToken,
        uint256 _amount
    ) external;

    function unstake(address _depositToken, uint256 _amount) external;

    function unstakeForAccount(
        address _account,
        address _depositToken,
        uint256 _amount,
        address _receiver
    ) external;

    function tokensPerInterval() external view returns (uint256);

    function claim(address _receiver) external returns (uint256);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function averageStakedAmounts(address _account) external view returns (uint256);

    function cumulativeRewards(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IGmxVaultPriceFeed {
    function getPrice(address, bool, bool, bool) external view returns (uint256);
}

interface IGmxVaultUtils {
    function getSwapFeeBasisPoints(address, address, uint256) external view returns (uint256);

    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
}

interface IGmxVault {
    function swap(address, address, address) external;

    function whitelistedTokens(address) external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function vaultUtils() external view returns (IGmxVaultUtils);

    function priceFeed() external view returns (IGmxVaultPriceFeed);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function maxUsdgAmounts(address) external view returns (uint256);

    function usdgAmounts(address) external view returns (uint256);

    function reservedAmounts(address) external view returns (uint256);

    function bufferAmounts(address) external view returns (uint256);

    function poolAmounts(address) external view returns (uint256);

    function usdg() external view returns (address);

    function hasDynamicFees() external view returns (bool);

    function stableTokens(address) external view returns (bool);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function setBufferAmount(address, uint256) external;

    function gov() external view returns (address);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function adjustForDecimals(uint256 _amount, address _tokenDiv, address _tokenMul) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
}