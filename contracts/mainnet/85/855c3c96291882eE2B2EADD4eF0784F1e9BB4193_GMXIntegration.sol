/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

pragma solidity ^0.8.7;


// SPDX-License-Identifier: MIT
// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint _x, uint _y) internal pure returns (uint z) {
        require((z = _x + _y) >= _x, "ds-math-add-overflow");
    }

    function sub(uint _x, uint _y) internal pure returns (uint z) {
        require((z = _x - _y) <= _x, "ds-math-sub-underflow");
    }

    function mul(uint _x, uint _y) internal pure returns (uint z) {
        require(_y == 0 || (z = _x * _y) / _y == _x, "ds-math-mul-overflow");
    }

    function div(uint _x, uint _y) internal pure returns (uint z) {
        require(_y > 0, "ds-math-div-by-zero");
        z = _x / _y;
    }
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

interface IDEX {
    function validatePair(
        address _tokenIn,
        address _tokenOut
    ) external view returns (bool);

    function getMaxAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view returns (uint256);

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _to
    ) external returns (uint256);
}

interface IGMXRouter {
    function vault() external view returns (address);

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external;
}

interface IGMXVault {
    function tokenDecimals(address) external view returns (uint256);

    function getMinPrice(address) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function stableTokens(address _token) external view returns (bool);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);
}

contract Lockable {
    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "Lockable: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

contract GMXIntegration is IDEX, Lockable {
    using SafeMath for uint256;

    uint256 public constant BASIS_POINTS_DIVISOR = 10000;
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant USDG_DECIMALS = 18;
    address public immutable router;

    constructor(address _router) {
        router = _router;
    }

    function _approve(address _token) internal {
        if (IERC20(_token).allowance(address(this), router) == 0) {
            IERC20(_token).approve(
                router,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        }
    }

    function _getFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        IGMXVault _vault,
        uint256 _usdgAmount,
        uint256 _baseBps,
        uint256 _taxBps
    ) internal view returns (uint256) {
        uint256 feesBasisPoints0 = _vault.getFeeBasisPoints(
            _tokenIn,
            _usdgAmount,
            _baseBps,
            _taxBps,
            true
        );
        uint256 feesBasisPoints1 = _vault.getFeeBasisPoints(
            _tokenOut,
            _usdgAmount,
            _baseBps,
            _taxBps,
            false
        );
        // use the higher of the two fee basis points
        return
            feesBasisPoints0 > feesBasisPoints1
                ? feesBasisPoints0
                : feesBasisPoints1;
    }

    function _getLimitAmountIn(
        IGMXVault _vault,
        address _tokenIn,
        address _tokenOut
    ) internal view returns (uint256) {
        uint256 priceIn = _vault.getMinPrice(_tokenIn);
        uint256 priceOut = _vault.getMaxPrice(_tokenOut);

        uint256 tokenInDecimals = _vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = _vault.tokenDecimals(_tokenOut);

        uint256 amountIn;

        {
            uint256 poolAmount = _vault.poolAmounts(_tokenOut);
            uint256 reservedAmount = _vault.reservedAmounts(_tokenOut);
            uint256 bufferAmount = _vault.bufferAmounts(_tokenOut);
            uint256 subAmount = reservedAmount > bufferAmount
                ? reservedAmount
                : bufferAmount;
            if (subAmount >= poolAmount) {
                return 0;
            }
            uint256 availableAmount = poolAmount.sub(subAmount);
            amountIn = availableAmount
                .mul(priceOut)
                .div(priceIn)
                .mul(10 ** tokenInDecimals)
                .div(10 ** tokenOutDecimals);
        }

        uint256 maxUsdgAmount = _vault.maxUsdgAmounts(_tokenIn);

        if (maxUsdgAmount != 0) {
            if (maxUsdgAmount < _vault.usdgAmounts(_tokenIn)) {
                return 0;
            }

            uint256 maxAmountIn = maxUsdgAmount.sub(
                _vault.usdgAmounts(_tokenIn)
            );
            maxAmountIn = maxAmountIn.mul(10 ** tokenInDecimals).div(
                10 ** USDG_DECIMALS
            );
            maxAmountIn = maxAmountIn.mul(PRICE_PRECISION).div(priceIn);

            if (amountIn > maxAmountIn) {
                return maxAmountIn;
            }
        }

        return amountIn;
    }

    function validatePair(
        address _tokenIn,
        address _tokenOut
    ) external view override returns (bool) {
        if (_tokenIn == _tokenOut) {
            return false;
        }
        IGMXVault vault = IGMXVault(IGMXRouter(router).vault());
        uint256 poolAmountIn = vault.poolAmounts(_tokenIn);
        uint256 poolAmountOut = vault.poolAmounts(_tokenOut);
        if (poolAmountIn == 0 || poolAmountOut == 0) {
            return false;
        }

        return true;
    }

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view override returns (uint256 amountOut) {
        IGMXVault vault = IGMXVault(IGMXRouter(router).vault());

        uint256 poolAmount = vault.poolAmounts(_tokenOut);
        uint256 reservedAmount = vault.reservedAmounts(_tokenOut);
        if (amountOut > poolAmount.sub(reservedAmount)) {
            return 0; // not enough liquidity
        }

        uint256 priceIn = vault.getMinPrice(_tokenIn);

        uint256 tokenInDecimals = vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = vault.tokenDecimals(_tokenOut);

        uint256 feeBasisPoints;
        {
            uint256 usdgAmount = _amountIn.mul(priceIn).div(PRICE_PRECISION);
            usdgAmount = usdgAmount.mul(10 ** USDG_DECIMALS).div(
                10 ** tokenInDecimals
            );

            bool isStableSwap = vault.stableTokens(_tokenIn) &&
                vault.stableTokens(_tokenOut);
            uint256 baseBps = isStableSwap
                ? vault.stableSwapFeeBasisPoints()
                : vault.swapFeeBasisPoints();
            uint256 taxBps = isStableSwap
                ? vault.stableTaxBasisPoints()
                : vault.taxBasisPoints();
            feeBasisPoints = _getFeeBasisPoints(
                _tokenIn,
                _tokenOut,
                vault,
                usdgAmount,
                baseBps,
                taxBps
            );
        }

        uint256 priceOut = vault.getMaxPrice(_tokenOut);
        amountOut = _amountIn.mul(priceIn).div(priceOut);
        amountOut = amountOut.mul(10 ** tokenOutDecimals).div(
            10 ** tokenInDecimals
        );

        amountOut = amountOut.mul(BASIS_POINTS_DIVISOR.sub(feeBasisPoints)).div(
            BASIS_POINTS_DIVISOR
        );
    }

    function getMaxAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view override returns (uint256 maxAmountIn) {
        IGMXVault vault = IGMXVault(IGMXRouter(router).vault());

        uint256 limitAmountIn = _getLimitAmountIn(vault, _tokenIn, _tokenOut);
        if (maxAmountIn > limitAmountIn) {
            return 0; // exceed the limit
        }

        uint256 maxFeeBasisPoints;
        {
            bool isStableSwap = vault.stableTokens(_tokenIn) &&
                vault.stableTokens(_tokenOut);
            uint256 baseBps = isStableSwap
                ? vault.stableSwapFeeBasisPoints()
                : vault.swapFeeBasisPoints();
            uint256 taxBps = isStableSwap
                ? vault.stableTaxBasisPoints()
                : vault.taxBasisPoints();
            maxFeeBasisPoints = baseBps.add(taxBps);
        }

        uint256 tokenInDecimals = vault.tokenDecimals(_tokenIn);
        uint256 tokenOutDecimals = vault.tokenDecimals(_tokenOut);
        uint256 priceIn = vault.getMinPrice(_tokenIn);
        uint256 priceOut = vault.getMaxPrice(_tokenOut);
        maxAmountIn = _amountOut.mul(priceOut).div(priceIn);
        maxAmountIn = maxAmountIn.mul(10 ** tokenInDecimals).div(
            10 ** tokenOutDecimals
        );

        maxAmountIn = maxAmountIn.mul(BASIS_POINTS_DIVISOR).div(
            BASIS_POINTS_DIVISOR.sub(maxFeeBasisPoints)
        );
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _to
    ) external override lock returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;
        uint256 amountIn = IERC20(_tokenIn).balanceOf(address(this));
        uint256 initialBalance = IERC20(_tokenOut).balanceOf(_to);
        _approve(_tokenIn);
        IGMXRouter(router).swap(path, amountIn, 0, _to);
        uint256 balance = IERC20(_tokenOut).balanceOf(_to);
        amountOut = balance - initialBalance;
        require(amountOut > 0, "GMXDEX: INSUFFICIENT_INPUT_TOKEN");
    }
}