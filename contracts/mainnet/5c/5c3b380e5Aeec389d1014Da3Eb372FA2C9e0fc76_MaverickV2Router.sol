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

import {ICallbackOperations} from "../routerbase/ICallbackOperations.sol";
import {IPushOperations} from "../routerbase/IPushOperations.sol";
import {IPayment} from "../paymentbase/IPayment.sol";
import {IChecks} from "../base/IChecks.sol";

/* solhint-disable no-empty-blocks */
interface IMaverickV2Router is IPayment, IChecks, ICallbackOperations, IPushOperations {}

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
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";
import {BytesLib} from "./BytesLib.sol";

/**
 * @notice Path is [pool_addr, tokenAIn, pool_addr, tokenAIn ...], alternating 20
 * bytes and then one byte for the tokenAIn bool.
 */
library Path {
    using BytesLib for bytes;

    /**
     * @notice The length of the bytes encoded address.
     */
    uint256 private constant ADDR_SIZE = 20;

    /**
     * @notice The length of the bytes encoded bool.
     */
    uint256 private constant BOOL_SIZE = 1;

    /**
     * @notice The offset of a single token address and pool address.
     */
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + BOOL_SIZE;

    /**
     * @notice Returns true iff the path contains two or more pools.
     * @param path The encoded swap path.
     * @return True if path contains two or more pools, otherwise false.
     */
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length > NEXT_OFFSET;
    }

    /**
     * @notice Decodes the first pool in path.
     * @param path The bytes encoded swap path.
     */
    function decodeFirstPool(bytes memory path) internal pure returns (IMaverickV2Pool pool, bool tokenAIn) {
        pool = IMaverickV2Pool(path.toAddress(0));
        tokenAIn = path.toBool(ADDR_SIZE);
    }

    function decodeNextPoolAddress(bytes memory path) internal pure returns (address pool) {
        pool = path.toAddress(NEXT_OFFSET);
    }

    /**
     * @notice Skips a token + pool element from the buffer and returns the
     * remainder.
     * @param path The swap path.
     * @return The remaining token + pool elements in the path.
     */
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
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

import {IMaverickV2Factory} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Factory.sol";

import {IMaverickV2Router} from "./interfaces/IMaverickV2Router.sol";
import {CallbackOperations} from "./routerbase/CallbackOperations.sol";
import {PushOperations} from "./routerbase/PushOperations.sol";
import {Checks} from "./base/Checks.sol";
import {State} from "./paymentbase/State.sol";
import {IWETH9} from "./paymentbase/IWETH9.sol";

/**
 * @notice Swap router functions for Maverick V2.  This contract requires that
 * users approve a spending allowance in order to pay for swaps.
 *
 * @notice The functions in this contract are partitioned into two subcontracts that
 * implement both push-based and callback-based swaps.  Maverick V2 provides
 * two mechanisms for paying for a swap:
 * - Push the input assets to the pool and then call swap.  This avoids a
 * callback to transfer the input assets and is generally more gas efficient but
 * is only suitable for exact-input swaps where the caller knows how much input
 * they need to send to the pool.
 * - Callback payment where the pool calls a callback function on this router
 * to settle up for the input amount of the swap.
 */
contract MaverickV2Router is Checks, PushOperations, CallbackOperations, IMaverickV2Router {
    constructor(IMaverickV2Factory _factory, IWETH9 _weth) State(_factory, _weth) {}
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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

import {ICallbackOperations} from "./ICallbackOperations.sol";
import {Path} from "../libraries/Path.sol";
import {ExactOutputSlim} from "./ExactOutputSlim.sol";

abstract contract CallbackOperations is ExactOutputSlim, ICallbackOperations {
    using Path for bytes;

    struct CallbackData {
        bytes path;
        address payer;
    }

    uint256 private __amountIn = type(uint256).max;

    /// @inheritdoc ICallbackOperations
    function exactOutputSingle(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public payable returns (uint256 amountIn, uint256 amountOut_) {
        int32 tickLimit = tokenAIn ? type(int32).max : type(int32).min;
        (amountIn, amountOut_) = _exactOutputSingleWithTickCheck(pool, recipient, amountOut, tokenAIn, tickLimit);
        if (amountIn > amountInMaximum) revert RouterTooMuchRequested(amountInMaximum, amountIn);
    }

    /// @inheritdoc ICallbackOperations
    function outputSingleWithTickLimit(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountOut,
        int32 tickLimit,
        uint256 amountInMaximum,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountIn_, uint256 amountOut_) {
        (amountIn_, amountOut_) = _exactOutputSingleWithTickCheck(pool, recipient, amountOut, tokenAIn, tickLimit);
        if (amountIn_ > amountInMaximum) revert RouterTooMuchRequested(amountInMaximum, amountIn_);
        if (amountOut_ < amountOutMinimum) revert RouterTooLittleReceived(amountOutMinimum, amountOut_);
    }

    /// @inheritdoc ICallbackOperations
    function exactOutputMultiHop(
        address recipient,
        bytes memory path,
        uint256 amountOut,
        uint256 amountInMaximum
    ) public payable returns (uint256 amountIn) {
        // recursively swap through the hops starting with the ouput pool.
        // inside of the swap callback, this contract will call the next pool
        // in the path until it gets to the input pool of the path.
        _exactOutputInternal(amountOut, recipient, CallbackData({path: path, payer: msg.sender}));
        amountIn = __amountIn;
        if (amountIn > amountInMaximum) revert RouterTooMuchRequested(amountInMaximum, amountIn);
        __amountIn = type(uint256).max;
    }

    /// @inheritdoc ICallbackOperations
    function inputSingleWithTickLimit(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountIn,
        int32 tickLimit,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountIn_, uint256 amountOut) {
        // swap
        IMaverickV2Pool.SwapParams memory swapParams = IMaverickV2Pool.SwapParams({
            amount: amountIn,
            tokenAIn: tokenAIn,
            exactOutput: false,
            tickLimit: tickLimit
        });
        (amountIn_, amountOut) = _swap(pool, recipient, swapParams, abi.encode(msg.sender));
        if (amountOut < amountOutMinimum) revert RouterTooLittleReceived(amountOutMinimum, amountOut);
    }

    function _exactOutputInternal(
        uint256 amountOut,
        address recipient,
        CallbackData memory data
    ) internal returns (uint256 amountIn) {
        if (recipient == address(0)) recipient = address(this);
        (IMaverickV2Pool pool, bool tokenAIn) = data.path.decodeFirstPool();

        int32 tickLimit = tokenAIn ? type(int32).max : type(int32).min;
        IMaverickV2Pool.SwapParams memory swapParams = IMaverickV2Pool.SwapParams({
            amount: amountOut,
            tokenAIn: tokenAIn,
            exactOutput: true,
            tickLimit: tickLimit
        });

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = _swap(pool, recipient, swapParams, abi.encode(data));
    }

    function maverickV2SwapCallback(
        IERC20 tokenIn,
        uint256 amountToPay,
        uint256,
        bytes calldata _data
    ) external override {
        // only used for either single-hop exactinput calls with a tick limit,
        // or exactouput calls.  if the path has more than one pool, then this
        // is an exactouput multihop swap.
        if (amountToPay == 0) revert RouterZeroSwap();
        if (!factory().isFactoryPool(IMaverickV2Pool(msg.sender))) revert RouterNotFactoryPool();

        if (_data.length == 32) {
            // exact in
            address payer = abi.decode(_data, (address));
            pay(tokenIn, payer, msg.sender, amountToPay);
        } else {
            // exact out
            CallbackData memory data = abi.decode(_data, (CallbackData));

            if (data.path.hasMultiplePools()) {
                data.path = data.path.skipToken();
                _exactOutputInternal(amountToPay, msg.sender, data);
            } else {
                // must be at first/input pool
                __amountIn = amountToPay;
                pay(tokenIn, data.payer, msg.sender, amountToPay);
            }
        }
    }
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

import {IExactOutputSlim} from "./IExactOutputSlim.sol";

interface ICallbackOperations is IExactOutputSlim {
    /**
     * @notice Perform an exact output single swap.
     * @param recipient The address of the recipient.
     * @param pool The Maverick V2 pool to swap with.
     * @param tokenAIn A boolean indicating if token A is the input.
     * @param amountOut The amount of output tokens desired.
     * @param amountInMaximum The maximum amount of input tokens allowed.
     * @return amountIn The amount of input tokens used for the swap.
     * @return amountOut_ The actual amount of output tokens received.
     */
    function exactOutputSingle(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountOut,
        uint256 amountInMaximum
    ) external payable returns (uint256 amountIn, uint256 amountOut_);

    /**
     * @notice Perform an output-specified single swap with tick limit check.
     * @param recipient The address of the recipient.
     * @param pool The Maverick V2 pool to swap with.
     * @param tokenAIn A boolean indicating if token A is the input.
     * @param amountOut The amount of output tokens desired.
     * @param tickLimit The tick limit for the swap.
     * @param amountInMaximum The maximum amount of input tokens allowed.
     * @param amountOutMinimum The minimum amount of output tokens expected.
     * @return amountIn_ The actual amount of input tokens used for the swap.
     * @return amountOut_ The actual amount of output tokens received.  This
     * amount can vary from the requested amountOut due to the tick limit.  If
     * the pool swaps to the tick limit, it will stop filling the order and
     * return the amount out swapped up to the ticklimit to the user.
     */
    function outputSingleWithTickLimit(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountOut,
        int32 tickLimit,
        uint256 amountInMaximum,
        uint256 amountOutMinimum
    ) external payable returns (uint256 amountIn_, uint256 amountOut_);

    /**
     * @notice Perform an exact output multihop swap.
     * @param recipient The recipient address.
     * @param path The swap path as encoded bytes.
     * @param amountOut The exact output amount.
     * @param amountInMaximum The maximum input amount allowed.
     * @return amountIn The input amount for the swap.
     */
    function exactOutputMultiHop(
        address recipient,
        bytes memory path,
        uint256 amountOut,
        uint256 amountInMaximum
    ) external payable returns (uint256 amountIn);

    /**
     * @notice Perform an input-specified single swap with tick limit check.
     * @param recipient The address of the recipient.
     * @param pool The Maverick V2 pool to swap with.
     * @param tokenAIn A boolean indicating if token A is the input.
     * @param amountIn The amount of input tokens.
     * @param tickLimit The tick limit for the swap.
     * @param amountOutMinimum The minimum amount of output tokens expected.
     * @return amountIn_ The actual input amount used for the swap. This may
     * differ from the amount the caller specified if the pool reaches the tick
     * limit.  In that case, the pool will consume the input swap amount up to
     * the tick limit and return the resulting output amount to the user.
     * @return amountOut The amount of output tokens received.
     */
    function inputSingleWithTickLimit(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountIn,
        int32 tickLimit,
        uint256 amountOutMinimum
    ) external payable returns (uint256 amountIn_, uint256 amountOut);
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

import {IMaverickV2Pool} from "@maverick/v2-common/contracts/interfaces/IMaverickV2Pool.sol";

import {IRouterErrors} from "./IRouterErrors.sol";

interface IPushOperations is IRouterErrors {
    /**
     * @notice Perform an exact input single swap with compressed input values.
     */
    function exactInputSinglePackedArgs(bytes memory argsPacked) external payable returns (uint256 amountOut);

    /**
     * @notice Perform an exact input single swap without tick limit check.
     * @param recipient The address of the recipient.
     * @param pool The Maverick V2 pool to swap with.
     * @param tokenAIn True is tokenA is the input token.  False is tokenB is
     * the input token.
     * @param amountIn The amount of input tokens.
     * @param amountOutMinimum The minimum amount of output tokens expected.
     */
    function exactInputSingle(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external payable returns (uint256 amountOut);

    /**
     * @notice Perform an exact input multi-hop swap.
     * @param recipient The address of the recipient.
     * @param path The path of tokens to swap.
     * @param amountIn The amount of input tokens.
     * @param amountOutMinimum The minimum amount of output tokens expected.
     */
    function exactInputMultiHop(
        address recipient,
        bytes memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external payable returns (uint256 amountOut);
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

import {PackLib} from "../libraries/PackLib.sol";
import {Payment} from "../paymentbase/Payment.sol";
import {Path} from "../libraries/Path.sol";
import {IPushOperations} from "./IPushOperations.sol";
import {Swap} from "./Swap.sol";

/**
 * @notice Exactinput router operations that can be performed by pushing assets
 * to the pool to swap.
 */
abstract contract PushOperations is Payment, Swap, IPushOperations {
    using Path for bytes;

    /// @inheritdoc IPushOperations
    function exactInputSinglePackedArgs(bytes memory argsPacked) public payable returns (uint256 amountOut) {
        (address recipient, IMaverickV2Pool pool, bool tokenAIn, uint256 amountIn, uint256 amountOutMinimum) = PackLib
            .unpackExactInputSingleArgsAmounts(argsPacked);
        return exactInputSingle(recipient, pool, tokenAIn, amountIn, amountOutMinimum);
    }

    /// @inheritdoc IPushOperations
    function exactInputSingle(
        address recipient,
        IMaverickV2Pool pool,
        bool tokenAIn,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountOut) {
        // pay pool
        pay(tokenAIn ? pool.tokenA() : pool.tokenB(), msg.sender, address(pool), amountIn);

        // swap
        IMaverickV2Pool.SwapParams memory swapParams = IMaverickV2Pool.SwapParams({
            amount: amountIn,
            tokenAIn: tokenAIn,
            exactOutput: false,
            tickLimit: tokenAIn ? type(int32).max : type(int32).min
        });
        (, amountOut) = _swap(pool, recipient, swapParams, bytes(""));

        // check slippage
        if (amountOut < amountOutMinimum) revert RouterTooLittleReceived(amountOutMinimum, amountOut);
    }

    /// @inheritdoc IPushOperations
    function exactInputMultiHop(
        address recipient,
        bytes memory path,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) public payable returns (uint256 amountOut) {
        (IMaverickV2Pool pool, bool tokenAIn) = path.decodeFirstPool();

        // pay first pool
        pay(tokenAIn ? pool.tokenA() : pool.tokenB(), msg.sender, address(pool), amountIn);

        amountOut = amountIn;
        while (true) {
            // if we have more pools, pay next pool, if not, pay recipient
            bool stillMultiPoolSwap = path.hasMultiplePools();
            address nextRecipient = stillMultiPoolSwap ? path.decodeNextPoolAddress() : recipient;

            // do swap and send proceeds to nextRecipient
            IMaverickV2Pool.SwapParams memory swapParams = IMaverickV2Pool.SwapParams({
                amount: amountOut,
                tokenAIn: tokenAIn,
                exactOutput: false,
                tickLimit: tokenAIn ? type(int32).max : type(int32).min
            });
            (, amountOut) = _swap(pool, nextRecipient, swapParams, bytes(""));

            // if there is more path, loop, if not, break
            if (stillMultiPoolSwap) {
                path = path.skipToken();
                (pool, tokenAIn) = path.decodeFirstPool();
            } else {
                break;
            }
        }
        if (amountOut < amountOutMinimum) revert RouterTooLittleReceived(amountOutMinimum, amountOut);
    }
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