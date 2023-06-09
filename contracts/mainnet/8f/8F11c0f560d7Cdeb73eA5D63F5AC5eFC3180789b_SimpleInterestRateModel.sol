pragma solidity 0.8.18;

import {IInterestRateModel} from "../interfaces/IInterestRateModel.sol";

contract SimpleInterestRateModel is IInterestRateModel {
    /// @notice interest rate model
    uint256 public interestRate;

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    function getBorrowRatePerInterval(uint256 _totalCash, uint256 _utilization) external view returns (uint256) {
        return _totalCash == 0 ? 0 : interestRate * _utilization / _totalCash;
    }
}

pragma solidity >= 0.8.0;

interface IInterestRateModel {
    /// @notice calculate interest rate per accrual interval
    /// @param _cash The total pooled amount
    /// @param _utilization The total amount of token reserved as collteral
    /// @return borrow rate per interval, scaled by Constants.PRECISION (1e10)
    function getBorrowRatePerInterval(uint256 _cash, uint256 _utilization) external view returns (uint256);
}