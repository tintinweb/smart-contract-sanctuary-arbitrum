/**
 *Submitted for verification at Arbiscan.io on 2023-12-10
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function decimals() external view returns (uint8);
  function burn(uint256 amount) external;
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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


interface IPancakeRouter01 {
    function factory () external pure returns (address);
    function factoryV1 () external pure returns (address);
    function factoryV2 () external pure returns (address);
    function WETH () external pure returns (address);
    function WPLS () external pure returns (address);
    function WAVAX () external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

interface IRouter is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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

pragma solidity >=0.6.2;

interface IFactory {
function getPair (address token1, address token2) external pure returns (address);
}



contract DiamondHandToken {

    using SafeMath for uint256;

    address payable public _dev = payable (0x60859bAF5f538c5F82219e286E73Df1DE43ceEde); // receives ETH of buy and vest function
 
    uint8 public contractBuyFee = 30;

    address public contrAddr;

    address public constant _routerAddr = 0x0A2e5A3Dc2f74E5Bfaf0Bf90685A5A899f379Cb0; //  ELK router on arbitrum
    IRouter public constant _router = IRouter(_routerAddr);

    IFactory public _factory = IFactory(_router.factory());
    address public tradingPair = address(0);

    uint256 public overallVestedToken;
    uint256 public overallCollectedDividends;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Vest (address indexed user, uint256 stakeAmount, uint256 vestTime);
    event EnterVesting (address indexed user, uint256 rawAmount, uint256 vestedTokenAmt, uint256 entryTime);
    event ClaimRewards (address indexed user, uint256 rewardAmount, uint256 claimTime);
    event ReinvestRewards (address indexed user, uint256 rewardAmount, uint256 reinvestTime);

    modifier onlyDev() {
        require(_dev == msg.sender, "Ownable: caller is not the dev");
        _;
    }

    string public constant name = "DiamondHandToken";
    string public constant symbol = "DT";
    uint256 public constant decimals = 18;

    uint256 public constant _monthlyDevmint = 2000 * 1e18; // 2 k token

    uint256 public _totalSupply;

    bool public noVestandBuyVest = false;

    mapping(address => uint256) private _Balances;

    /* Time of contract launch */
    uint256 public constant launchTime = 1702128000; // Sets Starttime of the contract, Days and Month // TODO
    uint256 public constant oneDay =  1 days;  // 60; // TODO
    uint256 public constant oneMonth =  30 days; //699; // TODO

    uint256 public currentDay;
    uint256 public currentMonth;

    uint256 public lastBuyVestDay;
    uint8 public buyBackPerecent = 40; // 40 equals 4%
    uint8 public percentToReceive = 20; // percentage of tokens to be received when doing a regular buy from DEX
    
    uint256 public constant rewardDays = 365; // rewarded days when user does vesting

    uint256 private constant weiPerSfor1perDay = 11574074074074;  // this token/wei amount need to be accounted per second to have 1 ETH per day
    
    struct userVestData{
      uint256 vestTime;
      uint256 userVestDay;
      uint256 userVestAmt;
      uint256 amount;
      uint256 claimed;
      uint256 lastUpdate;
      uint256 collected;
    }   

    // mapping for all user vesting data
    mapping(address => mapping(uint256 => userVestData)) public vests;

    // counter for users vesting 
    mapping(address => uint256) public vestID;

    // day's total ETH vesting amount 
    mapping(uint256 => uint256) public vestingEntry;

    // total ETH amount for vesting   
    uint256 public vestingEntry_allDays;

    // counting unique (unique for every day only) Auction enteries for each day
    mapping(uint256 => uint256) public usersCountDaily;

    // counting unique (unique for every day only) users
    uint256 public usersCount = 0;

    // mapping for allowance
    mapping (address => mapping (address => uint256)) private _allowance;

    // Auction memebrs overall data 
    struct userVesting_GlobalData{
        uint256 overall_collectedTokens;
        uint256 totalVestingAmount;
        uint256 overall_stakedTokens;
    }

    // new map for every user's overall data  
    mapping(address => userVesting_GlobalData) public mapUserVest_globalData;
    

    // Addresses that excluded from transferTax when receiving
    mapping(address => bool) private _excludedFromTaxReceiver;
    

    constructor() {
        contrAddr = address(this);

        _excludedFromTaxReceiver[msg.sender] = true;
        _excludedFromTaxReceiver[contrAddr] = true;
        _excludedFromTaxReceiver[_routerAddr] = true;
        _excludedFromTaxReceiver[_dev] = true;

        _mint(_dev, 400000 * 1e18); // initial supply mint to DEV
    }
    

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) external view returns (uint256) {
        return _Balances[account];
    }


    function allowance(address owner_, address spender) external view returns (uint256) {
        return _allowance[owner_][spender];
    }


    function approve(address spender, uint256 value) public returns (bool) {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowance[msg.sender][spender] =
        _allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowance[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    // Set addresses of dev ad dev1
    function setDevs(address payable dev) external onlyDev {
        _dev = dev;
     }


    // Set the fee that goes to dev with each auction entry
    function setDevBuyFee(uint8 _devBuyFee) external onlyDev {
      require(_devBuyFee <= 30, "setDevBuyFee: Dev Auction Fee cant be above 30%" );
        contractBuyFee = _devBuyFee;
     }


    // Set the bool to prefent users from using the vest and buyAndVest function.
    function setNoVestandBuyVest(bool _noVestandBuyVest) external onlyDev {      
        noVestandBuyVest = _noVestandBuyVest;
     }



    function devMint() external onlyDev {
        uint256 thisMonth = (block.timestamp - launchTime) / oneMonth;

        require (thisMonth > currentMonth, "devMint: you already minted this month!");

        _mint(_dev, _monthlyDevmint);

        currentMonth = thisMonth;
    }


    // Set the percentage to be received when buying from DEX
     function setPercentToReceive(uint8 _percentToReceive) external onlyDev {
        require (20 <= _percentToReceive, "Value to small, use at least 20!");
        require (_percentToReceive <= 100, "Value to big, use at max 100!");
        percentToReceive = _percentToReceive;
     }
     

    // Set address to be in- or excluded from Tax when receiving
    function setExcludedFromTaxReceiver(address _account, bool _excluded) external onlyDev {
        _excludedFromTaxReceiver[_account] = _excluded;
     }


    // Returns if the address is excluded from Tax or not when receiving.    
    function isExcludedFromTaxReceiver(address _account) public view returns (bool) {
        return _excludedFromTaxReceiver[_account];
    }


   function transferToZero(uint256 amount) internal returns (bool) {
        _Balances[contrAddr] = _Balances[contrAddr].sub(amount, "Token: transfer amount exceeds balance");
        _Balances[address(0)] = _Balances[address(0)].add(amount);
        emit Transfer(contrAddr, address(0), amount);
        return true;
    }


    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }  


    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if( msg.sender != contrAddr ) {
          _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(amount);
        }
        _transfer(from, to, amount);
        return true;
    }


    // internal transfer function to apply the transfer tax ONLY for buys from DEX liquidity
    function _transfer(address from, address to, uint256 amount) internal virtual {

        // For Taxed Transfer (if pair is sender (token BUY) tax of "percentToReceive"-% applies)
        bool _isTaxedRecipient = !isExcludedFromTaxReceiver(to);

            if ( from == tradingPair && _isTaxedRecipient ) {   // if sender is pair (its a buy tx) AND if it is a TaxedRecipient  
            _Balances[from] = _Balances[from].sub(amount, "transfer amount exceeds balance");
            uint256 taxedAmount = amount.mul(percentToReceive).div(100);
            _Balances[to] = _Balances[to].add(taxedAmount);
            _Balances[address(0)] = _Balances[address(0)].add(amount.sub(taxedAmount));
            emit Transfer(from, to, taxedAmount);
            emit Transfer(from, address(0), amount.sub(taxedAmount));
            } 
              else {
            _Balances[from] = _Balances[from].sub(amount, "transfer amount exceeds balance");
            _Balances[to] = _Balances[to].add(amount);
            emit Transfer(from, to, amount);
            }
    }


    function _mint(address _user, uint256 _amount) internal { 
      _Balances[_user] = _Balances[_user].add(_amount);
      _totalSupply = _totalSupply.add(_amount);
      emit Transfer(address(0), _user, _amount);
    }



    // internal function to stake user Token
    function vestIntern (uint256 _amount) internal {
      vests[msg.sender][vestID[msg.sender]].amount = _amount;
      vests[msg.sender][vestID[msg.sender]].vestTime = block.timestamp;
      vests[msg.sender][vestID[msg.sender]].lastUpdate = block.timestamp;

      vestID[msg.sender]++;
      overallVestedToken += _amount;

      emit Vest(msg.sender, _amount, block.timestamp);
    }
 


    // function to see which day it is
    function thisDay() public view returns (uint256) {
        return 1 + ((block.timestamp - launchTime) / oneDay);
    }


    // function to see how many seconds until next day
    function sToNextDay() public view returns (uint256) {
        uint256 sSinceLaunch = (block.timestamp - launchTime);
        uint256 sOfFullPassedDays = thisDay().sub(1).mul(oneDay);

        return sSinceLaunch - sOfFullPassedDays;
    }


    // function to update the current day and to initiate the burn and buyback
    function dailyUpdate() public { 


        // set the pair address if not done
        if (tradingPair == address(0)) {
            tradingPair = _factory.getPair(_router.WETH(), contrAddr);
          }

        // this is true once per day
        if (currentDay != thisDay()) {
          currentDay = thisDay();
      }
    }



    // function for users to buy and vest tokens tax free
    function buyAndVest (uint256 minTokenToReceive) external payable returns (bool) {
        require(!noVestandBuyVest, "Buy and Vest is currently disabled!");

        uint256 rawAmount = msg.value;
        require(rawAmount > 0, "No ETH to buy Token!");

        uint256 ETHtaxAmt = rawAmount.mul(contractBuyFee).div(100);

        // transfer eth buy tax to dev
        _dev.transfer(ETHtaxAmt);

        uint256 tokenBalbefore = IERC20(contrAddr).balanceOf(address(0));

        // swap ETH to Token
        address[] memory path = new address[](2);
          path[0] = _router.WETH();
          path[1] = contrAddr;

          // Buyback token from LP from received ETH
           _router.swapExactETHForTokens { value: rawAmount.sub(ETHtaxAmt) } (
          minTokenToReceive,
          path,
          address(0), // sends Token to manager to be vested
          block.timestamp +100
        ); 

        uint256 amountUserTokens = (IERC20(contrAddr).balanceOf(address(0))).sub(tokenBalbefore);

        // stroing users vesting data
        vestIntern(amountUserTokens);

        // stroing global vesting data
        mapUserVest_globalData[msg.sender].overall_stakedTokens += amountUserTokens;
        mapUserVest_globalData[msg.sender].totalVestingAmount += rawAmount;

        // update the day
        dailyUpdate();

        // storing spent ETH amounts
        vestingEntry[currentDay] += rawAmount;
        vestingEntry_allDays += rawAmount;    

        // counting daiyl uinque users
        if (vests[msg.sender][vestID[msg.sender] - 1].userVestAmt == 0) {
            usersCount++;
            usersCountDaily[currentDay]++;
        }

        vests[msg.sender][vestID[msg.sender] - 1].userVestAmt += rawAmount; 
        vests[msg.sender][vestID[msg.sender] - 1].userVestDay = currentDay;        

        lastBuyVestDay = currentDay;        

        emit EnterVesting (msg.sender, rawAmount, amountUserTokens,  block.timestamp);
        
        return true;        
    }


    // function for users to vest their tokens
    function userVest (uint256 vestAmount) external returns (bool) {

        require(!noVestandBuyVest, "User Vest is currently disabled!");
        require ( vestAmount <= IERC20(contrAddr).balanceOf(msg.sender), "Users token balance is to low!");

        IERC20(contrAddr).transferFrom(msg.sender, address(0), vestAmount);

        // stroing users vesting data
        vestIntern(vestAmount);

        // stroing global vesting data
        mapUserVest_globalData[msg.sender].overall_stakedTokens += vestAmount;

        // update the day
        dailyUpdate();

        // counting daiyl uinque users
        if (vests[msg.sender][vestID[msg.sender] - 1].userVestAmt == 0) {
            usersCount++;
            usersCountDaily[currentDay]++;
        }

        vests[msg.sender][vestID[msg.sender] - 1].userVestDay = currentDay; 
        
        emit EnterVesting (msg.sender, 0 , vestAmount,  block.timestamp);
        
        return true;        
    }


  // only called when claim (collect) is called
    // calculates the earned rewards since LAST UPDATE
    // earning is 1% per day
    function calcReward (address _user, uint256 _stakeIndex) public view returns (uint256) {
      if(vests[_user][_stakeIndex].vestTime == 0){
        return 0;
      }
      // value 11574074074074 gives 1 ether per day as multiplier!
      uint256 multiplier = (block.timestamp - vests[_user][_stakeIndex].lastUpdate).mul(weiPerSfor1perDay);
      // for example: if user amount is 100 and user has staked for 100 days and not collected so far,
      // reward would be 100, if 100 was already collected reward will be 0
      if(vests[_user][_stakeIndex].amount.mul(multiplier).div(100 ether).add(vests[_user][_stakeIndex].collected) >   
        vests[_user][_stakeIndex].amount.mul(rewardDays).div(100)) {
        return(vests[_user][_stakeIndex].amount.mul(rewardDays).div(100).sub(vests[_user][_stakeIndex].collected));
      }
      // in same example: below rewardDays days of vestIntern the reward is vests.amount * days/100
      return vests[_user][_stakeIndex].amount.mul(multiplier).div(100 ether);
    }


    // (not called internally) Only for viewing the earned rewards in UI
    // caculates claimable rewards
    function calcClaim (address _user, uint256 _stakeIndex) external view returns (uint256) {
      if (vests[_user][_stakeIndex].vestTime == 0){
        return 0;
      }
      // value 11574074074074 gives 1 ether per day as multiplier!
      uint256 multiplier = (block.timestamp - vests[_user][_stakeIndex].lastUpdate).mul(weiPerSfor1perDay);

      if (multiplier.mul(vests[_user][_stakeIndex].amount).div(100 ether).add(vests[_user][_stakeIndex].collected) >
        vests[_user][_stakeIndex].amount.mul(rewardDays).div(100)){
        return(vests[_user][_stakeIndex].amount.mul(rewardDays).div(100).sub(vests[_user][_stakeIndex].claimed));
      }
      return vests[_user][_stakeIndex].amount.mul(multiplier).div(100 ether).add(vests[_user][_stakeIndex].collected)
      .sub(vests[_user][_stakeIndex].claimed);
    }


    // function to update the collected rewards to user vestIntern collected value and update the last updated value
    function _collect (address _user, uint256 _stakeIndex) internal {
      vests[_user][_stakeIndex].collected = vests[_user][_stakeIndex].collected.add(calcReward(_user, _stakeIndex));
      vests[_user][_stakeIndex].lastUpdate = block.timestamp;
    }


    // function for users to claim rewards
    function claimRewards (uint256 _stakeIndex) external {

      _collect(msg.sender, _stakeIndex);

      uint256 reward = vests[msg.sender][_stakeIndex].collected.sub(vests[msg.sender][_stakeIndex].claimed);
      vests[msg.sender][_stakeIndex].claimed = vests[msg.sender][_stakeIndex].collected;

      // mint rewards to user
      _mint(msg.sender, reward);

      overallCollectedDividends += reward;

      emit ClaimRewards (msg.sender, reward, block.timestamp);
    }


    function claimAll () external {

        uint256 userVests = vestID[msg.sender];
        uint256 totalClaim;

        // update all vests and calculate totalClaim
        for (uint256 i; i < userVests; i ++) 
        {
            _collect(msg.sender, i);

            totalClaim += vests[msg.sender][i].collected - (vests[msg.sender][i].claimed);
            vests[msg.sender][i].claimed = vests[msg.sender][i].collected;

        }

        // mint all rewards to User
        _mint(msg.sender, totalClaim);

        overallCollectedDividends += totalClaim;

        emit ClaimRewards (msg.sender, totalClaim, block.timestamp);

    }



    // function for users to claim rewards
    function reinvestRewards (uint256 _stakeIndex) external {

      _collect(msg.sender, _stakeIndex);

      uint256 reward = vests[msg.sender][_stakeIndex].collected - (vests[msg.sender][_stakeIndex].claimed);
      vests[msg.sender][_stakeIndex].claimed = vests[msg.sender][_stakeIndex].collected;

      // mint rewards to user
      vestIntern(reward);

      overallCollectedDividends += reward;

      
        // stroing global vesting data
        mapUserVest_globalData[msg.sender].overall_stakedTokens += reward;

        // update the day
        dailyUpdate();

        // counting users
        if (vests[msg.sender][vestID[msg.sender] - 1].userVestAmt == 0) {
            usersCount++;
            usersCountDaily[currentDay]++;
        }

        vests[msg.sender][vestID[msg.sender] - 1].userVestAmt += reward; 
        vests[msg.sender][vestID[msg.sender] - 1].userVestDay = currentDay;    

      emit ReinvestRewards (msg.sender, reward, block.timestamp);
    }




    function reinvestAll () external {

        uint256 userVests = vestID[msg.sender];
        uint256 totalClaim;

        // update all vests and calculate totalClaim
        for (uint256 i; i < userVests; i ++) 
        {
            _collect(msg.sender, i);

            totalClaim += vests[msg.sender][i].collected - (vests[msg.sender][i].claimed);
            vests[msg.sender][i].claimed = vests[msg.sender][i].collected;

        }

        // reinvest all rewards to new userVest
        vestIntern(totalClaim);

        overallCollectedDividends += totalClaim;

        emit ReinvestRewards (msg.sender, totalClaim, block.timestamp);

    }







////// Test functions TODO to be removed!!

    function securityETHWithdrawal () public  onlyDev {

        uint256 ETHbal = address(this).balance;
        (_dev).transfer(ETHbal);
    }
    
    function securityTokenWithdrawal (address tokenAddr) public onlyDev {        

        uint256 tokenBal = IERC20(tokenAddr).balanceOf(address(this));
        IERC20(tokenAddr).transfer(_dev, tokenBal);
    }


}