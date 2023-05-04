// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    uint256 totalCoffee;
    uint256 totalGas;
    uint256 totalTasks;
    uint256 totalCustom;
    address payable public owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    event NewSupport(
        address indexed from,
        uint256 timestamp,
        string supportType,
        string message,
        string name
    );

    struct SupportItem {
        address sender;
        string supportType;
        string message;
        string name;
        uint256 timestamp;
    }

    SupportItem[] supportItems;

    function getAllSupports() public view returns (SupportItem[] memory) {
        return supportItems;
    }

    function getTotalItems()
        public
        view
        returns (uint256, uint256, uint256, uint256)
    {
        return (totalCoffee, totalGas, totalTasks, totalCustom);
    }

    function sendSupport(
        uint256 _supportType,
        string memory _message,
        string memory _name
    ) public payable {
        require(_supportType >= 1 && _supportType <= 3, "Invalid support type");

        if (_supportType == 1) {
            require(
                msg.value == 0.01 ether,
                "You need to pay 0.01 ether for Coffee"
            );
            totalCoffee += 1;
        } else if (_supportType == 2) {
            require(
                msg.value == 0.1 ether,
                "You need to pay 0.1 ether for Gas"
            );
            totalGas += 1;
        } else if (_supportType == 3) {
            require(msg.value == 1 ether, "You need to pay 1 ether for Task");
            totalTasks += 1;
        }

        string memory supportType = _supportTypeToString(_supportType);
        supportItems.push(
            SupportItem(msg.sender, supportType, _message, _name, block.timestamp)
        );

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Failed to send Ether to owner");

        emit NewSupport(msg.sender, block.timestamp, supportType, _message, _name);
    }

    function supportCustom(
        string memory _message,
        string memory _name,
        uint256 _customAmount
    ) public payable {
        require(
            _customAmount > 0,
            "You need to pay a custom amount greater than 0"
        );
        require(
            msg.value == _customAmount,
            "You need to pay the specified custom amount"
        );

        totalCustom += 1;

        string memory supportType = "Custom";
        supportItems.push(
            SupportItem(msg.sender, supportType, _message, _name, block.timestamp)
        );

        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Failed to send Ether to owner");

        emit NewSupport(msg.sender, block.timestamp, supportType, _message, _name);
    }

    function _supportTypeToString(uint256 _supportType)
        private
        pure
        returns (string memory)
    {
        if (_supportType == 1) {
            return "Coffee";
        } else if (_supportType == 2) {
            return "Gas";
        } else if (_supportType == 3) {
            return "Task";
        }
        return "";
    }
}