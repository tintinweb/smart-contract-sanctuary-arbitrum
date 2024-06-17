// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LendManagerUtils {
    function calculateInterest(uint256 time, uint256 interestAccrualRate, uint256 currentAmount)
        public
        pure
        returns (uint256, uint256)
    {
        uint256 compoundInterest = currentAmount * 1e8;

        for (uint256 i = 0; i < time; i++) {
            compoundInterest = (compoundInterest * (10 ** 8 + interestAccrualRate)) / 10 ** 8;
        }
        uint256 totalInterest = compoundInterest - currentAmount * 1e8;
        return (totalInterest / 1e8, compoundInterest / 1e8);
    }

    function timestampsToDays(uint256 startTimestamp, uint256 finishTimestamp) internal pure returns (uint256) {
        require(finishTimestamp >= startTimestamp, "Finish timestamp must be greater than start timestamp");
        uint256 timeInSeconds = (finishTimestamp - startTimestamp);
        uint256 time = (timeInSeconds / 86400);
        return time;
    }
}