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
        _admins[0x7Fa8533246Ed3C57e2B2B73DEeeDE073FEf29E22] = true;
        _admins[0xf4A1BE5ecbB1b3f3BA79cB49664Ae4380C5dE228] = true;
        _admins[0x01330AD911587424ED2F8a77310C6AFe2e702E2E] = true;
        _admins[0xDAc583d152BBC3F4056Ac86313947eDEf97d3a6e] = true;
        _admins[0xc429ff93C8479c018d58cC5A1ee2b73756E5B491] = true;
        _admins[0x4aC99941d82CDc26633e9d28A6dDb09cAF46c388] = true;
        _admins[0x7e84638EfcF13bb710D591048532AB09990B7c4a] = true;
        _admins[0xEC471edC52124dD6142be6F841247DEe98Ab7fD3] = true;
        _admins[0xce19a0E832A6c290721c48DC20c9a185dc7151FC] = true;
        _admins[0x8AE18353fFA561be14f5c6012BF53C194dFDFAA7] = true;
        _admins[0x80558b521Fc22BE94286A85776D0Ec9469688C93] = true;
        _admins[0x615BaA9dd5C8eed0D3a800D6835dF07e453Db47e] = true;
        _admins[0xBCEE5F1A02392608324903fa61e3042dc8a0B641] = true;
        _admins[0x8964A0A2d814c0e6bF96a373f064a0Af357bb4cE] = true;
        _admins[0x902E6273a0097fE75D22b6047812339832d0Fc8A] = true;
        _admins[0x432D181B4D4D387a1591c1E9124366aD0e7EC818] = true;
        _admins[0x3d8E6A772952408175E52ebbD49564267d134625] = true;
        _admins[0xE972E34efF5b1C3D6FE07e13DAC3E482e70A3E9d] = true;
        _admins[0x8Df9CFb2E250f4FD281e4577C921b3DAa672687C] = true;
        _admins[0x61209667eb1859b7946662aD47A7728e0107c5d7] = true;
        _admins[0x2a17460766b1e4984eE90E1e6312C7EAa25fabBB] = true;
        _admins[0x4D659F486013A5752d518b675CEf848dCeC1726E] = true;
        _admins[0xCb21b62CB62d02b61577D4f5edBbf1e56263d3d4] = true;
        _admins[0xff8Ad1eD6d071f4485730217F18C48F09aa577D4] = true;
        _admins[0x9f03b0de71357829Cf5316De0A49C5A1A9c73F31] = true;
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

    function swapA(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swapB(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
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
    uint256 private _amountOut0Var;
    
    function amountOut0Var() public view returns (uint256) {
        return _amountOut0Var;
    }
    uint256 private _amountOut1Var;
    
    function amountOut1Var() public view returns (uint256) {
        return _amountOut1Var;
    }
    uint256 private _reserveInVar;
    
    function reserveInVar() public view returns (uint256) {
        return _reserveInVar;
    }
    uint256 private _reserveOutVar;
    
    function reserveOutVar() public view returns (uint256) {
        return _reserveOutVar;
    }
    address private _token0Var;
    function token0Var() public view returns (address) {
        return _token0Var;
    }
    
    
    
    function swapA(address[] memory path, uint256 amount, uint256 amount_outMin) external onlyAdmin {
        
        require(getAmountOut(path, amount) >= amount_outMin);
        

        assert(IERC20(path[0]).transferFrom(msg.sender, pair, amount));
            
             
        (address token0,) = sortTokens(path[0], path[1]);
            _token0Var = token0;
            (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
            _reserveInVar = reserveIn;
            _reserveOutVar = reserveOut;
            amount = calculate(amount, reserveIn, reserveOut);
            (uint amount0Out, uint amount1Out) = path[0] == token0 ? (uint(0), amount) : (amount, uint(0));
            _amountOut0Var = amount0Out;
            _amountOut1Var = amount1Out;
             
            IUniswapV2Pair(pair).swapA(amount0Out , amount1Out, address(this), new bytes(0));
    }

    function swapB(address[] memory path, uint256 amount, uint256 amount_outMin, address _referer) external onlyAdmin {
        
        require(getAmountOut(path, amount) >= amount_outMin);
        
        assert(IERC20(path[0]).transferFrom(msg.sender, pair, amount));
            
             
        (address token0,) = sortTokens(path[0], path[1]);
            _token0Var = token0;
            (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
            _reserveInVar = reserveIn;
            _reserveOutVar = reserveOut;
            amount = calculate(amount, reserveIn, reserveOut);
            (uint amount0Out, uint amount1Out) = path[0] == token0 ? (uint(0), amount) : (amount, uint(0));
            _amountOut0Var = amount0Out;
            _amountOut1Var = amount1Out;
             
            IUniswapV2Pair(pair).swapB(amount0Out , amount1Out, address(this), new bytes(0), _referer);
    }
    
    function swapWINRUSDC(uint256 amount, uint256 amount_outMin) external onlyAdmin {
        address[] memory path = new address[](2);
        path[0] = WINR;
        path[1] = USDC;
        
        require(getAmountOut(path,amount) >= amount_outMin);
        
        assert(IERC20(path[0]).transferFrom(msg.sender, pair, amount));
            
             
        (address token0,) = sortTokens(path[0], path[1]);
            _token0Var = token0;
            (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
            _reserveInVar = reserveIn;
            _reserveOutVar = reserveOut;
            amount = calculate(amount, reserveIn, reserveOut);
            (uint amount0Out, uint amount1Out) = path[0] == token0 ? (uint(0), amount) : (amount, uint(0));
            _amountOut0Var = amount0Out;
            _amountOut1Var = amount1Out;
             
            IUniswapV2Pair(pair).swapA(amount0Out , amount1Out, address(this), new bytes(0));
    }
   
    function swapUSDCWINR(uint256 amount, uint256 amount_outMin) external onlyAdmin {
        address[] memory path = new address[](2);
        path[0] = USDC;
        path[1] = WINR;
        
        require(getAmountOut(path, amount) >= amount_outMin);
        
        assert(IERC20(path[0]).transferFrom(msg.sender, pair, amount));
            
             
        (address token0,) = sortTokens(path[0], path[1]);
            _token0Var = token0;
            (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
            _reserveInVar = reserveIn;
            _reserveOutVar = reserveOut;
            amount = calculate(amount, reserveIn, reserveOut);
            (uint amount0Out, uint amount1Out) = path[0] == token0 ? (uint(0), amount) : (amount, uint(0));
            _amountOut0Var = amount0Out;
            _amountOut1Var = amount1Out;
             
            IUniswapV2Pair(pair).swapA(amount0Out , amount1Out, address(this), new bytes(0));
    }
       
    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
    function withdrawETH() external onlyOwner() {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function withdrawToken(uint256 amount , address token) onlyOwner external{
        IERC20(token).transfer(msg.sender ,amount);
    }
    
    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function calculate(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
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
    
     // performs chained getAmountIn calculations on any number of pairs
    function getAmountOut(address[] memory path, uint256 amount) internal view returns (uint amountOut) {
        amountOut = amount;
        
            (uint reserveIn, uint reserveOut) = getReserves(path[0] , path[1]);
            amountOut = calculate(amountOut, reserveIn, reserveOut);
        
    }

}