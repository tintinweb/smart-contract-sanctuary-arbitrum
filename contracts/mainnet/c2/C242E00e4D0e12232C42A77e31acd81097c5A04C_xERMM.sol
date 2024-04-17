// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IxERMM {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address,address,uint256) external returns (bool);
    function burn(uint256) external returns (bool);
    function burnFrom(address, uint256) external returns (bool);
    function owner() external returns (address);
    function setOwner(address) external;
    function ERM() external returns (address);
    function setERM(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

import "./interfaces/IxERMM.sol";

contract xERMM is IxERMM {

    string public constant name = "xERMM";
    string public constant symbol = "xERMM";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 0;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    bool public initialMinted;
    address public owner;
    address public ERM;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        _mint(msg.sender, 0);
    }

    function setOwner(address _owner) external {
        require(msg.sender == owner);
        owner = _owner;
    }

    function setERM(address _ERM) external {
        require(msg.sender == owner);
        ERM = _ERM;
    }

    function initialMint(address _recipient) external {
        require(msg.sender == owner && !initialMinted);
        initialMinted = true;
        _mint(_recipient, 100 * 1e6 * 1e18);
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0x0), _to, _amount);
        return true;
    }

    function _burn(address _from, uint256 _amount) internal returns (bool) {
        totalSupply -= _amount;
        balanceOf[_from] -= _amount;
        emit Transfer(_from, address(0x0), _amount);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        balanceOf[_from] -= _value;
        unchecked {
            balanceOf[_to] += _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        uint allowed_from = allowance[_from][msg.sender];
        if (allowed_from != type(uint256).max) {
            allowance[_from][msg.sender] -= _value;
        }
        return _transfer(_from, _to, _value);
    }

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function burnFrom(address _from, uint256 amount) external returns (bool) {
        require(msg.sender == ERM);
        _burn(_from, amount);
        return true;
    }

}