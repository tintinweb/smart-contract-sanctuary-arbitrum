// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITelefrensBondingCurve {
    struct FeeConfig {
        address protocolFeeDestination;
        uint256 subjectFeePercent;
        uint256 protocolFeePercent;
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) external view returns (uint256);

    function getFeeConfig() external view returns (FeeConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./telefrens-bonding-curve-interface.sol";

contract TelefrensBondingCurve is ITelefrensBondingCurve {
    string public constant packageName = "telefrens-bonding-curve";
    FeeConfig public config;

    constructor(FeeConfig memory _config) {
        config = _config;
    }

    function getPrice(
        uint256 supply,
        uint256 amount
    ) public pure returns (uint256) {
        uint256 sum1 = supply == 0
            ? 0
            : ((supply - 1) * (supply) * (2 * (supply - 1) + 1)) / 6;
        uint256 sum2 = supply == 0 && amount == 1
            ? 0
            : ((supply + amount - 1) *
                (supply + amount) *
                (2 * (supply + amount - 1) + 1)) / 6;
        uint256 summation = sum2 - sum1;
        return (summation * 1 ether) / 16000;
    }

    function getFeeConfig() external view returns (FeeConfig memory) {
        return config;
    }
}