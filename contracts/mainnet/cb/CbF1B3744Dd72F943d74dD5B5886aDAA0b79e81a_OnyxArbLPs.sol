/**
 *Submitted for verification at Arbiscan on 2023-05-16
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

    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface MasterChef {
    function userInfo(uint256 pid, address)
        external
        view
        returns (uint256 deposits, uint256);
}

contract OnyxArbLPs {
    function balanceOf(address account) external view returns (uint256) {
        LPToken onyxETH = LPToken(0x135dd1c8Bb6610866419c06B8b61d6d5f345Bd38);
        uint lpBalance = onyxETH.balanceOf(account);
        (, uint reservedLPOnyx, ) = onyxETH.getReserves();

        return ((lpBalance * reservedLPOnyx) / onyxETH.totalSupply());
    }
}