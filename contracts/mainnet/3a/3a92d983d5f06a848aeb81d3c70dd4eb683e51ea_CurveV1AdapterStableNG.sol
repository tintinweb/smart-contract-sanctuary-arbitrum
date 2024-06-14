// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {AdapterType} from "@gearbox-protocol/sdk-gov/contracts/AdapterType.sol";
import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";

import {ICurvePoolStableNG} from "../../integrations/curve/ICurvePool_StableNG.sol";
import {ICurveV1_StableNGAdapter} from "../../interfaces/curve/ICurveV1_StableNGAdapter.sol";
import {CurveV1AdapterBase} from "./CurveV1_Base.sol";

/// @title Curve Stable NG adapter
/// @notice Implements logic allowing to interact with Curve StableNG pools
contract CurveV1AdapterStableNG is CurveV1AdapterBase, ICurveV1_StableNGAdapter {
    function _gearboxAdapterType() external pure virtual override returns (AdapterType) {
        return AdapterType.CURVE_STABLE_NG;
    }

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _curvePool Target Curve pool address
    /// @param _lp_token Pool LP token address
    /// @param _metapoolBase Base pool address (for metapools only) or zero address
    constructor(address _creditManager, address _curvePool, address _lp_token, address _metapoolBase)
        CurveV1AdapterBase(_creditManager, _curvePool, _lp_token, _metapoolBase, ICurvePoolStableNG(_curvePool).N_COINS())
    {}

    /// @notice Add liquidity to the pool
    /// @param amounts Amounts of tokens to add
    /// @dev `min_mint_amount` parameter is ignored because calldata is passed directly to the target contract
    function add_liquidity(uint256[] calldata amounts, uint256)
        external
        override
        creditFacadeOnly
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        uint256 len = amounts.length;
        (tokensToEnable, tokensToDisable) =
            _add_liquidity(amounts[0] > 1, amounts[1] > 1, len > 2 && amounts[2] > 1, len > 3 && amounts[3] > 1);
    }

    /// @dev Returns calldata for adding liquidity in coin `i`
    function _getAddLiquidityOneCoinCallData(uint256 i, uint256 amount, uint256 minAmount)
        internal
        view
        override
        returns (bytes memory)
    {
        uint256[] memory amounts = new uint256[](nCoins);
        amounts[i] = amount;
        return abi.encodeCall(ICurvePoolStableNG.add_liquidity, (amounts, minAmount));
    }

    /// @dev Returns calldata for calculating the result of adding liquidity in coin `i`
    function _getCalcAddOneCoinCallData(uint256 i, uint256 amount)
        internal
        view
        override
        returns (bytes memory, bytes memory)
    {
        uint256[] memory amounts = new uint256[](nCoins);
        amounts[i] = amount;
        return (
            abi.encodeCall(ICurvePoolStableNG.calc_token_amount, (amounts, true)),
            abi.encodeWithSignature("calc_token_amount(uint256[])", amounts)
        );
    }

    /// @notice Remove liquidity from the pool
    /// @dev '_amount' and 'min_amounts' parameters are ignored because calldata is directly passed to the target contract
    function remove_liquidity(uint256, uint256[] calldata)
        external
        virtual
        creditFacadeOnly
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) = _remove_liquidity();
    }

    /// @notice Withdraw exact amounts of tokens from the pool
    /// @param amounts Amounts of tokens to withdraw
    /// @dev `max_burn_amount` parameter is ignored because calldata is directly passed to the target contract
    function remove_liquidity_imbalance(uint256[] calldata amounts, uint256)
        external
        virtual
        override
        creditFacadeOnly
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        uint256 len = amounts.length;
        (tokensToEnable, tokensToDisable) = _remove_liquidity_imbalance(
            amounts[0] > 1, amounts[1] > 1, len > 2 && amounts[2] > 1, len > 3 && amounts[3] > 1
        );
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ICurvePool} from "./ICurvePool.sol";

/// @title ICurvePoolStableNG
/// @dev Extends original pool contract with liquidity functions
interface ICurvePoolStableNG is ICurvePool {
    function add_liquidity(uint256[] memory amounts, uint256 min_mint_amount) external;

    function remove_liquidity(uint256 _amount, uint256[] memory min_amounts) external;

    function remove_liquidity_imbalance(uint256[] calldata amounts, uint256 max_burn_amount) external;

    function calc_token_amount(uint256[] calldata _amounts, bool _is_deposit) external view returns (uint256);

    function get_balances() external view returns (uint256[] memory);

    function N_COINS() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {ICurveV1Adapter} from "./ICurveV1Adapter.sol";

/// @title Adapter for Curve stable pools with dynamic arrays
interface ICurveV1_StableNGAdapter is ICurveV1Adapter {
    function add_liquidity(uint256[] calldata amounts, uint256)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function remove_liquidity(uint256, uint256[] calldata)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function remove_liquidity_imbalance(uint256[] calldata amounts, uint256)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RAY} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import {BitMask} from "@gearbox-protocol/core-v3/contracts/libraries/BitMask.sol";
import {IncorrectParameterException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {ICurvePool} from "../../integrations/curve/ICurvePool.sol";
import {ICurveV1Adapter} from "../../interfaces/curve/ICurveV1Adapter.sol";
import {AbstractAdapter} from "../AbstractAdapter.sol";

/// @title Curve adapter base
/// @notice Implements logic allowing credit accounts to interact with Curve pools with arbitrary number of coins,
///         supporting stable/crypto plain/meta/lending pools of different versions
abstract contract CurveV1AdapterBase is AbstractAdapter, ICurveV1Adapter {
    using BitMask for uint256;

    uint16 public constant override _gearboxAdapterVersion = 3_00;

    /// @notice Pool LP token address (added for backward compatibility)
    address public immutable override token;

    /// @notice Pool LP token address
    address public immutable override lp_token;

    /// @notice Collateral token mask of pool LP token in the credit manager
    uint256 public immutable override lpTokenMask;

    /// @notice Base pool address (for metapools only)
    address public immutable override metapoolBase;

    /// @notice Number of coins in the pool
    uint256 public immutable override nCoins;

    /// @notice Whether pool is cryptoswap or stableswap
    bool public immutable override use256;

    address public immutable override token0;
    address public immutable override token1;
    address public immutable override token2;
    address public immutable override token3;

    uint256 public immutable override token0Mask;
    uint256 public immutable override token1Mask;
    uint256 public immutable override token2Mask;
    uint256 public immutable override token3Mask;

    address public immutable override underlying0;
    address public immutable override underlying1;
    address public immutable override underlying2;
    address public immutable override underlying3;

    uint256 public immutable override underlying0Mask;
    uint256 public immutable override underlying1Mask;
    uint256 public immutable override underlying2Mask;
    uint256 public immutable override underlying3Mask;

    /// @notice Constructor
    /// @param _creditManager Credit manager address
    /// @param _curvePool Target Curve pool address
    /// @param _lp_token Pool LP token address
    /// @param _metapoolBase Metapool's base pool address (must have 2 or 3 coins) or zero address
    /// @param _nCoins Number of coins in the pool
    constructor(address _creditManager, address _curvePool, address _lp_token, address _metapoolBase, uint256 _nCoins)
        AbstractAdapter(_creditManager, _curvePool) // U:[CRVB-1]
        nonZeroAddress(_lp_token) // U:[CRVB-1]
    {
        lpTokenMask = _getMaskOrRevert(_lp_token); // U:[CRVB-1]

        token = _lp_token; // U:[CRVB-1]
        lp_token = _lp_token; // U:[CRVB-1]
        metapoolBase = _metapoolBase; // U:[CRVB-1]
        nCoins = _nCoins; // U:[CRVB-1]
        use256 = _use256();

        address[4] memory tokens;
        uint256[4] memory tokenMasks;
        unchecked {
            for (uint256 i; i < nCoins; ++i) {
                tokens[i] = _getCoin(_curvePool, i); // U:[CRVB-1]
                if (tokens[i] == address(0)) revert IncorrectParameterException(); // U:[CRVB-1]
                tokenMasks[i] = _getMaskOrRevert(tokens[i]); // U:[CRVB-1]
            }
        }

        token0 = tokens[0];
        token1 = tokens[1];
        token2 = tokens[2];
        token3 = tokens[3];

        token0Mask = tokenMasks[0];
        token1Mask = tokenMasks[1];
        token2Mask = tokenMasks[2];
        token3Mask = tokenMasks[3];

        // underlying tokens (only relevant for meta and lending pools)
        address[4] memory underlyings;
        uint256[4] memory underlyingMasks;
        unchecked {
            for (uint256 i; i < 4; ++i) {
                if (_metapoolBase != address(0)) {
                    underlyings[i] = i == 0 ? token0 : _getCoin(_metapoolBase, i - 1); // U:[CRVB-1]
                } else {
                    // some pools are proxy contracts and return empty data when there is no function with given signature,
                    // which later results in revert when trying to decode the result, so low-level call is used instead
                    (bool success, bytes memory returnData) = _callWithAlternative(
                        abi.encodeWithSignature("underlying_coins(uint256)", i),
                        abi.encodeWithSignature("underlying_coins(int128)", i)
                    ); // U:[CRVB-1]
                    if (success && returnData.length > 0) underlyings[i] = abi.decode(returnData, (address));
                    else break;
                }

                if (underlyings[i] != address(0)) underlyingMasks[i] = _getMaskOrRevert(underlyings[i]); // U:[CRVB-1]
            }
        }

        underlying0 = underlyings[0];
        underlying1 = underlyings[1];
        underlying2 = underlyings[2];
        underlying3 = underlyings[3];

        underlying0Mask = underlyingMasks[0];
        underlying1Mask = underlyingMasks[1];
        underlying2Mask = underlyingMasks[2];
        underlying3Mask = underlyingMasks[3];
    }

    // -------- //
    // EXCHANGE //
    // -------- //

    /// @notice Exchanges one pool asset to another
    /// @param i Index of the asset to spend
    /// @param j Index of the asset to receive
    /// @param dx Amount of asset i to spend
    /// @param min_dy Minimum amount of asset j to receive
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        return _exchange(i, j, dx, min_dy); // U:[CRVB-3]
    }

    /// @dev Same as the previous one but accepts coin indexes as `int128`
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        return _exchange(_toU256(i), _toU256(j), dx, min_dy); // U:[CRVB-3]
    }

    /// @dev Implementation of both versions of `exchange`
    function _exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) = _exchange_impl(i, j, _getExchangeCallData(i, j, dx, min_dy), false); // U:[CRVB-3]
    }

    /// @notice Exchanges the entire balance of one pool asset to another, except the specified amount
    /// @param i Index of the asset to spend
    /// @param j Index of the asset to receive
    /// @param leftoverAmount Amount of input asset to keep on the account
    /// @param rateMinRAY Minimum exchange rate between assets i and j, scaled by 1e27
    function exchange_diff(uint256 i, uint256 j, uint256 leftoverAmount, uint256 rateMinRAY)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[CRVB-4]

        address tokenIn = _get_token(i); // U:[CRVB-4]
        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); // U:[CRVB-4]
        if (dx <= leftoverAmount) return (0, 0);

        unchecked {
            dx -= leftoverAmount; // U:[CRVB-4]
        }
        uint256 min_dy = (dx * rateMinRAY) / RAY; // U:[CRVB-4]
        (tokensToEnable, tokensToDisable) =
            _exchange_impl(i, j, _getExchangeCallData(i, j, dx, min_dy), leftoverAmount <= 1); // U:[CRVB-4]
    }

    /// @dev Internal implementation of `exchange` and `exchange_diff`
    ///      - passes calldata to the target contract
    ///      - sets max approval for the input token before the call and resets it to 1 after
    ///      - enables output asset after the call
    ///      - disables input asset only when exchanging the entire balance
    function _exchange_impl(uint256 i, uint256 j, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        _approveToken(_get_token(i), type(uint256).max); // U:[CRVB-3,4]
        _execute(callData); // U:[CRVB-3,4]
        _approveToken(_get_token(i), 1); // U:[CRVB-3,4]
        (tokensToEnable, tokensToDisable) = (_get_token_mask(j), disableTokenIn ? _get_token_mask(i) : 0); // U:[CRVB-3,4]
    }

    /// @dev Returns calldata for `exchange` and `exchange_diff` calls
    function _getExchangeCallData(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        internal
        view
        returns (bytes memory)
    {
        return use256
            ? abi.encodeWithSignature("exchange(uint256,uint256,uint256,uint256)", i, j, dx, min_dy)
            : abi.encodeWithSignature("exchange(int128,int128,uint256,uint256)", i, j, dx, min_dy); // U:[CRVB-3,4]
    }

    /// @notice Exchanges one pool's underlying asset to another
    /// @param i Index of the underlying asset to spend
    /// @param j Index of the underlying asset to receive
    /// @param dx Amount of underlying asset i to spend
    /// @param min_dy Minimum amount of underlying asset j to receive
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        return _exchange_underlying(i, j, dx, min_dy); // U:[CRVB-5]
    }

    /// @dev Same as the previous one but accepts coin indexes as `int128`
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        return _exchange_underlying(_toU256(i), _toU256(j), dx, min_dy); // U:[CRVB-5]
    }

    /// @dev Implementation of both versions of `exchange_underlying`
    function _exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) =
            _exchange_underlying_impl(i, j, _getExchangeUnderlyingCallData(i, j, dx, min_dy), false); // U:[CRVB-5]
    }

    /// @notice Exchanges the entire balance of one pool's underlying asset to another, except the specified amount
    /// @param i Index of the underlying asset to spend
    /// @param j Index of the underlying asset to receive
    /// @param rateMinRAY Minimum exchange rate between underlying assets i and j, scaled by 1e27
    function exchange_diff_underlying(uint256 i, uint256 j, uint256 leftoverAmount, uint256 rateMinRAY)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[CRVB-6]

        address tokenIn = _get_underlying(i); // U:[CRVB-6]
        uint256 dx = IERC20(tokenIn).balanceOf(creditAccount); // U:[CRVB-6]
        if (dx <= leftoverAmount) return (0, 0);

        unchecked {
            dx -= leftoverAmount; // U:[CRVB-6]
        }
        uint256 min_dy = (dx * rateMinRAY) / RAY; // U:[CRVB-6]
        (tokensToEnable, tokensToDisable) =
            _exchange_underlying_impl(i, j, _getExchangeUnderlyingCallData(i, j, dx, min_dy), leftoverAmount <= 1); // U:[CRVB-6]
    }

    /// @dev Internal implementation of `exchange_underlying` and `exchange_diff_underlying`
    ///      - passes calldata to the target contract
    ///      - sets max approval for the input token before the call and resets it to 1 after
    ///      - enables output asset after the call
    ///      - disables input asset only when exchanging the entire balance
    function _exchange_underlying_impl(uint256 i, uint256 j, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        _approveToken(_get_underlying(i), type(uint256).max); // U:[CRVB-5,6]
        _execute(callData); // U:[CRVB-5,6]
        _approveToken(_get_underlying(i), 1); // U:[CRVB-5,6]
        (tokensToEnable, tokensToDisable) = (_get_underlying_mask(j), disableTokenIn ? _get_underlying_mask(i) : 0); // U:[CRVB-5,6]
    }

    /// @dev Returns calldata for `exchange_underlying` and `exchange_diff_underlying` calls
    function _getExchangeUnderlyingCallData(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        internal
        view
        returns (bytes memory)
    {
        return use256
            ? abi.encodeWithSignature("exchange_underlying(uint256,uint256,uint256,uint256)", i, j, dx, min_dy)
            : abi.encodeWithSignature("exchange_underlying(int128,int128,uint256,uint256)", i, j, dx, min_dy); // U:[CRVB-5,6]
    }

    // ------------- //
    // ADD LIQUIDITY //
    // ------------- //

    /// @dev Internal implementation of `add_liquidity`
    ///      - passes calldata to the target contract
    ///      - sets max approvals for the specified tokens before the call and resets them to 1 after
    ///      - enables LP token
    function _add_liquidity(bool t0Approve, bool t1Approve, bool t2Approve, bool t3Approve)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        _approveTokens(t0Approve, t1Approve, t2Approve, t3Approve, type(uint256).max); // U:[CRV2-2, CRV3-2, CRV4-2]
        _execute(msg.data); // U:[CRV2-2, CRV3-2, CRV4-2]
        _approveTokens(t0Approve, t1Approve, t2Approve, t3Approve, 1); // U:[CRV2-2, CRV3-2, CRV4-2]
        (tokensToEnable, tokensToDisable) = (lpTokenMask, 0); // U:[CRV2-2, CRV3-2, CRV4-2]
    }

    /// @notice Adds given amount of asset as liquidity to the pool
    /// @param amount Amount to deposit
    /// @param i Index of the asset to deposit
    /// @param minAmount Minimum amount of LP tokens to receive
    function add_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) =
            _add_liquidity_one_coin_impl(i, _getAddLiquidityOneCoinCallData(i, amount, minAmount), false); // U:[CRVB-7]
    }

    /// @notice Adds the entire balance of asset as liquidity to the pool, except the specified amount
    /// @param leftoverAmount Amount of underlying to keep on the account
    /// @param i Index of the asset to deposit
    /// @param rateMinRAY Minimum exchange rate between deposited asset and LP token, scaled by 1e27
    function add_diff_liquidity_one_coin(uint256 leftoverAmount, uint256 i, uint256 rateMinRAY)
        external
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[CRVB-8]

        address tokenIn = _get_token(i); // U:[CRVB-8]
        uint256 amount = IERC20(tokenIn).balanceOf(creditAccount); // U:[CRVB-8]
        if (amount <= leftoverAmount) return (0, 0);

        unchecked {
            amount -= leftoverAmount; // U:[CRVB-8]
        }
        uint256 minAmount = (amount * rateMinRAY) / RAY; // U:[CRVB-8]
        (tokensToEnable, tokensToDisable) =
            _add_liquidity_one_coin_impl(i, _getAddLiquidityOneCoinCallData(i, amount, minAmount), leftoverAmount <= 1); // U:[CRVB-8]
    }

    /// @dev Internal implementation of `add_liquidity_one_coin' and `add_diff_liquidity_one_coin`
    ///      - passes calldata to the target contract
    ///      - sets max approval for the input token before the call and resets it to 1 after
    ///      - enables LP token
    ///      - disables input token only when adding the entire balance
    function _add_liquidity_one_coin_impl(uint256 i, bytes memory callData, bool disableTokenIn)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        _approveToken(_get_token(i), type(uint256).max); // U:[CRVB-7,8]
        _execute(callData); // U:[CRVB-7,8]
        _approveToken(_get_token(i), 1); // U:[CRVB-7,8]
        (tokensToEnable, tokensToDisable) = (lpTokenMask, disableTokenIn ? _get_token_mask(i) : 0); // U:[CRVB-7,8]
    }

    /// @notice Returns the amount of LP token received for adding a single asset to the pool
    /// @param amount Amount to deposit
    /// @param i Index of the asset to deposit
    function calc_add_one_coin(uint256 amount, uint256 i) external view override returns (uint256) {
        // some pools omit the second argument of `calc_token_amount` function, so
        // a call with alternative signature is made in case the first one fails
        (bytes memory callData, bytes memory callDataAlt) = _getCalcAddOneCoinCallData(i, amount);
        (bool success, bytes memory returnData) = _callWithAlternative(callData, callDataAlt);
        if (success && returnData.length > 0) {
            return abi.decode(returnData, (uint256));
        } else {
            revert("calc_token_amount reverted");
        }
    }

    /// @dev Returns calldata for adding liquidity in coin `i`, must be overriden in derived adapters
    function _getAddLiquidityOneCoinCallData(uint256 i, uint256 amount, uint256 minAmount)
        internal
        view
        virtual
        returns (bytes memory callData);

    /// @dev Returns calldata for calculating the result of adding liquidity in coin `i`,
    ///      must be overriden in derived adapters
    function _getCalcAddOneCoinCallData(uint256 i, uint256 amount)
        internal
        view
        virtual
        returns (bytes memory callData, bytes memory callDataAlt);

    // ---------------- //
    // REMOVE LIQUIDITY //
    // ---------------- //

    /// @dev Internal implementation of `remove_liquidity`
    ///      - passes calldata to the target contract
    ///      - enables all pool tokens
    function _remove_liquidity() internal returns (uint256 tokensToEnable, uint256 tokensToDisable) {
        _execute(msg.data); // U:[CRV2-3, CRV3-3, CRV4-3]
        (tokensToEnable, tokensToDisable) = (token0Mask | token1Mask | token2Mask | token3Mask, 0); // U:[CRV2-3, CRV3-3, CRV4-3]
    }

    /// @dev Internal implementation of `remove_liquidity_imbalance`
    ///      - passes calldata to the target contract
    ///      - enables specified pool tokens
    function _remove_liquidity_imbalance(bool t0Enable, bool t1Enable, bool t2Enable, bool t3Enable)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        _execute(msg.data); // U:[CRV2-4, CRV3-4, CRV4-4]

        if (t0Enable) tokensToEnable = tokensToEnable.enable(token0Mask); // U:[CRV2-4, CRV3-4, CRV4-4]
        if (t1Enable) tokensToEnable = tokensToEnable.enable(token1Mask); // U:[CRV2-4, CRV3-4, CRV4-4]
        if (t2Enable) tokensToEnable = tokensToEnable.enable(token2Mask); // U:[CRV3-4, CRV4-4]
        if (t3Enable) tokensToEnable = tokensToEnable.enable(token3Mask); // U:[CRV4-4]
        tokensToDisable = 0; // U:[CRV2-4, CRV3-4, CRV4-4]
    }

    /// @notice Removes liquidity from the pool in a specified asset
    /// @param amount Amount of liquidity to remove
    /// @param i Index of the asset to withdraw
    /// @param minAmount Minimum amount of asset to receive
    function remove_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount)
        external
        virtual
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) = _remove_liquidity_one_coin(amount, i, minAmount); // U:[CRVB-9]
    }

    /// @dev Same as the previous one but accepts coin indexes as `int128`
    function remove_liquidity_one_coin(uint256 amount, int128 i, uint256 minAmount)
        external
        virtual
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) = _remove_liquidity_one_coin(amount, _toU256(i), minAmount); // U:[CRVB-9]
    }

    /// @dev Implementation of both versions of `remove_liquidity_one_coin`
    function _remove_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        (tokensToEnable, tokensToDisable) =
            _remove_liquidity_one_coin_impl(i, _getRemoveLiquidityOneCoinCallData(i, amount, minAmount), false); // U:[CRVB-9]
    }

    /// @notice Removes all liquidity from the pool, except the specified amount, in a specified asset
    /// @param leftoverAmount Amount of Curve LP to keep on the account
    /// @param i Index of the asset to withdraw
    /// @param rateMinRAY Minimum exchange rate between LP token and received token, scaled by 1e27
    function remove_diff_liquidity_one_coin(uint256 leftoverAmount, uint256 i, uint256 rateMinRAY)
        external
        virtual
        override
        creditFacadeOnly // U:[CRVB-2]
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        return _remove_diff_liquidity_one_coin(i, leftoverAmount, rateMinRAY); // U:[CRVB-10]
    }

    /// @dev Implementation of `remove_diff_liquidity_one_coin`
    function _remove_diff_liquidity_one_coin(uint256 i, uint256 leftoverAmount, uint256 rateMinRAY)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        address creditAccount = _creditAccount(); // U:[CRVB-10]

        uint256 amount = IERC20(lp_token).balanceOf(creditAccount); // U:[CRVB-10]
        if (amount <= leftoverAmount) return (0, 0);

        unchecked {
            amount -= leftoverAmount; // U:[CRVB-10]
        }
        uint256 minAmount = (amount * rateMinRAY) / RAY; // U:[CRVB-10]
        (tokensToEnable, tokensToDisable) = _remove_liquidity_one_coin_impl(
            i, _getRemoveLiquidityOneCoinCallData(i, amount, minAmount), leftoverAmount <= 1
        ); // U:[CRVB-10]
    }

    /// @dev Internal implementation of `remove_liquidity_one_coin` and `remove_diff_liquidity_one_coin`
    ///      - passes calldata to the targe contract
    ///      - enables received asset
    ///      - disables LP token only when removing all liquidity
    function _remove_liquidity_one_coin_impl(uint256 i, bytes memory callData, bool disableLP)
        internal
        returns (uint256 tokensToEnable, uint256 tokensToDisable)
    {
        _execute(callData);
        (tokensToEnable, tokensToDisable) = (_get_token_mask(i), disableLP ? lpTokenMask : 0); // U:[CRVB-9,10]
    }

    /// @dev Returns calldata for `remove_liquidity_one_coin` and `remove_diff_liquidity_one_coin` calls
    function _getRemoveLiquidityOneCoinCallData(uint256 i, uint256 amount, uint256 minAmount)
        internal
        view
        returns (bytes memory)
    {
        return use256
            ? abi.encodeWithSignature("remove_liquidity_one_coin(uint256,uint256,uint256)", amount, i, minAmount)
            : abi.encodeWithSignature("remove_liquidity_one_coin(uint256,int128,uint256)", amount, i, minAmount); // U:[CRVB-9,10]
    }

    // ------- //
    // HELPERS //
    // ------- //

    /// @dev Returns true if pool is a cryptoswap pool, which is determined by whether it implements `mid_fee`
    function _use256() internal view returns (bool result) {
        try ICurvePool(targetContract).mid_fee() returns (uint256) {
            result = true;
        } catch {
            result = false;
        }
    }

    /// @dev Returns `i`-th coin of the `pool`, tries both signatures
    function _getCoin(address pool, uint256 i) internal view returns (address coin) {
        try ICurvePool(pool).coins(i) returns (address addr) {
            coin = addr;
        } catch {
            try ICurvePool(pool).coins(int128(int256(i))) returns (address addr) {
                coin = addr;
            } catch {}
        }
    }

    /// @dev Performs a low-level call to the target contract with provided calldata, and, should it fail,
    ///      makes a second call with alternative calldata
    function _callWithAlternative(bytes memory callData, bytes memory callDataAlt)
        internal
        view
        returns (bool success, bytes memory returnData)
    {
        (success, returnData) = targetContract.staticcall(callData);
        if (!success || returnData.length == 0) {
            (success, returnData) = targetContract.staticcall(callDataAlt);
        }
    }

    /// @dev Returns token `i`'s address
    function _get_token(uint256 i) internal view returns (address addr) {
        if (i == 0) return token0;
        if (i == 1) return token1;
        if (i == 2) return token2;
        if (i == 3) return token3;
    }

    /// @dev Returns underlying `i`'s address
    function _get_underlying(uint256 i) internal view returns (address addr) {
        if (i == 0) return underlying0;
        if (i == 1) return underlying1;
        if (i == 2) return underlying2;
        if (i == 3) return underlying3;
    }

    /// @dev Returns token `i`'s mask
    function _get_token_mask(uint256 i) internal view returns (uint256 mask) {
        if (i == 0) return token0Mask;
        if (i == 1) return token1Mask;
        if (i == 2) return token2Mask;
        if (i == 3) return token3Mask;
    }

    /// @dev Returns underlying `i`'s mask
    function _get_underlying_mask(uint256 i) internal view returns (uint256 mask) {
        if (i == 0) return underlying0Mask;
        if (i == 1) return underlying1Mask;
        if (i == 2) return underlying2Mask;
        if (i == 3) return underlying3Mask;
    }

    /// @dev Sets target contract's approval for specified tokens to `amount`
    function _approveTokens(bool t0Approve, bool t1Approve, bool t2Approve, bool t3Approve, uint256 amount) internal {
        if (t0Approve) _approveToken(token0, amount);
        if (t1Approve) _approveToken(token1, amount);
        if (t2Approve) _approveToken(token2, amount);
        if (t3Approve) _approveToken(token3, amount);
    }

    /// @dev Returns `int128`-typed number as `uint256`
    function _toU256(int128 i) internal pure returns (uint256) {
        return uint256(int256(i));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function underlying_coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function coins(int128) external view returns (address);

    function underlying_coins(int128) external view returns (address);

    function balances(int128) external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external;

    function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);

    function get_dy(uint256 i, uint256 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function virtual_price() external view returns (uint256);

    function token() external view returns (address);

    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_amount) external;

    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 min_amount) external;

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, uint256 i) external view returns (uint256);

    function admin_balances(uint256 i) external view returns (uint256);

    function admin() external view returns (address);

    function fee() external view returns (uint256);

    function admin_fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function mid_fee() external view returns (uint256);

    // Some pools implement ERC20

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IAdapter} from "@gearbox-protocol/core-v2/contracts/interfaces/IAdapter.sol";

/// @title Curve V1 base adapter interface
interface ICurveV1Adapter is IAdapter {
    function token() external view returns (address);

    function lp_token() external view returns (address);

    function lpTokenMask() external view returns (uint256);

    function metapoolBase() external view returns (address);

    function nCoins() external view returns (uint256);

    function use256() external view returns (bool);

    function token0() external view returns (address);
    function token1() external view returns (address);
    function token2() external view returns (address);
    function token3() external view returns (address);

    function token0Mask() external view returns (uint256);
    function token1Mask() external view returns (uint256);
    function token2Mask() external view returns (uint256);
    function token3Mask() external view returns (uint256);

    function underlying0() external view returns (address);
    function underlying1() external view returns (address);
    function underlying2() external view returns (address);
    function underlying3() external view returns (address);

    function underlying0Mask() external view returns (uint256);
    function underlying1Mask() external view returns (uint256);
    function underlying2Mask() external view returns (uint256);
    function underlying3Mask() external view returns (uint256);

    // -------- //
    // EXCHANGE //
    // -------- //

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exchange_diff(uint256 i, uint256 j, uint256 leftoverAmount, uint256 rateMinRAY)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function exchange_diff_underlying(uint256 i, uint256 j, uint256 leftoverAmount, uint256 rateMinRAY)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    // ------------- //
    // ADD LIQUIDITY //
    // ------------- //

    function add_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function add_diff_liquidity_one_coin(uint256 leftoverAmount, uint256 i, uint256 rateMinRAY)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function calc_add_one_coin(uint256 amount, uint256 i) external view returns (uint256);

    // ---------------- //
    // REMOVE LIQUIDITY //
    // ---------------- //

    function remove_liquidity_one_coin(uint256 amount, uint256 i, uint256 minAmount)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function remove_liquidity_one_coin(uint256 amount, int128 i, uint256 minAmount)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);

    function remove_diff_liquidity_one_coin(uint256 leftoverAmount, uint256 i, uint256 rateMinRAY)
        external
        returns (uint256 tokensToEnable, uint256 tokensToDisable);
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

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IncorrectParameterException} from "../interfaces/IExceptions.sol";

uint256 constant UNDERLYING_TOKEN_MASK = 1;

/// @title Bit mask library
/// @notice Implements functions that manipulate bit masks
///         Bit masks are utilized extensively by Gearbox to efficiently store token sets (enabled tokens on accounts
///         or forbidden tokens) and check for set inclusion. A mask is a uint256 number that has its i-th bit set to
///         1 if i-th item is included into the set. For example, each token has a mask equal to 2**i, so set inclusion
///         can be checked by checking tokenMask & setMask != 0.
library BitMask {
    /// @dev Calculates an index of an item based on its mask (using a binary search)
    /// @dev The input should always have only 1 bit set, otherwise the result may be unpredictable
    function calcIndex(uint256 mask) internal pure returns (uint8 index) {
        if (mask == 0) revert IncorrectParameterException(); // U:[BM-1]
        uint16 lb = 0; // U:[BM-2]
        uint16 ub = 256; // U:[BM-2]
        uint16 mid = 128; // U:[BM-2]

        unchecked {
            while (true) {
                uint256 newMask = 1 << mid;
                if (newMask & mask != 0) return uint8(mid); // U:[BM-2]

                if (newMask > mask) ub = mid; // U:[BM-2]

                else lb = mid; // U:[BM-2]
                mid = (lb + ub) >> 1; // U:[BM-2]
            }
        }
    }

    /// @dev Calculates the number of `1` bits
    /// @param enabledTokensMask Bit mask to compute the number of `1` bits in
    function calcEnabledTokens(uint256 enabledTokensMask) internal pure returns (uint256 totalTokensEnabled) {
        unchecked {
            while (enabledTokensMask > 0) {
                enabledTokensMask &= enabledTokensMask - 1; // U:[BM-3]
                ++totalTokensEnabled; // U:[BM-3]
            }
        }
    }

    /// @dev Enables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask of bits to enable
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable) internal pure returns (uint256) {
        return enabledTokenMask | bitsToEnable; // U:[BM-4]
    }

    /// @dev Disables bits from the second mask in the first mask
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask of bits to disable
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable) internal pure returns (uint256) {
        return enabledTokenMask & ~bitsToDisable; // U:[BM-4]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    function enableDisable(uint256 enabledTokensMask, uint256 bitsToEnable, uint256 bitsToDisable)
        internal
        pure
        returns (uint256)
    {
        return (enabledTokensMask | bitsToEnable) & (~bitsToDisable); // U:[BM-5]
    }

    /// @dev Enables bits from the second mask in the first mask, skipping specified bits
    /// @param enabledTokenMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function enable(uint256 enabledTokenMask, uint256 bitsToEnable, uint256 invertedSkipMask)
        internal
        pure
        returns (uint256)
    {
        return enabledTokenMask | (bitsToEnable & invertedSkipMask); // U:[BM-6]
    }

    /// @dev Disables bits from the second mask in the first mask, skipping specified bits
    /// @param enabledTokenMask The initial mask
    /// @param bitsToDisable Mask with bits to disable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function disable(uint256 enabledTokenMask, uint256 bitsToDisable, uint256 invertedSkipMask)
        internal
        pure
        returns (uint256)
    {
        return enabledTokenMask & (~(bitsToDisable & invertedSkipMask)); // U:[BM-6]
    }

    /// @dev Computes a new mask with sets of new enabled and disabled bits, skipping some bits
    /// @dev bitsToEnable and bitsToDisable are applied sequentially to original mask. Skipmask is applied in both cases.
    /// @param enabledTokensMask The initial mask
    /// @param bitsToEnable Mask with bits to enable
    /// @param bitsToDisable Mask with bits to disable
    /// @param invertedSkipMask An inversion of mask of immutable bits
    function enableDisable(
        uint256 enabledTokensMask,
        uint256 bitsToEnable,
        uint256 bitsToDisable,
        uint256 invertedSkipMask
    ) internal pure returns (uint256) {
        return (enabledTokensMask | (bitsToEnable & invertedSkipMask)) & (~(bitsToDisable & invertedSkipMask)); // U:[BM-7]
    }
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