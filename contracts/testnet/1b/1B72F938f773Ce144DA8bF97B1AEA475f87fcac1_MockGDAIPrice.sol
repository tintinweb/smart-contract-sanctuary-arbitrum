// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MockGDAIPrice {

    function shareToAssetsPrice() external returns(uint) {
        return 1000000000000000000;
    }
}