// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IOracle {

    /**
        @notice Fetches price of a given token in terms of ETH
        @param token Address of token
        @return price Price of token in terms of ETH
    */
    function getPrice(address token) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "src/core/IOracle.sol";

/**
    @title Zero Oracle
    @notice Oracle that returns price of token as zero
*/
contract ZeroOracle is IOracle {

    /// @inheritdoc IOracle
    function getPrice(address) external view returns (uint price) {}
}