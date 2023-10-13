pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import './SafeMath.sol';
import './Math.sol';
import './UQ112x112.sol';
import './IERC20.sol';
import './Ownable.sol';
import  './Address.sol';
import './ILftDaoVerifySignature.sol';
import './ILftSwapCheck.sol';


contract LftSwap is Ownable{
    using SafeMath  for uint;
    using UQ112x112 for uint224;
    using Address for address;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
 
    address public token0;

    address public token1;

    uint public  swapFee;

    address public verify;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;

    address public feeReceiveAddress;

    address private checkAddress;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'LFTV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'LFTV2: EXPIRED');
        _;
    }

    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        uint fee,
        address indexed to
    );
    
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor (address _token0, address _token1,uint256 _swapFee,address _verify,address _checkAddress)  {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
        swapFee = _swapFee;
        verify = _verify;
        feeReceiveAddress = 0x09c79D485e6A3c6b17A71BC4D1413581a5177Ef1;
        checkAddress = _checkAddress;
    }

    function setC(address _address) external onlyOwner{
        require(ILftSwapCheck(checkAddress).UpdateCheckAddress(),"error");
        checkAddress = _address;
    }

    function setVerify(address _verify) external onlyOwner{
          verify = _verify;
    }

    function setSwapFee(uint _swapFee) external onlyOwner{
        swapFee = _swapFee;
    }

    function setFeeAddress(address _feeAddress) external onlyOwner{
         feeReceiveAddress = _feeAddress;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1) external  onlyOwner {
        require(msg.sender == factory, 'LFTV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }


   function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'LFTswapV2: TRANSFER_FAILED');
    }
  

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'LFTswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) public  view returns (uint amountIn) {
        require(amountOut > 0, 'LFTswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'LFTswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(uint(997).sub(swapFee));
        amountIn = (numerator / denominator).add(1);
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public  view returns (uint amountOut) {
        require(amountIn > 0, 'LFTswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'LFTswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint realAmountIn = amountIn.mul(uint(1000).sub(swapFee).sub(3));
        uint amountInWithFee = realAmountIn;
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getFloatAmountIn(uint amountOut, uint reserveIn, uint reserveOut,uint floatRate) public  view returns (uint amountIn) {
        require(amountOut > 0, 'LFTswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'LFTswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(uint(1000).sub(floatRate.add(swapFee)));
        amountIn = (numerator / denominator).add(1);
    }

    function getFloatAmountOut(uint amountIn, uint reserveIn, uint reserveOut,uint floatRate) public  view returns (uint amountOut) {
        require(amountIn > 0, 'LFTswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'LFTswapV2Library: INSUFFICIENT_LIQUIDITY');
         uint realAmountIn = amountIn.mul(uint(1000).sub(swapFee).sub(floatRate));
        uint amountInWithFee = realAmountIn;
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'LFTswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'LFTswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    function _addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB,) = getReserves();
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'LFTswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'LFTswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        uint deadline
    ) external  ensure(deadline) returns (uint amountA, uint amountB) {
        require(ILftSwapCheck(checkAddress).checkPermissions(msg.sender),"not allow");
        (amountA, amountB) = _addLiquidity(amountADesired, amountBDesired, amountAMin, amountBMin);
        IERC20(token0).transferFrom(msg.sender, address(this), amountA);
        IERC20(token1).transferFrom(msg.sender, address(this), amountB);
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
         uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);   
    }

    function removeLiquidity(
        uint amount0,
        uint amount1,
        uint deadline
    ) external  ensure(deadline) {
        require(ILftSwapCheck(checkAddress).checkPermissions(msg.sender),"not allow");
        require(ILftSwapCheck(checkAddress).checkRemove(),"error");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));
        require(balance0 >= amount0, 'LFTswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(balance1 >= amount1, 'LFTswapV2Router: INSUFFICIENT_B_AMOUNT');
        require(amount0 > 0 && amount1 > 0, 'LFTswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _safeTransfer(_token0, msg.sender, amount0);
        _safeTransfer(_token1, msg.sender, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
    }

   function swapBuy(bytes memory data) external lock  returns (uint amounts) {
        (address user, uint256 amountIn,uint256 amountOutMin,uint256 swapType) = ILftDaoVerifySignature(verify).verifySwap(data);
        require(swapType==1,"type error");
        require(user==msg.sender,"user error");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        amounts = getAmountOut(amountIn,_reserve1,_reserve0);
        require(amounts >= amountOutMin, 'LFTswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
        uint fee = amountIn.mul(swapFee).div(1000);
        IERC20(token1).transferFrom(msg.sender,address(this),amountIn.sub(fee));
        IERC20(token1).transferFrom(msg.sender,feeReceiveAddress,fee);
        swap(amounts,msg.sender,1,fee);
    }
    function swapSell (bytes memory data) external lock returns (uint  amounts) {
        (address user, uint256 amountIn,uint256 amountOutMin,uint256 swapType) = ILftDaoVerifySignature(verify).verifySwap(data);
        require(swapType==2,"type error");
        require(user==msg.sender,"user error");
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        amounts = getAmountOut(amountIn,_reserve0,_reserve1);
        require(amounts >= amountOutMin, 'LFTswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');
         uint fee = amountIn.mul(swapFee).div(1000);
        IERC20(token0).transferFrom(msg.sender, address(this),amountIn.sub(fee));
        IERC20(token0).transferFrom(msg.sender,feeReceiveAddress,fee);
        swap(amounts,msg.sender,2,fee);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint256 amount, address to,uint _swapType,uint fee) internal  {
         (uint amount0Out, uint amount1Out) = _swapType == 2 ? (uint(0), amount) : (amount, uint(0));
        require(amount0Out > 0 || amount1Out > 0, 'LFTswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'LFTswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'LFTswapV2: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'LFTswapV2: INSUFFICIENT_INPUT_AMOUNT');
        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(uint(3)));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(uint(3)));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'LFTswapV2: K');
        }
        _update(balance0, balance1, _reserve0, _reserve1);
    
        emit Swap(msg.sender,amount0In,amount1In,amount0Out,amount1Out,fee,to);
    }

    // force balances to match reserves
    function skim(address to) external onlyOwner lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}