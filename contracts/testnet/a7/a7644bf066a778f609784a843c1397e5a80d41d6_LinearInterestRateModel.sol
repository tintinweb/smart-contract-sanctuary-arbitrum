// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

import { IInterestRateModel, InterestRates } from "./IInterestRateModel.sol";

contract LinearInterestRateModel is IInterestRateModel {
    address public owner;
    uint256 public baseInterestRate;  // Initial interest rate
    uint256 public steeperSlopeInterestRate; // Interest rate after reaching target utilization
    uint256 public targetUtilization; // Target utilization rate

    constructor(
        uint256 _baseInterestRate,
        uint256 _steeperSlopeInterestRate,
        uint256 _targetUtilization
    ) {
        owner = msg.sender;
        baseInterestRate = _baseInterestRate;
        steeperSlopeInterestRate = _steeperSlopeInterestRate;
        targetUtilization = _targetUtilization;
    }

    // Calculate the interest rate based on utilization
    function calculateInterestRate(uint256 utilization) public view returns (uint256) {
        if (utilization <= targetUtilization) {
            // Linear increase until the target utilization is reached
            return baseInterestRate + ((utilization * (steeperSlopeInterestRate - baseInterestRate)) / targetUtilization);
        } else {
            // Linear increase at a steeper slope after reaching target utilization
            return steeperSlopeInterestRate + (((utilization - targetUtilization) * (2 * steeperSlopeInterestRate - baseInterestRate)) / (1e18 - targetUtilization));
        }
    }

    // Update the interest rate parameters by the owner
    function updateInterestRateParameters(
        uint256 _baseInterestRate,
        uint256 _steeperSlopeInterestRate,
        uint256 _targetUtilization
    ) public {
        require(msg.sender == owner, "Only the owner can update parameters");
        baseInterestRate = _baseInterestRate;
        targetUtilization = _targetUtilization;
        steeperSlopeInterestRate = _steeperSlopeInterestRate;
    }

    function calculateInterestRates(
        uint256, // liquidityAdded,
        uint256//  liquidityTaken
    ) external pure returns (InterestRates memory) {
        InterestRates memory rates = InterestRates({
            supplyRate: 0.55e18,
            borrowRate: 0.75e18
        });
        return rates;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.20;

struct InterestRates {
    uint256 supplyRate;
    uint256 borrowRate;
}

interface IInterestRateModel {
    function calculateInterestRate(uint256 utilization) external view returns (uint256);
    function calculateInterestRates(
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) external view returns (InterestRates memory);
}