// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";

import {AbstractAdapter} from "../AbstractAdapter.sol";
import {AdapterType} from "@gearbox-protocol/sdk-gov/contracts/AdapterType.sol";

import {ISwapRouter} from "../../integrations/uniswap/IUniswapV3.sol";
import {BytesLib} from "../../integrations/uniswap/BytesLib.sol";
import {IUniswapV3Adapter, UniswapV3PoolStatus} from "../../interfaces/uniswap/IUniswapV3Adapter.sol";

/// @title Uniswap V3 Router adapter
/// @notice Implements logic allowing CAs to perform swaps via Uniswap V3
contract UniswapV3Adapter is AbstractAdapter, IUniswapV3Adapter {
    using BytesLib for bytes;

    AdapterType public constant override _gearboxAdapterType = AdapterType.UNISWAP_V3_ROUTER;
    uint16 public constant override _gearboxAdapterVersion = 3_00;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;

    /// @dev The length of the uint24 encoded address
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;

    /// @dev The length of the path with 1 hop
    uint256 private constant PATH_2_LENGTH = 2 * ADDR_SIZE + FEE_SIZE;

    /// @dev The length of the path with 2 hops
    uint256 private constant PATH_3_LENGTH = 3 * ADDR_SIZE + 2 * FEE_SIZE;

    /// @dev The length of the path with 3 hops
    uint256 private constant PATH_4_LENGTH = 4 * ADDR_SIZE + 3 * FEE_SIZE;

    /// @dev Mapping from (token0, token1, fee) to whether the pool can be traded through the adapter
    mapping(address => mapping(address => mapping(uint24 => bool))) internal _poolStatus;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _router Uniswap V3 Router address
    constructor(address _creditManager, address _router)
        AbstractAdapter(_creditManager, _router) // U:[UNI3-1]
    {}

    /// @notice Swaps given amount of input token for output token through a single pool
    /// @param params Swap params, see `ISwapRouter.ExactInputSingleParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params)
        external
        override
        creditFacadeOnly // U:[UNI3-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[UNI3-3]

        ISwapRouter.ExactInputSingleParams memory paramsUpdate = params; // U:[UNI3-3]
        paramsUpdate.recipient = creditAccount; // U:[UNI3-3]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            params.tokenIn, params.tokenOut, abi.encodeCall(ISwapRouter.exactInputSingle, (paramsUpdate)), false
        ); // U:[UNI3-3]
    }

    /// @notice Swaps all balance of input token for output token through a single pool, except the specified amount
    /// @param params Swap params, see `ExactDiffInputSingleParams` for details
    function exactDiffInputSingle(ExactDiffInputSingleParams calldata params)
        external
        override
        creditFacadeOnly // U:[UNI3-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[UNI3-4]

        uint256 amount = IERC20(params.tokenIn).balanceOf(creditAccount); // U:[UNI3-4]
        if (amount <= params.leftoverAmount) return (0, 0);
        unchecked {
            amount -= params.leftoverAmount; // U:[UNI3-4]
        }

        ISwapRouter.ExactInputSingleParams memory paramsUpdate = ISwapRouter.ExactInputSingleParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            fee: params.fee,
            recipient: creditAccount,
            deadline: params.deadline,
            amountIn: amount,
            amountOutMinimum: (amount * params.rateMinRAY) / RAY,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96
        }); // U:[UNI3-4]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            params.tokenIn,
            params.tokenOut,
            abi.encodeCall(ISwapRouter.exactInputSingle, (paramsUpdate)),
            params.leftoverAmount <= 1
        ); // U:[UNI3-4]
    }

    /// @notice Swaps given amount of input token for output token through multiple pools
    /// @param params Swap params, see `ISwapRouter.ExactInputParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    /// @dev `params.path` must have at most 3 hops through allowed pools
    function exactInput(ISwapRouter.ExactInputParams calldata params)
        external
        override
        creditFacadeOnly // U:[UNI3-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[UNI3-5]

        (bool valid, address tokenIn, address tokenOut) = _validatePath(params.path);
        if (!valid) revert InvalidPathException(); // U:[UNI3-5]

        ISwapRouter.ExactInputParams memory paramsUpdate = params; // U:[UNI3-5]
        paramsUpdate.recipient = creditAccount; // U:[UNI3-5]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) =
            _executeSwapSafeApprove(tokenIn, tokenOut, abi.encodeCall(ISwapRouter.exactInput, (paramsUpdate)), false); // U:[UNI3-5]
    }

    /// @notice Swaps all balance of input token for output token through multiple pools, except the specified amount
    /// @param params Swap params, see `ExactDiffInputParams` for details
    /// @dev `params.path` must have at most 3 hops through allowed pools
    function exactDiffInput(ExactDiffInputParams calldata params)
        external
        override
        creditFacadeOnly // U:[UNI3-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[UNI3-6]

        (bool valid, address tokenIn, address tokenOut) = _validatePath(params.path);
        if (!valid) revert InvalidPathException(); // U:[UNI3-6]

        uint256 amount = IERC20(tokenIn).balanceOf(creditAccount); // U:[UNI3-6]
        if (amount <= params.leftoverAmount) return (0, 0);

        unchecked {
            amount -= params.leftoverAmount; // U:[UNI3-6]
        }
        ISwapRouter.ExactInputParams memory paramsUpdate = ISwapRouter.ExactInputParams({
            path: params.path,
            recipient: creditAccount,
            deadline: params.deadline,
            amountIn: amount,
            amountOutMinimum: (amount * params.rateMinRAY) / RAY
        });

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            tokenIn, tokenOut, abi.encodeCall(ISwapRouter.exactInput, (paramsUpdate)), params.leftoverAmount <= 1
        ); // U:[UNI3-6]
    }

    /// @notice Swaps input token for given amount of output token through a single pool
    /// @param params Swap params, see `ISwapRouter.ExactOutputSingleParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params)
        external
        override
        creditFacadeOnly // U:[UNI3-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[UNI3-7]

        ISwapRouter.ExactOutputSingleParams memory paramsUpdate = params; // U:[UNI3-7]
        paramsUpdate.recipient = creditAccount; // U:[UNI3-7]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) = _executeSwapSafeApprove(
            params.tokenIn, params.tokenOut, abi.encodeCall(ISwapRouter.exactOutputSingle, (paramsUpdate)), false
        ); // U:[UNI3-7]
    }

    /// @notice Swaps input token for given amount of output token through multiple pools
    /// @param params Swap params, see `ISwapRouter.ExactOutputParams` for details
    /// @dev `params.recipient` is ignored since it can only be the credit account
    /// @dev `params.path` must have at most 3 hops through allowed pools
    function exactOutput(ISwapRouter.ExactOutputParams calldata params)
        external
        override
        creditFacadeOnly // U:[UNI3-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[UNI3-8]

        (bool valid, address tokenOut, address tokenIn) = _validatePath(params.path);
        if (!valid) revert InvalidPathException(); // U:[UNI3-8]

        ISwapRouter.ExactOutputParams memory paramsUpdate = params; // U:[UNI3-8]
        paramsUpdate.recipient = creditAccount; // U:[UNI3-8]

        // calling `_executeSwap` because we need to check if output token is registered as collateral token in the CM
        (tokensToEnable, tokensToDisable,) =
            _executeSwapSafeApprove(tokenIn, tokenOut, abi.encodeCall(ISwapRouter.exactOutput, (paramsUpdate)), false); // U:[UNI3-8]
    }

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Returns whether the (token0, token1, fee) pool is allowed to be traded through the adapter
    function isPoolAllowed(address token0, address token1, uint24 fee) public view override returns (bool) {
        (token0, token1) = _sortTokens(token0, token1);
        return _poolStatus[token0][token1][fee];
    }

    /// @notice Sets status for a batch of pools
    /// @param pools Array of `UniswapV3PoolStatus` objects
    function setPoolStatusBatch(UniswapV3PoolStatus[] calldata pools)
        external
        override
        configuratorOnly // U:[UNI3-9]
    {
        uint256 len = pools.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                (address token0, address token1) = _sortTokens(pools[i].token0, pools[i].token1);
                _poolStatus[token0][token1][pools[i].fee] = pools[i].allowed; // U:[UNI3-9]
                emit SetPoolStatus(token0, token1, pools[i].fee, pools[i].allowed); // U:[UNI3-9]
            }
        }
    }

    // ------- //
    // HELPERS //
    // ------- //

    /// @dev Performs sanity checks on a swap path, if path is valid also returns input and output tokens
    ///      - Path length must be no more than 4 (i.e., at most 3 hops)
    ///      - Each swap must be through an allowed pool
    function _validatePath(bytes memory path) internal view returns (bool valid, address tokenIn, address tokenOut) {
        uint256 len = path.length;
        if (len != PATH_2_LENGTH && len != PATH_3_LENGTH && len != PATH_4_LENGTH) return (false, tokenIn, tokenOut); // U:[UNI3-10]

        tokenIn = path.toAddress(0); // U:[UNI3-10]
        uint24 fee = path.toUint24(ADDR_SIZE);
        tokenOut = path.toAddress(NEXT_OFFSET); // U:[UNI3-10]
        valid = isPoolAllowed(tokenIn, tokenOut, fee); // U:[UNI3-10]

        if (valid && len > PATH_2_LENGTH) {
            address tokenMid = tokenOut;
            fee = path.toUint24(NEXT_OFFSET + ADDR_SIZE);
            tokenOut = path.toAddress(2 * NEXT_OFFSET); // U:[UNI3-10]
            valid = isPoolAllowed(tokenMid, tokenOut, fee); // U:[UNI3-10]

            if (valid && len > PATH_3_LENGTH) {
                tokenMid = tokenOut;
                fee = path.toUint24(2 * NEXT_OFFSET + ADDR_SIZE);
                tokenOut = path.toAddress(3 * NEXT_OFFSET); // U:[UNI3-10]
                valid = isPoolAllowed(tokenMid, tokenOut, fee); // U:[UNI3-10]
            }
        }
    }

    /// @dev Sorts two token addresses
    function _sortTokens(address token0, address token1) internal pure returns (address, address) {
        if (uint160(token0) < uint160(token1)) {
            return (token0, token1);
        } else {
            return (token1, token0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// Denominations

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 50%
uint16 constant DEFAULT_FEE_INTEREST = 50_00; // 50%

// LIQUIDATION_FEE 1.5%
uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50; // 1.5%

// LIQUIDATION PREMIUM 4%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00; // 4%

// LIQUIDATION_FEE_EXPIRED 2%
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00; // 2%

// LIQUIDATION PREMIUM EXPIRED 2%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00; // 2%

// DEFAULT PROPORTION OF MAX BORROWED PER BLOCK TO MAX BORROWED PER ACCOUNT
uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Leverage decimals - 100 is equal to 2x leverage (100% * collateral amount + 100% * borrowed amount)
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in PERCENTAGE_FACTOR format
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {CallerNotCreditFacadeException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import {ACLTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLTrait.sol";

/// @title Abstract adapter
/// @dev Inheriting adapters MUST use provided internal functions to perform all operations with credit accounts
abstract contract AbstractAdapter is IAdapter, ACLTrait {
    /// @notice Credit manager the adapter is connected to
    address public immutable override creditManager;

    /// @notice Address provider contract
    address public immutable override addressProvider;

    /// @notice Address of the contract the adapter is interacting with
    address public immutable override targetContract;

    /// @notice Constructor
    /// @param _creditManager Credit manager to connect the adapter to
    /// @param _targetContract Address of the adapted contract
    constructor(address _creditManager, address _targetContract)
        ACLTrait(ICreditManagerV3(_creditManager).addressProvider())
        nonZeroAddress(_targetContract)
    {
        creditManager = _creditManager;
        addressProvider = ICreditManagerV3(_creditManager).addressProvider();
        targetContract = _targetContract;
    }

    /// @dev Ensures that caller of the function is credit facade connected to the credit manager
    /// @dev Inheriting adapters MUST use this modifier in all external functions that operate on credit accounts
    modifier creditFacadeOnly() {
        _revertIfCallerNotCreditFacade();
        _;
    }

    /// @dev Ensures that caller is credit facade connected to the credit manager
    function _revertIfCallerNotCreditFacade() internal view {
        if (msg.sender != ICreditManagerV3(creditManager).creditFacade()) {
            revert CallerNotCreditFacadeException();
        }
    }

    /// @dev Ensures that active credit account is set and returns its address
    function _creditAccount() internal view returns (address) {
        return ICreditManagerV3(creditManager).getActiveCreditAccountOrRevert();
    }

    /// @dev Ensures that token is registered as collateral in the credit manager and returns its mask
    function _getMaskOrRevert(address token) internal view returns (uint256 tokenMask) {
        tokenMask = ICreditManagerV3(creditManager).getTokenMaskOrRevert(token);
    }

    /// @dev Approves target contract to spend given token from the active credit account
    ///      Reverts if active credit account is not set or token is not registered as collateral
    /// @param token Token to approve
    /// @param amount Amount to approve
    function _approveToken(address token, uint256 amount) internal {
        ICreditManagerV3(creditManager).approveCreditAccount(token, amount);
    }

    /// @dev Executes an external call from the active credit account to the target contract
    ///      Reverts if active credit account is not set
    /// @param callData Data to call the target contract with
    /// @return result Call result
    function _execute(bytes memory callData) internal returns (bytes memory result) {
        return ICreditManagerV3(creditManager).execute(callData);
    }

    /// @dev Executes a swap operation without input token approval
    ///      Reverts if active credit account is not set or any of passed tokens is not registered as collateral
    /// @param tokenIn Input token that credit account spends in the call
    /// @param tokenOut Output token that credit account receives after the call
    /// @param callData Data to call the target contract with
    /// @param disableTokenIn Whether `tokenIn` should be disabled after the call
    ///        (for operations that spend the entire account's balance of the input token)
    /// @return tokensToEnable Bit mask of tokens that should be enabled after the call
    /// @return tokensToDisable Bit mask of tokens that should be disabled after the call
    /// @return result Call result
    function _executeSwapNoApprove(address tokenIn, address tokenOut, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable, bytes memory result)
    {
        tokensToEnable = _getMaskOrRevert(tokenOut);
        uint256 tokenInMask = _getMaskOrRevert(tokenIn);
        if (disableTokenIn) tokensToDisable = tokenInMask;
        result = _execute(callData);
    }

    /// @dev Executes a swap operation with maximum input token approval, and revokes approval after the call
    ///      Reverts if active credit account is not set or any of passed tokens is not registered as collateral
    /// @param tokenIn Input token that credit account spends in the call
    /// @param tokenOut Output token that credit account receives after the call
    /// @param callData Data to call the target contract with
    /// @param disableTokenIn Whether `tokenIn` should be disabled after the call
    ///        (for operations that spend the entire account's balance of the input token)
    /// @return tokensToEnable Bit mask of tokens that should be enabled after the call
    /// @return tokensToDisable Bit mask of tokens that should be disabled after the call
    /// @return result Call result
    /// @custom:expects Credit manager reverts when trying to approve non-collateral token
    function _executeSwapSafeApprove(address tokenIn, address tokenOut, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable, bytes memory result)
    {
        tokensToEnable = _getMaskOrRevert(tokenOut);
        if (disableTokenIn) tokensToDisable = _getMaskOrRevert(tokenIn);
        _approveToken(tokenIn, type(uint256).max);
        result = _execute(callData);
        _approveToken(tokenIn, 1);
    }
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum AdapterType {
    ABSTRACT,
    UNISWAP_V2_ROUTER,
    UNISWAP_V3_ROUTER,
    CURVE_V1_EXCHANGE_ONLY,
    YEARN_V2,
    CURVE_V1_2ASSETS,
    CURVE_V1_3ASSETS,
    CURVE_V1_4ASSETS,
    CURVE_V1_STECRV_POOL,
    CURVE_V1_WRAPPER,
    CONVEX_V1_BASE_REWARD_POOL,
    CONVEX_V1_BOOSTER,
    CONVEX_V1_CLAIM_ZAP,
    LIDO_V1,
    UNIVERSAL,
    LIDO_WSTETH_V1,
    BALANCER_VAULT,
    AAVE_V2_LENDING_POOL,
    AAVE_V2_WRAPPED_ATOKEN,
    COMPOUND_V2_CERC20,
    COMPOUND_V2_CETHER,
    ERC4626_VAULT,
    VELODROME_V2_ROUTER,
    CURVE_STABLE_NG,
    CAMELOT_V3_ROUTER,
    CONVEX_L2_BOOSTER,
    CONVEX_L2_REWARD_POOL,
    AAVE_V3_LENDING_POOL
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.5;
pragma abicoder v2;

interface ISwapRouter {
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

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

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

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, "toUint24_overflow");
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for { let cc := add(_postBytes, 0x20) } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } { mstore(mc, mload(cc)) }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } { mstore(mc, mload(cc)) }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";

import {ISwapRouter} from "../../integrations/uniswap/IUniswapV3.sol";

struct UniswapV3PoolStatus {
    address token0;
    address token1;
    uint24 fee;
    bool allowed;
}

interface IUniswapV3AdapterTypes {
    /// @notice Params for exact diff input swap through a single pool
    /// @param tokenIn Input token
    /// @param tokenOut Output token
    /// @param fee Fee level of the pool to swap through
    /// @param deadline Maximum timestamp until which the transaction is valid
    /// @param leftoverAmount Amount of tokenIn to keep on the account
    /// @param rateMinRAY Minimum exchange rate between input and output tokens, scaled by 1e27
    /// @param sqrtPriceLimitX96 Maximum execution price, ignored if 0
    struct ExactDiffInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        uint256 deadline;
        uint256 leftoverAmount;
        uint256 rateMinRAY;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Params for exact diff input swap through multiple pools
    /// @param path Bytes-encoded swap path, see Uniswap docs for details
    /// @param deadline Maximum timestamp until which the transaction is valid
    /// @param leftoverAmount Amount of tokenIn to keep on the account
    /// @param rateMinRAY Minimum exchange rate between input and output tokens, scaled by 1e27
    struct ExactDiffInputParams {
        bytes path;
        uint256 deadline;
        uint256 leftoverAmount;
        uint256 rateMinRAY;
    }
}

interface IUniswapV3AdapterEvents {
    /// @notice Emitted when new status is set for a pool
    event SetPoolStatus(address indexed token0, address indexed token1, uint24 indexed fee, bool allowed);
}

interface IUniswapV3AdapterExceptions {
    /// @notice Thrown when sanity checks on a swap path fail
    error InvalidPathException();
}

/// @title Uniswap V3 Router adapter interface
interface IUniswapV3Adapter is
    IAdapter,
    IUniswapV3AdapterTypes,
    IUniswapV3AdapterEvents,
    IUniswapV3AdapterExceptions
{
    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exactDiffInputSingle(ExactDiffInputSingleParams calldata params)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exactInput(ISwapRouter.ExactInputParams calldata params)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exactDiffInput(ExactDiffInputParams calldata params)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exactOutputSingle(ISwapRouter.ExactOutputSingleParams calldata params)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exactOutput(ISwapRouter.ExactOutputParams calldata params)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function isPoolAllowed(address token0, address token1, uint24 fee) external view returns (bool);

    function setPoolStatusBatch(UniswapV3PoolStatus[] calldata pools) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.0;

import { AdapterType } from "@gearbox-protocol/sdk-gov/contracts/AdapterType.sol";

/// @title Adapter interface
interface IAdapter {
    function _gearboxAdapterType() external view returns (AdapterType);

    function _gearboxAdapterVersion() external view returns (uint16);

    function creditManager() external view returns (address);

    function addressProvider() external view returns (address);

    function targetContract() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint8 constant BOT_PERMISSIONS_SET_FLAG = 1;

uint8 constant DEFAULT_MAX_ENABLED_TOKENS = 4;
address constant INACTIVE_CREDIT_ACCOUNT_ADDRESS = address(1);

/// @notice Debt management type
///         - `INCREASE_DEBT` borrows additional funds from the pool, updates account's debt and cumulative interest index
///         - `DECREASE_DEBT` repays debt components (quota interest and fees -> base interest and fees -> debt principal)
///           and updates all corresponding state varibles (base interest index, quota interest and fees, debt).
///           When repaying all the debt, ensures that account has no enabled quotas.
enum ManageDebtAction {
    INCREASE_DEBT,
    DECREASE_DEBT
}

/// @notice Collateral/debt calculation mode
///         - `GENERIC_PARAMS` returns generic data like account debt and cumulative indexes
///         - `DEBT_ONLY` is same as `GENERIC_PARAMS` but includes more detailed debt info, like accrued base/quota
///           interest and fees
///         - `FULL_COLLATERAL_CHECK_LAZY` checks whether account is sufficiently collateralized in a lazy fashion,
///           i.e. it stops iterating over collateral tokens once TWV reaches the desired target.
///           Since it may return underestimated TWV, it's only available for internal use.
///         - `DEBT_COLLATERAL` is same as `DEBT_ONLY` but also returns total value and total LT-weighted value of
///           account's tokens, this mode is used during account liquidation
///         - `DEBT_COLLATERAL_SAFE_PRICES` is same as `DEBT_COLLATERAL` but uses safe prices from price oracle
enum CollateralCalcTask {
    GENERIC_PARAMS,
    DEBT_ONLY,
    FULL_COLLATERAL_CHECK_LAZY,
    DEBT_COLLATERAL,
    DEBT_COLLATERAL_SAFE_PRICES
}

struct CreditAccountInfo {
    uint256 debt;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint128 quotaFees;
    uint256 enabledTokensMask;
    uint16 flags;
    uint64 lastDebtUpdate;
    address borrower;
}

struct CollateralDebtData {
    uint256 debt;
    uint256 cumulativeIndexNow;
    uint256 cumulativeIndexLastUpdate;
    uint128 cumulativeQuotaInterest;
    uint256 accruedInterest;
    uint256 accruedFees;
    uint256 totalDebtUSD;
    uint256 totalValue;
    uint256 totalValueUSD;
    uint256 twvUSD;
    uint256 enabledTokensMask;
    uint256 quotedTokensMask;
    address[] quotedTokens;
    address _poolQuotaKeeper;
}

struct CollateralTokenData {
    address token;
    uint16 ltInitial;
    uint16 ltFinal;
    uint40 timestampRampStart;
    uint24 rampDuration;
}

struct RevocationPair {
    address spender;
    address token;
}

interface ICreditManagerV3Events {
    /// @notice Emitted when new credit configurator is set
    event SetCreditConfigurator(address indexed newConfigurator);
}

/// @title Credit manager V3 interface
interface ICreditManagerV3 is IVersion, ICreditManagerV3Events {
    function pool() external view returns (address);

    function underlying() external view returns (address);

    function creditFacade() external view returns (address);

    function creditConfigurator() external view returns (address);

    function addressProvider() external view returns (address);

    function accountFactory() external view returns (address);

    function name() external view returns (string memory);

    // ------------------ //
    // ACCOUNT MANAGEMENT //
    // ------------------ //

    function openCreditAccount(address onBehalfOf) external returns (address);

    function closeCreditAccount(address creditAccount) external;

    function liquidateCreditAccount(
        address creditAccount,
        CollateralDebtData calldata collateralDebtData,
        address to,
        bool isExpired
    ) external returns (uint256 remainingFunds, uint256 loss);

    function manageDebt(address creditAccount, uint256 amount, uint256 enabledTokensMask, ManageDebtAction action)
        external
        returns (uint256 newDebt, uint256 tokensToEnable, uint256 tokensToDisable);

    function addCollateral(address payer, address creditAccount, address token, uint256 amount)
        external
        returns (uint256 tokensToEnable);

    function withdrawCollateral(address creditAccount, address token, uint256 amount, address to)
        external
        returns (uint256 tokensToDisable);

    function externalCall(address creditAccount, address target, bytes calldata callData)
        external
        returns (bytes memory result);

    function approveToken(address creditAccount, address token, address spender, uint256 amount) external;

    function revokeAdapterAllowances(address creditAccount, RevocationPair[] calldata revocations) external;

    // -------- //
    // ADAPTERS //
    // -------- //

    function adapterToContract(address adapter) external view returns (address targetContract);

    function contractToAdapter(address targetContract) external view returns (address adapter);

    function execute(bytes calldata data) external returns (bytes memory result);

    function approveCreditAccount(address token, uint256 amount) external;

    function setActiveCreditAccount(address creditAccount) external;

    function getActiveCreditAccountOrRevert() external view returns (address creditAccount);

    // ----------------- //
    // COLLATERAL CHECKS //
    // ----------------- //

    function priceOracle() external view returns (address);

    function fullCollateralCheck(
        address creditAccount,
        uint256 enabledTokensMask,
        uint256[] calldata collateralHints,
        uint16 minHealthFactor,
        bool useSafePrices
    ) external returns (uint256 enabledTokensMaskAfter);

    function isLiquidatable(address creditAccount, uint16 minHealthFactor) external view returns (bool);

    function calcDebtAndCollateral(address creditAccount, CollateralCalcTask task)
        external
        view
        returns (CollateralDebtData memory cdd);

    // ------ //
    // QUOTAS //
    // ------ //

    function poolQuotaKeeper() external view returns (address);

    function quotedTokensMask() external view returns (uint256);

    function updateQuota(address creditAccount, address token, int96 quotaChange, uint96 minQuota, uint96 maxQuota)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // --------------------- //
    // CREDIT MANAGER PARAMS //
    // --------------------- //

    function maxEnabledTokens() external view returns (uint8);

    function fees()
        external
        view
        returns (
            uint16 feeInterest,
            uint16 feeLiquidation,
            uint16 liquidationDiscount,
            uint16 feeLiquidationExpired,
            uint16 liquidationDiscountExpired
        );

    function collateralTokensCount() external view returns (uint8);

    function getTokenMaskOrRevert(address token) external view returns (uint256 tokenMask);

    function getTokenByMask(uint256 tokenMask) external view returns (address token);

    function liquidationThresholds(address token) external view returns (uint16 lt);

    function ltParams(address token)
        external
        view
        returns (uint16 ltInitial, uint16 ltFinal, uint40 timestampRampStart, uint24 rampDuration);

    function collateralTokenByMask(uint256 tokenMask)
        external
        view
        returns (address token, uint16 liquidationThreshold);

    // ------------ //
    // ACCOUNT INFO //
    // ------------ //

    function creditAccountInfo(address creditAccount)
        external
        view
        returns (
            uint256 debt,
            uint256 cumulativeIndexLastUpdate,
            uint128 cumulativeQuotaInterest,
            uint128 quotaFees,
            uint256 enabledTokensMask,
            uint16 flags,
            uint64 lastDebtUpdate,
            address borrower
        );

    function getBorrowerOrRevert(address creditAccount) external view returns (address borrower);

    function flagsOf(address creditAccount) external view returns (uint16);

    function setFlagFor(address creditAccount, uint16 flag, bool value) external;

    function enabledTokensMaskOf(address creditAccount) external view returns (uint256);

    function creditAccounts() external view returns (address[] memory);

    function creditAccounts(uint256 offset, uint256 limit) external view returns (address[] memory);

    function creditAccountsLen() external view returns (uint256);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function addToken(address token) external;

    function setCollateralTokenData(
        address token,
        uint16 ltInitial,
        uint16 ltFinal,
        uint40 timestampRampStart,
        uint24 rampDuration
    ) external;

    function setFees(
        uint16 feeInterest,
        uint16 feeLiquidation,
        uint16 liquidationDiscount,
        uint16 feeLiquidationExpired,
        uint16 liquidationDiscountExpired
    ) external;

    function setQuotedMask(uint256 quotedTokensMask) external;

    function setMaxEnabledTokens(uint8 maxEnabledTokens) external;

    function setContractAllowance(address adapter, address targetContract) external;

    function setCreditFacade(address creditFacade) external;

    function setPriceOracle(address priceOracle) external;

    function setCreditConfigurator(address creditConfigurator) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IACL} from "@gearbox-protocol/core-v2/contracts/interfaces/IACL.sol";

import {AP_ACL, IAddressProviderV3, NO_VERSION_CONTROL} from "../interfaces/IAddressProviderV3.sol";
import {CallerNotConfiguratorException} from "../interfaces/IExceptions.sol";

import {SanityCheckTrait} from "./SanityCheckTrait.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is SanityCheckTrait {
    /// @notice ACL contract address
    address public immutable acl;

    /// @notice Constructor
    /// @param addressProvider Address provider contract address
    constructor(address addressProvider) nonZeroAddress(addressProvider) {
        acl = IAddressProviderV3(addressProvider).getAddressOrRevert(AP_ACL, NO_VERSION_CONTROL);
    }

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator({account: msg.sender})) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;
import { IVersion } from "./IVersion.sol";

interface IACLExceptions {
    /// @dev Thrown when attempting to delete an address from a set that is not a pausable admin
    error AddressNotPausableAdminException(address addr);

    /// @dev Thrown when attempting to delete an address from a set that is not a unpausable admin
    error AddressNotUnpausableAdminException(address addr);
}

interface IACLEvents {
    /// @dev Emits when a new admin is added that can pause contracts
    event PausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when a Pausable admin is removed
    event PausableAdminRemoved(address indexed admin);

    /// @dev Emits when a new admin is added that can unpause contracts
    event UnpausableAdminAdded(address indexed newAdmin);

    /// @dev Emits when an Unpausable admin is removed
    event UnpausableAdminRemoved(address indexed admin);
}

/// @title ACL interface
interface IACL is IACLEvents, IACLExceptions, IVersion {
    /// @dev Returns true if the address is a pausable admin and false if not
    /// @param addr Address to check
    function isPausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if the address is unpausable admin and false if not
    /// @param addr Address to check
    function isUnpausableAdmin(address addr) external view returns (bool);

    /// @dev Returns true if an address has configurator rights
    /// @param account Address to check
    function isConfigurator(address account) external view returns (bool);

    /// @dev Returns address of configurator
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

uint256 constant NO_VERSION_CONTROL = 0;

bytes32 constant AP_CONTRACTS_REGISTER = "CONTRACTS_REGISTER";
bytes32 constant AP_ACL = "ACL";
bytes32 constant AP_PRICE_ORACLE = "PRICE_ORACLE";
bytes32 constant AP_ACCOUNT_FACTORY = "ACCOUNT_FACTORY";
bytes32 constant AP_DATA_COMPRESSOR = "DATA_COMPRESSOR";
bytes32 constant AP_TREASURY = "TREASURY";
bytes32 constant AP_GEAR_TOKEN = "GEAR_TOKEN";
bytes32 constant AP_WETH_TOKEN = "WETH_TOKEN";
bytes32 constant AP_WETH_GATEWAY = "WETH_GATEWAY";
bytes32 constant AP_ROUTER = "ROUTER";
bytes32 constant AP_BOT_LIST = "BOT_LIST";
bytes32 constant AP_GEAR_STAKING = "GEAR_STAKING";
bytes32 constant AP_ZAPPER_REGISTER = "ZAPPER_REGISTER";

interface IAddressProviderV3Events {
    /// @notice Emitted when an address is set for a contract key
    event SetAddress(bytes32 indexed key, address indexed value, uint256 indexed version);
}

/// @title Address provider V3 interface
interface IAddressProviderV3 is IAddressProviderV3Events, IVersion {
    function addresses(bytes32 key, uint256 _version) external view returns (address);

    function getAddressOrRevert(bytes32 key, uint256 _version) external view returns (address result);

    function setAddress(bytes32 key, address value, bool saveVersion) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}