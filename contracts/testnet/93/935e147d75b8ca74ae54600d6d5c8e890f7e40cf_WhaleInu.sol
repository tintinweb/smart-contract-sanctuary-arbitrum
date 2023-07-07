/**
 *Submitted for verification at Arbiscan on 2023-07-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WhaleInu {
    string public name = "Whale Inu";
    string public symbol = "WHINU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 420690000 * (10 ** uint256(decimals));
    uint256 public maxWalletLimit = (totalSupply * 2) / 100; // 2% of total supply

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private _maxTxAmount = (totalSupply * 1) / 100; // 1% of total supply
    mapping(address => bool) private _isExcludedFromMaxTx;

    address public tokenPublisher; // Address of the token publisher

    bool private _ownershipRenounced; // Whether ownership has been renounced

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Buy(address indexed buyer, uint256 amount, uint256 cost);
    event Sell(address indexed seller, uint256 amount, uint256 earning);
    event OwnershipRenounced(address indexed previousOwner);

    modifier onlyTokenPublisher() {
        require(!_ownershipRenounced, "Ownership renounced: Only the current owner can perform this action.");
        require(msg.sender == tokenPublisher, "Unauthorized: Only the token publisher can perform this action.");
        _;
    }

    constructor() {
        balances[msg.sender] = totalSupply;
        _isExcludedFromMaxTx[msg.sender] = true;
        tokenPublisher = msg.sender; // Save the address of the token publisher
        _ownershipRenounced = false; // Initialize ownership renouncement state to "false"
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, allowed[from][msg.sender] - value);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "Invalid address");
        require(recipient != address(0), "Invalid address");
        require(amount > 0, "Invalid amount");

        if (_isExcludedFromMaxTx[sender] == false && _isExcludedFromMaxTx[recipient] == false) {
            require(amount <= _maxTxAmount, "Exceeds maximum transaction amount");
        }

        uint256 burnAmount = (amount * 2) / 100;
        uint256 transferAmount = amount - burnAmount;

        balances[sender] -= amount;
        balances[recipient] += transferAmount;
        balances[burnAddress] += burnAmount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, burnAddress, burnAmount);
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "Invalid address");
        require(spender != address(0), "Invalid address");

        allowed[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function setMaxTxExclusion(address account, bool excluded) external onlyTokenPublisher {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function renounceOwnership() public onlyTokenPublisher {
        _ownershipRenounced = true;
        emit OwnershipRenounced(tokenPublisher);
    }
}