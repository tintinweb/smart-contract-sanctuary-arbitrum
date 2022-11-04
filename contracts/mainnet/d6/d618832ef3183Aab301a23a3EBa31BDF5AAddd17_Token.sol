// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.11;

contract Token {

    string public constant symbol = "XCAL";
    string public constant name = "3xcalibur Ecosystem Token";
    uint8 public constant decimals = 18;
    uint public totalSupply = 0;
    uint public immutable MAX_SUPPLY;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    address public minter;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(uint _maxSupply) {
        MAX_SUPPLY = _maxSupply;
        minter = msg.sender;
        _mint(msg.sender, 0);
    }

    // No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        require(_minter != address(0));
        require(msg.sender == minter);
        minter = _minter;
    }

    function approve(address _spender, uint _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint _amount) internal returns (bool) {
        require(totalSupply + _amount <= MAX_SUPPLY, "Token: max supply reached");
        balanceOf[_to] += _amount;
        totalSupply += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function mint(address account, uint amount) external returns (bool) {
        require(msg.sender == minter);
        _mint(account, amount);
        return true;
    }
}