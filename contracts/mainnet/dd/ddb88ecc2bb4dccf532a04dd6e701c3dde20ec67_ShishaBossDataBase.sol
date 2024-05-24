/**
 *Submitted for verification at Arbiscan.io on 2024-05-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ShishaBossDataBase is Ownable {
    mapping(uint128 phone_number => uint16) private _phone_number_balances;

    constructor()Ownable(_msgSender()) {}
    
    function balanceOf(uint128 phone_number) public view returns (uint16) {
        return _phone_number_balances[phone_number];
    }

    function award(uint128 phone_number, uint16 amount) public onlyOwner {
        _phone_number_balances[phone_number] += amount;
    }

    function charge(uint128 phone_number, uint16 amount) public onlyOwner {
        if (_phone_number_balances[phone_number] < amount) {
            revert("ShishaBossDataBase: insufficient balance");
        }
        _phone_number_balances[phone_number] -= amount;
    }
}