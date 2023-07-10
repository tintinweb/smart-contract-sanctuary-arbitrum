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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
import './IPairsStorage.sol';
pragma solidity 0.8.17;

interface IAggregator{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL, ADL_CLOSE }
    function pairsStorage() external view returns(IPairsStorage);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function batchGetPrice(uint[] calldata,OrderType,uint) external returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function openFeeP(uint) external view returns(uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

// SPDX-License-Identifier: MIT
import './IReferralStorage.sol';

pragma solidity 0.8.17;

interface ICallbacks{
    struct Values{
        uint posUsdt; 
        uint levPosUsdt; 
        int profitP; 
        uint price;
        uint liqPrice;
        uint usdtSentToTrader;
        uint reward1;
        uint reward2;
        uint reward3;
        uint referralSaveFee;
    }

    struct Fees{
        uint rolloverFee;
        int fundingFee;
        uint closingFee;
    }

    struct AggregatorAnswer{ 
        uint orderId; 
        uint price; 
        uint spreadP; 
    }

    function usdtVaultFeeP() external view returns(uint);
    function nftPassSaveFeeP() external view returns(uint);
    function lpFeeP() external view returns(uint);
    function sssFeeP() external view returns(uint);
    function MAX_SL_P() external view returns(uint);
    function MIN_SL_P() external view returns(uint);
    function MAX_GAIN_P() external view returns(uint);
    function MIN_GAIN_P() external view returns(uint);
    function openTradeMarketCallback(AggregatorAnswer memory) external;
    function closeTradeMarketCallback(AggregatorAnswer memory) external;
    function executeNftOpenOrderCallback(AggregatorAnswer memory) external;
    function executeNftCloseOrderCallback(AggregatorAnswer memory) external;
    function updateSlCallback(AggregatorAnswer memory) external;
    function withinExposureLimits(uint, bool, uint, uint) external view returns(bool);
    function callSendToVault(uint, address) external;
    function callVaultSendToTrader     (uint, address ) external;
    function referralStorage() external view returns(IReferralStorage);
    function executionFee() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMonthPassNft{
    function paused() external view returns (bool);
    function exists(uint256) external view returns (bool);
    function isUsable(uint256) external view returns (bool);
    function balanceOf(address, uint256 ) external view returns (uint256);
    function isTokenIdExist(uint256) external view returns (bool);
    function isValidTokenId(uint256) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
import './IStorageT.sol';
pragma solidity 0.8.17;

interface INftRewards{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; IStorageT.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairsStorage{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Pair{string from; string to; Feed feed; uint spreadP; uint groupIndex; uint feeIndex;}
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairsCount() external view returns (uint);
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosUsdt(uint) external view returns(uint);
    function pairMaxLevPosUsdt(uint) external view returns(uint);
    function pairMaxGainP(uint) external view returns(uint);
    function getPairs(uint _index) external view returns(Pair memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable{
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPEXPairInfos{
    function maxNegativePnlOnOpenP() external view returns(uint); // PRECISION (%)
    function LIQ_THRESHOLD_P() external view returns(uint);

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice,   // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // USDT
    ) external view returns(
        uint priceImpactP,      // PRECISION (%)
        uint priceAfterImpact   // PRECISION
    );

   function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice,  // PRECISION
        bool long,
        uint collateral, // USDT
        uint leverage
    ) external view returns(uint); // PRECISION

    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // USDT
    ) external view returns(uint);

    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // USDT
        uint leverage
    ) external view returns(int);

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral,   // USDT
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee    // USDT
    ) external returns(uint amount, uint rolloverFee); // USDT

    function adlStoreAccFundingFees(uint pairIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPToken{
    function sendAssets(uint assets, address receiver) external;
    function receiveAssets(uint assets, address user) external;
    function currentBalanceUsdt() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IReferralStorage {
    function getTraderReferralInfo(
        address _account
    ) external returns (bytes32, address);

    function distributeReferralAndSaveFee(
        address trader,
        uint256 tradeVolume,
        uint256 fee
    ) external returns (uint256 fessSave);

    function claimRebate() external;

    function claimSave() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './ITokenV1.sol';
import './IPToken.sol';
import './IPairsStorage.sol';
import './IPausable.sol';
import './IAggregator.sol';
import './ITradeRegister.sol';
import './IMonthPassNft.sol';

interface IStorageT{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    enum AdlOrder { ADLTP, ADLSL }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosUSDT;        // !!! use as if nft used (cause proxy update)
        uint positionSizeUsdt;
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint openInterestUsdt;
        uint storeTradeBlock;
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // !!! use as if nft used (cause proxy update)
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // !!! index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    struct PendingAdlOrder{
        address nftHolder;
        address trader;
        uint pairIndex;
        uint index;
        AdlOrder adlType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function usdt() external view returns(IERC20);
    function token() external view returns(ITokenV1);
    function linkErc677() external view returns(ITokenV1);
    function priceAggregator() external view returns(IAggregator);
    function vault() external view returns(IPToken);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function transferUsdt(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint) external view returns(uint);
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestUsdt(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function isBotListed(address) external view returns (bool);
    function increaseUpnlLastId() external;
    function getUpnlLastId() external view returns(uint256);
    function storePendingAdlOrder(PendingAdlOrder memory, uint ) external;
    function adlCallbacks() external view returns(address);
    function adlClosing() external view returns(address);
    function unregisterPendingAdlOrder(uint) external;
    function pendingAdlOrders(uint) external view returns(PendingAdlOrder[] memory);
    function pendingAdlOrdersCount(uint) external view returns(uint);
    function tradeRegister() external view returns(ITradeRegister);
    function monthPassNft() external view returns(IMonthPassNft);
    function handlePlatFormFeeFromNft(address, uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenV1{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import './IStorageT.sol';

interface ITradeRegister{
    struct Fees{ uint rolloverFee; int fundingFee; uint closingFee; }
    function registerTrade(IStorageT.Trade memory, uint, uint) external returns (IStorageT.Trade memory);
    function unregisterTrade(IStorageT.Trade memory, int, uint, uint, uint) external returns (uint, Fees memory);
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import '../interfaces/ITokenV1.sol';
import '../interfaces/IPairsStorage.sol';
import '../interfaces/IStorageT.sol';
import '../interfaces/IPEXPairInfos.sol';
import '../interfaces/INftRewards.sol';
import '../interfaces/ICallbacks.sol';
import '../interfaces/IMonthPassNft.sol';

pragma solidity 0.8.17;

contract PEXTradingV1 is Initializable {

    // Contracts (constant)
    IStorageT public storageT;
    INftRewards public nftRewards;
    IPEXPairInfos public pairInfos;
    ICallbacks public pexCallbacks;

    // Params (constant)
    uint constant PRECISION = 1e10;

    // Params (adjustable)
    uint public maxPosUsdt;           // eg. 500000 * 1e6
    uint public limitOrdersTimelock;  // block (eg. 30)
    uint public marketOrdersTimeout;  // block (eg. 30)

    // State
    bool public isPaused;  // Prevent opening new trades
    bool public isDone;    // Prevent any interaction with the contract

    // sl tp
    struct PnlLimits {
        uint minTpDist;
        uint maxTpDist;
        uint minSlDist;
        uint maxSlDist;
    }

    // Events
    event Done(bool done);
    event Paused(bool paused);

    event NumberUpdated(string name, uint value);

    event MarketOrderInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        bool open
    );

    event OpenLimitPlaced(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );
    event OpenLimitUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newPrice,
        uint newTp,
        uint newSl
    );
    event OpenLimitCanceled(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event TpUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newTp
    );
    event SlUpdated(
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );
    event SlUpdateInitiated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );

    event NftOrderInitiated(
        uint orderId,
        address indexed nftHolder,
        address indexed trader,
        uint indexed pairIndex
    );
    event NftOrderSameBlock(
        address indexed nftHolder,
        address indexed trader,
        uint indexed pairIndex
    );

    event ChainlinkCallbackTimeout(
        uint indexed orderId,
        IStorageT.PendingMarketOrder order
    );
    event CouldNotCloseTrade(
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    function initialize(
        IStorageT _storageT,
        INftRewards _nftRewards,
        IPEXPairInfos _pairInfos,
        ICallbacks _callbacks,
        uint _maxPosUsdt,
        uint _limitOrdersTimelock,
        uint _marketOrdersTimeout
    ) external initializer {
        require(address(_storageT) != address(0)
            && address(_nftRewards) != address(0)
            && address(_pairInfos) != address(0)
            && address(_callbacks) != address(0)
            && _maxPosUsdt > 0
            && _limitOrdersTimelock > 0
            && _marketOrdersTimeout > 0, "WRONG_PARAMS");

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        pexCallbacks = _callbacks;

        maxPosUsdt = _maxPosUsdt;
        limitOrdersTimelock = _limitOrdersTimelock;
        marketOrdersTimeout = _marketOrdersTimeout;
    }

    // Modifiers
    modifier onlyGov(){
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyEoaOrInternal(){
        require(tx.origin == msg.sender || msg.sender == address(this));
        _;
    }
    modifier notContract(){
        require(tx.origin == msg.sender);
        _;
    }
    modifier notDone(){
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setMaxPosUsdt(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        maxPosUsdt = value;
        
        emit NumberUpdated("maxPosUsdt", value);
    }
    function setLimitOrdersTimelock(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        limitOrdersTimelock = value;
        
        emit NumberUpdated("limitOrdersTimelock", value);
    }
    function setMarketOrdersTimeout(uint value) external onlyGov{
        require(value > 0, "VALUE_0");
        marketOrdersTimeout = value;
        
        emit NumberUpdated("marketOrdersTimeout", value);
    }

    // Manage state
    function pause() external onlyGov{
        isPaused = !isPaused;

        emit Paused(isPaused);
    }
    function done() external onlyGov{
        isDone = !isDone;

        emit Done(isDone);
    }

    // Open new trade (MARKET/LIMIT)
    function openTrade(
        IStorageT.Trade memory t,
        INftRewards.OpenLimitOrderType orderType, // LEGACY => market
        uint slippageP, // for market orders only
        uint monthPassId
    ) external notContract notDone{

        require(!isPaused, "PAUSED");

        IAggregator aggregator = storageT.priceAggregator();
        IPairsStorage pairsStored = aggregator.pairsStorage();

        address sender = msg.sender;

        require(storageT.openTradesCount(sender, t.pairIndex)
            + storageT.pendingMarketOpenCount(sender, t.pairIndex)
            + storageT.openLimitOrdersCount(sender, t.pairIndex)
            < storageT.maxTradesPerPair(), 
            "MAX_TRADES_PER_PAIR");

        require(storageT.pendingOrderIdsCount(sender)
            < storageT.maxPendingMarketOrders(), 
            "MAX_PENDING_ORDERS");

        
        require(t.positionSizeUsdt * t.leverage 
            <= pairsStored.pairMaxLevPosUsdt(t.pairIndex), "ABOVE_MAX_POS");

        require(t.positionSizeUsdt * t.leverage
            >= pairsStored.pairMinLevPosUsdt(t.pairIndex), "BELOW_MIN_POS");

        require(t.leverage > 0 && t.leverage >= pairsStored.pairMinLeverage(t.pairIndex) 
            && t.leverage <= pairsStored.pairMaxLeverage(t.pairIndex), 
            "LEVERAGE_INCORRECT");

        PnlLimits memory pnlLimits;

        pnlLimits.minTpDist = t.openPrice * pexCallbacks.MIN_GAIN_P() / 100 / t.leverage;
        require(t.tp == 0 || (t.buy ?
            t.tp > t.openPrice + pnlLimits.minTpDist :
            t.tp < t.openPrice - pnlLimits.minTpDist), "TP_TOO_SMALL");

        pnlLimits.maxTpDist = t.openPrice * pairsStored.pairMaxGainP(t.pairIndex) / 100 / t.leverage;
        require(t.tp == 0 || (t.buy ? 
            t.tp <= t.openPrice + pnlLimits.maxTpDist :
            t.tp >= t.openPrice - pnlLimits.maxTpDist), "TP_TOO_BIG");

        pnlLimits.minSlDist = t.openPrice * pexCallbacks.MIN_SL_P() / 100 / t.leverage;
        require(t.sl == 0 || (t.buy ?
            t.sl < t.openPrice - pnlLimits.minSlDist:
            t.sl > t.openPrice + pnlLimits.minSlDist), "SL_TOO_SMALL");

        pnlLimits.maxSlDist = t.openPrice * pexCallbacks.MAX_SL_P() / 100 / t.leverage;
        require(t.sl == 0 || (t.buy ? 
            t.sl >= t.openPrice - pnlLimits.maxSlDist :
            t.sl <= t.openPrice + pnlLimits.maxSlDist), "SL_TOO_BIG");

        require(uint(orderType) >= 0 && uint(orderType) <= 1, "WRONG_ORDERTYPE");

        require(pexCallbacks.withinExposureLimits(
            t.pairIndex,
            t.buy,
            t.positionSizeUsdt,
            t.leverage), "OUT_EXPOSURELIMITS");
        
        // check nft used
        IMonthPassNft monthPassNft = storageT.monthPassNft();

        require(monthPassId == 0 
            || (monthPassNft.exists(monthPassId)
            && monthPassNft.isValidTokenId(monthPassId)
            && monthPassNft.isTokenIdExist(monthPassId)), "WRONG_PASSID");

        uint usedNft = 0;
        if(monthPassNft.balanceOf(sender, monthPassId) > 0 && monthPassNft.isUsable(monthPassId)){
            usedNft = 1;
        }

        storageT.transferUsdt(sender, address(storageT), t.positionSizeUsdt);

        if(orderType != INftRewards.OpenLimitOrderType.LEGACY){
            
            storeOpenLimitOrderAndEmit(sender, t, orderType, usedNft);
        }else{
            uint orderId = aggregator.getPrice(
                t.pairIndex, 
                IAggregator.OrderType.MARKET_OPEN, 
                t.positionSizeUsdt * t.leverage
            );

            storeMarketOrderAndEmit(orderId, sender, t, slippageP, usedNft);
        }
    }

    // avoid stack too deep
    function storeOpenLimitOrderAndEmit(
        address sender,
        IStorageT.Trade memory t,
        INftRewards.OpenLimitOrderType orderType,
        uint usedNft
    ) private {
        uint index = storageT.firstEmptyOpenLimitIndex(sender, t.pairIndex);

        storageT.storeOpenLimitOrder(
            IStorageT.OpenLimitOrder(
                sender,
                t.pairIndex,
                index,
                t.positionSizeUsdt,
                0,
                t.buy,
                t.leverage,
                t.tp,
                t.sl,
                t.openPrice,
                t.openPrice,
                block.number,
                usedNft // tokenid, use for nftPass
            )
        );

        nftRewards.setOpenLimitOrderType(sender, t.pairIndex, index, orderType);

        emit OpenLimitPlaced(
            sender,
            t.pairIndex,
            index
        );
    }

    function storeMarketOrderAndEmit(
        uint orderId,
        address sender,
        IStorageT.Trade memory t,
        uint slippageP,
        uint usedNft
    ) private {
        storageT.storePendingMarketOrder(
            IStorageT.PendingMarketOrder(
                IStorageT.Trade(
                    sender,
                    t.pairIndex,
                    0,
                    usedNft,
                    t.positionSizeUsdt,
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
            ), orderId, true
        );

        emit MarketOrderInitiated(
            orderId,
            sender,
            t.pairIndex,
            true
        );
    }

    // Close trade (MARKET)
    function closeTradeMarket(
        uint pairIndex,
        uint index
    ) public onlyEoaOrInternal notDone{

        address sender = msg.sender;

        IStorageT.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        IStorageT.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(storageT.pendingOrderIdsCount(sender)
            < storageT.maxPendingMarketOrders(), "MAX_PENDING_ORDERS");

        require(!i.beingMarketClosed, "ALREADY_BEING_CLOSED");
        require(t.leverage > 0, "NO_TRADE");

        uint orderId = storageT.priceAggregator().getPrice(
            pairIndex, 
            IAggregator.OrderType.MARKET_CLOSE, 
            t.positionSizeUsdt * t.leverage
        );

        storageT.storePendingMarketOrder(
            IStorageT.PendingMarketOrder(
                IStorageT.Trade(
                    sender, pairIndex, index, 0, 0, 0, false, 0, 0, 0
                ),
                0, 0, 0, 0, 0
            ), orderId, false
        );

        emit MarketOrderInitiated(
            orderId,
            sender,
            pairIndex,
            false
        );
    }

    // Manage limit order (OPEN)
    function updateOpenLimitOrder(
        uint pairIndex, 
        uint index, 
        uint price,  // PRECISION
        uint tp,
        uint sl
    ) external notContract notDone{

        address sender = msg.sender;
        IAggregator aggregator = storageT.priceAggregator();
        IPairsStorage pairsStored = aggregator.pairsStorage();

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT");

        IStorageT.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender, pairIndex, index
        );

        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        PnlLimits memory pnlLimits;

        pnlLimits.minTpDist = price * pexCallbacks.MIN_GAIN_P() / 100 / o.leverage;
        require(tp == 0 || (o.buy ?
            tp > price + pnlLimits.minTpDist:
            tp < price - pnlLimits.minTpDist), "TP_TOO_SMALL");
        
        pnlLimits.maxTpDist = price * pairsStored.pairMaxGainP(pairIndex) / 100 / o.leverage;
        require(tp == 0 || (o.buy ? 
            tp <= price + pnlLimits.maxTpDist :
            tp >= price - pnlLimits.maxTpDist), "TP_TOO_BIG");

        pnlLimits.minSlDist = price * pexCallbacks.MIN_SL_P() / 100 / o.leverage;
        require(sl == 0 || (o.buy ?
            sl < price - pnlLimits.minSlDist :
            sl > price + pnlLimits.minSlDist), "SL_TOO_SMALL");

        pnlLimits.maxSlDist = price * pexCallbacks.MAX_SL_P() / 100 / o.leverage;
        require(sl == 0 || (o.buy ? 
            sl >= price - pnlLimits.maxSlDist :
            sl <= price + pnlLimits.maxSlDist), "SL_TOO_BIG");

        o.minPrice = price;
        o.maxPrice = price;

        o.tp = tp;
        o.sl = sl;

        storageT.updateOpenLimitOrder(o);

        emit OpenLimitUpdated(
            sender,
            pairIndex,
            index,
            price,
            tp,
            sl
        );
    }

    function cancelOpenLimitOrder(
        uint pairIndex,
        uint index
    ) external notContract notDone{

        address sender = msg.sender;

        require(storageT.hasOpenLimitOrder(sender, pairIndex, index),
            "NO_LIMIT");

        IStorageT.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
            sender, pairIndex, index
        );

        require(block.number - o.block >= limitOrdersTimelock, "LIMIT_TIMELOCK");

        storageT.unregisterOpenLimitOrder(sender, pairIndex, index);
        storageT.transferUsdt(address(storageT), sender, o.positionSize);

        emit OpenLimitCanceled(
            sender,
            pairIndex,
            index
        );
    }

    // Manage limit order (TP/SL)
    function updateTp(
        uint pairIndex,
        uint index,
        uint newTp
    ) external notContract notDone{

        address sender = msg.sender;
        IAggregator aggregator = storageT.priceAggregator();
        IPairsStorage pairsStored = aggregator.pairsStorage();

        IStorageT.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        IStorageT.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(t.leverage > 0, "NO_TRADE");
        require(block.number - i.tpLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK");

        PnlLimits memory pnlLimits;

        pnlLimits.minTpDist = t.openPrice * pexCallbacks.MIN_GAIN_P() / 100 / t.leverage;
        require(newTp == 0 || (t.buy ?
                newTp > t.openPrice + pnlLimits.minTpDist :
                newTp < t.openPrice - pnlLimits.minTpDist), "TP_TOO_SMALL");

        pnlLimits.maxTpDist = t.openPrice * pairsStored.pairMaxGainP(pairIndex) / 100 / t.leverage;
        require(newTp == 0 || (t.buy ? 
            newTp <= t.openPrice + pnlLimits.maxTpDist :
            newTp >= t.openPrice - pnlLimits.maxTpDist), "TP_TOO_BIG");

        storageT.updateTp(sender, pairIndex, index, newTp);

        emit TpUpdated(
            sender,
            pairIndex,
            index,
            newTp
        );
    }

    function updateSl(
        uint pairIndex,
        uint index,
        uint newSl
    ) external notContract notDone{

        address sender = msg.sender;

        IStorageT.Trade memory t = storageT.openTrades(
            sender, pairIndex, index
        );

        IStorageT.TradeInfo memory i = storageT.openTradesInfo(
            sender, pairIndex, index
        );

        require(t.leverage > 0, "NO_TRADE");

        PnlLimits memory pnlLimits;

        pnlLimits.minSlDist = t.openPrice * pexCallbacks.MIN_SL_P() / 100 / t.leverage;
        require(newSl == 0 || (t.buy ?
                newSl < t.openPrice - pnlLimits.minSlDist :
                newSl > t.openPrice + pnlLimits.minSlDist), "SL_TOO_SMALL");

        uint maxSlDist = t.openPrice * pexCallbacks.MAX_SL_P() / 100 / t.leverage;
        require(newSl == 0 || (t.buy ? 
            newSl >= t.openPrice - maxSlDist :
            newSl <= t.openPrice + maxSlDist), "SL_TOO_BIG");
        
        require(block.number - i.slLastUpdated >= limitOrdersTimelock,
            "LIMIT_TIMELOCK");

        IAggregator aggregator = storageT.priceAggregator();

        if(newSl == 0
        || !aggregator.pairsStorage().guaranteedSlEnabled(pairIndex)){

            storageT.updateSl(sender, pairIndex, index, newSl);

            emit SlUpdated(
                sender,
                pairIndex,
                index,
                newSl
            );

        }else{
            uint orderId = aggregator.getPrice(
                pairIndex,
                IAggregator.OrderType.UPDATE_SL, 
                t.positionSizeUsdt * t.leverage
            );

            aggregator.storePendingSlOrder(
                orderId, 
                IAggregator.PendingSl(
                    sender, pairIndex, index, t.openPrice, t.buy, newSl
                )
            );
            
            emit SlUpdateInitiated(
                orderId,
                sender,
                pairIndex,
                index,
                newSl
            );
        }
    }

    // Execute limit order
    function executeNftOrder(
        IStorageT.LimitOrder orderType, 
        address trader, 
        uint pairIndex, 
        uint index,
        uint nftId
    ) external notContract notDone{

        address sender = msg.sender;

        require(storageT.isBotListed(sender), "NOT_IN_BOTLISTS");

        require(block.number >=
            storageT.nftLastSuccess(nftId) + storageT.nftSuccessTimelock(),
            "SUCCESS_TIMELOCK");

        IStorageT.Trade memory t;

        if(orderType == IStorageT.LimitOrder.OPEN){
            require(storageT.hasOpenLimitOrder(trader, pairIndex, index),
                "NO_LIMIT");

            IStorageT.OpenLimitOrder memory l = storageT.getOpenLimitOrder(
                trader, pairIndex, index
            );
            require(pexCallbacks.withinExposureLimits(
                pairIndex,
                l.buy,
                l.positionSize,
                l.leverage), "OUT_EXPOSURELIMITS");

        }else{
            t = storageT.openTrades(trader, pairIndex, index);

            require(t.leverage > 0, "NO_TRADE");

            if(orderType == IStorageT.LimitOrder.LIQ){
                uint liqPrice = getTradeLiquidationPrice(t);
                
                require(t.sl == 0 || (t.buy ?
                    liqPrice > t.sl :
                    liqPrice < t.sl), "HAS_SL");

            }else{
                require(orderType != IStorageT.LimitOrder.SL || t.sl > 0,
                    "NO_SL");
                require(orderType != IStorageT.LimitOrder.TP || t.tp > 0,
                    "NO_TP");
            }
        }

        INftRewards.TriggeredLimitId memory triggeredLimitId =
            INftRewards.TriggeredLimitId(
                trader, pairIndex, index, orderType
            );

        if(!nftRewards.triggered(triggeredLimitId)
        || nftRewards.timedOut(triggeredLimitId)){
            
            uint leveragedPosUsdt;

            if(orderType == IStorageT.LimitOrder.OPEN){

                IStorageT.OpenLimitOrder memory l = storageT.getOpenLimitOrder(
                    trader, pairIndex, index
                );

                leveragedPosUsdt = l.positionSize * l.leverage;

                /*
                (uint priceImpactP, ) = pairInfos.getTradePriceImpact(
                    0,
                    l.pairIndex,
                    l.buy,
                    leveragedPosUsdt
                );
                
                require(priceImpactP * l.leverage <= pairInfos.maxNegativePnlOnOpenP(),
                    "PRICE_IMPACT_TOO_HIGH");
                */

            }else{
                leveragedPosUsdt = t.positionSizeUsdt * t.leverage;
            }

            storageT.transferLinkToAggregator(sender, pairIndex, leveragedPosUsdt);

            uint orderId = storageT.priceAggregator().getPrice(
                pairIndex, 
                orderType == IStorageT.LimitOrder.OPEN ? 
                    IAggregator.OrderType.LIMIT_OPEN : 
                    IAggregator.OrderType.LIMIT_CLOSE,
                leveragedPosUsdt
            );

            storageT.storePendingNftOrder(
                IStorageT.PendingNftOrder(
                    sender,
                    nftId,
                    trader,
                    pairIndex,
                    index,
                    orderType
                ), orderId
            );

            nftRewards.storeFirstToTrigger(triggeredLimitId, sender);
            
            emit NftOrderInitiated(
                orderId,
                sender,
                trader,
                pairIndex
            );

        }else{
            nftRewards.storeTriggerSameBlock(triggeredLimitId, sender);
            
            emit NftOrderSameBlock(
                sender,
                trader,
                pairIndex
            );
        }
    }
    // Avoid stack too deep error in executeNftOrder
    function getTradeLiquidationPrice(
        IStorageT.Trade memory t
    ) private view returns(uint){
        return pairInfos.getTradeLiquidationPrice(
            t.trader,
            t.pairIndex,
            t.index,
            t.openPrice,
            t.buy,
            t.positionSizeUsdt,
            t.leverage
        );
    }

    // Market timeout
    function openTradeMarketTimeout(uint _order) external notContract notDone{
        address sender = msg.sender;

        IStorageT.PendingMarketOrder memory o =
            storageT.reqID_pendingMarketOrder(_order);

        IStorageT.Trade memory t = o.trade;

        require(o.block > 0
            && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage > 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, true);
        storageT.transferUsdt(address(storageT), sender, t.positionSizeUsdt);

        emit ChainlinkCallbackTimeout(
            _order,
            o
        );
    }
    
    function closeTradeMarketTimeout(uint _order) external notContract notDone{
        address sender = msg.sender;

        IStorageT.PendingMarketOrder memory o =
            storageT.reqID_pendingMarketOrder(_order);

        IStorageT.Trade memory t = o.trade;

        require(o.block > 0
            && block.number >= o.block + marketOrdersTimeout, "WAIT_TIMEOUT");

        require(t.trader == sender, "NOT_YOUR_ORDER");
        require(t.leverage == 0, "WRONG_MARKET_ORDER_TYPE");

        storageT.unregisterPendingMarketOrder(_order, false);

        closeTradeMarket(t.pairIndex, t.index);

        emit ChainlinkCallbackTimeout(
            _order,
            o
        );
    }
}