/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface LPToken {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112 onyxReserved,
            uint32
        );

    function totalSupply() external view returns (uint256);
}

interface StakingPool {
    function userInfo(address)
        external
        view
        returns (uint256 deposits, uint256);
}

interface MasterChef {
    function userInfo(uint256 pid, address)
        external
        view
        returns (uint256 deposits, uint256);
}

contract OnyxLPs {
    function balanceOf(address account) external view returns (uint256) {
        StakingPool pool = StakingPool(
            0xc78E60dBdAF8CCA7aeAE2bBF19C3B9260B989F1E
        );
        MasterChef farm = MasterChef(
            0xF9C83fF6cf1A9bf2584aa2D00A7297cA8F845CcE
        );
        LPToken onyxETH = LPToken(0xB8fCc49ecC9206DaBb48B28ecbcfD31D5C6346D1);
        (uint poolDeposits, ) = pool.userInfo(account);
        (uint farmDeposits, ) = farm.userInfo(3, account);
        (, uint reservedLPOnyx, ) = onyxETH.getReserves();
        uint lpBalance = poolDeposits + farmDeposits;

        return ((lpBalance * reservedLPOnyx) / onyxETH.totalSupply());
    }
}