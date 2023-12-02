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

import "../../interfaces/IGNSTradingStorage.sol";
import "../../interfaces/IGNSPairInfos.sol";
import "../../interfaces/IGNSReferrals.sol";
import "../../interfaces/IGToken.sol";
import "../../interfaces/IGNSStaking.sol";
import "../../interfaces/IGNSBorrowingFees.sol";
import "../../interfaces/IGNSOracleRewards.sol";
import "../../interfaces/IERC20.sol";

import "../../libraries/ChainUtils.sol";

/**
 * @custom:version 7
 */
contract GNSTradingCallbacks_goerli is Initializable {
    // Contracts (constant)
    IGNSTradingStorage public storageT;
    IGNSOracleRewards public nftRewards;
    IGNSPairInfos public pairInfos;
    IGNSReferrals public referrals;
    IGNSStaking public staking;

    // Params (constant)
    uint256 private constant PRECISION = 1e10; // 10 decimals
    uint256 private constant MAX_SL_P = 75; // -75% PNL
    uint256 private constant MAX_GAIN_P = 900; // 900% PnL (10x)
    uint256 private constant MAX_EXECUTE_TIMEOUT = 5; // 5 blocks

    // Params (adjustable)
    uint256 public daiVaultFeeP; // % of closing fee going to DAI vault (eg. 40)
    uint256 public lpFeeP; // % of closing fee going to GNS/DAI LPs (eg. 20)
    uint256 public sssFeeP; // % of closing fee going to GNS staking (eg. 40)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract
    uint256 public canExecuteTimeout; // How long an update to TP/SL/Limit has to wait before it is executable (DEPRECATED)

    // Last Updated State
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(TradeType => LastUpdated))))
        public tradeLastUpdated; // Block numbers for last updated

    // v6.3.2 Storage/State
    IGNSBorrowingFees public borrowingFees;
    mapping(uint256 => uint256) public pairMaxLeverage;

    // v6.4 Storage
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(TradeType => TradeData)))) public tradeData; // More storage for trades / limit orders

    // v6.4.1 State
    uint256 public govFeesDai; // 1e18

    // Custom data types
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
        uint216 _placeholder; // for potential future data
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

    // Events
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

    event ClosingFeeSharesPUpdated(uint daiVaultFeeP, uint lpFeeP, uint sssFeeP);
    event CanExecuteTimeoutUpdated(uint newValue);

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

    // Custom errors (save gas)
    error WrongParams();
    error Forbidden();

    function initialize(
        IGNSTradingStorage _storageT,
        IGNSOracleRewards _nftRewards,
        IGNSPairInfos _pairInfos,
        IGNSReferrals _referrals,
        IGNSStaking _staking,
        IGNSBorrowingFees _borrowingFees,
        address vaultToApprove,
        uint256 _daiVaultFeeP,
        uint256 _lpFeeP,
        uint256 _sssFeeP,
        uint256 _canExecuteTimeout
    ) external reinitializer(4) {
        if (
            address(_storageT) == address(0) ||
            address(_nftRewards) == address(0) ||
            address(_pairInfos) == address(0) ||
            address(_referrals) == address(0) ||
            address(_staking) == address(0) ||
            address(_borrowingFees) == address(0) ||
            vaultToApprove == address(0) ||
            _daiVaultFeeP + _lpFeeP + _sssFeeP != 100 ||
            _canExecuteTimeout > MAX_EXECUTE_TIMEOUT
        ) {
            revert WrongParams();
        }

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        referrals = _referrals;
        staking = _staking;

        daiVaultFeeP = _daiVaultFeeP;
        lpFeeP = _lpFeeP;
        sssFeeP = _sssFeeP;

        canExecuteTimeout = _canExecuteTimeout;

        IERC20 t = IERC20(storageT.dai());
        t.approve(address(staking), type(uint256).max);
        t.approve(vaultToApprove, type(uint256).max);
    }

    function initializeV2(IGNSBorrowingFees _borrowingFees) external reinitializer(2) {
        if (address(_borrowingFees) == address(0)) {
            revert WrongParams();
        }
        borrowingFees = _borrowingFees;
    }

    // skip v3 to be synced with testnet
    function initializeV4(IGNSStaking _staking, IGNSOracleRewards _oracleRewards) external reinitializer(4) {
        if (address(_staking) == address(0) || address(_oracleRewards) == address(0)) {
            revert WrongParams();
        }

        IERC20 t = IERC20(storageT.dai());
        t.approve(address(staking), 0); // revoke old staking contract
        t.approve(address(_staking), type(uint256).max); // approve new staking contract

        staking = _staking;
        nftRewards = _oracleRewards;
    }

    function test__updateStaking(IGNSStaking _staking) external onlyGov {
        staking = _staking;
        IERC20 t = IERC20(storageT.dai());
        t.approve(address(staking), type(uint256).max);
    }

    // Modifiers
    modifier onlyGov() {
        _isGov();
        _;
    }
    modifier onlyPriceAggregator() {
        _isPriceAggregator();
        _;
    }
    modifier notDone() {
        _isNotDone();
        _;
    }
    modifier onlyTrading() {
        _isTrading();
        _;
    }
    modifier onlyManager() {
        _isManager();
        _;
    }

    // Saving code size by calling these functions inside modifiers
    function _isGov() private view {
        if (msg.sender != storageT.gov()) {
            revert Forbidden();
        }
    }

    function _isPriceAggregator() private view {
        if (msg.sender != address(storageT.priceAggregator())) {
            revert Forbidden();
        }
    }

    function _isNotDone() private view {
        if (isDone) {
            revert Forbidden();
        }
    }

    function _isTrading() private view {
        if (msg.sender != storageT.trading()) {
            revert Forbidden();
        }
    }

    function _isManager() private view {
        if (msg.sender != pairInfos.manager()) {
            revert Forbidden();
        }
    }

    // Manage params
    function setPairMaxLeverage(uint256 pairIndex, uint256 maxLeverage) external onlyManager {
        _setPairMaxLeverage(pairIndex, maxLeverage);
    }

    function setPairMaxLeverageArray(uint256[] calldata indices, uint256[] calldata values) external onlyManager {
        uint256 len = indices.length;

        if (len != values.length) {
            revert WrongParams();
        }

        for (uint256 i; i < len; ) {
            _setPairMaxLeverage(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setPairMaxLeverage(uint256 pairIndex, uint256 maxLeverage) private {
        pairMaxLeverage[pairIndex] = maxLeverage;
        emit PairMaxLeverageUpdated(pairIndex, maxLeverage);
    }

    function setClosingFeeSharesP(uint256 _daiVaultFeeP, uint256 _lpFeeP, uint256 _sssFeeP) external onlyGov {
        if (_daiVaultFeeP + _lpFeeP + _sssFeeP != 100) {
            revert WrongParams();
        }

        daiVaultFeeP = _daiVaultFeeP;
        lpFeeP = _lpFeeP;
        sssFeeP = _sssFeeP;

        emit ClosingFeeSharesPUpdated(_daiVaultFeeP, _lpFeeP, _sssFeeP);
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;

        emit Pause(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // Claim fees
    function claimGovFees() external onlyGov {
        uint256 valueDai = govFeesDai;
        govFeesDai = 0;

        _transferFromStorageToAddress(storageT.gov(), valueDai);

        emit GovFeesClaimed(valueDai);
    }

    // Callbacks
    function openTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        IGNSTradingStorage.PendingMarketOrder memory o = _getPendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        IGNSTradingStorage.Trade memory t = o.trade;

        (uint256 priceImpactP, uint256 priceAfterImpact, CancelReason cancelReason) = _openTradePrep(
            OpenTradePrepInput(
                a.price,
                o.wantedPrice,
                a.price,
                a.spreadP,
                t.buy,
                t.pairIndex,
                t.positionSizeDai,
                t.leverage,
                o.slippageP,
                t.tp,
                t.sl
            )
        );

        t.openPrice = priceAfterImpact;

        if (cancelReason == CancelReason.NONE) {
            (IGNSTradingStorage.Trade memory finalTrade, uint256 tokenPriceDai) = _registerTrade(t, false, 0);

            emit MarketExecuted(
                a.orderId,
                finalTrade,
                true,
                finalTrade.openPrice,
                priceImpactP,
                (finalTrade.initialPosToken * tokenPriceDai) / PRECISION,
                0,
                0
            );
        } else {
            // Gov fee to pay for oracle cost
            uint256 govFees = _handleGovFees(t.trader, t.pairIndex, t.positionSizeDai * t.leverage, true);
            _transferFromStorageToAddress(t.trader, t.positionSizeDai - govFees);

            emit MarketOpenCanceled(a.orderId, t.trader, t.pairIndex, cancelReason);
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        IGNSTradingStorage.PendingMarketOrder memory o = _getPendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        IGNSTradingStorage.Trade memory t = _getOpenTrade(o.trade.trader, o.trade.pairIndex, o.trade.index);

        CancelReason cancelReason = t.leverage == 0
            ? CancelReason.NO_TRADE
            : (a.price == 0 ? CancelReason.MARKET_CLOSED : CancelReason.NONE);

        if (cancelReason != CancelReason.NO_TRADE) {
            IGNSTradingStorage.TradeInfo memory i = _getOpenTradeInfo(t.trader, t.pairIndex, t.index);
            IGNSPriceAggregator aggregator = storageT.priceAggregator();

            Values memory v;
            v.levPosDai = (t.initialPosToken * i.tokenPriceDai * t.leverage) / PRECISION;
            v.tokenPriceDai = aggregator.tokenPriceDai();

            if (cancelReason == CancelReason.NONE) {
                v.profitP = _currentPercentProfit(t.openPrice, a.price, t.buy, t.leverage);
                v.posDai = v.levPosDai / t.leverage;

                v.daiSentToTrader = _unregisterTrade(
                    t,
                    true,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai,
                    (v.levPosDai * aggregator.pairsStorage().pairCloseFeeP(t.pairIndex)) / 100 / PRECISION,
                    (v.levPosDai * aggregator.pairsStorage().pairNftLimitOrderFeeP(t.pairIndex)) / 100 / PRECISION
                );

                emit MarketExecuted(a.orderId, t, false, a.price, 0, v.posDai, v.profitP, v.daiSentToTrader);
            } else {
                // Gov fee to pay for oracle cost
                uint256 govFee = _handleGovFees(t.trader, t.pairIndex, v.levPosDai, t.positionSizeDai > 0);
                t.initialPosToken -= (govFee * PRECISION) / i.tokenPriceDai;

                storageT.updateTrade(t);
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit MarketCloseCanceled(a.orderId, o.trade.trader, o.trade.pairIndex, o.trade.index, cancelReason);
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }

    function executeNftOpenOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        IGNSTradingStorage.PendingNftOrder memory n = storageT.reqID_pendingNftOrder(a.orderId);

        CancelReason cancelReason = !storageT.hasOpenLimitOrder(n.trader, n.pairIndex, n.index)
            ? CancelReason.NO_TRADE
            : CancelReason.NONE;

        if (cancelReason == CancelReason.NONE) {
            IGNSTradingStorage.OpenLimitOrder memory o = storageT.getOpenLimitOrder(n.trader, n.pairIndex, n.index);

            IGNSOracleRewards.OpenLimitOrderType t = nftRewards.openLimitOrderTypes(n.trader, n.pairIndex, n.index);

            cancelReason = (a.high >= o.maxPrice && a.low <= o.maxPrice) ? CancelReason.NONE : CancelReason.NOT_HIT;

            // Note: o.minPrice always equals o.maxPrice so can use either
            (uint256 priceImpactP, uint256 priceAfterImpact, CancelReason _cancelReason) = _openTradePrep(
                OpenTradePrepInput(
                    cancelReason == CancelReason.NONE ? o.maxPrice : a.open,
                    o.maxPrice,
                    a.open,
                    a.spreadP,
                    o.buy,
                    o.pairIndex,
                    o.positionSize,
                    o.leverage,
                    tradeData[o.trader][o.pairIndex][o.index][TradeType.LIMIT].maxSlippageP,
                    o.tp,
                    o.sl
                )
            );

            bool exactExecution = cancelReason == CancelReason.NONE;

            cancelReason = !exactExecution &&
                (
                    o.maxPrice == 0 || t == IGNSOracleRewards.OpenLimitOrderType.MOMENTUM
                        ? (o.buy ? a.open < o.maxPrice : a.open > o.maxPrice)
                        : (o.buy ? a.open > o.maxPrice : a.open < o.maxPrice)
                )
                ? CancelReason.NOT_HIT
                : _cancelReason;

            if (cancelReason == CancelReason.NONE) {
                (IGNSTradingStorage.Trade memory finalTrade, uint256 tokenPriceDai) = _registerTrade(
                    IGNSTradingStorage.Trade(
                        o.trader,
                        o.pairIndex,
                        0,
                        0,
                        o.positionSize,
                        priceAfterImpact,
                        o.buy,
                        o.leverage,
                        o.tp,
                        o.sl
                    ),
                    true,
                    n.index
                );

                storageT.unregisterOpenLimitOrder(o.trader, o.pairIndex, o.index);

                emit LimitExecuted(
                    a.orderId,
                    n.index,
                    finalTrade,
                    n.nftHolder,
                    IGNSTradingStorage.LimitOrder.OPEN,
                    finalTrade.openPrice,
                    priceImpactP,
                    (finalTrade.initialPosToken * tokenPriceDai) / PRECISION,
                    0,
                    0,
                    exactExecution
                );
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit NftOrderCanceled(a.orderId, n.nftHolder, IGNSTradingStorage.LimitOrder.OPEN, cancelReason);
        }

        nftRewards.unregisterTrigger(IGNSOracleRewards.TriggeredLimitId(n.trader, n.pairIndex, n.index, n.orderType));

        storageT.unregisterPendingNftOrder(a.orderId);
    }

    function executeNftCloseOrderCallback(AggregatorAnswer memory a) external onlyPriceAggregator notDone {
        IGNSTradingStorage.PendingNftOrder memory o = storageT.reqID_pendingNftOrder(a.orderId);
        IGNSOracleRewards.TriggeredLimitId memory triggeredLimitId = IGNSOracleRewards.TriggeredLimitId(
            o.trader,
            o.pairIndex,
            o.index,
            o.orderType
        );
        IGNSTradingStorage.Trade memory t = _getOpenTrade(o.trader, o.pairIndex, o.index);

        IGNSPriceAggregator aggregator = storageT.priceAggregator();

        CancelReason cancelReason = a.open == 0
            ? CancelReason.MARKET_CLOSED
            : (t.leverage == 0 ? CancelReason.NO_TRADE : CancelReason.NONE);

        if (cancelReason == CancelReason.NONE) {
            IGNSTradingStorage.TradeInfo memory i = _getOpenTradeInfo(t.trader, t.pairIndex, t.index);

            IGNSPairsStorage pairsStored = aggregator.pairsStorage();

            Values memory v;
            v.levPosDai = (t.initialPosToken * i.tokenPriceDai * t.leverage) / PRECISION;
            v.posDai = v.levPosDai / t.leverage;

            if (o.orderType == IGNSTradingStorage.LimitOrder.LIQ) {
                v.liqPrice = borrowingFees.getTradeLiquidationPrice(
                    IGNSBorrowingFees.LiqPriceInput(
                        t.trader,
                        t.pairIndex,
                        t.index,
                        t.openPrice,
                        t.buy,
                        v.posDai,
                        t.leverage
                    )
                );
            }

            v.price = o.orderType == IGNSTradingStorage.LimitOrder.TP
                ? t.tp
                : (o.orderType == IGNSTradingStorage.LimitOrder.SL ? t.sl : v.liqPrice);

            v.exactExecution = v.price > 0 && a.low <= v.price && a.high >= v.price;

            if (v.exactExecution) {
                v.reward1 = o.orderType == IGNSTradingStorage.LimitOrder.LIQ
                    ? (v.posDai * 5) / 100
                    : (v.levPosDai * pairsStored.pairNftLimitOrderFeeP(t.pairIndex)) / 100 / PRECISION;
            } else {
                v.price = a.open;

                v.reward1 = o.orderType == IGNSTradingStorage.LimitOrder.LIQ
                    ? ((t.buy ? a.open <= v.liqPrice : a.open >= v.liqPrice) ? (v.posDai * 5) / 100 : 0)
                    : (
                        ((o.orderType == IGNSTradingStorage.LimitOrder.TP &&
                            t.tp > 0 &&
                            (t.buy ? a.open >= t.tp : a.open <= t.tp)) ||
                            (o.orderType == IGNSTradingStorage.LimitOrder.SL &&
                                t.sl > 0 &&
                                (t.buy ? a.open <= t.sl : a.open >= t.sl)))
                            ? (v.levPosDai * pairsStored.pairNftLimitOrderFeeP(t.pairIndex)) / 100 / PRECISION
                            : 0
                    );
            }

            cancelReason = v.reward1 == 0 ? CancelReason.NOT_HIT : CancelReason.NONE;

            // If can be triggered
            if (cancelReason == CancelReason.NONE) {
                v.profitP = _currentPercentProfit(t.openPrice, v.price, t.buy, t.leverage);
                v.tokenPriceDai = aggregator.tokenPriceDai();

                v.daiSentToTrader = _unregisterTrade(
                    t,
                    false,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai,
                    o.orderType == IGNSTradingStorage.LimitOrder.LIQ
                        ? v.reward1
                        : (v.levPosDai * pairsStored.pairCloseFeeP(t.pairIndex)) / 100 / PRECISION,
                    v.reward1
                );

                _handleOracleRewards(
                    triggeredLimitId,
                    t.trader,
                    (v.reward1 * 2) / 10,
                    v.tokenPriceDai,
                    aggregator.collateralDecimalDifference()
                );

                emit LimitExecuted(
                    a.orderId,
                    o.index,
                    t,
                    o.nftHolder,
                    o.orderType,
                    v.price,
                    0,
                    v.posDai,
                    v.profitP,
                    v.daiSentToTrader,
                    v.exactExecution
                );
            }
        }

        if (cancelReason != CancelReason.NONE) {
            emit NftOrderCanceled(a.orderId, o.nftHolder, o.orderType, cancelReason);
        }

        nftRewards.unregisterTrigger(triggeredLimitId);
        storageT.unregisterPendingNftOrder(a.orderId);
    }

    // Shared code between market & limit callbacks
    function _registerTrade(
        IGNSTradingStorage.Trade memory trade,
        bool isLimitOrder,
        uint256 limitIndex
    ) private returns (IGNSTradingStorage.Trade memory, uint256) {
        IGNSPriceAggregator aggregator = storageT.priceAggregator();
        IGNSPairsStorage pairsStored = aggregator.pairsStorage();

        Values memory v;

        v.levPosDai = trade.positionSizeDai * trade.leverage;
        v.tokenPriceDai = aggregator.tokenPriceDai();

        // 1. Charge referral fee (if applicable) and send DAI amount to vault
        if (referrals.getTraderReferrer(trade.trader) != address(0)) {
            // Use this variable to store lev pos dai for dev/gov fees after referral fees
            // and before volumeReferredDai increases
            v.posDai =
                (v.levPosDai * (100 * PRECISION - referrals.getPercentOfOpenFeeP(trade.trader))) /
                100 /
                PRECISION;

            v.reward1 = referrals.distributePotentialReward(
                trade.trader,
                v.levPosDai,
                pairsStored.pairOpenFeeP(trade.pairIndex),
                v.tokenPriceDai
            );

            _sendToVault(v.reward1, trade.trader);
            trade.positionSizeDai -= v.reward1;

            emit ReferralFeeCharged(trade.trader, v.reward1);
        }

        // 2. Calculate gov fee (- referral fee if applicable)
        uint256 govFee = _handleGovFees(trade.trader, trade.pairIndex, (v.posDai > 0 ? v.posDai : v.levPosDai), true);
        v.reward1 = govFee; // SSS fee (previously dev fee)

        // 3. Calculate Market/Limit fee
        v.reward2 = (v.levPosDai * pairsStored.pairNftLimitOrderFeeP(trade.pairIndex)) / 100 / PRECISION;

        // 3.1 Deduct gov fee, SSS fee (previously dev fee), Market/Limit fee
        trade.positionSizeDai -= govFee + v.reward1 + v.reward2;

        // 3.2 Distribute Oracle fee and send DAI amount to vault if applicable
        if (isLimitOrder) {
            v.reward3 = (v.reward2 * 2) / 10; // 20% of limit fees
            _sendToVault(v.reward3, trade.trader);

            _handleOracleRewards(
                IGNSOracleRewards.TriggeredLimitId(
                    trade.trader,
                    trade.pairIndex,
                    limitIndex,
                    IGNSTradingStorage.LimitOrder.OPEN
                ),
                trade.trader,
                v.reward3,
                v.tokenPriceDai,
                aggregator.collateralDecimalDifference()
            );
        }

        // 3.3 Distribute SSS fee (previous dev fee + market/limit fee - oracle reward)
        _distributeStakingReward(trade.trader, v.reward1 + v.reward2 - v.reward3);

        // 4. Set trade final details
        trade.index = storageT.firstEmptyTradeIndex(trade.trader, trade.pairIndex);
        trade.initialPosToken = (trade.positionSizeDai * PRECISION) / v.tokenPriceDai;

        trade.tp = _correctTp(trade.openPrice, trade.leverage, trade.tp, trade.buy);
        trade.sl = _correctSl(trade.openPrice, trade.leverage, trade.sl, trade.buy);

        // 5. Call other contracts
        pairInfos.storeTradeInitialAccFees(trade.trader, trade.pairIndex, trade.index, trade.buy);
        pairsStored.updateGroupCollateral(trade.pairIndex, trade.positionSizeDai, trade.buy, true);
        borrowingFees.handleTradeAction(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.positionSizeDai * trade.leverage,
            true,
            trade.buy
        );

        // 6. Store final trade in storage contract
        storageT.storeTrade(
            trade,
            IGNSTradingStorage.TradeInfo(0, v.tokenPriceDai, trade.positionSizeDai * trade.leverage, 0, 0, false)
        );

        // 7. Store tradeLastUpdated
        LastUpdated storage lastUpdated = tradeLastUpdated[trade.trader][trade.pairIndex][trade.index][
            TradeType.MARKET
        ];
        uint32 currBlock = uint32(ChainUtils.getBlockNumber());
        lastUpdated.tp = currBlock;
        lastUpdated.sl = currBlock;
        lastUpdated.created = currBlock;

        return (trade, v.tokenPriceDai);
    }

    function _unregisterTrade(
        IGNSTradingStorage.Trade memory trade,
        bool marketOrder,
        int256 percentProfit, // PRECISION
        uint256 currentDaiPos, // 1e18
        uint256 openInterestDai, // 1e18
        uint256 closingFeeDai, // 1e18
        uint256 nftFeeDai // 1e18 (= SSS reward if market order)
    ) private returns (uint256 daiSentToTrader) {
        IGToken vault = IGToken(storageT.vault());

        // 1. Calculate net PnL (after all closing and holding fees)
        (daiSentToTrader, ) = _getTradeValue(trade, currentDaiPos, percentProfit, closingFeeDai + nftFeeDai);

        // 2. Calls to other contracts
        borrowingFees.handleTradeAction(trade.trader, trade.pairIndex, trade.index, openInterestDai, false, trade.buy);
        _getPairsStorage().updateGroupCollateral(trade.pairIndex, openInterestDai / trade.leverage, trade.buy, false);

        // 3. Unregister trade from storage
        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);

        // 4.1 If collateral in storage
        if (trade.positionSizeDai > 0) {
            Values memory v;

            // 5. DAI vault reward
            v.reward2 = (closingFeeDai * daiVaultFeeP) / 100;
            _transferFromStorageToAddress(address(this), v.reward2);
            vault.distributeReward(v.reward2);

            emit DaiVaultFeeCharged(trade.trader, v.reward2);

            // 6. SSS reward
            v.reward3 = (marketOrder ? nftFeeDai : (nftFeeDai * 8) / 10) + (closingFeeDai * sssFeeP) / 100;
            _distributeStakingReward(trade.trader, v.reward3);

            // 7. Take DAI from vault if winning trade
            // or send DAI to vault if losing trade
            uint256 daiLeftInStorage = currentDaiPos - v.reward3 - v.reward2;

            if (daiSentToTrader > daiLeftInStorage) {
                vault.sendAssets(daiSentToTrader - daiLeftInStorage, trade.trader);
                _transferFromStorageToAddress(trade.trader, daiLeftInStorage);
            } else {
                _sendToVault(daiLeftInStorage - daiSentToTrader, trade.trader);
                _transferFromStorageToAddress(trade.trader, daiSentToTrader);
            }

            // 4.2 If collateral in vault, just send dai to trader from vault
        } else {
            vault.sendAssets(daiSentToTrader, trade.trader);
        }
    }

    // Setters (external)
    function setTradeLastUpdated(SimplifiedTradeId calldata _id, LastUpdated memory _lastUpdated) external onlyTrading {
        tradeLastUpdated[_id.trader][_id.pairIndex][_id.index][_id.tradeType] = _lastUpdated;
    }

    function setTradeData(SimplifiedTradeId calldata _id, TradeData memory _tradeData) external onlyTrading {
        tradeData[_id.trader][_id.pairIndex][_id.index][_id.tradeType] = _tradeData;
    }

    // Getters (private)
    function _getTradeValue(
        IGNSTradingStorage.Trade memory trade,
        uint256 currentDaiPos, // 1e18
        int256 percentProfit, // PRECISION
        uint256 closingFees // 1e18
    ) private returns (uint256 value, uint256 borrowingFee) {
        int256 netProfitP;

        (netProfitP, borrowingFee) = _getBorrowingFeeAdjustedPercentProfit(trade, currentDaiPos, percentProfit);
        value = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentDaiPos,
            trade.leverage,
            netProfitP,
            closingFees
        );

        emit BorrowingFeeCharged(trade.trader, value, borrowingFee);
    }

    function _getBorrowingFeeAdjustedPercentProfit(
        IGNSTradingStorage.Trade memory trade,
        uint256 currentDaiPos, // 1e18
        int256 percentProfit // PRECISION
    ) private view returns (int256 netProfitP, uint256 borrowingFee) {
        borrowingFee = borrowingFees.getTradeBorrowingFee(
            IGNSBorrowingFees.BorrowingFeeInput(
                trade.trader,
                trade.pairIndex,
                trade.index,
                trade.buy,
                currentDaiPos,
                trade.leverage
            )
        );
        netProfitP = percentProfit - int256((borrowingFee * 100 * PRECISION) / currentDaiPos);
    }

    function _withinMaxLeverage(uint256 pairIndex, uint256 leverage) private view returns (bool) {
        uint256 pairMaxLev = pairMaxLeverage[pairIndex];
        return pairMaxLev == 0 ? leverage <= _getPairsStorage().pairMaxLeverage(pairIndex) : leverage <= pairMaxLev;
    }

    function _withinExposureLimits(
        uint256 pairIndex,
        bool buy,
        uint256 positionSizeDai,
        uint256 leverage
    ) private view returns (bool) {
        uint256 levPositionSizeDai = positionSizeDai * leverage;

        return
            storageT.openInterestDai(pairIndex, buy ? 0 : 1) + levPositionSizeDai <=
            borrowingFees.getPairMaxOi(pairIndex) * 1e8 &&
            borrowingFees.withinMaxGroupOi(pairIndex, buy, levPositionSizeDai);
    }

    function _currentPercentProfit(
        uint256 openPrice,
        uint256 currentPrice,
        bool buy,
        uint256 leverage
    ) private pure returns (int256 p) {
        int256 maxPnlP = int256(MAX_GAIN_P) * int256(PRECISION);

        p = openPrice > 0
            ? ((buy ? int256(currentPrice) - int256(openPrice) : int256(openPrice) - int256(currentPrice)) *
                100 *
                int256(PRECISION) *
                int256(leverage)) / int256(openPrice)
            : int256(0);

        p = p > maxPnlP ? maxPnlP : p;
    }

    function _correctTp(uint256 openPrice, uint256 leverage, uint256 tp, bool buy) private pure returns (uint256) {
        if (tp == 0 || _currentPercentProfit(openPrice, tp, buy, leverage) == int256(MAX_GAIN_P) * int256(PRECISION)) {
            uint256 tpDiff = (openPrice * MAX_GAIN_P) / leverage / 100;

            return buy ? openPrice + tpDiff : (tpDiff <= openPrice ? openPrice - tpDiff : 0);
        }

        return tp;
    }

    function _correctSl(uint256 openPrice, uint256 leverage, uint256 sl, bool buy) private pure returns (uint256) {
        if (sl > 0 && _currentPercentProfit(openPrice, sl, buy, leverage) < int256(MAX_SL_P) * int256(PRECISION) * -1) {
            uint256 slDiff = (openPrice * MAX_SL_P) / leverage / 100;

            return buy ? openPrice - slDiff : openPrice + slDiff;
        }

        return sl;
    }

    function _marketExecutionPrice(uint256 price, uint256 spreadP, bool long) private pure returns (uint256) {
        uint256 priceDiff = (price * spreadP) / 100 / PRECISION;

        return long ? price + priceDiff : price - priceDiff;
    }

    function _openTradePrep(
        OpenTradePrepInput memory c
    ) private view returns (uint256 priceImpactP, uint256 priceAfterImpact, CancelReason cancelReason) {
        (priceImpactP, priceAfterImpact) = pairInfos.getTradePriceImpact(
            _marketExecutionPrice(c.executionPrice, c.spreadP, c.buy),
            c.pairIndex,
            c.buy,
            c.positionSize * c.leverage
        );

        uint256 maxSlippage = c.maxSlippageP > 0
            ? (c.wantedPrice * c.maxSlippageP) / 100 / PRECISION
            : c.wantedPrice / 100; // 1% by default

        cancelReason = isPaused
            ? CancelReason.PAUSED
            : (
                c.marketPrice == 0
                    ? CancelReason.MARKET_CLOSED
                    : (
                        c.buy
                            ? priceAfterImpact > c.wantedPrice + maxSlippage
                            : priceAfterImpact < c.wantedPrice - maxSlippage
                    )
                    ? CancelReason.SLIPPAGE
                    : (c.tp > 0 && (c.buy ? priceAfterImpact >= c.tp : priceAfterImpact <= c.tp))
                    ? CancelReason.TP_REACHED
                    : (c.sl > 0 && (c.buy ? priceAfterImpact <= c.sl : priceAfterImpact >= c.sl))
                    ? CancelReason.SL_REACHED
                    : !_withinExposureLimits(c.pairIndex, c.buy, c.positionSize, c.leverage)
                    ? CancelReason.EXPOSURE_LIMITS
                    : priceImpactP * c.leverage > pairInfos.maxNegativePnlOnOpenP()
                    ? CancelReason.PRICE_IMPACT
                    : !_withinMaxLeverage(c.pairIndex, c.leverage)
                    ? CancelReason.MAX_LEVERAGE
                    : CancelReason.NONE
            );
    }

    function _getPendingMarketOrder(
        uint256 orderId
    ) private view returns (IGNSTradingStorage.PendingMarketOrder memory) {
        return storageT.reqID_pendingMarketOrder(orderId);
    }

    function _getPairsStorage() private view returns (IGNSPairsStorage) {
        return storageT.priceAggregator().pairsStorage();
    }

    function _getOpenTrade(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) private view returns (IGNSTradingStorage.Trade memory) {
        return storageT.openTrades(trader, pairIndex, index);
    }

    function _getOpenTradeInfo(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) private view returns (IGNSTradingStorage.TradeInfo memory) {
        return storageT.openTradesInfo(trader, pairIndex, index);
    }

    // Utils (private)
    function _distributeStakingReward(address trader, uint256 amountDai) private {
        _transferFromStorageToAddress(address(this), amountDai);
        staking.distributeReward(amountDai, storageT.dai());
        emit SssFeeCharged(trader, amountDai);
    }

    function _sendToVault(uint256 amountDai, address trader) private {
        _transferFromStorageToAddress(address(this), amountDai);
        IGToken(storageT.vault()).receiveAssets(amountDai, trader);
    }

    function _transferFromStorageToAddress(address to, uint256 amountDai) private {
        storageT.transferDai(address(storageT), to, amountDai);
    }

    function _handleOracleRewards(
        IGNSOracleRewards.TriggeredLimitId memory triggeredLimitId,
        address trader,
        uint256 oracleRewardDai,
        uint256 tokenPriceDai,
        uint256 collateralDecimalDifference
    ) private {
        // Convert Oracle Rewards from DAI to token value
        uint256 oracleRewardToken = ((oracleRewardDai * collateralDecimalDifference * PRECISION) / tokenPriceDai);
        nftRewards.distributeOracleReward(triggeredLimitId, oracleRewardToken);

        emit TriggerFeeCharged(trader, oracleRewardDai);
    }

    function _handleGovFees(
        address trader,
        uint256 pairIndex,
        uint256 leveragedPositionSize,
        bool distribute
    ) private returns (uint256 govFee) {
        govFee = (leveragedPositionSize * storageT.priceAggregator().openFeeP(pairIndex)) / PRECISION / 100;

        if (distribute) {
            govFeesDai += govFee;
        }

        emit GovFeeCharged(trader, govFee, distribute);
    }

    // Getters (public)
    function getAllPairsMaxLeverage() external view returns (uint256[] memory) {
        uint256 len = _getPairsStorage().pairsCount();
        uint256[] memory lev = new uint256[](len);

        for (uint256 i; i < len; ) {
            lev[i] = pairMaxLeverage[i];
            unchecked {
                ++i;
            }
        }

        return lev;
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

/**
 * @custom:version 7
 */
interface IERC20 {
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
pragma solidity 0.8.17;

import "../libraries/PriceImpactUtils.sol";
import "../libraries/FeeTiersUtils.sol";

/**
 * @custom:version 7
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
        uint128 collateralPrecision;
    }

    // Errors
    error WrongSlot();
    error WrongAccess();
    error WrongParams();
    error ZeroGroup();
    error WrongExponent();
    error BlockOrder();
    error Overflow();
    error WrongLength();

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

    // v6.4.3 - FeeTiersUtils events
    event GroupVolumeMultipliersUpdated(uint256[] groupIndices, uint256[] groupVolumeMultipliers);
    event FeeTiersUpdated(uint256[] feeTiersIndices, FeeTiersUtils.FeeTier[] feeTiers);

    event TraderDailyPointsIncreased(address indexed trader, uint32 indexed day, uint224 amountScaled);
    event TraderInfoFirstUpdate(address indexed trader, uint32 day);
    event TraderTrailingPointsExpired(address indexed trader, uint32 fromDay, uint32 toDay, uint224 amount);
    event TraderInfoUpdated(address indexed trader, FeeTiersUtils.TraderInfo traderInfo);
    event TraderFeeMultiplierCached(address indexed trader, uint32 indexed day, uint32 feeMultiplier);

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

    function getNormalizedPairMaxOi(uint256 pairIndex) external view returns (uint256);

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

    // v6.4.3 - Functions
    function updateTraderPoints(address trader, uint256 amount, uint256 pairIndex) external;

    function calculateFeeAmount(address trader, uint256 normalFeeAmount) external view returns (uint256);
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
 * @custom:version 6.4.3
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

    function pairs(
        uint256
    )
        external
        view
        returns (
            string memory,
            string memory,
            Feed memory,
            uint256, // PRECISION
            uint256,
            uint256
        );

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

    function collateralPriceFeed() external view returns (IChainlinkFeed);

    function nodes(uint256 index) external view returns (address);

    function getCollateralDecimalDifference() external view returns (uint128);

    function collateralDecimalDifference() external view returns (uint128); // @todo remove

    function getCollateralPrecision() external view returns (uint128);

    event PairsStorageUpdated(address value);
    event LinkPriceFeedUpdated(address value);
    event CollateralPriceFeedUpdated(address value);

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

/**
 * @custom:version 7
 */
interface IGNSStaking {
    struct Staker {
        uint128 stakedGns; // 1e18
        uint128 debtDai; // 1e18
    }

    struct RewardState {
        uint128 accRewardPerToken;
        uint128 __placeholder;
    }

    struct StakeInfo {
        uint128 debtToken;
        uint128 __placeholder;
    }

    struct UnlockSchedule {
        uint128 totalGns; // 1e18
        uint128 claimedGns; // 1e18
        uint128 debtDai; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
        uint16 __placeholder;
    }

    struct UnlockScheduleInput {
        uint128 totalGns; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
    }

    enum UnlockType {
        LINEAR,
        CLIFF
    }

    function owner() external view returns (address);

    function distributeRewardDai(uint256 _amountDai) external;

    function distributeReward(uint256 _amountToken, address rewardToken) external;

    function createUnlockSchedule(UnlockScheduleInput calldata _schedule, address _staker) external;

    event UnlockManagerUpdated(address indexed manager, bool authorized);

    event DaiHarvested(address indexed staker, uint128 amountDai);
    event DaiHarvestedFromUnlock(address indexed staker, uint256[] ids, uint128 amountDai);

    event RewardHarvested(address indexed staker, address indexed token, uint128 amountToken);
    event RewardHarvestedFromUnlock(address indexed staker, address indexed token, uint256[] ids, uint128 amountToken);
    event RewardDistributed(address indexed token, uint256 amount);

    event GnsStaked(address indexed staker, uint128 amountGns);
    event GnsUnstaked(address indexed staker, uint128 amountGns);
    event GnsClaimed(address indexed staker, uint256[] ids, uint128 amountGns);

    event UnlockScheduled(address indexed staker, uint256 indexed index, UnlockSchedule schedule);
    event UnlockScheduleRevoked(address indexed staker, uint256 indexed index);

    event RewardTokenAdded(address token, uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSTradingStorage.sol";

/**
 * @custom:version 6.4.3
 */
interface IGNSTradingCallbacks {
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
        bool isPaused;
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
        uint256 pairMaxLeverage;
    }

    error WrongParams();
    error Forbidden();

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

/**
 * @custom:version 7
 */
interface IGToken {
    struct GnsPriceProvider {
        address addr;
        bytes signature;
    }

    struct LockedDeposit {
        address owner;
        uint256 shares; // 1e18
        uint256 assetsDeposited; // 1e18
        uint256 assetsDiscount; // 1e18
        uint256 atTimestamp; // timestamp
        uint256 lockDuration; // timestamp
    }

    struct ContractAddresses {
        address asset;
        address owner; // 2-week timelock contract
        address manager; // 3-day timelock contract
        address admin; // bypasses timelock, access to emergency functions
        address gnsToken;
        address lockedDepositNft;
        address pnlHandler;
        address openTradesPnlFeed;
        GnsPriceProvider gnsPriceProvider;
    }

    struct Meta {
        string name;
        string symbol;
    }

    function manager() external view returns (address);

    function admin() external view returns (address);

    function currentEpoch() external view returns (uint256);

    function currentEpochStart() external view returns (uint256);

    function currentEpochPositiveOpenPnl() external view returns (uint256);

    function updateAccPnlPerTokenUsed(
        uint256 prevPositiveOpenPnl,
        uint256 newPositiveOpenPnl
    ) external returns (uint256);

    function getLockedDeposit(uint256 depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint256 assets, address receiver) external;

    function receiveAssets(uint256 assets, address user) external;

    function distributeReward(uint256 assets) external;

    function currentBalanceDai() external view returns (uint256);

    function tvl() external view returns (uint256);

    function marketCap() external view returns (uint256);

    function getPendingAccBlockWeightedMarketCap(uint256 currentBlock) external view returns (uint256);

    event AddressParamUpdated(string name, address newValue);
    event GnsPriceProviderUpdated(GnsPriceProvider newValue);
    event NumberParamUpdated(string name, uint256 newValue);
    event WithdrawLockThresholdsPUpdated(uint256[2] newValue);

    event CurrentMaxSupplyUpdated(uint256 newValue);
    event DailyAccPnlDeltaReset();
    event ShareToAssetsPriceUpdated(uint256 newValue);
    event OpenTradesPnlFeedCallFailed();

    event WithdrawRequested(
        address indexed sender,
        address indexed owner,
        uint256 shares,
        uint256 currEpoch,
        uint256 indexed unlockEpoch
    );
    event WithdrawCanceled(
        address indexed sender,
        address indexed owner,
        uint256 shares,
        uint256 currEpoch,
        uint256 indexed unlockEpoch
    );

    event DepositLocked(address indexed sender, address indexed owner, uint256 depositId, LockedDeposit d);
    event DepositUnlocked(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 depositId,
        LockedDeposit d
    );

    event RewardDistributed(address indexed sender, uint256 assets);

    event AssetsSent(address indexed sender, address indexed receiver, uint256 assets);
    event AssetsReceived(address indexed sender, address indexed user, uint256 assets, uint256 assetsLessDeplete);

    event Depleted(address indexed sender, uint256 assets, uint256 amountGns);
    event Refilled(address indexed sender, uint256 assets, uint256 amountGns);

    event AccPnlPerTokenUsedUpdated(
        address indexed sender,
        uint256 indexed newEpoch,
        uint256 prevPositiveOpenPnl,
        uint256 newPositiveOpenPnl,
        uint256 newEpochPositiveOpenPnl,
        int256 newAccPnlPerTokenUsed
    );

    event AccBlockWeightedMarketCapStored(uint256 newAccValue);

    error IncorrectPrecision();
    error WrongParams();
    error OnlyManager();
    error OnlyTradingPnlHandler();
    error OnlyPnlFeed();
    error AddressZero();
    error PriceZero();
    error ValueZero();
    error BytesZero();
    error NoActiveDiscount();
    error BelowMinLockDuration();
    error AboveMaxLockDuration();
    error WrongValue();
    error WrongValues();
    error BelowMin();
    error AboveMax();
    error AboveMaxDiscount();
    error GnsPriceCallFailed();
    error GnsTokenPriceZero();
    error PendingWithdrawal();

    // ownable and erc4626

    error EndOfEpoch();
    error NotAllowed();
    error MoreThanBalance();
    error MoreThanWithdrawAmount();
    error DepositMoreThanMax();
    error MintMoreThanMax();
    error NoDiscount();
    error NotUnlocked();
    error NotEnoughAssets();
    error MaxDailyPnl();
    error AmountTooBig();
    error NotUnderCollateralized();
    error AboveInflationLimit();

    // Ownable
    error OwnableInvalidOwner(address owner);

    // ERC4626
    error ERC4626ExceededMaxDeposit();
    error ERC4626ExceededMaxMint();
    error ERC4626ExceededMaxWithdraw();
    error ERC4626ExceededMaxRedeem();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

/**
 * @custom:version 6.4.3
 */
library ChainUtils {
    uint256 private constant ARBITRUM_MAINNET = 42161;
    uint256 private constant ARBITRUM_GOERLI = 421613;
    IArbSys private constant ARB_SYS = IArbSys(address(100));

    error Overflow();

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint256 blockNumber) internal pure returns (uint48) {
        if (blockNumber > type(uint48).max) revert Overflow();
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./StorageUtils.sol";

/**
 * @custom:version 6.4.3
 *
 * @dev This is a library to apply fee tiers to trading fees based on a trailing point system.
 *
 * GNSBorrowingFees contains the storage and wrapper functions.
 * GNSTradingCallbacks calls the wrappers in GNSBorrowingFees to apply fee tiers and update a trader's points.
 */
library FeeTiersUtils {
    uint256 private constant MAX_FEE_TIERS = 8;
    uint32 private constant TRAILING_PERIOD_DAYS = 30;
    uint32 private constant FEE_MULTIPLIER_SCALE = 1e3;
    uint224 internal constant POINTS_THRESHOLD_SCALE = 1e18;
    uint256 private constant GROUP_VOLUME_MULTIPLIER_SCALE = 1e3;

    struct FeeTier {
        uint32 feeMultiplier; // 1e3
        uint32 pointsThreshold;
    }

    struct TraderInfo {
        uint32 lastDayUpdated;
        uint224 trailingPoints; // 1e18
    }

    struct TraderDailyInfo {
        uint32 feeMultiplierCache; // 1e3
        uint224 points; // 1e18
    }

    struct FeeTiersStorage {
        // Params
        FeeTier[MAX_FEE_TIERS] feeTiers;
        mapping(uint256 => uint256) groupVolumeMultipliers; // groupIndex (pairs storage) => multiplier (1e3)
        // State
        mapping(address => TraderInfo) traderInfos; // trader => TraderInfo
        mapping(address => mapping(uint32 => TraderDailyInfo)) traderDailyInfos; // trader => day => TraderDailyInfo
    }

    error WrongFeeTier();
    error WrongOrder();
    error WrongLength();
    error WrongVolumeMultiplier();

    event GroupVolumeMultipliersUpdated(uint256[] groupIndices, uint256[] groupVolumeMultipliers);
    event FeeTiersUpdated(uint256[] feeTiersIndices, FeeTier[] feeTiers);

    event TraderDailyPointsIncreased(address indexed trader, uint32 indexed day, uint224 points);
    event TraderInfoFirstUpdate(address indexed trader, uint32 day);
    event TraderTrailingPointsExpired(address indexed trader, uint32 fromDay, uint32 toDay, uint224 amount);
    event TraderInfoUpdated(address indexed trader, TraderInfo traderInfo);
    event TraderFeeMultiplierCached(address indexed trader, uint32 indexed day, uint32 feeMultiplier);

    /**
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function getSlot() public pure returns (uint256) {
        return StorageUtils.FEE_TIERS_STORAGE_SLOT;
    }

    /**
     * @dev Returns storage pointer for struct in borrowing fees contract, at defined slot
     */
    function getStorage() private pure returns (FeeTiersStorage storage s) {
        uint256 storageSlot = getSlot();
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Initialize fee tiers storage.
     */
    function initialize(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers,
        uint256[] calldata _feeTiersIndices,
        FeeTier[] calldata _feeTiers
    ) external {
        setGroupVolumeMultipliers(_groupIndices, _groupVolumeMultipliers);
        setFeeTiers(_feeTiersIndices, _feeTiers);
    }

    /**
     * @dev Set groups trading volume multipliers.
     */
    function setGroupVolumeMultipliers(
        uint256[] calldata _groupIndices,
        uint256[] calldata _groupVolumeMultipliers
    ) public {
        if (_groupIndices.length != _groupVolumeMultipliers.length) {
            revert WrongLength();
        }

        mapping(uint256 => uint256) storage groupVolumeMultipliers = getStorage().groupVolumeMultipliers;

        for (uint256 i; i < _groupIndices.length; ++i) {
            if (_groupVolumeMultipliers[i] < GROUP_VOLUME_MULTIPLIER_SCALE) {
                revert WrongVolumeMultiplier();
            }
            groupVolumeMultipliers[_groupIndices[i]] = _groupVolumeMultipliers[i];
        }

        emit GroupVolumeMultipliersUpdated(_groupIndices, _groupVolumeMultipliers);
    }

    /**
     * @dev Checks validity of a single fee tier update (feeMultiplier: descending, pointsThreshold: ascending, no gap)
     */
    function _checkFeeTierUpdateValid(
        uint256 _index,
        FeeTier calldata _feeTier,
        FeeTier[8] storage _feeTiers
    ) private view {
        bool isDisabled = _feeTier.feeMultiplier == 0 && _feeTier.pointsThreshold == 0;

        // Either both feeMultiplier and pointsThreshold are 0 or none
        // And make sure feeMultiplier < 1 otherwise useless
        if (
            !isDisabled &&
            (_feeTier.feeMultiplier >= FEE_MULTIPLIER_SCALE ||
                _feeTier.feeMultiplier == 0 ||
                _feeTier.pointsThreshold == 0)
        ) {
            revert WrongFeeTier();
        }

        bool hasNextValue = _index < MAX_FEE_TIERS - 1;

        // If disabled, only need to check the next fee tier is disabled as well to create no gaps in active tiers
        if (isDisabled) {
            if (hasNextValue && _feeTiers[_index + 1].feeMultiplier > 0) {
                revert WrongOrder();
            }
        } else {
            // Check next value order
            if (hasNextValue) {
                FeeTier memory feeTier = _feeTiers[_index + 1];
                if (
                    feeTier.feeMultiplier != 0 &&
                    (feeTier.feeMultiplier >= _feeTier.feeMultiplier ||
                        feeTier.pointsThreshold <= _feeTier.pointsThreshold)
                ) {
                    revert WrongOrder();
                }
            }

            // Check previous value order
            if (_index > 0) {
                FeeTier memory feeTier = _feeTiers[_index - 1];
                if (
                    feeTier.feeMultiplier <= _feeTier.feeMultiplier ||
                    feeTier.pointsThreshold >= _feeTier.pointsThreshold
                ) {
                    revert WrongOrder();
                }
            }
        }
    }

    /**
     * @dev Set multiple fee tiers.
     */
    function setFeeTiers(uint256[] calldata _feeTiersIndices, FeeTier[] calldata _feeTiers) public {
        if (_feeTiersIndices.length > MAX_FEE_TIERS) {
            revert WrongLength();
        }

        FeeTier[8] storage feeTiersStorage = getStorage().feeTiers;

        // First do all updates
        for (uint256 i; i < _feeTiersIndices.length; ++i) {
            feeTiersStorage[_feeTiersIndices[i]] = _feeTiers[i];
        }

        // Then check updates are valid
        for (uint256 i; i < _feeTiersIndices.length; ++i) {
            _checkFeeTierUpdateValid(_feeTiersIndices[i], _feeTiers[i], feeTiersStorage);
        }

        emit FeeTiersUpdated(_feeTiersIndices, _feeTiers);
    }

    /**
     * @dev Calculate trader fee amount, applying cached fee tier.
     */
    function calculateFeeAmount(address _trader, uint256 _normalFeeAmount) external view returns (uint256) {
        uint256 feeMultiplier = getStorage().traderDailyInfos[_trader][getCurrentDay()].feeMultiplierCache;
        return
            feeMultiplier == 0
                ? _normalFeeAmount
                : (uint256(feeMultiplier) * _normalFeeAmount) / uint256(FEE_MULTIPLIER_SCALE);
    }

    /**
     * @dev Returns active fee tiers count
     */
    function getFeeTiersCount(FeeTier[8] storage _feeTiers) public view returns (uint256) {
        for (uint256 i = MAX_FEE_TIERS; i > 0; --i) {
            if (_feeTiers[i - 1].feeMultiplier > 0) {
                return i;
            }
        }

        return 0;
    }

    /**
     * @dev Get current day (index of mapping traderDailyInfo)
     */
    function getCurrentDay() public view returns (uint32) {
        return uint32(block.timestamp / 1 days);
    }

    /**
     * @dev Update daily points, re-calculate trailing points, and cache daily fee tier for trader.
     */
    function updateTraderPoints(address _trader, uint256 _rawVolume, uint256 _groupIndex) external {
        FeeTiersStorage storage s = getStorage();

        // Scale amount by group multiplier
        uint224 points = uint224((_rawVolume * s.groupVolumeMultipliers[_groupIndex]) / GROUP_VOLUME_MULTIPLIER_SCALE);

        mapping(uint32 => TraderDailyInfo) storage traderDailyInfo = s.traderDailyInfos[_trader];
        uint32 currentDay = getCurrentDay();
        TraderDailyInfo storage traderCurrentDayInfo = traderDailyInfo[currentDay];

        // Increase points for current day
        if (points > 0) {
            traderCurrentDayInfo.points += points;
            emit TraderDailyPointsIncreased(_trader, currentDay, points);
        }

        TraderInfo storage traderInfo = s.traderInfos[_trader];

        // Return early if first update ever for trader since trailing points would be 0 anyway
        if (traderInfo.lastDayUpdated == 0) {
            traderInfo.lastDayUpdated = currentDay;
            emit TraderInfoFirstUpdate(_trader, currentDay);

            return;
        }

        // Update trailing points & re-calculate cached fee tier.
        // Only run if at least 1 day elapsed since last update
        if (currentDay > traderInfo.lastDayUpdated) {
            // Trailing points = sum of all daily points accumulated for last TRAILING_PERIOD_DAYS.
            // It determines which fee tier to apply (pointsThreshold)
            uint224 curTrailingPoints;

            // Calculate trailing points if less than or exactly TRAILING_PERIOD_DAYS have elapsed since update.
            // Otherwise, trailing points is 0 anyway.
            uint32 earliestActiveDay = currentDay - TRAILING_PERIOD_DAYS;

            if (traderInfo.lastDayUpdated >= earliestActiveDay) {
                // Load current trailing points and add last day updated points since it is now finalized
                curTrailingPoints = traderInfo.trailingPoints + traderDailyInfo[traderInfo.lastDayUpdated].points;

                // Expire outdated trailing points
                uint32 earliestOutdatedDay = traderInfo.lastDayUpdated - TRAILING_PERIOD_DAYS;
                uint32 lastOutdatedDay = earliestActiveDay - 1;

                uint224 expiredTrailingPoints;
                for (uint32 i = earliestOutdatedDay; i <= lastOutdatedDay; ++i) {
                    expiredTrailingPoints += traderDailyInfo[i].points;
                }

                curTrailingPoints -= expiredTrailingPoints;

                emit TraderTrailingPointsExpired(_trader, earliestOutdatedDay, lastOutdatedDay, expiredTrailingPoints);
            }

            // Store last updated day and new trailing points
            traderInfo.lastDayUpdated = currentDay;
            traderInfo.trailingPoints = curTrailingPoints;

            emit TraderInfoUpdated(_trader, traderInfo);

            // Re-calculate current fee tier for trader
            FeeTier[8] storage feeTiersStorage = s.feeTiers;
            uint32 newFeeMultiplier = FEE_MULTIPLIER_SCALE; // use 1 by default (if no fee tier corresponds)

            for (uint256 i = getFeeTiersCount(feeTiersStorage); i > 0; --i) {
                FeeTier memory feeTier = feeTiersStorage[i - 1];

                if (curTrailingPoints >= uint224(feeTier.pointsThreshold) * POINTS_THRESHOLD_SCALE) {
                    newFeeMultiplier = feeTier.feeMultiplier;
                    break;
                }
            }

            // Update trader cached fee multiplier
            traderCurrentDayInfo.feeMultiplierCache = newFeeMultiplier;
            emit TraderFeeMultiplierCached(_trader, currentDay, newFeeMultiplier);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IGNSTradingStorage.sol";

import "./StorageUtils.sol";

/**
 * @custom:version 7
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
     * @dev Returns storage slot to use when fetching storage relevant to library
     */
    function getSlot() public pure returns (uint256) {
        return StorageUtils.PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT;
    }

    /**
     * @dev Returns storage pointer for struct in borrowing contract, at defined slot
     */
    function getStorage() private pure returns (OiWindowsStorage storage s) {
        uint256 storageSlot = getSlot();
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
     * to current window of `_newPairOiWindows` for `_pairsCount` pairs.
     *
     * Emits a {PriceImpactOiTransferredPairs} event.
     */
    function transferPriceImpactOiForPairs(
        uint256 _pairsCount,
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

        for (uint256 pairIndex; pairIndex < _pairsCount; ) {
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

        emit PriceImpactOiTransferredPairs(_pairsCount, prevCurrentWindowId, prevEarliestWindowId, newCurrentWindowId);
    }

    /**
     * @dev Transfers total long / short OI from `prevEarliestWindowId` to `prevCurrentWindowId` windows of
     * `_prevPairOiWindows` to `_newPairOiWindow` window.
     *
     * Emits a {PriceImpactOiTransferredPair} event.
     */
    function transferPriceImpactOiForPair(
        uint256 _pairIndex,
        uint256 _prevCurrentWindowId,
        uint256 _prevEarliestWindowId,
        mapping(uint256 => PairOi) storage _prevPairOiWindows,
        PairOi storage _newPairOiWindow
    ) private {
        PairOi memory totalPairOi;

        // Aggregate sum of total long / short OI for past windows
        for (uint256 id = _prevEarliestWindowId; id <= _prevCurrentWindowId; ) {
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
            emit PriceImpactOiTransferredPair(_pairIndex, totalPairOi);
        }
    }

    /**
     * @dev Returns window id at `_timestamp` given `_settings`.
     */
    function getWindowId(uint48 _timestamp, OiWindowsSettings memory _settings) public pure returns (uint256) {
        return (_timestamp - _settings.startTs) / _settings.windowsDuration;
    }

    /**
     * @dev Returns window id at current timestamp given `_settings`.
     */
    function getCurrentWindowId(OiWindowsSettings memory _settings) public view returns (uint256) {
        return getWindowId(uint48(block.timestamp), _settings);
    }

    /**
     * @dev Returns earliest active window id given `_currentWindowId` and `_windowsCount`.
     */
    function getEarliestActiveWindowId(uint256 _currentWindowId, uint48 _windowsCount) public pure returns (uint256) {
        uint256 windowNegativeDelta = _windowsCount - 1; // -1 because we include current window
        return _currentWindowId > windowNegativeDelta ? _currentWindowId - windowNegativeDelta : 0;
    }

    /**
     * @dev Returns whether '_windowId' can be potentially active id given `_currentWindowId`
     */
    function isWindowPotentiallyActive(uint256 _windowId, uint256 _currentWindowId) public pure returns (bool) {
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
        uint256 _onePercentDepth,
        uint128 _collateralPrecision
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

        priceImpactP =
            ((_startOpenInterest + _tradeOpenInterest / 2) * PRECISION) /
            _onePercentDepth /
            uint256(_collateralPrecision);

        uint256 priceImpact = (priceImpactP * _openPrice) / PRECISION / 100;
        priceAfterImpact = _long ? _openPrice + priceImpact : _openPrice - priceImpact;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.4.3
 *
 * @dev This is a library to help manage storage slots used by our external libraries.
 *
 * BE EXTREMELY CAREFUL, DO NOT EDIT THIS WITHOUT A GOOD REASON
 *
 */
library StorageUtils {
    uint256 internal constant PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT = 7;
    uint256 internal constant FEE_TIERS_STORAGE_SLOT = 9;
}