// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPyth.sol";
import "./PythErrors.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
    function queryPriceFeed(
        bytes32 id
    ) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(
        bytes32 id
    ) public view virtual returns (bool exists);

    function getValidTimePeriod()
        public
        view
        virtual
        override
        returns (uint validTimePeriod);

    function getPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(
        bytes32 id
    ) external view virtual override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function getEmaPriceUnsafe(
        bytes32 id
    ) public view virtual override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) public view virtual override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        if (diff(block.timestamp, price.publishTime) > age)
            revert PythErrors.StalePrice();

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    // Access modifier is overridden to public to be able to call it locally.
    function updatePriceFeeds(
        bytes[] calldata updateData
    ) public payable virtual override;

    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable virtual override {
        if (priceIds.length != publishTimes.length)
            revert PythErrors.InvalidArgument();

        for (uint i = 0; i < priceIds.length; i++) {
            if (
                !priceFeedExists(priceIds[i]) ||
                queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]
            ) {
                updatePriceFeeds(updateData);
                return;
            }
        }

        revert PythErrors.NoFreshUpdate();
    }

    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    )
        external
        payable
        virtual
        override
        returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
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

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

library PythErrors {
    // Function arguments are invalid (e.g., the arguments lengths mismatch)
    error InvalidArgument();
    // Update data is coming from an invalid data source.
    error InvalidUpdateDataSource();
    // Update data is invalid (e.g., deserialization error)
    error InvalidUpdateData();
    // Insufficient fee is paid to the method.
    error InsufficientFee();
    // There is no fresh update, whereas expected fresh updates.
    error NoFreshUpdate();
    // There is no price feed found within the given range or it does not exists.
    error PriceFeedNotFoundWithinRange();
    // Price feed not found or it is not pushed on-chain yet.
    error PriceFeedNotFound();
    // Requested price is stale.
    error StalePrice();
    // Given message is not a valid Wormhole VAA.
    error InvalidWormholeVaa();
    // Governance message is invalid (e.g., deserialization error).
    error InvalidGovernanceMessage();
    // Governance message is not for this contract.
    error InvalidGovernanceTarget();
    // Governance message is coming from an invalid data source.
    error InvalidGovernanceDataSource();
    // Governance message is old.
    error OldGovernanceMessage();
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
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
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
pragma solidity 0.8.15;
import "./PairsStorageInterface.sol";
import "./StorageInterface.sol";
import "./CallbacksInterface.sol";

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    function beforeGetPriceLimit(
        StorageInterface.Trade memory t
    ) external returns (uint256);

    function getPrice(
        OrderType,
        bytes[] calldata,
        StorageInterface.Trade memory
    ) external returns (uint, uint256);

    function fulfill(uint256 orderId, uint256 price) external;

    function pairsStorage() external view returns (PairsStorageInterface);

    function tokenPriceUSDT() external returns (uint);

    function updatePriceFeed(uint256 pairIndex,bytes[] calldata updateData) external returns (uint256);

    function linkFee(uint, uint) external view returns (uint);

    function orders(uint) external view returns (uint, OrderType, uint, bool);

    function tokenUSDTReservesLp() external view returns (uint, uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    function getPairForIndex(
        uint256 _pairIndex
    ) external view returns (string memory, string memory);

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface CallbacksInterface {
    struct AggregatorAnswer {
        uint orderId;
        uint256 price;
        uint spreadP;
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeOpenOrderCallback(AggregatorAnswer memory) external;

    function executeCloseOrderCallback(AggregatorAnswer memory) external;

    function updateSlCallback(AggregatorAnswer memory) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOracle {
    function getUnderlyingPrice(
        string memory _pair
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
import "./StorageInterface.sol";

interface LimitOrdersInterface {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterface.LimitOrder order;
    }
    //MOMENTUM = STOP
    //REVERSAL = LIMIT
    //LEGACY = MARKET
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function openLimitOrderTypes(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(
        address,
        uint,
        uint,
        OpenLimitOrderType
    ) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface LpInterfaceV5 {
    function getReserves() external view returns (uint112, uint112, uint32);

    function token0() external view returns (address);

    function transfer(address, uint) external returns (bool);

    function transferFrom(address, address, uint256) external;

    function totalSupply() external view returns (uint);

    function balanceOf(address) external view returns (uint);

    function approve(address, uint256) external returns (bool);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface NarwhalReferralInterface {
    struct ReferrerDetails {
        address[] userReferralList;
        uint volumeReferredUSDT; // 1e18
        uint pendingRewards; // 1e18
        uint totalRewards; // 1e18
        bool registered;
        uint256 referralLink;
        bool canChangeReferralLink;
        address userReferredFrom;
        bool isWhitelisted;
        uint256 discount;
        uint256 rebate;
        uint256 tier;
    }

    function getReferralDiscountAndRebate(
        address _user
    ) external view returns (uint256, uint256);

    function signUp(address trader, address referral) external;

    function incrementTier2Tier3(
        address _tier2,
        uint256 _rewardTier2,
        uint256 _rewardTier3,
        uint256 _tradeSize
    ) external;

    function getReferralDetails(
        address _user
    ) external view returns (ReferrerDetails memory);

    function getReferral(address _user) external view returns (address);

    function isTier3KOL(address _user) external view returns (bool);

    function tier3tier2RebateBonus() external view returns (uint256);

    function incrementRewards(address _user, uint256 _rewards,uint256 _tradeSize) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairInfoInterface {
    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e18 (USDT)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e18 (USDT)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e18 (USDT)
    ) external returns (uint); // 1e18 (USDT)

    function getAccFundingFeesLong(uint pairIndex) external view returns (int);

    function getAccFundingFeesShort(uint pairIndex) external view returns (int);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PairsStorageInterface {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        bytes32 feed1;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairSpreadP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupMaxCollateral(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUSDT(uint) external view returns (uint);

    function pairLimitOrderFeeP(
        uint _pairIndex
    ) external view returns (uint);

    function incr() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface PoolInterface {
    function increaseAccTokens(uint) external;
}

// SPDX-License-Identifier: MITUSDT
pragma solidity 0.8.15;
import "./TokenInterface.sol";
import "./AggregatorInterfaceV6_2.sol";
import "./UniswapRouterInterfaceV5.sol";
import "./VaultInterface.sol";
import "./PoolInterface.sol";

interface StorageInterface {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trader {
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal; // 1e18
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUSDT; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUSDT; // PRECISION
        uint openInterestUSDT; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (USDT or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }

    struct PendingLimitOrder {
        address limitHolder;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function getNetOI(uint256 _pairIndex, bool _long) external view returns (uint256);
    
    function gov() external view returns (address);

    function dev() external view returns (address);

    function USDT() external view returns (TokenInterface);

    function token() external view returns (TokenInterface);

    function linkErc677() external view returns (TokenInterface);

    function tokenUSDTRouter() external view returns (UniswapRouterInterfaceV5);

    function tempTradeStatus(address _trader,uint256 _pairIndex,uint256 _index) external view returns (bool);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (VaultInterface);

    function pool() external view returns (PoolInterface);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUSDT(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint,
        bool
    ) external;

    function storeReferral(address, address) external;

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

    function openTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function tradeTimestamp(
        address,
        uint,
        uint
    ) external view returns (uint256);

    function openTradesInfo(
        address,
        uint,
        uint
    ) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function positionSizeTokenDynamic(uint, uint) external view returns (uint);

    function maxSlP() external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingLimitOrder(PendingLimitOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function currentPercentProfit(
        uint,
        uint,
        bool,
        uint
    ) external view returns (int);

    function reqID_pendingLimitOrder(
        uint
    ) external view returns (PendingLimitOrder memory);

    function updateTrade(Trade memory) external;

    function unregisterPendingLimitOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function getReferral(address) external view returns (address);

    function increaseReferralRewards(address, uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function setLeverageUnlocked(address, uint) external;

    function getLeverageUnlocked(address) external view returns (uint);

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function maxOpenLimitOrdersPerPair() external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function maxTradesPerBlock() external view returns (uint);

    function tradesPerBlock(uint) external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function maxGainP() external view returns (uint);

    function defaultLeverageUnlocked() external view returns (uint);

    function openInterestUSDT(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function traders(address) external view returns (Trader memory);

    function keeperForOrder(uint256) external view returns (address);

    function accPerOiOpen(
        address,
        uint,
        uint
    ) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface TokenInterface {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface UniswapRouterInterfaceV5 {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface VaultInterface {
    function sendUSDTToTrader(address, uint) external;

    function receiveUSDTFromTrader(address, uint, uint, bool) external;

    function currentBalanceUSDT() external view returns (uint);

    function distributeRewardUSDT(uint, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library BitMath {
    // returns the 0 indexed position of the most significant bit of the input x
    // s.t. x >= 2**msb and x < 2**(msb+1)
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::mostSignificantBit: zero");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    // returns the 0 indexed position of the least significant bit of the input x
    // s.t. (x & 2**lsb) != 0 and (x & (2**(lsb) - 1)) == 0)
    // i.e. the bit at the index is set and the mask of all lower bits is 0
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "BitMath::leastSignificantBit: zero");

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 =
        0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(
        uq112x112 memory self,
        uint256 y
    ) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(
            y == 0 || (z = self._x * y) / y == self._x,
            "FixedPoint::mul: overflow"
        );
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(
        uq112x112 memory self,
        int256 y
    ) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2 ** 255, "FixedPoint::muli: overflow");
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(
        uq112x112 memory self,
        uq112x112 memory other
    ) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(
            upper <= type(uint112).max,
            "FixedPoint::muluq: upper overflow"
        );

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) +
            uppers_lowero +
            uppero_lowers +
            (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, "FixedPoint::muluq: sum overflow");

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(
        uq112x112 memory self,
        uq112x112 memory other
    ) internal pure returns (uq112x112 memory) {
        require(other._x > 0, "FixedPoint::divuq: division by zero");
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, "FixedPoint::divuq: overflow");
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, "FixedPoint::divuq: overflow");
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: division by zero");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(
                result <= type(uint224).max,
                "FixedPoint::fraction: overflow"
            );
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(
                result <= type(uint224).max,
                "FixedPoint::fraction: overflow"
            );
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(
        uq112x112 memory self
    ) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint::reciprocal: reciprocal of zero");
        require(self._x != 1, "FixedPoint::reciprocal: overflow");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(
        uq112x112 memory self
    ) internal pure returns (uq112x112 memory) {
        if (self._x <= type(uint144).max) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return
            uq112x112(
                uint224(
                    Babylonian.sqrt(uint256(self._x) << safeShiftBits) <<
                        ((112 - safeShiftBits) / 2)
                )
            );
    }
}

library FullMath {
    function fullMul(
        uint256 x,
        uint256 y
    ) internal pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, type(uint256).max);
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & (~d + 1);
        d /= pow2;
        l /= pow2;
        l += h * ((~pow2 + 1) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);

        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;

        if (h == 0) return l / d;

        require(h < d, "FullMath: FULLDIV_OVERFLOW");
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/CallbacksInterface.sol";
import "./interfaces/LpInterfaceV5.sol";
import "./libraries/FullMath.sol";

import "@pythnetwork/pyth-sdk-solidity/AbstractPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface INarwhal {
    function tempSlippage() external view returns (uint256);

    function tempSpreadReduction() external view returns (uint256);

    function tempSL() external view returns (uint256);

    function isLimitOrder() external view returns (bool);

    function tempOrderId() external view returns (uint256);
}

interface IPythTestnet {
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    function queryPriceFeed(
        bytes32 id
    ) external view returns (PythStructs.PriceFeed memory priceFeed);
    
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    function priceFeedExists(
        bytes32 id
    ) external view returns (bool);
    
}

interface IUniswapOracle {
    function consult(
        address token,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}

contract NarwhalPriceAggregator {
    using FixedPoint for *;
    using SafeMath for uint256;

    // Contracts (constant)
    StorageInterface public immutable storageT;
    address public PythOracle;
    address public NarwhalTrading;
    // Contracts (adjustable)
    address public pairsStorage;
    bytes32 public USDTFeed;

    // Params (constant)
    uint256 constant PRECISION = 1e10;
    uint256 public age = 60; //seconds price confidence

    // Custom data types
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL
    }

    struct Order {
        uint pairIndex;
        OrderType orderType;
        uint pythFeePerNode;
        bool initiated;
    }

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }

    struct PendingMarket {
        uint block;
        uint wantedPrice;
        uint slippageP;
        uint spreadReductionP;
        uint tokenId;
    }

    mapping(uint => Order) public orders;
    mapping(uint => uint[]) public ordersAnswers;
    mapping(uint => PendingSl) public pendingSlOrders;

    // Events
    event PairsStorageUpdated(address value);
    event USDTFeedSet(bytes32 indexed feed);
    event OracleSet(address indexed oracle);
    event AgeSet(uint256 age);
    event NarwhalTradingSet(address indexed NarwhalTrading);

    constructor(
        StorageInterface _storageT,
        address _pairsStorage,
        address _PythOracle,
        bytes32 _usdtFeed
    ) {
        require(
            address(_storageT) != address(0) &&
                address(_pairsStorage) != address(0) &&
                address(_PythOracle) != address(0),
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        PythOracle = _PythOracle;
        pairsStorage = _pairsStorage;
        USDTFeed = _usdtFeed;
        require(IPythTestnet(PythOracle).priceFeedExists(USDTFeed),"INCORRECT_PRICE_FEED");
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyTrading() {
        require(msg.sender == storageT.trading(), "TRADING_ONLY");
        _;
    }
    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Manage contracts
    function updatePairsStorage(address value) external onlyGov {
        require(address(value) != address(0), "VALUE_0");

        pairsStorage = value;

        emit PairsStorageUpdated(address(value));
    }

    function setUSDTFeed(bytes32 _feed) public onlyGov {
        require(IPythTestnet(PythOracle).priceFeedExists(_feed),"INCORRECT_PRICE_FEED");
        USDTFeed = _feed;
        emit USDTFeedSet(_feed);
    }

    function setOracle(address _oracle) public onlyGov {
        require(_oracle != address(0), "ZERO_ADDRESS");
        PythOracle = _oracle;
        emit OracleSet(_oracle);
    }

    function setAge(uint256 _age) public onlyGov {
        require(_age <= 60, "Too much");
        age = _age;
        emit AgeSet(_age);
    }

    function setNarwhalTrading(address _NarwhalTrading) public onlyGov {
        require(_NarwhalTrading != address(0), "ZERO_ADDRESS");
        NarwhalTrading = _NarwhalTrading;
        emit NarwhalTradingSet(_NarwhalTrading);
    }
    
    function tokenPriceUSDT() public view returns (uint256) {
        //testnet
        PythStructs.Price memory priceP = IPythTestnet(PythOracle)
           .getPriceUnsafe(USDTFeed);
        //mainnet
        // PythStructs.Price memory priceP = IPythTestnet(PythOracle)
        //      .getPriceNoOlderThan(USDTFeed,age);

        uint256 price = uint256(uint64(priceP.price));
        require(price != 0, "PRICE_FEED_ERROR");
        uint256 convertedNumber = price * 1e10;
        return convertedNumber;
    }

    function beforeGetPriceLimit(
        StorageInterface.Trade memory t
    ) public onlyTrading returns (uint256) {
        (, , uint orderId) = PairsStorageInterface(pairsStorage).pairJob(
            t.pairIndex
        );
        return (orderId);
    }

    function updatePriceFeed(uint256 pairIndex,bytes[] calldata updateData) public payable onlyTrading returns (uint256) {
        PairsStorageInterface.Feed memory f = PairsStorageInterface(
            pairsStorage
        ).pairFeed(pairIndex);

        IPythTestnet(PythOracle).updatePriceFeeds{
            value: getPythFee(updateData)
        }(updateData);

        // //mainnet
        // PythStructs.Price memory priceP = IPythTestnet(PythOracle)
        //      .getPriceNoOlderThan(f.feed1,age);

        //testnet
        PythStructs.Price memory priceP = IPythTestnet(PythOracle)
           .getPriceUnsafe(f.feed1);

        uint256 convertedNumber = uint256(uint64(priceP.price));
        int32 expRefactor = priceP.expo + 18;
        uint256 factor;
        if (expRefactor > 0) {
            factor = tenPow(expRefactor);
        } else {
            revert("Check the feed decimals");
        }
        uint256 precisionPrice = convertedNumber * (factor);
        return (precisionPrice);
    }

    // On-demand price request to oracles network
    function getPrice(
        OrderType orderType,
        bytes[] calldata updateData,
        StorageInterface.Trade memory t
    ) public onlyTrading returns (uint, uint256) {
        uint orderId;
        if (INarwhal(NarwhalTrading).isLimitOrder()) {
            orderId = INarwhal(NarwhalTrading).tempOrderId();
        } else {
            orderId = beforeGetPriceLimit(t);
        }

        orders[orderId] = Order(
            t.pairIndex,
            orderType,
            getPythFee(updateData),
            true
        );

        uint256 precisionPrice = updatePriceFeed(t.pairIndex,updateData);

        if (orderType == OrderType.MARKET_CLOSE) {
            storageT.storePendingMarketOrder(
                StorageInterface.PendingMarketOrder(
                    StorageInterface.Trade(
                        t.trader,
                        t.pairIndex,
                        t.index,
                        0,
                        0,
                        0,
                        false,
                        0,
                        0,
                        0
                    ),
                    0,
                    0,
                    0,
                    0,
                    0
                ),
                orderId,
                false
            );
        } else if (orderType == OrderType.MARKET_OPEN) {
            storageT.storePendingMarketOrder(
                StorageInterface.PendingMarketOrder(
                    StorageInterface.Trade(
                        t.trader,
                        t.pairIndex,
                        0,
                        0,
                        t.positionSizeUSDT,
                        0,
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    INarwhal(NarwhalTrading).tempSlippage(),
                    INarwhal(NarwhalTrading).tempSpreadReduction(),
                    0
                ),
                orderId,
                true
            );
        } else {
            storePendingSlOrder(
                orderId,
                PendingSl(
                    t.trader,
                    t.pairIndex,
                    t.index,
                    t.openPrice,
                    t.buy,
                    INarwhal(NarwhalTrading).tempSL()
                )
            );
        }

        
        fulfill(orderId, precisionPrice);
        return (orderId, precisionPrice);
    }

    function tenPow(int32 exp) internal pure returns (uint256) {
        uint256 result = 1;
        for (int32 i = 0; i < exp; i++) {
            result = result.mul(10);
        }
        return result;
    }

    // Fulfill on-demand price requests
    function fulfill(uint256 orderId, uint256 price) internal {

        Order memory r = orders[orderId];
        if (!r.initiated) {
            return;
        }

        uint[] storage answers = ordersAnswers[orderId];
        answers.push(price);

        CallbacksInterface.AggregatorAnswer memory a;
        a.orderId = orderId;
        a.price = price;
        a.spreadP = PairsStorageInterface(pairsStorage).pairSpreadP(
            r.pairIndex
        );

        CallbacksInterface c = CallbacksInterface(storageT.callbacks());
        if (r.orderType == OrderType.MARKET_OPEN) {
            c.openTradeMarketCallback(a);
        } else if (r.orderType == OrderType.MARKET_CLOSE) {
            c.closeTradeMarketCallback(a);
        } else if (r.orderType == OrderType.LIMIT_OPEN) {
            c.executeOpenOrderCallback(a);
        } else if (r.orderType == OrderType.LIMIT_CLOSE) {
            c.executeCloseOrderCallback(a);
        } else {
            c.updateSlCallback(a);
        }

        delete orders[orderId];
        delete ordersAnswers[orderId];
    }

    function getPythFee(
        bytes[] calldata updateData
    ) public view returns (uint) {
        uint256 feeAmount = IPythTestnet(PythOracle).getUpdateFee(updateData);
        return feeAmount;
    }

    // Manage pending SL orders
    function storePendingSlOrder(uint orderId, PendingSl memory p) internal {
        pendingSlOrders[orderId] = p;
    }

    function unregisterPendingSlOrder(uint orderId) external {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");

        delete pendingSlOrders[orderId];
    }

    // Median function
    function swap(uint[] memory array, uint i, uint j) private pure {
        (array[i], array[j]) = (array[j], array[i]);
    }

    function sort(uint[] memory array, uint begin, uint end) private pure {
        if (begin >= end) {
            return;
        }

        uint j = begin;
        uint pivot = array[j];

        for (uint i = begin + 1; i < end; ++i) {
            if (array[i] < pivot) {
                swap(array, i, ++j);
            }
        }

        swap(array, begin, j);
        sort(array, begin, j);
        sort(array, j + 1, end);
    }

    function median(uint[] memory array) private pure returns (uint) {
        sort(array, 0, array.length);

        return
            array.length % 2 == 0
                ? (array[array.length / 2 - 1] + array[array.length / 2]) / 2
                : array[array.length / 2];
    }

    // Storage v5 compatibility
    function openFeeP(uint pairIndex) external view returns (uint) {
        return PairsStorageInterface(pairsStorage).pairOpenFeeP(pairIndex);
    }

    function withdrawETH(address payable recipient) external onlyGov {
        require(recipient != address(0), "Invalid address");
        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    receive() external payable {}
}