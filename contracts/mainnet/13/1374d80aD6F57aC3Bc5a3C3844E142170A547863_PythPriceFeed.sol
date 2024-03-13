// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

pragma solidity 0.8.19;

interface IPositionRouter {
    function increasePositionRequestKeysStart() external returns (uint256);

    function decreasePositionRequestKeysStart() external returns (uint256);

    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function whitelistedTraders(address _account) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IVaultPriceFeed {
    function adjustmentBasisPoints(address _token)
        external
        view
        returns (uint256);

    function isAdjustmentAdditive(address _token) external view returns (bool);

    function setAdjustment(
        address _token,
        bool _isAdditive,
        uint256 _adjustmentBps
    ) external;

    function setUseV2Pricing(bool _useV2Pricing) external;

    function setIsAmmEnabled(bool _isEnabled) external;

    function setIsSecondaryPriceEnabled(bool _isEnabled) external;

    function setSpreadBasisPoints(address _token, uint256 _spreadBasisPoints)
        external;

    function setSpreadThresholdBasisPoints(uint256 _spreadThresholdBasisPoints)
        external;

    function setFavorPrimaryPrice(bool _favorPrimaryPrice) external;

    function setPriceSampleSpace(uint256 _priceSampleSpace) external;

    function setMaxStrictPriceDeviation(uint256 _maxStrictPriceDeviation)
        external;

    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool _useSwapPricing
    ) external view returns (uint256);

    function getAmmPrice(address _token) external view returns (uint256);

    function getLatestPrimaryPrice(address _token)
        external
        view
        returns (uint256);

    function getPrimaryPrice(address _token, bool _maximise)
        external
        view
        returns (uint256);

    function setTokenConfig(
        address _token,
        address _priceFeed,
        uint256 _priceDecimals,
        bool _isStrictStable,
        uint256 _stalePriceThreshold
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "./interfaces/IPythPriceFeed.sol";
import "./interfaces/ISecondaryPriceFeed.sol";
import "../core/interfaces/IVaultPriceFeed.sol";
import "../core/interfaces/IPositionRouter.sol";

contract PythPriceFeed is IPythPriceFeed, ISecondaryPriceFeed, Ownable {
    uint256 public constant PRICE_PRECISION = 10 ** 30;
    uint256 public constant BASIS_POINTS_DIVISOR = 10000;

    event SetMaxTimeDeviation(uint256 maxTimeDeviation);
    event SetHandler(address indexed handler, bool flag);

    IPyth public immutable pyth;
    IVaultPriceFeed public vaultPriceFeed;
    // allowed deviation from primary price
    uint256 public maxDeviationBasisPoints;
    uint256 public maxTimeDeviation = 1 minutes;
    mapping(address => bytes32) public override pythIds;
    mapping(address => bool) public handlers;

    constructor(
        address _pyth,
        address _vaultPriceFeed,
        uint256 _maxDeviationBasisPoints
    ) {
        pyth = IPyth(_pyth);
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
        vaultPriceFeed = IVaultPriceFeed(_vaultPriceFeed);
    }

    function setPythIds(
        address[] calldata _tokens,
        bytes32[] calldata _pythIds
    ) external onlyOwner {
        uint256 len = _tokens.length;
        require(len == _pythIds.length, "PythPriceFeed: invalid lengths");

        for (uint256 i; i < len; i += 1) {
            pythIds[_tokens[i]] = _pythIds[i];
        }
    }

    function setVaultPriceFeed(address _vaultPriceFeed) external onlyOwner {
        vaultPriceFeed = IVaultPriceFeed(_vaultPriceFeed);
    }

    function setMaxTimeDeviation(uint256 _maxTimeDeviation) external onlyOwner {
        maxTimeDeviation = _maxTimeDeviation;

        emit SetMaxTimeDeviation(_maxTimeDeviation);
    }

    function setMaxDeviationBasisPoints(
        uint256 _maxDeviationBasisPoints
    ) external onlyOwner {
        maxDeviationBasisPoints = _maxDeviationBasisPoints;
    }

    function setHandler(address _handler, bool _flag) external onlyOwner {
        handlers[_handler] = _flag;

        emit SetHandler(_handler, _flag);
    }

    function getUpdateFee(
        bytes[] calldata priceUpdateData
    ) external view override returns (uint256 fee) {
        fee = pyth.getUpdateFee(priceUpdateData);
    }

    function updatePriceFeeds(
        bytes[] calldata priceUpdateData,
        address refundee
    ) external payable override {
        require(handlers[msg.sender], "PythPriceFeed: forbidden!");

        uint256 fee = pyth.getUpdateFee(priceUpdateData);
        pyth.updatePriceFeeds{value: fee}(priceUpdateData);

        if (address(this).balance != 0) {
            (bool success, ) = refundee.call{value: address(this).balance}("");
            require(success, "PythPriceFeed: Refund failed");
        }
    }

    function getPrice(
        address _token,
        uint256 _refPrice, // chainlink price
        bool _maximise
    ) external view override returns (uint256) {
        PythStructs.Price memory price = pyth.getPriceNoOlderThan(
            pythIds[_token],
            maxTimeDeviation
        );

        uint256 pythPrice = (uint256(uint64(price.price)) * PRICE_PRECISION) /
            (10 ** uint32(-price.expo));

        return _getPrice(_refPrice, pythPrice, _maximise);
    }

    function getOffchainPrice(
        address _token,
        uint256 _offchainPrice,
        bool _maximise
    ) external view override returns (uint256) {
        uint256 primaryPrice = vaultPriceFeed.getPrimaryPrice(
            _token,
            _maximise
        );

        return _getPrice(primaryPrice, _offchainPrice, _maximise);
    }

    function _getPrice(
        uint256 primaryPrice,
        uint256 secondaryPrice,
        bool maximise
    ) internal view returns (uint256) {
        uint256 diffBasisPoints = primaryPrice > secondaryPrice
            ? primaryPrice - secondaryPrice
            : secondaryPrice - primaryPrice;
        diffBasisPoints =
            (diffBasisPoints * BASIS_POINTS_DIVISOR) /
            primaryPrice;

        // create a spread between the primaryPrice and the p if the maxDeviationBasisPoints is exceeded
        // or if watchers have flagged an issue with the pyth price
        if (diffBasisPoints > maxDeviationBasisPoints) {
            // return the higher of the two prices
            if (maximise) {
                return
                    primaryPrice > secondaryPrice
                        ? primaryPrice
                        : secondaryPrice;
            }

            // return the lower of the two prices
            return
                primaryPrice < secondaryPrice ? primaryPrice : secondaryPrice;
        }

        return secondaryPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IPythPriceFeed {
    function pythIds(address token) external view returns (bytes32);

    function getUpdateFee(
        bytes[] calldata priceUpdateData
    ) external view returns (uint256 fee);

    function updatePriceFeeds(
        bytes[] calldata priceUpdateData,
        address refundee
    ) external payable;

    function getOffchainPrice(
        address _token,
        uint256 _offchainPrice,
        bool _maximise
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISecondaryPriceFeed {
    function getPrice(
        address _token,
        uint256 _referencePrice,
        bool _maximise
    ) external view returns (uint256);
}