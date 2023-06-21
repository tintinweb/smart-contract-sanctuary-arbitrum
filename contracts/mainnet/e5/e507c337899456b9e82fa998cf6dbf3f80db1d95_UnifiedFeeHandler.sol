/**
 *Submitted for verification at Arbiscan on 2023-06-21
*/

/**
 *Submitted for verification at Arbiscan on 2023-06-13
 */

// SPDX-License-Identifier: MIT
// FeeHandler for RAMSES
pragma solidity ^0.8.13;

interface IFeeCollector {
    function collectProtocolFees(address _pool) external;
}

interface IVoter {
    function pools(uint256 _index) external view returns (address);

    function gauges(address _pool) external view returns (address);

    function length() external view returns (uint256);
}

interface IGauge {
    function claimFees() external;

    function rewards(uint256 _index) external view returns (address);
}

contract UnifiedFeeHandler {
    IVoter voter = IVoter(0xAAA2564DEb34763E3d05162ed3f5C2658691f499);
    address public owner;
    address public feeCollector = 0xAA2ef8a3b34B414F8F7B47183971f18e4F367dC4;

    //Only the DOG
    modifier onlyDOG() {
        require(msg.sender == owner, "!authorized");
        _;
    }

    //dead constructor
    constructor() {
        owner = msg.sender;
    }

    // Get the fees.
    function woof() external {
        claimAllTheFeesInRange(0, 32);
        claimAllTheFeesInRange(34, 81);
        claimAllTheFeesInRange(83, 119);
        claimAllTheFeesInRange(120, 122);
    }

    // Get the fees, rest
    function woof2() external {
        for (uint256 i = 122; i < voter.length(); ++i) {
            try IGauge(gauge_list(i)).claimFees() {} catch {
                try IFeeCollector(feeCollector).collectProtocolFees(voter.pools(i)) {} catch {
                    continue;
                }
            }
        }
    }

    function claimAllTheFeesInRange(uint256 _i, uint256 _x) internal {
        for (uint256 i = _i; i < _x; ++i) {
            IGauge(gauge_list(i)).claimFees();
        }
    }

    // New V2 fee collector
    function setNewFeeCollector(address _newFeeCollector) external onlyDOG {
        feeCollector = _newFeeCollector;
    }

    // New RAMSESLens
    function setNewLensAddress(address _newLensAddress) external onlyDOG {
        voter = IVoter(_newLensAddress);
    }

    function gauge_list(uint256 _index) internal view returns (address) {
        return (voter.gauges(voter.pools(_index)));
    }
}