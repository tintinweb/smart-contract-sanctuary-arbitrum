// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {
    GoldLinkOwnableUpgradeable
} from "../../utils/GoldLinkOwnableUpgradeable.sol";
import {
    MarketConfigurationManager
} from "./configuration/MarketConfigurationManager.sol";
import {
    DeploymentConfigurationManager
} from "./configuration/DeploymentConfigurationManager.sol";
import {
    IChainlinkAdapter
} from "../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";
import {
    IChainlinkAggregatorV3
} from "../../adapters/chainlink/interfaces/external/IChainlinkAggregatorV3.sol";
import {
    OracleAssetRegistry
} from "../../adapters/chainlink/OracleAssetRegistry.sol";
import {
    IGmxFrfStrategyManager
} from "./interfaces/IGmxFrfStrategyManager.sol";
import {
    IGmxV2ExchangeRouter
} from "../../strategies/gmxFrf/interfaces/gmx/IGmxV2ExchangeRouter.sol";
import {
    IGmxV2Reader
} from "../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2DataStore
} from "../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2RoleStore
} from "../../strategies/gmxFrf/interfaces/gmx/IGmxV2RoleStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import {
    IGmxV2MarketTypes
} from "../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import { IMarketConfiguration } from "./interfaces/IMarketConfiguration.sol";
import {
    IWrappedNativeToken
} from "../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import { GmxFrfStrategyErrors } from "./GmxFrfStrategyErrors.sol";
import { Limits } from "./libraries/Limits.sol";

/**
 * @title GmxFrfStrategyManager
 * @author GoldLink
 *
 * @notice Contract that deploys new strategy accounts for the GMX funding rate farming strategy.
 */
contract GmxFrfStrategyManager is
    IGmxFrfStrategyManager,
    DeploymentConfigurationManager,
    MarketConfigurationManager,
    OracleAssetRegistry,
    GoldLinkOwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ Constructor ============

    /**
     * @notice Constructor for upgradeable contract, distinct from initializer.
     *
     *  The constructor is used to set immutable variables, and for top-level upgradeable
     *  contracts, it is also used to disable the initializer of the logic contract.
     */
    constructor(
        IERC20 strategyAsset,
        IWrappedNativeToken wrappedNativeToken,
        address collateralClaimDistributor
    )
        DeploymentConfigurationManager(
            strategyAsset,
            wrappedNativeToken,
            collateralClaimDistributor
        )
    {
        _disableInitializers();
    }

    // ============ Initializer ============

    function initialize(
        Deployments calldata deployments,
        SharedOrderParameters calldata sharedOrderParameters,
        IChainlinkAdapter.OracleConfiguration
            calldata strategyAssetOracleConfig,
        uint256 liquidationOrderTimeoutDeadline
    ) external initializer {
        __Ownable_init(msg.sender);
        __DeploymentConfigurationManager_init(deployments);
        __MarketConfigurationManager_init(
            sharedOrderParameters,
            liquidationOrderTimeoutDeadline
        );
        __OracleAssetRegistry_init(address(USDC), strategyAssetOracleConfig);
    }

    // ============ External Functions ============

    function setExchangeRouter(
        IGmxV2ExchangeRouter exchangeRouter
    ) external override onlyOwner onlyNonZeroAddress(address(exchangeRouter)) {
        _setExchangeRouter(exchangeRouter);
    }

    function setOrderVault(
        address orderVault
    ) external override onlyOwner onlyNonZeroAddress(orderVault) {
        _setOrderVault(orderVault);
    }

    function setReader(
        IGmxV2Reader reader
    ) external override onlyOwner onlyNonZeroAddress(address(reader)) {
        _setReader(reader);
    }

    function setDataStore(
        IGmxV2DataStore dataStore
    ) external override onlyOwner onlyNonZeroAddress(address(dataStore)) {
        _setDataStore(dataStore);
    }

    function setRoleStore(
        IGmxV2RoleStore roleStore
    ) external override onlyOwner onlyNonZeroAddress(address(roleStore)) {
        _setRoleStore(roleStore);
    }

    function setReferralStorage(
        IGmxV2ReferralStorage referralStorage
    ) external override onlyOwner onlyNonZeroAddress(address(referralStorage)) {
        _setReferralStorage(referralStorage);
    }

    /**
     * @notice Sets the market configuration for the specified `marketAddress`. Will overwrite the existing configuration. The function should be
     * guarded by a timelock, or changes should be announced in advance, to ensure that any account that may be effected has ample amount of time to adjust their position accordingly
     * in the event that a parameter change puts their position at risk.
     * @param marketAddress                  The address of the market being set.
     * @param oracleConfig                   The configuration for the oracle for the long token of this market.
     * @param marketParameters               The parameters for the newly added market.
     * @param positionParameters             The parameters for maintaining a position.
     * @param unwindParameters               The parameters for unwinding a position.
     * @param longTokenLiquidationFeePercent The fee for liquidating a position.
     */
    function setMarket(
        address marketAddress,
        IChainlinkAdapter.OracleConfiguration calldata oracleConfig,
        OrderPricingParameters calldata marketParameters,
        PositionParameters calldata positionParameters,
        UnwindParameters calldata unwindParameters,
        uint256 longTokenLiquidationFeePercent
    ) external override onlyOwner {
        // Get the market from the GMX V2 Reader to validate the state of the market.
        IGmxV2MarketTypes.Props memory market = gmxV2Reader().getMarket(
            gmxV2DataStore(),
            marketAddress
        );

        // Make sure the short token is USDC, also ensures the market exists otherwise
        // the short token would be the zero address.
        require(
            market.shortToken == address(USDC),
            GmxFrfStrategyErrors
                .GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_MUST_BE_USDC
        );

        // Sanity check.
        require(
            market.longToken != address(USDC),
            GmxFrfStrategyErrors.LONG_TOKEN_CANT_BE_USDC
        );

        // Check to make sure we are either modifying an existing asset's oracle or adding
        // a new oracle. The asset oracle length must be limited to prevent the admin adding
        // a lot of asset oracles, making it impossible for a strategy account to be liquidated
        // or repay it's loan due to out of gas errors when calling `getAccountValue()`.
        require(
            registeredAssets_.contains(market.longToken) ||
                registeredAssets_.length() < Limits.MAX_REGISTERED_ASSET_COUNT,
            GmxFrfStrategyErrors.ASSET_ORACLE_COUNT_CANNOT_EXCEED_MAXIMUM
        );

        // Get all markets so we can check that there is no market with a different address
        // that has the same long token. This prevents double counting the value of assets.
        address[] memory markets = getAvailableMarkets();

        uint256 marketsLength = markets.length;
        for (uint256 i = 0; i < marketsLength; ++i) {
            address marketAddressToCheck = markets[i];
            if (marketAddressToCheck == marketAddress) {
                // If the market already exists, it implies this check already passed
                // successfully.
                break;
            }

            IGmxV2MarketTypes.Props memory marketToCheck = gmxV2Reader()
                .getMarket(gmxV2DataStore(), marketAddressToCheck);

            // Check to make sure the market we are checking, which at this point is a different address than the market being added,
            // does not have the same long token. This can occur if GMX decides to upgrade market contracts, so it must be validated.
            require(
                marketToCheck.longToken != market.longToken,
                GmxFrfStrategyErrors
                    .CANNOT_ADD_SEPERATE_MARKET_WITH_SAME_LONG_TOKEN
            );
        }

        _setAssetOracle(
            market.longToken,
            oracleConfig.oracle,
            oracleConfig.validPriceDuration
        );

        // Set the market configuration.
        _setMarketConfiguration(
            marketAddress,
            marketParameters,
            positionParameters,
            unwindParameters
        );

        // Set the liquidation fee for the long token.
        _setAssetLiquidationFeePercent(
            market.longToken,
            longTokenLiquidationFeePercent
        );
    }

    /**
     * @notice Update the USDC oracle. Gives admin the ability to update the USDC oracle should
     * it change upstream.
     * @param strategyAssetOracleConfig The updated configuration for the USDC oracle.
     */
    function updateUsdcOracle(
        IChainlinkAdapter.OracleConfiguration calldata strategyAssetOracleConfig
    ) external override onlyOwner {
        _setAssetOracle(
            address(USDC),
            strategyAssetOracleConfig.oracle,
            strategyAssetOracleConfig.validPriceDuration
        );
    }

    /**
     * @notice Disables all increase orders in a market. This function is provided so the timelock contract that owns the GmxFrfStrategyManager can
     * instantly disable increase orders in a market in the event of severe protocol malfunction that require immediate attention. This function should not
     * be timelocked, as it only prevents borrowers from increasing exposure to a given market. All decrease functionality remains possible.
     * Note that is still possible to disable market increases via `setMarket`.
     * @param marketAddress       The address of the market being added.
     */
    function disableMarketIncreases(
        address marketAddress
    ) external override onlyOwner {
        // Make sure the market actually exists.
        require(
            isApprovedMarket(marketAddress),
            GmxFrfStrategyErrors.MARKET_IS_NOT_ENABLED
        );

        MarketConfiguration memory config = getMarketConfiguration(
            marketAddress
        );

        // Make sure that increases are not already disabled.
        require(
            config.orderPricingParameters.increaseEnabled,
            GmxFrfStrategyErrors.MARKET_INCREASES_ARE_ALREADY_DISABLED
        );

        // Set `increaseEnabled` to false, preventing increase orders from being created. Pending increase orders will still be executed.
        config.orderPricingParameters.increaseEnabled = false;

        _setMarketConfiguration(
            marketAddress,
            config.orderPricingParameters,
            config.positionParameters,
            config.unwindParameters
        );
    }

    /**
     * @notice Set the asset liquidation fee percent for a specific asset. There is a maximum fee
     * of 10% (1e17) to prevent a bad owner from stealing all assets in an account.
     * @param asset                    The asset to set the liquidation fee for.
     * @param newLiquidationFeePercent The fee percentage that is paid to liquidators when selling this asset.
     */
    function setAssetLiquidationFee(
        address asset,
        uint256 newLiquidationFeePercent
    ) external override onlyOwner {
        _setAssetLiquidationFeePercent(asset, newLiquidationFeePercent);
    }

    /**
     * @notice Set the liquidation order timeout deadline, which is the amount of time that must pass before
     * a liquidation order can be cancelled.
     * @param newLiquidationOrderTimeoutDeadline The new liquidation order timeout to use for all liquidation orders.
     */
    function setLiquidationOrderTimeoutDeadline(
        uint256 newLiquidationOrderTimeoutDeadline
    ) external override onlyOwner {
        _setLiquidationOrderTimeoutDeadline(newLiquidationOrderTimeoutDeadline);
    }

    /**
     * @notice Set the callback gas limit for the strategy. Setting this value too low results in callback
     * execution failures which must be avoided. Setting this value too high
     * requires the user to provide a higher execution fee, which will ultimately be rebated if not used.
     * A configured limit prevents the owner from setting a large callback limit to prevent orders from being placed.
     * @param newCallbackGasLimit The callback gas limit to provide for all orders.
     */
    function setCallbackGasLimit(
        uint256 newCallbackGasLimit
    ) external override onlyOwner {
        _setCallbackGasLimit(newCallbackGasLimit);
    }

    /**
     * @notice Set the execution fee buffer percentage for the strategy. This is the percentage of the initially
     * calculated execution fee that needs to be provided additionally to prevent orders from failing execution.
     * The value of the execution fee buffer percentage should account for possible shifts in gas price between
     * order creation and keeper execution. A higher value will result in a higher execution fee being required
     * by the user. As such, a configured maximum value is checked against when setting this configuration variable
     * to prevent the owner from setting a high fee that prevents accounts from creating orders.
     * @param newExecutionFeeBufferPercent The new execution fee buffer percentage.
     */
    function setExecutionFeeBufferPercent(
        uint256 newExecutionFeeBufferPercent
    ) external override onlyOwner {
        _setExecutionFeeBufferPercent(newExecutionFeeBufferPercent);
    }

    /**
     * @notice Set the referral code to use for all orders.
     * @param newReferralCode The new referral code to use for all orders.
     */
    function setReferralCode(
        bytes32 newReferralCode
    ) external override onlyOwner {
        _setReferralCode(newReferralCode);
    }

    /**
     * @notice Set the ui fee receiver to use for all orders.
     * @param newUiFeeReceiver The new ui fee receiver to use for all orders.
     */
    function setUiFeeReceiver(
        address newUiFeeReceiver
    ) external override onlyOwner {
        _setUiFeeReceiver(newUiFeeReceiver);
    }

    /**
     * @notice Sets the withdrawal buffer percentage. There is a configured minimum to prevent the owner from allowing accounts
     * to withdraw funds that bring the account's value below the loan. There is no maximum because it may be neccesary in
     * extreme circumstances for the owner to disable withdrawals while a loan is active by setting a higher limit.
     * It is always possible to withdraw funds once the loan is repaid, so this does not lock user funds permanantly.
     * A `withdrawalBufferPercentage` of 1.1e18 (110%) implies that the value of an account after withdrawing funds
     * must be greater than the `1.1 * loan` for a given account.
     * @param newWithdrawalBufferPercentage The new withdrawal buffer percentage.
     */
    function setWithdrawalBufferPercentage(
        uint256 newWithdrawalBufferPercentage
    ) external override onlyOwner {
        _setWithdrawalBufferPercentage(newWithdrawalBufferPercentage);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position is the index of the value in the `values` array plus 1.
        // Position 0 is used to mean a value is not in the set.
        mapping(bytes32 value => uint256) _positions;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We cache the value's position to prevent multiple reads from the same storage slot
        uint256 position = set._positions[value];

        if (position != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the lastValue to the index where the value to delete is
                set._values[valueIndex] = lastValue;
                // Update the tracked position of the lastValue (that was just moved)
                set._positions[lastValue] = position;
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the tracked position for the deleted slot
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._positions[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    Ownable2StepUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

import { Errors } from "../libraries/Errors.sol";

/**
 * @title GoldLinkOwnableUpgradeable
 * @author GoldLink
 *
 * @dev Ownable contract that requires new owner to accept, and disallows renouncing ownership.
 */
abstract contract GoldLinkOwnableUpgradeable is Ownable2StepUpgradeable {
    // ============ Public Functions ============

    function renounceOwnership() public view override onlyOwner {
        revert(Errors.CANNOT_RENOUNCE_OWNERSHIP);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { IMarketConfiguration } from "../interfaces/IMarketConfiguration.sol";
import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";
import { Limits } from "../libraries/Limits.sol";

/**
 * @title GmxV2Configuration
 * @author GoldLink
 *
 * @dev Storage related to GMX market configurations.
 */
abstract contract MarketConfigurationManager is
    IMarketConfiguration,
    Initializable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ Storage Variables ============

    /// @dev Set of available markets.
    EnumerableSet.AddressSet private markets_;

    /// @dev Mapping of markets to their Pricing Parameters
    mapping(address => OrderPricingParameters) private marketPricingParameters_;

    /// @dev Mapping of markets to their Position Parameters
    mapping(address => PositionParameters) private marketPositionParameters_;

    /// @dev Mapping of markets to their Unwind Parameters
    mapping(address => UnwindParameters) private marketUnwindParameters_;

    /// @dev Mapping of assets to their liquidation fee percent. Percents are denoted with 1e18 is 100%.
    mapping(address => uint256) private assetLiquidationFeePercent_;

    /// @dev Liquidation order timeout deadline.
    uint256 private liquidationOrderTimeoutDeadline_;

    /// @dev The minimum callback gas limit passed in. This prevents users from forcing the callback to run out of gas
    // and disrupting the contract's state, as it relies on the callback being executed.
    uint256 private callbackGasLimit_;

    /// @dev The minimum execution fee buffer percentage required to be provided by the user. This is the percentage of the initially calculated execution fee
    // that needs to be provided additionally to prevent orders from failing execution.
    uint256 private executionFeeBufferPercent_;

    /// @dev Gmx V2 referral address to use for orders.
    bytes32 private referralCode_;

    /// @dev UI fee receiver address.
    address private uiFeeReceiver_;

    /// @dev The minimum percentage above an account's loan that the value must be above when withdrawing.
    /// To disable withdrawls while a loan is active (funds can always be withdrawn when a loan is inactive),
    /// set to max uint256.
    uint256 private withdrawalBufferPercentage_;

    /**
     * @dev This is empty reserved space intended to allow future versions of this upgradeable
     *  contract to define new variables without shifting down storage in the inheritance chain.
     *  See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[39] private __gap;

    // ============ Initializer ============

    function __MarketConfigurationManager_init(
        SharedOrderParameters calldata sharedOrderParameters,
        uint256 liquidationOrderTimeDeadline
    ) internal onlyInitializing {
        __MarketConfigurationManager_init_unchained(
            sharedOrderParameters,
            liquidationOrderTimeDeadline
        );
    }

    function __MarketConfigurationManager_init_unchained(
        SharedOrderParameters calldata sharedOrderParameters,
        uint256 liquidationOrderTimeDeadline
    ) internal onlyInitializing {
        _setCallbackGasLimit(sharedOrderParameters.callbackGasLimit);
        _setExecutionFeeBufferPercent(
            sharedOrderParameters.executionFeeBufferPercent
        );
        _setReferralCode(sharedOrderParameters.referralCode);
        _setUiFeeReceiver(sharedOrderParameters.uiFeeReceiver);
        _setLiquidationOrderTimeoutDeadline(liquidationOrderTimeDeadline);
        _setWithdrawalBufferPercentage(
            sharedOrderParameters.withdrawalBufferPercentage
        );
    }

    // ============ External Functions ============

    /**
     * @notice Get the unwind configuration for a specific market.
     * @param market                  The market to get the unwind configuration for.
     * @return marketUnwindParameters The market specific parameters for unwinding a position.
     */
    function getMarketUnwindConfiguration(
        address market
    ) external view returns (UnwindParameters memory marketUnwindParameters) {
        return marketUnwindParameters_[market];
    }

    /**
     * @notice Get the asset liquidation fee percent for the specified asset. Percents are denoted with 1e18 is 100%.
     * @param asset                  The asset to get the liquidation fee percent for.
     * @return liquidationFeePercent The liquidation fee percent for a specific asset.
     */
    function getAssetLiquidationFeePercent(
        address asset
    ) external view returns (uint256 liquidationFeePercent) {
        return assetLiquidationFeePercent_[asset];
    }

    /**
     * @notice Get the configured liquidation order timeout deadline.
     * @return liquidationOrderTimeoutDeadline The time after which a liquidation order can be canceled.
     */
    function getLiquidationOrderTimeoutDeadline()
        external
        view
        returns (uint256 liquidationOrderTimeoutDeadline)
    {
        return liquidationOrderTimeoutDeadline_;
    }

    /**
     * @notice Get the configured callback gas limit.
     * @return callbackGasLimit The gas limit on a callback, how much gas a callback can cost.
     */
    function getCallbackGasLimit()
        external
        view
        returns (uint256 callbackGasLimit)
    {
        return callbackGasLimit_;
    }

    /**
     * @notice Get the configured execution fee buffer percentage.
     * @return executionFeeBufferPercent The percentage of the initially calculated execution fee that needs to be provided additionally
     * to prevent orders from failing execution.
     */
    function getExecutionFeeBufferPercent()
        external
        view
        returns (uint256 executionFeeBufferPercent)
    {
        return executionFeeBufferPercent_;
    }

    /**
     * @notice Get the configured referral code.
     * @return referralCode The code applied to all orders for the strategy, tying orders back to
     * this protocol.
     */
    function getReferralCode() external view returns (bytes32 referralCode) {
        return referralCode_;
    }

    /**
     * @notice Get the configured UI fee receiver.
     * @return uiFeeReceiver The fee paid to the UI, this protocol for placing orders.
     */
    function getUiFeeReceiver() external view returns (address uiFeeReceiver) {
        return uiFeeReceiver_;
    }

    /**
     * @notice Get the configured minimumWithdrawalBufferPercentage.
     * @return percentage The current withdrawalBufferPercentage.
     */
    function getProfitWithdrawalBufferPercent()
        external
        view
        returns (uint256 percentage)
    {
        return withdrawalBufferPercentage_;
    }

    // ============ Public Functions ============

    /**
     * @notice Get the configuration information for a specific market.
     * @param market               The market to get the configuration for.
     * @return marketConfiguration The configuration for a specific market.
     */
    function getMarketConfiguration(
        address market
    )
        public
        view
        override
        returns (MarketConfiguration memory marketConfiguration)
    {
        return
            MarketConfiguration({
                orderPricingParameters: marketPricingParameters_[market],
                sharedOrderParameters: SharedOrderParameters({
                    callbackGasLimit: callbackGasLimit_,
                    executionFeeBufferPercent: executionFeeBufferPercent_,
                    referralCode: referralCode_,
                    uiFeeReceiver: uiFeeReceiver_,
                    withdrawalBufferPercentage: withdrawalBufferPercentage_
                }),
                positionParameters: marketPositionParameters_[market],
                unwindParameters: marketUnwindParameters_[market]
            });
    }

    /**
     * @notice Check whether or not a market address is approved for the strategy.
     * @param market      The market to recieve the approval status for.
     * @return isApproved If the market is approved for the strategy.
     */
    function isApprovedMarket(
        address market
    ) public view returns (bool isApproved) {
        return markets_.contains(market);
    }

    /**
     * @notice Get all available markets for the strategy.
     * @return markets The markets supported for this strategy. All markets that delta-neutral positions
     * can be placed on for this strategy.
     */
    function getAvailableMarkets()
        public
        view
        override
        returns (address[] memory markets)
    {
        return markets_.values();
    }

    // ============ Internal Functions ============

    /**
     * @notice Set the configuration for a specific market.
     * @dev Emits the `MarketConfigurationSet()` event.
     * @param orderPricingParams The parameters dictating pricing for the market.
     * @param positionParams     The parameters dictating establishing/maintaining a position for
     * the market.
     * @param unwindParameters   The parameters dictating when a position can be unwound for the market.
     */
    function _setMarketConfiguration(
        address market,
        OrderPricingParameters memory orderPricingParams,
        PositionParameters memory positionParams,
        UnwindParameters memory unwindParameters
    ) internal {
        // Make sure we are not exceeding maximum market count.
        require(
            markets_.contains(market) ||
                markets_.length() < Limits.MAX_MARKET_COUNT,
            GmxFrfStrategyErrors.MARKETS_COUNT_CANNOT_EXCEED_MAXIMUM
        );

        // Validate order and position parameters.
        _validateOrderPricingParameters(orderPricingParams);
        _validatePositionParameters(positionParams);
        _validateUnwindParameters(unwindParameters);

        // Add market to registered markets.
        markets_.add(market);

        // Set all new market parameters.
        marketPricingParameters_[market] = orderPricingParams;
        marketPositionParameters_[market] = positionParams;
        marketUnwindParameters_[market] = unwindParameters;

        emit MarketConfigurationSet(
            market,
            orderPricingParams,
            positionParams,
            unwindParameters
        );
    }

    /**
     * @notice Set the asset liquidation fee percent for a specific asset. There is a maximum fee
     * of 10% (1e17) to prevent a bad owner from stealing all assets in an account.
     * @dev Emits the `AssetLiquidationFeeSet()` event.
     * @param asset                    The asset to set the liquidation fee for.
     * @param newLiquidationFeePercent The fee percentage that is paid to liquidators when selling this asset.
     */
    function _setAssetLiquidationFeePercent(
        address asset,
        uint256 newLiquidationFeePercent
    ) internal {
        require(
            newLiquidationFeePercent <=
                Limits.MAXIMUM_ASSET_LIQUIDATION_FEE_PERCENT,
            GmxFrfStrategyErrors
                .ASSET_LIQUIDATION_FEE_CANNOT_BE_GREATER_THAN_MAXIMUM
        );
        assetLiquidationFeePercent_[asset] = newLiquidationFeePercent;
        emit AssetLiquidationFeeSet(asset, newLiquidationFeePercent);
    }

    /**
     * @notice Set the liquidation order timeout deadline, which is the amount of time that must pass before
     * a liquidation order can be cancelled.
     * @dev Emits the `LiquidationOrderTimeoutDeadlineSet()` event.
     * @param newLiquidationOrderTimeoutDeadline The new liquidation order timeout to use for all liquidation orders.
     */
    function _setLiquidationOrderTimeoutDeadline(
        uint256 newLiquidationOrderTimeoutDeadline
    ) internal {
        liquidationOrderTimeoutDeadline_ = newLiquidationOrderTimeoutDeadline;
        emit LiquidationOrderTimeoutDeadlineSet(
            newLiquidationOrderTimeoutDeadline
        );
    }

    /**
     * @notice Set the callback gas limit for the strategy. Setting this value too low results in callback
     * execution failures which must be avoided. Setting this value too high
     * requires the user to provide a higher execution fee, which will ultimately be rebated if not used.
     * A configured limit prevents the owner from setting a large callback limit to prevent orders from being placed.
     * @dev Emits the `CallbackGasLimitSet()` event.
     * @param newCallbackGasLimit The callback gas limit to provide for all orders.
     */
    function _setCallbackGasLimit(uint256 newCallbackGasLimit) internal {
        require(
            newCallbackGasLimit <= Limits.MAXIMUM_CALLBACK_GAS_LIMIT,
            GmxFrfStrategyErrors
                .CANNOT_SET_THE_CALLBACK_GAS_LIMIT_ABOVE_THE_MAXIMUM
        );
        callbackGasLimit_ = newCallbackGasLimit;
        emit CallbackGasLimitSet(newCallbackGasLimit);
    }

    /**
     * @notice Set the execution fee buffer percentage for the strategy. This is the percentage of the initially
     * calculated execution fee that needs to be provided additionally to prevent orders from failing execution.
     * The value of the execution fee buffer percentage should account for possible shifts in gas price between
     * order creation and keeper execution. A higher value will result in a higher execution fee being required
     * by the user. As such, a configured maximum value is checked against when setting this configuration variable
     * to prevent the owner from setting a high fee that prevents accounts from creating orders.
     * @dev Emits the `ExecutionFeeBufferPercentSet()` event.
     * @param newExecutionFeeBufferPercent The new execution fee buffer percentage.
     */
    function _setExecutionFeeBufferPercent(
        uint256 newExecutionFeeBufferPercent
    ) internal {
        require(
            newExecutionFeeBufferPercent <=
                Limits.MAXIMUM_EXECUTION_FEE_BUFFER_PERCENT,
            GmxFrfStrategyErrors
                .CANNOT_SET_THE_EXECUTION_FEE_BUFFER_ABOVE_THE_MAXIMUM
        );
        executionFeeBufferPercent_ = newExecutionFeeBufferPercent;
        emit ExecutionFeeBufferPercentSet(newExecutionFeeBufferPercent);
    }

    /**
     * @notice Set the referral code to use for all orders.
     * @dev Emits the `ReferralCodeSet()` event.
     * @param newReferralCode The new referral code to use for all orders.
     */
    function _setReferralCode(bytes32 newReferralCode) internal {
        referralCode_ = newReferralCode;
        emit ReferralCodeSet(newReferralCode);
    }

    /**
     * @notice Set the ui fee receiver to use for all orders.
     * @dev Emits the `UiFeeReceiverSet()` event.
     * @param newUiFeeReceiver The new ui fee receiver to use for all orders.
     */
    function _setUiFeeReceiver(address newUiFeeReceiver) internal {
        require(
            newUiFeeReceiver != address(0),
            GmxFrfStrategyErrors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );

        uiFeeReceiver_ = newUiFeeReceiver;
        emit UiFeeReceiverSet(newUiFeeReceiver);
    }

    /**
     * @notice Sets the withdrawal buffer percentage. There is a configured minimum to prevent the owner from allowing accounts
     * to withdraw funds that bring the account's value below the loan. There is no maximum because it may be neccesary in
     * extreme circumstances for the owner to disable withdrawals while a loan is active by setting a higher limit.
     * It is always possible to withdraw funds once the loan is repaid, so this does not lock user funds permanantly.
     * A `withdrawalBufferPercentage` of 1.1e18 (110%) implies that the value of an account after withdrawing funds
     * must be greater than the `1.1 * loan` for a given account.
     * @dev Emits the `WithdrawalBufferPercentageSet()` event.
     * @param newWithdrawalBufferPercentage The new withdrawal buffer percentage.
     */
    function _setWithdrawalBufferPercentage(
        uint256 newWithdrawalBufferPercentage
    ) internal {
        require(
            newWithdrawalBufferPercentage >=
                Limits.MINIMUM_WITHDRAWAL_BUFFER_PERCENT,
            GmxFrfStrategyErrors
                .WITHDRAWAL_BUFFER_PERCENTAGE_MUST_BE_GREATER_THAN_THE_MINIMUM
        );
        withdrawalBufferPercentage_ = newWithdrawalBufferPercentage;
        emit WithdrawalBufferPercentageSet(newWithdrawalBufferPercentage);
    }

    // ============ Private Functions ============

    /**
     * @notice Validate order pricing parameters, making sure parameters are internally consistent,
     * i.e. minimum order size does not exceed maximum.
     *  @param orderPricingParameters The order pricing parameters being validated.
     */
    function _validateOrderPricingParameters(
        OrderPricingParameters memory orderPricingParameters
    ) private pure {
        // It is important to note that no `decreaseDisabled` parameter is present. This is because
        // the owner of the GmxFrFStrategyManager contract should never be able to prevent accounts from closing positions.
        // However, in the event the market is either compromised or being winded down, it may be neccesary to disable increase orders
        // to mitigate protocol risk.

        // The `maxSwapSlippagePercent` must be validated to ensure the configured value is not too low such that it prevents any swaps from being executed.
        // Otherwise, the owner can effectively prevent all orders from being executed.
        require(
            orderPricingParameters.maxSwapSlippagePercent >=
                Limits.MINIMUM_MAX_SWAP_SLIPPAGE_PERCENT,
            GmxFrfStrategyErrors
                .CANNOT_SET_MAX_SWAP_SLIPPAGE_BELOW_MINIMUM_VALUE
        );

        // Similarly, the `maxPositionSlippagePercent` needs to be validated to prevent the owner from setting the number so low that
        // it prevents position decreases.
        require(
            orderPricingParameters.maxPositionSlippagePercent >=
                Limits.MINIMUM_MAX_POSITION_SLIPPAGE_PERCENT,
            GmxFrfStrategyErrors
                .CANNOT_SET_MAX_POSITION_SLIPPAGE_BELOW_MINIMUM_VALUE
        );

        // It is not possible for the owner of the contract to manipulate these configured parameters
        // to make it impossible to close a position, because the order logic itself when winding down a
        // position disregards order minimums if the position is being fully closed.
        require(
            orderPricingParameters.minOrderSizeUsd <=
                orderPricingParameters.maxOrderSizeUsd,
            GmxFrfStrategyErrors
                .MARKET_CONFIGURATION_MANAGER_MIN_ORDER_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_ORDER_SIZE
        );
    }

    /**
     * @notice Validate position parameters, making sure parameters are internally consistent,
     * i.e. minimum position size does not exceed maximum.
     * @param positionParameters The position parameters being validated.
     */
    function _validatePositionParameters(
        PositionParameters memory positionParameters
    ) private pure {
        require(
            positionParameters.minPositionSizeUsd <=
                positionParameters.maxPositionSizeUsd,
            GmxFrfStrategyErrors
                .MARKET_CONFIGURATION_MANAGER_MIN_POSITION_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_POSITION_SIZE
        );
    }

    /**
     * @notice Validate unwind parameters, making sure the owner of the contract cannot forcibly prevent and/or force liquidations.
     * @param unwindParameters The unwind parameters to validate.
     */
    function _validateUnwindParameters(
        UnwindParameters memory unwindParameters
    ) private pure {
        // The `minSwapRebalanceSize` does not need to be validated, because it's configured value becomes 'more extreme'
        // as it approaches 0, which is an acceptable value. Furthermore, this number represents a fixed token amount,
        // which varies depending on token decimals.

        // The `maxDeltaProportion` must be validated to prevent the owner of the contract from reducing the value and
        // profiting from rebalancing accounts. Furthermore, the number must be greater than 1 to function properly.
        require(
            unwindParameters.maxDeltaProportion >=
                Limits.MINIMUM_MAX_DELTA_PROPORTION_PERCENT,
            GmxFrfStrategyErrors
                .MAX_DELTA_PROPORTION_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE
        );

        // The `maxPositionLeverage` must be validated to ensure the owner of the `GmxFrfManager` contract does not set a small configured value, as this can
        // allow positions to be releveraged unexpectedly, resulting in fees. Furthermore, if this number is too high, it puts positions at risk of
        // liquidation on GMX.
        require(
            unwindParameters.maxPositionLeverage >=
                Limits.MINIMUM_MAX_POSITION_LEVERAGE_PERCENT,
            GmxFrfStrategyErrors
                .MAX_POSITION_LEVERAGE_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE
        );

        // The `unwindFee` must be validated so that the owner cannot forcibly take a sizeable portion of a position's value.
        require(
            unwindParameters.unwindFee <= Limits.MAXIMUM_UNWIND_FEE_PERCENT,
            GmxFrfStrategyErrors.UNWIND_FEE_IS_ABOVE_THE_MAXIMUM_ALLOWED_VALUE
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IWrappedNativeToken
} from "../../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import {
    IGmxV2PositionTypes
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2RoleStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2RoleStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import {
    IWrappedNativeToken
} from "../../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import {
    IDeploymentConfiguration
} from "../interfaces/IDeploymentConfiguration.sol";
import { GmxFrfStrategyErrors } from "../GmxFrfStrategyErrors.sol";
import {
    IGmxV2ExchangeRouter
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ExchangeRouter.sol";
import { ISwapCallbackRelayer } from "../interfaces/ISwapCallbackRelayer.sol";
import { SwapCallbackRelayer } from "../SwapCallbackRelayer.sol";

/**
 * @title DeploymentConfigurationManager
 * @author GoldLink
 *
 * @dev Manages the deployment configuration for the GMX V2.
 */
abstract contract DeploymentConfigurationManager is
    IDeploymentConfiguration,
    Initializable
{
    // ============ Constants ============

    /// @notice Usdc token address.
    IERC20 public immutable USDC;

    /// @notice Wrapped native ERC20 token address.
    IWrappedNativeToken public immutable WRAPPED_NATIVE_TOKEN;

    /// @notice Callback Relayer address for swap callback security.
    ISwapCallbackRelayer public immutable SWAP_CALLBACK_RELAYER;

    /// @notice The collateral claim distributor address. In the event that the GMX team
    /// issues a collateral stipend and the account was liquidated after, this address will
    /// receive it and subsequently be responsible for distributing it.
    address public immutable COLLATERAL_CLAIM_DISTRIBUTOR;

    // ============ Storage Variables ============

    /// @dev GMX V2 ExchangeRouter.
    IGmxV2ExchangeRouter private gmxV2ExchangeRouter_;

    /// @dev GMX V2 order vault address.
    address private gmxV2OrderVault_;

    /// @dev GMX V2 `Reader` deployment address.
    IGmxV2Reader private gmxV2Reader_;

    /// @dev GMX V2 `DataStore` deployment address.
    IGmxV2DataStore private gmxV2DataStore_;

    /// @dev GMX V2 `RoleStore` deployment address.
    IGmxV2RoleStore private gmxV2RoleStore_;

    /// @dev Gmx V2 `ReferralStorage` deployment address.
    IGmxV2ReferralStorage private gmxV2ReferralStorage_;

    /**
     * @dev This is empty reserved space intended to allow future versions of this upgradeable
     *  contract to define new variables without shifting down storage in the inheritance chain.
     *  See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;

    // ============ Modifiers ============

    /// @dev Verify the address is not the zero address.
    modifier onlyNonZeroAddress(address addressToCheck) {
        require(
            addressToCheck != address(0),
            GmxFrfStrategyErrors.ZERO_ADDRESS_IS_NOT_ALLOWED
        );
        _;
    }

    // ============ Constructor ============

    /**
     * @notice Constructor for upgradeable contract, distinct from initializer.
     *
     *  The constructor is used to set immutable variables, and for top-level upgradeable
     *  contracts, it is also used to disable the initializer of the logic contract.
     */
    constructor(
        IERC20 _usdc,
        IWrappedNativeToken _wrappedNativeToken,
        address _collateralClaimDistributor
    )
        onlyNonZeroAddress(address(_usdc))
        onlyNonZeroAddress(address(_wrappedNativeToken))
        onlyNonZeroAddress(_collateralClaimDistributor)
    {
        USDC = _usdc;
        WRAPPED_NATIVE_TOKEN = _wrappedNativeToken;
        COLLATERAL_CLAIM_DISTRIBUTOR = _collateralClaimDistributor;
        SWAP_CALLBACK_RELAYER = ISwapCallbackRelayer(new SwapCallbackRelayer());
    }

    // ============ Initializer ============

    function __DeploymentConfigurationManager_init(
        Deployments calldata deployments
    ) internal onlyInitializing {
        __DeploymentConfigurationManager_init_unchained(deployments);
    }

    function __DeploymentConfigurationManager_init_unchained(
        Deployments calldata deployments
    ) internal onlyInitializing {
        _setExchangeRouter(deployments.exchangeRouter);
        _setOrderVault(deployments.orderVault);
        _setReader(deployments.reader);
        _setDataStore(deployments.dataStore);
        _setRoleStore(deployments.roleStore);
        _setReferralStorage(deployments.referralStorage);
    }

    // ============ Public Functions ============

    /**
     * @notice Get the cached deployment address for the GMX V2 ExchangeRouter.
     * @return gmxV2ExchangeRouter The deployment address for the GMX V2 ExchangeRouter.
     */
    function gmxV2ExchangeRouter()
        public
        view
        override
        returns (IGmxV2ExchangeRouter)
    {
        return gmxV2ExchangeRouter_;
    }

    /**
     * @notice Get the cached deployment address for the GMX V2 OrderVault.
     * @return gmxV2OrderVault The deployment address for the GMX V2 OrderVault.
     */
    function gmxV2OrderVault() public view override returns (address) {
        return gmxV2OrderVault_;
    }

    /**
     * @notice Get the cached deployment address for the GMX V2 Reader.
     * @return gmxV2Reader The deployment address for the GMX V2 Reader.
     */
    function gmxV2Reader() public view override returns (IGmxV2Reader) {
        return gmxV2Reader_;
    }

    /**
     * @notice Get the cached deployment address for the GMX V2 DataStore.
     * @return gmxV2DataStore The deployment address for the GMX V2 DataStore.
     */
    function gmxV2DataStore() public view override returns (IGmxV2DataStore) {
        return gmxV2DataStore_;
    }

    /**
     * @notice Get the cached deployment address for the GMX V2 RoleStore.
     * @return gmxV2RoleStore The deployment address for the GMX V2 RoleStore.
     */
    function gmxV2RoleStore() public view override returns (IGmxV2RoleStore) {
        return gmxV2RoleStore_;
    }

    /**
     * @notice Get the cached deployment address for the GMX V2 ReferralStorage.
     * @return gmxV2ReferralStorage The deployment address for the GMX V2 ReferralStorage.
     */
    function gmxV2ReferralStorage()
        public
        view
        override
        returns (IGmxV2ReferralStorage)
    {
        return gmxV2ReferralStorage_;
    }

    // ============ Internal Functions ============

    /**
     * @notice Set the ExchangeRouter address for Gmx V2. Care should be taken when setting the ExchangeRouter address to ensure the strategy implementation is compatible.
     * @dev Emits the `ExchangeRouterSet()` event.
     * @param newExchangeRouter The deployment address for the GMX V2 ExchangeRouter.
     */
    function _setExchangeRouter(
        IGmxV2ExchangeRouter newExchangeRouter
    ) internal onlyNonZeroAddress(address(newExchangeRouter)) {
        gmxV2ExchangeRouter_ = newExchangeRouter;

        emit ExchangeRouterSet(address(newExchangeRouter));
    }

    /**
     * @notice Set the OrderVault address for Gmx V2. Care should be taken when setting the OrderVault address to ensure the strategy implementation is compatible.
     * @dev Emits the `OrderVaultSet()` event.
     * @param newOrderVault The deployment address for the GMX V2 OrderVault.
     */
    function _setOrderVault(
        address newOrderVault
    ) internal onlyNonZeroAddress(newOrderVault) {
        gmxV2OrderVault_ = newOrderVault;

        emit OrderVaultSet(newOrderVault);
    }

    /**
     * @notice Set the Reader address for Gmx V2. Care should be taken when setting the Reader address to ensure the strategy implementation is compatible.
     * @dev Emits the `ReaderSet()` event.
     * @param newReader The deployment address for the GMX V2 Reader.
     */
    function _setReader(
        IGmxV2Reader newReader
    ) internal onlyNonZeroAddress(address(newReader)) {
        gmxV2Reader_ = newReader;

        emit ReaderSet(address(newReader));
    }

    /**
     * @notice Set the DataStore address for Gmx V2. Care should be taken when setting the DataStore address to ensure the strategy implementation is compatible.
     * @dev Emits the `DataStoreSet()` event.
     * @param newDataStore The deployment address for the GMX V2 DataStore.
     */
    function _setDataStore(
        IGmxV2DataStore newDataStore
    ) internal onlyNonZeroAddress(address(newDataStore)) {
        gmxV2DataStore_ = newDataStore;

        emit DataStoreSet(address(newDataStore));
    }

    /**
     * @notice Set the RoleStore address for Gmx V2. Care should be taken when setting the RoleStore address to ensure the strategy implementation is compatible.
     * @dev Emits the `RoleStoreSet()` event.
     * @param newRoleStore The deployment address for the GMX V2 RoleStore.
     */
    function _setRoleStore(
        IGmxV2RoleStore newRoleStore
    ) internal onlyNonZeroAddress(address(newRoleStore)) {
        gmxV2RoleStore_ = newRoleStore;

        emit RoleStoreSet(address(newRoleStore));
    }

    /**
     * @notice Set the ReferralStorage address for Gmx V2. Care should be taken when setting the ReferralStorage address to ensure the strategy implementation is compatible.
     * @dev Emits the `ReferralStorageSet()` event.
     * @param newReferralStorage The deployment address for the GMX V2 ReferralStorage.
     */
    function _setReferralStorage(
        IGmxV2ReferralStorage newReferralStorage
    ) internal onlyNonZeroAddress(address(newReferralStorage)) {
        gmxV2ReferralStorage_ = newReferralStorage;

        emit ReferralStorageSet(address(newReferralStorage));
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IChainlinkAggregatorV3 } from "./external/IChainlinkAggregatorV3.sol";

/**
 * @title IChainlinkAdapter
 * @author GoldLink
 *
 * @dev Oracle registry interface for registering and retrieving price feeds for assets using chainlink oracles.
 */
interface IChainlinkAdapter {
    // ============ Structs ============

    /// @dev Struct to hold the configuration for an oracle.
    struct OracleConfiguration {
        // The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
        uint256 validPriceDuration;
        // The address of the chainlink oracle to fetch prices from.
        IChainlinkAggregatorV3 oracle;
    }

    // ============ Events ============

    /// @notice Emitted when registering an oracle for an asset.
    /// @param asset              The address of the asset whose price oracle is beig set.
    /// @param oracle             The address of the price oracle for the asset.
    /// @param validPriceDuration The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
    event AssetOracleRegistered(
        address indexed asset,
        IChainlinkAggregatorV3 indexed oracle,
        uint256 validPriceDuration
    );

    /// @notice Emitted when removing a price oracle for an asset.
    /// @param asset The asset whose price oracle is being removed.
    event AssetOracleRemoved(address indexed asset);

    // ============ External Functions ============

    /// @dev Get the price of an asset.
    function getAssetPrice(
        address asset
    ) external view returns (uint256 price, uint256 oracleDecimals);

    /// @dev Get the oracle registered for a specific asset.
    function getAssetOracle(
        address asset
    ) external view returns (IChainlinkAggregatorV3 oracle);

    /// @dev Get the oracle configuration for a specific asset.
    function getAssetOracleConfiguration(
        address asset
    )
        external
        view
        returns (IChainlinkAggregatorV3 oracle, uint256 validPriceDuration);

    /// @dev Get all assets registered with oracles in this adapter.
    function getRegisteredAssets()
        external
        view
        returns (address[] memory registeredAssets);
}

// SPDX-License-Identifier: MIT
//
// Adapted from https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol

pragma solidity 0.8.20;

interface IChainlinkAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { ChainlinkErrors } from "./ChainlinkErrors.sol";
import { IChainlinkAdapter } from "./interfaces/IChainlinkAdapter.sol";
import {
    IChainlinkAggregatorV3
} from "./interfaces/external/IChainlinkAggregatorV3.sol";
import { GoldLinkOwnable } from "../../utils/GoldLinkOwnable.sol";
import {
    Initializable
} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title OracleAssetRegistry
 * @author GoldLink
 *
 * @notice Handles all registered assets for a given oracle.
 *
 */
abstract contract OracleAssetRegistry is IChainlinkAdapter, Initializable {
    using EnumerableSet for EnumerableSet.AddressSet;

    // ============ Storage Variables ============

    /// @dev Mapping of asset addresses to their corresponding oracle configurations.
    mapping(address => IChainlinkAdapter.OracleConfiguration)
        internal assetToOracle_;

    /// @dev Set containing registered assets. Used to provide a set of assets with registered oracles.
    EnumerableSet.AddressSet internal registeredAssets_;

    /**
     * @dev This is empty reserved space intended to allow future versions of this upgradeable
     *  contract to define new variables without shifting down storage in the inheritance chain.
     *  See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    // ============ Initializer ============

    function __OracleAssetRegistry_init(
        address strategyAsset,
        OracleConfiguration memory strategyAssetConfig
    ) internal onlyInitializing {
        __OracleAssetRegistry_init_unchained(
            strategyAsset,
            strategyAssetConfig
        );
    }

    function __OracleAssetRegistry_init_unchained(
        address strategyAsset,
        OracleConfiguration memory strategyAssetConfig
    ) internal onlyInitializing {
        _setAssetOracle(
            strategyAsset,
            strategyAssetConfig.oracle,
            strategyAssetConfig.validPriceDuration
        );
    }

    // ============ External Functions ============

    /**
     * @notice Get the price for an asset.
     * @param asset     The asset to fetch the price for. Must have a valid oracle, and the oracle's last update must be within the valid price duration.
     * @return price    The price for the asset with `decimals` amount of precision.
     * @return decimals The amount of decimals used by the oracle to represent the price of the asset / asset pair.
     */
    function getAssetPrice(
        address asset
    ) public view override returns (uint256 price, uint256 decimals) {
        return _getAssetPrice(asset);
    }

    /**
     * @notice Get the oracle address corresponding to the provided `asset`. If no oracle exists, the returned oracle address will be the zero address.
     * @param asset   The asset whose oracle is being fetched.
     * @return oracle The `IChainlinkAggregatorV3` oracle corresponding to the provided `asset`.
     */
    function getAssetOracle(
        address asset
    ) public view returns (IChainlinkAggregatorV3 oracle) {
        return assetToOracle_[asset].oracle;
    }

    /**
     * @notice Get the oracle configuration for an asset.
     * @param asset    The asset to get the oracle configuration for.
     * @return oracle  The `IChainlinkAggregatorV3` oracle corresponding to the provided `asset`.
     * @return validPriceDuration The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
     */
    function getAssetOracleConfiguration(
        address asset
    )
        public
        view
        returns (IChainlinkAggregatorV3 oracle, uint256 validPriceDuration)
    {
        OracleConfiguration memory config = assetToOracle_[asset];

        return (config.oracle, config.validPriceDuration);
    }

    /**
     * @notice Get all registered assets, the assets with oracles for this contract.
     * @return assets The array of all registered assets.
     */
    function getRegisteredAssets()
        external
        view
        returns (address[] memory assets)
    {
        return registeredAssets_.values();
    }

    // ============ Internal Functions ============

    /**
     * @notice Sets the oracle configuration for the provided `asset`.
     * @dev Emits the `AssetOracleRegistered()` event.
     * @param asset  The asset that the correspond `IChainlinkAggregatorV3` provides a price feed for.
     * @param oracle The `IChainlinkAggregatorV3` that provides a price feed for the specified `asset`.
     * @param validPriceDuration The amount of time (seconds) since the last update of the oracle that the price is still considered valid.
     */
    function _setAssetOracle(
        address asset,
        IChainlinkAggregatorV3 oracle,
        uint256 validPriceDuration
    ) internal {
        require(asset != address(0), ChainlinkErrors.INVALID_ASSET_ADDRESS);

        require(
            address(oracle) != address(0),
            ChainlinkErrors.ORACLE_REGISTRY_INVALID_ORACLE
        );

        // Set the configuration for the asset oracle.
        assetToOracle_[asset] = OracleConfiguration({
            validPriceDuration: validPriceDuration,
            oracle: oracle
        });

        // Add the asset to the set of registered assets if it is not already registered.
        registeredAssets_.add(address(asset));

        emit AssetOracleRegistered(asset, oracle, validPriceDuration);
    }

    /**
     * @notice Remove the oracle for an asset, preventing prices for the oracle `asset` from being fetched.
     * @dev Emits the `AssetOracleRemoved()` event.
     * @param asset The asset to remove from the oracle registry.
     */
    function _removeAssetOracle(address asset) internal {
        // Don't do anything if the asset is not registered.
        if (!registeredAssets_.contains(asset)) {
            return;
        }

        // Remove the asset from the set of registered assets.
        registeredAssets_.remove(asset);

        // Delete the asset's oracle configuration.
        delete assetToOracle_[asset];

        emit AssetOracleRemoved(asset);
    }

    /**
     * @notice Get the price for an asset.
     * @param asset     The asset to fetch the price for. Must have a valid oracle, and the oracle's last update must be within the valid price duration.
     * @return price    The price for the asset with `decimals` amount of precision.
     * @return decimals The amount of decimals used by the oracle to represent the price of the asset / asset pair.
     */
    function _getAssetPrice(
        address asset
    ) internal view returns (uint256 price, uint256 decimals) {
        // Get the registered oracle for the asset, if it exists.
        OracleConfiguration memory oracleConfig = assetToOracle_[asset];

        // Make sure the oracle for this asset exists.
        require(
            oracleConfig.oracle != IChainlinkAggregatorV3(address(0)),
            ChainlinkErrors.ORACLE_REGISTRY_ASSET_NOT_FOUND
        );

        // Get the latest round data, which includes the price and the timestamp of the last oracle price update.
        // The timestamp is used to validate that the price is not stale.
        (, int256 oraclePrice, , uint256 timestamp, ) = oracleConfig
            .oracle
            .latestRoundData();

        // Prices that are less than or equal to zero should be considered invalid.
        require(
            oraclePrice > 0,
            ChainlinkErrors.ORACLE_REGISTRY_INVALID_ORACLE_PRICE
        );

        // Make sure the price is within the valid price duration.
        // This is an important step in retrieving the price, as it ensures that old oracle prices do not result in
        // inintended behavior / unfair asset pricing.
        require(
            block.timestamp - timestamp <= oracleConfig.validPriceDuration,
            ChainlinkErrors
                .ORACLE_REGISTRY_LAST_UPDATE_TIMESTAMP_EXCEEDS_VALID_TIMESTAMP_RANGE
        );

        return (
            SafeCast.toUint256(oraclePrice),
            oracleConfig.oracle.decimals()
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IMarketConfiguration } from "./IMarketConfiguration.sol";
import { IDeploymentConfiguration } from "./IDeploymentConfiguration.sol";
import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IGmxFrfStrategyManager
 * @author GoldLink
 *
 * @dev Interface for manager contract for configuration vars.
 */
interface IGmxFrfStrategyManager is
    IMarketConfiguration,
    IDeploymentConfiguration,
    IChainlinkAdapter
{}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IGmxV2OrderTypes
} from "../../../../lib/gmx/interfaces/external/IGmxV2OrderTypes.sol";
import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's ExchangeRouter.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/router/ExchangeRouter.sol
 */
interface IGmxV2ExchangeRouter {
    struct SimulatePricesParams {
        address[] primaryTokens;
        IGmxV2PriceTypes.Props[] primaryPrices;
    }

    function multicall(
        bytes[] calldata data
    ) external returns (bytes[] memory results);

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external payable;

    function sendNativeToken(address receiver, uint256 amount) external payable;

    function setSavedCallbackContract(
        address market,
        address callbackContract
    ) external payable;

    function cancelWithdrawal(bytes32 key) external payable;

    function createOrder(
        IGmxV2OrderTypes.CreateOrderParams calldata params
    ) external payable returns (bytes32);

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external payable;

    function cancelOrder(bytes32 key) external payable;

    function simulateExecuteOrder(
        bytes32 key,
        SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);

    function setUiFeeFactor(uint256 uiFeeFactor) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified version of https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/Reader.sol
// Modified as follows:
// - Using GoldLink types

pragma solidity ^0.8.0;

import {
    IGmxV2MarketTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2MarketTypes.sol";
import {
    IGmxV2PriceTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PriceTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import { IGmxV2OrderTypes } from "./IGmxV2OrderTypes.sol";
import {
    IGmxV2PositionTypes
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2PositionTypes.sol";
import {
    IGmxV2DataStore
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";

interface IGmxV2Reader {
    function getMarket(
        IGmxV2DataStore dataStore,
        address key
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getMarketBySalt(
        IGmxV2DataStore dataStore,
        bytes32 salt
    ) external view returns (IGmxV2MarketTypes.Props memory);

    function getPosition(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2PositionTypes.Props memory);

    function getOrder(
        IGmxV2DataStore dataStore,
        bytes32 key
    ) external view returns (IGmxV2OrderTypes.Props memory);

    function getPositionPnlUsd(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    ) external view returns (int256, int256, uint256);

    function getAccountPositions(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2PositionTypes.Props[] memory);

    function getAccountPositionInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32[] memory positionKeys,
        IGmxV2MarketTypes.MarketPrices[] memory prices,
        address uiFeeReceiver
    ) external view returns (IGmxV2PositionTypes.PositionInfo[] memory);

    function getPositionInfo(
        IGmxV2DataStore dataStore,
        IGmxV2ReferralStorage referralStorage,
        bytes32 positionKey,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (IGmxV2PositionTypes.PositionInfo memory);

    function getAccountOrders(
        IGmxV2DataStore dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2OrderTypes.Props[] memory);

    function getMarkets(
        IGmxV2DataStore dataStore,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.Props[] memory);

    function getMarketInfoList(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices[] memory marketPricesList,
        uint256 start,
        uint256 end
    ) external view returns (IGmxV2MarketTypes.MarketInfo[] memory);

    function getMarketInfo(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address marketKey
    ) external view returns (IGmxV2MarketTypes.MarketInfo memory);

    function getMarketTokenPrice(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        IGmxV2PriceTypes.Props memory longTokenPrice,
        IGmxV2PriceTypes.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, IGmxV2MarketTypes.PoolValueInfo memory);

    function getNetPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool maximize
    ) external view returns (int256);

    function getPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getOpenInterestWithPnl(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPnlToPoolFactor(
        IGmxV2DataStore dataStore,
        address marketAddress,
        IGmxV2MarketTypes.MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getSwapAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        address tokenIn,
        uint256 amountIn,
        address uiFeeReceiver
    )
        external
        view
        returns (uint256, int256, IGmxV2PriceTypes.SwapFees memory fees);

    function getExecutionPrice(
        IGmxV2DataStore dataStore,
        address marketKey,
        IGmxV2PriceTypes.Props memory indexTokenPrice,
        uint256 positionSizeInUsd,
        uint256 positionSizeInTokens,
        int256 sizeDeltaUsd,
        bool isLong
    ) external view returns (IGmxV2PriceTypes.ExecutionPriceResult memory);

    function getSwapPriceImpact(
        IGmxV2DataStore dataStore,
        address marketKey,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        IGmxV2PriceTypes.Props memory tokenInPrice,
        IGmxV2PriceTypes.Props memory tokenOutPrice
    ) external view returns (int256, int256);

    function getAdlState(
        IGmxV2DataStore dataStore,
        address market,
        bool isLong,
        IGmxV2MarketTypes.MarketPrices memory prices
    ) external view returns (uint256, bool, int256, uint256);

    function getDepositAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 longTokenAmount,
        uint256 shortTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256);

    function getWithdrawalAmountOut(
        IGmxV2DataStore dataStore,
        IGmxV2MarketTypes.Props memory market,
        IGmxV2MarketTypes.MarketPrices memory prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2DataStore
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Datastore.
 * Contract this is an interface for can be found here: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/data/DataStore.sol
 */
interface IGmxV2DataStore {
    // ============ External Functions ============

    function getAddress(bytes32 key) external view returns (address);

    function getUint(bytes32 key) external view returns (uint256);

    function getBool(bytes32 key) external view returns (bool);

    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function containsBytes32(
        bytes32 setKey,
        bytes32 value
    ) external view returns (bool);

    function getAddressArray(
        bytes32 key
    ) external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title IGmxV2RoleStore
 * @author GoldLink
 *
 * @dev Interface for the GMX role store.
 * Adapted from https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/role/RoleStore.sol
 */
interface IGmxV2RoleStore {
    function hasRole(
        address account,
        bytes32 roleKey
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

interface IGmxV2ReferralStorage {}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";

/**
 * @title IGmxV2EventUtilsTypes
 * @author GoldLink
 *
 * Types used by Gmx V2 for market information.
 * Adapted from these four files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/Market.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/market/MarketPoolValueInfo.sol
 */
interface IGmxV2MarketTypes {
    // ============ Enums ============

    enum FundingRateChangeType {
        NoChange,
        Increase,
        Decrease
    }

    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    struct MarketPrices {
        IGmxV2PriceTypes.Props indexTokenPrice;
        IGmxV2PriceTypes.Props longTokenPrice;
        IGmxV2PriceTypes.Props shortTokenPrice;
    }

    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    struct VirtualInventory {
        uint256 virtualPoolAmountForLongToken;
        uint256 virtualPoolAmountForShortToken;
        int256 virtualInventoryForPositions;
    }

    struct MarketInfo {
        IGmxV2MarketTypes.Props market;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        BaseFundingValues baseFunding;
        GetNextFundingAmountPerSizeResult nextFunding;
        VirtualInventory virtualInventory;
        bool isDisabled;
    }

    struct BaseFundingValues {
        PositionType fundingFeeAmountPerSize;
        PositionType claimableFundingAmountPerSize;
    }

    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }

    struct PoolValueInfo {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;
        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;
        uint256 impactPoolAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import {
    IChainlinkAdapter
} from "../../../adapters/chainlink/interfaces/IChainlinkAdapter.sol";

/**
 * @title IMarketConfiguration
 * @author GoldLink
 *
 * @dev Manages the configuration of markets for the GmxV2 funding rate farming strategy.
 */
interface IMarketConfiguration {
    // ============ Structs ============

    /// @dev Parameters for pricing an order.
    struct OrderPricingParameters {
        // The maximum swap slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxSwapSlippagePercent;
        // The maximum slippage percentage for this market. The value is computed using the oracle price as a reference.
        uint256 maxPositionSlippagePercent;
        // The minimum order size in USD for this market.
        uint256 minOrderSizeUsd;
        // The maximum order size in USD for this market.
        uint256 maxOrderSizeUsd;
        // Whether or not increase orders are enabled.
        bool increaseEnabled;
    }

    /// @dev Parameters for unwinding an order.
    struct UnwindParameters {
        // The minimum amount of delta the position is allowed to have before it can be rebalanced.
        uint256 maxDeltaProportion;
        // The minimum size of a token sale rebalance required. This is used to prevent dust orders from preventing rebalancing of a position via unwinding a position from occuring.
        uint256 minSwapRebalanceSize;
        // The maximum amount of leverage a position is allowed to have.
        uint256 maxPositionLeverage;
        // The fee rate that pays rebalancers for purchasing additional assets to match the short position.
        uint256 unwindFee;
    }

    /// @dev Parameters shared across order types for a market.
    struct SharedOrderParameters {
        // The callback gas limit for all orders.
        uint256 callbackGasLimit;
        // The execution fee buffer percentage required for placing an order.
        uint256 executionFeeBufferPercent;
        // The referral code to use for all orders.
        bytes32 referralCode;
        // The ui fee receiver used for all orders.
        address uiFeeReceiver;
        // The `withdrawalBufferPercentage` for all accounts.
        uint256 withdrawalBufferPercentage;
    }

    /// @dev Parameters for a position established on GMX through the strategy.
    struct PositionParameters {
        // The minimum position size in USD for this market, in order to prevent
        // dust orders from needing to be liquidated. This implies that if a position is partially closed,
        // the value of the position after the partial close must be greater than this value.
        uint256 minPositionSizeUsd;
        // The maximum position size in USD for this market.
        uint256 maxPositionSizeUsd;
    }

    /// @dev Object containing all parameters for a market.
    struct MarketConfiguration {
        // The order pricing parameters for the market.
        OrderPricingParameters orderPricingParameters;
        // The shared order parameters for the market.
        SharedOrderParameters sharedOrderParameters;
        // The position parameters for the market.
        PositionParameters positionParameters;
        // The unwind parameters for the market.
        UnwindParameters unwindParameters;
    }

    // ============ Events ============

    /// @notice Emitted when setting the configuration for a market.
    /// @param market             The address of the market whose configuration is being updated.
    /// @param marketParameters   The updated market parameters for the market.
    /// @param positionParameters The updated position parameters for the market.
    /// @param unwindParameters   The updated unwind parameters for the market.
    event MarketConfigurationSet(
        address indexed market,
        OrderPricingParameters marketParameters,
        PositionParameters positionParameters,
        UnwindParameters unwindParameters
    );

    /// @notice Emitted when setting the asset liquidation fee.
    /// @param asset                    The asset whose liquidation fee percent is being set.
    /// @param newLiquidationFeePercent The new liquidation fee percent for the asset.
    event AssetLiquidationFeeSet(
        address indexed asset,
        uint256 newLiquidationFeePercent
    );

    /// @notice Emitted when setting the liquidation order timeout deadline.
    /// @param newLiquidationOrderTimeoutDeadline The window after which a liquidation order
    /// can be canceled.
    event LiquidationOrderTimeoutDeadlineSet(
        uint256 newLiquidationOrderTimeoutDeadline
    );

    /// @notice Emitted when setting the callback gas limit.
    /// @param newCallbackGasLimit The gas limit on any callback made from the strategy.
    event CallbackGasLimitSet(uint256 newCallbackGasLimit);

    /// @notice Emitted when setting the execution fee buffer percent.
    /// @param newExecutionFeeBufferPercent The percentage of the initially calculated execution fee that needs to be provided additionally
    /// to prevent orders from failing execution.
    event ExecutionFeeBufferPercentSet(uint256 newExecutionFeeBufferPercent);

    /// @notice Emitted when setting the referral code.
    /// @param newReferralCode The code applied to all orders for the strategy, tying orders back to
    /// this protocol.
    event ReferralCodeSet(bytes32 newReferralCode);

    /// @notice Emitted when setting the ui fee receiver.
    /// @param newUiFeeReceiver The fee paid to the UI, this protocol for placing orders.
    event UiFeeReceiverSet(address newUiFeeReceiver);

    /// @notice Emitted when setting the withdrawal buffer percentage.
    /// @param newWithdrawalBufferPercentage The new withdrawal buffer percentage that was set.
    event WithdrawalBufferPercentageSet(uint256 newWithdrawalBufferPercentage);

    // ============ External Functions ============

    /// @dev Set a market for the GMX FRF strategy.
    function setMarket(
        address market,
        IChainlinkAdapter.OracleConfiguration memory oracleConfig,
        OrderPricingParameters memory marketParameters,
        PositionParameters memory positionParameters,
        UnwindParameters memory unwindParameters,
        uint256 longTokenLiquidationFeePercent
    ) external;

    /// @dev Update the oracle for USDC.
    function updateUsdcOracle(
        IChainlinkAdapter.OracleConfiguration calldata strategyAssetOracleConfig
    ) external;

    /// @dev Disable increase orders in a market.
    function disableMarketIncreases(address marketAddress) external;

    /// @dev Set the asset liquidation fee percentage for an asset.
    function setAssetLiquidationFee(
        address asset,
        uint256 newLiquidationFeePercent
    ) external;

    /// @dev Set the asset liquidation timeout for an asset. The time that must
    /// pass before a liquidated order can be cancelled.
    function setLiquidationOrderTimeoutDeadline(
        uint256 newLiquidationOrderTimeoutDeadline
    ) external;

    /// @dev Set the callback gas limit.
    function setCallbackGasLimit(uint256 newCallbackGasLimit) external;

    /// @dev Set the execution fee buffer percent.
    function setExecutionFeeBufferPercent(
        uint256 newExecutionFeeBufferPercent
    ) external;

    /// @dev Set the referral code for all trades made through the GMX Frf strategy.
    function setReferralCode(bytes32 newReferralCode) external;

    /// @dev Set the address of the UI fee receiver.
    function setUiFeeReceiver(address newUiFeeReceiver) external;

    /// @dev Set the buffer on the account value that must be maintained to withdraw profit
    /// with an active loan.
    function setWithdrawalBufferPercentage(
        uint256 newWithdrawalBufferPercentage
    ) external;

    /// @dev Get if a market is approved for the GMX FRF strategy.
    function isApprovedMarket(address market) external view returns (bool);

    /// @dev Get the config that dictates parameters for unwinding an order.
    function getMarketUnwindConfiguration(
        address market
    ) external view returns (UnwindParameters memory);

    /// @dev Get the config for a specific market.
    function getMarketConfiguration(
        address market
    ) external view returns (MarketConfiguration memory);

    /// @dev Get the list of available markets for the GMX FRF strategy.
    function getAvailableMarkets() external view returns (address[] memory);

    /// @dev Get the asset liquidation fee percent.
    function getAssetLiquidationFeePercent(
        address asset
    ) external view returns (uint256);

    /// @dev Get the liquidation order timeout deadline.
    function getLiquidationOrderTimeoutDeadline()
        external
        view
        returns (uint256);

    /// @dev Get the callback gas limit.
    function getCallbackGasLimit() external view returns (uint256);

    /// @dev Get the execution fee buffer percent.
    function getExecutionFeeBufferPercent() external view returns (uint256);

    /// @dev Get the referral code.
    function getReferralCode() external view returns (bytes32);

    /// @dev Get the UI fee receiver
    function getUiFeeReceiver() external view returns (address);

    /// @dev Get profit withdraw buffer percent.
    function getProfitWithdrawalBufferPercent() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWrappedNativeToken
 * @author GoldLink
 *
 * @dev Interface for wrapping native network tokens.
 */
interface IWrappedNativeToken is IERC20 {
    // ============ External Functions ============

    /// @dev Deposit ETH into contract for wrapped tokens.
    function deposit() external payable;

    /// @dev Withdraw ETH by burning wrapped tokens.
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title GmxFrfStrategyErrors
 * @author GoldLink
 *
 * @dev Gmx Delta Neutral Errors library for GMX related interactions.
 */
library GmxFrfStrategyErrors {
    //
    // COMMON
    //
    string internal constant ZERO_ADDRESS_IS_NOT_ALLOWED =
        "Zero address is not allowed.";
    string
        internal constant TOO_MUCH_NATIVE_TOKEN_SPENT_IN_MULTICALL_EXECUTION =
        "Too much native token spent in multicall transaction.";
    string internal constant MSG_VALUE_LESS_THAN_PROVIDED_EXECUTION_FEE =
        "Msg value less than provided execution fee.";
    string internal constant NESTED_MULTICALLS_ARE_NOT_ALLOWED =
        "Nested multicalls are not allowed.";

    //
    // Deployment Configuration Manager
    //
    string
        internal constant DEPLOYMENT_CONFIGURATION_MANAGER_INVALID_DEPLOYMENT_ADDRESS =
        "DeploymentConfigurationManager: Invalid deployment address.";

    //
    // GMX Delta Neutral Funding Rate Farming Manager
    //
    string internal constant CANNOT_ADD_SEPERATE_MARKET_WITH_SAME_LONG_TOKEN =
        "GmxFrfStrategyManager: Cannot add seperate market with same long token.";
    string
        internal constant GMX_FRF_STRATEGY_MANAGER_LONG_TOKEN_DOES_NOT_HAVE_AN_ORACLE =
        "GmxFrfStrategyManager: Long token does not have an oracle.";
    string internal constant GMX_FRF_STRATEGY_MANAGER_MARKET_DOES_NOT_EXIST =
        "GmxFrfStrategyManager: Market does not exist.";
    string
        internal constant GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_DOES_NOT_HAVE_AN_ORACLE =
        "GmxFrfStrategyManager: Short token does not have an oracle.";
    string internal constant GMX_FRF_STRATEGY_MANAGER_SHORT_TOKEN_MUST_BE_USDC =
        "GmxFrfStrategyManager: Short token for market must be usdc.";
    string internal constant LONG_TOKEN_CANT_BE_USDC =
        "GmxFrfStrategyManager: Long token can't be usdc.";
    string internal constant MARKET_CAN_ONLY_BE_DISABLED_IN_DECREASE_ONLY_MODE =
        "GmxFrfStrategyManager: Market can only be disabled in decrease only mode.";
    string internal constant MARKETS_COUNT_CANNOT_EXCEED_MAXIMUM =
        "GmxFrfStrategyManager: Market count cannot exceed maximum.";
    string internal constant MARKET_INCREASES_ARE_ALREADY_DISABLED =
        "GmxFrfStrategyManager: Market increases are already disabled.";
    string internal constant MARKET_IS_NOT_ENABLED =
        "GmxFrfStrategyManager: Market is not enabled.";

    //
    // GMX V2 Adapter
    //
    string
        internal constant GMX_V2_ADAPTER_MAX_SLIPPAGE_MUST_BE_LT_100_PERCENT =
        "GmxV2Adapter: Maximum slippage must be less than 100%.";
    string internal constant GMX_V2_ADAPTER_MINIMUM_SLIPPAGE_MUST_BE_LT_MAX =
        "GmxV2Adapter: Minimum slippage must be less than maximum slippage.";

    //
    // Liquidation Management
    //
    string
        internal constant LIQUIDATION_MANAGEMENT_AVAILABLE_TOKEN_BALANCE_MUST_BE_CLEARED_BEFORE_REBALANCING =
        "LiquidationManagement: Available token balance must be cleared before rebalancing.";
    string
        internal constant LIQUIDATION_MANAGEMENT_NO_ASSETS_EXIST_IN_THIS_MARKET_TO_REBALANCE =
        "LiquidationManagement: No assets exist in this market to rebalance.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_DELTA_IS_NOT_SUFFICIENT_FOR_SWAP_REBALANCE =
        "LiquidationManagement: Position delta is not sufficient for swap rebalance.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_IS_WITHIN_MAX_DEVIATION =
        "LiquidationManagement: Position is within max deviation.";
    string
        internal constant LIQUIDATION_MANAGEMENT_POSITION_IS_WITHIN_MAX_LEVERAGE =
        "LiquidationManagement: Position is within max leverage.";
    string
        internal constant LIQUIDATION_MANAGEMENT_REBALANCE_AMOUNT_LEAVE_TOO_LITTLE_REMAINING_ASSETS =
        "LiquidationManagement: Rebalance amount leaves too little remaining assets.";

    //
    // Swap Callback Logic
    //
    string
        internal constant SWAP_CALLBACK_LOGIC_CALLBACK_ADDRESS_MUST_NOT_HAVE_GMX_CONTROLLER_ROLE =
        "SwapCallbackLogic: Callback address must not have GMX controller role.";
    string internal constant SWAP_CALLBACK_LOGIC_CANNOT_SWAP_USDC =
        "SwapCallbackLogic: Cannot swap USDC.";
    string internal constant SWAP_CALLBACK_LOGIC_INSUFFICIENT_USDC_RETURNED =
        "SwapCallbackLogic: Insufficient USDC returned.";
    string
        internal constant SWAP_CALLBACK_LOGIC_NO_BALANCE_AFTER_SLIPPAGE_APPLIED =
        "SwapCallbackLogic: No balance after slippage applied.";

    //
    // Order Management
    //
    string internal constant ORDER_MANAGEMENT_INVALID_FEE_REFUND_RECIPIENT =
        "OrderManagement: Invalid fee refund recipient.";
    string
        internal constant ORDER_MANAGEMENT_LIQUIDATION_ORDER_CANNOT_BE_CANCELLED_YET =
        "OrderManagement: Liquidation order cannot be cancelled yet.";
    string internal constant ORDER_MANAGEMENT_ORDER_MUST_BE_FOR_THIS_ACCOUNT =
        "OrderManagement: Order must be for this account.";

    //
    // Order Validation
    //
    string
        internal constant ORDER_VALIDATION_ACCEPTABLE_PRICE_IS_NOT_WITHIN_SLIPPAGE_BOUNDS =
        "OrderValidation: Acceptable price is not within slippage bounds.";
    string internal constant ORDER_VALIDATION_DECREASE_AMOUNT_CANNOT_BE_ZERO =
        "OrderValidation: Decrease amount cannot be zero.";
    string internal constant ORDER_VALIDATION_DECREASE_AMOUNT_IS_TOO_LARGE =
        "OrderValidation: Decrease amount is too large.";
    string
        internal constant ORDER_VALIDATION_EXECUTION_PRICE_NOT_WITHIN_SLIPPAGE_RANGE =
        "OrderValidation: Execution price not within slippage range.";
    string
        internal constant ORDER_VALIDATION_INITIAL_COLLATERAL_BALANCE_IS_TOO_LOW =
        "OrderValidation: Initial collateral balance is too low.";
    string internal constant ORDER_VALIDATION_MARKET_HAS_PENDING_ORDERS =
        "OrderValidation: Market has pending orders.";
    string internal constant ORDER_VALIDATION_ORDER_TYPE_IS_DISABLED =
        "OrderValidation: Order type is disabled.";
    string internal constant ORDER_VALIDATION_ORDER_SIZE_IS_TOO_LARGE =
        "OrderValidation: Order size is too large.";
    string internal constant ORDER_VALIDATION_ORDER_SIZE_IS_TOO_SMALL =
        "OrderValidation: Order size is too small.";
    string internal constant ORDER_VALIDATION_POSITION_DOES_NOT_EXIST =
        "OrderValidation: Position does not exist.";
    string
        internal constant ORDER_VALIDATION_POSITION_NOT_OWNED_BY_THIS_ACCOUNT =
        "OrderValidation: Position not owned by this account.";
    string internal constant ORDER_VALIDATION_POSITION_SIZE_IS_TOO_LARGE =
        "OrderValidation: Position size is too large.";
    string internal constant ORDER_VALIDATION_POSITION_SIZE_IS_TOO_SMALL =
        "OrderValidation: Position size is too small.";
    string
        internal constant ORDER_VALIDATION_PROVIDED_EXECUTION_FEE_IS_TOO_LOW =
        "OrderValidation: Provided execution fee is too low.";
    string internal constant ORDER_VALIDATION_SWAP_SLIPPAGE_IS_TOO_HGIH =
        "OrderValidation: Swap slippage is too high.";

    //
    // Gmx Funding Rate Farming
    //
    string internal constant GMX_FRF_STRATEGY_MARKET_DOES_NOT_EXIST =
        "GmxFrfStrategyAccount: Market does not exist.";
    string
        internal constant GMX_FRF_STRATEGY_ORDER_CALLBACK_RECEIVER_CALLER_MUST_HAVE_CONTROLLER_ROLE =
        "GmxFrfStrategyAccount: Caller must have controller role.";

    //
    // Gmx V2 Order Callback Receiver
    //
    string
        internal constant GMX_V2_ORDER_CALLBACK_RECEIVER_CALLER_MUST_HAVE_CONTROLLER_ROLE =
        "GmxV2OrderCallbackReceiver: Caller must have controller role.";

    //
    // Market Configuration Manager
    //
    string
        internal constant ASSET_LIQUIDATION_FEE_CANNOT_BE_GREATER_THAN_MAXIMUM =
        "MarketConfigurationManager: Asset liquidation fee cannot be greater than maximum.";
    string internal constant ASSET_ORACLE_COUNT_CANNOT_EXCEED_MAXIMUM =
        "MarketConfigurationManager: Asset oracle count cannot exceed maximum.";
    string
        internal constant CANNOT_SET_MAX_POSITION_SLIPPAGE_BELOW_MINIMUM_VALUE =
        "MarketConfigurationManager: Cannot set maxPositionSlippagePercent below the minimum value.";
    string
        internal constant CANNOT_SET_THE_CALLBACK_GAS_LIMIT_ABOVE_THE_MAXIMUM =
        "MarketConfigurationManager: Cannot set the callback gas limit above the maximum.";
    string internal constant CANNOT_SET_MAX_SWAP_SLIPPAGE_BELOW_MINIMUM_VALUE =
        "MarketConfigurationManager: Cannot set maxSwapSlippagePercent below minimum value.";
    string
        internal constant CANNOT_SET_THE_EXECUTION_FEE_BUFFER_ABOVE_THE_MAXIMUM =
        "MarketConfigurationManager: Cannot set the execution fee buffer above the maximum.";
    string
        internal constant MARKET_CONFIGURATION_MANAGER_MIN_ORDER_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_ORDER_SIZE =
        "MarketConfigurationManager: Min order size must be less than or equal to max order size.";
    string
        internal constant MARKET_CONFIGURATION_MANAGER_MIN_POSITION_SIZE_MUST_BE_LESS_THAN_OR_EQUAL_TO_MAX_POSITION_SIZE =
        "MarketConfigurationManager: Min position size must be less than or equal to max position size.";
    string
        internal constant MAX_DELTA_PROPORTION_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE =
        "MarketConfigurationManager: MaxDeltaProportion is below the minimum required value.";
    string
        internal constant MAX_POSITION_LEVERAGE_IS_BELOW_THE_MINIMUM_REQUIRED_VALUE =
        "MarketConfigurationManager: MaxPositionLeverage is below the minimum required value.";
    string internal constant UNWIND_FEE_IS_ABOVE_THE_MAXIMUM_ALLOWED_VALUE =
        "MarketConfigurationManager: UnwindFee is above the maximum allowed value.";
    string
        internal constant WITHDRAWAL_BUFFER_PERCENTAGE_MUST_BE_GREATER_THAN_THE_MINIMUM =
        "MarketConfigurationManager: WithdrawalBufferPercentage must be greater than the minimum.";
    //
    // Withdrawal Logic Errors
    //
    string
        internal constant CANNOT_WITHDRAW_BELOW_THE_ACCOUNTS_LOAN_VALUE_WITH_BUFFER_APPLIED =
        "WithdrawalLogic: Cannot withdraw to below the account's loan value with buffer applied.";
    string
        internal constant CANNOT_WITHDRAW_FROM_MARKET_IF_ACCOUNT_MARKET_DELTA_IS_SHORT =
        "WithdrawalLogic: Cannot withdraw from market if account's market delta is short.";
    string internal constant CANNOT_WITHDRAW_MORE_TOKENS_THAN_ACCOUNT_BALANCE =
        "WithdrawalLogic: Cannot withdraw more tokens than account balance.";
    string
        internal constant REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_CURRENT_DELTA_DIFFERENCE =
        "WithdrawalLogic: Requested amount exceeds current delta difference.";
    string
        internal constant WITHDRAWAL_BRINGS_ACCOUNT_BELOW_MINIMUM_OPEN_HEALTH_SCORE =
        "WithdrawalLogic: Withdrawal brings account below minimum open health score.";
    string internal constant WITHDRAWAL_VALUE_CANNOT_BE_GTE_ACCOUNT_VALUE =
        "WithdrawalLogic: Withdrawal value cannot be gte to account value.";
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Constants } from "../../../libraries/Constants.sol";

/**
 * @title Limits
 * @author GoldLink
 *
 * @dev Constants library for limiting manager configuration variables to prevent owner manipulation.
 */
library Limits {
    /// ================= Constants ====================

    // Oracle Limits
    uint256 internal constant MAX_REGISTERED_ASSET_COUNT = 30;

    // Market Limits
    uint256 internal constant MAX_MARKET_COUNT = 30;

    // Order Pricing Parameters Limits
    uint256 internal constant MINIMUM_MAX_SWAP_SLIPPAGE_PERCENT = 0.02e18; // 2%
    uint256 internal constant MINIMUM_MAX_POSITION_SLIPPAGE_PERCENT = 0.02e18; // 2%

    // Unwind Parameters Limits
    uint256 internal constant MINIMUM_MAX_DELTA_PROPORTION_PERCENT = 1.025e18; // 102.5%
    uint256 internal constant MINIMUM_MAX_POSITION_LEVERAGE_PERCENT = 1.05e18; // 105%
    uint256 internal constant MAXIMUM_UNWIND_FEE_PERCENT = 0.1e18; // 10%

    // Shared Order Limits
    uint256 internal constant MAXIMUM_CALLBACK_GAS_LIMIT = 2e6; // 2 million gwei
    uint256 internal constant MAXIMUM_EXECUTION_FEE_BUFFER_PERCENT = 0.2e18; // 20%
    uint256 internal constant MAXIMUM_ASSET_LIQUIDATION_FEE_PERCENT = 0.1e18; // 10%
    uint256 internal constant MINIMUM_WITHDRAWAL_BUFFER_PERCENT = 1e18; // 100%
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "./OwnableUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable2Step
    struct Ownable2StepStorage {
        address _pendingOwner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable2Step")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant Ownable2StepStorageLocation = 0x237e158222e3e6968b72b9db0d8043aacf074ad9f650f0d1606b4d82ee432c00;

    function _getOwnable2StepStorage() private pure returns (Ownable2StepStorage storage $) {
        assembly {
            $.slot := Ownable2StepStorageLocation
        }
    }

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal onlyInitializing {
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        return $._pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        $._pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        delete $._pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title Errors
 * @author GoldLink
 *
 * @dev The core GoldLink Protocol errors library.
 */
library Errors {
    //
    // COMMON
    //
    string internal constant ADDRESS_CANNOT_BE_RESET =
        "Address cannot be reset.";
    string internal constant CALLER_MUST_BE_VALID_STRATEGY_BANK =
        "Caller must be valid strategy bank.";
    string internal constant CANNOT_CALL_FUNCTION_WHEN_PAUSED =
        "Cannot call function when paused.";
    string internal constant ZERO_ADDRESS_IS_NOT_ALLOWED =
        "Zero address is not allowed.";
    string internal constant ZERO_AMOUNT_IS_NOT_VALID =
        "Zero amount is not valid.";

    //
    // UTILS
    //
    string internal constant CANNOT_RENOUNCE_OWNERSHIP =
        "GoldLinkOwnable: Cannot renounce ownership";

    //
    // STRATEGY ACCOUNT
    //
    string internal constant STRATEGY_ACCOUNT_ACCOUNT_IS_NOT_LIQUIDATABLE =
        "StrategyAccount: Account is not liquidatable.";
    string internal constant STRATEGY_ACCOUNT_ACCOUNT_HAS_AN_ACTIVE_LOAN =
        "StrategyAccount: Account has an active loan.";
    string internal constant STRATEGY_ACCOUNT_ACCOUNT_HAS_NO_LOAN =
        "StrategyAccount: Account has no loan.";
    string
        internal constant STRATEGY_ACCOUNT_CANNOT_CALL_WHILE_LIQUIDATION_ACTIVE =
        "StrategyAccount: Cannot call while liquidation active.";
    string
        internal constant STRATEGY_ACCOUNT_CANNOT_CALL_WHILE_LIQUIDATION_INACTIVE =
        "StrategyAccount: Cannot call while liquidation inactive.";
    string
        internal constant STRATEGY_ACCOUNT_CANNOT_PROCESS_LIQUIDATION_WHEN_NOT_COMPLETE =
        "StrategyAccount: Cannot process liquidation when not complete.";
    string internal constant STRATEGY_ACCOUNT_PARAMETERS_LENGTH_MISMATCH =
        "StrategyAccount: Parameters length mismatch.";
    string internal constant STRATEGY_ACCOUNT_SENDER_IS_NOT_OWNER =
        "StrategyAccount: Sender is not owner.";

    //
    // STRATEGY BANK
    //
    string
        internal constant STRATEGY_BANK_CALLER_IS_NOT_VALID_STRATEGY_ACCOUNT =
        "StrategyBank: Caller is not valid strategy account.";
    string internal constant STRATEGY_BANK_CALLER_MUST_BE_STRATEGY_RESERVE =
        "StrategyBank: Caller must be strategy reserve.";
    string
        internal constant STRATEGY_BANK_CANNOT_DECREASE_COLLATERAL_BELOW_ZERO =
        "StrategyBank: Cannot decrease collateral below zero.";
    string internal constant STRATEGY_BANK_CANNOT_REPAY_LOAN_WHEN_LIQUIDATABLE =
        "StrategyBank: Cannot repay loan when liquidatable.";
    string
        internal constant STRATEGY_BANK_CANNOT_REPAY_MORE_THAN_IS_IN_STRATEGY_ACCOUNT =
        "StrategyBank: Cannot repay more than is in strategy account.";
    string internal constant STRATEGY_BANK_CANNOT_REPAY_MORE_THAN_TOTAL_LOAN =
        "StrategyBank: Cannot repay more than total loan.";
    string
        internal constant STRATEGY_BANK_COLLATERAL_WOULD_BE_LESS_THAN_MINIMUM =
        "StrategyBank: Collateral would be less than minimum.";
    string
        internal constant STRATEGY_BANK_EXECUTOR_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Executor premium must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_HEALTH_SCORE_WOULD_FALL_BELOW_MINIMUM_OPEN_HEALTH_SCORE =
        "StrategyBank: Health score would fall below minimum open health score.";
    string
        internal constant STRATEGY_BANK_INSURANCE_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Insurance premium must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_LIQUIDATABLE_HEALTH_SCORE_MUST_BE_GREATER_THAN_ZERO =
        "StrategyBank: Liquidatable health score must be greater than zero.";
    string
        internal constant STRATEGY_BANK_LIQUIDATABLE_HEALTH_SCORE_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Liquidatable health score must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_LIQUIDATION_INSURANCE_PREMIUM_MUST_BE_LESS_THAN_ONE_HUNDRED_PERCENT =
        "StrategyBank: Liquidation insurance premium must be less than one hundred percent.";
    string
        internal constant STRATEGY_BANK_MINIMUM_OPEN_HEALTH_SCORE_CANNOT_BE_AT_OR_BELOW_LIQUIDATABLE_HEALTH_SCORE =
        "StrategyBank: Minimum open health score cannot be at or below liquidatable health score.";
    string
        internal constant STRATEGY_BANK_REQUESTED_WITHDRAWAL_AMOUNT_EXCEEDS_AVAILABLE_COLLATERAL =
        "StrategyBank: Requested withdrawal amount exceeds available collateral.";

    //
    // STRATEGY RESERVE
    //
    string internal constant STRATEGY_RESERVE_CALLER_MUST_BE_THE_STRATEGY_BANK =
        "StrategyReserve: Caller must be the strategy bank.";
    string internal constant STRATEGY_RESERVE_INSUFFICIENT_AVAILABLE_TO_BORROW =
        "StrategyReserve: Insufficient available to borrow.";
    string
        internal constant STRATEGY_RESERVE_OPTIMAL_UTILIZATION_MUST_BE_LESS_THAN_OR_EQUAL_TO_ONE_HUNDRED_PERCENT =
        "StrategyReserve: Optimal utilization must be less than or equal to one hundred percent.";
    string
        internal constant STRATEGY_RESERVE_STRATEGY_ASSET_DOES_NOT_HAVE_ASSET_DECIMALS_SET =
        "StrategyReserve: Strategy asset does not have asset decimals set.";

    //
    // STRATEGY CONTROLLER
    //
    string internal constant STRATEGY_CONTROLLER_CALLER_IS_NOT_STRATEGY_CORE =
        "StrategyController: Caller is not strategy core.";
    string internal constant STRATEGY_CONTROLLER_LOCK_ALREADY_ACQUIRED =
        "StrategyController: Lock already acquired.";
    string internal constant STRATEGY_CONTROLLER_LOCK_NOT_ACQUIRED =
        "StrategyController: Lock not acquired.";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PriceTypes } from "./IGmxV2PriceTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PositionTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's position types. A few structs are the same as GMX but a number are
 * added.
 * Adapted from these three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/position/Position.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/PositionPricingUtils.sol
 */
interface IGmxV2PositionTypes {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    struct Flags {
        bool isLong;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        PositionFees fees;
        IGmxV2PriceTypes.ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionFeesParams {
        address dataStore;
        address referralStorage;
        IGmxV2PositionTypes.Props position;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        bool forPositiveImpact;
        address longToken;
        address shortToken;
        uint256 sizeDeltaUsd;
        address uiFeeReceiver;
    }

    struct GetPriceImpactUsdParams {
        address dataStore;
        IGmxV2MarketTypes.Props market;
        int256 usdDelta;
        bool isLong;
    }

    struct OpenInterestParams {
        uint256 longOpenInterest;
        uint256 shortOpenInterest;
        uint256 nextLongOpenInterest;
        uint256 nextShortOpenInterest;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        IGmxV2PriceTypes.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }

    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {
    IWrappedNativeToken
} from "../../../adapters/shared/interfaces/IWrappedNativeToken.sol";
import {
    IGmxV2ExchangeRouter
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ExchangeRouter.sol";
import {
    IGmxV2Reader
} from "../../../lib/gmx/interfaces/external/IGmxV2Reader.sol";
import {
    IGmxV2DataStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2DataStore.sol";
import {
    IGmxV2RoleStore
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2RoleStore.sol";
import {
    IGmxV2ReferralStorage
} from "../../../strategies/gmxFrf/interfaces/gmx/IGmxV2ReferralStorage.sol";
import { ISwapCallbackRelayer } from "./ISwapCallbackRelayer.sol";

/**
 * @title IDeploymentConfiguration
 * @author GoldLink
 *
 * @dev Actions that can be performed by the GMX V2 Adapter Controller.
 */
interface IDeploymentConfiguration {
    // ============ Structs ============

    struct Deployments {
        IGmxV2ExchangeRouter exchangeRouter;
        address orderVault;
        IGmxV2Reader reader;
        IGmxV2DataStore dataStore;
        IGmxV2RoleStore roleStore;
        IGmxV2ReferralStorage referralStorage;
    }

    // ============ Events ============

    /// @notice Emitted when setting the exchange router.
    /// @param exchangeRouter The address of the exhcange router being set.
    event ExchangeRouterSet(address exchangeRouter);

    /// @notice Emitted when setting the order vault.
    /// @param orderVault The address of the order vault being set.
    event OrderVaultSet(address orderVault);

    /// @notice Emitted when setting the reader.
    /// @param reader The address of the reader being set.
    event ReaderSet(address reader);

    /// @notice Emitted when setting the data store.
    /// @param dataStore The address of the data store being set.
    event DataStoreSet(address dataStore);

    /// @notice Emitted when setting the role store.
    /// @param roleStore The address of the role store being set.
    event RoleStoreSet(address roleStore);

    /// @notice Emitted when setting the referral storage.
    /// @param referralStorage The address of the referral storage being set.
    event ReferralStorageSet(address referralStorage);

    // ============ External Functions ============

    /// @dev Set the exchange router for the strategy.
    function setExchangeRouter(IGmxV2ExchangeRouter exchangeRouter) external;

    /// @dev Set the order vault for the strategy.
    function setOrderVault(address orderVault) external;

    /// @dev Set the reader for the strategy.
    function setReader(IGmxV2Reader reader) external;

    /// @dev Set the data store for the strategy.
    function setDataStore(IGmxV2DataStore dataStore) external;

    /// @dev Set the role store for the strategy.
    function setRoleStore(IGmxV2RoleStore roleStore) external;

    /// @dev Set the referral storage for the strategy.
    function setReferralStorage(IGmxV2ReferralStorage referralStorage) external;

    /// @dev Get the configured Gmx V2 `ExchangeRouter` deployment address.
    function gmxV2ExchangeRouter() external view returns (IGmxV2ExchangeRouter);

    /// @dev Get the configured Gmx V2 `OrderVault` deployment address.
    function gmxV2OrderVault() external view returns (address);

    /// @dev Get the configured Gmx V2 `Reader` deployment address.
    function gmxV2Reader() external view returns (IGmxV2Reader);

    /// @dev Get the configured Gmx V2 `DataStore` deployment address.
    function gmxV2DataStore() external view returns (IGmxV2DataStore);

    /// @dev Get the configured Gmx V2 `RoleStore` deployment address.
    function gmxV2RoleStore() external view returns (IGmxV2RoleStore);

    /// @dev Get the configured Gmx V2 `ReferralStorage` deployment address.
    function gmxV2ReferralStorage()
        external
        view
        returns (IGmxV2ReferralStorage);

    /// @dev Get the usdc deployment address.
    function USDC() external view returns (IERC20);

    /// @dev Get the wrapped native token deployment address.
    function WRAPPED_NATIVE_TOKEN() external view returns (IWrappedNativeToken);

    /// @dev The collateral claim distributor.
    function COLLATERAL_CLAIM_DISTRIBUTOR() external view returns (address);

    /// @dev Get the wrapped native token deployment address.
    function SWAP_CALLBACK_RELAYER()
        external
        view
        returns (ISwapCallbackRelayer);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { ISwapCallbackHandler } from "./ISwapCallbackHandler.sol";

/**
 * @title ISwapCallbackRelayer
 * @author GoldLink
 *
 * @dev Serves as a middle man for executing the swapCallback function in order to
 * prevent any issues that arise due to signature collisions and the msg.sender context
 * of a strategyAccount.
 */
interface ISwapCallbackRelayer {
    // ============ External Functions ============

    /// @dev Relay a swap callback on behalf of another address.
    function relaySwapCallback(
        address callbackHandler,
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { ISwapCallbackRelayer } from "./interfaces/ISwapCallbackRelayer.sol";
import { ISwapCallbackHandler } from "./interfaces/ISwapCallbackHandler.sol";

/**
 * @title SwapCallbackRelayer
 * @author GoldLink
 *
 * @notice Contract that serves as a middle man for execution callback functions. This contract
 * prevents collision risks with the `ISwapCallbackHandler.handleSwapCallback` function
 * potentially allowing for malicious calls from a strategy account using the account `msg.sender` context.
 */
contract SwapCallbackRelayer is ISwapCallbackRelayer {
    // ============ External Functions ============

    /**
     * @notice Relays a swap callback, executing on behalf of a caller to prevent collision risk.
     * @param callbackHandler   The address of the callback handler.
     * @param tokensToLiquidate The amount of tokens to liquidate during the callback.
     * @param expectedUsdc      The expected USDC received after the callback.
     * @param data              Data passed through to the callback contract.
     */
    function relaySwapCallback(
        address callbackHandler,
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external {
        ISwapCallbackHandler(callbackHandler).handleSwapCallback(
            tokensToLiquidate,
            expectedUsdc,
            data
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title ChainlinkErrors
 * @author GoldLink
 *
 * @dev The Chainlink errors library.
 */
library ChainlinkErrors {
    string internal constant INVALID_ASSET_ADDRESS = "Invalid asset address.";
    string internal constant INVALID_ORACLE_ASSET = "Invalid oracle asset.";
    string internal constant ORACLE_REGISTRY_ASSET_NOT_FOUND =
        "OracleRegistry: Asset not found.";
    string internal constant ORACLE_REGISTRY_INVALID_ORACLE =
        "OracleRegistry: Invalid oracle.";

    string internal constant ORACLE_REGISTRY_INVALID_ORACLE_PRICE =
        "OracleRegistry: Invalid oracle price.";
    string
        internal constant ORACLE_REGISTRY_LAST_UPDATE_TIMESTAMP_EXCEEDS_VALID_TIMESTAMP_RANGE =
        "OracleRegistry: Last update timestamp exceeds valid timestamp range.";
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";

import { Errors } from "../libraries/Errors.sol";

/**
 * @title GoldLinkOwnable
 * @author GoldLink
 *
 * @dev Ownable contract that requires new owner to accept, and disallows renouncing ownership.
 */
abstract contract GoldLinkOwnable is Ownable2Step {
    // ============ Public Functions ============

    function renounceOwnership() public view override onlyOwner {
        revert(Errors.CANNOT_RENOUNCE_OWNERSHIP);
    }
}

// SPDX-License-Identifier: BUSL-1.1

// Slightly modified from: https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/order/Order.sol
// Modified as follows:
// - Removed all logic
// - Added additional order structs

pragma solidity ^0.8.0;

interface IGmxV2OrderTypes {
    enum OrderType {
        MarketSwap,
        LimitSwap,
        MarketIncrease,
        LimitIncrease,
        MarketDecrease,
        LimitDecrease,
        StopLossDecrease,
        Liquidation
    }

    enum SecondaryOrderType {
        None,
        Adl
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

import { IGmxV2PositionTypes } from "./IGmxV2PositionTypes.sol";
import { IGmxV2MarketTypes } from "./IGmxV2MarketTypes.sol";

/**
 * @title IGmxV2PriceTypes
 * @author GoldLink
 *
 * Used for interacting with Gmx V2's Prices, removes all logic from GMX contract and adds additional
 * structs.
 * The structs here come from three files:
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/price/Price.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/reader/ReaderPricingUtils.sol
 * https://github.com/gmx-io/gmx-synthetics/blob/178290846694d65296a14b9f4b6ff9beae28a7f7/contracts/pricing/SwapPricingUtils.sol
 */
interface IGmxV2PriceTypes {
    struct Props {
        uint256 min;
        uint256 max;
    }

    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }

    struct PositionInfo {
        IGmxV2PositionTypes.Props position;
        IGmxV2PositionTypes.PositionFees fees;
        ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct GetPositionInfoCache {
        IGmxV2MarketTypes.Props market;
        Props collateralTokenPrice;
        uint256 pendingBorrowingFeeUsd;
        int256 latestLongTokenFundingAmountPerSize;
        int256 latestShortTokenFundingAmountPerSize;
    }

    struct SwapFees {
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 amountAfterFees;
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title Constants
 * @author GoldLink
 *
 * @dev Core constants for the GoldLink Protocol.
 */
library Constants {
    ///
    /// COMMON
    ///
    /// @dev ONE_HUNDRED_PERCENT is one WAD.
    uint256 internal constant ONE_HUNDRED_PERCENT = 1e18;
    uint256 internal constant SECONDS_PER_YEAR = 365 days;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title ISwapCallbackHandler
 * @author GoldLink
 *
 * @dev Interfaces that implents the `handleSwapCallback` function, which allows
 * atomic swaps of spot assets for the purpose of liquidations and user profit swaps.
 */
interface ISwapCallbackHandler {
    // ============ External Functions ============

    /// @dev Handle a swap callback.
    function handleSwapCallback(
        uint256 tokensToLiquidate,
        uint256 expectedUsdc,
        bytes memory data
    ) external;
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
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {Ownable} from "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
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