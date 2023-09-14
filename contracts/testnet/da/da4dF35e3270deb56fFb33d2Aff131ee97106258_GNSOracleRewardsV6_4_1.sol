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
pragma solidity 0.8.17;

interface ChainlinkFeedInterfaceV5 {
    function latestRoundData() external view returns (uint80, int, uint, uint, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.9.0;

/**
 * @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface IArbSys {
    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external pure returns (uint);

    function arbChainID() external view returns (uint);

    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination) external payable returns (uint);

    /**
     * @notice Send a transaction to L1
     * @param destination recipient address on L1
     * @param calldataForL1 (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata calldataForL1) external payable returns (uint);

    /**
     * @notice get the number of transactions issued by the given external account or the account sequence number of the given contract
     * @param account target account
     * @return the number of transactions issued by the given external account or the account sequence number of the given contract
     */
    function getTransactionCount(address account) external view returns (uint256);

    /**
     * @notice get the value of target L2 storage slot
     * This function is only callable from address 0 to prevent contracts from being able to call it
     * @param account target account
     * @param index target index of storage slot
     * @return stotage value for the given account at the given index
     */
    function getStorageAt(address account, uint256 index) external view returns (uint256);

    /**
     * @notice check if current call is coming from l1
     * @return true if the caller of this was called directly from L1
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param dest destination address
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address dest) external pure returns (address);

    /**
     * @notice get the caller's amount of available storage gas
     * @return amount of storage gas available to the caller
     */
    function getStorageGasAvailable() external view returns (uint);

    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint indexed uniqueId,
        uint indexed batchNumber,
        uint indexInBatch,
        uint arbBlockNum,
        uint ethBlockNum,
        uint timestamp,
        uint callvalue,
        bytes data
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGNSOracle {
    function getAuthorizationStatus(address) external view returns (bool);

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGToken {
    function manager() external view returns (address);

    function admin() external view returns (address);

    function currentEpoch() external view returns (uint);

    function currentEpochStart() external view returns (uint);

    function currentEpochPositiveOpenPnl() external view returns (uint);

    function updateAccPnlPerTokenUsed(uint prevPositiveOpenPnl, uint newPositiveOpenPnl) external returns (uint);

    struct LockedDeposit {
        address owner;
        uint shares; // 1e18
        uint assetsDeposited; // 1e18
        uint assetsDiscount; // 1e18
        uint atTimestamp; // timestamp
        uint lockDuration; // timestamp
    }

    function getLockedDeposit(uint depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function distributeReward(uint assets) external;

    function currentBalanceDai() external view returns (uint);

    function tvl() external view returns (uint);

    function marketCap() external view returns (uint);

    function getPendingAccBlockWeightedMarketCap(uint currentBlock) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface PairsStorageInterfaceV6 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function incrementCurrentOrderId() external returns (uint);

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(uint) external returns (string memory, string memory, bytes32, uint);

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

    function pairNftLimitOrderFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosDai(uint) external view returns (uint);

    function pairsCount() external view returns (uint);
}

// SPDX-License-Identifier: MIT
import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";
import "./IGToken.sol";
import "./PairsStorageInterfaceV6.sol";
import "./ChainlinkFeedInterfaceV5.sol";

pragma solidity 0.8.17;

interface PoolInterfaceV5 {
    function increaseAccTokensPerLp(uint) external;
}

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface StorageInterfaceV5 {
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
        uint positionSizeDai; // 1e18
        uint openPrice; // PRECISION
        bool buy;
        uint leverage;
        uint tp; // PRECISION
        uint sl; // PRECISION
    }
    struct TradeInfo {
        uint tokenId;
        uint tokenPriceDai; // PRECISION
        uint openInterestDai; // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e18 (DAI or GFARM2)
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
    struct PendingNftOrder {
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (TokenInterfaceV5);

    function token() external view returns (TokenInterfaceV5);

    function linkErc677() external view returns (TokenInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6_4);

    function vault() external view returns (IGToken);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferDai(address, address, uint) external;

    function transferLinkToAggregator(address, uint, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(address, uint, uint) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;

    function openTrades(address, uint, uint) external view returns (Trade memory);

    function openTradesInfo(address, uint, uint) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(address, uint, uint) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(address, uint) external view returns (uint);

    function increaseNftRewards(uint, uint) external;

    function nftSuccessTimelock() external view returns (uint);

    function reqID_pendingNftOrder(uint) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint) external view returns (uint);

    function unregisterPendingNftOrder(uint) external;

    function handleDevGovFees(uint, uint, bool, bool) external returns (uint);

    function distributeLpRewards(uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(address, uint) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function openInterestDai(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function nfts(uint) external view returns (NftInterfaceV5);

    function fakeBlockNumber() external view returns (uint); // Testing
}

interface IStateCopyUtils {
    function getOpenLimitOrders() external view returns (StorageInterfaceV5.OpenLimitOrder[] memory);

    function nftRewards() external view returns (NftRewardsInterfaceV6_3_1);
}

interface NftRewardsInterfaceV6_3_1 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterfaceV5.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address, uint) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeNftReward(TriggeredLimitId calldata, uint, uint) external;

    function openLimitOrderTypes(address, uint, uint) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);

    function botInUse(bytes32) external view returns (bool);

    function getNftBotHashes(uint, address, uint, address, uint, uint) external pure returns (bytes32, bytes32);

    function setNftBotInUse(bytes32, bytes32) external;

    function nftBotInUse(bytes32, bytes32) external view returns (bool);

    function linkToTokenRewards(uint, uint) external view returns (uint);
}

interface AggregatorInterfaceV6_4 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    function pairsStorage() external view returns (PairsStorageInterfaceV6);

    function getPrice(uint, OrderType, uint, uint) external returns (uint);

    function tokenPriceDai() external returns (uint);

    function linkFee(uint, uint) external view returns (uint);

    function openFeeP(uint) external view returns (uint);

    function linkPriceFeed() external view returns (ChainlinkFeedInterfaceV5);

    function nodes(uint index) external view returns (address);
}

interface TradingCallbacksV6_4 {
    enum TradeType {
        MARKET,
        LIMIT
    }
    struct SimplifiedTradeId {
        address trader;
        uint pairIndex;
        uint index;
        TradeType tradeType;
    }
    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }
    struct TradeData {
        uint40 maxSlippageP; // 1e10 (%)
        uint216 _placeholder; // for potential future data
    }

    function tradeLastUpdated(address, uint, uint, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function setTradeData(SimplifiedTradeId calldata, TradeData memory) external;

    function canExecuteTimeout() external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function decimals() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

library ChainUtils {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint blockNumber) internal pure returns (uint48) {
        require(blockNumber <= type(uint48).max, "OVERFLOW");
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../libraries/ChainUtils.sol";
import "../interfaces/StorageInterfaceV5.sol";
import "../interfaces/IGNSOracle.sol";

contract GNSOracleRewardsV6_4_1 is Initializable {
    // Constants
    uint private constant CHAIN_ID_POLY = 137;
    uint private constant CHAIN_ID_MUMBAI = 80001;
    uint private constant CHAIN_ID_ARBI = 42161;

    address private constant NFT_REWARDS_OLD_POLY = 0x8103C0665A544201BBF606d90845d1B2D8005F1c;
    address private constant NFT_REWARDS_OLD_MUMBAI = 0xf7Ac400b45Bdd2E098FaCA3642bE4d01071BC73B;
    address private constant NFT_REWARDS_OLD_ARBI = 0xde5750071CacA8db173FC6543D23d0BCACACFEC3;

    uint private constant MIN_TRIGGER_TIMEOUT = 1;

    // Addresses (constant)
    StorageInterfaceV5 public storageT;
    mapping(uint => address) public nftRewardsOldByChainId;

    // Params (adjustable)
    uint public triggerTimeout; // blocks
    address[] public oracles; // oracles rewarded

    // Custom data types
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        StorageInterfaceV5.LimitOrder order;
    }

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    // State
    mapping(address => uint) public pendingRewardGns;
    mapping(address => mapping(uint => mapping(uint => mapping(StorageInterfaceV5.LimitOrder => uint))))
        public triggeredLimits;
    mapping(address => mapping(uint => mapping(uint => OpenLimitOrderType))) public openLimitOrderTypes;

    bool public stateCopied;

    // Events
    event OldLimitTypesCopied(address oldContract, uint start, uint end);
    event StateCopyDone();
    event TriggerTimeoutUpdated(uint value);
    event OraclesUpdated(uint oraclesCount);

    event TriggeredFirst(TriggeredLimitId id);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(TriggeredLimitId id, uint rewardGns, uint rewardGnsPerOracle, uint oraclesCount);
    event RewardsClaimed(address oracle, uint amountGns);
    event OpenLimitOrderTypeSet(address trader, uint pairIndex, uint index, OpenLimitOrderType value);

    function initialize(StorageInterfaceV5 _storageT, uint _triggerTimeout, uint _oraclesCount) external initializer {
        require(
            address(_storageT) != address(0) && _triggerTimeout >= MIN_TRIGGER_TIMEOUT && _oraclesCount > 0,
            "WRONG_PARAMS"
        );

        nftRewardsOldByChainId[CHAIN_ID_POLY] = NFT_REWARDS_OLD_POLY;
        nftRewardsOldByChainId[CHAIN_ID_MUMBAI] = NFT_REWARDS_OLD_MUMBAI;
        nftRewardsOldByChainId[CHAIN_ID_ARBI] = NFT_REWARDS_OLD_ARBI;

        storageT = _storageT;
        triggerTimeout = _triggerTimeout;

        _updateOracles(_oraclesCount);
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

    // Copy limit order types from old nft rewards contract
    // TODO: this needs to be disabled for greenfield deployment
    function copyOldLimitTypes(uint _start, uint _end) external onlyGov {
        require(!stateCopied, "COPY_DONE");
        require(_start <= _end, "START_AFTER_END");

        address oldAddress = nftRewardsOldByChainId[block.chainid];
        require(oldAddress != address(0), "UNKNOWN_CHAIN");

        StorageInterfaceV5.OpenLimitOrder[] memory openLimitOrders = IStateCopyUtils(address(storageT))
            .getOpenLimitOrders();

        require(_start < openLimitOrders.length, "START_TOO_BIG");

        if (_end >= openLimitOrders.length) {
            _end = openLimitOrders.length - 1;
        }

        NftRewardsInterfaceV6_3_1 old = NftRewardsInterfaceV6_3_1(oldAddress);

        for (uint i = _start; i <= _end; ) {
            StorageInterfaceV5.OpenLimitOrder memory o = openLimitOrders[i];

            openLimitOrderTypes[o.trader][o.pairIndex][o.index] = OpenLimitOrderType(
                uint(old.openLimitOrderTypes(o.trader, o.pairIndex, o.index))
            );

            unchecked {
                ++i;
            }
        }

        emit OldLimitTypesCopied(oldAddress, _start, _end);
    }

    function setStateCopyAsDone() external onlyGov {
        stateCopied = true;

        emit StateCopyDone();
    }

    // Manage params
    function updateTriggerTimeout(uint _triggerTimeout) external onlyGov {
        require(_triggerTimeout >= MIN_TRIGGER_TIMEOUT, "BELOW_MIN");

        triggerTimeout = _triggerTimeout;

        emit TriggerTimeoutUpdated(_triggerTimeout);
    }

    function _updateOracles(uint _oraclesCount) private {
        require(_oraclesCount > 0, "VALUE_ZERO");

        delete oracles;

        for (uint i; i < _oraclesCount; ) {
            oracles.push(storageT.priceAggregator().nodes(i));

            unchecked {
                ++i;
            }
        }

        emit OraclesUpdated(_oraclesCount);
    }

    function updateOracles(uint _oraclesCount) external onlyGov {
        _updateOracles(_oraclesCount);
    }

    // Triggers
    function storeTrigger(TriggeredLimitId calldata _id) external onlyTrading {
        triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order] = ChainUtils.getBlockNumber();

        emit TriggeredFirst(_id);
    }

    function unregisterTrigger(TriggeredLimitId calldata _id) external onlyCallbacks {
        delete triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        emit TriggerUnregistered(_id);
    }

    // Distribute oracle rewards
    function distributeOracleReward(TriggeredLimitId calldata _id, uint _reward) external onlyCallbacks {
        require(triggered(_id), "NOT_TRIGGERED");

        uint oraclesCount = oracles.length;
        uint rewardPerOracle = _reward / oraclesCount;

        for (uint i; i < oraclesCount; ) {
            pendingRewardGns[oracles[i]] += rewardPerOracle;

            unchecked {
                ++i;
            }
        }

        storageT.handleTokens(address(this), _reward, true);

        emit TriggerRewarded(_id, _reward, rewardPerOracle, oraclesCount);
    }

    // Claim oracle rewards
    function claimRewards(address _oracle) external {
        IGNSOracle _o = IGNSOracle(_oracle);

        // msg.sender must either be the oracle owner or an authorized fulfiller
        require(_o.owner() == msg.sender || _o.getAuthorizationStatus(msg.sender), "NOT_AUTHORIZED");

        uint amountGns = pendingRewardGns[_oracle];

        pendingRewardGns[_oracle] = 0;
        storageT.token().transfer(msg.sender, amountGns);

        emit RewardsClaimed(_oracle, amountGns);
    }

    // Manage open limit order types
    function setOpenLimitOrderType(
        address _trader,
        uint _pairIndex,
        uint _index,
        OpenLimitOrderType _type
    ) external onlyTrading {
        openLimitOrderTypes[_trader][_pairIndex][_index] = _type;

        emit OpenLimitOrderTypeSet(_trader, _pairIndex, _index, _type);
    }

    // Getters
    function triggered(TriggeredLimitId calldata _id) public view returns (bool) {
        return triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order] > 0;
    }

    function timedOut(TriggeredLimitId calldata _id) external view returns (bool) {
        uint triggerBlock = triggeredLimits[_id.trader][_id.pairIndex][_id.index][_id.order];

        return triggerBlock > 0 && ChainUtils.getBlockNumber() - triggerBlock >= triggerTimeout;
    }

    function getOracles() external view returns (address[] memory) {
        return oracles;
    }
}