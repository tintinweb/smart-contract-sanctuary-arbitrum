// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OmniseaERC721PsiProxy {
    address private _proxy;

    constructor(address proxy_) {
        _proxy = proxy_;
    }

    fallback() external payable {
        _delegate(_proxy);
    }

    receive() external payable {
        _delegate(_proxy);
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