/**
 *Submitted for verification at Arbiscan on 2023-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VipUserManager {
    struct VipUser {
        uint256 expirationDate;
        bool isValid;
    }

    mapping(address => VipUser) public vipUsers;
    mapping(address => uint256) public inviteCount;
    address payable public owner;
    address[] public inviters;
    uint256 public distributeCount = 10;
    uint256 public currentVipUserCount = 0;

    event RegisteredAsVip(address user, uint256 expirationDate);

    constructor() {
        owner = payable(msg.sender);
    }

    function register(address invitor) public payable {
        require(msg.value == 0.01 ether, "Payment should be equal to 0.01 ether");
        require(vipUsers[msg.sender].isValid == false, "You are already a VIP user");

        VipUser memory newUser;
        newUser.expirationDate = block.timestamp + 90 days;
        newUser.isValid = true;

        vipUsers[msg.sender] = newUser;
        if (inviteCount[invitor] == 0) {
            inviters.push(invitor);
        }
        inviteCount[invitor] += 1;
        currentVipUserCount += 1;

        uint256 toOwner = (msg.value * 60) / 100;
        uint256 toInvitor = (msg.value * 20) / 100;
        owner.transfer(toOwner);
        payable(invitor).transfer(toInvitor);

        emit RegisteredAsVip(msg.sender, newUser.expirationDate);
    }

    function isVip(address _address) public view returns (bool) {
        if(vipUsers[_address].isValid && vipUsers[_address].expirationDate > block.timestamp) {
            return true;
        }
        return false;
    }

    function distributePrize() public {
        require(currentVipUserCount >= distributeCount, "The number of VIP users is less than distributeCount");
        address winner = findTopInvitor();
        payable(winner).transfer(address(this).balance);
    }

    function setDistributeCount(uint256 _distributeCount) public {
        require(msg.sender == owner, "Only owner can set distribute count");
        distributeCount = _distributeCount;
    }

    function findTopInvitor() private view returns (address) {
        address topInvitor = owner;
        uint256 maxInviteCount = 0;

        for (uint i = 0; i < inviters.length; i++) {
            if (inviteCount[inviters[i]] > maxInviteCount) {
                maxInviteCount = inviteCount[inviters[i]];
                topInvitor = inviters[i];
            }
        }

        return topInvitor;
    }

    // 紧急提款函数，只能由合约所有者调用，将合约中的所有ETH转移到所有者地址
    function emergencyWithdraw() public {
        require(msg.sender == owner, "Only the owner can perform an emergency withdrawal");
        owner.transfer(address(this).balance);
    }
}