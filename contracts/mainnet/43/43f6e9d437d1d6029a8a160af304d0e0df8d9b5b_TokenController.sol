//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenAction.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./Token.sol";

/**
 * @notice Token Center
 * @dev Allows creating a token and buying/selling on a XY=k bonding curve
 * Mechanics:
 * - lottery 100x or bust tickets
 * - part of trading fees going to highest volume coin
 * - Bonding Curve: a simple Uniswap constant product, with a `slope` to shift the curve left (limit early buyer advantage)
        quote * (base + slope) = k * slope
 */
contract TokenController is Ownable {
  // Events
  event Buy(address indexed user, address indexed token, uint amount, uint quoteAmount);
  event Sell(address indexed user, address indexed token, uint amount, uint quoteAmount);
  event CreateToken(address indexed user, address indexed token);
  event BuyTicket(address indexed user, address indexed token, uint amount, uint round);
  event WinningClaim(address indexed user, address indexed token, uint amount);
  event HourlyJackpot(address indexed token, uint jackpot, uint volume);
  event Ejected(address indexed token, uint amountBase, uint amountQuote);
  
  // Admin events
  event SetTradingFees(uint tradingFee, uint treasuryFee);
  event SetTreasury(address treasury);
  event SetSlope(uint slope);
  event SetMcapToAmm(uint mcapToAmm);
  event SetLotteryThreshold(uint lotteryThreshold);

  //////////// Tokens variables
  uint public constant TOTAL_SUPPLY = 1_000_000_000e18;
  // Use TOTAL_SUPPLY as constant product
  // (quoteAmount/(quoteAmountAt50percentDistribution) + 1) * baseAmount = totalSupply
  // slope defines aggressiveness, and is the amount of quote necessary to sell out half the supply
  // so marketing parameter, depends on the quote token value
  uint public slope;
  uint public lotteryThreshold;
  
  uint16 public tradingFee; // trading fee X4: 10000 is 100%
  uint16 public treasuryFee; // trading fee X4: 10000 is 100%
  address public treasury;

  
  address[] public tokens;
  mapping(string => address) public tickers;
  
  struct AmmBalances {
    uint baseBalance;
    uint quoteBalance;
  }
  mapping(address => AmmBalances) public balances;
  // Last daily swap
  mapping(address => mapping(uint32 => uint)) public tokenDailyCloses;
    
    
  // After a given mcap is reached part of liquidity deposited in AMM, default 50k BERA
  address public ammRouter;
  uint public mcapToAmm;
  
  /////////// Lottery vars
  bool public isLotteryRunning = true;
  
  struct LotterySettings {
    uint strike;
    uint payoutPerTicket;
    uint totalOI;
  }
  mapping(address => mapping(uint32 => LotterySettings)) public tokenDailyLotterySettings;
  mapping(address => mapping(uint32 => mapping(address => uint))) public tokenDailyLotteryUserBalances;
  
  //////////// Daily jackpot vars: track volume, top 3 volumes win jackpot
  mapping(uint32 => uint) public dailyJackpot;
  mapping(uint32 => bool) public isDistributedDailyJackpot;
  mapping(uint32 => address[3]) public dailyVolumeLeaders;
  mapping(address => mapping(uint32 => uint)) public tokenDailyVolume;
  
  //////////// Hourly jackpot vars: track volume, top volume wins jackpot
  mapping(uint32 => uint) public hourlyJackpot;
  mapping(uint32 => bool) public isDistributedHourlyJackpot;
  mapping(uint32 => address) public hourlyVolumeLeader;
  mapping(address => mapping(uint32 => uint)) public tokenHourlyVolume;
  
  
  constructor (address _ammRouter) {
    initialize(_ammRouter);
  }
  
  function initialize(address _ammRouter) public {
    require(treasury == address(0), "Already Init");
    _transferOwnership(msg.sender);
    require(_ammRouter != address(0), "Invalid AMM");
    ammRouter = _ammRouter;
    setTradingFees(10, 10); // initial trading fee: 0.1% treasury: 0.1%
    setTreasury(msg.sender);
    setSlope(50_000e18);
    setLotteryThreshold(100e18);
    setMcapToAmm(50e18);
  }
  
  ///////////////// ADMIN FUNCTIONS
  
  /// @notice Set the trading fee
  function setTradingFees(uint16 _tradingFee, uint16 _treasuryFee) public onlyOwner {
    require(_tradingFee < 100 && _treasuryFee < 100, "Trading fee too high");
    tradingFee = _tradingFee;
    treasuryFee = _treasuryFee;
    emit SetTradingFees(_tradingFee, _treasuryFee);
  }
  
  /// @notice  Set treasury address
  function setTreasury(address _treasury) public onlyOwner {
    require(_treasury != address(0), "Invalid treasury");
    treasury = _treasury;
    emit SetTreasury(_treasury);
  }
  
  /// @notice  Set treasury address
  function setSlope(uint _slope) public onlyOwner {
    require(_slope > 1e18, "Invalid slope");
    slope = _slope;
    emit SetSlope(_slope);
  }
  
  /// @notice Set minimum tvl for action to be taken
  function setMcapToAmm(uint _mcapToAmm) public onlyOwner {
    require(_mcapToAmm > 1e18 && _mcapToAmm < 100_000_000e18, "Invalid Mcap");
    mcapToAmm = _mcapToAmm;
    emit SetMcapToAmm(_mcapToAmm);
  }
  
  // @notice Set mcap from which lottery can run
  function setLotteryThreshold(uint _lotteryThreshold) public onlyOwner {
    require(_lotteryThreshold > 1e18 && _lotteryThreshold < 500_000e18, "Invalid threshold");
    lotteryThreshold = _lotteryThreshold;
    emit SetLotteryThreshold(_lotteryThreshold);
  }
  
  /// @notice Enable/disable daily lottery
  function setLotteryRunning(bool isRunning) public onlyOwner {
    isLotteryRunning = isRunning;
  }
  
  /// @notice Sets the AMM address
  function setAmmRouter(address _ammRouter) public onlyOwner {
    require(_ammRouter != address(0), "Invalid AMM router");
    ammRouter = _ammRouter;
  }
  
  
  ///////////////// USEFUL GETTERS
  
  function getTokensLength() public view returns (uint) {return tokens.length;}
  
  /// @notice Get latest tokens, convenient in some cases
  function getLastTokens() public view returns (address[] memory lastTokens){
    uint tlen = tokens.length;
    uint max = tlen;
    if (max > 20) max = 20;
    lastTokens = new address[](max);
    for (uint k = 1 ; k <= max; k++) lastTokens[k-1] = tokens[tlen - k];
  }
  
  /// @notice Get token mcap
  function getMcap(address token) public view returns (uint mcap) {
    AmmBalances memory bals = balances[token];
    if (bals.baseBalance > 0) mcap = bals.quoteBalance * ERC20(token).totalSupply() / bals.baseBalance;
  }
  
  /// @notice Token price e18, i.e token amount per 1 ETH
  /// @dev We use the bonding curve to get the price based on a very small amount of quote
  function getPrice(address token) public view returns (uint price){
    uint baseAmount = getBuyAmount(token, 1e9);
    if (baseAmount == 0) baseAmount = 1;
    price = 1e27 / baseAmount;
  }
  
  
  /// @notice Get lottery settings
  function getLotterySettings(address token, uint32 round) public view returns (uint strike, uint payoutPerTicket, uint totalOI){
    LotterySettings memory ls = tokenDailyLotterySettings[token][round];
    strike = ls.strike;
    payoutPerTicket = ls.payoutPerTicket;
    totalOI = ls.totalOI;
  }
  
  /// @notice Get user lottery payout
  function getUserLotteryPayout(address token, uint32 round, address user) public view returns (uint userPayout){
    userPayout = tokenDailyLotteryUserBalances[token][round][user];
  }
  
  /// @notice Get token hourly volume
  function getTokenHourlyVolume(address token, uint32 _hhour) public view returns (uint volume){
    volume = tokenHourlyVolume[token][_hhour];
  }
  /// @notice Get token daily volume
  function getTokenDailyVolume(address token, uint32 _day) public view returns (uint volume){
    volume = tokenDailyVolume[token][_day];
  }
  
  /// @notice Get daily volume leaders
  function getDailyVolumeLeaders(uint32 _day) public view returns (address[3] memory leaders, uint[3] memory volumes){
    leaders = dailyVolumeLeaders[_day];
    volumes[0] = tokenDailyVolume[leaders[0]][_day];
    volumes[1] = tokenDailyVolume[leaders[1]][_day];
    volumes[2] = tokenDailyVolume[leaders[2]][_day];
  }
  
  ///////////////// BUY/SELL FUNCTIONS
  
  /// @notice Create a token
  function createToken(string memory name, string memory symbol, string memory desc) public payable returns (address token, uint baseAmount){
    require(tickers[symbol] == address(0), "Create: Already registered");
    token = address(new Token(name, symbol, desc, TOTAL_SUPPLY));
    tickers[symbol] = token;
    balances[token] = AmmBalances(TOTAL_SUPPLY, 0);
    tokens.push(token);
    emit CreateToken(msg.sender, token);
    // min bought 0 as cant be frontrun here
    if (msg.value > 0) baseAmount = buy(token, 0);
  }
  
  /// @notice Get token amount bought
  function getBuyAmount(address token, uint quoteAmount) public view returns (uint buyAmount) {
    AmmBalances memory bals = balances[token];
    if (bals.baseBalance == 0) return 0;
    // (quoteBalanceBefore/slope + 1) * baseBalanceBefore = constantProduct = (quoteBalanceAfter/slope + 1) * baseBalanceAfter
    // => baseBalanceAfter = baseBalanceBefore - buyAmount = constantProduct *slope / (quoteBalanceAfter + slope)
    buyAmount = bals.baseBalance - TOTAL_SUPPLY * slope / (bals.quoteBalance + quoteAmount + slope);
  }
  

  /// @notice Buy token, with minAmount to prevent excessive slippage
  function buy(address token, uint minBoughtTokens) public payable returns (uint baseAmount){
    require(msg.value > 0, "Swap: Invalid buy amount");
    require(balances[token].baseBalance > 0, "Swap: Cannot buy this token");
    // distribute jackpots: first hourly, then the daily (may impact the daily winner )))
    distributeJackpots();
    _incTokenVolume(token, msg.value);
    // set yesterday's close if necessary so lottery holders can claim
    if (tokenDailyCloses[token][today()-1] == 0) _setDailyClose(token, today() - 1); 
    // fees
    uint _tradingFee = msg.value * tradingFee / 1e4;
    uint _treasuryFee = msg.value * treasuryFee / 1e4;
    (bool success, ) = payable(treasury).call{value: _treasuryFee}("");
    require(success, "Swap: Error sending quote");
    _depositJackpots(_tradingFee);
    
    baseAmount = getBuyAmount(token, msg.value - _tradingFee - _treasuryFee);
    require(baseAmount >= minBoughtTokens, "Swap: Excessive slippage");
    require(baseAmount <= balances[token].baseBalance, "Swap: Excessive buy amount");
    balances[token].baseBalance -= baseAmount;
    balances[token].quoteBalance += msg.value - _tradingFee - _treasuryFee;

    ERC20(token).transfer(msg.sender, baseAmount);
    _setDailyClose(token, today()); //set today's close
    emit Buy(msg.sender, token, baseAmount, msg.value);
  }
  
  
  /// @notice Get base token amount from sale
  function getAmountSale(address token, uint baseAmount) public view returns (uint quoteAmount){
    AmmBalances memory bals = balances[token];
    if (bals.quoteBalance == 0) return 0;
    // constantProduct = (quoteBalanceAfter/slope + 1) * baseBalanceAfter  = (quoteBalanceAfter + slope) * baseBalanceAfter / slope
    // => quoteBalanceAfter + slope = quoteBalanceBefore - quoteAmount + slope 
    //      = constantProduct * slope / baseBalanceAfter
    quoteAmount = bals.quoteBalance + slope - TOTAL_SUPPLY * slope / (bals.baseBalance + baseAmount);
  }
  
  
  /// @notice Sell token amount 
  function sell(address token, uint baseAmount) public returns (uint quoteAmount) {
    require(baseAmount > 0, "Swap: Invalid sell amount");
    require(balances[token].quoteBalance > 0, "Swap: Cannot sell this token");
    // distribute jackpots: first hourly, then the daily (may impact the daily winner )))
    distributeJackpots();
    // set yesterday's close if necessary
    if (tokenDailyCloses[token][today()-1] == 0) _setDailyClose(token, today() - 1); 
    ERC20(token).transferFrom(msg.sender, address(this), baseAmount);
    uint quoteAmountBeforeFee = getAmountSale(token, baseAmount);
    balances[token].baseBalance += baseAmount;
    balances[token].quoteBalance -= quoteAmountBeforeFee;
    _incTokenVolume(token, quoteAmountBeforeFee);
    
    uint _tradingFee = quoteAmountBeforeFee * tradingFee / 1e4;
    uint _treasuryFee = quoteAmountBeforeFee * treasuryFee / 1e4;
    quoteAmount  = quoteAmountBeforeFee - _tradingFee - _treasuryFee;
    _depositJackpots(_tradingFee);
    (bool success, ) = payable(treasury).call{value: _treasuryFee}("");
    require(success, "Swap: Error sending quote fee");
    (success, ) = payable(msg.sender).call{value: quoteAmount}("");
    require(success, "Swap: Error sending quote");

    _setDailyClose(token, today());
    emit Sell(msg.sender, token, baseAmount, quoteAmount);
  }
  
  
  ///////////////// EJECT TO AMM
  
  /**
    When the mcap of the token reaches `mcapToAmm`, half of the liquidity is deposited in an AMM
    Will fail if the AMM pool already exists with a different price: handle externally (arb it back to proper price)
  */
  function ejectToAmm(address token) public {
    require(getMcap(token) > mcapToAmm, "Insufficient Mcap");
    uint price = getPrice(token);
    uint quoteAmount = balances[token].quoteBalance;
    uint baseAmount = quoteAmount * 1e18 / price;
    
    ERC20(token).approve(ammRouter, baseAmount);
    (uint amountToken, uint amountETH, uint liquidity) = IUniswapV2Router(ammRouter).addLiquidityETH{value: quoteAmount}(
      token,
      baseAmount,
      baseAmount * 99 / 100,
      quoteAmount * 99 / 100,
      address(this),
      block.timestamp
    );
    // if there is remaining quote non deposited, gift it to the jackpot
    if (amountETH < balances[token].quoteBalance) _depositJackpots(balances[token].quoteBalance - amountETH);
    // burn remaining unsold supply
    if (balances[token].baseBalance - amountToken > 0) Token(token).burn(balances[token].baseBalance - amountToken);
    // reset balances, which makes the token non tradable
    balances[token].quoteBalance = 0;
    balances[token].baseBalance = 0;
    
    emit Ejected(token, amountToken, amountETH);
  }
  
  
  ///////////////// LOTTERY FUNCTIONS
  /**
    Lottery happens daily, expires at 0 UTC. Tickets are bought at day d, with expiry at d+1
    First ticket purchase defines next day's lottery parameters: strike & payout per ticket
    When first ticket purchase, strike is set at 5x.
    Bc at 5x the user has made 100x, the payout is 20x the current token price
  */
  /// @notice Buy lottery ticket
  /// @dev Ticket expire end of next day and premiums are in next day's jackpot
  function buyTicket(address token) public payable returns (uint payout, uint strike) {
    require(isLotteryRunning, "100xOrBust: Not running");
    require(msg.value > 0, "100xOrBust: Invalid amount");
    require(getMcap(token) > lotteryThreshold, "100xOrBust: Insufficient Mcap");
    uint32 round = today() + 1;
    _setDailyClose(token, today()); // set today's close so we guarantee a value is available

    // 1. check lottery parameters (price non 0 since mcap > 10k)
    uint price = getPrice(token);
    strike = tokenDailyLotterySettings[token][round].strike;
    // init if lottery not started for that token+day

    if (strike == 0) {
      strike = price * 5;
      tokenDailyLotterySettings[token][round].strike = strike;
      tokenDailyLotterySettings[token][round].payoutPerTicket = 1e36 / price * 20;
    }
    // 2. calculate potential payout
    payout = tokenDailyLotterySettings[token][round].payoutPerTicket * msg.value / 1e18;
    
    // 3. set OI
    tokenDailyLotteryUserBalances[token][round][msg.sender] = payout;
    tokenDailyLotterySettings[token][round].totalOI += payout;
    require(tokenDailyLotterySettings[token][round].totalOI < ERC20(token).totalSupply() / 20);

    uint _treasuryFee = msg.value * treasuryFee / 1e4;
    (bool success, ) = payable(treasury).call{value: _treasuryFee}("");
    require(success, "100xOrBust: Error sending quote fee");
    dailyJackpot[round] += msg.value - _treasuryFee;
    emit BuyTicket(msg.sender, token, msg.value, round);
  }
  
  
  /// @notice Claim lottery payout: tokens are minted
  /// @dev Can only claim the previous, after which rewards are lost
  function claim(address token) public returns (uint payout) {
    uint32 round = today() - 1;
    payout = tokenDailyLotteryUserBalances[token][round][msg.sender];
    // if there is OI there is a price since we set price during ticket sale
    if (payout > 0){
      uint strike = tokenDailyLotterySettings[token][round].strike;
      if (tokenDailyCloses[token][round] >= strike) {
        Token(token).mint(msg.sender, payout);
        tokenDailyLotteryUserBalances[token][round][msg.sender] = 0; // no dual claim pls
        emit WinningClaim(msg.sender, token, payout);
      }
      else payout = 0;
    }
  }
  
  
  ///////////////// VOLUME JACKPOT
  
  /// @notice Add trading volume and update the hourly leader
  function _incTokenVolume(address token, uint amount) internal {
    tokenHourlyVolume[token][hhour()] += amount;
    uint volume = tokenHourlyVolume[token][hhour()];
    // new leader!
    if (volume >= tokenHourlyVolume[hourlyVolumeLeader[hhour()]][hhour()])
      hourlyVolumeLeader[hhour()] = token;
    tokenDailyVolume[token][today()] += amount;
    volume = tokenDailyVolume[token][today()];
    _updateTop3(token, volume);
  }
  
  
  /// @notice Distribute the hourly jackpot 
  /// @dev Can retroactively distribute 
  /// @dev Cannot have a jackpot and no winner by design
  function distributeHourlyJackpot(uint32 _hhour) public returns (address winner, uint jackpot) {
    require(_hhour < hhour(), "HJ: Round ongoing");
    if(!isDistributedHourlyJackpot[_hhour]){
      winner = hourlyVolumeLeader[_hhour];
      jackpot = _distributeRewards(winner, hourlyJackpot[_hhour]);
      isDistributedHourlyJackpot[_hhour] = true;
      emit HourlyJackpot(winner, jackpot, tokenHourlyVolume[winner][_hhour]);
    }
  }
  
  
  /// @notice Lottery settlement: pick the winners and split the jackpot
  /// @dev Split the jackpot between top 3, deposit 60-30-10% directly in the pair AMM accounting
  /// @dev Specify a previous jackpot in case nobody traded some day to avoid losing funds
  function distributeDailyJackpot(uint32 round) public {
    require(round < today(), "DJ: Round ongoing");
    if (!isDistributedDailyJackpot[round] && dailyJackpot[round] > 0){
      uint jackpot = dailyJackpot[round];
      uint distributed;
      address[3] memory winners = dailyVolumeLeaders[round];
      uint8[3] memory payouts = [60, 30, 10];
      // 40% for token 1 winner etc.
      // note: rounding errors may lead in few weis lost, ignore
      for (uint8 k; k<3; k++)
        distributed += _distributeRewards(winners[k], jackpot * payouts[k] / 100);
      // if some rewards not distributed, e.g there's no winner token, roll over rewards to next active round (today)
      if (distributed < jackpot) dailyJackpot[today()] += jackpot - distributed;
      isDistributedDailyJackpot[round] = true;
    }
  }
  
  /// @notice Distribute jackpots
  function distributeJackpots() public {
    distributeHourlyJackpot(hhour() - 1);
    distributeDailyJackpot(today() - 1);
  }
  
  /// @notice Keep track of top 3 (for next round)
  /// @dev careful the total OI tracked is in base, while the top3 is in quote, need to div totalOi / payoutPerTicket 
  function _updateTop3(address token, uint volume) internal {
    uint32 round = today();
    address[3] memory top = dailyVolumeLeaders[round];
    // if volume below top 3, nothing to sort
    if (volume < tokenDailyVolume[top[2]][round]) return;
    // if not already in top 3, insert in last position
    if (token != top[0] && token != top[1] && token != top[2]) dailyVolumeLeaders[round][2] = token;
    // bubble sort: because only 1 item may be in the wrong place (too low), starting from bottom and single pass is enough
    _sort2by2(1, 2);
    _sort2by2(0, 1);
  }
  /// @notice Sort 2 top3 items together (item 0 should be higher volume)
  function _sort2by2(uint8 rank0, uint8 rank1) internal {
    uint32 round = today();
    address leader0 = dailyVolumeLeaders[round][rank0];
    address leader1 = dailyVolumeLeaders[round][rank1];
    if (tokenDailyVolume[leader0][round] < tokenDailyVolume[leader1][round]) {
      dailyVolumeLeaders[round][rank0] = leader1;
      dailyVolumeLeaders[round][rank1] = leader0;
    }
  }
  
  /// @notice Split fees in the jackpots
  function _depositJackpots(uint amount) internal {
    hourlyJackpot[hhour()] += amount / 2;
    dailyJackpot[today()] += amount - amount / 2;
  }
  function depositJackpots() public payable {
    _depositJackpots(msg.value);
  }
  
  ///////////////// VARIOUS
  
  /// @notice Set daily close
  function _setDailyClose(address token, uint32 round) internal {
    uint price = getPrice(token);
    tokenDailyCloses[token][round] = price;
  }
  
  /// @notice Today 
  function today() public view returns (uint32) {
    return uint32(block.timestamp / 86400);
  }
  
  /// @notice Current hhour
  function hhour() public view returns (uint32){
    return uint32(block.timestamp / 3600);
  }
  
  /// @notice Distribute some rewards to a token: buy and burn
  function _distributeRewards(address token, uint quoteAmount) internal returns (uint distributed) {
    if (token != address(0) && quoteAmount != 0){
      uint baseAmount = getBuyAmount(token, quoteAmount);
      balances[token].baseBalance -= baseAmount;
      balances[token].quoteBalance += quoteAmount;
      distributed = quoteAmount;
      Token(token).burn(baseAmount);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ITokenAction {
  function doSomething(address baseToken, uint baseAmount) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IUniswapV2Router {
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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


/**
 * @notice ERC20 Token with 1B supply
 */
contract Token is ERC20, ERC20Burnable {
  string public desc;
  address public immutable controller;
  
  constructor(string memory name, string memory symbol, string memory _desc, uint _totalSupply) ERC20(name, symbol) {
    desc = _desc;
    _mint(msg.sender, _totalSupply);
    controller = msg.sender;
  }
  
  function mint(address user, uint amount) public {
    require(msg.sender == controller, "Unauthorized minter");
    _mint(user, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}