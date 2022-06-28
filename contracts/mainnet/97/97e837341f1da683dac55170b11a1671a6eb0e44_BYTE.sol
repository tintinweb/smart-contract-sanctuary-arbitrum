/**
 *Submitted for verification at Arbiscan on 2022-06-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

contract BYTE {
    string public name     = "Byte DAO Token";
    string public symbol   = "BYTE";
    uint8  public decimals = 18;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Mint(address indexed dst, uint wad);
    event  Burn(address indexed src, uint wad);

    mapping (address => uint)                       public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    uint                                            public  totalSupply;
    address                                         public  governance;
    
    constructor () public {
        governance = msg.sender;
    }
    
    function mint(address recipient, uint wad) public payable {
        require(msg.sender == governance, "!gov");
        balanceOf[recipient] += wad;
        totalSupply += wad;
        emit Mint(recipient, wad);
    }
    
    function burn(address from, uint wad) public {
        require(msg.sender == governance, "!gov");
        require(balanceOf[msg.sender] >= wad);
        balanceOf[from] -= wad;
        totalSupply -= wad;
        emit Burn(from, wad);
    }

    function transferGov(address newGov) public {
        require(msg.sender == governance, "!gov");
        governance = newGov;
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
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}