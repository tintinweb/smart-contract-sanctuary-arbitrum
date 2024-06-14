// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;
pragma abicoder v1;

import {WAD, RAY, PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v2/contracts/libraries/Constants.sol";
import {ILinearInterestRateModelV3} from "../interfaces/ILinearInterestRateModelV3.sol";

// EXCEPTIONS
import {IncorrectParameterException, BorrowingMoreThanU2ForbiddenException} from "../interfaces/IExceptions.sol";

/// @title Linear interest rate model V3
/// @notice Gearbox V3 uses a two-point linear interest rate model in its pools.
///         Unlike previous single-point models, it has a new intermediate slope between the obtuse and steep regions
///         which serves to decrease interest rate jumps due to large withdrawals.
///         The model can also be configured to prevent borrowing after in the steep region (over `U_2` utilization)
///         in order to create a reserve for exits and make rates more stable.
contract LinearInterestRateModelV3 is ILinearInterestRateModelV3 {
    /// @notice Contract version
    uint256 public constant override version = 3_00;

    /// @notice Whether to prevent borrowing over `U_2` utilization
    bool public immutable override isBorrowingMoreU2Forbidden;

    /// @notice The first slope change point (obtuse -> intermediate region)
    uint256 public immutable U_1_WAD;

    /// @notice The second slope change point (intermediate -> steep region)
    uint256 public immutable U_2_WAD;

    /// @notice Base interest rate in RAY format
    uint256 public immutable R_base_RAY;

    /// @notice Slope of the obtuse region
    uint256 public immutable R_slope1_RAY;

    /// @notice Slope of the intermediate region
    uint256 public immutable R_slope2_RAY;

    /// @notice Slope of the steep region
    uint256 public immutable R_slope3_RAY;

    /// @notice Constructor
    /// @param U_1 `U_1` in basis points
    /// @param U_2 `U_2` in basis points
    /// @param R_base `R_base` in basis points
    /// @param R_slope1 `R_slope1` in basis points
    /// @param R_slope2 `R_slope2` in basis points
    /// @param R_slope3 `R_slope3` in basis points
    /// @param _isBorrowingMoreU2Forbidden Whether to prevent borrowing over `U_2` utilization
    constructor(
        uint16 U_1,
        uint16 U_2,
        uint16 R_base,
        uint16 R_slope1,
        uint16 R_slope2,
        uint16 R_slope3,
        bool _isBorrowingMoreU2Forbidden
    ) {
        if (
            (U_1 >= PERCENTAGE_FACTOR) || (U_2 >= PERCENTAGE_FACTOR) || (U_1 > U_2) || (R_base > PERCENTAGE_FACTOR)
                || (R_slope1 > PERCENTAGE_FACTOR) || (R_slope2 > PERCENTAGE_FACTOR) || (R_slope1 > R_slope2)
                || (R_slope2 > R_slope3)
        ) {
            revert IncorrectParameterException(); // U:[LIM-2]
        }

        /// Critical utilization points are stored in WAD format

        U_1_WAD = U_1 * (WAD / PERCENTAGE_FACTOR); // U:[LIM-1]
        U_2_WAD = U_2 * (WAD / PERCENTAGE_FACTOR); // U:[LIM-1]

        /// Slopes are stored in RAY format
        R_base_RAY = R_base * (RAY / PERCENTAGE_FACTOR); // U:[LIM-1]
        R_slope1_RAY = R_slope1 * (RAY / PERCENTAGE_FACTOR); // U:[LIM-1]
        R_slope2_RAY = R_slope2 * (RAY / PERCENTAGE_FACTOR); // U:[LIM-1]
        R_slope3_RAY = R_slope3 * (RAY / PERCENTAGE_FACTOR); // U:[LIM-1]

        isBorrowingMoreU2Forbidden = _isBorrowingMoreU2Forbidden; // U:[LIM-1]
    }

    /// @dev Same as the next one with `checkOptimalBorrowing` set to `false`, added for compatibility with older pools
    function calcBorrowRate(uint256 expectedLiquidity, uint256 availableLiquidity) external view returns (uint256) {
        return calcBorrowRate(expectedLiquidity, availableLiquidity, false);
    }

    /// @notice Returns the borrow rate calculated based on expected and available liquidity
    /// @param expectedLiquidity Expected liquidity in the pool
    /// @param availableLiquidity Available liquidity in the pool
    /// @param checkOptimalBorrowing Whether to check if borrowing over `U_2` utilization should be prevented
    function calcBorrowRate(uint256 expectedLiquidity, uint256 availableLiquidity, bool checkOptimalBorrowing)
        public
        view
        override
        returns (uint256)
    {
        if (expectedLiquidity <= availableLiquidity) {
            return R_base_RAY; // U:[LIM-3]
        }

        //      expectedLiquidity - availableLiquidity
        // U = ----------------------------------------
        //                expectedLiquidity

        uint256 U_WAD = (WAD * (expectedLiquidity - availableLiquidity)) / expectedLiquidity; // U:[LIM-3]

        // If U < U_1:
        //                                    U
        // borrowRate = R_base + R_slope1 * -----
        //                                   U_1

        if (U_WAD < U_1_WAD) {
            return R_base_RAY + ((R_slope1_RAY * U_WAD) / U_1_WAD); // U:[LIM-3]
        }

        // If U >= U_1 & U < U_2:
        //                                               U  - U_1
        // borrowRate = R_base + R_slope1 + R_slope2 * -----------
        //                                              U_2 - U_1

        if (U_WAD < U_2_WAD) {
            return R_base_RAY + R_slope1_RAY + (R_slope2_RAY * (U_WAD - U_1_WAD)) / (U_2_WAD - U_1_WAD); // U:[LIM-3]
        }

        // If U > U_2 in `isBorrowingMoreU2Forbidden` and the utilization check is requested,
        // the function will revert to prevent raising utilization over the limit
        if (checkOptimalBorrowing && isBorrowingMoreU2Forbidden) {
            revert BorrowingMoreThanU2ForbiddenException(); // U:[LIM-3]
        }

        // If U >= U_2:
        //                                                         U - U_2
        // borrowRate = R_base + R_slope1 + R_slope2 + R_slope3 * ----------
        //                                                         1 - U_2

        return R_base_RAY + R_slope1_RAY + R_slope2_RAY + R_slope3_RAY * (U_WAD - U_2_WAD) / (WAD - U_2_WAD); // U:[LIM-3]
    }

    /// @notice Returns the model's parameters in basis points
    function getModelParameters()
        external
        view
        override
        returns (uint16 U_1, uint16 U_2, uint16 R_base, uint16 R_slope1, uint16 R_slope2, uint16 R_slope3)
    {
        U_1 = uint16(U_1_WAD / (WAD / PERCENTAGE_FACTOR)); // U:[LIM-1]
        U_2 = uint16(U_2_WAD / (WAD / PERCENTAGE_FACTOR)); // U:[LIM-1]
        R_base = uint16(R_base_RAY / (RAY / PERCENTAGE_FACTOR)); // U:[LIM-1]
        R_slope1 = uint16(R_slope1_RAY / (RAY / PERCENTAGE_FACTOR)); // U:[LIM-1]
        R_slope2 = uint16(R_slope2_RAY / (RAY / PERCENTAGE_FACTOR)); // U:[LIM-1]
        R_slope3 = uint16(R_slope3_RAY / (RAY / PERCENTAGE_FACTOR)); // U:[LIM-1]
    }

    /// @notice Returns the amount available to borrow
    ///         - If borrowing over `U_2` is prohibited, returns the amount that can be borrowed before `U_2` is reached
    ///         - Otherwise, simply returns the available liquidity
    function availableToBorrow(uint256 expectedLiquidity, uint256 availableLiquidity)
        external
        view
        override
        returns (uint256)
    {
        if (isBorrowingMoreU2Forbidden && (expectedLiquidity >= availableLiquidity) && (expectedLiquidity != 0)) {
            uint256 U_WAD = (WAD * (expectedLiquidity - availableLiquidity)) / expectedLiquidity; // U:[LIM-3]

            return (U_WAD < U_2_WAD) ? ((U_2_WAD - U_WAD) * expectedLiquidity) / WAD : 0; // U:[LIM-3]
        } else {
            return availableLiquidity; // U:[LIM-3]
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

// Denominations

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals

// 25% of type(uint256).max
uint256 constant ALLOWANCE_THRESHOLD = type(uint96).max >> 3;

// FEE = 50%
uint16 constant DEFAULT_FEE_INTEREST = 50_00; // 50%

// LIQUIDATION_FEE 1.5%
uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50; // 1.5%

// LIQUIDATION PREMIUM 4%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00; // 4%

// LIQUIDATION_FEE_EXPIRED 2%
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00; // 2%

// LIQUIDATION PREMIUM EXPIRED 2%
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00; // 2%

// DEFAULT PROPORTION OF MAX BORROWED PER BLOCK TO MAX BORROWED PER ACCOUNT
uint16 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

// Seconds in a year
uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant SECONDS_PER_ONE_AND_HALF_YEAR = (SECONDS_PER_YEAR * 3) / 2;

// OPERATIONS

// Leverage decimals - 100 is equal to 2x leverage (100% * collateral amount + 100% * borrowed amount)
uint8 constant LEVERAGE_DECIMALS = 100;

// Maximum withdraw fee for pool in PERCENTAGE_FACTOR format
uint8 constant MAX_WITHDRAW_FEE = 100;

uint256 constant EXACT_INPUT = 1;
uint256 constant EXACT_OUTPUT = 2;

address constant UNIVERSAL_CONTRACT = 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC;

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {IVersion} from "@gearbox-protocol/core-v2/contracts/interfaces/IVersion.sol";

/// @title Linear interest rate model V3 interface
interface ILinearInterestRateModelV3 is IVersion {
    function calcBorrowRate(uint256 expectedLiquidity, uint256 availableLiquidity, bool checkOptimalBorrowing)
        external
        view
        returns (uint256);

    function availableToBorrow(uint256 expectedLiquidity, uint256 availableLiquidity) external view returns (uint256);

    function isBorrowingMoreU2Forbidden() external view returns (bool);

    function getModelParameters()
        external
        view
        returns (uint16 U_1, uint16 U_2, uint16 R_base, uint16 R_slope1, uint16 R_slope2, uint16 R_slope3);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

// ------- //
// GENERAL //
// ------- //

/// @notice Thrown on attempting to set an important address to zero address
error ZeroAddressException();

/// @notice Thrown when attempting to pass a zero amount to a funding-related operation
error AmountCantBeZeroException();

/// @notice Thrown on incorrect input parameter
error IncorrectParameterException();

/// @notice Thrown when balance is insufficient to perform an operation
error InsufficientBalanceException();

/// @notice Thrown if parameter is out of range
error ValueOutOfRangeException();

/// @notice Thrown when trying to send ETH to a contract that is not allowed to receive ETH directly
error ReceiveIsNotAllowedException();

/// @notice Thrown on attempting to set an EOA as an important contract in the system
error AddressIsNotContractException(address);

/// @notice Thrown on attempting to receive a token that is not a collateral token or was forbidden
error TokenNotAllowedException();

/// @notice Thrown on attempting to add a token that is already in a collateral list
error TokenAlreadyAddedException();

/// @notice Thrown when attempting to use quota-related logic for a token that is not quoted in quota keeper
error TokenIsNotQuotedException();

/// @notice Thrown on attempting to interact with an address that is not a valid target contract
error TargetContractNotAllowedException();

/// @notice Thrown if function is not implemented
error NotImplementedException();

// ------------------ //
// CONTRACTS REGISTER //
// ------------------ //

/// @notice Thrown when an address is expected to be a registered credit manager, but is not
error RegisteredCreditManagerOnlyException();

/// @notice Thrown when an address is expected to be a registered pool, but is not
error RegisteredPoolOnlyException();

// ---------------- //
// ADDRESS PROVIDER //
// ---------------- //

/// @notice Reverts if address key isn't found in address provider
error AddressNotFoundException();

// ----------------- //
// POOL, PQK, GAUGES //
// ----------------- //

/// @notice Thrown by pool-adjacent contracts when a credit manager being connected has a wrong pool address
error IncompatibleCreditManagerException();

/// @notice Thrown when attempting to set an incompatible successor staking contract
error IncompatibleSuccessorException();

/// @notice Thrown when attempting to vote in a non-approved contract
error VotingContractNotAllowedException();

/// @notice Thrown when attempting to unvote more votes than there are
error InsufficientVotesException();

/// @notice Thrown when attempting to borrow more than the second point on a two-point curve
error BorrowingMoreThanU2ForbiddenException();

/// @notice Thrown when a credit manager attempts to borrow more than its limit in the current block, or in general
error CreditManagerCantBorrowException();

/// @notice Thrown when attempting to connect a quota keeper to an incompatible pool
error IncompatiblePoolQuotaKeeperException();

/// @notice Thrown when the quota is outside of min/max bounds
error QuotaIsOutOfBoundsException();

// -------------- //
// CREDIT MANAGER //
// -------------- //

/// @notice Thrown on failing a full collateral check after multicall
error NotEnoughCollateralException();

/// @notice Thrown if an attempt to approve a collateral token to adapter's target contract fails
error AllowanceFailedException();

/// @notice Thrown on attempting to perform an action for a credit account that does not exist
error CreditAccountDoesNotExistException();

/// @notice Thrown on configurator attempting to add more than 255 collateral tokens
error TooManyTokensException();

/// @notice Thrown if more than the maximum number of tokens were enabled on a credit account
error TooManyEnabledTokensException();

/// @notice Thrown when attempting to execute a protocol interaction without active credit account set
error ActiveCreditAccountNotSetException();

/// @notice Thrown when trying to update credit account's debt more than once in the same block
error DebtUpdatedTwiceInOneBlockException();

/// @notice Thrown when trying to repay all debt while having active quotas
error DebtToZeroWithActiveQuotasException();

/// @notice Thrown when a zero-debt account attempts to update quota
error UpdateQuotaOnZeroDebtAccountException();

/// @notice Thrown when attempting to close an account with non-zero debt
error CloseAccountWithNonZeroDebtException();

/// @notice Thrown when value of funds remaining on the account after liquidation is insufficient
error InsufficientRemainingFundsException();

/// @notice Thrown when Credit Facade tries to write over a non-zero active Credit Account
error ActiveCreditAccountOverridenException();

// ------------------- //
// CREDIT CONFIGURATOR //
// ------------------- //

/// @notice Thrown on attempting to use a non-ERC20 contract or an EOA as a token
error IncorrectTokenContractException();

/// @notice Thrown if the newly set LT if zero or greater than the underlying's LT
error IncorrectLiquidationThresholdException();

/// @notice Thrown if borrowing limits are incorrect: minLimit > maxLimit or maxLimit > blockLimit
error IncorrectLimitsException();

/// @notice Thrown if the new expiration date is less than the current expiration date or current timestamp
error IncorrectExpirationDateException();

/// @notice Thrown if a contract returns a wrong credit manager or reverts when trying to retrieve it
error IncompatibleContractException();

/// @notice Thrown if attempting to forbid an adapter that is not registered in the credit manager
error AdapterIsNotRegisteredException();

// ------------- //
// CREDIT FACADE //
// ------------- //

/// @notice Thrown when attempting to perform an action that is forbidden in whitelisted mode
error ForbiddenInWhitelistedModeException();

/// @notice Thrown if credit facade is not expirable, and attempted aciton requires expirability
error NotAllowedWhenNotExpirableException();

/// @notice Thrown if a selector that doesn't match any allowed function is passed to the credit facade in a multicall
error UnknownMethodException();

/// @notice Thrown when trying to close an account with enabled tokens
error CloseAccountWithEnabledTokensException();

/// @notice Thrown if a liquidator tries to liquidate an account with a health factor above 1
error CreditAccountNotLiquidatableException();

/// @notice Thrown if too much new debt was taken within a single block
error BorrowedBlockLimitException();

/// @notice Thrown if the new debt principal for a credit account falls outside of borrowing limits
error BorrowAmountOutOfLimitsException();

/// @notice Thrown if a user attempts to open an account via an expired credit facade
error NotAllowedAfterExpirationException();

/// @notice Thrown if expected balances are attempted to be set twice without performing a slippage check
error ExpectedBalancesAlreadySetException();

/// @notice Thrown if attempting to perform a slippage check when excepted balances are not set
error ExpectedBalancesNotSetException();

/// @notice Thrown if balance of at least one token is less than expected during a slippage check
error BalanceLessThanExpectedException();

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException();

/// @notice Thrown when new forbidden tokens are enabled during the multicall
error ForbiddenTokenEnabledException();

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException();

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException();

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException();

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException();

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException();

// ------ //
// ACCESS //
// ------ //

/// @notice Thrown on attempting to call an access restricted function not as credit account owner
error CallerNotCreditAccountOwnerException();

/// @notice Thrown on attempting to call an access restricted function not as configurator
error CallerNotConfiguratorException();

/// @notice Thrown on attempting to call an access-restructed function not as account factory
error CallerNotAccountFactoryException();

/// @notice Thrown on attempting to call an access restricted function not as credit manager
error CallerNotCreditManagerException();

/// @notice Thrown on attempting to call an access restricted function not as credit facade
error CallerNotCreditFacadeException();

/// @notice Thrown on attempting to call an access restricted function not as controller or configurator
error CallerNotControllerException();

/// @notice Thrown on attempting to pause a contract without pausable admin rights
error CallerNotPausableAdminException();

/// @notice Thrown on attempting to unpause a contract without unpausable admin rights
error CallerNotUnpausableAdminException();

/// @notice Thrown on attempting to call an access restricted function not as gauge
error CallerNotGaugeException();

/// @notice Thrown on attempting to call an access restricted function not as quota keeper
error CallerNotPoolQuotaKeeperException();

/// @notice Thrown on attempting to call an access restricted function not as voter
error CallerNotVoterException();

/// @notice Thrown on attempting to call an access restricted function not as allowed adapter
error CallerNotAdapterException();

/// @notice Thrown on attempting to call an access restricted function not as migrator
error CallerNotMigratorException();

/// @notice Thrown when an address that is not the designated executor attempts to execute a transaction
error CallerNotExecutorException();

/// @notice Thrown on attempting to call an access restricted function not as veto admin
error CallerNotVetoAdminException();

// ------------------- //
// CONTROLLER TIMELOCK //
// ------------------- //

/// @notice Thrown when the new parameter values do not satisfy required conditions
error ParameterChecksFailedException();

/// @notice Thrown when attempting to execute a non-queued transaction
error TxNotQueuedException();

/// @notice Thrown when attempting to execute a transaction that is either immature or stale
error TxExecutedOutsideTimeWindowException();

/// @notice Thrown when execution of a transaction fails
error TxExecutionRevertedException();

/// @notice Thrown when the value of a parameter on execution is different from the value on queue
error ParameterChangedAfterQueuedTxException();

// -------- //
// BOT LIST //
// -------- //

/// @notice Thrown when attempting to set non-zero permissions for a forbidden or special bot
error InvalidBotException();

// --------------- //
// ACCOUNT FACTORY //
// --------------- //

/// @notice Thrown when trying to deploy second master credit account for a credit manager
error MasterCreditAccountAlreadyDeployedException();

/// @notice Thrown when trying to rescue funds from a credit account that is currently in use
error CreditAccountIsInUseException();

// ------------ //
// PRICE ORACLE //
// ------------ //

/// @notice Thrown on attempting to set a token price feed to an address that is not a correct price feed
error IncorrectPriceFeedException();

/// @notice Thrown on attempting to interact with a price feed for a token not added to the price oracle
error PriceFeedDoesNotExistException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2022
pragma solidity ^0.8.10;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}