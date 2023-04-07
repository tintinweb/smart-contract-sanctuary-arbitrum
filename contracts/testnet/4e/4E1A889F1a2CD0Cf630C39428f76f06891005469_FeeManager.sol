// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IPairFactory {
    function acceptFeeManager() external;
}

contract FeeManager {
    IPairFactory public pairFactory;

    constructor(IPairFactory _pairFactory) {
        pairFactory = _pairFactory;
    }

    function acceptPermission() external {
        pairFactory.acceptFeeManager();
    }
}