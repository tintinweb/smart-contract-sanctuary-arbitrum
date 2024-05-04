// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.24;

interface versionedContract {
    function version() external view returns (uint256);
}

contract ZoomVersionView {
    function getVersion(address _contract) public view returns (uint256 result) {
        try versionedContract(_contract).version() returns (uint256 _result) {
            result = _result;
        } catch {
            result = 0;
        }
    }
}