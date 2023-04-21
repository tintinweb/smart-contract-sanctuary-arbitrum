/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20 {
    function balanceOf(address) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface LPToken is ERC20 {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112 onyxReserved,
            uint32
        );
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

interface OnyxVault {
    function getPricePerFullShare() external view returns (uint256);

    function userInfo(address)
        external
        view
        returns (
            uint256 shares,
            uint256,
            uint256,
            uint256
        );
}

contract OnyxPowor {
    function poworOf(address account) external view returns (uint256) {
        ERC20 onyx = ERC20(0xB7cD6C8C4600AeD9985d2c0Eb174e0BEe56E8854);
        MasterChef mc = MasterChef(0xF9C83fF6cf1A9bf2584aa2D00A7297cA8F845CcE);
        OnyxVault autoVault = OnyxVault(
            0x94D2D545bBcb82c18D9B6CA4fd7e07863cEcf8B2
        );

        (uint manualDeposits, ) = mc.userInfo(0, account);
        (uint autoShares, , , ) = autoVault.userInfo(account);
        uint autoSharesPrice = autoVault.getPricePerFullShare();
        uint pricedAutoShares = autoShares * autoSharesPrice;

        // To get ONYX from LP position
        // 1. LP balanceOf / LP totalSupply = shared position
        // 2. ONYX reservedONYX = LP getReserves (, uint onyx)
        // 3. ONYX from position = reservedONYX * shared position
        LPToken onyxETH = LPToken(0xB8fCc49ecC9206DaBb48B28ecbcfD31D5C6346D1);
        uint sharedLPBalance = onyxETH.balanceOf(account) /
            onyxETH.totalSupply();
        (, uint reservedLPOnyx, ) = onyxETH.getReserves();
        uint onyxFromLPPosition = reservedLPOnyx * sharedLPBalance;

        return (onyxFromLPPosition +
            manualDeposits +
            pricedAutoShares +
            onyx.balanceOf(account));
    }
}