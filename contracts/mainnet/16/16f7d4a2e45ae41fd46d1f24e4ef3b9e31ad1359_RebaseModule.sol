// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import { AccessControl } from "../../base/AccessControl.sol";
import { ModeTicksCalculation } from "../../base/ModeTicksCalculation.sol";

import { ICLTBase } from "../../interfaces/ICLTBase.sol";
import { ICLTTwapQuoter } from "../../interfaces/ICLTTwapQuoter.sol";
import { IRebaseStrategy } from "../../interfaces/modules/IRebaseStrategy.sol";

/// @title A51 Finance Autonomous Liquidity Provision Rebase Module Contract
/// @author undefined_0x
/// @notice This contract is part of the A51 Finance platform, focusing on automated liquidity provision and rebalancing
/// strategies. The RebaseModule contract is responsible for validating and verifying the strategies before executing
/// them through CLTBase.
contract RebaseModule is ModeTicksCalculation, AccessControl, IRebaseStrategy {
    /// @notice The address of base contract
    ICLTBase public immutable cltBase;

    /// @notice The address of twap quoter
    ICLTTwapQuoter public twapQuoter;

    /// @notice Threshold for swaps in manual override
    uint256 public swapsThreshold = 5;

    // 0xca2ac00817703c8a34fa4f786a4f8f1f1eb57801f5369ebb12f510342c03f53b
    bytes32 public constant PRICE_PREFERENCE = keccak256("PRICE_PREFERENCE");
    // 0x697d458f1054678eeb971e50a66090683c55cfb1cab904d3050bdfe6ab249893
    bytes32 public constant REBASE_INACTIVITY = keccak256("REBASE_INACTIVITY");

    /// @notice Constructs the RebaseModule with the provided parameters.
    /// @param _baseContractAddress Address of the base contract.
    constructor(address _baseContractAddress, address _twapQuoter) AccessControl() {
        twapQuoter = ICLTTwapQuoter(_twapQuoter);
        cltBase = ICLTBase(payable(_baseContractAddress));
    }

    /// @notice Executes given strategies via bot.
    /// @dev Can only be called by any one.
    /// @param strategyIDs Array of strategy IDs to be executed.
    function executeStrategies(bytes32[] calldata strategyIDs) external nonReentrancy {
        checkStrategiesArray(strategyIDs);
        ExecutableStrategiesData[] memory _queue = checkAndProcessStrategies(strategyIDs);
        uint256 queueLength = _queue.length;

        for (uint256 i = 0; i < queueLength; i++) {
            uint256 rebaseCount;
            uint256 manualSwapsCount;
            uint256 lastUpdateTimeStamp;
            bool hasRebaseInactivity = false;

            ICLTBase.ShiftLiquidityParams memory params;

            (ICLTBase.StrategyKey memory key,,, bytes memory actionStatus,,,,,) =
                cltBase.strategies(_queue[i].strategyID);

            if (_queue[i].actionNames[0] == REBASE_INACTIVITY || _queue[i].actionNames[1] == REBASE_INACTIVITY) {
                hasRebaseInactivity = true;
                if (actionStatus.length > 0) {
                    (rebaseCount,, lastUpdateTimeStamp, manualSwapsCount) =
                        abi.decode(actionStatus, (uint256, bool, uint256, uint256));
                }
            }

            params.strategyId = _queue[i].strategyID;
            params.shouldMint = true;
            params.swapAmount = 0;

            uint256 queueActionNames = _queue[i].actionNames.length;
            for (uint256 j = 0; j < queueActionNames; j++) {
                if (_queue[i].actionNames[j] == bytes32(0) || _queue[i].actionNames[j] == REBASE_INACTIVITY) {
                    continue;
                }

                (int24 tickLower, int24 tickUpper) = getTicksForMode(key, _queue[i].mode);
                key.tickLower = tickLower;
                key.tickUpper = tickUpper;
                params.key = key;
                params.moduleStatus = hasRebaseInactivity
                    ? abi.encode(uint256(++rebaseCount), false, lastUpdateTimeStamp, manualSwapsCount)
                    : actionStatus;

                cltBase.shiftLiquidity(params);
            }
        }
    }

    /// @notice Provides functionality for executing and managing strategies manually with customizations.
    /// @dev This function updates strategy parameters, checks for permissions, and triggers liquidity shifts.
    function executeStrategy(ExectuteStrategyParams calldata executeParams) external nonReentrancy {
        (ICLTBase.StrategyKey memory key, address strategyOwner,, bytes memory actionStatus,,,,,) =
            cltBase.strategies(executeParams.strategyID);

        require(strategyOwner != address(0), "StrategyIdDonotExist");
        require(strategyOwner == _msgSender(), "InvalidCaller");

        key.tickLower = executeParams.tickLower;
        key.tickUpper = executeParams.tickUpper;

        bool isExited;
        uint256 rebaseCount;
        uint256 manualSwapsCount;
        uint256 lastUpdateTimeStamp;

        if (swapsThreshold != 0 && executeParams.swapAmount > 0) {
            if (actionStatus.length == 0) {
                lastUpdateTimeStamp = block.timestamp;
                manualSwapsCount = 1;
            } else {
                if (actionStatus.length == 64) {
                    (lastUpdateTimeStamp, manualSwapsCount) = _checkSwapsInADay(0, 0);
                } else {
                    (,, uint256 _lastUpdateTimeStamp, uint256 _manualSwapsCount) =
                        abi.decode(actionStatus, (uint256, bool, uint256, uint256));
                    (lastUpdateTimeStamp, manualSwapsCount) = _checkSwapsInADay(_lastUpdateTimeStamp, _manualSwapsCount);
                }
            }
        }

        ICLTBase.ShiftLiquidityParams memory params;
        params.key = key;
        params.strategyId = executeParams.strategyID;
        params.shouldMint = executeParams.shouldMint;
        params.zeroForOne = executeParams.zeroForOne;
        params.swapAmount = executeParams.swapAmount;
        params.sqrtPriceLimitX96 = executeParams.sqrtPriceLimitX96;

        isExited = !executeParams.shouldMint;

        if (actionStatus.length > 0) {
            if (actionStatus.length == 64) {
                (rebaseCount,) = abi.decode(actionStatus, (uint256, bool));
            } else {
                (rebaseCount,,,) = abi.decode(actionStatus, (uint256, bool, uint256, uint256));
            }
        }

        params.moduleStatus = abi.encode(rebaseCount, isExited, lastUpdateTimeStamp, manualSwapsCount);

        cltBase.shiftLiquidity(params);
    }

    /// @notice Checks and updates the swap count within a single day threshold.
    /// @dev This function is used to limit the number of manual swaps within a 24-hour period. Reverts if the number of
    /// swaps exceeds the set threshold within a day.
    /// @param lastUpdateTimeStamp The last time the swap count was updated.
    /// @param manualSwapsCount The current count of manual swaps.
    /// @return uint256 The updated time stamp.
    /// @return uint256 The updated swap count.
    function _checkSwapsInADay(
        uint256 lastUpdateTimeStamp,
        uint256 manualSwapsCount
    )
        internal
        view
        returns (uint256, uint256)
    {
        if (block.timestamp <= lastUpdateTimeStamp + 1 days) {
            require(manualSwapsCount < swapsThreshold, "SwapsThresholdExceeded");
            return (lastUpdateTimeStamp, manualSwapsCount += 1);
        } else {
            return (block.timestamp, manualSwapsCount = 1);
        }
    }

    /// @notice Computes ticks for a given mode.
    /// @dev Logic to adjust the ticks based on mode.
    /// @param key Strategy key.
    /// @param mode Mode to calculate ticks.
    /// @return tickLower and tickUpper values.
    function getTicksForMode(
        ICLTBase.StrategyKey memory key,
        uint256 mode
    )
        internal
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        int24 currentTick = twapQuoter.getTwap(key.pool);

        if (mode == 1) {
            (tickLower, tickUpper) = shiftLeft(key, currentTick);
        } else if (mode == 2) {
            (tickLower, tickUpper) = shiftRight(key, currentTick);
        } else if (mode == 3) {
            (tickLower, tickUpper) = shiftBothSide(key, currentTick);
        }
    }

    /// @notice Checks and processes strategies based on their validity.
    /// @dev Returns an array of valid strategies.
    /// @param strategyIDs Array of strategy IDs to check and process.
    /// @return ExecutableStrategiesData[] array containing valid strategies.
    function checkAndProcessStrategies(bytes32[] memory strategyIDs)
        internal
        returns (ExecutableStrategiesData[] memory)
    {
        ExecutableStrategiesData[] memory _queue = new ExecutableStrategiesData[](strategyIDs.length);
        uint256 validEntries = 0;
        uint256 strategyIdsLength = strategyIDs.length;

        for (uint256 i = 0; i < strategyIdsLength; i++) {
            ExecutableStrategiesData memory data = getStrategyData(strategyIDs[i]);
            if (data.strategyID != bytes32(0) && data.mode != 0) {
                _queue[validEntries++] = data;
            }
        }

        return _queue;
    }

    // /// @notice Retrieves strategy data based on strategy ID.
    /// @param strategyId The Data of the strategy to retrieve.
    /// @return ExecutableStrategiesData representing the retrieved strategy.
    function getStrategyData(bytes32 strategyId) internal returns (ExecutableStrategiesData memory) {
        (ICLTBase.StrategyKey memory key,, bytes memory actionsData, bytes memory actionStatus,,,,,) =
            cltBase.strategies(strategyId);

        ICLTBase.PositionActions memory strategyActionsData = abi.decode(actionsData, (ICLTBase.PositionActions));

        uint256 actionDataLength = strategyActionsData.rebaseStrategy.length;
        for (uint256 i = 0; i < actionDataLength; i++) {
            if (
                strategyActionsData.rebaseStrategy[i].actionName == REBASE_INACTIVITY
                    && !_checkRebaseInactivityStrategies(strategyActionsData.rebaseStrategy[i], actionStatus)
            ) {
                return ExecutableStrategiesData(bytes32(0), uint256(0), [bytes32(0), bytes32(0)]);
            }
        }

        ExecutableStrategiesData memory executableStrategiesData;
        uint256 count = 0;

        for (uint256 i = 0; i < actionDataLength; i++) {
            ICLTBase.StrategyPayload memory rebaseAction = strategyActionsData.rebaseStrategy[i];
            if (shouldAddToQueue(rebaseAction, key, strategyActionsData.mode)) {
                executableStrategiesData.actionNames[count++] = rebaseAction.actionName;
            }
        }

        if (count == 0) {
            return ExecutableStrategiesData(bytes32(0), uint256(0), [bytes32(0), bytes32(0)]);
        }

        executableStrategiesData.mode = strategyActionsData.mode;
        executableStrategiesData.strategyID = strategyId;
        return executableStrategiesData;
    }

    /// @notice Determines if a strategy should be added to the queue.
    /// @dev Checks the preference and other strategy details.
    /// @param rebaseAction  Data related to strategy actions.
    /// @param key Strategy key.
    /// @return bool indicating whether the strategy should be added to the queue.
    function shouldAddToQueue(
        ICLTBase.StrategyPayload memory rebaseAction,
        ICLTBase.StrategyKey memory key,
        uint256 mode
    )
        internal
        view
        returns (bool)
    {
        if (rebaseAction.actionName == PRICE_PREFERENCE) {
            return _checkRebasePreferenceStrategies(key, rebaseAction.data, mode);
        } else {
            return true;
        }
    }

    /// @notice Checks if rebase preference strategies are satisfied for the given key and action data.
    /// @param key The strategy key to be checked.
    /// @param actionsData The actions data that includes the rebase strategy data.
    /// @return true if the conditions are met, false otherwise.
    function _checkRebasePreferenceStrategies(
        ICLTBase.StrategyKey memory key,
        bytes memory actionsData,
        uint256 mode
    )
        internal
        view
        returns (bool)
    {
        (int24 lowerPreferenceDiff, int24 upperPreferenceDiff) = abi.decode(actionsData, (int24, int24));

        (int24 lowerPreferenceTick, int24 upperPreferenceTick) =
            _getPreferenceTicks(key, lowerPreferenceDiff, upperPreferenceDiff);

        int24 tick = twapQuoter.getTwap(key.pool);

        if (mode == 2 && tick > key.tickUpper || mode == 1 && tick < key.tickLower || mode == 3) {
            if (tick < lowerPreferenceTick || tick > upperPreferenceTick) {
                return true;
            }
        }

        return false;
    }

    /// @notice Checks if the rebase inactivity strategies are satisfied.
    /// @param strategyDetail The actions data that includes the rebase strategy data.
    /// @param actionStatus The status of the action.
    /// @return true if the conditions are met, false otherwise.
    function _checkRebaseInactivityStrategies(
        ICLTBase.StrategyPayload memory strategyDetail,
        bytes memory actionStatus
    )
        internal
        pure
        returns (bool)
    {
        uint256 preferredInActivity = abi.decode(strategyDetail.data, (uint256));

        if (actionStatus.length > 0) {
            (uint256 rebaseCount,) = abi.decode(actionStatus, (uint256, bool));
            if (rebaseCount > 0 && preferredInActivity == rebaseCount) {
                return false;
            }
        }

        return true;
    }

    /// @notice Validates the given strategy payload data for rebase strategies.
    /// @param actionsData The strategy payload to validate, containing action names and associated data.
    /// @return True if the strategy payload data is valid, otherwise it reverts.
    function checkInputData(ICLTBase.StrategyPayload memory actionsData) external pure override returns (bool) {
        bool hasDiffPreference = actionsData.actionName == PRICE_PREFERENCE;
        bool hasInActivity = actionsData.actionName == REBASE_INACTIVITY;

        if (hasDiffPreference && isNonZero(actionsData.data)) {
            (int24 lowerPreferenceDiff, int24 upperPreferenceDiff) = abi.decode(actionsData.data, (int24, int24));
            require(lowerPreferenceDiff > 0 && upperPreferenceDiff > 0, "InvalidPricePreferenceDifference");
            return true;
        }

        if (hasInActivity) {
            uint256 preferredInActivity = abi.decode(actionsData.data, (uint256));
            require(preferredInActivity > 0, "RebaseInactivityCannotBeZero");
            return true;
        }

        revert();
    }

    /// @notice Checks the bytes value is non zero or not.
    /// @param data bytes value to be checked.
    /// @return true if the value is nonzero.
    function isNonZero(bytes memory data) internal pure returns (bool) {
        uint256 dataLength = data.length;

        for (uint256 i = 0; i < dataLength; i++) {
            if (data[i] != bytes1(0)) {
                return true;
            }
        }

        return false;
    }

    /// @notice Checks the strategies array for validity.
    /// @param data An array of strategy IDs.
    /// @return true if the strategies array is valid.
    function checkStrategiesArray(bytes32[] memory data) public returns (bool) {
        require(data.length > 0, "StrategyIdsCannotBeEmpty");

        // check 0 strategyId
        uint256 dataLength = data.length;
        for (uint256 i = 0; i < dataLength; i++) {
            (, address strategyOwner,,,,,,,) = cltBase.strategies(data[i]);
            require(data[i] != bytes32(0) && strategyOwner != address(0), "InvalidStrategyId");

            // check duplicacy
            for (uint256 j = i + 1; j < data.length; j++) {
                require(data[i] != data[j], "DuplicateStrategyId");
            }
        }

        return true;
    }

    ///@notice Calculates the preference ticks based on the strategy key and the given preference differences.
    /// @dev  This function adjusts the given tick bounds (both lower and upper) based on a preference difference. The
    /// preference differences indicate by how much the ticks should be moved.
    /// @param _key The strategy key.
    /// @param lowerPreferenceDiff The lower preference difference.
    /// @param upperPreferenceDiff The upper preference difference.
    /// @return lowerPreferenceTick The calculated lower preference tick.
    /// @return upperPreferenceTick The calculated upper preference tick.
    function _getPreferenceTicks(
        ICLTBase.StrategyKey memory _key,
        int24 lowerPreferenceDiff,
        int24 upperPreferenceDiff
    )
        internal
        pure
        returns (int24 lowerPreferenceTick, int24 upperPreferenceTick)
    {
        lowerPreferenceTick = _key.tickLower - lowerPreferenceDiff;
        upperPreferenceTick = _key.tickUpper + upperPreferenceDiff;
    }

    function getPreferenceTicks(bytes32 strategyID)
        external
        returns (int24 lowerPreferenceTick, int24 upperPreferenceTick)
    {
        (ICLTBase.StrategyKey memory key,, bytes memory actionsData,,,,,,) = cltBase.strategies(strategyID);

        (int24 lowerPreferenceDiff, int24 upperPreferenceDiff) = abi.decode(actionsData, (int24, int24));

        (lowerPreferenceTick, upperPreferenceTick) = _getPreferenceTicks(key, lowerPreferenceDiff, upperPreferenceDiff);
    }

    /// @notice Updates the address twapQuoter.
    /// @param _twapQuoter The new address of twapQuoter
    function updateTwapQuoter(address _twapQuoter) external onlyOwner {
        twapQuoter = ICLTTwapQuoter(_twapQuoter);
    }

    /// @notice Updates the swaps threshold.
    /// @dev Reverts if the new threshold is less than zero.
    /// @param _newThreshold The new liquidity threshold value.
    function updateSwapsThreshold(uint256 _newThreshold) external onlyOperator {
        require(_newThreshold >= 0, "InvalidThreshold");
        swapsThreshold = _newThreshold;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title  AccessControl
/// @notice Contain helper methods for accessibility of functions
abstract contract AccessControl is Ownable, Pausable {
    uint32 private _unlocked = 1;

    mapping(address => bool) internal _operatorApproved;

    modifier onlyOperator() {
        require(_operatorApproved[msg.sender]);
        _;
    }

    modifier nonReentrancy() {
        require(_unlocked == 1);
        _unlocked = 2;
        _;
        _unlocked = 1;
    }

    constructor() Ownable() { }

    /// @notice Updates the status of given account as operator
    /// @dev Must be called by the current governance
    /// @param _operator Account to update status
    function toggleOperator(address _operator) external onlyOwner {
        _operatorApproved[_operator] = !_operatorApproved[_operator];
    }

    /// @notice Returns the status for a given operator that can execute operations
    /// @param _operator Account to check status
    function isOperator(address _operator) external view returns (bool) {
        return _operatorApproved[_operator];
    }

    /// @dev Triggers stopped state.
    function pause() external onlyOwner {
        _pause();
    }

    /// @dev Returns to normal state.
    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import { ICLTBase } from "../interfaces/ICLTBase.sol";

/// @title  ModeTicksCalculation
/// @notice Provides functions for computing ticks for basic modes of strategy
abstract contract ModeTicksCalculation {
    /// @notice Computes new tick lower and upper for the individual strategy downside
    /// @dev shift left will trail the strategy position closer to the cuurent tick, current tick will be one tick left
    /// from position
    /// @param key A51 strategy key details
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function shiftLeft(
        ICLTBase.StrategyKey memory key,
        int24 currentTick
    )
        internal
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        int24 tickSpacing = key.pool.tickSpacing();

        if (currentTick < key.tickLower) {
            (, currentTick,,,,,) = key.pool.globalState();

            currentTick = floorTick(currentTick, tickSpacing);

            int24 positionWidth = getPositionWidth(currentTick, key.tickLower, key.tickUpper);

            tickLower = currentTick + tickSpacing;
            tickUpper = floorTick(tickLower + positionWidth, tickSpacing);
        } else {
            revert();
        }
    }

    /// @notice Computes new tick lower and upper for the individual strategy upside
    /// @dev shift right will trail the strategy position closer to the cuurent tick, current tick will be one tick
    /// right from position
    /// @param key A51 strategy key details
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function shiftRight(
        ICLTBase.StrategyKey memory key,
        int24 currentTick
    )
        internal
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        int24 tickSpacing = key.pool.tickSpacing();

        if (currentTick > key.tickUpper) {
            (, currentTick,,,,,) = key.pool.globalState();

            currentTick = floorTick(currentTick, tickSpacing);

            int24 positionWidth = getPositionWidth(currentTick, key.tickLower, key.tickUpper);

            tickUpper = currentTick - tickSpacing;
            tickLower = floorTick(tickUpper - positionWidth, tickSpacing);
        } else {
            revert();
        }
    }

    /// @notice Computes new tick lower and upper for the individual strategy downside or upside
    /// @dev it will trail the strategy position closer to the cuurent tick
    /// @param key A51 strategy key details
    /// @return tickLower The lower tick of the range
    /// @return tickUpper The upper tick of the range
    function shiftBothSide(
        ICLTBase.StrategyKey memory key,
        int24 currentTick
    )
        internal
        view
        returns (int24 tickLower, int24 tickUpper)
    {
        if (currentTick < key.tickLower) return shiftLeft(key, currentTick);
        if (currentTick > key.tickUpper) return shiftRight(key, currentTick);

        revert();
    }

    /// @dev Rounds tick down towards negative infinity so that it's a multiple
    /// of `tickSpacing`
    /// @param tick The current tick of pool
    /// @param tickSpacing The tick spacing of pool
    /// @return floor value of tick
    function floorTick(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--;
        return compressed * tickSpacing;
    }

    /// @notice Returns the number of ticks between lower & upper tick
    /// @param currentTick The current tick of pool
    /// @param tickLower The lower tick of strategy
    /// @param tickUpper The upper tick of strategy
    /// @return width The total count of ticks
    function getPositionWidth(
        int24 currentTick,
        int24 tickLower,
        int24 tickUpper
    )
        internal
        pure
        returns (int24 width)
    {
        width = (currentTick - tickLower) + (tickUpper - currentTick);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import { IAlgebraPool } from "@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol";

interface ICLTBase {
    /// @param pool The Uniswap V3 pool
    /// @param tickLower The lower tick of the A51's LP position
    /// @param tickUpper The upper tick of the A51's LP position
    struct StrategyKey {
        IAlgebraPool pool;
        int24 tickLower;
        int24 tickUpper;
    }

    /// @param actionName Encoded name of whitelisted advance module
    /// @param data input as encoded data for selected module
    struct StrategyPayload {
        bytes32 actionName;
        bytes data;
    }

    /// @param mode ModuleId: one of four basic modes 1: left, 2: Right, 3: Both, 4: Static
    /// @param exitStrategy Array of whitelistd ids for advance mode exit strategy selection
    /// @param rebaseStrategy Array of whitelistd ids for advance mode rebase strategy selection
    /// @param liquidityDistribution Array of whitelistd ids for advance mode liquidity distribution selection
    struct PositionActions {
        uint256 mode;
        StrategyPayload[] exitStrategy;
        StrategyPayload[] rebaseStrategy;
        StrategyPayload[] liquidityDistribution;
    }

    /// @param fee0 Amount of fees0 collected by strategy
    /// @param fee1 Amount of fees1 collected by strategy
    /// @param balance0 Amount of token0 left in strategy that were not added in pool
    /// @param balance1 Amount of token1 left in strategy that were not added in pool
    /// @param totalShares Total no of shares minted for this A51's strategy
    /// @param uniswapLiquidity Total no of liquidity added on AMM for this strategy
    /// @param feeGrowthInside0LastX128 The fee growth of token0 collected per unit of liquidity for
    /// the entire life of the A51's position
    /// @param feeGrowthInside1LastX128 The fee growth of token1 collected per unit of liquidity for
    /// the entire life of the A51's position
    struct Account {
        uint256 fee0;
        uint256 fee1;
        uint256 balance0;
        uint256 balance1;
        uint256 totalShares;
        uint128 uniswapLiquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        uint256 feeGrowthOutside0LastX128;
        uint256 feeGrowthOutside1LastX128;
    }

    /// @param key A51 position's key details
    /// @param owner The address of the strategy owner
    /// @param actions Ids of all modes selected by the strategist encoded together in a single hash
    /// @param actionStatus The encoded data for each of the strategy to track any detail for futher actions
    /// @param isCompound Bool weather the strategy has compunding activated or not
    /// @param isPrivate Bool weather strategy is open for all users or not
    /// @param managementFee  The value of fee in percentage applied on strategy users liquidity by strategy owner
    /// @param performanceFee The value of fee in percentage applied on strategy users earned fee by strategy owner
    /// @param account Strategy accounts of balances and fee account details
    struct StrategyData {
        StrategyKey key;
        address owner;
        bytes actions;
        bytes actionStatus;
        bool isCompound;
        bool isPrivate;
        uint256 managementFee;
        uint256 performanceFee;
        Account account;
    }

    /// @notice Emitted when tokens are collected for a position NFT
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0Collected The amount of token0 owed to the position that was collected
    /// @param amount1Collected The amount of token1 owed to the position that was collected
    event Collect(uint256 tokenId, address recipient, uint256 amount0Collected, uint256 amount1Collected);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param recipient Recipient of liquidity
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event Deposit(
        uint256 indexed tokenId, address indexed recipient, uint256 liquidity, uint256 amount0, uint256 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param recipient Recipient of liquidity
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event Withdraw(
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 liquidity,
        uint256 amount0,
        uint256 amount1,
        uint256 fee0,
        uint256 fee1
    );

    /// @notice Emitted when strategy is created
    /// @param strategyId The strategy's key is a hash of a preimage composed by the owner & token ID
    event StrategyCreated(bytes32 indexed strategyId);

    /// @notice Emitted when data of strategy is updated
    /// @param strategyId Hash of strategy ID
    event StrategyUpdated(bytes32 indexed strategyId);

    /// @notice Emitted when fee of strategy is collected
    /// @param strategyId Hash of strategy ID
    /// @param fee0 Amount of fees0 collected by strategy
    /// @param fee1 Amount of fees1 collected by strategy
    event StrategyFee(bytes32 indexed strategyId, uint256 fee0, uint256 fee1);

    /// @notice Emitted when liquidity is increased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param share The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event PositionUpdated(uint256 indexed tokenId, uint256 share, uint256 amount0, uint256 amount1);

    /// @notice Emitted when strategy position is updated or shifted
    /// @param strategyId The strategy's key is a hash of a preimage composed by the owner & token ID
    /// @param isLiquidityMinted Bool whether the new liquidity position is minted in pool or HODL in contract
    /// @param zeroForOne Bool The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param swapAmount The amount of the swap, which implicitly configures the swap as exact input (positive), or
    /// exact output (negative)
    event LiquidityShifted(bytes32 indexed strategyId, bool isLiquidityMinted, bool zeroForOne, int256 swapAmount);

    /// @notice Emitted when collected fee of strategy is compounded
    /// @param strategyId Hash of strategy ID
    /// @param amount0 The amount of token0 that were compounded
    /// @param amount1 The amount of token1 that were compounded
    event FeeCompounded(bytes32 indexed strategyId, uint256 amount0, uint256 amount1);

    /// @notice Creates new LP strategy on AMM
    /// @dev Call this when the pool does exist and is initialized
    /// List of whitelisted IDs could be fetched by the modules contract for each basic & advance mode.
    /// If any ID is selected of any module it is mandatory to encode data for it then pass it to StrategyPayload.data
    /// @param key The params necessary to select a position, encoded as `StrategyKey` in calldata
    /// @param actions It is hash of all encoded data of whitelisted IDs which are being passed
    /// @param managementFee  The value of fee in percentage applied on strategy users liquidity by strategy owner
    /// @param performanceFee The value of fee in percentage applied on strategy users earned fee by strategy owner
    /// @param isCompound Bool weather the strategy should have compunding activated or not
    /// @param isPrivate Bool weather strategy is open for all users or not
    function createStrategy(
        StrategyKey calldata key,
        PositionActions calldata actions,
        uint256 managementFee,
        uint256 performanceFee,
        bool isCompound,
        bool isPrivate
    )
        external
        payable;

    /// @notice Returns the information about a strategy by the strategy's key
    /// @param strategyId The strategy's key is a hash of a preimage composed by the owner & token ID
    /// @return key A51 position's key details associated with this strategy
    /// owner The address of the strategy owner
    /// actions It is a hash of a preimage composed by all modes IDs selected by the strategist
    /// actionStatus It is a hash of a additional data of strategy for further required actions
    /// isCompound Bool weather the strategy has compunding activated or not
    /// isPrivate Bool weather strategy is open for all users or not
    /// managementFee The value of fee in percentage applied on strategy users liquidity by strategy owner
    /// performanceFee The value of fee in percentage applied on strategy users earned fee by strategy owner
    /// account Strategy values of balances and fee accounting details
    function strategies(bytes32 strategyId)
        external
        returns (
            StrategyKey memory key,
            address owner,
            bytes memory actions,
            bytes memory actionStatus,
            bool isCompound,
            bool isPrivate,
            uint256 managementFee,
            uint256 performanceFee,
            Account memory account
        );

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param positionId The ID of the token that represents the position
    /// @return strategyId strategy ID assigned to this token ID
    /// liquidityShare Shares assigned to this token ID
    /// feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 positionId)
        external
        returns (
            bytes32 strategyId,
            uint256 liquidityShare,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @param amount0Desired The desired amount of token0 to be spent,
    /// @param amount1Desired The desired amount of token1 to be spent,
    /// @param amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// @param amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// @param recipient account that should receive the shares in terms of A51's NFT
    struct DepositParams {
        bytes32 strategyId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
    }

    /// @notice Creates a new position wrapped in a A51 NFT
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function deposit(DepositParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint256 liquidity, uint256 amount0, uint256 amount1);

    /// @param params tokenId The ID of the token for which liquidity is being increased
    /// @param amount0Desired The desired amount of token0 to be spent,
    /// @param amount1Desired The desired amount of token1 to be spent,
    struct UpdatePositionParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params The params necessary to increase a position, encoded as `UpdatePositionParams` in calldata
    /// @dev This method can be used by by both compounding & non-compounding strategy positions
    /// @return share The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function updatePositionLiquidity(UpdatePositionParams calldata params)
        external
        payable
        returns (uint256 share, uint256 amount0, uint256 amount1);

    /// @param params tokenId The ID of the token for which liquidity is being decreased
    /// @param liquidity amount The amount by which liquidity will be decreased,
    /// @param recipient Recipient of tokens
    /// @param refundAsETH whether to recieve in WETH or ETH (only valid for WETH/ALT pairs)
    struct WithdrawParams {
        uint256 tokenId;
        uint256 liquidity;
        address recipient;
        bool refundAsETH;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params The params necessary to decrease a position, encoded as `WithdrawParams` in calldata
    /// @return amount0 Amount of token0 sent to recipient
    /// @return amount1 Amount of token1 sent to recipient
    function withdraw(WithdrawParams calldata params) external returns (uint256 amount0, uint256 amount1);

    /// @param recipient Recipient of tokens
    /// @param params tokenId The ID of the NFT for which tokens are being collected
    /// @param refundAsETH whether to recieve in WETH or ETH (only valid for WETH/ALT pairs)
    struct ClaimFeesParams {
        address recipient;
        uint256 tokenId;
        bool refundAsETH;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @dev Only non-compounding strategy users can call this
    /// @param params The params necessary to collect a position uncompounded fee, encoded as `ClaimFeesParams` in
    /// calldata
    function claimPositionFee(ClaimFeesParams calldata params) external;

    /// @param key A51 new position's key with updated ticks
    /// @param strategyId Id of A51's position for which ticks are being updated
    /// @param shouldMint Bool weather liquidity should be added on AMM or hold in contract
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param swapAmount The amount of the swap, which implicitly configures the swap as exact input (positive), or
    /// exact output (negative)
    /// @param moduleStatus The encoded data for each of the strategy to track any detail for futher actions
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    struct ShiftLiquidityParams {
        StrategyKey key;
        bytes32 strategyId;
        bool shouldMint;
        bool zeroForOne;
        int256 swapAmount;
        bytes moduleStatus;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Updates the strategy's liquidity accordingly w.r.t basic or advance module when it is activated
    /// @dev Only called by the whitlisted bot or owner of strategy
    /// @param params The params necessary to update a position, encoded as `ShiftLiquidityParams` in calldata
    function shiftLiquidity(ShiftLiquidityParams calldata params) external;
}

//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import { IAlgebraPool } from "@cryptoalgebra/core/contracts/interfaces/IAlgebraPool.sol";

interface ICLTTwapQuoter {
    /// @param twapDuration Period of time that we observe for price slippage
    /// @param maxTwapDeviation Maximum deviation of time waited avarage price in ticks
    struct PoolStrategy {
        uint32 twapDuration;
        int24 maxTwapDeviation;
    }

    function checkDeviation(IAlgebraPool pool) external;

    function twapDuration() external view returns (uint32);

    function getTwap(IAlgebraPool pool) external view returns (int24 twap);

    /// @notice Returns twap duration & max twap deviation for each pool
    function poolStrategy(address pool) external returns (uint32 twapDuration, int24 maxTwapDeviation);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

import "../ICLTBase.sol";

interface IRebaseStrategy {
    /// @param strategyId The strategy's key is a hash of a preimage composed by the owner & token ID
    /// @param mode ModuleId: one of four basic modes 1: left, 2: Right, 3: Both, 4: Static
    /// @param actionNames to hold multiple valid modes
    struct ExecutableStrategiesData {
        bytes32 strategyID;
        uint256 mode;
        bytes32[2] actionNames;
    }

    function checkInputData(ICLTBase.StrategyPayload memory data) external returns (bool);

    /// @param pool The Uniswap V3 pool
    /// @param strategyId The strategy's key is a hash of a preimage composed by the owner & token ID
    /// @param tickLower The lower tick of the A51's LP position
    /// @param tickUpper The upper tick of the A51's LP position
    /// @param tickLower The lower tick of the A51's LP position
    /// @param shouldMint Bool weather liquidity should be added on AMM or hold in contract
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param swapAmount The amount of the swap, which implicitly configures the swap as exact input (positive), or
    /// exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this

    struct ExectuteStrategyParams {
        IAlgebraPool pool;
        bytes32 strategyID;
        int24 tickLower;
        int24 tickUpper;
        bool shouldMint;
        bool zeroForOne;
        int256 swapAmount;
        uint160 sqrtPriceLimitX96;
    }

    event Executed(ExecutableStrategiesData[] strategyIds);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IAlgebraPoolImmutables.sol';
import './pool/IAlgebraPoolState.sol';
import './pool/IAlgebraPoolDerivedState.sol';
import './pool/IAlgebraPoolActions.sol';
import './pool/IAlgebraPoolPermissionedActions.sol';
import './pool/IAlgebraPoolEvents.sol';

/**
 * @title The interface for a Algebra Pool
 * @dev The pool interface is broken up into many smaller pieces.
 * Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPool is
  IAlgebraPoolImmutables,
  IAlgebraPoolState,
  IAlgebraPoolDerivedState,
  IAlgebraPoolActions,
  IAlgebraPoolPermissionedActions,
  IAlgebraPoolEvents
{
  // used only for combining interfaces
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '../IDataStorageOperator.sol';

/// @title Pool state that never changes
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolImmutables {
  /**
   * @notice The contract that stores all the timepoints and can perform actions with them
   * @return The operator address
   */
  function dataStorageOperator() external view returns (address);

  /**
   * @notice The contract that deployed the pool, which must adhere to the IAlgebraFactory interface
   * @return The contract address
   */
  function factory() external view returns (address);

  /**
   * @notice The first of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token0() external view returns (address);

  /**
   * @notice The second of the two tokens of the pool, sorted by address
   * @return The token contract address
   */
  function token1() external view returns (address);

  /**
   * @notice The pool tick spacing
   * @dev Ticks can only be used at multiples of this value
   * e.g.: a tickSpacing of 60 means ticks can be initialized every 60th tick, i.e., ..., -120, -60, 0, 60, 120, ...
   * This value is an int24 to avoid casting even though it is always positive.
   * @return The tick spacing
   */
  function tickSpacing() external view returns (int24);

  /**
   * @notice The maximum amount of position liquidity that can use any tick in the range
   * @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
   * also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
   * @return The max amount of liquidity per tick
   */
  function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolState {
  /**
   * @notice The globalState structure in the pool stores many values but requires only one slot
   * and is exposed as a single method to save gas when accessed externally.
   * @return price The current price of the pool as a sqrt(token1/token0) Q64.96 value;
   * Returns tick The current tick of the pool, i.e. according to the last tick transition that was run;
   * Returns This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(price) if the price is on a tick
   * boundary;
   * Returns fee The last pool fee value in hundredths of a bip, i.e. 1e-6;
   * Returns timepointIndex The index of the last written timepoint;
   * Returns communityFeeToken0 The community fee percentage of the swap fee in thousandths (1e-3) for token0;
   * Returns communityFeeToken1 The community fee percentage of the swap fee in thousandths (1e-3) for token1;
   * Returns unlocked Whether the pool is currently locked to reentrancy;
   */
  function globalState()
    external
    view
    returns (
      uint160 price,
      int24 tick,
      uint16 fee,
      uint16 timepointIndex,
      uint8 communityFeeToken0,
      uint8 communityFeeToken1,
      bool unlocked
    );

  /**
   * @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth0Token() external view returns (uint256);

  /**
   * @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
   * @dev This value can overflow the uint256
   */
  function totalFeeGrowth1Token() external view returns (uint256);

  /**
   * @notice The currently in range liquidity available to the pool
   * @dev This value has no relationship to the total liquidity across all ticks.
   * Returned value cannot exceed type(uint128).max
   */
  function liquidity() external view returns (uint128);

  /**
   * @notice Look up information about a specific tick in the pool
   * @dev This is a public structure, so the `return` natspec tags are omitted.
   * @param tick The tick to look up
   * @return liquidityTotal the total amount of position liquidity that uses the pool either as tick lower or
   * tick upper;
   * Returns liquidityDelta how much liquidity changes when the pool price crosses the tick;
   * Returns outerFeeGrowth0Token the fee growth on the other side of the tick from the current tick in token0;
   * Returns outerFeeGrowth1Token the fee growth on the other side of the tick from the current tick in token1;
   * Returns outerTickCumulative the cumulative tick value on the other side of the tick from the current tick;
   * Returns outerSecondsPerLiquidity the seconds spent per liquidity on the other side of the tick from the current tick;
   * Returns outerSecondsSpent the seconds spent on the other side of the tick from the current tick;
   * Returns initialized Set to true if the tick is initialized, i.e. liquidityTotal is greater than 0
   * otherwise equal to false. Outside values can only be used if the tick is initialized.
   * In addition, these values are only relative and must be used only in comparison to previous snapshots for
   * a specific position.
   */
  function ticks(int24 tick)
    external
    view
    returns (
      uint128 liquidityTotal,
      int128 liquidityDelta,
      uint256 outerFeeGrowth0Token,
      uint256 outerFeeGrowth1Token,
      int56 outerTickCumulative,
      uint160 outerSecondsPerLiquidity,
      uint32 outerSecondsSpent,
      bool initialized
    );

  /** @notice Returns 256 packed tick initialized boolean values. See TickTable for more information */
  function tickTable(int16 wordPosition) external view returns (uint256);

  /**
   * @notice Returns the information about a position by the position's key
   * @dev This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @param key The position's key is a hash of a preimage composed by the owner, bottomTick and topTick
   * @return liquidityAmount The amount of liquidity in the position;
   * Returns lastLiquidityAddTimestamp Timestamp of last adding of liquidity;
   * Returns innerFeeGrowth0Token Fee growth of token0 inside the tick range as of the last mint/burn/poke;
   * Returns innerFeeGrowth1Token Fee growth of token1 inside the tick range as of the last mint/burn/poke;
   * Returns fees0 The computed amount of token0 owed to the position as of the last mint/burn/poke;
   * Returns fees1 The computed amount of token1 owed to the position as of the last mint/burn/poke
   */
  function positions(bytes32 key)
    external
    view
    returns (
      uint128 liquidityAmount,
      uint32 lastLiquidityAddTimestamp,
      uint256 innerFeeGrowth0Token,
      uint256 innerFeeGrowth1Token,
      uint128 fees0,
      uint128 fees1
    );

  /**
   * @notice Returns data about a specific timepoint index
   * @param index The element of the timepoints array to fetch
   * @dev You most likely want to use #getTimepoints() instead of this method to get an timepoint as of some amount of time
   * ago, rather than at a specific index in the array.
   * This is a public mapping of structures, so the `return` natspec tags are omitted.
   * @return initialized whether the timepoint has been initialized and the values are safe to use;
   * Returns blockTimestamp The timestamp of the timepoint;
   * Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp;
   * Returns secondsPerLiquidityCumulative the seconds per in range liquidity for the life of the pool as of the timepoint timestamp;
   * Returns volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp;
   * Returns averageTick Time-weighted average tick;
   * Returns volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp;
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /**
   * @notice Returns the information about active incentive
   * @dev if there is no active incentive at the moment, virtualPool,endTimestamp,startTimestamp would be equal to 0
   * @return virtualPool The address of a virtual pool associated with the current active incentive
   */
  function activeIncentive() external view returns (address virtualPool);

  /**
   * @notice Returns the lock time for added liquidity
   */
  function liquidityCooldown() external view returns (uint32 cooldownInSeconds);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Pool state that is not stored
 * @notice Contains view functions to provide information about the pool that is computed rather than stored on the
 * blockchain. The functions here may have variable gas costs.
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolDerivedState {
  /**
   * @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
   * @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
   * the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
   * you must call it with secondsAgos = [3600, 0].
   * @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
   * log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
   * @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
   * @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
   * @return secondsPerLiquidityCumulatives Cumulative seconds per liquidity-in-range value as of each `secondsAgos`
   * from the current block timestamp
   * @return volatilityCumulatives Cumulative standard deviation as of each `secondsAgos`
   * @return volumePerAvgLiquiditys Cumulative swap volume per liquidity as of each `secondsAgos`
   */
  function getTimepoints(uint32[] calldata secondsAgos)
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /**
   * @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
   * @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
   * I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
   * snapshot is taken and the second snapshot is taken.
   * @param bottomTick The lower tick of the range
   * @param topTick The upper tick of the range
   * @return innerTickCumulative The snapshot of the tick accumulator for the range
   * @return innerSecondsSpentPerLiquidity The snapshot of seconds per liquidity for the range
   * @return innerSecondsSpent The snapshot of the number of seconds during which the price was in this range
   */
  function getInnerCumulatives(int24 bottomTick, int24 topTick)
    external
    view
    returns (
      int56 innerTickCumulative,
      uint160 innerSecondsSpentPerLiquidity,
      uint32 innerSecondsSpent
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolActions {
  /**
   * @notice Sets the initial price for the pool
   * @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
   * @param price the initial sqrt price of the pool as a Q64.96
   */
  function initialize(uint160 price) external;

  /**
   * @notice Adds liquidity for the given recipient/bottomTick/topTick position
   * @dev The caller of this method receives a callback in the form of IAlgebraMintCallback# AlgebraMintCallback
   * in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
   * on bottomTick, topTick, the amount of liquidity, and the current price.
   * @param sender The address which will receive potential surplus of paid tokens
   * @param recipient The address for which the liquidity will be created
   * @param bottomTick The lower tick of the position in which to add liquidity
   * @param topTick The upper tick of the position in which to add liquidity
   * @param amount The desired amount of liquidity to mint
   * @param data Any data that should be passed through to the callback
   * @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
   * @return liquidityActual The actual minted amount of liquidity
   */
  function mint(
    address sender,
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount,
    bytes calldata data
  )
    external
    returns (
      uint256 amount0,
      uint256 amount1,
      uint128 liquidityActual
    );

  /**
   * @notice Collects tokens owed to a position
   * @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
   * Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
   * amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
   * actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
   * @param recipient The address which should receive the fees collected
   * @param bottomTick The lower tick of the position for which to collect fees
   * @param topTick The upper tick of the position for which to collect fees
   * @param amount0Requested How much token0 should be withdrawn from the fees owed
   * @param amount1Requested How much token1 should be withdrawn from the fees owed
   * @return amount0 The amount of fees collected in token0
   * @return amount1 The amount of fees collected in token1
   */
  function collect(
    address recipient,
    int24 bottomTick,
    int24 topTick,
    uint128 amount0Requested,
    uint128 amount1Requested
  ) external returns (uint128 amount0, uint128 amount1);

  /**
   * @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
   * @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
   * @dev Fees must be collected separately via a call to #collect
   * @param bottomTick The lower tick of the position for which to burn liquidity
   * @param topTick The upper tick of the position for which to burn liquidity
   * @param amount How much liquidity to burn
   * @return amount0 The amount of token0 sent to the recipient
   * @return amount1 The amount of token1 sent to the recipient
   */
  function burn(
    int24 bottomTick,
    int24 topTick,
    uint128 amount
  ) external returns (uint256 amount0, uint256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0
   * @dev The caller of this method receives a callback in the form of IAlgebraSwapCallback# AlgebraSwapCallback
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swap(
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Swap token0 for token1, or token1 for token0 (tokens that have fee on transfer)
   * @dev The caller of this method receives a callback in the form of I AlgebraSwapCallback# AlgebraSwapCallback
   * @param sender The address called this function (Comes from the Router)
   * @param recipient The address to receive the output of the swap
   * @param zeroToOne The direction of the swap, true for token0 to token1, false for token1 to token0
   * @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
   * @param limitSqrtPrice The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
   * value after the swap. If one for zero, the price cannot be greater than this value after the swap
   * @param data Any data to be passed through to the callback. If using the Router it should contain
   * SwapRouter#SwapCallbackData
   * @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
   * @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
   */
  function swapSupportingFeeOnInputTokens(
    address sender,
    address recipient,
    bool zeroToOne,
    int256 amountSpecified,
    uint160 limitSqrtPrice,
    bytes calldata data
  ) external returns (int256 amount0, int256 amount1);

  /**
   * @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
   * @dev The caller of this method receives a callback in the form of IAlgebraFlashCallback# AlgebraFlashCallback
   * @dev All excess tokens paid in the callback are distributed to liquidity providers as an additional fee. So this method can be used
   * to donate underlying tokens to currently in-range liquidity providers by calling with 0 amount{0,1} and sending
   * the donation amount(s) from the callback
   * @param recipient The address which will receive the token0 and token1 amounts
   * @param amount0 The amount of token0 to send
   * @param amount1 The amount of token1 to send
   * @param data Any data to be passed through to the callback
   */
  function flash(
    address recipient,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title Permissioned pool actions
 * @notice Contains pool methods that may only be called by the factory owner or tokenomics
 * @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
 * https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
 */
interface IAlgebraPoolPermissionedActions {
  /**
   * @notice Set the community's % share of the fees. Cannot exceed 25% (250)
   * @param communityFee0 new community fee percent for token0 of the pool in thousandths (1e-3)
   * @param communityFee1 new community fee percent for token1 of the pool in thousandths (1e-3)
   */
  function setCommunityFee(uint8 communityFee0, uint8 communityFee1) external;

  /**
   * @notice Sets an active incentive
   * @param virtualPoolAddress The address of a virtual pool associated with the incentive
   */
  function setIncentive(address virtualPoolAddress) external;

  /**
   * @notice Sets new lock time for added liquidity
   * @param newLiquidityCooldown The time in seconds
   */
  function setLiquidityCooldown(uint32 newLiquidityCooldown) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @dev Credit to Uniswap Labs under GPL-2.0-or-later license:
/// https://github.com/Uniswap/v3-core/tree/main/contracts/interfaces
interface IAlgebraPoolEvents {
  /**
   * @notice Emitted exactly once by a pool when #initialize is first called on the pool
   * @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
   * @param price The initial sqrt price of the pool, as a Q64.96
   * @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
   */
  event Initialize(uint160 price, int24 tick);

  /**
   * @notice Emitted when liquidity is minted for a given position
   * @param sender The address that minted the liquidity
   * @param owner The owner of the position and recipient of any minted liquidity
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity minted to the position range
   * @param amount0 How much token0 was required for the minted liquidity
   * @param amount1 How much token1 was required for the minted liquidity
   */
  event Mint(
    address sender,
    address indexed owner,
    int24 indexed bottomTick,
    int24 indexed topTick,
    uint128 liquidityAmount,
    uint256 amount0,
    uint256 amount1
  );

  /**
   * @notice Emitted when fees are collected by the owner of a position
   * @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
   * @param owner The owner of the position for which fees are collected
   * @param recipient The address that received fees
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param amount0 The amount of token0 fees collected
   * @param amount1 The amount of token1 fees collected
   */
  event Collect(address indexed owner, address recipient, int24 indexed bottomTick, int24 indexed topTick, uint128 amount0, uint128 amount1);

  /**
   * @notice Emitted when a position's liquidity is removed
   * @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
   * @param owner The owner of the position for which liquidity is removed
   * @param bottomTick The lower tick of the position
   * @param topTick The upper tick of the position
   * @param liquidityAmount The amount of liquidity to remove
   * @param amount0 The amount of token0 withdrawn
   * @param amount1 The amount of token1 withdrawn
   */
  event Burn(address indexed owner, int24 indexed bottomTick, int24 indexed topTick, uint128 liquidityAmount, uint256 amount0, uint256 amount1);

  /**
   * @notice Emitted by the pool for any swaps between token0 and token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the output of the swap
   * @param amount0 The delta of the token0 balance of the pool
   * @param amount1 The delta of the token1 balance of the pool
   * @param price The sqrt(price) of the pool after the swap, as a Q64.96
   * @param liquidity The liquidity of the pool after the swap
   * @param tick The log base 1.0001 of price of the pool after the swap
   */
  event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 price, uint128 liquidity, int24 tick);

  /**
   * @notice Emitted by the pool for any flashes of token0/token1
   * @param sender The address that initiated the swap call, and that received the callback
   * @param recipient The address that received the tokens from flash
   * @param amount0 The amount of token0 that was flashed
   * @param amount1 The amount of token1 that was flashed
   * @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
   * @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
   */
  event Flash(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1, uint256 paid0, uint256 paid1);

  /**
   * @notice Emitted when the community fee is changed by the pool
   * @param communityFee0New The updated value of the token0 community fee percent
   * @param communityFee1New The updated value of the token1 community fee percent
   */
  event CommunityFee(uint8 communityFee0New, uint8 communityFee1New);

  /**
   * @notice Emitted when new activeIncentive is set
   * @param virtualPoolAddress The address of a virtual pool associated with the current active incentive
   */
  event Incentive(address indexed virtualPoolAddress);

  /**
   * @notice Emitted when the fee changes
   * @param fee The value of the token fee
   */
  event Fee(uint16 fee);

  /**
   * @notice Emitted when the LiquidityCooldown changes
   * @param liquidityCooldown The value of locktime for added liquidity
   */
  event LiquidityCooldown(uint32 liquidityCooldown);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma abicoder v2;

import '../libraries/AdaptiveFee.sol';

interface IDataStorageOperator {
  event FeeConfiguration(AdaptiveFee.Configuration feeConfig);

  /**
   * @notice Returns data belonging to a certain timepoint
   * @param index The index of timepoint in the array
   * @dev There is more convenient function to fetch a timepoint: observe(). Which requires not an index but seconds
   * @return initialized Whether the timepoint has been initialized and the values are safe to use,
   * blockTimestamp The timestamp of the observation,
   * tickCumulative The tick multiplied by seconds elapsed for the life of the pool as of the timepoint timestamp,
   * secondsPerLiquidityCumulative The seconds per in range liquidity for the life of the pool as of the timepoint timestamp,
   * volatilityCumulative Cumulative standard deviation for the life of the pool as of the timepoint timestamp,
   * averageTick Time-weighted average tick,
   * volumePerLiquidityCumulative Cumulative swap volume per liquidity for the life of the pool as of the timepoint timestamp
   */
  function timepoints(uint256 index)
    external
    view
    returns (
      bool initialized,
      uint32 blockTimestamp,
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint88 volatilityCumulative,
      int24 averageTick,
      uint144 volumePerLiquidityCumulative
    );

  /// @notice Initialize the dataStorage array by writing the first slot. Called once for the lifecycle of the timepoints array
  /// @param time The time of the dataStorage initialization, via block.timestamp truncated to uint32
  /// @param tick Initial tick
  function initialize(uint32 time, int24 tick) external;

  /// @dev Reverts if an timepoint at or before the desired timepoint timestamp does not exist.
  /// 0 may be passed as `secondsAgo' to return the current cumulative values.
  /// If called with a timestamp falling between two timepoints, returns the counterfactual accumulator values
  /// at exactly the timestamp between the two timepoints.
  /// @param time The current block timestamp
  /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulative The cumulative tick since the pool was first initialized, as of `secondsAgo`
  /// @return secondsPerLiquidityCumulative The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
  /// @return volatilityCumulative The cumulative volatility value since the pool was first initialized, as of `secondsAgo`
  /// @return volumePerAvgLiquidity The cumulative volume per liquidity value since the pool was first initialized, as of `secondsAgo`
  function getSingleTimepoint(
    uint32 time,
    uint32 secondsAgo,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56 tickCumulative,
      uint160 secondsPerLiquidityCumulative,
      uint112 volatilityCumulative,
      uint256 volumePerAvgLiquidity
    );

  /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
  /// @dev Reverts if `secondsAgos` > oldest timepoint
  /// @param time The current block.timestamp
  /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an timepoint
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return tickCumulatives The cumulative tick since the pool was first initialized, as of each `secondsAgo`
  /// @return secondsPerLiquidityCumulatives The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
  /// @return volatilityCumulatives The cumulative volatility values since the pool was first initialized, as of each `secondsAgo`
  /// @return volumePerAvgLiquiditys The cumulative volume per liquidity values since the pool was first initialized, as of each `secondsAgo`
  function getTimepoints(
    uint32 time,
    uint32[] memory secondsAgos,
    int24 tick,
    uint16 index,
    uint128 liquidity
  )
    external
    view
    returns (
      int56[] memory tickCumulatives,
      uint160[] memory secondsPerLiquidityCumulatives,
      uint112[] memory volatilityCumulatives,
      uint256[] memory volumePerAvgLiquiditys
    );

  /// @notice Returns average volatility in the range from time-WINDOW to time
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return TWVolatilityAverage The average volatility in the recent range
  /// @return TWVolumePerLiqAverage The average volume per liquidity in the recent range
  function getAverages(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint112 TWVolatilityAverage, uint256 TWVolumePerLiqAverage);

  /// @notice Writes an dataStorage timepoint to the array
  /// @dev Writable at most once per block. Index represents the most recently written element. index must be tracked externally.
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param blockTimestamp The timestamp of the new timepoint
  /// @param tick The active tick at the time of the new timepoint
  /// @param liquidity The total in-range liquidity at the time of the new timepoint
  /// @param volumePerLiquidity The gmean(volumes)/liquidity at the time of the new timepoint
  /// @return indexUpdated The new index of the most recently written element in the dataStorage array
  function write(
    uint16 index,
    uint32 blockTimestamp,
    int24 tick,
    uint128 liquidity,
    uint128 volumePerLiquidity
  ) external returns (uint16 indexUpdated);

  /// @notice Changes fee configuration for the pool
  function changeFeeConfiguration(AdaptiveFee.Configuration calldata feeConfig) external;

  /// @notice Calculates gmean(volume/liquidity) for block
  /// @param liquidity The current in-range pool liquidity
  /// @param amount0 Total amount of swapped token0
  /// @param amount1 Total amount of swapped token1
  /// @return volumePerLiquidity gmean(volume/liquidity) capped by 100000 << 64
  function calculateVolumePerLiquidity(
    uint128 liquidity,
    int256 amount0,
    int256 amount1
  ) external pure returns (uint128 volumePerLiquidity);

  /// @return windowLength Length of window used to calculate averages
  function window() external view returns (uint32 windowLength);

  /// @notice Calculates fee based on combination of sigmoids
  /// @param time The current block.timestamp
  /// @param tick The current tick
  /// @param index The index of the timepoint that was most recently written to the timepoints array
  /// @param liquidity The current in-range pool liquidity
  /// @return fee The fee in hundredths of a bip, i.e. 1e-6
  function getFee(
    uint32 time,
    int24 tick,
    uint16 index,
    uint128 liquidity
  ) external view returns (uint16 fee);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './Constants.sol';

/// @title AdaptiveFee
/// @notice Calculates fee based on combination of sigmoids
library AdaptiveFee {
  // alpha1 + alpha2 + baseFee must be <= type(uint16).max
  struct Configuration {
    uint16 alpha1; // max value of the first sigmoid
    uint16 alpha2; // max value of the second sigmoid
    uint32 beta1; // shift along the x-axis for the first sigmoid
    uint32 beta2; // shift along the x-axis for the second sigmoid
    uint16 gamma1; // horizontal stretch factor for the first sigmoid
    uint16 gamma2; // horizontal stretch factor for the second sigmoid
    uint32 volumeBeta; // shift along the x-axis for the outer volume-sigmoid
    uint16 volumeGamma; // horizontal stretch factor the outer volume-sigmoid
    uint16 baseFee; // minimum possible fee
  }

  /// @notice Calculates fee based on formula:
  /// baseFee + sigmoidVolume(sigmoid1(volatility, volumePerLiquidity) + sigmoid2(volatility, volumePerLiquidity))
  /// maximum value capped by baseFee + alpha1 + alpha2
  function getFee(
    uint88 volatility,
    uint256 volumePerLiquidity,
    Configuration memory config
  ) internal pure returns (uint16 fee) {
    uint256 sumOfSigmoids = sigmoid(volatility, config.gamma1, config.alpha1, config.beta1) +
      sigmoid(volatility, config.gamma2, config.alpha2, config.beta2);

    if (sumOfSigmoids > type(uint16).max) {
      // should be impossible, just in case
      sumOfSigmoids = type(uint16).max;
    }

    return uint16(config.baseFee + sigmoid(volumePerLiquidity, config.volumeGamma, uint16(sumOfSigmoids), config.volumeBeta)); // safe since alpha1 + alpha2 + baseFee _must_ be <= type(uint16).max
  }

  /// @notice calculates α / (1 + e^( (β-x) / γ))
  /// that is a sigmoid with a maximum value of α, x-shifted by β, and stretched by γ
  /// @dev returns uint256 for fuzzy testing. Guaranteed that the result is not greater than alpha
  function sigmoid(
    uint256 x,
    uint16 g,
    uint16 alpha,
    uint256 beta
  ) internal pure returns (uint256 res) {
    if (x > beta) {
      x = x - beta;
      if (x >= 6 * uint256(g)) return alpha; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = exp(x, g, g8); // < 155 bits
      res = (alpha * ex) / (g8 + ex); // in worst case: (16 + 155 bits) / 155 bits
      // so res <= alpha
    } else {
      x = beta - x;
      if (x >= 6 * uint256(g)) return 0; // so x < 19 bits
      uint256 g8 = uint256(g)**8; // < 128 bits (8*16)
      uint256 ex = g8 + exp(x, g, g8); // < 156 bits
      res = (alpha * g8) / ex; // in worst case: (16 + 128 bits) / 156 bits
      // g8 <= ex, so res <= alpha
    }
  }

  /// @notice calculates e^(x/g) * g^8 in a series, since (around zero):
  /// e^x = 1 + x + x^2/2 + ... + x^n/n! + ...
  /// e^(x/g) = 1 + x/g + x^2/(2*g^2) + ... + x^(n)/(g^n * n!) + ...
  function exp(
    uint256 x,
    uint16 g,
    uint256 gHighestDegree
  ) internal pure returns (uint256 res) {
    // calculating:
    // g**8 + x * g**7 + (x**2 * g**6) / 2 + (x**3 * g**5) / 6 + (x**4 * g**4) / 24 + (x**5 * g**3) / 120 + (x**6 * g^2) / 720 + x**7 * g / 5040 + x**8 / 40320

    // x**8 < 152 bits (19*8) and g**8 < 128 bits (8*16)
    // so each summand < 152 bits and res < 155 bits
    uint256 xLowestDegree = x;
    res = gHighestDegree; // g**8

    gHighestDegree /= g; // g**7
    res += xLowestDegree * gHighestDegree;

    gHighestDegree /= g; // g**6
    xLowestDegree *= x; // x**2
    res += (xLowestDegree * gHighestDegree) / 2;

    gHighestDegree /= g; // g**5
    xLowestDegree *= x; // x**3
    res += (xLowestDegree * gHighestDegree) / 6;

    gHighestDegree /= g; // g**4
    xLowestDegree *= x; // x**4
    res += (xLowestDegree * gHighestDegree) / 24;

    gHighestDegree /= g; // g**3
    xLowestDegree *= x; // x**5
    res += (xLowestDegree * gHighestDegree) / 120;

    gHighestDegree /= g; // g**2
    xLowestDegree *= x; // x**6
    res += (xLowestDegree * gHighestDegree) / 720;

    xLowestDegree *= x; // x**7
    res += (xLowestDegree * g) / 5040 + (xLowestDegree * x) / (40320);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

library Constants {
  uint8 internal constant RESOLUTION = 96;
  uint256 internal constant Q96 = 0x1000000000000000000000000;
  uint256 internal constant Q128 = 0x100000000000000000000000000000000;
  // fee value in hundredths of a bip, i.e. 1e-6
  uint16 internal constant BASE_FEE = 100;
  int24 internal constant TICK_SPACING = 60;

  // max(uint128) / ( (MAX_TICK - MIN_TICK) / TICK_SPACING )
  uint128 internal constant MAX_LIQUIDITY_PER_TICK = 11505743598341114571880798222544994;

  uint32 internal constant MAX_LIQUIDITY_COOLDOWN = 1 days;
  uint8 internal constant MAX_COMMUNITY_FEE = 250;
  uint256 internal constant COMMUNITY_FEE_DENOMINATOR = 1000;
}