// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

interface YourContract {
    function owner() external view returns (address);
    function getNumber() external view returns (int256);
}


/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage is YourContract {

    function owner() external pure returns (address _owner) {
        _owner = 0x47d80912400ef8f8224531EBEB1ce8f2ACf4b75a;
    }

    function getNumber() external pure returns (int256 _number) {
        _number = 1227;
    }
}