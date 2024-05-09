// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

contract Loop {
    uint256 public maxLength;
    mapping (uint256 => uint256) public counters;

    function updateMaxLength(uint256 newMaxLength) public {
        maxLength = newMaxLength;
    }

    function aggregate() public view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < maxLength; i++) {
            count += 1;
        }

        return count;
    }

    function updateCounters() public {
        uint256 count = 0;

        for (uint256 i = 0; i < maxLength; i++) {
            counters[i] = i * 2;
        }
    }
}