// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {AddressIsNotContractException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import {IPriceOracleV3, PriceFeedParams} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IPriceFeed, IUpdatablePriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";
import {IPriceFeedCompressor} from "../interfaces/IPriceFeedCompressor.sol";
import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

import {IStateSerializerLegacy} from "../interfaces/IStateSerializerLegacy.sol";
import {IStateSerializer} from "../interfaces/IStateSerializer.sol";
import {NestedPriceFeeds} from "../libraries/NestedPriceFeeds.sol";
import {BoundedPriceFeedSerializer} from "../serializers/oracles/BoundedPriceFeedSerializer.sol";
import {BPTWeightedPriceFeedSerializer} from "../serializers/oracles/BPTWeightedPriceFeedSerializer.sol";
import {LPPriceFeedSerializer} from "../serializers/oracles/LPPriceFeedSerializer.sol";
import {PythPriceFeedSerializer} from "../serializers/oracles/PythPriceFeedSerializer.sol";
import {RedstonePriceFeedSerializer} from "../serializers/oracles/RedstonePriceFeedSerializer.sol";
import {PriceFeedAnswer, PriceFeedMapEntry, PriceFeedTreeNode} from "./Types.sol";

interface ImplementsPriceFeedType {
    /// @dev Annotates `priceFeedType` as `uint8` instead of `PriceFeedType` enum to support future types
    function priceFeedType() external view returns (uint8);
}

/// @dev Price oracle with version below `3_10` has some important interface differences:
///      - it does not implement `getTokens`
///      - it only allows to fetch staleness period of a currently active price feed
interface IPriceOracleV3Legacy {
    /// @dev Older signature for fetching main and reserve feeds, reverts if price feed is not set
    function priceFeedsRaw(address token, bool reserve) external view returns (address);
}

/// @title  Price feed compressor
/// @notice Allows to fetch all useful data from price oracle in a single call
/// @dev    The contract is not gas optimized and is thus not recommended for on-chain use
contract PriceFeedCompressor is IPriceFeedCompressor {
    using NestedPriceFeeds for IPriceFeed;

    /// @notice Contract version
    uint256 public constant override version = 3_10;

    /// @notice Map of state serializers for different price feed types
    /// @dev    Serializers only apply to feeds that don't implement `IStateSerializer` themselves
    mapping(uint8 => address) public serializers;

    /// @notice Constructor
    /// @dev    Sets serializers for existing price feed types.
    ///         It is recommended to implement `IStateSerializer` in new price feeds.
    constructor() {
        address lpSerializer = address(new LPPriceFeedSerializer());
        // these types can be serialized as generic LP price feeds
        _setSerializer(uint8(PriceFeedType.BALANCER_STABLE_LP_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.COMPOUND_V2_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.CURVE_2LP_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.CURVE_3LP_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.CURVE_4LP_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.CURVE_CRYPTO_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.CURVE_USD_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.ERC4626_VAULT_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.WRAPPED_AAVE_V2_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.WSTETH_ORACLE), lpSerializer);
        _setSerializer(uint8(PriceFeedType.YEARN_ORACLE), lpSerializer);

        // these types need special serialization
        _setSerializer(uint8(PriceFeedType.BALANCER_WEIGHTED_LP_ORACLE), address(new BPTWeightedPriceFeedSerializer()));
        _setSerializer(uint8(PriceFeedType.BOUNDED_ORACLE), address(new BoundedPriceFeedSerializer()));
        _setSerializer(uint8(PriceFeedType.PYTH_ORACLE), address(new PythPriceFeedSerializer()));
        _setSerializer(uint8(PriceFeedType.REDSTONE_ORACLE), address(new RedstonePriceFeedSerializer()));
    }

    /// @notice Returns all potentially useful price feeds data for a given price oracle in the form of two arrays:
    ///         - `priceFeedMap` is a set of entries in the map (token, reserve) => (priceFeed, stalenessPeirod).
    ///         These are all the price feeds one can actually query via the price oracle.
    ///         - `priceFeedTree` is a set of nodes in a tree-like structure that contains detailed info of both feeds
    ///         from `priceFeedMap` and their underlying feeds, in case former are nested, which can help to determine
    ///         what underlying feeds should be updated to query the nested one.
    function getPriceFeeds(address priceOracle)
        external
        view
        override
        returns (PriceFeedMapEntry[] memory priceFeedMap, PriceFeedTreeNode[] memory priceFeedTree)
    {
        address[] memory tokens = IPriceOracleV3(priceOracle).getTokens();
        return getPriceFeeds(priceOracle, tokens);
    }

    /// @dev Same as the above but takes the list of tokens as argument as legacy oracle doesn't implement `getTokens`
    function getPriceFeeds(address priceOracle, address[] memory tokens)
        public
        view
        override
        returns (PriceFeedMapEntry[] memory priceFeedMap, PriceFeedTreeNode[] memory priceFeedTree)
    {
        uint256 numTokens = tokens.length;

        priceFeedMap = new PriceFeedMapEntry[](2 * numTokens);
        uint256 priceFeedMapSize;
        uint256 priceFeedTreeSize;

        for (uint256 i; i < 2 * numTokens; ++i) {
            address token = tokens[i % numTokens];
            bool reserve = i >= numTokens;

            (address priceFeed, uint32 stalenessPeriod) = _getPriceFeed(priceOracle, token, reserve);
            if (priceFeed == address(0)) continue;

            priceFeedMap[priceFeedMapSize++] = PriceFeedMapEntry({
                token: token,
                reserve: reserve,
                priceFeed: priceFeed,
                stalenessPeriod: stalenessPeriod
            });
            priceFeedTreeSize += _getPriceFeedTreeSize(priceFeed);
        }
        assembly {
            mstore(priceFeedMap, priceFeedMapSize)
        }

        priceFeedTree = new PriceFeedTreeNode[](priceFeedTreeSize);
        uint256 offset;
        for (uint256 i; i < priceFeedMapSize; ++i) {
            offset = _loadPriceFeedTree(priceFeedMap[i].priceFeed, priceFeedTree, offset);
        }
        // trim array to its actual size in case there were duplicates
        assembly {
            mstore(priceFeedTree, offset)
        }
    }

    function loadPriceFeedTree(address[] memory priceFeeds)
        external
        view
        override
        returns (PriceFeedTreeNode[] memory priceFeedTree)
    {
        uint256 len = priceFeeds.length;
        uint256 priceFeedTreeSize;

        for (uint256 i; i < len; ++i) {
            priceFeedTreeSize += _getPriceFeedTreeSize(priceFeeds[i]);
        }

        priceFeedTree = new PriceFeedTreeNode[](priceFeedTreeSize);
        uint256 offset;
        for (uint256 i; i < len; ++i) {
            offset = _loadPriceFeedTree(priceFeeds[i], priceFeedTree, offset);
        }
        // trim array to its actual size in case there were duplicates
        assembly {
            mstore(priceFeedTree, offset)
        }
    }

    // --------- //
    // INTERNALS //
    // --------- //

    /// @dev Sets `serializer` for `priceFeedType`
    function _setSerializer(uint8 priceFeedType, address serializer) internal {
        if (serializers[priceFeedType] != serializer) {
            serializers[priceFeedType] = serializer;
            emit SetSerializer(priceFeedType, serializer);
        }
    }

    /// @dev Returns `token`'s price feed in the price oracle
    function _getPriceFeed(address priceOracle, address token, bool reserve) internal view returns (address, uint32) {
        if (IPriceOracleV3(priceOracle).version() < 3_10) {
            try IPriceOracleV3Legacy(priceOracle).priceFeedsRaw(token, reserve) returns (address priceFeed) {
                // legacy oracle does not allow to fetch staleness period of a non-active feed
                return (priceFeed, 0);
            } catch {
                return (address(0), 0);
            }
        }
        PriceFeedParams memory params = reserve
            ? IPriceOracleV3(priceOracle).reservePriceFeedParams(token)
            : IPriceOracleV3(priceOracle).priceFeedParams(token);
        return (params.priceFeed, params.stalenessPeriod);
    }

    /// @dev Computes the size of the `priceFeed`'s subtree (recursively)
    function _getPriceFeedTreeSize(address priceFeed) internal view returns (uint256 size) {
        size = 1;
        (address[] memory underlyingFeeds,) = IPriceFeed(priceFeed).getUnderlyingFeeds();
        for (uint256 i; i < underlyingFeeds.length; ++i) {
            size += _getPriceFeedTreeSize(underlyingFeeds[i]);
        }
    }

    /// @dev Loads `priceFeed`'s subtree (recursively)
    function _loadPriceFeedTree(address priceFeed, PriceFeedTreeNode[] memory priceFeedTree, uint256 offset)
        internal
        view
        returns (uint256)
    {
        // duplicates are possible since price feed can be in `priceFeedMap` for more than one (token, reserve) pair
        // or serve as an underlying in more than one nested feed, and the whole subtree can be skipped in this case
        for (uint256 i; i < offset; ++i) {
            if (priceFeedTree[i].priceFeed == priceFeed) return offset;
        }

        PriceFeedTreeNode memory node = _getPriceFeedTreeNode(priceFeed);
        priceFeedTree[offset++] = node;
        for (uint256 i; i < node.underlyingFeeds.length; ++i) {
            offset = _loadPriceFeedTree(node.underlyingFeeds[i], priceFeedTree, offset);
        }
        return offset;
    }

    /// @dev Returns price feed tree node, see `PriceFeedTreeNode` for detailed description of struct fields
    function _getPriceFeedTreeNode(address priceFeed) internal view returns (PriceFeedTreeNode memory data) {
        data.priceFeed = priceFeed;
        data.decimals = IPriceFeed(priceFeed).decimals();
        data.version = IPriceFeed(priceFeed).version();

        try ImplementsPriceFeedType(priceFeed).priceFeedType() returns (uint8 priceFeedType) {
            data.priceFeedType = priceFeedType;
        } catch {
            data.priceFeedType = uint8(PriceFeedType.CHAINLINK_ORACLE);
        }

        try IPriceFeed(priceFeed).skipPriceCheck() returns (bool skipCheck) {
            data.skipCheck = skipCheck;
        } catch {}

        try IUpdatablePriceFeed(priceFeed).updatable() returns (bool updatable) {
            data.updatable = updatable;
        } catch {}

        try IStateSerializer(priceFeed).serialize() returns (bytes memory specificParams) {
            data.specificParams = specificParams;
        } catch {
            address serializer = serializers[data.priceFeedType];
            if (serializer != address(0)) {
                data.specificParams = IStateSerializerLegacy(serializer).serialize(priceFeed);
            }
        }

        (data.underlyingFeeds, data.underlyingStalenessPeriods) = IPriceFeed(priceFeed).getUnderlyingFeeds();

        try IPriceFeed(priceFeed).latestRoundData() returns (uint80, int256 price, uint256, uint256 updatedAt, uint80) {
            data.answer = PriceFeedAnswer({price: price, updatedAt: updatedAt, success: true});
        } catch {}
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
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
error UnknownMethodException(bytes4 selector);

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
error BalanceLessThanExpectedException(address token);

/// @notice Thrown when trying to perform an action that is forbidden when credit account has enabled forbidden tokens
error ForbiddenTokensException(uint256 forbiddenTokensMask);

/// @notice Thrown when forbidden token quota is increased during the multicall
error ForbiddenTokenQuotaIncreasedException(address token);

/// @notice Thrown when enabled forbidden token balance is increased during the multicall
error ForbiddenTokenBalanceIncreasedException(address token);

/// @notice Thrown when the remaining token balance is increased during the liquidation
error RemainingTokenBalanceIncreasedException(address token);

/// @notice Thrown if `botMulticall` is called by an address that is not approved by account owner or is forbidden
error NotApprovedBotException(address bot);

/// @notice Thrown when attempting to perform a multicall action with no permission for it
error NoPermissionException(uint256 permission);

/// @notice Thrown when attempting to give a bot unexpected permissions
error UnexpectedPermissionsException(uint256 permissions);

/// @notice Thrown when a custom HF parameter lower than 10000 is passed into the full collateral check
error CustomHealthFactorTooLowException();

/// @notice Thrown when submitted collateral hint is not a valid token mask
error InvalidCollateralHintException(uint256 mask);

/// @notice Thrown when trying to seize underlying token during partial liquidation
error UnderlyingIsNotLiquidatableException();

/// @notice Thrown when amount of collateral seized during partial liquidation is less than required
error SeizedLessThanRequiredException(uint256 seizedAmount);

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

/// @notice Thrown when attempting to set non-zero permissions for a forbidden bot
error InvalidBotException();

/// @notice Thrown when attempting to set permissions for a bot that don't meet its requirements
error InsufficientBotPermissionsException();

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

/// @notice Thrown when trying to apply an on-demand price update to a non-updatable price feed
error PriceFeedIsNotUpdatableException();

/// @notice Thrown when price feed returns incorrect price for a token
error IncorrectPriceException();

/// @notice Thrown when token's price feed becomes stale
error StalePriceException();

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IVersion} from "./base/IVersion.sol";

/// @notice Price feed params
/// @param priceFeed Price feed address
/// @param stalenessPeriod Period (in seconds) after which price feed's answer should be considered stale
/// @param skipCheck Whether price feed implements its own safety and staleness checks
/// @param tokenDecimals Token decimals
struct PriceFeedParams {
    address priceFeed;
    uint32 stalenessPeriod;
    bool skipCheck;
    uint8 tokenDecimals;
}

/// @notice On-demand price update params
/// @param priceFeed Price feed to update, must be in the set of updatable feeds in the price oracle
/// @param data Update data
struct PriceUpdate {
    address priceFeed;
    bytes data;
}

interface IPriceOracleV3Events {
    /// @notice Emitted when new price feed is set for token
    event SetPriceFeed(address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck);

    /// @notice Emitted when new reserve price feed is set for token
    event SetReservePriceFeed(address indexed token, address indexed priceFeed, uint32 stalenessPeriod, bool skipCheck);

    /// @notice Emitted when new updatable price feed is added
    event AddUpdatablePriceFeed(address indexed priceFeed);
}

/// @title Price oracle V3 interface
interface IPriceOracleV3 is IVersion, IPriceOracleV3Events {
    function getTokens() external view returns (address[] memory);

    function priceFeeds(address token) external view returns (address priceFeed);

    function reservePriceFeeds(address token) external view returns (address);

    function priceFeedParams(address token) external view returns (PriceFeedParams memory);

    function reservePriceFeedParams(address token) external view returns (PriceFeedParams memory);

    // ---------- //
    // CONVERSION //
    // ---------- //

    function getPrice(address token) external view returns (uint256);

    function getSafePrice(address token) external view returns (uint256);

    function getReservePrice(address token) external view returns (uint256);

    function convertToUSD(uint256 amount, address token) external view returns (uint256);

    function convertFromUSD(uint256 amount, address token) external view returns (uint256);

    function convert(uint256 amount, address tokenFrom, address tokenTo) external view returns (uint256);

    function safeConvertToUSD(uint256 amount, address token) external view returns (uint256);

    // ------------- //
    // PRICE UPDATES //
    // ------------- //

    function getUpdatablePriceFeeds() external view returns (address[] memory);

    function updatePrices(PriceUpdate[] calldata updates) external;

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function setPriceFeed(address token, address priceFeed, uint32 stalenessPeriod) external;

    function setReservePriceFeed(address token, address priceFeed, uint32 stalenessPeriod) external;

    function addUpdatablePriceFeed(address priceFeed) external;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";
import {IVersion} from "./IVersion.sol";

/// @title Price feed interface
/// @notice Interface for Chainlink-like price feeds that can be plugged into Gearbox's price oracle
interface IPriceFeed is IVersion {
    /// @notice Price feed type
    function priceFeedType() external view returns (PriceFeedType);

    /// @notice Whether price feed implements its own staleness and sanity checks
    function skipPriceCheck() external view returns (bool);

    /// @notice Scale decimals of price feed answers
    function decimals() external view returns (uint8);

    /// @notice Price feed description
    function description() external view returns (string memory);

    /// @notice Price feed answer in standard Chainlink format, only `answer` and `updatedAt` fields are used
    function latestRoundData() external view returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80);
}

/// @title Updatable price feed interface
/// @notice Extended version of `IPriceFeed` for pull oracles that allow on-demand updates
interface IUpdatablePriceFeed is IPriceFeed {
    /// @notice Whether price feed is updatable
    function updatable() external view returns (bool);

    /// @notice Performs on-demand price update
    function updatePrice(bytes calldata data) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2023
pragma solidity ^0.8.10;

import {PriceFeedAnswer, PriceFeedMapEntry, PriceFeedTreeNode} from "../compressors/Types.sol";

import {IVersion} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IVersion.sol";

interface IPriceFeedCompressor is IVersion {
    /// @notice Emitted when new state serializer is set for a given price feed type
    event SetSerializer(uint8 indexed priceFeedType, address indexed serializer);

    function getPriceFeeds(address priceOracle)
        external
        view
        returns (PriceFeedMapEntry[] memory priceFeedMap, PriceFeedTreeNode[] memory priceFeedTree);

    function getPriceFeeds(address priceOracle, address[] memory tokens)
        external
        view
        returns (PriceFeedMapEntry[] memory priceFeedMap, PriceFeedTreeNode[] memory priceFeedTree);

    function loadPriceFeedTree(address[] memory priceFeeds)
        external
        view
        returns (PriceFeedTreeNode[] memory priceFeedTree);
}

// SPDX-License-Identifier: UNLICENSED
// Gearbox. Generalized leverage protocol that allows to take leverage and then use it across other DeFi protocols and platforms in a composable way.
// (c) Gearbox Foundation, 2023
pragma solidity ^0.8.17;

enum PriceFeedType {
    CHAINLINK_ORACLE,
    YEARN_ORACLE,
    CURVE_2LP_ORACLE,
    CURVE_3LP_ORACLE,
    CURVE_4LP_ORACLE,
    ZERO_ORACLE,
    WSTETH_ORACLE,
    BOUNDED_ORACLE,
    COMPOSITE_ORACLE,
    WRAPPED_AAVE_V2_ORACLE,
    COMPOUND_V2_ORACLE,
    BALANCER_STABLE_LP_ORACLE,
    BALANCER_WEIGHTED_LP_ORACLE,
    CURVE_CRYPTO_ORACLE,
    THE_SAME_AS,
    REDSTONE_ORACLE,
    ERC4626_VAULT_ORACLE,
    NETWORK_DEPENDENT,
    CURVE_USD_ORACLE,
    PYTH_ORACLE
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @title State serializer
/// @notice Generic interface of a contract that is able to serialize state of other contracts
interface IStateSerializerLegacy {
    function serialize(address) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @title State serializer trait
/// @notice Generic interface of a contract that is able to serialize its own state
interface IStateSerializer {
    function serialize() external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IPriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";

uint256 constant MAX_UNDERLYING_PRICE_FEEDS = 8;

interface NestedPriceFeedWithSingleUnderlying is IPriceFeed {
    function priceFeed() external view returns (address);
    function stalenessPeriod() external view returns (uint32);
}

interface NestedPriceFeedWithMultipleUnderlyings is IPriceFeed {
    function priceFeed0() external view returns (address);
    function priceFeed1() external view returns (address);
    function priceFeed2() external view returns (address);
    function priceFeed3() external view returns (address);
    function priceFeed4() external view returns (address);
    function priceFeed5() external view returns (address);
    function priceFeed6() external view returns (address);
    function priceFeed7() external view returns (address);

    function stalenessPeriod0() external view returns (uint32);
    function stalenessPeriod1() external view returns (uint32);
    function stalenessPeriod2() external view returns (uint32);
    function stalenessPeriod3() external view returns (uint32);
    function stalenessPeriod4() external view returns (uint32);
    function stalenessPeriod5() external view returns (uint32);
    function stalenessPeriod6() external view returns (uint32);
    function stalenessPeriod7() external view returns (uint32);
}

library NestedPriceFeeds {
    enum NestingType {
        NO_NESTING,
        SINGLE_UNDERLYING,
        MULTIPLE_UNDERLYING
    }

    function getUnderlyingFeeds(IPriceFeed priceFeed)
        internal
        view
        returns (address[] memory feeds, uint32[] memory stalenessPeriods)
    {
        NestingType nestingType = getNestingType(priceFeed);
        if (nestingType == NestingType.SINGLE_UNDERLYING) {
            (feeds, stalenessPeriods) = getSingleUnderlyingFeed(NestedPriceFeedWithSingleUnderlying(address(priceFeed)));
        } else if (nestingType == NestingType.MULTIPLE_UNDERLYING) {
            (feeds, stalenessPeriods) =
                getMultipleUnderlyingFeeds(NestedPriceFeedWithMultipleUnderlyings(address(priceFeed)));
        }
    }

    function getNestingType(IPriceFeed priceFeed) internal view returns (NestingType) {
        try NestedPriceFeedWithSingleUnderlying(address(priceFeed)).priceFeed() returns (address) {
            return NestingType.SINGLE_UNDERLYING;
        } catch {}

        try NestedPriceFeedWithMultipleUnderlyings(address(priceFeed)).priceFeed0() returns (address) {
            return NestingType.MULTIPLE_UNDERLYING;
        } catch {}

        return NestingType.NO_NESTING;
    }

    function getSingleUnderlyingFeed(NestedPriceFeedWithSingleUnderlying priceFeed)
        internal
        view
        returns (address[] memory feeds, uint32[] memory stalenessPeriods)
    {
        feeds = new address[](1);
        stalenessPeriods = new uint32[](1);
        (feeds[0], stalenessPeriods[0]) = (priceFeed.priceFeed(), priceFeed.stalenessPeriod());
    }

    function getMultipleUnderlyingFeeds(NestedPriceFeedWithMultipleUnderlyings priceFeed)
        internal
        view
        returns (address[] memory feeds, uint32[] memory stalenessPeriods)
    {
        feeds = new address[](MAX_UNDERLYING_PRICE_FEEDS);
        stalenessPeriods = new uint32[](MAX_UNDERLYING_PRICE_FEEDS);
        for (uint256 i; i < MAX_UNDERLYING_PRICE_FEEDS; ++i) {
            feeds[i] = _getPriceFeedByIndex(priceFeed, i);
            if (feeds[i] == address(0)) {
                assembly {
                    mstore(feeds, i)
                    mstore(stalenessPeriods, i)
                }
                break;
            }
            stalenessPeriods[i] = _getStalenessPeriodByIndex(priceFeed, i);
        }
    }

    function _getPriceFeedByIndex(NestedPriceFeedWithMultipleUnderlyings priceFeed, uint256 index)
        private
        view
        returns (address)
    {
        bytes4 selector;
        if (index == 0) {
            selector = priceFeed.priceFeed0.selector;
        } else if (index == 1) {
            selector = priceFeed.priceFeed1.selector;
        } else if (index == 2) {
            selector = priceFeed.priceFeed2.selector;
        } else if (index == 3) {
            selector = priceFeed.priceFeed3.selector;
        } else if (index == 4) {
            selector = priceFeed.priceFeed4.selector;
        } else if (index == 5) {
            selector = priceFeed.priceFeed5.selector;
        } else if (index == 6) {
            selector = priceFeed.priceFeed6.selector;
        } else if (index == 7) {
            selector = priceFeed.priceFeed7.selector;
        }
        (bool success, bytes memory result) = address(priceFeed).staticcall(abi.encodePacked(selector));
        if (!success || result.length == 0) return address(0);
        return abi.decode(result, (address));
    }

    function _getStalenessPeriodByIndex(NestedPriceFeedWithMultipleUnderlyings priceFeed, uint256 index)
        private
        view
        returns (uint32)
    {
        bytes4 selector;
        if (index == 0) {
            selector = priceFeed.stalenessPeriod0.selector;
        } else if (index == 1) {
            selector = priceFeed.stalenessPeriod1.selector;
        } else if (index == 2) {
            selector = priceFeed.stalenessPeriod2.selector;
        } else if (index == 3) {
            selector = priceFeed.stalenessPeriod3.selector;
        } else if (index == 4) {
            selector = priceFeed.stalenessPeriod4.selector;
        } else if (index == 5) {
            selector = priceFeed.stalenessPeriod5.selector;
        } else if (index == 6) {
            selector = priceFeed.stalenessPeriod6.selector;
        } else if (index == 7) {
            selector = priceFeed.stalenessPeriod7.selector;
        }
        (bool success, bytes memory result) = address(priceFeed).staticcall(abi.encodePacked(selector));
        if (!success || result.length == 0) return 0;
        return abi.decode(result, (uint32));
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {BoundedPriceFeed} from "@gearbox-protocol/oracles-v3/contracts/oracles/BoundedPriceFeed.sol";
import {IStateSerializerLegacy} from "../../interfaces/IStateSerializerLegacy.sol";

contract BoundedPriceFeedSerializer is IStateSerializerLegacy {
    function serialize(address priceFeed) external view override returns (bytes memory) {
        BoundedPriceFeed pf = BoundedPriceFeed(priceFeed);

        return abi.encode(pf.upperBound());
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {BPTWeightedPriceFeed} from "@gearbox-protocol/oracles-v3/contracts/oracles/balancer/BPTWeightedPriceFeed.sol";
import {LPPriceFeedSerializer} from "./LPPriceFeedSerializer.sol";

contract BPTWeightedPriceFeedSerializer is LPPriceFeedSerializer {
    function serialize(address priceFeed) public view override returns (bytes memory) {
        BPTWeightedPriceFeed pf = BPTWeightedPriceFeed(priceFeed);

        uint256[8] memory weights = [
            pf.weight0(),
            pf.weight1(),
            pf.weight2(),
            pf.weight3(),
            pf.weight4(),
            pf.weight5(),
            pf.weight6(),
            pf.weight7()
        ];

        return abi.encode(super.serialize(priceFeed), pf.vault(), pf.poolId(), weights);
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ILPPriceFeed} from "@gearbox-protocol/oracles-v3/contracts/interfaces/ILPPriceFeed.sol";
import {IStateSerializerLegacy} from "../../interfaces/IStateSerializerLegacy.sol";

contract LPPriceFeedSerializer is IStateSerializerLegacy {
    struct PriceData {
        uint256 exchangeRate;
        int256 aggregatePrice;
        uint256 scale;
        bool exchageRateSuccess;
        bool aggregatePriceSuccess;
    }

    function serialize(address priceFeed) public view virtual override returns (bytes memory) {
        ILPPriceFeed pf = ILPPriceFeed(priceFeed);

        return abi.encode(
            pf.lpToken(),
            pf.lpContract(),
            pf.lowerBound(),
            pf.upperBound(),
            pf.updateBoundsAllowed(),
            pf.lastBoundsUpdate(),
            _getPriceData(pf)
        );
    }

    function _getPriceData(ILPPriceFeed priceFeed) internal view returns (PriceData memory data) {
        try priceFeed.getLPExchangeRate() returns (uint256 rate) {
            data.exchangeRate = rate;
            data.exchageRateSuccess = true;
        } catch {}

        try priceFeed.getAggregatePrice() returns (int256 price) {
            data.aggregatePrice = price;
            data.aggregatePriceSuccess = true;
        } catch {}

        // safe to assume that `getScale` is non-reverting
        data.scale = priceFeed.getScale();
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {PythPriceFeed} from "@gearbox-protocol/oracles-v3/contracts/oracles/updatable/PythPriceFeed.sol";
import {IStateSerializerLegacy} from "../../interfaces/IStateSerializerLegacy.sol";

contract PythPriceFeedSerializer is IStateSerializerLegacy {
    function serialize(address priceFeed) external view override returns (bytes memory) {
        PythPriceFeed pf = PythPriceFeed(payable(priceFeed));

        return abi.encode(pf.token(), pf.priceFeedId(), pf.pyth());
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {RedstonePriceFeed} from "@gearbox-protocol/oracles-v3/contracts/oracles/updatable/RedstonePriceFeed.sol";
import {IStateSerializerLegacy} from "../../interfaces/IStateSerializerLegacy.sol";

contract RedstonePriceFeedSerializer is IStateSerializerLegacy {
    function serialize(address priceFeed) external view override returns (bytes memory) {
        RedstonePriceFeed pf = RedstonePriceFeed(priceFeed);

        address[10] memory signers = [
            pf.signerAddress0(),
            pf.signerAddress1(),
            pf.signerAddress2(),
            pf.signerAddress3(),
            pf.signerAddress4(),
            pf.signerAddress5(),
            pf.signerAddress6(),
            pf.signerAddress7(),
            pf.signerAddress8(),
            pf.signerAddress9()
        ];

        return abi.encode(
            pf.token(),
            pf.dataFeedId(),
            signers,
            pf.getUniqueSignersThreshold(),
            pf.lastPrice(),
            pf.lastPayloadTimestamp()
        );
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @notice Credit account data
/// @param  creditAccount Credit account address
/// @param  creditManager Credit manager account is opened in
/// @param  creditFacade Facade connected to account's credit manager
/// @param  underlying Credit manager's underlying token
/// @param  owner Credit account's owner
/// @param  enabledTokensMask Bitmask of tokens enabled on credit account as collateral
/// @param  debt Credit account's debt principal in underlying
/// @param  accruedInterest Base and quota interest accrued on the credit account
/// @param  accruedFees Fees accrued on the credit account
/// @param  totalDebtUSD Account's total debt in USD
/// @param  totalValueUSD Account's total value in USD
/// @param  twvUSD Account's threshold-weighted value in USD
/// @param  totalValue Account's total value in underlying
/// @param  healthFactor Account's health factor, i.e. ratio of `twvUSD` to `totalDebtUSD`, in bps
/// @param  success Whether collateral calculation was successful
/// @param  tokens Info on credit account's enabled tokens and tokens with non-zero balance, see `TokenInfo`
/// @dev    Fields from `totalDebtUSD` through `healthFactor` are not filled if `success` is `false`
/// @dev    `debt`, `accruedInterest` and `accruedFees` don't account for transfer fees
struct CreditAccountData {
    address creditAccount;
    address creditManager;
    address creditFacade;
    address underlying;
    address owner;
    uint256 enabledTokensMask;
    uint256 debt;
    uint256 accruedInterest;
    uint256 accruedFees;
    uint256 totalDebtUSD;
    uint256 totalValueUSD;
    uint256 twvUSD;
    uint256 totalValue;
    uint16 healthFactor;
    bool success;
    TokenInfo[] tokens;
}

/// @notice Credit account filters
/// @param  owner If set, match credit accounts owned by given address
/// @param  includeZeroDebt If set, also match accounts with zero debt
/// @param  minHealthFactor If set, only return accounts with health factor above this value
/// @param  maxHealthFactor If set, only return accounts with health factor below this value
/// @param  reverting If set, only match accounts with reverting collateral calculation
struct CreditAccountFilter {
    address owner;
    bool includeZeroDebt;
    uint16 minHealthFactor;
    uint16 maxHealthFactor;
    bool reverting;
}

/// @notice Credit manager filters
/// @param  curator If set, match credit managers managed by given curator
/// @param  pool If set, match credit managers connected to a given pool
/// @param  underlying If set, match credit managers with given underlying
struct CreditManagerFilter {
    address curator;
    address pool;
    address underlying;
}

/// @notice Price feed answer packed in a struct
struct PriceFeedAnswer {
    int256 price;
    uint256 updatedAt;
    bool success;
}

/// @notice Represents an entry in the price feed map of a price oracle
/// @dev    `stalenessPeriod` is always 0 if price oracle's version is below `3_10`
struct PriceFeedMapEntry {
    address token;
    bool reserve;
    address priceFeed;
    uint32 stalenessPeriod;
}

/// @notice Represents a node in the price feed "tree"
/// @param  priceFeed Price feed address
/// @param  decimals Price feed's decimals (might not be equal to 8 for lower-level)
/// @param  priceFeedType Price feed type (same as `PriceFeedType` but annotated as `uint8` to support future types),
///         defaults to `PriceFeedType.CHAINLINK_ORACLE`
/// @param  version Price feed version
/// @param  skipCheck Whether price feed implements its own staleness and sanity check, defaults to `false`
/// @param  updatable Whether it is an on-demand updatable (aka pull) price feed, defaults to `false`
/// @param  specificParams ABI-encoded params specific to this price feed type, filled if price feed implements
///         `IStateSerializer` or there is a state serializer set for this type
/// @param  underlyingFeeds Array of underlying feeds, filled when `priceFeed` is nested
/// @param  underlyingStalenessPeriods Staleness periods of underlying feeds, filled when `priceFeed` is nested
/// @param  answer Price feed answer packed in a struct
struct PriceFeedTreeNode {
    address priceFeed;
    uint8 decimals;
    uint8 priceFeedType;
    uint256 version;
    bool skipCheck;
    bool updatable;
    bytes specificParams;
    address[] underlyingFeeds;
    uint32[] underlyingStalenessPeriods;
    PriceFeedAnswer answer;
}

/// @notice Info on credit account's holdings of a token
/// @param  token Token address
/// @param  mask Token mask in the credit manager
/// @param  balance Account's balance of token
/// @param  quota Account's quota of token
/// @param  success Whether balance call was successful
struct TokenInfo {
    address token;
    uint256 mask;
    uint256 balance;
    uint256 quota;
    bool success;
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

/// @title Version interface
/// @notice Defines contract version
interface IVersion {
    /// @notice Contract version
    function version() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import {IPriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";
import {SanityCheckTrait} from "@gearbox-protocol/core-v3/contracts/traits/SanityCheckTrait.sol";
import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";
import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

interface ChainlinkReadableAggregator {
    function aggregator() external view returns (address);
    function phaseAggregators(uint16 idx) external view returns (AggregatorV2V3Interface);
    function phaseId() external view returns (uint16);
}

/// @title Bounded price feed
/// @notice Can be used to provide upper-bounded answers for assets that are
///         expected to have the price in a certain range, e.g. stablecoins
contract BoundedPriceFeed is IPriceFeed, ChainlinkReadableAggregator, SanityCheckTrait, PriceFeedValidationTrait {
    PriceFeedType public constant override priceFeedType = PriceFeedType.BOUNDED_ORACLE;
    uint256 public constant override version = 3_00;
    uint8 public constant override decimals = 8; // U:[BPF-2]
    bool public constant override skipPriceCheck = true; // U:[BPF-2]

    /// @notice Underlying price feed
    address public immutable priceFeed;
    uint32 public immutable stalenessPeriod;
    bool public immutable skipCheck;

    /// @notice Upper bound for underlying price feed answers
    int256 public immutable upperBound;

    /// @notice Constructor
    /// @param _priceFeed Underlying price feed
    /// @param _stalenessPeriod Underlying price feed staleness period, must be non-zero unless it performs own checks
    /// @param _upperBound Upper bound for underlying price feed answers
    constructor(address _priceFeed, uint32 _stalenessPeriod, int256 _upperBound)
        nonZeroAddress(_priceFeed) // U:[BPF-1]
    {
        priceFeed = _priceFeed; // U:[BPF-1]
        stalenessPeriod = _stalenessPeriod; // U:[BPF-1]
        skipCheck = _validatePriceFeed(priceFeed, stalenessPeriod); // U:[BPF-1]
        upperBound = _upperBound; // U:[BPF-1]
    }

    /// @notice Price feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked(IPriceFeed(priceFeed).description(), " bounded price feed")); // U:[BPF-2]
    }

    /// @notice Returns the upper-bounded USD price of the token
    function latestRoundData() external view override returns (uint80, int256 answer, uint256, uint256, uint80) {
        answer = _getValidatedPrice(priceFeed, stalenessPeriod, skipCheck); // U:[BPF-3]
        return (0, _upperBoundValue(answer), 0, 0, 0); // U:[BPF-3]
    }

    /// @dev Upper-bounds given value
    function _upperBoundValue(int256 value) internal view returns (int256) {
        return (value > upperBound) ? upperBound : value;
    }

    // --------- //
    // ANALYTICS //
    // --------- //

    function aggregator() external view override returns (address) {
        return ChainlinkReadableAggregator(priceFeed).aggregator();
    }

    function phaseAggregators(uint16 idx) external view override returns (AggregatorV2V3Interface) {
        return ChainlinkReadableAggregator(priceFeed).phaseAggregators(idx);
    }

    function phaseId() external view override returns (uint16) {
        return ChainlinkReadableAggregator(priceFeed).phaseId();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {WAD} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";
import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

import {IBalancerVault} from "../../interfaces/balancer/IBalancerVault.sol";
import {IBalancerWeightedPool} from "../../interfaces/balancer/IBalancerWeightedPool.sol";
import {FixedPoint} from "../../libraries/FixedPoint.sol";
import {LPPriceFeed} from "../LPPriceFeed.sol";
import {PriceFeedParams} from "../PriceFeedParams.sol";

uint256 constant WAD_OVER_USD_FEED_SCALE = 10 ** 10;

/// @title Balancer weighted pool token price feed
/// @notice Weighted Balancer pools LP tokens price feed.
///         BPTs are priced according to the formula `k * prod((p_i / w_i) ^ w_i) / S`, where `k` is pool's invariant,
///         `S` is pool's LP token total supply, `w_i` and `p_i` are `i`-th asset's weight and price respectively.
///         Pool's invariant, in turn, equals `prod(b_i ^ w_i)`, where `b_i` is pool's balance of `i`-th asset.
///         Bounding logic is applied to `n * k / S` which can be considered BPT's exchange rate that should grow slowly
///         over time as fees accrue.
/// @dev Severe gas optimizations have been made:
///      * Many variables saved as immutable which reduces the number of external calls and storage reads
///      * Variables are stored and processed in the order of ascending weights, which allows to reduce
///        the number of fixed point exponentiations in case some assets have identical weights
/// @dev This contract must not be used to price managed pools that allow to change their weights/tokens
contract BPTWeightedPriceFeed is LPPriceFeed {
    using FixedPoint for uint256;

    uint256 public constant override version = 3_00;
    PriceFeedType public constant override priceFeedType = PriceFeedType.BALANCER_WEIGHTED_LP_ORACLE;

    /// @notice Balancer vault address
    address public immutable vault;

    /// @notice Balancer pool ID
    bytes32 public immutable poolId;

    uint256 public immutable numAssets;

    address public immutable priceFeed0;
    address public immutable priceFeed1;
    address public immutable priceFeed2;
    address public immutable priceFeed3;
    address public immutable priceFeed4;
    address public immutable priceFeed5;
    address public immutable priceFeed6;
    address public immutable priceFeed7;

    uint32 public immutable stalenessPeriod0;
    uint32 public immutable stalenessPeriod1;
    uint32 public immutable stalenessPeriod2;
    uint32 public immutable stalenessPeriod3;
    uint32 public immutable stalenessPeriod4;
    uint32 public immutable stalenessPeriod5;
    uint32 public immutable stalenessPeriod6;
    uint32 public immutable stalenessPeriod7;

    bool public immutable skipCheck0;
    bool public immutable skipCheck1;
    bool public immutable skipCheck2;
    bool public immutable skipCheck3;
    bool public immutable skipCheck4;
    bool public immutable skipCheck5;
    bool public immutable skipCheck6;
    bool public immutable skipCheck7;

    uint256 public immutable weight0;
    uint256 public immutable weight1;
    uint256 public immutable weight2;
    uint256 public immutable weight3;
    uint256 public immutable weight4;
    uint256 public immutable weight5;
    uint256 public immutable weight6;
    uint256 public immutable weight7;

    uint256 immutable index0;
    uint256 immutable index1;
    uint256 immutable index2;
    uint256 immutable index3;
    uint256 immutable index4;
    uint256 immutable index5;
    uint256 immutable index6;
    uint256 immutable index7;

    uint256 immutable scale0;
    uint256 immutable scale1;
    uint256 immutable scale2;
    uint256 immutable scale3;
    uint256 immutable scale4;
    uint256 immutable scale5;
    uint256 immutable scale6;
    uint256 immutable scale7;

    constructor(
        address _acl,
        address _priceOracle,
        uint256 lowerBound,
        address _vault,
        address _pool,
        PriceFeedParams[] memory priceFeeds
    )
        LPPriceFeed(_acl, _priceOracle, _pool, _pool) // U:[BAL-W-1]
        nonZeroAddress(_vault) // U:[BAL-W-1]
        nonZeroAddress(priceFeeds[0].priceFeed) // U:[BAL-W-2]
        nonZeroAddress(priceFeeds[1].priceFeed) // U:[BAL-W-2]
    {
        uint256[] memory weights = IBalancerWeightedPool(_pool).getNormalizedWeights();
        uint256[] memory indices = _sort(weights);

        numAssets = weights.length; // U:[BAL-W-2]
        vault = _vault; // U:[BAL-W-1]
        poolId = IBalancerWeightedPool(_pool).getPoolId(); // U:[BAL-W-1]

        index0 = indices[0];
        index1 = indices[1];
        index2 = numAssets >= 3 ? indices[2] : 0;
        index3 = numAssets >= 4 ? indices[3] : 0;
        index4 = numAssets >= 5 ? indices[4] : 0;
        index5 = numAssets >= 6 ? indices[5] : 0;
        index6 = numAssets >= 7 ? indices[6] : 0;
        index7 = numAssets >= 8 ? indices[7] : 0;

        weight0 = weights[0];
        weight1 = weights[1];
        weight2 = numAssets >= 3 ? weights[2] : 0;
        weight3 = numAssets >= 4 ? weights[3] : 0;
        weight4 = numAssets >= 5 ? weights[4] : 0;
        weight5 = numAssets >= 6 ? weights[5] : 0;
        weight6 = numAssets >= 7 ? weights[6] : 0;
        weight7 = numAssets >= 8 ? weights[7] : 0;

        (address[] memory tokens,,) = IBalancerVault(_vault).getPoolTokens(poolId);
        scale0 = _tokenScale(tokens[index0]);
        scale1 = _tokenScale(tokens[index1]);
        scale2 = numAssets >= 3 ? _tokenScale(tokens[index2]) : 0;
        scale3 = numAssets >= 4 ? _tokenScale(tokens[index3]) : 0;
        scale4 = numAssets >= 5 ? _tokenScale(tokens[index4]) : 0;
        scale5 = numAssets >= 6 ? _tokenScale(tokens[index5]) : 0;
        scale6 = numAssets >= 7 ? _tokenScale(tokens[index6]) : 0;
        scale7 = numAssets >= 8 ? _tokenScale(tokens[index7]) : 0;

        priceFeed0 = priceFeeds[index0].priceFeed;
        priceFeed1 = priceFeeds[index1].priceFeed;
        priceFeed2 = numAssets >= 3 ? priceFeeds[index2].priceFeed : address(0);
        priceFeed3 = numAssets >= 4 ? priceFeeds[index3].priceFeed : address(0);
        priceFeed4 = numAssets >= 5 ? priceFeeds[index4].priceFeed : address(0);
        priceFeed5 = numAssets >= 6 ? priceFeeds[index5].priceFeed : address(0);
        priceFeed6 = numAssets >= 7 ? priceFeeds[index6].priceFeed : address(0);
        priceFeed7 = numAssets >= 8 ? priceFeeds[index7].priceFeed : address(0);

        stalenessPeriod0 = priceFeeds[index0].stalenessPeriod;
        stalenessPeriod1 = priceFeeds[index1].stalenessPeriod;
        stalenessPeriod2 = numAssets >= 3 ? priceFeeds[index2].stalenessPeriod : 0;
        stalenessPeriod3 = numAssets >= 4 ? priceFeeds[index3].stalenessPeriod : 0;
        stalenessPeriod4 = numAssets >= 5 ? priceFeeds[index4].stalenessPeriod : 0;
        stalenessPeriod5 = numAssets >= 6 ? priceFeeds[index5].stalenessPeriod : 0;
        stalenessPeriod6 = numAssets >= 7 ? priceFeeds[index6].stalenessPeriod : 0;
        stalenessPeriod7 = numAssets >= 8 ? priceFeeds[index7].stalenessPeriod : 0;

        skipCheck0 = _validatePriceFeed(priceFeed0, stalenessPeriod0);
        skipCheck1 = _validatePriceFeed(priceFeed1, stalenessPeriod1);
        skipCheck2 = numAssets >= 3 ? _validatePriceFeed(priceFeed2, stalenessPeriod2) : false;
        skipCheck3 = numAssets >= 4 ? _validatePriceFeed(priceFeed3, stalenessPeriod3) : false;
        skipCheck4 = numAssets >= 5 ? _validatePriceFeed(priceFeed4, stalenessPeriod4) : false;
        skipCheck5 = numAssets >= 6 ? _validatePriceFeed(priceFeed5, stalenessPeriod5) : false;
        skipCheck6 = numAssets >= 7 ? _validatePriceFeed(priceFeed6, stalenessPeriod6) : false;
        skipCheck7 = numAssets >= 8 ? _validatePriceFeed(priceFeed7, stalenessPeriod7) : false;

        _setLimiter(lowerBound); // U:[BAL-W-1]
    }

    // ------- //
    // PRICING //
    // ------- //

    function getAggregatePrice() public view override returns (int256 answer) {
        uint256[] memory weights = _getWeightsArray();

        uint256 weightedPrice = FixedPoint.ONE;
        uint256 currentBase = FixedPoint.ONE;
        for (uint256 i = 0; i < numAssets;) {
            (address priceFeed, uint32 stalenessPeriod, bool skipCheck) = _getPriceFeedParams(i);
            answer = _getValidatedPrice(priceFeed, stalenessPeriod, skipCheck);
            answer = answer * int256(WAD_OVER_USD_FEED_SCALE);

            currentBase = currentBase.mulDown(uint256(answer).divDown(weights[i]));
            if (i == numAssets - 1 || weights[i] != weights[i + 1]) {
                weightedPrice = weightedPrice.mulDown(currentBase.powDown(weights[i]));
                currentBase = FixedPoint.ONE;
            }

            unchecked {
                ++i;
            }
        }

        answer = int256(weightedPrice / (numAssets * WAD_OVER_USD_FEED_SCALE)); // U:[BAL-W-2]
    }

    function getLPExchangeRate() public view override returns (uint256) {
        return (numAssets * _getBPTInvariant()).divDown(_getBPTSupply()); // U:[BAL-W-1]
    }

    function getScale() public pure override returns (uint256) {
        return WAD; // U:[BAL-W-1]
    }

    /// @dev Returns BPT invariant
    function _getBPTInvariant() internal view returns (uint256 k) {
        uint256[] memory balances = _getBalancesArray();
        uint256[] memory weights = _getWeightsArray();

        uint256 len = balances.length;

        k = FixedPoint.ONE;
        uint256 currentBase = FixedPoint.ONE;
        for (uint256 i = 0; i < len;) {
            currentBase = currentBase.mulDown(balances[i]);
            if (i == len - 1 || weights[i] != weights[i + 1]) {
                k = k.mulDown(currentBase.powDown(weights[i]));
                currentBase = FixedPoint.ONE;
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Returns BPT total supply
    function _getBPTSupply() internal view returns (uint256 supply) {
        try IBalancerWeightedPool(lpToken).getActualSupply() returns (uint256 actualSupply) {
            supply = actualSupply;
        } catch {
            supply = IBalancerWeightedPool(lpToken).totalSupply();
        }
    }

    // ------- //
    // HELPERS //
    // ------- //

    /// @dev Returns i-th price feed params
    function _getPriceFeedParams(uint256 i)
        internal
        view
        returns (address priceFeed, uint32 stalenessPeriod, bool skipCheck)
    {
        if (i == 0) return (priceFeed0, stalenessPeriod0, skipCheck0);
        if (i == 1) return (priceFeed1, stalenessPeriod1, skipCheck1);
        if (i == 2) return (priceFeed2, stalenessPeriod2, skipCheck2);
        if (i == 3) return (priceFeed3, stalenessPeriod3, skipCheck3);
        if (i == 4) return (priceFeed4, stalenessPeriod4, skipCheck4);
        if (i == 5) return (priceFeed5, stalenessPeriod5, skipCheck5);
        if (i == 6) return (priceFeed6, stalenessPeriod6, skipCheck6);
        if (i == 7) return (priceFeed7, stalenessPeriod7, skipCheck7);
    }

    /// @dev Returns weights as an array
    function _getWeightsArray() internal view returns (uint256[] memory weights) {
        weights = new uint256[](numAssets);
        weights[0] = weight0;
        weights[1] = weight1;
        if (numAssets >= 3) weights[2] = weight2;
        if (numAssets >= 4) weights[3] = weight3;
        if (numAssets >= 5) weights[4] = weight4;
        if (numAssets >= 6) weights[5] = weight5;
        if (numAssets >= 7) weights[6] = weight6;
        if (numAssets >= 8) weights[7] = weight7;
    }

    /// @dev Returns assets balances sorted in the order of increasing weights and scaled to have the same precision
    function _getBalancesArray() internal view returns (uint256[] memory balances) {
        (, uint256[] memory rawBalances,) = IBalancerVault(vault).getPoolTokens(poolId);

        balances = new uint256[](numAssets);
        balances[0] = rawBalances[index0] * WAD / scale0;
        balances[1] = rawBalances[index1] * WAD / scale1;
        if (numAssets >= 3) balances[2] = rawBalances[index2] * WAD / scale2;
        if (numAssets >= 4) balances[3] = rawBalances[index3] * WAD / scale3;
        if (numAssets >= 5) balances[4] = rawBalances[index4] * WAD / scale4;
        if (numAssets >= 6) balances[5] = rawBalances[index5] * WAD / scale5;
        if (numAssets >= 7) balances[6] = rawBalances[index6] * WAD / scale6;
        if (numAssets >= 8) balances[7] = rawBalances[index7] * WAD / scale7;
    }

    /// @dev Returns `token`'s scale (10^decimals)
    function _tokenScale(address token) internal view returns (uint256) {
        return 10 ** IERC20Metadata(token).decimals();
    }

    // ------- //
    // SORTING //
    // ------- //

    /// @dev Sorts array in-place in ascending order, also returns the resulting permutation
    function _sort(uint256[] memory data) internal pure returns (uint256[] memory indices) {
        uint256 len = data.length;
        indices = new uint256[](len);
        unchecked {
            for (uint256 i; i < len; ++i) {
                indices[i] = i;
            }
        }
        _quickSort(data, indices, 0, len - 1);
    }

    /// @dev Quick sort sub-routine
    function _quickSort(uint256[] memory data, uint256[] memory indices, uint256 low, uint256 high) private pure {
        unchecked {
            if (low < high) {
                uint256 pVal = data[(low + high) / 2];

                uint256 i = low;
                uint256 j = high;
                for (;;) {
                    while (data[i] < pVal) i++;
                    while (data[j] > pVal) j--;
                    if (i >= j) break;
                    if (data[i] != data[j]) {
                        (data[i], data[j]) = (data[j], data[i]);
                        (indices[i], indices[j]) = (indices[j], indices[i]);
                    }
                    i++;
                    j--;
                }
                if (low < j) _quickSort(data, indices, low, j);
                j++;
                if (j < high) _quickSort(data, indices, j, high);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IPriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";

interface ILPPriceFeedEvents {
    /// @notice Emitted when new LP token exchange rate bounds are set
    event SetBounds(uint256 lowerBound, uint256 upperBound);

    /// @notice Emitted when permissionless bounds update is allowed or forbidden
    event SetUpdateBoundsAllowed(bool allowed);
}

interface ILPPriceFeedExceptions {
    /// @notice Thrown when trying to set exchange rate lower bound to zero
    error LowerBoundCantBeZeroException();

    /// @notice Thrown when exchange rate falls below lower bound during price calculation
    ///         or new boudns don't contain exchange rate during bounds update
    error ExchangeRateOutOfBoundsException();

    /// @notice Thrown when trying to call `updateBounds` while it's not allowed
    error UpdateBoundsNotAllowedException();

    /// @notice Thrown when trying to call `updateBounds` before cooldown since the last update has passed
    error UpdateBoundsBeforeCooldownException();

    /// @notice Thrown when price oracle's reserve price feed is the LP price feed itself
    error ReserveFeedMustNotBeSelfException();
}

/// @title LP price feed interface
interface ILPPriceFeed is IPriceFeed, ILPPriceFeedEvents, ILPPriceFeedExceptions {
    function priceOracle() external view returns (address);

    function lpToken() external view returns (address);
    function lpContract() external view returns (address);

    function lowerBound() external view returns (uint256);
    function upperBound() external view returns (uint256);
    function updateBoundsAllowed() external view returns (bool);
    function lastBoundsUpdate() external view returns (uint40);

    function getAggregatePrice() external view returns (int256 answer);
    function getLPExchangeRate() external view returns (uint256 exchangeRate);
    function getScale() external view returns (uint256 scale);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    function allowBoundsUpdate() external;
    function forbidBoundsUpdate() external;
    function setLimiter(uint256 newLowerBound) external;
    function updateBounds(bytes calldata updateData) external;
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";
import {IncorrectPriceException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

/// @dev Max period that the payload can be backward in time relative to the block
uint256 constant MAX_DATA_TIMESTAMP_DELAY_SECONDS = 10 minutes;

/// @dev Max period that the payload can be forward in time relative to the block
uint256 constant MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

int256 constant DECIMALS = 10 ** 8;

interface IPythExtended {
    function latestPriceInfoPublishTime(bytes32 priceFeedId) external view returns (uint64);
}

interface IPythPriceFeedExceptions {
    /// @notice Thrown when the timestamp sent with the payload for early stop does not match
    ///         the payload's internal timestamp
    error IncorrectExpectedPublishTimestamp();

    /// @notice Thrown when the decimals returned by Pyth are outside sane boundaries
    error IncorrectPriceDecimals();
}

/// @title Pyth price feed
contract PythPriceFeed is IUpdatablePriceFeed, IPythPriceFeedExceptions {
    using SafeCast for uint256;

    PriceFeedType public constant override priceFeedType = PriceFeedType.PYTH_ORACLE;
    uint256 public constant override version = 3_00;
    uint8 public constant override decimals = 8;
    bool public constant override skipPriceCheck = false;
    bool public constant override updatable = true;

    /// @notice Token for which the prices are provided
    address public immutable token;

    /// @notice Pyth's ID for the price feed
    bytes32 public immutable priceFeedId;

    /// @notice Address of the Pyth main contract instance
    address public immutable pyth;

    /// @dev Price feed description
    string public description;

    constructor(address _token, bytes32 _priceFeedId, address _pyth, string memory _descriptionTicker) {
        token = _token;
        priceFeedId = _priceFeedId;
        pyth = _pyth;
        description = string(abi.encodePacked(_descriptionTicker, " Pyth price feed"));
    }

    /// @notice Returns the USD price of the token with 8 decimals and the last update timestamp
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        PythStructs.Price memory priceData = IPyth(pyth).getPriceUnsafe(priceFeedId);

        int256 price = _getDecimalAdjustedPrice(priceData);

        return (0, price, 0, priceData.publishTime, 0);
    }

    /// @notice Passes a Pyth payload to the Pyth oracle to update the price
    /// @param data A data blob with with 2 parts:
    ///        - Publish time reported by Pyth API - must be equal to publish time after update
    ///        - Pyth payload from Hermes
    function updatePrice(bytes calldata data) external override {
        (uint256 expectedPublishTimestamp, bytes[] memory updateData) = abi.decode(data, (uint256, bytes[]));

        uint256 lastPublishTimestamp = uint256(IPythExtended(pyth).latestPriceInfoPublishTime(priceFeedId));

        // We want to minimize price update execution, in case, e.g., when several users submit
        // the same price update in a short span of time. So only updates with a larger payload timestamp than last recorded
        // are sent to Pyth. While Pyth technically performs an early stop by not writing a new price for outdated payloads,
        // it still performs payload validation before that, which is expensive
        if (expectedPublishTimestamp <= lastPublishTimestamp) return;
        _validateExpectedPublishTimestamp(expectedPublishTimestamp);

        uint256 fee = IPyth(pyth).getUpdateFee(updateData);
        IPyth(pyth).updatePriceFeeds{value: fee}(updateData);

        PythStructs.Price memory priceData = IPyth(pyth).getPriceUnsafe(priceFeedId);

        if (priceData.publishTime != expectedPublishTimestamp) revert IncorrectExpectedPublishTimestamp();
        if (priceData.price == 0) revert IncorrectPriceException();
    }

    /// @dev Returns price adjusted to 8 decimals (if Pyth returns different precision)
    function _getDecimalAdjustedPrice(PythStructs.Price memory priceData) internal pure returns (int256) {
        int256 price = int256(priceData.price);

        if (priceData.expo != -8) {
            if (priceData.expo > 0 || priceData.expo < -255) revert IncorrectPriceDecimals();
            int256 pythDecimals = int256(uint256(10) ** uint32(-priceData.expo));
            price = price * DECIMALS / pythDecimals;
        }

        return price;
    }

    /// @dev Validates that the expected payload timestamp is not too far from the current block's
    /// @param expectedPublishTimestamp Expected timestamp after the current price update
    function _validateExpectedPublishTimestamp(uint256 expectedPublishTimestamp) internal view {
        if ((block.timestamp < expectedPublishTimestamp)) {
            if ((expectedPublishTimestamp - block.timestamp) > MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
                revert IncorrectExpectedPublishTimestamp();
            }
        } else if ((block.timestamp - expectedPublishTimestamp) > MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
            revert IncorrectExpectedPublishTimestamp();
        }
    }

    /// @dev Receive is defined so that ETH can be precharged on the price feed to cover future Pyth feeds
    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {RedstoneConsumerNumericBase} from
    "@redstone-finance/evm-connector/contracts/core/RedstoneConsumerNumericBase.sol";

import {IncorrectPriceException} from "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";
import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";

/// @dev Max period that the payload can be backward in time relative to the block
uint256 constant MAX_DATA_TIMESTAMP_DELAY_SECONDS = 10 minutes;

/// @dev Max period that the payload can be forward in time relative to the block
uint256 constant MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

/// @dev Max number of authorized signers
uint256 constant MAX_SIGNERS = 10;

interface IRedstonePriceFeedExceptions {
    /// @notice Thrown when trying to construct a price feed with incorrect signers threshold
    error IncorrectSignersThresholdException();

    /// @notice Thrown when the provided set of signers is smaller than the threshold
    error NotEnoughSignersException();

    /// @notice Thrown when the provided set of signers contains duplicates
    error DuplicateSignersException();

    /// @notice Thrown when attempting to push an update with the payload that is older than the last
    ///         update payload, or too far from the current block timestamp
    error RedstonePayloadTimestampIncorrect();

    /// @notice Thrown when data package timestamp is not equal to expected payload timestamp
    error DataPackageTimestampIncorrect();
}

interface IRedstonePriceFeedEvents {
    /// @notice Emitted when a successful price update is pushed
    /// @param price New USD price of the token with 8 decimals
    event UpdatePrice(uint256 price);
}

/// @title Redstone price feed
contract RedstonePriceFeed is
    IUpdatablePriceFeed,
    IRedstonePriceFeedExceptions,
    IRedstonePriceFeedEvents,
    RedstoneConsumerNumericBase
{
    using SafeCast for uint256;

    PriceFeedType public constant override priceFeedType = PriceFeedType.REDSTONE_ORACLE;
    uint256 public constant override version = 3_00;
    uint8 public constant override decimals = 8;
    bool public constant override skipPriceCheck = false;
    bool public constant override updatable = true;

    /// @notice Token for which the prices are provided
    address public immutable token;

    /// @notice ID of the asset in Redstone's payload
    bytes32 public immutable dataFeedId;

    address public immutable signerAddress0;
    address public immutable signerAddress1;
    address public immutable signerAddress2;
    address public immutable signerAddress3;
    address public immutable signerAddress4;
    address public immutable signerAddress5;
    address public immutable signerAddress6;
    address public immutable signerAddress7;
    address public immutable signerAddress8;
    address public immutable signerAddress9;

    /// @dev Minimal number of unique signatures from authorized signers required to validate a payload
    uint8 internal immutable _signersThreshold;

    /// @notice The last stored price value
    uint128 public lastPrice;

    /// @notice The timestamp of the last update's payload
    uint40 public lastPayloadTimestamp;

    constructor(address _token, bytes32 _dataFeedId, address[MAX_SIGNERS] memory _signers, uint8 signersThreshold) {
        if (signersThreshold == 0 || signersThreshold > MAX_SIGNERS) revert IncorrectSignersThresholdException();
        unchecked {
            uint256 numSigners;
            for (uint256 i; i < MAX_SIGNERS; ++i) {
                if (_signers[i] == address(0)) continue;
                for (uint256 j = i + 1; j < MAX_SIGNERS; ++j) {
                    if (_signers[j] == _signers[i]) revert DuplicateSignersException();
                }
                ++numSigners;
            }
            if (numSigners < signersThreshold) revert NotEnoughSignersException();
        }

        token = _token;
        dataFeedId = _dataFeedId; // U:[RPF-1]

        signerAddress0 = _signers[0];
        signerAddress1 = _signers[1];
        signerAddress2 = _signers[2];
        signerAddress3 = _signers[3];
        signerAddress4 = _signers[4];
        signerAddress5 = _signers[5];
        signerAddress6 = _signers[6];
        signerAddress7 = _signers[7];
        signerAddress8 = _signers[8];
        signerAddress9 = _signers[9];

        _signersThreshold = signersThreshold; // U:[RPF-1]
    }

    /// @notice Price feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked(ERC20(token).symbol(), " / USD Redstone price feed")); // U:[RPF-1]
    }

    /// @notice Returns the USD price of the token with 8 decimals and the last update timestamp
    function latestRoundData() external view override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, int256(uint256(lastPrice)), 0, lastPayloadTimestamp, 0); // U:[RPF-2]
    }

    /// @notice Saves validated price retrieved from the passed Redstone payload
    /// @param data A data blob with with 2 parts:
    ///        - A timestamp expected to be in all Redstone data packages
    ///        - Redstone payload with price update
    function updatePrice(bytes calldata data) external override {
        (uint256 expectedPayloadTimestamp,) = abi.decode(data, (uint256, bytes));

        // We want to minimize price update execution, in case, e.g., when several users submit
        // the same price update in a short span of time. So only updates with a larger payload timestamp
        // are fully validated and applied
        if (expectedPayloadTimestamp <= lastPayloadTimestamp) return; // U:[RPF-4]

        // We validate and set the payload timestamp here. Data packages' timestamps being equal
        // to the expected timestamp is checked in `validateTimestamp()`, which is called
        // from inside `getOracleNumericValueFromTxMsg`
        _validateExpectedPayloadTimestamp(expectedPayloadTimestamp);
        lastPayloadTimestamp = uint40(expectedPayloadTimestamp); // U:[RPF-2,5]

        uint256 priceValue = getOracleNumericValueFromTxMsg(dataFeedId); // U:[RPF-7]

        if (priceValue == 0) revert IncorrectPriceException(); // U:[RPF-8]

        if (priceValue != lastPrice) {
            lastPrice = priceValue.toUint128(); // U:[RPF-2,5]
            emit UpdatePrice(priceValue); // U:[RPF-2,5]
        }
    }

    /// @notice Returns the number of unique signatures required to validate a payload
    function getUniqueSignersThreshold() public view virtual override returns (uint8) {
        return _signersThreshold;
    }

    /// @notice Returns the index of the provided signer or reverts if the address is not a signer
    function getAuthorisedSignerIndex(address signerAddress) public view virtual override returns (uint8) {
        if (signerAddress == address(0)) revert SignerNotAuthorised(signerAddress);

        if (signerAddress == signerAddress0) return 0;
        if (signerAddress == signerAddress1) return 1;
        if (signerAddress == signerAddress2) return 2;
        if (signerAddress == signerAddress3) return 3;
        if (signerAddress == signerAddress4) return 4;
        if (signerAddress == signerAddress5) return 5;
        if (signerAddress == signerAddress6) return 6;
        if (signerAddress == signerAddress7) return 7;
        if (signerAddress == signerAddress8) return 8;
        if (signerAddress == signerAddress9) return 9;

        revert SignerNotAuthorised(signerAddress); // U:[RPF-6]
    }

    /// @notice Validates that a timestamp in a data package is valid
    /// @dev Sanity checks on the timestamp are performed earlier in the update,
    ///      when the lastPayloadTimestamp is being set
    /// @param receivedTimestampMilliseconds Timestamp in the data package, in milliseconds
    function validateTimestamp(uint256 receivedTimestampMilliseconds) public view override {
        uint256 receivedTimestampSeconds = receivedTimestampMilliseconds / 1000;

        if (receivedTimestampSeconds != lastPayloadTimestamp) {
            revert DataPackageTimestampIncorrect(); // U:[RPF-3]
        }
    }

    /// @dev Validates that the expected payload timestamp is not older than the last payload's,
    ///      and not too far from the current block's
    /// @param expectedPayloadTimestamp Timestamp expected to be in all of the incoming payload's packages
    function _validateExpectedPayloadTimestamp(uint256 expectedPayloadTimestamp) internal view {
        if ((block.timestamp < expectedPayloadTimestamp)) {
            if ((expectedPayloadTimestamp - block.timestamp) > MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
                revert RedstonePayloadTimestampIncorrect(); // U:[RPF-9]
            }
        } else if ((block.timestamp - expectedPayloadTimestamp) > MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
            revert RedstonePayloadTimestampIncorrect(); // U:[RPF-9]
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ZeroAddressException} from "../interfaces/IExceptions.sol";

/// @title Sanity check trait
abstract contract SanityCheckTrait {
    /// @dev Ensures that passed address is non-zero
    modifier nonZeroAddress(address addr) {
        _revertIfZeroAddress(addr);
        _;
    }

    /// @dev Reverts if address is zero
    function _revertIfZeroAddress(address addr) private pure {
        if (addr == address(0)) revert ZeroAddressException();
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {
    AddressIsNotContractException,
    IncorrectParameterException,
    IncorrectPriceException,
    IncorrectPriceFeedException,
    PriceFeedDoesNotExistException,
    StalePriceException
} from "../interfaces/IExceptions.sol";
import {IPriceFeed, IUpdatablePriceFeed} from "../interfaces/base/IPriceFeed.sol";

/// @title Price feed validation trait
abstract contract PriceFeedValidationTrait {
    using Address for address;

    /// @dev Ensures that price is positive and not stale
    /// @custom:tests U:[PO-9]
    function _checkAnswer(int256 price, uint256 updatedAt, uint32 stalenessPeriod) internal view {
        if (price <= 0) revert IncorrectPriceException();
        if (block.timestamp >= updatedAt + stalenessPeriod) revert StalePriceException();
    }

    /// @dev Valites that `priceFeed` is a contract that adheres to Chainlink interface and passes sanity checks
    /// @dev Some price feeds return stale prices unless updated right before querying their answer, which causes
    ///      issues during deployment and configuration, so for such price feeds staleness check is skipped, and
    ///      special care must be taken to ensure all parameters are in tune.
    /// @custom:tests U:[PO-8]
    function _validatePriceFeed(address priceFeed, uint32 stalenessPeriod) internal view returns (bool skipCheck) {
        if (!priceFeed.isContract()) revert AddressIsNotContractException(priceFeed);

        try IPriceFeed(priceFeed).decimals() returns (uint8 _decimals) {
            if (_decimals != 8) revert IncorrectPriceFeedException();
        } catch {
            revert IncorrectPriceFeedException();
        }

        try IPriceFeed(priceFeed).skipPriceCheck() returns (bool _skipCheck) {
            skipCheck = _skipCheck;
        } catch {}

        try IPriceFeed(priceFeed).latestRoundData() returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80)
        {
            if (skipCheck) {
                if (stalenessPeriod != 0) revert IncorrectParameterException();
            } else {
                if (stalenessPeriod == 0) revert IncorrectParameterException();
                if (!_isUpdatable(priceFeed)) _checkAnswer(answer, updatedAt, stalenessPeriod);
            }
        } catch {
            revert IncorrectPriceFeedException();
        }
    }

    /// @dev Returns answer from a price feed with optional sanity and staleness checks
    /// @custom:tests U:[PO-9]
    function _getValidatedPrice(address priceFeed, uint32 stalenessPeriod, bool skipCheck)
        internal
        view
        returns (int256 answer)
    {
        uint256 updatedAt;
        (, answer,, updatedAt,) = IPriceFeed(priceFeed).latestRoundData();
        if (!skipCheck) _checkAnswer(answer, updatedAt, stalenessPeriod);
    }

    /// @dev Checks whether price feed is updatable
    function _isUpdatable(address priceFeed) internal view returns (bool updatable) {
        try IUpdatablePriceFeed(priceFeed).updatable() returns (bool value) {
            updatable = value;
        } catch {}
    }
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

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

uint256 constant WAD = 1e18;
uint256 constant RAY = 1e27;
uint16 constant PERCENTAGE_FACTOR = 1e4;

uint256 constant SECONDS_PER_YEAR = 365 days;
uint256 constant EPOCH_LENGTH = 7 days;
uint256 constant EPOCHS_TO_WITHDRAW = 4;

uint8 constant MAX_WITHDRAW_FEE = 100;

uint16 constant DEFAULT_FEE_LIQUIDATION = 1_50;
uint16 constant DEFAULT_LIQUIDATION_PREMIUM = 4_00;
uint16 constant DEFAULT_FEE_LIQUIDATION_EXPIRED = 1_00;
uint16 constant DEFAULT_LIQUIDATION_PREMIUM_EXPIRED = 2_00;
uint8 constant DEFAULT_LIMIT_PER_BLOCK_MULTIPLIER = 2;

uint8 constant DEFAULT_MAX_ENABLED_TOKENS = 4;

uint8 constant BOT_PERMISSIONS_SET_FLAG = 1;

uint256 constant UNDERLYING_TOKEN_MASK = 1;

address constant INACTIVE_CREDIT_ACCOUNT_ADDRESS = address(1);

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IBalancerVault {
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}

// SPDX-License-Identifier: MIT
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IBalancerWeightedPool {
    function getRate() external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function totalSupply() external view returns (uint256);

    function getActualSupply() external view returns (uint256);

    function getPoolId() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "./LogExpMath.sol";

/* solhint-disable private-vars-leading-underscore */

library FixedPoint {
    // solhint-disable no-inline-assembly

    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant TWO = 2 * ONE;
    uint256 internal constant FOUR = 4 * ONE;
    uint256 internal constant MAX_POW_RELATIVE_ERROR = 10000; // 10^(-14)

    // Minimum base for the power function when the exponent is 'free' (larger than ONE).
    uint256 internal constant MIN_POW_BASE_FREE_EXPONENT = 0.7e18;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 product = a * b;

        assembly {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        require(b != 0, "zero division");

        uint256 aInflated = a * ONE;

        assembly {
            result := mul(iszero(iszero(aInflated)), add(div(sub(aInflated, 1), b), 1))
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding down. The result is guaranteed to not be above
     * the true value (that is, the error function expected - actual is always positive).
     */
    function powDown(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulDown(x, x);
        } else if (y == FOUR) {
            uint256 square = mulDown(x, x);
            return mulDown(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            if (raw < maxError) {
                return 0;
            } else {
                return sub(raw, maxError);
            }
        }
    }

    /**
     * @dev Returns x^y, assuming both are fixed point numbers, rounding up. The result is guaranteed to not be below
     * the true value (that is, the error function expected - actual is always negative).
     */
    function powUp(uint256 x, uint256 y) internal pure returns (uint256) {
        // Optimize for when y equals 1.0, 2.0 or 4.0, as those are very simple to implement and occur often in 50/50
        // and 80/20 Weighted Pools
        if (y == ONE) {
            return x;
        } else if (y == TWO) {
            return mulUp(x, x);
        } else if (y == FOUR) {
            uint256 square = mulUp(x, x);
            return mulUp(square, square);
        } else {
            uint256 raw = LogExpMath.pow(x, y);
            uint256 maxError = add(mulUp(raw, MAX_POW_RELATIVE_ERROR), 1);

            return add(raw, maxError);
        }
    }

    /**
     * @dev Returns the complement of a value (1 - x), capped to 0 if x is larger than 1.
     *
     * Useful when computing the complement for values with some level of relative error, as it strips this error and
     * prevents intermediate negative values.
     */
    function complement(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mul(lt(x, ONE), sub(ONE, x))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v3/contracts/interfaces/base/IPriceFeed.sol";
import {PERCENTAGE_FACTOR} from "@gearbox-protocol/core-v3/contracts/libraries/Constants.sol";
import {ACLNonReentrantTrait} from "@gearbox-protocol/core-v3/contracts/traits/ACLNonReentrantTrait.sol";
import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";
import {ILPPriceFeed} from "../interfaces/ILPPriceFeed.sol";

/// @dev Window size in bps, used to compute upper bound given lower bound
uint256 constant WINDOW_SIZE = 200;

/// @dev Buffer size in bps, used to compute new lower bound given current exchange rate
uint256 constant BUFFER_SIZE = 100;

/// @dev Minimum interval between two permissionless bounds updates
uint256 constant UPDATE_BOUNDS_COOLDOWN = 1 days;

/// @title LP price feed
/// @notice Abstract contract for LP token price feeds.
///         It is assumed that the price of an LP token is the product of its exchange rate and some aggregate function
///         of underlying tokens prices. This contract simplifies creation of such price feeds and provides standard
///         validation of the LP token exchange rate that protects against price manipulation.
abstract contract LPPriceFeed is ILPPriceFeed, ACLNonReentrantTrait, PriceFeedValidationTrait {
    /// @notice Answer precision (always 8 decimals for USD price feeds)
    uint8 public constant override decimals = 8; // U:[LPPF-2]

    /// @notice Indicates that price oracle can skip checks for this price feed's answers
    bool public constant override skipPriceCheck = true; // U:[LPPF-2]

    /// @notice Price oracle contract
    address public immutable override priceOracle;

    /// @notice LP token for which the prices are computed
    address public immutable override lpToken;

    /// @notice LP contract (can be different from LP token)
    address public immutable override lpContract;

    /// @notice Lower bound for the LP token exchange rate
    uint256 public override lowerBound;

    /// @notice Whether permissionless bounds update is allowed
    bool public override updateBoundsAllowed;

    /// @notice Timestamp of the last bounds update
    uint40 public override lastBoundsUpdate;

    /// @notice Constructor
    /// @param _acl Address of the ACL contract
    /// @param _priceOracle Address of the price oracle
    /// @param _lpToken  LP token for which the prices are computed
    /// @param _lpContract LP contract (can be different from LP token)
    /// @dev Derived price feeds must call `_setLimiter` in their constructor after
    ///      initializing all state variables needed for exchange rate calculation
    constructor(address _acl, address _priceOracle, address _lpToken, address _lpContract)
        ACLNonReentrantTrait(_acl) // U:[LPPF-1]
        nonZeroAddress(_priceOracle) // U:[LPPF-1]
        nonZeroAddress(_lpToken) // U:[LPPF-1]
        nonZeroAddress(_lpContract) // U:[LPPF-1]
    {
        priceOracle = _priceOracle; // U:[LPPF-1]
        lpToken = _lpToken; // U:[LPPF-1]
        lpContract = _lpContract; // U:[LPPF-1]
    }

    /// @notice Price feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked(ERC20(lpToken).symbol(), " / USD price feed")); // U:[LPPF-2]
    }

    /// @notice Returns USD price of the LP token with 8 decimals
    function latestRoundData() external view override returns (uint80, int256 answer, uint256, uint256, uint80) {
        uint256 exchangeRate = getLPExchangeRate();
        uint256 lb = lowerBound;
        if (exchangeRate < lb) revert ExchangeRateOutOfBoundsException(); // U:[LPPF-3]

        uint256 ub = _calcUpperBound(lb);
        if (exchangeRate > ub) exchangeRate = ub; // U:[LPPF-3]

        answer = int256((exchangeRate * uint256(getAggregatePrice())) / getScale()); // U:[LPPF-3]
        return (0, answer, 0, 0, 0);
    }

    /// @notice Upper bound for the LP token exchange rate
    function upperBound() external view returns (uint256) {
        return _calcUpperBound(lowerBound); // U:[LPPF-4]
    }

    /// @notice Returns aggregate price of underlying tokens with 8 decimals
    /// @dev Must be implemented by derived price feeds
    function getAggregatePrice() public view virtual override returns (int256 answer);

    /// @notice Returns LP token exchange rate
    /// @dev Must be implemented by derived price feeds
    function getLPExchangeRate() public view virtual override returns (uint256 exchangeRate);

    /// @notice Returns LP token exchange rate scale
    /// @dev Must be implemented by derived price feeds
    function getScale() public view virtual override returns (uint256 scale);

    // ------------- //
    // CONFIGURATION //
    // ------------- //

    /// @notice Allows permissionless bounds update
    function allowBoundsUpdate()
        external
        override
        configuratorOnly // U:[LPPF-5]
    {
        if (updateBoundsAllowed) return;
        updateBoundsAllowed = true; // U:[LPPF-5]
        emit SetUpdateBoundsAllowed(true); // U:[LPPF-5]
    }

    /// @notice Forbids permissionless bounds update
    function forbidBoundsUpdate()
        external
        override
        controllerOnly // U:[LPPF-5]
    {
        if (!updateBoundsAllowed) return;
        updateBoundsAllowed = false; // U:[LPPF-5]
        emit SetUpdateBoundsAllowed(false); // U:[LPPF-5]
    }

    /// @notice Sets new lower and upper bounds for the LP token exchange rate
    /// @param newLowerBound New lower bound value
    function setLimiter(uint256 newLowerBound)
        external
        override
        controllerOnly // U:[LPPF-6]
    {
        _setLimiter(newLowerBound); // U:[LPPF-6]
    }

    /// @notice Permissionlessly updates LP token's exchange rate bounds using answer from the reserve price feed.
    ///         Lower bound is set to the induced reserve exchange rate (with small buffer for downside movement).
    /// @param updateData Data to update the reserve price feed with before querying its answer if it is updatable
    function updateBounds(bytes calldata updateData) external override {
        if (!updateBoundsAllowed) revert UpdateBoundsNotAllowedException(); // U:[LPPF-7]

        if (block.timestamp < lastBoundsUpdate + UPDATE_BOUNDS_COOLDOWN) revert UpdateBoundsBeforeCooldownException(); // U:[LPPF-7]
        lastBoundsUpdate = uint40(block.timestamp); // U:[LPPF-7]

        address reserveFeed = IPriceOracleV3(priceOracle).reservePriceFeeds({token: lpToken}); // U:[LPPF-7]
        if (reserveFeed == address(this)) revert ReserveFeedMustNotBeSelfException(); // U:[LPPF-7]
        try IUpdatablePriceFeed(reserveFeed).updatable() returns (bool updatable) {
            if (updatable) IUpdatablePriceFeed(reserveFeed).updatePrice(updateData); // U:[LPPF-7]
        } catch {}

        uint256 reserveAnswer = IPriceOracleV3(priceOracle).getReservePrice({token: lpToken}); // U:[LPPF-7]
        uint256 reserveExchangeRate = uint256(reserveAnswer * getScale() / uint256(getAggregatePrice())); // U:[LPPF-7]

        _ensureValueInBounds(reserveExchangeRate, lowerBound); // U:[LPPF-7]
        _setLimiter(_calcLowerBound(reserveExchangeRate)); // U:[LPPF-7]
    }

    /// @dev `setLimiter` implementation: sets new bounds, ensures that current value is within them, emits event
    function _setLimiter(uint256 lower) internal {
        if (lower == 0) revert LowerBoundCantBeZeroException(); // U:[LPPF-6]
        uint256 upper = _ensureValueInBounds(getLPExchangeRate(), lower); // U:[LPPF-6]
        lowerBound = lower; // U:[LPPF-6]
        emit SetBounds(lower, upper); // U:[LPPF-6]
    }

    /// @dev Computes upper bound as `_lowerBound * (1 + WINDOW_SIZE)`
    function _calcUpperBound(uint256 _lowerBound) internal pure returns (uint256) {
        return _lowerBound * (PERCENTAGE_FACTOR + WINDOW_SIZE) / PERCENTAGE_FACTOR; // U:[LPPF-4]
    }

    /// @dev Computes lower bound as `exchangeRate * (1 - BUFFER_SIZE)`
    function _calcLowerBound(uint256 exchangeRate) internal pure returns (uint256) {
        return exchangeRate * (PERCENTAGE_FACTOR - BUFFER_SIZE) / PERCENTAGE_FACTOR; // U:[LPPF-6]
    }

    /// @dev Ensures that value is in bounds, returns upper bound computed from lower bound
    function _ensureValueInBounds(uint256 value, uint256 lower) internal pure returns (uint256 upper) {
        if (value < lower) revert ExchangeRateOutOfBoundsException();
        upper = _calcUpperBound(lower);
        if (value > upper) revert ExchangeRateOutOfBoundsException();
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

struct PriceFeedParams {
    address priceFeed;
    uint32 stalenessPeriod;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
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
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

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
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
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
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
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
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
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
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
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
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
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
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
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
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
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
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
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
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);

    /// @notice Similar to `parsePriceFeedUpdates` but ensures the updates returned are
    /// the first updates published in minPublishTime. That is, if there are multiple updates for a given timestamp,
    /// this method will return the first update. This method may store the price updates on-chain, if they
    /// are more recent than the current stored prices.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range and uniqueness condition.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdatesUnique(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/documentation/pythnet-price-feeds/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./RedstoneConsumerBase.sol";

/**
 * @title The base contract for Redstone consumers' contracts that allows to
 * securely calculate numeric redstone oracle values
 * @author The Redstone Oracles team
 * @dev This contract can extend other contracts to allow them
 * securely fetch Redstone oracle data from transactions calldata
 */
abstract contract RedstoneConsumerNumericBase is RedstoneConsumerBase {
  /**
   * @dev This function can be used in a consumer contract to securely extract an
   * oracle value for a given data feed id. Security is achieved by
   * signatures verification, timestamp validation, and aggregating values
   * from different authorised signers into a single numeric value. If any of the
   * required conditions do not match, the function will revert.
   * Note! This function expects that tx calldata contains redstone payload in the end
   * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
   * @param dataFeedId bytes32 value that uniquely identifies the data feed
   * @return Extracted and verified numeric oracle value for the given data feed id
   */
  function getOracleNumericValueFromTxMsg(bytes32 dataFeedId)
    internal
    view
    virtual
    returns (uint256)
  {
    bytes32[] memory dataFeedIds = new bytes32[](1);
    dataFeedIds[0] = dataFeedId;
    return getOracleNumericValuesFromTxMsg(dataFeedIds)[0];
  }

  /**
   * @dev This function can be used in a consumer contract to securely extract several
   * numeric oracle values for a given array of data feed ids. Security is achieved by
   * signatures verification, timestamp validation, and aggregating values
   * from different authorised signers into a single numeric value. If any of the
   * required conditions do not match, the function will revert.
   * Note! This function expects that tx calldata contains redstone payload in the end
   * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
   * @param dataFeedIds An array of unique data feed identifiers
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in the dataFeedIds array
   */
  function getOracleNumericValuesFromTxMsg(bytes32[] memory dataFeedIds)
    internal
    view
    virtual
    returns (uint256[] memory)
  {
    return _securelyExtractOracleValuesFromTxMsg(dataFeedIds);
  }

  /**
   * @dev This function works similarly to the `getOracleNumericValuesFromTxMsg` with the
   * only difference that it allows to request oracle data for an array of data feeds
   * that may contain duplicates
   * 
   * @param dataFeedIdsWithDuplicates An array of data feed identifiers (duplicates are allowed)
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in the dataFeedIdsWithDuplicates array
   */
  function getOracleNumericValuesWithDuplicatesFromTxMsg(bytes32[] memory dataFeedIdsWithDuplicates) internal view returns (uint256[] memory) {
    // Building an array without duplicates
    bytes32[] memory dataFeedIdsWithoutDuplicates = new bytes32[](dataFeedIdsWithDuplicates.length);
    bool alreadyIncluded;
    uint256 uniqueDataFeedIdsCount = 0;

    for (uint256 indexWithDup = 0; indexWithDup < dataFeedIdsWithDuplicates.length; indexWithDup++) {
      // Checking if current element is already included in `dataFeedIdsWithoutDuplicates`
      alreadyIncluded = false;
      for (uint256 indexWithoutDup = 0; indexWithoutDup < uniqueDataFeedIdsCount; indexWithoutDup++) {
        if (dataFeedIdsWithoutDuplicates[indexWithoutDup] == dataFeedIdsWithDuplicates[indexWithDup]) {
          alreadyIncluded = true;
          break;
        }
      }

      // Adding if not included
      if (!alreadyIncluded) {
        dataFeedIdsWithoutDuplicates[uniqueDataFeedIdsCount] = dataFeedIdsWithDuplicates[indexWithDup];
        uniqueDataFeedIdsCount++;
      }
    }

    // Overriding dataFeedIdsWithoutDuplicates.length
    // Equivalent to: dataFeedIdsWithoutDuplicates.length = uniqueDataFeedIdsCount;
    assembly {
      mstore(dataFeedIdsWithoutDuplicates, uniqueDataFeedIdsCount)
    }

    // Requesting oracle values (without duplicates)
    uint256[] memory valuesWithoutDuplicates = getOracleNumericValuesFromTxMsg(dataFeedIdsWithoutDuplicates);

    // Preparing result values array
    uint256[] memory valuesWithDuplicates = new uint256[](dataFeedIdsWithDuplicates.length);
    for (uint256 indexWithDup = 0; indexWithDup < dataFeedIdsWithDuplicates.length; indexWithDup++) {
      for (uint256 indexWithoutDup = 0; indexWithoutDup < dataFeedIdsWithoutDuplicates.length; indexWithoutDup++) {
        if (dataFeedIdsWithDuplicates[indexWithDup] == dataFeedIdsWithoutDuplicates[indexWithoutDup]) {
          valuesWithDuplicates[indexWithDup] = valuesWithoutDuplicates[indexWithoutDup];
          break;
        }
      }
    }

    return valuesWithDuplicates;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.0;

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128000000000000000000; // 2ˆ7
    int256 constant a0 = 38877084059945950922200000000000000000000000000000000000; // eˆ(x0) (no decimals)
    int256 constant x1 = 64000000000000000000; // 2ˆ6
    int256 constant a1 = 6235149080811616882910000000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3200000000000000000000; // 2ˆ5
    int256 constant a2 = 7896296018268069516100000000000000; // eˆ(x2)
    int256 constant x3 = 1600000000000000000000; // 2ˆ4
    int256 constant a3 = 888611052050787263676000000; // eˆ(x3)
    int256 constant x4 = 800000000000000000000; // 2ˆ3
    int256 constant a4 = 298095798704172827474000; // eˆ(x4)
    int256 constant x5 = 400000000000000000000; // 2ˆ2
    int256 constant a5 = 5459815003314423907810; // eˆ(x5)
    int256 constant x6 = 200000000000000000000; // 2ˆ1
    int256 constant a6 = 738905609893065022723; // eˆ(x6)
    int256 constant x7 = 100000000000000000000; // 2ˆ0
    int256 constant a7 = 271828182845904523536; // eˆ(x7)
    int256 constant x8 = 50000000000000000000; // 2ˆ-1
    int256 constant a8 = 164872127070012814685; // eˆ(x8)
    int256 constant x9 = 25000000000000000000; // 2ˆ-2
    int256 constant a9 = 128402541668774148407; // eˆ(x9)
    int256 constant x10 = 12500000000000000000; // 2ˆ-3
    int256 constant a10 = 113314845306682631683; // eˆ(x10)
    int256 constant x11 = 6250000000000000000; // 2ˆ-4
    int256 constant a11 = 106449445891785942956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x >> 255 == 0, "x out of bounds");
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit range.
            require(y < MILD_EXPONENT_BOUND, "y out of bounds");
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT, "product out of bounds"
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        unchecked {
            require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, "invalid exponent");

            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        unchecked {
            // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

            // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
            // upscaling.

            int256 logBase;
            if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
                logBase = _ln_36(base);
            } else {
                logBase = _ln(base) * ONE_18;
            }

            int256 logArg;
            if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
                logArg = _ln_36(arg);
            } else {
                logArg = _ln(arg) * ONE_18;
            }

            // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
            return (logArg * ONE_18) / logBase;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, "out of bounds");
            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two, which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IACL} from "../interfaces/IACL.sol";
import {
    CallerNotControllerException,
    CallerNotPausableAdminException,
    CallerNotUnpausableAdminException
} from "../interfaces/IExceptions.sol";

import {ACLTrait} from "./ACLTrait.sol";
import {ReentrancyGuardTrait} from "./ReentrancyGuardTrait.sol";

/// @title ACL non-reentrant trait
/// @notice Extended version of `ACLTrait` that implements pausable functionality,
///         reentrancy protection and external controller role
abstract contract ACLNonReentrantTrait is ACLTrait, Pausable, ReentrancyGuardTrait {
    /// @notice Emitted when new external controller is set
    event NewController(address indexed newController);

    /// @notice External controller address
    address public controller;

    /// @dev Ensures that function caller is external controller or configurator
    modifier controllerOnly() {
        _ensureCallerIsControllerOrConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not controller or configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsControllerOrConfigurator() internal view {
        if (msg.sender != controller && !_isConfigurator({account: msg.sender})) {
            revert CallerNotControllerException();
        }
    }

    /// @dev Ensures that function caller has pausable admin role
    modifier pausableAdminsOnly() {
        _ensureCallerIsPausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not pausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsPausableAdmin() internal view {
        if (!_isPausableAdmin({account: msg.sender})) {
            revert CallerNotPausableAdminException();
        }
    }

    /// @dev Ensures that function caller has unpausable admin role
    modifier unpausableAdminsOnly() {
        _ensureCallerIsUnpausableAdmin();
        _;
    }

    /// @dev Reverts if the caller is not unpausable admin
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsUnpausableAdmin() internal view {
        if (!_isUnpausableAdmin({account: msg.sender})) {
            revert CallerNotUnpausableAdminException();
        }
    }

    /// @notice Constructor
    /// @param acl ACL contract address
    constructor(address acl) ACLTrait(acl) {
        controller = IACL(acl).owner();
    }

    /// @notice Pauses contract, can only be called by an account with pausable admin role
    function pause() external virtual pausableAdminsOnly {
        _pause();
    }

    /// @notice Unpauses contract, can only be called by an account with unpausable admin role
    function unpause() external virtual unpausableAdminsOnly {
        _unpause();
    }

    /// @notice Sets new external controller, can only be called by configurator
    function setController(address newController) external configuratorOnly {
        if (controller == newController) return;
        controller = newController;
        emit NewController(newController);
    }

    /// @dev Checks whether given account has pausable admin role
    function _isPausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isPausableAdmin(account);
    }

    /// @dev Checks whether given account has unpausable admin role
    function _isUnpausableAdmin(address account) internal view returns (bool) {
        return IACL(acl).isUnpausableAdmin(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./RedstoneConstants.sol";
import "./RedstoneDefaultsLib.sol";
import "./CalldataExtractor.sol";
import "../libs/BitmapLib.sol";
import "../libs/SignatureLib.sol";

/**
 * @title The base contract with the main Redstone logic
 * @author The Redstone Oracles team
 * @dev Do not use this contract directly in consumer contracts, take a
 * look at `RedstoneConsumerNumericBase` and `RedstoneConsumerBytesBase` instead
 */
abstract contract RedstoneConsumerBase is CalldataExtractor {
  using SafeMath for uint256;

  error GetDataServiceIdNotImplemented();

  /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDDEN IN CHILD CONTRACTS) ========== */

  /**
   * @dev This function must be implemented by the child consumer contract.
   * It should return dataServiceId which DataServiceWrapper will use if not provided explicitly .
   * If not overridden, value will always have to be provided explicitly in DataServiceWrapper.
   * @return dataServiceId being consumed by contract
   */
  function getDataServiceId() public view virtual returns (string memory) {
    revert GetDataServiceIdNotImplemented();
  }

  /**
   * @dev This function must be implemented by the child consumer contract.
   * It should return a unique index for a given signer address if the signer
   * is authorised, otherwise it should revert
   * @param receivedSigner The address of a signer, recovered from ECDSA signature
   * @return Unique index for a signer in the range [0..255]
   */
  function getAuthorisedSignerIndex(address receivedSigner) public view virtual returns (uint8);

  /**
   * @dev This function may be overridden by the child consumer contract.
   * It should validate the timestamp against the current time (block.timestamp)
   * It should revert with a helpful message if the timestamp is not valid
   * @param receivedTimestampMilliseconds Timestamp extracted from calldata
   */
  function validateTimestamp(uint256 receivedTimestampMilliseconds) public view virtual {
    RedstoneDefaultsLib.validateTimestamp(receivedTimestampMilliseconds);
  }

  /**
   * @dev This function should be overridden by the child consumer contract.
   * @return The minimum required value of unique authorised signers
   */
  function getUniqueSignersThreshold() public view virtual returns (uint8) {
    return 1;
  }

  /**
   * @dev This function may be overridden by the child consumer contract.
   * It should aggregate values from different signers to a single uint value.
   * By default, it calculates the median value
   * @param values An array of uint256 values from different signers
   * @return Result of the aggregation in the form of a single number
   */
  function aggregateValues(uint256[] memory values) public view virtual returns (uint256) {
    return RedstoneDefaultsLib.aggregateValues(values);
  }

  /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDDEN) ========== */

  /**
   * @dev This is an internal helpful function for secure extraction oracle values
   * from the tx calldata. Security is achieved by signatures verification, timestamp
   * validation, and aggregating values from different authorised signers into a
   * single numeric value. If any of the required conditions (e.g. too old timestamp or
   * insufficient number of authorised signers) do not match, the function will revert.
   *
   * Note! You should not call this function in a consumer contract. You can use
   * `getOracleNumericValuesFromTxMsg` or `getOracleNumericValueFromTxMsg` instead.
   *
   * @param dataFeedIds An array of unique data feed identifiers
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in dataFeedIds array
   */
  function _securelyExtractOracleValuesFromTxMsg(bytes32[] memory dataFeedIds)
    internal
    view
    returns (uint256[] memory)
  {
    // Initializing helpful variables and allocating memory
    uint256[] memory uniqueSignerCountForDataFeedIds = new uint256[](dataFeedIds.length);
    uint256[] memory signersBitmapForDataFeedIds = new uint256[](dataFeedIds.length);
    uint256[][] memory valuesForDataFeeds = new uint256[][](dataFeedIds.length);
    for (uint256 i = 0; i < dataFeedIds.length; i++) {
      // The line below is commented because newly allocated arrays are filled with zeros
      // But we left it for better readability
      // signersBitmapForDataFeedIds[i] = 0; // <- setting to an empty bitmap
      valuesForDataFeeds[i] = new uint256[](getUniqueSignersThreshold());
    }

    // Extracting the number of data packages from calldata
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);
    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;

    // Saving current free memory pointer
    uint256 freeMemPtr;
    assembly {
      freeMemPtr := mload(FREE_MEMORY_PTR)
    }

    // Data packages extraction in a loop
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      // Extract data package details and update calldata offset
      uint256 dataPackageByteSize = _extractDataPackage(
        dataFeedIds,
        uniqueSignerCountForDataFeedIds,
        signersBitmapForDataFeedIds,
        valuesForDataFeeds,
        calldataNegativeOffset
      );
      calldataNegativeOffset += dataPackageByteSize;

      // Shifting memory pointer back to the "safe" value
      assembly {
        mstore(FREE_MEMORY_PTR, freeMemPtr)
      }
    }

    // Validating numbers of unique signers and calculating aggregated values for each dataFeedId
    return _getAggregatedValues(valuesForDataFeeds, uniqueSignerCountForDataFeedIds);
  }

  /**
   * @dev This is a private helpful function, which extracts data for a data package based
   * on the given negative calldata offset, verifies them, and in the case of successful
   * verification updates the corresponding data package values in memory
   *
   * @param dataFeedIds an array of unique data feed identifiers
   * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
   * for each data feed
   * @param signersBitmapForDataFeedIds an array of signer bitmaps for data feeds
   * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
   * j-th value for the i-th data feed
   * @param calldataNegativeOffset negative calldata offset for the given data package
   *
   * @return An array of the aggregated values
   */
  function _extractDataPackage(
    bytes32[] memory dataFeedIds,
    uint256[] memory uniqueSignerCountForDataFeedIds,
    uint256[] memory signersBitmapForDataFeedIds,
    uint256[][] memory valuesForDataFeeds,
    uint256 calldataNegativeOffset
  ) private view returns (uint256) {
    uint256 signerIndex;

    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    // We use scopes to resolve problem with too deep stack
    {
      uint48 extractedTimestamp;
      address signerAddress;
      bytes32 signedHash;
      bytes memory signedMessage;
      uint256 signedMessageBytesCount;

      signedMessageBytesCount = dataPointsCount.mul(eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS)
        + DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS; //DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS

      uint256 timestampCalldataOffset = msg.data.length.sub(
        calldataNegativeOffset + TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS);

      uint256 signedMessageCalldataOffset = msg.data.length.sub(
        calldataNegativeOffset + SIG_BS + signedMessageBytesCount);

      assembly {
        // Extracting the signed message
        signedMessage := extractBytesFromCalldata(
          signedMessageCalldataOffset,
          signedMessageBytesCount
        )

        // Hashing the signed message
        signedHash := keccak256(add(signedMessage, BYTES_ARR_LEN_VAR_BS), signedMessageBytesCount)

        // Extracting timestamp
        extractedTimestamp := calldataload(timestampCalldataOffset)

        function initByteArray(bytesCount) -> ptr {
          ptr := mload(FREE_MEMORY_PTR)
          mstore(ptr, bytesCount)
          ptr := add(ptr, BYTES_ARR_LEN_VAR_BS)
          mstore(FREE_MEMORY_PTR, add(ptr, bytesCount))
        }

        function extractBytesFromCalldata(offset, bytesCount) -> extractedBytes {
          let extractedBytesStartPtr := initByteArray(bytesCount)
          calldatacopy(
            extractedBytesStartPtr,
            offset,
            bytesCount
          )
          extractedBytes := sub(extractedBytesStartPtr, BYTES_ARR_LEN_VAR_BS)
        }
      }

      // Validating timestamp
      validateTimestamp(extractedTimestamp);

      // Verifying the off-chain signature against on-chain hashed data
      signerAddress = SignatureLib.recoverSignerAddress(
        signedHash,
        calldataNegativeOffset + SIG_BS
      );
      signerIndex = getAuthorisedSignerIndex(signerAddress);
    }

    // Updating helpful arrays
    {
      bytes32 dataPointDataFeedId;
      uint256 dataPointValue;
      for (uint256 dataPointIndex = 0; dataPointIndex < dataPointsCount; dataPointIndex++) {
        // Extracting data feed id and value for the current data point
        (dataPointDataFeedId, dataPointValue) = _extractDataPointValueAndDataFeedId(
          calldataNegativeOffset,
          eachDataPointValueByteSize,
          dataPointIndex
        );

        for (
          uint256 dataFeedIdIndex = 0;
          dataFeedIdIndex < dataFeedIds.length;
          dataFeedIdIndex++
        ) {
          if (dataPointDataFeedId == dataFeedIds[dataFeedIdIndex]) {
            uint256 bitmapSignersForDataFeedId = signersBitmapForDataFeedIds[dataFeedIdIndex];

            if (
              !BitmapLib.getBitFromBitmap(bitmapSignersForDataFeedId, signerIndex) && /* current signer was not counted for current dataFeedId */
              uniqueSignerCountForDataFeedIds[dataFeedIdIndex] < getUniqueSignersThreshold()
            ) {
              // Increase unique signer counter
              uniqueSignerCountForDataFeedIds[dataFeedIdIndex]++;

              // Add new value
              valuesForDataFeeds[dataFeedIdIndex][
                uniqueSignerCountForDataFeedIds[dataFeedIdIndex] - 1
              ] = dataPointValue;

              // Update signers bitmap
              signersBitmapForDataFeedIds[dataFeedIdIndex] = BitmapLib.setBitInBitmap(
                bitmapSignersForDataFeedId,
                signerIndex
              );
            }

            // Breaking, as there couldn't be several indexes for the same feed ID
            break;
          }
        }
      }
    }

    // Return total data package byte size
    return
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS +
      (eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS) *
      dataPointsCount;
  }

  /**
   * @dev This is a private helpful function, which aggregates values from different
   * authorised signers for the given arrays of values for each data feed
   *
   * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
   * j-th value for the i-th data feed
   * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
   * for each data feed
   *
   * @return An array of the aggregated values
   */
  function _getAggregatedValues(
    uint256[][] memory valuesForDataFeeds,
    uint256[] memory uniqueSignerCountForDataFeedIds
  ) private view returns (uint256[] memory) {
    uint256[] memory aggregatedValues = new uint256[](valuesForDataFeeds.length);
    uint256 uniqueSignersThreshold = getUniqueSignersThreshold();

    for (uint256 dataFeedIndex = 0; dataFeedIndex < valuesForDataFeeds.length; dataFeedIndex++) {
      if (uniqueSignerCountForDataFeedIds[dataFeedIndex] < uniqueSignersThreshold) {
        revert InsufficientNumberOfUniqueSigners(
          uniqueSignerCountForDataFeedIds[dataFeedIndex],
          uniqueSignersThreshold);
      }
      uint256 aggregatedValueForDataFeedId = aggregateValues(valuesForDataFeeds[dataFeedIndex]);
      aggregatedValues[dataFeedIndex] = aggregatedValueForDataFeedId;
    }

    return aggregatedValues;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

interface IACL {
    function owner() external view returns (address);
    function isConfigurator(address account) external view returns (bool);
    function isPausableAdmin(address addr) external view returns (bool);
    function isUnpausableAdmin(address addr) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

import {IACL} from "../interfaces/IACL.sol";
import {CallerNotConfiguratorException} from "../interfaces/IExceptions.sol";

import {SanityCheckTrait} from "./SanityCheckTrait.sol";

/// @title ACL trait
/// @notice Utility class for ACL (access-control list) consumers
abstract contract ACLTrait is SanityCheckTrait {
    /// @notice ACL contract address
    address public immutable acl;

    /// @notice Constructor
    /// @param _acl ACL contract address
    constructor(address _acl) nonZeroAddress(_acl) {
        acl = _acl;
    }

    /// @dev Ensures that function caller has configurator role
    modifier configuratorOnly() {
        _ensureCallerIsConfigurator();
        _;
    }

    /// @dev Reverts if the caller is not the configurator
    /// @dev Used to cut contract size on modifiers
    function _ensureCallerIsConfigurator() internal view {
        if (!_isConfigurator({account: msg.sender})) {
            revert CallerNotConfiguratorException();
        }
    }

    /// @dev Checks whether given account has configurator role
    function _isConfigurator(address account) internal view returns (bool) {
        return IACL(acl).isConfigurator(account);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024.
pragma solidity ^0.8.17;

uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/// @title Reentrancy guard trait
/// @notice Same as OpenZeppelin's `ReentrancyGuard` but only uses 1 byte of storage instead of 32
abstract contract ReentrancyGuardTrait {
    uint8 internal _reentrancyStatus = NOT_ENTERED;

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    /// Calling a `nonReentrant` function from another `nonReentrant`
    /// function is not supported. It is possible to prevent this from happening
    /// by making the `nonReentrant` function external, and making it call a
    /// `private` function that does the actual work.
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        _ensureNotEntered();

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = NOT_ENTERED;
    }

    /// @dev Reverts if the contract is currently entered
    /// @dev Used to cut contract size on modifiers
    function _ensureNotEntered() internal view {
        require(_reentrancyStatus != ENTERED, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

/**
 * @title The base contract with helpful constants
 * @author The Redstone Oracles team
 * @dev It mainly contains redstone-related values, which improve readability
 * of other contracts (e.g. CalldataExtractor and RedstoneConsumerBase)
 */
contract RedstoneConstants {
  // === Abbreviations ===
  // BS - Bytes size
  // PTR - Pointer (memory location)
  // SIG - Signature

  // Solidity and YUL constants
  uint256 internal constant STANDARD_SLOT_BS = 32;
  uint256 internal constant FREE_MEMORY_PTR = 0x40;
  uint256 internal constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 internal constant FUNCTION_SIGNATURE_BS = 4;
  uint256 internal constant REVERT_MSG_OFFSET = 68; // Revert message structure described here: https://ethereum.stackexchange.com/a/66173/106364
  uint256 internal constant STRING_ERR_MESSAGE_MASK = 0x08c379a000000000000000000000000000000000000000000000000000000000;

  // RedStone protocol consts
  uint256 internal constant SIG_BS = 65;
  uint256 internal constant TIMESTAMP_BS = 6;
  uint256 internal constant DATA_PACKAGES_COUNT_BS = 2;
  uint256 internal constant DATA_POINTS_COUNT_BS = 3;
  uint256 internal constant DATA_POINT_VALUE_BYTE_SIZE_BS = 4;
  uint256 internal constant DATA_POINT_SYMBOL_BS = 32;
  uint256 internal constant DEFAULT_DATA_POINT_VALUE_BS = 32;
  uint256 internal constant UNSIGNED_METADATA_BYTE_SIZE_BS = 3;
  uint256 internal constant REDSTONE_MARKER_BS = 9; // byte size of 0x000002ed57011e0000
  uint256 internal constant REDSTONE_MARKER_MASK = 0x0000000000000000000000000000000000000000000000000002ed57011e0000;

  // Derived values (based on consts)
  uint256 internal constant TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS = 104; // SIG_BS + DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + STANDARD_SLOT_BS
  uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_BS = 78; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS + SIG_BS
  uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS = 13; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS
  uint256 internal constant REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS = 41; // REDSTONE_MARKER_BS + STANDARD_SLOT_BS

  // Error messages
  error CalldataOverOrUnderFlow();
  error IncorrectUnsignedMetadataSize();
  error InsufficientNumberOfUniqueSigners(uint256 receivedSignersCount, uint256 requiredSignersCount);
  error EachSignerMustProvideTheSameValue();
  error EmptyCalldataPointersArr();
  error InvalidCalldataPointer();
  error CalldataMustHaveValidPayload();
  error SignerNotAuthorised(address receivedSigner);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "../libs/NumericArrayLib.sol";

/**
 * @title Default implementations of virtual redstone consumer base functions
 * @author The Redstone Oracles team
 */
library RedstoneDefaultsLib {
  uint256 constant DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS = 3 minutes;
  uint256 constant DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

  error TimestampFromTooLongFuture(uint256 receivedTimestampSeconds, uint256 blockTimestamp);
  error TimestampIsTooOld(uint256 receivedTimestampSeconds, uint256 blockTimestamp);

  function validateTimestamp(uint256 receivedTimestampMilliseconds) internal view {
    // Getting data timestamp from future seems quite unlikely
    // But we've already spent too much time with different cases
    // Where block.timestamp was less than dataPackage.timestamp.
    // Some blockchains may case this problem as well.
    // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
    // and allow data "from future" but with a small delay
    uint256 receivedTimestampSeconds = receivedTimestampMilliseconds / 1000;

    if (block.timestamp < receivedTimestampSeconds) {
      if ((receivedTimestampSeconds - block.timestamp) > DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
        revert TimestampFromTooLongFuture(receivedTimestampSeconds, block.timestamp);
      }
    } else if ((block.timestamp - receivedTimestampSeconds) > DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
      revert TimestampIsTooOld(receivedTimestampSeconds, block.timestamp);
    }
  }

  function aggregateValues(uint256[] memory values) internal pure returns (uint256) {
    return NumericArrayLib.pickMedian(values);
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./RedstoneConstants.sol";

/**
 * @title The base contract with the main logic of data extraction from calldata
 * @author The Redstone Oracles team
 * @dev This contract was created to reuse the same logic in the RedstoneConsumerBase
 * and the ProxyConnector contracts
 */
contract CalldataExtractor is RedstoneConstants {
  using SafeMath for uint256;

  error DataPackageTimestampMustNotBeZero();
  error DataPackageTimestampsMustBeEqual();
  error RedstonePayloadMustHaveAtLeastOneDataPackage();

  function extractTimestampsAndAssertAllAreEqual() public pure returns (uint256 extractedTimestamp) {
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);

    if (dataPackagesCount == 0) {
      revert RedstonePayloadMustHaveAtLeastOneDataPackage();
    }

    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      uint256 dataPackageByteSize = _getDataPackageByteSize(calldataNegativeOffset);

      // Extracting timestamp for the current data package
      uint48 dataPackageTimestamp; // uint48, because timestamp uses 6 bytes
      uint256 timestampNegativeOffset = (calldataNegativeOffset + TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS);
      uint256 timestampOffset = msg.data.length - timestampNegativeOffset;
      assembly {
        dataPackageTimestamp := calldataload(timestampOffset)
      }

      if (dataPackageTimestamp == 0) {
        revert DataPackageTimestampMustNotBeZero();
      }

      if (extractedTimestamp == 0) {
        extractedTimestamp = dataPackageTimestamp;
      } else if (dataPackageTimestamp != extractedTimestamp) {
        revert DataPackageTimestampsMustBeEqual();
      }

      calldataNegativeOffset += dataPackageByteSize;
    }
  }

  function _getDataPackageByteSize(uint256 calldataNegativeOffset) internal pure returns (uint256) {
    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    return
      dataPointsCount *
      (DATA_POINT_SYMBOL_BS + eachDataPointValueByteSize) +
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
  }

  function _extractByteSizeOfUnsignedMetadata() internal pure returns (uint256) {
    // Checking if the calldata ends with the RedStone marker
    bool hasValidRedstoneMarker;
    assembly {
      let calldataLast32Bytes := calldataload(sub(calldatasize(), STANDARD_SLOT_BS))
      hasValidRedstoneMarker := eq(
        REDSTONE_MARKER_MASK,
        and(calldataLast32Bytes, REDSTONE_MARKER_MASK)
      )
    }
    if (!hasValidRedstoneMarker) {
      revert CalldataMustHaveValidPayload();
    }

    // Using uint24, because unsigned metadata byte size number has 3 bytes
    uint24 unsignedMetadataByteSize;
    if (REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }
    assembly {
      unsignedMetadataByteSize := calldataload(
        sub(calldatasize(), REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS)
      )
    }
    uint256 calldataNegativeOffset = unsignedMetadataByteSize
      + UNSIGNED_METADATA_BYTE_SIZE_BS
      + REDSTONE_MARKER_BS;
    if (calldataNegativeOffset + DATA_PACKAGES_COUNT_BS > msg.data.length) {
      revert IncorrectUnsignedMetadataSize();
    }
    return calldataNegativeOffset;
  }

  // We return uint16, because unsigned metadata byte size number has 2 bytes
  function _extractDataPackagesCountFromCalldata(uint256 calldataNegativeOffset)
    internal
    pure
    returns (uint16 dataPackagesCount)
  {
    uint256 calldataNegativeOffsetWithStandardSlot = calldataNegativeOffset + STANDARD_SLOT_BS;
    if (calldataNegativeOffsetWithStandardSlot > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }
    assembly {
      dataPackagesCount := calldataload(
        sub(calldatasize(), calldataNegativeOffsetWithStandardSlot)
      )
    }
    return dataPackagesCount;
  }

  function _extractDataPointValueAndDataFeedId(
    uint256 calldataNegativeOffsetForDataPackage,
    uint256 defaultDataPointValueByteSize,
    uint256 dataPointIndex
  ) internal pure virtual returns (bytes32 dataPointDataFeedId, uint256 dataPointValue) {
    uint256 negativeOffsetToDataPoints = calldataNegativeOffsetForDataPackage + DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
    uint256 dataPointNegativeOffset = negativeOffsetToDataPoints.add(
      (1 + dataPointIndex).mul((defaultDataPointValueByteSize + DATA_POINT_SYMBOL_BS))
    );
    uint256 dataPointCalldataOffset = msg.data.length.sub(dataPointNegativeOffset);
    assembly {
      dataPointDataFeedId := calldataload(dataPointCalldataOffset)
      dataPointValue := calldataload(add(dataPointCalldataOffset, DATA_POINT_SYMBOL_BS))
    }
  }

  function _extractDataPointsDetailsForDataPackage(uint256 calldataNegativeOffsetForDataPackage)
    internal
    pure
    returns (uint256 dataPointsCount, uint256 eachDataPointValueByteSize)
  {
    // Using uint24, because data points count byte size number has 3 bytes
    uint24 dataPointsCount_;

    // Using uint32, because data point value byte size has 4 bytes
    uint32 eachDataPointValueByteSize_;

    // Extract data points count
    uint256 negativeCalldataOffset = calldataNegativeOffsetForDataPackage + SIG_BS;
    uint256 calldataOffset = msg.data.length.sub(negativeCalldataOffset + STANDARD_SLOT_BS);
    assembly {
      dataPointsCount_ := calldataload(calldataOffset)
    }

    // Extract each data point value size
    calldataOffset = calldataOffset.sub(DATA_POINTS_COUNT_BS);
    assembly {
      eachDataPointValueByteSize_ := calldataload(calldataOffset)
    }

    // Prepare returned values
    dataPointsCount = dataPointsCount_;
    eachDataPointValueByteSize = eachDataPointValueByteSize_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library BitmapLib {
  function setBitInBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (uint256) {
    return bitmap | (1 << bitIndex);
  }

  function getBitFromBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (bool) {
    uint256 bitAtIndex = bitmap & (1 << bitIndex);
    return bitAtIndex > 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SignatureLib {
  uint256 constant ECDSA_SIG_R_BS = 32;
  uint256 constant ECDSA_SIG_S_BS = 32;

  function recoverSignerAddress(bytes32 signedHash, uint256 signatureCalldataNegativeOffset)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      let signatureCalldataStartPos := sub(calldatasize(), signatureCalldataNegativeOffset)
      r := calldataload(signatureCalldataStartPos)
      signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_R_BS)
      s := calldataload(signatureCalldataStartPos)
      signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_S_BS)
      v := byte(0, calldataload(signatureCalldataStartPos)) // last byte of the signature memory array
    }
    return ecrecover(signedHash, v, r, s);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library NumericArrayLib {
  // This function sort array in memory using bubble sort algorithm,
  // which performs even better than quick sort for small arrays

  uint256 constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 constant UINT256_VALUE_BS = 32;

  error CanNotPickMedianOfEmptyArray();

  // This function modifies the array
  function pickMedian(uint256[] memory arr) internal pure returns (uint256) {
    if (arr.length == 0) {
      revert CanNotPickMedianOfEmptyArray();
    }
    sort(arr);
    uint256 middleIndex = arr.length / 2;
    if (arr.length % 2 == 0) {
      uint256 sum = SafeMath.add(arr[middleIndex - 1], arr[middleIndex]);
      return sum / 2;
    } else {
      return arr[middleIndex];
    }
  }

  function sort(uint256[] memory arr) internal pure {
    assembly {
      let arrLength := mload(arr)
      let valuesPtr := add(arr, BYTES_ARR_LEN_VAR_BS)
      let endPtr := add(valuesPtr, mul(arrLength, UINT256_VALUE_BS))
      for {
        let arrIPtr := valuesPtr
      } lt(arrIPtr, endPtr) {
        arrIPtr := add(arrIPtr, UINT256_VALUE_BS) // arrIPtr += 32
      } {
        for {
          let arrJPtr := valuesPtr
        } lt(arrJPtr, arrIPtr) {
          arrJPtr := add(arrJPtr, UINT256_VALUE_BS) // arrJPtr += 32
        } {
          let arrI := mload(arrIPtr)
          let arrJ := mload(arrJPtr)
          if lt(arrI, arrJ) {
            mstore(arrIPtr, arrJ)
            mstore(arrJPtr, arrI)
          }
        }
      }
    }
  }
}