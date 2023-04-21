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
    function userInfo(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256 deposits,
            uint256
        );
}

contract OnyxPowor {
    address public owner;
    address[] public stakingPools;

    constructor(address _owner) {
        owner = _owner;
    }

    function setStakingPools(address[] memory _stakingPools) external {
        require(msg.sender == owner, "Not owner");

        stakingPools = _stakingPools;
    }

    function onyxFromLPs(address account) public view returns (uint256) {
        // To get ONYX from LP position
        // 1. LP balanceOf / LP totalSupply = shared position
        // 2. ONYX reservedONYX = LP getReserves (, uint onyx)
        // 3. ONYX from position = reservedONYX * shared position
        LPToken onyxETH = LPToken(0xB8fCc49ecC9206DaBb48B28ecbcfD31D5C6346D1);
        uint lpBalance = onyxETH.balanceOf(account);
        (, uint reservedLPOnyx, ) = onyxETH.getReserves();

        return ((lpBalance * reservedLPOnyx) / onyxETH.totalSupply());
    }

    function stakedMasterOnyx(address account) public view returns (uint256) {
        MasterChef mc = MasterChef(0xF9C83fF6cf1A9bf2584aa2D00A7297cA8F845CcE);
        OnyxVault vault = OnyxVault(0x94D2D545bBcb82c18D9B6CA4fd7e07863cEcf8B2);

        (uint manualDeposits, ) = mc.userInfo(0, account); // Farm ZERO
        (, , uint autoDeposits, ) = vault.userInfo(account);

        return (manualDeposits + autoDeposits);
    }

    function poworOf(address account) external view returns (uint256) {
        ERC20 onyx = ERC20(0xB7cD6C8C4600AeD9985d2c0Eb174e0BEe56E8854);
        uint stakedOnyx = 0;

        // Loop over ONYX Staking pools and fetch user deposits
        for (uint16 i = 0; i < stakingPools.length; i++) {
            StakingPool pool = StakingPool(stakingPools[i]);
            (uint deposits, ) = pool.userInfo(account);
            stakedOnyx += deposits;
        }

        return (stakedOnyx +
            onyxFromLPs(account) +
            stakedMasterOnyx(account) +
            onyx.balanceOf(account));
    }
}