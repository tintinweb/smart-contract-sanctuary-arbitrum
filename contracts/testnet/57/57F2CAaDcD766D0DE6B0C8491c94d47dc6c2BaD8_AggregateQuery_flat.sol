/**
 *Submitted for verification at Arbiscan on 2022-04-26
*/

// Sources flattened with hardhat v2.8.0 https://hardhat.org


// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IApeXPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockDuration;
    }

    struct Yield {
        uint256 amount;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake ApeX
        Yield[] yields; //vest esApeX
        Deposit[] esDeposits; //stake esApeX
    }

    event BatchWithdraw(
        address indexed by,
        uint256[] _depositIds,
        uint256[] _depositAmounts,
        uint256[] _yieldIds,
        uint256[] _yieldAmounts,
        uint256[] _esDepositIds,
        uint256[] _esDepositAmounts
    );

    event ForceWithdraw(address indexed by, uint256[] yieldIds);

    event Staked(
        address indexed to,
        uint256 depositId,
        bool isEsApeX,
        uint256 amount,
        uint256 lockFrom,
        uint256 lockUntil
    );

    event YieldClaimed(address indexed by, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight);

    event UpdateStakeLock(address indexed by, uint256 depositId, bool isEsApeX, uint256 lockFrom, uint256 lockUntil);

    event MintEsApeX(address to, uint256 amount);

    /// @notice Get pool token of this core pool
    function poolToken() external view returns (address);

    function getStakeInfo(address _user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        );

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function getYield(address _user, uint256 _yieldId) external view returns (Yield memory);

    function getYieldsLength(address _user) external view returns (uint256);

    function getEsDeposit(address _user, uint256 _esDepositId) external view returns (Deposit memory);

    function getEsDepositsLength(address _user) external view returns (uint256);

    /// @notice Process yield reward (esApeX) of msg.sender
    function processRewards() external;

    /// @notice Stake apeX
    /// @param amount apeX's amount to stake.
    /// @param _lockDuration time to lock.
    function stake(uint256 amount, uint256 _lockDuration) external;

    function stakeEsApeX(uint256 amount, uint256 _lockDuration) external;

    function vest(uint256 amount) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory depositAmounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts,
        uint256[] memory esDepositIds,
        uint256[] memory esDepositAmounts
    ) external;

    /// @notice force withdraw locked reward
    /// @param depositIds the deposit index of locked reward.
    function forceWithdraw(uint256[] memory depositIds) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockDuration`
    /// @param depositId the deposit index.
    /// @param lockDuration new lock duration.
    /// @param isEsApeX update esApeX or apeX stake.
    function updateStakeLock(
        uint256 depositId,
        uint256 lockDuration,
        bool isEsApeX
    ) external;
}


// File contracts/staking/interfaces/AggregateQuery.sol

pragma solidity ^0.8.0;

contract AggregateQuery_flat {

    address apexPool;

    constructor(address apexPool_) {
        apexPool = apexPool_;
    }

    function getDeposits(address user_, uint256 offset, uint256 size) external view returns (IApeXPool.Deposit[] memory){
        uint256 len = IApeXPool(apexPool).getDepositsLength(user_);
        if (offset > len) {
            return new IApeXPool.Deposit[](0);
        }
        if (size >= len - offset) {
            size = len - offset;
        }

        IApeXPool.Deposit[] memory result = new IApeXPool.Deposit[](size);
        for (uint256 i = 0; i < len; i++) {
            result[i] = IApeXPool(apexPool).getDeposit(user_, offset + i);
        }
        return result;

    }
}