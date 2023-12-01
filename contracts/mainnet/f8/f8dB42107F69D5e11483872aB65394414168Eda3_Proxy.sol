/**
 *Submitted for verification at Arbiscan.io on 2023-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Proxy {
    address internal _implementation;
    address internal _developer;

    modifier onlyDev() {require(msg.sender == _developer, "Only dev can perform this action");_;}

    constructor(address implementation_) {_implementation = implementation_; _developer = msg.sender;}

    function upgrade(address implementation_) external onlyDev {_implementation = implementation_;}

    function newDeveloper(address developer_) external onlyDev { _developer = developer_;}

    fallback() external payable {
        address _impl = _implementation;
        require(_impl != address(0));

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}