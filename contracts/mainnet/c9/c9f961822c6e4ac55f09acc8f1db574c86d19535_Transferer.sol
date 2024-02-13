/**
 *Submitted for verification at Arbiscan.io on 2024-02-13
*/

pragma solidity >=0.8.2 <0.9.0;

contract Transferer {

    function send(address payable receiver) public payable {
        receiver.transfer(msg.value);
    }
}