// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./NoDelegateCall.sol";

contract FakeUniswapV3Pool is NoDelegateCall {
    address public token0;
    address owner;
    int56 public tickCumulatives1 = -2309888782959;
    int56 public tickCumulatives2 = -2310102904165;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function observe(uint32[] calldata secondsAgos)
        external
        view
        noDelegateCall
        returns (
            int56[] memory tickCumulatives,
            uint160[] memory secondsPerLiquidityCumulativeX128s
        )
    {
        tickCumulatives = new int56[](2);
        tickCumulatives[0] = tickCumulatives1;
        tickCumulatives[1] = tickCumulatives2;
        secondsPerLiquidityCumulativeX128s = new uint160[](1);
        secondsPerLiquidityCumulativeX128s[0] = secondsAgos[0];
    }

    function updateTickCum(int56[] memory tickCums) external ownerOnly {
        tickCumulatives1 = tickCums[0];
        tickCumulatives2 = tickCums[1];
    }
}