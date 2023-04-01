// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ISwapRouter.sol";
import "../interfaces/AggregatorV3Interface.sol";

//import "./interfaces/IOracle.sol";

contract TradingAccount is Pausable, Ownable {

    uint256 private constant MAX_INT = ~uint256(0);
    uint256 private constant SLIPPAGE_PRECISION = 1e6;

    //8
    uint8 private price_precision;

    AggregatorV3Interface private priceFeed;
    ISwapRouter private  swapRouter;


    //交易对
    address public  usd;
    address public  token;
    

    //网格数目
    uint256 public gridLevels;

    //每一格的实际购买的资产数量
    uint256[] public amountPerGrid;

    //usd,理论值，怎么转化成实际值，确保交易成功
    //（1）需预留交易手续费，
    //价格间隔
    uint256 public gridInterval;
    uint256 public openTradePrice;


    //当前网格位置
    uint256 public currentLevel;
    uint256 public currentLevelPrice;

    //交易手续费 精度 1000000
    //the fee for a pool at the 0.3% tier is 3000; the fee for a pool at the 0.01% tier is 100
    uint24 public poolFee = 3000;
    //滑点 1%
    uint256 public slipPageTolerance = 10000;
    
    //交易金额
    uint256 public tradeAmount;

    /// @notice Emitted when the trade is finished
    /// @param inAmount The amount of tokenIn for trade
    /// @param outAmount The amount of tokenOut we got
    /// @param price the current price that trigger off the trade
    /// @param tradetype true for buy, false for sell
    event TradeFinished(uint256 indexed inAmount, uint256 indexed outAmount, uint256 indexed price, bool tradetype);

    constructor(address _usd, address _token, address _swapRouter, address _oracleAddress){
       
        _setTradePair(_usd, _token, _swapRouter, _oracleAddress);
        _pause();
    }


    function _setTradePair(address _usd, address _token, address _swapRouter, address _oracleAddress) internal{
        usd = _usd;
        token = _token;
        swapRouter = ISwapRouter(_swapRouter);

        /**
        * Network: Sepolia
        * Aggregator: BTC/USD
        * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
        */
        priceFeed = AggregatorV3Interface(_oracleAddress);
        price_precision = getDecimals();

    }

    function setTradePair(address _usd, address _token, address _swapRouter, address _oracleAddress) external onlyOwner whenPaused{
         _setTradePair(_usd, _token, _swapRouter, _oracleAddress);
    }

    function initGrid( uint256 _levels, uint256 _Interval,uint256 _amount) external onlyOwner whenPaused{
        _initGrid(_levels,  _Interval, _amount);
        
    }


    //interval 精度8，amount 精度 6
    function _initGrid( uint256 _levels, uint256 _Interval,uint256 _amount) internal {
        require(_levels%2==0,"not right levels");
        require(_Interval>0,"not right interval ");
        
        //reinit the grid array
        _autoAdjustGridArray(_levels+1);
        _clearAllGrid();


        openTradePrice = getLatestPrice();
        currentLevelPrice = openTradePrice;

        gridInterval = _Interval;
        gridLevels = _levels;

        tradeAmount = _amount;

  
        //初始仓位的大小
        currentLevel = _levels/2;
        uint256 usdAmount = currentLevel*tradeAmount;

        //授权合约
        IERC20(usd).approve(address(swapRouter), MAX_INT);
        IERC20(token).approve(address(swapRouter), MAX_INT);
        
        //初始仓位
        uint256 initAmountOut = _swap(usdAmount, openTradePrice,true);
        for(uint256 i=1; i< currentLevel+1; i++){
            amountPerGrid[i] = initAmountOut/currentLevel;
        }

        _unpause();
    }

    function _swap(uint256 _amount,uint256 _price, bool _tradeType) internal returns(uint256 amountOut){
        if(_tradeType){//buy
             amountOut = _swap(_amount, usd,token);
          
        }else{//sell
        
            amountOut = _swap(_amount, token,usd);
            
        }
        emit TradeFinished(_amount, amountOut, _price , _tradeType);
    }

    function _swap(uint256 _usdAmount, address _tokenIn, address _tokenOut)internal returns(uint256 amountOut){

        //这里需要计算,未计算滑点
        uint256 outMinimum = 0;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp+60,
                amountIn: _usdAmount,
                amountOutMinimum: outMinimum,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

    }



    function checkPrice() public view returns(bool result){
        uint256 current_price = getLatestPrice();

        bool buyState =(current_price <= currentLevelPrice - gridInterval) && (currentLevel < gridLevels);
        bool sellState=(current_price >= currentLevelPrice + gridInterval) && (currentLevel !=0);

        result = buyState||sellState;
    }

    function buyTest() public onlyOwner{
        
        uint256 current_price = getLatestPrice();
         //交易 买
           uint256 amount =  _swap(tradeAmount,current_price, true);
        
            //更新状态
           amountPerGrid[currentLevel +1 ] = amount;
           currentLevel = currentLevel +1;
           currentLevelPrice = currentLevelPrice - gridInterval;

    }

    function sellTest() public onlyOwner{
         uint256 current_price = getLatestPrice();
        //售卖b token的数量,滑点需要考虑
            uint256 sellAmount = amountPerGrid[currentLevel];
            //卖
            _swap(sellAmount,current_price, false);
            
            //更新状态
            amountPerGrid[currentLevel] = 0;
            currentLevel = currentLevel -1;
            currentLevelPrice = currentLevelPrice + gridInterval;
    }

    function trading() public whenNotPaused{

        require(checkPrice(),"no need to trade!");
        uint256 current_price = getLatestPrice();

        if((current_price <= currentLevelPrice - gridInterval) && (currentLevel < gridLevels)){
            //交易 买
           uint256 amount =  _swap(tradeAmount,current_price, true);
        
            //更新状态
           amountPerGrid[currentLevel +1 ] = amount;
           currentLevel = currentLevel +1;
           currentLevelPrice = currentLevelPrice - gridInterval;
        }

        if((current_price >= currentLevelPrice + gridInterval) && (currentLevel !=0)){
            
            //售卖b token的数量,滑点需要考虑
            uint256 sellAmount = amountPerGrid[currentLevel];
            //卖
            _swap(sellAmount,current_price, false);
            
            //更新状态
            amountPerGrid[currentLevel] = 0;
            currentLevel = currentLevel -1;
            currentLevelPrice = currentLevelPrice + gridInterval;
           

        }

    }


     /**
     * Returns the latest price.
     */
    function getLatestPrice() public view returns (uint256) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int256 price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        if(price >0){
            return uint256(price);
        }else{
            return 0;
        }
        
    }

    function getDecimals() public view returns (uint8) {
       return priceFeed.decimals();   
    }


    //deposit
    function _deposit(
        address _token,
        uint256 _amount
    ) internal  {
        require(_token==usd||_token==token,"not the right token assets!");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        
    }

    function deposit(
        address _token,
        uint256 _amount
    ) external{
        _deposit(_token, _amount);
    }

    //withdraw
    function _withdraw(
        address _token,
        address _to,
        uint256 _amount
    )internal {
        require(IERC20(_token).balanceOf(address(this))>=_amount, "not engouth assets!");
        IERC20(_token).transfer(_to, _amount);
    }


    //withdraw
    function withdraw(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner{
        _withdraw(_token, _to, _amount);
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getAmountPerGrid(uint256 i) public view returns (uint256) {
        return amountPerGrid[i];
    }

    function getGridLength()public view returns (uint256) {
        return amountPerGrid.length;
    }

    function getGrids() public view returns (uint256[] memory) {
        return amountPerGrid;
    }

    //将仓位都卖掉
    function liquidation() public onlyOwner{

        uint256 current_price = getLatestPrice();
        uint256 tokenAmount  =  IERC20(token).balanceOf(address(this));

        if(tokenAmount > 0){
            _swap(tokenAmount, current_price,false);
        }

        _pause();
        
    }
   function _autoAdjustGridArray(uint256 _n) internal{
        uint256 length = amountPerGrid.length;
        uint256 i = 0;
        if(_n > length){
            for(i = length;i<_n;i++){
                amountPerGrid.push(0);
            }
        }else if(_n<length){
            for(i=_n;i<length;i++){
                amountPerGrid.pop();
            }
        }
    }

    function _clearAllGrid() internal{
        for(uint256 i=0; i<amountPerGrid.length;i++){
            amountPerGrid[i] = 0;
        }

    }

    function _calculateMinOutAmount(uint256 _inAmount, uint256 _price) internal view returns(uint256 minOutAmount){
        minOutAmount = _inAmount * price_precision*(SLIPPAGE_PRECISION - slipPageTolerance)/(_price*SLIPPAGE_PRECISION);
    }
}