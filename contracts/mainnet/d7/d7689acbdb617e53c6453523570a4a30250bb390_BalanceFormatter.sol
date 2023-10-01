// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract BalanceFormatter {
    function formatAmount(address token, uint256 amount) public view returns (uint256 formattedAmount) {
        uint256 decimals = 10 ** IERC20(token).decimals();
        formattedAmount = amount * 1e18 / decimals;
    }

}