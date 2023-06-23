/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

struct DepositInfo {           /* 存款信息 */
     uint256    Amount;        /* 当前存款金额 */
     uint256    DepositTm; /* 最新一次存款时间点，unix时间戳，秒  */
}

contract Escrow {
     uint256 constant _MaxWeightSec = 1 days * 30;//30*24*60*60;         /* 权重最多累计30天 */

     address public OwnerAddr;
     uint256 public TotalDeposits ;         /* 通过deposit存入的总的金额 */

     event Deposited(address indexed addr, uint256 depAmt, uint256 poolAmt);      /* 地址， 新存金额， 最新余额 */
     event Withdrawn(address indexed addr, uint256 withdrawAmt, uint256 poolAmt); /* 地址， 新取金额， 最新余额 */

     mapping(address => DepositInfo) private depInfoMap;

     constructor() {
          OwnerAddr = msg.sender;
     }

     function calcVotesTo(uint256 depositTm, uint256 depositAmt, uint256 toTm) public pure returns (uint256 voteAmt) {
          uint256 weightSec;
          if (toTm > depositTm){
               weightSec = toTm - depositTm;
          }else{
               weightSec = 0;
          }

          if(weightSec > _MaxWeightSec){
               weightSec = _MaxWeightSec;
          }
          unchecked{
               voteAmt = depositAmt * weightSec/_MaxWeightSec;
          }
          
          if(voteAmt > depositAmt){
               voteAmt = depositAmt;
          }
          return voteAmt;
     }

     /* getDepositInfo : 查询用户投票时间,投票的ETH金额,当前的投票数 */
     function getDepositInfoTo(address addr, uint256 toTm) public view returns (uint256 amount, uint256 depositTm, uint256 voteAmt) {
          DepositInfo storage info = depInfoMap[addr];
          voteAmt = calcVotesTo(info.DepositTm, info.Amount, toTm);
          return (info.Amount, info.DepositTm, voteAmt);
     }

     function getDepositInfoTo(address addr) public view returns (uint256 amount, uint256 depositTm, uint256 voteAmt) {
          DepositInfo storage info = depInfoMap[addr];
          voteAmt = calcVotesTo(info.DepositTm, info.Amount, block.timestamp);
          return (info.Amount, info.DepositTm, voteAmt);
     }     

     /* getVoteAmt : 查询用户投票时间,投票的ETH金额,当前的投票数 */
     function getVoteAmt(address addr) public view returns (uint256 voteAmt) {
          DepositInfo storage info = depInfoMap[addr];
          voteAmt = calcVotesTo(info.DepositTm, info.Amount, block.timestamp);
          return voteAmt;
     }

     function deposit() public payable {
          require(msg.sender == tx.origin, "support EOA only");
          uint256 incAmt = msg.value;
          
          DepositInfo storage info = depInfoMap[msg.sender];
          if(info.DepositTm > 0 && info.Amount > 0){
               uint256 weightSec = uint256(block.timestamp) - info.DepositTm;
               if(weightSec > _MaxWeightSec){
                    weightSec = _MaxWeightSec;
               }
               uint256 fakeVoteTm;
               unchecked {
                    fakeVoteTm = uint256(block.timestamp) - info.Amount * weightSec/(info.Amount + incAmt); // 倒推伪投票时间
               }
               
               if(fakeVoteTm < info.DepositTm){
                    fakeVoteTm = info.DepositTm;
               }
               if(fakeVoteTm > block.timestamp){
                    fakeVoteTm = block.timestamp;
               }
               info.Amount += incAmt;
               info.DepositTm = fakeVoteTm;
          }else{
               info.Amount = incAmt;
               info.DepositTm = block.timestamp;
          }
          TotalDeposits += incAmt;
          require(address(this).balance >= TotalDeposits, "stat incorrect");
          require(TotalDeposits >= info.Amount, "total amount less than personal amount");
          emit Deposited(msg.sender, incAmt, info.Amount);
     }

     function withdraw(uint256 amt) public{
          require(msg.sender == tx.origin, "support EOA only");

          DepositInfo storage info = depInfoMap[msg.sender];
          require(info.Amount >= amt, "personal deposit insufficient");
          require(TotalDeposits >= amt, "total deposit insufficient");

          info.Amount -= amt;
          TotalDeposits -= amt;

          uint256 oldBalance = address(this).balance;
          payable(msg.sender).transfer(amt);
          
          require(address(this).balance >= TotalDeposits, "stat incorrect");
          require(address(this).balance + amt == oldBalance, "stat incorrect");
          
          emit Withdrawn(msg.sender, amt, info.Amount);
     }
}