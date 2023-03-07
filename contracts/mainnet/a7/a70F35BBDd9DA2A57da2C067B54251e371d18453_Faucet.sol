/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

//b3rtone faucet in Arbitrum. 10x to ethereumbook
pragma solidity 0.6.4;
contract Faucet {
    receive() external payable {}
    function withdraw(uint withdraw_amount) public {
        require(withdraw_amount <= 1000000000000);
        msg.sender.transfer(withdraw_amount);
    }
}