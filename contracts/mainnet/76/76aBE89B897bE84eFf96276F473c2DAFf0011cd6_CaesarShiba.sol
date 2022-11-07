/**
 ______    ______   ________   ______    ______   _______          ______   __    __  ______  _______    ______
 /      \  /      \ |        \ /      \  /      \ |       \        /      \ |  \  |  \|      \|       \  /      \
|  $$$$$$\|  $$$$$$\| $$$$$$$$|  $$$$$$\|  $$$$$$\| $$$$$$$\      |  $$$$$$\| $$  | $$ \$$$$$$| $$$$$$$\|  $$$$$$\
| $$   \$$| $$__| $$| $$__    | $$___\$$| $$__| $$| $$__| $$      | $$___\$$| $$__| $$  | $$  | $$__/ $$| $$__| $$
| $$      | $$    $$| $$  \    \$$    \ | $$    $$| $$    $$       \$$    \ | $$    $$  | $$  | $$    $$| $$    $$
| $$   __ | $$$$$$$$| $$$$$    _\$$$$$$\| $$$$$$$$| $$$$$$$\       _\$$$$$$\| $$$$$$$$  | $$  | $$$$$$$\| $$$$$$$$
| $$__/  \| $$  | $$| $$_____ |  \__| $$| $$  | $$| $$  | $$      |  \__| $$| $$  | $$ _| $$_ | $$__/ $$| $$  | $$
 \$$    $$| $$  | $$| $$     \ \$$    $$| $$  | $$| $$  | $$       \$$    $$| $$  | $$|   $$ \| $$    $$| $$  | $$
  \$$$$$$  \$$   \$$ \$$$$$$$$  \$$$$$$  \$$   \$$ \$$   \$$        \$$$$$$  \$$   \$$ \$$$$$$ \$$$$$$$  \$$   \$$


Website: http://caesarshiba.finance
Telegram: https://t.me/caesarshibaarbi
Twitter: https://twitter.com/CaesarShibaArbi
Discord: https://discord.gg/Ufch6uEX25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ERC20.sol';
import './SushiSwap.sol';
import './SafeMath.sol';

contract CaesarShiba is ERC20 {
    using SafeMath for uint256;

    // DEX router
    IUniswapV2Router02 public sushiswapRouter;
    address public sushiswapPair;
    address public chestAddress = 0x50bfe5291FC6277a922dE2408F8d954645124A23;
    address payable public marketingAddress = payable(0x32470161A22aab70039310EA6F501AD363D7C419);
    mapping (address => bool) public _isExcludedFromFee;
    address payable public _owner;
    bool public _manualSwap = true;
    uint public _feesLiquidity = 2;
    uint public _feesMarketing = 4;
    uint public _feesChest = 4;
    uint public _chestPercentWon = 20;
    uint toMint = 10 ** (18 + 8);
    uint public _minAmountToParticipate = toMint / 10000;
    uint minSwapAmount = toMint / 1000;
    uint maxSwapAmount = toMint / 100;
    uint public _maxWallet;
    // Chest infos
    uint public _maxChest;
    uint public _startTimeChest;
    uint public _minTimeHoldingChest = 60;
    address public _chestWonBy;
    address public _lastParticipantAddress;
    mapping (address => bool) private _isExcludedFromGame;
    // Presale
    bool public _presaleRunning = true;
    mapping (address => bool) _presale;

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Call authorized only for owner");
        _;
    }

    struct WinHistory {
        uint time;
        uint amount;
        address account;
    }

    WinHistory[] public _winningHistory;

    bool inSwapAndLiquify;
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() ERC20("CaesarShiba", "CSRA") {
        _owner = payable(msg.sender);

        address sushiswapRouterAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        sushiswapRouter = IUniswapV2Router02(sushiswapRouterAddress);
        sushiswapPair = IUniswapV2Factory(sushiswapRouter.factory()).createPair(address(this), sushiswapRouter.WETH());

        _isExcludedFromFee[_owner] = true;
        _isExcludedFromFee[marketingAddress] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[chestAddress] = true;
        _isExcludedFromFee[address(0)] = true;
        _isExcludedFromFee[sushiswapRouterAddress] = true;

        _isExcludedFromGame[chestAddress] = true;
        _isExcludedFromGame[address(this)] = true;
        _isExcludedFromGame[_owner] = true;
        _isExcludedFromGame[marketingAddress] = true;
        _isExcludedFromGame[address(0)] = true;
        _isExcludedFromGame[sushiswapPair] = true;
        _isExcludedFromGame[sushiswapRouterAddress] = true;

        _presale[chestAddress] = true;
        _presale[address(this)] = true;
        _presale[_owner] = true;
        _presale[marketingAddress] = true;
        _presale[address(0)] = true;
        _presale[sushiswapPair] = true;
        _presale[sushiswapRouterAddress] = true;

        _mint(msg.sender, toMint);
        _maxWallet = _totalSupply / 50;
        _maxChest = (_totalSupply / 100) * 3;
    }

    function launch() public onlyOwner{
        setManualSwap(false);
        setPresaleActivation(false);
    }

    function _addLiquidity(uint amountTokenDesired, uint amountETH) private
    {
        _approve(address(this), address(sushiswapRouter), amountTokenDesired);
        sushiswapRouter.addLiquidityETH{value: amountETH}(address(this), amountTokenDesired, 0, 0, _owner, block.timestamp);
    }

    function swapTokensForETH(uint amountToken) private
    {
        // Step 1 : approve
        _approve(address(this), address(sushiswapRouter), amountToken);

        // Step 2 : swapExactTokensForETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = sushiswapRouter.WETH();

        sushiswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(amountToken, 0, path, address(this), block.timestamp + 1 minutes);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /*amount*/
    ) internal override
    {
        bool isBuying = from == sushiswapPair;
        if (_presaleRunning && isBuying) {
            require(_presale[to], "Buys are reserved to whitelisted addresses during presale");
        }

        bool isSelling = to == sushiswapPair;
        if (isSelling && !_manualSwap && !inSwapAndLiquify && balanceOf(sushiswapPair) > 0)
        {
            _swapAndLiquify();
        }
    }


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override
    {
        if (!_presaleRunning) {
            manageChest(from, to, amount);
        }

        bool isBuying = from == sushiswapPair;
        if (!_presaleRunning && !_isExcludedFromFee[from] && !_isExcludedFromFee[to] && balanceOf(sushiswapPair) > 0)
        {
            if ((_feesLiquidity + _feesMarketing + _feesChest) > 0) {
                // bool isSelling = to == sushiswapPair;
                uint feesPercentage = _feesLiquidity.add(_feesMarketing);
                // use isSelling ? condition if sell taxes != buy taxes
                uint256 contractFeesAmount = amount.mul(feesPercentage).div(100);
                uint chestFeeAmount = amount.mul(_feesChest).div(100);
                _balances[to] = _balances[to].sub(contractFeesAmount.add(chestFeeAmount));
                _balances[address(this)] = _balances[address(this)].add(contractFeesAmount);
                _balances[chestAddress] = _balances[chestAddress].add(chestFeeAmount);
                if (_balances[chestAddress] > _maxChest) {
                    uint overflow = _balances[chestAddress].sub(_maxChest);
                    _balances[address(this)] = _balances[address(this)].add(overflow);
                    _balances[chestAddress] = _balances[chestAddress].sub(overflow);
                }
            }
        }
        // Anti whale
        if (isBuying && !_isExcludedFromFee[to]) {
            require(_balances[to] <= _maxWallet, "Impossible to hold more than max wallet");
        }
    }

    function _swapAndLiquify() internal lockTheSwap
    {
        uint contractBalance = _balances[address(this)];
        if (contractBalance > minSwapAmount || _manualSwap)
        {
            if (contractBalance > maxSwapAmount && !_manualSwap)
            {
                contractBalance = maxSwapAmount;
            }

            uint totalFees = _feesMarketing.add(_feesLiquidity);
            uint marketingTokens = contractBalance.mul(_feesMarketing).div(totalFees == 0 ? 1 : totalFees);
            uint liquidityTokens = contractBalance.sub(marketingTokens);
            uint liquidityTokensHalf = liquidityTokens.div(2);
            uint liquidityTokensOtherHalf = liquidityTokens.sub(liquidityTokensHalf);

            swapTokensForETH(marketingTokens.add(liquidityTokensHalf));
            uint amountETHToLiquefy = address(this).balance.mul(liquidityTokensHalf).div(marketingTokens.add(liquidityTokensHalf));
            _addLiquidity(liquidityTokensOtherHalf, amountETHToLiquefy);
            (bool sent,) = marketingAddress.call{value : address(this).balance}("");
            require(sent, "Failed to send Ether");
        }
    }

    function swapAndLiquify() public onlyOwner
    {
        _swapAndLiquify();
    }

    function checkReward() public {
        if (!inSwapAndLiquify && _startTimeChest > 0 && block.timestamp > _startTimeChest + _minTimeHoldingChest * 1 minutes) {
            // We have a winner
            _startTimeChest = 0;
            uint amountWon = _balances[chestAddress].mul(_chestPercentWon).div(100);
            _balances[_lastParticipantAddress] = _balances[_lastParticipantAddress].add(amountWon);
            _balances[chestAddress] = _balances[chestAddress].sub(amountWon);
            _chestWonBy = _lastParticipantAddress;
            _lastParticipantAddress = 0x000000000000000000000000000000000000dEaD;
            // Store all victories
            WinHistory memory winHistory;
            winHistory.time = block.timestamp;
            winHistory.amount = amountWon;
            winHistory.account = _chestWonBy;
            _winningHistory.push(winHistory);
        }
    }

    function manageChest(address from, address to, uint amount) private {
        checkReward();

        bool isBuying = from == sushiswapPair;
        if (isBuying && amount >= _minAmountToParticipate && !_isExcludedFromGame[to] && _lastParticipantAddress != to) {
            // Buyer is now owner of the chest
            _startTimeChest = block.timestamp;
            _lastParticipantAddress = to;
        }
    }

    receive() external payable {}

    function chestAmount() public view returns (uint) { return _balances[chestAddress]; }
    function historySize() public view returns (uint) { return _winningHistory.length; }

    function setMinAmountToParticipate(uint value) public onlyOwner {
        _minAmountToParticipate = value;
    }
    function setMinSwapAmount(uint value) public onlyOwner {
        minSwapAmount = value;
    }
    function setMaxSwapAmount(uint value) public onlyOwner {
        maxSwapAmount = value;
    }
    function setMaxWalletAmount(uint value) public onlyOwner {
        _maxWallet = value;
    }
    function setMaxChestAmount(uint value) public onlyOwner {
        _maxChest = value;
    }
    function setChestPercentWon(uint value) public onlyOwner {
        _chestPercentWon = value;
    }

    function setFeeLiquidity(uint value) public onlyOwner {
        _feesLiquidity = value;
    }
    function setFeeMarketing(uint value) public onlyOwner {
        _feesMarketing = value;
    }
    function setFeeChest(uint value) public onlyOwner {
        _feesChest = value;
    }

    function setMinTimeHoldingChest(uint value) public onlyOwner {
        _minTimeHoldingChest = value;
    }

    function setManualSwap(bool value) public onlyOwner {
        _manualSwap = value;
    }
    function setGameParticipation(bool value, address add) public onlyOwner {
        _isExcludedFromGame[add] = value;
    }
    function setTaxContribution(bool value, address add) public onlyOwner {
        _isExcludedFromFee[add] = value;
    }
    function setPresaleActivation(bool value) public onlyOwner {
        _presaleRunning = value;
    }
    function addToPresale(address account) public onlyOwner {
        _presale[account] = true;
    }

    /**
     * HELPER FUNCTIONS
     */
    function changeOwner(address newOwner) public onlyOwner {
        _owner = payable(newOwner);
    }

    function addLiquidityInit(uint amountTokenDesired) public payable onlyOwner
    {
        _balances[address(this)] += amountTokenDesired;
        _balances[msg.sender] -= amountTokenDesired;
        _approve(address(this), address(sushiswapRouter), amountTokenDesired);
        sushiswapRouter.addLiquidityETH{value: msg.value}(address(this), amountTokenDesired, 0, 0, msg.sender, block.timestamp);
    }

    function retrieveETHFromContract() public onlyOwner {
        (bool sent,) = _owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    function getETHBalance(address account) public view onlyOwner returns (uint) {
        return account.balance;
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    function isChestWon() public view returns(bool)
    {
        return !inSwapAndLiquify && _startTimeChest > 0 && block.timestamp > _startTimeChest + _minTimeHoldingChest * 1 minutes;
    }
}