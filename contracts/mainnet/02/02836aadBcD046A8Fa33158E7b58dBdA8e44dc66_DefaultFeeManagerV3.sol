// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved

pragma solidity ^0.8.9;
import "./IFeeManager.sol";
import "./interfaces/IDCAStrategyManagerV3.sol";
import "./DCATypes.sol";

contract DefaultFeeManagerV3 is IFeeManager {
    uint256 constant DENOMINATOR = 1000000;
    IDCAStrategyManagerV3 dcaStrategyManager;

    constructor(address dcaStrategyManager_) {
        dcaStrategyManager = IDCAStrategyManagerV3(dcaStrategyManager_);
    }

    function getFeePercentage(
        uint256 strategyId,
        address /*user*/
    ) public view returns (uint256) {
        DCATypes.StrategyDataV3 memory strategyData = dcaStrategyManager
            .getStrategy(strategyId);
        return strategyData.strategyFee;
    }

    function calculateFee(
        uint256 strategyId,
        address user,
        uint256 amount
    ) external view returns (uint256) {
        uint256 strategyFee = getFeePercentage(strategyId, user);
        uint256 fee = (amount * strategyFee) / DENOMINATOR;

        return fee;
    }
}

// SPDX-License-Identifier: UNLICENSED
// © Copyright AutoDCA. All Rights Reserved
pragma solidity ^0.8.9;

interface IFeeManager {
    // percentage amount divided by 1000000
    function getFeePercentage(
        uint256 poolId,
        address user
    ) external view returns (uint256);

    function calculateFee(
        uint256 poolId,
        address user,
        uint256 amount
    ) external returns (uint256);
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