// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

contract WithdrawalManager {
    event FeeUpdated(uint256 fee);
    event UpgradedTo(address newImplementation);
    event WithdrawalPeriodSet(uint256 periodLength);

    function setFeeInBps(uint256 fee) external {
        emit FeeUpdated(fee);
    }

    function upgradeTo(address newImplementation) external {
        emit UpgradedTo(newImplementation);
    }

    function setWithdrawalPeriod(uint256 periodLength) external {
        emit WithdrawalPeriodSet(periodLength);
    }
}