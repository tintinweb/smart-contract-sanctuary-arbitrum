/**
 *Submitted for verification at Arbiscan on 2023-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
 
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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IRouter {
    function factory() external pure returns (address);
    function WTRX() external pure returns (address);

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
    function addLiquidityTRX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountTRX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityTRX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountTRX);
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
    function removeLiquidityTRXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountTRXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountTRX);
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
    function swapExactTRXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactTRX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForTRX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapTRXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

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


interface IAVAX20 {
    function totalSupply() external view returns (uint256);
    function deposit(uint256 amount) external payable;
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender)
    external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWAVAX {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address who) external view returns (uint256);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}


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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract arb is Ownable{
    
    using SafeMath for uint;
    
    
    address private WAVAX =  address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address constant REDACTED = 0xcCA536eB0BD0d80474C4e9b144CA5758aF464f8E;

    fallback() external payable{
          
    }
    uint256 private _balanceWAVAX;
    function balanceWAVAX() public view returns (uint256) {
        return _balanceWAVAX;
    }
    
    
    function simpleSwap(address[] memory path , address pair, uint256 amount, uint256 amount_outMin) external onlyOwner() {

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 reserveIn = path[0] == IUniswapV2Pair(pair).token0() ? reserve0 : reserve1;
        uint256 reserveOut = path[1] == IUniswapV2Pair(pair).token1() ? reserve1 : reserve0;
            
        uint256 amountOut = calculate(amount, reserveIn, reserveOut);
        (uint256 amount0Out, uint256 amount1Out) = path[0] == IUniswapV2Pair(pair).token0() ? (uint(0), amountOut) : (amountOut, uint(0));
            
        require(amountOut >= amount_outMin);
        IAVAX20(path[0]).transferFrom(msg.sender, address(this), amount);
        assert(IWAVAX(path[0]).transfer(pair, amount));
        IUniswapV2Pair(pair).swap(amount0Out , amount1Out, msg.sender, new bytes(0));

    }

    function doubleSwap(address[] memory path, address pairA, address pairB, uint256 amount, uint256 amount_outMin) external onlyOwner() {

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pairA).getReserves();
        uint256 reserveIn = path[0] == IUniswapV2Pair(pairA).token0() ? reserve0 : reserve1;
        uint256 reserveOut = path[1] == IUniswapV2Pair(pairA).token1() ? reserve1 : reserve0;
            
        uint256 amountOut = calculate(amount, reserveIn, reserveOut);
        (uint256 amount0Out, uint256 amount1Out) = path[0] == IUniswapV2Pair(pairA).token0() ? (uint(0), amountOut) : (amountOut, uint(0));
        
        IWAVAX(path[0]).mint(address(this), amount);
    
        assert(IWAVAX(path[0]).transfer(pairA, amount));
        IUniswapV2Pair(pairA).swap(amount0Out , amount1Out, address(this), new bytes(0));
        
        uint256 amountReceived = IAVAX20(path[1]).balanceOf(address(this));
        
        (reserve0, reserve1,) = IUniswapV2Pair(pairB).getReserves();
        reserveIn = path[1] == IUniswapV2Pair(pairB).token0() ? reserve0 : reserve1;
        reserveOut = path[2] == IUniswapV2Pair(pairB).token1() ? reserve1 : reserve0;
        

        amountOut = calculate(amountReceived, reserveIn, reserveOut);
        (amount0Out, amount1Out) = path[1] == IUniswapV2Pair(pairB).token0() ? (uint(0), amountOut) : (amountOut, uint(0));
            
        require(amountOut >= amount_outMin);
        assert(IWAVAX(path[1]).transfer(pairB, amountReceived));
        IUniswapV2Pair(pairB).swap(amount0Out , amount1Out, msg.sender, new bytes(0));

    }

    function simpleSwapReflect(address[] memory path , address pair, uint256 amount, uint256 amount_outMin, uint256 reflect) external onlyOwner() {

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 reserveIn = path[0] == IUniswapV2Pair(pair).token0() ? reserve0 : reserve1;
        uint256 reserveOut = path[1] == IUniswapV2Pair(pair).token1() ? reserve1 : reserve0;
            
        uint256 amountOut = calculate(amount, reserveIn, reserveOut);
        (uint256 amount0Out, uint256 amount1Out) = path[0] == IUniswapV2Pair(pair).token0() ? (uint(0), amountOut.mul(reflect).div(100)) : (amountOut.mul(reflect).div(100), uint(0));
            
        require(amountOut >= amount_outMin);
        IAVAX20(path[0]).transferFrom(msg.sender, address(this), amount);
        assert(IWAVAX(path[0]).transfer(pair, amount));
        IUniswapV2Pair(pair).swap(amount0Out , amount1Out, msg.sender, new bytes(0));

    }

    function simpleSwapCalculateReflect(address[] memory path , address pair, uint256 amount, uint256 amount_outMin, uint256 reflect) external onlyOwner() {

        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(pair).getReserves();
        uint256 reserveIn = path[0] == IUniswapV2Pair(pair).token0() ? reserve0 : reserve1;
        uint256 reserveOut = path[1] == IUniswapV2Pair(pair).token1() ? reserve1 : reserve0;
            
        uint256 amountOut = calculateReflect(amount, reserveIn, reserveOut, reflect);
        (uint256 amount0Out, uint256 amount1Out) = path[0] == IUniswapV2Pair(pair).token0() ? (uint(0), amountOut) : (amountOut, uint(0));
            
        require(amountOut >= amount_outMin);
        IAVAX20(path[0]).transferFrom(msg.sender, address(this), amount);
        assert(IWAVAX(path[0]).transfer(pair, amount));
        IUniswapV2Pair(pair).swap(amount0Out , amount1Out, msg.sender, new bytes(0));

    }

    function burn(uint256 amount) external onlyOwner(){
        IWAVAX(REDACTED).burn(msg.sender, amount);
    }
       
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function withdrawAVAX() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 amount, address token) external onlyOwner{
         IAVAX20(token).transfer(msg.sender, amount);
    }

    function wrapAVAX(uint256 amount) external onlyOwner{
        IAVAX20(WAVAX).deposit(amount);
    }

    function getBalanceOfToken(address _address) public view returns (uint256) {
        return IAVAX20(_address).balanceOf(address(this));
    }

    //function updateBalanceOfWAVAX() public view returns (uint256) {
        //return IAVAX20(_address).balanceOf(address(this));
    //}
    
    
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function calculate(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function calculateReflect(uint amountIn, uint reserveIn, uint reserveOut, uint reflect) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(reflect);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    
     // performs chained getAmountIn calculations on any number of pairs
    function getAmountOut(address[] memory path , address pair,  uint256 amount) internal view returns (uint amountOut) {
        
        
    }

}