// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ContractA {
    uint256 private _whiplash;

    function methodX() external {
        if (_whiplash == 1) {
            _whiplash += 1;
            // Perform actions in Contract A
        }
    }

    function getWhiplash() external view returns (uint256) {
        return _whiplash;
    }
}

contract Contract {
    address private _contractA;

    constructor(address contractA) {
        _contractA = contractA;
    }

    function methodQ() external {
        ContractA(_contractA).methodX();
    }
}