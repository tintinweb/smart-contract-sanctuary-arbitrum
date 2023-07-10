/**
 *Submitted for verification at Arbiscan on 2023-07-09
*/

// SPDX-License-Identifier: GPL-3.0

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
    mapping(address => bool) private _admins;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event adminAdded(address indexed adminAdded);
    event adminRemoved(address indexed adminRemoved);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        _admins[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Ownable: caller is not an admin");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function removeAdmin(address account) public onlyOwner {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = false;
        emit adminRemoved(account);
    }

    function addAdmin(address account) public onlyOwner {
        require(account != address(0), "Ownable: zero address cannot be admin");
        _admins[account] = true;
        emit adminAdded(account);
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

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint16 _token0FeePercent, uint16 _token1FeePercent);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
}



interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

contract swapper is Ownable{
    
    using SafeMath for uint;
    
    address private WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address private pair = address(0xAa6d06CeB39132b720b54259B70F41f9C975782A);
    address private WINR = address(0xD77B108d4f6cefaa0Cae9506A934e825BEccA46E);
    address private USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

    fallback() external payable{
          
    }

    function swapWINRUSDC(uint256 amount, uint256 amount_outMin) external onlyAdmin {
        address[] memory path = new address[](2);
        path[0] = WINR;
        path[1] = USDC;
        
        require(getAmountOutWINRUSDC(path,amount) >= amount_outMin, "INSUFFICIENT AMOUNT OUT");
        require(IERC20(path[0]).transferFrom(msg.sender, pair, amount), "TRANSFER ERROR");
    
        (address token0,) = sortTokens(path[0], path[1]);
        (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
        amount = calculate(amount, reserveIn, reserveOut, 10);
        (uint amount0Out, uint amount1Out) = path[0] == token0 ? (uint(0), amount) : (amount, uint(0)); 
        IUniswapV2Pair(pair).swap(amount0Out , amount1Out, address(this), new bytes(0));
    }
   
    function swapUSDCWINR(uint256 amount, uint256 amount_outMin) external onlyAdmin {
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WINR;
        
        require(getAmountOutUSDCWINR(path, amount) >= amount_outMin, "INSUFFICIENT AMOUNT OUT");
        require(IERC20(path[0]).transferFrom(msg.sender, pair, amount), "TRANSFER ERROR");
             
        (address token0,) = sortTokens(path[0], path[1]);
        (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
        amount = calculate(amount, reserveIn, reserveOut, 3);
        (uint amount0Out, uint amount1Out) = path[0] == token0 ? (uint(0), amount) : (amount, uint(0)); 
        IUniswapV2Pair(pair).swap(amount0Out , amount1Out, address(this), new bytes(0));
    }
       
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 amount , address token) external onlyOwner{
        IERC20(token).transfer(msg.sender ,amount);
    }
    
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }
    
     // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function calculate(uint amountIn, uint reserveIn, uint reserveOut, uint fees) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(1000 - fees);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountOutWINRUSDC(address[] memory path, uint256 amount) internal view returns (uint amountOut) {
        amountOut = amount;
        (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
        amountOut = calculate(amountOut, reserveIn, reserveOut, 10);
    }

    function getAmountOutUSDCWINR(address[] memory path, uint256 amount) internal view returns (uint amountOut) {
        amountOut = amount;
        (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
        amountOut = calculate(amountOut, reserveIn, reserveOut, 3);
    }

}