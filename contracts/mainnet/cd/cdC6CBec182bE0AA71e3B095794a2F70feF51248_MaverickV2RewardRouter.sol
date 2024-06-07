// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

interface IMulticall {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

interface IPayableMulticall {
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;
import {IPayableMulticall} from "./IPayableMulticall.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6ba452dea4258afe77726293435f10baf2bed265/contracts/utils/Multicall.sol

/*
 * @notice Payable multicall; requires all functions in the multicall to also be
 * payable.
 */
abstract contract PayableMulticall is IPayableMulticall {
    /**
     * @dev This function allows multiple calls to different contract functions
     * in a single transaction.
     * @param data An array of encoded function call data.
     * @return results An array of the results of the function calls.
     */
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMaverickV2Pool} from "./IMaverickV2Pool.sol";

interface IMaverickV2Factory {
    error FactoryInvalidProtocolFeeRatio(uint8 protocolFeeRatioD3);
    error FactoryInvalidLendingFeeRate(uint256 protocolLendingFeeRateD18);
    error FactoryProtocolFeeOnRenounce(uint8 protocolFeeRatioD3);
    error FactorAlreadyInitialized();
    error FactorNotInitialized();
    error FactoryInvalidTokenOrder(IERC20 _tokenA, IERC20 _tokenB);
    error FactoryInvalidFee();
    error FactoryInvalidKinds(uint8 kinds);
    error FactoryInvalidTickSpacing(uint256 tickSpacing);
    error FactoryInvalidLookback(uint256 lookback);
    error FactoryInvalidTokenDecimals(uint8 decimalsA, uint8 decimalsB);
    error FactoryPoolAlreadyExists(
        uint256 feeAIn,
        uint256 feeBIn,
        uint256 tickSpacing,
        uint256 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        uint8 kinds,
        address accessor
    );
    error FactoryAccessorMustBeNonZero();

    event PoolCreated(
        IMaverickV2Pool poolAddress,
        uint8 protocolFeeRatio,
        uint256 feeAIn,
        uint256 feeBIn,
        uint256 tickSpacing,
        uint256 lookback,
        int32 activeTick,
        IERC20 tokenA,
        IERC20 tokenB,
        uint8 kinds,
        address accessor
    );
    event SetFactoryProtocolFeeRatio(uint8 protocolFeeRatioD3);
    event SetFactoryProtocolLendingFeeRate(uint256 lendingFeeRateD18);
    event SetFactoryProtocolFeeReceiver(address receiver);

    struct DeployParameters {
        uint64 feeAIn;
        uint64 feeBIn;
        uint32 lookback;
        int32 activeTick;
        uint64 tokenAScale;
        uint64 tokenBScale;
        // slot
        IERC20 tokenA;
        // slot
        IERC20 tokenB;
        // slot
        uint16 tickSpacing;
        uint8 options;
        address accessor;
    }

    /**
     * @notice Called by deployer library to initialize a pool.
     */
    function deployParameters()
        external
        view
        returns (
            uint64 feeAIn,
            uint64 feeBIn,
            uint32 lookback,
            int32 activeTick,
            uint64 tokenAScale,
            uint64 tokenBScale,
            // slot
            IERC20 tokenA,
            // slot
            IERC20 tokenB,
            // slot
            uint16 tickSpacing,
            uint8 options,
            address accessor
        );

    /**
     * @notice Create a new MaverickV2Pool with symmetric swap fees.
     * @param fee Fraction of the pool swap amount that is retained as an LP in
     * D18 scale.
     * @param tickSpacing Tick spacing of pool where 1.0001^tickSpacing is the
     * bin width.
     * @param lookback Pool lookback in seconds.
     * @param tokenA Address of tokenA.
     * @param tokenB Address of tokenB.
     * @param activeTick Tick position that contains the active bins.
     * @param kinds 1-15 number to represent the active kinds
     * 0b0001 = static;
     * 0b0010 = right;
     * 0b0100 = left;
     * 0b1000 = both.
     * E.g. a pool with all 4 modes will have kinds = b1111 = 15
     */
    function create(
        uint64 fee,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds
    ) external returns (IMaverickV2Pool);

    /**
     * @notice Create a new MaverickV2Pool.
     * @param feeAIn Fraction of the pool swap amount for tokenA-input swaps
     * that is retained as an LP in D18 scale.
     * @param feeBIn Fraction of the pool swap amount for tokenB-input swaps
     * that is retained as an LP in D18 scale.
     * @param tickSpacing Tick spacing of pool where 1.0001^tickSpacing is the
     * bin width.
     * @param lookback Pool lookback in seconds.
     * @param tokenA Address of tokenA.
     * @param tokenB Address of tokenB.
     * @param activeTick Tick position that contains the active bins.
     * @param kinds 1-15 number to represent the active kinds
     * 0b0001 = static;
     * 0b0010 = right;
     * 0b0100 = left;
     * 0b1000 = both.
     * e.g. a pool with all 4 modes will have kinds = b1111 = 15
     */
    function create(
        uint64 feeAIn,
        uint64 feeBIn,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds
    ) external returns (IMaverickV2Pool);

    /**
     * @notice Create a new MaverickV2PoolPermissioned with symmetric swap fees
     * with all functions permissioned.  Set fee to zero to make the pool fee settable by the accessor.
     * @param fee Fraction of the pool swap amount that is retained as an LP in
     * D18 scale.
     * @param tickSpacing Tick spacing of pool where 1.0001^tickSpacing is the
     * bin width.
     * @param lookback Pool lookback in seconds.
     * @param tokenA Address of tokenA.
     * @param tokenB Address of tokenB.
     * @param activeTick Tick position that contains the active bins.
     * @param kinds 1-15 number to represent the active kinds
     * 0b0001 = static;
     * 0b0010 = right;
     * 0b0100 = left;
     * 0b1000 = both.
     * E.g. a pool with all 4 modes will have kinds = b1111 = 15
     * @param accessor Only address that can access the pool's public write functions.
     */
    function createPermissioned(
        uint64 fee,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds,
        address accessor
    ) external returns (IMaverickV2Pool);

    /**
     * @notice Create a new MaverickV2PoolPermissioned with all functions
     * permissioned. Set fees to zero to make the pool fee settable by the
     * accessor.
     * @param feeAIn Fraction of the pool swap amount for tokenA-input swaps
     * that is retained as an LP in D18 scale.
     * @param feeBIn Fraction of the pool swap amount for tokenB-input swaps
     * that is retained as an LP in D18 scale.
     * @param tickSpacing Tick spacing of pool where 1.0001^tickSpacing is the
     * bin width.
     * @param lookback Pool lookback in seconds.
     * @param tokenA Address of tokenA.
     * @param tokenB Address of tokenB.
     * @param activeTick Tick position that contains the active bins.
     * @param kinds 1-15 number to represent the active kinds
     * 0b0001 = static;
     * 0b0010 = right;
     * 0b0100 = left;
     * 0b1000 = both.
     * E.g. a pool with all 4 modes will have kinds = b1111 = 15
     * @param accessor only address that can access the pool's public write functions.
     */
    function createPermissioned(
        uint64 feeAIn,
        uint64 feeBIn,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds,
        address accessor
    ) external returns (IMaverickV2Pool);

    /**
     * @notice Create a new MaverickV2PoolPermissioned with the option to make
     * a subset of function permissionless. Set fee to zero to make the pool
     * fee settable by the accessor.
     * @param feeAIn Fraction of the pool swap amount for tokenA-input swaps
     * that is retained as an LP in D18 scale.
     * @param feeBIn Fraction of the pool swap amount for tokenB-input swaps
     * that is retained as an LP in D18 scale.
     * @param tickSpacing Tick spacing of pool where 1.0001^tickSpacing is the
     * bin width.
     * @param lookback Pool lookback in seconds.
     * @param tokenA Address of tokenA.
     * @param tokenB Address of tokenB.
     * @param activeTick Tick position that contains the active bins.
     * @param kinds 1-15 number to represent the active kinds
     * 0b0001 = static;
     * 0b0010 = right;
     * 0b0100 = left;
     * 0b1000 = both.
     * E.g. a pool with all 4 modes will have kinds = b1111 = 15
     * @param accessor only address that can access the pool's public permissioned write functions.
     * @param  permissionedLiquidity If true, then only accessor can call
     * pool's liquidity management functions: `flashLoan`,
     * `migrateBinsUpstack`, `addLiquidity`, `removeLiquidity`.
     * @param  permissionedSwap If true, then only accessor can call
     * pool's swap function.
     */
    function createPermissioned(
        uint64 feeAIn,
        uint64 feeBIn,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds,
        address accessor,
        bool permissionedLiquidity,
        bool permissionedSwap
    ) external returns (IMaverickV2Pool pool);

    /**
     * @notice Update the protocol fee ratio for a pool. Can be called
     * permissionlessly allowing any user to sync the pool protocol fee value
     * with the factory protocol fee value.
     * @param pool The pool for which to update.
     */
    function updateProtocolFeeRatioForPool(IMaverickV2Pool pool) external;

    /**
     * @notice Update the protocol lending fee rate for a pool. Can be called
     * permissionlessly allowing any user to sync the pool protocol lending fee
     * rate value with the factory value.
     * @param pool The pool for which to update.
     */
    function updateProtocolLendingFeeRateForPool(IMaverickV2Pool pool) external;

    /**
     * @notice Claim protocol fee for a pool and transfer it to the protocolFeeReceiver.
     * @param pool The pool from which to claim the protocol fee.
     * @param isTokenA A boolean indicating whether tokenA (true) or tokenB
     * (false) is being collected.
     */
    function claimProtocolFeeForPool(IMaverickV2Pool pool, bool isTokenA) external;

    /**
     * @notice Claim protocol fee for a pool and transfer it to the protocolFeeReceiver.
     * @param pool The pool from which to claim the protocol fee.
     */
    function claimProtocolFeeForPool(IMaverickV2Pool pool) external;

    /**
     * @notice Bool indicating whether the pool was deployed from this factory.
     */
    function isFactoryPool(IMaverickV2Pool pool) external view returns (bool);

    /**
     * @notice Address that receives the protocol fee when users call
     * `claimProtocolFeeForPool`.
     */
    function protocolFeeReceiver() external view returns (address);

    /**
     * @notice Lookup a pool for given parameters.
     *
     * @dev  options bit map of kinds and function permissions
     * 0b000001 = static;
     * 0b000010 = right;
     * 0b000100 = left;
     * 0b001000 = both;
     * 0b010000 = liquidity functions are permissioned
     * 0b100000 = swap function is permissioned
     */
    function lookupPermissioned(
        uint256 feeAIn,
        uint256 feeBIn,
        uint256 tickSpacing,
        uint256 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        uint8 options,
        address accessor
    ) external view returns (IMaverickV2Pool);

    /**
     * @notice Lookup a pool for given parameters.
     */
    function lookupPermissioned(
        IERC20 _tokenA,
        IERC20 _tokenB,
        address accessor,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Pool[] memory pools);

    /**
     * @notice Lookup a pool for given parameters.
     */
    function lookupPermissioned(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Pool[] memory pools);

    /**
     * @notice Lookup a pool for given parameters.
     */
    function lookup(
        uint256 feeAIn,
        uint256 feeBIn,
        uint256 tickSpacing,
        uint256 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        uint8 kinds
    ) external view returns (IMaverickV2Pool);

    /**
     * @notice Lookup a pool for given parameters.
     */
    function lookup(
        IERC20 _tokenA,
        IERC20 _tokenB,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Pool[] memory pools);

    /**
     * @notice Lookup a pool for given parameters.
     */
    function lookup(uint256 startIndex, uint256 endIndex) external view returns (IMaverickV2Pool[] memory pools);

    /**
     * @notice Count of permissionless pools.
     */
    function poolCount() external view returns (uint256 _poolCount);

    /**
     * @notice Count of permissioned pools.
     */
    function poolPermissionedCount() external view returns (uint256 _poolCount);

    /**
     * @notice Count of pools for a given accessor and token pair.  For
     * permissionless pools, pass `accessor = address(0)`.
     */
    function poolByTokenCount(
        IERC20 _tokenA,
        IERC20 _tokenB,
        address accessor
    ) external view returns (uint256 _poolCount);

    /**
     * @notice Get the current factory owner.
     */
    function owner() external view returns (address);

    /**
     * @notice Proportion of protocol fee to collect on each swap.  Value is in
     * 3-decimal format with a maximum value of 0.25e3.
     */
    function protocolFeeRatioD3() external view returns (uint8);

    /**
     * @notice Fee rate charged by the protocol for flashloans.  Value is in
     * 18-decimal format with a maximum value of 0.02e18.
     */
    function protocolLendingFeeRateD18() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2Factory} from "./IMaverickV2Factory.sol";

interface IMaverickV2Pool {
    error PoolZeroLiquidityAdded();
    error PoolMinimumLiquidityNotMet();
    error PoolLocked();
    error PoolInvalidFee();
    error PoolTicksNotSorted(uint256 index, int256 previousTick, int256 tick);
    error PoolTicksAmountsLengthMismatch(uint256 ticksLength, uint256 amountsLength);
    error PoolBinIdsAmountsLengthMismatch(uint256 binIdsLength, uint256 amountsLength);
    error PoolKindNotSupported(uint256 kinds, uint256 kind);
    error PoolInsufficientBalance(uint256 deltaLpAmount, uint256 accountBalance);
    error PoolReservesExceedMaximum(uint256 amount);
    error PoolValueExceedsBits(uint256 amount, uint256 bits);
    error PoolTickMaxExceeded(uint256 tick);
    error PoolMigrateBinFirst();
    error PoolCurrentTickBeyondSwapLimit(int32 startingTick);
    error PoolSenderNotAccessor(address sender_, address accessor);
    error PoolSenderNotFactory(address sender_, address accessor);
    error PoolFunctionNotImplemented();
    error PoolTokenNotSolvent(uint256 internalReserve, uint256 tokenBalance, IERC20 token);

    event PoolSwap(address sender, address recipient, SwapParams params, uint256 amountIn, uint256 amountOut);

    event PoolAddLiquidity(
        address sender,
        address recipient,
        uint256 subaccount,
        AddLiquidityParams params,
        uint256 tokenAAmount,
        uint256 tokenBAmount,
        uint32[] binIds
    );

    event PoolMigrateBinsUpStack(address sender, uint32 binId, uint32 maxRecursion);

    event PoolRemoveLiquidity(
        address sender,
        address recipient,
        uint256 subaccount,
        RemoveLiquidityParams params,
        uint256 tokenAOut,
        uint256 tokenBOut
    );

    event PoolSetVariableFee(uint256 newFeeAIn, uint256 newFeeBIn);

    /**
     * @notice Tick state parameters.
     */
    struct TickState {
        uint128 reserveA;
        uint128 reserveB;
        uint128 totalSupply;
        uint32[4] binIdsByTick;
    }

    /**
     * @notice Tick data parameters.
     * @param currentReserveA Current reserve of token A.
     * @param currentReserveB Current reserve of token B.
     * @param currentLiquidity Current liquidity amount.
     */
    struct TickData {
        uint256 currentReserveA;
        uint256 currentReserveB;
        uint256 currentLiquidity;
    }

    /**
     * @notice Bin state parameters.
     * @param mergeBinBalance LP token balance that this bin possesses of the merge bin.
     * @param mergeId Bin ID of the bin that this bin has merged into.
     * @param totalSupply Total amount of LP tokens in this bin.
     * @param kind One of the 4 kinds (0=static, 1=right, 2=left, 3=both).
     * @param tick The lower price tick of the bin in its current state.
     * @param tickBalance Balance of the tick.
     */
    struct BinState {
        uint128 mergeBinBalance;
        uint128 tickBalance;
        uint128 totalSupply;
        uint8 kind;
        int32 tick;
        uint32 mergeId;
    }

    /**
     * @notice Parameters for swap.
     * @param amount Amount of the token that is either the input if exactOutput is false
     * or the output if exactOutput is true.
     * @param tokenAIn Boolean indicating whether tokenA is the input.
     * @param exactOutput Boolean indicating whether the amount specified is
     * the exact output amount (true).
     * @param tickLimit The furthest tick a swap will execute in. If no limit
     * is desired, value should be set to type(int32).max for a tokenAIn swap
     * and type(int32).min for a swap where tokenB is the input.
     */
    struct SwapParams {
        uint256 amount;
        bool tokenAIn;
        bool exactOutput;
        int32 tickLimit;
    }

    /**
     * @notice Parameters associated with adding liquidity.
     * @param kind One of the 4 kinds (0=static, 1=right, 2=left, 3=both).
     * @param ticks Array of ticks to add liquidity to.
     * @param amounts Array of bin LP amounts to add.
     */
    struct AddLiquidityParams {
        uint8 kind;
        int32[] ticks;
        uint128[] amounts;
    }

    /**
     * @notice Parameters for each bin that will have liquidity removed.
     * @param binIds Index array of the bins losing liquidity.
     * @param amounts Array of bin LP amounts to remove.
     */
    struct RemoveLiquidityParams {
        uint32[] binIds;
        uint128[] amounts;
    }

    /**
     * @notice State of the pool.
     * @param reserveA Pool tokenA balanceOf at end of last operation
     * @param reserveB Pool tokenB balanceOf at end of last operation
     * @param lastTwaD8 Value of log time weighted average price at last block.
     * Value is 8-decimal scale and is in the fractional tick domain.  E.g. a
     * value of 12.3e8 indicates the TWAP was 3/10ths of the way into the 12th
     * tick.
     * @param lastLogPriceD8 Value of log price at last block. Value is
     * 8-decimal scale and is in the fractional tick domain.  E.g. a value of
     * 12.3e8 indicates the price was 3/10ths of the way into the 12th tick.
     * @param lastTimestamp Last block.timestamp value in seconds for latest
     * swap transaction.
     * @param activeTick Current tick position that contains the active bins.
     * @param isLocked Pool isLocked, E.g., locked or unlocked; isLocked values
     * defined in Pool.sol.
     * @param binCounter Index of the last bin created.
     * @param protocolFeeRatioD3 Ratio of the swap fee that is kept for the
     * protocol.
     */
    struct State {
        uint128 reserveA;
        uint128 reserveB;
        int64 lastTwaD8;
        int64 lastLogPriceD8;
        uint40 lastTimestamp;
        int32 activeTick;
        bool isLocked;
        uint32 binCounter;
        uint8 protocolFeeRatioD3;
    }

    /**
     * @notice Internal data used for data passing between Pool and Bin code.
     */
    struct BinDelta {
        uint128 deltaA;
        uint128 deltaB;
    }

    /**
     * @notice 1-15 number to represent the active kinds.
     * @notice 0b0001 = static;
     * @notice 0b0010 = right;
     * @notice 0b0100 = left;
     * @notice 0b1000 = both;
     *
     * E.g. a pool with all 4 modes will have kinds = b1111 = 15
     */
    function kinds() external view returns (uint8 _kinds);

    /**
     * @notice Returns whether a pool has permissioned functions. If true, the
     * `accessor()` of the pool can set the pool fees.  Other functions in the
     * pool may also be permissioned; whether or not they are can be determined
     * through calls to `permissionedLiquidity()` and `permissionedSwap()`.
     */
    function permissionedPool() external view returns (bool _permissionedPool);

    /**
     * @notice Returns whether a pool has permissioned liquidity management
     * functions. If true, the pool is incompatible with permissioned pool
     * liquidity management infrastructure.
     */
    function permissionedLiquidity() external view returns (bool _permissionedLiquidity);

    /**
     * @notice Returns whether a pool has a permissioned swap functions. If
     * true, the pool is incompatible with permissioned pool swap router
     * infrastructure.
     */
    function permissionedSwap() external view returns (bool _permissionedSwap);

    /**
     * @notice Pool swap fee for the given direction (A-in or B-in swap) in
     * 18-decimal format. E.g. 0.01e18 is a 1% swap fee.
     */
    function fee(bool tokenAIn) external view returns (uint256);

    /**
     * @notice TickSpacing of pool where 1.0001^tickSpacing is the bin width.
     */
    function tickSpacing() external view returns (uint256);

    /**
     * @notice Lookback period of pool in seconds.
     */
    function lookback() external view returns (uint256);

    /**
     * @notice Address of Pool accessor.  This is Zero address for
     * permissionless pools.
     */
    function accessor() external view returns (address);

    /**
     * @notice Pool tokenA.  Address of tokenA is such that tokenA < tokenB.
     */
    function tokenA() external view returns (IERC20);

    /**
     * @notice Pool tokenB.
     */
    function tokenB() external view returns (IERC20);

    /**
     * @notice Deploying factory of the pool and also contract that has ability
     * to set and collect protocol fees for the pool.
     */
    function factory() external view returns (IMaverickV2Factory);

    /**
     * @notice Most significant bit of scale value is a flag to indicate whether
     * tokenA has more or less than 18 decimals.  Scale is used in conjuction
     * with Math.toScale/Math.fromScale functions to convert from token amounts
     * to D18 scale internal pool accounting.
     */
    function tokenAScale() external view returns (uint256);

    /**
     * @notice Most significant bit of scale value is a flag to indicate whether
     * tokenA has more or less than 18 decimals.  Scale is used in conjuction
     * with Math.toScale/Math.fromScale functions to convert from token amounts
     * to D18 scale internal pool accounting.
     */
    function tokenBScale() external view returns (uint256);

    /**
     * @notice ID of bin at input tick position and kind.
     */
    function binIdByTickKind(int32 tick, uint256 kind) external view returns (uint32);

    /**
     * @notice Accumulated tokenA protocol fee.
     */
    function protocolFeeA() external view returns (uint128);

    /**
     * @notice Accumulated tokenB protocol fee.
     */
    function protocolFeeB() external view returns (uint128);

    /**
     * @notice Lending fee rate on flash loans.
     */
    function lendingFeeRateD18() external view returns (uint256);

    /**
     * @notice External function to get the current time-weighted average price.
     */
    function getCurrentTwa() external view returns (int256);

    /**
     * @notice External function to get the state of the pool.
     */
    function getState() external view returns (State memory);

    /**
     * @notice Return state of Bin at input binId.
     */
    function getBin(uint32 binId) external view returns (BinState memory bin);

    /**
     * @notice Return state of Tick at input tick position.
     */
    function getTick(int32 tick) external view returns (TickState memory tickState);

    /**
     * @notice Retrieves the balance of a user within a bin.
     * @param user The user's address.
     * @param subaccount The subaccount for the user.
     * @param binId The ID of the bin.
     */
    function balanceOf(address user, uint256 subaccount, uint32 binId) external view returns (uint128 lpToken);

    /**
     * @notice Add liquidity to a pool. This function allows users to deposit
     * tokens into a liquidity pool.
     * @dev This function will call `maverickV2AddLiquidityCallback` on the
     * calling contract to collect the tokenA/tokenB payment.
     * @param recipient The account that will receive credit for the added liquidity.
     * @param subaccount The account that will receive credit for the added liquidity.
     * @param params Parameters containing the details for adding liquidity,
     * such as token types and amounts.
     * @param data Bytes information that gets passed to the callback.
     * @return tokenAAmount The amount of token A added to the pool.
     * @return tokenBAmount The amount of token B added to the pool.
     * @return binIds An array of bin IDs where the liquidity is stored.
     */
    function addLiquidity(
        address recipient,
        uint256 subaccount,
        AddLiquidityParams calldata params,
        bytes calldata data
    ) external returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds);

    /**
     * @notice Removes liquidity from the pool.
     * @dev Liquidy can only be removed from a bin that is either unmerged or
     * has a mergeId of an unmerged bin.  If a bin is merged more than one
     * level deep, it must be migrated up the merge stack to the root bin
     * before liquidity removal.
     * @param recipient The address to receive the tokens.
     * @param subaccount The subaccount for the recipient.
     * @param params The parameters for removing liquidity.
     * @return tokenAOut The amount of token A received.
     * @return tokenBOut The amount of token B received.
     */
    function removeLiquidity(
        address recipient,
        uint256 subaccount,
        RemoveLiquidityParams calldata params
    ) external returns (uint256 tokenAOut, uint256 tokenBOut);

    /**
     * @notice Migrate bins up the linked list of merged bins so that its
     * mergeId is the currrent active bin.
     * @dev Liquidy can only be removed from a bin that is either unmerged or
     * has a mergeId of an unmerged bin.  If a bin is merged more than one
     * level deep, it must be migrated up the merge stack to the root bin
     * before liquidity removal.
     * @param binId The ID of the bin to migrate.
     * @param maxRecursion The maximum recursion depth for the migration.
     */
    function migrateBinUpStack(uint32 binId, uint32 maxRecursion) external;

    /**
     * @notice Swap tokenA/tokenB assets in the pool.  The swap user has two
     * options for funding their swap.
     * - The user can push the input token amount to the pool before calling
     * the swap function. In order to avoid having the pool call the callback,
     * the user should pass a zero-length `data` bytes object with the swap
     * call.
     * - The user can send the input token amount to the pool when the pool
     * calls the `maverickV2SwapCallback` function on the calling contract.
     * That callback has input parameters that specify the token address of the
     * input token, the input and output amounts, and the bytes data sent to
     * the swap function.
     * @dev  If the users elects to do a callback-based swap, the output
     * assets will be sent before the callback is called, allowing the user to
     * execute flash swaps.  However, the pool does have reentrancy protection,
     * so a swapper will not be able to interact with the same pool again
     * while they are in the callback function.
     * @param recipient The address to receive the output tokens.
     * @param params Parameters containing the details of the swap
     * @param data Bytes information that gets passed to the callback.
     */
    function swap(
        address recipient,
        SwapParams memory params,
        bytes calldata data
    ) external returns (uint256 amountIn, uint256 amountOut);

    /**
     * @notice Loan tokenA/tokenB assets from the pool to recipient. The fee
     * rate of a loan is determined by `lendingFeeRateD18`, which is set at the
     * protocol level by the factory.  This function calls
     * `maverickV2FlashLoanCallback` on the calling contract.  At the end of
     * the callback, the caller must pay back the loan with fee (if there is a
     * fee).
     * @param recipient The address to receive the loaned tokens.
     * @param amountB Loan amount of tokenA sent to recipient.
     * @param amountB Loan amount of tokenB sent to recipient.
     * @param data Bytes information that gets passed to the callback.
     */
    function flashLoan(
        address recipient,
        uint256 amountA,
        uint256 amountB,
        bytes calldata data
    ) external returns (uint128 lendingFeeA, uint128 lendingFeeB);

    /**
     * @notice Sets fee for permissioned pools.  May only be called by the
     * accessor.
     */
    function setFee(uint256 newFeeAIn, uint256 newFeeBIn) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

// factory contraints on pools
uint8 constant MAX_PROTOCOL_FEE_RATIO_D3 = 0.25e3; // 25%
uint256 constant MAX_PROTOCOL_LENDING_FEE_RATE_D18 = 0.02e18; // 2%
uint64 constant MAX_POOL_FEE_D18 = 0.9e18; // 90%
uint64 constant MIN_LOOKBACK = 1 seconds;
uint64 constant MAX_TICK_SPACING = 10_000;

// pool constraints
uint8 constant NUMBER_OF_KINDS = 4;
int32 constant NUMBER_OF_KINDS_32 = int32(int8(NUMBER_OF_KINDS));
uint256 constant MAX_TICK = 322_378; // max price 1e14 in D18 scale
int32 constant MAX_TICK_32 = int32(int256(MAX_TICK));
int32 constant MIN_TICK_32 = int32(-int256(MAX_TICK));
uint256 constant MAX_BINS_TO_MERGE = 3;
uint128 constant MINIMUM_LIQUIDITY = 1e8;

// accessor named constants
uint8 constant ALL_KINDS_MASK = 0xF; // 0b1111
uint8 constant PERMISSIONED_LIQUIDITY_MASK = 0x10; // 0b010000
uint8 constant PERMISSIONED_SWAP_MASK = 0x20; // 0b100000
uint8 constant OPTIONS_MASK = ALL_KINDS_MASK | PERMISSIONED_LIQUIDITY_MASK | PERMISSIONED_SWAP_MASK; // 0b111111

// named values
address constant MERGED_LP_BALANCE_ADDRESS = address(0);
uint256 constant MERGED_LP_BALANCE_SUBACCOUNT = 0;
uint128 constant ONE = 1e18;
uint128 constant ONE_SQUARED = 1e36;
int256 constant INT256_ONE = 1e18;
uint256 constant ONE_D8 = 1e8;
uint256 constant ONE_D3 = 1e3;
int40 constant INT_ONE_D8 = 1e8;
int40 constant HALF_TICK_D8 = 0.5e8;
uint8 constant DEFAULT_DECIMALS = 18;
uint256 constant DEFAULT_SCALE = 1;
bytes constant EMPTY_PRICE_BREAKS = hex"010000000000000000000000";

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {Math as OzMath} from "@openzeppelin/contracts/utils/math/Math.sol";

import {ONE, DEFAULT_SCALE, DEFAULT_DECIMALS, INT_ONE_D8, ONE_SQUARED} from "./Constants.sol";

/**
 * @notice Math functions.
 */
library Math {
    /**
     * @notice Returns the lesser of two values.
     * @param x First uint256 value.
     * @param y Second uint256 value.
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /**
     * @notice Returns the lesser of two uint128 values.
     * @param x First uint128 value.
     * @param y Second uint128 value.
     */
    function min128(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /**
     * @notice Returns the lesser of two int256 values.
     * @param x First int256 value.
     * @param y Second int256 value.
     */
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /**
     * @notice Returns the greater of two uint256 values.
     * @param x First uint256 value.
     * @param y Second uint256 value.
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /**
     * @notice Returns the greater of two int256 values.
     * @param x First int256 value.
     * @param y Second int256 value.
     */
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /**
     * @notice Returns the greater of two uint128 values.
     * @param x First uint128 value.
     * @param y Second uint128 value.
     */
    function max128(uint128 x, uint128 y) internal pure returns (uint128 z) {
        assembly ("memory-safe") {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /**
     * @notice Thresholds a value to be within the specified bounds.
     * @param value The value to bound.
     * @param lowerLimit The minimum allowable value.
     * @param upperLimit The maximum allowable value.
     */
    function boundValue(
        uint256 value,
        uint256 lowerLimit,
        uint256 upperLimit
    ) internal pure returns (uint256 outputValue) {
        outputValue = min(max(value, lowerLimit), upperLimit);
    }

    /**
     * @notice Returns the difference between two uint128 values or zero if the result would be negative.
     * @param x The minuend.
     * @param y The subtrahend.
     */
    function clip128(uint128 x, uint128 y) internal pure returns (uint128) {
        unchecked {
            return x < y ? 0 : x - y;
        }
    }

    /**
     * @notice Returns the difference between two uint256 values or zero if the result would be negative.
     * @param x The minuend.
     * @param y The subtrahend.
     */
    function clip(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            return x < y ? 0 : x - y;
        }
    }

    /**
     * @notice Divides one uint256 by another, rounding down to the nearest
     * integer.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divFloor(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivFloor(x, ONE, y);
    }

    /**
     * @notice Divides one uint256 by another, rounding up to the nearest integer.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivCeil(x, ONE, y);
    }

    /**
     * @notice Multiplies two uint256 values and then divides by ONE, rounding down.
     * @param x The multiplicand.
     * @param y The multiplier.
     */
    function mulFloor(uint256 x, uint256 y) internal pure returns (uint256) {
        return OzMath.mulDiv(x, y, ONE);
    }

    /**
     * @notice Multiplies two uint256 values and then divides by ONE, rounding up.
     * @param x The multiplicand.
     * @param y The multiplier.
     */
    function mulCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivCeil(x, y, ONE);
    }

    /**
     * @notice Calculates the multiplicative inverse of a uint256, rounding down.
     * @param x The value to invert.
     */
    function invFloor(uint256 x) internal pure returns (uint256) {
        unchecked {
            return ONE_SQUARED / x;
        }
    }

    /**
     * @notice Calculates the multiplicative inverse of a uint256, rounding up.
     * @param denominator The value to invert.
     */
    function invCeil(uint256 denominator) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // divide z - 1 by the denominator and add 1.
            z := add(div(sub(ONE_SQUARED, 1), denominator), 1)
        }
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding down.
     * @param x The multiplicand.
     * @param y The multiplier.
     * @param k The divisor.
     */
    function mulDivFloor(uint256 x, uint256 y, uint256 k) internal pure returns (uint256 result) {
        result = OzMath.mulDiv(x, y, max(1, k));
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding up if there's a remainder.
     * @param x The multiplicand.
     * @param y The multiplier.
     * @param k The divisor.
     */
    function mulDivCeil(uint256 x, uint256 y, uint256 k) internal pure returns (uint256 result) {
        result = mulDivFloor(x, y, k);
        if (mulmod(x, y, max(1, k)) != 0) result = result + 1;
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding
     * down. Will revert if `x * y` is larger than `type(uint256).max`.
     * @param x The first operand for multiplication.
     * @param y The second operand for multiplication.
     * @param denominator The divisor after multiplication.
     */
    function mulDivDown(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Store x * y in z for now.
            z := mul(x, y)
            if iszero(denominator) {
                denominator := 1
            }

            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    /**
     * @notice Multiplies two uint256 values and divides by a third, rounding
     * up. Will revert if `x * y` is larger than `type(uint256).max`.
     * @param x The first operand for multiplication.
     * @param y The second operand for multiplication.
     * @param denominator The divisor after multiplication.
     */
    function mulDivUp(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        assembly ("memory-safe") {
            // Store x * y in z for now.
            z := mul(x, y)
            if iszero(denominator) {
                denominator := 1
            }

            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    /**
     * @notice Multiplies a uint256 by another and divides by a constant,
     * rounding down. Will revert if `x * y` is larger than
     * `type(uint256).max`.
     * @param x The multiplicand.
     * @param y The multiplier.
     */
    function mulDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, ONE);
    }

    /**
     * @notice Divides a uint256 by another, rounding down the result. Will
     * revert if `x * 1e18` is larger than `type(uint256).max`.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, ONE, y);
    }

    /**
     * @notice Divides a uint256 by another, rounding up the result. Will
     * revert if `x * 1e18` is larger than `type(uint256).max`.
     * @param x The dividend.
     * @param y The divisor.
     */
    function divUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, ONE, y);
    }

    /**
     * @notice Scales a number based on a difference in decimals from a default.
     * @param decimals The new decimal precision.
     */
    function scale(uint8 decimals) internal pure returns (uint256) {
        unchecked {
            if (decimals == DEFAULT_DECIMALS) {
                return DEFAULT_SCALE;
            } else {
                return 10 ** (DEFAULT_DECIMALS - decimals);
            }
        }
    }

    /**
     * @notice Adjusts a scaled amount to the token decimal scale.
     * @param amount The scaled amount.
     * @param scaleFactor The scaling factor to adjust by.
     * @param ceil Whether to round up (true) or down (false).
     */
    function ammScaleToTokenScale(uint256 amount, uint256 scaleFactor, bool ceil) internal pure returns (uint256 z) {
        unchecked {
            if (scaleFactor == DEFAULT_SCALE || amount == 0) {
                return amount;
            } else {
                if (!ceil) return amount / scaleFactor;
                assembly ("memory-safe") {
                    z := add(div(sub(amount, 1), scaleFactor), 1)
                }
            }
        }
    }

    /**
     * @notice Adjusts a token amount to the D18 AMM scale.
     * @param amount The amount in token scale.
     * @param scaleFactor The scale factor for adjustment.
     */
    function tokenScaleToAmmScale(uint256 amount, uint256 scaleFactor) internal pure returns (uint256) {
        if (scaleFactor == DEFAULT_SCALE) {
            return amount;
        } else {
            return amount * scaleFactor;
        }
    }

    /**
     * @notice Returns the absolute value of a signed 32-bit integer.
     * @param x The integer to take the absolute value of.
     */
    function abs32(int32 x) internal pure returns (uint32) {
        unchecked {
            return uint32(x < 0 ? -x : x);
        }
    }

    /**
     * @notice Returns the absolute value of a signed 256-bit integer.
     * @param x The integer to take the absolute value of.
     */
    function abs(int256 x) internal pure returns (uint256) {
        unchecked {
            return uint256(x < 0 ? -x : x);
        }
    }

    /**
     * @notice Calculates the integer square root of a uint256 rounded down.
     * @param x The number to take the square root of.
     */
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        // from https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/FixedPointMathLib.sol
        assembly ("memory-safe") {
            let y := x
            z := 181

            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            z := shr(18, mul(z, add(y, 65536)))

            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            z := sub(z, lt(div(x, z), z))
        }
    }

    /**
     * @notice Computes the floor of a D8-scaled number as an int32, ignoring
     * potential overflow in the cast.
     * @param val The D8-scaled number.
     */
    function floorD8Unchecked(int256 val) internal pure returns (int32) {
        int32 val32;
        bool check;
        unchecked {
            val32 = int32(val / INT_ONE_D8);
            check = (val < 0 && val % INT_ONE_D8 != 0);
        }
        return check ? val32 - 1 : val32;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {SafeCast as Cast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IMaverickV2Pool} from "../interfaces/IMaverickV2Pool.sol";
import {TickMath} from "./TickMath.sol";
import {Math} from "./Math.sol";

/**
 * @notice Library of pool functions.
 */
library PoolLib {
    using Cast for uint256;

    struct AddLiquidityInfo {
        uint256 deltaA;
        uint256 deltaB;
        bool tickLtActive;
        uint256 tickSpacing;
        int32 tick;
    }

    /**
     * @notice Check to ensure that the ticks are in ascending order and amount
     * array is same length as tick array.
     * @param ticks An array of int32 values representing ticks to be checked.
     * @param amountsLength Amount array length.
     */
    function uniqueOrderedTicksCheck(int32[] memory ticks, uint256 amountsLength) internal pure {
        unchecked {
            if (ticks.length != amountsLength)
                revert IMaverickV2Pool.PoolTicksAmountsLengthMismatch(ticks.length, amountsLength);
            int32 lastTick = type(int32).min;
            for (uint256 i; i < ticks.length; ) {
                if (ticks[i] <= lastTick) revert IMaverickV2Pool.PoolTicksNotSorted(i, lastTick, ticks[i]);
                lastTick = ticks[i];
                i = i + 1;
            }
        }
    }

    /**
     * @notice Compute bin reserves assuming the bin is not merged; not accurate
     * reflection of reserves for merged bins.
     * @param bin The storage reference to the state for this bin.
     * @param tick The memory reference to the state for this tick.
     * @return reserveA The reserve amount for token A.
     * @return reserveB The reserve amount for token B.
     */
    function binReserves(
        IMaverickV2Pool.BinState storage bin,
        IMaverickV2Pool.TickState memory tick
    ) internal view returns (uint128 reserveA, uint128 reserveB) {
        return binReserves(bin.tickBalance, tick.reserveA, tick.reserveB, tick.totalSupply);
    }

    /**
     * @notice Compute bin reserves assuming the bin is not merged; not accurate
     * reflection of reserves for merged bins.
     * @param tickBalance Bin's balance in the tick.
     * @param tickReserveA Tick's tokenA reserves.
     * @param tickReserveB Tick's tokenB reserves.
     * @param tickTotalSupply Tick total supply of bin balances.
     */
    function binReserves(
        uint128 tickBalance,
        uint128 tickReserveA,
        uint128 tickReserveB,
        uint128 tickTotalSupply
    ) internal pure returns (uint128 reserveA, uint128 reserveB) {
        if (tickTotalSupply != 0) {
            reserveA = reserveValue(tickReserveA, tickBalance, tickTotalSupply);
            reserveB = reserveValue(tickReserveB, tickBalance, tickTotalSupply);
        }
    }

    /**
     * @notice Reserves of a bin in a tick.
     * @param tickReserve Tick reserve amount in a given token.
     * @param tickBalance Bin's balance in the tick.
     * @param tickTotalSupply Tick total supply of bin balances.
     */
    function reserveValue(
        uint128 tickReserve,
        uint128 tickBalance,
        uint128 tickTotalSupply
    ) internal pure returns (uint128 reserve) {
        reserve = Math.mulDivFloor(tickReserve, tickBalance, tickTotalSupply).toUint128();
        reserve = Math.min128(tickReserve, reserve);
    }

    /**
     * @notice Calculate delta A, delta B, and delta Tick Balance based on delta
     * LP balance and the Tick/Bin state.
     */
    function deltaTickBalanceFromDeltaLpBalance(
        uint256 binTickBalance,
        uint256 binTotalSupply,
        IMaverickV2Pool.TickState memory tickState,
        uint128 deltaLpBalance,
        AddLiquidityInfo memory addLiquidityInfo
    ) internal pure returns (uint256 deltaTickBalance) {
        unchecked {
            if (tickState.reserveA != 0 || tickState.reserveB != 0) {
                // if there are already reserves, then we just contribute pro rata
                // deltaLiquidity = deltaBinLP / binTS * binTickBalance / tickTS * tickL
                uint256 numerator = Math.max(1, binTickBalance) * uint256(deltaLpBalance);
                uint256 denominator = Math.max(1, tickState.totalSupply) * Math.max(1, binTotalSupply);
                addLiquidityInfo.deltaA = Math.mulDivCeil(tickState.reserveA, numerator, denominator);
                addLiquidityInfo.deltaB = Math.mulDivCeil(tickState.reserveB, numerator, denominator);
            } else {
                _setRequiredDeltaReservesForEmptyTick(deltaLpBalance, addLiquidityInfo);
            }

            // round down the amount credited to the tick; this could lead to a
            // small add amount getting zero reserves credit.
            deltaTickBalance = tickState.totalSupply == 0
                ? deltaLpBalance
                : Math.mulDivDown(deltaLpBalance, Math.max(1, binTickBalance), binTotalSupply);
        }
    }

    /**
     * @notice Calculates deltaA = liquidity * (sqrt(upper) - sqrt(lower))
     * @notice Calculates deltaB = liquidity / sqrt(lower) - liquidity / sqrt(upper),
     * @notice i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
     * @notice we set liquidity = deltaLpBalance / (1.0001^(tick * tickspacing) - 1)
     * @notice which simplifies the A/B amounts to:
     * @notice deltaA = deltaLpBalance * sqrt(lower)
     * @notice deltaB = deltaLpBalance / sqrt(upper)
     */
    function _setRequiredDeltaReservesForEmptyTick(
        uint128 deltaLpBalance,
        AddLiquidityInfo memory addLiquidityInfo
    ) internal pure {
        // No reserves, so we will use deltaLpBalance as liquidity to be added.
        // In this logic branch, the tick is empty, so we know the tick will be
        // a one-asset add.
        (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(
            addLiquidityInfo.tickSpacing,
            addLiquidityInfo.tick
        );

        addLiquidityInfo.deltaA = addLiquidityInfo.tickLtActive ? Math.mulCeil(deltaLpBalance, sqrtLowerTickPrice) : 0;
        addLiquidityInfo.deltaB = addLiquidityInfo.tickLtActive ? 0 : Math.divCeil(deltaLpBalance, sqrtUpperTickPrice);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {Math as OzMath} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Math} from "./Math.sol";
import {MAX_TICK, ONE} from "./Constants.sol";

/**
 * @notice Math functions related to tick operations.
 */
library TickMath {
    using Math for uint256;

    error TickMaxExceeded(int256 tick);

    /**
     * @notice Compute the lower and upper sqrtPrice of a tick.
     * @param tickSpacing The tick spacing used for calculations.
     * @param _tick The input tick value.
     */
    function tickSqrtPrices(
        uint256 tickSpacing,
        int32 _tick
    ) internal pure returns (uint256 sqrtLowerPrice, uint256 sqrtUpperPrice) {
        unchecked {
            sqrtLowerPrice = tickSqrtPrice(tickSpacing, _tick);
            sqrtUpperPrice = tickSqrtPrice(tickSpacing, _tick + 1);
        }
    }

    /**
     * @notice Compute the base tick value from the pool tick and the
     * tickSpacing.  Revert if base tick is beyond the max tick boundary.
     * @param tickSpacing The tick spacing used for calculations.
     * @param _tick The input tick value.
     */
    function subTickIndex(uint256 tickSpacing, int32 _tick) internal pure returns (uint32 subTick) {
        subTick = Math.abs32(_tick);
        subTick *= uint32(tickSpacing);
        if (subTick > MAX_TICK) {
            revert TickMaxExceeded(_tick);
        }
    }

    /**
     * @notice Calculate the square root price for a given tick and tick spacing.
     * @param tickSpacing The tick spacing used for calculations.
     * @param _tick The input tick value.
     * @return _result The square root price.
     */
    function tickSqrtPrice(uint256 tickSpacing, int32 _tick) internal pure returns (uint256 _result) {
        unchecked {
            uint256 tick = subTickIndex(tickSpacing, _tick);

            uint256 ratio = tick & 0x1 != 0 ? 0xfffcb933bd6fad9d3af5f0b9f25db4d6 : 0x100000000000000000000000000000000;
            if (tick & 0x2 != 0) ratio = (ratio * 0xfff97272373d41fd789c8cb37ffcaa1c) >> 128;
            if (tick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656ac9229c67059486f389) >> 128;
            if (tick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e81259b3cddc7a064941) >> 128;
            if (tick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f67b19e8887e0bd251eb7) >> 128;
            if (tick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98cd2e57b660be99eb2c4a) >> 128;
            if (tick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c9838804e327cb417cafcb) >> 128;
            if (tick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99d51e2cc356c2f617dbe0) >> 128;
            if (tick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900aecf64236ab31f1f9dcb5) >> 128;
            if (tick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac4d9194200696907cf2e37) >> 128;
            if (tick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b88206f8abe8a3b44dd9be) >> 128;
            if (tick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c578ef4f1d17b2b235d480) >> 128;
            if (tick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd254ee83bdd3f248e7e785e) >> 128;
            if (tick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d8f7dd10e744d913d033333) >> 128;
            if (tick & 0x4000 != 0) ratio = (ratio * 0x70d869a156ddd32a39e257bc3f50aa9b) >> 128;
            if (tick & 0x8000 != 0) ratio = (ratio * 0x31be135f97da6e09a19dc367e3b6da40) >> 128;
            if (tick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7e5a9780b0cc4e25d61a56) >> 128;
            if (tick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedbcb3a6ccb7ce618d14225) >> 128;
            if (tick & 0x40000 != 0) ratio = (ratio * 0x2216e584f630389b2052b8db590e) >> 128;
            if (_tick > 0) ratio = type(uint256).max / ratio;
            _result = (ratio * ONE) >> 128;
        }
    }

    /**
     * @notice Calculate liquidity of a tick.
     * @param reserveA Tick reserve of token A.
     * @param reserveB Tick reserve of token B.
     * @param sqrtLowerTickPrice The square root price of the lower tick edge.
     * @param sqrtUpperTickPrice The square root price of the upper tick edge.
     */
    function getTickL(
        uint256 reserveA,
        uint256 reserveB,
        uint256 sqrtLowerTickPrice,
        uint256 sqrtUpperTickPrice
    ) internal pure returns (uint256 liquidity) {
        // known:
        // - sqrt price values are different
        // - reserveA and reserveB fit in 128 bit
        // - sqrt price is in (1e-7, 1e7)
        // - D18 max for uint256 is 1.15e59
        // - D18 min is 1e-18

        unchecked {
            // diff is in (5e-12, 4e6); max tick spacing is 10_000
            uint256 diff = sqrtUpperTickPrice - sqrtLowerTickPrice;

            // Need to maximize precision by shifting small values A and B up so
            // that they use more of the available bit range. Two constraints to
            // consider: we need A * B * diff / sqrtPrice to be bigger than 1e-18
            // when the bump is not in play.  This constrains the threshold for
            // bumping to be at least 77 bit; ie, either a or b needs 2^77 which
            // means that term A * B * diff / sqrtPrice > 1e-18.
            //
            // At the other end, the second constraint is that b^2 needs to fit in
            // a 256-bit number, so, post bump, the max reserve value needs to be
            // less than 6e22. With a 78-bit threshold and a 57-bit bump, we have A
            // and B are in (1.4e-1, 4.4e22 (2^(78+57))) with bump, and one of A or
            // B is at least 2^78 without the bump, but the other reserve value may
            // be as small as 1 wei.
            uint256 precisionBump = 0;
            if ((reserveA >> 78) == 0 && (reserveB >> 78) == 0) {
                precisionBump = 57;
                reserveA <<= precisionBump;
                reserveB <<= precisionBump;
            }

            if (reserveB == 0) return Math.divDown(reserveA, diff) >> precisionBump;
            if (reserveA == 0)
                return Math.mulDivDown(reserveB.mulDown(sqrtLowerTickPrice), sqrtUpperTickPrice, diff) >> precisionBump;

            // b is in (7.2e-9 (2^57 / 1e7 / 2), 2.8e29  (2^(78+57) * 1e7 / 2)) with bump
            // b is in a subset of the same range without bump
            uint256 b = (reserveA.divDown(sqrtUpperTickPrice) + reserveB.mulDown(sqrtLowerTickPrice)) >> 1;

            // b^2 is in (5.1e-17, 4.8e58); and will not overflow on either end;
            // A*B is in (3e-13 (2^78 / 1e18 * 1e-18), 1.9e45) without bump and is in a subset range with bump
            // A*B*diff/sqrtUpper is in (1.5e-17 (3e-13 * 5e-12 * 1e7), 7.6e58);

            // Since b^2 is at the upper edge of the precision range, we are not
            // able to multiply the argument of the sqrt by 1e18, instead, we move
            // this factor outside of the sqrt. The resulting loss of precision
            // means that this liquidity value is a lower bound on the tick
            // liquidity
            return
                OzMath.mulDiv(
                    b +
                        Math.sqrt(
                            (OzMath.mulDiv(b, b, ONE) +
                                OzMath.mulDiv(reserveB.mulFloor(reserveA), diff, sqrtUpperTickPrice))
                        ) *
                        1e9,
                    sqrtUpperTickPrice,
                    diff
                ) >> precisionBump;
        }
    }

    /**
     * @notice Calculate square root price of a tick. Returns left edge of the
     * tick if the tick has no reserves.
     * @param reserveA Tick reserve of token A.
     * @param reserveB Tick reserve of token B.
     * @param sqrtLowerTickPrice The square root price of the lower tick edge.
     * @param sqrtUpperTickPrice The square root price of the upper tick edge.
     * @return sqrtPrice The calculated square root price.
     */
    function getSqrtPrice(
        uint256 reserveA,
        uint256 reserveB,
        uint256 sqrtLowerTickPrice,
        uint256 sqrtUpperTickPrice,
        uint256 liquidity
    ) internal pure returns (uint256 sqrtPrice) {
        unchecked {
            if (reserveA == 0) {
                return sqrtLowerTickPrice;
            }
            if (reserveB == 0) {
                return sqrtUpperTickPrice;
            }
            sqrtPrice = Math.sqrt(
                ONE *
                    (reserveA + liquidity.mulDown(sqrtLowerTickPrice)).divDown(
                        reserveB + liquidity.divDown(sqrtUpperTickPrice)
                    )
            );
            sqrtPrice = Math.boundValue(sqrtPrice, sqrtLowerTickPrice, sqrtUpperTickPrice);
        }
    }

    /**
     * @notice Calculate square root price of a tick. Returns left edge of the
     * tick if the tick has no reserves.
     * @param reserveA Tick reserve of token A.
     * @param reserveB Tick reserve of token B.
     * @param sqrtLowerTickPrice The square root price of the lower tick edge.
     * @param sqrtUpperTickPrice The square root price of the upper tick edge.
     * @return sqrtPrice The calculated square root price.
     * @return liquidity The calculated liquidity.
     */
    function getTickSqrtPriceAndL(
        uint256 reserveA,
        uint256 reserveB,
        uint256 sqrtLowerTickPrice,
        uint256 sqrtUpperTickPrice
    ) internal pure returns (uint256 sqrtPrice, uint256 liquidity) {
        liquidity = getTickL(reserveA, reserveB, sqrtLowerTickPrice, sqrtUpperTickPrice);
        sqrtPrice = getSqrtPrice(reserveA, reserveB, sqrtLowerTickPrice, sqrtUpperTickPrice, liquidity);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
// As the copyright holder of this work, Ubiquity Labs retains
// the right to distribute, use, and modify this code under any license of
// their choosing, in addition to the terms of the GPL-v2 or later.
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Low-gas transfer functions.
 */
library TransferLib {
    error TransferFailed(IERC20 token, address to, uint256 amount);
    error TransferFromFailed(IERC20 token, address from, address to, uint256 amount);

    // implementation adapted from
    // https://github.com/transmissions11/solmate/blob/e8f96f25d48fe702117ce76c79228ca4f20206cb/src/utils/SafeTransferLib.sol

    /**
     * @notice Transfer token amount.  Amount is sent from caller address to `to` address.
     */
    function transfer(IERC20 token, address to, uint256 amount) internal {
        bool success;
        assembly ("memory-safe") {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(memPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            // Append arguments. Addresses are assumed clean. Transfer will fail otherwise.
            mstore(add(memPointer, 0x4), to)
            mstore(add(memPointer, 0x24), amount) // Append the "amount" argument.
            // 68 bytes total

            // fail if reverted; only allocate 32 bytes for return to ensure we
            // only use mem slot 0 which is scatch space and memory safe to use.
            success := call(gas(), token, 0, memPointer, 68, 0, 32)
            // handle transfers that return 1/true and ensure the value is from
            // the return and not dirty bits left in the scratch space.
            let returnedOne := and(eq(mload(0), 1), gt(returndatasize(), 31))
            // handle transfers that return nothing
            let noReturn := iszero(returndatasize())
            // good if didn't revert and the return is either empty or true
            success := and(success, or(returnedOne, noReturn))
        }

        if (!success) revert TransferFailed(token, to, amount);
    }

    /**
     * @notice Transfer token amount.  Amount is sent from `from` address to `to` address.
     */
    function transferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bool success;

        assembly ("memory-safe") {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(memPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            // Append arguments. Addresses are assumed clean. Transfer will fail otherwise.
            mstore(add(memPointer, 0x4), from) // Append the "from" argument.
            mstore(add(memPointer, 0x24), to) // Append the "to" argument.
            mstore(add(memPointer, 0x44), amount) // Append the "amount" argument.
            // 100 bytes total

            // fail if reverted; only allocate 32 bytes for return to ensure we
            // only use mem slot 0 which is scatch space and memory safe to use.
            success := call(gas(), token, 0, memPointer, 100, 0, 32)
            // handle transfers that return 1/true and ensure the value is from
            // the return and not dirty bits left in the scratch space.
            let returnedOne := and(eq(mload(0), 1), gt(returndatasize(), 31))
            // handle transfers that return nothing
            let noReturn := iszero(returndatasize())
            // good if didn't revert and the return is either empty or true
            success := and(success, or(returnedOne, noReturn))
        }

        if (!success) revert TransferFromFailed(token, from, to, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {INft} from "@maverick/v2-supplemental/contracts/positionbase/INft.sol";
import {IMulticall} from "@maverick/v2-common/contracts/base/IMulticall.sol";

import {IMaverickV2VotingEscrow} from "./IMaverickV2VotingEscrow.sol";
import {IMaverickV2RewardVault} from "./IMaverickV2RewardVault.sol";
import {IRewardAccounting} from "../rewardbase/IRewardAccounting.sol";

interface IMaverickV2Reward is INft, IMulticall, IRewardAccounting {
    event NotifyRewardAmount(
        address sender,
        IERC20 rewardTokenAddress,
        uint256 amount,
        uint256 duration,
        uint256 rewardRate
    );
    event GetReward(
        address sender,
        uint256 tokenId,
        address recipient,
        uint8 rewardTokenIndex,
        uint256 stakeDuration,
        IERC20 rewardTokenAddress,
        RewardOutput rewardOutput,
        uint256 lockupId
    );
    event UnStake(
        address sender,
        uint256 tokenId,
        uint256 amount,
        address recipient,
        uint256 userBalance,
        uint256 totalSupply
    );
    event Stake(
        address sender,
        address supplier,
        uint256 amount,
        uint256 tokenId,
        uint256 userBalance,
        uint256 totalSupply
    );
    event AddRewardToken(IERC20 rewardTokenAddress, uint8 rewardTokenIndex);
    event RemoveRewardToken(IERC20 rewardTokenAddress, uint8 rewardTokenIndex);
    event ApproveRewardGetter(uint256 tokenId, address getter);

    error RewardDurationOutOfBounds(uint256 duration, uint256 minDuration, uint256 maxDuration);
    error RewardZeroAmount();
    error RewardNotValidRewardToken(IERC20 rewardTokenAddress);
    error RewardNotValidIndex(uint8 index);
    error RewardTokenCannotBeStakingToken(IERC20 stakingToken);
    error RewardTransferNotSupported();
    error RewardNotApprovedGetter(uint256 tokenId, address approved, address getter);
    error RewardUnboostedTimePeriodNotMet(uint256 timestamp, uint256 minTimestamp);

    struct RewardInfo {
        // Timestamp of when the rewards finish
        uint256 finishAt;
        // Minimum of last updated time and reward finish time
        uint256 updatedAt;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Escrowed rewards
        uint256 escrowedReward;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardPerTokenStored;
        // Reward Token to be emitted
        IERC20 rewardToken;
        // ve locking contract
        IMaverickV2VotingEscrow veRewardToken;
        // amount available to push to ve as incentive
        uint128 unboostedAmount;
        // timestamp of unboosted push
        uint256 lastUnboostedPushTimestamp;
    }

    struct ContractInfo {
        // Reward Name
        string name;
        // Reward Symbol
        string symbol;
        // total supply staked
        uint256 totalSupply;
        // staking token
        IERC20 stakingToken;
    }

    struct EarnedInfo {
        // earned
        uint256 earned;
        // reward token
        IERC20 rewardToken;
    }

    struct RewardOutput {
        uint256 amount;
        bool asVe;
        IMaverickV2VotingEscrow veContract;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MAX_DURATION() external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function MIN_DURATION() external view returns (uint256);

    /**
     * @notice This function retrieves the minimum time gap in seconds that
     * must have elasped between calls to `pushUnboostedToVe()`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function UNBOOSTED_MIN_TIME_GAP() external view returns (uint256);

    /**
     * @notice This function retrieves the address of the token used for
     * staking in this reward contract.
     * @return The address of the staking token (IERC20).
     */
    function stakingToken() external view returns (IERC20);

    /**
     * @notice This function retrieves the address of the MaverickV2RewardVault
     * contract associated with this reward contract.
     * @return The address of the IMaverickV2RewardVault contract.
     */
    function vault() external view returns (IMaverickV2RewardVault);

    /**
     * @notice This function retrieves information about all available reward tokens for this reward contract.
     * @return info An array of RewardInfo structs containing details about each reward token.
     */
    function rewardInfo() external view returns (RewardInfo[] memory info);

    /**
     * @notice This function retrieves information about all available reward
     * tokens and overall contract details for this reward contract.
     * @return info An array of RewardInfo structs containing details about each reward token.
     * @return _contractInfo A ContractInfo struct containing overall contract details.
     */
    function contractInfo() external view returns (RewardInfo[] memory info, ContractInfo memory _contractInfo);

    /**
     * @notice This function calculates the total amount of all earned rewards
     * for a specific tokenId across all reward tokens.
     * @param tokenId The address of the tokenId for which to calculate earned rewards.
     * @return earnedInfo An array of EarnedInfo structs containing details about earned rewards for each supported token.
     */
    function earned(uint256 tokenId) external view returns (EarnedInfo[] memory earnedInfo);

    /**
     * @notice This function calculates the total amount of earned rewards for
     * a specific tokenId for a particular reward token.
     * @param tokenId The address of the tokenId for which to calculate earned rewards.
     * @param rewardTokenAddress The address of the specific reward token.
     * @return amount The total amount of earned rewards for the specified token.
     */
    function earned(uint256 tokenId, IERC20 rewardTokenAddress) external view returns (uint256);

    /**
     * @notice This function retrieves the internal index associated with a specific reward token address.
     * @param  rewardToken The address of the reward token to get the index for.
     * @return rewardTokenIndex The internal index of the token within the reward contract (uint8).
     */
    function tokenIndex(IERC20 rewardToken) external view returns (uint8 rewardTokenIndex);

    /**
     * @notice This function retrieves the total number of supported reward tokens in this reward contract.
     * @return count The total number of reward tokens (uint256).
     */
    function rewardTokenCount() external view returns (uint256);

    /**
     * @notice This function transfers a specified amount of reward tokens from
     * the caller to distribute them over a defined duration. The caller will
     * need to approve this rewards contract to make the transfer on the
     * caller's behalf. See `notifyRewardAmount` for details of how the
     * duration is set by the rewards contract.
     * @param rewardToken The address of the reward token to transfer.
     * @param duration The duration (in seconds) over which to distribute the rewards.
     * @param amount The amount of reward tokens to transfer.
     * @return _duration The duration in seconds that the incentives will be distributed over.
     */
    function transferAndNotifyRewardAmount(
        IERC20 rewardToken,
        uint256 duration,
        uint256 amount
    ) external returns (uint256 _duration);

    /**
     * @notice This function notifies the vault to distribute a previously
     * transferred amount of reward tokens over a defined duration. (Assumes
     * tokens are already in the contract).
     * @dev The duration of the distribution may not be the same as the input
     * duration.  If this notify amount is less than the amount already pending
     * disbursement, then this new amount will be distributed as the same rate
     * as the existing rate and that will dictate the duration.  Alternatively,
     * if the amount is more than the pending disbursement, then the input
     * duration will be honored and all pending disbursement tokens will also be
     * distributed at this newly set rate.
     * @param rewardToken The address of the reward token to distribute.
     * @param duration The duration (in seconds) over which to distribute the rewards.
     * @return _duration The duration in seconds that the incentives will be distributed over.
     */
    function notifyRewardAmount(IERC20 rewardToken, uint256 duration) external returns (uint256 _duration);

    /**
     * @notice This function transfers a specified amount of staking tokens
     * from the caller to the staking `vault()` and stakes them on the
     * recipient's behalf.  The user has to approve this reward contract to
     * transfer the staking token on their behalf for this function not to
     * revert.
     * @param tokenId Nft tokenId to stake for the staked tokens.
     * @param _amount The amount of staking tokens to transfer and stake.
     * @return amount The amount of staking tokens staked.  May differ from
     * input if there were unstaked tokens in the vault prior to this call.
     * @return stakedTokenId TokenId where liquidity was staked to.  This may
     * differ from the input tokenIf if the input `tokenId=0`.
     */
    function transferAndStake(
        uint256 tokenId,
        uint256 _amount
    ) external returns (uint256 amount, uint256 stakedTokenId);

    /**
     * @notice This function stakes the staking tokens to the specified
     * tokenId. If `tokenId=0` is passed in, then this function will look up
     * the caller's tokenIds and stake to the zero-index tokenId.  If the user
     * does not yet have a staking NFT tokenId, this function will mint one for
     * the sender and stake to that newly-minted tokenId.
     *
     * @dev The amount staked is derived by looking at the new balance on
     * the `vault()`. So, for staking to yield a non-zero balance, the user
     * will need to have transfered the `stakingToken()` to the `vault()` prior
     * to calling `stake`.  Note, tokens sent to the reward contract instead
     * of the vault will not be stakable and instead will be eligible to be
     * disbursed as rewards to stakers.  This is an advanced usage function.
     * If in doubt about the mechanics of staking, use `transferAndStake()`
     * instead.
     * @param tokenId The address of the tokenId whose tokens to stake.
     * @return amount The amount of staking tokens staked (uint256).
     * @return stakedTokenId TokenId where liquidity was staked to.  This may
     * differ from the input tokenIf if the input `tokenId=0`.
     */
    function stake(uint256 tokenId) external returns (uint256 amount, uint256 stakedTokenId);

    /**
     * @notice This function initiates unstaking of a specified amount of
     * staking tokens for the caller and sends them to a recipient.
     * @param tokenId The address of the tokenId whose tokens to unstake.
     * @param amount The amount of staking tokens to unstake (uint256).
     */
    function unstakeToOwner(uint256 tokenId, uint256 amount) external;

    /**
     * @notice This function initiates unstaking of a specified amount of
     * staking tokens on behalf of a specific tokenId and sends them to a recipient.
     * @dev To unstakeFrom, the caller must have an approval allowance of at
     * least `amount`.  Approvals follow the ERC-721 approval interface.
     * @param tokenId The address of the tokenId whose tokens to unstake.
     * @param recipient The address to which the unstaked tokens will be sent.
     * @param amount The amount of staking tokens to unstake (uint256).
     */
    function unstake(uint256 tokenId, address recipient, uint256 amount) external;

    /**
     * @notice This function retrieves the claimable reward for a specific
     * reward token and stake duration for the caller.
     * @param tokenId The address of the tokenId whose reward to claim.
     * @param rewardTokenIndex The internal index of the reward token.
     * @param stakeDuration The duration (in seconds) for which the rewards were staked.
     * @return rewardOutput A RewardOutput struct containing details about the claimable reward.
     */
    function getRewardToOwner(
        uint256 tokenId,
        uint8 rewardTokenIndex,
        uint256 stakeDuration
    ) external returns (RewardOutput memory rewardOutput);

    /**
     * @notice This function retrieves the claimable reward for a specific
     * reward token, stake duration, and lockup ID for the caller.
     * @param tokenId The address of the tokenId whose reward to claim.
     * @param rewardTokenIndex The internal index of the reward token.
     * @param stakeDuration The duration (in seconds) for which the rewards were staked.
     * @param lockupId The unique identifier for the specific lockup (optional).
     * @return rewardOutput A RewardOutput struct containing details about the claimable reward.
     */
    function getRewardToOwnerForExistingVeLockup(
        uint256 tokenId,
        uint8 rewardTokenIndex,
        uint256 stakeDuration,
        uint256 lockupId
    ) external returns (RewardOutput memory);

    /**
     * @notice This function retrieves the claimable reward for a specific
     * reward token and stake duration for a specified tokenId and sends it to
     * a recipient.  If the reward is staked in the corresponding veToken, a
     * new lockup in the ve token will be created.
     * @param tokenId The address of the tokenId whose reward to claim.
     * @param recipient The address to which the claimed reward will be sent.
     * @param rewardTokenIndex The internal index of the reward token.
     * @param stakeDuration The duration (in seconds) for which the rewards
     * will be staked in the ve contract.
     * @return rewardOutput A RewardOutput struct containing details about the claimable reward.
     */
    function getReward(
        uint256 tokenId,
        address recipient,
        uint8 rewardTokenIndex,
        uint256 stakeDuration
    ) external returns (RewardOutput memory);

    /**
     * @notice This function retrieves a list of all supported tokens in the reward contract.
     * @param includeStakingToken A flag indicating whether to include the staking token in the list.
     * @return tokens An array of IERC20 token addresses.
     */
    function tokenList(bool includeStakingToken) external view returns (IERC20[] memory tokens);

    /**
     * @notice This function retrieves the veToken contract associated with a
     * specific index within the reward contract.
     * @param index The index of the veToken to retrieve.
     * @return output The IMaverickV2VotingEscrow contract associated with the index.
     */
    function veTokenByIndex(uint8 index) external view returns (IMaverickV2VotingEscrow output);

    /**
     * @notice This function retrieves the reward token contract associated
     * with a specific index within the reward contract.
     * @param index The index of the reward token to retrieve.
     * @return output The IERC20 contract associated with the index.
     */
    function rewardTokenByIndex(uint8 index) external view returns (IERC20 output);

    /**
     * @notice This function calculates the boosted amount an tokenId would
     * receive based on their veToken balance and stake duration.
     * @param tokenId The address of the tokenId for which to calculate the boosted amount.
     * @param veToken The IMaverickV2VotingEscrow contract representing the veToken used for boosting.
     * @param rawAmount The raw (unboosted) amount.
     * @param stakeDuration The duration (in seconds) for which the rewards would be staked.
     * @return earnedAmount The boosted amount the tokenId would receive (uint256).
     * @return asVe A boolean indicating whether the boosted amount is
     * staked in the veToken (true) or is disbursed without ve staking required (false).
     */
    function boostedAmount(
        uint256 tokenId,
        IMaverickV2VotingEscrow veToken,
        uint256 rawAmount,
        uint256 stakeDuration
    ) external view returns (uint256 earnedAmount, bool asVe);

    /**
     * @notice This function is used to push unboosted rewards to the veToken
     * contract.  This unboosted reward amount is then distributed to the
     * veToken holders. This function will revert if less than
     * `UNBOOSTED_MIN_TIME_GAP()` seconds have passed since the last call.
     * @param rewardTokenIndex The internal index of the reward token.
     * @return amount The amount of unboosted rewards pushed (uint128).
     * @return timepoint The timestamp associated with the pushed rewards (uint48).
     * @return batchIndex The batch index for the pushed rewards (uint256).
     */
    function pushUnboostedToVe(
        uint8 rewardTokenIndex
    ) external returns (uint128 amount, uint48 timepoint, uint256 batchIndex);

    /**
     * @notice Mints an NFT stake to a user.  This NFT will not possesses any
     * assets until a user `stake`s asset to the NFT tokenId as part of a
     * separate call.
     * @param recipient The address that owns the output NFT
     */
    function mint(address recipient) external returns (uint256 tokenId);

    /**
     * @notice Mints an NFT stake to caller.  This NFT will not possesses any
     * assets until a user `stake`s asset to the NFT tokenId as part of a
     * separate call.
     */
    function mintToSender() external returns (uint256 tokenId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2BoostedPositionFactory} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2BoostedPositionFactory.sol";

import {IMaverickV2VotingEscrowFactory} from "./IMaverickV2VotingEscrowFactory.sol";
import {IMaverickV2VotingEscrow} from "./IMaverickV2VotingEscrow.sol";
import {IMaverickV2Reward} from "./IMaverickV2Reward.sol";

interface IMaverickV2RewardFactory {
    error RewardFactoryNotFactoryBoostedPosition();
    error RewardFactoryTooManyRewardTokens();
    error RewardFactoryRewardAndVeLengthsAreNotEqual();
    error RewardFactoryInvalidVeBaseTokenPair();

    event CreateRewardsContract(
        IERC20 stakeToken,
        IERC20[] rewardTokens,
        IMaverickV2VotingEscrow[] veTokens,
        IMaverickV2Reward rewardsContract,
        bool isFactoryBoostedPosition
    );

    /**
     * @notice This function creates a new MaverickV2Reward contract associated
     * with a specific stake token contract and set of reward and voting
     * escrow tokens.
     * @param stakeToken Token to be staked in reward contract; e.g. a boosted position contract.
     * @param rewardTokens An array of IERC20 token addresses representing the available reward tokens.
     * @param veTokens An array of IMaverickV2VotingEscrow contract addresses
     * representing the associated veTokens for boosting.
     * @return rewardsContract The newly created IMaverickV2Reward contract.
     */
    function createRewardsContract(
        IERC20 stakeToken,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    ) external returns (IMaverickV2Reward rewardsContract);

    /**
     * @notice This function retrieves the address of the MaverickV2BoostedPositionFactory contract.
     * @return factory The address of the IMaverickV2BoostedPositionFactory contract.
     */
    function boostedPositionFactory() external returns (IMaverickV2BoostedPositionFactory);

    /**
     * @notice This function retrieves the address of the MaverickV2VotingEscrowFactory contract.
     * @return factory The address of the IMaverickV2VotingEscrowFactory contract.
     */
    function votingEscrowFactory() external returns (IMaverickV2VotingEscrowFactory);

    /**
     * @notice This function checks if a provided IMaverickV2Reward contract is
     * a valid contract created by this factory.
     * @param reward The IMaverickV2Reward contract to check.
     * @return isFactoryContract True if the contract is a valid factory-created reward contract, False otherwise.
     */
    function isFactoryContract(IMaverickV2Reward reward) external returns (bool);

    /**
     * @notice This function retrieves a list of all MaverickV2Reward contracts
     * associated with a specific staking token contract within a specified
     * range.
     * @param stakeToken Lookup token.
     * @param startIndex The starting index of the list to retrieve.
     * @param endIndex The ending index of the list to retrieve.
     * @return rewardsContract An array of IMaverickV2Reward contracts
     * associated with the BoostedPosition within the specified range.
     */
    function rewardsForStakeToken(
        IERC20 stakeToken,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Reward[] memory rewardsContract);

    /**
     * @notice Returns the number of reward contracts this factory has deployed
     * for a given staking token.
     */
    function rewardsForStakeTokenCount(IERC20 stakeToken) external view returns (uint256 count);

    /**
     * @notice This function retrieves a list of all MaverickV2Reward contracts within a specified range.
     * @param startIndex The starting index of the list to retrieve.
     * @param endIndex The ending index of the list to retrieve.
     * @return rewardsContract An array of IMaverickV2Reward contracts within the specified range.
     */
    function rewards(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Reward[] memory rewardsContract);

    /**
     * @notice Returns the number of reward contracts this factory has deployed.
     */
    function rewardsCount() external view returns (uint256 count);

    /**
     * @notice This function retrieves a list of all MaverickV2Reward contracts
     * within a specified range that have a staking token that is a boosted
     * position from the maverick boosted position contract.
     * @param startIndex The starting index of the list to retrieve.
     * @param endIndex The ending index of the list to retrieve.
     * @return rewardsContract An array of IMaverickV2Reward contracts within the specified range.
     */
    function boostedPositionRewards(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Reward[] memory);

    /**
     * @notice Returns the number of reward contracts where the staking token
     * is a booste position that this factory has deployed.
     */
    function boostedPositionRewardsCount() external view returns (uint256 count);

    /**
     * @notice This function retrieves a list of all MaverickV2Reward contracts
     * within a specified range that have a staking token that is not a boosted
     * position from the maverick boosted position contract.
     * @param startIndex The starting index of the list to retrieve.
     * @param endIndex The ending index of the list to retrieve.
     * @return rewardsContract An array of IMaverickV2Reward contracts within the specified range.
     */
    function nonBoostedPositionRewards(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2Reward[] memory);

    /**
     * @notice Returns the number of reward contracts where the staking token
     * is not a booste position that this factory has deployed.
     */
    function nonBoostedPositionRewardsCount() external view returns (uint256 count);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2BoostedPosition} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2BoostedPosition.sol";
import {IMaverickV2LiquidityManager} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2LiquidityManager.sol";

import {IMaverickV2RewardFactory} from "./IMaverickV2RewardFactory.sol";
import {IMaverickV2VotingEscrowWSync} from "./IMaverickV2VotingEscrowWSync.sol";
import {IMaverickV2Reward} from "./IMaverickV2Reward.sol";
import {IMaverickV2VotingEscrow} from "./IMaverickV2VotingEscrow.sol";

interface IMaverickV2RewardRouter is IMaverickV2LiquidityManager {
    /**
     * @notice This function stakes any new staking token balance that are in
     * the `reward.vault()` for a specified recipient tokenId.  Passing input
     * `tokenId=0` will cause the stake to mint to either the first tokenId for
     * the caller, or a new NFT tokenId if the sender does not yet have one.
     * @param reward The IMaverickV2Reward contract for which to stake.
     * @param tokenId Nft tokenId to stake for the staked tokens.
     * @return amount The amount of staking tokens staked.  May differ from
     * input if there were unstaked tokens in the vault prior to this call.
     * @return stakedTokenId TokenId where liquidity was staked to.  This may
     * differ from the input tokenId if the input `tokenId=0`.
     */
    function stake(
        IMaverickV2Reward reward,
        uint256 tokenId
    ) external payable returns (uint256 amount, uint256 stakedTokenId);

    /**
     * @notice This function retrieves the address of the MaverickV2RewardFactory
     * contract associated with this contract.
     */
    function rewardFactory() external view returns (IMaverickV2RewardFactory);

    /**
     * @notice This function transfers a specified amount of reward tokens from
     * the caller to a reward contract and notifies it to distribute them over
     * a defined duration.
     * @param reward The IMaverickV2Reward contract to notify.
     * @param rewardToken The address of the reward token to transfer.
     * @param duration The duration (in seconds) over which to distribute the rewards.
     * @return _duration The duration in seconds that the incentives will be distributed over.
     */
    function notifyRewardAmount(
        IMaverickV2Reward reward,
        IERC20 rewardToken,
        uint256 duration
    ) external payable returns (uint256 _duration);

    /**
     * @notice This function transfers a specified amount of staking tokens from
     * the caller, stakes them on the recipient's behalf, and
     * associates them with a specified reward contract.
     * @param reward The IMaverickV2Reward contract for which to stake.
     * @param tokenId Nft tokenId to stake for the staked tokens.
     * @param _amount The amount of staking tokens to transfer and stake.
     * @return amount The amount of staking tokens staked.  May differ from
     * input if there were unstaked tokens in the vault prior to this call.
     * @return stakedTokenId TokenId where liquidity was staked to.  This may
     * differ from the input tokenIf if the input `tokenId=0`.
     *
     */
    function transferAndStake(
        IMaverickV2Reward reward,
        uint256 tokenId,
        uint256 _amount
    ) external payable returns (uint256 amount, uint256 stakedTokenId);

    /**
     * @notice This function transfers a specified amount of reward tokens
     *  from the caller and adds them to the reward contract as incentives.
     * @param reward The IMaverickV2Reward contract to notify.
     * @param rewardToken The address of the reward token to transfer.
     * @param duration The duration (in seconds) over which to distribute the rewards.
     * @param amount The amount of staking tokens to stake (uint256).
     * @return _duration The duration in seconds that the incentives will be distributed over.
     */
    function transferAndNotifyRewardAmount(
        IMaverickV2Reward reward,
        IERC20 rewardToken,
        uint256 duration,
        uint256 amount
    ) external payable returns (uint256 _duration);

    /**
     * @notice This function creates a new BoostedPosition contract, adds
     * liquidity to a pool using the provided parameters, stakes the received
     * LP tokens, and associates them with a specified reward contract.
     * @param recipient The address to which the minted LP tokens will be
     * credited.
     * @param params A struct containing parameters for creating the
     * BoostedPosition (see IMaverickV2PoolLens.CreateBoostedPositionInputs).
     * @param rewardTokens An array of IERC20 token addresses representing the
     * available reward tokens for the staked LP position.
     * @param veTokens An array of IMaverickV2VotingEscrow contract addresses
     * representing the veTokens used for boosting.
     * @return boostedPosition The created IMaverickV2BoostedPosition contract.
     * @return mintedLpAmount The amount of LP tokens minted from the added liquidity.
     * @return tokenAAmount The amount of token A deposited for liquidity.
     * @return tokenBAmount The amount of token B deposited for liquidity.
     * @return stakeAmount The amount of LP tokens staked in the reward contract.
     * @return reward The IMaverickV2Reward contract.
     * @return tokenId Token on reward contract where user liquidity was staked.
     */
    function createBoostedPositionAndAddLiquidityAndStake(
        address recipient,
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    )
        external
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint256 stakeAmount,
            IMaverickV2Reward reward,
            uint256 tokenId
        );

    /**
     * @notice This function is similar to
     * `createBoostedPositionAndAddLiquidityAndStake` but stakes the minted LP
     * tokens for the caller (msg.sender) instead of a specified recipient.
     * @param params A struct containing parameters for creating the
     * BoostedPosition (see IMaverickV2PoolLens.CreateBoostedPositionInputs).
     * @param rewardTokens An array of IERC20 token addresses representing the
     * available reward tokens for the staked LP position.
     * @param veTokens An array of IMaverickV2VotingEscrow contract addresses
     * representing the veTokens used for boosting.
     * @return boostedPosition The created IMaverickV2BoostedPosition contract.
     * @return mintedLpAmount The amount of LP tokens minted from the added liquidity.
     * @return tokenAAmount The amount of token A deposited for liquidity.
     * @return tokenBAmount The amount of token B deposited for liquidity.
     * @return stakeAmount The amount of LP tokens staked in the reward contract.
     * @return reward The IMaverickV2Reward contract associated with the staked LP position.
     * @return tokenId Token on reward contract where user liquidity was staked.
     */
    function createBoostedPositionAndAddLiquidityAndStakeToSender(
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    )
        external
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint256 stakeAmount,
            IMaverickV2Reward reward,
            uint256 tokenId
        );

    /**
     * @notice This function adds liquidity to a pool using a pre-created
     * BoostedPosition contract, stakes the received LP tokens, and associates
     * them with a specified reward contract.
     * @param tokenId Token on reward contract where liquidity is to be staked.
     * @param boostedPosition The IMaverickV2BoostedPosition contract representing the existing boosted position.
     * @param packedSqrtPriceBreaks A packed representation of sqrt price
     * breaks for the liquidity range (see
     * IMaverickV2Pool.IAddLiquidityParams).
     * @param packedArgs Additional packed arguments for adding liquidity (see
     * IMaverickV2Pool.IAddLiquidityParams).
     * @param reward The IMaverickV2Reward contract for which to stake the LP tokens.
     * @return mintedLpAmount The amount of LP tokens minted from the added liquidity.
     * @return tokenAAmount The amount of token A deposited for liquidity.
     * @return tokenBAmount The amount of token B deposited for liquidity.
     * @return stakeAmount The amount of LP tokens staked in the reward contract.
     *
     */
    function addLiquidityAndMintBoostedPositionAndStake(
        uint256 tokenId,
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs,
        IMaverickV2Reward reward
    )
        external
        payable
        returns (uint256 mintedLpAmount, uint256 tokenAAmount, uint256 tokenBAmount, uint256 stakeAmount);

    /**
     * @notice This function is similar to
     * `addLiquidityAndMintBoostedPositionAndStake` but uses the caller
     * (msg.sender) as the recipient for the minted reward stake.
     * @param sendersTokenIndex Token index of sender on the reward contract to
     * mint to.  If sender does not have a token already, then this call will
     * mint one for the user.
     * @param boostedPosition The IMaverickV2BoostedPosition contract representing the existing boosted position.
     * @param packedSqrtPriceBreaks A packed representation of sqrt price breaks for the liquidity range (see IMaverickV2Pool.IAddLiquidityParams).
     * @param packedArgs Additional packed arguments for adding liquidity (see IMaverickV2Pool.IAddLiquidityParams).
     * @param reward The IMaverickV2Reward contract for which to stake the LP tokens.
     * @return mintedLpAmount The amount of LP tokens minted from the added liquidity.
     * @return tokenAAmount The amount of token A deposited for liquidity.
     * @return tokenBAmount The amount of token B deposited for liquidity.
     * @return stakeAmount The amount of LP tokens staked in the reward contract.
     * @return tokenId Token on reward contract where user liquidity was staked.
     */
    function addLiquidityAndMintBoostedPositionAndStakeToSender(
        uint256 sendersTokenIndex,
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs,
        IMaverickV2Reward reward
    )
        external
        payable
        returns (
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint256 stakeAmount,
            uint256 tokenId
        );

    /**
     * @notice This function syncs the balance of a staker's votes on the
     * legacy ve mav contract with the new V2 ve mav contract.
     * @param ve The IMaverickV2VotingEscrowWSync contract to interact with.
     * @param staker The address of the user whose veToken lock may need syncing.
     * @param  legacyLockupIndexes A list of indexes to synchronize from the
     * legacy veMav to the V2 ve contract.
     *
     */
    function sync(
        IMaverickV2VotingEscrowWSync ve,
        address staker,
        uint256[] memory legacyLockupIndexes
    ) external returns (uint256[] memory newBalance);

    function mintTokenInRewardToSender(IMaverickV2Reward reward) external payable returns (uint256 tokenId);

    function mintTokenInReward(IMaverickV2Reward reward, address recipient) external payable returns (uint256 tokenId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMaverickV2RewardVault {
    error RewardVaultUnauthorizedAccount(address caller, address owner);

    /**
     * @notice This function allows the owner of the reward vault to withdraw a
     * specified amount of staking tokens to a recipient address.  If non-owner
     * calls this function, it will revert.
     * @param recipient The address to which the withdrawn staking tokens will be sent.
     * @param amount The amount of staking tokens to withdraw.
     */
    function withdraw(address recipient, uint256 amount) external;

    /**
     * @notice This function retrieves the address of the owner of the reward
     * vault contract.
     */
    function owner() external view returns (address);

    /**
     * @notice This function retrieves the address of the ERC20 token used for
     * staking within the reward vault.
     */
    function stakingToken() external view returns (IERC20);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";

import {IHistoricalBalance} from "../votingescrowbase/IHistoricalBalance.sol";

interface IMaverickV2VotingEscrowBase is IVotes, IHistoricalBalance {
    error VotingEscrowTransferNotSupported();
    error VotingEscrowInvalidAddress(address);
    error VotingEscrowInvalidAmount(uint256);
    error VotingEscrowInvalidDuration(uint256 duration, uint256 minDuration, uint256 maxDuration);
    error VotingEscrowInvalidEndTime(uint256 newEnd, uint256 oldEnd);
    error VotingEscrowStakeStillLocked(uint256 currentTime, uint256 endTime);
    error VotingEscrowStakeAlreadyRedeemed();
    error VotingEscrowNotApprovedExtender(address account, address extender, uint256 lockupId);
    error VotingEscrowIncentiveAlreadyClaimed(address account, uint256 batchIndex);
    error VotingEscrowNoIncentivesToClaim(address account, uint256 batchIndex);
    error VotingEscrowInvalidExtendIncentiveToken(IERC20 incentiveToken);
    error VotingEscrowNoSupplyAtTimepoint();
    error VotingEscrowIncentiveTimepointInFuture(uint256 timestamp, uint256 claimTimepoint);

    event Stake(address indexed user, uint256 lockupId, Lockup);
    event Unstake(address indexed user, uint256 lockupId, Lockup);
    event ExtenderApproval(address staker, address extender, uint256 lockupId, bool newState);
    event ClaimIncentiveBatch(uint256 batchIndex, address account, uint256 claimAmount);
    event CreateNewIncentiveBatch(
        address user,
        uint256 amount,
        uint256 timepoint,
        uint256 stakeDuration,
        IERC20 incentiveToken
    );

    struct Lockup {
        uint128 amount;
        uint128 end;
        uint256 votes;
    }

    struct ClaimInformation {
        bool timepointInPast;
        bool hasClaimed;
        uint128 claimAmount;
    }

    struct BatchInformation {
        uint128 totalIncentives;
        uint128 stakeDuration;
        uint48 claimTimepoint;
        IERC20 incentiveToken;
    }

    struct TokenIncentiveTotals {
        uint128 totalIncentives;
        uint128 claimedIncentives;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MIN_STAKE_DURATION() external returns (uint256 duration);

    // solhint-disable-next-line func-name-mixedcase
    function MAX_STAKE_DURATION() external returns (uint256 duration);

    // solhint-disable-next-line func-name-mixedcase
    function YEAR_BASE() external returns (uint256);

    /**
     * @notice This function retrieves the address of the ERC20 token used as the base token for staking and rewards.
     * @return baseToken The address of the IERC20 base token contract.
     */
    function baseToken() external returns (IERC20);

    /**
     * @notice This function retrieves the starting timestamp. This may be used
     * for reward calculations or other time-based logic.
     */
    function startTimestamp() external returns (uint256 timestamp);

    /**
     * @notice This function retrieves the details of a specific lockup for a given staker and lockup index.
     * @param staker The address of the staker for which to retrieve the lockup details.
     * @param index The index of the lockup within the staker's lockup history.
     * @return lockup A Lockup struct containing details about the lockup (see struct definition for details).
     */
    function getLockup(address staker, uint256 index) external view returns (Lockup memory lockup);

    /**
     * @notice This function retrieves the total number of lockups associated with a specific staker.
     * @param staker The address of the staker for which to retrieve the lockup count.
     * @return count The total number of lockups for the staker.
     */
    function lockupCount(address staker) external view returns (uint256 count);

    /**
     * @notice This function simulates a lockup scenario, providing details about the resulting lockup structure for a specified amount and duration.
     * @param amount The amount of tokens to be locked.
     * @param duration The duration of the lockup period.
     * @return lockup A Lockup struct containing details about the simulated lockup (see struct definition for details).
     */
    function previewVotes(uint128 amount, uint256 duration) external view returns (Lockup memory lockup);

    /**
     * @notice This function grants approval for a designated extender contract to manage a specific lockup on behalf of the staker.
     * @param extender The address of the extender contract to be approved.
     * @param lockupId The ID of the lockup for which to grant approval.
     */
    function approveExtender(address extender, uint256 lockupId) external;

    /**
     * @notice This function revokes approval previously granted to an extender contract for managing a specific lockup.
     * @param extender The address of the extender contract whose approval is being revoked.
     * @param lockupId The ID of the lockup for which to revoke approval.
     */
    function revokeExtender(address extender, uint256 lockupId) external;

    /**
     * @notice This function checks whether a specific account has been approved by a staker to manage a particular lockup through an extender contract.
     * @param account The address of the account to check for approval (may be the extender or another account).
     * @param extender The address of the extender contract for which to check approval.
     * @param lockupId The ID of the lockup to verify approval for.
     * @return isApproved True if the account is approved for the lockup, False otherwise (bool).
     */
    function isApprovedExtender(address account, address extender, uint256 lockupId) external view returns (bool);

    /**
     * @notice This function extends the lockup period for the caller (msg.sender) for a specified lockup ID, adding a new duration and amount.
     * @param lockupId The ID of the lockup to be extended.
     * @param duration The additional duration to extend the lockup by.
     * @param amount The additional amount of tokens to be locked.
     * @return newLockup A Lockup struct containing details about the newly extended lockup (see struct definition for details).
     */
    function extendForSender(
        uint256 lockupId,
        uint256 duration,
        uint128 amount
    ) external returns (Lockup memory newLockup);

    /**
     * @notice This function extends the lockup period for a specified account, adding a new duration and amount. The caller (msg.sender) must be authorized to manage the lockup through an extender contract.
     * @param account The address of the account whose lockup is being extended.
     * @param lockupId The ID of the lockup to be extended.
     * @param duration The additional duration to extend the lockup by.
     * @param amount The additional amount of tokens to be locked.
     * @return newLockup A Lockup struct containing details about the newly extended lockup (see struct definition for details).
     */
    function extendForAccount(
        address account,
        uint256 lockupId,
        uint256 duration,
        uint128 amount
    ) external returns (Lockup memory newLockup);

    /**
     * @notice This function merges multiple lockups associated with the caller
     * (msg.sender) into a single new lockup.
     * @param lockupIds An array containing the IDs of the lockups to be merged.
     * @return newLockup A Lockup struct containing details about the newly merged lockup (see struct definition for details).
     */
    function merge(uint256[] memory lockupIds) external returns (Lockup memory newLockup);

    /**
     * @notice This function unstakes the specified lockup ID for the caller (msg.sender), returning the details of the unstaked lockup.
     * @param lockupId The ID of the lockup to be unstaked.
     * @param to The address to which the unstaked tokens should be sent (optional, defaults to msg.sender).
     * @return lockup A Lockup struct containing details about the unstaked lockup (see struct definition for details).
     */
    function unstake(uint256 lockupId, address to) external returns (Lockup memory lockup);

    /**
     * @notice This function is a simplified version of `unstake` that automatically sends the unstaked tokens to the caller (msg.sender).
     * @param lockupId The ID of the lockup to be unstaked.
     * @return lockup A Lockup struct containing details about the unstaked lockup (see struct definition for details).
     */
    function unstakeToSender(uint256 lockupId) external returns (Lockup memory lockup);

    /**
     * @notice This function stakes a specified amount of tokens for the caller
     * (msg.sender) for a defined duration.
     * @param amount The amount of tokens to be staked.
     * @param duration The duration of the lockup period.
     * @return lockup A Lockup struct containing details about the newly
     * created lockup (see struct definition for details).
     */
    function stakeToSender(uint128 amount, uint256 duration) external returns (Lockup memory lockup);

    /**
     * @notice This function stakes a specified amount of tokens for a defined
     * duration, allowing the caller (msg.sender) to specify an optional
     * recipient for the staked tokens.
     * @param amount The amount of tokens to be staked.
     * @param duration The duration of the lockup period.
     * @param to The address to which the staked tokens will be credited (optional, defaults to msg.sender).
     * @return lockup A Lockup struct containing details about the newly
     * created lockup (see struct definition for details).
     */
    function stake(uint128 amount, uint256 duration, address to) external returns (Lockup memory);

    /**
     * @notice This function retrieves the total incentive information for a specific ERC-20 token.
     * @param token The address of the ERC20 token for which to retrieve incentive totals.
     * @return totals A TokenIncentiveTotals struct containing details about
     * the token's incentives (see struct definition for details).
     */
    function incentiveTotals(IERC20 token) external view returns (TokenIncentiveTotals memory);

    /**
     * @notice This function retrieves the total number of created incentive batches.
     * @return count The total number of incentive batches.
     */
    function incentiveBatchCount() external view returns (uint256);

    /**
     * @notice This function retrieves claim information for a specific account and incentive batch index.
     * @param account The address of the account for which to retrieve claim information.
     * @param batchIndex The index of the incentive batch for which to retrieve
     * claim information.
     * @return claimInformation A ClaimInformation struct containing details about the
     * account's claims for the specified batch (see struct definition for
     * details).
     * @return batchInformation A BatchInformation struct containing details about the
     * specified batch (see struct definition for details).
     */
    function claimAndBatchInformation(
        address account,
        uint256 batchIndex
    ) external view returns (ClaimInformation memory claimInformation, BatchInformation memory batchInformation);

    /**
     * @notice This function retrieves batch information for a incentive batch index.
     * @param batchIndex The index of the incentive batch for which to retrieve
     * claim information.
     * @return info A BatchInformation struct containing details about the
     * specified batch (see struct definition for details).
     */
    function incentiveBatchInformation(uint256 batchIndex) external view returns (BatchInformation memory info);

    /**
     * @notice This function allows claiming rewards from a specific incentive
     * batch while simultaneously extending a lockup with the claimed tokens.
     * @param batchIndex The index of the incentive batch from which to claim rewards.
     * @param lockupId The ID of the lockup to be extended with the claimed tokens.
     * @return lockup A Lockup struct containing details about the updated
     * lockup after extension (see struct definition for details).
     * @return claimAmount The amount of tokens claimed from the incentive batch.
     */
    function claimFromIncentiveBatchAndExtend(
        uint256 batchIndex,
        uint256 lockupId
    ) external returns (Lockup memory lockup, uint128 claimAmount);

    /**
     * @notice This function allows claiming rewards from a specific incentive
     * batch, without extending any lockups.
     * @param batchIndex The index of the incentive batch from which to claim rewards.
     * @return lockup A Lockup struct containing details about the user's
     * lockup that might have been affected by the claim (see struct definition
     * for details).
     * @return claimAmount The amount of tokens claimed from the incentive batch.
     */
    function claimFromIncentiveBatch(uint256 batchIndex) external returns (Lockup memory lockup, uint128 claimAmount);

    /**
     * @notice This function creates a new incentive batch for a specified amount
     * of incentive tokens, timepoint, stake duration, and associated ERC-20
     * token. An incentive batch is a reward of incentives put up by the
     * caller at a certain timepoint.  The incentive batch is claimable by ve
     * holders after the timepoint has passed.  The ve holders will receive
     * their incentive pro rata of their vote balance (`pastbalanceOf`) at that
     * timepoint.  The incentivizer can specify that users have to stake the
     * resulting incentive for a given `stakeDuration` number of seconds.
     * `stakeDuration` can either be zero, meaning that no staking is required
     * on redemption, or can be a number between `MIN_STAKE_DURATION()` and
     * `MAX_STAKE_DURATION()`.
     * @param amount The total amount of incentive tokens to be distributed in the batch.
     * @param timepoint The timepoint at which the incentive batch starts accruing rewards.
     * @param stakeDuration The duration of the lockup period required to be
     * eligible for the incentive batch rewards.
     * @param incentiveToken The address of the ERC20 token used for the incentive rewards.
     * @return index The index of the newly created incentive batch.
     */
    function createIncentiveBatch(
        uint128 amount,
        uint48 timepoint,
        uint128 stakeDuration,
        IERC20 incentiveToken
    ) external returns (uint256 index);
}

interface IMaverickV2VotingEscrow is IMaverickV2VotingEscrowBase, IERC20Metadata, IERC6372 {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IMaverickV2VotingEscrow} from "./IMaverickV2VotingEscrow.sol";

interface IMaverickV2VotingEscrowFactory {
    error VotingEscrowTokenAlreadyExists(IERC20 baseToken, IMaverickV2VotingEscrow veToken);

    event CreateVotingEscrow(IERC20 baseToken, IMaverickV2VotingEscrow veToken);

    /**
     * @notice This function retrieves the address of the legacy Maverick V1
     * Voting Escrow (veMAV) token.  The address will be zero for blockchains
     * where this contract is deployed that do not have a legacy MAV contract
     * deployed.
     * @return legacyVeMav The address of the IERC20 legacy veMav token.
     */
    function legacyVeMav() external view returns (IERC20);

    /**
     * @notice This function checks whether a provided IMaverickV2VotingEscrow
     * contract address was created by this factory.
     * @param veToken The address of the IMaverickV2VotingEscrow contract to be checked.
     * @return isFactoryToken True if the veToken was created by this factory, False otherwise (bool).
     */
    function isFactoryToken(IMaverickV2VotingEscrow veToken) external view returns (bool);

    /**
     * @notice This function creates a new Maverick V2 Voting Escrow (veToken)
     * contract for a specified ERC20 base token.
     * @dev Once the ve contract is created, it will call `name()` and
     * `symbol()` on the `baseToken`.  If those functions do not exist, the ve
     * creation will revert.
     * @param baseToken The address of the ERC-20 token to be used as the base token for the new veToken.
     * @return veToken The address of the newly created IMaverickV2VotingEscrow contract.
     */
    function createVotingEscrow(IERC20 baseToken) external returns (IMaverickV2VotingEscrow veToken);

    /**
     * @notice This function retrieves a paginated list of existing Maverick V2
     * Voting Escrow (veToken) contracts within a specified index range.
     * @param startIndex The starting index for the desired range of veTokens.
     * @param endIndex The ending index for the desired range of veTokens.
     * @return votingEscrows An array of IMaverickV2VotingEscrow addresses
     * representing the veTokens within the specified range.
     */
    function votingEscrows(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2VotingEscrow[] memory votingEscrows);

    /**
     * @notice This function retrieves the total number of deployed Maverick V2
     * Voting Escrow (veToken) contracts.
     * @return count The total number of veTokens.
     */
    function votingEscrowsCount() external view returns (uint256 count);

    /**
     * @notice This function retrieves the address of the existing Maverick V2
     * Voting Escrow (veToken) contract associated with a specific ERC20 base
     * token.
     * @param baseToken The address of the ERC-20 base token for which to retrieve the veToken address.
     * @return veToken The address of the IMaverickV2VotingEscrow contract
     * associated with the base token, or the zero address if none exists.
     */
    function veForBaseToken(IERC20 baseToken) external view returns (IMaverickV2VotingEscrow veToken);

    /**
     * @notice This function retrieves the default base token used for creating
     * new voting escrow contracts.  This state variable is only used
     * temporarily when a new veToken is deployed.
     * @return baseToken The address of the default ERC-20 base token.
     */
    function baseTokenParameter() external returns (IERC20);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMaverickV2VotingEscrowWSync {
    error VotingEscrowLockupEndTooShortToSync(uint256 legacyLockupEnd, uint256 minimumLockupEnd);

    event Sync(address staker, uint256 legacyLockupIndex, uint256 newBalance);

    /**
     * @notice This function retrieves the minimum lockup duration required for
     * a legacy lockup to be eligible for synchronization.
     * @return minSyncDuration The minimum allowed lockup end time.
     */
    // solhint-disable-next-line func-name-mixedcase
    function MIN_SYNC_DURATION() external pure returns (uint256 minSyncDuration);

    /**
     * @notice This function retrieves the address of the legacy Maverick V1
     * Voting Escrow (veMav) token.
     * @return legacyVeMav The address of the IERC20 legacy veMav token.
     */
    function legacyVeMav() external view returns (IERC20);

    /**
     * @notice This function retrieves the synced balance for a specific legacy lockup index of a user.
     * @param staker The address of the user for whom to retrieve the synced balance.
     * @param legacyLockupIndex The index of the legacy lockup for which to
     * retrieve the synced balance.
     * @return balance The synced balance associated with the legacy lockup.
     */
    function syncBalances(address staker, uint256 legacyLockupIndex) external view returns (uint256 balance);

    /**
     * @notice This function synchronizes a specific legacy lockup index for a
     * user within the contract.  If the legacy lockup.end is not at least
     * `block.timestamp + MIN_SYNC_DURATION()`, this function will revert.
     * @param staker The address of the user for whom to perform synchronization.
     * @param legacyLockupIndex The index of the legacy lockup to be
     * synchronized.
     * @return newBalance The new balance resulting from the synchronization
     * process.
     */
    function sync(address staker, uint256 legacyLockupIndex) external returns (uint256 newBalance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";

import {MaverickV2LiquidityManager} from "@maverick/v2-supplemental/contracts/MaverickV2LiquidityManager.sol";
import {IMaverickV2PoolLens} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2BoostedPosition} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2BoostedPosition.sol";
import {IWETH9} from "@maverick/v2-supplemental/contracts/paymentbase/IWETH9.sol";
import {IMaverickV2Position} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2Position.sol";
import {IMaverickV2BoostedPositionFactory} from "@maverick/v2-supplemental/contracts/interfaces/IMaverickV2BoostedPositionFactory.sol";

import {IMaverickV2Reward} from "./interfaces/IMaverickV2Reward.sol";
import {IMaverickV2RewardRouter} from "./interfaces/IMaverickV2RewardRouter.sol";
import {IMaverickV2RewardFactory} from "./interfaces/IMaverickV2RewardFactory.sol";
import {IMaverickV2VotingEscrow} from "./interfaces/IMaverickV2VotingEscrow.sol";
import {IMaverickV2VotingEscrowWSync} from "./interfaces/IMaverickV2VotingEscrowWSync.sol";

/**
 * @notice Liquidity and Reward contract to facilitate multi-step interactions
 * with adding and staking liquidity in Maverick V2.  This contracts inherits
 * all of the functionality of `MaverickV2LiquidityManager` that allows the
 * creation of pools and BPs and adds mechanisms to interact with the various
 * reward and ve functionality that are present in v2-rewards.  All of the
 * functions are specified as `payable` to enable multicall transactions that
 * involve functions that require ETH and those that do not.
 */
contract MaverickV2RewardRouter is IMaverickV2RewardRouter, MaverickV2LiquidityManager {
    using SafeERC20 for IERC20;

    /// @inheritdoc IMaverickV2RewardRouter
    IMaverickV2RewardFactory public immutable rewardFactory;

    constructor(
        IMaverickV2Factory _factory,
        IWETH9 _weth,
        IMaverickV2Position _position,
        IMaverickV2BoostedPositionFactory _boostedPositionFactory,
        IMaverickV2RewardFactory _rewardFactory
    ) MaverickV2LiquidityManager(_factory, _weth, _position, _boostedPositionFactory) {
        rewardFactory = _rewardFactory;
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function stake(
        IMaverickV2Reward reward,
        uint256 tokenId
    ) public payable returns (uint256 amount, uint256 stakedTokenId) {
        stakedTokenId = tokenId;
        if (stakedTokenId == 0) {
            if (reward.tokenOfOwnerByIndexExists(msg.sender, 0)) {
                stakedTokenId = reward.tokenOfOwnerByIndex(msg.sender, 0);
            } else {
                stakedTokenId = reward.mint(msg.sender);
            }
        }
        return reward.stake(stakedTokenId);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function transferAndStake(
        IMaverickV2Reward reward,
        uint256 tokenId,
        uint256 _amount
    ) public payable returns (uint256 amount, uint256 stakedTokenId) {
        reward.stakingToken().safeTransferFrom(msg.sender, address(reward.vault()), _amount);
        return stake(reward, tokenId);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function notifyRewardAmount(
        IMaverickV2Reward reward,
        IERC20 rewardToken,
        uint256 duration
    ) public payable returns (uint256 _duration) {
        return reward.notifyRewardAmount(rewardToken, duration);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function transferAndNotifyRewardAmount(
        IMaverickV2Reward reward,
        IERC20 rewardToken,
        uint256 duration,
        uint256 amount
    ) public payable returns (uint256 _duration) {
        rewardToken.safeTransferFrom(msg.sender, address(reward), amount);
        return reward.notifyRewardAmount(rewardToken, duration);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function createBoostedPositionAndAddLiquidityAndStake(
        address recipient,
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    )
        public
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint256 stakeAmount,
            IMaverickV2Reward reward,
            uint256 tokenId
        )
    {
        (boostedPosition, mintedLpAmount, tokenAAmount, tokenBAmount) = createBoostedPositionAndAddLiquidity(
            address(this),
            params
        );
        reward = rewardFactory.createRewardsContract(boostedPosition, rewardTokens, veTokens);
        tokenId = reward.mint(recipient);
        boostedPosition.transfer(address(reward.vault()), boostedPosition.balanceOf(address(this)));
        (stakeAmount, ) = reward.stake(tokenId);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function createBoostedPositionAndAddLiquidityAndStakeToSender(
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params,
        IERC20[] memory rewardTokens,
        IMaverickV2VotingEscrow[] memory veTokens
    )
        public
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint256 stakeAmount,
            IMaverickV2Reward reward,
            uint256 tokenId
        )
    {
        return createBoostedPositionAndAddLiquidityAndStake(msg.sender, params, rewardTokens, veTokens);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function addLiquidityAndMintBoostedPositionAndStake(
        uint256 tokenId,
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs,
        IMaverickV2Reward reward
    ) public payable returns (uint256 mintedLpAmount, uint256 tokenAAmount, uint256 tokenBAmount, uint256 stakeAmount) {
        (mintedLpAmount, tokenAAmount, tokenBAmount) = addLiquidityAndMintBoostedPosition(
            address(reward.vault()),
            boostedPosition,
            packedSqrtPriceBreaks,
            packedArgs
        );
        (stakeAmount, ) = reward.stake(tokenId);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function addLiquidityAndMintBoostedPositionAndStakeToSender(
        uint256 sendersTokenIndex,
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs,
        IMaverickV2Reward reward
    )
        public
        payable
        returns (
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint256 stakeAmount,
            uint256 tokenId
        )
    {
        if (reward.tokenOfOwnerByIndexExists(msg.sender, sendersTokenIndex)) {
            tokenId = reward.tokenOfOwnerByIndex(msg.sender, sendersTokenIndex);
        } else {
            tokenId = reward.mint(msg.sender);
        }

        (mintedLpAmount, tokenAAmount, tokenBAmount, stakeAmount) = addLiquidityAndMintBoostedPositionAndStake(
            tokenId,
            boostedPosition,
            packedSqrtPriceBreaks,
            packedArgs,
            reward
        );
    }

    function mintTokenInRewardToSender(IMaverickV2Reward reward) public payable returns (uint256 tokenId) {
        tokenId = reward.mint(msg.sender);
    }

    function mintTokenInReward(IMaverickV2Reward reward, address recipient) public payable returns (uint256 tokenId) {
        tokenId = reward.mint(recipient);
    }

    /// @inheritdoc IMaverickV2RewardRouter
    function sync(
        IMaverickV2VotingEscrowWSync ve,
        address staker,
        uint256[] memory legacyLockupIndexes
    ) public returns (uint256[] memory newBalance) {
        uint256 length = legacyLockupIndexes.length;
        newBalance = new uint256[](length);
        for (uint256 k; k < length; k++) {
            newBalance[k] = ve.sync(staker, k);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

interface IRewardAccounting {
    error InsufficientBalance(uint256 tokenId, uint256 currentBalance, uint256 value);

    /**
     * @notice Balance of stake for a given `tokenId` account.
     */
    function stakeBalanceOf(uint256 tokenId) external view returns (uint256 balance);

    /**
     * @notice Sum of all balances across all tokenIds.
     */
    function stakeTotalSupply() external view returns (uint256 supply);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

interface IHistoricalBalance {
    /**
     * @notice This function retrieves the historical balance of an account at
     * a specific point in time.
     * @param account The address of the account for which to retrieve the
     * historical balance.
     * @param timepoint The timepoint (block number or timestamp depending on
     * implementation) at which to query the balance (uint256).
     * @return balance The balance of the account at the specified timepoint.
     */
    function getPastBalanceOf(address account, uint256 timepoint) external view returns (uint256 balance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {IChecks} from "./IChecks.sol";
import {PoolInspection} from "../libraries/PoolInspection.sol";

abstract contract Checks is IChecks {
    /// @inheritdoc IChecks
    function checkSqrtPrice(IMaverickV2Pool pool, uint256 minSqrtPrice, uint256 maxSqrtPrice) public payable {
        uint256 sqrtPrice = PoolInspection.poolSqrtPrice(pool);
        if (sqrtPrice < minSqrtPrice || sqrtPrice > maxSqrtPrice)
            revert PositionExceededPriceBounds(sqrtPrice, minSqrtPrice, maxSqrtPrice);
    }

    /// @inheritdoc IChecks
    function checkDeadline(uint256 deadline) public payable {
        if (block.timestamp > deadline) revert PositionDeadlinePassed(deadline, block.timestamp);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

interface IChecks {
    error PositionExceededPriceBounds(uint256 sqrtPrice, uint256 minSqrtPrice, uint256 maxSqrtPrice);
    error PositionDeadlinePassed(uint256 deadline, uint256 blockTimestamp);

    /**
     * @notice Function to check if the price of a pool is within specified bounds.
     * @param pool The MaverickV2Pool contract to check.
     * @param minSqrtPrice The minimum acceptable square root price.
     * @param maxSqrtPrice The maximum acceptable square root price.
     */
    function checkSqrtPrice(IMaverickV2Pool pool, uint256 minSqrtPrice, uint256 maxSqrtPrice) external payable;

    /**
     * @notice Function to check if a given deadline has passed.
     * @param deadline The timestamp representing the deadline.
     */
    function checkDeadline(uint256 deadline) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

interface IMigrateBins {
    function migrateBinsUpStack(IMaverickV2Pool pool, uint32[] calldata binIds, uint32 maxRecursion) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {IMigrateBins} from "./IMigrateBins.sol";

abstract contract MigrateBins is IMigrateBins {
    /**
     * @dev Migrates bins up the stack in the pool.
     * @param pool The MaverickV2Pool contract.
     * @param binIds An array of bin IDs to migrate.
     * @param maxRecursion The maximum recursion depth.
     */
    function migrateBinsUpStack(IMaverickV2Pool pool, uint32[] memory binIds, uint32 maxRecursion) public payable {
        for (uint256 i = 0; i < binIds.length; i++) {
            pool.migrateBinUpStack(binIds[i], maxRecursion);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {IMulticall} from "@maverick/v2-common/contracts/base/IMulticall.sol";

import {IChecks} from "../base/IChecks.sol";

interface IBoostedPositionBase is IERC20Metadata, IChecks, IMulticall {
    /**
     * @notice BP Pool.
     */
    function pool() external view returns (IMaverickV2Pool pool_);

    /**
     * @notice BP Bin kind (static, right, left, both).
     */
    function kind() external view returns (uint8 kind_);

    /**
     * @notice Number of bins in the BP.
     */
    function binCount() external view returns (uint8 binCount_);

    /**
     * @notice Liquidity balance in BP bins since last mint/burn operation.
     */
    function getBinBalances() external view returns (uint128[] memory binBalances_);

    /**
     * @notice Liquidity balance in given BP bin since last mint/burn
     * operation.
     */
    function binBalances(uint256 index) external view returns (uint128 binBalance);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IBoostedPositionBase} from "../boostedpositionbase/IBoostedPositionBase.sol";

interface IMaverickV2BoostedPosition is IBoostedPositionBase {
    event BoostedPositionMigrateBinLiquidity(uint32 currentBinId, uint32 newBinId, uint128 newBinBalance);

    error BoostedPositionTooLittleLiquidityAdded(uint256 binIdIndex, uint32 binId, uint128 required, uint128 available);
    error BoostedPositionMovementBinNotMigrated();

    /**
     * @notice Mints BP LP position to recipient.  User has to add liquidity to
     * BP contract before making this call as this mint function simply assigns
     * any new liquidity that this BP possesses in the pool to the recipient.
     * Accordingly, this function should only be called in the same transaction
     * where liquidity has been added to a pool as part of a multicall or
     * through a router/manager contract.
     */
    function mint(address recipient) external returns (uint256 deltaSupply);

    /**
     * @notice Burns BP LP positions and redeems the underlying A/B token to the recipient.
     */
    function burn(address recipient, uint256 amount) external returns (uint256 tokenAOut, uint256 tokenBOut);

    /**
     * @notice Migrates all underlying movement-mode liquidity from a merged
     * bin to the active parent of the merged bin.  For Static BPs, this
     * function is a no-op and never needs to be called.
     */
    function migrateBinLiquidityToRoot() external;

    /**
     * @notice Array of ticks where the underlying BP liquidity exists.
     */
    function getTicks() external view returns (int32[] memory ticks);

    /**
     * @notice Array of relative pool bin LP balance of the bins in the BP.
     */
    function getRatios() external view returns (uint128[] memory ratios_);

    /**
     * @notice Array of BP binIds.
     */
    function getBinIds() external view returns (uint32[] memory binIds_);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

import {IMaverickV2BoostedPosition} from "./IMaverickV2BoostedPosition.sol";

interface IMaverickV2BoostedPositionFactory {
    error BoostedPositionFactoryNotFactoryPool();
    error BoostedPositionPermissionedLiquidityPool();
    error BoostedPositionFactoryKindNotSupportedByPool(uint8 poolKinds, uint8 kind);
    error BoostedPositionFactoryInvalidRatioZero(uint128 ratioZero);
    error BoostedPositionFactoryInvalidLengths(uint256 ratioLength, uint256 binIdsLength);
    error BoostedPositionFactoryInvalidLengthForKind(uint8 kind, uint256 ratiosLength);
    error BoostedPositionFactoryBinIdsNotSorted(uint256 index, uint32 lastBinId, uint32 thisBinId);
    error BoostedPositionFactoryInvalidBinKind(uint8 inputKind, uint8 binKind, uint32 binId);

    event CreateBoostedPosition(
        IMaverickV2Pool pool,
        uint32[] binIds,
        uint128[] ratios,
        uint8 kind,
        IMaverickV2BoostedPosition boostedPosition
    );

    /**
     * @notice Creates BP from the specified input parameters.  Requirements:
     *
     * - Pool must be from pool factory
     * - BP kind must be supported by the pool
     * - BinIds have to be sorted in ascending order
     * - ratios[0] must be 1e18; ratios are specified in D18 scale
     * - ratio and binId arrays have to be the same length
     * - movement-mode BPs can only have one binId
     * - static-mode BPs can have at most 24 binIds
     */
    function createBoostedPosition(
        IMaverickV2Pool pool,
        uint32[] memory binIds,
        uint128[] memory ratios,
        uint8 kind
    ) external returns (IMaverickV2BoostedPosition boostedPosition);

    /**
     * @notice Look up BPs by range of indexes.
     */
    function lookup(uint256 startIndex, uint256 endIndex) external view returns (IMaverickV2BoostedPosition[] memory);

    /**
     * @notice Returns count of all BPs deployed by the factory.
     */
    function boostedPositionsCount() external view returns (uint256 count);

    /**
     * @notice Look up BPs by range of indexes for a given pool.
     */
    function lookup(
        IMaverickV2Pool pool,
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (IMaverickV2BoostedPosition[] memory);

    /**
     * @notice Returns count of all BPs deployed by the factory for a given
     * pool.
     */
    function boostedPositionsByPoolCount(IMaverickV2Pool pool) external view returns (uint256 count);

    /**
     * @notice Returns whether or not input BP was created by this factory.
     */
    function isFactoryBoostedPosition(IMaverickV2BoostedPosition) external returns (bool);

    /**
     * @notice Pool factory that all BPs pool must be deployed from.
     */
    function poolFactory() external returns (IMaverickV2Factory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

import {IMaverickV2Position} from "./IMaverickV2Position.sol";
import {IMaverickV2BoostedPosition} from "./IMaverickV2BoostedPosition.sol";
import {IMaverickV2PoolLens} from "./IMaverickV2PoolLens.sol";
import {IMaverickV2BoostedPositionFactory} from "./IMaverickV2BoostedPositionFactory.sol";
import {IArgPacker} from "../liquiditybase/IArgPacker.sol";
import {IExactOutputSlim} from "../routerbase/IExactOutputSlim.sol";
import {IPayment} from "../paymentbase/IPayment.sol";
import {IChecks} from "../base/IChecks.sol";
import {IMigrateBins} from "../base/IMigrateBins.sol";

interface IMaverickV2LiquidityManager is IPayment, IChecks, IExactOutputSlim, IArgPacker, IMigrateBins {
    error LiquidityManagerNotFactoryPool();
    error LiquidityManagerNotTokenIdOwner();

    /**
     * @notice Maverick V2 NFT position contract that tracks NFT-based
     * liquditiy positions.
     */
    function position() external view returns (IMaverickV2Position);

    /**
     * @notice Maverick V2 BP factory contract.
     */
    function boostedPositionFactory() external view returns (IMaverickV2BoostedPositionFactory);

    /**
     * @notice Create Maverick V2 pool.  Function is a pass through to the pool
     * factory and is provided here so that is can be assembled as part of a
     * multicall transaction.
     */
    function createPool(
        uint64 fee,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds
    ) external payable returns (IMaverickV2Pool pool);

    /**
     * @notice Create Maverick V2 pool with two-way fees.  Function is a pass
     * through to the pool factory and is provided here so that is can be
     * assembled as part of a multicall transaction.
     */
    function createPool(
        uint64 feeAIn,
        uint64 feeBIn,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds
    ) external payable returns (IMaverickV2Pool pool);

    /**
     * @notice Add Liquidity to a Maverick V2 pool.  Function is a pass through
     * to the pool and is provided here so that is can be assembled as part of a
     * multicall transaction.  Users can add liquidity to the Position NFT
     * contract or a BP as part of a multicall in order to mint NFT/BP
     * positions.
     * @dev Liquidity is specified as bytes that represent a lookup table of
     * add parameters.  This allows an adder to specify what liquidity amounts
     * they wish to add conditional on the price of the pool when their
     * transaction is executed.  With this, users have fine-grain control of how
     * price slippage affects the amount of liquidity they add.  The
     * MaverickV2PoolLens contract has helper view functions that can be used
     * to easily create a combination of price breaks and packed arguments.
     */
    function addLiquidity(
        IMaverickV2Pool pool,
        address recipient,
        uint256 subaccount,
        bytes calldata packedSqrtPriceBreaks,
        bytes[] calldata packedArgs
    ) external payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds);

    /**
     * @notice Add Liquidity position NFT for msg.sender by specifying
     * msg.sender's token index.
     * @dev Token index is different from tokenId.
     * On the Position NFT contract a user can own multiple NFT tokenIds and
     * these are indexes by an enumeration index which is the `index` input
     * here.
     *
     * See addLiquidity for a description of the add params.
     */
    function addPositionLiquidityToSenderByTokenIndex(
        IMaverickV2Pool pool,
        uint256 index,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) external payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds);

    /**
     * @notice Add Liquidity position NFT for msg.sender by specifying
     * recipient's token index.
     * @dev Token index is different from tokenId.
     * On the Position NFT contract a user can own multiple NFT tokenIds and
     * these are indexes by an enumeration index which is the `index` input
     * here.
     *
     * See addLiquidity for a description of the add params.
     */
    function addPositionLiquidityToRecipientByTokenIndex(
        IMaverickV2Pool pool,
        address recipient,
        uint256 index,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) external payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds);

    /**
     * @notice Pass through function to the BP bin migration.
     */
    function migrateBoostedPosition(IMaverickV2BoostedPosition boostedPosition) external payable;

    /**
     * @notice Mint new tokenId in the Position NFT contract. Both mints an NFT
     * and adds liquidity to the pool that is held by the NFT.
     * @dev Caller must approve this LiquidityManager contract to spend the
     * caller's token A/B in order to fund the liquidity position.
     *
     * See addLiquidity for a description of the add params.
     */
    function mintPositionNft(
        IMaverickV2Pool pool,
        address recipient,
        bytes calldata packedSqrtPriceBreaks,
        bytes[] calldata packedArgs
    ) external payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds, uint256 tokenId);

    /**
     * @notice Mint new tokenId in the Position NFt contract to msg.sender.
     * Both mints an NFT and adds liquidity to the pool that is held by the
     * NFT.
     */
    function mintPositionNftToSender(
        IMaverickV2Pool pool,
        bytes calldata packedSqrtPriceBreaks,
        bytes[] calldata packedArgs
    ) external payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds, uint256 tokenId);

    /**
     * @notice Mint BP LP tokens to recipient.  This function does not add
     * liquidity to the BP and is only useful in conjuction with addLiquidity
     * as part of a multcall.
     */
    function mintBoostedPosition(
        IMaverickV2BoostedPosition boostedPosition,
        address recipient
    ) external payable returns (uint256 mintedLpAmount);

    /**
     * @notice Donates liqudity to a pool that is held by the position contract
     * and will never be retrievable.  Can be used to start a pool and ensure
     * there will always be a base level of liquditiy in the pool.
     */
    function donateLiquidity(IMaverickV2Pool pool, IMaverickV2Pool.AddLiquidityParams memory args) external payable;

    /**
     * @notice Creates a pool at a specified price and mints a Position NFT
     * with liquidity to the recipient.
     * @dev A Maverick V2 pool has no native was to specify a starting price,
     * only a starting `activeTick`.  The initial pool price will be the left
     * edge of the initial activeTick.  In order to create a pool at a fixed
     * price, this function dontes a small amount of liquidity to the pool, does
     * a swap to the specified price, and then adds liquidity for the user.
     */
    function createPoolAtPriceAndAddLiquidity(
        address recipient,
        IMaverickV2PoolLens.CreateAndAddParamsInputs memory params
    )
        external
        payable
        returns (
            IMaverickV2Pool pool,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint32[] memory binIds,
            uint256 tokenId
        );

    /**
     * @notice Creates a pool at a specified price and mints a Position NFT
     * with liquidity to msg.sender.
     */
    function createPoolAtPriceAndAddLiquidityToSender(
        IMaverickV2PoolLens.CreateAndAddParamsInputs memory params
    )
        external
        payable
        returns (
            IMaverickV2Pool pool,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint32[] memory binIds,
            uint256 tokenId
        );

    /**
     * @notice Executes the multi-step process of minting BP LP positions by
     * adding liqudiity to a pool in the BP liquidity distribution and then
     * minting the BP to recipient.
     * @dev Caller will need to approve this LiquidityManager contract to spend
     * their token A/B in order to execute this function.
     */
    function addLiquidityAndMintBoostedPosition(
        address recipient,
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) external payable returns (uint256 mintedLpAmount, uint256 tokenAAmount, uint256 tokenBAmount);

    /**
     * @notice Executes the multi-step process of minting BP LP positions by
     * adding liquidity to a pool in the BP liquidity distribution and then
     * minting the BP to msg.sender.
     * @dev Caller will need to approve this LiquidityManager contract to spend
     * their token A/B in order to execute this function.
     */
    function addLiquidityAndMintBoostedPositionToSender(
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) external payable returns (uint256 mintedLpAmount, uint256 tokenAAmount, uint256 tokenBAmount);

    /**
     * @notice Deploy new BP contract from the BP factory and mint BP LP tokens
     * to the recipient.
     * @dev Caller will need to approve this LiquidityManager contract to spend
     * their token A/B in order to execute this function.
     */
    function createBoostedPositionAndAddLiquidity(
        address recipient,
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params
    )
        external
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount
        );

    /**
     * @notice Deploy new BP contract from the BP factory and mint BP LP tokens
     * to msg.sender.
     * @dev Caller will need to approve this LiquidityManager contract to spend
     * their token A/B in order to execute this function.
     */
    function createBoostedPositionAndAddLiquidityToSender(
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params
    )
        external
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {IMaverickV2BoostedPosition} from "./IMaverickV2BoostedPosition.sol";

interface IMaverickV2PoolLens {
    error LensTargetPriceOutOfBounds(uint256 targetSqrtPrice, uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice);
    error LensTooLittleLiquidity(uint256 relativeLiquidityAmount, uint256 deltaA, uint256 deltaB);
    error LensTargetingTokenWithNoDelta(bool targetIsA, uint256 deltaA, uint256 deltaB);

    /**
     * @notice Add liquidity slippage parameters for a distribution of liquidity.
     * @param pool Pool where liquidity is being added.
     * @param kind Bin kind; all bins must have the same kind in a given call
     * to addLiquidity.
     * @param ticks Array of tick values to add liquidity to.
     * @param relativeLiquidityAmounts Relative liquidity amounts for the
     * specified ticks.  Liquidity in this case is not bin LP balance, it is
     * the bin liquidity as defined by liquidity = deltaA / (sqrt(upper) -
     * sqrt(lower)) or deltaB = liquidity / sqrt(lower) - liquidity /
     * sqrt(upper).
     * @param addSpec Slippage specification.
     */
    struct AddParamsViewInputs {
        IMaverickV2Pool pool;
        uint8 kind;
        int32[] ticks;
        uint128[] relativeLiquidityAmounts;
        AddParamsSpecification addSpec;
    }

    /**
     * @notice Multi-price add param specification.
     * @param slippageFactorD18 Max slippage allowed as a percent in D18 scale. e.g. 1% slippage is 0.01e18
     * @param numberOfPriceBreaksPerSide Number of price break values on either
     * side of current price.
     * @param targetAmount Target token contribution amount in tokenA if
     * targetIsA is true, otherwise this is the target amount for tokenB.
     * @param targetIsA  Indicates if the target amount is for tokenA or tokenB
     */
    struct AddParamsSpecification {
        uint256 slippageFactorD18;
        uint256 numberOfPriceBreaksPerSide;
        uint256 targetAmount;
        bool targetIsA;
    }

    /**
     * @notice Boosted position creation specification and add parameters.
     * @param bpSpec Boosted position kind/binId/ratio information.
     * @param packedSqrtPriceBreaks Array of sqrt price breaks packed into
     * bytes.  These breaks act as a lookup table for the packedArgs array to
     * indicate to the Liquidity manager what add liquidity parameters from
     * packedArgs to use depending on the price of the pool at add time.
     * @param packedArgs Array of bytes arguments.  Each array element is a
     * packed version of addLiquidity paramters.
     */
    struct CreateBoostedPositionInputs {
        BoostedPositionSpecification bpSpec;
        bytes packedSqrtPriceBreaks;
        bytes[] packedArgs;
    }

    /**
     * @notice Specification for deriving create pool parameters. Creating a pool in the liquidity manager has several steps:
     *
     * - Deploy pool
     * - Donate a small amount of initial liquidity in the activeTick
     * - Execute a small swap to set the pool price to the desired value
     * - Add liquidity
     *
     * In order to execute these steps, the caller must specify the parameters
     * of each step.  The PoolLens has helper function to derive the values
     * used by the LiquidityManager, but this struct is the input to that
     * helper function and represents the core intent of the pool creator.
     *
     * @param fee Fraction of the pool swap amount that is retained as an LP in
     * D18 scale.
     * @param tickSpacing Tick spacing of pool where 1.0001^tickSpacing is the
     * bin width.
     * @param lookback Pool lookback in seconds.
     * @param tokenA Address of tokenA.
     * @param tokenB Address of tokenB.
     * @param activeTick Tick position that contains the active bins.
     * @param kinds 1-15 number to represent the active kinds
     * 0b0001 = static;
     * 0b0010 = right;
     * 0b0100 = left;
     * 0b1000 = both.
     * e.g. a pool with all 4 modes will have kinds = b1111 = 15
     * @param initialTargetB Amount of B to be donated to the pool after pool
     * create.  This amount needs to be big enough to meet the minimum bin
     * liquidity.
     * @param sqrtPrice Target sqrt price of the pool.
     * @param kind Bin kind; all bins must have the same kind in a given call
     * to addLiquidity.
     * @param ticks Array of tick values to add liquidity to.
     * @param relativeLiquidityAmounts Relative liquidity amounts for the
     * specified ticks.  Liquidity in this case is not bin LP balance, it is
     * the bin liquidity as defined by liquidity = deltaA / (sqrt(upper) -
     * sqrt(lower)) or deltaB = liquidity / sqrt(lower) - liquidity /
     * sqrt(upper).
     * @param targetAmount Target token contribution amount in tokenA if
     * targetIsA is true, otherwise this is the target amount for tokenB.
     * @param targetIsA  Indicates if the target amount is for tokenA or tokenB
     */
    struct CreateAndAddParamsViewInputs {
        uint64 feeAIn;
        uint64 feeBIn;
        uint16 tickSpacing;
        uint32 lookback;
        IERC20 tokenA;
        IERC20 tokenB;
        int32 activeTick;
        uint8 kinds;
        // donate params
        uint256 initialTargetB;
        uint256 sqrtPrice;
        // add target
        uint8 kind;
        int32[] ticks;
        uint128[] relativeLiquidityAmounts;
        uint256 targetAmount;
        bool targetIsA;
    }

    struct Output {
        uint256 deltaAOut;
        uint256 deltaBOut;
        uint256[] deltaAs;
        uint256[] deltaBs;
        uint128[] deltaLpBalances;
    }

    struct Reserves {
        uint256 amountA;
        uint256 amountB;
    }

    struct BinPositionKinds {
        uint128[4] values;
    }

    struct PoolState {
        IMaverickV2Pool.TickState[] tickStateMapping;
        IMaverickV2Pool.BinState[] binStateMapping;
        BinPositionKinds[] binIdByTickKindMapping;
        IMaverickV2Pool.State state;
        Reserves protocolFees;
    }

    struct BoostedPositionSpecification {
        IMaverickV2Pool pool;
        uint32[] binIds;
        uint128[] ratios;
        uint8 kind;
    }

    struct CreateAndAddParamsInputs {
        uint64 feeAIn;
        uint64 feeBIn;
        uint16 tickSpacing;
        uint32 lookback;
        IERC20 tokenA;
        IERC20 tokenB;
        int32 activeTick;
        uint8 kinds;
        // donate params
        IMaverickV2Pool.AddLiquidityParams donateParams;
        // swap params
        uint256 swapAmount;
        // add params
        IMaverickV2Pool.AddLiquidityParams addParams;
        bytes[] packedAddParams;
        uint256 deltaAOut;
        uint256 deltaBOut;
        uint256 preAddReserveA;
        uint256 preAddReserveB;
    }

    struct TickDeltas {
        uint256 deltaAOut;
        uint256 deltaBOut;
        uint256[] deltaAs;
        uint256[] deltaBs;
    }

    /**
     * @notice Converts add parameter slippage specification into add
     * parameters.  The return values are given in both raw format and as packed
     * values that can be used in the LiquidityManager contract.
     */
    function getAddLiquidityParams(
        AddParamsViewInputs memory params
    )
        external
        view
        returns (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            uint88[] memory sqrtPriceBreaks,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,
            IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
        );

    /**
     * @notice Converts add parameter slippage specification for a boosted
     * position into add parameters.  The return values are given in both raw
     * format and as packed values that can be used in the LiquidityManager
     * contract.
     */
    function getAddLiquidityParamsForBoostedPosition(
        IMaverickV2BoostedPosition boostedPosition,
        AddParamsSpecification memory addSpec
    )
        external
        view
        returns (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            uint88[] memory sqrtPriceBreaks,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,
            IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
        );

    /**
     * @notice Converts add parameter slippage specification and boosted
     * position specification into add parameters.  The return values are given
     * in both raw format and as packed values that can be used in the
     * LiquidityManager contract.
     */
    function getCreateBoostedPositionParams(
        BoostedPositionSpecification memory bpSpec,
        AddParamsSpecification memory addSpec
    )
        external
        view
        returns (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            uint88[] memory sqrtPriceBreaks,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,
            IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
        );

    /**
     * @notice Converts add parameter slippage specification and new pool
     * specification into CreateAndAddParamsInputs parameters that can be used in the
     * LiquidityManager contract.
     */
    function getCreatePoolAtPriceAndAddLiquidityParams(
        CreateAndAddParamsViewInputs memory params,
        IMaverickV2Factory factory
    ) external view returns (CreateAndAddParamsInputs memory output);

    /**
     * @notice View function that provides information about pool ticks within
     * a tick radius from the activeTick. Ticks with no reserves are not
     * included in part o f the return array.
     */
    function getTicksAroundActive(
        IMaverickV2Pool pool,
        int32 tickRadius
    ) external view returns (int32[] memory ticks, IMaverickV2Pool.TickState[] memory tickStates);

    /**
     * @notice View function that provides information about pool ticks within
     * a range. Ticks with no reserves are not included in part o f the return
     * array.
     */
    function getTicks(
        IMaverickV2Pool pool,
        int32 tickStart,
        int32 tickEnd
    ) external view returns (int32[] memory ticks, IMaverickV2Pool.TickState[] memory tickStates);

    /**
     * @notice View function that provides information about pool ticks within
     * a range.  Information returned includes all pool state needed to emulate
     * a swap off chain. Ticks with no reserves are not included in part o f
     * the return array.
     */
    function getTicksAroundActiveWLiquidity(
        IMaverickV2Pool pool,
        int32 tickRadius
    )
        external
        view
        returns (
            int32[] memory ticks,
            IMaverickV2Pool.TickState[] memory tickStates,
            uint256[] memory liquidities,
            uint256[] memory sqrtLowerTickPrices,
            uint256[] memory sqrtUpperTickPrices,
            IMaverickV2Pool.State memory poolState,
            uint256 sqrtPrice,
            uint256 feeAIn,
            uint256 feeBIn
        );

    /**
     * @notice View function that provides pool state information.
     */
    function getFullPoolState(
        IMaverickV2Pool pool,
        uint32 binStart,
        uint32 binEnd
    ) external view returns (PoolState memory poolState);

    /**
     * @notice View function that provides price and liquidity of a given tick.
     */
    function getTickSqrtPriceAndL(
        IMaverickV2Pool pool,
        int32 tick
    ) external view returns (uint256 sqrtPrice, uint256 liquidity);

    /**
     * @notice Pool sqrt price.
     */
    function getPoolSqrtPrice(IMaverickV2Pool pool) external view returns (uint256 sqrtPrice);

    /**
     * @notice Pool price.
     */
    function getPoolPrice(IMaverickV2Pool pool) external view returns (uint256 price);

    /**
     * @notice Token scale of two tokens in a pool.
     */
    function tokenScales(IMaverickV2Pool pool) external view returns (uint256 tokenAScale, uint256 tokenBScale);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {IMulticall} from "@maverick/v2-common/contracts/base/IMulticall.sol";
import {IPositionImage} from "./IPositionImage.sol";
import {INft} from "../positionbase/INft.sol";
import {IMigrateBins} from "../base/IMigrateBins.sol";
import {IChecks} from "../base/IChecks.sol";

interface IMaverickV2Position is INft, IMigrateBins, IMulticall, IChecks {
    event PositionClearData(uint256 indexed tokenId);
    event PositionSetData(uint256 indexed tokenId, uint256 index, PositionPoolBinIds newData);

    error PositionDuplicatePool(uint256 index, IMaverickV2Pool pool);
    error PositionNotFactoryPool();
    error PositionPermissionedLiquidityPool();

    struct PositionPoolBinIds {
        IMaverickV2Pool pool;
        uint32[] binIds;
    }

    struct PositionFullInformation {
        PositionPoolBinIds poolBinIds;
        uint256 amountA;
        uint256 amountB;
        uint256[] binAAmounts;
        uint256[] binBAmounts;
        int32[] ticks;
        uint256[] liquidities;
    }

    /**
     * @notice Contract that renders the position nft svg image.
     */
    function positionImage() external view returns (IPositionImage);

    /**
     * @notice Pool factory.
     */
    function factory() external view returns (IMaverickV2Factory);

    /**
     * @notice Mint NFT that holds liquidity in a Maverick V2 Pool. To mint
     * liquidity to an NFT, add liquidity to bins in a pool where the
     * add liquidity recipient is this contract and the subaccount is the
     * tokenId. LiquidityManager can be used to simplify minting Position NFTs.
     */
    function mint(address recipient, IMaverickV2Pool pool, uint32[] memory binIds) external returns (uint256 tokenId);

    /**
     * @notice Overwrites tokenId pool/binId information for a given data index.
     */
    function setTokenIdData(uint256 tokenId, uint256 index, IMaverickV2Pool pool, uint32[] memory binIds) external;

    /**
     * @notice Overwrites entire pool/binId data set for a given tokenId.
     */
    function setTokenIdData(uint256 tokenId, PositionPoolBinIds[] memory data) external;

    /**
     * @notice Append new pool/binIds data array to tokenId.
     */
    function appendTokenIdData(uint256 tokenId, IMaverickV2Pool pool, uint32[] memory binIds) external;

    /**
     * @notice Get array pool/binIds data for a given tokenId.
     */
    function getTokenIdData(uint256 tokenId) external view returns (PositionPoolBinIds[] memory);

    /**
     * @notice Get value from array of pool/binIds data for a given tokenId.
     */
    function getTokenIdData(uint256 tokenId, uint256 index) external view returns (PositionPoolBinIds memory);

    /**
     * @notice Length of array of pool/binIds data for a given tokenId.
     */
    function tokenIdDataLength(uint256 tokenId) external view returns (uint256 length);

    /**
     * @notice Remove liquidity from tokenId for a given pool.  User can
     * specify arbitrary bins to remove from for their subaccount in the pool
     * even if those bins are not in the tokenIdData set.
     */
    function removeLiquidity(
        uint256 tokenId,
        address recipient,
        IMaverickV2Pool pool,
        IMaverickV2Pool.RemoveLiquidityParams memory params
    ) external returns (uint256 tokenAAmount, uint256 tokenBAmount);

    /**
     * @notice Remove liquidity from tokenId for a given pool to sender.  User
     * can specify arbitrary bins to remove from for their subaccount in the
     * pool even if those bins are not in the tokenIdData set.
     */
    function removeLiquidityToSender(
        uint256 tokenId,
        IMaverickV2Pool pool,
        IMaverickV2Pool.RemoveLiquidityParams memory params
    ) external returns (uint256 tokenAAmount, uint256 tokenBAmount);

    /**
     * @notice NFT asset information for a given range of pool/binIds indexes.
     * This function only returns the liquidity in the pools/binIds stored as
     * part of the tokenIdData, but it is possible that the NFT has additional
     * liquidity in pools/binIds that have not been recorded.
     */
    function tokenIdPositionInformation(
        uint256 tokenId,
        uint256 startIndex,
        uint256 stopIndex
    ) external view returns (PositionFullInformation[] memory output);

    /**
     * @notice NFT asset information for a given pool/binIds index. This
     * function only returns the liquidity in the pools/binIds stored as part
     * of the tokenIdData, but it is possible that the NFT has additional
     * liquidity in pools/binIds that have not been recorded.
     */
    function tokenIdPositionInformation(
        uint256 tokenId,
        uint256 index
    ) external view returns (PositionFullInformation memory output);

    /**
     * @notice Get remove paramters for removing a fractional part of the
     * liquidity owned by a given tokenId.  The fractional factor to remove is
     * given by proporationD18 in 18-decimal scale.
     */
    function getRemoveParams(
        uint256 tokenId,
        uint256 index,
        uint256 proportionD18
    ) external view returns (IMaverickV2Pool.RemoveLiquidityParams memory params);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;
import {IMaverickV2Position} from "./IMaverickV2Position.sol";

interface IPositionImage {
    error PositionImageSetPositionError(address sender, address deployer, IMaverickV2Position currentPosition);

    function position() external view returns (IMaverickV2Position _position);
    function setPosition(IMaverickV2Position _position) external;
    function image(uint256 tokenId, address tokenOwner) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

// Adapted from https://github.com/GNSPS/solidity-bytes-utils/blob/1dff13ef21304eb3634cb9e7f86c119cf280bd35/contracts/BytesLib.sol
library BytesLib {
    error BytesLibToBoolOutOfBounds();
    error BytesLibToAddressOutOfBounds();
    error BytesLibSliceOverflow();
    error BytesLibSliceOutOfBounds();
    error BytesLibInvalidLength(uint256 inputLength, uint256 expectedLength);

    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        // 31 is added to _length in assembly; need to check here that that
        // operation will not overflow
        if (_length > type(uint256).max - 31) revert BytesLibSliceOverflow();
        if (_bytes.length < _start + _length) revert BytesLibSliceOutOfBounds();

        bytes memory tempBytes;

        assembly ("memory-safe") {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address addr) {
        unchecked {
            if (_bytes.length < _start + 20) revert BytesLibToAddressOutOfBounds();

            assembly ("memory-safe") {
                addr := and(0xffffffffffffffffffffffffffffffffffffffff, mload(add(add(_bytes, 20), _start)))
            }
        }
    }

    function toBool(bytes memory _bytes, uint256 _start) internal pure returns (bool) {
        unchecked {
            if (_bytes.length < _start + 1) revert BytesLibToBoolOutOfBounds();
            uint8 tempUint;

            assembly ("memory-safe") {
                tempUint := mload(add(add(_bytes, 1), _start))
            }

            return tempUint == 1;
        }
    }

    function toAddressAddressBoolUint128Uint128(
        bytes memory _bytes
    ) internal pure returns (address addr1, address addr2, bool bool_, uint128 amount1, uint128 amount2) {
        if (_bytes.length != 73) revert BytesLibInvalidLength(_bytes.length, 73);
        uint8 temp;
        assembly ("memory-safe") {
            addr1 := and(0xffffffffffffffffffffffffffffffffffffffff, mload(add(_bytes, 20)))
            addr2 := and(0xffffffffffffffffffffffffffffffffffffffff, mload(add(_bytes, 40)))
            temp := mload(add(_bytes, 41))
            amount1 := and(0xffffffffffffffffffffffffffffffff, mload(add(_bytes, 57)))
            amount2 := and(0xffffffffffffffffffffffffffffffff, mload(add(_bytes, 73)))
        }
        bool_ = temp == 1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeCast as Cast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {Math} from "@maverick/v2-common/contracts/libraries/Math.sol";
import {PoolLib} from "@maverick/v2-common/contracts/libraries/PoolLib.sol";
import {ONE, MINIMUM_LIQUIDITY} from "@maverick/v2-common/contracts/libraries/Constants.sol";
import {TickMath} from "@maverick/v2-common/contracts/libraries/TickMath.sol";

import {IMaverickV2PoolLens} from "../interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2BoostedPosition} from "../interfaces/IMaverickV2BoostedPosition.sol";
import {PoolInspection} from "../libraries/PoolInspection.sol";
import {PackLib} from "../libraries/PackLib.sol";

library LiquidityUtilities {
    using Cast for uint256;

    error LiquidityUtilitiesTargetPriceOutOfBounds(
        uint256 targetSqrtPrice,
        uint256 sqrtLowerTickPrice,
        uint256 sqrtUpperTickPrice
    );
    error LiquidityUtilitiesTooLittleLiquidity(uint256 relativeLiquidityAmount, uint256 deltaA, uint256 deltaB);
    error LiquidityUtilitiesTargetingTokenWithNoDelta(bool targetIsA, uint256 deltaA, uint256 deltaB);
    error LiquidityUtilitiesNoSwapLiquidity();
    error LiquidityUtilitiesFailedToFindDeltaAmounts();
    error LiquidityUtilitiesInitialTargetBTooSmall(
        uint256 initialTargetB,
        uint256 deltaLpBalance,
        uint256 minimumRequiredLpBalance
    );

    uint256 internal constant MIN_DELTA_RESERVES = 100;

    /**
     *
     * @notice Return index into the price breaks array that corresponds to the
     * current pool price.
     *
     * @dev Price break array is N elements [e_0, e_1, ..., e_{n-1}].
     * @dev If price is less than e_0, then `0` is returned, if price is
     * betweeen e_0 and e_1, then `1` is returned, etc.  If the price is
     * between e_{n-2} and e_{n-1}, then n-2 is returned.  If price is larger
     * than e_{n-1}, then n-1 is returned.
     *
     */
    function priceIndexFromPriceBreaks(
        uint256 sqrtPrice,
        bytes memory packedSqrtPriceBreaks
    ) internal pure returns (uint256 index) {
        // index is zero if the pricebreaks array only has one price
        if (packedSqrtPriceBreaks.length == 12) return index;
        uint88[] memory breaks = PackLib.unpackUint88Array(packedSqrtPriceBreaks);

        // loop terminates with `breaks.length - 1` as the max value.
        for (; index < breaks.length - 1; index++) {
            if (sqrtPrice <= breaks[index]) break;
        }
    }

    function tokenScales(IMaverickV2Pool pool) internal view returns (uint256 tokenAScale, uint256 tokenBScale) {
        tokenAScale = pool.tokenAScale();
        tokenBScale = pool.tokenBScale();
    }

    function deltaReservesFromDeltaLpBalanceAtNewPrice(
        IMaverickV2Pool pool,
        int32 tick,
        uint128 deltaLpBalance,
        uint8 kind,
        uint256 newSqrtPrice
    ) internal view returns (uint256 deltaA, uint256 deltaB) {
        PoolLib.AddLiquidityInfo memory addLiquidityInfo;
        uint32 binId = pool.binIdByTickKind(tick, kind);
        IMaverickV2Pool.BinState memory bin = pool.getBin(binId);

        addLiquidityInfo.tickSpacing = pool.tickSpacing();
        addLiquidityInfo.tick = tick;

        IMaverickV2Pool.TickState memory tickState;
        (tickState, addLiquidityInfo.tickLtActive, ) = reservesInTickForGivenPrice(pool, tick, newSqrtPrice);

        PoolLib.deltaTickBalanceFromDeltaLpBalance(
            bin.tickBalance,
            bin.totalSupply,
            tickState,
            deltaLpBalance,
            addLiquidityInfo
        );
        (uint256 tokenAScale, uint256 tokenBScale) = tokenScales(pool);
        deltaA = Math.ammScaleToTokenScale(addLiquidityInfo.deltaA, tokenAScale, true);
        deltaB = Math.ammScaleToTokenScale(addLiquidityInfo.deltaB, tokenBScale, true);
    }

    function deltaReservesFromDeltaLpBalancesAtNewPrice(
        IMaverickV2Pool pool,
        IMaverickV2Pool.AddLiquidityParams memory addParams,
        uint256 newSqrtPrice
    ) internal view returns (IMaverickV2PoolLens.TickDeltas memory tickDeltas) {
        uint256 length = addParams.ticks.length;
        tickDeltas.deltaAs = new uint256[](length);
        tickDeltas.deltaBs = new uint256[](length);
        for (uint256 k; k < length; k++) {
            (tickDeltas.deltaAs[k], tickDeltas.deltaBs[k]) = deltaReservesFromDeltaLpBalanceAtNewPrice(
                pool,
                addParams.ticks[k],
                addParams.amounts[k],
                addParams.kind,
                newSqrtPrice
            );
            tickDeltas.deltaAOut += tickDeltas.deltaAs[k];
            tickDeltas.deltaBOut += tickDeltas.deltaBs[k];
        }
    }

    function scaleAddParams(
        IMaverickV2Pool.AddLiquidityParams memory addParams,
        uint128[] memory ratios,
        uint256 addAmount,
        uint256 targetAmount
    ) internal pure returns (IMaverickV2Pool.AddLiquidityParams memory addParamsScaled) {
        uint256 length = addParams.ticks.length;
        addParamsScaled.ticks = addParams.ticks;
        addParamsScaled.kind = addParams.kind;

        addParamsScaled.amounts = new uint128[](length);

        addParamsScaled.amounts[0] = Math.mulDivFloor(addParams.amounts[0], targetAmount, addAmount).toUint128();
        for (uint256 k = 1; k < length; k++) {
            addParamsScaled.amounts[k] = Math.mulCeil(addParamsScaled.amounts[0], ratios[k]).toUint128();
        }
    }

    function getScaledAddParams(
        IMaverickV2Pool pool,
        IMaverickV2Pool.AddLiquidityParams memory addParams,
        uint128[] memory ratios,
        uint256 newSqrtPrice,
        uint256 targetAmount,
        bool targetIsA
    )
        internal
        view
        returns (
            IMaverickV2Pool.AddLiquidityParams memory addParamsScaled,
            IMaverickV2PoolLens.TickDeltas memory tickDeltas
        )
    {
        // find A and B amount for input addParams
        tickDeltas = deltaReservesFromDeltaLpBalancesAtNewPrice(pool, addParams, newSqrtPrice);
        uint256 unScaledAmount = targetIsA ? tickDeltas.deltaAOut : tickDeltas.deltaBOut;
        if (unScaledAmount == 0) revert LiquidityUtilitiesFailedToFindDeltaAmounts();

        // scale addParams to meet the delta target
        addParamsScaled = scaleAddParams(
            addParams,
            ratios,
            targetIsA ? tickDeltas.deltaAOut : tickDeltas.deltaBOut,
            targetAmount
        );
        tickDeltas = deltaReservesFromDeltaLpBalancesAtNewPrice(pool, addParamsScaled, newSqrtPrice);
    }

    function getAddLiquidityParamsFromRelativeBinLpBalance(
        IMaverickV2PoolLens.BoostedPositionSpecification memory spec,
        int32[] memory ticks,
        IMaverickV2PoolLens.AddParamsSpecification memory params
    )
        internal
        view
        returns (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            uint88[] memory sqrtPriceBreaks,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,
            IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
        )
    {
        uint256 length = params.numberOfPriceBreaksPerSide * 2 + 1;
        addParams = new IMaverickV2Pool.AddLiquidityParams[](length);
        tickDeltas = new IMaverickV2PoolLens.TickDeltas[](length);

        uint256 sqrtPrice = PoolInspection.poolSqrtPrice(spec.pool);
        addParams[params.numberOfPriceBreaksPerSide].ticks = ticks;
        addParams[params.numberOfPriceBreaksPerSide].amounts = spec.ratios;
        addParams[params.numberOfPriceBreaksPerSide].kind = spec.kind;
        (
            addParams[params.numberOfPriceBreaksPerSide],
            tickDeltas[params.numberOfPriceBreaksPerSide]
        ) = getScaledAddParams(
            spec.pool,
            addParams[params.numberOfPriceBreaksPerSide],
            spec.ratios,
            sqrtPrice,
            params.targetAmount,
            params.targetIsA
        );

        sqrtPriceBreaks = new uint88[](length);
        sqrtPriceBreaks[params.numberOfPriceBreaksPerSide] = sqrtPrice.toUint88();

        // left of price,
        for (uint256 k; k < params.numberOfPriceBreaksPerSide; k++) {
            params.targetIsA = false;
            params.targetAmount = Math.mulDown(tickDeltas[params.numberOfPriceBreaksPerSide].deltaBOut, 0.99999e18);
            if (params.targetAmount == 0) continue;

            // price / (factor + 1), price / (factor * (n-1) / n + 1), price / (factor * (n-2)/n + 1)...
            uint256 factor = Math.mulDivFloor(
                params.slippageFactorD18,
                params.numberOfPriceBreaksPerSide - k,
                params.numberOfPriceBreaksPerSide
            );
            sqrtPriceBreaks[k] = Math.divCeil(sqrtPrice, factor + ONE).toUint88();

            (addParams[k], tickDeltas[k]) = getScaledAddParams(
                spec.pool,
                addParams[params.numberOfPriceBreaksPerSide],
                spec.ratios,
                sqrtPriceBreaks[k],
                params.targetAmount,
                params.targetIsA
            );
        }

        // right of price
        for (uint256 k; k < params.numberOfPriceBreaksPerSide; k++) {
            uint256 index = params.numberOfPriceBreaksPerSide + k + 1;
            params.targetIsA = true;
            params.targetAmount = Math.mulDown(tickDeltas[params.numberOfPriceBreaksPerSide].deltaAOut, 0.99999e18);
            if (params.targetAmount == 0) {
                sqrtPriceBreaks[index - 1] = type(uint88).max;
                break;
            }

            {
                // price * (factor * (1 / n) + 1), price * (factor * (2 / n) + 1), price / (factor * (3 / n) + 1)...
                uint256 factor = Math.mulDivFloor(params.slippageFactorD18, k + 1, params.numberOfPriceBreaksPerSide);
                sqrtPriceBreaks[index] = Math.mulCeil(sqrtPrice, factor + ONE).toUint88();
            }
            (addParams[index], tickDeltas[index]) = getScaledAddParams(
                spec.pool,
                addParams[params.numberOfPriceBreaksPerSide],
                spec.ratios,
                sqrtPriceBreaks[index],
                params.targetAmount,
                params.targetIsA
            );
        }
        sortAddParamsArray(addParams, tickDeltas);
        packedArgs = PackLib.packAddLiquidityArgsArray(addParams);
        packedSqrtPriceBreaks = PackLib.packArray(sqrtPriceBreaks);
    }

    /** @notice Compute add params for N price breaks around price with max right
     * slippage of p * (1 + f) and max left slippage of p / (1 + f).
     *
     * The user specifies the max A and B they are willing to spend.  If the
     * price of the pool does not move, the user will spend exactly this
     * amount. If the price moves left, then the user would like to spend the
     * specified B amount, but will end up spending less A.  Conversely, if the
     * price moves right, the user will spend their max A amount, but less B.
     *
     * By having more break points, we make it so that the user gets as much
     * liquidity as possible at the new price. With too few break points, the
     * user will not have bought as much liquidity as they could have.
     */
    function getAddLiquidityParams(
        IMaverickV2PoolLens.AddParamsViewInputs memory params
    )
        internal
        view
        returns (
            bytes memory packedSqrtPriceBreaks,
            bytes[] memory packedArgs,
            uint88[] memory sqrtPriceBreaks,
            IMaverickV2Pool.AddLiquidityParams[] memory addParams,
            IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
        )
    {
        RelativeLiquidityInput memory input;

        input.poolTickSpacing = params.pool.tickSpacing();
        (input.tokenAScale, input.tokenBScale) = tokenScales(params.pool);
        input.ticks = params.ticks;
        input.relativeLiquidityAmounts = params.relativeLiquidityAmounts;

        uint256 length = params.addSpec.numberOfPriceBreaksPerSide * 2 + 1;
        addParams = new IMaverickV2Pool.AddLiquidityParams[](length);
        tickDeltas = new IMaverickV2PoolLens.TickDeltas[](length);

        // initially target the bigger amount at pool price
        input.targetIsA = params.addSpec.targetIsA;
        input.targetAmount = params.addSpec.targetAmount;
        uint256 startingPrice = PoolInspection.poolSqrtPrice(params.pool);

        input.newSqrtPrice = startingPrice;
        bool success;
        (
            addParams[params.addSpec.numberOfPriceBreaksPerSide],
            tickDeltas[params.addSpec.numberOfPriceBreaksPerSide],
            success
        ) = lpBalanceForArrayOfTargetAmounts(input, params.pool, params.kind);
        if (!success) revert LiquidityUtilitiesFailedToFindDeltaAmounts();
        sqrtPriceBreaks = new uint88[](length);
        sqrtPriceBreaks[params.addSpec.numberOfPriceBreaksPerSide] = input.newSqrtPrice.toUint88();

        // compute slippage price
        // look through N breaks
        // compute deltas
        // convert to addParams
        //

        // left of price,
        for (uint256 k; k < params.addSpec.numberOfPriceBreaksPerSide; k++) {
            input.targetIsA = false;
            input.targetAmount = tickDeltas[params.addSpec.numberOfPriceBreaksPerSide].deltaBOut;

            // price / (factor + 1), price / (factor * (n-1) / n + 1), price / (factor * (n-2)/n + 1)...
            uint256 factor = Math.mulDivFloor(
                params.addSpec.slippageFactorD18,
                params.addSpec.numberOfPriceBreaksPerSide - k,
                params.addSpec.numberOfPriceBreaksPerSide
            );
            sqrtPriceBreaks[k] = Math.divCeil(startingPrice, factor + ONE).toUint88();

            input.newSqrtPrice = sqrtPriceBreaks[k];

            (addParams[k], tickDeltas[k], success) = lpBalanceForArrayOfTargetAmounts(input, params.pool, params.kind);
            if (!success) sqrtPriceBreaks[k] = 0;
        }

        // right of price
        for (uint256 k; k < params.addSpec.numberOfPriceBreaksPerSide; k++) {
            uint256 index = params.addSpec.numberOfPriceBreaksPerSide + k + 1;
            input.targetIsA = true;
            input.targetAmount = tickDeltas[params.addSpec.numberOfPriceBreaksPerSide].deltaAOut;

            // price * (factor * (1 / n) + 1), price * (factor * (2 / n) + 1), price / (factor * (3 / n) + 1)...
            uint256 factor = Math.mulDivFloor(
                params.addSpec.slippageFactorD18,
                k + 1,
                params.addSpec.numberOfPriceBreaksPerSide
            );
            sqrtPriceBreaks[index] = Math.mulCeil(startingPrice, factor + ONE).toUint88();

            input.newSqrtPrice = sqrtPriceBreaks[index];

            (addParams[index], tickDeltas[index], success) = lpBalanceForArrayOfTargetAmounts(
                input,
                params.pool,
                params.kind
            );
            if (!success) {
                sqrtPriceBreaks[index - 1] = type(uint88).max;
                break;
            }
        }
        packedArgs = PackLib.packAddLiquidityArgsArray(addParams);
        packedSqrtPriceBreaks = PackLib.packArray(sqrtPriceBreaks);
    }

    function deltaReservesFromDeltaLiquidity(
        uint256 poolTickSpacing,
        uint256 tokenAScale,
        uint256 tokenBScale,
        int32 tick,
        uint128 deltaLiquidity,
        uint256 tickSqrtPrice
    ) internal pure returns (uint256 deltaA, uint256 deltaB) {
        (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(poolTickSpacing, tick);
        {
            uint256 lowerEdge = Math.max(sqrtLowerTickPrice, tickSqrtPrice);

            deltaB = Math.mulDivCeil(
                deltaLiquidity,
                ONE * Math.clip(sqrtUpperTickPrice, lowerEdge),
                sqrtUpperTickPrice * lowerEdge
            );
        }

        if (tickSqrtPrice < sqrtLowerTickPrice) {
            deltaA = 0;
        } else if (tickSqrtPrice >= sqrtUpperTickPrice) {
            deltaA = Math.mulCeil(deltaLiquidity, sqrtUpperTickPrice - sqrtLowerTickPrice);
            deltaB = 0;
        } else {
            deltaA = Math.mulCeil(
                deltaLiquidity,
                Math.clip(Math.min(sqrtUpperTickPrice, tickSqrtPrice), sqrtLowerTickPrice)
            );
        }
        deltaA = Math.ammScaleToTokenScale(deltaA, tokenAScale, true);
        deltaB = Math.ammScaleToTokenScale(deltaB, tokenBScale, true);
    }

    function deltasFromBinLiquidityAmounts(
        uint256 poolTickSpacing,
        uint256 tokenAScale,
        uint256 tokenBScale,
        int32[] memory ticks,
        uint128[] memory liquidityAmounts,
        uint256 newSqrtPrice
    ) internal pure returns (uint256 deltaA, uint256 deltaB, uint256[] memory deltaAs, uint256[] memory deltaBs) {
        uint256 length = ticks.length;
        deltaAs = new uint256[](length);
        deltaBs = new uint256[](length);
        for (uint256 k = 0; k < length; k++) {
            (deltaAs[k], deltaBs[k]) = deltaReservesFromDeltaLiquidity(
                poolTickSpacing,
                tokenAScale,
                tokenBScale,
                ticks[k],
                liquidityAmounts[k],
                newSqrtPrice
            );
            deltaA += deltaAs[k];
            deltaB += deltaBs[k];
        }
    }

    struct StateInfo {
        uint256 reserveA;
        uint256 reserveB;
        uint256 binTotalSupply;
        int32 activeTick;
    }

    struct RelativeLiquidityInput {
        uint256 poolTickSpacing;
        uint256 tokenAScale;
        uint256 tokenBScale;
        int32[] ticks;
        uint128[] relativeLiquidityAmounts;
        uint256 targetAmount;
        bool targetIsA;
        uint256 newSqrtPrice;
    }

    function _deltasFromRelativeBinLiquidityAmountsAndTargetAmount(
        RelativeLiquidityInput memory input
    ) internal pure returns (IMaverickV2PoolLens.TickDeltas memory output, bool success) {
        uint256 deltaA;
        uint256 deltaB;
        success = true;

        (deltaA, deltaB, output.deltaAs, output.deltaBs) = deltasFromBinLiquidityAmounts(
            input.poolTickSpacing,
            input.tokenAScale,
            input.tokenBScale,
            input.ticks,
            input.relativeLiquidityAmounts,
            input.newSqrtPrice
        );
        uint256 deltaDenominator = input.targetIsA ? deltaA : deltaB;

        if ((input.targetIsA && deltaA == 0) || (!input.targetIsA && deltaB == 0)) return (output, false);

        for (uint256 k; k < input.ticks.length; k++) {
            output.deltaAs[k] = Math
                .mulDivFloor(Math.clip(output.deltaAs[k], 1), input.targetAmount, deltaDenominator)
                .toUint128();
            output.deltaBs[k] = Math
                .mulDivFloor(Math.clip(output.deltaBs[k], 1), input.targetAmount, deltaDenominator)
                .toUint128();
            if (output.deltaAs[k] < MIN_DELTA_RESERVES && output.deltaBs[k] < MIN_DELTA_RESERVES)
                return (output, false);

            output.deltaAOut += output.deltaAs[k];
            output.deltaBOut += output.deltaBs[k];
        }
    }

    function lpBalanceForArrayOfTargetAmountsEmptyPool(
        IMaverickV2PoolLens.TickDeltas memory tickDeltas,
        RelativeLiquidityInput memory input,
        StateInfo memory existingState,
        uint8 kind
    ) internal pure returns (IMaverickV2Pool.AddLiquidityParams memory addParams) {
        addParams.ticks = input.ticks;
        addParams.kind = kind;
        addParams.amounts = new uint128[](input.ticks.length);
        for (uint256 k; k < input.ticks.length; k++) {
            bool tickIsActive = existingState.activeTick == input.ticks[k];
            addParams.amounts[k] = lpBalanceRequiredForTargetReserveAmountsOneBinTick(
                input,
                input.ticks[k],
                Math.tokenScaleToAmmScale(tickDeltas.deltaAs[k], input.tokenAScale),
                Math.tokenScaleToAmmScale(tickDeltas.deltaBs[k], input.tokenBScale),
                tickIsActive ? existingState.reserveA : 0,
                tickIsActive ? existingState.reserveB : 0,
                tickIsActive ? existingState.binTotalSupply : 0,
                input.ticks[k] < existingState.activeTick
            ).toUint128();
        }
    }

    function lpBalanceForArrayOfTargetAmounts(
        RelativeLiquidityInput memory input,
        IMaverickV2Pool pool,
        uint8 kind
    )
        internal
        view
        returns (
            IMaverickV2Pool.AddLiquidityParams memory addParams,
            IMaverickV2PoolLens.TickDeltas memory tickDeltas,
            bool success
        )
    {
        (tickDeltas, success) = _deltasFromRelativeBinLiquidityAmountsAndTargetAmount(input);
        addParams.ticks = input.ticks;
        addParams.kind = kind;

        addParams.amounts = new uint128[](input.ticks.length);
        for (uint256 k; k < input.ticks.length; k++) {
            addParams.amounts[k] = lpBalanceRequiredForTargetReserveAmountsMultiBinTick(
                input,
                pool,
                input.ticks[k],
                kind,
                Math.tokenScaleToAmmScale(tickDeltas.deltaAs[k], input.tokenAScale),
                Math.tokenScaleToAmmScale(tickDeltas.deltaBs[k], input.tokenBScale)
            ).toUint128();
        }
    }

    function donateAndSwapData(
        uint256 poolTickSpacing,
        int32 poolTick,
        uint256 poolFee,
        IERC20 tokenB,
        uint256 targetAmountB,
        uint256 targetSqrtPrice
    ) internal view returns (uint128 deltaLpBalanceB, uint256 swapAmount) {
        uint256 tokenBScale = Math.scale(IERC20Metadata(address(tokenB)).decimals());

        targetAmountB = Math.tokenScaleToAmmScale(targetAmountB, tokenBScale);
        (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(poolTickSpacing, poolTick);

        deltaLpBalanceB = Math.mulFloor(targetAmountB, sqrtUpperTickPrice).toUint128();

        uint256 liquidity = TickMath.getTickL(0, targetAmountB, sqrtLowerTickPrice, sqrtUpperTickPrice);
        if (targetSqrtPrice <= sqrtLowerTickPrice || targetSqrtPrice >= sqrtUpperTickPrice)
            revert LiquidityUtilitiesTargetPriceOutOfBounds(targetSqrtPrice, sqrtLowerTickPrice, sqrtUpperTickPrice);

        swapAmount = Math.mulDivCeil(
            liquidity,
            ONE * (targetSqrtPrice - sqrtLowerTickPrice),
            targetSqrtPrice * sqrtLowerTickPrice
        );
        swapAmount = Math.ammScaleToTokenScale(swapAmount, tokenBScale, true);
        swapAmount = Math.mulCeil(swapAmount, ONE - poolFee);
    }

    function getCreatePoolParams(
        IMaverickV2PoolLens.CreateAndAddParamsViewInputs memory params,
        uint256 protocolFeeRatio
    ) internal view returns (IMaverickV2PoolLens.CreateAndAddParamsInputs memory output) {
        (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(
            params.tickSpacing,
            params.activeTick
        );
        RelativeLiquidityInput memory input;
        StateInfo memory existingState;

        input.poolTickSpacing = params.tickSpacing;
        input.tokenAScale = Math.scale(IERC20Metadata(address(params.tokenA)).decimals());
        input.tokenBScale = Math.scale(IERC20Metadata(address(params.tokenB)).decimals());
        input.ticks = params.ticks;
        input.relativeLiquidityAmounts = params.relativeLiquidityAmounts;
        input.targetAmount = params.targetAmount;
        input.targetIsA = params.targetIsA;
        existingState.activeTick = params.activeTick;

        output.donateParams.ticks = new int32[](1);
        output.donateParams.ticks[0] = params.activeTick;
        output.donateParams.amounts = new uint128[](1);
        if (sqrtLowerTickPrice != params.sqrtPrice) {
            // target price is not tick edge, need to dontate/swap
            (output.donateParams.amounts[0], output.swapAmount) = donateAndSwapData(
                params.tickSpacing,
                params.activeTick,
                params.feeAIn,
                params.tokenB,
                params.initialTargetB,
                params.sqrtPrice
            );

            if (output.donateParams.amounts[0] < MINIMUM_LIQUIDITY)
                revert LiquidityUtilitiesInitialTargetBTooSmall(
                    params.initialTargetB,
                    output.donateParams.amounts[0],
                    MINIMUM_LIQUIDITY
                );
            existingState.binTotalSupply = output.donateParams.amounts[0];

            existingState.reserveB = Math.tokenScaleToAmmScale(
                params.initialTargetB - output.swapAmount,
                input.tokenBScale
            );
            existingState.reserveA = emulateExactOut(
                Math.tokenScaleToAmmScale(output.swapAmount, input.tokenBScale),
                Math.tokenScaleToAmmScale(params.initialTargetB, input.tokenBScale),
                sqrtLowerTickPrice,
                sqrtUpperTickPrice,
                params.feeAIn,
                protocolFeeRatio
            );

            (input.newSqrtPrice, ) = TickMath.getTickSqrtPriceAndL(
                existingState.reserveA,
                existingState.reserveB,
                sqrtLowerTickPrice,
                sqrtUpperTickPrice
            );
        } else {
            input.newSqrtPrice = sqrtLowerTickPrice;
        }

        {
            (
                IMaverickV2PoolLens.TickDeltas memory tickDeltas,
                bool success
            ) = _deltasFromRelativeBinLiquidityAmountsAndTargetAmount(input);
            if (!success) revert LiquidityUtilitiesFailedToFindDeltaAmounts();

            output.addParams = lpBalanceForArrayOfTargetAmountsEmptyPool(tickDeltas, input, existingState, params.kind);
            output.packedAddParams = PackLib.packAddLiquidityArgsToArray(output.addParams);
            output.deltaAOut = tickDeltas.deltaAOut;
            output.deltaBOut = tickDeltas.deltaBOut;
            output.preAddReserveA = existingState.reserveA;
            output.preAddReserveB = existingState.reserveB;
        }
    }

    function emulateExactOut(
        uint256 amountOut,
        uint256 currentReserveB,
        uint256 sqrtLowerTickPrice,
        uint256 sqrtUpperTickPrice,
        uint256 fee,
        uint256 protocolFee
    ) internal pure returns (uint256 amountAIn) {
        uint256 existingLiquidity = TickMath.getTickL(0, currentReserveB, sqrtLowerTickPrice, sqrtUpperTickPrice);

        if (existingLiquidity == 0) revert LiquidityUtilitiesNoSwapLiquidity();

        uint256 binAmountIn = Math.mulDivCeil(
            amountOut,
            sqrtLowerTickPrice,
            Math.invFloor(sqrtLowerTickPrice) - Math.divCeil(amountOut, existingLiquidity)
        );

        // some of the input is fee
        uint256 feeBasis = Math.mulDivCeil(binAmountIn, fee, ONE - fee);
        // fee is added to input amount and just increases bin liquidity
        // out = in / (1-fee)  -> out - fee * out = in  -> out = in + fee * out
        uint256 inWithoutProtocolFee = binAmountIn + feeBasis;
        // add on protocol fee
        amountAIn = protocolFee != 0
            ? Math.clip(inWithoutProtocolFee, Math.mulCeil(feeBasis, protocolFee))
            : inWithoutProtocolFee;
    }

    /**
     * @notice Calculates deltaA = liquidity * (sqrt(upper) - sqrt(lower))
     *  Calculates deltaB = liquidity / sqrt(lower) - liquidity / sqrt(upper),
     *  i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
     */
    function reservesInTickForGivenPrice(
        IMaverickV2Pool pool,
        int32 tick,
        uint256 newSqrtPrice
    ) internal view returns (IMaverickV2Pool.TickState memory tickState, bool tickLtActive, bool tickGtActive) {
        tickState = pool.getTick(tick);
        (uint256 lowerSqrtPrice, uint256 upperSqrtPrice) = TickMath.tickSqrtPrices(pool.tickSpacing(), tick);

        tickGtActive = newSqrtPrice < lowerSqrtPrice;
        tickLtActive = newSqrtPrice >= upperSqrtPrice;

        uint256 liquidity = TickMath.getTickL(tickState.reserveA, tickState.reserveB, lowerSqrtPrice, upperSqrtPrice);

        if (liquidity == 0) {
            (tickState.reserveA, tickState.reserveB) = (0, 0);
        } else {
            uint256 lowerEdge = Math.max(lowerSqrtPrice, newSqrtPrice);

            tickState.reserveA = Math
                .mulCeil(liquidity, Math.clip(Math.min(upperSqrtPrice, newSqrtPrice), lowerSqrtPrice))
                .toUint128();
            tickState.reserveB = Math
                .mulDivCeil(liquidity, ONE * Math.clip(upperSqrtPrice, lowerEdge), upperSqrtPrice * lowerEdge)
                .toUint128();
        }
    }

    function lpBalanceRequiredForTargetReserveAmountsMultiBinTick(
        RelativeLiquidityInput memory input,
        IMaverickV2Pool pool,
        int32 tick,
        uint8 kind,
        uint256 amountAMax,
        uint256 amountBMax
    ) internal view returns (uint256 deltaLpBalance) {
        (IMaverickV2Pool.TickState memory tickState, bool tickLtActive, ) = reservesInTickForGivenPrice(
            pool,
            tick,
            input.newSqrtPrice
        );
        if (tickState.reserveB != 0 || tickState.reserveA != 0) {
            uint256 liquidity;
            {
                (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(
                    input.poolTickSpacing,
                    tick
                );
                liquidity = TickMath.getTickL(
                    tickState.reserveA,
                    tickState.reserveB,
                    sqrtLowerTickPrice,
                    sqrtUpperTickPrice
                );
            }
            uint32 binId = pool.binIdByTickKind(tick, kind);
            IMaverickV2Pool.BinState memory bin = pool.getBin(binId);

            uint256 numerator = Math.max(1, uint256(tickState.totalSupply)) * Math.max(1, uint256(bin.totalSupply));
            if (tickState.reserveA != 0) {
                uint256 denominator = Math.max(1, uint256(bin.tickBalance)) * uint256(tickState.reserveA);
                amountAMax = Math.max(amountAMax, 1);
                deltaLpBalance = Math.mulDivFloor(amountAMax, numerator, denominator);
            } else {
                deltaLpBalance = type(uint256).max;
            }
            if (tickState.reserveB != 0) {
                uint256 denominator = Math.max(1, uint256(bin.tickBalance)) * uint256(tickState.reserveB);
                amountBMax = Math.max(amountBMax, 1);
                deltaLpBalance = Math.min(deltaLpBalance, Math.mulDivFloor(amountBMax, numerator, denominator));
            }
        } else {
            deltaLpBalance = emptyTickLpBalanceRequirement(input, tick, amountAMax, amountBMax, tickLtActive);
        }
    }

    function lpBalanceRequiredForTargetReserveAmountsOneBinTick(
        RelativeLiquidityInput memory input,
        int32 tick,
        uint256 amountAMax,
        uint256 amountBMax,
        uint256 reserveA,
        uint256 reserveB,
        uint256 binTotalSupply,
        bool tickLtActive
    ) internal pure returns (uint256 deltaLpBalance) {
        if (reserveB != 0 || reserveA != 0) {
            deltaLpBalance = Math.min(
                reserveA == 0 ? type(uint256).max : Math.mulDivFloor(amountAMax, binTotalSupply, reserveA),
                reserveB == 0 ? type(uint256).max : Math.mulDivFloor(amountBMax, binTotalSupply, reserveB)
            );
        } else {
            deltaLpBalance = emptyTickLpBalanceRequirement(input, tick, amountAMax, amountBMax, tickLtActive);
        }
    }

    function emptyTickLpBalanceRequirement(
        RelativeLiquidityInput memory input,
        int32 tick,
        uint256 amountAMax,
        uint256 amountBMax,
        bool tickLtActive
    ) internal pure returns (uint256 deltaLpBalance) {
        (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(input.poolTickSpacing, tick);
        if (tickLtActive) {
            deltaLpBalance = Math.divFloor(amountAMax, sqrtLowerTickPrice);
        } else {
            deltaLpBalance = Math.mulFloor(amountBMax, sqrtUpperTickPrice);
        }
    }

    function getBoostedPositionSpec(
        IMaverickV2BoostedPosition boostedPosition
    ) internal view returns (IMaverickV2PoolLens.BoostedPositionSpecification memory spec, int32[] memory ticks) {
        spec.pool = boostedPosition.pool();
        spec.binIds = boostedPosition.getBinIds();
        spec.ratios = boostedPosition.getRatios();
        spec.kind = boostedPosition.kind();
        ticks = boostedPosition.getTicks();
    }

    /**
     * @notice Sort ticks and amounts in addParams struct array in tick order.
     * Mutates input params array in place.
     *
     * @notice Sort operation in this function assumes that all element of the
     * input arrays have the same tick ordering.
     */
    function sortAddParamsArray(
        IMaverickV2Pool.AddLiquidityParams[] memory addParams,
        IMaverickV2PoolLens.TickDeltas[] memory tickDeltas
    ) internal pure {
        uint256 breakPoints = addParams.length;
        uint256 length = addParams[0].ticks.length;
        for (uint256 i = 0; i < length - 1; i++) {
            for (uint256 j = 0; j < length - i - 1; j++) {
                // compare
                if (addParams[0].ticks[j] > addParams[0].ticks[j + 1]) {
                    // if there is a mis-ordering, flip values in all addParam structs
                    for (uint256 k = 0; k < breakPoints; k++) {
                        (addParams[k].ticks[j], addParams[k].ticks[j + 1]) = (
                            addParams[k].ticks[j + 1],
                            addParams[k].ticks[j]
                        );
                        (addParams[k].amounts[j], addParams[k].amounts[j + 1]) = (
                            addParams[k].amounts[j + 1],
                            addParams[k].amounts[j]
                        );
                        (tickDeltas[k].deltaAs[j], tickDeltas[k].deltaAs[j + 1]) = (
                            tickDeltas[k].deltaAs[j + 1],
                            tickDeltas[k].deltaAs[j]
                        );
                        (tickDeltas[k].deltaBs[j], tickDeltas[k].deltaBs[j + 1]) = (
                            tickDeltas[k].deltaBs[j + 1],
                            tickDeltas[k].deltaBs[j]
                        );
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

// adapted from https://github.com/latticexyz/mud/blob/main/packages/store/src/Slice.sol
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {SafeCast as Cast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {BytesLib} from "./BytesLib.sol";

library PackLib {
    using Cast for uint256;
    using BytesLib for bytes;

    function unpackExactInputSingleArgsAmounts(
        bytes memory argsPacked
    )
        internal
        pure
        returns (address recipient, IMaverickV2Pool pool, bool tokenAIn, uint256 amountIn, uint256 amountOutMinimum)
    {
        address pool_;
        (recipient, pool_, tokenAIn, amountIn, amountOutMinimum) = argsPacked.toAddressAddressBoolUint128Uint128();
        pool = IMaverickV2Pool(pool_);
    }

    function unpackAddLiquidityArgs(
        bytes memory argsPacked
    ) internal pure returns (IMaverickV2Pool.AddLiquidityParams memory args) {
        args.kind = uint8(argsPacked[0]);
        args.ticks = unpackInt32Array(argsPacked.slice(1, argsPacked.length - 1));
        uint256 startByte = args.ticks.length * 4 + 2;
        args.amounts = unpackUint128Array(argsPacked.slice(startByte, argsPacked.length - startByte));
    }

    function packAddLiquidityArgs(
        IMaverickV2Pool.AddLiquidityParams memory args
    ) internal pure returns (bytes memory argsPacked) {
        argsPacked = abi.encodePacked(args.kind);
        argsPacked = bytes.concat(argsPacked, packArray(args.ticks));
        argsPacked = bytes.concat(argsPacked, packArray(args.amounts));
    }

    function packAddLiquidityArgsToArray(
        IMaverickV2Pool.AddLiquidityParams memory args
    ) internal pure returns (bytes[] memory argsPacked) {
        argsPacked = new bytes[](1);
        argsPacked[0] = packAddLiquidityArgs(args);
    }

    function packAddLiquidityArgsArray(
        IMaverickV2Pool.AddLiquidityParams[] memory args
    ) internal pure returns (bytes[] memory argsPacked) {
        argsPacked = new bytes[](args.length);
        for (uint256 k; k < args.length; k++) {
            argsPacked[k] = packAddLiquidityArgs(args[k]);
        }
    }

    function unpackInt32Array(bytes memory input) internal pure returns (int32[] memory array) {
        uint256[] memory output = _unpackArray(input, 4);
        assembly ("memory-safe") {
            array := output
        }
    }

    function unpackUint128Array(bytes memory input) internal pure returns (uint128[] memory array) {
        uint256[] memory output = _unpackArray(input, 16);
        assembly ("memory-safe") {
            array := output
        }
    }

    function unpackUint88Array(bytes memory input) internal pure returns (uint88[] memory array) {
        uint256[] memory output = _unpackArray(input, 11);
        assembly ("memory-safe") {
            array := output
        }
    }

    function packArray(int32[] memory array) internal pure returns (bytes memory output) {
        uint256[] memory input;
        assembly ("memory-safe") {
            input := array
        }
        output = _packArray(input, 4);
    }

    function packArray(uint128[] memory array) internal pure returns (bytes memory output) {
        uint256[] memory input;
        assembly ("memory-safe") {
            input := array
        }
        output = _packArray(input, 16);
    }

    function packArray(uint88[] memory array) internal pure returns (bytes memory output) {
        uint256[] memory input;
        assembly ("memory-safe") {
            input := array
        }
        output = _packArray(input, 11);
    }

    /*
     * @notice [length, array[0], array[1],..., array[length-1]]. length is 1 bytes.
     * @dev Unpacked signed array elements will contain "dirty bits".  That is,
     * this function does not 0xf pad signed return elements.
     */
    function _unpackArray(bytes memory input, uint256 elementBytes) internal pure returns (uint256[] memory array) {
        uint256 packedPointer;
        uint256 arrayLength;
        assembly ("memory-safe") {
            // read from input pointer + 32 bytes
            // pad 1-byte length value to fill 32 bytes (248 pad bits)
            arrayLength := shr(248, mload(add(input, 0x20)))
            packedPointer := add(input, 0x21)
        }

        uint256 padRight = 256 - 8 * elementBytes;
        assembly ("memory-safe") {
            // Allocate a word for each element, and a word for the array's length
            let allocateBytes := add(mul(arrayLength, 32), 0x20)
            // Allocate memory and update the free memory pointer
            array := mload(0x40)
            mstore(0x40, add(array, allocateBytes))

            // Store array length
            mstore(array, arrayLength)

            for {
                let i := 0
                let arrayCursor := add(array, 0x20) // skip array length
                let packedCursor := packedPointer
            } lt(i, arrayLength) {
                // Loop until we reach the end of the array
                i := add(i, 1)
                arrayCursor := add(arrayCursor, 0x20) // increment array pointer by one word
                packedCursor := add(packedCursor, elementBytes) // increment packed pointer by one element size
            } {
                mstore(arrayCursor, shr(padRight, mload(packedCursor))) // unpack one array element
            }
        }
    }

    /*
     * @dev [length, array[0], array[1],..., array[length-1]]. length is 1 bytes.
     */
    function _packArray(uint256[] memory array, uint256 elementBytes) internal pure returns (bytes memory output) {
        // cast to check size fits in 8 bits
        uint8 arrayLength = array.length.toUint8();
        uint256 packedLength = arrayLength * elementBytes + 1;

        output = new bytes(packedLength);

        uint256 padLeft = 256 - 8 * elementBytes;
        assembly ("memory-safe") {
            // Store array length
            mstore(add(output, 0x20), shl(248, arrayLength))

            for {
                let i := 0
                let arrayCursor := add(array, 0x20) // skip array length
                let packedCursor := add(output, 0x21) // skip length
            } lt(i, arrayLength) {
                // Loop until we reach the end of the array
                i := add(i, 1)
                arrayCursor := add(arrayCursor, 0x20) // increment array pointer by one word
                packedCursor := add(packedCursor, elementBytes) // increment packed pointer by one element size
            } {
                mstore(packedCursor, shl(padLeft, mload(arrayCursor))) // pack one array element
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {SafeCast as Cast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {Math} from "@maverick/v2-common/contracts/libraries/Math.sol";
import {PoolLib} from "@maverick/v2-common/contracts/libraries/PoolLib.sol";
import {TickMath} from "@maverick/v2-common/contracts/libraries/TickMath.sol";

library PoolInspection {
    using Cast for uint256;

    /**
     * @dev Calculates the square root price of a given Maverick V2 pool.
     * @param pool The Maverick V2 pool to inspect.
     * @return sqrtPrice The square root price of the pool.
     */
    function poolSqrtPrice(IMaverickV2Pool pool) internal view returns (uint256 sqrtPrice) {
        int32 activeTick = pool.getState().activeTick;
        IMaverickV2Pool.TickState memory tickState = pool.getTick(activeTick);

        (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(
            pool.tickSpacing(),
            activeTick
        );

        (sqrtPrice, ) = TickMath.getTickSqrtPriceAndL(
            tickState.reserveA,
            tickState.reserveB,
            sqrtLowerTickPrice,
            sqrtUpperTickPrice
        );
    }

    /**
     * @dev Retrieves the reserves of a user's subaccount for a specific bin.
     */
    function userSubaccountBinReserves(
        IMaverickV2Pool pool,
        address user,
        uint256 subaccount,
        uint32 binId
    ) internal view returns (uint256 amountA, uint256 amountB, int32 tick, uint256 liquidity) {
        IMaverickV2Pool.BinState memory bin = pool.getBin(binId);

        uint256 userBinLpBalance = pool.balanceOf(user, subaccount, binId);
        while (bin.mergeId != 0) {
            userBinLpBalance = bin.totalSupply == 0
                ? 0
                : Math.mulDivFloor(userBinLpBalance, bin.mergeBinBalance, bin.totalSupply);
            bin = pool.getBin(bin.mergeId);
        }
        tick = bin.tick;

        IMaverickV2Pool.TickState memory tickState = pool.getTick(tick);

        uint256 activeBinDeltaLpBalance = Math.min(userBinLpBalance, bin.totalSupply);

        uint128 deltaTickBalance = Math
            .mulDivDown(activeBinDeltaLpBalance, bin.tickBalance, bin.totalSupply)
            .toUint128();

        deltaTickBalance = Math.min128(deltaTickBalance, tickState.totalSupply);

        (amountA, amountB) = PoolLib.binReserves(
            deltaTickBalance,
            tickState.reserveA,
            tickState.reserveB,
            tickState.totalSupply
        );

        {
            (uint256 sqrtLowerTickPrice, uint256 sqrtUpperTickPrice) = TickMath.tickSqrtPrices(
                pool.tickSpacing(),
                tick
            );
            liquidity = TickMath.getTickL(amountA, amountB, sqrtLowerTickPrice, sqrtUpperTickPrice);
        }
    }

    /**
     * @dev Retrieves the reserves of a token for all bins associated with it.
     * Bin reserve amounts are in pool D18 scale units.
     */
    function subaccountPositionInformation(
        IMaverickV2Pool pool,
        address user,
        uint256 subaccount,
        uint32[] memory binIds
    )
        internal
        view
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256[] memory binAAmounts,
            uint256[] memory binBAmounts,
            int32[] memory ticks,
            uint256[] memory liquidities
        )
    {
        binAAmounts = new uint256[](binIds.length);
        binBAmounts = new uint256[](binIds.length);
        ticks = new int32[](binIds.length);
        liquidities = new uint256[](binIds.length);

        for (uint256 i; i < binIds.length; i++) {
            (binAAmounts[i], binBAmounts[i], ticks[i], liquidities[i]) = userSubaccountBinReserves(
                pool,
                user,
                subaccount,
                binIds[i]
            );
            amountA += binAAmounts[i];
            amountB += binBAmounts[i];
        }
        {
            uint256 tokenAScale = pool.tokenAScale();
            uint256 tokenBScale = pool.tokenBScale();
            amountA = Math.ammScaleToTokenScale(amountA, tokenAScale, false);
            amountB = Math.ammScaleToTokenScale(amountB, tokenBScale, false);
        }
    }

    function binLpBalances(
        IMaverickV2Pool pool,
        uint32[] memory binIds,
        uint256 subaccount
    ) internal view returns (uint128[] memory amounts) {
        amounts = new uint128[](binIds.length);
        for (uint256 i = 0; i < binIds.length; i++) {
            amounts[i] = pool.balanceOf(address(this), subaccount, binIds[i]);
        }
    }

    function lpBalanceForTargetReserveAmounts(
        IMaverickV2Pool pool,
        uint32 binId,
        uint256 amountA,
        uint256 amountB,
        uint256 scaleA,
        uint256 scaleB
    ) internal view returns (IMaverickV2Pool.AddLiquidityParams memory addParams) {
        amountA = Math.tokenScaleToAmmScale(amountA, scaleA);
        amountB = Math.tokenScaleToAmmScale(amountB, scaleB);

        IMaverickV2Pool.BinState memory bin = pool.getBin(binId);
        uint128[] memory amounts = new uint128[](1);

        IMaverickV2Pool.TickState memory tickState = pool.getTick(bin.tick);
        uint256 numerator = Math.max(1, uint256(tickState.totalSupply)) * Math.max(1, uint256(bin.totalSupply));

        if (amountA != 0) {
            uint256 denominator = Math.max(1, uint256(bin.tickBalance)) * uint256(tickState.reserveA);
            amounts[0] = Math.mulDivFloor(amountA, numerator, denominator).toUint128();
        }
        if (amountB != 0) {
            uint256 denominator = Math.max(1, uint256(bin.tickBalance)) * uint256(tickState.reserveB);

            if (amountA != 0) {
                amounts[0] = Math.min128(amounts[0], Math.mulDivFloor(amountB, numerator, denominator).toUint128());
            } else {
                amounts[0] = Math.mulDivFloor(amountB, numerator, denominator).toUint128();
            }
        }
        {
            int32[] memory ticks = new int32[](1);
            ticks[0] = bin.tick;
            addParams = IMaverickV2Pool.AddLiquidityParams({kind: bin.kind, ticks: ticks, amounts: amounts});
        }
    }

    function maxRemoveParams(
        IMaverickV2Pool pool,
        uint32 binId,
        address user,
        uint256 subaccount
    ) internal view returns (IMaverickV2Pool.RemoveLiquidityParams memory params) {
        uint32[] memory binIds = new uint32[](1);
        uint128[] memory amounts = new uint128[](1);
        binIds[0] = binId;
        amounts[0] = pool.balanceOf(user, subaccount, binId);
        params = IMaverickV2Pool.RemoveLiquidityParams({binIds: binIds, amounts: amounts});
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {PackLib} from "../libraries/PackLib.sol";
import {IArgPacker} from "./IArgPacker.sol";

/**
 * @notice View functions that pack and unpack addLiquidity parameters.
 */
abstract contract ArgPacker is IArgPacker {
    /// @inheritdoc IArgPacker
    function unpackAddLiquidityArgs(
        bytes memory argsPacked
    ) public pure returns (IMaverickV2Pool.AddLiquidityParams memory args) {
        return PackLib.unpackAddLiquidityArgs(argsPacked);
    }

    /// @inheritdoc IArgPacker
    function packAddLiquidityArgs(
        IMaverickV2Pool.AddLiquidityParams memory args
    ) public pure returns (bytes memory argsPacked) {
        return PackLib.packAddLiquidityArgs(args);
    }

    /// @inheritdoc IArgPacker
    function packAddLiquidityArgsArray(
        IMaverickV2Pool.AddLiquidityParams[] memory args
    ) public pure returns (bytes[] memory argsPacked) {
        return PackLib.packAddLiquidityArgsArray(args);
    }

    /// @inheritdoc IArgPacker
    function unpackUint88Array(bytes memory packedArray) public pure returns (uint88[] memory fullArray) {
        fullArray = PackLib.unpackUint88Array(packedArray);
    }

    /// @inheritdoc IArgPacker
    function packUint88Array(uint88[] memory fullArray) public pure returns (bytes memory packedArray) {
        packedArray = PackLib.packArray(fullArray);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

interface IArgPacker {
    /**
     * @notice Packs addLiquidity paramters into a bytes object.  The packing
     * is [kind, ticksArray, amountsArray] where the arrays are packed like
     * this: [length, array[0], array[1],..., array[length-1]]. length is 1
     * byte (256 total possible elements).
     */
    function packAddLiquidityArgs(
        IMaverickV2Pool.AddLiquidityParams memory args
    ) external pure returns (bytes memory argsPacked);

    /**
     * @notice Unpacks packed addLiquidity parameters.
     */
    function unpackAddLiquidityArgs(
        bytes memory argsPacked
    ) external pure returns (IMaverickV2Pool.AddLiquidityParams memory args);

    /**
     * @notice Packs addLiquidity paramters array element-wise.
     */
    function packAddLiquidityArgsArray(
        IMaverickV2Pool.AddLiquidityParams[] memory args
    ) external pure returns (bytes[] memory argsPacked);

    /**
     * @notice Packs sqrtPrice breaks array with this format: [length,
     * array[0], array[1],..., array[length-1]] where length is 1 byte.

     */
    function packUint88Array(uint88[] memory fullArray) external pure returns (bytes memory packedArray);

    /**
     * @notice Unpacks sqrtPrice breaks bytes object into array.
     */
    function unpackUint88Array(bytes memory packedArray) external pure returns (uint88[] memory fullArray);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";
import {EMPTY_PRICE_BREAKS} from "@maverick/v2-common/contracts/libraries/Constants.sol";

import {PoolInspection} from "./libraries/PoolInspection.sol";
import {IMaverickV2Position} from "./interfaces/IMaverickV2Position.sol";
import {IMaverickV2PoolLens} from "./interfaces/IMaverickV2PoolLens.sol";
import {IMaverickV2BoostedPosition} from "./interfaces/IMaverickV2BoostedPosition.sol";
import {IMaverickV2LiquidityManager} from "./interfaces/IMaverickV2LiquidityManager.sol";
import {IMaverickV2BoostedPositionFactory} from "./interfaces/IMaverickV2BoostedPositionFactory.sol";
import {IWETH9} from "./paymentbase/IWETH9.sol";
import {ArgPacker} from "./liquiditybase/ArgPacker.sol";
import {State} from "./paymentbase/State.sol";
import {ExactOutputSlim} from "./routerbase/ExactOutputSlim.sol";
import {LiquidityUtilities} from "./libraries/LiquidityUtilities.sol";
import {Checks} from "./base/Checks.sol";
import {MigrateBins} from "./base/MigrateBins.sol";

/**
 * @notice Maverick liquidity management contract that provides helper
 * functions for minting either NFT liquidity positions or boosted positions
 * which are fungible positions in a Maverick V2 pool.  While this contract
 * does have public payment callback functions, these are access controlled
 * so that they can only be called by a factory pool; so it is safe to approve
 * this contract to spend a caller's tokens.
 *
 * This contract inherits "Check" functions that can be multicalled with
 * liquidity management functions to create slippage and deadline constraints on
 * transactions.
 *
 *
 * @dev This contract has a multicall interface and all public functions are
 * payable which facilitates multicall combinations of both payable
 * interactions and non-payable interactions.
 *
 * @dev addLiquidity parameters are specified as a lookup table of prices where
 * the caller specifies packedSqrtPriceBreaks and packedArgs.  During the add
 * operation, this contract queries the pool for its current sqrtPrice and then
 * looks up this price relative to the price breaks array (the array is packed
 * as bytes using the conventions in the inherited ArgPacker contract to save
 * calldata space).  If the current pool sqrt price is in between the N and N+1
 * elements of the packedSqrtPriceBreaks array, then the add parameters from the
 * Nth element of the packedArgs array are used in the add liquidity call.
 *
 * @dev This lookup table approach provides a flexible way for callers to
 * manage price slippage between the time they submit their transaction and the
 * time it is executed. The MaverickV2PoolLens contract provides a number of
 * helper function to create this slippage lookup table.
 */
contract MaverickV2LiquidityManager is Checks, ExactOutputSlim, ArgPacker, MigrateBins, IMaverickV2LiquidityManager {
    /// @inheritdoc IMaverickV2LiquidityManager
    IMaverickV2Position public immutable position;

    /// @inheritdoc IMaverickV2LiquidityManager
    IMaverickV2BoostedPositionFactory public immutable boostedPositionFactory;

    constructor(
        IMaverickV2Factory _factory,
        IWETH9 _weth,
        IMaverickV2Position _position,
        IMaverickV2BoostedPositionFactory _boostedPositionFactory
    ) State(_factory, _weth) {
        position = _position;
        boostedPositionFactory = _boostedPositionFactory;
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function createPool(
        uint64 fee,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds
    ) public payable returns (IMaverickV2Pool pool) {
        pool = factory().create(fee, fee, tickSpacing, lookback, tokenA, tokenB, activeTick, kinds);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function createPool(
        uint64 feeAIn,
        uint64 feeBIn,
        uint16 tickSpacing,
        uint32 lookback,
        IERC20 tokenA,
        IERC20 tokenB,
        int32 activeTick,
        uint8 kinds
    ) public payable returns (IMaverickV2Pool pool) {
        pool = factory().create(feeAIn, feeBIn, tickSpacing, lookback, tokenA, tokenB, activeTick, kinds);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function addLiquidity(
        IMaverickV2Pool pool,
        address recipient,
        uint256 subaccount,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds) {
        uint256 sqrtPrice = PoolInspection.poolSqrtPrice(pool);

        uint256 priceIndex = LiquidityUtilities.priceIndexFromPriceBreaks(sqrtPrice, packedSqrtPriceBreaks);
        IMaverickV2Pool.AddLiquidityParams memory args = unpackAddLiquidityArgs(packedArgs[priceIndex]);
        (tokenAAmount, tokenBAmount, binIds) = pool.addLiquidity(recipient, subaccount, args, abi.encode(msg.sender));
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function addPositionLiquidityToSenderByTokenIndex(
        IMaverickV2Pool pool,
        uint256 index,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds) {
        (tokenAAmount, tokenBAmount, binIds) = addLiquidity(
            pool,
            address(position),
            position.tokenOfOwnerByIndex(msg.sender, index),
            packedSqrtPriceBreaks,
            packedArgs
        );
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function addPositionLiquidityToRecipientByTokenIndex(
        IMaverickV2Pool pool,
        address recipient,
        uint256 index,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds) {
        (tokenAAmount, tokenBAmount, binIds) = addLiquidity(
            pool,
            address(position),
            position.tokenOfOwnerByIndex(recipient, index),
            packedSqrtPriceBreaks,
            packedArgs
        );
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function mintPositionNft(
        IMaverickV2Pool pool,
        address recipient,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds, uint256 tokenId) {
        (tokenAAmount, tokenBAmount, binIds) = addLiquidity(
            pool,
            address(position),
            position.nextTokenId(),
            packedSqrtPriceBreaks,
            packedArgs
        );
        tokenId = position.mint(recipient, pool, binIds);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function mintPositionNftToSender(
        IMaverickV2Pool pool,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable returns (uint256 tokenAAmount, uint256 tokenBAmount, uint32[] memory binIds, uint256 tokenId) {
        return mintPositionNft(pool, msg.sender, packedSqrtPriceBreaks, packedArgs);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function migrateBoostedPosition(IMaverickV2BoostedPosition boostedPosition) public payable {
        boostedPosition.migrateBinLiquidityToRoot();
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function mintBoostedPosition(
        IMaverickV2BoostedPosition boostedPosition,
        address recipient
    ) public payable returns (uint256 mintedLpAmount) {
        mintedLpAmount = boostedPosition.mint(recipient);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function addLiquidityAndMintBoostedPosition(
        address recipient,
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable virtual returns (uint256 mintedLpAmount, uint256 tokenAAmount, uint256 tokenBAmount) {
        boostedPosition.migrateBinLiquidityToRoot();
        (tokenAAmount, tokenBAmount, ) = addLiquidity(
            boostedPosition.pool(),
            address(boostedPosition),
            0,
            packedSqrtPriceBreaks,
            packedArgs
        );
        mintedLpAmount = boostedPosition.mint(recipient);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function addLiquidityAndMintBoostedPositionToSender(
        IMaverickV2BoostedPosition boostedPosition,
        bytes memory packedSqrtPriceBreaks,
        bytes[] memory packedArgs
    ) public payable returns (uint256 mintedLpAmount, uint256 tokenAAmount, uint256 tokenBAmount) {
        return addLiquidityAndMintBoostedPosition(msg.sender, boostedPosition, packedSqrtPriceBreaks, packedArgs);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function createBoostedPositionAndAddLiquidityToSender(
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params
    )
        public
        payable
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount
        )
    {
        return createBoostedPositionAndAddLiquidity(msg.sender, params);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function createBoostedPositionAndAddLiquidity(
        address recipient,
        IMaverickV2PoolLens.CreateBoostedPositionInputs memory params
    )
        public
        payable
        virtual
        returns (
            IMaverickV2BoostedPosition boostedPosition,
            uint256 mintedLpAmount,
            uint256 tokenAAmount,
            uint256 tokenBAmount
        )
    {
        boostedPosition = boostedPositionFactory.createBoostedPosition(
            params.bpSpec.pool,
            params.bpSpec.binIds,
            params.bpSpec.ratios,
            params.bpSpec.kind
        );
        (tokenAAmount, tokenBAmount, ) = addLiquidity(
            params.bpSpec.pool,
            address(boostedPosition),
            0,
            params.packedSqrtPriceBreaks,
            params.packedArgs
        );
        mintedLpAmount = boostedPosition.mint(recipient);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function donateLiquidity(IMaverickV2Pool pool, IMaverickV2Pool.AddLiquidityParams memory args) public payable {
        pool.addLiquidity(address(position), 0, args, abi.encode(msg.sender));
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function createPoolAtPriceAndAddLiquidityToSender(
        IMaverickV2PoolLens.CreateAndAddParamsInputs memory params
    )
        public
        payable
        returns (
            IMaverickV2Pool pool,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint32[] memory binIds,
            uint256 tokenId
        )
    {
        return createPoolAtPriceAndAddLiquidity(msg.sender, params);
    }

    /// @inheritdoc IMaverickV2LiquidityManager
    function createPoolAtPriceAndAddLiquidity(
        address recipient,
        IMaverickV2PoolLens.CreateAndAddParamsInputs memory params
    )
        public
        payable
        returns (
            IMaverickV2Pool pool,
            uint256 tokenAAmount,
            uint256 tokenBAmount,
            uint32[] memory binIds,
            uint256 tokenId
        )
    {
        pool = createPool(
            params.feeAIn,
            params.feeBIn,
            params.tickSpacing,
            params.lookback,
            params.tokenA,
            params.tokenB,
            params.activeTick,
            params.kinds
        );
        if (params.swapAmount != 0) {
            donateLiquidity(pool, params.donateParams);
            exactOutputSingleMinimal(recipient, pool, true, params.swapAmount, type(int32).max);
        }

        (tokenAAmount, tokenBAmount, binIds, tokenId) = mintPositionNft(
            pool,
            recipient,
            EMPTY_PRICE_BREAKS,
            params.packedAddParams
        );
    }

    function maverickV2AddLiquidityCallback(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountA,
        uint256 amountB,
        bytes calldata data
    ) public {
        if (!factory().isFactoryPool(IMaverickV2Pool(msg.sender))) revert LiquidityManagerNotFactoryPool();
        address payer = abi.decode(data, (address));
        if (amountA != 0) {
            pay(tokenA, payer, msg.sender, amountA);
        }
        if (amountB != 0) {
            pay(tokenB, payer, msg.sender, amountB);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IPayableMulticall} from "@maverick/v2-common/contracts/base/IPayableMulticall.sol";

import {IState} from "./IState.sol";

interface IPayment is IPayableMulticall, IState {
    error PaymentSenderNotWETH9();
    error PaymentInsufficientBalance(address token, uint256 amountMinimum, uint256 contractBalance);

    receive() external payable;

    /**
     * @notice Unwrap WETH9 tokens into ETH and send that balance to recipient.
     * If less than amountMinimum WETH is avialble, then revert.
     */
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /**
     * @notice Transfers specified token amount to recipient
     */
    function sweepTokenAmount(IERC20 token, uint256 amount, address recipient) external payable;

    /**
     * @notice Sweep entire ERC20 token balance on this contract to recipient.
     * If less than amountMinimum balance is avialble, then revert.
     */
    function sweepToken(IERC20 token, uint256 amountMinimum, address recipient) external payable;

    /**
     * @notice Send any ETH on this contract to msg.sender.
     */
    function refundETH() external payable;

    /**
     * @notice For tokenA and tokenB, sweep all of the
     * non-WETH tokens to msg.sender.  Any WETH balance is unwrapped to ETH and
     * then all the ETH on this contract is sent to msg.sender.
     */
    function unwrapAndSweep(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 tokenAAmountMin,
        uint256 tokenBAmountMin
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IWETH9} from "./IWETH9.sol";
import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";

interface IState {
    function weth() external view returns (IWETH9 _weth);
    function factory() external view returns (IMaverickV2Factory _factory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransferLib} from "@maverick/v2-common/contracts/libraries/TransferLib.sol";
import {PayableMulticall} from "@maverick/v2-common/contracts/base/PayableMulticall.sol";

import {IWETH9} from "./IWETH9.sol";
import {State} from "./State.sol";

import {IPayment} from "./IPayment.sol";

/**
 * @notice Payment helper function that lets user sweep ERC20 tokens off the
 * router and liquidity manager.  Also provides mechanism to wrap and unwrap
 * ETH/WETH so that it can be used in the Maverick pools.
 */
abstract contract Payment is State, PayableMulticall, IPayment {
    receive() external payable {
        if (IWETH9(msg.sender) != weth()) revert PaymentSenderNotWETH9();
    }

    /// @inheritdoc IPayment
    function unwrapWETH9(uint256 amountMinimum, address recipient) public payable {
        uint256 balanceWETH9 = weth().balanceOf(address(this));
        if (balanceWETH9 < amountMinimum)
            revert PaymentInsufficientBalance(address(weth()), amountMinimum, balanceWETH9);
        if (balanceWETH9 > 0) {
            weth().withdraw(balanceWETH9);
            Address.sendValue(payable(recipient), balanceWETH9);
        }
    }

    /// @inheritdoc IPayment
    function sweepToken(IERC20 token, uint256 amountMinimum, address recipient) public payable {
        uint256 balanceToken = token.balanceOf(address(this));
        if (balanceToken < amountMinimum)
            revert PaymentInsufficientBalance(address(token), amountMinimum, balanceToken);
        if (balanceToken > 0) {
            TransferLib.transfer(token, recipient, balanceToken);
        }
    }

    /// @inheritdoc IPayment
    function sweepTokenAmount(IERC20 token, uint256 amount, address recipient) public payable {
        TransferLib.transfer(token, recipient, amount);
    }

    /// @inheritdoc IPayment
    function unwrapAndSweep(
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 tokenAAmountMin,
        uint256 tokenBAmountMin
    ) public payable {
        if (address(tokenA) == address(weth())) {
            unwrapWETH9(tokenAAmountMin, msg.sender);
            refundETH();
            sweepToken(tokenB, tokenBAmountMin, msg.sender);
        } else if (address(tokenB) == address(weth())) {
            sweepToken(tokenA, tokenAAmountMin, msg.sender);
            unwrapWETH9(tokenBAmountMin, msg.sender);
            refundETH();
        } else {
            sweepToken(tokenA, tokenAAmountMin, msg.sender);
            sweepToken(tokenB, tokenBAmountMin, msg.sender);
        }
    }

    /// @inheritdoc IPayment
    function refundETH() public payable {
        if (address(this).balance > 0) Address.sendValue(payable(msg.sender), address(this).balance);
    }

    /**
     * @notice Internal function to pay tokens or eth.
     * @param token ERC20 token to pay.
     * @param payer Address of the payer.
     * @param recipient Address of the recipient.
     * @param value Amount of tokens to pay.
     */
    function pay(IERC20 token, address payer, address recipient, uint256 value) internal {
        if (IWETH9(address(token)) == weth() && address(this).balance >= value) {
            weth().deposit{value: value}();
            weth().transfer(recipient, value);
        } else if (payer == address(this)) {
            TransferLib.transfer(token, recipient, value);
        } else {
            TransferLib.transferFrom(token, payer, recipient, value);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";
import {IWETH9} from "./IWETH9.sol";
import {IState} from "./IState.sol";

abstract contract State is IState {
    IWETH9 private immutable _weth;
    IMaverickV2Factory private immutable _factory;

    constructor(IMaverickV2Factory __factory, IWETH9 __weth) {
        _factory = __factory;
        _weth = __weth;
    }

    function weth() public view returns (IWETH9 weth_) {
        weth_ = _weth;
    }

    function factory() public view returns (IMaverickV2Factory factory_) {
        factory_ = _factory;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface INft is IERC721Enumerable {
    /**
     * @notice Check if an NFT exists for a given owner and index.
     */
    function tokenOfOwnerByIndexExists(address owner, uint256 index) external view returns (bool);

    /**
     * @notice Return Id of the next token minted.
     */
    function nextTokenId() external view returns (uint256 nextTokenId_);

    /**
     * @notice Check if the caller has access to a specific NFT by tokenId.
     */
    function checkAuthorized(address spender, uint256 tokenId) external view returns (address owner);

    /**
     * @notice List of tokenIds by owner.
     */
    function tokenIdsOfOwner(address owner) external view returns (uint256[] memory tokenIds);

    /**
     * @notice Get the token URI for a given tokenId.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

import {Payment} from "../paymentbase/Payment.sol";
import {IExactOutputSlim} from "./IExactOutputSlim.sol";
import {Swap} from "./Swap.sol";

abstract contract ExactOutputSlim is Payment, Swap, IExactOutputSlim {
    /**
     * @dev Callback function called by Maverick V2 pools when swapping tokens.
     * @param tokenIn The input token.
     * @param amountToPay The amount to pay.
     * @param data Additional data.
     */
    function maverickV2SwapCallback(
        IERC20 tokenIn,
        uint256 amountToPay,
        uint256,
        bytes calldata data
    ) external virtual {
        if (!factory().isFactoryPool(IMaverickV2Pool(msg.sender))) revert RouterNotFactoryPool();
        address payer = abi.decode(data, (address));
        if (amountToPay != 0) pay(tokenIn, payer, msg.sender, amountToPay);
    }

    /**
     * @dev Perform a swap with an exact output amount.
     * @param recipient The recipient of the swapped tokens.
     * @param pool The MaverickV2 pool to use for the swap.
     * @param tokenAIn Whether token A is the input token.
     * @param amountOut The exact output amount.
     * @param tickLimit The tick limit for the swap.
     * @return amountIn The input amount required to achieve the exact output.
     * @return amountOut_ The actual output amount received from the swap.
     */
    function exactOutputSingleMinimal(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountOut,
        int32 tickLimit
    ) public payable returns (uint256 amountIn, uint256 amountOut_) {
        (amountIn, amountOut_) = _exactOutputSingleWithTickCheck(pool, recipient, amountOut, tokenAIn, tickLimit);
    }

    /**
     * @dev Perform an exact output single swap with tick limit validation.
     * @param pool The MaverickV2 pool to use for the swap.
     * @param recipient The recipient of the swapped tokens.
     * @param amountOut The exact output amount.
     * @param tokenAIn Whether token A is the input token.
     * @param tickLimit The tick limit for the swap.
     * @return amountIn The input amount required to achieve the exact output.
     * @return _amountOut The actual output amount received from the swap.
     */
    function _exactOutputSingleWithTickCheck(
        IMaverickV2Pool pool,
        address recipient,
        uint256 amountOut,
        bool tokenAIn,
        int32 tickLimit
    ) internal returns (uint256 amountIn, uint256 _amountOut) {
        IMaverickV2Pool.SwapParams memory swapParams = IMaverickV2Pool.SwapParams({
            amount: amountOut,
            tokenAIn: tokenAIn,
            exactOutput: true,
            tickLimit: tickLimit
        });
        (amountIn, _amountOut) = _swap(
            pool,
            (recipient == address(0)) ? address(this) : recipient,
            swapParams,
            abi.encode(msg.sender)
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

import {IRouterErrors} from "./IRouterErrors.sol";

interface IExactOutputSlim is IRouterErrors {
    function exactOutputSingleMinimal(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountOut,
        int32 tickLimit
    ) external payable returns (uint256 amountIn, uint256 amountOut_);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

interface IRouterErrors {
    error RouterZeroSwap();
    error RouterNotFactoryPool();
    error RouterTooLittleReceived(uint256 amountOutMinimum, uint256 amountOut);
    error RouterTooMuchRequested(uint256 amountInMaximum, uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.25;

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

/**
 * @notice Base contract support for swaps
 */
abstract contract Swap {
    /**
     * @notice Internal swap function.  Override this function to add logic
     * before or after a swap.
     */
    function _swap(
        IMaverickV2Pool pool,
        address recipient,
        IMaverickV2Pool.SwapParams memory params,
        bytes memory data
    ) internal virtual returns (uint256 amountIn, uint256 amountOut) {
        (amountIn, amountOut) = pool.swap(recipient, params, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.20;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 */
interface IVotes {
    /**
     * @dev The signature used has expired.
     */
    error VotesExpiredSignature(uint256 expiry);

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     */
    function getPastVotes(address account, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value at the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC6372.sol)

pragma solidity ^0.8.20;

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.20;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeCast {
    /**
     * @dev Value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedUintDowncast(uint8 bits, uint256 value);

    /**
     * @dev An int value doesn't fit in an uint of `bits` size.
     */
    error SafeCastOverflowedIntToUint(int256 value);

    /**
     * @dev Value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedIntDowncast(uint8 bits, int256 value);

    /**
     * @dev An uint value doesn't fit in an int of `bits` size.
     */
    error SafeCastOverflowedUintToInt(uint256 value);

    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        if (value > type(uint248).max) {
            revert SafeCastOverflowedUintDowncast(248, value);
        }
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        if (value > type(uint240).max) {
            revert SafeCastOverflowedUintDowncast(240, value);
        }
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        if (value > type(uint232).max) {
            revert SafeCastOverflowedUintDowncast(232, value);
        }
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        if (value > type(uint224).max) {
            revert SafeCastOverflowedUintDowncast(224, value);
        }
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        if (value > type(uint216).max) {
            revert SafeCastOverflowedUintDowncast(216, value);
        }
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        if (value > type(uint208).max) {
            revert SafeCastOverflowedUintDowncast(208, value);
        }
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        if (value > type(uint200).max) {
            revert SafeCastOverflowedUintDowncast(200, value);
        }
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        if (value > type(uint192).max) {
            revert SafeCastOverflowedUintDowncast(192, value);
        }
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        if (value > type(uint184).max) {
            revert SafeCastOverflowedUintDowncast(184, value);
        }
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        if (value > type(uint176).max) {
            revert SafeCastOverflowedUintDowncast(176, value);
        }
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        if (value > type(uint168).max) {
            revert SafeCastOverflowedUintDowncast(168, value);
        }
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        if (value > type(uint160).max) {
            revert SafeCastOverflowedUintDowncast(160, value);
        }
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        if (value > type(uint152).max) {
            revert SafeCastOverflowedUintDowncast(152, value);
        }
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        if (value > type(uint144).max) {
            revert SafeCastOverflowedUintDowncast(144, value);
        }
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        if (value > type(uint136).max) {
            revert SafeCastOverflowedUintDowncast(136, value);
        }
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        if (value > type(uint128).max) {
            revert SafeCastOverflowedUintDowncast(128, value);
        }
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        if (value > type(uint120).max) {
            revert SafeCastOverflowedUintDowncast(120, value);
        }
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        if (value > type(uint112).max) {
            revert SafeCastOverflowedUintDowncast(112, value);
        }
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        if (value > type(uint104).max) {
            revert SafeCastOverflowedUintDowncast(104, value);
        }
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        if (value > type(uint96).max) {
            revert SafeCastOverflowedUintDowncast(96, value);
        }
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        if (value > type(uint88).max) {
            revert SafeCastOverflowedUintDowncast(88, value);
        }
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        if (value > type(uint80).max) {
            revert SafeCastOverflowedUintDowncast(80, value);
        }
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        if (value > type(uint72).max) {
            revert SafeCastOverflowedUintDowncast(72, value);
        }
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        if (value > type(uint64).max) {
            revert SafeCastOverflowedUintDowncast(64, value);
        }
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        if (value > type(uint56).max) {
            revert SafeCastOverflowedUintDowncast(56, value);
        }
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        if (value > type(uint48).max) {
            revert SafeCastOverflowedUintDowncast(48, value);
        }
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        if (value > type(uint40).max) {
            revert SafeCastOverflowedUintDowncast(40, value);
        }
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        if (value > type(uint32).max) {
            revert SafeCastOverflowedUintDowncast(32, value);
        }
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        if (value > type(uint24).max) {
            revert SafeCastOverflowedUintDowncast(24, value);
        }
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        if (value > type(uint16).max) {
            revert SafeCastOverflowedUintDowncast(16, value);
        }
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        if (value > type(uint8).max) {
            revert SafeCastOverflowedUintDowncast(8, value);
        }
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        if (value < 0) {
            revert SafeCastOverflowedIntToUint(value);
        }
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(248, value);
        }
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(240, value);
        }
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(232, value);
        }
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(224, value);
        }
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(216, value);
        }
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(208, value);
        }
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(200, value);
        }
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(192, value);
        }
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(184, value);
        }
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(176, value);
        }
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(168, value);
        }
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(160, value);
        }
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(152, value);
        }
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(144, value);
        }
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(136, value);
        }
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(128, value);
        }
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(120, value);
        }
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(112, value);
        }
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(104, value);
        }
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(96, value);
        }
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(88, value);
        }
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(80, value);
        }
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(72, value);
        }
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(64, value);
        }
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(56, value);
        }
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(48, value);
        }
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(40, value);
        }
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(32, value);
        }
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(24, value);
        }
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(16, value);
        }
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        if (downcasted != value) {
            revert SafeCastOverflowedIntDowncast(8, value);
        }
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        if (value > uint256(type(int256).max)) {
            revert SafeCastOverflowedUintToInt(value);
        }
        return int256(value);
    }
}