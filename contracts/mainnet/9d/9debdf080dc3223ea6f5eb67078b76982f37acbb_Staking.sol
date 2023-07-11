/**
 *Submitted for verification at Arbiscan on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// ERC20 代币接口
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Staking {
    event deposit_e(uint256 amount,uint256 proid);
    event withdraw_e(uint256 tokenId);
    address public tokenAddress;
    address public admin;
    uint256 public baseapy;
    uint256 public order_Id;//cur orderid
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        baseapy = 6;
        order_Id=0;
        admin=msg.sender;
    }
    mapping(uint256 => ProDatav) public getprov;
    mapping(uint256 => OrderInfov) public orderInfov;
    mapping(uint256 => address) public order_idToAddress;
    mapping(address => uint256[]) internal order_addressToIds;

    function order_getIds(address _addr) public view returns (uint256[] memory) {
        return order_addressToIds[_addr];
    }

    //set Pro
    struct ProDatav {
        uint256 apy;
        uint256 day;
        uint256 status;
    }
    function usetProData(uint256 id, uint256 apy, uint256 day, uint256 status) public {
        require(admin==msg.sender, "Caller error");
        ProDatav memory data = ProDatav(apy, day, status);
        getprov[id] = data;
    }

    function getProData(uint256 id) internal view returns (uint256, uint256, uint256) {
        ProDatav memory data = getprov[id];
        return (data.apy, data.day, data.status);
    }

    //set order
    struct OrderInfov {
        address addr;
        uint256 amount;
        uint256 proid;
        uint256 start_time;
    }    
    function getOrderInfo(uint256 _orderId) internal view returns (address, uint256, uint256, uint256) {
        OrderInfov storage data = orderInfov[_orderId];
        return (data.addr, data.amount, data.proid, data.start_time);
    }

    //存入
    function deposit(uint256 amount,uint256 proid) public {
        (,,uint256 status) = getProData(proid);
        require(status==1, "Package stopped");

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);

        //creat order
        order_Id=order_Id+1;
        order_idToAddress[order_Id] = msg.sender;
        order_addressToIds[msg.sender].push(order_Id);

        //order
        OrderInfov storage data = orderInfov[order_Id];
        data.addr = msg.sender;
        data.amount = amount;
        data.proid = proid;
        data.start_time = block.timestamp;
        emit deposit_e(amount,proid);
    }


    //提取
    function withdraw(uint256 tokenId) public{
        (address addr,uint256 amount ,uint256 proid , uint256 start_time) = getOrderInfo(tokenId);
        require(addr==msg.sender, "Caller error");
        require(order_idToAddress[tokenId] == msg.sender, "Orderid error");
        //burn order
        uint[] storage ids = order_addressToIds[msg.sender];
        for (uint i = 0; i < ids.length; i++) {
            if (ids[i] == tokenId) {
                // 将最后一个 ID 移到要删除的位置
                ids[i] = ids[ids.length - 1];
                ids.pop(); // 移除末尾的 ID
                break;
            }
        }
        delete order_idToAddress[tokenId];
        //burn order

        (uint256 apy,uint256 day,) = getProData(proid);

        uint256 difference = block.timestamp - start_time;
        uint256 cur_day = difference / (1 days);
        uint256 amount_income=0;
        if(cur_day<=day){
            amount_income = cur_day* apy * amount / (100 * 365);
        }else{
            uint256 diffday=cur_day-day;
            amount_income = day * apy * amount / (100 * 365) + diffday * baseapy * amount / (100 * 365);
        }        
        uint256 totalamount=amount_income + amount;

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= totalamount, "Insufficient balance");
        token.transfer(msg.sender, totalamount);
        emit withdraw_e(tokenId);
    }

    //order to income
    function order_income(uint256 tokenId) public view returns (uint256){
        (,uint256 amount ,uint256 proid , uint256 start_time) = getOrderInfo(tokenId);

        require(order_idToAddress[tokenId] != 0x0000000000000000000000000000000000000000, "Orderid error");

        (uint256 apy,uint256 day,) = getProData(proid);

        uint256 difference = block.timestamp - start_time;
        uint256 cur_day = difference / (1 days);
        uint256 amount_income=0;
        if(cur_day<=day){
            amount_income = cur_day* apy * amount / (100 * 365);
        }else{
            uint256 diffday=cur_day-day;
            amount_income = day * apy * amount / (100 * 365) + diffday * baseapy * amount / (100 * 365);
        }
        uint256 totalamount=amount_income + amount;
        return totalamount;
    }
    //查询合约余额
    function balance() public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(address(this));
    }

}