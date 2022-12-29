/**
 *Submitted for verification at Arbiscan on 2022-12-29
*/

pragma solidity ^0.8.0;

contract Disperse {
  address owner;
  address WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    constructor() public {
        owner = msg.sender;
    }
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function disperseETH(address payable[] memory _recipients)external payable{
        uint value = msg.value/_recipients.length;
        // Iterate through the recipients and send the corresponding amount of ETH
        for (uint256 i = 0; i < _recipients.length; i++) {
            _recipients[i].transfer(value);
        }
    }
    function EmergencyWithdraw(address payable _receiver) external payable {
      
        require(msg.sender == owner, "You are not the owner.");
        _receiver.transfer(this.getBalance());
    }
    function setTokenAddress(address _token) public {
        require(msg.sender == owner, "You are not the owner.");
        WETH = _token;
    }    
    
}