/**
 *Submitted for verification at arbiscan.io on 2022-03-02
*/

/**
 *Submitted for verification at arbiscan.io on 2022-03-03
*/

// Asian Dragon - ARBIAD2.sol - AD2 (ARBI) is the official Asian Dragon (AD2) Token.
// AD2 on ARBITRUM Chain is "One of Asian Dragon (AD2) Token" multiple chain that allow Asian Dragon Loyalty members to exchange Loyalty Points to Cryptocurrency (AD2).
//
//SPDX-License-Identifier: MIT

//      #                              ######                                     
//     # #    ####  #   ##   #    #    #     # #####    ##    ####   ####  #    # 
//    #   #  #      #  #  #  ##   #    #     # #    #  #  #  #    # #    # ##   # 
//   #     #  ####  # #    # # #  #    #     # #    # #    # #      #    # # #  # 
//   #######      # # ###### #  # #    #     # #####  ###### #  ### #    # #  # # 
//   #     # #    # # #    # #   ##    #     # #   #  #    # #    # #    # #   ## 
//   #     #  ####  # #    # #    #    ######  #    # #    #  ####   ####  #    # 
//
//
//

pragma solidity ^0.4.18;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {

        c = a + b;

        require(c >= a);

    }

    function sub(uint a, uint b) internal pure returns (uint c) {

        require(b <= a);

        c = a - b;

    }

    function mul(uint a, uint b) internal pure returns (uint c) {

        c = a * b;

        require(a == 0 || c / a == b);

    }

    function div(uint a, uint b) internal pure returns (uint c) {

        require(b > 0);

        c = a / b;

    }

}

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md


contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


contract ApproveAndCallFallBack {

    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;

}

contract Owned {

    address public owner;

    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {

        owner = msg.sender;

    }

    modifier onlyOwner {

        require(msg.sender == owner);

        _;

    }


    function transferOwnership(address _newOwner) public onlyOwner {

        newOwner = _newOwner;

    }

    function acceptOwnership() public {

        require(msg.sender == newOwner);

        OwnershipTransferred(owner, newOwner);

        owner = newOwner;

        newOwner = address(0);

    }

}

// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply

contract ARBIAD2 is ERC20Interface, Owned {

    using SafeMath for uint;

    string public symbol;

    string public  name;

    uint8 public decimals;

    uint public _totalSupply;

    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;
 
// Constructor

    function FreeToken() public {

        symbol = "AD2";

        name = "Asian Dragon";

        decimals = 8;

        _totalSupply = 100000000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;

        Transfer(address(0), owner, _totalSupply);

    }

// Total supply
  
    function totalSupply() public constant returns (uint) {

        return _totalSupply  - balances[address(0)];

    }
 
// Get the token balance for account `tokenOwner`
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {

        return balances[tokenOwner];

    }
 
    function transfer(address to, uint tokens) public returns (bool success) {

        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        Transfer(msg.sender, to, tokens);

        return true;

    }

 // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

    function approve(address spender, uint tokens) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        Approval(msg.sender, spender, tokens);

        return true;

    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {

        balances[from] = balances[from].sub(tokens);

        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);

        balances[to] = balances[to].add(tokens);

        Transfer(from, to, tokens);

        return true;

    }

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {

        return allowed[tokenOwner][spender];

    }


    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {

        allowed[msg.sender][spender] = tokens;

        Approval(msg.sender, spender, tokens);

        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);

        return true;

    }

    function () public payable {

        revert();

    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {

        return ERC20Interface(tokenAddress).transfer(owner, tokens);

    }

}