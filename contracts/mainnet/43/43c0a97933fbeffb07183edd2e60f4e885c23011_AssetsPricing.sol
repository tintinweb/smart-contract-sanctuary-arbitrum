// SPDX-License-Identifier: MIT

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IAggregatorV3} from "src/interfaces/IAggregatorV3.sol";
import {IStableSwap} from "src/interfaces/swap/IStableSwap.sol";
import {UniswapV2Library} from "src/libraries/UniswapV2Library.sol";

/**
 * @title AssetsPricing
 * @author JonesDAO
 * @notice Helper contract to aggregate the process of fetching prices internally across Metavaults V2 product.
 */
library AssetsPricing {
    //////////////////////////////////////////////////////////
    //                  CONSTANTS
    //////////////////////////////////////////////////////////

    // @notice Chainlink ETH/USD oracle (8 decimals)
    IAggregatorV3 private constant ETH_ORACLE = IAggregatorV3(0x639Fe6ab55C921f74e7fac1ee960C0B6293ba612);

    // @notice Chainlink USDC/USD oracle (8 decimals)
    IAggregatorV3 private constant USDC_ORACLE = IAggregatorV3(0x50834F3163758fcC1Df9973b6e91f0F0F0434aD3);

    // @notice Chainlink stETH/ETH oracle (18 decimals)
    IAggregatorV3 private constant ST_ETH_ORACLE = IAggregatorV3(0x07C5b924399cc23c24a95c8743DE4006a32b7f2a);

    // @notice Chainlink wstETH/stETH ratio oracle (18 decimals)
    IAggregatorV3 private constant WST_ETH_ORACLE = IAggregatorV3(0xB1552C5e96B312d0Bf8b554186F846C40614a540);

    // @notice Chainlink wstETH/ETH ratio oracle (18 decimals)
    IAggregatorV3 private constant WST_ETH_RATIO_ORACLE = IAggregatorV3(0xb523AE262D20A936BC152e6023996e46FDC2A95D);

    // @notice Curve's 2CRV
    IStableSwap private constant CRV = IStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);

    // @notice Used to normalize results to 18 decimals
    uint256 private constant STANDARD_DECIMALS = 1e18;

    // @notice Used to normalize USDC functions
    uint256 private constant USDC_DECIMALS = 1e6;

    //////////////////////////////////////////////////////////
    //                  UniV2 VIEW FUNCTIONS
    //////////////////////////////////////////////////////////

    /**
     * @param _lp Pool that will happen the token swap
     * @param _amountIn Amount of tokens that will be swapped
     * @param _tokenIn Received token
     * @param _tokenOut Wanted token
     * @return min amount of tokens with slippage applied
     */
    function getAmountOut(address _lp, uint256 _amountIn, address _tokenIn, address _tokenOut)
        external
        view
        returns (uint256)
    {
        (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(_lp, _tokenIn, _tokenOut);

        return UniswapV2Library.getAmountOut(_amountIn, reserveA, reserveB);
    }

    //////////////////////////////////////////////////////////
    //                  ASSETS PRICING
    //////////////////////////////////////////////////////////

    /**
     * @notice Returns wstETH price quoted in USD
     * @dev Returns value in 8 decimals
     */
    function wstEthPriceInUsd(uint256 amount) external view returns (uint256) {
        (, int256 stEthPrice,,,) = ST_ETH_ORACLE.latestRoundData();
        (, int256 wstEthRatio_,,,) = WST_ETH_ORACLE.latestRoundData();

        uint256 priceInEth = (uint256(stEthPrice) * uint256(wstEthRatio_)) / STANDARD_DECIMALS;

        return (amount * priceInEth) / STANDARD_DECIMALS;
    }

    /**
     * @notice Returns an arbitrary amount of wETH quoted in USD
     * @dev Returns value in 8 decimals
     */
    function ethPriceInUsd(uint256 amount) public view returns (uint256) {
        (, int256 ethPrice,,,) = ETH_ORACLE.latestRoundData();

        return (uint256(ethPrice) * amount) / STANDARD_DECIMALS;
    }

    function ethPriceInUsdc(uint256 amount) external view returns (uint256) {
        // 8 decimals + 6 decimals
        uint256 ethPriceInUsd_ = ethPriceInUsd(amount) * USDC_DECIMALS;
        uint256 usdcPriceInUsd_ = usdcPriceInUsd(USDC_DECIMALS);

        return ethPriceInUsd_ / usdcPriceInUsd_;
    }

    /**
     * @notice Returns wstETH quoted in ETH
     * @dev Returns value with 18 decimals
     */
    function wstEthRatio() external view returns (uint256) {
        (, int256 wstEthRatio_,,,) = WST_ETH_RATIO_ORACLE.latestRoundData();

        return uint256(wstEthRatio_);
    }

    /**
     * @notice Returns USD price of USDC
     * @dev Returns value with 8 decimals
     */
    function usdcPriceInUsd(uint256 amount) public view returns (uint256) {
        (, int256 usdcPrice,,,) = USDC_ORACLE.latestRoundData();

        return (uint256(usdcPrice) * amount) / USDC_DECIMALS;
    }

    /**
     * @notice Returns the amount of 2crv that will be received from depositing given amount of USDC
     * @notice Since this is an unbalanced deposit, we may incur some positive or negative slippage
     * @dev 2crv = 18 decimals
     * @return 2crv amount that will be received
     */
    function get2CrvAmountFromDeposit(uint256 _usdcAmount) external view returns (uint256) {
        // First array element is USDC and second USDT, we pass it == true since its a deposit
        // Receive 2crv amount accounting for slippage but not fees
        return CRV.calc_token_amount([_usdcAmount, 0], true);
    }

    /**
     * @notice Returns amount of USDC that will be received by redeeming an amount of 2crv
     * @dev 6 decimals return
     * @return USDC amount
     */
    function getUsdcAmountFromWithdraw(uint256 _2crvAmount) public view returns (uint256) {
        return CRV.calc_withdraw_one_coin(_2crvAmount, 0);
    }

    function getUsdValueFromWithdraw(uint256 _2crvAmount) external view returns (uint256) {
        uint256 usdcAmount = getUsdcAmountFromWithdraw(_2crvAmount);

        return usdcPriceInUsd(usdcAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IStableSwap is IERC20 {
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount, address receiver)
        external
        returns (uint256);

    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts)
        external
        returns (uint256[2] memory);
    function remove_liquidity(uint256 burn_amount, uint256[2] calldata min_amounts, address receiver)
        external
        returns (uint256[2] memory);
    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount) external returns (uint256);
    function remove_liquidity_one_coin(uint256 burn_amount, int128 i, uint256 min_amount, address receiver)
        external
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool is_deposit) external view returns (uint256);

    function calc_withdraw_one_coin(uint256 burn_amount, int128 i) external view returns (uint256);

    function coins(uint256 i) external view returns (address);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IUniswapV2Pair} from "src/interfaces/lp/IUniswapV2Pair.sol";

library SafeMathUniswap {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}