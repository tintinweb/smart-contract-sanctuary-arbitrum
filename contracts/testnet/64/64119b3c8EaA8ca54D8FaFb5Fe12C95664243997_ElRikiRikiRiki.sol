pragma solidity ^0.8.0;

contract ElRikiRikiRiki {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    address private _marketingWallet;

    // Define the events
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        _name = "El Riki Riki Riki";
        _symbol = "RIKI";
        _totalSupply = 1000000000; // Set the initial total supply
        _balances[msg.sender] = _totalSupply; // Assign the total supply to the contract deployer
        _marketingWallet = 0xb8143bB7c22a5f5817582836B8600E47e0D6b98e; // Set the marketing wallet address
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= _balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid recipient address");

        uint256 taxAmount = value * 10 / 100; // Calculate the tax amount (10% of the transaction value)
        uint256 netAmount = value - taxAmount; // Calculate the net amount after applying the tax

        _balances[msg.sender] -= value; // Subtract the total transaction value from the sender's balance
        _balances[_marketingWallet] += taxAmount; // Add the tax amount to the marketing wallet
        _balances[to] += netAmount; // Add the net amount to the recipient's balance

        emit Transfer(msg.sender, to, netAmount); // Emit a Transfer event for the net amount

        return true;
    }
}