// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title HubSpokeStructs
 * @notice A set of structs and enums used in the Hub and Spoke contracts
 */
contract HubSpokeStructs {
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

    enum Action {
        Deposit,
        Borrow,
        Withdraw,
        Repay,
        DepositNative,
        RepayNative
    }

    enum Round {
        UP,
        DOWN
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../HubSpokeStructs.sol";
import "../../interfaces/IInterestRateCalculator.sol";
import "../../interfaces/IHubPriceUtilities.sol";
import "../../interfaces/IHub.sol";
import "../../interfaces/IAssetRegistry.sol";

contract HubHelperViews {

    IHub hub;

    constructor(address _hub) {
        hub = IHub(_hub);
    }

    /**
     * @dev Get the maximum amount of an asset that can be borrowed by a vault owner
     *
     * @param vaultOwner - The address of the owner of the vault
     * @param assetAddress - The address of the relevant asset
     * @param minHealth - The minimum health of the vault after the borrow
     * @param minHealthPrecision - The precision of the minimum health
     * @return maxBorrowableAmount - The maximum amount of the asset that can be borrowed by the vault owner
     */
    function getMaxBorrowableAmount(address vaultOwner, address assetAddress, uint256 minHealth, uint256 minHealthPrecision) external view returns (uint256) {
        // calculate max borrowable amount without a preceding deposit change (0 for amount and whatever for deposit/withdrawal boolean)
        return calculateMaxBorrowableAmount(0, assetAddress, vaultOwner, true, minHealth, minHealthPrecision);
    }

    /**
     * @notice Get the maximum amount of an asset that can be borrowed by a vault owner after a deposit or withdrawal
     *
     * @param assetAmount - The amount of the asset that is being deposited or withdrawn
     * @param assetAddress - The address of the relevant asset
     * @param vaultOwner - The address of the owner of the vault
     * @param deposit - Whether or not the transaction is a deposit or withdrawal
     * @param minHealth - The minimum health of the vault after the borrow
     * @param minHealthPrecision - The precision of the minimum health
     * @return maxBorrowableAmount - The maximum amount of the asset that can be borrowed by the vault owner
     */
    function calculateMaxBorrowableAmount(uint256 assetAmount, address assetAddress, address vaultOwner, bool deposit, uint256 minHealth, uint256 minHealthPrecision)
        public
        view
        returns (uint256 maxBorrowableAmount)
    {
        IHubPriceUtilities hubPriceUtilities = IHubPriceUtilities(address(hub.getPriceUtilities()));
        (, maxBorrowableAmount) = hubPriceUtilities.calculateMaxWithdrawableAndBorrowableAmounts(
            assetAmount, assetAddress, vaultOwner, deposit
        );
        if (minHealth > minHealthPrecision) {
            maxBorrowableAmount = _limitToMinHealth(
                hubPriceUtilities,
                HubSpokeStructs.DenormalizedVaultAmount(0, maxBorrowableAmount),
                assetAddress,
                vaultOwner,
                minHealth,
                minHealthPrecision
            ).borrowed;
        }
    }

    /**
     *
     * @param hubPriceUtilities HubPriceUtilities contract
     * @param _amounts max withdrawable and borrowable amounts from hubPriceUtilities.calculateMaxWithdrawableAndBorrowableAmounts
     * @param _assetAddress the address of the asset
     * @param _vaultOwner the owner of the vault
     * @param _minHealth minimum target health of the vault after withdrawal/borrow
     * @param _minHealthPrecision the precision with which _minHealth is expressed
     */
    function _limitToMinHealth(
        IHubPriceUtilities hubPriceUtilities,
        HubSpokeStructs.DenormalizedVaultAmount memory _amounts,
        address _assetAddress,
        address _vaultOwner,
        uint256 _minHealth,
        uint256 _minHealthPrecision
    ) internal view returns (HubSpokeStructs.DenormalizedVaultAmount memory _amountsLimited) {
        require(_minHealth >= _minHealthPrecision, "HubHelperViews: minHealth must be greater than or equal to minHealthPrecision");

        // get the notionals of the whole account
        HubSpokeStructs.NotionalVaultAmount memory notionals = hubPriceUtilities.getVaultEffectiveNotionals(_vaultOwner, true);
        if (notionals.deposited * _minHealthPrecision <= notionals.borrowed * _minHealth) {
            // if the vault is already below the target health, return zero amounts
            return _amountsLimited;
        }

        // start with the given amounts
        _amountsLimited = _amounts;
        // get the notional value of passed amounts
        HubSpokeStructs.NotionalVaultAmount memory amountNotionals = hubPriceUtilities.calculateEffectiveNotionals(_assetAddress, _amounts);
        // this will not underflow beacause of the previous check
        // get the maximum notional value that is withdrawable or borrowable given the minHealth
        uint256 maxNotionalWithdrawRetainingHealth = notionals.deposited - (notionals.borrowed * _minHealth / _minHealthPrecision);

        // notionals.deposited >= (notionals.borrowed + maxNotionalBorrowRetainingHealth) * _minHealth / _minHealthPrecision
        // notionals.deposited * _minHealthPrecision / _minHealth - notionals.borrowed >= maxNotionalBorrowRetainingHealth
        uint256 maxNotionalBorrowRetainingHealth = notionals.deposited * _minHealthPrecision / _minHealth - notionals.borrowed;
        if (notionals.borrowed == 0) {
            // no debt. leave withdrawal as is.
            // set borrow to max that would retain health
            _amountsLimited.borrowed = hubPriceUtilities.invertNotionals(_assetAddress, hubPriceUtilities.removeCollateralizationRatios(
                _assetAddress, HubSpokeStructs.NotionalVaultAmount(0, notionals.deposited * _minHealthPrecision / _minHealth)
            )).borrowed;
        } else if (amountNotionals.deposited > maxNotionalWithdrawRetainingHealth || amountNotionals.borrowed > maxNotionalBorrowRetainingHealth) {
            // at least one of the amounts is too high
            // get the max amounts that would retain health
            HubSpokeStructs.DenormalizedVaultAmount memory maxAmounts = hubPriceUtilities.invertNotionals(_assetAddress, hubPriceUtilities.removeCollateralizationRatios(
                _assetAddress, HubSpokeStructs.NotionalVaultAmount(maxNotionalWithdrawRetainingHealth, maxNotionalBorrowRetainingHealth)
            ));
            if (amountNotionals.deposited > maxNotionalWithdrawRetainingHealth) {
                _amountsLimited.deposited = maxAmounts.deposited;
            }
            if (amountNotionals.borrowed > maxNotionalBorrowRetainingHealth) {
                _amountsLimited.borrowed = maxAmounts.borrowed;
            }
        }
    }

    /**
     * @notice Get the maximum amount of an asset that can be withdrawn by a vault owner
     *
     * @param vaultOwner - The address of the owner of the vault
     * @param assetAddress - The address of the relevant asset
     * @param minHealth - The minimum health of the vault after the withdrawal
     * @param minHealthPrecision - The precision of the minimum health
     * @return maxWithdrawableAmount - The maximum amount of the asset that can be withdrawn by the vault owner
     */
    function getMaxWithdrawableAmount(address vaultOwner, address assetAddress, uint256 minHealth, uint256 minHealthPrecision)
        external
        view
        returns (uint256 maxWithdrawableAmount)
    {
        IHubPriceUtilities hubPriceUtilities = IHubPriceUtilities(address(hub.getPriceUtilities()));
        // calculate max withdrawable amount without a preceding deposit change (0 for amount and whatever for deposit/withdrawal boolean)
        (maxWithdrawableAmount,) = hubPriceUtilities.calculateMaxWithdrawableAndBorrowableAmounts(0, assetAddress, vaultOwner, true);
        if (minHealth > minHealthPrecision) {
            maxWithdrawableAmount = _limitToMinHealth(
                hubPriceUtilities,
                HubSpokeStructs.DenormalizedVaultAmount(maxWithdrawableAmount, 0),
                assetAddress,
                vaultOwner,
                minHealth,
                minHealthPrecision
            ).deposited;
        }
    }

    /**
     * @notice Get the current interest rate for an asset
     *
     * @param assetAddress - the address of the asset
     * @return IInterestRateCalculator.InterestRates The current deposit interest rate for the asset, multiplied by rate precision
     */
    function getCurrentInterestRate(address assetAddress) external view returns (IInterestRateCalculator.InterestRates memory) {
        IAssetRegistry assetRegistry = IAssetRegistry(hub.getAssetRegistry());
        HubSpokeStructs.AssetInfo memory assetInfo = assetRegistry.getAssetInfo(assetAddress);
        IInterestRateCalculator assetCalculator = IInterestRateCalculator(assetInfo.interestRateCalculator);
        HubSpokeStructs.DenormalizedVaultAmount memory denormalizedGlobals = hub.getGlobalAmounts(assetAddress);
        return assetCalculator.currentInterestRate(denormalizedGlobals);
    }

    /**
     * @notice Get the reserve factor and precision for a given asset
     *
     * @param asset - The address of the asset
     * @return reserveFactor - The reserve factor for the asset
     * @return reservePrecision - The precision of the reserve factor
     */
    function getReserveFactor(address asset) external view returns (uint256, uint256) {
        IAssetRegistry assetRegistry = IAssetRegistry(hub.getAssetRegistry());
        HubSpokeStructs.AssetInfo memory assetInfo = assetRegistry.getAssetInfo(asset);
        address assetCalculator = assetInfo.interestRateCalculator;
        return IInterestRateCalculator(assetCalculator).getReserveFactorAndPrecision();
    }

    /**
     * @notice Get a user's account balance in an asset
     *
     * @param vaultOwner - the address of the user
     * @param assetAddress - the address of the asset
     * @return VaultAmount a struct with 'deposited' field and 'borrowed' field for the amount deposited and borrowed of the asset
     * multiplied by 10^decimal for that asset. Values are denormalized.
     */
    function getUserBalance(address vaultOwner, address assetAddress)
        public
        view
        returns (HubSpokeStructs.DenormalizedVaultAmount memory)
    {
        return hub.getVaultAmounts(vaultOwner, assetAddress);
    }

    /**
     * @notice Get the protocol's global balance in an asset
     *
     * @param assetAddress - the address of the asset
     * @return VaultAmount a struct with 'deposited' field and 'borrowed' field for the amount deposited and borrowed of the asset
     * multiplied by 10^decimal for that asset. Values are denormalized.
     */
    function getGlobalBalance(address assetAddress) public view returns (HubSpokeStructs.DenormalizedVaultAmount memory) {
        return hub.getGlobalAmounts(assetAddress);
    }

    /**
     * @notice Get the protocol's global reserve amount in an asset
     *
     * @param assetAddress - the address of the asset
     * @return uint256 The amount of the asset in the protocol's reserve
     */
    function getReserveAmount(address assetAddress) external view returns (uint256) {
        return hub.getReserveAmount(assetAddress);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "@wormhole-upgradeable/interfaces/IWETH.sol";
import "../contracts/HubSpokeStructs.sol";

interface IAssetRegistry {
    function registerAsset(
        address assetAddress,
        uint256 collateralizationRatioDeposit,
        uint256 collateralizationRatioBorrow,
        address interestRateCalculator,
        uint256 maxLiquidationPortion,
        uint256 maxLiquidationBonus
    ) external;

    function getAssetInfo(address assetAddress) external view returns (HubSpokeStructs.AssetInfo memory);

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
    function calculateMaxWithdrawableAndBorrowableAmounts(uint256 assetAmount, address assetAddress, address vaultOwner, bool deposit) external view returns (uint256, uint256);
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
    function getPriceSource() external view returns (ISynonymPriceOracle.PriceSource);
    function setPriceSource(ISynonymPriceOracle.PriceSource _priceSource) external;
}

// contracts/Bridge.sol
// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "../contracts/HubSpokeStructs.sol";

interface IInterestRateCalculator {
    struct InterestRates {
        uint256 depositRate;
        uint256 borrowRate;
        uint256 precision;
    }

    struct InterestRateBase {
        uint256 interestRate;
        uint256 precision;
    }

    /**
     * @notice Computes the source interest factor
     * @param secondsElapsed The number of seconds elapsed
     * @param globalAssetAmount The global denormalized asset amounts
     * @param interestAccrualIndexPrecision The precision of the interest accrual index
     * @return depositInterestFactor interest factor for deposits
     * @return borrowInterestFactor interest factor for borrows
     * @return precision precision
     */
    function computeSourceInterestFactor(
        uint256 secondsElapsed,
        HubSpokeStructs.DenormalizedVaultAmount memory globalAssetAmount,
        uint256 interestAccrualIndexPrecision
    ) external view returns (uint256 depositInterestFactor, uint256 borrowInterestFactor, uint256 precision);

    /**
     * @notice utility function to return current APY for an asset
     * @param globalAssetAmount The global denormalized amounts of the asset
     * @return interestRates rate * model.ratePrecision
     */
    function currentInterestRate(HubSpokeStructs.DenormalizedVaultAmount memory globalAssetAmount)
        external
        view
        returns (InterestRates memory);

    function getReserveFactorAndPrecision() external view returns (uint256 reserveFactor, uint256 reservePrecision);

    function getInterestRateFromPoolUtilization(HubSpokeStructs.DenormalizedVaultAmount memory globalAssetAmount) view external returns (InterestRateBase memory);
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

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ISynonymPriceOracle {
    enum PriceSource {
        PYTH,
        CHAINLINK
    }

    struct Price {
        uint256 price;
        uint256 confidence;
        uint256 precision;
    }

    function priceSourceAvailable(address _asset, PriceSource _source) external view returns (bool);
    function getPrice(address _asset, PriceSource _source) external view returns (Price memory price);
    function setPyth(IPyth _pyth) external;
    function setPriceSource(address _asset, bytes32 _pythId, uint256 _maxPythPriceAge, AggregatorV3Interface _chainlinkAggregator, uint256 _maxChainlinkPriceAge) external;
}