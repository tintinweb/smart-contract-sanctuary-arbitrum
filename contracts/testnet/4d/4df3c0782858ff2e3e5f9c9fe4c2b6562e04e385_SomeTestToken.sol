/**
 *Submitted for verification at Arbiscan on 2022-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract SomeTestToken is ERC20 {
    string public constant symbol = "XYZ";
    string public constant name = "XYZ Coin";
    uint8 public constant decimals = 18;

    uint private constant __totalSupply = 1000000 * 10 ** decimals;
    mapping (address => uint) private __balanceOf;
    mapping (address => mapping (address => uint)) private __allowances;
    constructor() {
        __balanceOf[msg.sender] = __totalSupply;
    }
    function totalSupply() public pure returns (uint _totalSupply) {
        _totalSupply = __totalSupply;
    }
    function balanceOf(address _addr) public view override returns (uint balance) {
        return __balanceOf[_addr];
    }
    function transfer(address _to, uint _value) public override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }
    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        if (__allowances[_from][msg.sender] > 0 &&
            _value >0 &&
            __allowances[_from][msg.sender] >= _value
            //  the to address is not a contract
            && !isContract(_to)) {
            __balanceOf[_from] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;    
    }
    function approve(address _spender, uint _value) external override returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return __allowances[_owner][_spender];
    }
}