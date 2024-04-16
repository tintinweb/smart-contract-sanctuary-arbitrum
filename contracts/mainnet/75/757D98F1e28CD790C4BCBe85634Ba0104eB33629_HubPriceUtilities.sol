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
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
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
    /// this method will return the first update.
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

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
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

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILiquidationCalculator} from "../interfaces/ILiquidationCalculator.sol";
import {IHubPriceUtilities} from "../interfaces/IHubPriceUtilities.sol";
import {IAssetRegistry} from "../interfaces/IAssetRegistry.sol";

/**
 * @title HubSpokeStructs
 * @notice A set of structs and enums used in the Hub and Spoke contracts
 */
library HubSpokeStructs {
    /**
     * @param wormhole: Address of the Wormhole contract
     * @param tokenBridge: Address of the TokenBridge contract
     * @param wormholeRelayer: Address of the WormholeRelayer contract
     * @param consistencyLevel: Desired level of finality the Wormhole guardians will reach before signing the messages
     * NOTE: consistencyLevel = 200 will result in an instant message, while all other values will wait for finality
     * Recommended finality levels can be found here: https://book.wormhole.com/reference/contracts.html
     * @param pythAddress: Address of the Pyth oracle on the Hub chain
     * @param priceStandardDeviations: priceStandardDeviations = (psd * priceStandardDeviationsPrecision), where psd is
     * the number of standard deviations that we use for our price intervals in calculations relating to allowing
     * withdraws, borrows, or liquidations
     * @param priceStandardDeviationsPrecision: A precision number that allows us to represent our desired noninteger
     * price standard deviation as an integer (psd = priceStandardDeviations/priceStandardDeviationsPrecision)
     * @param maxLiquidationPortionPrecision: A precision number that allows us to represent our desired noninteger
     * max liquidation portion mlp as an integer (mlp = maxLiquidationPortion/maxLiquidationPortionPrecision)
     * @param interestAccrualIndexPrecision: A precision number that allows us to represent our noninteger interest
     * accrual indices as integers; we store each index as its true value multiplied by interestAccrualIndexPrecision
     * @param collateralizationRatioPrecision: A precision number that allows us to represent our noninteger
     * collateralization ratios as integers; we store each ratio as its true value multiplied by
     * collateralizationRatioPrecision
     * @param liquidationFee: The fee taken by the protocol on liquidation
     * @param _circleMessageTransmitter: Cicle Message Transmitter contract (cctp)
     * @param _circleTokenMessenger: Cicle Token Messenger contract (cctp)
     * @param _USDC: USDC token contract (cctp)
     */
    struct ConstructorArgs {
        /* Wormhole Information */
        address wormhole;
        address tokenBridge;
        address wormholeRelayer;
        uint8 consistencyLevel;
        /* Liquidation Information */
        uint256 interestAccrualIndexPrecision;
        uint256 liquidationFee;
        uint256 liquidationFeePrecision;
        /* CCTP Information */
        address circleMessageTransmitter;
        address circleTokenMessenger;
        address USDC;
    }

    struct StoredVaultAmount {
        DenormalizedVaultAmount amounts;
        AccrualIndices accrualIndices;
    }

    struct DenormalizedVaultAmount {
        uint256 deposited;
        uint256 borrowed;
    }

    struct NotionalVaultAmount {
        uint256 deposited;
        uint256 borrowed;
    }

    struct AccrualIndices {
        uint256 deposited;
        uint256 borrowed;
    }

    /**
     * @dev Struct to hold the decoded data from a Wormhole payload
     * @param action The action to be performed (e.g., Deposit, Borrow, Withdraw, Repay)
     * @param sender The address of the sender initiating the action
     * @param wrappedAsset The address of the wrapped asset involved in the action
     * @param amount The amount of the wrapped asset involved in the action
     * @param unwrap A boolean indicating whether to unwrap the asset or not for native withdraws and borrows
     */
    struct PayloadData {
        Action action;
        address sender;
        address wrappedAsset;
        uint256 amount;
        bool unwrap;
    }

    struct CrossChainTarget {
        bytes32 addressWhFormat;
        uint16 chainId;
        bytes32 deliveryHash;
    }

    enum Action {
        Deposit,
        Borrow,
        Withdraw,
        Repay,
        DepositNative,
        RepayNative
    }

    struct HubState {
        // number of confirmations for wormhole messages
        uint8 consistencyLevel;
        // vault for lending
        mapping(address => mapping(address => HubSpokeStructs.StoredVaultAmount)) vault;
        // total asset amounts (tokenAddress => (uint256, uint256))
        mapping(address => HubSpokeStructs.StoredVaultAmount) totalAssets;
        // interest accrual indices
        mapping(address => HubSpokeStructs.AccrualIndices) indices;
        // last timestamp for update
        mapping(address => uint256) lastActivityBlockTimestamps;
        // interest accrual rate precision level
        uint256 interestAccrualIndexPrecision;
        // calculator for liquidation amounts
        ILiquidationCalculator liquidationCalculator;
        // price utilities for getting prices
        IHubPriceUtilities priceUtilities;
        // asset registry for getting asset info
        IAssetRegistry assetRegistry;
        // protocol fee taken on liquidation
        uint256 liquidationFee;
        // for wormhole relay quotes
        uint256 defaultGasLimit;
        // for refunding of returnCost amount
        uint256 refundGasLimit;
        // toggle for using CCTP for asset => USDC
        bool isUsingCCTP;
        // the precision of the liquidation fee
        uint256 liquidationFeePrecision;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import {ISynonymPriceOracle} from "../../interfaces/ISynonymPriceOracle.sol";
import "../../interfaces/IHub.sol";
import "../../interfaces/IHubPriceUtilities.sol";
import "../HubSpokeStructs.sol";
import "../wormhole/TokenBridgeUtilities.sol";

/**
 * @title HubPriceUtilities
 * @notice Contract defining price-related utility functions for the Hub contract
 */
contract HubPriceUtilities is IHubPriceUtilities, Ownable {

    IHub hub;
    ISynonymPriceOracle priceOracle;

    // the amount of confidence intervals to use for the lower and upper bounds of the price
    uint256 priceStandardDeviations;
    uint256 priceStandardDeviationsPrecision;

    string public constant ERROR_DEPOSIT_LIMIT_EXCEEDED = "DepositLimitExceeded";
    string public constant ERROR_VAULT_UNDER_COLLAT = "VaultUnderCollateralized";
    string public constant ERROR_VAULT_INSUFFICIENT_BORROWS = "VaultInsufficientBorrows";

    error DepositLimitExceeded();
    error NoZeroOrNegativePrices();

    constructor(
        address _hub,
        address _priceOracle,
        uint256 _priceStandardDeviations,
        uint256 _priceStandardDeviationsPrecision
    ) Ownable(msg.sender) {
        require(_hub != address(0));
        require(_priceOracle != address(0));
        hub = IHub(_hub);
        priceOracle = ISynonymPriceOracle(_priceOracle);
        priceStandardDeviations = _priceStandardDeviations;
        priceStandardDeviationsPrecision = _priceStandardDeviationsPrecision;
    }

    function getAssetRegistry() public view override returns (IAssetRegistry) {
        return IAssetRegistry(hub.getAssetRegistry());
    }

    function getAssetInfo(address asset) internal view returns (IAssetRegistry.AssetInfo memory) {
        return getAssetRegistry().getAssetInfo(asset);
    }

    /**
     * @dev Gets priceCollateral and priceDebt, which are price - c*stdev and price + c*stdev, respectively
     * where c is a constant specified by the protocol (priceStandardDeviations/priceStandardDeviationPrecision),
     * and stdev is the standard deviation of the price.
     * Multiplies each of these values by getPriceStandardDeviationsPrecision().
     * These values are used as lower and upper bounds of the price when determining whether to allow
     * borrows and withdraws
     *
     * @param assetAddress the address of the relevant asset
     * @return truePrice - the price of the asset
     * @return priceCollateral - the price of the asset when used as collateral [true price reduced by c*stdev]
     * @return priceDebt - the price of the asset when used as debt [true price increased by c*stdev]
     * @return pricePrecision - the precision of the price
     */
    function getPrices(address assetAddress)
        public
        view
        override
        returns (uint256 truePrice, uint256 priceCollateral, uint256 priceDebt, uint256 pricePrecision)
    {
        (uint256 price, uint256 conf, uint256 _pricePrecision) = getOraclePrices(assetAddress);
        // use conservative (from protocol's perspective) prices for collateral (low) and debt (high)--see https://docs.pyth.network/consume-data/best-practices#confidence-intervals
        uint256 confidenceInterval = conf * priceStandardDeviations / priceStandardDeviationsPrecision;

        if (price <= confidenceInterval) {
            revert NoZeroOrNegativePrices();
        }

        truePrice = price;
        priceCollateral = price - confidenceInterval;
        priceDebt = price + confidenceInterval;
        pricePrecision = _pricePrecision;
    }

    /**
     * @dev Get the price, through Pyth, of the asset at address assetAddress
     * @param assetAddress - The address of the relevant asset
     * @return The price (in USD) of the asset, from Pyth;
     * @return The confidence (in USD) of the asset's price
     */
    function getOraclePrices(address assetAddress) internal view returns (uint256, uint256, uint256) {
        ISynonymPriceOracle.Price memory oraclePrice = priceOracle.getPrice(assetAddress);
        return (oraclePrice.price, oraclePrice.confidence, oraclePrice.precision);
    }

    /**
     * @dev Using the pyth prices, get the total price of the assets deposited into the vault, and
     * total price of the assets borrowed from the vault (multiplied by their respecetive collateralization ratios)
     * The result will be multiplied by interestAccrualIndexPrecision * priceStandardDeviationsPrecision * 10^(maxDecimals) * (collateralizationRatioPrecision if collateralizationRatios is true, otherwise 1)
     * because we are denormalizing without dividing by this value, and we are (maybe) multiplying by collateralizationRatios without dividing
     * by the precision, and we are using getPrices which returns the prices multiplied by priceStandardDeviationsPrecision
     * and we are multiplying by 10^maxDecimals to keep integers when we divide by 10^(decimals of each asset).
     *
     * @param vaultOwner - The address of the owner of the vault
     * @param collateralizationRatios - Whether or not to multiply by collateralizationRatios in the computation
     * @return NotionalVaultAmount memory The total value of the assets deposited into and borrowed from the vault
     */
    function getVaultEffectiveNotionals(address vaultOwner, bool collateralizationRatios)
        public
        view
        override
        returns (HubSpokeStructs.NotionalVaultAmount memory)
    {
        HubSpokeStructs.NotionalVaultAmount memory totalNotionalValues = HubSpokeStructs.NotionalVaultAmount(0, 0);
        address[] memory allowList = getAssetRegistry().getRegisteredAssets();
        for (uint256 i = 0; i < allowList.length;) {
            address asset = allowList[i];
            HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount = hub.getVaultAmounts(vaultOwner, asset);
            HubSpokeStructs.NotionalVaultAmount memory notionalValues = calculateNotionals(asset, vaultAmount);
            if (collateralizationRatios) {
                notionalValues = applyCollateralizationRatios(asset, notionalValues);
            }
            totalNotionalValues.deposited += notionalValues.deposited;
            totalNotionalValues.borrowed += notionalValues.borrowed;

            unchecked {
                i++;
            }
        }

        return totalNotionalValues;
    }

    /**
     * @dev Calculates the effective notional values for the assets deposited and borrowed from the vault.
     * The function takes into account the collateralization ratios if specified.
     * The effective notional values are used to determine the total price of the assets in the vault.
     * Precision: 1e36 = protocol precision 1e18 * price precision 1e18
     *
     * @param asset - The address of the asset in the vault
     * @param vaultAmount - The struct with amount deposited and borrowed
     * @return VaultAmount - the notional amount deposited and borrowed
     */
    function calculateNotionals(
        address asset,
        HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount
    ) public view override returns (HubSpokeStructs.NotionalVaultAmount memory) {
        IAssetRegistry assetRegistry = getAssetRegistry();
        IAssetRegistry.AssetInfo memory assetInfo = assetRegistry.getAssetInfo(asset);
        (,uint256 priceCollateral, uint256 priceDebt,) = getPrices(asset);
        uint256 expVal = 10 ** (assetRegistry.getMaxDecimals() - assetInfo.decimals);

        return HubSpokeStructs.NotionalVaultAmount(
            vaultAmount.deposited * priceCollateral * expVal,
            vaultAmount.borrowed * priceDebt * expVal
        );
    }

    function invertNotionals(
        address asset,
        HubSpokeStructs.NotionalVaultAmount memory realValues
    ) public view override returns (HubSpokeStructs.DenormalizedVaultAmount memory) {
        IAssetRegistry assetRegistry = getAssetRegistry();
        IAssetRegistry.AssetInfo memory assetInfo = assetRegistry.getAssetInfo(asset);
        (,uint256 priceCollateral, uint256 priceDebt,) = getPrices(asset);
        uint256 expVal = 10 ** (assetRegistry.getMaxDecimals() - assetInfo.decimals);

        return HubSpokeStructs.DenormalizedVaultAmount(
            realValues.deposited / (priceCollateral * expVal),
            realValues.borrowed / (priceDebt * expVal)
        );
    }

    function applyCollateralizationRatios(address asset, HubSpokeStructs.NotionalVaultAmount memory vaultAmount) public view override returns (HubSpokeStructs.NotionalVaultAmount memory) {
        IAssetRegistry assetRegistry = getAssetRegistry();
        IAssetRegistry.AssetInfo memory assetInfo = assetRegistry.getAssetInfo(asset);
        uint256 collateralizationRatioPrecision = assetRegistry.getCollateralizationRatioPrecision();
        vaultAmount.deposited = vaultAmount.deposited * collateralizationRatioPrecision / assetInfo.collateralizationRatioDeposit;
        vaultAmount.borrowed = vaultAmount.borrowed * assetInfo.collateralizationRatioBorrow / collateralizationRatioPrecision;
        return vaultAmount;
    }

    function removeCollateralizationRatios(address asset, HubSpokeStructs.NotionalVaultAmount memory vaultAmount) public view override returns (HubSpokeStructs.NotionalVaultAmount memory) {
        IAssetRegistry assetRegistry = getAssetRegistry();
        IAssetRegistry.AssetInfo memory assetInfo = assetRegistry.getAssetInfo(asset);
        uint256 collateralizationRatioPrecision = assetRegistry.getCollateralizationRatioPrecision();
        vaultAmount.deposited = vaultAmount.deposited * assetInfo.collateralizationRatioDeposit / collateralizationRatioPrecision;
        vaultAmount.borrowed = vaultAmount.borrowed * collateralizationRatioPrecision / assetInfo.collateralizationRatioBorrow;
        return vaultAmount;
    }

    function calculateEffectiveNotionals(address asset, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) public view override returns (HubSpokeStructs.NotionalVaultAmount memory) {
        return applyCollateralizationRatios(asset, calculateNotionals(asset, vaultAmount));
    }

    /**
     * @dev Check if a deposit of a certain amount of a certain asset is allowed
     *
     * @param assetAddress - The address of the relevant asset
     * @param assetAmount - The amount of the relevant asset
     * @param shouldRevert - Whether we should revert or simply log the error
     * Only returns if this deposit does not exceed the deposit limit for the asset
     * @return success - Whether the deposit is allowed
     * @return error - The error message if the deposit is not allowed
     */
    function checkAllowedToDeposit(address assetAddress, uint256 assetAmount, bool shouldRevert)
        external
        view
        override
        returns (bool success, string memory error)
    {
        IAssetRegistry.AssetInfo memory assetInfo = getAssetInfo(assetAddress);
        if (assetInfo.supplyLimit < type(uint256).max) {
            HubSpokeStructs.DenormalizedVaultAmount memory globalAmounts = hub.getGlobalAmounts(assetAddress);

            if (globalAmounts.deposited + assetAmount > assetInfo.supplyLimit) {
                if (shouldRevert) {
                    revert DepositLimitExceeded();
                }
                return (false, ERROR_DEPOSIT_LIMIT_EXCEEDED);
            }
        }

        return (true, error);
    }

    /**
     * @dev Check if vaultOwner is allowed to withdraw assetAmount of assetAddress from their vault
     *
     * @param vaultOwner - The address of the owner of the vault
     * @param assetAddress - The address of the relevant asset
     * @param assetAmount - The amount of the relevant asset
     * @param shouldRevert - Whether we should revert or simply log the error
     * Only returns if this withdrawal keeps the vault at a nonnegative notional value (worth >= $0 according to Pyth prices)
     * (where the deposit values are divided by the deposit collateralization ratio and the borrow values are multiplied by the borrow collateralization ratio)
     * and also if there is enough asset in the vault to complete the withdrawal
     * and also if there is enough asset in the total reserve of the protocol to complete the withdrawal
     * @return success - Whether the vault owner is allowed to withdraw
     * @return error - The error message if the vault owner is not allowed to withdraw
     */
    function checkAllowedToWithdraw(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert)
        external
        view
        override
        returns (bool success, string memory error)
    {
        (success, error) = hub.checkVaultHasAssets(vaultOwner, assetAddress, assetAmount, shouldRevert);

        if (success) {
            // checkProtocolGloballyHasAssets internally assumes the amount is denormalized
            (success, error) =
                hub.checkProtocolGloballyHasAssets(assetAddress, assetAmount, shouldRevert);
        }

        if (success) {
            HubSpokeStructs.NotionalVaultAmount memory effectiveValue = calculateEffectiveNotionals(
                assetAddress,
                HubSpokeStructs.DenormalizedVaultAmount(assetAmount, 0)
            );
            HubSpokeStructs.NotionalVaultAmount memory notionals = getVaultEffectiveNotionals(vaultOwner, true);

            bool overCollat = notionals.deposited >= notionals.borrowed + effectiveValue.deposited;

            if (shouldRevert) {
                require(overCollat, ERROR_VAULT_UNDER_COLLAT);
            }

            return (overCollat, ERROR_VAULT_UNDER_COLLAT);
        }
    }

    /**
     * @dev Check if vaultOwner is allowed to borrow assetAmount of assetAddress from their vault
     *
     * @param vaultOwner - The address of the owner of the vault
     * @param assetAddress - The address of the relevant asset
     * @param assetAmount - The amount of the relevant asset
     * @param shouldRevert - Whether we should revert or simply log the error
     * Only returns (otherwise reverts) if this borrow keeps the vault at a nonnegative notional value (worth >= $0 according to Pyth prices)
     * (where the deposit values are divided by the deposit collateralization ratio and the borrow values are multiplied by the borrow collateralization ratio)
     * and also if there is enough asset in the total reserve of the protocol to complete the borrow
     * @return success - Whether the vault owner is allowed to borrow
     * @return error - The error message if the vault owner is not allowed to borrow
     */
    function checkAllowedToBorrow(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert)
        external
        view
        override
        returns (bool success, string memory error)
    {
        IAssetRegistry.AssetInfo memory assetInfo = getAssetInfo(assetAddress);

        HubSpokeStructs.NotionalVaultAmount memory notionals = getVaultEffectiveNotionals(vaultOwner, true);

        (success, error) = hub.checkProtocolGloballyHasAssets(
            assetAddress, assetAmount, shouldRevert, assetInfo.borrowLimit
        );

        if (success) {
            HubSpokeStructs.NotionalVaultAmount memory effectiveValue = calculateEffectiveNotionals(
                assetAddress,
                HubSpokeStructs.DenormalizedVaultAmount(0, assetAmount)
            );
            bool overCollat = notionals.deposited >= notionals.borrowed + effectiveValue.borrowed;

            if (shouldRevert) {
                require(overCollat, ERROR_VAULT_UNDER_COLLAT);
            }

            return (overCollat, ERROR_VAULT_UNDER_COLLAT);
        }
    }

    /**
     * @dev Check if vaultOwner is allowed to repay assetAmount of assetAddress to their vault;
     * they must have outstanding borrows of at least assetAmount for assetAddress to enable repayment
     * @param vaultOwner - The address of the owner of the vault
     * @param assetAddress - The address of the relevant asset
     * @param assetAmount - The amount of the relevant asset
     * @param shouldRevert - Whether we should revert or simply log the error
     * @return success - Whether the vault owner is allowed to repay
     * @return error - The error message if the vault owner is not allowed to repay
     */
    function checkAllowedToRepay(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert)
        external
        view
        override
        returns (bool success, string memory error)
    {
        HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount = hub.getVaultAmounts(vaultOwner, assetAddress);
        IAssetRegistry.AssetInfo memory assetInfo = getAssetInfo(assetAddress);

        bool allowed;
        if (shouldRevert || assetInfo.decimals <= TokenBridgeUtilities.MAX_DECIMALS) {
            // this is a same chain operation or the bridged token has less decimals than the bridge
            // there can be no dust truncation here
            // require that the debt is strictly greater or equal to the amount being repaid
            allowed = vaultAmount.borrowed >= assetAmount;
        } else {
            // This is a cross-chain operation and Wormhole truncates the sent token to 8 decimals, so we allow for slight overpaying of the debt (by up to 1e-8)
            // This allows vault owner to always be able to fully repay outstanding borrows.
            uint256 allowedRepay = TokenBridgeUtilities.trimDust(vaultAmount.borrowed, assetInfo.decimals);
            allowedRepay += 10 ** (assetInfo.decimals - TokenBridgeUtilities.MAX_DECIMALS);
            allowed = allowedRepay >= assetAmount;
        }

        if (shouldRevert) {
            require(allowed, ERROR_VAULT_INSUFFICIENT_BORROWS);
        }

        return (allowed, ERROR_VAULT_INSUFFICIENT_BORROWS);
    }

    // Getter for hub
    function getHub() public view override returns (IHub) {
        return hub;
    }

    function setHub(IHub _hub) public override onlyOwner {
        require(address(_hub) != address(0));
        hub = _hub;
    }

    function getPriceOracle() public view override returns (ISynonymPriceOracle) {
        return priceOracle;
    }

    function setPriceOracle(ISynonymPriceOracle _priceOracle) public override onlyOwner {
        require(address(_priceOracle) != address(0));
        priceOracle = _priceOracle;
    }

    function getPriceStandardDeviations() public view override returns (uint256, uint256) {
        return (priceStandardDeviations, priceStandardDeviationsPrecision);
    }

    function setPriceStandardDeviations(uint256 _priceStandardDeviations, uint256 _precision) public override onlyOwner {
        priceStandardDeviations = _priceStandardDeviations;
        priceStandardDeviationsPrecision = _precision;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../interfaces/IERC20decimals.sol";

/**
 * @title TokenBridgeUtilities
 * @notice A set of internal utility functions
 */
library TokenBridgeUtilities {
    error TooManyDecimalPlaces();

    uint8 public constant MAX_DECIMALS = 8;

    /**
     * @dev This function checks if the asset amount is valid for the token bridge
     * @param assetAddress The address of the asset
     * @param assetAmount The amount of the asset
     */
    function requireAssetAmountValidForTokenBridge(address assetAddress, uint256 assetAmount) public view {
        uint8 decimals;
        if (assetAddress == address(0)) {
            // native ETH
            decimals = 18;
        } else {
            decimals = IERC20decimals(assetAddress).decimals();
        }

        if (decimals > MAX_DECIMALS && trimDust(assetAmount, decimals) != assetAmount) {
            revert TooManyDecimalPlaces();
        }
    }

    function trimDust(uint256 amount, uint8 decimals) public pure returns (uint256) {
        return denormalizeAmount(normalizeAmount(amount, decimals), decimals);
    }

    /**
     * @dev This function normalizes the amount based on the decimals
     * @param amount The amount to be normalized
     * @param decimals The number of decimals
     * @return The normalized amount
     */
    function normalizeAmount(uint256 amount, uint8 decimals) public pure returns (uint256) {
        if (decimals > MAX_DECIMALS) {
            amount /= uint256(10) ** (decimals - MAX_DECIMALS);
        }

        return amount;
    }

    /**
     * @dev This function normalizes the amount based on the decimals
     * @param amount The amount to be normalized
     * @param decimals The number of decimals
     * @return The normalized amount
     */
    function denormalizeAmount(uint256 amount, uint8 decimals) public pure returns (uint256) {
        if (decimals > MAX_DECIMALS) {
            amount *= uint256(10) ** (decimals - MAX_DECIMALS);
        }

        return amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "@wormhole-upgradeable/interfaces/IWETH.sol";
import "../contracts/HubSpokeStructs.sol";

interface IAssetRegistry {
    struct AssetInfo {
        uint256 collateralizationRatioDeposit;
        uint256 collateralizationRatioBorrow;
        uint8 decimals;
        address interestRateCalculator;
        bool exists;
        uint256 borrowLimit;
        uint256 supplyLimit;
        uint256 maxLiquidationPortion;
        uint256 maxLiquidationBonus; // 1e6 precision; 130e4 = 130% = 1.3; the liquidator gets 30% over what he repays
    }

    function registerAsset(
        address assetAddress,
        uint256 collateralizationRatioDeposit,
        uint256 collateralizationRatioBorrow,
        address interestRateCalculator,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus
    ) external;

    function getAssetInfo(address assetAddress) external view returns (AssetInfo memory);

    function setAssetParams(
        address assetAddress,
        uint256 borrowLimit,
        uint256 supplyLimit,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus,
        address interestRateCalculatorAddress
    ) external;

    function setCollateralizationRatios(address _asset, uint256 _deposit, uint256 _borrow) external;

    function getRegisteredAssets() external view returns (address[] memory);

    function getCollateralizationRatioPrecision() external view returns (uint256);

    function getMaxLiquidationPortionPrecision() external view returns (uint256);

    function WETH() external view returns (IWETH);

    function getMaxDecimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20decimals is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../contracts/HubSpokeStructs.sol";
import "./ILiquidationCalculator.sol";
import "./IHubPriceUtilities.sol";
import "./IAssetRegistry.sol";

/**
 * @notice interface for external contracts that need to access Hub state
 */
interface IHub {
    function checkVaultHasAssets(address vault, address assetAddress, uint256 normalizedAmount, bool shouldRevert)
        external
        view
        returns (bool success, string memory error);

    function checkProtocolGloballyHasAssets(
        address assetAddress,
        uint256 normalizedAmount,
        bool shouldRevert
    ) external view returns (bool success, string memory error);

    function checkProtocolGloballyHasAssets(
        address assetAddress,
        uint256 normalizedAmount,
        bool shouldRevert,
        uint256 borrowLimit
    ) external view returns (bool success, string memory error);

    function getInterestAccrualIndices(address assetAddress)
        external
        view
        returns (HubSpokeStructs.AccrualIndices memory);

    function getInterestAccrualIndexPrecision() external view returns (uint256);

    function getVaultAmounts(address vaultOwner, address assetAddress)
        external
        view
        returns (HubSpokeStructs.DenormalizedVaultAmount memory);

    function getCurrentAccrualIndices(address assetAddress)
        external
        view
        returns (HubSpokeStructs.AccrualIndices memory);

    function updateAccrualIndices(address assetAddress) external;

    function getLastActivityBlockTimestamp(address assetAddress) external view returns (uint256);

    function getGlobalAmounts(address assetAddress) external view returns (HubSpokeStructs.DenormalizedVaultAmount memory);

    function getReserveAmount(address assetAddress) external view returns (uint256);

    function getLiquidationCalculator() external view returns (ILiquidationCalculator);

    function getPriceUtilities() external view returns (IHubPriceUtilities);

    function getAssetRegistry() external view returns (IAssetRegistry);

    function getLiquidationFeeAndPrecision() external view returns (uint256, uint256);

    function liquidation(ILiquidationCalculator.LiquidationInput memory input) external;

    function userActions(HubSpokeStructs.Action action, address asset, uint256 amount) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "./IHub.sol";
import "./IAssetRegistry.sol";
import "./ISynonymPriceOracle.sol";
import "../contracts/HubSpokeStructs.sol";

interface IHubPriceUtilities {
    function getAssetRegistry() external view returns (IAssetRegistry);
    function getPrices(address assetAddress) external view returns (uint256, uint256, uint256, uint256);
    function getVaultEffectiveNotionals(address vaultOwner, bool collateralizationRatios) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function calculateNotionals(address asset, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function calculateEffectiveNotionals(address asset, HubSpokeStructs.DenormalizedVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function invertNotionals(address asset, HubSpokeStructs.NotionalVaultAmount memory realValues) external view returns (HubSpokeStructs.DenormalizedVaultAmount memory);
    function applyCollateralizationRatios(address asset, HubSpokeStructs.NotionalVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function removeCollateralizationRatios(address asset, HubSpokeStructs.NotionalVaultAmount memory vaultAmount) external view returns (HubSpokeStructs.NotionalVaultAmount memory);
    function checkAllowedToDeposit(address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function checkAllowedToWithdraw(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function checkAllowedToBorrow(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function checkAllowedToRepay(address vaultOwner, address assetAddress, uint256 assetAmount, bool shouldRevert) external view returns (bool success, string memory error);
    function getHub() external view returns (IHub);
    function setHub(IHub _hub) external;
    function getPriceOracle() external view returns (ISynonymPriceOracle);
    function setPriceOracle(ISynonymPriceOracle _priceOracle) external;
    function getPriceStandardDeviations() external view returns (uint256, uint256);
    function setPriceStandardDeviations(uint256 _priceStandardDeviations, uint256 _precision) external;
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../contracts/HubSpokeStructs.sol";

interface ILiquidationCalculator {
    /**
     * @param assetAddress - The address of the repaid/received asset
     * @param repaidAmount - The amount of the asset that is being repaid (can be zero)
     * @param receivedAmount - The amount of the asset that is being received (can be zero)
     * @param depositTakeover - A flag if the liquidator will take the deposit of the debtor instead of collateral tokens
     */
    struct DenormalizedLiquidationAsset {
        address assetAddress;
        uint256 repaidAmount;
        uint256 receivedAmount;
        bool depositTakeover;
    }

    /**
     * @param vault - the address of the vault that is being liquidated
     */
    struct LiquidationInput {
        address vault;
        DenormalizedLiquidationAsset[] assets;
    }

    function checkLiquidationInputsValid(LiquidationInput memory input) external view;
    function checkAllowedToLiquidate(LiquidationInput memory input) external view;
    function getMaxHealthFactor() external view returns (uint256, uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ISynonymPriceSource} from "./ISynonymPriceSource.sol";

interface ISynonymPriceOracle is ISynonymPriceSource {
    struct PriceSource {
        ISynonymPriceSource priceSource;
        uint256 maxPriceAge;
    }

    function getPrice(address _asset) external view returns (Price memory price);
    function setPriceSource(address _asset, PriceSource memory _priceSource) external;
    function removePriceSource(address _asset) external;
    function getPriceSource(address _asset) external view returns (PriceSource memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISynonymPriceSource {
    error NoPriceForAsset();
    error StalePrice();

    struct Price {
        uint256 price;
        uint256 confidence;
        uint256 precision;
        uint256 updatedAt;
    }

    function getPrice(address _asset, uint256 _maxAge) external view returns (Price memory price);
    function priceAvailable(address _asset) external view returns (bool);
    function outputAsset() external view returns (string memory);
}