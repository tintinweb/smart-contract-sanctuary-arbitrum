// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {BaseContract} from "../../libraries/BaseContract.sol";
import {PriceDifferenceCheckerLogicBase} from "./PriceDifferenceCheckerLogicBase.sol";

import {IDittoOracleV3} from "../../interfaces/IDittoOracleV3.sol";
import {IPriceDifferenceCheckerLogicUniswap} from "../../interfaces/checkers/IPriceDifferenceCheckerLogicUniswap.sol";

/// @title PriceDifferenceCheckerLogicUniswap
contract PriceDifferenceCheckerLogicUniswap is
    IPriceDifferenceCheckerLogicUniswap,
    BaseContract,
    PriceDifferenceCheckerLogicBase
{
    // =========================
    // Constructor
    // =========================

    constructor(
        IDittoOracleV3 _dittoOracle,
        address _uniswapFactory
    ) PriceDifferenceCheckerLogicBase(_dittoOracle, _uniswapFactory) {}

    // =========================
    // Initializer
    // =========================

    /// @inheritdoc IPriceDifferenceCheckerLogicUniswap
    function priceDifferenceCheckerUniswapInitialize(
        IUniswapV3Pool uniswapPool,
        uint24 percentageDeviation_E3,
        bytes32 pointer
    ) external onlyVaultItself {
        _priceDifferenceCheckerInitialize(
            uniswapPool,
            percentageDeviation_E3,
            pointer
        );
    }

    // =========================
    // Main functions
    // =========================

    /// @inheritdoc IPriceDifferenceCheckerLogicUniswap
    function uniswapCheckPriceDifference(
        bytes32 pointer
    ) external onlyVaultItself returns (bool success) {
        return _checkPriceDifference(pointer);
    }

    /// @inheritdoc IPriceDifferenceCheckerLogicUniswap
    function uniswapCheckPriceDifferenceView(
        bytes32 pointer
    ) external view returns (bool success) {
        return _checkPriceDifferenceView(pointer);
    }

    // =========================
    // Setters
    // =========================

    /// @inheritdoc IPriceDifferenceCheckerLogicUniswap
    function uniswapChangeTokensAndFeePriceDiffChecker(
        IUniswapV3Pool uniswapPool,
        bytes32 pointer
    ) external onlyOwnerOrVaultItself {
        _changeTokensAndFeePriceDiffChecker(uniswapPool, pointer);
    }

    /// @inheritdoc IPriceDifferenceCheckerLogicUniswap
    function uniswapChangePercentageDeviationE3(
        uint24 percentageDeviation_E3,
        bytes32 pointer
    ) external onlyOwnerOrVaultItself {
        _changePercentageDeviationE3(percentageDeviation_E3, pointer);
    }

    // =========================
    // Getters
    // =========================

    /// @inheritdoc IPriceDifferenceCheckerLogicUniswap
    function uniswapGetLocalPriceDifferenceCheckerStorage(
        bytes32 pointer
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint24 percentageDeviation_E3,
            uint256 lastCheckPrice,
            bool initialized
        )
    {
        PriceDifferenceCheckerStorage storage pdcs = _getStorageUnsafe(pointer);

        return (
            pdcs.token0,
            pdcs.token1,
            pdcs.fee,
            pdcs.percentageDeviation_E3,
            pdcs.lastCheckPrice,
            pdcs.initialized
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlLib} from "./AccessControlLib.sol";
import {Constants} from "./Constants.sol";

/// @title BaseContract
/// @notice A base contract that provides common access control features.
/// @dev This contract integrates with AccessControlLib to provide role-based access
/// control and ownership checks. Contracts inheriting from this can use its modifiers
/// for common access restrictions.
contract BaseContract {
    // =========================
    // Error
    // =========================

    /// @notice Thrown when an account is not authorized to perform a specific action.
    error UnauthorizedAccount(address account);

    // =========================
    // Modifiers
    // =========================

    /// @dev Modifier that checks if an account has a specific `role`
    /// or is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if the conditions are not met.
    modifier onlyRoleOrOwner(bytes32 role) {
        _checkRole(role, msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwner() {
        _checkOnlyOwner(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyVaultItself() {
        _checkOnlyVaultItself(msg.sender);

        _;
    }

    /// @dev Modifier that checks if an account is the contract's owner
    /// or the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    modifier onlyOwnerOrVaultItself() {
        _checkOnlyOwnerOrVaultItself(msg.sender);

        _;
    }

    // =========================
    // Internal function
    // =========================

    /// @dev Checks if the given `account` possesses the specified `role` or is the owner.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    function _checkRole(bytes32 role, address account) internal view virtual {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (
            !((msg.sender == AccessControlLib.getOwner()) ||
                _hasRole(s, role, account))
        ) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyVaultItself(address account) internal view virtual {
        if (account != address(this)) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the contract's address itself.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwnerOrVaultItself(
        address account
    ) internal view virtual {
        if (account == address(this)) {
            return;
        }

        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Checks if the given `account` is the owner of the contract.
    /// @dev Reverts with `UnauthorizedAccount` error if neither conditions are met.
    /// @param account The account to check.
    function _checkOnlyOwner(address account) internal view virtual {
        if (account != AccessControlLib.getOwner()) {
            revert UnauthorizedAccount(account);
        }
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    /// @param s The storage reference for roles from AccessControlLib.
    /// @param role The role to check against the account.
    /// @param account The account to check.
    /// @return True if the account possesses the role, false otherwise.
    function _hasRole(
        AccessControlLib.RolesStorage storage s,
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return s.roles[role][account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IDittoOracleV3} from "../../interfaces/IDittoOracleV3.sol";
import {IPriceDifferenceCheckerLogicBase} from "../../interfaces/checkers/IPriceDifferenceCheckerLogicBase.sol";

/// @title PriceDifferenceCheckerLogicBase
abstract contract PriceDifferenceCheckerLogicBase is
    IPriceDifferenceCheckerLogicBase
{
    // =========================
    // Constructor
    // =========================

    IDittoOracleV3 private immutable dittoOracle;
    address private immutable dexFactory;

    uint128 private constant E3 = 1000;
    uint128 private constant _2E3 = 2000;

    constructor(IDittoOracleV3 _dittoOracle, address _dexFactory) {
        dittoOracle = _dittoOracle;
        dexFactory = _dexFactory;
    }

    // =========================
    // Storage
    // =========================

    /// @dev Fetches the checker storage without initialization check.
    /// @dev Uses inline assembly to point to the specific storage slot.
    /// Be cautious while using this.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return s The storage slot for PriceDifferenceCheckerStorage structure.
    function _getStorageUnsafe(
        bytes32 pointer
    ) internal pure returns (PriceDifferenceCheckerStorage storage s) {
        assembly ("memory-safe") {
            s.slot := pointer
        }
    }

    /// @dev Fetches the checker storage after checking initialization.
    /// @dev Reverts if the strategy is not initialized.
    /// @param pointer Pointer to the strategy's storage location.
    /// @return s The storage slot for strategyStorage structure.
    function _getStorage(
        bytes32 pointer
    ) internal view returns (PriceDifferenceCheckerStorage storage s) {
        s = _getStorageUnsafe(pointer);

        if (!s.initialized) {
            revert PriceDifferenceChecker_NotInitialized();
        }
    }

    // =========================
    // Initializer
    // =========================

    /// @notice Initializes the PriceDifferenceChecker contract by setting the token addresses and percentage of difference.
    /// @param dexPool The Uniswap V3 pool from which to check the price.
    /// @param percentageDeviation_E3 The percentage of difference allowed between the two token prices.
    /// @param pointer The bytes32 pointer value.
    function _priceDifferenceCheckerInitialize(
        IUniswapV3Pool dexPool,
        uint24 percentageDeviation_E3,
        bytes32 pointer
    ) internal {
        PriceDifferenceCheckerStorage storage s = _getStorageUnsafe(pointer);

        if (s.initialized) {
            revert PriceDifferenceChecker_AlreadyInitialized();
        }

        s.initialized = true;

        _changeTokensAndFee(dexPool, s);
        _setPercentageDeviation(percentageDeviation_E3, s);

        emit PriceDifferenceCheckerInitialized();
    }

    // =========================
    // Main functions
    // =========================

    /// @notice Checks the percentage difference between the current price and the last checked price.
    /// @dev Updates the last recorded price in the state.
    /// @param pointer The bytes32 pointer value.
    /// @return success True if the percentage difference is within an acceptable range.
    function _checkPriceDifference(
        bytes32 pointer
    ) internal returns (bool success) {
        PriceDifferenceCheckerStorage storage s = _getStorage(pointer);

        uint256 currentPrice;
        (success, currentPrice) = _checkPriceDifference(s);
        if (success) {
            s.lastCheckPrice = currentPrice;
        }
    }

    /// @notice Checks the percentage difference between the current price and the last checked price.
    /// @param pointer The bytes32 pointer value.
    /// @return success True if the percentage difference is within an acceptable range.
    function _checkPriceDifferenceView(
        bytes32 pointer
    ) public view returns (bool success) {
        PriceDifferenceCheckerStorage storage s = _getStorage(pointer);
        (success, ) = _checkPriceDifference(s);
    }

    /// @notice Sets the tokens for the pool.
    /// @param dexPool The Uniswap V3 pool from which to check the price.
    /// @param pointer The bytes32 pointer value.
    function _changeTokensAndFeePriceDiffChecker(
        IUniswapV3Pool dexPool,
        bytes32 pointer
    ) internal {
        PriceDifferenceCheckerStorage storage s = _getStorage(pointer);

        _changeTokensAndFee(dexPool, s);
    }

    /// @notice Sets the percentage of difference for the contract.
    /// @param percentageDeviation_E3 The percentage of difference to be set.
    /// @param pointer The bytes32 pointer value.
    function _changePercentageDeviationE3(
        uint24 percentageDeviation_E3,
        bytes32 pointer
    ) internal {
        PriceDifferenceCheckerStorage storage s = _getStorage(pointer);

        _setPercentageDeviation(percentageDeviation_E3, s);
    }

    function _getLocalPriceDifferenceCheckerStorage(
        bytes32 pointer
    )
        internal
        pure
        returns (
            PriceDifferenceCheckerStorage memory priceDifferenceCheckerStorage
        )
    {
        priceDifferenceCheckerStorage = _getStorageUnsafe(pointer);
    }

    // =========================
    // Private functions
    // =========================

    /// @dev Fetches the last price rate from uniswapV3 pool.
    /// @param token0 The token0 from the uniswapV3 pool.
    /// @param token1 The token1 from the uniswapV3 pool.
    /// @param fee The feeTier from the uniswapV3 pool.
    function _getLastCheckPrice(
        address token0,
        address token1,
        uint24 fee
    ) private view returns (uint256) {
        IERC20Metadata _token0 = IERC20Metadata(token0);

        uint256 amount;
        unchecked {
            amount = 10 ** _token0.decimals();
        }

        return dittoOracle.consult(token0, amount, token1, fee, dexFactory);
    }

    /// @dev Checks the percentage difference between the current price and the last checked price.
    /// @param s The storage slot for PriceDifferenceCheckerStorage structure.
    /// @return success True if the percentage difference is within an acceptable range.
    /// @return currentPrice The current price of the tokens.
    function _checkPriceDifference(
        PriceDifferenceCheckerStorage storage s
    ) private view returns (bool success, uint256 currentPrice) {
        currentPrice = _getLastCheckPrice(s.token0, s.token1, s.fee);

        uint24 percentageDeviation_E3 = s.percentageDeviation_E3;

        if (percentageDeviation_E3 > E3) {
            unchecked {
                success =
                    currentPrice >
                    (s.lastCheckPrice * (percentageDeviation_E3)) / E3;
            }
        } else {
            unchecked {
                success =
                    currentPrice <
                    (s.lastCheckPrice * (percentageDeviation_E3)) / E3;
            }
        }
    }

    /// @dev Sets the percentage deviation for checker.
    /// @param percentageDeviation_E3 The percentage deviation to be set.
    /// @param s The storage slot for PriceDifferenceCheckerStorage structure.
    function _setPercentageDeviation(
        uint24 percentageDeviation_E3,
        PriceDifferenceCheckerStorage storage s
    ) private {
        if (percentageDeviation_E3 > _2E3) {
            revert PriceDifferenceChecker_InvalidPercentageDeviation();
        }

        s.percentageDeviation_E3 = percentageDeviation_E3;

        emit PriceDifferenceCheckerSetNewDeviationThreshold(
            percentageDeviation_E3
        );
    }

    /// @dev Sets the tokens and feeTier from the pair to checker storage.
    /// @param dexPool The pool to fetch the tokens and fee from.
    /// @param s The storage slot for PriceCheckerStorage structure.
    function _changeTokensAndFee(
        IUniswapV3Pool dexPool,
        PriceDifferenceCheckerStorage storage s
    ) private {
        address token0 = dexPool.token0();
        address token1 = dexPool.token1();
        uint24 fee = dexPool.fee();

        s.token0 = token0;
        s.token1 = token1;
        s.fee = fee;
        s.lastCheckPrice = _getLastCheckPrice(token0, token1, fee);

        emit PriceDifferenceCheckerSetNewTokensAndFee(token0, token1, fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IDittoOracleV3 - DittoOracleV3 interface
interface IDittoOracleV3 {
    // =========================
    // Storage
    // =========================

    /// @notice Returns the period for which oracle gets time-weighted average price.
    function PERIOD() external returns (uint256);

    // =========================
    // Errors
    // =========================

    /// @notice This error is thrown when a sender tries to call `consult`
    /// for non-existing fee tier for provided tokens.
    error UniswapOracle_PoolNotFound();

    // =========================
    // Main function
    // =========================

    /// @notice Calculates time-weighted average price for a given UniswapV3-like pool.
    /// @param tokenIn The token that will be exchanged.
    /// @param amountIn The amount of tokens whose price is to be obtained in `tokenOut`.
    /// @param tokenOut The token in which the price will be received `tokenIn`.
    /// @param fee Fee tier in UniswapV3-like protocol.
    /// @param dexFactory Factory address of the UniswapV3-like protocol. (e.g.: Pancakeswap, Uniswap, etc.)
    /// @return amountOut The amount of tokens that the pool can approximately exhange for `amountIn`.
    /// @dev If pool with tokens and fee does not exist in the protocol, `UniswapOracle_PoolNotFound` error is thrown.
    function consult(
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint24 fee,
        address dexFactory
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IPriceDifferenceCheckerLogicBase} from "./IPriceDifferenceCheckerLogicBase.sol";

/// @title IPriceDifferenceCheckerLogicUniswap - PriceDifferenceCheckerLogicUniswap interface.
interface IPriceDifferenceCheckerLogicUniswap is
    IPriceDifferenceCheckerLogicBase
{
    // =========================
    // Initializer
    // =========================

    /// @notice Initializes the PriceDifferenceChecker contract by setting the token addresses and percentage of difference.
    /// @param uniswapPool The Uniswap V3 pool for the Uniswap exchange.
    /// @param percentageDeviation_E3 The percentage of difference allowed between the two token prices.
    /// @param pointer The bytes32 pointer value.
    function priceDifferenceCheckerUniswapInitialize(
        IUniswapV3Pool uniswapPool,
        uint24 percentageDeviation_E3,
        bytes32 pointer
    ) external;

    // =========================
    // Main functions
    // =========================

    /// @notice Checks the percentage difference between the current price and the last checked price.
    /// @dev Updates the last recorded price in the state.
    /// @param pointer The bytes32 pointer value.
    /// @return success True if the percentage difference is within an acceptable range.
    function uniswapCheckPriceDifference(
        bytes32 pointer
    ) external returns (bool success);

    /// @notice Checks the percentage difference between the current price and the last checked price.
    /// @param pointer The bytes32 pointer value.
    /// @return success True if the percentage difference is within an acceptable range.
    function uniswapCheckPriceDifferenceView(
        bytes32 pointer
    ) external view returns (bool success);

    // =========================
    // Setters
    // =========================

    /// @notice Sets the tokens for the pool.
    /// @param uniswapPool The Uniswap V3 pool for the Uniswap exchange.
    /// @param pointer The bytes32 pointer value.
    function uniswapChangeTokensAndFeePriceDiffChecker(
        IUniswapV3Pool uniswapPool,
        bytes32 pointer
    ) external;

    /// @notice Sets the percentage of difference for the contract.
    /// @param percentageDeviation_E3 The percentage of difference to be set.
    /// @param pointer The bytes32 pointer value.
    function uniswapChangePercentageDeviationE3(
        uint24 percentageDeviation_E3,
        bytes32 pointer
    ) external;

    // =========================
    // Getters
    // =========================

    /// @notice Retrieves the local price difference checker storage values.
    /// @param pointer The bytes32 pointer value.
    /// @return token0 The address of the first token.
    /// @return token1 The address of the second token.
    /// @return fee The fee for the pool.
    /// @return percentageDeviation_E3 The allowed percentage deviation.
    /// @return lastCheckPrice The last recorded price.
    /// @return initialized A boolean indicating if the checker has been initialized or not.
    function uniswapGetLocalPriceDifferenceCheckerStorage(
        bytes32 pointer
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint24 fee,
            uint24 percentageDeviation_E3,
            uint256 lastCheckPrice,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title AccessControlLib
/// @notice A library for managing access controls with roles and ownership.
/// @dev Provides the structures and functions needed to manage roles and determine ownership.
library AccessControlLib {
    // =========================
    // Errors
    // =========================

    /// @notice Thrown when attempting to initialize an already initialized vault.
    error AccessControlLib_AlreadyInitialized();

    // =========================
    // Storage
    // =========================

    /// @dev Storage position for the access control struct, to avoid collisions in storage.
    /// @dev Uses the "magic" constant to find a unique storage slot.
    bytes32 constant ROLES_STORAGE_POSITION = keccak256("vault.roles.storage");

    /// @notice Struct to store roles and ownership details.
    struct RolesStorage {
        // Role-based access mapping
        mapping(bytes32 role => mapping(address account => bool)) roles;
        // Address that created the entity
        address creator;
        // Identifier for the vault
        uint16 vaultId;
        // Flag to decide if cross chain logic is not allowed
        bool crossChainLogicInactive;
        // Owner address
        address owner;
        // Flag to decide if `owner` or `creator` is used
        bool useOwner;
    }

    // =========================
    // Main library logic
    // =========================

    /// @dev Retrieve the storage location for roles.
    /// @return s Reference to the roles storage struct in the storage.
    function rolesStorage() internal pure returns (RolesStorage storage s) {
        bytes32 position = ROLES_STORAGE_POSITION;
        assembly ("memory-safe") {
            s.slot := position
        }
    }

    /// @dev Fetch the owner of the vault.
    /// @dev Determines whether to use the `creator` or the `owner` based on the `useOwner` flag.
    /// @return Address of the owner.
    function getOwner() internal view returns (address) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        if (s.useOwner) {
            return s.owner;
        } else {
            return s.creator;
        }
    }

    /// @dev Returns the address of the creator of the vault and its ID.
    /// @return The creator's address and the vault ID.
    function getCreatorAndId() internal view returns (address, uint16) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();
        return (s.creator, s.vaultId);
    }

    /// @dev Initializes the `creator` and `vaultId` for a new vault.
    /// @dev Should only be used once. Reverts if already set.
    /// @param creator Address of the vault creator.
    /// @param vaultId Identifier for the vault.
    function initializeCreatorAndId(address creator, uint16 vaultId) internal {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        // check if vault never existed before
        if (s.vaultId != 0) {
            revert AccessControlLib_AlreadyInitialized();
        }

        s.creator = creator;
        s.vaultId = vaultId;
    }

    /// @dev Fetches cross chain logic flag.
    /// @return True if cross chain logic is active.
    function crossChainLogicIsActive() internal view returns (bool) {
        AccessControlLib.RolesStorage storage s = AccessControlLib
            .rolesStorage();

        return !s.crossChainLogicInactive;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Constants
/// @dev These constants can be imported and used by other contracts for consistency.
library Constants {
    /// @dev A keccak256 hash representing the executor role.
    bytes32 internal constant EXECUTOR_ROLE =
        keccak256("DITTO_WORKFLOW_EXECUTOR_ROLE");

    /// @dev A constant representing the native token in any network.
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
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
pragma solidity ^0.8.0;

/// @title IPriceDifferenceCheckerLogicBase - PriceDifferenceCheckerLogicBase interface.
interface IPriceDifferenceCheckerLogicBase {
    // =========================
    // Storage
    // =========================

    /// @notice Storage structure for managing price difference checker data.
    struct PriceDifferenceCheckerStorage {
        // Address of the first token.
        address token0;
        // Address of the second token.
        address token1;
        // Fee associated with the token pair.
        uint24 fee;
        // Allowed percentage deviation.
        uint24 percentageDeviation_E3;
        // Flag indicating if the checker has been initialized.
        bool initialized;
        // The last recorded check price.
        uint256 lastCheckPrice;
    }

    // =========================
    // Events
    // =========================

    /// @notice Emits when the Price Difference Checker is initialized.
    event PriceDifferenceCheckerInitialized();

    /// @notice Emits when a new deviation threshold is set.
    /// @param newPercentage The new percentage deviation threshold.
    event PriceDifferenceCheckerSetNewDeviationThreshold(uint24 newPercentage);

    /// @notice Emits when new tokens and fee are set.
    /// @param token0 Address of the first token.
    /// @param token1 Address of the second token.
    /// @param fee Associated fee with the token pair.
    event PriceDifferenceCheckerSetNewTokensAndFee(
        address token0,
        address token1,
        uint24 fee
    );

    // =========================
    // Errors
    // =========================

    /// @notice Thrown when trying to initialize an already initialized Price
    /// Difference Checker
    error PriceDifferenceChecker_AlreadyInitialized();

    /// @notice Thrown when trying to provide an invalid percentage deviation
    /// to constructor or setter
    error PriceDifferenceChecker_InvalidPercentageDeviation();

    /// @notice Thrown when trying to perform an action on a not initialized
    /// Price Difference Checker
    error PriceDifferenceChecker_NotInitialized();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}