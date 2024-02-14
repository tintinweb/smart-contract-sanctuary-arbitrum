// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract OmniseaDN404Proxy {
    fallback() external payable {
        _delegate(address(0x9e02954F283BA8F8040FAE57620e6089ABCABAe2));
    }

    receive() external payable {
        _delegate(address(0x9e02954F283BA8F8040FAE57620e6089ABCABAe2));
    }

    function _delegate(address _proxyTo) internal {
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _proxyTo, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}