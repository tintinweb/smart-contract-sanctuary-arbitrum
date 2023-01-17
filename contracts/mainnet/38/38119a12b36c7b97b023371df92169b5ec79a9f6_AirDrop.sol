/**
 *Submitted for verification at Arbiscan on 2023-01-17
*/

// SPDX-License-Identifier: MIT

/*

-----------ArbiBonk-----------

AirDrop contract

*/

pragma solidity ^0.8.9;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract AirDrop is Ownable {

    constructor() Ownable() {}
    
    function AirDropTokens(IERC20 token, address[] memory _wallets, uint256 _amount) public onlyOwner {
        for (uint256 i = 0; i < _wallets.length; i++) {
            require(token.transferFrom(msg.sender, _wallets[i], _amount));
            }
        }
}