/**
 *Submitted for verification at ArbiScan.io on 2023-02-11
*/

/**
Telegram: https://t.me/Quicky_TG
Website: https://quickintel.io
Twitter: https://twitter.com/quicki_erc
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./QuickiDividendTracker.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./WaveMapping.sol";
import "./Counters.sol";

contract Quicki is ERC20, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    string private constant _name = "Quick Intel";
    string private constant _symbol = "QUICKI";
    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1e12 * 10**18;

    IUniswapV2Router02 private uniswapV2Router =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    bool private tradingOpen = false;
    bool public waveActive = false;
    bool private waveEnabled = false;
    uint256 private launchBlock = 0;
    address private uniswapV2Pair;

    mapping(address => bool) private automatedMarketMakerPairs;
    mapping(address => bool) public isExcludeFromFee;
    mapping(address => bool) private isBot;
    mapping(address => bool) private canClaimUnclaimed;
    mapping(address => bool) public isExcludeFromMaxWalletAmount;

    uint256 public maxWalletAmount;

    uint256 private baseBuyTax = 30;
    uint256 private baseSellTax = 30;
    uint256 private buyRewards = 3;
    uint256 private sellRewards = 3;
    uint256 private waveJeetTax;
    uint256 private waveEnabledJeetTax = 10;

    uint256 private autoLP = 30;
    uint256 private devFee = 40;
    uint256 private teamFee = 20;
    uint256 private buybackFee = 10;

    uint256 private minContractTokensToSwap = 2e9 * 10**_decimals;
    uint256 public minWaveIncludeAmount = 110000000 * 10**_decimals;
    uint256 public minWaveActivationCount = 11;

    WaveMapping public waveMap;

    address private devWalletAddress;
    address private teamWalletAddress;
    address private buyBackWalletAddress;

    QuickiDividendTracker public dividendTracker;
    QuickiDividendTracker private waveDivTracker;

    uint256 public pendingTokensForReward;

    uint256 private pendingEthReward;

    uint256 public totalETHRewardsPaidOut;

    struct WaveWins {
        address divTrackerWin;
        uint256 timestamp;
    }

    Counters.Counter private waveParticipationHistoryIds;

    mapping(uint256 => WaveWins) private waveWinsMap;
    mapping(address => uint256[]) private waveWinIds;

    event BuyFees(address from, address to, uint256 amountTokens);
    event SellFees(address from, address to, uint256 amountTokens);
    event AddLiquidity(uint256 amountTokens, uint256 amountEth);
    event SwapTokensForEth(uint256 sentTokens, uint256 receivedEth);
    event SwapEthForTokens(uint256 sentEth, uint256 receivedTokens);
    event DistributeFees(uint256 devEth, uint256 remarketingEth, uint256 rebuybackFees);

    event SendWaveDividends(uint256 amount);

    event DividendClaimed(uint256 ethAmount, address account);

    constructor(
        address _devWalletAddress,
        address _teamWalletAddress,
        address _buyBackWalletAddress
    ) ERC20(_name, _symbol) {
        devWalletAddress = _devWalletAddress;
        teamWalletAddress = _teamWalletAddress;
        buyBackWalletAddress = _buyBackWalletAddress;

        maxWalletAmount = (_tTotal * 1) / 10000; // 0.01% maxWalletAmount (initial limit)

        waveMap = new WaveMapping();

        dividendTracker = new QuickiDividendTracker();
        dividendTracker.excludeFromDividends(address(dividendTracker));
        dividendTracker.excludeFromDividends(address(this));
        dividendTracker.excludeFromDividends(owner());
        dividendTracker.excludeFromDividends(address(uniswapV2Router));

        isExcludeFromFee[owner()] = true;
        isExcludeFromFee[address(this)] = true;
        isExcludeFromFee[devWalletAddress] = true;
        isExcludeFromFee[teamWalletAddress] = true;
        isExcludeFromFee[buyBackWalletAddress] = true;
        isExcludeFromMaxWalletAmount[owner()] = true;
        isExcludeFromMaxWalletAmount[address(this)] = true;
        isExcludeFromMaxWalletAmount[address(uniswapV2Router)] = true;
        isExcludeFromMaxWalletAmount[devWalletAddress] = true;
        isExcludeFromMaxWalletAmount[teamWalletAddress] = true;
        isExcludeFromMaxWalletAmount[buyBackWalletAddress] = true;
        canClaimUnclaimed[owner()] = true;
        canClaimUnclaimed[address(this)] = true;

        _mint(owner(), _tTotal);

    }

    /**
     * @dev Function to recover any ETH sent to Contract by Mistake.
    */
    function withdrawStuckETH(bool pendingETH) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        bool success;
        (success, ) = address(msg.sender).call{ value: address(this).balance.sub(pendingEthReward) }(
            ""
        );

        if(pendingETH) {
            require(pendingEthReward > 0, "NER");

            bool pendingETHsuccess;
            (pendingETHsuccess, ) = address(msg.sender).call{ value: pendingEthReward }(
                ""
            );

            if (pendingETHsuccess) {
                pendingEthReward = pendingEthReward.sub(pendingEthReward);
            }
        }
    }

    /**
     * @dev Function to recover any ERC20 Tokens sent to Contract by Mistake.
    */
    function recoverAccidentalERC20(address _tokenAddr, address _to) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 _amount = IERC20(_tokenAddr).balanceOf(address(this));
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    function setSniperProtect() external onlyOwner {
        require(!tradingOpen, "TOP1");
        
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isExcludeFromMaxWalletAmount[address(uniswapV2Pair)] = true;

        automatedMarketMakerPairs[uniswapV2Pair] = true;
        dividendTracker.excludeFromDividends(uniswapV2Pair);

        addLiquidity(balanceOf(address(this)), address(this).balance);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        tradingOpen = true;
        launchBlock = block.number;
    }

    function manualSwap() external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        uint256 totalTokens = balanceOf(address(this)).sub(
            pendingTokensForReward
        );

        swapTokensForEth(totalTokens);

    }

    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        require(!isBot[_from] && !isBot[_to]);

        uint256 transferAmount = _amount;
        if (
            tradingOpen &&
            (automatedMarketMakerPairs[_from] ||
                automatedMarketMakerPairs[_to]) &&
            !isExcludeFromFee[_from] &&
            !isExcludeFromFee[_to]
        ) {
            
            transferAmount = takeFees(_from, _to, _amount);
        }

        if (!automatedMarketMakerPairs[_to] && !isExcludeFromMaxWalletAmount[_to]) {
            require(balanceOf(_to) + transferAmount <= maxWalletAmount,
                "WBL"
            );
        }

        super._transfer(_from, _to, transferAmount);

    }

    function claimUnclaimed(address waveDivAddress, address payable _unclaimedAccount, address payable _account) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        waveDivTracker = QuickiDividendTracker(payable(waveDivAddress));
        
        uint256 withdrawableAmount = waveDivTracker.withdrawableDividendOf(_unclaimedAccount);
        require(withdrawableAmount > 0,
            "NWD"
        );

        uint256 ethAmount;

        ethAmount = waveDivTracker.processAccount(_unclaimedAccount, _account);

        if (ethAmount > 0) {
            waveDivTracker.setBalance(_unclaimedAccount, 0);

            emit DividendClaimed(ethAmount, _unclaimedAccount);
        }
    }

    function claim(address waveDivAddress) external {
        _claim(waveDivAddress, payable(msg.sender));
    }

    function _claim(address waveDivAddress, address payable _account) private {
        waveDivTracker = QuickiDividendTracker(payable(waveDivAddress));

        uint256 withdrawableAmount = waveDivTracker.withdrawableDividendOf(
            _account
        );
        require(
            withdrawableAmount > 0,
            "NWD"
        );
        uint256 ethAmount;

        ethAmount = waveDivTracker.processAccount(_account, _account);

        if (ethAmount > 0) {
            waveDivTracker.setBalance(_account, 0);

            emit DividendClaimed(ethAmount, _account);
        }
    }

    function checkWaveWinnings(address waveDivAddress, address _account) public view returns (uint256) {
        return QuickiDividendTracker(payable(waveDivAddress)).withdrawableDividendOf(_account);
    }

    function _setAutomatedMarketMakerPair(address _pair, bool _value) private {
        require(
            automatedMarketMakerPairs[_pair] != _value,
            "AMMS"
        );
        automatedMarketMakerPairs[_pair] = _value;
    }

    function setExcludeFromFee(address _address, bool _isExludeFromFee)
        external onlyOwner {
        isExcludeFromFee[_address] = _isExludeFromFee;
    }

    function setExcludeFromMaxWalletAmount(address _address, bool _isExludeFromMaxWalletAmount)
        external onlyOwner {
        isExcludeFromMaxWalletAmount[_address] = _isExludeFromMaxWalletAmount;
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet >= (totalSupply() * 1 / 1000)/1e18, "MWLP");
        maxWalletAmount = newMaxWallet * (10**_decimals);
    }

    function isIncludeInWave(address _address) public view returns (bool) {
        return waveMap.isPartOfWave(_address);
    }

    function setTaxes(
        uint256 _baseBuyTax,
        uint256 _buyRewards,
        uint256 _baseSellTax,
        uint256 _waveEnabledJeetTax,
        uint256 _sellRewards,
        uint256 _autoLP,
        uint256 _devFee,
        uint256 _teamFee,
        uint256 _buybackFee
    ) external onlyOwner {
        require(_baseBuyTax <= 10 && _baseSellTax <= 10);

        baseBuyTax = _baseBuyTax;
        buyRewards = _buyRewards;
        baseSellTax = _baseSellTax;
        sellRewards = _sellRewards;
        waveEnabledJeetTax = _waveEnabledJeetTax;
        autoLP = _autoLP;
        devFee = _devFee;
        teamFee = _teamFee;
        buybackFee =_buybackFee;
    }

    function setMinParams(uint256 _numTokenContractTokensToSwap, uint256 _minWaveActivationCount, uint256 _minWaveIncludeAmount) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        minContractTokensToSwap = _numTokenContractTokensToSwap * 10 ** _decimals;
        minWaveActivationCount = _minWaveActivationCount;
        minWaveIncludeAmount = _minWaveIncludeAmount * 10 ** _decimals;
    }

    function setBots(address[] calldata _bots) public onlyOwner {
        for (uint256 i = 0; i < _bots.length; i++) {
            if (
                _bots[i] != uniswapV2Pair &&
                _bots[i] != address(uniswapV2Router)
            ) {
                isBot[_bots[i]] = true;
            }
        }
    }

    function setWalletAddress(address _devWalletAddress, address _teamWalletAddress, address _buyBackWalletAddress) external onlyOwner {
        devWalletAddress = _devWalletAddress;
        teamWalletAddress = _teamWalletAddress;
        buyBackWalletAddress = _buyBackWalletAddress;
    }

    function takeFees(
        address _from,
        address _to,
        uint256 _amount
    ) private returns (uint256) {
        uint256 fees;
        uint256 remainingAmount;
        require(
            automatedMarketMakerPairs[_from] || automatedMarketMakerPairs[_to],
            "NMM"
        );

        if (automatedMarketMakerPairs[_from]) {
            uint256 totalBuyTax;

            if(waveEnabled) {
                totalBuyTax = baseBuyTax.add(buyRewards);
            } else {
                totalBuyTax = baseBuyTax;
            }

            fees = _amount.mul(totalBuyTax).div(100);


            if(waveEnabled) {
                uint256 rewardTokens = _amount.mul(buyRewards).div(100);

                pendingTokensForReward = pendingTokensForReward.add(rewardTokens);
            }

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);
            
            if (waveEnabled && _amount >= minWaveIncludeAmount) {
                if(!waveActive) {
                    waveJeetTax = 0;
                }

                if (!waveMap.isPartOfWave(_to)) {
                
                    waveMap.includeToWaveMap(_to);

                    if (!dividendTracker.isBrokeOutOfWave(_to)) {
                        addHolderToWaveWinHistory(_to, address(dividendTracker));
                    }

                }

                dividendTracker.includeFromDividends(_to, balanceOf(_to).add(remainingAmount));
                    
                dividendTracker._brokeOutOfWave(_to, false);
                
            }

            if (waveMap.getNumberOfWaveHolders() >= minWaveActivationCount) {
                waveActive = true;

                waveJeetTax = waveEnabledJeetTax;
            }

            emit BuyFees(_from, address(this), fees);
        } else {
            uint256 totalSellTax;
            
            if(waveEnabled) {
                totalSellTax = baseSellTax.add(sellRewards).add(waveJeetTax);

                if(waveJeetTax > 0) {
                    uint256 jeetExtraTax = waveJeetTax.div(4);

                    uint256 rewardTokens = _amount.mul(sellRewards.add(jeetExtraTax)).div(100);

                    pendingTokensForReward = pendingTokensForReward.add(rewardTokens);
                } else {

                    uint256 rewardTokens = _amount.mul(sellRewards).div(100);

                    pendingTokensForReward = pendingTokensForReward.add(rewardTokens);
                }
            } else {
                totalSellTax = baseSellTax;
            }

            if(totalSellTax > 15) {
                totalSellTax = 15;
            }

            fees = _amount.mul(totalSellTax).div(100);

            remainingAmount = _amount.sub(fees);

            super._transfer(_from, address(this), fees);

            if(waveEnabled) {

                waveMap.excludeToWaveMap(_from);

                dividendTracker.setBalance(payable(_from), 0);

                dividendTracker._brokeOutOfWave(_from, true);
            }

            uint256 tokensToSwap = balanceOf(address(this)).sub(
                pendingTokensForReward);

            if (tokensToSwap > minContractTokensToSwap && !waveActive) {
                distributeTokensEth(tokensToSwap);
            }

            if (waveActive) {
                swapAndSendWaveDividends(pendingTokensForReward);
            }

            emit SellFees(_from, address(this), fees);
        }

        return remainingAmount;
    }

    function endWave() private {
        waveActive = false;

        delete waveMap;

        waveMap = new WaveMapping();

        dividendTracker = new QuickiDividendTracker();
    }

    function addHolderToWaveWinHistory(address _account, address _waveDivAddress) private {
        waveParticipationHistoryIds.increment();
        uint256 hId = waveParticipationHistoryIds.current();
        waveWinsMap[hId].divTrackerWin = _waveDivAddress;
        waveWinsMap[hId].timestamp = block.timestamp;

        waveWinIds[_account].push(hId);
    }

    function distributeTokensEth(uint256 _tokenAmount) private {
        uint256 tokensForLiquidity = _tokenAmount.mul(autoLP).div(100);

        uint256 halfLiquidity = tokensForLiquidity.div(2);
        uint256 tokensForSwap = _tokenAmount.sub(halfLiquidity);

        uint256 totalEth = swapTokensForEth(tokensForSwap);

        uint256 ethForAddLP = totalEth.mul(autoLP).div(100);
        uint256 devFeesToSend = totalEth.mul(devFee).div(100);
        uint256 teamFeesToSend = totalEth.mul(teamFee).div(100);
        uint256 buybackFeesToSend = totalEth.mul(buybackFee).div(100);
        uint256 remainingEthForFees = totalEth
            .sub(ethForAddLP)
            .sub(devFeesToSend)
            .sub(teamFeesToSend)
            .sub(buybackFeesToSend);
        devFeesToSend = devFeesToSend.add(remainingEthForFees);

        sendEthToWallets(devFeesToSend, teamFeesToSend, buybackFeesToSend);

        if (halfLiquidity > 0 && ethForAddLP > 0) {
            addLiquidity(halfLiquidity, ethForAddLP);
        }
    }

    function sendEthToWallets(uint256 _devFees, uint256 _teamFees, uint256 _buybackFees) private {
        if (_devFees > 0) {
            payable(devWalletAddress).transfer(_devFees);
        }
        if (_teamFees > 0) {
            payable(teamWalletAddress).transfer(_teamFees);
        }
        if (_buybackFees > 0) {
            payable(buyBackWalletAddress).transfer(_buybackFees);
        }
        emit DistributeFees(_devFees, _teamFees, _buybackFees);
    }

    function swapTokensForEth(uint256 _tokenAmount) private returns (uint256) {
        uint256 initialEthBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 receivedEth = address(this).balance.sub(initialEthBalance);

        emit SwapTokensForEth(_tokenAmount, receivedEth);
        return receivedEth;
    }

    function swapEthForTokens(uint256 _ethAmount, address _to) private returns (uint256) {
        uint256 initialTokenBalance = balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: _ethAmount
        }(0, path, _to, block.timestamp);

        uint256 receivedTokens = balanceOf(address(this)).sub(
            initialTokenBalance
        );

        emit SwapEthForTokens(_ethAmount, receivedTokens);
        return receivedTokens;
    }

    function addLiquidity(uint256 _tokenAmount, uint256 _ethAmount) private {
        _approve(address(this), address(uniswapV2Router), _tokenAmount);
        uniswapV2Router.addLiquidityETH{value: _ethAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
        emit AddLiquidity(_tokenAmount, _ethAmount);
    }

    function swapAndSendWaveDividends(uint256 _tokenAmount) private {
        addHolderToWaveWinHistory(address(this), address(dividendTracker));

        uint256 pendingRewardsEth = swapTokensForEth(_tokenAmount);

        pendingTokensForReward = pendingTokensForReward.sub(_tokenAmount);

        (bool success, ) = address(dividendTracker).call{value: pendingRewardsEth}(
            ""
        );

        if (success) {
            emit SendWaveDividends(pendingRewardsEth);

            dividendTracker.distributeDividends();

            dividendTracker.setWaveEnded();

            endWave();
        } else {
            pendingEthReward = pendingEthReward.add(pendingRewardsEth);

            endWave();
        }

        totalETHRewardsPaidOut = totalETHRewardsPaidOut.add(pendingRewardsEth);

    }

    function enableWave(bool state) external {
        require(canClaimUnclaimed[msg.sender], "UTC");
        waveEnabled = state;
    }

    function availableContractTokenBalance() external view returns (uint256) {
        return balanceOf(address(this)).sub(pendingTokensForReward);
    }

    function getBuyTax() public view returns (uint256) {
        if(waveEnabled) {
            return baseBuyTax.add(buyRewards);
        } else {
            return baseBuyTax;
        }
    }

    function getSellTax() public view returns (uint256) {
        if(waveEnabled) {
            return baseSellTax.add(sellRewards).add(waveJeetTax);
        } else {
            return baseSellTax;
        }
    }

    function getNumberOfWaveHolders() external view returns (uint256) {
        return waveMap.getNumberOfWaveHolders();
    }

     function getWinningHistory(
        address _account,
        uint256 _limit,
        uint256 _pageNumber
    ) external view returns (WaveWins[] memory) {
        require(_limit > 0 && _pageNumber > 0, "IA");
        uint256 waveWinCount = waveWinIds[_account].length;
        uint256 end = _pageNumber * _limit;
        uint256 start = end - _limit;
        require(start < waveWinCount, "OOR");
        uint256 limit = _limit;
        if (end > waveWinCount) {
            end = waveWinCount;
            limit = waveWinCount % _limit;
        }

        WaveWins[] memory myWaveWins = new WaveWins[](limit);
        uint256 currentIndex = 0;
        for (uint256 i = start; i < end; i++) {
            uint256 hId = waveWinIds[_account][i];
            myWaveWins[currentIndex] = waveWinsMap[hId];
            currentIndex += 1;
        }
        return myWaveWins;
    }

    function getWinningHistoryCount(address _account) external view returns (uint256) {
        return waveWinIds[_account].length;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library Counters {
    struct Counter {
        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Ownable.sol";
import "./Counters.sol";

contract WaveMapping is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private waveHoldersCount;

    mapping(address => bool) private waveHoldersMap;

    function includeToWaveMap(address account) external onlyOwner {
        if (waveHoldersMap[account] == false) {
            waveHoldersMap[account] = true;
            waveHoldersCount.increment();
            }
    }

    function excludeToWaveMap(address account) external onlyOwner {
        if (waveHoldersMap[account] == true) {
            waveHoldersMap[account] = false;
            waveHoldersCount.decrement();
            }
    }

    function setIncludeToWaveMap(address _address, bool _isIncludeToWaveMap) external onlyOwner {
        waveHoldersMap[_address] = _isIncludeToWaveMap;
    }

    function isPartOfWave(address _address) external view returns (bool) {
        return waveHoldersMap[_address];
    }

    function getNumberOfWaveHolders() external view returns (uint256) {
        return waveHoldersCount.current();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidityETH(
      address token,
      uint liquidity,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
    ) external returns (uint amountToken, uint amountETH); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
     
    function createPair(address tokenA, address tokenB) external returns (address pair);
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Ownable {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./DividendPayingToken.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract QuickiDividendTracker is DividendPayingToken, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private tokenHoldersCount;
    mapping(address => bool) private tokenHoldersMap;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => bool) public brokeOutOfWave;

    mapping(address => uint256) public lastDateClaimed;

    bool public waveEnded = false;
    uint256 public waveEndedTimestamp;

    event ExcludeFromDividends(address indexed account);
    event ClaimInactive(address indexed account, uint256 amount);


    constructor() DividendPayingToken("Quicki_Dividend_Tracker","Quicki_Dividend_Tracker") {
    }

    function _approve(address, address, uint256) internal pure override {
        require(false, "Quicki_Dividend_Tracker: No approvals allowed");
    }

    function _transfer(address, address, uint256) internal pure override {
        require(false, "Quicki_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false,
            "Quicki_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Quicki contract."
        );
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;

        _setBalance(account, 0);

        if (tokenHoldersMap[account] == true) {
            tokenHoldersMap[account] = false;
            tokenHoldersCount.decrement();
        }

        emit ExcludeFromDividends(account);
    }

    function includeFromDividends(address account, uint256 balance) external onlyOwner {
        excludedFromDividends[account] = false;

        _setBalance(account, balance);

        if (tokenHoldersMap[account] == false) {
            tokenHoldersMap[account] = true;
            tokenHoldersCount.increment();
        }
        

        emit ExcludeFromDividends(account);
    }

    function isExcludeFromDividends(address account) external view onlyOwner returns (bool) {
        return excludedFromDividends[account];
    }

    function _brokeOutOfWave(address account, bool brokeOut) external onlyOwner {
        brokeOutOfWave[account] = brokeOut;
    }

    function isBrokeOutOfWave(address account) external view onlyOwner returns (bool) {
        return brokeOutOfWave[account];
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersCount.current();
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account]) {
            return;
        }

        _setBalance(account, newBalance);

        if (tokenHoldersMap[account] == false) {
            tokenHoldersMap[account] = true;
            tokenHoldersCount.increment();
        }
    }

    function setWaveEnded() external onlyOwner {
        waveEnded = true;
        waveEndedTimestamp = block.timestamp;
    }

    function processAccount(address account, address toAccount) public onlyOwner returns (uint256) {
        uint256 amount = _withdrawDividendOfUser(
            payable(account),
            payable(toAccount)
        );

        lastDateClaimed[account] = block.timestamp;

        return amount;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./SignedSafeMath.sol";
import "./SafeCast.sol";
import "./DividendPayingTokenInterface.sol";
import "./DividendPayingTokenOptionalInterface.sol";

abstract contract DividendPayingToken is
    ERC20,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface
{
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public pendingDividendsToDistribute;
    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    receive() external payable {
        pendingDividendsToDistribute = pendingDividendsToDistribute.add(msg.value);
    }

    function distributeDividends() public payable {
        require(totalSupply() > 0);

        require(pendingDividendsToDistribute > 0, "There are no dividends currently available to distribute.");

        if (pendingDividendsToDistribute > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add(
                (pendingDividendsToDistribute).mul(magnitude) / totalSupply()
            );
            emit DividendsDistributed(msg.sender, pendingDividendsToDistribute);

            totalDividendsDistributed = totalDividendsDistributed.add(pendingDividendsToDistribute);
            pendingDividendsToDistribute = pendingDividendsToDistribute.sub(pendingDividendsToDistribute);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender), payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user, address payable to)
        internal
        returns (uint256)
    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(
                _withdrawableDividend
            );
            emit DividendWithdrawn(user, _withdrawableDividend, to);
            (bool success, ) = to.call{value: _withdrawableDividend}("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(
                    _withdrawableDividend
                );
                return 0;
            }

            return _withdrawableDividend;
        }

        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns (uint256) {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns (uint256) {
        return
            magnifiedDividendPerShare
                .mul(balanceOf(_owner))
                .toInt256()
                .add(magnifiedDividendCorrections[_owner])
                .toUint256() / magnitude;
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);

        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].sub((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[
            account
        ].add((magnifiedDividendPerShare.mul(value)).toInt256());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);

        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }

    function getAccount(address _account) public view returns (uint256 _withdrawableDividends, uint256 _withdrawnDividends) {
        _withdrawableDividends = withdrawableDividendOf(_account);
        _withdrawnDividends = withdrawnDividends[_account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface DividendPayingTokenInterface {
    function dividendOf(address _owner) external view returns (uint256);

    function withdrawDividend() external;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(
        address indexed to,
        uint256 weiAmount,
        address received
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(
            value <= type(uint224).max,
            "SafeCast: value doesn't fit in 224 bits"
        );
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(
            value <= type(uint128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(
            value <= type(uint96).max,
            "SafeCast: value doesn't fit in 96 bits"
        );
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(
            value <= type(uint64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(
            value <= type(uint32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(
            value <= type(uint16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(
            value <= type(uint8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library SignedSafeMath {
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
import "./SafeMath.sol";

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}