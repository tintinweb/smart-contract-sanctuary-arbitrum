/**
 *Submitted for verification at Arbiscan on 2023-01-27
*/

pragma solidity ^0.6.12;

contract CheckPaid {
    
    address public owner;
    uint256 public fee = 100000000000000000;
    
    constructor() public {
        owner = msg.sender;
    }
    
    mapping(address => bool) public payments;
    
    function transferowner(address _owner) public {
        require(msg.sender == owner);
        owner = _owner;
    }
    
    function changeFee(uint256 _fee) public {
        require(msg.sender == owner);
        fee = _fee;
    }
    
    function pay() public payable {
        require(msg.value == fee, "must pay the fee in eth");
        require(payments[msg.sender] == false, "you already paid");
        payments[msg.sender] = true;
    }
    
    function withdraw() public {
        require(msg.sender == owner);
        msg.sender.transfer(address(this).balance);
    }
}