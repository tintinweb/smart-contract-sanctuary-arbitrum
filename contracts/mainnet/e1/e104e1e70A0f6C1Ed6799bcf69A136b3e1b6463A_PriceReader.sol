/**
 *Submitted for verification at Arbiscan on 2023-05-21
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

interface IDEXAggregator {
    function dexes(uint256) external view returns (address);

    function dexIndex(address) external view returns (uint256);

    function dexLength() external view returns (uint256);

    function getMaxAmountIn(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view returns (uint256 maxAmountIn, address dex);

    function getAmountOut(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256 amountOut, address dex);

    function swap(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _to
    ) external returns (uint256 amountOut, address dex);
}

contract PriceReader {
    using SafeMath for uint256;

    address public manager;
    address public usd;

    event SetManager(address manager);
    event SetUsd(address usd);

    constructor(address _manager, address _usd) public {
        manager = _manager;
        usd = _usd;
    }

    modifier onlyManager() {
        require(msg.sender == manager, "PriceReader: FORBIDDEN");
        _;
    }

    function setManager(address _manager) external onlyManager {
        manager = _manager;

        emit SetManager(_manager);
    }

    function setUsd(address _usd) external onlyManager {
        usd = _usd;

        emit SetUsd(_usd);
    }

    // returns (price, precision)
    function price(
        address _baseToken,
        address _quoteToken,
        address _dex
    ) public view returns (uint256, uint256) {
        uint256 baseDecimals = IERC20(_baseToken).decimals();
        uint256 quoteDecimals = IERC20(_quoteToken).decimals();
        uint256 amountIn = 10 ** baseDecimals;
        uint256 amountOut = IDEX(_dex).getAmountOut(
            _baseToken,
            _quoteToken,
            amountIn
        );
        return (
            amountOut.mul(1e18) / amountIn,
            (10 ** quoteDecimals).mul(1e18) / (10 ** baseDecimals)
        );
    }

    function usdPrice(
        address _token,
        address _dex
    ) external view returns (uint256, uint256) {
        return price(_token, usd, _dex);
    }

    // returns (price, precision, dex)
    function bestPrice(
        address _baseToken,
        address _quoteToken,
        address _aggregator
    ) public view returns (uint256, uint256, address) {
        uint256 baseDecimals = IERC20(_baseToken).decimals();
        uint256 quoteDecimals = IERC20(_quoteToken).decimals();
        uint256 amountIn = 10 ** baseDecimals;
        (uint256 amountOut, address dex) = IDEXAggregator(_aggregator)
            .getAmountOut(address(0), _baseToken, _quoteToken, amountIn);
        return (
            amountOut.mul(1e18) / amountIn,
            (10 ** quoteDecimals).mul(1e18) / (10 ** baseDecimals),
            dex
        );
    }

    function bestUsdPrice(
        address _token,
        address _aggregator
    ) external view returns (uint256, uint256, address) {
        return bestPrice(_token, usd, _aggregator);
    }

    // returns (price, precision)
    function priceWithAmountIn(
        address _baseToken,
        address _quoteToken,
        uint256 _amountIn,
        address _dex
    ) public view returns (uint256, uint256) {
        uint256 baseDecimals = IERC20(_baseToken).decimals();
        uint256 quoteDecimals = IERC20(_quoteToken).decimals();
        uint256 amountOut = IDEX(_dex).getAmountOut(
            _baseToken,
            _quoteToken,
            _amountIn
        );
        return (
            amountOut.mul(1e18) / _amountIn,
            (10 ** quoteDecimals).mul(1e18) / (10 ** baseDecimals)
        );
    }

    function usdPriceWithAmountIn(
        address _token,
        uint256 _amountIn,
        address _dex
    ) public view returns (uint256, uint256) {
        return priceWithAmountIn(_token, usd, _amountIn, _dex);
    }

    // returns (price, precision, dex)
    function bestPriceWithAmountIn(
        address _baseToken,
        address _quoteToken,
        uint256 _amountIn,
        address _aggregator
    ) public view returns (uint256, uint256, address) {
        uint256 baseDecimals = IERC20(_baseToken).decimals();
        uint256 quoteDecimals = IERC20(_quoteToken).decimals();
        (uint256 amountOut, address dex) = IDEXAggregator(_aggregator)
            .getAmountOut(address(0), _baseToken, _quoteToken, _amountIn);
        return (
            amountOut.mul(1e18) / _amountIn,
            (10 ** quoteDecimals).mul(1e18) / (10 ** baseDecimals),
            dex
        );
    }

    function bestUsdPriceWithAmountIn(
        address _token,
        uint256 _amountIn,
        address _aggregator
    ) external view returns (uint256, uint256, address) {
        return bestPriceWithAmountIn(_token, usd, _amountIn, _aggregator);
    }
}