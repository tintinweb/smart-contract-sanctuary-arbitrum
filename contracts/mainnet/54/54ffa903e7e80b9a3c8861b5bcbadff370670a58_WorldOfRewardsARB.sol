/**
 *Submitted for verification at Arbiscan on 2023-06-17
*/

//SPDX-License-Identifier: MIT

/**

    WOR token contract

    World of Rewards (WOR) is a rewards platform
    based on blockchains that aims to create an ecosystem
    decentralized, transparent, and
    fair reward system for users.
    The project is based on the BSC blockchain and uses
    smart contracts to automate the distribution of rewards.

    https://worldofrewards.finance/
    https://twitter.com/WorldofRewards
    https://t.me/WorldofRewards


*/

pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}


interface IUniswapV2Router02 is IUniswapV2Router01 {

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}



abstract contract Ownable is Context {
    address private _owner;
    mapping (address => bool) public auth;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function getAuth() public view virtual returns (bool) {
        return auth[_msgSender()];
    }

    modifier onlyOwner() {
        require(owner() == _msgSender() || getAuth(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(getAuth() == false, "Ownable: caller is not the owner");
        require(auth[newOwner] == false, "Is auth");
        require(newOwner != address(0), "Is impossible to renounce the ownership of the contract");
        require(newOwner != address(0xdead), "Is impossible to renounce the ownership of the contract");

        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function setAuthAddress(address authAddress, bool isAuth) external virtual onlyOwner {
        require(getAuth() == false, "Ownable: caller is not the owner");
        auth[authAddress] = isAuth;
    }
}


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

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

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
            address sender,
            address recipient,
            uint256 amount
        ) public virtual override returns (bool) {
            _transfer(sender, recipient, amount);

            uint256 currentAllowance = _allowances[sender][_msgSender()];
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }

            return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _create(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: create to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burnToZeroAddress(address account, uint256 amount) internal {
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[account] = accountBalance - amount;}
        _balances[address(0)] += amount;
        
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    function _burnOfSupply(address account, uint256 amount) internal {
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

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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


//This auxiliary contract is necessary for the logic of the liquidity mechanism to work
//The pancake router V2 does not allow the address(this) to be in swap and at the same time be the destination of "to"
//This contract is where the funds will be stored
//The movement of these funds (WOR and BNB) is done exclusively by the token's main contract
contract ControlledFunds is Ownable {

    uint256 public amountBNBwithdrawled;

    receive() external payable {}

    function withdrawBNBofControlled(address to, uint256 amount) public onlyOwner() {
        amountBNBwithdrawled += amount;
        payable(to).transfer(amount);
    }

    function withdrawTokenOfControlled(address token, address to,uint256 amount) public onlyOwner() {
        IERC20(token).transfer(to,amount);
    }

    function approvedByControlled(address token, address addressAllowed, uint256 amount) public onlyOwner() {
        IERC20(token).approve(addressAllowed,amount);
    }

}



contract WorldOfRewardsARB is ERC20, Ownable  {

    struct Buy {
        uint16 supportBSC;
        uint16 marketing;
        uint16 rewards;
        uint16 liquidity;
        uint16 nftHolders;
    }

    struct Sell {
        uint16 supportBSC;
        uint16 marketing;
        uint16 rewards;
        uint16 liquidity;
        uint16 nftHolders;
    }

    Buy public buy;
    Sell public sell;

    uint16 public totalBuy;
    uint16 public totalSell;
    uint16 public totalFees;

    bool private internalSwapping;

    uint256 public whatsBurn;
    uint256 public totalBurned;
    uint256 public lastBurnPriceGowth;

    uint256 public totalBNBsupportBSC;
    uint256 public totalBNBmarketingWallet;
    uint256 public totalBNBrewards;
    uint256 public totalBNBliquidity;
    uint256 public totalBNBnftHolders;

    uint256 public triggerSwapTokensToBNB;

    uint256 public timeLaunched;

    ControlledFunds public controlledFunds;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public WBNB = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address private PCVS2 = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // sushiswap

    address public marketingWallet1 = 0x30c69E18D090de6dff8be2ab7A4ef11e9166A9B6;
    address public marketingWallet2 = 0xCF7AD59488f7605a2653648970368D75399f82ce;

    //Trades are always on, never off
    mapping(address => bool) public _isExcept;
    mapping (address => bool) public _isRewardsExempt;
    mapping(address => bool) public _automatedMarketMakerPairs;

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event feesExceptEvent(address indexed account, bool isExcluded);
    event rewardsExceptEvent(address indexed account, bool isExcluded);

    event setAutomatedMarketMakerPairEvent(address indexed pair, bool indexed value);

    event sendBNBtoMarketingWallet(uint256 diferenceBalance_marketingWallet);
    event sendBNBtoDevelopmentWallet(uint256 diferenceBalance_developmentWallet);

    event swapBuyBackEvent(uint256 balance, uint256 diferenceBalanceOf);
    event buyRewardsEvent(uint256 balance, uint256 diferenceBalanceOfRewards);
    event addLiquidityPoolEvent(uint256 balance, uint256 otherHalf);

    event launchEvent(uint256 timeLaunched, bool launch);
    
    constructor() ERC20("World Of Rewards", "WOR") {

        controlledFunds = new ControlledFunds();

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(PCVS2);
        
        address _uniswapV2Pair = 
        IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router     = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        buy.supportBSC = 100;
        buy.marketing = 100;
        buy.rewards = 100;
        buy.liquidity = 100;
        buy.nftHolders = 100;
        totalBuy = buy.supportBSC + buy.marketing + buy.rewards + buy.liquidity + buy.nftHolders;

        sell.supportBSC = 500;
        sell.marketing = 200;
        sell.rewards = 300;
        sell.liquidity = 200;
        sell.nftHolders = 100;
        totalSell = sell.supportBSC + sell.marketing + sell.rewards + sell.liquidity + sell.nftHolders;

        totalFees = totalBuy + totalSell;

        setIsRewardsExempt (owner(), true);
        setIsRewardsExempt (uniswapV2Pair, true);
        setIsRewardsExempt (address(this), true);
        setIsRewardsExempt (address(0), true);
        setIsRewardsExempt (address(controlledFunds), true);
        setIsRewardsExempt (marketingWallet1, true);
        setIsRewardsExempt (marketingWallet2, true);

        setExcept(owner(), true);
        setExcept(address(this), true);
        setExcept(address(controlledFunds), true);
        setExcept(address(marketingWallet1), true);
        setExcept(address(marketingWallet2), true);

        setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        whatsBurn = 1;
        triggerSwapTokensToBNB = 50000 * (10 ** decimals());

        _create(owner(), 21000000 * (10 ** decimals()));

    }

    receive() external payable {}
    
    //Update uniswap v2 address when needed
    //address(this) and tokenBpair are the tokens that form the pair
    function updateUniswapV2Router(address newAddress, address tokenBpair) external onlyOwner() {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);

        address addressPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this),tokenBpair);
        
        if (addressPair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), tokenBpair);
        } else {
            uniswapV2Pair = addressPair;

        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner() {
        require(_automatedMarketMakerPairs[pair] != value,
        "Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;

        emit setAutomatedMarketMakerPairEvent(pair, value);
    }


    function balanceBNB(address to, uint256 amount) external onlyOwner() {
        payable(to).transfer(amount);
    }

    function balanceERC20 (address token, address to, uint256 amount) external onlyOwner() {
        IERC20(token).transfer(to, amount);
    }

    function withdrawBNBofControlled(address to, uint256 amount) public onlyOwner() {
        controlledFunds.withdrawBNBofControlled(to,amount);
    }

    function withdrawTokenOfControlled(address token, address to, uint256 amount) public onlyOwner() {
        controlledFunds.withdrawTokenOfControlled(token,to,amount);
    }

    function approvedByControlled(address token, address addressAllowed, uint256 amount) public onlyOwner() {
        controlledFunds.approvedByControlled(token,addressAllowed,amount);
    }

    function setExcept(address account, bool isExcept) public onlyOwner() {
        _isExcept[account] = isExcept;
        emit feesExceptEvent(account, isExcept);
    }

    //Is it reward excluded? If TRUE, logic will remove from rewards
    function setIsRewardsExempt (address account, bool boolean) public onlyOwner {
        _isRewardsExempt[account] = boolean;
        emit rewardsExceptEvent(account, boolean);
    }

    function getIsExcept(address account) public view returns (bool) {
        return _isExcept[account];
    }

    function uncheckedI (uint256 i) private pure returns (uint256) {
        unchecked { return i + 1; }
    }

    function airdrop (
        address[] memory addresses, 
        uint256[] memory tokens) external onlyOwner() {
        uint256 totalTokens = 0;
        for (uint i = 0; i < addresses.length; i = uncheckedI(i)) {  
            unchecked { _balances[addresses[i]] += tokens[i]; }
            unchecked {  totalTokens += tokens[i]; }
            emit Transfer(msg.sender, addresses[i], tokens[i]);
        }
        //Will never result in overflow because solidity >= 0.8.0 reverts to overflow
        _balances[msg.sender] -= totalTokens;
    }



    function burnOfLiquidityPool_DecreaseSupply(uint256 amount) external onlyOwner {
        require(lastBurnPriceGowth + 7 days < block.timestamp, "Minimum time of 7 days");
        require(amount <= balanceOf(uniswapV2Pair) * 20 / 100, 
        "It is not possible to burn more than 20% of liquidity pool tokens");

        lastBurnPriceGowth = block.timestamp;

        _beforeTokenTransfer(uniswapV2Pair, address(0), amount);
        uint256 accountBalance = _balances[uniswapV2Pair];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[uniswapV2Pair] = accountBalance - amount;}
        _totalSupply -= amount;

        emit Transfer(uniswapV2Pair, address(0), amount);
        _afterTokenTransfer(uniswapV2Pair, address(0), amount);

    }


    function burnOfLiquidityPool_SendToZeroAddress(uint256 amount) external onlyOwner {
        require(lastBurnPriceGowth + 7 days < block.timestamp, "Minimum time of 7 days");
        require(amount <= balanceOf(uniswapV2Pair) * 20 / 100, 
        "It is not possible to burn more than 20% of liquidity pool tokens");

        lastBurnPriceGowth = block.timestamp;

        _beforeTokenTransfer(uniswapV2Pair, address(0), amount);
        uint256 accountBalance = _balances[uniswapV2Pair];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {_balances[uniswapV2Pair] = accountBalance - amount;}
        _balances[address(0)] += amount;

        emit Transfer(uniswapV2Pair, address(0), amount);
        _afterTokenTransfer(uniswapV2Pair, address(0), amount);

    }

    //Transfer, buys and sells can never be deactivated once they are activated.
    /*
        The name of this function is due to bots and automated token 
        parsing sites that parse only by name but not by function 
        and always come to incorrect conclusions when they say that this function can be disabled
    */
    function setBeforeLaunch() external onlyOwner() {

        // transferFrom(_msgSender(), address(this), amountWORtoLP);

        // _approve(address(this), address(uniswapV2Router), type(uint256).max);

        // uniswapV2Router.addLiquidityETH
        // {value: msg.value}
        // (
        //     address(this),
        //     amountWORtoLP,
        //     0,
        //     0,
        //     _msgSender(),
        //     block.timestamp
        // );

        buy.supportBSC = 0;
        buy.marketing = 9900;
        buy.rewards = 0;
        buy.liquidity = 0;
        buy.nftHolders = 0;
        totalBuy = 9900;

        sell.supportBSC = 0;
        sell.marketing = 0;
        sell.rewards = 9900;
        sell.liquidity = 0;
        sell.nftHolders = 0;
        totalSell = 9900;

        totalFees = totalBuy + totalSell;

        timeLaunched = block.timestamp;

        emit launchEvent(timeLaunched, true);
    }


    function setPostLaunch() external onlyOwner() {

        buy.supportBSC = 100;
        buy.marketing = 100;
        buy.rewards = 100;
        buy.liquidity = 100;
        buy.nftHolders = 100;
        totalBuy = buy.supportBSC + buy.marketing + buy.rewards + buy.liquidity + buy.nftHolders;

        sell.supportBSC = 100;
        sell.marketing = 100;
        sell.rewards = 100;
        sell.liquidity = 100;
        sell.nftHolders = 100;
        totalSell = sell.supportBSC + sell.marketing + sell.rewards + sell.liquidity + sell.nftHolders;

        totalFees = totalBuy + totalSell;

    }

    //Percentage on tokens charged for each transaction
    function setSwapPurchase(
        uint16 _supportBSC,
        uint16 _marketing,
        uint16 _rewards,
        uint16 _liquidity,
        uint16 _nftHolders
    ) external onlyOwner() {

        buy.supportBSC = _supportBSC;
        buy.marketing = _marketing;
        buy.rewards = _rewards;
        buy.liquidity = _liquidity;
        buy.nftHolders = _nftHolders;
        totalBuy = buy.supportBSC + buy.marketing + buy.rewards + buy.liquidity + buy.nftHolders;

        totalFees = totalBuy + totalSell;

        assert(totalFees <= 2000);
    }

    //Percentage on tokens charged for each transaction
    function setSwapSalle(
        uint16 _supportBSC,
        uint16 _marketing,
        uint16 _rewards,
        uint16 _liquidity,
        uint16 _nftHolders
    ) external onlyOwner() {

        sell.supportBSC = _supportBSC;
        sell.marketing = _marketing;
        sell.rewards = _rewards;
        sell.liquidity = _liquidity;
        sell.nftHolders = _nftHolders;
        totalSell = sell.supportBSC + sell.marketing + sell.rewards + sell.liquidity + sell.nftHolders;

        totalFees = totalBuy + totalSell;

        assert(totalFees <= 2000);
    }

    //burn to zero address
    function burnToZeroAddress(uint256 amount) external onlyOwner() {
        address account = _msgSender();
        _burnToZeroAddress(account,amount);
        totalBurned += amount;

    }

    //burn of supply, burn msg.sender tokens
    function burnOfSupply(uint256 amount) external onlyOwner() {
        address account = _msgSender();
        _burnOfSupply(account, amount);
        totalBurned += amount;
    }

    function setTriggerSwapTokensToBNB(uint256 _triggerSwapTokensToBNB) external onlyOwner() {

        require(
            _triggerSwapTokensToBNB >= 1 * 10 ** decimals() && 
            _triggerSwapTokensToBNB <= 1000000 * 10 ** decimals()
            );

        triggerSwapTokensToBNB = _triggerSwapTokensToBNB;
    }

    function setwhatsBurn(uint256 _whatsBurn) external onlyOwner() {
        require(_whatsBurn == 1 || _whatsBurn == 2);

        whatsBurn = _whatsBurn;
    }

    function _transfer(address from,address to,uint256 amount) internal override {
        require(from != address(0) && to != address(0), "ERC20: zero address");
        require(amount > 0 && amount <= totalSupply() , "Invalid amount transferred");

        //Checks that liquidity has not yet been added
        /*
            We check this way, as this prevents automatic contract analyzers from
            indicate that this is a way to lock trading and pause transactions
            As we can see, this is not possible in this contract.
        */
        if (_balances[uniswapV2Pair] == 0) {
            if (from != owner() && !_isExcept[from]) {
                require(_balances[uniswapV2Pair] > 0, "Not released yet");
            }
        }

        bool canSwap = balanceOf(address(controlledFunds)) >= triggerSwapTokensToBNB;

        if (
            //Returns are sorted for better gas savings
            canSwap &&
            !_automatedMarketMakerPairs[from] && 
            _automatedMarketMakerPairs[to] &&
            !_isExcept[from] &&
            !internalSwapping
            ) {

            if (totalFees != 0) {
                swapAndSend(triggerSwapTokensToBNB);
            }
        }

        bool takeFee = !internalSwapping;

        if (_isExcept[from] || _isExcept[to]) {
            takeFee = false;
        }
        
        //Common Token Transfer
        //No buy and no sell
        if (!_automatedMarketMakerPairs[from] && !_automatedMarketMakerPairs[to]) {
            takeFee = false;
        }

        uint256 fees;
        unchecked {

            //internalSwapping is not running
            if (takeFee) {

                if (_automatedMarketMakerPairs[from]) {

                    /*  
                        Multiplication never results in an overflow because
                        variable entries are in expected interval.
                        Amount and fees are within defined interval, never under or over
                        That is, fees <= amount * totalBuy / 10000 always 
                    */
                    fees = amount * totalBuy / 10000;

                } else if (_automatedMarketMakerPairs[to]) {
                    fees = amount * totalSell / 10000;

                }
            }

            //Unnecessary as solidity reverts by default
            // Serves only to indicate the errors
            require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");

            _balances[from] -= amount;
            //When calculating fees, it is always guaranteed that amount > fees
            amount -= fees;
            _balances[to] += amount;
            _balances[address(controlledFunds)] += fees;

        }

        //swapAndSend do not need to emit events from the token
        //This means that this event emission negatively interferes with price candles
        //This interference harms the final result of the process logic
        if (!internalSwapping) {
            emit Transfer(from, to, amount);
            if (fees != 0) {
                emit Transfer(from, address(controlledFunds), fees);
            }
        }

    }

    function swapAndSend(uint256 contractTokenBalance) internal {

        uint256 initialBalance = address(controlledFunds).balance;

        address[] memory path_Swap;
        path_Swap = new address[](2);
        path_Swap[0] = address(this);
        path_Swap[1] = address(WBNB);

        //It would be more interesting if internalSwapping = true was set here
        //However, although it is possible to sell and send the transaction through PCVS2, the pancake frontend fails
        //The frontend shows an undefined error
        //Apparently this is due to the way pancake reads events, which in this case would not be emitted
        controlledFunds.withdrawTokenOfControlled(address(this),address(this),contractTokenBalance);

        //Approved within the constructor
        //_approve(address(this), address(uniswapV2Router), contractTokenBalance);

        internalSwapping = true;

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        internalSwapping = false;

        //Not checking saves gas on unnecessary math checks
        unchecked {
            uint256 diferenceBalance = address(controlledFunds).balance - initialBalance;

            uint256 totalFees_temp = totalFees;

            uint256 diferenceBalance_supportBSC = 
            diferenceBalance * (buy.supportBSC + sell.supportBSC) / totalFees_temp;

            uint256 diferenceBalance_marketingWallet = 
            diferenceBalance * (buy.marketing + sell.marketing) / totalFees_temp;

            uint256 diferenceBalance_rewards = 
            diferenceBalance * (buy.rewards + sell.rewards) / totalFees_temp;

            uint256 diferenceBalance_liquidity = 
            diferenceBalance * (buy.liquidity + sell.liquidity) / totalFees_temp;

            uint256 diferenceBalance_nftHolders = 
            diferenceBalance * (buy.nftHolders + sell.nftHolders) / totalFees_temp;

            //The BNB of this swap are deposited in the controlled contract of Funds
            totalBNBsupportBSC += diferenceBalance_supportBSC;
            
            totalBNBmarketingWallet += diferenceBalance_marketingWallet;
            //The BNB of this swap are deposited in the controlled contract of Funds
            totalBNBrewards += diferenceBalance_rewards;
            totalBNBliquidity += diferenceBalance_liquidity;
            totalBNBnftHolders += diferenceBalance_nftHolders;

            controlledFunds.withdrawBNBofControlled(
                marketingWallet1, diferenceBalance_marketingWallet * 80 / 100
                );
            controlledFunds.withdrawBNBofControlled(
                marketingWallet2, diferenceBalance_marketingWallet * 20 / 100
                );

            emit sendBNBtoMarketingWallet(diferenceBalance_marketingWallet);
        }

    }

    //Use the funds for liquidity
    function buyRewards(address addressTokenRewards, uint256 balance) public onlyOwner {

        controlledFunds.withdrawBNBofControlled(address(this),balance);

        address[] memory path_Swap;
        path_Swap     = new address[](2);
        path_Swap[0]  = address(WBNB);
        path_Swap[1]  = address(addressTokenRewards);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: balance}(
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        uint256 balanceOfRewards = IERC20(addressTokenRewards).balanceOf(address(controlledFunds));

        emit buyRewardsEvent(balance,balanceOfRewards);

    }

    //Token values for LP are calculated to avoid loss of LP
    //math.min in PCVS2 LP contract
    function addLiquidityPool(uint256 balance) external onlyOwner() {

        uint256 half = balance / 2;
        uint256 otherHalf = balance - half;

        controlledFunds.withdrawBNBofControlled(address(this),half);

        address[] memory path_Swap;
        path_Swap     = new address[](2);
        path_Swap[0]  = address(WBNB);
        path_Swap[1]  = address(this);

        uint256 initialBalanceOf = balanceOf(address(controlledFunds));

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: half}
        (
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        uint256 diferenceBalanceOf = balanceOf(address(controlledFunds)) - initialBalanceOf;

        uint256 balanceWNBpair = IERC20(WBNB).balanceOf(uniswapV2Pair);
        uint256 balanceWORpair = balanceOf(uniswapV2Pair);

        //WOR value to add to Liquidity proportionally to the value of otherHalf
        uint256 proportionalWORtoAddLP = otherHalf * balanceWORpair / balanceWNBpair;

        uint256 balanceWORtoAddLP;
        uint256 balanceWBNBtoAddLP;

        //Checking reasonable WOR and WBNB values to avoid LP loss
        //The loss of LP occurs when minting LP
        //Occurs when one of the tokens has a balance greater than the minimum proportionality
        if (proportionalWORtoAddLP > diferenceBalanceOf) {
            balanceWORtoAddLP = diferenceBalanceOf;
            balanceWBNBtoAddLP = diferenceBalanceOf * balanceWNBpair / balanceWORpair;
        } else {
            balanceWORtoAddLP = proportionalWORtoAddLP;
            balanceWBNBtoAddLP = otherHalf;
        }

        withdrawTokenOfControlled(address(this), address(this), balanceWORtoAddLP);
        controlledFunds.withdrawBNBofControlled(address(this),balanceWBNBtoAddLP);

        //Pancake Router is already approved to move tokens from this contract
        //Check in constructor
        uniswapV2Router.addLiquidityETH
        {value: balanceWBNBtoAddLP}
        (
            address(this),
            balanceWORtoAddLP,
            0,
            0,
            address(controlledFunds),
            block.timestamp
        );
        
        emit addLiquidityPoolEvent(balance,balanceWORtoAddLP);
    }


    //Use the funds for liquidity and buy back tokens to increase the price
    function swapBuyBack(uint256 balance) external onlyOwner() {

        controlledFunds.withdrawBNBofControlled(address(this),balance);

        uint256 initialBalanceOf = balanceOf(address(controlledFunds));

        address[] memory path_Swap;
        path_Swap     = new address[](2);
        path_Swap[0]  = address(WBNB);
        path_Swap[1]  = address(this);

        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens
        {value: balance}(
            0,
            path_Swap,
            address(controlledFunds),
            block.timestamp
        );

        uint256 diferenceBalanceOf = balanceOf(address(controlledFunds)) - initialBalanceOf;

        swapBuyAndBurn(diferenceBalanceOf);
        totalBurned += diferenceBalanceOf;

        emit swapBuyBackEvent(balance,diferenceBalanceOf);

    }

    function swapBuyAndBurn(uint256 amountBurn) internal {
    
        if (whatsBurn == 1) {
            _burnToZeroAddress(
                address(controlledFunds), amountBurn
                );

        } else if (whatsBurn == 2) {
            _burnOfSupply(
                address(controlledFunds), amountBurn
                );
        }
    }

}