// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

contract Token {
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint public totalSupply; 
    address payable public owner; 

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approve(address indexed owner, address indexed spender, uint value);

    constructor() {
        name = "Pepe Inu"; 
        symbol = "Pepe"; 
        decimals = 6;
        uint _initialSupply = 1_000_000_000 * 10**6; 

        owner = payable(msg.sender);

        balanceOf[owner] = _initialSupply;
        totalSupply = _initialSupply;

        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        uint senderBalance = balanceOf[msg.sender];
        uint receiverBalance = balanceOf[_to];

        require(_to != address(0), "Receiver address invalid");
        require(_value >= 0, "Value must be greater or equal to 0");
        require(senderBalance > _value, "Not enough balance");

        balanceOf[msg.sender] = senderBalance - _value;
        balanceOf[_to] = receiverBalance + _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value)
      public returns (bool success) {
        uint senderBalance = balanceOf[msg.sender];
        uint fromAllowance = allowance[_from][msg.sender];
        uint receiverBalance = balanceOf[_to];

        require(_to != address(0), "Receiver address invalid");
        require(_value >= 0, "Value must be greater or equal to 0");
        require(senderBalance > _value, "Not enough balance");
        require(fromAllowance >= _value, "Not enough allowance");

        balanceOf[_from] = senderBalance - _value;
        balanceOf[_to] = receiverBalance + _value;
        allowance[_from][msg.sender] = fromAllowance - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

     function approve(address _spender, uint _value) public returns (bool success) {
        require(_value > 0, "Value must be greater than 0");

        allowance[msg.sender][_spender] = _value;

        emit Approve(msg.sender, _spender, _value);
        return true;
    }

    function mint(uint _amount) public returns (bool success) {
        require(msg.sender == owner, "Operation unauthorised");

        totalSupply += _amount;
        balanceOf[msg.sender] += _amount;

        emit Transfer(address(0), msg.sender, _amount);
        return true;
    }

    function burn(uint _amount) public returns (bool success) {
      require(msg.sender != address(0), "Invalid burn recipient");

      uint accountBalance = balanceOf[msg.sender];
      require(accountBalance > _amount, "Burn amount exceeds balance");

      balanceOf[msg.sender] -= _amount;
      totalSupply -= _amount;

      emit Transfer(msg.sender, address(0), _amount);
      return true;
    }
}