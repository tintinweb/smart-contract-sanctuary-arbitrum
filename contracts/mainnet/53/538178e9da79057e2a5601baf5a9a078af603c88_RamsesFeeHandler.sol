/**
 *Submitted for verification at Arbiscan on 2023-05-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IVoter {
    function distribute(uint256 _start, uint256 _finish) external;

    function length() external view returns (uint256);
}

contract RamsesFeeHandler {
    IVoter voter = IVoter(0xAAA2564DEb34763E3d05162ed3f5C2658691f499);

    ///@dev skip DEI Gauges [32, 33, 81, 82]
    function safeDistributeGauges_ExcludingDEI() external {
        voter.distribute(0, 32);
        voter.distribute(34, 81);
        voter.distribute(83, (voter.length() - 1));
    }
}