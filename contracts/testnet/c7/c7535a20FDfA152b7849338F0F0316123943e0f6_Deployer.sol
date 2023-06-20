/**
 *Submitted for verification at Arbiscan on 2023-06-20
*/

// Sources flattened with hardhat v2.15.0 https://hardhat.org

// File contracts/testSupport/TestCreate2.sol

/*
    Copyright 2022 JOJO Exchange
    SPDX-License-Identifier: BUSL-1.1
    ONLY FOR TEST
    DO NOT DEPLOY IN PRODUCTION ENV
*/

pragma solidity 0.8.9;

contract TestCreate2 {
    uint256 public price;

    function getMarkPrice() external view returns (uint256) {
        return price;
    }

    function setMarkPrice(uint256 newPrice) external {
        price = newPrice;
    }
}


// File contracts/testSupport/Deploy.sol


contract Deployer {

    function deploy(bytes32 _salt) public returns (address) {
        TestCreate2 c = new TestCreate2{salt: _salt}();
        return address(c);
    }

}