// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TimeLockContract {
    address public beneficiary;
    uint256 public releaseTime;

    // Store the locked token balance for an account in `lockedBalanceOf[account][token]`
    // `token = 0x0` means ETH
    mapping(address => mapping(address => uint256)) public lockedBalanceOf;

    // Constructor sets the beneficiary address and release time (in Unix timestamp)
    // `beneficiary` is a multi-sig address
    constructor(address _beneficiary, uint256 _releaseTime) {
        require(_releaseTime > block.timestamp, "Release time must be in the future");
        require(_releaseTime < block.timestamp + 90 days, "Release time must be within 3 months");
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

    // TODO: extend release time

    // Function to receive ETH deposits
    receive() external payable {
        uint256 amount = msg.value;
        require(amount > 0, "Deposit amount must be greater than zero");

        lockedBalanceOf[msg.sender][address(0x0)] += amount;
        emit TokenLocked(msg.sender, address(0x0), amount);
    }

    // Function to receive ERC20 tokens
    function lockERC20(address token, uint256 amount) public {
        require(amount > 0, "Deposit amount must be greater than zero");

        lockedBalanceOf[msg.sender][token] += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit TokenLocked(msg.sender, token, amount);
    }

    // Function to withdraw ETH, only available after release time and only to the beneficiary
    function withdrawETH(uint256 amount) public {
        require(block.timestamp >= releaseTime, "Current time is before release time");
        require(msg.sender == beneficiary, "Only beneficiary can withdraw");

        uint256 balance = address(this).balance;
        require(balance >= amount, "Insufficient ETH balance");

        payable(beneficiary).transfer(amount);
        emit TokenWithdrawn(address(0x0), amount);
    }

    // Function to withdraw ERC20 tokens, only available after release time and only to the beneficiary
    function withdrawERC20(address token, uint256 amount) public {
        require(block.timestamp >= releaseTime, "Current time is before release time");
        require(msg.sender == beneficiary, "Only beneficiary can withdraw");

        IERC20 tokenContract = IERC20(token);
        uint256 balance = tokenContract.balanceOf(address(this));
        require(balance >= amount, "Insufficient token balance");

        tokenContract.transfer(beneficiary, amount);
        emit TokenWithdrawn(token, amount);
    }

    event TokenLocked(address indexed account, address token, uint256 amount);
    event TokenWithdrawn(address token, uint256 amount);
}