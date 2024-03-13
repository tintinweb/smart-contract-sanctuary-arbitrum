// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CompoundInterest {
    mapping(uint256 => mapping(uint256 => uint256)) private _interestMultiplier;

    constructor() {
        for(uint i = 1; i <= 233; i++) {
            _interestMultiplier[1e16][i] = _calculateInterestMultiplier(1e16, i);
        }
    }

    // Function to get the multiplier for view purposes
    // Rate should be multiplied by 1e18... e.g. 1% would be 0.01 * 1e18 or 10000000000000000
    function getInterestMultiplierView(uint256 rate, uint256 periods) external view returns (uint256) {
        return _calculateInterestMultiplier(rate, periods);
    }

    // Function to get and store the multiplier
    // Rate should be multiplied by 1e18... e.g. 1% would be 0.01 * 1e18 or 10000000000000000
    function getInterestMultiplier(uint256 rate, uint256 periods) external returns (uint256) {
        uint256 multiplier = _calculateInterestMultiplier(rate, periods);
        _interestMultiplier[rate][periods] = multiplier;
        return multiplier;
    }

    // Internal function to calculate interest multiplier, optimized to start from the closest calculated period
    function _calculateInterestMultiplier(uint256 rate, uint256 periods) internal view returns (uint256) {
        // Check if it already exists
        uint256 multiplier = _interestMultiplier[rate][periods];
        if(multiplier != 0) return multiplier;
        // Check if there's a closer period to reduce iterations
        uint256 closestPeriod = _findClosestPeriod(rate, periods);
        multiplier = closestPeriod != 0 ? _interestMultiplier[rate][closestPeriod] : 1e18;
        rate += 1e18; // Adjust rate for calculation
        // Start calculation from the closest calculated period, if any
        for (uint256 i = closestPeriod; i < periods; i++) {
            multiplier = (multiplier * rate) / 1e18;
        }
        return multiplier;
    }

    // Helper function to find the closest period that has been calculated
    function _findClosestPeriod(uint256 rate, uint256 targetPeriod) internal view returns (uint256) {
        for (uint256 i = targetPeriod; i > 0; i--) {
            if (_interestMultiplier[rate][i] != 0) {
                return i;
            }
        }
        return 0;
    }
}