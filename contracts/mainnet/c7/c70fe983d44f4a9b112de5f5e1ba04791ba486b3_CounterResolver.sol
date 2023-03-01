/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

interface IWrapper {
    function getIdealRange() external view returns (int24 targetLower, int24 targetUpper, bool needsToUpdate);
    function updateRange() external returns (uint256 amount0, uint256 amount1, uint128 liquidityAdded);
}

contract CounterResolver {

    function checker(IWrapper wrapper)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        (, , canExec) = wrapper.getIdealRange();
        
        execPayload = abi.encodeCall(IWrapper.updateRange, ());
    }
}