/**
 *Submitted for verification at Arbiscan on 2023-07-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

/**
 * @title Wrapped Ether v9
 * @dev Implementation of the WETH9 interface.
 * @dev <https://github.com/ethereum/EIPs/issues/20>
 * @dev <https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md>
 * @author Christian Lundkvist
 */
contract WETH {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Deposit(address indexed _owner, uint256 _value);
    event Withdrawal(address indexed _owner, uint256 _value);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "insufficient-balance");
        balanceOf[msg.sender] -= _value;
        payable(msg.sender).transfer(_value);
        emit Withdrawal(msg.sender, _value);
    }

    function totalSupply() external view returns (uint256) {
        return address(this).balance;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balanceOf[msg.sender] >= _value, "insufficient-balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(balanceOf[_from] >= _value, "insufficient-balance");
        require(allowance[_from][msg.sender] >= _value, "insufficient-allowance");
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}