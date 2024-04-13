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

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapV2Router02{
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TokenDistributor {
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

interface RwasTeam{
    function getTeamNumber(address _address) external view returns(uint256);
    function validTeamNumber(uint256 _teamNumber) external view returns(bool);
    function setTeamNumber(address _address,uint256 _teamNumber) external;
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

contract RwasMiningCoreV2 is Ownable {

    uint256 lockTimeMin = 0;//minimum lock time
    function setLockTimeMin(uint256 _lockTimeMin) public onlyOwner {
        lockTimeMin = _lockTimeMin;
    }

    address public RWAS = 0x1F2b426417663Ac76eB92149a037753a45969F31; // Arbitrum pro RWAS
    address public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9; // Arbitrum pro USDT
    IUniswapV2Factory private factoryV2 = IUniswapV2Factory(0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9); // Arbitrum pro Factory V2
    address public pair = factoryV2.getPair(RWAS, USDT);

    UniswapV2Router02 private routerV2 = UniswapV2Router02(0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24); // Arbitrum pro Router V2
    RwasTeam private rwasTeam = RwasTeam(0xd096aB69f8E7A5faa1c1cc5909C46605547b6aE4);// Arbitrum pro RwasTeam

    event Event_Buy(address indexed _user,uint256 _teamNumber,uint256 _amount,uint256 _time,uint256 _unlockTime,uint256 _orderId,uint256 _usdtAmount);
    event Event_Add(address indexed _user,uint256 _teamNumber,uint256 _amount,uint256 _time,uint256 _unlockTime,uint256 _orderId,uint256 _usdtAmount,uint256 _rwasAmount);
    event Event_Take(uint256 _orderId,uint256 _time,uint256 _type);
    event Event_TakeOrders(uint256[] _orderIds,uint256 _time,uint256 _type);

    struct OrderData {
        uint256 id;
        address account;
        address token;
        uint256 amount;
        uint256 time;
        bool redeemed;
        uint256 unlockTime;
    }
    uint256 private orderId = 1;
    mapping(address => uint256[]) public addressOrderIdsMap;
    mapping(uint256 => OrderData) public idOrderMap;
    TokenDistributor private rwasDistributor = new TokenDistributor(RWAS);

    constructor () {
        IERC20(RWAS).approve(address(routerV2), type(uint256).max);
        IERC20(USDT).approve(address(routerV2), type(uint256).max);
    }
    
    function buyRwas(uint256 _teamNumber,uint256 _usdtAmount,uint256 _lockTime) public returns(uint256){
        require(rwasTeam.validTeamNumber(_teamNumber), "Team Number is invalid");
        if(rwasTeam.getTeamNumber(msg.sender) == 0){
            rwasTeam.setTeamNumber(msg.sender,_teamNumber);
        }
        
        require(_lockTime >= lockTimeMin, "Less than the minimum lock time");
        IERC20(USDT).transferFrom(msg.sender, address(this),_usdtAmount);

        address[] memory path = new address[](2);
        path[0] = USDT;
        path[1] = RWAS;
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(_usdtAmount,0,path,address(rwasDistributor),block.timestamp+15);
        uint256 rwasAmount = IERC20(RWAS).balanceOf(address(rwasDistributor));
        IERC20(RWAS).transferFrom(address(rwasDistributor), address(this), rwasAmount);

        uint256 newId = makeOrder(RWAS,rwasAmount, block.timestamp + _lockTime);
        emit Event_Buy(msg.sender,rwasTeam.getTeamNumber(msg.sender),rwasAmount,block.timestamp,block.timestamp + _lockTime,newId,_usdtAmount);
        return rwasAmount;
    }

    function addLiquidity(uint256 _teamNumber,uint256 _rwasDesired,uint256 _amountDesired,uint256 _lockTime) external returns (uint rwasFinal, uint usdtFinal, uint liquidity){
        require(_lockTime >= lockTimeMin, "Less than the minimum lock time");
        require(rwasTeam.validTeamNumber(_teamNumber), "Team Number is invalid");
        if(rwasTeam.getTeamNumber(msg.sender) == 0){
            rwasTeam.setTeamNumber(msg.sender,_teamNumber);
        }
        (uint rwasExpected, uint usdtExpected) = _addLiquidity(RWAS,USDT,_rwasDesired,_amountDesired,0,0);
        IERC20(RWAS).transferFrom(msg.sender, address(this),rwasExpected);
        IERC20(USDT).transferFrom(msg.sender, address(this),usdtExpected);
        (rwasFinal, usdtFinal,liquidity) = routerV2.addLiquidity(RWAS,USDT,rwasExpected,usdtExpected,0,0,address(this),block.timestamp+15);

        if(rwasExpected > rwasFinal){
            IERC20(RWAS).transfer(msg.sender,(rwasExpected - rwasFinal));
        }
        if(usdtExpected > usdtFinal){
            IERC20(USDT).transfer(msg.sender,(usdtExpected - usdtFinal));
        }
        uint256 newId = makeOrder(pair,liquidity, block.timestamp + _lockTime);
        emit Event_Add(msg.sender,rwasTeam.getTeamNumber(msg.sender),liquidity, block.timestamp, block.timestamp + _lockTime,newId,usdtFinal,rwasFinal);
    }

    // Expected consumption for settlement
    function _addLiquidity(address tokenA,address tokenB,uint amountADesired,uint amountBDesired,uint amountAMin,uint amountBMin) internal view returns (uint amountA, uint amountB) {
        (uint reserveA, uint reserveB) = getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pair).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'RwasMiningCoreV2: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'RwasMiningCoreV2: ZERO_ADDRESS');
    }
    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'RwasMiningCoreV2: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'RwasMiningCoreV2: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    function makeOrder(address _token,uint256 _amount,uint256 _unlockTime) internal returns(uint256){
        uint256 tempId = orderId;
        OrderData memory order = OrderData({
            id:tempId,
            account:msg.sender,
            token:_token,
            amount:_amount,
            time:block.timestamp,
            unlockTime:_unlockTime,
            redeemed:false
        });
        idOrderMap[tempId] = order;
        addressOrderIdsMap[msg.sender].push(tempId);
        orderId++;
        return tempId;
    }

    function getOrders(address _address) public view returns(OrderData[] memory){
        uint256[] memory orderIds = addressOrderIdsMap[_address];
        OrderData[] memory orders = new OrderData[](orderIds.length);
        for (uint256 i=0; i < orderIds.length; i++) {
             uint256 _orderId = orderIds[i];
             orders[i] = idOrderMap[_orderId];
        }
        return orders;
    }

    function getLastOrder(address _address) public view returns(OrderData memory){
        uint256[] memory orderIds = addressOrderIdsMap[_address];
        require(orderIds.length > 0,"no orders");
        return idOrderMap[orderIds[orderIds.length-1]];
    }

    function take(uint256 _orderId) public{
        OrderData memory order = idOrderMap[_orderId];
        require(msg.sender == order.account, "Not the holder");
        require(order.unlockTime < block.timestamp, "Unlock time has not yet arrived");
        require(order.redeemed == false, "Redeemed");
        idOrderMap[_orderId].redeemed = true;
        IERC20(order.token).transfer(msg.sender,order.amount);
        emit Event_Take(_orderId,block.timestamp,1);
    }
    
    function sell(uint256 _orderId) public {
        OrderData memory order = idOrderMap[_orderId];
        require(msg.sender == order.account && order.unlockTime < block.timestamp && !order.redeemed && order.token == RWAS , "invalid");
        idOrderMap[_orderId].redeemed = true;
        
        address[] memory path = new address[](2);
        path[0] = RWAS;
        path[1] = USDT;
        routerV2.swapExactTokensForTokensSupportingFeeOnTransferTokens(order.amount,0,path,msg.sender,block.timestamp+15);
        
        emit Event_Take(_orderId,block.timestamp,2);
    }

    function removeLiquidity(uint256 _orderId) public returns (uint amountA, uint amountB) {
        OrderData memory order = idOrderMap[_orderId];
        require(msg.sender == order.account && order.unlockTime < block.timestamp && !order.redeemed && order.token == pair , "invalid");
        idOrderMap[_orderId].redeemed = true;

        (amountA, amountB) = routerV2.removeLiquidity(RWAS,USDT,order.amount,0,0,order.account,block.timestamp+15);
        emit Event_Take(_orderId,block.timestamp,2);
    }
}