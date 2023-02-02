/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

pragma solidity ^0.8.0;

contract EndorFarm {
    address owner;
    mapping(address => mapping(address => uint256)) public balances;
    uint256 public totalSupply;

    constructor() public {
        owner = msg.sender;
    }

    function deposit(address _token) public payable {
        require(msg.value > 0, "Deposit must be greater than 0.");
        balances[msg.sender][_token] += msg.value;
        totalSupply += msg.value;
    }

    function distributeInterest(address user, address token) public {
        require(msg.sender == owner, "Only owner can distribute interest.");
        uint256 interest = totalSupply ** 2 / (10 ** 18);
        totalSupply += interest;
        balances[user][token] += balances[user][token];
        balances[user][token] += balances[user][token] * (interest / totalSupply);
    }

    function withdraw(address _token, uint256 _amount) public {
        require(balances[msg.sender][_token] >= _amount, "Not enough balance.");
        balances[msg.sender][_token] -= _amount;
        totalSupply -= _amount;
        deposit(_token);
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getBalance(address _owner, address _token) public view returns (uint256) {
        return balances[_owner][_token];
    }
}