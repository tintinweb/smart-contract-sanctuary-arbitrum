// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved

pragma solidity ^0.8.9;
import "./IAccessManager.sol";
import "./interfaces/IDCAStrategyManagerV3.sol";
import "./DCATypes.sol";

contract DefaultAccessManagerV3 is IAccessManager {
    enum AccessResult {
        OK,
        MAX_PARTICIPANTS_LIMIT_REACHED,
        WEEKLY_AMOUNT_TOO_LOW
    }

    error AccessDenied(uint256 poolId, AccessResult reason);

    event AccessGranted();

    IDCAStrategyManagerV3 dcaStrategyManager;

    constructor(address dcaStrategyManager_) {
        dcaStrategyManager = IDCAStrategyManagerV3(dcaStrategyManager_);
    }

    function hasAccess(
        uint256 strategyId,
        address user,
        uint256 weeklyAmount
    ) internal view returns (bool, AccessResult) {
        DCATypes.StrategyDataV3 memory strategyData = dcaStrategyManager
            .getStrategy(strategyId);
        DCATypes.UserStrategyData memory userStrategyData = dcaStrategyManager
            .getUserStrategy(user, strategyId);
        uint256 poolParticipantsLength = dcaStrategyManager
            .getStrategyParticipantsLength(strategyId);
        if (!userStrategyData.participating) {
            if (poolParticipantsLength >= strategyData.maxParticipants) {
                return (false, AccessResult.MAX_PARTICIPANTS_LIMIT_REACHED);
            }
        }
        if (strategyData.minWeeklyAmount > weeklyAmount) {
            return (false, AccessResult.WEEKLY_AMOUNT_TOO_LOW);
        }
        return (true, AccessResult.OK);
    }

    function hasAccess(
        uint256 strategyId,
        address user
    ) external view returns (bool) {
        (bool allowed, ) = hasAccess(strategyId, user, type(uint256).max);
        return allowed;
    }

    function participate(
        uint256 strategyId,
        address user,
        uint256 weeklyAmount
    ) external view {
        (bool allowed, AccessResult reason) = hasAccess(
            strategyId,
            user,
            weeklyAmount
        );
        if (!allowed) {
            revert AccessDenied(strategyId, reason);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved
pragma solidity ^0.8.9;

interface IAccessManager {
    function hasAccess(
        uint256 poolId,
        address user
    ) external view returns (bool);

    function participate(
        uint256 poolId,
        address user,
        uint256 weeklyInvestment
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved

pragma solidity ^0.8.9;

library DCATypes {
    enum ExecutionPhase {
        COLLECT,
        EXCHANGE,
        DISTRIBUTE,
        FINISH
    }

    struct StrategyExecutionData {
        bool isExecuting;
        ExecutionPhase currentPhase;
        int256 lastLoopIndex;
        uint256 totalCollectedToExchange;
        uint256 totalCollectedFee;
        uint256 received;
    }

    /*
     * @deprecated: new version of strategy is using path instead of fromAsset and toAsset
     */
    struct StrategyData {
        address fromAsset;
        address toAsset;
        address accessManager;
        address feeManager;
        uint256 totalCollectedFromAsset;
        uint256 totalReceivedToAsset;
        uint256 strategyFee; // percentage amount divided by 1000000
        uint24 uniswapFeeTier; // 3000 for 0.3% https://docs.uniswap.org/protocol/concepts/V3-overview/fees#pool-fees-tiers
        uint256 maxParticipants;
        uint256 minWeeklyAmount;
        uint256 lastExecuted;
        StrategyExecutionData executionData;
    }

    /*
     * @dev: Used for strategies on Uniswap V2 comatible DEXs
     */
    struct StrategyDataV2 {
        address[] path; // first is fromAsset, last toAsset
        address accessManager;
        address feeManager;
        uint256 totalCollectedFromAsset;
        uint256 totalReceivedToAsset;
        uint256 strategyFee; // percentage amount divided by 1000000
        uint256 maxParticipants;
        uint256 minWeeklyAmount;
        uint256 lastExecuted;
        StrategyExecutionData executionData;
    }
    /*
     * @dev: Used for strategies on Uniswap V3 comatible DEXs
     */
    struct StrategyDataV3 {
        bytes path;
        address fromAsset;
        address toAsset;
        address accessManager;
        address feeManager;
        uint256 totalCollectedFromAsset;
        uint256 totalReceivedToAsset;
        uint256 strategyFee; // percentage amount divided by 1000000
        uint256 maxParticipants;
        uint256 minWeeklyAmount;
        uint256 lastExecuted;
        StrategyExecutionData executionData;
    }

    struct UserStrategyData {
        uint256 totalCollectedFromAsset; // total "FromAsset" already collected by user in strategy
        uint256 totalReceivedToAsset; // total "ToAsset" received by user in strategy
        uint256 lastCollectedFromAssetAmount; // "FromAsset" collected during last DCA strategy execution
        uint256 totalCollectedFromAssetSinceStart; // total "FromAsset" already collected by user in strategy since start timestamp
        uint256 start; // participate timestamp (updates when updating weeklyAmount)
        uint256 weeklyAmount; // amount of "FromAsset" that will be converted to "ToAsset" within one week period
        bool participating; // is currently participating
        uint256 participantsIndex; // index in strategyParticipants array
    }

    struct StrategyInfoResponse {
        address fromAsset;
        address toAsset;
        address accessManager;
        address feeManager;
        uint256 totalCollectedFromAsset;
        uint256 totalReceivedToAsset;
        uint256 strategyFee; // percentage amount divided by 1000000
        uint24 uniswapFeeTier; // 3000 for 0.3% https://docs.uniswap.org/protocol/concepts/V3-overview/fees#pool-fees-tiers
        uint256 maxParticipants;
        uint256 minWeeklyAmount;
        uint256 lastExecuted;
        bool isExecuting;
        uint256 participantsAmount;
        DCATypes.UserStrategyData userStrategyData;
    }

    struct StrategyInfoResponseV2 {
        address[] path;
        address accessManager;
        address feeManager;
        uint256 totalCollectedFromAsset;
        uint256 totalReceivedToAsset;
        uint256 strategyFee; // percentage amount divided by 1000000
        uint256 maxParticipants;
        uint256 minWeeklyAmount;
        uint256 lastExecuted;
        bool isExecuting;
        uint256 participantsAmount;
        DCATypes.UserStrategyData userStrategyData;
    }

    struct StrategyInfoResponseV3 {
        bytes path;
        address fromAsset;
        address toAsset;
        address accessManager;
        address feeManager;
        uint256 totalCollectedFromAsset;
        uint256 totalReceivedToAsset;
        uint256 strategyFee; // percentage amount divided by 1000000
        uint256 maxParticipants;
        uint256 minWeeklyAmount;
        uint256 lastExecuted;
        bool isExecuting;
        uint256 participantsAmount;
        DCATypes.UserStrategyData userStrategyData;
    }
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved

pragma solidity 0.8.9;

import "../DCATypes.sol";

interface IDCAStrategyManagerV3 {
    function getStrategy(
        uint256 strategyId
    ) external view returns (DCATypes.StrategyDataV3 memory);

    function getUserStrategy(
        address user,
        uint256 strategyId
    ) external view returns (DCATypes.UserStrategyData memory);

    function getStrategyParticipantsLength(
        uint256 strategyId
    ) external view returns (uint256);
}