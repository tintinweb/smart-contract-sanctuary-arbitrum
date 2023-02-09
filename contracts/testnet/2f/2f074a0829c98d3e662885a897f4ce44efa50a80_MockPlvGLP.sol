// SPDX-License-Identifier: BSD-3-Clause

//this contract mocks the necessary functions behind plvGLP and is for testing purposes ONLY!!
//Author: Lodestar Finance
pragma solidity ^0.8.17;

contract MockPlvGLP {
    uint256 _totalAssets = 4385690448959168297133346;

    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    function totalSupply() public pure returns (uint256) {
        uint256 totalSupply;
        totalSupply = 4335445707657153052302414;
        return totalSupply;
    }

    function changeTotalAssets(uint256 newTotalAssets) external {
        _totalAssets = newTotalAssets;
    }
}