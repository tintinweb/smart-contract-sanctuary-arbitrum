/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

pragma solidity >=0.8.2 <0.9.0;


contract BlackFridaySaver {

    address depositor;
    uint256 depositTime;

    receive() external payable {
        require(msg.sender == address(0x0), "already deposited");
        depositor = msg.sender;
        depositTime = block.timestamp;
    }

    function withdraw() external {
        require(block.timestamp >= depositTime + 2 minutes, "holding time not elapsed yet");
        require(msg.sender == depositor, "you're not the depositor!!");
        payable(msg.sender).transfer(address(this).balance);
    }


}