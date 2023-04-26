// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;


contract TestEvent  {
    event EventRecord(address indexed trader, uint val);

    function Record(uint n) external {
        require(n > 0 && n <= 10, "INVALID_PARAM");
        for (uint i = 1; i <= n; i++) {
            emit EventRecord(msg.sender, n);
        }
    }
}