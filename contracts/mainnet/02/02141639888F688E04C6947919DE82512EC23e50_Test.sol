/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

//SPDX-License-Identifier: MIT

/** 
 * Contract: Surge Token
 * Developed by: Heisenman
 * Team: t.me/ALBINO_RHINOOO, t.me/Heisenman, t.me/STFGNZ 
 * Trade without dex fees and RUGS!. $SURGE is the inception of the next generation of decentralized protocols.
 * Socials:
 * TG: https://t.me/SURGEPROTOCOL
 * Website: https://surgeprotocol.io/
 * Twitter: https://twitter.com/SURGEPROTOCOL
 */

pragma solidity 0.8.19;

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IPancakePair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract Test is IERC20, Context, Ownable, ReentrancyGuard {

    event Bought(address indexed from, address indexed to,uint256 tokens, uint256 beans,uint256 dollarBuy);
    event Sold(address indexed from, address indexed to,uint256 tokens, uint256 beans,uint256 dollarSell);
    event FeesMulChanged(uint256 newBuyMul, uint256 newSellMul);
    event StablePairChanged(address newStablePair, address newStableToken);
    event MaxBagChanged(uint256 newMaxBag);

    // token data
    string constant private _name = "Test";
    string constant private  _symbol = "Test";
    uint8 constant private _decimals = 9;
    uint256 constant private _decMultiplier = 10**_decimals;

    // Total Supply
    uint256 public constant _totalSupply = 10**8*_decMultiplier;

    // balances
    mapping (address => uint256) public _balances;
    mapping (address => mapping (address => uint256)) internal _allowances;

    //Fees
    mapping (address => bool) public isFeeExempt;
    uint256 public sellMul = 950;
    uint256 public buyMul = 950;
    uint256 public constant DIVISOR = 1000;

    //Max bag requirements
    mapping (address => bool) public isTxLimitExempt;
    uint256 public maxBag = _totalSupply/100;
    
    //Tax collection
    uint256 public taxBalance = 0;

    //Tax wallets
    address public teamWallet = 0xDa17D158bC42f9C29E626b836d9231bB173bab06;
    address public treasuryWallet = 0xF526A924c406D31d16a844FF04810b79E71804Ef ;

    // Tax Split
    uint256 public teamShare = 500;
    uint256 public treasuryShare = 500;
    uint256 public constant SHAREDIVISOR = 1000;

    //Known Wallets
    address constant private DEAD = 0x000000000000000000000000000000000000dEaD;

    //trading parameters
    uint256 public liquidity = 6900000000000000000;
    uint256 public liqConst = liquidity*_totalSupply;
    bool public isTradeOpen = false;
    bool public isLaunched = false;
    mapping(address => uint256) public whitelist;

    //volume trackers
    mapping (address => uint256) public indVol;
    mapping (uint256 => uint256) public tVol;
    uint256 public totalVolume = 0;

    //candlestick data
    uint256 public totalTx;
    mapping(uint256 => uint256) public txTimeStamp;

    struct candleStick{ 
        uint256 time;
        uint256 open;
        uint256 close;
        uint256 high;
        uint256 low;
    }

    mapping(uint256 => candleStick) public candleStickData;

    //Frontrun Guard
    mapping(address => uint256) private _lastBuyBlock;

    // initialize supply
    constructor(
    ) {
        _balances[address(this)] = _totalSupply;

        isFeeExempt[msg.sender] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(0)] = true;
        //burn to be added here if needed

        emit Transfer(address(0), address(this), _totalSupply);
    }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(spender != address(0), "SRG20: approve to the zero address");
        require(msg.sender != address(0), "SRG20: approve from the zero address");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;    
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint).max);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply-_balances[DEAD];
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        require(newLimit >= maxBag,"New wallet limit should be more than last maxBag");
        maxBag  = newLimit;
        emit MaxBagChanged(newLimit);
    }
    
    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    /** Transfer Function */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    /** TransferFrom Function */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        
        address spender = msg.sender;
        //check allowance requirement
        _spendAllowance(sender, spender, amount);
        return _transferFrom(sender, recipient, amount);
    }
    
    /** Internal Transfer */
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        // make standard checks
        require(recipient != address(0) && recipient != address(this), "transfer to the zero address or CA");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(isTxLimitExempt[recipient]||_balances[recipient] + amount <= maxBag,"Max wallet exceeded!");
        require(isTxLimitExempt[sender]|| isLaunched, "Nice Try!");
        // subtract from sender
        _balances[sender] = _balances[sender] - amount;

        // give amount to receiver
        _balances[recipient] = _balances[recipient] + amount;

        // Transfer Event
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "SRG20: insufficient allowance");

            unchecked {
                // decrease allowance
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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


    /** Purchases SURGE Tokens and Deposits Them in Sender's Address*/
    function _buy(uint256 minTokenOut, uint256 deadline) public nonReentrant payable returns (bool) {
        // deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");
        
        // Frontrun Guard
        _lastBuyBlock[msg.sender]=block.number;

        // liquidity is set and trade open
        require(isTradeOpen || isTxLimitExempt[msg.sender], "trade is not enabled");
     
        //remove the buy tax
        uint256 bnbAmount = isFeeExempt[msg.sender] ? msg.value : msg.value * buyMul / DIVISOR;
        
        // how much they should purchase?
        uint256 tokensToSend = _balances[address(this)]-(liqConst/(bnbAmount+liquidity));
        
        //revert for max bag
        require(_balances[msg.sender] + tokensToSend <= maxBag || isTxLimitExempt[msg.sender],"Max wallet exceeded");

        // revert if under 1
        require(tokensToSend > 1 && tokensToSend >= minTokenOut,"INSUFFICIENT OUTPUT AMOUNT");
 
        //Whitelist requirement
        require(isLaunched || _balances[msg.sender]+tokensToSend <= whitelist[msg.sender]|| isTxLimitExempt[msg.sender]);

        // transfer the tokens from CA to the buyer
        buy(msg.sender, tokensToSend);

        //update available tax to extract and Liquidity
        uint256 taxAmount = msg.value - bnbAmount;
        taxBalance += taxAmount;
        liquidity += bnbAmount;

        //update volume
        uint cTime = block.timestamp;
        uint dollarBuy = msg.value*getBNBPrice();
        totalVolume += dollarBuy;
        indVol[msg.sender]+= dollarBuy;
        tVol[cTime]+=dollarBuy;

        //update candleStickData
        totalTx+=1;
        txTimeStamp[totalTx]= cTime;
        uint cPrice = calculatePrice()*getBNBPrice();
        candleStickData[cTime].time= cTime;
        if(candleStickData[cTime].open == 0){
            if(totalTx==1)
            {
            candleStickData[cTime].open = (liquidity-bnbAmount)/(_totalSupply)*getBNBPrice();
            }
            else {candleStickData[cTime].open = candleStickData[txTimeStamp[totalTx-1]].close;}
        }
        candleStickData[cTime].close = cPrice;
        
        if(candleStickData[cTime].high < cPrice || candleStickData[cTime].high==0){
            candleStickData[cTime].high = cPrice;
        }

          if(candleStickData[cTime].low > cPrice || candleStickData[cTime].low==0){
            candleStickData[cTime].low = cPrice;
        }

        //emit transfer and buy events
        emit Transfer(address(this), msg.sender, tokensToSend);
        emit Bought(msg.sender, address(this), tokensToSend, msg.value,bnbAmount*getBNBPrice());
        return true;
    }
    
    /** Sends Tokens to the buyer Address */
    function buy(address receiver, uint amount) internal {
        _balances[receiver] = _balances[receiver] + amount;
        _balances[address(this)] = _balances[address(this)] - amount;
    }

    /** Sells SURGE Tokens And Deposits the BNB into Seller's Address */
    function _sell(uint256 tokenAmount, uint256 deadline, uint256 minBNBOut) public nonReentrant  returns (bool) {
        // deadline requirement
        require(deadline >= block.timestamp, "Deadline EXPIRED");
        
        //Frontrun Guard
        require(_lastBuyBlock[msg.sender]!=block.number,"Buying and selling in the same block is not allowed!");
        
        address seller = msg.sender;
        
        // make sure seller has this balance
        require(_balances[seller] >= tokenAmount, "cannot sell above token amount");
        
        // get how much beans are the tokens worth
        uint256 amountBNB = liquidity - (liqConst/(_balances[address(this)]+tokenAmount));
        uint256 amountTax = amountBNB * (DIVISOR - sellMul)/DIVISOR;
        uint256 BNBToSend = amountBNB - amountTax;
        
        //slippage revert
        require(amountBNB >= minBNBOut,"INSUFFICIENT OUTPUT AMOUNT");

        // send BNB to Seller
        (bool successful,) = isFeeExempt[msg.sender] ? payable(seller).call{value: amountBNB}(""): payable(seller).call{value: BNBToSend}(""); 
        require(successful,"BNB/ETH transfer failed");

        // subtract full amount from sender
        _balances[seller] -= tokenAmount;

        //add tax allowance to be withdrawn and remove from liq the amount of beans taken by the seller
        taxBalance = isFeeExempt[msg.sender] ? taxBalance : taxBalance + amountTax;
        liquidity -= amountBNB;

        // add tokens back into the contract
        _balances[address(this)]=_balances[address(this)] + tokenAmount;

        //update volume
        uint cTime = block.timestamp;
        uint dollarSell= amountBNB*getBNBPrice();
        totalVolume += dollarSell;
        indVol[msg.sender]+= dollarSell;
        tVol[cTime]+=dollarSell;

        //update candleStickData
        totalTx+=1;
        txTimeStamp[totalTx]= cTime;
        uint cPrice = calculatePrice()*getBNBPrice();
        candleStickData[cTime].time= cTime;
        if(candleStickData[cTime].open == 0){
            candleStickData[cTime].open = candleStickData[txTimeStamp[totalTx-1]].close;
        }
        candleStickData[cTime].close = cPrice;
        
        if(candleStickData[cTime].high < cPrice || candleStickData[cTime].high==0){
            candleStickData[cTime].high = cPrice;
        }

          if(candleStickData[cTime].low > cPrice || candleStickData[cTime].low==0){
            candleStickData[cTime].low = cPrice;
        }

        // emit transfer and sell events
        emit Transfer(seller, address(this), tokenAmount);
        if(isFeeExempt[msg.sender]){
            emit Sold(address(this), msg.sender,tokenAmount,amountBNB,dollarSell);
        }
        
        else{ emit Sold(address(this), msg.sender,tokenAmount,BNBToSend,BNBToSend*getBNBPrice());}
        return true;
    }
    
    /** Amount of BNB in Contract */
    function getLiquidity() public view returns(uint256){
        return liquidity;
    }

    /** Returns the value of your holdings before the sell fee */
    function getValueOfHoldings(address holder) public view returns(uint256) {
        return _balances[holder]*liquidity/_balances[address(this)]*getBNBPrice();
    }

    function changeFees(uint256 newBuyMul, uint256 newSellMul) external onlyOwner {
        require( newBuyMul >= 90 && newSellMul >= 90 && newBuyMul <=100 && newSellMul<= 100,"Fees are too high");

        buyMul = newBuyMul;
        sellMul = newSellMul;

        emit FeesMulChanged(newBuyMul, newSellMul);
    }

    function changeTaxDistribution(uint newteamShare, uint newtreasuryShare) external onlyOwner {
        require(newteamShare + newtreasuryShare == SHAREDIVISOR,"Sum of shares must be 100");
    
        teamShare = newteamShare;
        treasuryShare = newtreasuryShare;
    }

    function changeFeeReceivers(address newTeamWallet, address newTreasuryWallet) external onlyOwner {
        require(newTeamWallet!=address(0)&& newTreasuryWallet != address(0),"New wallets must not be the ZERO address");
        
        teamWallet = newTeamWallet;
        treasuryWallet = newTreasuryWallet;
    }

    function withdrawTaxBalance() external nonReentrant() onlyOwner {
        (bool temp1,)= payable(teamWallet).call{value:taxBalance*teamShare/SHAREDIVISOR}("");
        (bool temp2,)= payable(treasuryWallet).call{value:taxBalance*treasuryShare/SHAREDIVISOR}("");
        assert(temp1 && temp2);
        taxBalance = 0; 
    }

    function getTokenAmountOut(uint256 amountBNBIn) external view returns (uint256) {
        uint256 amountAfter = liqConst/(liquidity-amountBNBIn);
        uint256 amountBefore = liqConst/liquidity;
        return amountAfter-amountBefore;
    }

    function getBNBAmountOut(uint256 amountIn) public view returns (uint256) {
        uint256 beansBefore = liqConst / _balances[address(this)];
        uint256 beansAfter = liqConst / (_balances[address(this)] + amountIn);
        return beansBefore-beansAfter;
    }

    function addLiquidity() external onlyOwner payable {
        uint256 tokensToAdd= _balances[address(this)]*msg.value/liquidity;
        require(_balances[msg.sender]>= tokensToAdd,"Not enough tokens!");

        uint256 oldLiq = liquidity;
        liquidity = liquidity+msg.value;
        _balances[address(this)]+= tokensToAdd;
        _balances[msg.sender]-= tokensToAdd;
        liqConst= liqConst*liquidity/oldLiq;

        emit Transfer(msg.sender, address(this),tokensToAdd);
    }

    function getMarketCap() external view returns(uint256){
        return (getCirculatingSupply()*calculatePrice()*getBNBPrice());
    }

    address private stablePairAddress = 0x905dfCD5649217c42684f23958568e533C711Aa3;
    address private stableAddress = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    function changeStablePair(address newStablePair, address newStableAddress) external onlyOwner{
        require(newStablePair!=address(0) && newStableAddress != address(0),"New addresses must not be the ZERO address");
    
        stablePairAddress = newStablePair;
        stableAddress = newStableAddress;
        emit StablePairChanged(newStablePair,newStableAddress);
  }

   // calculate price based on pair reserves
   function getBNBPrice() public view returns(uint)
   {
    IPancakePair pair = IPancakePair(stablePairAddress);
    IERC20 token1 = pair.token0() == stableAddress? IERC20(pair.token1()):IERC20(pair.token0()); 
    
    (uint Res0, uint Res1,) = pair.getReserves();

    if(pair.token0() != stableAddress){(Res1,Res0,) = pair.getReserves();}
    uint res0 = Res0*10**token1.decimals();
    return(res0/Res1); // return amount of token0 needed to buy token1
   }

    // Returns the Current Price of the Token in beans
    function calculatePrice() public view returns (uint256) {
        require(liquidity>0,"No Liquidity");
        return liquidity/_balances[address(this)];
    }

    function enableTrade() external onlyOwner{
        require(!isTradeOpen, "Trade is Enabled!");
        isTradeOpen = true;
    }

    function launch() external onlyOwner{
        require(!isLaunched);
        isLaunched = true;
    }

    function addToWhitelist(address[] memory _addresses, uint256[] memory _values) external onlyOwner {
        require(_addresses.length == _values.length, "Length mismatch");

        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _values[i];
        }
    }
}