/**
 *Submitted for verification at Arbiscan.io on 2024-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;

contract BlockATMAccount {

    mapping(address => uint256) private balanceOf;

    address public settleAddress;

    address public onwer;

    uint256 public minBalance = 100000000;

    struct FeeInfo{
        address contractAddress;
        uint256 amount;
    }

    constructor(address newSettleAddress) {
        settleAddress = newSettleAddress;
        onwer = msg.sender;
    }

    event BatchSettleBalance(FeeInfo[] feeInfoList);

    event SettleBalance(address indexed contractAddress,uint256 balance);

    event SetMinBalance(uint256 minBalance);

    event SetSettleAddress(address settleAddress);


    modifier onlyOwner() {
        require(onwer == msg.sender, "Not the owner");
        _;
    }

    modifier onlySettle() {
        require(settleAddress == msg.sender, "Not the settle address");
        _;
    }

    function batchSettleBalance(FeeInfo[] memory feeInfoList) public onlySettle returns (bool) {
        require(feeInfoList.length > 0, "Parameter error");
        for(uint16 i = 0; i < feeInfoList.length; i++ ){
            FeeInfo memory feeInfo = feeInfoList[i];
            balanceOf[feeInfo.contractAddress] = feeInfo.amount;
        }
        emit BatchSettleBalance(feeInfoList);
        return true;
    }

    function settleBalance(address contractAddress,uint256 balance) public onlySettle returns (bool) {
        balanceOf[contractAddress] = balance;
        emit SettleBalance(contractAddress,balance);
        return true;
    }

    function recharge(FeeInfo memory feeInfo) public onlySettle returns (bool) {
        balanceOf[feeInfo.contractAddress] += feeInfo.amount;
        return true;
    }

    function checkWithdraw() public view returns (bool)  {
        uint256 balance = balanceOf[msg.sender];
        require(balance >= minBalance, "Insufficient business balance");
        return true;
    }

    
    function setSettleAddress(address newSettleAddress) public onlyOwner {
        settleAddress = newSettleAddress;
        emit SetSettleAddress(newSettleAddress);
    }

    function setMinBalance(uint256 newMinBalance) public onlyOwner {
        minBalance = newMinBalance;
        emit SetMinBalance(newMinBalance);
    }

    function getBalanceOf(address newSettleAddress) public view returns (uint256) {
        return balanceOf[newSettleAddress];
    }

}