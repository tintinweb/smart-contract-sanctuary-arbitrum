/**
 *Submitted for verification at Arbiscan on 2023-07-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

interface IERC20 {
    
    function decimals() external view returns (uint256);
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function mint(address user,uint256 amount) external returns(bool);

    function transferMinter(address newMinter) external;
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
 
}

interface IRouter{
    function factory() external pure returns (address);
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address refer,
        uint deadline
    ) external;
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


contract owned {
    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface IRefer {
    function user_referrer(address user) external view returns (address);
    function rootAddr() external view returns(address);
}

interface IUniswapV2Pair {

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
    external
    view
    returns (
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    );

}

contract YDJMode is owned {
    using SafeMath for uint256;
    IRefer public refer = IRefer(address(0xcA62f991b21659598dD0eA70D133d7bAe037920B));
    address public token = address(0x9571597344BADBc681cA44B826b73f6eEB859a37);
    address public usdt = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
    address public pair = address(0);
    address public deadAddr = address(0xdead);
    address public router = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    uint256 public maxUAmount = 2000 * 10**6;
    uint256 public minUAmount = 100 * 10**6;
    uint256 public holdUAmount = 300 * 10**6;
    uint256 public RewardDays = 5;
    uint256 public oneDay = 86400;
    uint256 public period = 30;
    uint256 public startTime = 1690873200 ;
    uint256[] public rates = [20,20,10,5,5,5,5];
    struct Order {
        uint256 amount;
        uint256 debtAmount;
    }

    struct UserInfo {
        mapping(uint256 => Order) orders;
        uint256 startDay;
        uint256 lastUpdateDay;
        uint256 endDay;
        mapping(uint256 =>mapping( uint256 => uint256) ) refAmounts;
        uint256 totalAmount;
        uint256 totalAmountDebt;
    }

    mapping(address => bool) public isUserAddrs;
    address[] public userAddrs;
    mapping(address => UserInfo) public userInfo;

    constructor() {
        pair = IPancakeFactory(IRouter(router).factory()).getPair(usdt,token);
        IERC20(usdt).approve(router,~uint256(0));
        IERC20(token).approve(router,~uint256(0));
    }

    function stake(uint256 amountU,uint256 amountT) external returns(bool){ 
        require(block.timestamp >= startTime);
        uint256 poolU = 0;
        uint256 poolT = 0;
        {
            address token0 = IUniswapV2Pair(address(pair)).token0();
            (uint256 r0,uint256 r1,) = IUniswapV2Pair(address(pair)).getReserves();
            
            if(token0 == usdt){ 
                poolU = r0;
                poolT = r1;
            }else{
                poolU = r1; 
                poolT = r0;
            }
            require(poolU > 0 && poolT > 0);
            uint256 amountTU = poolU.mul(amountT).div(poolT);
            if(amountTU>amountU){
                require(amountU.mul(105).div(100) >= amountTU);
                require(amountU >= minUAmount);
                amountT = poolT.mul(amountU).div(poolU);   
            }else{
                require(amountTU.mul(105).div(100) >= amountU);
                require(amountTU >= minUAmount);
                amountU =amountTU;
            }
        }
        
        UserInfo storage user = userInfo[msg.sender];
        uint256 nowDay = block.timestamp.div(oneDay);
        uint256 amount = amountU.mul(2);
        require(user.orders[nowDay].amount.add(amount) <= maxUAmount.mul(2) && msg.sender == tx.origin);
        _getRewardBy(msg.sender);
        TransferHelper.safeTransferFrom(usdt,msg.sender,address(this),amountU);
        TransferHelper.safeTransferFrom(token,msg.sender,address(this),amountT);
        TransferHelper.safeTransfer(token,deadAddr,amountT.mul(80).div(100));
        {
            address[] memory path = new address[](2);
            path[0] = usdt;
            path[1] = token;
            IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountU.mul(40).div(100),0,path,address(this),address(0),block.timestamp
            );
        }
        IRouter(router).addLiquidity(token,usdt,IERC20(token).balanceOf(address(this)),IERC20(usdt).balanceOf(address(this)),0,0,deadAddr,block.timestamp);
        TransferHelper.safeTransfer(token,deadAddr,IERC20(token).balanceOf(address(this)));
        if(!isUserAddrs[msg.sender]){
            isUserAddrs[msg.sender] = true;
            userAddrs.push(msg.sender);
            user.startDay = nowDay;
            user.lastUpdateDay =  user.startDay;
            user.totalAmount = 0;
            user.totalAmountDebt = 0;
        }
        user.endDay = nowDay;
        user.orders[nowDay].amount = user.orders[nowDay].amount.add(amount);
        user.totalAmount = user.totalAmount.add(amount);
        address up = refer.user_referrer(msg.sender);
        address root = refer.rootAddr();
        uint256 level = 0; 
        if(up != address(0)){

            while(up != root && level < 7){
                UserInfo storage upUser = userInfo[up];
                upUser.refAmounts[nowDay][level] = upUser.refAmounts[nowDay][level].add(amount);
                up = refer.user_referrer(up);
                level++;
            }

        }
       
        return true;
    }

    function getReward() public returns (bool){
        require(msg.sender == tx.origin);
        return _getRewardBy(msg.sender);
    }


    function _getRewardBy(address _user) internal returns (bool){
        uint256 nowDay = block.timestamp.div(oneDay);
        UserInfo storage user = userInfo[_user];
        uint256 endDay = nowDay;
        if(endDay > user.endDay.add(period))
            endDay = user.endDay.add(period);
        if(user.lastUpdateDay.add(RewardDays) < endDay)
            user.lastUpdateDay = endDay.sub(RewardDays);
        uint256 amountR = earnedReward(_user);
        if(amountR > 0 && endDay > user.lastUpdateDay){
            address token0 = IUniswapV2Pair(address(pair)).token0();
            (uint256 r0,uint256 r1,) = IUniswapV2Pair(address(pair)).getReserves();
            uint256 poolU = 0;
            uint256 poolT = 0;
            if(token0 == usdt){ 
                poolU = r0;
                poolT = r1;
            }else{
                poolU = r1; 
                poolT = r0;
            }
            require(poolU > 0 && poolT > 0 );
            uint256 amountT = poolT.mul(amountR).div(poolU);
            IERC20(token).mint(_user,amountT);
            for(uint256 i = user.lastUpdateDay.add(1).sub(period);i<endDay;i++){
                if(user.orders[i].amount > user.orders[i].debtAmount){
                    uint256 amount  = user.orders[i].amount.sub(user.orders[i].debtAmount);
                    uint256 amountp = user.orders[i].amount.div(period).mul(endDay.sub(user.lastUpdateDay));
                    if(amountp > amount){
                        amountp = amount;
                    }
                    user.orders[i].debtAmount = user.orders[i].debtAmount.add(amountp);
                    user.totalAmountDebt = user.totalAmountDebt.add(amountp);
                }
            }
        }
        if(user.lastUpdateDay < nowDay)
            user.lastUpdateDay = nowDay;
        return true;
    }

    function earnedReward(address _user) public view returns(uint256){
            uint256 nowDay = block.timestamp.div(oneDay);
            uint256 endDay = nowDay;
            UserInfo storage user = userInfo[_user];
            if(user.totalAmount == 0)
                return 0;
            address up = refer.user_referrer(_user);
            UserInfo storage upUser = userInfo[up];
            uint amountR = 0;
            uint256 tamountU = user.totalAmount.sub(user.totalAmountDebt);
            if(endDay>user.endDay.add(period))
                    endDay = user.endDay.add(period);
            uint256 startDay = user.lastUpdateDay;
            if(user.lastUpdateDay.add(RewardDays) < endDay)
                startDay = endDay.sub(RewardDays);
            if(endDay > startDay){
                for(uint256 i = startDay;i<endDay;i++){
                     uint256 upAmount = 0;
                     uint256 amountU = 0; 
                     uint256 len = i+1;
                     for(uint256 j = len.sub(period);j<len;j++){
                            upAmount = upAmount.add(upUser.orders[j].amount);
                            amountU = amountU.add(user.orders[j].amount);
                     }
                     upAmount = upAmount.mul(387).div(10000*period);
                     uint256 amount = amountU.mul(129).div(100*period);
                     {
                        uint256 upAmountMax = amountU.mul(1290).div(10000*period);
                        if(upAmount > upAmountMax)
                            upAmount = upAmountMax;
                     }
                     uint256 downAmount = 0;  
                     {

                     for(uint256 k = 0;k<7;k++){
                        uint256 dAmount = 0;
                        for(uint256 j = len-period;j<len;j++){
                            dAmount = dAmount.add(user.refAmounts[j][k]);
                        }
                        dAmount = dAmount.mul(129*rates[k]);
                        dAmount = dAmount.div(100000*period);
                        downAmount = downAmount.add(dAmount);
                    }
                    uint256 downAmountMax = amountU.mul(387).div(100*period);
                    if(downAmount > downAmountMax)
                        downAmount = downAmountMax;
                    }
                    
                    
                    if(tamountU >= holdUAmount){
                        amountR = amountR.add(upAmount).add(downAmount).add(amount);
                    }else{
                        amountR = amountR.add(amount);
                    }
                    if(tamountU>0){
                        if(tamountU > amountU.div(period))
                            tamountU = tamountU.sub(amountU.div(period));
                        else
                            tamountU = 0;
                    }
                    
                }
            }
             
            return amountR; 
    }

    function setMinter(address _newMinter) external onlyOwner{
        IERC20(token).transferMinter(_newMinter);
    }


    function getUsersLen() public view returns (uint) {
        return userAddrs.length;
    }

    function getNowRes(address _user) external view returns ( uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 res = maxUAmount.mul(2).sub(user.orders[block.timestamp.div(oneDay)].amount);
        return res;
    }

    struct UserInfoDetail{
        uint256 totalAmount;
        uint256 totalAmountA;
        uint256 totalAmountDebt;
        uint256 day;
        uint256 upAmount;
        uint256 upReward;
        uint256 upRewardMax;
        uint256 downReward;
        uint256 downRewardMax;
        uint256 amount;
        uint256 aReward;
        uint256 reward;
        uint256[7] downAmounts;
        uint256[7] downRewards;  
    }

    function getUserInfo(address _user) public view returns(UserInfoDetail memory uid){
        UserInfo storage user = userInfo[_user];
        address up = refer.user_referrer(_user);
        UserInfo storage upUser = userInfo[up];
        uid.day = block.timestamp.div(oneDay);
        if(user.totalAmount ==0)
            return uid;
        uid.totalAmount = user.totalAmount;
        uid.totalAmountDebt = user.totalAmountDebt;
        uid.totalAmountA = uid.totalAmount.sub(uid.totalAmountDebt);
        uint256 endDay = uid.day;
        if(endDay > user.endDay.add(period))
            endDay = user.endDay.add(period);
        uint256 startDay = user.lastUpdateDay;
        if(user.lastUpdateDay.add(RewardDays) < endDay)
            startDay = endDay.sub(RewardDays);
        if(endDay > startDay){
            uint256 amountU = 0;
            uint256 eDay = endDay.sub(1);
            for(uint256 i = startDay;i<eDay;i++){
                uint256 len = i+1;
                for(uint256 j = len.sub(period);j<len;j++){
                        amountU = amountU.add(user.orders[j].amount);
                }
            }
            amountU = amountU.mul(eDay-startDay).div(period);
            if( amountU > uid.totalAmountA)
                uid.totalAmountA = 0;
            else 
                uid.totalAmountA = uid.totalAmountA.sub(amountU);
        }
        uint256 len1 = endDay+1;
        for(uint256 j = len1.sub(period);j<len1;j++){
            uid.upAmount = uid.upAmount.add(upUser.orders[j].amount);
            uid.amount = uid.amount.add(user.orders[j].amount);
        }
        uid.upReward = uid.upAmount.mul(387).div(10000*period);
        uid.aReward = uid.amount.mul(129).div(100*period);
        uid.upRewardMax = uid.amount.mul(1290).div(10000*period);
        uid.downRewardMax = uid.amount.mul(387).div(100*period);
        for(uint256 k = 0;k<7;k++){
            for(uint256 j = len1.sub(period);j<len1;j++){
                uid.downAmounts[k] = uid.downAmounts[k].add(user.refAmounts[j][k]);
            }
            uid.downRewards[k] = uid.downAmounts[k].mul(129*rates[k]);
            uid.downRewards[k] = uid.downRewards[k].div(100000*period);
            uid.downReward = uid.downReward.add(uid.downRewards[k]);
        }
        {
            uint256 upReward = uid.upReward;
            if(upReward > uid.upRewardMax) upReward = uid.upRewardMax;
            uint256 downReward = uid.downReward;
            if(downReward > uid.downRewardMax) downReward = uid.downRewardMax;
            if(uid.totalAmountA >= holdUAmount)
                uid.reward = uid.aReward.add(upReward).add(downReward);
            else 
                uid.reward = uid.aReward;
            uid.upReward = upReward;
            uid.downReward = downReward;
        }
    }

}