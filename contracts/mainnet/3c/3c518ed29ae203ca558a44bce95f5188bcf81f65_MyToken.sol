/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Define the variables to track the sell tax fee and the time of contract creation
    uint256 public sellTaxFee;
    uint256 public contractCreationTime;
    address public owner;

    constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, uint8 decimalUnits) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        // Set the initial sell tax fee to 10%
        sellTaxFee = 10;
        contractCreationTime = block.timestamp;
        owner = msg.sender; // Set the contract creator as the owner
    }

    function _setSellTaxFee() internal {
            if (block.timestamp >= contractCreationTime + 1 hours) {
                sellTaxFee = 10;
            } else {
                sellTaxFee = 0;
            }
        }

        function buyTokens() public payable {
        require(msg.value > 0, "Insufficient ether provided");

        uint256 tokensToBuy = msg.value * 2000000000000000000000000000; // Each ether sent can buy 2000000000000000000000000000 tokens
        require(tokensToBuy <= balanceOf[owner], "Not enough tokens in the contract");

        // Transfer the tokens from the owner to the buyer
        balanceOf[msg.sender] += tokensToBuy;
        balanceOf[owner] -= tokensToBuy;

        // Emit the Transfer and Approval events
        emit Transfer(owner, msg.sender, tokensToBuy);
        emit Approval(msg.sender, owner, tokensToBuy);
    }

       function transfer(address _to, uint256 _value) public returns (bool success) {
        _setSellTaxFee();

        if (_to == address(this)) {
            if (sellTaxFee > 0) {
                uint256 sellTaxAmount = (_value * sellTaxFee) / 100;
                balanceOf[msg.sender] -= sellTaxAmount;
                balanceOf[address(this)] += sellTaxAmount;
                emit Transfer(msg.sender, address(this), sellTaxAmount);
            }
        }

        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    


    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}