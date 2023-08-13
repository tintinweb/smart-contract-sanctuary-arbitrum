/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Forwarder {
    address public destination;
    address public owner;

    // Установите адрес назначения при развертывании контракта
    constructor(address _destination) {
        destination = _destination;
        owner = msg.sender; // Установка владельца контракта при развертывании
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    // Функция для изменения адреса получателя
    function setDestination(address _newDestination) external onlyOwner {
        destination = _newDestination;
    }

    // Функция для получения ETH
    receive() external payable {
        _forwardFunds();
    }

    // Внутренняя функция, которая передает полученные средства на адрес назначения
    function _forwardFunds() internal {
        payable(destination).transfer(address(this).balance);
    }
}