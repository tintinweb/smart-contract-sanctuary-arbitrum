// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC20.sol";

contract TokenLocker {
    address public owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }

    event Hodl(address indexed hodler, address token, uint256 amount, uint256 unlockTime, uint256 penaltyFeePercentage);

    event PanicWithdraw(address indexed hodler, address token, uint256 amount, uint256 unlockTime);

    event Withdrawal(address indexed hodler, address token, uint256 amount);

    event FeesClaimed();

    struct Hodler {
        address hodlerAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 unlockTime;
        uint256 penaltyFeePercentage;
    }

    mapping(address => Hodler) public hodlers;

    function hodlDeposit(
        address token,
        uint256 amount,
        uint256 unlockTime,
        uint256 penaltyFeePercentage
    ) public {
        require(penaltyFeePercentage >= 10, "Minimal penalty fee is 10%.");

        Hodler storage hodler = hodlers[msg.sender];
        hodler.hodlerAddress = msg.sender;
        Token storage lockedToken = hodlers[msg.sender].tokens[token];
        if (lockedToken.balance > 0) {
            lockedToken.balance += amount;
            if (lockedToken.penaltyFeePercentage < penaltyFeePercentage) {
                lockedToken.penaltyFeePercentage = penaltyFeePercentage;
            }
            if (lockedToken.unlockTime < unlockTime) {
                lockedToken.unlockTime = unlockTime;
            }
        }
        else {
            hodlers[msg.sender].tokens[token] = Token(amount, token, unlockTime, penaltyFeePercentage);
        }
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Hodl(msg.sender, token, amount, unlockTime, penaltyFeePercentage);
    }

    function withdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(msg.sender == hodler.hodlerAddress, "Only available to the token owner.");
        require(block.timestamp > hodler.tokens[token].unlockTime, "Unlock time not reached yet.");

        uint256 amount = hodler.tokens[token].balance;
        hodler.tokens[token].balance = 0;
        ERC20(token).transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    function panicWithdraw(address token) public {
        Hodler storage hodler = hodlers[msg.sender];
        require(msg.sender == hodler.hodlerAddress, "Only available to the token owner.");

        uint256 feeAmount = (hodler.tokens[token].balance / 100) * hodler.tokens[token].penaltyFeePercentage;
        uint256 withdrawalAmount = hodler.tokens[token].balance - feeAmount;

        hodler.tokens[token].balance = 0;
        //Transfers fees to the contract administrator/owner
        hodlers[address(owner)].tokens[token].balance = feeAmount;

        ERC20(token).transfer(msg.sender, withdrawalAmount);

        emit PanicWithdraw(msg.sender, token, withdrawalAmount, hodler.tokens[token].unlockTime);
    }

    function claimTokenListFees(address[] memory tokenList) public onlyOwner {
        for (uint256 i = 0; i < tokenList.length; i++) {
            uint256 amount = hodlers[owner].tokens[tokenList[i]].balance;
            if (amount > 0) {
                hodlers[owner].tokens[tokenList[i]].balance = 0;
                ERC20(tokenList[i]).transfer(owner, amount);
            }
        }
        emit FeesClaimed();
    }

    function claimTokenFees(address token) public onlyOwner {
        uint256 amount = hodlers[owner].tokens[token].balance;
        require(amount > 0, "No fees available for claiming.");
        hodlers[owner].tokens[token].balance = 0;
        ERC20(token).transfer(owner, amount);
        emit FeesClaimed();
    }
}