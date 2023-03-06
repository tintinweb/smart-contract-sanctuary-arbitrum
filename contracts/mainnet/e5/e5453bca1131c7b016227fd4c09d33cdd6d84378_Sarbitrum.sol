/**
 *Submitted for verification at Arbiscan on 2023-03-06
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract Sarbitrum {
  address teacher = msg.sender;
     uint  Totalstudent = 20;
   uint public Totalstudent_pre  =0;
uint public todaystu;
    mapping(address=>bool) public Present_in_class;
function yesMam(address studentID) public {
       require(!Present_in_class[studentID],"already atended");
        Present_in_class[studentID] = true;
        Totalstudent_pre++;
}
function todayaatendence() public{  
  todaystu = Totalstudent - Totalstudent_pre;
}
    }