// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IBespokeBasketV1.sol";
import "./IERC20.sol";
import "./IUniswapV2Router02.sol";
import "./ITrade.sol";

contract BasketShareManagerV1 is Ownable {

    address public weth;
    address public detraTrade;

    constructor(address _weth, address _detraTrade) {
        weth = _weth;
        detraTrade = _detraTrade;
    }

    function setDetraTrade(address _detraTrade) external onlyOwner {
        detraTrade = _detraTrade;
    }

    function swapForWeth(address _tokenInRouter, address _tokenIn, uint256 _amountIn) public {
        address[] memory path = new address[](2);
        path[1] = address(weth);
        path[0] = _tokenIn;

        uint[] memory amounts = IUniswapV2Router02(_tokenInRouter).getAmountsOut(_amountIn, path);

        IERC20(_tokenIn).transfer(detraTrade, amounts[0]);
        ITrade(detraTrade).trade(2, _tokenInRouter, amounts[0], amounts[1] - (amounts[1] * 1e16 / 1e18), path);
    }

    function getCostForTokens(
        address _basket,
        address _tokenInRouter,
        address[] memory _tokenList,
        uint256 _shares
    ) public view returns (uint256, uint256[] memory, uint256[] memory) {
        uint256[] memory portions = new uint256[](_tokenList.length);
        uint256[] memory costs = new uint256[](_tokenList.length);

        uint256 costForTokens = 0;
        for (uint i; i < _tokenList.length; i++) {
            uint256 portion = IBespokeBasketV1(_basket).tokenPortions(_tokenList[i]) * _shares / 1e18;
            portions[i] = portion;

            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = _tokenList[i];

            uint[] memory amounts = IUniswapV2Router02(_tokenInRouter).getAmountsIn(portion, path);

            costForTokens += amounts[0];
            costs[i] = amounts[0];
        }
        return (costForTokens, costs, portions);
    }

    function swapWethForTokens(
        uint256[] memory portions,
        uint256[] memory _tradeTypes,
        address[] memory _routers,
        address[] memory _tokenList,
        uint256[] memory costs
    ) public {
        for (uint i; i < portions.length; i++) {
            IERC20(weth).approve(_routers[i], costs[i]);

            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = _tokenList[i];

            uint[] memory amounts = IUniswapV2Router02(_routers[i]).getAmountsOut(costs[i], path);

            IERC20(weth).transfer(detraTrade, costs[i]);
            ITrade(detraTrade).trade(_tradeTypes[i], _routers[i], costs[i], amounts[1] - (amounts[1] * 1e16 / 1e18), path);
        }
    }

    function convertToShares(
        address _basket,
        address _tokenIn,
        address _tokenInRouter,
        uint256 _amountIn,
        uint256 _shares,
        uint256[] memory _tradeTypes,
        address[] calldata _tokenList,
        address[] calldata _routers
    ) public {
        require(_routers.length == _tokenList.length, "did not provide routers for tokens");
        IERC20(_tokenIn).transferFrom(msg.sender, address(this), _amountIn);

        if (_tokenIn != weth)
            swapForWeth(_tokenInRouter, _tokenIn, _amountIn);

        (uint256 costForTokens, uint256[] memory costs, uint256[] memory portions) = getCostForTokens(_basket, _tokenInRouter, _tokenList, _shares);

        require(costForTokens <= IERC20(weth).balanceOf(address(this)), "Must provide more eth");
        swapWethForTokens(portions, _tradeTypes, _routers, _tokenList, costs);

        for (uint i; i < portions.length; i++) {
            IERC20(_tokenList[i]).approve(_basket, (portions[i]) + 1);
        }

        IBespokeBasketV1(_basket).create(_shares);
        IERC20(_basket).transfer(msg.sender, IERC20(_basket).balanceOf(address(this)));
        IERC20(weth).transfer(msg.sender, IERC20(weth).balanceOf(address(this)));
        for (uint i; i < _tokenList.length; i++) {
            if (IERC20(_tokenList[i]).balanceOf(address(this)) > 0)
                IERC20(_tokenList[i]).transfer(msg.sender, IERC20(_tokenList[i]).balanceOf(address(this)));
        }
    }

    function withdrawETH(uint256 _amount, address payable _account) external onlyOwner {
        _account.transfer(_amount);
    }

    function withdraw(address _token, uint256 _amount, address _account) external onlyOwner {
        IERC20(_token).transfer(_account, _amount);
    }
}