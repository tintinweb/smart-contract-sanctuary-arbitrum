// SPDX-License-Identifier: MIT
/*
test
*/





pragma solidity 0.8.17;



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    //function totalSupply(uint256) external view returns (uint256);
    //function totalShare(uint256) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}



contract DontBuy is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => uint256) public _userPushSpend;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private _userTokenMoved;
    mapping (address => uint256) private  userClaimsShare;
    mapping (address=> uint) private claimTime;
    mapping (address=> bool) public claimer;
    mapping (address=> bool) private _locked;
    
    
    //uint256 private enabled = 0;
    uint256 totalBalances;
    //time for waiting to claim set in hours
    uint256 public waitTime = 336;
    
    
    struct Taxes {
        uint256 rewards;        
        uint256 outreach;
        uint256 dev;
    }

    //Taxes  eg. 250 / 1000 = 25% 
    Taxes public buyTax = Taxes(4,6,26);
    Taxes public sellTax = Taxes(11,15,10);
    
   
    uint256 public totalBuyTax = 36; //#buyTax.rewards + buyTax.outreach +buyTax.dev; 
    uint256 public totalSellTax = 36; //sellTax.rewards + sellTax.outreach + sellTax.dev;
    
    
    
    address public outreachWallet = 0xCcd1e792752FbFfdE0E8bF1dE1e7f473c9e33f8E ;
    address payable private devWallet = payable(0x995fa5eadCDf96268C7a99357d87fe89dCF7EDd2);
    address public rewardsAddress = 0xfbD806e9Fb2b7bB353EdDE8725257f603A4bBD5C ;
    

    uint8 private constant _decimals = 9;
    uint256 private constant _eDec = 10**16;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"Dont Buy Token"; 
    string private constant _symbol = unicode"Dont buy"; 
    uint256 public _maxTxAmount =   20000000 * 10**_decimals;    
    uint256 public _maxWalletSize = 25000000 * 10**_decimals; 
    uint256 public _taxSwapThreshold = 2000000 * 10**_decimals; 
    uint256 public _maxTaxSwap = 20000000 * 10**_decimals;
    
    //Tokens needed to push claimtime  back
    uint256 public _pushAmount = 100 * 10**_decimals;

    struct Levels {
        uint256 peanutBrain;
        uint256 babydoll;
        uint256 fan;
        uint256 friend;
        uint256 chad;        
    }
    Levels public friendStatus = Levels(5*_eDec, 20*_eDec, 100*_eDec, 500*_eDec, 2500*_eDec );
    uint256 public wipeFee = 2 * 10**15 wei;

    //we start with 50 and make it a large multiplier number then divide it by 100% 
    //5* 10 ** 8 gives an abstract 50% 
    uint256 tooManySales = (50 * 10** _decimals) / 100; 

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private claimable = true;

    //not sure why its here uint public userTokens = 500000 * 10**_decimals;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    
    mapping(address => usersEthTracking) public userTracker;
    mapping(address => uint256) public sellRatio;
  
    //total amount of funds for those sharing dividends
    
    uint256 totalShareTracker;

    struct usersEthTracking {
        uint256 lastEthSpend; 
        uint256 totalEthSpend;
    }

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event setClaimer(address claimer, bool state);
    event resetClaimer(address _targetAddress, uint pushHours);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    bool inSwapAndLiquify;

    event wipeClaim(address _user, uint256 _claimTime);
    event settings(uint256 _wipeFee, uint256 _waitTime, uint256 pushAmount);

    event Wallets( 
        address _rewardsAddress,
        address _outreachWallet,
        address devWallet
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event sellTracker(
        uint256 _sellRatio, 
        uint256 _claimTime,
        uint256 _userEth,
        uint256 _lastSpend
    );
    
    constructor () {
        uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); //change for Arbitrum... 
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[outreachWallet] = true;
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    // Exclude wallets from Fees
    function excludeFromFees(address[] memory wallets_) public {
        require( _msgSender() == devWallet ,"Only the Dev can add exclsions!");
        for (uint i = 0; i < wallets_.length; i++) {
            _isExcludedFromFee[wallets_[i]] = true;
        }
    }

    // Add wallets to include them into Fees
    function removeExcluded(address[] memory wallets_) public  {
        require( _msgSender() == devWallet,"Only the Dev remove excluded wallets!");
        for (uint i = 0; i < wallets_.length; i++) {
            _isExcludedFromFee[wallets_[i]] = false;
        }
    }    

    function enableTrading() external onlyOwner() {
        require(!tradingOpen,"ERROR: Requirement already met");
        swapEnabled = true;
        tradingOpen = true;
    }
    
    // Change the buy and sell taxes - old 
    function setBuyTaxes( uint256 _rewards, uint256 _outreach, uint256 _dev) external onlyOwner{
        require( _rewards +_outreach + _dev <= 200, "Fee must be <= 20%");
        buyTax = Taxes(  _rewards, _outreach, _dev);
        totalBuyTax =  _rewards +_outreach + _dev;
    }

    function setSellTaxes( uint256 _rewards, uint256 _outreach, uint256 _dev) external onlyOwner{
        require( _rewards +_outreach + _dev <= 200, "Fee must be <= 20%");
        sellTax = Taxes( _rewards, _outreach, _dev);
        totalSellTax =  _rewards +_outreach + _dev;
    }

    //add liquidity Function
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        lockTheSwap
    {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            outreachWallet,
            block.timestamp
        );
    }
    
    function _swapAndLiquify(uint256 _contractTokenBalance) private lockTheSwap {
        
        //half the tokens are to be used for liquidity , half (in eth) are for dev
        uint256 tokensForLP = _contractTokenBalance.div(2); 

        uint256 halfLP = tokensForLP.div(2); 
        uint256 otherHalfLP = tokensForLP - halfLP; 

        //gets balance of eth in contract 10
        uint256 initialBalance = address(this).balance; 

        //swap LP fraction of tokens for eth ~ 75%
        swapTokensForEth( _contractTokenBalance - halfLP ); 

        //get the balance of eth (25%) linked to the token swap
        uint256 newBalance = (address(this).balance - initialBalance).div(3); 

        _addLiquidity(otherHalfLP, newBalance);

        emit SwapAndLiquify(halfLP, newBalance, otherHalfLP); 
    }


    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }
    function totalShareableTokens() public view returns (uint256) {
        return totalShareTracker;
    }

    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }

    function userShare(address account) public view returns (uint256) {
        return userClaimsShare[account];
    }

    function userClaimTimer(address account) public view returns (uint256) {
        return claimTime[account];
    }

    function userStatus (address account) public view returns( uint256) {
        //peanut brain by default
        uint status ;
        //only give a hihger status if the % of tokens held is larger than the sell threshold
        if (sellRatio[account] > tooManySales ) {
            if (userTracker[account].lastEthSpend > friendStatus.peanutBrain ) {
                status = 0;
            }   
            if (userTracker[account].lastEthSpend > friendStatus.babydoll ) {
                status = 1;
            } 
            if (userTracker[account].lastEthSpend > friendStatus.fan ) {
                status = 2;
            }            
            if (userTracker[account].lastEthSpend > friendStatus.friend ) {
                status = 3;
            }            
            if (userTracker[account].lastEthSpend > friendStatus.chad ) {
                status = 4;
            } 


        }
        return status;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount); //, false 
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 
    function manualSwapToLP() external {
        require(_msgSender()==devWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){          
          _swapAndLiquify(min(tokenBalance,_maxTaxSwap));
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function isClaimer(address _claimerAddress, bool _state) public {
        require( msg.sender == devWallet, "Only the Dev can do this!");
        require(  claimer[_claimerAddress] != _state, "already set");

        claimer[_claimerAddress] = _state;        
        emit setClaimer(_claimerAddress, _state);

    }

    function resetTimer(address _targetAddress) public{
       require(claimer[msg.sender],"Not a claimer contract");
        uint pushHours = block.timestamp + waitTime * 3600;
        claimTime[_targetAddress] = pushHours;

        emit resetClaimer(_targetAddress, pushHours);
    }

    function pushTimer (address _targetAddress, uint256 _amount) public {
        require( _amount >= 2*_pushAmount ,"push amount too low");
        require( claimTime[_targetAddress] > 0, "can not push 0 timer address");

        uint256 _push = _pushAmount;
        uint pushHours = ( waitTime * 3600).mul(_amount).div(_push);

        _transfer(msg.sender, rewardsAddress,  ( _amount - _push ) );
        _transfer(msg.sender, _targetAddress,  _push );
        claimTime[_targetAddress] += pushHours;
        _userPushSpend[msg.sender] += _amount;
        emit resetClaimer(_targetAddress, pushHours);
        

    }

    function wipeClaimTime (address _userAddress ) payable public {
        require( msg.value == wipeFee,"Wrong wipeFee paid" );
        require( msg.sender == _userAddress, "Not your account Dude!");
        require( userStatus(_userAddress) != 0, "status cant be zero");
        
        _locked[_userAddress] = true;
       
        // use the status of the user to create a new shorter time
        uint256 _status = userStatus(_userAddress) ;

        //reduce current wait until the user can claim
        uint256 _userClaimtime = claimTime[_userAddress];
        uint256 timeNow = block.timestamp;
        
        
        uint newtime = timeNow + (_userClaimtime - timeNow).div(_status+1) ;

        //claim time is reduced to min one day 86400
        _userClaimtime = max( (timeNow + 864), newtime ) ;

        claimTime[_userAddress] = _userClaimtime;        
        userTracker[_userAddress].lastEthSpend += wipeFee;
        userTracker[_userAddress].totalEthSpend += wipeFee;
        
        _locked[msg.sender] = false;
        emit wipeClaim(  _userAddress, _userClaimtime);

    }

    function waitSettings (uint256 _wipeFee, uint256 _waitTime, uint256 _pushFactor) external {
        require( msg.sender == devWallet, "Only the Dev can do this!");
        require( _wipeFee > 1 && _wipeFee < 1000 , " wipe fee is set out of range");
        require( _waitTime >= 1 && _waitTime <= 772, "Hours out of range");
        require( _pushFactor > 1 && _pushFactor < 5000 , "Push Factor out of range" );
        
        // wipefee is multiplied by  10**15 for example 1000 -> 1 eth;
        wipeFee = _wipeFee * 10**15  wei; 
        //set wait time in hours
        waitTime = _waitTime;
        //set push amount using push factor and the minimum transaction
        _pushAmount = _pushFactor * 10**_decimals ;

        emit settings(wipeFee, waitTime, _pushAmount);

    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount); //, false
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address from, address to, uint256 amount) private { //, bool push 
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be bigger than zero");
        //require(amount >= _minTxAmount, "Not enough tokens transfered");
        
        uint256 taxAmount;
        uint256 lDev;
        uint256 lOutreach;
        uint256 lRewards;
        uint256 userEth ;
        uint256 balanceTo;
        //uint256 userTok ; userTracker[to].claimTime
        // User storage user = users[_address];
        
        
        

        if (from != owner() && to != owner()) {

            
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(tradingOpen, "Trading not open");
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");                
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                //get 3 taxes and add them together? 
                //buying 
                //possibly assign local variable amount - i think this is already done
                
                taxAmount = amount.mul(totalBuyTax).div(1000); 

                lDev = amount.mul(buyTax.dev).div(1000);
                lOutreach = amount.mul(buyTax.outreach).div(1000);              
                lRewards = amount.mul(buyTax.rewards).div(1000);
                                 
                //counts estimated eth spend from user
                address[] memory path = new address[](2);                
                path[0] = uniswapV2Router.WETH(); 
                path[1] = address(this);

                uint[] memory lpAmounts =  uniswapV2Router.getAmountsIn( amount, path );
                userEth = lpAmounts[0];
 

                
            }

            // selling...
            if(to == uniswapV2Pair && from != address(this) ){
                //get 3 taxes and add them together
                
                taxAmount = amount.mul(totalSellTax).div(1000);//change to div by 4 and % need to b in decimcal
                lDev = amount.mul(sellTax.dev).div(1000);
                lOutreach = amount.mul(sellTax.outreach).div(1000);                
                lRewards = amount.mul(sellTax.rewards).div(1000);
                
                //update user token sell total not including tax fee
                
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold) {

                
                //swap and liquify tokens.. but dont do so many that it rekts the user
                _swapAndLiquify(min (amount, min( contractTokenBalance, _maxTaxSwap)));
                
                uint256 contractETHBalance = address(this).balance; 
                if(contractETHBalance > 0) {
                    //add eth profit if you want 
                    sendETHToFee(address(this).balance);
                }
            }

            //Update users 'sold' token balance
            //userTok =  (amount - taxAmount);
            _userTokenMoved[from] +=  amount.sub(taxAmount);// userTok;
        } 

        if(taxAmount > 0){
             
            //add balance to contract balances
            _balances[address(this)] += lDev;
            _balances[outreachWallet] += lOutreach;
            _balances[rewardsAddress] += lRewards;

            //send to wallets
            emit Transfer(from, address(this), lDev);
            emit Transfer(from, outreachWallet, lOutreach);
            emit Transfer(from, rewardsAddress, lRewards);

        }
        
        
        // update sender balance & reciever balance
        // case 1 buying tokens - router sends token from contract -> user and contract balance is subtracted
        // case 2 selling tokens - user sends token from his address -> router and balance is subtracted before he can send more
        _balances[from] =_balances[from].sub(amount); 
        _balances[to] = _balances[to].add( amount.sub(taxAmount) );

        emit Transfer(from, to, amount.sub(taxAmount));


        //UPDATE THE TOTAL FUNDS OF THE WALLET TO BE SHARED - CHECK THIS
        // probably should be + rewards
        balanceTo = _balances[to];        

        //calulate ratio of user tokens held in wallet, to the user's total held+sold amount 
        //should be less than 1 * 10**9
        uint256 balanceFrom = smallZero(_balances[from]);
        uint256 sellRatioFrom =  balanceFrom.mul(10**_decimals).div( _userTokenMoved[from] + balanceFrom ) ;
        sellRatio[from] = sellRatioFrom; 

        //if (!push ){
        //  
        //}
        
        
        //what x% of the tokens is he still holding?
        
        if ( tooManySales > sellRatioFrom ) {

            // we remove the users previous claim share from the total claimers tracker
            totalShareTracker = totalShareTracker.sub(userClaimsShare[to]) ;
            //user no longer eligible - we reset the eth required to become eligible
            userTracker[to].lastEthSpend = 0;
            userClaimsShare[to] = 0;
            claimTime[to] = 0;             
            
        }

        
        // Cheking if  the user has spent some eth in this transfer
        // Now update users eth spent after buying tokens - After the token tax has been sent
        
        if (userEth > 0 ){

            claimTime[to] = max ( (block.timestamp + waitTime * 3600), claimTime[to] ) ;   
            //update the lst time eth was bought and the total amount spent             
            userTracker[to].lastEthSpend += userEth;
            
            //Update the total amount of eth the user has ever spent
            userTracker[to].totalEthSpend += userEth; 
                  
            
            // The user is tested to see if he's eligible for rewards
            if (userTracker[to].lastEthSpend > friendStatus.babydoll && tooManySales < sellRatioFrom ){
                
                //remove the previous balance of the users claims from the total claims.
               //then add the new balance since they just bought more tokens            
                totalShareTracker = totalShareTracker.add(balanceTo).sub( userClaimsShare[to] ) ; 

                //set the amount of tokens the user is eligible to claim based on what just they bought         
                userClaimsShare[to] = balanceTo;
                                
            }
            
        }
        emit sellTracker( sellRatioFrom, claimTime[to], userEth, userTracker[to].lastEthSpend );

    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function setWallets ( address _rewardsAddress, address _outreachWallet , address _devWallet ) external{
       require( msg.sender == devWallet, "Only the Dev can do this!");
       require(_rewardsAddress != address(0),"rewards address set as 0");
       require( _devWallet != address(0),"dev address set as 0");
       require( _outreachWallet != address(0),"outreach address set as 0");

       rewardsAddress = _rewardsAddress;
       outreachWallet = _outreachWallet;
       devWallet = payable (_devWallet);
       emit Wallets(_rewardsAddress,_outreachWallet,devWallet);

    }
    function updateTooManySells (uint256 _updateSellLimit) external {
        require( msg.sender == devWallet, "Only dev can change sell limit" );
        require( _updateSellLimit > 0, " must be more than zero" );
        require( _updateSellLimit <= 95, " must be less than or equal to 95" );

        tooManySales = (_updateSellLimit * 10**_decimals) / 100 ;
        

    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }
    function max(uint256 a, uint256 b) private pure returns (uint256){
      return (a<b)?b:a;
    }
    function smallZero(uint256 balance) private pure returns(uint256){
       return (balance==0)?1:balance;
    }

    function sendETHToFee(uint256 amount) private {
        //send to dev wallet
        devWallet.transfer(amount); //change to dev wallet
    }
           
    function escapeTrappedETH() external {
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    receive() external payable {}

}