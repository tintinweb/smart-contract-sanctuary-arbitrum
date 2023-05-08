/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

pragma solidity ^0.4.24;

contract Token{
    function transfer(address to, uint256 value) public returns (bool);
}

contract multisender {
    
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function multisend(address _tokenAddr, address[] memory _to, uint256[] memory _value) public onlyOwner returns (bool _success) {
        require(_to.length == _value.length);
        require(_to.length <= 1000);
        for (uint8 i = 0; i < _to.length; i++) {
            require(Token(_tokenAddr).transfer(_to[i], _value[i] * 10**18));
        }
        return true;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}