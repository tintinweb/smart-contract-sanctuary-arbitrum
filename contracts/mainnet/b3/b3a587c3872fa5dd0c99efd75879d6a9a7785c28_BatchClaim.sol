/**
 *Submitted for verification at Arbiscan on 2023-06-06
*/

/**
 *Submitted for verification at Arbiscan on 2023-06-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IDO {
    function claim (address adr) external payable;
}

 contract  returnC {

     function claim(address ido,address ercAddress,address adr) public  payable {
         IDO(ido).claim{value:msg.value}(adr);
     }
    
}

contract BatchClaim {

    uint public  idoEtherAmount = 0.00085 ether;
    address public idoAddress = 0x3E0fcF78622dE8573093dd9592B4f4C178187BA3;
    address public ercAddress = 0x51EaCC8Be6F7Aa9D0a20f22eD6FD3dF4Abe2Bf03;

    function batchClaim (uint amount,address inviteaddress) public payable{
        require(msg.value == idoEtherAmount*amount,"Insufficient quantity");
        for(uint a;a < amount;a++){
            returnC claimC = new returnC();
            claimC.claim{value:idoEtherAmount}(idoAddress,ercAddress,inviteaddress);
        }
    }

}