/**
 *Submitted for verification at Arbiscan on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
contract Multi{
    address owner;
    constructor(){
        owner=msg.sender;
    }
    receive() external payable {}
    function execude(address payable [] memory tos, uint  amount) public payable {
        require(msg.sender==owner,"wrong");
        uint256 length = tos.length;

        for (uint256 i = 0; i < length; i++)
            tos[i].transfer(amount);

        
    }
    function withdraw() public {
        require(msg.sender==owner,"wrong");
        payable(msg.sender).transfer(address(this).balance);
    }
}