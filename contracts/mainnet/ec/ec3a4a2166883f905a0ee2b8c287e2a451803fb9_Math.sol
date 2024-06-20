pragma solidity =0.8.19;

/// @author Elliot Friedman
library Math {
    /// @notice return the smallest of two numbers
    /// @param a first number
    /// @param b second number
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a > b ? b : a;
    }
}