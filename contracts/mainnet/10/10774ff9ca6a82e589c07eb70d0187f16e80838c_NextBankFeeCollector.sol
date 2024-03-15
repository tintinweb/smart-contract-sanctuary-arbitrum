/**
 *Submitted for verification at Arbiscan.io on 2024-03-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract NextBankFeeCollector {
    address public owner;
    IERC20 public usdtContract;
    mapping(address => bool) public hasTransferred;
    uint256 public transferAmount;

    event USDTTransferred(address indexed sender, uint256 amount);
    event OwnerUpdated(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    constructor(address _owner, address _usdtContract, uint256 _initialAmount) {
        owner = _owner;
        usdtContract = IERC20(_usdtContract);
        transferAmount = _initialAmount;
    }

    function updateTransferAmount(uint256 _newAmount) public onlyOwner {
        transferAmount = _newAmount;
    }

    function transferToAdmin() public {
        require(!hasTransferred[msg.sender], "Sender has already transferred USDT.");
        require(transferAmount > 0, "Transfer amount must be greater than zero.");
        bool sent = usdtContract.transferFrom(msg.sender, owner, transferAmount);
        require(sent, "USDT transfer failed.");
        hasTransferred[msg.sender] = true;
        
        emit USDTTransferred(msg.sender, transferAmount);
    }

    function hasAddressTransferred(address _address) public view returns (bool) {
        return hasTransferred[_address];
    }

    function withdraw(IERC20 token) public onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        bool sent = token.transfer(owner, balance);
        require(sent, "Token transfer failed.");
    }

    function updateOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be the zero address.");
        emit OwnerUpdated(owner, _newOwner);
        owner = _newOwner;
    }
}