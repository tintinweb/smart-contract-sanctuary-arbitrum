// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.4;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IApeXPool.sol";

contract StakingQuery {
    IStakingPool public lpPool;
    IApeXPool public apeXPool;

    constructor(address _lpPool, address _apeXPool) {
        lpPool = IStakingPool(_lpPool);
        apeXPool = IApeXPool(_apeXPool);
    }

    function getWithdrawableLPs(
        address user
    ) external view returns (uint256[] memory depositIds, uint256[] memory amounts) {
        uint256 length = lpPool.getDepositsLength(user);
        depositIds = new uint256[](length);
        uint256 count;
        IStakingPool.Deposit memory _deposit;
        for (uint256 i = 0; i < length; i++) {
            _deposit = lpPool.getDeposit(user, i);
            if (
                _deposit.amount > 0 &&
                (_deposit.lockFrom == 0 || block.timestamp > _deposit.lockFrom + _deposit.lockDuration)
            ) {
                depositIds[count] = i;
                count += 1;
            }
        }

        amounts = new uint256[](count);
        uint256 tempId;
        for (uint256 j = 0; j < count; j++) {
            tempId = depositIds[j];
            amounts[j] = lpPool.getDeposit(user, tempId).amount;
        }

        for (uint256 z = count; z < length; z++) {
            delete depositIds[z];
        }
    }

    function getWithdrawableAPEX(
        address user
    ) external view returns (uint256[] memory depositIds, uint256[] memory amounts) {
        uint256 length = apeXPool.getDepositsLength(user);
        depositIds = new uint256[](length);
        uint256 count;
        IApeXPool.Deposit memory _deposit;
        for (uint256 i = 0; i < length; i++) {
            _deposit = apeXPool.getDeposit(user, i);
            if (
                _deposit.amount > 0 &&
                (_deposit.lockFrom == 0 || block.timestamp > _deposit.lockFrom + _deposit.lockDuration)
            ) {
                depositIds[count] = i;
                count += 1;
            }
        }

        amounts = new uint256[](count);
        uint256 tempId;
        for (uint256 j = 0; j < count; j++) {
            tempId = depositIds[j];
            amounts[j] = apeXPool.getDeposit(user, tempId).amount;
        }

        for (uint256 z = count; z < length; z++) {
            delete depositIds[z];
        }
    }

    function getWithdrawableEsAPEX(
        address user
    ) external view returns (uint256[] memory depositIds, uint256[] memory amounts) {
        uint256 length = apeXPool.getEsDepositsLength(user);
        depositIds = new uint256[](length);
        uint256 count;
        IApeXPool.Deposit memory _deposit;
        for (uint256 i = 0; i < length; i++) {
            _deposit = apeXPool.getEsDeposit(user, i);
            if (
                _deposit.amount > 0 &&
                (_deposit.lockFrom == 0 || block.timestamp > _deposit.lockFrom + _deposit.lockDuration)
            ) {
                depositIds[count] = i;
                count += 1;
            }
        }

        amounts = new uint256[](count);
        uint256 tempId;
        for (uint256 j = 0; j < count; j++) {
            tempId = depositIds[j];
            amounts[j] = apeXPool.getEsDeposit(user, tempId).amount;
        }

        for (uint256 z = count; z < length; z++) {
            delete depositIds[z];
        }
    }

    function getWithdrawableYields(
        address user
    ) external view returns (uint256[] memory yieldIds, uint256[] memory amounts) {
        uint256 length = apeXPool.getYieldsLength(user);
        yieldIds = new uint256[](length);
        uint256 count;
        IApeXPool.Yield memory _yield;
        for (uint256 i = 0; i < length; i++) {
            _yield = apeXPool.getYield(user, i);
            if (_yield.amount > 0 && block.timestamp > _yield.lockUntil) {
                yieldIds[count] = i;
                count += 1;
            }
        }

        amounts = new uint256[](count);
        uint256 tempId;
        for (uint256 j = 0; j < count; j++) {
            tempId = yieldIds[j];
            amounts[j] = apeXPool.getYield(user, tempId).amount;
        }

        for (uint256 z = count; z < length; z++) {
            delete yieldIds[z];
        }
    }

    function getForceWithdrawYieldIds(address user) external view returns (uint256[] memory yieldIds) {
        uint256 length = apeXPool.getYieldsLength(user);
        yieldIds = new uint256[](length);
        uint256 count;
        IApeXPool.Yield memory _yield;
        for (uint256 i = 0; i < length; i++) {
            _yield = apeXPool.getYield(user, i);
            if (_yield.amount > 0) {
                yieldIds[count] = i;
                count += 1;
            }
        }

        for (uint256 z = count; z < length; z++) {
            delete yieldIds[z];
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockDuration;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake slp/alp
        uint256  lastYieldRewardsPerWeight;
    }

    event BatchWithdraw(address indexed by, uint256[] _depositIds, uint256[] _depositAmounts);

    event Staked(address indexed to, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight);

    event UpdateStakeLock(address indexed by, uint256 depositId, uint256 lockFrom, uint256 lockUntil);

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

    function syncWeightPrice() external;

    function initialize(address _factory, address _poolToken, uint256 _initTime, uint256 _endTime) external;

    /// @notice Process yield reward (esApeX) of msg.sender
    function processRewards() external;

    /// @notice Stake poolToken
    /// @param amount poolToken's amount to stake.
    /// @param _lockDuration time to lock.
    function stake(uint256 amount, uint256 _lockDuration) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(uint256[] memory depositIds, uint256[] memory depositAmounts) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockDuration`
    /// @param depositId the deposit index.
    /// @param _lockDuration new lock time.
    function updateStakeLock(uint256 depositId, uint256 _lockDuration) external;
}

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
        uint256  lastYieldRewardsPerWeight;
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

    function syncWeightPrice() external;

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