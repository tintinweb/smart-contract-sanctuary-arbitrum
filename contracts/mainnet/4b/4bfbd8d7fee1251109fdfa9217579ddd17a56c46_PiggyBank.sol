/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

pragma solidity >=0.8.2 <0.9.0;



contract PiggyBank {


    bool received;
    address depositor;
    uint256 depositTime;
    uint256 public constant holdingTime = 2 minutes;
    
    receive() external payable {
        require(depositor == address(0x0), "already deposited");
        depositor = msg.sender;
        depositTime = block.timestamp;
    }

    function redeem() external {
        require (msg.sender == depositor, "caller is not depositor");
        require (block.timestamp >= depositTime + holdingTime, "holding time not elapsed yet");
        payable(msg.sender).transfer(address(this).balance);
    }

}