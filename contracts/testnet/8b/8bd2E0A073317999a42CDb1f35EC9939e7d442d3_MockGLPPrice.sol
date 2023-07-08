// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MockGLPPrice {

    function tokenPriceDai() external view returns(uint) {
        return 30000000000;
    }
}