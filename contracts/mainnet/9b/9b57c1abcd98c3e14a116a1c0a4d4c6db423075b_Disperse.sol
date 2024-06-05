/**
 *Submitted for verification at Arbiscan.io on 2024-06-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

abstract contract ReentrancyGuard {//от OpenZeppelin

    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    uint256 private _status;
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

contract Disperse is ReentrancyGuard {
    uint256 public REIMBURSEMENT_PER_RECIPIENT; // Размер кешбека за каждого получателя
    address public owner;

    constructor() {
        owner = msg.sender;
        REIMBURSEMENT_PER_RECIPIENT = 10000000000000;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    // Функция для передачи прав владельца другому адресу
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function setReimbursementPerRecipient(uint256 _newAmount) public onlyOwner {
        REIMBURSEMENT_PER_RECIPIENT = _newAmount;
    }

    // Функция для вывода эфиров с контракта только владельцем
    function withdrawEther(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    function disperseEther(address[] memory recipients, uint256 value) external payable nonReentrant {
        require(recipients.length * value <= msg.value, "Sent amount exceeds available balance");

        for (uint256 i = 0; i < recipients.length; i++) {
            address payable recipientPayable = payable(recipients[i]);
            recipientPayable.transfer(value);
        }
    
        uint256 reimbursementAmount = recipients.length * REIMBURSEMENT_PER_RECIPIENT;
        if (address(this).balance >= reimbursementAmount) {
            reimburseGas(reimbursementAmount);
        }
    }

    function disperseToken(IERC20 token, address[] calldata recipients, uint256 value) external nonReentrant {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            total += value;
        }
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], value));
        }

        uint256 reimbursementAmount = recipients.length * REIMBURSEMENT_PER_RECIPIENT;
        if (address(this).balance >= reimbursementAmount) {
            reimburseGas(reimbursementAmount);
        }
    }

    function disperseEtherToMultiple(address[] memory recipients, uint256[] memory values) external payable nonReentrant {
        require(recipients.length == values.length, "Recipients and values count mismatch");

        uint256 totalSent = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            totalSent += values[i];
            address payable recipientPayable = payable(recipients[i]);
            recipientPayable.transfer(values[i]);
        }

        require(totalSent <= msg.value, "Sent amount exceeds available balance");

        // Возмещение затрат на газ
        uint256 reimbursementAmount = recipients.length * REIMBURSEMENT_PER_RECIPIENT;
        if (address(this).balance >= reimbursementAmount) {
            reimburseGas(reimbursementAmount);
        }
    }

    function disperseTokenToMultiple(IERC20 token, address[] calldata recipients, uint256[] calldata values) external nonReentrant {
        require(recipients.length == values.length, "Recipients and values count mismatch");

        uint256 totalRequired = 0;
        for (uint256 i = 0; i < values.length; i++) {
            totalRequired += values[i];
        }

        require(token.transferFrom(msg.sender, address(this), totalRequired));
    
        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], values[i]));
        }

        // Возмещение затрат на газ
        uint256 reimbursementAmount = recipients.length * REIMBURSEMENT_PER_RECIPIENT;
        if (address(this).balance >= reimbursementAmount) {
            reimburseGas(reimbursementAmount);
        }
    }

    function reimburseGas(uint256 amount) private {
        if (address(this).balance >= amount) {
            payable(msg.sender).transfer(amount);
        }
    }


    receive() external payable {
    }
}