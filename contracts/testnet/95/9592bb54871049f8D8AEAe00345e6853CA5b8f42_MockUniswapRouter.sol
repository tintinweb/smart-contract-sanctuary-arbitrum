// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

/// @title IDexRouter
/// @author gotbit
interface IDexRouter {
    /// @dev Returns the address of the factory contract of the DEX.
    /// @return factory address of the factory
    function factory() external view returns (address factory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import './../interfaces/IDexRouter.sol';

contract MockUniswapRouter is IDexRouter {
    address public factory;

    constructor(address f) {
        factory = f;
    }

    function setFactory(address f) external {
        factory = f;
    }
}