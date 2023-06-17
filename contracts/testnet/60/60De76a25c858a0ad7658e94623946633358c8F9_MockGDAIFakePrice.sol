// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MockGDAIFakePrice {

    uint p = 500000000000000000;

    function shareToAssetsPrice() external returns(uint) {
        return p;
    }

    function setPrice(uint _p) external {
        p = _p;
    }
}