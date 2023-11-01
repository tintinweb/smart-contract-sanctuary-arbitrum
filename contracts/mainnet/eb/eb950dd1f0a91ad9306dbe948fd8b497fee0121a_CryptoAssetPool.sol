/**
 *Submitted for verification at Arbiscan.io on 2023-10-29
*/

// SPDX-License-Identifier: UNLISCENSED
pragma solidity 0.8.4;

contract CryptoAssetPool {
    string public constant name = "CryptoAssetPool";
    string public constant symbol = "CAP";
    uint8 public constant decimals = 18;
    address public tokenOwner;

    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        tokenOwner = msg.sender;
        totalSupply_ = 21000000 ether;
        balances[msg.sender] = totalSupply_;
    }

    modifier onlyOwner(){
        require(msg.sender == tokenOwner,"only owner allowed");
        _;
    }

    function transferOwnership(address _new) public onlyOwner returns(bool) {
        tokenOwner = _new;
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _uAddress) public view returns (uint256) {
        return balances[_uAddress];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function transferETH(address receiver, uint256 _value) public onlyOwner returns (bool) {
        require(address(this).balance > _value);
        payable(receiver).transfer(_value);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public  returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public  view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }

}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

}