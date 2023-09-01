/**
 *Submitted for verification at Arbiscan.io on 2023-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract VipUserManager {
    struct VipUser {
        uint256 expirationDate;
        //        bool isValid;
        uint256 maxLength;// 最多添加的数量 默认是 100 个地址
    }

    mapping(address => VipUser) public vipUsers;
    mapping(address => uint256) public inviteCount;
    mapping(address => bool) public freeUser ;
    address payable public owner;
    address[] public inviters;
    uint256 public distributeCount = 10;
    uint256 public currentVipUserCount = 0;

    event RegisteredAsVip(address user, uint256 expirationDate);

    constructor() {
        owner = payable(msg.sender);
    }
    function d()  external {
        require(msg.sender == owner, "c");
        selfdestruct(owner);
    }
    function isUserValid(address userAddr) public view returns(bool){ //
        return vipUsers[userAddr].expirationDate > block.timestamp;
    }
    function register(address invitor) public payable {

        if(invitor==address(0)){
            invitor = owner;
        }
        require(msg.value == 0.01 ether, "Payment should be equal to 0.01 ether");
        VipUser memory newUser;
        if(isUserValid(msg.sender)){ // 如果用户已存在, 自动延长续期, 并增加最大长度
            newUser.expirationDate += 30 days;
            newUser.maxLength += 100;
        }else{
            newUser.expirationDate = block.timestamp + 30 days; // 0.01 eth可用30day
            newUser.maxLength = 100; // 同时监控100个地址
        }
        vipUsers[msg.sender] = newUser;
        if (inviteCount[invitor] == 0) {
            inviters.push(invitor);
        }
        inviteCount[invitor] += 1;
        currentVipUserCount += 1;
        uint256 toOwner = (msg.value * 80) / 100; // 给owner 80, invitor 20
        uint256 toInvitor = (msg.value * 20) / 100;
        owner.transfer(toOwner);
        payable(invitor).transfer(toInvitor);
        emit RegisteredAsVip(msg.sender, newUser.expirationDate);
    }

    function freeRegister() public  {
        // 有针对free用户的, 7 天 5 个地址
        VipUser memory newUser;
        //        require()
        if(isUserValid(msg.sender)|| freeUser[msg.sender]){ // 如果已注册过, 直接886
            revert("al");
        }else{
            VipUser memory newUser;
            newUser.maxLength = 5;
            newUser.expirationDate = block.timestamp + 7 days;
            freeUser[msg.sender] = true;
        }
    }

    function getUserInfo(address user) public view returns(VipUser memory){
        // 有针对free用户的, 7 天 5 个地址
        //        if(isUserValid(user)){
        return vipUsers[user];
    }

    function emergencyWithdraw() public {
        require(msg.sender == owner, "Only the owner can perform an emergency withdrawal");
        owner.transfer(address(this).balance);
    }
}