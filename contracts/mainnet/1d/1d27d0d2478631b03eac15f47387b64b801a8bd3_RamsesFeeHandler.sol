/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ILens {
    function gaugesAddresses() external view returns (address[] memory);
}

interface IGauge {
    function claimFees() external;
}

contract RamsesFeeHandler {
    ILens lens = ILens(0xAD426AB13bcA2f0b8Cd87689F643718150Cedc12);

    function claimAllTheFees() external {
        address[] memory gauges = lens.gaugesAddresses();
        for (uint256 i = 0; i < gauges.length; ++i) {
            IGauge(gauges[i]).claimFees();
        }
    }

    function safeClaimAllTheFees() external {
        address[] memory gauges = lens.gaugesAddresses();
        for (uint256 i = 0; i < gauges.length; ++i) {
            try IGauge(gauges[i]).claimFees() {} catch {}
        }
    }

    function claimAllTheFeesInRange(uint256 _i, uint256 _x) external {
        address[] memory gauges = lens.gaugesAddresses();
        for (uint256 i = _i; i < _x; ++i) {
            IGauge(gauges[i]).claimFees();
        }
    }

    function numberOfGauges() external view returns (uint256) {
        return lens.gaugesAddresses().length;
    }
}