/**
 * Hook to get gas spent in arbi transaction on the L1 (not otherwise available through gasleft())
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IGasHook} from "./IGasHook.sol";

contract ArbitrumL1GasHook is IGasHook {
    address internal constant ARB_GASINFO_PRECOMPILE =
        0x000000000000000000000000000000000000006C;

    function getAdditionalGasCost()
        external
        view
        returns (uint256 additionalCost)
    {
        (, bytes memory res) = ARB_GASINFO_PRECOMPILE.staticcall(
            abi.encodeWithSignature("getCurrentTxL1GasFees()")
        );

        additionalCost = abi.decode(res, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IGasHook
 * @author Ofir Smolinsky
 * @notice Defines an interface for a gas hook, simply returns all additional WEI that should be paid
 * by a vault (L2's specifically have different calcs for htat)
 */
interface IGasHook {
    function getAdditionalGasCost() external view returns (uint256 gasLeft);
}