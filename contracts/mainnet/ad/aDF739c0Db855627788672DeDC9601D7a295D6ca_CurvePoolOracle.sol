/**
 *Submitted for verification at Arbiscan on 2023-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IStableSwap {
    function get_dy(
        int128 i, 
        int128 j, 
        int128 dx
    ) external view returns (uint256);
}

contract CurvePoolOracle {

    address public immutable pool;

    constructor(address _pool) {
        require(_pool != address(0), "CPO: invalid address");
        pool = _pool;
    }

    function getPrice() external view returns (uint256) {
        return IStableSwap(pool).get_dy(int128(1), int128(0), 1 ether);
    }
}