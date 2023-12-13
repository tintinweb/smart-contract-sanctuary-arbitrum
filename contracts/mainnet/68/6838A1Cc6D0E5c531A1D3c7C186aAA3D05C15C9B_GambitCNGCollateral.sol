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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library GambitErrorsV1 {
    // msg.sender is not gov
    error NotGov();

    // msg.sender is not manager (GambitPairInfosV1)
    error NotManager();

    // msg.sender is not trading contract
    error NotTrading();

    // msg.sender is not callback contract
    error NotCallbacks();

    // msg.sender is not price aggregator contract
    error NotAggregator();

    error NotTimelockOwner();
    error NotTradingOrCallback();
    error NotNftRewardsOrReferralsOrCallbacks();
    error ZeroAddress();

    // Not authorized
    error NoAuth();

    // contract is not done
    error NotDone();

    // contract is done
    error Done();

    // contract is not paused
    error NotPaused();

    // contract is paused
    error Paused();

    // Wrong parameters
    error WrongParams();

    // Wrong length of array
    error WrongLength();

    // Wrong order of array
    error WrongOrder();

    // unknown group id
    error GroupNotListed();
    // unknown fee id
    error FeeNotListed();
    // unknown pair id
    error PairNotListed();

    error AlreadyListedPair();

    // invalid data for group
    error WrongGroup();
    // invalid data for pair
    error InvalidPair();
    // invalid data for fee
    error WrongFee();
    // invalid data for feed
    error WrongFeed();

    // stablecoin decimals mismatch
    error StablecoinDecimalsMismatch();

    // zero value
    error ZeroValue();

    // same value
    error SameValue();

    // trade errors
    error MaxTradesPerPair();
    error MaxPendingOrders();
    error NoTrade();
    error AboveMaxPos();
    error BelowMinPos();
    error AlreadyBeingClosed();
    error LeverageIncorrect();
    error NoCorrespondingNftSpreadReduction();
    error WrongTp();
    error WrongSl();
    error PriceImpactTooHigh();
    error NoLimit();
    error LimitTimelock();
    error AbovePos();
    error BelowFee();
    error WrongNftType();
    error NoNFT();
    error HasSl();
    error NoSl();
    error NoTp();
    error PriceFeedFailed();
    error WaitTimeout();
    error NotYourOrder();
    error WrongMarketOrderType();

    // address is zero
    error ZeroAdress();

    // pyth caller doesn't have enough balance to pay the fee
    error InsufficientPythFee();

    // value is too high
    error TooHigh();
    // value is too low
    error TooLow();

    // price errors
    error InsufficientCNG();
    error InvalidPrice();
    error InvalidChainlinkPrice();
    error InvalidChainlinkFeed();
    error InvalidPythPrice();
    error InvalidPythExpo();
    error PythPriceTooOld();
    error AlreadyReported();

    // nft reward trigger timing error
    error TooLate();
    error TooEarly();
    error SameBlockLimit();
    error NotTriggered();
    error NothingToClaim();

    // referral
    error InvalidTailingZero();
    error RewardUnavailable();

    // trading storage
    error AlreadyAddedToken();
    error NotOpenLimitOrder();

    // SimpleGToken
    error ZeroPrice();
    error PendingWithdrawal();
    error EndOfEpoch();
    error NotAllowed();
    error NotTradingPnlHandler();
    error NotPnlFeed();
    error MaxDailyPnl();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGambitPairsStorageV1 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        bytes32 priceId1;
        bytes32 priceId2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairConfMultiplierP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFee(uint) external view returns (uint);

    function pairNftLimitOrderFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUsdc(uint) external view returns (uint);

    function pairsCount() external view returns (uint);

    function pairExposureUtilsP(uint) external view returns (uint);

    function groupMaxCollateralP(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPyth} from "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import {IGambitTradingStorageV1} from "../trading-storage/interfaces/IGambitTradingStorageV1.sol";
import {IGambitPairsStorageV1} from "../pair-storage/interfaces/IGambitPairsStorageV1.sol";

import {IGambitCNGCollateral} from "./interfaces/IGambitCNGCollateral.sol";

import "../GambitErrorsV1.sol";

/**
 * @notice This contract holds CNG as collateral to provide optimistic pyth price.
 *         "Optimistic" means that the price is not verified by pyth contract when consume.
 *
 *          1. price feeder "reports" optimistic price to process orders.
 *          2. anyone can "challenges" to the price with valid price update data.
 *          3. price feeder re-challenges (or "resolves") to the challenge with his own price update data.
 *              - if there is no valid re-challenge, challenger gets all CNG as reward.
 *              - if re-challenge is successful, the challanger gets no reward.
 *
 */
contract GambitCNGCollateral is Initializable, IGambitCNGCollateral {
    // Contracts (constant)
    IPyth public pyth;
    IGambitTradingStorageV1 public storageT;
    IERC20 public CNG;

    // Contracts (adjustable)
    // NOTHING

    // Params (constant)
    uint256 public constant MIN_THRESHOLD = 1000e18; // 1000 CNG
    uint256 public constant DURATION = 3 days; // duration to challenge, re-challenge, claim

    // Params (adjustable)
    uint256 public threshold;

    struct ReportedPrice {
        bytes32 priceId;
        address challenger; // address of the challenger
        uint64 challengedAt; // timestamp when the challenge is initiated
        bool resolved; // whether the re-challenge is successful or not
        bool finalized; // whether the challenge is finalized or not
        bool slashed; // whether the challenge is valid and collateral is slashed or not
        PythStructs.Price price; // reported price by price feeder
    }

    // orderId => ReportedPrice
    mapping(uint256 => ReportedPrice) public reportedPriceOf;

    uint256 public nReportedPrices;
    uint256[] public challengedOrderIds; // a list of all challenged orders. only push new id when challenged.
    uint256 public nFinalizedChallenges; // increased when re-challenge is successful.

    struct ClaimRequest {
        uint256 amount;
        uint256 requestedAt;
        uint256 nFinalizedChallenges;
        bool claimed;
    }
    ClaimRequest[] public claimRequests;

    modifier onlyGov() {
        if (msg.sender != storageT.gov()) {
            revert GambitErrorsV1.NotGov();
        }
        _;
    }

    modifier onlyPriceAggregator() {
        if (msg.sender != address(storageT.priceAggregator())) {
            revert GambitErrorsV1.NotAggregator();
        }
        _;
    }

    event ThresholdUpdated(uint256 threshold);

    event PriceReported(
        uint256 indexed orderId,
        bytes32 indexed priceId,
        PythStructs.Price price
    );

    event ChallengeInitiated(
        uint256 indexed orderId,
        bytes32 indexed priceId,
        address indexed challenger,
        PythStructs.Price price,
        uint256 challengedAt
    );

    event ChallengeFinalized(
        uint256 indexed orderId,
        address indexed challenger,
        bool slashed,
        uint256 reward
    );

    event ChallengeResolved(
        uint256 indexed orderId,
        bytes32 indexed priceId,
        address indexed resolver,
        PythStructs.Price price
    );

    event Pause(bool paused);
    event Done(bool done);

    event ClaimRequested(
        uint256 amount,
        uint256 nFinalizedChallenges,
        uint256 requestedAt
    );
    event Claimed(uint256 amount);

    function initialize(
        IPyth _pyth,
        IGambitTradingStorageV1 _storageT,
        IERC20 _CNG,
        uint256 _threshold
    ) external initializer {
        if (
            address(_pyth) == address(0) ||
            address(_storageT) == address(0) ||
            address(_CNG) == address(0)
        ) {
            revert GambitErrorsV1.ZeroAddress();
        }

        if (_threshold < MIN_THRESHOLD) {
            revert GambitErrorsV1.WrongParams();
        }

        pyth = _pyth;
        storageT = _storageT;
        CNG = _CNG;
        threshold = _threshold;
    }

    function updateThreshold(uint256 newThreshold) external onlyGov {
        if (newThreshold < MIN_THRESHOLD) revert GambitErrorsV1.WrongParams();

        threshold = newThreshold;

        emit ThresholdUpdated(newThreshold);
    }

    function nChallenges() external view returns (uint256) {
        return challengedOrderIds.length;
    }

    function active() public view returns (bool) {
        return CNG.balanceOf(address(this)) >= threshold;
    }

    function isReported(uint256 orderId) public view returns (bool) {
        return reportedPriceOf[orderId].price.publishTime != 0;
    }

    function reportPrice(
        uint256 orderId,
        uint256 pairIndex,
        PythStructs.Price memory price
    ) external onlyPriceAggregator {
        // throw if not enough CNG
        if (!active()) {
            revert GambitErrorsV1.InsufficientCNG();
        }

        if (isReported(orderId)) {
            revert GambitErrorsV1.AlreadyReported();
        }

        IGambitPairsStorageV1.Feed memory f = storageT
            .priceAggregator()
            .pairsStorage()
            .pairFeed(pairIndex);

        if (
            price.price <= 0 ||
            price.conf == 0 ||
            price.publishTime == 0 ||
            price.expo > 0
        ) {
            revert GambitErrorsV1.WrongParams();
        }

        // check priceId is valid
        PythStructs.Price memory unsafePrice = pyth.getPriceUnsafe(f.priceId1);
        require(unsafePrice.price != 0, "Invalid priceId");

        require(
            price.publishTime + DURATION > block.timestamp,
            "Unchallengable price"
        );

        ReportedPrice storage report = reportedPriceOf[orderId];
        report.priceId = f.priceId1;
        report.price = price;
        nReportedPrices++;

        emit PriceReported(orderId, f.priceId1, price);
    }

    function isChallenged(uint256 orderId) public view returns (bool) {
        return reportedPriceOf[orderId].challengedAt != 0;
    }

    function challengable(uint256 orderId) public view returns (bool) {
        return
            !isChallenged(orderId) &&
            reportedPriceOf[orderId].price.publishTime + DURATION >
            block.timestamp;
    }

    function challenge(
        uint256 orderId,
        bytes calldata priceUpdateData
    ) external payable {
        require(challengable(orderId), "Not challengable");

        ReportedPrice storage report = reportedPriceOf[orderId];

        PythStructs.PriceFeed[] memory priceFeeds = _parsePriceFeedUpdates(
            report,
            priceUpdateData
        );

        // check reported price data is different with given update data
        bool valid = false;
        PythStructs.Price memory challengedPrice;
        for (uint i = 0; i < priceFeeds.length && !valid; i++) {
            PythStructs.PriceFeed memory priceFeed = priceFeeds[i];
            if (priceFeed.price.publishTime == report.price.publishTime) {
                if (
                    priceFeed.price.price != report.price.price ||
                    priceFeed.price.conf != report.price.conf ||
                    priceFeed.price.expo != report.price.expo
                ) {
                    valid = true;
                    challengedPrice = priceFeed.price;
                }
            }
        }

        require(valid, "Invalid update data");

        if (valid) {
            report.challenger = msg.sender;
            report.challengedAt = uint64(block.timestamp);
            challengedOrderIds.push(orderId);

            emit ChallengeInitiated(
                orderId,
                report.priceId,
                msg.sender,
                challengedPrice,
                block.timestamp
            );
        }
    }

    function isResolved(uint256 orderId) public view returns (bool) {
        return reportedPriceOf[orderId].resolved;
    }

    function resolvable(uint256 orderId) public view returns (bool) {
        return
            !isResolved(orderId) &&
            isChallenged(orderId) &&
            reportedPriceOf[orderId].challengedAt + DURATION > block.timestamp;
    }

    function resolve(
        uint256 orderId,
        bytes calldata priceUpdateData
    ) external payable {
        require(resolvable(orderId), "Not resolvable");

        ReportedPrice storage report = reportedPriceOf[orderId];

        PythStructs.PriceFeed[] memory priceFeeds = _parsePriceFeedUpdates(
            report,
            priceUpdateData
        );

        bool valid = false;
        for (uint i = 0; i < priceFeeds.length && !valid; i++) {
            PythStructs.PriceFeed memory priceFeed = priceFeeds[i];
            if (priceFeed.price.publishTime == report.price.publishTime) {
                if (
                    priceFeed.price.price == report.price.price ||
                    priceFeed.price.conf == report.price.conf ||
                    priceFeed.price.expo == report.price.expo
                ) {
                    valid = true;
                }
            }
        }

        require(valid, "Invalid update data");

        report.resolved = true;
        emit ChallengeResolved(
            orderId,
            report.priceId,
            msg.sender,
            report.price
        );

        // also finalize the challenge
        finalize(orderId);
    }

    function isFinalized(uint256 orderId) public view returns (bool) {
        return reportedPriceOf[orderId].finalized;
    }

    function finalizable(uint256 orderId) public view returns (bool) {
        return
            !isFinalized(orderId) &&
            isChallenged(orderId) &&
            (isResolved(orderId) ||
                reportedPriceOf[orderId].challengedAt + DURATION <
                block.timestamp);
    }

    /**
     * @dev finalize challenge and slash collateral if the challenge is valid.
     */
    function finalize(uint256 orderId) public {
        require(finalizable(orderId), "Not finalizable");

        ReportedPrice storage report = reportedPriceOf[orderId];

        uint256 reward;
        if (!isResolved(orderId)) {
            // transfer all CNG to the challanger
            reward = CNG.balanceOf(address(this));
            report.slashed = true;
            CNG.transfer(report.challenger, reward);
        }

        report.finalized = true;
        nFinalizedChallenges++;

        emit ChallengeFinalized(
            orderId,
            report.challenger,
            report.slashed,
            reward
        );
    }

    function makeClaimRequest(uint256 amount) external onlyGov {
        if (amount > CNG.balanceOf(address(this))) {
            revert GambitErrorsV1.InsufficientCNG();
        }

        require(
            challengedOrderIds.length == nFinalizedChallenges,
            "Remaining challenges"
        );

        ClaimRequest memory request = ClaimRequest({
            amount: amount,
            requestedAt: block.timestamp,
            nFinalizedChallenges: nFinalizedChallenges,
            claimed: false
        });

        claimRequests.push(request);

        emit ClaimRequested(amount, nFinalizedChallenges, block.timestamp);
    }

    function claim(uint256 requestId) external onlyGov {
        require(
            challengedOrderIds.length == nFinalizedChallenges,
            "Remaining challenges"
        );

        ClaimRequest memory request = claimRequests[requestId];
        require(!request.claimed, "Already claimed");
        require(
            request.requestedAt + DURATION < block.timestamp,
            "Too early to claim"
        );
        require(
            request.nFinalizedChallenges == nFinalizedChallenges,
            "New challenge exists"
        );

        if (request.amount > CNG.balanceOf(address(this))) {
            revert GambitErrorsV1.InsufficientCNG();
        }

        request.claimed = true;

        emit Claimed(request.amount);

        CNG.transfer(storageT.gov(), request.amount);
    }

    function _parsePriceFeedUpdates(
        ReportedPrice storage report,
        bytes calldata priceUpdateData
    ) internal returns (PythStructs.PriceFeed[] memory priceFeeds) {
        bytes[] memory updateData = new bytes[](1);
        bytes32[] memory priceIds = new bytes32[](1);
        updateData[0] = priceUpdateData;
        priceIds[0] = report.priceId;

        uint256 updateFee = pyth.getUpdateFee(updateData);
        if (msg.value < updateFee) {
            revert GambitErrorsV1.InsufficientPythFee();
        }

        priceFeeds = pyth.parsePriceFeedUpdates{value: updateFee}(
            updateData,
            priceIds,
            uint64(report.price.publishTime - 1),
            uint64(report.price.publishTime + 1)
        );
    }
}

// Testing 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43 at 1701681420
// [2023-12-04T09:23:58.483Z] price=41638.30365211      , conf=16.10365211         , publishTime=1701681420
// [2023-12-04T09:27:32.119Z] price=41635.01            , conf=13.03213661         , publishTime=1701681420
// Price mismatch
// Conf mismatch

// Testing 0xff61491a931112ddf1bd8147cd1b641375f79f5825126d665480874634fd0ace at 1701687600
// [2023-12-04T11:06:55.791Z] on-chain price=2261.09909198  , conf=0.96038948, publishTime=1701687600 off-chain price=2261.09909198  , conf=0.96038948 1701687600
// [2023-12-04T11:13:24.677Z] on-chain price=2260.97634172  , conf=0.82404356, publishTime=1701687600 off-chain price=2260.97634172  , conf=0.82404356 1701687600

// Testing 0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43 at 1701812760
// [2023-12-05T21:46:57.834Z] on-chain price=43951.73058056 , conf=16.83608787, publishTime=1701812760 off-chain price=43951.73058056 , conf=16.83608787 1701812760
// [2023-12-05T21:52:55.558Z] on-chain price=43951.81294029 , conf=18.41165225, publishTime=1701812760 off-chain price=43952.62       , conf=17.60459254 1701812760

// Testing 0x3fa4252848f9f0a1480be62745a4629d9eb1322aebab8a791e344b3b9c1adcf5 at 1701739440
// [2023-12-05T01:26:11.913Z] on-chain price=1.0905         , conf=0.000718  , publishTime=1701739440 off-chain price=1.0905         , conf=0.000718   1701739440
// [2023-12-05T01:30:58.529Z] on-chain price=1.09049164     , conf=0.00065523, publishTime=1701739440 off-chain price=1.0905         , conf=0.000718   1701739440

// Testing 0x3fa4252848f9f0a1480be62745a4629d9eb1322aebab8a791e344b3b9c1adcf5 at 1701738780
// [2023-12-05T01:16:54.161Z] on-chain price=1.1001615      , conf=0.0006614 , publishTime=1701738780 off-chain price=1.1001615      , conf=0.0006614  1701738780
// [2023-12-05T01:19:56.520Z] on-chain price=1.10023185     , conf=0.00056815, publishTime=1701738780 off-chain price=1.10023185     , conf=0.00056815 1701738780

// Testing 0x78d185a741d07edb3412b09008b7c5cfb9bbbd7d568bf00ba737b456ba171501 at 1701850200
// [2023-12-06T08:16:55.160Z] on-chain price=6.11584882     , conf=0.00596481, publishTime=1701850200 off-chain price=6.11584882     , conf=0.00596481 1701850200
// [2023-12-06T12:45:13.573Z] on-chain price=6.11587743     , conf=0.00665291, publishTime=1701850200 off-chain price=6.11587743     , conf=0.00665291 1701850200

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PythStructs} from "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

interface IGambitCNGCollateral {
    function reportPrice(
        uint256 orderId,
        uint256 pairIndex,
        PythStructs.Price memory price
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../vault/interfaces/ISimpleGToken.sol";
import "../../pair-storage/interfaces/IGambitPairsStorageV1.sol";

import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface IGambitTradingStorageV1 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint openPrice; // PRECISION
        bool buy;
        uint leverage; // 1e18
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUsdc; // PRECISION
        uint openInterestUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e6 (USDC) or 1e18 (DAI)
        uint spreadReductionP;
        bool buy;
        uint leverage; // 1e18
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
    struct PendingNftOrder {
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    struct PendingRemoveCollateralOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint amount;
        uint openPrice;
        bool buy;
    }

    function PRECISION() external pure returns (uint);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function usdc() external view returns (IERC20);

    function usdcDecimals() external view returns (uint8);

    function token() external view returns (TokenInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (ISimpleGToken);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUsdc(address, address, uint) external;

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

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

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

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function reqID_pendingRemoveCollateralOrder(
        uint
    ) external view returns (PendingRemoveCollateralOrder memory);

    function storePendingRemoveCollateralOrder(
        PendingRemoveCollateralOrder memory,
        uint
    ) external;

    function unregisterPendingRemoveCollateralOrder(uint) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function increaseNftRewards(uint, uint) external;

    function nftSuccessTimelock() external view returns (uint);

    function reqID_pendingNftOrder(
        uint
    ) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint) external view returns (uint);

    function unregisterPendingNftOrder(uint) external;

    function handleDevGovFees(uint, uint, bool) external returns (uint);

    function handleGovFee(uint) external;

    function getDevGovFees(uint, uint, bool) external view returns (uint);

    function distributeLpRewards(uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function openInterestUsdc(uint, uint) external view returns (uint);

    function openInterestToken(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function nfts(uint) external view returns (NftInterfaceV5);

    function fakeBlockNumber() external view returns (uint); // Testing
}

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL,
        REMOVE_COLLATERAL
    }

    function pyth() external returns (IPyth);

    function PYTH_PRICE_AGE() external returns (uint);

    function pairsStorage() external view returns (IGambitPairsStorageV1);

    function getPrice(uint, OrderType, uint) external returns (uint);

    function fulfill(
        uint orderId,
        PythStructs.Price calldata pythPrice
    ) external payable returns (uint256 price, uint256 conf, bool success);

    function tokenPriceUsdc() external returns (uint);

    function openFeeP(uint) external view returns (uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

interface NftRewardsInterfaceV6 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        IGambitTradingStorageV1.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeNftReward(TriggeredLimitId calldata, uint) external;

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
pragma solidity ^0.8.0;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISimpleGToken {
    function manager() external view returns (address);

    function gov() external view returns (address);

    function currentEpoch() external view returns (uint);

    function currentEpochStart() external view returns (uint);

    function currentEpochPositiveOpenPnl() external view returns (uint);

    function updateAccPnlPerTokenUsed(
        uint prevPositiveOpenPnl,
        uint newPositiveOpenPnl
    ) external returns (uint);

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function distributeReward(uint assets) external;

    function currentBalanceUsdc() external view returns (uint);
}