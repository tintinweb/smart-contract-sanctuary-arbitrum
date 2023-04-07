// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPairFactory {
    function acceptFeeManager() external;
}

contract FeeManager {
    IPairFactory public pairFactory;
    address payable dead = payable(address(0x0)); 

    constructor(IPairFactory _pairFactory) {
        pairFactory = _pairFactory;
    }

    function acceptPermission() external {
        pairFactory.acceptFeeManager();
        selfdestruct(dead);
    }
}