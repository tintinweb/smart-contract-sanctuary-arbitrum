// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
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
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity 0.8.9;

contract Constants {
    uint8 internal constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 internal constant BASIS_POINTS_DIVISOR = 100000;
    uint256 internal constant LIQUIDATE_THRESHOLD_DIVISOR = 10 * BASIS_POINTS_DIVISOR;
    uint256 internal constant DEFAULT_VLP_PRICE = 100000;
    uint256 internal constant FUNDING_RATE_PRECISION = BASIS_POINTS_DIVISOR ** 3; // 1e15
    uint256 internal constant MAX_DEPOSIT_WITHDRAW_FEE = 10000; // 10%
    uint256 internal constant MAX_DELTA_TIME = 24 hours;
    uint256 internal constant MAX_COOLDOWN_DURATION = 30 days;
    uint256 internal constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 internal constant MAX_PRICE_MOVEMENT_PERCENT = 10000; // 10%
    uint256 internal constant MAX_BORROW_FEE_FACTOR = 500; // 0.5% per hour
    uint256 internal constant MAX_FUNDING_RATE = FUNDING_RATE_PRECISION / 10; // 10% per hour
    uint256 internal constant MAX_STAKING_UNSTAKING_FEE = 10000; // 10%
    uint256 internal constant MAX_EXPIRY_DURATION = 60; // 60 seconds
    uint256 internal constant MAX_SELF_EXECUTE_COOLDOWN = 300; // 5 minutes
    uint256 internal constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 internal constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_MARKET_ORDER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_VESTING_DURATION = 700 days;
    uint256 internal constant MIN_LEVERAGE = 10000; // 1x
    uint256 internal constant POSITION_MARKET = 0;
    uint256 internal constant POSITION_LIMIT = 1;
    uint256 internal constant POSITION_STOP_MARKET = 2;
    uint256 internal constant POSITION_STOP_LIMIT = 3;
    uint256 internal constant POSITION_TRAILING_STOP = 4;
    uint256 internal constant PRICE_PRECISION = 10 ** 30;
    uint256 internal constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 internal constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 internal constant VLP_DECIMALS = 18;

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function checkSlippage(bool isLong, uint256 allowedPrice, uint256 actualMarketPrice) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <= allowedPrice,
                string(
                    abi.encodePacked(
                        "long: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        } else {
            require(
                actualMarketPrice >= allowedPrice,
                string(
                    abi.encodePacked(
                        "short: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceManager {
    function getLastPrice(uint256 _tokenId) external view returns (uint256);

    function maxLeverage(uint256 _tokenId) external view returns (uint256);

    function tokenToUsd(address _token, uint256 _tokenAmount) external view returns (uint256);

    function usdToToken(address _token, uint256 _usdAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/IOperators.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import {Constants} from "../access/Constants.sol";

interface IChainLinkVerifier {
    function verifyBulk(
        bytes[] calldata payloads,
        bytes calldata parameterPayload
    ) external payable returns (bytes[] memory verifiedReports);
}

contract PriceManager is Constants, Initializable, IPriceManager {
    IOperators public operators;
    IPyth public pyth;

    mapping(uint256 => Asset) public assets;
    struct Asset {
        string symbol;
        bytes32 pythId;
        uint256 price;
        uint256 timestamp;
        uint256 allowedStaleness;
        uint256 allowedDeviation;
        uint256 maxLeverage;
        uint256 tokenDecimals; // for usd stablecoin only
    }

    mapping(address => uint256) public tokenAddressToAssetId; // for usd stablecoin

    // an array to track valid assets
    uint256[] private validAssetIds;

    // ========= new variables ===========
    mapping(uint256 => uint256) public assetFeedTypes; // assetId => feedType, default 0 for pyth, 1 for chainlink

    // copy from https://docs.chain.link/data-streams/tutorials/streams-direct-onchain-verification
    struct ChainLinkReport {
        bytes32 feedId; // The feed ID the report has data for
        uint32 validFromTimestamp; // Earliest timestamp for which price is applicable
        uint32 observationsTimestamp; // Latest timestamp for which price is applicable
        uint192 nativeFee; // Base cost to validate a transaction using the report, denominated in the chain’s native token (WETH/ETH)
        uint192 linkFee; // Base cost to validate a transaction using the report, denominated in LINK
        uint32 expiresAt; // Latest timestamp where the report can be verified onchain
        int192 price; // DON consensus median price, carried to 18 decimal places
        int192 bid; // Simulated price impact of a buy order up to the X% depth of liquidity utilisation
        int192 ask; // Simulated price impact of a sell order up to the X% depth of liquidity utilisation
    }
    mapping(bytes32 => ChainLinkReport) public chainLinkReports; // chainlink feedId => ChainLinkReport
    IChainLinkVerifier public chainLinkVerifier; // 0x478Aa2aC9F6D65F84e09D9185d126c3a17c2a93C on arbitrum

    event SetAsset(
        uint256 assetId,
        string symbol,
        bytes32 pythId,
        uint256 price,
        uint256 timestamp,
        uint256 allowedStaleness,
        uint256 allowedDeviation,
        uint256 maxLeverage
    );
    event SetUsdAsset(
        address tokenAddress,
        uint256 assetId,
        string symbol,
        bytes32 pythId,
        uint256 price,
        uint256 timestamp,
        uint256 allowedStaleness,
        uint256 allowedDeviation,
        uint256 tokenDecimals
    );
    event SetPrice(uint256 assetId, uint256 price, uint256 timestamp);

    modifier onlyOperator(uint256 level) {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
        _;
    }

    function initialize(address _operators, address _pyth) public initializer {
        require(AddressUpgradeable.isContract(_operators), "operators invalid");
        require(AddressUpgradeable.isContract(_pyth), "pyth invalid");

        operators = IOperators(_operators);
        pyth = IPyth(_pyth);
    }

    function setChainLinkVerifier(address _chainLinkVerifier) external onlyOperator(3) {
        chainLinkVerifier = IChainLinkVerifier(_chainLinkVerifier);
    }

    function setAsset(
        uint256 _assetId,
        string calldata _symbol,
        bytes32 _pythId,
        uint256 _price,
        uint256 _allowedStaleness,
        uint256 _allowedDeviation,
        uint256 _maxLeverage
    ) external onlyOperator(3) {
        require(_maxLeverage > MIN_LEVERAGE, "Max Leverage should be greater than Min Leverage");

        // new asset
        if (assets[_assetId].maxLeverage == 0) {
            validAssetIds.push(_assetId);
        }

        assets[_assetId] = Asset({
            symbol: _symbol,
            pythId: _pythId,
            price: _price,
            timestamp: block.timestamp,
            allowedStaleness: _allowedStaleness,
            allowedDeviation: _allowedDeviation,
            maxLeverage: _maxLeverage,
            tokenDecimals: 0
        });

        emit SetAsset(
            _assetId,
            _symbol,
            _pythId,
            _price,
            block.timestamp,
            _allowedStaleness,
            _allowedDeviation,
            _maxLeverage
        );
    }

    function setAssetFeedTypes(uint256 _feedType, uint256[] calldata _assetIds) external onlyOperator(3) {
        for (uint i; i < _assetIds.length; i++) {
            assetFeedTypes[_assetIds[i]] = _feedType;
        }
    }

    function batchSetAllowedDeviation(uint256[] memory _assetIds, uint256 _allowedDeviation) external onlyOperator(3) {
        for (uint256 i; i < _assetIds.length; i++) {
            uint256 _assetId = _assetIds[i];
            Asset memory asset = assets[_assetId];
            require(asset.maxLeverage > 0, "!newAsset");
            asset.allowedDeviation = _allowedDeviation;
            assets[_assetId] = asset;
            emit SetAsset(
                _assetId,
                asset.symbol,
                asset.pythId,
                asset.price,
                asset.timestamp,
                asset.allowedStaleness,
                asset.allowedDeviation,
                asset.maxLeverage
            );
        }
    }

    function batchSetAllowedStaleness(uint256[] memory _assetIds, uint256 _allowedStaleness) external onlyOperator(3) {
        for (uint256 i; i < _assetIds.length; i++) {
            uint256 _assetId = _assetIds[i];
            Asset memory asset = assets[_assetId];
            require(asset.maxLeverage > 0, "!newAsset");
            asset.allowedStaleness = _allowedStaleness;
            assets[_assetId] = asset;
            emit SetAsset(
                _assetId,
                asset.symbol,
                asset.pythId,
                asset.price,
                asset.timestamp,
                asset.allowedStaleness,
                asset.allowedDeviation,
                asset.maxLeverage
            );
        }
    }

    function batchSetMaxLeverage(uint256[] memory _assetIds, uint256 _maxLeverage) external onlyOperator(3) {
        for (uint256 i; i < _assetIds.length; i++) {
            uint256 _assetId = _assetIds[i];
            Asset memory asset = assets[_assetId];
            require(asset.maxLeverage > 0, "!newAsset");
            asset.maxLeverage = _maxLeverage;
            assets[_assetId] = asset;
            emit SetAsset(
                _assetId,
                asset.symbol,
                asset.pythId,
                asset.price,
                asset.timestamp,
                asset.allowedStaleness,
                asset.allowedDeviation,
                asset.maxLeverage
            );
        }
    }

    function setUsdAsset(
        address _tokenAddress,
        uint256 _assetId,
        string calldata _symbol,
        bytes32 _pythId,
        uint256 _price,
        uint256 _allowedStaleness,
        uint256 _allowedDeviation,
        uint256 _tokenDecimals
    ) external onlyOperator(3) {
        // new asset
        if (assets[_assetId].tokenDecimals == 0) {
            validAssetIds.push(_assetId);
        }

        tokenAddressToAssetId[_tokenAddress] = _assetId;
        assets[_assetId] = Asset({
            symbol: _symbol,
            pythId: _pythId,
            price: _price,
            timestamp: block.timestamp,
            allowedStaleness: _allowedStaleness,
            allowedDeviation: _allowedDeviation,
            maxLeverage: 0,
            tokenDecimals: _tokenDecimals
        });

        emit SetUsdAsset(
            _tokenAddress,
            _assetId,
            _symbol,
            _pythId,
            _price,
            block.timestamp,
            _allowedStaleness,
            _allowedDeviation,
            _tokenDecimals
        );
    }

    function getPythLastPrice(uint256 _assetId, bool _requireFreshness) public view returns (uint256) {
        PythStructs.Price memory priceInfo = pyth.getPriceUnsafe(assets[_assetId].pythId);
        if (_requireFreshness) {
            require(block.timestamp <= priceInfo.publishTime + assets[_assetId].allowedStaleness, "price stale");
        }

        uint256 price = uint256(uint64(priceInfo.price));
        if (priceInfo.expo >= 0) {
            uint256 exponent = uint256(uint32(priceInfo.expo));
            return price * PRICE_PRECISION * (10 ** exponent);
        } else {
            uint256 exponent = uint256(uint32(-priceInfo.expo));
            return (price * PRICE_PRECISION) / (10 ** exponent);
        }
    }

    function getChainLinkLastPrice(uint256 _assetId, bool _requireFreshness) public view returns (uint256) {
        ChainLinkReport memory report = chainLinkReports[assets[_assetId].pythId];
        if (_requireFreshness) {
            require(block.timestamp <= report.validFromTimestamp + assets[_assetId].allowedStaleness, "price stale2");
        }
        uint256 price = uint256(int256(report.price));
        require(price > 0, "no chainlink price");
        return (price * PRICE_PRECISION) / 10 ** 18;
    }

    function getLastPrice(uint256 _assetId) public view override returns (uint256) {
        uint256 price = assets[_assetId].price;
        require(price > 0, "invalid price");

        uint256 ts = assets[_assetId].timestamp;
        uint256 allowedStaleness = assets[_assetId].allowedStaleness;
        if (allowedStaleness == 0 || block.timestamp - ts <= allowedStaleness) {
            // our price is fresh enough, return our answer
            return price;
        } else {
            // our price is stale, try use on-chain price with freshness requirement
            uint256 feedType = assetFeedTypes[_assetId];
            if (feedType == 0) {
                return getPythLastPrice(_assetId, true);
            } else if (feedType == 1) {
                return getChainLinkLastPrice(_assetId, true);
            } else {
                revert("unknown feed type");
            }
        }
    }

    function setPrice(uint256 _assetId, uint256 _price, uint256 _ts) public onlyOperator(2) {
        require(_ts > assets[_assetId].timestamp, "already updated");
        bytes32 pythId = assets[_assetId].pythId;
        if (pythId != bytes32(0)) {
            // skip validation if on-chain price not enabled for this asset
            uint256 priceOnChain;
            if (assetFeedTypes[_assetId] == 1) {
                priceOnChain = getChainLinkLastPrice(_assetId, false);
            } else {
                priceOnChain = getPythLastPrice(_assetId, false);
            }
            uint256 deviation = _price > priceOnChain
                ? ((_price - priceOnChain) * BASIS_POINTS_DIVISOR) / priceOnChain
                : ((priceOnChain - _price) * BASIS_POINTS_DIVISOR) / priceOnChain;
            require(deviation <= assets[_assetId].allowedDeviation, "need update pyth price");
        }
        assets[_assetId].price = _price;
        assets[_assetId].timestamp = _ts;

        emit SetPrice(_assetId, _price, _ts);
    }

    function tokenToUsd(address _token, uint256 _tokenAmount) external view override returns (uint256) {
        uint256 assetId = tokenAddressToAssetId[_token];

        return (_tokenAmount * getLastPrice(assetId)) / (10 ** assets[assetId].tokenDecimals);
    }

    function usdToToken(address _token, uint256 _usdAmount) external view override returns (uint256) {
        uint256 assetId = tokenAddressToAssetId[_token];

        return (_usdAmount * (10 ** assets[assetId].tokenDecimals)) / getLastPrice(assetId);
    }

    function getCurrentTime() external view returns (uint256) {
        return block.timestamp;
    }

    function maxLeverage(uint256 _assetId) external view override returns (uint256) {
        return assets[_assetId].maxLeverage;
    }

    function getValidAssetIds() external view returns (uint256[] memory) {
        return validAssetIds;
    }

    function bulkVerifyChainLinkDataStreams(
        bytes[] calldata _payloads,
        bytes calldata _parameterPayload
    ) external payable onlyOperator(1) {
        bytes[] memory verifiedReportDatas = chainLinkVerifier.verifyBulk{value: msg.value}(
            _payloads,
            _parameterPayload
        );
        for (uint256 i; i < verifiedReportDatas.length; ++i) {
            ChainLinkReport memory report = abi.decode(verifiedReportDatas[i], (ChainLinkReport));
            require(report.validFromTimestamp > chainLinkReports[report.feedId].validFromTimestamp, "stale report");
            chainLinkReports[report.feedId] = report;
        }
    }
}