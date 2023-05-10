/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

/**
 *Submitted for verification at Arbiscan on 2021-09-21
*/

pragma solidity ^0.4.25;


library SafeMath {
     function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
     function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
}

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

  
contract Disperse {
    using SafeMath for uint256;
    address private owner;
    uint256 private tax=1;
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner.");
        _;
    }
    constructor() public {
        owner = msg.sender;
    }

    function changeTax(uint256 newTax)public onlyOwner returns (bool)
    {
        tax=newTax;
    }

    function disperseEther(address[] recipients, uint256[] values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function disperseToken(IERC20 token, address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total+total.mul(tax).div(100)));
        require(token.transferFrom(msg.sender,owner,total.mul(tax).div(100)));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function disperseTokenSimple(IERC20 token, address[] recipients, uint256[] values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }
}