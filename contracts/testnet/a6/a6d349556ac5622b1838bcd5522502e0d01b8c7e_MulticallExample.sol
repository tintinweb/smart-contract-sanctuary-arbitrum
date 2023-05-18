/**
 *Submitted for verification at Arbiscan on 2023-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract MulticallContract is Ownable {
    function executeCalls(address[] calldata targets, bytes[] calldata calls)
        external
        returns (bytes[] memory results)
    {
        require(targets.length == calls.length, "Invalid input: targets and calls lengths differ");

        results = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = targets[i].call(calls[i]);
            require(success, "Call execution failed");

            results[i] = result;
        }

        return results;
    }
}

contract ContractA {
    uint256 public contractAValue;

    function setContractAValue(uint256 newValue) external {
        contractAValue = newValue;
    }
}

contract ContractB {
    uint256 public contractBValue;

    function setContractBValue(uint256 newValue) external {
        contractBValue = newValue;
    }
}

contract MulticallExample is Ownable {
    ContractA public contractA;
    ContractB public contractB;

    constructor() {}

    function setAddresses(address contractAAddress, address contractBAddress) external onlyOwner {
        contractA = ContractA(contractAAddress);
        contractB = ContractB(contractBAddress);
    }

    function setValues(uint256 valueA, uint256 valueB) external onlyOwner {
        contractA.setContractAValue(valueA);
        contractB.setContractBValue(valueB);
    }
}