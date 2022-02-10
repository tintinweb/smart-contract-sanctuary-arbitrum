pragma solidity ^0.8.0;
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "../external/interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "../external/interfaces/IUniswapV2Factory.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";

import { SOwnable } from "../utils/SOwnable.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract UniswapLpOracle is 
    SOwnable,
    IUniswapLpOracle 
{
    
    event LpOracleUpdated(
        uint256 indexed timestamp,
        address indexed oracleAddress,
        address indexed keeper, 
        int256 avgPrice,
        int256 instantPrice
    );

    using SignedBaseMath for int256;

    struct CalcParams{
        int256 strpReserve;
        int256 usdcReserve;

        int256 totalSupply;

        int256 usdcForLp;
        int256 strpForLp;
        int256 usdcForStrp;
    }

    struct AlphaParams{
        uint _r0;
        uint _r1;

        int supply;

        int K;
        int256 sqrtK;
    }


    bool public isActive;
    address public strp;
    address public sushiRouter;
    address public pair;

    uint public lastTimeStamp;

    uint public interval;
    int256 public periodsPassed;
    int256 public periods;
    int256 public avgPairPrice;
    int256 public accumulated;

    bool public instant;

    int256[24] prices;
    uint head;
    uint tail;

    modifier activeOnly() {
        require(isActive, "NOT_ACTIVE");
         _;
    }

    constructor(address _router,
                address _strp,
                address _pair,
                bool _instant,
                address _keeper){

        sushiRouter = _router;
        
        strp = _strp;
        pair = _pair;

        avgPairPrice = 0;
        lastTimeStamp = 0;

        instant = _instant;
        if (instant){
            periods = 1;
            interval = 0; //1 hour
        }else{
            periods = 24;
            interval = 3600; //1 hour
        }

        owner = msg.sender;
        listed[_keeper] = true;
    }

    function changeRouter(address _router) external ownerOrListed
    {
        sushiRouter = _router;
    }

    function changeStrp(address _strp) external ownerOrListed
    {
        strp = _strp;
    }

    function changePair(address _pair) external ownerOrListed
    {
        pair = _pair;
    }


    function changePeriods(int256 _newPeriods) external ownerOrListed
    {
        periods = _newPeriods;
    }

    function changeInterval(uint _newInterval) external ownerOrListed
    {
        interval = _newInterval;
    }

    function getPrice() external view override activeOnly returns (int256){
        return avgPairPrice;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        if (block.timestamp > lastTimeStamp + interval){
            upkeepNeeded = true;
        }else{
            upkeepNeeded = false;
        }
    }

    function performUpkeep(bytes calldata _data) external virtual override ownerOrListed {
        require(block.timestamp > lastTimeStamp + interval, "NO_NEED_UPDATE");
        lastTimeStamp = block.timestamp;

        if (instant){
            /*This mode is used for testnet only */
            accumulateInstantOracle();

            isActive = true;
        }else{
            accumulateOracle();

            periodsPassed += 1;

            /*Activate oralce once enough periods passed */
            if (isActive == false && periodsPassed >= periods){
                isActive = true;
            }
        }

        if (isActive){
                int256 instantPrice = instantLpPrice();

                emit LpOracleUpdated(
                    block.timestamp,
                    address(this),
                    msg.sender,
                    avgPairPrice,
                    instantPrice
                );
        }
    }

    /*Use this mode for testnet only */
    function accumulateInstantOracle() internal {
        avgPairPrice = instantLpPrice();
    }


    function accumulateOracle() internal {
        int256 lpPrice = instantLpPrice();

        if (isActive){
            avgPairPrice = accumulated / periods;

            accumulated -= prices[tail];
            
            tail += 1;
            if (tail > 23) {
                tail = 0;
            }
        }
        
        accumulated += lpPrice;
        prices[head] = lpPrice;
        head += 1;
        if (head > 23){
            head = 0;
        }
    }

    function instantLpPrice() public view returns (int256)
    {
        CalcParams memory params;

        (uint112 reserve0,
            uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();

        if (strp == IUniswapV2Pair(pair).token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }

        /*
            How much liquidity we need to burn? 
        */
        params.totalSupply = int256(IUniswapV2Pair(pair).totalSupply());
        params.usdcForLp = params.usdcReserve.divd(params.totalSupply);

        params.strpForLp = params.strpReserve.divd(params.totalSupply);
        params.usdcForStrp = int256(IUniswapV2Router02(sushiRouter).quote(uint(params.strpForLp), uint(params.strpReserve), uint(params.usdcReserve)));
        return params.usdcForLp + params.usdcForStrp;
    }


    /*
        For testing ONLY
     */
    function lpPriceWithoutSwap() public view returns (int256)
    {
        CalcParams memory params;

        (uint112 reserve0,
            uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();

        if (strp == IUniswapV2Pair(pair).token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }

        /*
            How much liquidity we need to burn? 
        */
        params.totalSupply = int256(IUniswapV2Pair(pair).totalSupply());
        params.usdcForLp = params.usdcReserve.divd(params.totalSupply);

        return params.usdcForLp;
    }


    function strpPrice() public view override returns (int256){
        CalcParams memory params;

        (uint112 reserve0,
            uint112 reserve1,) = IUniswapV2Pair(pair).getReserves();

        if (strp == IUniswapV2Pair(pair).token0()){
            params.strpReserve = int256(uint(reserve0));
            params.usdcReserve = int256(uint(reserve1));
        }else{
            params.strpReserve = int256(uint(reserve1));
            params.usdcReserve = int256(uint(reserve0));
        }

        int256 strpAmount = 1;

        return int256(IUniswapV2Router02(sushiRouter).quote(uint(strpAmount.toDecimal()), uint(params.strpReserve), uint(params.usdcReserve)));
    }

    function bothPrices() external view override returns (int256 _lpPrice, int256 _strpPrice){
        _lpPrice = avgPairPrice;
        _strpPrice = strpPrice();
    }
}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IUniswapLpOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function strpPrice() external view returns (int256);
    function bothPrices() external view returns (int256 lpPrice, int256 strpPrice);
}

pragma solidity >=0.8.0;

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

pragma solidity >=0.8.0;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity >=0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity ^0.8.0;

// We are using 0.8.0 with safemath inbuilt
// Need to implement mul and div operations only
// We have 18 for decimal part and  58 for integer part. 58+18 = 76 + 1 bit for sign
// so the maximum is 10**58.10**18 (should be enough :) )

library SignedBaseMath {
    uint8 constant DECIMALS = 18;
    int256 constant BASE = 10**18;
    int256 constant BASE_PERCENT = 10**16;

    function toDecimal(int256 x, uint8 decimals) internal pure returns (int256) {
        return x * int256(10**decimals);
    }

    function toDecimal(int256 x) internal pure returns (int256) {
        return x * BASE;
    }

    function oneDecimal() internal pure returns (int256) {
        return 1 * BASE;
    }

    function tenPercent() internal pure returns (int256) {
        return 10 * BASE_PERCENT;
    }

    function ninetyPercent() internal pure returns (int256) {
        return 90 * BASE_PERCENT;
    }

    function onpointOne() internal pure returns (int256) {
        return 110 * BASE_PERCENT;
    }


    function onePercent() internal pure returns (int256) {
        return 1 * BASE_PERCENT;
    }

    function muld(int256 x, int256 y) internal pure returns (int256) {
        return _muld(x, y, DECIMALS);
    }

    function divd(int256 x, int256 y) internal pure returns (int256) {
        if (y == 1){
            return x;
        }
        return _divd(x, y, DECIMALS);
    }

    function _muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    function _divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / y;
    }

    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }
}

abstract contract SOwnable
{
    address public owner;
    address public admin; // used for managing admin functions like add remove to list
    address public strips;
    address public proposed;

    mapping (address => bool) public listed;

    modifier onlyProposed(){
        require(msg.sender == proposed, "NOT_PROPOSED");
        _;
    }


    modifier onlyOwner(){
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier ownerOrAdmin(){
        require(msg.sender == owner || msg.sender == admin, "NOT_OWNER_NOR_ADMIN");
        _;
    }

    modifier ownerOrStrips(){
        require(msg.sender == owner || msg.sender == strips, "NOT_OWNER_NOR_STRIPS");
        _;
    }

    modifier onlyStrips(){
        require(msg.sender == strips, "NOT_STRIPS");
        _;
    }

    modifier ownerOrListed(){
        require(msg.sender == owner || listed[msg.sender] == true, "NOT_OWNER_NOR_LISTED");
        _;
    }

    function listAdd(address _new) public ownerOrAdmin {
        listed[_new] = true;
    }

    function listRemove(address _exist) public ownerOrAdmin {
        /*No check for existing */
        listed[_exist] = false;
    }

    function proposeOwner(address _new) public onlyOwner {
        require(_new != address(0), "ZERO_OWNER");
        require(_new != msg.sender, "ALREADY_AN_OWNER");

        proposed = _new;
    }

    function changeOwner() public onlyProposed {
        owner = proposed;

        /*Reset proposed */
        proposed = address(0);
    }

    function changeAdmin(address _new) public onlyOwner {
        admin = _new;
    }

    function changeStrips(address _new) public onlyOwner {
        strips = _new;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}