/**
 *Submitted for verification at Arbiscan on 2023-05-03
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TuleToken {
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(string memory _name, string memory _symbol, uint256 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balances[msg.sender] = totalSupply;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function buyTokens() public payable {
        uint256 tokens = msg.value * 1000 / 1100; // Cobramos una comisión de compra del 10% y quemamos el 1%
        uint256 burnAmount = msg.value * 100 / 11000; // Calculamos el 1% para quemar
        require(balances[msg.sender] + tokens <= totalSupply);
        balances[msg.sender] += tokens;
        balances[address(this)] += msg.value - burnAmount;
        balances[address(0)] += burnAmount; // Quemamos el 1%
        emit Transfer(address(this), msg.sender, tokens);
        emit Transfer(address(this), address(0), burnAmount); // Emitimos el evento de transferencia a la dirección 0x0 para indicar la quema
    }

    function sellTokens(uint256 _value) public {
        require(balances[msg.sender] >= _value);
        uint256 ethAmount = _value * 100 / 110; // Cobramos una comisión de venta del 10% y quemamos el 1%
        uint256 burnAmount = _value / 110; // Calculamos el 1% para quemar
        balances[msg.sender] -= _value;
        balances[address(this)] += ethAmount - burnAmount;
        balances[address(0)] += burnAmount; // Quemamos el 1%
        payable(msg.sender).transfer(ethAmount);
        emit Transfer(msg.sender, address(this), _value);
        emit Transfer(address(this), address(0), burnAmount); // Emitimos el evento de transferencia a la dirección 0x0 para indicar la quema
    }
}