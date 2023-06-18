/**
 *Submitted for verification at Arbiscan on 2023-06-18
*/

pragma solidity ^0.4.26;

library SafeMath2 {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}





contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract ERC20Interface {
    
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, string memory data) public;
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


contract ETOToken is ERC20Interface, Owned, SafeMath {
    using SafeMath2 for uint;
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    //mapping(address => uint) balances;
    //mapping(address => mapping(address => uint)) allowed;
    mapping(address => mapping(address => uint)) public allowance;


    constructor(address _address) public payable {
        symbol = "ETO";
        name = "Eternity Trio Org";
        decimals = 6;
        totalSupply = 300000000000000000;
        balanceOf[_address] = totalSupply;


        emit Transfer(address(0), _address, totalSupply);

    }


    function totalSupply() public view returns (uint) {
        return totalSupply;
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balanceOf[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
   
    function approve(address spender, uint tokens) public returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balanceOf[from] = safeSub(balanceOf[from], tokens);
        allowance[from][msg.sender] = safeSub(allowance[from][msg.sender], tokens);
        balanceOf[to] = safeAdd(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowance[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, string memory data) public  returns (bool success) {
        allowance[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, spender, data);
        return true;
    }

    function transferOwner(address _address) public onlyOwner returns (bool success) {
        Owned.transferOwnership(_address);
        return true;
    }
 
	function burn(address to,uint value) public onlyOwner returns (bool success) {
       
        totalSupply = safeSub(totalSupply, value);
        emit Transfer(to, address(0), value);
    }
    
  
}