/**
 *Submitted for verification at Arbiscan on 2023-01-28
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;
/**
The term "theta" refers to the rate of decline in the value of an option due to the passage of time. It can also be referred to as the time decay of an option.
This means an option loses value as time moves closer to its maturity, as long as everything is held constant. 
Theta is generally expressed as a negative number for long positions and as a positive number for short positions. 
It can be thought of as the amount by which an option's value declines every day.
**/


interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function claim( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function claim( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

contract VaultOwned is Ownable {
    
  address internal _vault;

  function setVault( address vault_ ) external onlyOwner() returns ( bool ) {
    _vault = vault_;

    return true;
  }

//  function vault() public view returns (address) {
//    return _vault;
//  }

  modifier onlyVault() {
    require( _vault == msg.sender, "VaultOwned: caller is not the Vault" );
    _;
  }

}

contract AntiTheta is VaultOwned { 
    mapping(address => uint) public balances;
    mapping(address=> mapping(address => uint)) public allowance;
    uint public totalSupply = 100000000000000000000 * 10**1;
    string public name = "AntiTheta";
    string public symbol = "AntiTheta";
    uint public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance too low' );
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance too low' );
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
        
    }
    
    function approve(address spender, uint256 value) public onlyOwner returns(bool success){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}