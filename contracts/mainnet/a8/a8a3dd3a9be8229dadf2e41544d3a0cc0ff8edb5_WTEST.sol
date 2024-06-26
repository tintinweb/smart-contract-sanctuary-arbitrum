// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./ERC20.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";
import "./AggregatorV3Interface.sol";

contract WTEST is Context, ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public buyTaxes;
    uint256 public sellTaxes;

    mapping(address => bool) public pair;
    mapping (address => bool) public _isExcludedFromFees;

    uint256 private start;
    uint256 private end;

    uint256 public swapTokensAtAmount;
    uint256 public initialDeploymentTime;

    bool public swapping;
    bool public taxDisabled;

    uint256 private maxWalletTimer;
    uint256 private started;
    uint256 private maxWallet;
    uint256 private _supply;

    address payable teamWallet;
    address payable waterWallet;

    event TaxesSent(
        address taxWallet,
        uint256 ETHAmount
    );

    event TaxesReduce(
        uint256 oldBuyTax,
        uint256 oldSellTax,
        uint256 newBuyTax,
        uint256 newSellTax
    );

    event TradingPairAdded(
        address indexed newPair
    );

    constructor(address payable _teamWallet, address payable _waterWallet) ERC20("WTEST", "$WTEST") Ownable(msg.sender) {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Router address for Uniswap Mainnet
        uniswapV2Pair = address(0);

        teamWallet = _teamWallet;
        waterWallet = _waterWallet;
        _supply = 1 * 10 ** 9 * 10 ** decimals();
        buyTaxes = 300;
        sellTaxes = 300;
        maxWallet = ((_supply * 93) / 10000); // Max wallet of 0.93% of total supply
        swapTokensAtAmount = ((_supply * 25) / 10000); // Swap 0.25% of total supply
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(waterWallet)] = true;

        _mint(owner(), (_supply * 7976) / 10000);
        _mint(address(payable(waterWallet)), (_supply * 2024) / 10000);
    }

    receive() external payable {

  	}

    function addPair(address toPair) public onlyOwner {
        
        uniswapV2Pair = toPair;
        start = block.number;
        initialDeploymentTime = block.timestamp;
        pair[toPair] = true;
        maxWalletTimer = 1800;

        emit TradingPairAdded(toPair);
    }

    function taxReduce() private {
        uint256 swapTime = block.timestamp;
        uint256 _buyTaxes = buyTaxes;
        uint256 _sellTaxes = sellTaxes;

        if(swapTime > initialDeploymentTime + 30 minutes) {
            buyTaxes = 0;
            sellTaxes = 0;
            taxDisabled = true;

            emit TaxesReduce(_buyTaxes, _sellTaxes, buyTaxes, sellTaxes);
        } else if(swapTime > initialDeploymentTime + 20 minutes) {
            buyTaxes = 10;
            sellTaxes = 10;

            emit TaxesReduce(_buyTaxes, _sellTaxes, buyTaxes, sellTaxes);
        }
    }

    function getTokenPriceInUSD(uint256 _amount) public view returns (uint256) {
        // Import the Chainlink AggregatorV3Interface contract
        AggregatorV3Interface ethUsdPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); // ETH/USD Price Feed

        address pairAddress = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pairAddress).getReserves();

        // Ensure non-zero reserves
        require(reserve0 > 0 && reserve1 > 0, "Reserves are zero");

        uint256 tokenPriceInETH;

        if (address(this) < uniswapV2Router.WETH()) { // token is token0
            tokenPriceInETH = (uint256(reserve1) * 10**decimals()) / reserve0;
        } else { // token is token1
            tokenPriceInETH = (uint256(reserve0) * 10**decimals()) / reserve1;
        }

        // Get the price of ETH in USD from Chainlink
        (, int price,, ,) = ethUsdPriceFeed.latestRoundData();
        uint8 chainlinkDecimals = ethUsdPriceFeed.decimals();

        // Adjust for Chainlink's decimals
        uint256 adjustedEthPriceInUSD = uint256(price) * 10**(decimals() - chainlinkDecimals);

        uint256 tokenPrice = (tokenPriceInETH * adjustedEthPriceInUSD) / 10**decimals();

        // Calculate the MC in USD
        uint256 mcUsd = ((tokenPrice * _amount) / 10 ** decimals());

        return mcUsd;
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        uint256 transferValue;
        if(uniswapV2Pair != address(0) && !taxDisabled && to != owner()) {
            taxReduce();
            transferValue = getTokenPriceInUSD(amount);
        }
        
        if(uniswapV2Pair == address(0) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            revert("Trading is not yet active");
        }

        if((block.timestamp < (initialDeploymentTime + maxWalletTimer)) && to != address(0) && to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            uint256 balance = balanceOf(to);
            require(balance + amount <= maxWallet, "Transfer amount exceeds maximum wallet");
        }

		uint256 contractTokenBalance = (balanceOf(address(this)));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        

        if(taxDisabled && contractTokenBalance > 0) {
            canSwap = true;
        }
		
		if(canSwap && !swapping && pair[to] && from != address(uniswapV2Router) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from] && transferValue >= 300) {

		   contractTokenBalance = contractTokenBalance > swapTokensAtAmount ? swapTokensAtAmount : contractTokenBalance;
            swapping = true;
                
            swapTokensForEth(contractTokenBalance);

            uint256 taxAmount = address(this).balance;
            (bool success, ) = address(teamWallet).call{value: taxAmount}("");
            require(success, "Failed to send marketing fee");

            emit TaxesSent(address(teamWallet), taxAmount);

            swapping = false;
        }

        bool takeFee = !swapping;

         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || taxDisabled) {
            takeFee = false;
            super._update(from, to, amount);
        }

        else if(!pair[to] && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            takeFee = false;
            super._update(from, to, amount);
        }

        if(takeFee) {

            uint256 BuyFees = ((amount * buyTaxes) / 1000);
            uint256 SellFees = ((amount * sellTaxes) / 1000);

            // if sell
            if(pair[to] && sellTaxes > 0) {
                amount -= SellFees;
                
                super._update(from, address(this), SellFees);
                super._update(from, to, amount);
            }

            // if buy transfer
            else if(pair[from] && buyTaxes > 0) {
                amount -= BuyFees;

                super._update(from, address(this), BuyFees);
                super._update(from, to, amount);
                }

            else {
                super._update(from, to, amount);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}