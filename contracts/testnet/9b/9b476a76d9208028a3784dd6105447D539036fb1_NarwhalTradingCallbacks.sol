// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import "./interfaces/PairInfoInterface.sol";
import "./interfaces/NarwhalReferralInterface.sol";
import "./interfaces/LimitOrdersInterface.sol";

contract NarwhalTradingCallbacks is Initializable, PausableUpgradeable {

    StorageInterface public storageT;
    LimitOrdersInterface public limitOrders;
    PairInfoInterface public pairInfos;
    NarwhalReferralInterface public referrals;

    address public Treasury;
    address public MarketingFund;

    // Params
    uint public PRECISION; // 10 decimals
    uint public MAX_SL_P; // -90% PNL
    uint public MAX_GAIN_P; // 900% PnL (10x)

    // Params (adjustable)
    uint public USDTVaultFeeP; // % of closing fee going to USDT vault (eg. 40)
    uint public lpFeeP; // % of closing fee going to NWX/USDT LPs (eg. 20)
    uint public projectFeeP; // % of closing fee going to treasury (eg. 40)
    uint public marketingFeeP; // % of closing fee going to marketing fund


    // Custom data types
    struct AggregatorAnswer {
        uint orderId;
        uint price;
        uint spreadP;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint posUSDT;
        uint levPosUSDT;
        uint tokenPriceUSDT;
        int profitP;
        uint price;
        uint liqPrice;
        uint USDTSentToTrader;
        uint reward1;
        uint reward2;
        uint reward3;
        uint reward4;
        uint reward5;
        uint leftoverFees;
        uint totalFees;
    }

    function initialize (
        StorageInterface _storageT,
        LimitOrdersInterface _limitOrders,
        PairInfoInterface _pairInfos,
        NarwhalReferralInterface _referrals,
        uint _USDTVaultFeeP,
        uint _lpFeeP,
        uint _projectFeeP,
        uint256 _marketingFeeP
    ) public initializer {
        storageT = _storageT;
        limitOrders = _limitOrders;
        pairInfos = _pairInfos;
        referrals = _referrals;

        require(_USDTVaultFeeP + _lpFeeP + _projectFeeP + _marketingFeeP == 100, "SUM_NOT_100");
        require(address(_storageT) != address(0) &&
            address(_limitOrders) != address(0) &&
            address(_pairInfos) != address(0) &&
            address(_referrals) != address(0), "ZERO_ADDRESS");

        USDTVaultFeeP = _USDTVaultFeeP;
        lpFeeP = _lpFeeP;
        projectFeeP = _projectFeeP;
        marketingFeeP = _marketingFeeP;

        PRECISION = 1e10; // 10 decimals
        MAX_SL_P = 90; // -90% PNL
        MAX_GAIN_P = 900; // 900% PnL (10x)
        
        Treasury = msg.sender;
        MarketingFund = msg.sender;
        __Pausable_init();
    }
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function setCoreSettings(
        StorageInterface _storageT,
        LimitOrdersInterface _limitOrders,
        PairInfoInterface _pairInfos,
        NarwhalReferralInterface _referrals,
        uint _USDTVaultFeeP,
        uint _lpFeeP,
        uint _projectFeeP,
        uint256 _marketingFeeP) public onlyGov {
        storageT = _storageT;
        limitOrders = _limitOrders;
        pairInfos = _pairInfos;
        referrals = _referrals;

        require(_USDTVaultFeeP + _lpFeeP + _projectFeeP + _marketingFeeP == 100, "SUM_NOT_100");
        require(address(_storageT) != address(0) &&
            address(_limitOrders) != address(0) &&
            address(_pairInfos) != address(0) &&
            address(_referrals) != address(0), "ZERO_ADDRESS");

        USDTVaultFeeP = _USDTVaultFeeP;
        lpFeeP = _lpFeeP;
        projectFeeP = _projectFeeP;
        marketingFeeP = _marketingFeeP;
    }

    function giveAllowance() public onlyGov {
        storageT.USDT().approve(address(storageT.vault()), type(uint256).max);
        storageT.USDT().approve(address(storageT.pool()), type(uint256).max);
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyPriceAggregator() {
        require(
            msg.sender == address(storageT.priceAggregator()),
            "AGGREGATOR_ONLY"
        );
        _;
    }

    function openTradeMarketCallback(
        AggregatorAnswer memory a
    ) external whenNotPaused onlyPriceAggregator {
        StorageInterface.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        StorageInterface.Trade memory t = o.trade;

        (uint priceImpactP, uint priceAfterImpact) = pairInfos
            .getTradePriceImpact(
                marketExecutionPrice(
                    a.price,
                    a.spreadP,
                    o.spreadReductionP,
                    t.buy
                ),
                t.pairIndex,
                t.buy,
                t.positionSizeUSDT * t.leverage
            );

        t.openPrice = priceAfterImpact;
        uint maxSlippage = (o.wantedPrice * o.slippageP) / 100 / PRECISION;

        if (a.price == 0 ||
            (
                t.buy
                    ? t.openPrice > o.wantedPrice + maxSlippage
                    : t.openPrice < o.wantedPrice - maxSlippage
            ) ||
            (t.tp > 0 && (t.buy ? t.openPrice >= t.tp : t.openPrice <= t.tp)) ||
            (t.sl > 0 && (t.buy ? t.openPrice <= t.sl : t.openPrice >= t.sl)) ||
            !withinExposureLimits(
                t.pairIndex,
                t.buy,
                t.positionSizeUSDT,
                t.leverage
            ) ||
            priceImpactP * t.leverage > pairInfos.maxNegativePnlOnOpenP()
        ) {
            storageT.transferUSDT(
                address(storageT),
                t.trader,
                t.positionSizeUSDT
            );

        } else {
            registerTrade(t, a.orderId, false);
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator {
        StorageInterface.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        StorageInterface.Trade memory t = storageT.openTrades(
            o.trade.trader,
            o.trade.pairIndex,
            o.trade.index
        );

        if (t.leverage > 0) {
            StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
                t.trader,
                t.pairIndex,
                t.index
            );

            AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
            PairsStorageInterface pairsStorage = aggregator.pairsStorage();

            Values memory v;

            v.levPosUSDT =
                (t.initialPosToken * i.tokenPriceUSDT * t.leverage) / PRECISION / 1e8;
            if (a.price == 0) {
                t.initialPosToken -= (v.reward1 * PRECISION) / i.tokenPriceUSDT;
                storageT.updateTrade(t);

            } else {
                v.profitP = currentPercentProfit(
                    t.openPrice,
                    a.price,
                    t.buy,
                    t.leverage
                );
                v.posUSDT = v.levPosUSDT / t.leverage;
                v.USDTSentToTrader = unregisterTrade(
                    t,
                    v.profitP,
                    v.posUSDT,
                    i.openInterestUSDT / t.leverage,
                    (v.levPosUSDT * pairsStorage.pairCloseFeeP(t.pairIndex)) /
                        100000,
                    0
                );
            }
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }

    function executeOpenOrderCallback(
        AggregatorAnswer memory a
    ) external whenNotPaused onlyPriceAggregator {
        StorageInterface.PendingLimitOrder memory n = storageT
            .reqID_pendingLimitOrder(a.orderId);
        require(n.trader != address(0), "INVALID_ORDER");

        if (a.price > 0 &&
            storageT.hasOpenLimitOrder(n.trader, n.pairIndex, n.index)
        ) {

            StorageInterface.OpenLimitOrder memory o = storageT
                .getOpenLimitOrder(n.trader, n.pairIndex, n.index);

            LimitOrdersInterface.OpenLimitOrderType t = limitOrders
                .openLimitOrderTypes(n.trader, n.pairIndex, n.index);

            (uint priceImpactP, uint priceAfterImpact) = pairInfos
                .getTradePriceImpact(
                    marketExecutionPrice(
                        a.price,
                        a.spreadP,
                        o.spreadReductionP,
                        o.buy
                    ),
                    o.pairIndex,
                    o.buy,
                    o.positionSize * o.leverage
                );

            a.price = priceAfterImpact;
            if (
                (
                    t == LimitOrdersInterface.OpenLimitOrderType.LEGACY
                        ? (a.price >= o.minPrice && a.price <= o.maxPrice)
                        : t == LimitOrdersInterface.OpenLimitOrderType.REVERSAL
                        ? (
                            o.buy
                                ? a.price <= o.maxPrice
                                : a.price >= o.minPrice
                        )
                        : (
                            o.buy
                                ? a.price >= o.minPrice
                                : a.price <= o.maxPrice
                        )
                ) &&
                withinExposureLimits(
                    o.pairIndex,
                    o.buy,
                    o.positionSize,
                    o.leverage
                ) &&
                priceImpactP * o.leverage <= pairInfos.maxNegativePnlOnOpenP()
            ) {
 
                registerTrade(
                        StorageInterface.Trade(
                            o.trader,
                            o.pairIndex,
                            0,
                            0,
                            o.positionSize,
                            t ==
                                LimitOrdersInterface.OpenLimitOrderType.REVERSAL
                                ? o.maxPrice
                                : a.price,
                            o.buy,
                            o.leverage,
                            o.tp,
                            o.sl
                        ),
                        a.orderId,
                        true
                    );

                storageT.unregisterOpenLimitOrder(
                    o.trader,
                    o.pairIndex,
                    o.index
                );
            }
        }

        limitOrders.unregisterTrigger(
            LimitOrdersInterface.TriggeredLimitId(
                n.trader,
                n.pairIndex,
                n.index,
                n.orderType
            )
        );

        storageT.unregisterPendingLimitOrder(a.orderId);
    }

    function executeCloseOrderCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator {
        StorageInterface.PendingLimitOrder memory o = storageT
            .reqID_pendingLimitOrder(a.orderId);
        StorageInterface.Trade memory t = storageT.openTrades(
            o.trader,
            o.pairIndex,
            o.index
        );

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if (a.price > 0 && t.leverage > 0) {
            StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
                t.trader,
                t.pairIndex,
                t.index
            );

            PairsStorageInterface pairsStored = aggregator.pairsStorage();

            Values memory v;

            v.price = pairsStored.guaranteedSlEnabled(t.pairIndex)
                ? o.orderType == StorageInterface.LimitOrder.TP
                    ? t.tp
                    : o.orderType == StorageInterface.LimitOrder.SL
                    ? t.sl
                    : a.price
                : a.price;

            v.profitP = currentPercentProfit(
                t.openPrice,
                v.price,
                t.buy,
                t.leverage
            );
            v.levPosUSDT =
                (t.initialPosToken * i.tokenPriceUSDT * t.leverage) /
                PRECISION /
                1e8;
            
            v.posUSDT = v.levPosUSDT / t.leverage;

            if (o.orderType == StorageInterface.LimitOrder.LIQ) {
                v.liqPrice = pairInfos.getTradeLiquidationPrice(
                    t.trader,
                    t.pairIndex,
                    t.index,
                    t.openPrice,
                    t.buy,
                    v.posUSDT,
                    t.leverage
                );
                v.reward1 = (
                    t.buy ? a.price <= v.liqPrice : a.price >= v.liqPrice
                )
                    ? (v.posUSDT * 5) / 100
                    : 0;
            } else {
                v.reward1 = ((o.orderType == StorageInterface.LimitOrder.TP &&
                    t.tp > 0 &&
                    (t.buy ? a.price >= t.tp : a.price <= t.tp)) ||
                    (o.orderType == StorageInterface.LimitOrder.SL &&
                        t.sl > 0 &&
                        (t.buy ? a.price <= t.sl : a.price >= t.sl)))
                    ? ((v.levPosUSDT * pairsStored.pairCloseFeeP(t.pairIndex)) /
                        100000) * 5 / 100 : 0;
                
            }

            if (v.reward1 > 0) {
                storageT.transferUSDT(
                    address(storageT),
                    storageT.keeperForOrder(a.orderId),
                    v.reward1
                );
                
                unregisterTrade(
                    t,
                    v.profitP,
                    v.posUSDT - v.reward1,
                    i.openInterestUSDT / t.leverage,
                    (v.levPosUSDT * pairsStored.pairCloseFeeP(t.pairIndex)) /
                        100000 - v.reward1,
                    v.reward1
                );

            }
        }

        limitOrders.unregisterTrigger(
            LimitOrdersInterface.TriggeredLimitId(
                o.trader,
                o.pairIndex,
                o.index,
                o.orderType
            )
        );

        storageT.unregisterPendingLimitOrder(a.orderId);
    }

    function updateSlCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        AggregatorInterfaceV6_2.PendingSl memory o = aggregator.pendingSlOrders(
            a.orderId
        );

        StorageInterface.Trade memory t = storageT.openTrades(
            o.trader,
            o.pairIndex,
            o.index
        );
        if (t.leverage > 0) {
            StorageInterface.TradeInfo memory i = storageT.openTradesInfo(
                o.trader,
                o.pairIndex,
                o.index
            );

            Values memory v;

            v.tokenPriceUSDT = aggregator.tokenPriceUSDT();
            v.levPosUSDT =
                (t.initialPosToken * i.tokenPriceUSDT * t.leverage) /
                PRECISION /
                1e8 /
                2;

            t.initialPosToken -= (v.reward1 * PRECISION) / i.tokenPriceUSDT;
            storageT.updateTrade(t);

            if (
                a.price > 0 &&
                t.buy == o.buy &&
                t.openPrice == o.openPrice &&
                (t.buy ? o.newSl <= a.price : o.newSl >= a.price)
            ) {
                storageT.updateSl(o.trader, o.pairIndex, o.index, o.newSl);
            }
        }

        aggregator.unregisterPendingSlOrder(a.orderId);
    }

    function registerTrade(
        StorageInterface.Trade memory trade,
        uint256 _orderId,
        bool _limit
    ) private returns (StorageInterface.Trade memory, uint) {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        PairsStorageInterface pairsStored = aggregator.pairsStorage();
        Values memory v;

        v.levPosUSDT = trade.positionSizeUSDT * trade.leverage;
        v.tokenPriceUSDT = aggregator.tokenPriceUSDT();
        v.totalFees =
            (v.levPosUSDT *
                (pairsStored.pairOpenFeeP(trade.pairIndex))) /
            100000;
        trade.positionSizeUSDT -= v.totalFees;
        address ref = referrals.getReferral(trade.trader);
        if (ref != address(0)) {
            (uint256 discount, uint256 rebate) = referrals
                .getReferralDiscountAndRebate(trade.trader);
            v.reward2 = (v.totalFees * discount) / 1000;

            storageT.transferUSDT(address(storageT), trade.trader, v.reward2);

            if (referrals.isTier3KOL(ref)) {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementTier2Tier3(
                    ref,
                    v.reward1,
                    (v.totalFees * referrals.tier3tier2RebateBonus()) / 1000,
                    v.levPosUSDT
                );
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000)
                );
                v.leftoverFees =
                    v.totalFees -
                    (v.reward1 +
                        v.reward2 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000));
            } else {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementRewards(ref, v.reward1,v.levPosUSDT);
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1
                );
                v.leftoverFees = v.totalFees - (v.reward1 + v.reward2);
            }
        } else {
            v.leftoverFees = v.totalFees;
        }

        if (_limit) {
            v.reward3 =
                (v.leftoverFees *
                    pairsStored.pairLimitOrderFeeP(trade.pairIndex)) /
                1000;
            storageT.transferUSDT(
                address(storageT),
                storageT.keeperForOrder(_orderId),
                v.reward3
            );
            storageT.transferUSDT(
                address(storageT),
                Treasury,
                (v.leftoverFees * projectFeeP) / 100
            );
        } else {
            storageT.transferUSDT(
                address(storageT),
                Treasury,
                (v.leftoverFees * projectFeeP) / 100
            );
            storageT.transferUSDT(
                address(storageT),
                MarketingFund,
                (v.leftoverFees * marketingFeeP) / 100
            );
        }

        v.reward4 = (v.leftoverFees * USDTVaultFeeP) / 100;
        storageT.transferUSDT(address(storageT), address(this), v.reward4);
        storageT.vault().distributeRewardUSDT(v.reward4, true);

        v.reward5 = (v.leftoverFees * lpFeeP) / 100;
        storageT.distributeLpRewards(v.reward5);

        trade.index = storageT.firstEmptyTradeIndex(
            trade.trader,
            trade.pairIndex
        );
        trade.initialPosToken = trade.positionSizeUSDT * 1e18 / v.tokenPriceUSDT;

        trade.tp = correctTp(
            trade.openPrice,
            trade.leverage,
            trade.tp,
            trade.buy
        );
        trade.sl = correctSl(
            trade.openPrice,
            trade.leverage,
            trade.sl,
            trade.buy
        );

        pairInfos.storeTradeInitialAccFees(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy
        );
        pairsStored.updateGroupCollateral(
            trade.pairIndex,
            trade.positionSizeUSDT,
            trade.buy,
            true
        );

        storageT.storeTrade(
            trade,
            StorageInterface.TradeInfo(
                0,
                v.tokenPriceUSDT,
                trade.positionSizeUSDT * trade.leverage,
                0,
                0,
                false
            )
        );

        return (trade, v.tokenPriceUSDT);
    }

    function unregisterTrade(
        StorageInterface.Trade memory trade,
        int percentProfit, // PRECISION
        uint currentUSDTPos, // usdtDecimals
        uint initialUSDTPos, // usdtDecimals
        uint closingFeeUSDT, // usdtDecimals
        uint limitFeeUSDT
    ) internal returns (uint USDTSentToTrader) {
        USDTSentToTrader = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentUSDTPos,
            trade.leverage,
            percentProfit,
            closingFeeUSDT + limitFeeUSDT
        );
        Values memory v;
        v.totalFees = closingFeeUSDT;
        if (referrals.getReferral(trade.trader) != address(0)) {

            (uint256 discount, uint256 rebate) = referrals
                .getReferralDiscountAndRebate(trade.trader);
            v.reward2 = (v.totalFees * discount) / 1000;
            storageT.transferUSDT(address(storageT), trade.trader, v.reward2);

            if (referrals.isTier3KOL(referrals.getReferral(trade.trader))) {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementTier2Tier3(
                    referrals.getReferral(trade.trader),
                    v.reward1,
                    (v.totalFees * referrals.tier3tier2RebateBonus()) / 1000,
                    trade.positionSizeUSDT * trade.leverage
                );
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000)
                );
                v.leftoverFees =
                    v.totalFees -
                    (v.reward1 +
                        v.reward2 +
                        ((v.totalFees * referrals.tier3tier2RebateBonus()) /
                            1000));
            } else {
                v.reward1 = (v.totalFees * rebate) / 1000;
                referrals.incrementRewards(referrals.getReferral(trade.trader), v.reward1,trade.positionSizeUSDT * trade.leverage);
                storageT.transferUSDT(
                    address(storageT),
                    address(referrals),
                    v.reward1
                );
                v.leftoverFees = v.totalFees - (v.reward1 + v.reward2);
            }
        } else {
            v.leftoverFees = v.totalFees;
        }

        if (trade.positionSizeUSDT > 0) {
            storageT.transferUSDT(
                address(storageT),
                Treasury,
                (v.leftoverFees * projectFeeP) / 100
            );
            storageT.transferUSDT(
                address(storageT),
                MarketingFund,
                (v.leftoverFees * marketingFeeP) / 100
            );

            v.reward4 = (v.leftoverFees * USDTVaultFeeP) / 100;
            storageT.transferUSDT(address(storageT), address(this), v.reward4);
            storageT.vault().distributeRewardUSDT(v.reward4, true);

            v.reward5 = (v.leftoverFees * lpFeeP) / 100;
            storageT.distributeLpRewards(v.reward5);

            uint USDTLeftInStorage = currentUSDTPos - v.totalFees;
            if (USDTSentToTrader > USDTLeftInStorage) {
                storageT.vault().sendUSDTToTrader(
                    trade.trader,
                    USDTSentToTrader - USDTLeftInStorage
                );
                storageT.transferUSDT(
                    address(storageT),
                    trade.trader,
                    USDTLeftInStorage
                );
            } else {
                storageT.vault().receiveUSDTFromTrader(
                    trade.trader,
                    USDTLeftInStorage - USDTSentToTrader,
                    0,
                    false
                );
                storageT.transferUSDT(
                    address(storageT),
                    trade.trader,
                    USDTSentToTrader
                );
            }

        } else {
            storageT.vault().sendUSDTToTrader(trade.trader, USDTSentToTrader);
        }

        storageT.priceAggregator().pairsStorage().updateGroupCollateral(
            trade.pairIndex,
            initialUSDTPos,
            trade.buy,
            false
        );

        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);
    }

    function withinExposureLimits(
        uint pairIndex,
        bool buy,
        uint positionSizeUSDT,
        uint leverage
    ) internal view returns (bool) {
        PairsStorageInterface pairsStored = storageT
            .priceAggregator()
            .pairsStorage();

        uint256 posLev = positionSizeUSDT * leverage;
        uint256 OILimit = storageT.openInterestUSDT(pairIndex, buy ? 0 : 1) + posLev;
        uint256 netOI = storageT.getNetOI(pairIndex, buy);

        return
            OILimit <= storageT.openInterestUSDT(pairIndex, 2) && 
            netOI + posLev <= storageT.openInterestUSDT(pairIndex, buy ? 3 : 4) &&
            pairsStored.groupCollateral(pairIndex, buy) + positionSizeUSDT <=
            pairsStored.groupMaxCollateral(pairIndex);
    }

    function currentPercentProfit(
        uint openPrice,
        uint currentPrice,
        bool buy,
        uint leverage
    ) internal view returns (int p) {
        int maxPnlP = int(MAX_GAIN_P) * int(PRECISION);

        p =
            ((
                buy
                    ? int(currentPrice) - int(openPrice)
                    : int(openPrice) - int(currentPrice)
            ) *
                100 *
                int(PRECISION) *
                int(leverage)) /
            int(openPrice);

        p = p > maxPnlP ? maxPnlP : p;
    }

    function correctTp(
        uint openPrice,
        uint leverage,
        uint tp,
        bool buy
    ) internal view returns (uint) {
        if (
            tp == 0 ||
            currentPercentProfit(openPrice, tp, buy, leverage) ==
            int(MAX_GAIN_P) * int(PRECISION)
        ) {
            uint tpDiff = (openPrice * MAX_GAIN_P) / leverage / 100;

            return
                buy ? openPrice + tpDiff : tpDiff <= openPrice
                    ? openPrice - tpDiff
                    : 0;
        }

        return tp;
    }

    function correctSl(
        uint openPrice,
        uint leverage,
        uint sl,
        bool buy
    ) internal view returns (uint) {
        if (
            sl > 0 &&
            currentPercentProfit(openPrice, sl, buy, leverage) <
            int(MAX_SL_P) * int(PRECISION) * -1
        ) {
            uint slDiff = (openPrice * MAX_SL_P) / leverage / 100;

            return buy ? openPrice - slDiff : openPrice + slDiff;
        }

        return sl;
    }

    function marketExecutionPrice(
        uint price,
        uint spreadP,
        uint spreadReductionP,
        bool long
    ) internal view returns (uint) {
        uint priceDiff = (price *
            (spreadP - (spreadP * spreadReductionP) / 100)) /
            100 /
            PRECISION;

        return long ? price + priceDiff : price - priceDiff;
    }
}