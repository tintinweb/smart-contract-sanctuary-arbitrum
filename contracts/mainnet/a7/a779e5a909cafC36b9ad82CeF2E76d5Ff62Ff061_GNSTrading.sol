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
pragma solidity 0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IGNSTrading.sol";
import "../interfaces/IGNSPairInfos.sol";
import "../interfaces/IGNSReferrals.sol";
import "../interfaces/IGNSBorrowingFees.sol";
import "../interfaces/IGNSOracleRewards.sol";

import "../libraries/ChainUtils.sol";
import "../libraries/TradeUtils.sol";
import "../libraries/PackingUtils.sol";

import "../misc/Delegatable.sol";

/**
 * @custom:version 6.4.2
 * @custom:oz-upgrades-unsafe-allow external-library-linking delegatecall
 */
contract GNSTrading is Initializable, Delegatable, IGNSTrading {
    using TradeUtils for address;
    using PackingUtils for uint256;

    // Contracts (constant)
    IGNSTradingStorage public storageT;
    IGNSOracleRewards public oracleRewards;
    IGNSPairInfos public pairInfos;
    IGNSReferrals public referrals;
    IGNSBorrowingFees public borrowingFees;

    // Params (constant)
    uint256 private constant PRECISION = 1e10;
    uint256 private constant MAX_SL_P = 75; // -75% PNL

    // Params (adjustable)
    uint256 public maxPosDai; // 1e18 (eg. 75000 * 1e18)
    uint256 public marketOrdersTimeout; // block (eg. 30)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract

    mapping(address => bool) public bypassTriggerLink; // Doesn't have to pay link in executeNftOrder()

    function initialize(
        IGNSTradingStorage _storageT,
        IGNSOracleRewards _oracleRewards,
        IGNSPairInfos _pairInfos,
        IGNSReferrals _referrals,
        IGNSBorrowingFees _borrowingFees,
        uint256 _maxPosDai,
        uint256 _marketOrdersTimeout
    ) external initializer {
        require(
            address(_storageT) != address(0) &&
                address(_oracleRewards) != address(0) &&
                address(_pairInfos) != address(0) &&
                address(_referrals) != address(0) &&
                address(_borrowingFees) != address(0) &&
                _maxPosDai > 0 &&
                _marketOrdersTimeout > 0,
            "WRONG_PARAMS"
        );

        storageT = _storageT;
        oracleRewards = _oracleRewards;
        pairInfos = _pairInfos;
        referrals = _referrals;
        borrowingFees = _borrowingFees;

        maxPosDai = _maxPosDai;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov() {
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier notContract() {
        require(tx.origin == msg.sender);
        _;
    }
    modifier notDone() {
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setMaxPosDai(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        maxPosDai = value;
        emit NumberUpdated("maxPosDai", value);
    }

    function setMarketOrdersTimeout(uint256 value) external onlyGov {
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;
        emit NumberUpdated("marketOrdersTimeout", value);
    }

    function setBypassTriggerLink(address user, bool bypass) external onlyGov {
        bypassTriggerLink[user] = bypass;

        emit BypassTriggerLinkUpdated(user, bypass);
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;
        emit Paused(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;
        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        IGNSTradingStorage.Trade memory t,
        IGNSOracleRewards.OpenLimitOrderType orderType, // LEGACY => market
        uint256 slippageP, // 1e10 (%)
        address referrer
    ) external notContract notDone {
        require(!isPaused, "PAUSED");
        require(t.openPrice * slippageP < type(uint256).max, "OVERFLOW");
        require(t.openPrice > 0, "PRICE_ZERO");

        IGNSPriceAggregator aggregator = storageT.priceAggregator();
        IGNSPairsStorage pairsStored = IGNSPairsStorage(aggregator.pairsStorage());

        address sender = _msgSender();

        require(
            storageT.openTradesCount(sender, t.pairIndex) +
                storageT.pendingMarketOpenCount(sender, t.pairIndex) +
                storageT.openLimitOrdersCount(sender, t.pairIndex) <
                storageT.maxTradesPerPair(),
            "MAX_TRADES_PER_PAIR"
        );

        require(storageT.pendingOrderIdsCount(sender) < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");
        require(t.positionSizeDai <= maxPosDai, "ABOVE_MAX_POS");

        uint levPosDai = t.positionSizeDai * t.leverage;
        require(
            storageT.openInterestDai(t.pairIndex, t.buy ? 0 : 1) + levPosDai <=
                borrowingFees.getPairMaxOi(t.pairIndex) * 1e8,
            "ABOVE_PAIR_MAX_OI"
        );
        require(borrowingFees.withinMaxGroupOi(t.pairIndex, t.buy, levPosDai), "ABOVE_GROUP_MAX_OI");
        require(levPosDai >= pairsStored.pairMinLevPosDai(t.pairIndex), "BELOW_MIN_POS");

        require(
            t.leverage > 0 &&
                t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) &&
                t.leverage <= _pairMaxLeverage(pairsStored, t.pairIndex),
            "LEVERAGE_INCORRECT"
        );

        require(t.tp == 0 || (t.buy ? t.tp > t.openPrice : t.tp < t.openPrice), "WRONG_TP");
        require(t.sl == 0 || (t.buy ? t.sl < t.openPrice : t.sl > t.openPrice), "WRONG_SL");

        (uint256 priceImpactP, ) = borrowingFees.getTradePriceImpact(0, t.pairIndex, t.buy, levPosDai);
        require(priceImpactP * t.leverage <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");

        storageT.transferDai(sender, address(storageT), t.positionSizeDai);

        if (orderType != IGNSOracleRewards.OpenLimitOrderType.LEGACY) {
            uint256 index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

            storageT.storeOpenLimitOrder(
                IGNSTradingStorage.OpenLimitOrder(
                    sender,
                    t.pairIndex,
                    index,
                    t.positionSizeDai,
                    0,
                    t.buy,
                    t.leverage,
                    t.tp,
                    t.sl,
                    t.openPrice,
                    t.openPrice,
                    block.number,
                    0
                )
            );

            oracleRewards.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);

            address c = storageT.callbacks();
            c.setTradeLastUpdated(
                sender,
                t.pairIndex,
                index,
                IGNSTradingCallbacks.TradeType.LIMIT,
                ChainUtils.getBlockNumber()
            );
            c.setLimitMaxSlippageP(sender, t.pairIndex, index, slippageP);

            emit OpenLimitPlaced(sender, t.pairIndex, index);
        } else {
            uint256 orderId = aggregator.getPrice(
                t.pairIndex,
                IGNSPriceAggregator.OrderType.MARKET_OPEN,
                levPosDai,
                ChainUtils.getBlockNumber()
            );

            storageT.storePendingMarketOrder(
                IGNSTradingStorage.PendingMarketOrder(
                    IGNSTradingStorage.Trade(
                        sender,
                        t.pairIndex,
                        0,
                        0,
                        t.positionSizeDai,
                        0,
                        t.buy,
                        t.leverage,
                        t.tp,
                        t.sl
                    ),
                    0,
                    t.openPrice,
                    slippageP,
                    0,
                    0
                ),
                orderId,
                true
            );

            emit MarketOrderInitiated(orderId, sender, t.pairIndex, true);
        }

        referrals.registerPotentialReferrer(sender, referrer);
    }

    // Close trade (MARKET)
    function closeTradeMarket(uint256 pairIndex, uint256 index) external notContract notDone {
        address sender = _msgSender();

        IGNSTradingStorage.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        IGNSTradingStorage.TradeInfo memory i = storageT.openTradesInfo(sender, pairIndex, index);

        require(storageT.pendingOrderIdsCount(sender) < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");
        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint256 orderId = storageT.priceAggregator().getPrice(
            pairIndex,
            IGNSPriceAggregator.OrderType.MARKET_CLOSE,
            (t.initialPosToken * i.tokenPriceDai * t.leverage) / PRECISION,
            ChainUtils.getBlockNumber()
        );

        storageT.storePendingMarketOrder(
            IGNSTradingStorage.PendingMarketOrder(
                IGNSTradingStorage.Trade(sender, pairIndex, index, 0, 0, 0, false, 0, 0, 0),
                0,
                0,
                0,
                0,
                0
            ),
            orderId,
            false
        );

        emit MarketOrderInitiated(orderId, sender, pairIndex, false);
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint256 pairIndex,
        uint256 index,
        uint256 price, // PRECISION
        uint256 tp,
        uint256 sl,
        uint256 maxSlippageP
    ) external notContract notDone {
        require(price > 0, "PRICE_ZERO");

        address sender = _msgSender();
        require(storageT.hasOpenLimitOrder(sender, pairIndex, index), "NO_LIMIT");

        IGNSTradingStorage.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        require(tp == 0 || (o.buy ? tp > price : tp < price), "WRONG_TP");
        require(sl == 0 || (o.buy ? sl < price : sl > price), "WRONG_SL");

        require(price * maxSlippageP < type(uint256).max, "OVERFLOW");

        _checkNoPendingTrigger(sender, pairIndex, index, IGNSTradingStorage.LimitOrder.OPEN);

        o.minPrice = price;
        o.maxPrice = price;
        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);

        address c = storageT.callbacks();
        c.setTradeLastUpdated(
            sender,
            pairIndex,
            index,
            IGNSTradingCallbacks.TradeType.LIMIT,
            ChainUtils.getBlockNumber()
        );
        c.setLimitMaxSlippageP(sender, pairIndex, index, maxSlippageP);

        emit OpenLimitUpdated(sender, pairIndex, index, price, tp, sl, maxSlippageP);
    }

    function cancelOpenLimitOrder(uint256 pairIndex, uint256 index) external notContract notDone {
        address sender = _msgSender();
        require(storageT.hasOpenLimitOrder(sender, pairIndex, index), "NO_LIMIT");

        IGNSTradingStorage.OpenLimitOrder memory o = storageT.getOpenLimitOrder(sender, pairIndex, index);

        _checkNoPendingTrigger(sender, pairIndex, index, IGNSTradingStorage.LimitOrder.OPEN);

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferDai(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(sender, pairIndex, index);
    }

    // Manage limit order (TP/SL)
    function updateTp(uint256 pairIndex, uint256 index, uint256 newTp) external notContract notDone {
        address sender = _msgSender();

        _checkNoPendingTrigger(sender, pairIndex, index, IGNSTradingStorage.LimitOrder.TP);

        IGNSTradingStorage.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        require(t.leverage > 0, "NO_TRADE");

        storageT.updateTp(sender, pairIndex, index, newTp);
        storageT.callbacks().setTpLastUpdated(
            sender,
            pairIndex,
            index,
            IGNSTradingCallbacks.TradeType.MARKET,
            ChainUtils.getBlockNumber()
        );

        emit TpUpdated(sender, pairIndex, index, newTp);
    }

    function updateSl(uint256 pairIndex, uint256 index, uint256 newSl) external notContract notDone {
        address sender = _msgSender();

        _checkNoPendingTrigger(sender, pairIndex, index, IGNSTradingStorage.LimitOrder.SL);

        IGNSTradingStorage.Trade memory t = storageT.openTrades(sender, pairIndex, index);
        require(t.leverage > 0, "NO_TRADE");

        uint256 maxSlDist = (t.openPrice * MAX_SL_P) / 100 / t.leverage;

        require(
            newSl == 0 || (t.buy ? newSl >= t.openPrice - maxSlDist : newSl <= t.openPrice + maxSlDist),
            "SL_TOO_BIG"
        );

        storageT.updateSl(sender, pairIndex, index, newSl);
        storageT.callbacks().setSlLastUpdated(
            sender,
            pairIndex,
            index,
            IGNSTradingCallbacks.TradeType.MARKET,
            ChainUtils.getBlockNumber()
        );

        emit SlUpdated(sender, pairIndex, index, newSl);
    }

    // Execute limit order
    function executeNftOrder(uint256 packed) external notContract notDone {
        (uint256 _orderType, address trader, uint256 pairIndex, uint256 index, , ) = packed.unpackExecuteNftOrder();

        IGNSTradingStorage.LimitOrder orderType = IGNSTradingStorage.LimitOrder(_orderType);
        bool isOpenLimit = orderType == IGNSTradingStorage.LimitOrder.OPEN;

        IGNSTradingStorage.Trade memory t;

        if (isOpenLimit) {
            require(storageT.hasOpenLimitOrder(trader, pairIndex, index), "NO_LIMIT");
        } else {
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");

            if (orderType == IGNSTradingStorage.LimitOrder.LIQ) {
                if (t.sl > 0) {
                    uint256 liqPrice = borrowingFees.getTradeLiquidationPrice(
                        IGNSBorrowingFees.LiqPriceInput(
                            t.trader,
                            t.pairIndex,
                            t.index,
                            t.openPrice,
                            t.buy,
                            (t.initialPosToken *
                                storageT.openTradesInfo(t.trader, t.pairIndex, t.index).tokenPriceDai) / PRECISION,
                            t.leverage
                        )
                    );

                    // If liq price not closer than SL, turn order into a SL order
                    if ((t.buy && liqPrice <= t.sl) || (!t.buy && liqPrice >= t.sl)) {
                        orderType = IGNSTradingStorage.LimitOrder.SL;
                    }
                }
            } else {
                require(orderType != IGNSTradingStorage.LimitOrder.SL || t.sl > 0, "NO_SL");
                require(orderType != IGNSTradingStorage.LimitOrder.TP || t.tp > 0, "NO_TP");
            }
        }

        IGNSOracleRewards.TriggeredLimitId memory triggeredLimitId = _checkNoPendingTrigger(
            trader,
            pairIndex,
            index,
            orderType
        );

        address sender = _msgSender();
        bool byPassesLinkCost = bypassTriggerLink[sender];

        uint256 leveragedPosDai;

        if (isOpenLimit) {
            IGNSTradingStorage.OpenLimitOrder memory l = storageT.getOpenLimitOrder(trader, pairIndex, index);

            uint256 _leveragedPosDai = l.positionSize * l.leverage;
            (uint256 priceImpactP, ) = borrowingFees.getTradePriceImpact(0, l.pairIndex, l.buy, _leveragedPosDai);

            require(priceImpactP * l.leverage <= pairInfos.maxNegativePnlOnOpenP(), "PRICE_IMPACT_TOO_HIGH");

            if (!byPassesLinkCost) {
                leveragedPosDai = _leveragedPosDai;
            }
        } else if (!byPassesLinkCost) {
            leveragedPosDai =
                (t.initialPosToken * storageT.openTradesInfo(trader, pairIndex, index).tokenPriceDai * t.leverage) /
                PRECISION;
        }

        if (leveragedPosDai > 0) {
            storageT.transferLinkToAggregator(sender, pairIndex, leveragedPosDai);
        }

        uint256 orderId = _getPriceNftOrder(
            isOpenLimit,
            trader,
            pairIndex,
            index,
            isOpenLimit ? IGNSTradingCallbacks.TradeType.LIMIT : IGNSTradingCallbacks.TradeType.MARKET,
            orderType,
            leveragedPosDai
        );

        IGNSTradingStorage.PendingNftOrder memory pendingNftOrder;
        pendingNftOrder.nftHolder = sender;
        pendingNftOrder.nftId = 0;
        pendingNftOrder.trader = trader;
        pendingNftOrder.pairIndex = pairIndex;
        pendingNftOrder.index = index;
        pendingNftOrder.orderType = orderType;

        storageT.storePendingNftOrder(pendingNftOrder, orderId);
        oracleRewards.storeTrigger(triggeredLimitId);

        emit NftOrderInitiated(orderId, trader, pairIndex, byPassesLinkCost);
    }

    // Market timeout
    function openTradeMarketTimeout(uint256 _order) external notContract notDone {
        address sender = _msgSender();

        IGNSTradingStorage.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        IGNSTradingStorage.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");
        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferDai(address(storageT), sender, t.positionSizeDai);

        emit ChainlinkCallbackTimeout(_order, o);
    }

    function closeTradeMarketTimeout(uint256 _order) external notContract notDone {
        address sender = _msgSender();

        IGNSTradingStorage.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(_order);
        IGNSTradingStorage.Trade memory t = o.trade;

        require(o.block > 0 && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");
        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        (bool success, ) = address(this).delegatecall(
            abi.encodeWithSignature("closeTradeMarket(uint256,uint256)", t.pairIndex, t.index)
        );

        if (!success) {
            emit CouldNotCloseTrade(sender, t.pairIndex, t.index);
        }

        emit ChainlinkCallbackTimeout(_order, o);
    }

    // Helpers (private)
    function _checkNoPendingTrigger(
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingStorage.LimitOrder orderType
    ) private view returns (IGNSOracleRewards.TriggeredLimitId memory triggeredLimitId) {
        triggeredLimitId = IGNSOracleRewards.TriggeredLimitId(trader, pairIndex, index, orderType);
        require(
            !oracleRewards.triggered(triggeredLimitId) || oracleRewards.timedOut(triggeredLimitId),
            "PENDING_TRIGGER"
        );
    }

    function _pairMaxLeverage(IGNSPairsStorage pairsStored, uint256 pairIndex) private view returns (uint256) {
        uint256 max = IGNSTradingCallbacks(storageT.callbacks()).pairMaxLeverage(pairIndex);
        return max > 0 ? max : pairsStored.pairMaxLeverage(pairIndex);
    }

    function _getPriceNftOrder(
        bool isOpenLimit,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType tradeType,
        IGNSTradingStorage.LimitOrder orderType,
        uint256 leveragedPosDai
    ) private returns (uint256 orderId) {
        IGNSTradingCallbacks.LastUpdated memory lastUpdated = IGNSTradingCallbacks(storageT.callbacks())
            .getTradeLastUpdated(trader, pairIndex, index, tradeType);

        IGNSPriceAggregator aggregator = storageT.priceAggregator();

        orderId = aggregator.getPrice(
            pairIndex,
            isOpenLimit ? IGNSPriceAggregator.OrderType.LIMIT_OPEN : IGNSPriceAggregator.OrderType.LIMIT_CLOSE,
            leveragedPosDai,
            isOpenLimit ? lastUpdated.limit : orderType == IGNSTradingStorage.LimitOrder.SL
                ? lastUpdated.sl
                : orderType == IGNSTradingStorage.LimitOrder.TP
                ? lastUpdated.tp
                : lastUpdated.created
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.3.2
 */
interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 5
 */
interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/PriceImpactUtils.sol";

/**
 * @custom:version 6.4.2
 */
interface IGNSBorrowingFees {
    // Structs
    struct PairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; // 1e10 (%)
        uint64 initialAccFeeShort; // 1e10 (%)
        uint64 prevGroupAccFeeLong; // 1e10 (%)
        uint64 prevGroupAccFeeShort; // 1e10 (%)
        uint64 pairAccFeeLong; // 1e10 (%)
        uint64 pairAccFeeShort; // 1e10 (%)
        uint64 _placeholder; // might be useful later
    }
    struct Pair {
        PairGroup[] groups;
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint48 feeExponent;
        uint256 lastAccBlockWeightedMarketCap; // 1e40
    }
    struct PairOi {
        uint72 long; // 1e10 (DAI)
        uint72 short; // 1e10 (DAI)
        uint72 max; // 1e10 (DAI)
        uint40 _placeholder; // might be useful later
    }
    struct Group {
        uint112 oiLong; // 1e10
        uint112 oiShort; // 1e10
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint80 maxOi; // 1e10
        uint256 lastAccBlockWeightedMarketCap; // 1e40
    }
    struct InitialAccFees {
        uint64 accPairFee; // 1e10 (%)
        uint64 accGroupFee; // 1e10 (%)
        uint48 block;
        uint80 _placeholder; // might be useful later
    }
    struct PairParams {
        uint16 groupIndex;
        uint32 feePerBlock; // 1e10 (%)
        uint48 feeExponent;
        uint72 maxOi;
    }
    struct GroupParams {
        uint32 feePerBlock; // 1e10 (%)
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }
    struct BorrowingFeeInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        bool long;
        uint256 collateral; // 1e18 (DAI)
        uint256 leverage;
    }
    struct LiqPriceInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice; // 1e10
        bool long;
        uint256 collateral; // 1e18 (DAI)
        uint256 leverage;
    }
    struct PendingAccFeesInput {
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint256 oiLong; // 1e18
        uint256 oiShort; // 1e18
        uint32 feePerBlock; // 1e10
        uint256 currentBlock;
        uint256 accLastUpdatedBlock;
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }

    // Events
    event PairParamsUpdated(
        uint256 indexed pairIndex,
        uint16 indexed groupIndex,
        uint32 feePerBlock,
        uint48 feeExponent,
        uint72 maxOi
    );
    event PairGroupUpdated(uint256 indexed pairIndex, uint16 indexed prevGroupIndex, uint16 indexed newGroupIndex);
    event GroupUpdated(uint16 indexed groupIndex, uint32 feePerBlock, uint72 maxOi, uint48 feeExponent);
    event TradeInitialAccFeesStored(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );
    event TradeActionHandled(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        bool open,
        bool long,
        uint256 positionSizeDai // 1e18
    );
    event PairAccFeesUpdated(uint256 indexed pairIndex, uint256 currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupAccFeesUpdated(uint16 indexed groupIndex, uint256 currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupOiUpdated(
        uint16 indexed groupIndex,
        bool indexed long,
        bool indexed increase,
        uint112 amount,
        uint112 oiLong,
        uint112 oiShort
    );

    // v6.4.2 - PriceImpactUtils events, have to be duplicated (solved after 0.8.20 but can't update bc of PUSH0 opcode)
    event OiWindowsSettingsInitialized(uint48 indexed windowsDuration);

    event PriceImpactWindowsCountUpdated(uint48 indexed windowsCount);
    event PriceImpactWindowsDurationUpdated(uint48 indexed windowsDuration);

    event PriceImpactOpenInterestAdded(PriceImpactUtils.OiWindowUpdate oiWindowUpdate);
    event PriceImpactOpenInterestRemoved(PriceImpactUtils.OiWindowUpdate oiWindowUpdate, bool notOutdated);

    event PriceImpactOiTransferredPairs(
        uint256 pairsCount,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        uint256 newCurrentWindowId
    );
    event PriceImpactOiTransferredPair(uint256 indexed pairIndex, PriceImpactUtils.PairOi totalPairOi);

    // Functions
    function getTradeLiquidationPrice(LiqPriceInput calldata) external view returns (uint256); // PRECISION

    function getTradeBorrowingFee(BorrowingFeeInput memory) external view returns (uint256); // 1e18 (DAI)

    function handleTradeAction(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 positionSizeDai, // 1e18 (collateral * leverage)
        bool open,
        bool long
    ) external;

    function withinMaxGroupOi(uint256 pairIndex, bool long, uint256 positionSizeDai) external view returns (bool);

    function getPairMaxOi(uint256 pairIndex) external view returns (uint256);

    // v6.4.2 - Functions
    function addPriceImpactOpenInterest(uint256 _openInterest, uint256 _pairIndex, bool _long) external;

    function removePriceImpactOpenInterest(
        uint256 _openInterest,
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external;

    function getTradePriceImpact(
        uint256 _openPrice, // PRECISION
        uint256 _pairIndex,
        bool _long,
        uint256 _tradeOpenInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSTradingStorage.sol";

/**
 * @custom:version 6.4.1
 */
interface IGNSOracleRewards {
    struct TriggeredLimitId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        IGNSTradingStorage.LimitOrder order;
    }

    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeTrigger(TriggeredLimitId calldata) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeOracleReward(TriggeredLimitId calldata, uint256) external;

    function openLimitOrderTypes(address, uint256, uint256) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(address, uint256, uint256, OpenLimitOrderType) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);

    event OldLimitTypesCopied(address oldContract, uint256 start, uint256 end);
    event StateCopyDone();
    event TriggerTimeoutUpdated(uint256 value);
    event OraclesUpdated(uint256 oraclesCount);

    event TriggeredFirst(TriggeredLimitId id);
    event TriggerUnregistered(TriggeredLimitId id);
    event TriggerRewarded(TriggeredLimitId id, uint256 rewardGns, uint256 rewardGnsPerOracle, uint256 oraclesCount);
    event RewardsClaimed(address oracle, uint256 amountGns);
    event OpenLimitOrderTypeSet(address trader, uint256 pairIndex, uint256 index, OpenLimitOrderType value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6
 */
interface IGNSPairInfos {
    struct PairParams {
        uint256 onePercentDepthAbove; // DAI
        uint256 onePercentDepthBelow; // DAI
        uint256 rolloverFeePerBlockP; // PRECISION (%)
        uint256 fundingFeePerBlockP; // PRECISION (%)
    }

    struct TradeInitialAccFees {
        uint256 rollover; // 1e18 (DAI)
        int256 funding; // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    function pairParams(uint256) external view returns (PairParams memory);

    function tradeInitialAccFees(address, uint256, uint256) external view returns (TradeInitialAccFees memory);

    function maxNegativePnlOnOpenP() external view returns (uint256); // PRECISION (%)

    function storeTradeInitialAccFees(address trader, uint256 pairIndex, uint256 index, bool long) external;

    /**
     * @custom:deprecated
     * getTradePriceImpact has been moved to Borrowing Fees contract
     */
    function getTradePriceImpact(
        uint256 openPrice, // PRECISION
        uint256 pairIndex,
        bool long,
        uint256 openInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        );

    function getTradeRolloverFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 collateral // 1e18 (DAI)
    ) external view returns (uint256);

    function getTradeFundingFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    )
        external
        view
        returns (
            int256 // 1e18 (DAI) | Positive => Fee, Negative => Reward
        );

    function getTradeLiquidationPricePure(
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        uint256 rolloverFee, // 1e18 (DAI)
        int256 fundingFee // 1e18 (DAI)
    ) external pure returns (uint256);

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    ) external view returns (uint256); // PRECISION

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        int256 percentProfit, // PRECISION (%)
        uint256 closingFee // 1e18 (DAI)
    ) external returns (uint256); // 1e18 (DAI)

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6
 */
interface IGNSPairsStorage {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } // PRECISION (%)

    struct Pair {
        string from;
        string to;
        Feed feed;
        uint256 spreadP; // PRECISION
        uint256 groupIndex;
        uint256 feeIndex;
    }
    struct Group {
        string name;
        bytes32 job;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 maxCollateralP; // % (of DAI vault current balance)
    }
    struct Fee {
        string name;
        uint256 openFeeP; // PRECISION (% of leveraged pos)
        uint256 closeFeeP; // PRECISION (% of leveraged pos)
        uint256 oracleFeeP; // PRECISION (% of leveraged pos)
        uint256 nftLimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint256 referralFeeP; // PRECISION (% of leveraged pos)
        uint256 minLevPosDai; // 1e18 (collateral x leverage, useful for min fee)
    }

    function updateGroupCollateral(uint256, uint256, bool, bool) external;

    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);

    function pairFeed(uint256) external view returns (Feed memory);

    function pairSpreadP(uint256) external view returns (uint256);

    function pairMinLeverage(uint256) external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    function groupMaxCollateral(uint256) external view returns (uint256);

    function groupCollateral(uint256, bool) external view returns (uint256);

    function guaranteedSlEnabled(uint256) external view returns (bool);

    function pairOpenFeeP(uint256) external view returns (uint256);

    function pairCloseFeeP(uint256) external view returns (uint256);

    function pairOracleFeeP(uint256) external view returns (uint256);

    function pairNftLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosDai(uint256) external view returns (uint256);

    function pairsCount() external view returns (uint256);

    event PairAdded(uint256 index, string from, string to);
    event PairUpdated(uint256 index);

    event GroupAdded(uint256 index, string name);
    event GroupUpdated(uint256 index);

    event FeeAdded(uint256 index, string name);
    event FeeUpdated(uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IChainlinkFeed.sol";
import "./IGNSTradingCallbacks.sol";
import "./IGNSPairsStorage.sol";

/**
 * @custom:version 6.4
 */
interface IGNSPriceAggregator {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    struct Order {
        uint16 pairIndex;
        uint112 linkFeePerNode;
        OrderType orderType;
        bool active;
        bool isLookback;
    }

    struct LookbackOrderAnswer {
        uint64 open;
        uint64 high;
        uint64 low;
        uint64 ts;
    }

    function pairsStorage() external view returns (IGNSPairsStorage);

    function getPrice(uint256, OrderType, uint256, uint256) external returns (uint256);

    function tokenPriceDai() external returns (uint256);

    function linkFee(uint256, uint256) external view returns (uint256);

    function openFeeP(uint256) external view returns (uint256);

    function linkPriceFeed() external view returns (IChainlinkFeed);

    function nodes(uint256 index) external view returns (address);

    event PairsStorageUpdated(address value);
    event LinkPriceFeedUpdated(address value);
    event MinAnswersUpdated(uint256 value);

    event NodeAdded(uint256 index, address value);
    event NodeReplaced(uint256 index, address oldNode, address newNode);
    event NodeRemoved(uint256 index, address oldNode);

    event JobIdUpdated(uint256 index, bytes32 jobId);

    event PriceRequested(
        uint256 indexed orderId,
        bytes32 indexed job,
        uint256 indexed pairIndex,
        OrderType orderType,
        uint256 nodesCount,
        uint256 linkFeePerNode,
        uint256 fromBlock,
        bool isLookback
    );

    event PriceReceived(
        bytes32 request,
        uint256 indexed orderId,
        address indexed node,
        uint16 indexed pairIndex,
        uint256 price,
        uint256 referencePrice,
        uint112 linkFee,
        bool isLookback,
        bool usedInMedian
    );

    event CallbackExecuted(IGNSTradingCallbacks.AggregatorAnswer a, OrderType orderType);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.2
 */
interface IGNSReferrals {
    struct AllyDetails {
        address[] referrersReferred;
        uint256 volumeReferredDai; // 1e18
        uint256 pendingRewardsToken; // 1e18
        uint256 totalRewardsToken; // 1e18
        uint256 totalRewardsValueDai; // 1e18
        bool active;
    }

    struct ReferrerDetails {
        address ally;
        address[] tradersReferred;
        uint256 volumeReferredDai; // 1e18
        uint256 pendingRewardsToken; // 1e18
        uint256 totalRewardsToken; // 1e18
        uint256 totalRewardsValueDai; // 1e18
        bool active;
    }

    function registerPotentialReferrer(address trader, address referral) external;

    function distributePotentialReward(
        address trader,
        uint256 volumeDai,
        uint256 pairOpenFeeP,
        uint256 tokenPriceDai
    ) external returns (uint256);

    function getPercentOfOpenFeeP(address trader) external view returns (uint256);

    function getTraderReferrer(address trader) external view returns (address referrer);

    event UpdatedAllyFeeP(uint256 value);
    event UpdatedStartReferrerFeeP(uint256 value);
    event UpdatedOpenFeeP(uint256 value);
    event UpdatedTargetVolumeDai(uint256 value);

    event AllyWhitelisted(address indexed ally);
    event AllyUnwhitelisted(address indexed ally);

    event ReferrerWhitelisted(address indexed referrer, address indexed ally);
    event ReferrerUnwhitelisted(address indexed referrer);
    event ReferrerRegistered(address indexed trader, address indexed referrer);

    event AllyRewardDistributed(
        address indexed ally,
        address indexed trader,
        uint256 volumeDai,
        uint256 amountToken,
        uint256 amountValueDai
    );
    event ReferrerRewardDistributed(
        address indexed referrer,
        address indexed trader,
        uint256 volumeDai,
        uint256 amountToken,
        uint256 amountValueDai
    );

    event AllyRewardsClaimed(address indexed ally, uint256 amountToken);
    event ReferrerRewardsClaimed(address indexed referrer, uint256 amountToken);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSTradingStorage.sol";

/**
 * @custom:version 6.4.2
 */
interface IGNSTrading {
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint256 value);
    event BypassTriggerLinkUpdated(address user, bool bypass);

    event MarketOrderInitiated(uint256 indexed orderId, address indexed trader, uint256 indexed pairIndex, bool open);

    event OpenLimitPlaced(address indexed trader, uint256 indexed pairIndex, uint256 index);
    event OpenLimitUpdated(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint256 newPrice,
        uint256 newTp,
        uint256 newSl,
        uint256 maxSlippageP
    );
    event OpenLimitCanceled(address indexed trader, uint256 indexed pairIndex, uint256 index);

    event TpUpdated(address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newTp);
    event SlUpdated(address indexed trader, uint256 indexed pairIndex, uint256 index, uint256 newSl);

    event NftOrderInitiated(uint256 orderId, address indexed trader, uint256 indexed pairIndex, bool byPassesLinkCost);

    event ChainlinkCallbackTimeout(uint256 indexed orderId, IGNSTradingStorage.PendingMarketOrder order);
    event CouldNotCloseTrade(address indexed trader, uint256 indexed pairIndex, uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSTradingStorage.sol";

/**
 * @custom:version 6.4.2
 */
interface IGNSTradingCallbacks {
    struct AggregatorAnswer {
        uint256 orderId;
        uint256 price;
        uint256 spreadP;
        uint256 open;
        uint256 high;
        uint256 low;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint256 posDai;
        uint256 levPosDai;
        uint256 tokenPriceDai;
        int256 profitP;
        uint256 price;
        uint256 liqPrice;
        uint256 daiSentToTrader;
        uint256 reward1;
        uint256 reward2;
        uint256 reward3;
        bool exactExecution;
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
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
        uint48 lastOiUpdateTs;
        uint168 _placeholder; // for potential future data
    }

    struct OpenTradePrepInput {
        uint256 executionPrice;
        uint256 wantedPrice;
        uint256 marketPrice;
        uint256 spreadP;
        bool buy;
        uint256 pairIndex;
        uint256 positionSize;
        uint256 leverage;
        uint256 maxSlippageP;
        uint256 tp;
        uint256 sl;
    }

    enum TradeType {
        MARKET,
        LIMIT
    }

    enum CancelReason {
        NONE,
        PAUSED,
        MARKET_CLOSED,
        SLIPPAGE,
        TP_REACHED,
        SL_REACHED,
        EXPOSURE_LIMITS,
        PRICE_IMPACT,
        MAX_LEVERAGE,
        NO_TRADE,
        WRONG_TRADE,
        NOT_HIT
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeNftOpenOrderCallback(AggregatorAnswer memory) external;

    function executeNftCloseOrderCallback(AggregatorAnswer memory) external;

    function getTradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function setTradeData(SimplifiedTradeId calldata, TradeData memory) external;

    function canExecuteTimeout() external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    event MarketExecuted(
        uint256 indexed orderId,
        IGNSTradingStorage.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit, // before fees
        uint256 daiSentToTrader
    );

    event LimitExecuted(
        uint256 indexed orderId,
        uint256 limitIndex,
        IGNSTradingStorage.Trade t,
        address indexed nftHolder,
        IGNSTradingStorage.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit,
        uint256 daiSentToTrader,
        bool exactExecution
    );

    event MarketOpenCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        CancelReason cancelReason
    );
    event MarketCloseCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        CancelReason cancelReason
    );
    event NftOrderCanceled(
        uint256 indexed orderId,
        address indexed nftHolder,
        IGNSTradingStorage.LimitOrder orderType,
        CancelReason cancelReason
    );

    event ClosingFeeSharesPUpdated(uint256 daiVaultFeeP, uint256 lpFeeP, uint256 sssFeeP);

    event Pause(bool paused);
    event Done(bool done);
    event GovFeesClaimed(uint256 valueDai);

    event GovFeeCharged(address indexed trader, uint256 valueDai, bool distributed);
    event ReferralFeeCharged(address indexed trader, uint256 valueDai);
    event TriggerFeeCharged(address indexed trader, uint256 valueDai);
    event SssFeeCharged(address indexed trader, uint256 valueDai);
    event DaiVaultFeeCharged(address indexed trader, uint256 valueDai);
    event BorrowingFeeCharged(address indexed trader, uint256 tradeValueDai, uint256 feeValueDai);
    event PairMaxLeverageUpdated(uint256 indexed pairIndex, uint256 maxLeverage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSPriceAggregator.sol"; // avoid chained conversions for pairsStorage

/**
 * @custom:version 5
 */
interface IGNSTradingStorage {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 initialPosToken; // 1e18
        uint256 positionSizeDai; // 1e18
        uint256 openPrice; // PRECISION
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION
        uint256 sl; // PRECISION
    }
    struct TradeInfo {
        uint256 tokenId;
        uint256 tokenPriceDai; // PRECISION
        uint256 openInterestDai; // 1e18
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize; // 1e18 (DAI or GFARM2)
        uint256 spreadReductionP;
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION (%)
        uint256 sl; // PRECISION (%)
        uint256 minPrice; // PRECISION
        uint256 maxPrice; // PRECISION
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; // PRECISION
        uint256 slippageP; // PRECISION (%)
        uint256 spreadReductionP;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint256 nftId;
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (address);

    function token() external view returns (address);

    function linkErc677() external view returns (address);

    function priceAggregator() external view returns (IGNSPriceAggregator);

    function vault() external view returns (address);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint256, bool) external;

    function transferDai(address, address, uint256) external;

    function transferLinkToAggregator(address, uint256, uint256) external;

    function unregisterTrade(address, uint256, uint256) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(address, uint256, uint256) external;

    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;

    function openTrades(address, uint256, uint256) external view returns (Trade memory);

    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);

    function updateSl(address, uint256, uint256, uint256) external;

    function updateTp(address, uint256, uint256, uint256) external;

    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);

    function getOpenLimitOrders() external view returns (OpenLimitOrder[] memory);

    function spreadReductionsP(uint256) external view returns (uint256);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);

    function increaseNftRewards(uint256, uint256) external;

    function nftSuccessTimelock() external view returns (uint256);

    function reqID_pendingNftOrder(uint256) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint256) external view returns (uint256);

    function unregisterPendingNftOrder(uint256) external;

    function handleDevGovFees(uint256, uint256, bool, bool) external returns (uint256);

    function distributeLpRewards(uint256) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint256) external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256) external view returns (uint256);

    function pendingMarketCloseCount(address, uint256) external view returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestDai(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address) external view returns (uint256[] memory);

    function nfts(uint256) external view returns (address);

    function fakeBlockNumber() external view returns (uint256); // Testing
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

/**
 * @custom:version 6.3.2
 */
library ChainUtils {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint256 blockNumber) internal pure returns (uint48) {
        require(blockNumber <= type(uint48).max, "OVERFLOW");
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.4
 */
library PackingUtils {
    function pack(uint256[] memory values, uint256[] memory bitLengths) external pure returns (uint256 packed) {
        require(values.length == bitLengths.length, "Mismatch in the lengths of values and bitLengths arrays");

        uint256 currentShift;

        for (uint256 i; i < values.length; i++) {
            require(currentShift + bitLengths[i] <= 256, "Packed value exceeds 256 bits");

            uint256 maxValue = (1 << bitLengths[i]) - 1;
            require(values[i] <= maxValue, "Value too large for specified bit length");

            uint256 maskedValue = values[i] & maxValue;
            packed |= maskedValue << currentShift;
            currentShift += bitLengths[i];
        }
    }

    function unpack(uint256 packed, uint256[] memory bitLengths) external pure returns (uint256[] memory values) {
        values = new uint256[](bitLengths.length);

        uint256 currentShift;
        for (uint256 i; i < bitLengths.length; i++) {
            require(currentShift + bitLengths[i] <= 256, "Unpacked value exceeds 256 bits");

            uint256 maxValue = (1 << bitLengths[i]) - 1;
            uint256 mask = maxValue << currentShift;
            values[i] = (packed & mask) >> currentShift;

            currentShift += bitLengths[i];
        }
    }

    function unpack256To64(uint256 packed) external pure returns (uint64 a, uint64 b, uint64 c, uint64 d) {
        a = uint64(packed);
        b = uint64(packed >> 64);
        c = uint64(packed >> 128);
        d = uint64(packed >> 192);
    }

    // Function-specific unpacking utils
    function unpackExecuteNftOrder(
        uint256 packed
    ) external pure returns (uint256 a, address b, uint256 c, uint256 d, uint256 e, uint256 f) {
        a = packed & 0xFF; // 8 bits
        b = address(uint160(packed >> 8)); // 160 bits
        c = (packed >> 168) & 0xFFFF; // 16 bits
        d = (packed >> 184) & 0xFFFF; // 16 bits
        e = (packed >> 200) & 0xFFFF; // 16 bits
        f = (packed >> 216) & 0xFFFF; // 16 bits
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IGNSTradingStorage.sol";

import "./StorageUtils.sol";

/**
 * @custom:version 6.4.2
 *
 * @dev This is a library to help manage a price impact decay algorithm .
 *
 * When a trade is placed, OI is added to the window corresponding to time of open.
 * When a trade is removed, OI is removed from the window corresponding to time of open.
 *
 * When calculating price impact, only the most recent X windows are taken into account.
 */
library PriceImpactUtils {
    uint256 private constant PRECISION = 1e10; // 10 decimals

    uint48 private constant MAX_WINDOWS_COUNT = 5;
    uint48 private constant MAX_WINDOWS_DURATION = 1 days;
    uint48 private constant MIN_WINDOWS_DURATION = 10 minutes;

    struct OiWindowsStorage {
        OiWindowsSettings settings;
        mapping(uint48 => mapping(uint256 => mapping(uint256 => PairOi))) windows; // duration => pairIndex => windowId => Oi
    }

    struct OiWindowsSettings {
        uint48 startTs;
        uint48 windowsDuration;
        uint48 windowsCount;
    }

    struct PairOi {
        uint128 long; // 1e18 (DAI)
        uint128 short; // 1e18 (DAI)
    }

    struct OiWindowUpdate {
        uint48 windowsDuration;
        uint256 pairIndex;
        uint256 windowId;
        bool long;
        uint128 openInterest; // 1e18 (DAI)
    }

    /**
     * @dev Triggered when OiWindowsSettings is initialized (once)
     */
    event OiWindowsSettingsInitialized(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OiWindowsSettings.windowsCount is updated
     */
    event PriceImpactWindowsCountUpdated(uint48 indexed windowsCount);

    /**
     * @dev Triggered when OiWindowsSettings.windowsDuration is updated
     */
    event PriceImpactWindowsDurationUpdated(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OI is added to a window.
     */
    event PriceImpactOpenInterestAdded(OiWindowUpdate oiWindowUpdate);

    /**
     * @dev Triggered when OI is (tentatively) removed from a window.
     */
    event PriceImpactOpenInterestRemoved(OiWindowUpdate oiWindowUpdate, bool notOutdated);

    /**
     * @dev Triggered when multiple pairs' OI are transferred to a new window.
     */
    event PriceImpactOiTransferredPairs(
        uint256 pairsCount,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        uint256 newCurrentWindowId
    );

    /**
     * @dev Triggered when a pair's OI is transferred to a new window.
     */
    event PriceImpactOiTransferredPair(uint256 indexed pairIndex, PairOi totalPairOi);

    /**
     * @dev Returns storage pointer for struct in borrowing contract, at defined slot
     */
    function getStorage() private pure returns (OiWindowsStorage storage s) {
        uint256 storageSlot = StorageUtils.PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT;
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Validates new windowsDuration value
     */
    modifier validWindowsDuration(uint48 _windowsDuration) {
        require(
            _windowsDuration >= MIN_WINDOWS_DURATION && _windowsDuration <= MAX_WINDOWS_DURATION,
            "WRONG_WINDOWS_DURATION"
        );
        _;
    }

    /**
     * @dev Initializes OiWindowsSettings startTs and windowsDuration.
     * windowsCount is 0 for now for backwards-compatible behavior until oi windows have enough data.
     *
     * Should only be called once, in initializeV2() of borrowing contract.
     * Emits a {OiWindowsSettingsInitialized} event.
     */
    function initializeOiWindowsSettings(uint48 _windowsDuration) external validWindowsDuration(_windowsDuration) {
        getStorage().settings = OiWindowsSettings({
            startTs: uint48(block.timestamp),
            windowsDuration: _windowsDuration,
            windowsCount: 0 // maintains previous price impact OI behavior for now
        });

        emit OiWindowsSettingsInitialized(_windowsDuration);
    }

    /**
     * @dev Updates OiWindowSettings.windowsCount storage value
     *
     * Emits a {PriceImpactWindowsCountUpdated} event.
     */
    function setPriceImpactWindowsCount(uint48 _newWindowsCount) external {
        OiWindowsSettings storage settings = getStorage().settings;

        require(_newWindowsCount <= MAX_WINDOWS_COUNT, "ABOVE_MAX_WINDOWS_COUNT");
        require(_newWindowsCount == 0 || getCurrentWindowId(settings) >= _newWindowsCount - 1, "TOO_EARLY");

        settings.windowsCount = _newWindowsCount;

        emit PriceImpactWindowsCountUpdated(_newWindowsCount);
    }

    /**
     * @dev Updates OiWindowSettings.windowsDuration storage value,
     * and transfers the OI from all pairs past active windows (current window duration)
     * to the new current window (new window duration).
     *
     * Emits a {PriceImpactWindowsDurationUpdated} event.
     */
    function setPriceImpactWindowsDuration(
        uint48 _newWindowsDuration,
        uint256 _pairsCount
    ) external validWindowsDuration(_newWindowsDuration) {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        if (settings.windowsCount > 0) {
            transferPriceImpactOiForPairs(
                _pairsCount,
                oiStorage.windows[settings.windowsDuration],
                oiStorage.windows[_newWindowsDuration],
                settings,
                _newWindowsDuration
            );
        }

        settings.windowsDuration = _newWindowsDuration;

        emit PriceImpactWindowsDurationUpdated(_newWindowsDuration);
    }

    /**
     * @dev Adds long / short `_openInterest` (1e18) to current window of `_pairIndex`.
     *
     * Emits a {PriceImpactOpenInterestAdded} event.
     */
    function addPriceImpactOpenInterest(uint128 _openInterest, uint256 _pairIndex, bool _long) external {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        uint256 currentWindowId = getCurrentWindowId(settings);
        PairOi storage pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][currentWindowId];

        if (_long) {
            pairOi.long += _openInterest;
        } else {
            pairOi.short += _openInterest;
        }

        emit PriceImpactOpenInterestAdded(
            OiWindowUpdate(settings.windowsDuration, _pairIndex, currentWindowId, _long, _openInterest)
        );
    }

    /**
     * @dev Removes `_openInterest` (1e18) from window at `_addTs` of `_pairIndex`.
     *
     * Emits a {PriceImpactOpenInterestRemoved} event when `_addTs` is greater than zero.
     */
    function removePriceImpactOpenInterest(
        uint128 _openInterest,
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external {
        // If trade opened before update, OI wasn't stored in any window anyway
        if (_addTs == 0) {
            return;
        }

        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        uint256 currentWindowId = getCurrentWindowId(settings);
        uint256 addWindowId = getWindowId(_addTs, settings);

        bool notOutdated = isWindowPotentiallyActive(addWindowId, currentWindowId);

        // Only remove OI if window is not outdated already
        if (notOutdated) {
            PairOi storage pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][addWindowId];

            if (_long) {
                pairOi.long = _openInterest < pairOi.long ? pairOi.long - _openInterest : 0;
            } else {
                pairOi.short = _openInterest < pairOi.short ? pairOi.short - _openInterest : 0;
            }
        }

        emit PriceImpactOpenInterestRemoved(
            OiWindowUpdate(settings.windowsDuration, _pairIndex, addWindowId, _long, _openInterest),
            notOutdated
        );
    }

    /**
     * @dev Transfers total long / short OI from last '_settings.windowsCount' windows of `_prevPairOiWindows`
     * to current window of `_newPairOiWindows` for `pairsCount` pairs.
     *
     * Emits a {PriceImpactOiTransferredPairs} event.
     */
    function transferPriceImpactOiForPairs(
        uint256 pairsCount,
        mapping(uint256 => mapping(uint256 => PairOi)) storage _prevPairOiWindows, // pairIndex => windowId => PairOi
        mapping(uint256 => mapping(uint256 => PairOi)) storage _newPairOiWindows, // pairIndex => windowId => PairOi
        OiWindowsSettings memory _settings,
        uint48 _newWindowsDuration
    ) private {
        uint256 prevCurrentWindowId = getCurrentWindowId(_settings);
        uint256 prevEarliestWindowId = getEarliestActiveWindowId(prevCurrentWindowId, _settings.windowsCount);

        uint256 newCurrentWindowId = getCurrentWindowId(
            OiWindowsSettings(_settings.startTs, _newWindowsDuration, _settings.windowsCount)
        );

        for (uint256 pairIndex; pairIndex < pairsCount; ) {
            transferPriceImpactOiForPair(
                pairIndex,
                prevCurrentWindowId,
                prevEarliestWindowId,
                _prevPairOiWindows[pairIndex],
                _newPairOiWindows[pairIndex][newCurrentWindowId]
            );

            unchecked {
                ++pairIndex;
            }
        }

        emit PriceImpactOiTransferredPairs(pairsCount, prevCurrentWindowId, prevEarliestWindowId, newCurrentWindowId);
    }

    /**
     * @dev Transfers total long / short OI from `prevEarliestWindowId` to `prevCurrentWindowId` windows of
     * `_prevPairOiWindows` to `_newPairOiWindow` window.
     *
     * Emits a {PriceImpactOiTransferredPair} event.
     */
    function transferPriceImpactOiForPair(
        uint256 pairIndex,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        mapping(uint256 => PairOi) storage _prevPairOiWindows,
        PairOi storage _newPairOiWindow
    ) private {
        PairOi memory totalPairOi;

        // Aggregate sum of total long / short OI for past windows
        for (uint256 id = prevEarliestWindowId; id <= prevCurrentWindowId; ) {
            PairOi memory pairOi = _prevPairOiWindows[id];

            totalPairOi.long += pairOi.long;
            totalPairOi.short += pairOi.short;

            // Clean up previous map once added to the sum
            delete _prevPairOiWindows[id];

            unchecked {
                ++id;
            }
        }

        bool longOiTransfer = totalPairOi.long > 0;
        bool shortOiTransfer = totalPairOi.short > 0;

        if (longOiTransfer) {
            _newPairOiWindow.long += totalPairOi.long;
        }

        if (shortOiTransfer) {
            _newPairOiWindow.short += totalPairOi.short;
        }

        // Only emit even if there was an actual OI transfer
        if (longOiTransfer || shortOiTransfer) {
            emit PriceImpactOiTransferredPair(pairIndex, totalPairOi);
        }
    }

    /**
     * @dev Returns window id at `_timestamp` given `_settings`.
     */
    function getWindowId(uint48 _timestamp, OiWindowsSettings memory _settings) internal pure returns (uint256) {
        return (_timestamp - _settings.startTs) / _settings.windowsDuration;
    }

    /**
     * @dev Returns window id at current timestamp given `_settings`.
     */
    function getCurrentWindowId(OiWindowsSettings memory _settings) internal view returns (uint256) {
        return getWindowId(uint48(block.timestamp), _settings);
    }

    /**
     * @dev Returns earliest active window id given `_currentWindowId` and `_windowsCount`.
     */
    function getEarliestActiveWindowId(uint256 _currentWindowId, uint48 _windowsCount) internal pure returns (uint256) {
        uint256 windowNegativeDelta = _windowsCount - 1; // -1 because we include current window
        return _currentWindowId > windowNegativeDelta ? _currentWindowId - windowNegativeDelta : 0;
    }

    /**
     * @dev Returns whether '_windowId' can be potentially active id given `_currentWindowId`
     */
    function isWindowPotentiallyActive(uint256 _windowId, uint256 _currentWindowId) internal pure returns (bool) {
        return _currentWindowId - _windowId < MAX_WINDOWS_COUNT;
    }

    /**
     * @dev Returns total long / short OI `activeOi`, from last active windows of `_pairOiWindows`
     * given `_settings` (backwards-compatible).
     */
    function getPriceImpactOi(
        uint256 _pairIndex,
        bool _long,
        IGNSTradingStorage _previousOiContract
    ) external view returns (uint256 activeOi) {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        // Return raw OI if windowsCount is explicitly 0 (= previous behavior)
        if (settings.windowsCount == 0) {
            return _previousOiContract.openInterestDai(_pairIndex, _long ? 0 : 1);
        }

        uint256 currentWindowId = getCurrentWindowId(settings);
        uint256 earliestWindowId = getEarliestActiveWindowId(currentWindowId, settings.windowsCount);

        for (uint256 i = earliestWindowId; i <= currentWindowId; ) {
            PairOi memory _pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][i];
            activeOi += _long ? _pairOi.long : _pairOi.short;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns trade price impact % and opening price after impact.
     */
    function getTradePriceImpact(
        uint256 _openPrice, // PRECISION
        bool _long,
        uint256 _startOpenInterest, // 1e18 (DAI)
        uint256 _tradeOpenInterest, // 1e18 (DAI)
        uint256 _onePercentDepth
    )
        external
        pure
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        )
    {
        if (_onePercentDepth == 0) {
            return (0, _openPrice);
        }

        priceImpactP = ((_startOpenInterest + _tradeOpenInterest / 2) * PRECISION) / _onePercentDepth / 1e18;

        uint256 priceImpact = (priceImpactP * _openPrice) / PRECISION / 100;
        priceAfterImpact = _long ? _openPrice + priceImpact : _openPrice - priceImpact;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.4.2
 *
 * @dev This is a library to help manage storage slots used by our external libraries.
 *
 * BE EXTREMELY CAREFUL, DO NOT EDIT THIS WITHOUT A GOOD REASON
 *
 */
library StorageUtils {
    uint256 internal constant PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT = 7;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IGNSTradingCallbacks.sol";

/**
 * @custom:version 6.4.2
 */
library TradeUtils {
    function _getTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type
    )
        internal
        view
        returns (
            IGNSTradingCallbacks,
            IGNSTradingCallbacks.LastUpdated memory,
            IGNSTradingCallbacks.SimplifiedTradeId memory
        )
    {
        IGNSTradingCallbacks callbacks = IGNSTradingCallbacks(_callbacks);
        IGNSTradingCallbacks.LastUpdated memory l = callbacks.getTradeLastUpdated(trader, pairIndex, index, _type);

        return (callbacks, l, IGNSTradingCallbacks.SimplifiedTradeId(trader, pairIndex, index, _type));
    }

    function setTradeLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type,
        uint256 blockNumber
    ) external {
        uint32 b = uint32(blockNumber);
        IGNSTradingCallbacks callbacks = IGNSTradingCallbacks(_callbacks);
        callbacks.setTradeLastUpdated(
            IGNSTradingCallbacks.SimplifiedTradeId(trader, pairIndex, index, _type),
            IGNSTradingCallbacks.LastUpdated(b, b, b, b)
        );
    }

    function setSlLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            IGNSTradingCallbacks callbacks,
            IGNSTradingCallbacks.LastUpdated memory l,
            IGNSTradingCallbacks.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.sl = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setTpLastUpdated(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        IGNSTradingCallbacks.TradeType _type,
        uint256 blockNumber
    ) external {
        (
            IGNSTradingCallbacks callbacks,
            IGNSTradingCallbacks.LastUpdated memory l,
            IGNSTradingCallbacks.SimplifiedTradeId memory id
        ) = _getTradeLastUpdated(_callbacks, trader, pairIndex, index, _type);

        l.tp = uint32(blockNumber);
        callbacks.setTradeLastUpdated(id, l);
    }

    function setLimitMaxSlippageP(
        address _callbacks,
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 maxSlippageP
    ) external {
        require(maxSlippageP <= type(uint40).max, "OVERFLOW");
        IGNSTradingCallbacks(_callbacks).setTradeData(
            IGNSTradingCallbacks.SimplifiedTradeId(trader, pairIndex, index, IGNSTradingCallbacks.TradeType.LIMIT),
            IGNSTradingCallbacks.TradeData(uint40(maxSlippageP), 0, 0)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.2
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract Delegatable {
    mapping(address => address) public delegations;
    address private senderOverride;

    function setDelegate(address delegate) external {
        require(tx.origin == msg.sender, "NO_CONTRACT");

        delegations[msg.sender] = delegate;
    }

    function removeDelegate() external {
        delegations[msg.sender] = address(0);
    }

    function delegatedAction(address trader, bytes calldata call_data) external returns (bytes memory) {
        require(delegations[trader] == msg.sender, "DELEGATE_NOT_APPROVED");

        senderOverride = trader;
        (bool success, bytes memory result) = address(this).delegatecall(call_data);
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577 (return the original revert reason)
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }

        senderOverride = address(0);

        return result;
    }

    function _msgSender() public view returns (address) {
        if (senderOverride == address(0)) {
            return msg.sender;
        } else {
            return senderOverride;
        }
    }
}