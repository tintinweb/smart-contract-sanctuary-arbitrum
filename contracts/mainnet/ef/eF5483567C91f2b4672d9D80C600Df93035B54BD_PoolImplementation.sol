// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

import "../token/IERC20.sol";
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IOracleManager is INameVersion, IAdmin {

    event NewOracle(bytes32 indexed symbolId, address indexed oracle);

    function getOracle(bytes32 symbolId) external view returns (address);

    function getOracle(string memory symbol) external view returns (address);

    function setOracle(address oracleAddress) external;

    function delOracle(bytes32 symbolId) external;

    function delOracle(string memory symbol) external;

    function value(bytes32 symbolId) external view returns (uint256);

    function timestamp(bytes32 symbolId) external view returns (uint256);

    function getValue(bytes32 symbolId) external view returns (uint256);

    function getValueWithJump(bytes32 symbolId) external returns (uint256 val, int256 jump);

    function updateValue(
        bytes32 symbolId,
        uint256 timestamp_,
        uint256 value_,
        uint8   v_,
        bytes32 r_,
        bytes32 s_
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../token/IERC20.sol';
import '../token/IDToken.sol';
import '../vault/IMarket.sol';
import '../vault/IVault.sol';
import '../oracle/IOracleManager.sol';
import '../swapper/ISwapper.sol';
import '../symbol/ISymbolManager.sol';
import '../utils/IPrivileger.sol';
import '../utils/IRewardVault.sol';
import './PoolStorage.sol';
import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/SafeERC20.sol';

contract PoolImplementation is PoolStorage, NameVersion {

    event CollectProtocolFee(address indexed collector, uint256 amount);

    event AddMarket(address indexed market);

    event SetRouter(address router, bool isActive);

    event AddLiquidity(
        uint256 indexed lTokenId,
        address indexed asset,
        uint256 amount,
        int256 newLiquidity
    );

    event RemoveLiquidity(
        uint256 indexed lTokenId,
        address indexed asset,
        uint256 amount,
        int256 newLiquidity
    );

    event AddMargin(
        uint256 indexed pTokenId,
        address indexed asset,
        uint256 amount,
        int256 newMargin
    );

    event RemoveMargin(
        uint256 indexed pTokenId,
        address indexed asset,
        uint256 amount,
        int256 newMargin
    );

    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;

    int256 constant ONE = 1e18;
    uint256 constant UONE = 1e18;
    uint256 constant UMAX = type(uint256).max / UONE;

    address public immutable vaultTemplate;

    address public immutable vaultImplementation;

    address public immutable tokenB0;

    address public immutable tokenWETH;

    address public immutable marketB0;

    address public immutable marketWETH;

    IDToken public immutable lToken;

    IDToken public immutable pToken;

    IOracleManager public immutable oracleManager;

    ISwapper public immutable swapper;

    ISymbolManager public immutable symbolManager;

    IPrivileger public immutable privileger;

    IRewardVault public immutable rewardVault;

    uint8 public immutable decimalsB0;

    uint256 public immutable reserveRatioB0;

    int256 public immutable minRatioB0;

    int256 public immutable poolInitialMarginMultiplier;

    int256 public immutable protocolFeeCollectRatio;

    int256 public immutable minLiquidationReward;

    int256 public immutable maxLiquidationReward;

    int256 public immutable liquidationRewardCutRatio;

    constructor (
        address[13] memory addresses_,
        uint256[7] memory parameters_
    ) NameVersion('PoolImplementation', '3.0.2')
    {
        vaultTemplate = addresses_[0];
        vaultImplementation = addresses_[1];
        tokenB0 = addresses_[2];
        tokenWETH = addresses_[3];
        marketB0 = addresses_[4];
        marketWETH = addresses_[5];
        lToken = IDToken(addresses_[6]);
        pToken = IDToken(addresses_[7]);
        oracleManager = IOracleManager(addresses_[8]);
        swapper = ISwapper(addresses_[9]);
        symbolManager = ISymbolManager(addresses_[10]);
        privileger = IPrivileger(addresses_[11]);
        rewardVault = IRewardVault(addresses_[12]);

        decimalsB0 = IERC20(tokenB0).decimals();

        reserveRatioB0 = parameters_[0];
        minRatioB0 = parameters_[1].utoi();
        poolInitialMarginMultiplier = parameters_[2].utoi();
        protocolFeeCollectRatio = parameters_[3].utoi();
        minLiquidationReward = parameters_[4].utoi();
        maxLiquidationReward = parameters_[5].utoi();
        liquidationRewardCutRatio = parameters_[6].utoi();
    }

    function addMarket(address market) external _onlyAdmin_ {
        // asset is the underlying token of Aave market
        address asset = IMarket(market).UNDERLYING_ASSET_ADDRESS();
        require(
            IMarket(market).POOL() == IVault(vaultImplementation).aavePool(),
            'PI: wrong Aave pool'
        );
        require(
            swapper.isSupportedToken(asset),
            'PI: no swapper support'
        );
        require(
            markets[asset] == address(0),
            'PI: replace not allowed'
        );

        markets[asset] = market;
        approveSwapper(asset);

        emit AddMarket(market);
    }

    function approveSwapper(address asset) public _onlyAdmin_ {
        uint256 allowance = IERC20(asset).allowance(address(this), address(swapper));
        if (allowance != type(uint256).max) {
            if (allowance != 0) {
                IERC20(asset).safeApprove(address(swapper), 0);
            }
            IERC20(asset).safeApprove(address(swapper), type(uint256).max);
        }
    }

    function setRouter(address router_, bool isActive) external _onlyAdmin_ {
        isRouter[router_] = isActive;
        emit SetRouter(router_, isActive);
    }

    function collectProtocolFee() external {
        require(protocolFeeCollector != address(0), 'PI: collector not set');
        // rescale protocolFeeAccrued from decimals18 to decimalsB0
        (uint256 amount, uint256 remainder) = protocolFeeAccrued.itou().rescaleDown(18, decimalsB0);
        protocolFeeAccrued = remainder.utoi();
        IERC20(tokenB0).safeTransfer(protocolFeeCollector, amount);
        emit CollectProtocolFee(protocolFeeCollector, amount);
    }

    function claimStakedAaveLp(address reward, address account) external {
        uint256 lTokenId = lToken.getTokenIdOf(account);
        if (lTokenId != 0) {
            IVault vault = IVault(lpInfos[lTokenId].vault);
            address[] memory assetsIn = vault.getAssetsIn();
            address[] memory marketsIn = new address[](assetsIn.length);
            for (uint256 i = 0; i < assetsIn.length; i++) {
                marketsIn[i] = markets[assetsIn[i]];
            }
            vault.claimStakedAave(marketsIn, reward, account);
        }
    }

    function claimStakedAaveTrader(address reward, address account) external {
        uint256 pTokenId = pToken.getTokenIdOf(account);
        if (pTokenId != 0) {
            IVault vault = IVault(tdInfos[pTokenId].vault);
            address[] memory assetsIn = vault.getAssetsIn();
            address[] memory marketsIn = new address[](assetsIn.length);
            for (uint256 i = 0; i < assetsIn.length; i++) {
                marketsIn[i] = markets[assetsIn[i]];
            }
            vault.claimStakedAave(marketsIn, reward, account);
        }
    }

    //================================================================================

    // amount in asset's own decimals
    function addLiquidity(address asset, uint256 amount, OracleSignature[] memory oracleSignatures) external payable _reentryLock_
    {
        _updateOracles(oracleSignatures);

        if (asset == address(0)) amount = msg.value;

        Data memory data = _initializeDataWithAccount(msg.sender, asset);
        _getLpInfo(data, true);

        ISymbolManager.SettlementOnAddLiquidity memory s =
        symbolManager.settleSymbolsOnAddLiquidity(data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        if (undistributedPnl != 0) {
            data.lpsPnl += undistributedPnl;
            data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
        }

        uint256 balanceB0 = IERC20(tokenB0).balanceOf(address(this));
        _settleLp(data);
        _transferIn(data, amount);
        int256 newLiquidity = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        if (address(rewardVault) != address(0)) {
            uint256 assetBalanceB0 = IVault(data.vault).getAssetBalance(marketB0);
            int256 newLiquidityB0 = assetBalanceB0.rescale(decimalsB0, 18).utoi() + data.amountB0;
            newLiquidityB0 = newLiquidity >= newLiquidityB0 ? newLiquidityB0 : newLiquidity;
            rewardVault.updateVault(data.liquidity.itou(), data.tokenId, data.lpLiquidity.itou(), balanceB0.rescale(decimalsB0, 18), newLiquidityB0);
        }

        data.liquidity += newLiquidity - data.lpLiquidity;
        data.lpLiquidity = newLiquidity;

        // only check B0 sufficiency when underlying is not B0
        if (asset != tokenB0) {
            require(
                // rescale tokenB0 balance from decimalsB0 to 18
                IERC20(tokenB0).balanceOf(address(this)).rescale(decimalsB0, 18).utoi() * ONE >= data.liquidity * minRatioB0,
                'PI: insufficient B0'
            );
        }

        liquidity = data.liquidity;
        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        LpInfo storage info = lpInfos[data.tokenId];
        info.vault = data.vault;
        info.amountB0 = data.amountB0;
        info.liquidity = data.lpLiquidity;
        info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

        emit AddLiquidity(data.tokenId, asset, amount, newLiquidity);
    }

    // amount in asset's own decimals
    function removeLiquidity(address asset, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        _updateOracles(oracleSignatures);

        Data memory data = _initializeDataWithAccount(msg.sender, asset);
        _getLpInfo(data, false);

        int256 removedLiquidity;
        uint256 assetBalance = IVault(data.vault).getAssetBalance(data.market);
        if (asset == tokenB0) {
            int256 available = assetBalance.rescale(decimalsB0, 18).utoi() + data.amountB0; // available in decimals18
            if (available > 0) {
                removedLiquidity = amount >= UMAX ?
                                   available :
                                   available.min(amount.rescale(decimalsB0, 18).utoi());
            }
        } else if (assetBalance > 0) {
            uint256 redeemAmount = amount.min(assetBalance);
            removedLiquidity = IVault(data.vault).getHypotheticalVaultLiquidityChange(data.asset, redeemAmount).utoi();
        }

        require(data.liquidity + data.lpsPnl > removedLiquidity, 'PI: removedLiquidity > total liquidity');
        ISymbolManager.SettlementOnRemoveLiquidity memory s =
        symbolManager.settleSymbolsOnRemoveLiquidity(data.liquidity + data.lpsPnl, removedLiquidity);
        require(s.removeLiquidityPenalty >= 0, 'PI: negative penalty');

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.removeLiquidityPenalty;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;
        data.amountB0 -= s.removeLiquidityPenalty;

        _settleLp(data);

        uint256 balanceB0 = IERC20(tokenB0).balanceOf(address(this));
        uint256 newVaultLiquidity = _transferOut(data, amount, assetBalance);
        int256 newLiquidity = newVaultLiquidity.utoi() + data.amountB0;

        if (address(rewardVault) != address(0)) {
            uint256 assetBalanceB0 = IVault(data.vault).getAssetBalance(marketB0);
            int256 newLiquidityB0 = assetBalanceB0.rescale(decimalsB0, 18).utoi() + data.amountB0;
            newLiquidityB0 = newLiquidity >= newLiquidityB0 ? newLiquidityB0 : newLiquidity;
            rewardVault.updateVault(data.liquidity.itou(), data.tokenId, data.lpLiquidity.itou(), balanceB0.rescale(decimalsB0, 18), newLiquidityB0);
        }

        data.liquidity += newLiquidity - data.lpLiquidity;
        data.lpLiquidity = newLiquidity;

        require(
            data.liquidity * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PI: pool insufficient liquidity'
        );

        liquidity = data.liquidity;
        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        LpInfo storage info = lpInfos[data.tokenId];
        info.amountB0 = data.amountB0;
        info.liquidity = data.lpLiquidity;
        info.cumulativePnlPerLiquidity = data.lpCumulativePnlPerLiquidity;

        emit RemoveLiquidity(data.tokenId, asset, amount, newLiquidity);
    }

    // amount in asset's own decimals
    function addMargin(address account, address asset, uint256 amount, OracleSignature[] memory oracleSignatures) external payable _reentryLock_
    {   if (!isRouter[msg.sender]) {
            require(account == msg.sender, "PI: unauthorized call");
        }

        _updateOracles(oracleSignatures);

        if (asset == address(0)) amount = msg.value;

        Data memory data;
        data.asset = asset;
        data.decimalsAsset = _getDecimalsAsset(asset); // get asset's decimals
        data.market = _getMarket(asset);
        data.account = account;

        _getTdInfo(data, true);
        _transferIn(data, amount);

        int256 newMargin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        TdInfo storage info = tdInfos[data.tokenId];
        info.vault = data.vault;
        info.amountB0 = data.amountB0;

        emit AddMargin(data.tokenId, asset, amount, newMargin);
    }

    // amount in asset's own decimals
    function removeMargin(address account, address asset, uint256 amount, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        if (!isRouter[msg.sender]) {
            require(account == msg.sender, "PI: unauthorized call");
        }

        _updateOracles(oracleSignatures);

        Data memory data = _initializeDataWithAccount(account, asset);
        _getTdInfo(data, false);

        ISymbolManager.SettlementOnRemoveMargin memory s =
        symbolManager.settleSymbolsOnRemoveMargin(data.tokenId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding;

        uint256 assetBalance = IVault(data.vault).getAssetBalance(data.market);
        int256 newVaultLiquidity = _transferOut(data, amount, assetBalance).utoi();

        require(
            newVaultLiquidity + data.amountB0 + s.traderPnl >= s.traderInitialMarginRequired,
            'PI: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        tdInfos[data.tokenId].amountB0 = data.amountB0;

        emit RemoveMargin(data.tokenId, asset, amount, newVaultLiquidity + data.amountB0);
    }

    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit) external _reentryLock_
    {
        require(isRouter[msg.sender], 'PI: only router');
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));

        Data memory data = _initializeDataWithAccount(account);
        _getTdInfo(data, false);

        ISymbolManager.SettlementOnTrade memory s =
        symbolManager.settleSymbolsOnTrade(data.tokenId, symbolId, tradeVolume, data.liquidity + data.lpsPnl, priceLimit);

        int256 collect = s.tradeFee * protocolFeeCollectRatio / ONE;
        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.tradeFee - collect + s.tradeRealizedCost;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        data.amountB0 -= s.traderFunding + s.tradeFee + s.tradeRealizedCost;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        require(
            (data.liquidity + data.lpsPnl) * ONE >= s.initialMarginRequired * poolInitialMarginMultiplier,
            'PI: pool insufficient liquidity'
        );
        require(
            margin + s.traderPnl >= s.traderInitialMarginRequired,
            'PI: insufficient margin'
        );

        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
        protocolFeeAccrued += collect;

        tdInfos[data.tokenId].amountB0 = data.amountB0;
    }

    function liquidate(uint256 pTokenId, OracleSignature[] memory oracleSignatures) external _reentryLock_
    {
        require(
            address(privileger) == address(0) || privileger.isQualifiedLiquidator(msg.sender),
            'PI: unqualified liquidator'
        );

        _updateOracles(oracleSignatures);

        require(
            pToken.exists(pTokenId),
            'PI: nonexistent pTokenId'
        );

        Data memory data = _initializeDataWithAccount(msg.sender);
        data.vault = tdInfos[pTokenId].vault;
        data.amountB0 = tdInfos[pTokenId].amountB0;

        ISymbolManager.SettlementOnLiquidate memory s =
        symbolManager.settleSymbolsOnLiquidate(pTokenId, data.liquidity + data.lpsPnl);

        int256 undistributedPnl = s.funding - s.deltaTradersPnl + s.traderRealizedCost;

        data.amountB0 -= s.traderFunding;
        int256 margin = IVault(data.vault).getVaultLiquidity().utoi() + data.amountB0;

        require(
            s.traderMaintenanceMarginRequired > 0,
            'PI: no position'
        );
        require(
            margin + s.traderPnl < s.traderMaintenanceMarginRequired,
            'PI: cannot liquidate'
        );

        data.amountB0 -= s.traderRealizedCost;

        IVault v = IVault(data.vault);
        address[] memory assetsIn = v.getAssetsIn();

        for (uint256 i = 0; i < assetsIn.length; i++) {
            address asset = assetsIn[i];
            if (asset == tokenWETH) asset = address(0);
            uint256 balance = v.redeem(asset, type(uint256).max);
            if (asset == address(0)) {
                (uint256 resultB0, ) = swapper.swapExactETHForB0{value: balance}();
                data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // rescale resultB0 from decimalsB0 to 18
            } else if (asset == tokenB0) {
                data.amountB0 += balance.rescale(decimalsB0, 18).utoi(); // rescale balance from decimalsB0 to 18
            } else {
                (uint256 resultB0, ) = swapper.swapExactBXForB0(asset, balance);
                data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // rescale resultB0 from decimalsB0 to 18
            }
        }

        int256 reward;
        if (data.amountB0 <= minLiquidationReward) {
            reward = minLiquidationReward;
        } else {
            reward = (data.amountB0 - minLiquidationReward) * liquidationRewardCutRatio / ONE + minLiquidationReward;
            reward = reward.min(maxLiquidationReward);
        }
        reward = reward.itou().rescale(18, decimalsB0).rescale(decimalsB0, 18).utoi(); // make reward no remainder when convert to decimalsB0

        undistributedPnl += data.amountB0 - reward;
        data.lpsPnl += undistributedPnl;
        data.cumulativePnlPerLiquidity += undistributedPnl * ONE / data.liquidity;

        _transfer(tokenB0, msg.sender, reward.itou().rescale(18, decimalsB0)); // when transfer, use decimalsB0

        lpsPnl = data.lpsPnl;
        cumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;

        tdInfos[pTokenId].amountB0 = 0;
    }

    //================================================================================

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function _updateOracles(OracleSignature[] memory oracleSignatures) internal {
        for (uint256 i = 0; i < oracleSignatures.length; i++) {
            OracleSignature memory signature = oracleSignatures[i];
            oracleManager.updateValue(
                signature.oracleSymbolId,
                signature.timestamp,
                signature.value,
                signature.v,
                signature.r,
                signature.s
            );
        }
    }

    struct Data {
        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;

        address asset;
        address market;
        uint256 decimalsAsset;

        address account;
        uint256 tokenId;
        address vault;
        int256 amountB0;
        int256 lpLiquidity;
        int256 lpCumulativePnlPerLiquidity;
    }

//    function _initializeData() internal view returns (Data memory data) {
//        data.liquidity = liquidity;
//        data.lpsPnl = lpsPnl;
//        data.cumulativePnlPerLiquidity = cumulativePnlPerLiquidity;
//        data.account = msg.sender;
//    }

    function _initializeDataWithAccount(address account) internal view returns (Data memory data) {
        data.liquidity = liquidity;
        data.lpsPnl = lpsPnl;
        data.cumulativePnlPerLiquidity = cumulativePnlPerLiquidity;
        data.account = account;
    }

    function _initializeDataWithAccount(address account, address asset) internal view returns (Data memory data) {
        data = _initializeDataWithAccount(account);
        data.asset = asset;
        data.decimalsAsset = _getDecimalsAsset(asset); // get asset's decimals
        data.market = _getMarket(asset);
    }

//    function _initializeData(address asset) internal view returns (Data memory data) {
//        data = _initializeData();
//        data.asset = asset;
//        data.decimalsAsset = _getDecimalsAsset(asset); // get asset's decimals
//        data.market = _getMarket(asset);
//    }

    function _getDecimalsAsset(address asset) internal view returns (uint8) {
        if (asset == address(0)) {
            return 18;
        } else if (asset == tokenB0) {
            return decimalsB0;
        } else {
            return IERC20(asset).decimals();
        }
    }

    function _getMarket(address asset) internal view returns (address market) {
        if (asset == address(0)) {
            market = marketWETH;
        } else if (asset == tokenB0) {
            market = marketB0;
        } else {
            market = markets[asset];
            require(
                market != address(0),
                'PI: unsupported market'
            );
        }
    }

    function _getUnderlyingAsset(address market) internal view returns (address asset) {
        if (market == marketB0) {
            asset = tokenB0;
        } else if (market == marketWETH) {
            asset = address(0);
        } else {
            asset = IMarket(market).UNDERLYING_ASSET_ADDRESS();
        }
    }

    function _getLpInfo(Data memory data, bool createOnDemand) internal {
        data.tokenId = lToken.getTokenIdOf(data.account);
        if (data.tokenId == 0) {
            require(createOnDemand, 'PI: not LP');
            data.tokenId = lToken.mint(data.account);
            data.vault = _clone(vaultTemplate);
        } else {
            LpInfo storage info = lpInfos[data.tokenId];
            data.vault = info.vault;
            data.amountB0 = info.amountB0;
            data.lpLiquidity = info.liquidity;
            data.lpCumulativePnlPerLiquidity = info.cumulativePnlPerLiquidity;
        }
    }

    function _getTdInfo(Data memory data, bool createOnDemand) internal {
        data.tokenId = pToken.getTokenIdOf(data.account);
        if (data.tokenId == 0) {
            require(createOnDemand, 'PI: not trader');
            data.tokenId = pToken.mint(data.account);
            data.vault = _clone(vaultTemplate);
        } else {
            TdInfo storage info = tdInfos[data.tokenId];
            data.vault = info.vault;
            data.amountB0 = info.amountB0;
        }
    }

    function _clone(address source) internal returns (address target) {
        bytes20 sourceBytes = bytes20(source);
        assembly {
            let c := mload(0x40)
            mstore(c, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(c, 0x14), sourceBytes)
            mstore(add(c, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            target := create(0, c, 0x37)
        }
    }

    function _settleLp(Data memory data) internal pure {
        int256 diff;
        unchecked { diff = data.cumulativePnlPerLiquidity - data.lpCumulativePnlPerLiquidity; }
        int256 pnl = diff * data.lpLiquidity / ONE;

        data.amountB0 += pnl;
        data.lpsPnl -= pnl;
        data.lpCumulativePnlPerLiquidity = data.cumulativePnlPerLiquidity;
    }

    // amount in asset's own decimals
    function _transfer(address asset, address to, uint256 amount) internal {
        if (asset == address(0)) {
            (bool success, ) = payable(to).call{value: amount}('');
            require(success, 'PI: send ETH fail');
        } else {
            IERC20(asset).safeTransfer(to, amount);
        }
    }

    // amount in asset's own decimals
    function _transferIn(Data memory data, uint256 amount) internal {
        IVault v = IVault(data.vault);

        if (data.asset == address(0)) { // ETH
            v.mint{value: amount}();
        }
        else if (data.asset == tokenB0) {
            uint256 reserve = amount * reserveRatioB0 / UONE;
            uint256 deposit = amount - reserve;

            IERC20(data.asset).safeTransferFrom(data.account, address(this), amount);
            IERC20(data.asset).safeTransfer(data.vault, deposit);

            v.mint(data.asset, deposit);
            data.amountB0 += reserve.rescale(data.decimalsAsset, 18).utoi(); // amountB0 is in decimals18
        }
        else {
            IERC20(data.asset).safeTransferFrom(data.account, data.vault, amount);
            v.mint(data.asset, amount);
        }
    }

    // amount/assetBalance are all in their own decimals
    function _transferOut(Data memory data, uint256 amount, uint256 assetBalance)
    internal returns (uint256 newVaultLiquidity)
    {
        IVault v = IVault(data.vault);

        if (assetBalance > 0) {
            // redeem asset, assetBalance is the exact redeemed amount
            assetBalance = v.redeem(data.asset, amount >= assetBalance ? type(uint256).max : amount);

            // if user has debt, pay it first
            if (data.amountB0 < 0) {
                (uint256 owe, uint256 excessive) = (-data.amountB0).itou().rescaleUp(18, decimalsB0); // amountB0 is in decimals18

                if (data.asset == address(0)) {
                    (uint256 resultB0, uint256 resultBX) = swapper.swapETHForExactB0{value: assetBalance}(owe);
                    data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // rescale resultB0 from decimalsB0 to 18
                    assetBalance -= resultBX;
                }
                else if (data.asset == tokenB0) {
                    if (assetBalance >= owe) {
                        data.amountB0 = excessive.utoi(); // excessive is already in decimals18
                        assetBalance -= owe;
                    } else {
                        data.amountB0 += assetBalance.rescale(decimalsB0, 18).utoi(); // rescale assetBalance to decimals18
                        assetBalance = 0;
                    }
                }
                else {
                    (uint256 resultB0, uint256 resultBX) = swapper.swapBXForExactB0(data.asset, owe, assetBalance);
                    data.amountB0 += resultB0.rescale(decimalsB0, 18).utoi(); // resultB0 to decimals18
                    assetBalance -= resultBX;
                }
            }

        }

        newVaultLiquidity = v.getVaultLiquidity();

        // user is removing all liquidity/margin completely
        // swap user's reserved amountB0 to his target token and transfer to him
        if (newVaultLiquidity == 0 && amount >= UMAX && data.amountB0 > 0) {
            (uint256 own, uint256 remainder) = data.amountB0.itou().rescaleDown(18, decimalsB0); // rescale amountB0 to decimalsB0
            uint256 resultBX;

            if (data.asset == address(0)) {
                (, resultBX) = swapper.swapExactB0ForETH(own);
            } else if (data.asset == tokenB0) {
                resultBX = own;
            } else {
                (, resultBX) = swapper.swapExactB0ForBX(data.asset, own);
            }

            assetBalance += resultBX;
            data.amountB0 = remainder.utoi(); // assign the remainder back to amountB0, which is not swappable
        }

        // user is removing tokenB0 and his intended amount is more than his vault's balance
        // use his reserved amountB0 to match user's intended amount if possible
        if (data.asset == tokenB0 && data.amountB0 > 0 && amount > assetBalance) {
            uint256 own = data.amountB0.itou().rescale(18, decimalsB0); // rescale amountB0 to decimalsB0
            uint256 resultBX = own.min(amount - assetBalance);

            assetBalance += resultBX;
            data.amountB0 -= resultBX.rescale(decimalsB0, 18).utoi();
        }

        if (assetBalance > 0) {
            _transfer(data.asset, data.account, assetBalance);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract PoolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    event NewProtocolFeeCollector(address newProtocolFeeCollector);

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    address public implementation;

    address public protocolFeeCollector;

    // underlying => vToken, supported markets
    mapping (address => address) public markets;

    struct LpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }

    // lTokenId => LpInfo
    mapping (uint256 => LpInfo) public lpInfos;

    struct TdInfo {
        address vault;
        int256 amountB0;
    }

    // pTokenId => TdInfo
    mapping (uint256 => TdInfo) public tdInfos;

    int256 public liquidity;

    int256 public lpsPnl;

    int256 public cumulativePnlPerLiquidity;

    int256 public protocolFeeAccrued;

    mapping (address => bool) public isRouter;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '../utils/IAdmin.sol';
import '../utils/INameVersion.sol';
import '../oracle/IOracleManager.sol';

interface ISwapper is IAdmin, INameVersion {

    function factory() external view returns (IUniswapV3Factory);

    function router() external view returns (ISwapRouter);

    function oracleManager() external view returns (IOracleManager);

    function tokenB0() external view returns (address);

    function tokenWETH() external view returns (address);

    function feeB0WETH() external view returns (uint24);

    function decimalsB0() external view returns (uint8);

    function maxSlippageRatio() external view returns (uint256);

    function oracleSymbolIds(address tokenBX) external view returns (bytes32);

    function setPath(string memory priceSymbol, uint24[] calldata fees, address[] calldata tokens) external;

    function getPath(address tokenBX) external view returns (bytes memory);

    function isSupportedToken(address tokenBX) external view returns (bool);

    function getTokenPrice(address tokenBX) external view returns (uint256);

    function swapExactB0ForBX(address tokenBX, uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactBXForB0(address tokenBX, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactBX(address tokenBX, uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapBXForExactB0(address tokenBX, uint256 amountB0, uint256 maxAmountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactB0ForETH(uint256 amountB0)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapExactETHForB0()
    external payable returns (uint256 resultB0, uint256 resultBX);

    function swapB0ForExactETH(uint256 maxAmountB0, uint256 amountBX)
    external returns (uint256 resultB0, uint256 resultBX);

    function swapETHForExactB0(uint256 amountB0)
    external payable returns (uint256 resultB0, uint256 resultBX);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbolManager {

    struct SettlementOnAddLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
    }

    struct SettlementOnRemoveLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnRemoveMargin {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
        int256 tradeFee;
        int256 tradeRealizedCost;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 traderRealizedCost;
    }

    function implementation() external view returns (address);

    function initialMarginRequired() external view returns (int256);

    function pool() external view returns (address);

    function getActiveSymbols(uint256 pTokenId) external view returns (address[] memory);

    function getSymbolsLength() external view returns (uint256);

    function addSymbol(address symbol) external;

    function removeSymbol(bytes32 symbolId) external;

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external returns (SettlementOnAddLiquidity memory ss);

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (SettlementOnRemoveLiquidity memory ss);

    function settleSymbolsOnRemoveMargin(uint256 pTokenId, int256 liquidity)
    external returns (SettlementOnRemoveMargin memory ss);

    function settleSymbolsOnTrade(uint256 pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (SettlementOnTrade memory ss);

    function settleSymbolsOnLiquidate(uint256 pTokenId, int256 liquidity)
    external returns (SettlementOnLiquidate memory ss);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IERC721.sol';
import '../utils/INameVersion.sol';

interface IDToken is IERC721, INameVersion {

    function pool() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalMinted() external view returns (uint256);

    function exists(address owner) external view returns (bool);

    function exists(uint256 tokenId) external view returns (bool);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function getTokenIdOf(address owner) external view returns (uint256);

    function mint(address owner) external returns (uint256);

    function burn(uint256 tokenId) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./IERC165.sol";

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IPrivileger {

    function deposit(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function isQualifiedLiquidator(address liquidator) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;


interface IRewardVault {

	struct UserInfo {
		uint256 accRewardPerB0Liquidity; // last updated accRewardPerB0Liquidity when the user triggered claim/update ops
		uint256 accRewardPerBXLiquidity; // last updated accRewardPerBXLiquidity when the user triggered claim/update ops
		uint256 unclaimed; // the unclaimed reward
		uint256 liquidityB0;
	}

	function updateVault(uint256, uint256, uint256, uint256, int256) external;

	function initializeAave(address) external;

	function initializeFromAaveA(address) external;

	function initializeFromAaveB(address, address, uint256, uint256) external;

	function initializeVenus(address) external;

	function initializeFromVenus(address, address) external;

	function initializeLite(address, address) external;

	function setRewardPerSecond(address, uint256) external;

	function emergencyWithdraw(address) external;

	function claim(address) external;

	function pending(address, uint256) view external returns (uint256);

	function pending(address, address) view external returns (uint256);

	function getRewardPerLiquidityPerSecond(address) view external returns (uint256, uint256);

	function getUserInfo(address, address) view external returns (UserInfo memory);

	function getTotalLiquidityB0(address) view external returns (uint256);

	function getAccRewardPerB0Liquidity(address) view external returns (uint256);

	function getAccRewardPerBXLiquidity(address) view external returns (uint256);

	function getVaultBalance(uint256) view external returns (uint256, int256);

	function getPendingPerPool(address) view external returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

// AAVE AToken Interface
interface IMarket {

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function POOL() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IVault is INameVersion {

    function pool() external view returns (address);

    function weth() external view returns (address);

    function aavePool() external view returns (address);

    function aaveOracle() external view returns (address);

    function aaveRewardsController() external view returns (address);

    function vaultLiquidityMultiplier() external view returns (uint256);

    function getVaultLiquidity() external view  returns (uint256);

    function getHypotheticalVaultLiquidityChange(address asset, uint256 removeAmount) external view returns (uint256);

    function getAssetsIn() external view returns (address[] memory);

    function getAssetBalance(address market) external view returns (uint256);

    function mint() external payable;

    function mint(address asset, uint256 amount) external;

    function redeem(address asset, uint256 amount) external returns (uint256 withdrawnAmount);

    function transfer(address asset, address to, uint256 amount) external;

    function transferAll(address asset, address to) external returns (uint256);

    function claimStakedAave(address[] memory markets, address reward, address to) external;

}