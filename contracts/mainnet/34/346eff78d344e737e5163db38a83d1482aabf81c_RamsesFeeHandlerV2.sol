/**
 *Submitted for verification at Arbiscan on 2023-05-31
*/

// SPDX-License-Identifier: MIT
// temporary ad-hoc fee handler for CL implementation
pragma solidity ^0.8.13;

interface IFeeCollector {
    function collectProtocolFees(address _pool) external;
}

contract RamsesFeeHandlerV2 {
    address public owner;
    address[] public v2Pools;
    address public constant feeCollector = 0xAA2ef8a3b34B414F8F7B47183971f18e4F367dC4;

    modifier onlyOwner() {
        require(msg.sender == owner, "!authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function push() external {
        for (uint256 i = 0; i < v2Pools.length; ++i) {
            IFeeCollector(feeCollector).collectProtocolFees(v2Pools[i]);
        }
    }

    function setPools(address[] calldata _newPools) external onlyOwner {
        v2Pools = _newPools;
    }
}