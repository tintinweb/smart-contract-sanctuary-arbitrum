/**
 *Submitted for verification at Arbiscan.io on 2024-04-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface BgtParent {
    function getLeader(address _user) external view returns (address);
    function getParent(address _user) external view returns (address);
    function isLeader(address _user) external view returns (bool);
}

interface ISwapRouter {
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
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface UniswapV2Router02{
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract RwasHomeV2 is Ownable {
    address public RWAS = 0x1F2b426417663Ac76eB92149a037753a45969F31; // Arbitrum PRO RWAS
    address private USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // Arbitrum PRO USDT
    address private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; // Arbitrum PRO WETH
    
    BgtParent public bgtParent = BgtParent(0xD1e1D9AD749056B9556FE1a9860CFB04F81a41BE); // Arbitrum PRO BgtParent
    ISwapRouter public routerV3 = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564); // Arbitrum PRO v3 pool Router
    
    IUniswapV2Factory private factoryV2 = IUniswapV2Factory(0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9); // Arbitrum PRO Factory V2
    UniswapV2Router02 public routerV2 = UniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24); // Arbitrum PRO Router V2
    TokenDistributor private  usdtDistributor = new TokenDistributor(USDT);
    TokenDistributor private rwasDistributor = new TokenDistributor(RWAS);
    IUniswapV2Pair public lpPair = IUniswapV2Pair(factoryV2.getPair(RWAS,USDT));

    event Recharge(address indexed _user,uint256 _type,uint256 _amount,uint256 _value,uint256 _rwas, uint256 _eth,uint256 time,uint256 rwasOrderId);
    event Event_Take(uint256 _orderId,uint256 _time);
    
    constructor () {
        IERC20(USDT).approve(address(routerV2), type(uint256).max);
        IERC20(RWAS).approve(address(routerV2), type(uint256).max);
        IERC20(USDT).approve(address(routerV3), type(uint256).max);
    }

    struct OrderData {
        uint256 id;
        address account;
        uint256 amount;
        bool redeemed;
    }
    uint256 public orderId = 1;
    mapping(uint256 => OrderData) public idOrderMap;

    function checkAccount(address _user) public view returns (bool) {
        bool isl = bgtParent.isLeader(_user);
        address leader = bgtParent.getLeader(_user);
        address parent = bgtParent.getParent(_user);
        if(isl || leader == address(0) || parent == address(0)){
            return false;
        }
        return true;
    }

    function join(uint256 _type,uint256 _amount,uint256 _rate) public {
        require(_amount > 0 && _rate >=0 && _rate <= 100, "invalid amount");
        address leader = bgtParent.getLeader(msg.sender);
        require(leader != address(0) && msg.sender != leader, "invalid account");

        uint256 rwasAmt = 0;
        uint256 rwasOrderId = 0;
        uint256 value = 0;
        uint256 wethAmt = 0;
        if(_type == 1){
            IERC20(USDT).transferFrom(address(msg.sender),address(this),_amount);
            if(_rate > 0){
                uint256 forToken = _amount * _rate / 100;
                rwasAmt = usdtToRwas(forToken);
                rwasOrderId = makeOrder(rwasAmt);
            }
            if(_rate < 100){
                uint256 forWeth = _amount * (100-_rate) / 100;
                usdtToWeth(forWeth);
                wethAmt = IERC20(WETH).balanceOf(address(this));
                IERC20(WETH).transfer(leader,wethAmt);
            }
            value = _amount;
        }else{
            IERC20(RWAS).transferFrom(address(msg.sender),address(this),_amount);
            if(_rate > 0){
                rwasAmt = _amount * _rate / 100;
                rwasOrderId = makeOrder(rwasAmt);
            }
            if(_rate < 100){
                uint256 forUsdt = _amount * (100-_rate) / 100;
                uint256 usdtAmount = rwasToUsdt(forUsdt);
                usdtToWeth(usdtAmount);
                wethAmt = IERC20(WETH).balanceOf(address(this));
                IERC20(WETH).transfer(leader,wethAmt);
                value = usdtAmount * 100 / (100-_rate);
            }
            if(value == 0){
                value = getRwasPrice() * _amount / 10 ** 18;
            }
        }
        emit Recharge(msg.sender,_type, _amount, value,rwasAmt, wethAmt, block.timestamp,rwasOrderId);
    }

    function usdtToWeth(uint256 _usdtAmount) internal {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: USDT,
            tokenOut: WETH,
            fee: 3000,
            recipient: address(this),
            deadline: block.timestamp + 15,
            amountIn: _usdtAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        routerV3.exactInputSingle(params);
    }

    function rwasToUsdt(uint256 _rwasAmount) internal returns(uint256){
        address[] memory path = new address[](2);
        path[0] = RWAS;
        path[1] = USDT;
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(_rwasAmount,0,path,address(usdtDistributor),block.timestamp+15);
        uint256 usdtAmount = IERC20(USDT).balanceOf(address(usdtDistributor));
        IERC20(USDT).transferFrom(address(usdtDistributor), address(this), usdtAmount);
        return usdtAmount;
    }

    function usdtToRwas(uint256 _usdtAmount) internal returns(uint256){
        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = RWAS;
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(_usdtAmount,0,path,address(rwasDistributor),block.timestamp+15);
        uint256 rwasAmount = IERC20(RWAS).balanceOf(address(rwasDistributor));
        IERC20(RWAS).transferFrom(address(rwasDistributor), address(this), rwasAmount);
        return rwasAmount;
    }

    function getRwasPrice() public view returns(uint256){
        (uint256 reserve0, uint256 reserve1,) = lpPair.getReserves();
        return  reserve1 * 10 ** 18/reserve0;
    }

    function makeOrder(uint256 _amount) internal returns(uint256){
        uint256 tempId = orderId;
        OrderData memory order = OrderData({
            id:tempId,
            account:msg.sender,
            amount:_amount,
            redeemed:false
        });
        idOrderMap[tempId] = order;
        orderId++;
        return tempId;
    }

    function takeOrder(uint256 _orderId) public {
        OrderData memory order = idOrderMap[_orderId];
        require(msg.sender == order.account && !order.redeemed,"invalid");
        idOrderMap[_orderId].redeemed = true;
        IERC20(RWAS).transfer(order.account,order.amount);
        emit Event_Take(_orderId,block.timestamp);
    }
}