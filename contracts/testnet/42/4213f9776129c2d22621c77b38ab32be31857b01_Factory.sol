/**
 *Submitted for verification at Arbiscan on 2022-07-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8;

interface ICloneFactory {
    function clone(address prototype) external returns (address proxy);
}

interface IERC20init {
    function init(address owner, uint amount) external;
}

contract Factory {

    address clone;
    address erc20init;


    address[] ERC20Array;

    event NewERC20(address erc20, address owner);
    constructor(address _clone, address _erc20init){
        clone = _clone;
        erc20init = _erc20init;
    }

    function createERC20(address owner, uint amount) external returns (address newERC20){

        newERC20 = ICloneFactory(clone).clone(erc20init);

        IERC20init(newERC20).init(owner, amount);

        ERC20Array.push(newERC20);
        emit NewERC20(newERC20, msg.sender);

    }

    
}