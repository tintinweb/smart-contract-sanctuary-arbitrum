// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";
import {IERC20} from "openzeppelin-contracts/interfaces/IERC20.sol";
import {Math} from "/mimswap/libraries/Math.sol";
import {DecimalMath} from "/mimswap/libraries/DecimalMath.sol";
import {IWETH} from "interfaces/IWETH.sol";
import {IMagicLP} from "/mimswap/interfaces/IMagicLP.sol";
import {IFactory} from "/mimswap/interfaces/IFactory.sol";
import {IERC20Metadata} from "openzeppelin-contracts/interfaces/IERC20Metadata.sol";
import {ReentrancyGuard} from "solady/utils/ReentrancyGuard.sol";

struct AddLiquidityImbalancedParams {
    address lp;
    address to;
    uint256 baseInAmount;
    uint256 quoteInAmount;
    bool remainingAmountToSwapIsBase;
    uint256 remainingAmountToSwap;
    uint256 minimumShares;
    uint256 deadline;
}

/// @notice Router for creating and interacting with MagicLP
/// Can only be used for pool created by the Factory
///
/// @dev A pool can be removed from the Factory. So, when integrating with this contract,
/// validate that the pool exists using the Factory `poolExists` function.
contract Router is ReentrancyGuard {
    using SafeTransferLib for address;
    using SafeTransferLib for address payable;

    error ErrNotETHLP();
    error ErrExpired();
    error ErrZeroAddress();
    error ErrPathTooLong();
    error ErrEmptyPath();
    error ErrBadPath();
    error ErrTooHighSlippage(uint256 amountOut);
    error ErrInvalidBaseToken();
    error ErrInvalidQuoteToken();
    error ErrInTokenNotETH();
    error ErrOutTokenNotETH();
    error ErrInvalidQuoteTarget();
    error ErrZeroDecimals();
    error ErrTooLargeDecimals();
    error ErrDecimalsDifferenceTooLarge();
    error ErrUnknownPool();

    uint256 public constant MAX_BASE_QUOTE_DECIMALS_DIFFERENCE = 12;

    IWETH public immutable weth;
    IFactory public immutable factory;

    receive() external payable {}

    constructor(IWETH weth_, IFactory factory_) {
        if (address(weth_) == address(0) || address(factory_) == address(0)) {
            revert ErrZeroAddress();
        }

        weth = weth_;
        factory = factory_;
    }

    modifier ensureDeadline(uint256 deadline) {
        if (block.timestamp > deadline) {
            revert ErrExpired();
        }
        _;
    }

    modifier onlyKnownPool(address pool) {
        if (!factory.poolExists(pool)) {
            revert ErrUnknownPool();
        }
        _;
    }

    function createPool(
        address baseToken,
        address quoteToken,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        address to,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        bool protocolOwnedPool
    ) public virtual returns (address clone, uint256 shares) {
        _validateDecimals(IERC20Metadata(baseToken).decimals(), IERC20Metadata(quoteToken).decimals());

        clone = IFactory(factory).create(baseToken, quoteToken, lpFeeRate, i, k, protocolOwnedPool);

        baseToken.safeTransferFrom(msg.sender, clone, baseInAmount);
        quoteToken.safeTransferFrom(msg.sender, clone, quoteInAmount);
        (shares, , ) = IMagicLP(clone).buyShares(to);
    }

    function createPoolETH(
        address token,
        bool useTokenAsQuote,
        uint256 lpFeeRate,
        uint256 i,
        uint256 k,
        address to,
        uint256 tokenInAmount,
        bool protocolOwnedPool
    ) public payable virtual returns (address clone, uint256 shares) {
        if (useTokenAsQuote) {
            _validateDecimals(18, IERC20Metadata(token).decimals());
        } else {
            _validateDecimals(IERC20Metadata(token).decimals(), 18);
        }

        clone = IFactory(factory).create(
            useTokenAsQuote ? address(weth) : token,
            useTokenAsQuote ? token : address(weth),
            lpFeeRate,
            i,
            k,
            protocolOwnedPool
        );

        weth.deposit{value: msg.value}();
        token.safeTransferFrom(msg.sender, clone, tokenInAmount);
        address(weth).safeTransfer(clone, msg.value);
        (shares, , ) = IMagicLP(clone).buyShares(to);
    }

    function previewCreatePool(
        uint256 i,
        uint256 baseInAmount,
        uint256 quoteInAmount
    ) external pure returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount, uint256 shares) {
        shares = quoteInAmount < DecimalMath.mulFloor(baseInAmount, i) ? DecimalMath.divFloor(quoteInAmount, i) : baseInAmount;
        baseAdjustedInAmount = shares;
        quoteAdjustedInAmount = DecimalMath.mulFloor(shares, i);

        if (shares <= 2001) {
            return (0, 0, 0);
        }

        shares -= 1001;
    }

    function addLiquidity(
        address lp,
        address to,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 minimumShares,
        uint256 deadline
    )
        public
        virtual
        ensureDeadline(deadline)
        onlyKnownPool(lp)
        returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount, uint256 shares)
    {
        (baseAdjustedInAmount, quoteAdjustedInAmount) = _adjustAddLiquidity(lp, baseInAmount, quoteInAmount);

        IMagicLP(lp)._BASE_TOKEN_().safeTransferFrom(msg.sender, lp, baseAdjustedInAmount);
        IMagicLP(lp)._QUOTE_TOKEN_().safeTransferFrom(msg.sender, lp, quoteAdjustedInAmount);

        shares = _addLiquidity(lp, to, minimumShares);
    }

    function addLiquidityUnsafe(
        address lp,
        address to,
        uint256 baseInAmount,
        uint256 quoteInAmount,
        uint256 minimumShares,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 shares) {
        IMagicLP(lp)._BASE_TOKEN_().safeTransferFrom(msg.sender, lp, baseInAmount);
        IMagicLP(lp)._QUOTE_TOKEN_().safeTransferFrom(msg.sender, lp, quoteInAmount);

        return _addLiquidity(lp, to, minimumShares);
    }

    function addLiquidityETH(
        address lp,
        address to,
        address payable refundTo,
        uint256 tokenInAmount,
        uint256 minimumShares,
        uint256 deadline
    )
        public
        payable
        virtual
        nonReentrant
        ensureDeadline(deadline)
        onlyKnownPool(lp)
        returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount, uint256 shares)
    {
        uint256 wethAdjustedAmount;
        uint256 tokenAdjustedAmount;
        address token = IMagicLP(lp)._BASE_TOKEN_();
        if (token == address(weth)) {
            token = IMagicLP(lp)._QUOTE_TOKEN_();
            (baseAdjustedInAmount, quoteAdjustedInAmount) = _adjustAddLiquidity(lp, msg.value, tokenInAmount);
            wethAdjustedAmount = baseAdjustedInAmount;
            tokenAdjustedAmount = quoteAdjustedInAmount;
        } else if (IMagicLP(lp)._QUOTE_TOKEN_() == address(weth)) {
            (baseAdjustedInAmount, quoteAdjustedInAmount) = _adjustAddLiquidity(lp, tokenInAmount, msg.value);
            wethAdjustedAmount = quoteAdjustedInAmount;
            tokenAdjustedAmount = baseAdjustedInAmount;
        } else {
            revert ErrNotETHLP();
        }

        weth.deposit{value: wethAdjustedAmount}();
        address(weth).safeTransfer(lp, wethAdjustedAmount);

        // Refund unused ETH
        if (msg.value > wethAdjustedAmount) {
            refundTo.safeTransferETH(msg.value - wethAdjustedAmount);
        }

        token.safeTransferFrom(msg.sender, lp, tokenAdjustedAmount);

        shares = _addLiquidity(lp, to, minimumShares);
    }

    function addLiquidityETHUnsafe(
        address lp,
        address to,
        uint256 tokenInAmount,
        uint256 minimumShares,
        uint256 deadline
    ) public payable virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 shares) {
        address token = IMagicLP(lp)._BASE_TOKEN_();
        if (token == address(weth)) {
            token = IMagicLP(lp)._QUOTE_TOKEN_();
        } else if (IMagicLP(lp)._QUOTE_TOKEN_() != address(weth)) {
            revert ErrNotETHLP();
        }

        weth.deposit{value: msg.value}();
        address(weth).safeTransfer(lp, msg.value);

        token.safeTransferFrom(msg.sender, lp, tokenInAmount);

        return _addLiquidity(lp, to, minimumShares);
    }

    function previewRemoveLiquidity(
        address lp,
        uint256 sharesIn
    ) external view nonReadReentrant onlyKnownPool(lp) returns (uint256 baseAmountOut, uint256 quoteAmountOut) {
        uint256 baseBalance = IMagicLP(lp)._BASE_TOKEN_().balanceOf(address(lp));
        uint256 quoteBalance = IMagicLP(lp)._QUOTE_TOKEN_().balanceOf(address(lp));

        uint256 totalShares = IERC20(lp).totalSupply();

        baseAmountOut = (baseBalance * sharesIn) / totalShares;
        quoteAmountOut = (quoteBalance * sharesIn) / totalShares;
    }

    function removeLiquidity(
        address lp,
        address to,
        uint256 sharesIn,
        uint256 minimumBaseAmount,
        uint256 minimumQuoteAmount,
        uint256 deadline
    ) public virtual onlyKnownPool(lp) returns (uint256 baseAmountOut, uint256 quoteAmountOut) {
        lp.safeTransferFrom(msg.sender, address(this), sharesIn);

        return IMagicLP(lp).sellShares(sharesIn, to, minimumBaseAmount, minimumQuoteAmount, "", deadline);
    }

    function removeLiquidityETH(
        address lp,
        address to,
        uint256 sharesIn,
        uint256 minimumETHAmount,
        uint256 minimumTokenAmount,
        uint256 deadline
    ) public virtual onlyKnownPool(lp) returns (uint256 ethAmountOut, uint256 tokenAmountOut) {
        lp.safeTransferFrom(msg.sender, address(this), sharesIn);

        address token = IMagicLP(lp)._BASE_TOKEN_();
        if (token == address(weth)) {
            token = IMagicLP(lp)._QUOTE_TOKEN_();
            (ethAmountOut, tokenAmountOut) = IMagicLP(lp).sellShares(
                sharesIn,
                address(this),
                minimumETHAmount,
                minimumTokenAmount,
                "",
                deadline
            );
        } else if (IMagicLP(lp)._QUOTE_TOKEN_() == address(weth)) {
            (tokenAmountOut, ethAmountOut) = IMagicLP(lp).sellShares(
                sharesIn,
                address(this),
                minimumTokenAmount,
                minimumETHAmount,
                "",
                deadline
            );
        } else {
            revert ErrNotETHLP();
        }

        weth.withdraw(ethAmountOut);
        to.safeTransferETH(ethAmountOut);

        token.safeTransfer(to, tokenAmountOut);
    }

    function swapTokensForTokens(
        address to,
        uint256 amountIn,
        address[] calldata path,
        uint256 directions,
        uint256 minimumOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) returns (uint256 amountOut) {
        _validatePath(path);

        address firstLp = path[0];

        // Transfer to the first LP
        if (directions & 1 == 0) {
            IMagicLP(firstLp)._BASE_TOKEN_().safeTransferFrom(msg.sender, address(firstLp), amountIn);
        } else {
            IMagicLP(firstLp)._QUOTE_TOKEN_().safeTransferFrom(msg.sender, address(firstLp), amountIn);
        }

        return _swap(to, path, directions, minimumOut);
    }

    function swapETHForTokens(
        address to,
        address[] calldata path,
        uint256 directions,
        uint256 minimumOut,
        uint256 deadline
    ) public payable virtual ensureDeadline(deadline) returns (uint256 amountOut) {
        _validatePath(path);

        address firstLp = path[0];
        address inToken;

        if (directions & 1 == 0) {
            inToken = IMagicLP(firstLp)._BASE_TOKEN_();
        } else {
            inToken = IMagicLP(firstLp)._QUOTE_TOKEN_();
        }

        // Transfer to the first LP
        if (inToken != address(weth)) {
            revert ErrInTokenNotETH();
        }

        weth.deposit{value: msg.value}();
        inToken.safeTransfer(address(firstLp), msg.value);

        return _swap(to, path, directions, minimumOut);
    }

    function swapTokensForETH(
        address to,
        uint256 amountIn,
        address[] calldata path,
        uint256 directions,
        uint256 minimumOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) returns (uint256 amountOut) {
        _validatePath(path);

        uint256 lastLpIndex = path.length - 1;
        address lastLp = path[lastLpIndex];
        address outToken;

        if ((directions >> lastLpIndex) & 1 == 0) {
            outToken = IMagicLP(lastLp)._QUOTE_TOKEN_();
        } else {
            outToken = IMagicLP(lastLp)._BASE_TOKEN_();
        }

        if (outToken != address(weth)) {
            revert ErrOutTokenNotETH();
        }

        address firstLp = path[0];

        // Transfer to the first LP
        if (directions & 1 == 0) {
            IMagicLP(firstLp)._BASE_TOKEN_().safeTransferFrom(msg.sender, firstLp, amountIn);
        } else {
            IMagicLP(firstLp)._QUOTE_TOKEN_().safeTransferFrom(msg.sender, firstLp, amountIn);
        }

        amountOut = _swap(address(this), path, directions, minimumOut);
        weth.withdraw(amountOut);

        to.safeTransferETH(amountOut);
    }

    function sellBaseTokensForTokens(
        address lp,
        address to,
        uint256 amountIn,
        uint256 minimumOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        IMagicLP(lp)._BASE_TOKEN_().safeTransferFrom(msg.sender, lp, amountIn);
        return _sellBase(lp, to, minimumOut);
    }

    function sellBaseETHForTokens(
        address lp,
        address to,
        uint256 minimumOut,
        uint256 deadline
    ) public payable virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        address baseToken = IMagicLP(lp)._BASE_TOKEN_();

        if (baseToken != address(weth)) {
            revert ErrInvalidBaseToken();
        }

        weth.deposit{value: msg.value}();
        baseToken.safeTransfer(lp, msg.value);
        return _sellBase(lp, to, minimumOut);
    }

    function sellBaseTokensForETH(
        address lp,
        address to,
        uint256 amountIn,
        uint256 minimumOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        if (IMagicLP(lp)._QUOTE_TOKEN_() != address(weth)) {
            revert ErrInvalidQuoteToken();
        }

        IMagicLP(lp)._BASE_TOKEN_().safeTransferFrom(msg.sender, lp, amountIn);
        amountOut = _sellBase(lp, address(this), minimumOut);
        weth.withdraw(amountOut);
        to.safeTransferETH(amountOut);
    }

    function sellQuoteTokensForTokens(
        address lp,
        address to,
        uint256 amountIn,
        uint256 minimumOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        IMagicLP(lp)._QUOTE_TOKEN_().safeTransferFrom(msg.sender, lp, amountIn);

        return _sellQuote(lp, to, minimumOut);
    }

    function sellQuoteETHForTokens(
        address lp,
        address to,
        uint256 minimumOut,
        uint256 deadline
    ) public payable virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        address quoteToken = IMagicLP(lp)._QUOTE_TOKEN_();

        if (quoteToken != address(weth)) {
            revert ErrInvalidQuoteToken();
        }

        weth.deposit{value: msg.value}();
        quoteToken.safeTransfer(lp, msg.value);
        return _sellQuote(lp, to, minimumOut);
    }

    function sellQuoteTokensForETH(
        address lp,
        address to,
        uint256 amountIn,
        uint256 minimumOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        if (IMagicLP(lp)._BASE_TOKEN_() != address(weth)) {
            revert ErrInvalidBaseToken();
        }

        IMagicLP(lp)._QUOTE_TOKEN_().safeTransferFrom(msg.sender, lp, amountIn);
        amountOut = _sellQuote(lp, address(this), minimumOut);
        weth.withdraw(amountOut);
        to.safeTransferETH(amountOut);
    }

    function addLiquidityOneSide(
        address lp,
        address to,
        bool inAmountIsBase,
        uint256 inAmount,
        uint256 inAmountToSwap,
        uint256 minimumShares,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 baseAmount, uint256 quoteAmount, uint256 shares) {
        address baseToken = IMagicLP(lp)._BASE_TOKEN_();
        address quoteToken = IMagicLP(lp)._QUOTE_TOKEN_();

        // base -> quote
        if (inAmountIsBase) {
            baseToken.safeTransferFrom(msg.sender, address(this), inAmount);
            baseAmount = inAmount - inAmountToSwap;
            baseToken.safeTransfer(lp, inAmountToSwap);
            quoteAmount = IMagicLP(lp).sellBase(address(this));
        }
        // quote -> base
        else {
            quoteToken.safeTransferFrom(msg.sender, address(this), inAmount);
            quoteAmount = inAmount - inAmountToSwap;
            quoteToken.safeTransfer(lp, inAmountToSwap);
            baseAmount = IMagicLP(lp).sellQuote(address(this));
        }

        (baseAmount, quoteAmount) = _adjustAddLiquidity(lp, baseAmount, quoteAmount);
        baseToken.safeTransfer(lp, baseAmount);
        quoteToken.safeTransfer(lp, quoteAmount);
        shares = _addLiquidity(lp, to, minimumShares);

        // Refund remaining tokens
        uint256 remaining = baseToken.balanceOf(address(this));
        if (remaining > 0) {
            baseToken.safeTransfer(msg.sender, remaining);
        }

        remaining = quoteToken.balanceOf(address(this));
        if (remaining > 0) {
            quoteToken.safeTransfer(msg.sender, remaining);
        }
    }

    function removeLiquidityOneSide(
        address lp,
        address to,
        bool withdrawBase,
        uint256 sharesIn,
        uint256 minAmountOut,
        uint256 deadline
    ) public virtual ensureDeadline(deadline) onlyKnownPool(lp) returns (uint256 amountOut) {
        address baseToken = IMagicLP(lp)._BASE_TOKEN_();
        address quoteToken = IMagicLP(lp)._QUOTE_TOKEN_();

        lp.safeTransferFrom(msg.sender, address(this), sharesIn);
        (uint256 baseAmount, uint256 quoteAmount) = IMagicLP(lp).sellShares(sharesIn, address(this), 0, 0, "", deadline);

        // withdraw base
        if (withdrawBase) {
            quoteToken.safeTransfer(lp, quoteAmount);
            amountOut = baseAmount + IMagicLP(lp).sellQuote(address(this));

            if (amountOut > 0) {
                baseToken.safeTransfer(to, amountOut);
            }
        }
        // withdraw quote
        else {
            baseToken.safeTransfer(lp, baseAmount);
            amountOut = quoteAmount + IMagicLP(lp).sellBase(address(this));

            if (amountOut > 0) {
                quoteToken.safeTransfer(to, amountOut);
            }
        }

        if (amountOut < minAmountOut) {
            revert ErrTooHighSlippage(amountOut);
        }
    }

    function addLiquidityImbalanced(
        AddLiquidityImbalancedParams calldata params
    )
        public
        virtual
        ensureDeadline(params.deadline)
        onlyKnownPool(params.lp)
        returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount, uint256 shares)
    {
        address baseToken = IMagicLP(params.lp)._BASE_TOKEN_();
        address quoteToken = IMagicLP(params.lp)._QUOTE_TOKEN_();

        baseToken.safeTransferFrom(msg.sender, address(this), params.baseInAmount);
        quoteToken.safeTransferFrom(msg.sender, address(this), params.quoteInAmount);

        (baseAdjustedInAmount, quoteAdjustedInAmount) = _adjustAddLiquidity(params.lp, params.baseInAmount, params.quoteInAmount);

        // base -> quote
        if (params.remainingAmountToSwapIsBase) {
            baseToken.safeTransfer(params.lp, params.remainingAmountToSwap);
            baseAdjustedInAmount += (params.baseInAmount - baseAdjustedInAmount) - params.remainingAmountToSwap;
            quoteAdjustedInAmount += IMagicLP(params.lp).sellBase(address(this));
        }
        // quote -> base
        else {
            quoteToken.safeTransfer(params.lp, params.remainingAmountToSwap);
            baseAdjustedInAmount += IMagicLP(params.lp).sellQuote(address(this));
            quoteAdjustedInAmount += (params.quoteInAmount - quoteAdjustedInAmount) - params.remainingAmountToSwap;
        }

        (baseAdjustedInAmount, quoteAdjustedInAmount) = _adjustAddLiquidity(params.lp, baseAdjustedInAmount, quoteAdjustedInAmount);

        baseToken.safeTransfer(params.lp, baseAdjustedInAmount);
        quoteToken.safeTransfer(params.lp, quoteAdjustedInAmount);
        shares = _addLiquidity(params.lp, params.to, params.minimumShares);

        // Refund remaining tokens
        uint256 remaining = baseToken.balanceOf(address(this));
        if (remaining > 0) {
            baseToken.safeTransfer(msg.sender, remaining);
        }

        remaining = quoteToken.balanceOf(address(this));
        if (remaining > 0) {
            quoteToken.safeTransfer(msg.sender, remaining);
        }
    }

    //////////////////////////////////////////////////////////////////////////////////////
    /// INTERNALS
    //////////////////////////////////////////////////////////////////////////////////////

    function _addLiquidity(address lp, address to, uint256 minimumShares) internal returns (uint256 shares) {
        (shares, , ) = IMagicLP(lp).buyShares(to);

        if (shares < minimumShares) {
            revert ErrTooHighSlippage(shares);
        }
    }

    /// Adapted from: https://github.com/DODOEX/contractV2/blob/main/contracts/SmartRoute/proxies/DODODspProxy.sol
    /// Copyright 2020 DODO ZOO. Licensed under Apache-2.0.
    function _adjustAddLiquidity(
        address lp,
        uint256 baseInAmount,
        uint256 quoteInAmount
    ) internal view returns (uint256 baseAdjustedInAmount, uint256 quoteAdjustedInAmount) {
        if (IERC20(lp).totalSupply() == 0) {
            uint256 i = IMagicLP(lp)._I_();
            uint256 shares = quoteInAmount < DecimalMath.mulFloor(baseInAmount, i) ? DecimalMath.divFloor(quoteInAmount, i) : baseInAmount;
            baseAdjustedInAmount = shares;
            quoteAdjustedInAmount = DecimalMath.mulFloor(shares, i);
        } else {
            (uint256 baseReserve, uint256 quoteReserve) = IMagicLP(lp).getReserves();
            if (quoteReserve > 0 && baseReserve > 0) {
                uint256 baseIncreaseRatio = DecimalMath.divFloor(baseInAmount, baseReserve);
                uint256 quoteIncreaseRatio = DecimalMath.divFloor(quoteInAmount, quoteReserve);
                if (baseIncreaseRatio <= quoteIncreaseRatio) {
                    baseAdjustedInAmount = baseInAmount;
                    quoteAdjustedInAmount = DecimalMath.mulFloor(quoteReserve, baseIncreaseRatio);
                } else {
                    quoteAdjustedInAmount = quoteInAmount;
                    baseAdjustedInAmount = DecimalMath.mulFloor(baseReserve, quoteIncreaseRatio);
                }
            }
        }
    }

    function _swap(address to, address[] calldata path, uint256 directions, uint256 minimumOut) internal returns (uint256 amountOut) {
        uint256 iterations = path.length - 1; // Subtract by one as last swap is done separately

        for (uint256 i = 0; i < iterations; ) {
            address lp = path[i];
            if (!factory.poolExists(lp)) {
                revert ErrUnknownPool();
            }

            if (directions & 1 == 0) {
                // Sell base
                IMagicLP(lp).sellBase(address(path[i + 1]));
            } else {
                // Sell quote
                IMagicLP(lp).sellQuote(address(path[i + 1]));
            }

            directions >>= 1;

            unchecked {
                ++i;
            }
        }

        if ((directions & 1 == 0)) {
            amountOut = IMagicLP(path[iterations]).sellBase(to);
        } else {
            amountOut = IMagicLP(path[iterations]).sellQuote(to);
        }

        if (amountOut < minimumOut) {
            revert ErrTooHighSlippage(amountOut);
        }
    }

    function _sellBase(address lp, address to, uint256 minimumOut) internal returns (uint256 amountOut) {
        amountOut = IMagicLP(lp).sellBase(to);
        if (amountOut < minimumOut) {
            revert ErrTooHighSlippage(amountOut);
        }
    }

    function _sellQuote(address lp, address to, uint256 minimumOut) internal returns (uint256 amountOut) {
        amountOut = IMagicLP(lp).sellQuote(to);

        if (amountOut < minimumOut) {
            revert ErrTooHighSlippage(amountOut);
        }
    }

    function _validatePath(address[] calldata path) internal pure {
        uint256 pathLength = path.length;

        // Max 256 because of bits in directions
        if (pathLength > 256) {
            revert ErrPathTooLong();
        }
        if (pathLength <= 0) {
            revert ErrEmptyPath();
        }
    }

    function _validateDecimals(uint8 baseDecimals, uint8 quoteDecimals) internal pure {
        if (baseDecimals == 0 || quoteDecimals == 0) {
            revert ErrZeroDecimals();
        }

        if (baseDecimals > 18 || quoteDecimals > 18) {
            revert ErrTooLargeDecimals();
        }

        uint256 deltaDecimals = baseDecimals > quoteDecimals ? baseDecimals - quoteDecimals : quoteDecimals - baseDecimals;

        if (deltaDecimals > MAX_BASE_QUOTE_DECIMALS_DIFFERENCE) {
            revert ErrDecimalsDifferenceTooLarge();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity >=0.8.0;

import {DecimalMath} from "/mimswap/libraries/DecimalMath.sol";

/**
 * @author Adapted from https://github.com/DODOEX/contractV2/blob/main/contracts/lib/Math.sol
 * @notice Functions for complex calculating. Including ONE Integration and TWO Quadratic solutions
 */
library Math {
    error ErrIsZero();

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = a / b;
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    // from UniswapV2 https://github.com/Uniswap/v2-core/blob/master/contracts/libraries/Math.sol
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /*
        Integrate dodo curve from V1 to V2
        require V0>=V1>=V2>0
        res = (1-k)i(V1-V2)+ikV0*V0(1/V2-1/V1)
        let V1-V2=delta
        res = i*delta*(1-k+k(V0^2/V1/V2))

        i is the price of V-res trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _GeneralIntegrate(uint256 V0, uint256 V1, uint256 V2, uint256 i, uint256 k) internal pure returns (uint256) {
        if (V0 == 0) {
            revert ErrIsZero();
        }

        uint256 fairAmount = i * (V1 - V2); // i*delta

        if (k == 0) {
            return fairAmount / DecimalMath.ONE;
        }

        uint256 V0V0V1V2 = DecimalMath.divFloor((V0 * V0) / V1, V2);
        uint256 penalty = DecimalMath.mulFloor(k, V0V0V1V2); // k(V0^2/V1/V2)
        return (((DecimalMath.ONE - k) + penalty) * fairAmount) / DecimalMath.ONE2;
    }

    /*
        Follow the integration function above
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Assume Q2=Q0, Given Q1 and deltaB, solve Q0

        i is the price of delta-V trading pair
        give out target of V

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTarget(uint256 V1, uint256 delta, uint256 i, uint256 k) internal pure returns (uint256) {
        if (k == 0) {
            return V1 + DecimalMath.mulFloor(i, delta);
        }

        // V0 = V1*(1+(sqrt-1)/2k)
        // sqrt = √(1+4kidelta/V1)
        // premium = 1+(sqrt-1)/2k
        // uint256 sqrt = (4 * k).mul(i).mul(delta).div(V1).add(DecimalMath.ONE2).sqrt();

        if (V1 == 0) {
            return 0;
        }
        uint256 _sqrt;
        uint256 ki = (4 * k) * i;
        if (ki == 0) {
            _sqrt = DecimalMath.ONE;
        } else if ((ki * delta) / ki == delta) {
            _sqrt = sqrt(((ki * delta) / V1) + DecimalMath.ONE2);
        } else {
            _sqrt = sqrt(((ki / V1) * delta) + DecimalMath.ONE2);
        }
        uint256 premium = DecimalMath.divFloor(_sqrt - DecimalMath.ONE, k * 2) + DecimalMath.ONE;
        // V0 is greater than or equal to V1 according to the solution
        return DecimalMath.mulFloor(V1, premium);
    }

    /*
        Follow the integration expression above, we have:
        i*deltaB = (Q2-Q1)*(1-k+kQ0^2/Q1/Q2)
        Given Q1 and deltaB, solve Q2
        This is a quadratic function and the standard version is
        aQ2^2 + bQ2 + c = 0, where
        a=1-k
        -b=(1-k)Q1-kQ0^2/Q1+i*deltaB
        c=-kQ0^2 
        and Q2=(-b+sqrt(b^2+4(1-k)kQ0^2))/2(1-k)
        note: another root is negative, abondan

        if deltaBSig=true, then Q2>Q1, user sell Q and receive B
        if deltaBSig=false, then Q2<Q1, user sell B and receive Q
        return |Q1-Q2|

        as we only support sell amount as delta, the deltaB is always negative
        the input ideltaB is actually -ideltaB in the equation

        i is the price of delta-V trading pair

        support k=1 & k=0 case

        [round down]
    */
    function _SolveQuadraticFunctionForTrade(uint256 V0, uint256 V1, uint256 delta, uint256 i, uint256 k) internal pure returns (uint256) {
        if (V0 == 0) {
            revert ErrIsZero();
        }

        if (delta == 0) {
            return 0;
        }

        if (k == 0) {
            return DecimalMath.mulFloor(i, delta) > V1 ? V1 : DecimalMath.mulFloor(i, delta);
        }

        if (k == DecimalMath.ONE) {
            // if k==1
            // Q2=Q1/(1+ideltaBQ1/Q0/Q0)
            // temp = ideltaBQ1/Q0/Q0
            // Q2 = Q1/(1+temp)
            // Q1-Q2 = Q1*(1-1/(1+temp)) = Q1*(temp/(1+temp))
            // uint256 temp = i.mul(delta).mul(V1).div(V0.mul(V0));
            uint256 temp;
            uint256 idelta = i * delta;
            if (idelta == 0) {
                temp = 0;
            } else if ((idelta * V1) / idelta == V1) {
                temp = (idelta * V1) / (V0 * V0);
            } else {
                temp = (((delta * V1) / V0) * i) / V0;
            }
            return (V1 * temp) / (temp + DecimalMath.ONE);
        }

        // calculate -b value and sig
        // b = kQ0^2/Q1-i*deltaB-(1-k)Q1
        // part1 = (1-k)Q1 >=0
        // part2 = kQ0^2/Q1-i*deltaB >=0
        // bAbs = abs(part1-part2)
        // if part1>part2 => b is negative => bSig is false
        // if part2>part1 => b is positive => bSig is true
        uint256 part2 = (((k * V0) / V1) * V0) + (i * delta); // kQ0^2/Q1-i*deltaB
        uint256 bAbs = (DecimalMath.ONE - k) * V1; // (1-k)Q1

        bool bSig;
        if (bAbs >= part2) {
            bAbs = bAbs - part2;
            bSig = false;
        } else {
            bAbs = part2 - bAbs;
            bSig = true;
        }
        bAbs = bAbs / DecimalMath.ONE;

        // calculate sqrt
        uint256 squareRoot = DecimalMath.mulFloor((DecimalMath.ONE - k) * 4, DecimalMath.mulFloor(k, V0) * V0); // 4(1-k)kQ0^2
        squareRoot = sqrt((bAbs * bAbs) + squareRoot); // sqrt(b*b+4(1-k)kQ0*Q0)

        // final res
        uint256 denominator = (DecimalMath.ONE - k) * 2; // 2(1-k)
        uint256 numerator;
        if (bSig) {
            numerator = squareRoot - bAbs;
            if (numerator == 0) {
                revert ErrIsZero();
            }
        } else {
            numerator = bAbs + squareRoot;
        }

        uint256 V2 = DecimalMath.divCeil(numerator, denominator);
        if (V2 > V1) {
            return 0;
        } else {
            return V1 - V2;
        }
    }
}

/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/
pragma solidity >=0.8.0;

import {Math} from "/mimswap/libraries/Math.sol";

/**
 * @title DecimalMath
 * @author DODO Breeder
 *
 * @notice Functions for fixed point number with 18 decimals
 */
library DecimalMath {
    using Math for uint256;

    uint256 internal constant ONE = 10 ** 18;
    uint256 internal constant ONE2 = 10 ** 36;

    function mulFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * d) / ONE;
    }

    function mulCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * d).divCeil(ONE);
    }

    function divFloor(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * ONE) / d;
    }

    function divCeil(uint256 target, uint256 d) internal pure returns (uint256) {
        return (target * ONE).divCeil(d);
    }

    function reciprocalFloor(uint256 target) internal pure returns (uint256) {
        return ONE2 / target;
    }

    function reciprocalCeil(uint256 target) internal pure returns (uint256) {
        return ONE2.divCeil(target);
    }

    function powFloor(uint256 target, uint256 e) internal pure returns (uint256) {
        if (e == 0) {
            return 10 ** 18;
        } else if (e == 1) {
            return target;
        } else {
            uint p = powFloor(target, e / 2);
            p = (p * p) / ONE;
            if (e % 2 == 1) {
                p = (p * target) / ONE;
            }
            return p;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "BoringSolidity/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IWETHAlike is IWETH {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IMagicLP {
    function _BASE_TOKEN_() external view returns (address);

    function _QUOTE_TOKEN_() external view returns (address);

    function _BASE_RESERVE_() external view returns (uint112);

    function _QUOTE_RESERVE_() external view returns (uint112);

    function _BASE_TARGET_() external view returns (uint112);

    function _QUOTE_TARGET_() external view returns (uint112);

    function _I_() external view returns (uint256);

    function getReserves() external view returns (uint256 baseReserve, uint256 quoteReserve);

    function totalSupply() external view returns (uint256 totalSupply);

    function init(
        address baseTokenAddress,
        address quoteTokenAddress,
        uint256 lpFeeRate,
        address mtFeeRateModel,
        uint256 i,
        uint256 k,
        bool protocolOwnedPool
    ) external;

    function sellBase(address to) external returns (uint256 receiveQuoteAmount);

    function sellQuote(address to) external returns (uint256 receiveBaseAmount);

    function flashLoan(uint256 baseAmount, uint256 quoteAmount, address assetTo, bytes calldata data) external;

    function buyShares(address to) external returns (uint256 shares, uint256 baseInput, uint256 quoteInput);

    function sellShares(
        uint256 shareAmount,
        address to,
        uint256 baseMinAmount,
        uint256 quoteMinAmount,
        bytes calldata data,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function MIN_LP_FEE_RATE() external view returns (uint256);

    function MAX_LP_FEE_RATE() external view returns (uint256);

    function _PAUSED_() external view returns (bool);

    function setPaused(bool paused) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFactory {
    function predictDeterministicAddress(
        address creator,
        address baseToken_,
        address quoteToken_,
        uint256 lpFeeRate_,
        uint256 i_,
        uint256 k_
    ) external view returns (address);

    function maintainerFeeRateModel() external view returns (address);

    function create(
        address baseToken_,
        address quoteToken_,
        uint256 lpFeeRate_,
        uint256 i_,
        uint256 k_,
        bool protocolOwnedPool_
    ) external returns (address clone);

    function poolExists(address pool) external view returns (bool);

    function addPool(address creator, address baseToken, address quoteToken, address pool) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Reentrancy guard mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unauthorized reentrant call.
    error Reentrancy();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to: `uint72(bytes9(keccak256("_REENTRANCY_GUARD_SLOT")))`.
    /// 9 bytes is large enough to avoid collisions with lower slots,
    /// but not too large to result in excessive bytecode bloat.
    uint256 private constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      REENTRANCY GUARD                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Guards a function from reentrancy.
    modifier nonReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), address()) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
            sstore(_REENTRANCY_GUARD_SLOT, address())
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_REENTRANCY_GUARD_SLOT, codesize())
        }
    }

    /// @dev Guards a view function from read-only reentrancy.
    modifier nonReadReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), address()) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
        }
        _;
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
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}