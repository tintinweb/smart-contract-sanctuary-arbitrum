// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

interface AccessControllerInterface {
    function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.7.6;

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
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IFastPriceFeed {
    function setPrices(address sender, uint8 priceType, bytes memory offChainPrices) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC165.sol";
import "../libraries/Common.sol";
import "./IVerifierFeeManager.sol";

interface IFeeManager is IERC165, IVerifierFeeManager {
    /**
     * @notice Calculate the applied fee and the reward from a report. If the sender is a subscriber, they will receive a discount.
   * @param subscriber address trying to verify
   * @param report report to calculate the fee for
   * @param quoteAddress address of the quote payment token
   * @return (fee, reward, totalDiscount) fee and the reward data with the discount applied
   */
    function getFeeAndReward(
        address subscriber,
        bytes memory report,
        address quoteAddress
    ) external returns (Common.Asset memory, Common.Asset memory, uint256);

    /**
     * @notice Sets the native surcharge
   * @param surcharge surcharge to be paid if paying in native
   */
    function setNativeSurcharge(uint64 surcharge) external;

    /**
     * @notice Adds a subscriber to the fee manager
   * @param subscriber address of the subscriber
   * @param feedId feed id to apply the discount to
   * @param token token to apply the discount to
   * @param discount discount to be applied to the fee
   */
    function updateSubscriberDiscount(address subscriber, bytes32 feedId, address token, uint64 discount) external;

    /**
     * @notice Withdraws any native or LINK rewards to the owner address
   * @param assetAddress address of the asset to withdraw
   * @param recipientAddress address to withdraw to
   * @param quantity quantity to withdraw
   */
    function withdraw(address assetAddress, address recipientAddress, uint192 quantity) external;

    /**
     * @notice Returns the link balance of the fee manager
   * @return link balance of the fee manager
   */
    function linkAvailableForPayment() external returns (uint256);

    /**
     * @notice Admin function to pay the LINK deficit for a given config digest
   * @param configDigest the config digest to pay the deficit for
   */
    function payLinkDeficit(bytes32 configDigest) external;

    function i_linkAddress() external view returns (address);

    function i_nativeAddress() external view returns (address);

    function i_rewardManager() external view returns (address);

    /**
     * @notice The structure to hold a fee and reward to verify a report
   * @param digest the digest linked to the fee and reward
   * @param fee the fee paid to verify the report
   * @param reward the reward paid upon verification
   & @param appliedDiscount the discount applied to the reward
   */
    struct FeeAndReward {
        bytes32 configDigest;
        Common.Asset fee;
        Common.Asset reward;
        uint256 appliedDiscount;
    }

    /**
     * @notice The structure to hold quote metadata
   * @param quoteAddress the address of the quote
   */
    struct Quote {
        address quoteAddress;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSuperSigner(address _signer) external view returns (bool);

    function checkSigner(address signer, uint8 sType) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkExecutorRouter(address _executorRouter) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function checkMarketLogic(address _logic) external view returns (bool);

    function checkMarketPriceFeed(address _feed) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused(address market) external view returns (bool);

    function isInterestPaused(address pool) external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkExecutor(address _executor, uint8 eType) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);

    function modifySingleInterestStatus(address pool, bool _interestPaused) external;

    function modifySingleFundingStatus(address market, bool _fundingPaused) external;
    
    function router() external view returns (address);

    function executorRouter() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "./IPriceHelper.sol";

interface IMarketPriceFeed {
    function priceForTrade(address pool, address market, string memory token, int8 takerDirection, uint256 deltaSize, uint256 deltaValue, bool isLiquidation) external returns (uint256 size, uint256 vol, uint256 tradePrice);

    function priceForPool(string memory _token, bool _maximise) external view returns (uint256);

    function priceForLiquidate(string memory _token, bool _maximise) external view returns (uint256);

    function priceForIndex(string memory _token, bool _maximise) external view returns (uint256);

    function getLatestPrimaryPrice(string memory _token) external view returns (uint256);

    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;

    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    function modifyMarketTickConfig(address pool, address market, string memory token, IPriceHelper.MarketTickConfig memory cfg) external;

    function getMarketPrice(address market, string memory _token, bool maximise) external view returns (uint256 marketPrice);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "../libraries/Tick.sol";

interface IPriceHelper {
    struct MarketTickConfig {
        bool isLinear;
        uint8 marketType;
        uint8 liquidationIndex;
        uint256 baseAssetDivisor;
        uint256 multiplier; // different precision from rate divisor
        uint256 maxLiquidity;
        Tick.Config[7] tickConfigs;
    }

    struct CalcTradeInfoParams {
        address pool;
        address market;
        uint256 indexPrice;
        bool isTakerLong;
        bool liquidation;
        uint256 deltaSize;
        uint256 deltaValue;
    }

    function calcTradeInfo(CalcTradeInfoParams memory params) external returns(uint256 deltaSize, uint256 volTotal, uint256 tradePrice);
    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;
    function modifyMarketTickConfig(address pool, address market, MarketTickConfig memory cfg, uint256 indexPrice) external;
    function getMarketPrice(address market, uint256 indexPrice) external view returns (uint256 marketPrice);
    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    event TickConfigChanged(address market, MarketTickConfig cfg);
    event TickInfoChanged(address market, uint8 index, uint256 size, uint256 premiumX96);
    event Slot0StateChanged(address market, uint256 netSize, uint256 premiumX96, bool isLong, uint8 currentTick);
    event LiquidationBufferSizeChanged(address market, uint8 index, uint256 bufferSize);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/PythStructs.sol";
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
pragma solidity 0.7.6;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "./IERC165.sol";
import "../libraries/Common.sol";

interface IVerifierFeeManager is IERC165 {
    /**
     * @notice Handles fees for a report from the subscriber and manages rewards
   * @param payload report to process the fee for
   * @param parameterPayload fee payload
   * @param subscriber address of the fee will be applied
   */
    function processFee(bytes calldata payload, bytes calldata parameterPayload, address subscriber) external payable;

    /**
     * @notice Processes the fees for each report in the payload, billing the subscriber and paying the reward manager
   * @param payloads reports to process
   * @param parameterPayload fee payload
   * @param subscriber address of the user to process fee for
   */
    function processFeeBulk(
        bytes[] calldata payloads,
        bytes calldata parameterPayload,
        address subscriber
    ) external payable;

    /**
     * @notice Sets the fee recipients according to the fee manager
   * @param configDigest digest of the configuration
   * @param rewardRecipientAndWeights the address and weights of all the recipients to receive rewards
   */
    function setFeeRecipients(
        bytes32 configDigest,
        Common.AddressAndWeight[] calldata rewardRecipientAndWeights
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/Common.sol";
import "./AccessControllerInterface.sol";
import "./IVerifierFeeManager.sol";

interface IVerifierProxy {
    /**
     * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payload The encoded data to be verified, including the signed
   * report.
   * @param parameterPayload fee metadata for billing
   * @return verifierResponse The encoded report from the verifier.
   */
    function verify(
        bytes calldata payload,
        bytes calldata parameterPayload
    ) external payable returns (bytes memory verifierResponse);

    /**
     * @notice Bulk verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payloads The encoded payloads to be verified, including the signed
   * report.
   * @param parameterPayload fee metadata for billing
   * @return verifiedReports The encoded reports from the verifier.
   */
    function verifyBulk(
        bytes[] calldata payloads,
        bytes calldata parameterPayload
    ) external payable returns (bytes[] memory verifiedReports);

    /**
     * @notice Sets the verifier address initially, allowing `setVerifier` to be set by this Verifier in the future
   * @param verifierAddress The address of the verifier contract to initialize
   */
    function initializeVerifier(address verifierAddress) external;

    /**
     * @notice Sets a new verifier for a config digest
   * @param currentConfigDigest The current config digest
   * @param newConfigDigest The config digest to set
   * @param addressesAndWeights The addresses and weights of reward recipients
   * reports for a given config digest.
   */
    function setVerifier(
        bytes32 currentConfigDigest,
        bytes32 newConfigDigest,
        Common.AddressAndWeight[] memory addressesAndWeights
    ) external;

    /**
     * @notice Removes a verifier for a given config digest
   * @param configDigest The config digest of the verifier to remove
   */
    function unsetVerifier(bytes32 configDigest) external;

    /**
     * @notice Retrieves the verifier address that verifies reports
   * for a config digest.
   * @param configDigest The config digest to query for
   * @return verifierAddress The address of the verifier contract that verifies
   * reports for a given config digest.
   */
    function getVerifier(bytes32 configDigest) external view returns (address verifierAddress);

    /**
     * @notice Called by the admin to set an access controller contract
   * @param accessController The new access controller to set
   */
    function setAccessController(AccessControllerInterface accessController) external;

    /**
     * @notice Updates the fee manager
   * @param feeManager The new fee manager
   */
    function setFeeManager(IVerifierFeeManager feeManager) external;

    function s_feeManager() external view returns (IVerifierFeeManager);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IWrappedCoin {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/*
 * @title Common
 * @author Michael Fletcher
 * @notice Common functions and structs
 */
library Common {
    // @notice The asset struct to hold the address of an asset and amount
    struct Asset {
        address assetAddress;
        uint256 amount;
    }

    // @notice Struct to hold the address and its associated weight
    struct AddressAndWeight {
        address addr;
        uint64 weight;
    }

    /**
     * @notice Checks if an array of AddressAndWeight has duplicate addresses
   * @param recipients The array of AddressAndWeight to check
   * @return bool True if there are duplicates, false otherwise
   */
    function hasDuplicateAddresses(Common.AddressAndWeight[] memory recipients) internal pure returns (bool) {
        for (uint256 i = 0; i < recipients.length;) {
            for (uint256 j = i + 1; j < recipients.length;) {
                if (recipients[i].addr == recipients[j].addr) {
                    return true;
                }
                ++j;
            }
            ++i;
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

library Constant {
    uint256 constant Q96 = 1 << 96;
    uint256 constant RATE_DIVISOR = 1e8;
    uint256 constant PRICE_DIVISOR = 1e10;// 1e10
    uint256 constant SIZE_DIVISOR = 1e20;// 1e20 for AMOUNT_PRECISION
    uint256 constant TICK_LENGTH = 7;
    uint256 constant MULTIPLIER_DIVISOR = 1e6;

    int256 constant FundingRate1_10000X96 = int256(Q96) * 1 / 10000;
    int256 constant FundingRate4_10000X96 = int256(Q96) * 4 / 10000;
    int256 constant FundingRate5_10000X96 = int256(Q96) * 5 / 10000;
    int256 constant FundingRate6_10000X96 = int256(Q96) * 6 / 10000;
    int256 constant FundingRateMaxX96 = int256(Q96) * 375 / 100000;
    int256 constant FundingRate8Hours = 8 hours;
    int256 constant FundingRate24Hours = 24 hours;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

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
pragma solidity 0.7.6;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "./Constant.sol";
import "./SafeMath.sol";

library Tick {
    using SafeMath for uint256;

    struct Info {
        uint256 size;
        uint256 premiumX96;
    }

    struct Config {
        uint32 sizeRate;
        uint32 premium;
    }

    function calcTickInfo(uint32 sizeRate, uint32 premium, bool isLinear, uint256 liquidity, uint256 indexPrice) internal pure returns (uint256 size, uint256 premiumX96){
        if(isLinear) {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(Constant.PRICE_DIVISOR).div(indexPrice);
        } else {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(indexPrice).div(Constant.PRICE_DIVISOR);
        }

        premiumX96 = uint256(premium).mul(Constant.Q96).div(Constant.RATE_DIVISOR);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IERC20.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // usdt of tron mainnet TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t: 0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c
        /*
        if (token == address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c)){
            IERC20(token).transfer(to, value);
            return;
        }
        */

        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/PythStructs.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Common.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IMarketPriceFeed.sol";
import "../interfaces/IFeeManager.sol";
import "../interfaces/IVerifierProxy.sol";
import "../interfaces/IFastPriceFeed.sol";
import "../interfaces/IPyth.sol";
import "../interfaces/IWrappedCoin.sol";

contract FastPriceFeed {
    using SafeMath for uint256;
    using SafeMath for uint32;

    uint256 public constant MAX_REF_PRICE = type(uint160).max;//max chainLink price
    uint256 public constant MAX_CUMULATIVE_REF_DELTA = type(uint32).max;//max cumulative chainLink price delta
    uint256 public constant MAX_CUMULATIVE_FAST_DELTA = type(uint32).max;//max cumulative fast price delta
    uint256 public constant CUMULATIVE_DELTA_PRECISION = 10 * 1000 * 1000;//cumulative delta precision
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;//basis points divisor
    uint256 public constant MAX_PRICE_DURATION = 30 minutes;//max price validity period 
    uint256 public constant PRICE_PRECISION = 10 ** 10;//price precision

    // fit data in a uint256 slot to save gas costs
    struct PriceDataItem {
        uint160 refPrice; // ChainLink price
        uint32 refTime; // last ChainLink price updated at time
        uint32 cumulativeRefDelta; // cumulative ChainLink price delta
        uint32 cumulativeFastDelta; // cumulative fast price delta
    }

    mapping(string => PriceDataItem) public priceData;//chainLink price data
    mapping(string => uint256) public prices;//offChain price data
    mapping(string => uint32) lastUpdatedAts;//last offChain price update time
    uint256 public lastUpdatedBlock;//last offChain price update block
    mapping(string => uint256) public maxCumulativeDeltaDiffs;//max cumulative delta diff,delta = (cumulativeFastDelta - cumulativeRefDelta)

    // should be 10 ** 8
    string[] public tokens;//index token
    mapping(bytes32 => string) public feedIds;
    mapping(bytes32 => string) public pythFeedIds;
    mapping(string => uint256) public backUpPricePrecisions;
    mapping(string => uint256) public primaryPricePrecisions;

    bool public isInitialized;//is initialized,only can be initialized once
    address public marketPriceFeed;//marketPriceFeed address

    //max diff between chainLink price and offChain price,if diff > maxDeviationBasisPoints then use chainLink price or offChain price
    uint256 public maxDeviationBasisPoints;
    //max diff between chainLink price and offChain price,if diff > maxDeviationBasisPoints then use chainLink price 
    uint256 public indexMaxDeviationBasisPoints;
    uint256 public priceDuration;//offChain validity period tradePrice,if delay > priceDuration then use chainLink price with 0.2% spreadBasisPoints 
    uint256 public indexPriceDuration;//offChain validity period for indexPrice
    //max offChain price update delay,if delay > maxPriceUpdateDelay then use chainLink price with 5% spreadBasisPoints 
    uint256 public maxPriceUpdateDelay;
    uint256 public spreadBasisPointsIfInactive = 20;
    uint256 public spreadBasisPointsIfChainError = 500;
    uint256 public minBlockInterval; //min block interval between two offChain price update
    uint256 public maxTimeDeviation = 3600;//max time deviation between offChain price update time and block timestamp
    uint256 public priceDataInterval = 60;//cumulative delta interval
    bool public isSpreadEnabled = false;//is spread enabled
    address public manager;

    address public WETH;
    IVerifierProxy public verifier;
    IPyth public pyth;
    uint256 public maxPriceTsDiff;//max price timestamp diff

    struct PremiumReport {
        bytes32 feedId; // The feed ID the report has data for
        uint32 validFromTimestamp; // Earliest timestamp for which price is applicable
        uint32 observationsTimestamp; // Latest timestamp for which price is applicable
        uint192 nativeFee; // Base cost to validate a transaction using the report, denominated in the chain’s native token (WETH/ETH)
        uint192 linkFee; // Base cost to validate a transaction using the report, denominated in LINK
        uint64 expiresAt; // Latest timestamp where the report can be verified on-chain
        int192 price; // DON consensus median price, carried to 8 decimal places
        int192 bid; // Simulated price impact of a buy order up to the X% depth of liquidity utilisation
        int192 ask; // Simulated price impact of a sell order up to the X% depth of liquidity utilisation
    }

    event PriceData(string token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event MaxCumulativeDeltaDiffExceeded(string token, uint256 refPrice, uint256 fastPrice, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta);
    event PriceUpdated(string _token, uint256 _price);
    event SetMarketPriceFeed(address _marketPriceFeed);
    event SetMaxTimeDeviation(uint256 _maxTimeDeviation);
    event SetPriceDuration(uint256 _priceDuration, uint256 _indexPriceDuration);
    event SetMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay);
    event SetMinBlockInterval(uint256 _minBlockInterval);
    event SetMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints);
    event SetSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive);
    event SetSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError);
    event SetPriceDataInterval(uint256 _priceDataInterval);
    event SetVerifier(IVerifierProxy verifier);
    event SetIsSpreadEnabled(bool _isSpreadEnabled);
    event SetTokens(string[] _tokens, bytes32[] _feedIds, bytes32[] _pythFeedIds, uint256[] _backUpPricePrecisions, uint256[] _primaryPricePrecisions);
    event SetLastUpdatedAt(string token, uint256 lastUpdatedAt);
    event SetMaxCumulativeDeltaDiff(string token, uint256 maxCumulativeDeltaDiff);
    event fallbackCalled(address sender, uint256 value, bytes data);
    event SetPyth(IPyth _pyth);
    event SetMaxPriceTsDiff(uint256 _maxPriceTsDiff);

    modifier onlyExecutorRouter() {
        require(IManager(manager).checkExecutorRouter(msg.sender), "FastPriceFeed: forbidden");
        _;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "FastPriceFeed: Must be controller");
        _;
    }

    modifier onlyTreasurer() {
        require(IManager(manager).checkTreasurer(msg.sender), "FastPriceFeed: Must be treasurer");
        _;
    }

    constructor(
        address _WETH,
        address _manager,
        uint256 _priceDuration,
        uint256 _indexPriceDuration,
        uint256 _maxPriceUpdateDelay,
        uint256 _minBlockInterval,
        uint256 _maxDeviationBasisPoints,
        uint256 _indexMaxDeviationBasisPoints
    ) {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        require(_indexPriceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _indexPriceDuration");
        require(_manager != address(0) && _WETH != address(0), "FastPriceFeed: invalid address");
        WETH = _WETH;
        manager = _manager;
        priceDuration = _priceDuration;
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        minBlockInterval = _minBlockInterval;
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        indexMaxDeviationBasisPoints = _indexMaxDeviationBasisPoints;
        indexPriceDuration = _indexPriceDuration;
    }

    function setMarketPriceFeed(address _marketPriceFeed) external onlyController {
        require(_marketPriceFeed != address(0), "FastPriceFeed: invalid _marketPriceFeed");
        marketPriceFeed = _marketPriceFeed;
        emit SetMarketPriceFeed(_marketPriceFeed);
    }

    function setMaxTimeDeviation(uint256 _maxTimeDeviation) external onlyController {
        maxTimeDeviation = _maxTimeDeviation;
        emit SetMaxTimeDeviation(_maxTimeDeviation);
    }

    function setPriceDuration(uint256 _priceDuration, uint256 _indexPriceDuration) external onlyController {
        require(_priceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _priceDuration");
        require(_indexPriceDuration <= MAX_PRICE_DURATION, "FastPriceFeed: invalid _indexPriceDuration");
        priceDuration = _priceDuration;
        indexPriceDuration = _indexPriceDuration;
        emit SetPriceDuration(_priceDuration, _indexPriceDuration);
    }

    function setMaxPriceUpdateDelay(uint256 _maxPriceUpdateDelay) external onlyController {
        maxPriceUpdateDelay = _maxPriceUpdateDelay;
        emit SetMaxPriceUpdateDelay(_maxPriceUpdateDelay);
    }

    function setSpreadBasisPointsIfInactive(uint256 _spreadBasisPointsIfInactive) external onlyController {
        spreadBasisPointsIfInactive = _spreadBasisPointsIfInactive;
        emit SetSpreadBasisPointsIfInactive(_spreadBasisPointsIfInactive);
    }

    function setSpreadBasisPointsIfChainError(uint256 _spreadBasisPointsIfChainError) external onlyController {
        spreadBasisPointsIfChainError = _spreadBasisPointsIfChainError;
        emit SetSpreadBasisPointsIfChainError(_spreadBasisPointsIfChainError);
    }

    function setMinBlockInterval(uint256 _minBlockInterval) external onlyController {
        minBlockInterval = _minBlockInterval;
        emit SetMinBlockInterval(_minBlockInterval);
    }

    function setIsSpreadEnabled(bool _isSpreadEnabled) external onlyController {
        isSpreadEnabled = _isSpreadEnabled;
        emit SetIsSpreadEnabled(_isSpreadEnabled);
    }

    function setLastUpdatedAt(string memory _token, uint32 _lastUpdatedAt) external onlyController {
        lastUpdatedAts[_token] = _lastUpdatedAt;
        emit  SetLastUpdatedAt(_token, _lastUpdatedAt);
    }

    function setMaxDeviationBasisPoints(uint256 _maxDeviationBasisPoints, uint256 _indexMaxDeviationBasisPoints) external onlyController {
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        indexMaxDeviationBasisPoints = _indexMaxDeviationBasisPoints;
        emit SetMaxDeviationBasisPoints(_maxDeviationBasisPoints);
    }

    function setMaxCumulativeDeltaDiffs(string[] memory _tokens, uint256[] memory _maxCumulativeDeltaDiffs) external onlyController {
        for (uint256 i = 0; i < _tokens.length; i++) {
            string memory token = _tokens[i];
            maxCumulativeDeltaDiffs[token] = _maxCumulativeDeltaDiffs[i];
            emit SetMaxCumulativeDeltaDiff(token, _maxCumulativeDeltaDiffs[i]);
        }
    }

    function setPriceDataInterval(uint256 _priceDataInterval) external onlyController {
        priceDataInterval = _priceDataInterval;
        emit SetPriceDataInterval(_priceDataInterval);
    }

    function setVerifier(IVerifierProxy _verifier) external onlyController {
        verifier = _verifier;
        emit SetVerifier(verifier);
    }

    function setPyth(IPyth _pyth) external onlyController {
        pyth = _pyth;
        emit SetPyth(_pyth);
    }

    function setMaxPriceTsDiff(uint256 _maxPriceTsDiff) external onlyController {
        maxPriceTsDiff = _maxPriceTsDiff;
        emit SetMaxPriceTsDiff(_maxPriceTsDiff);
    }

    function withdrawVerifyingFee(address _to) external onlyTreasurer {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(_to).transfer(balance);
        }
    }

    function setTokens(string[] memory _tokens, bytes32[] memory _feedIds, bytes32[] memory _pythFeedIds, uint256[] memory _backUpPricePrecisions, uint256[] memory _primaryPricePrecisions) external onlyController {
        require(_tokens.length == _pythFeedIds.length, "FastPriceFeed: invalid pyth feed id lengths");
        require(_tokens.length == _feedIds.length, "FastPriceFeed: invalid feed id lengths");
        require(_tokens.length == _backUpPricePrecisions.length, "FastPriceFeed: invalid backUpPricePrecisions lengths");
        require(_tokens.length == _primaryPricePrecisions.length, "FastPriceFeed: invalid primaryPricePrecisions lengths");
        tokens = _tokens;
        for (uint256 i = 0; i < tokens.length; ++i) {
            feedIds[_feedIds[i]] = tokens[i];
            backUpPricePrecisions[tokens[i]] = _backUpPricePrecisions[i];
            primaryPricePrecisions[tokens[i]] = _primaryPricePrecisions[i];
            pythFeedIds[_pythFeedIds[i]] = tokens[i];
        }

        emit SetTokens(_tokens, _feedIds, _pythFeedIds, _backUpPricePrecisions, _primaryPricePrecisions);
    }

    /// @notice off-chain price update
    /// @param sender price data sender
    /// @param priceType price type {0:backup price;1:pyth price;2:data stream price}
    /// @param offChainPrices off-chain price array
    function setPrices(address sender, uint8 priceType, bytes memory offChainPrices) external onlyExecutorRouter {
        uint256 price;
        bool shouldUpdate;
        require(priceType == 0 || priceType == 1 || priceType == 2, "FastPriceFeed: invalid prices type");
        if (priceType == 0) {
            bytes[] memory _backupPrices = abi.decode(offChainPrices, (bytes[]));
            for (uint256 i = 0; i < _backupPrices.length; i++) {
                (string memory token, uint192 backUpPrice, uint32 ts) = abi.decode(_backupPrices[i], (string, uint192, uint32));
                shouldUpdate = _setLastUpdatedValues(token, ts);
                if (shouldUpdate) {
                    price = backUpPrice;
                    if (price > 0) {
                        price = price.mul(PRICE_PRECISION).div(10 ** backUpPricePrecisions[token]);
                        _setPrice(token, price, marketPriceFeed);
                    }
                }
            }
        } else if (priceType == 1) {
            (bytes32[] memory _priceIds, bytes[] memory _priceUpdateData) = abi.decode(offChainPrices, (bytes32[], bytes[]));
            uint256 fee = pyth.getUpdateFee(_priceUpdateData);
            TransferHelper.safeTransferFrom(WETH, sender, address(this), fee);
            IWrappedCoin(WETH).withdraw(fee);
            PythStructs.PriceFeed[] memory _priceFeed = pyth.parsePriceFeedUpdates{value: fee}(_priceUpdateData, _priceIds, uint64(block.timestamp.sub(maxPriceTsDiff)), uint64(block.timestamp));

            for (uint256 i = 0; i < _priceIds.length; i++) {
                string memory token = pythFeedIds[_priceIds[i]];
                require(_priceFeed[i].price.price > 0 && _priceFeed[i].price.expo <= 0, "FastPriceFeed: invalid price");

                shouldUpdate = _setLastUpdatedValues(token, uint32(_priceFeed[i].price.publishTime));
                if (shouldUpdate) {
                    price = uint256(_priceFeed[i].price.price);
                    price = price.mul(PRICE_PRECISION).div(10 ** uint32(- _priceFeed[i].price.expo));
                    _setPrice(token, price, marketPriceFeed);
                }
            }
        } else {
            bytes[] memory _signedReports = abi.decode(offChainPrices, (bytes[]));
            IFeeManager feeManager = IFeeManager(address(verifier.s_feeManager()));
            address feeNativeTokenAddress = feeManager.i_nativeAddress();
            uint256 feeCost;
            for (uint256 i = 0; i < _signedReports.length; i++) {
                (PremiumReport memory basicReport, uint256 fee) = _calcVerifyFee(_signedReports[i], feeManager, feeNativeTokenAddress);
                feeCost = feeCost.add(fee);
                shouldUpdate = _setLastUpdatedValues(feedIds[basicReport.feedId], basicReport.validFromTimestamp);
                if (shouldUpdate) {
                    require(basicReport.price > 0, "FastPriceFeed: invalid price");
                    price = uint256(basicReport.price);
                    price = price.mul(PRICE_PRECISION).div(10 ** primaryPricePrecisions[feedIds[basicReport.feedId]]);
                    _setPrice(feedIds[basicReport.feedId], price, marketPriceFeed);
                }
            }

            // Verify the reports
            TransferHelper.safeTransferFrom(WETH, sender, address(this), feeCost);
            IWrappedCoin(WETH).withdraw(feeCost);
            verifier.verifyBulk{value: feeCost}(_signedReports, abi.encode(feeNativeTokenAddress));
        }
    }

    function _calcVerifyFee(bytes memory unverifiedReport, IFeeManager feeManager, address feeNativeTokenAddress) internal returns (PremiumReport memory basicReport, uint256 feeCost){
        (, /* bytes32[3] reportContextData */ bytes memory reportData) = abi.decode(unverifiedReport, (bytes32[3], bytes));
        basicReport = abi.decode(reportData, (PremiumReport));
        require(block.timestamp <= basicReport.validFromTimestamp.add(maxPriceTsDiff) && basicReport.expiresAt >= block.timestamp, "FastPriceFeed: invalid price ts");

        // Report verification fees
        (Common.Asset memory fee, ,) = feeManager.getFeeAndReward(
            address(this),
            reportData,
            feeNativeTokenAddress
        );

        feeCost = fee.amount;
    }

    // under regular operation, the fastPrice (prices[token]) is returned and there is no spread returned from this function,
    // though VaultPriceFeed might apply its own spread
    //
    // if the fastPrice has not been updated within priceDuration then it is ignored and only _refPrice with a spread is used (spread: spreadBasisPointsIfInactive)
    // in case the fastPrice has not been updated for maxPriceUpdateDelay then the _refPrice with a larger spread is used (spread: spreadBasisPointsIfChainError)
    //
    // there will be a spread from the _refPrice to the fastPrice in the following cases:
    // - in case isSpreadEnabled is set to true
    // - in case the maxDeviationBasisPoints between _refPrice and fastPrice is exceeded
    // - in case watchers flag an issue
    // - in case the cumulativeFastDelta exceeds the cumulativeRefDelta by the maxCumulativeDeltaDiff
    function getPrice(string memory _token, uint256 _refPrice, bool _maximise) external view returns (uint256) {
        if (block.timestamp > uint256(lastUpdatedAts[_token]).add(maxPriceUpdateDelay)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
            }
            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfChainError)).div(BASIS_POINTS_DIVISOR);
        }

        if (block.timestamp > uint256(lastUpdatedAts[_token]).add(priceDuration)) {
            if (_maximise) {
                return _refPrice.mul(BASIS_POINTS_DIVISOR.add(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
            }
            return _refPrice.mul(BASIS_POINTS_DIVISOR.sub(spreadBasisPointsIfInactive)).div(BASIS_POINTS_DIVISOR);
        }

        uint256 fastPrice = prices[_token];

        if (fastPrice == 0) {return _refPrice;}
        uint256 diffBasisPoints = _refPrice > fastPrice ? _refPrice.sub(fastPrice) : fastPrice.sub(_refPrice);
        diffBasisPoints = diffBasisPoints.mul(BASIS_POINTS_DIVISOR).div(_refPrice);

        // create a spread between the _refPrice and the fastPrice if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the fast price
        bool hasSpread = !favorFastPrice(_token) || diffBasisPoints > maxDeviationBasisPoints;

        if (hasSpread) {
            // return the higher of the two prices
            if (_maximise) {
                return _refPrice > fastPrice ? _refPrice : fastPrice;
            }

            // return the lower of the two prices
            //min price
            return _refPrice < fastPrice ? _refPrice : fastPrice;
        }

        return fastPrice;
    }

    function favorFastPrice(string memory _token) public view returns (bool) {
        if (isSpreadEnabled) {
            return false;
        }

        (/* uint256 prevRefPrice */, /* uint256 refTime */, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);
        if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
            // force a spread if the cumulative delta for the fast price feed exceeds the cumulative delta
            // for the Chainlink price feed by the maxCumulativeDeltaDiff allowed
            return false;
        }

        return true;
    }

    function getIndexPrice(string memory _token, uint256 _refPrice, bool /* _maximise*/) external view returns (uint256) {
        if (block.timestamp > uint256(lastUpdatedAts[_token]).add(indexPriceDuration)) {
            return _refPrice;
        }

        uint256 fastPrice = prices[_token];
        if (fastPrice == 0) return _refPrice;

        uint256 diffBasisPoints = _refPrice > fastPrice ? _refPrice.sub(fastPrice) : fastPrice.sub(_refPrice);
        diffBasisPoints = diffBasisPoints.mul(BASIS_POINTS_DIVISOR).div(_refPrice);

        // create a spread between the _refPrice and the fastPrice if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the fast price
        if (diffBasisPoints > indexMaxDeviationBasisPoints) {
            return _refPrice;
        }

        return fastPrice;
    }

    function getPriceData(string memory _token) public view returns (uint256, uint256, uint256, uint256) {
        PriceDataItem memory data = priceData[_token];
        return (uint256(data.refPrice), uint256(data.refTime), uint256(data.cumulativeRefDelta), uint256(data.cumulativeFastDelta));
    }

    function _setPrice(string memory _token, uint256 _price, address _marketPriceFeed) internal {
        if (_marketPriceFeed != address(0)) {
            uint256 refPrice = IMarketPriceFeed(_marketPriceFeed).getLatestPrimaryPrice(_token);
            uint256 fastPrice = prices[_token];
            (uint256 prevRefPrice, uint256 refTime, uint256 cumulativeRefDelta, uint256 cumulativeFastDelta) = getPriceData(_token);

            if (prevRefPrice > 0) {
                uint256 refDeltaAmount = refPrice > prevRefPrice ? refPrice.sub(prevRefPrice) : prevRefPrice.sub(refPrice);
                uint256 fastDeltaAmount = fastPrice > _price ? fastPrice.sub(_price) : _price.sub(fastPrice);

                // reset cumulative delta values if it is a new time window
                if (refTime.div(priceDataInterval) != block.timestamp.div(priceDataInterval)) {
                    cumulativeRefDelta = 0;
                    cumulativeFastDelta = 0;
                }

                cumulativeRefDelta = cumulativeRefDelta.add(refDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(prevRefPrice));
                cumulativeFastDelta = cumulativeFastDelta.add(fastDeltaAmount.mul(CUMULATIVE_DELTA_PRECISION).div(fastPrice));
            }

            if (cumulativeFastDelta > cumulativeRefDelta && cumulativeFastDelta.sub(cumulativeRefDelta) > maxCumulativeDeltaDiffs[_token]) {
                emit MaxCumulativeDeltaDiffExceeded(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
            }

            _setPriceData(_token, refPrice, cumulativeRefDelta, cumulativeFastDelta);
            emit PriceData(_token, refPrice, fastPrice, cumulativeRefDelta, cumulativeFastDelta);
        }
        prices[_token] = _price;
        emit PriceUpdated(_token, _price);
    }

    function _setPriceData(string memory _token, uint256 _refPrice, uint256 _cumulativeRefDelta, uint256 _cumulativeFastDelta) internal {
        require(_refPrice < MAX_REF_PRICE, "FastPriceFeed: invalid refPrice");
        // skip validation of block.timestamp, it should only be out of range after the year 2100
        require(_cumulativeRefDelta < MAX_CUMULATIVE_REF_DELTA, "FastPriceFeed: invalid cumulativeRefDelta");
        require(_cumulativeFastDelta < MAX_CUMULATIVE_FAST_DELTA, "FastPriceFeed: invalid cumulativeFastDelta");

        priceData[_token] = PriceDataItem(
            uint160(_refPrice),
            uint32(block.timestamp),
            uint32(_cumulativeRefDelta),
            uint32(_cumulativeFastDelta)
        );
    }

    function _setLastUpdatedValues(string memory _token, uint32 _timestamp) internal returns (bool) {
        if (minBlockInterval > 0) {
            require(block.number.sub(lastUpdatedBlock) >= minBlockInterval, "FastPriceFeed: minBlockInterval not yet passed");
        }

        uint256 _maxTimeDeviation = maxTimeDeviation;
        require(_timestamp > block.timestamp.sub(_maxTimeDeviation), "FastPriceFeed: _timestamp below allowed range");
        require(_timestamp < block.timestamp.add(_maxTimeDeviation), "FastPriceFeed: _timestamp exceeds allowed range");

        // do not update prices if _timestamp is before the current lastUpdatedAt value
        if (_timestamp < lastUpdatedAts[_token]) {
            return false;
        }

        lastUpdatedAts[_token] = _timestamp;
        lastUpdatedBlock = block.number;

        return true;
    }

    receive() external payable {
        emit fallbackCalled(msg.sender, msg.value, msg.data);
    }
}