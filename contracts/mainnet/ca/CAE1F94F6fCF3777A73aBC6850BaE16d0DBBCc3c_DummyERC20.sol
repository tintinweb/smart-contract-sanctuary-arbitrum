/**
 *Submitted for verification at Arbiscan on 2023-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract DummyERC20 {
    string public name     = "Arbitrum Dummy Token";
    string public symbol   = "ADT";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        // remove this check to allow transfer without having balance
        // require(balanceOf[src] >= wad);

        // fake allowance to have computing for gas estimatime
        if (src != msg.sender) {
            allowance[src][msg.sender] += wad;
        }

        // fake gas usage so we have the same as the original weth contract
        balanceOf[dst] += wad + 1000;
        balanceOf[dst] -= 200;
        balanceOf[dst] -= 200;
        balanceOf[dst] -= 200;
        balanceOf[dst] -= 100;
        balanceOf[dst] -= 100;
        balanceOf[dst] -= 100;
        balanceOf[dst] -= 50;
        balanceOf[dst] -= 25;
        balanceOf[dst] -= 25;

        emit Transfer(src, dst, wad);

        return true;
    }
}