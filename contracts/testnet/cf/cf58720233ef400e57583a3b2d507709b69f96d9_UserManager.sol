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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IController {
    /* ========== EVENTS ========== */

    event TradePairAdded(address indexed tradePair);

    event LiquidityPoolAdded(address indexed liquidityPool);

    event LiquidityPoolAdapterAdded(address indexed liquidityPoolAdapter);

    event PriceFeedAdded(address indexed priceFeed);

    event UpdatableAdded(address indexed updatable);

    event TradePairRemoved(address indexed tradePair);

    event LiquidityPoolRemoved(address indexed liquidityPool);

    event LiquidityPoolAdapterRemoved(address indexed liquidityPoolAdapter);

    event PriceFeedRemoved(address indexed priceFeed);

    event UpdatableRemoved(address indexed updatable);

    event SignerAdded(address indexed signer);

    event SignerRemoved(address indexed signer);

    event OrderExecutorAdded(address indexed orderExecutor);

    event OrderExecutorRemoved(address indexed orderExecutor);

    event SetOrderRewardOfCollateral(address indexed collateral_, uint256 reward_);

    /* ========== VIEW FUNCTIONS ========== */

    /// @notice Is trade pair registered
    function isTradePair(address tradePair) external view returns (bool);

    /// @notice Is liquidity pool registered
    function isLiquidityPool(address liquidityPool) external view returns (bool);

    /// @notice Is liquidity pool adapter registered
    function isLiquidityPoolAdapter(address liquidityPoolAdapter) external view returns (bool);

    /// @notice Is price fee adapter registered
    function isPriceFeed(address priceFeed) external view returns (bool);

    /// @notice Is contract updatable
    function isUpdatable(address contractAddress) external view returns (bool);

    /// @notice Is Signer registered
    function isSigner(address signer) external view returns (bool);

    /// @notice Is order executor registered
    function isOrderExecutor(address orderExecutor) external view returns (bool);

    /// @notice Reverts if trade pair inactive
    function checkTradePairActive(address tradePair) external view;

    /// @notice Returns order reward for collateral token
    function orderRewardOfCollateral(address collateral) external view returns (uint256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Adds the trade pair to the registry
     */
    function addTradePair(address tradePair) external;

    /**
     * @notice Adds the liquidity pool to the registry
     */
    function addLiquidityPool(address liquidityPool) external;

    /**
     * @notice Adds the liquidity pool adapter to the registry
     */
    function addLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Adds the price feed to the registry
     */
    function addPriceFeed(address priceFeed) external;

    /**
     * @notice Adds updatable contract to the registry
     */
    function addUpdatable(address) external;

    /**
     * @notice Adds signer to the registry
     */
    function addSigner(address) external;

    /**
     * @notice Adds order executor to the registry
     */
    function addOrderExecutor(address) external;

    /**
     * @notice Removes the trade pair from the registry
     */
    function removeTradePair(address tradePair) external;

    /**
     * @notice Removes the liquidity pool from the registry
     */
    function removeLiquidityPool(address liquidityPool) external;

    /**
     * @notice Removes the liquidity pool adapter from the registry
     */
    function removeLiquidityPoolAdapter(address liquidityPoolAdapter) external;

    /**
     * @notice Removes the price feed from the registry
     */
    function removePriceFeed(address priceFeed) external;

    /**
     * @notice Removes updatable from the registry
     */
    function removeUpdatable(address) external;

    /**
     * @notice Removes signer from the registry
     */
    function removeSigner(address) external;

    /**
     * @notice Removes order executor from the registry
     */
    function removeOrderExecutor(address) external;

    /**
     * @notice Sets order reward for collateral token
     */
    function setOrderRewardOfCollateral(address, uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

interface IFeeManager {
    /* ========== EVENTS ============ */

    event ReferrerFeesPaid(address indexed referrer, address indexed asset, uint256 amount, address user);

    event WhiteLabelFeesPaid(address indexed whitelabel, address indexed asset, uint256 amount, address user);

    event UpdatedReferralFee(uint256 newReferrerFee);

    event UpdatedStakersFeeAddress(address stakersFeeAddress);

    event UpdatedDevFeeAddress(address devFeeAddress);

    event UpdatedInsuranceFundFeeAddress(address insuranceFundFeeAddress);

    event SetWhitelabelFee(address indexed whitelabelAddress, uint256 feeSize);

    event SetCustomReferralFee(address indexed referrer, uint256 feeSize);

    event SpreadFees(
        address asset,
        uint256 stakersFeeAmount,
        uint256 devFeeAmount,
        uint256 insuranceFundFeeAmount,
        uint256 liquidityPoolFeeAmount,
        address user
    );

    /* ========== CORE FUNCTIONS ========== */

    function depositOpenFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositCloseFees(address user, address asset, uint256 amount, address whitelabelAddress) external;

    function depositBorrowFees(address asset, uint256 amount) external;

    /* ========== VIEW FUNCTIONS ========== */

    function calculateUserOpenFeeAmount(address user, uint256 amount) external view returns (uint256);

    function calculateUserOpenFeeAmount(address user, uint256 amount, uint256 leverage)
        external
        view
        returns (uint256);

    function calculateUserExtendToLeverageFeeAmount(
        address user,
        uint256 margin,
        uint256 volume,
        uint256 targetLeverage
    ) external view returns (uint256);

    function calculateUserCloseFeeAmount(address user, uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

struct LiquidityPoolConfig {
    address poolAddress;
    uint96 percentage;
}

interface ILiquidityPoolAdapter {
    /* ========== EVENTS ========== */

    event PayedOutLoss(address indexed tradePair, uint256 loss);

    event DepositedProfit(address indexed tradePair, uint256 profit);

    event UpdatedMaxPayoutProportion(uint256 maxPayoutProportion);

    event UpdatedLiquidityPools(LiquidityPoolConfig[] liquidityPools);

    /* ========== CORE FUNCTIONS ========== */

    function requestLossPayout(uint256 profit) external returns (uint256);

    function depositProfit(uint256 profit) external;

    function depositFees(uint256 fee) external;

    /* ========== VIEW FUNCTIONS ========== */

    function availableLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IPriceFeed
 * @notice Gets the last and previous price of an asset from a price feed
 * @dev The price must be returned with 8 decimals, following the USD convention
 */
interface IPriceFeed {
    /* ========== VIEW FUNCTIONS ========== */

    function price() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../interfaces/IPriceFeedAggregator.sol";

/**
 * @title IPriceFeedAdapter
 * @notice Provides a way to convert an asset amount to a collateral amount and vice versa
 * Needs two PriceFeedAggregators: One for asset and one for collateral
 */
interface IPriceFeedAdapter {
    function name() external view returns (string memory);

    /* ============ DECIMALS ============ */

    function collateralDecimals() external view returns (uint256);

    /* ============ ASSET - COLLATERAL CONVERSION ============ */

    function collateralToAssetMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToAssetMax(uint256 collateralAmount) external view returns (uint256);

    function assetToCollateralMin(uint256 assetAmount) external view returns (uint256);

    function assetToCollateralMax(uint256 assetAmount) external view returns (uint256);

    /* ============ USD Conversion ============ */

    function assetToUsdMin(uint256 assetAmount) external view returns (uint256);

    function assetToUsdMax(uint256 assetAmount) external view returns (uint256);

    function collateralToUsdMin(uint256 collateralAmount) external view returns (uint256);

    function collateralToUsdMax(uint256 collateralAmount) external view returns (uint256);

    /* ============ PRICE ============ */

    function markPriceMin() external view returns (int256);

    function markPriceMax() external view returns (int256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IPriceFeed.sol";

/**
 * @title IPriceFeedAggregator
 * @notice Aggreates two or more price feeds into min and max prices
 */
interface IPriceFeedAggregator {
    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function minPrice() external view returns (int256);

    function maxPrice() external view returns (int256);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addPriceFeed(IPriceFeed) external;

    function removePriceFeed(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "../interfaces/IController.sol";
import "../interfaces/ITradePair.sol";
import "../interfaces/IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Parameters for opening a position
 * @custom:member tradePair The trade pair to open the position on
 * @custom:member margin The amount of margin to use for the position
 * @custom:member leverage The leverage to open the position with
 * @custom:member isShort Whether the position is a short position
 * @custom:member referrer The address of the referrer or zero
 * @custom:member whitelabelAddress The address of the whitelabel or zero
 */
struct OpenPositionParams {
    address tradePair;
    uint256 margin;
    uint256 leverage;
    bool isShort;
    address referrer;
    address whitelabelAddress;
}

/**
 * @notice Parameters for closing a position
 * @custom:member tradePair The trade pair to close the position on
 * @custom:member positionId The id of the position to close
 */
struct ClosePositionParams {
    address tradePair;
    uint256 positionId;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member proportion the proportion of the position to close
 * @custom:member leaveLeverageFactor the leaveLeverage / takeProfit factor
 */
struct PartiallyClosePositionParams {
    address tradePair;
    uint256 positionId;
    uint256 proportion;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member tradePair The trade pair to add margin to
 * @custom:member positionId The id of the position to add margin to
 * @custom:member removedMargin The amount of margin to remove
 */
struct RemoveMarginFromPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 removedMargin;
}

/**
 * @notice Parameters for adding margin to a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 */
struct AddMarginToPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
}

/**
 * @notice Parameters for extending a position
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member addedMargin The amount of margin to add
 * @custom:member addedLeverage The leverage used on the addedMargin
 */
struct ExtendPositionParams {
    address tradePair;
    uint256 positionId;
    uint256 addedMargin;
    uint256 addedLeverage;
}

/**
 * @notice Parameters for extending a position to a target leverage
 * @custom:member tradePair The trade pair to add margin to the position on
 * @custom:member positionId The id of the position to add margin to
 * @custom:member targetLeverage the target leverage to close to
 */
struct ExtendPositionToLeverageParams {
    address tradePair;
    uint256 positionId;
    uint256 targetLeverage;
}

/**
 * @notice Constraints to constraint the opening, alteration or closing of a position
 * @custom:member deadline The deadline for the transaction
 * @custom:member minPrice a minimum price for the transaction
 * @custom:member maxPrice a maximum price for the transaction
 */
struct Constraints {
    uint256 deadline;
    int256 minPrice;
    int256 maxPrice;
}

/**
 * @notice Parameters for opening a position
 * @custom:member params The parameters for opening a position
 * @custom:member constraints The constraints for opening a position
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct OpenPositionOrder {
    OpenPositionParams params;
    Constraints constraints;
    uint256 salt;
}

/**
 * @notice Parameters for closing a position
 * @custom:member params The parameters for closing a position
 * @custom:member constraints The constraints for closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ClosePositionOrder {
    ClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for partially closing a position
 * @custom:member params The parameters for partially closing a position
 * @custom:member constraints The constraints for partially closing a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct PartiallyClosePositionOrder {
    PartiallyClosePositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position
 * @custom:member params The parameters for extending a position
 * @custom:member constraints The constraints for extending a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionOrder {
    ExtendPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for extending a position to leverage
 * @custom:member params The parameters for extending a position to leverage
 * @custom:member constraints The constraints for extending a position to leverage
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct ExtendPositionToLeverageOrder {
    ExtendPositionToLeverageParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters foradding margin to a position
 * @custom:member params The parameters foradding margin to a position
 * @custom:member constraints The constraints foradding margin to a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct AddMarginToPositionOrder {
    AddMarginToPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice Parameters for removing margin from a position
 * @custom:member params The parameters for removing margin from a position
 * @custom:member constraints The constraints for removing margin from a position
 * @custom:member signatureHash The signatureHash of the open position order, when this is an automated order
 * @custom:member salt Salt to ensure uniqueness of signed message
 */
struct RemoveMarginFromPositionOrder {
    RemoveMarginFromPositionParams params;
    Constraints constraints;
    bytes32 signatureHash;
    uint256 salt;
}

/**
 * @notice UpdateData for updatable contracts like the UnlimitedPriceFeed
 * @custom:member updatableContract The address of the updatable contract
 * @custom:member data The data to update the contract with
 */
struct UpdateData {
    address updatableContract;
    bytes data;
}

/**
 * @notice Struct to store tradePair and positionId together.
 * @custom:member tradePair the address of the tradePair
 * @custom:member positionId the positionId of the position
 */
struct TradeId {
    address tradePair;
    uint96 positionId;
}

interface ITradeManager {
    /* ========== EVENTS ========== */

    event PositionOpened(address indexed tradePair, uint256 indexed id);

    event PositionClosed(address indexed tradePair, uint256 indexed id);

    event PositionPartiallyClosed(address indexed tradePair, uint256 indexed id, uint256 proportion);

    event PositionLiquidated(address indexed tradePair, uint256 indexed id);

    event PositionExtended(address indexed tradePair, uint256 indexed id, uint256 addedMargin, uint256 addedLeverage);

    event PositionExtendedToLeverage(address indexed tradePair, uint256 indexed id, uint256 targetLeverage);

    event MarginAddedToPosition(address indexed tradePair, uint256 indexed id, uint256 addedMargin);

    event MarginRemovedFromPosition(address indexed tradePair, uint256 indexed id, uint256 removedMargin);

    /* ========== CORE FUNCTIONS - LIQUIDATIONS ========== */

    function liquidatePosition(address tradePair, uint256 positionId, UpdateData[] calldata updateData) external;

    function batchLiquidatePositions(
        address[] calldata tradePairs,
        uint256[][] calldata positionIds,
        bool allowRevert,
        UpdateData[] calldata updateData
    ) external returns (bool[][] memory didLiquidate);

    /* =========== VIEW FUNCTIONS ========== */

    function detailsOfPosition(address tradePair, uint256 positionId) external view returns (PositionDetails memory);

    function positionIsLiquidatable(address tradePair, uint256 positionId) external view returns (bool);

    function canLiquidatePositions(address[] calldata tradePairs, uint256[][] calldata positionIds)
        external
        view
        returns (bool[][] memory canLiquidate);

    function canLiquidatePositionsAtPrices(
        address[] calldata tradePairs_,
        uint256[][] calldata positionIds_,
        int256[] calldata prices_
    ) external view returns (bool[][] memory canLiquidate);

    function getCurrentFundingFeeRates(address tradePair) external view returns (int256, int256);

    function totalVolumeLimitOfTradePair(address tradePair_) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IFeeManager.sol";
import "./ILiquidityPoolAdapter.sol";
import "./IPriceFeedAdapter.sol";
import "./ITradeManager.sol";
import "./IUserManager.sol";

// =============================================================
//                           STRUCTS
// =============================================================

/**
 * @notice Struct with details of a position, returned by the detailsOfPosition function
 * @custom:member id the position id
 * @custom:member margin the margin of the position
 * @custom:member volume the entry volume of the position
 * @custom:member size the size of the position
 * @custom:member leverage the size of the position
 * @custom:member isShort bool if the position is short
 * @custom:member entryPrice The entry price of the position
 * @custom:member markPrice The (current) mark price of the position
 * @custom:member bankruptcyPrice the bankruptcy price of the position
 * @custom:member equity the current net equity of the position
 * @custom:member PnL the current net PnL of the position
 * @custom:member totalFeeAmount the totalFeeAmount of the position
 * @custom:member currentVolume the current volume of the position
 */
struct PositionDetails {
    uint256 id;
    uint256 margin;
    uint256 volume;
    uint256 assetAmount;
    uint256 leverage;
    bool isShort;
    int256 entryPrice;
    int256 liquidationPrice;
    int256 totalFeeAmount;
}

/**
 * @notice Struct with a minimum and maximum price
 * @custom:member minPrice the minimum price
 * @custom:member maxPrice the maximum price
 */
struct PricePair {
    int256 minPrice;
    int256 maxPrice;
}

interface ITradePair {
    /* ========== ENUMS ========== */

    enum PositionAlterationType {
        partiallyClose,
        extend,
        extendToLeverage,
        removeMargin,
        addMargin
    }

    /* ========== EVENTS ========== */

    event OpenedPosition(address maker, uint256 id, uint256 margin, uint256 volume, uint256 size, bool isShort);

    event ClosedPosition(uint256 id, int256 closePrice);

    event LiquidatedPosition(uint256 indexed id, address indexed liquidator);

    event AlteredPosition(
        PositionAlterationType alterationType, uint256 id, uint256 netMargin, uint256 volume, uint256 size
    );

    event UpdatedFeesOfPosition(uint256 id, int256 totalFeeAmount, uint256 lastNetMargin);

    event DepositedOpenFees(address user, uint256 amount, uint256 positionId);

    event DepositedCloseFees(address user, uint256 amount, uint256 positionId);

    event FeeOvercollected(int256 amount);

    event PayedOutCollateral(address maker, uint256 amount, uint256 positionId);

    event LiquidityGapWarning(uint256 amount);

    event RealizedPnL(address indexed maker, uint256 indexed positionId, int256 realizedPnL);

    event UpdatedFeeIntegrals(int256 borrowFeeIntegral, int256 longFundingFeeIntegral, int256 shortFundingFeeIntegral);

    event SetTotalVolumeLimit(uint256 totalVolumeLimit);

    event DepositedBorrowFees(uint256 amount);

    event RegisteredProtocolPnL(int256 protocolPnL, uint256 payout);

    event SetBorrowFeeRate(int256 borrowFeeRate);

    event SetMaxFundingFeeRate(int256 maxFundingFeeRate);

    event SetMaxExcessRatio(int256 maxExcessRatio);

    event SetLiquidatorReward(uint256 liquidatorReward);

    event SetMinLeverage(uint128 minLeverage);

    event SetMaxLeverage(uint128 maxLeverage);

    event SetMinMargin(uint256 minMargin);

    event SetVolumeLimit(uint256 volumeLimit);

    event SetFeeBufferFactor(int256 feeBufferFactor);

    event SetTotalAssetAmountLimit(uint256 totalAssetAmountLimit);

    event SetPriceFeedAdapter(address priceFeedAdapter);

    /* ========== VIEW FUNCTIONS ========== */

    function name() external view returns (string memory);

    function collateral() external view returns (IERC20);

    function detailsOfPosition(uint256 positionId) external view returns (PositionDetails memory);

    function priceFeedAdapter() external view returns (IPriceFeedAdapter);

    function liquidityPoolAdapter() external view returns (ILiquidityPoolAdapter);

    function userManager() external view returns (IUserManager);

    function feeManager() external view returns (IFeeManager);

    function tradeManager() external view returns (ITradeManager);

    function positionIsLiquidatable(uint256 positionId) external view returns (bool);

    function positionIsLiquidatableAtPrice(uint256 positionId, int256 price) external view returns (bool);

    function getCurrentFundingFeeRates() external view returns (int256, int256);

    function getCurrentPrices() external view returns (int256, int256);

    function positionIsShort(uint256) external view returns (bool);

    function collateralToPriceMultiplier() external view returns (uint256);

    /* ========== GENERATED VIEW FUNCTIONS ========== */

    function feeIntegral() external view returns (int256, int256, int256, int256, int256, int256, uint256);

    function liquidatorReward() external view returns (uint256);

    function maxLeverage() external view returns (uint128);

    function minLeverage() external view returns (uint128);

    function minMargin() external view returns (uint256);

    function volumeLimit() external view returns (uint256);

    function totalVolumeLimit() external view returns (uint256);

    function positionStats() external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function overcollectedFees() external view returns (int256);

    function feeBuffer() external view returns (int256, int256);

    function positionIdToWhiteLabel(uint256) external view returns (address);

    /* ========== CORE FUNCTIONS - POSITIONS ========== */

    function openPosition(address maker, uint256 margin, uint256 leverage, bool isShort, address whitelabelAddress)
        external
        returns (uint256 positionId);

    function closePosition(address maker, uint256 positionId) external;

    function addMarginToPosition(address maker, uint256 positionId, uint256 margin) external;

    function removeMarginFromPosition(address maker, uint256 positionId, uint256 removedMargin) external;

    function partiallyClosePosition(address maker, uint256 positionId, uint256 proportion) external;

    function extendPosition(address maker, uint256 positionId, uint256 addedMargin, uint256 addedLeverage) external;

    function extendPositionToLeverage(address maker, uint256 positionId, uint256 targetLeverage) external;

    function liquidatePosition(address liquidator, uint256 positionId) external;

    /* ========== CORE FUNCTIONS - FEES ========== */

    function syncPositionFees() external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initialize(
        string memory name,
        IERC20Metadata collateral,
        IPriceFeedAdapter priceFeedAdapter,
        ILiquidityPoolAdapter liquidityPoolAdapter
    ) external;

    function setBorrowFeeRate(int256 borrowFeeRate) external;

    function setMaxFundingFeeRate(int256 fee) external;

    function setMaxExcessRatio(int256 maxExcessRatio) external;

    function setLiquidatorReward(uint256 liquidatorReward) external;

    function setMinLeverage(uint128 minLeverage) external;

    function setMaxLeverage(uint128 maxLeverage) external;

    function setMinMargin(uint256 minMargin) external;

    function setVolumeLimit(uint256 volumeLimit) external;

    function setFeeBufferFactor(int256 feeBufferAmount) external;

    function setTotalVolumeLimit(uint256 totalVolumeLimit) external;

    function setPriceFeedAdapter(IPriceFeedAdapter priceFeedAdapter) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IUnlimitedOwner
 */
interface IUnlimitedOwner {
    function owner() external view returns (address);

    function isUnlimitedOwner(address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/// @notice Enum for the different fee tiers
enum Tier {
    ZERO,
    ONE,
    TWO,
    THREE,
    FOUR,
    FIVE,
    SIX
}

interface IUserManager {
    /* ========== EVENTS ========== */

    event FeeSizeUpdated(uint256 indexed feeIndex, uint256 feeSize);

    event FeeVolumeUpdated(uint256 indexed feeIndex, uint256 feeVolume);

    event UserVolumeAdded(address indexed user, address indexed tradePair, uint256 volume);

    event UserManualTierUpdated(address indexed user, Tier tier, uint256 validUntil);

    event UserReferrerAdded(address indexed user, address referrer);

    /* =========== CORE FUNCTIONS =========== */

    function addUserVolume(address user, uint40 volume) external;

    function setUserReferrer(address user, address referrer) external;

    function setUserManualTier(address user, Tier tier, uint32 validUntil) external;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes) external;

    function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes) external;

    /* ========== VIEW FUNCTIONS ========== */

    function getUserFee(address user) external view returns (uint256);

    function getUserReferrer(address user) external view returns (address referrer);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "../interfaces/IUnlimitedOwner.sol";

/// @title Logic to help check whether the caller is the Unlimited owner
abstract contract UnlimitedOwnable {
    /* ========== STATE VARIABLES ========== */

    /// @notice Contract that holds the address of Unlimited owner
    IUnlimitedOwner public immutable unlimitedOwner;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets correct initial values
     * @param _unlimitedOwner Unlimited owner contract address
     */
    constructor(IUnlimitedOwner _unlimitedOwner) {
        require(
            address(_unlimitedOwner) != address(0),
            "UnlimitedOwnable::constructor: Unlimited owner contract address cannot be 0"
        );

        unlimitedOwner = _unlimitedOwner;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Checks if caller is Unlimited owner
     * @return True if caller is Unlimited owner, false otherwise
     */
    function isUnlimitedOwner() internal view returns (bool) {
        return unlimitedOwner.isUnlimitedOwner(msg.sender);
    }

    /// @notice Checks and throws if caller is not Unlimited owner
    function _onlyOwner() private view {
        require(isUnlimitedOwner(), "UnlimitedOwnable::_onlyOwner: Caller is not the Unlimited owner");
    }

    /// @notice Checks and throws if caller is not Unlimited owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IController.sol";
import "../interfaces/ITradeManager.sol";
import "../interfaces/IUserManager.sol";
import "../shared/UnlimitedOwnable.sol";

/**
 * @custom:member Struct to store the daily volumes of a user. Packed in 40-bit words to optimize storage.
 * @custom:member zero word 1
 * @custom:member one word 2
 * @custom:member two word 3
 * @custom:member three word 4
 * @custom:member four word 5
 * @custom:member five word 6
 */
struct DailyVolumes {
    uint40 zero;
    uint40 one;
    uint40 two;
    uint40 three;
    uint40 four;
    uint40 five;
}

/**
 * @notice Struct to store the volume limits to reach a new fee tier
 * @custom:member volume 1 The volume limit to reach the first fee tier.
 * @custom:member volume 2 The volume limit to reach the second fee tier.
 * @custom:member volume 3 The volume limit to reach the third fee tier.
 * @custom:member volume 4 The volume limit to reach the fourth fee tier.
 * @custom:member volume 5 The volume limit to reach the fifth fee tier.
 * @custom:member volume 6 The volume limit to reach the sixth fee tier.
 */
struct FeeVolumes {
    uint40 volume1;
    uint40 volume2;
    uint40 volume3;
    uint40 volume4;
    uint40 volume5;
    uint40 volume6;
}

/**
 * @notice Struct to store the fee sizes for each fee tier
 *
 * @custom:member baseFee The base fee for the base fee tier.
 * @custom:member fee1 The fee size for the first fee tier.
 * @custom:member fee2 The fee size for the second fee tier.
 * @custom:member fee3 The fee size for the third fee tier.
 * @custom:member fee4 The fee size for the fourth fee tier.
 * @custom:member fee5 The fee size for the fifth fee tier.
 * @custom:member fee6 The fee size for the sixth fee tier.
 */
struct FeeSizes {
    uint8 baseFee;
    uint8 fee1;
    uint8 fee2;
    uint8 fee3;
    uint8 fee4;
    uint8 fee5;
    uint8 fee6;
}

/**
 * @notice Struct to store the fee tiers of a specific user individually
 * @custom:member tier the tier of the user
 * @custom:member validUntil the timestamp until the tier is valid
 */
struct ManualUserTier {
    Tier tier;
    uint32 validUntil;
}

contract UserManager is IUserManager, UnlimitedOwnable, Initializable {
    /* ========== CONSTANTS ========== */

    /// @notice Maximum fee size that can be set is 1%. 0.01% - 1%
    uint256 private constant MAX_FEE_SIZE = 1_00;

    /// @notice Defines number of days in a `DailyVolumes` struct.
    uint256 public constant DAYS_IN_WORD = 6;

    /// @notice This address is used when the user has no referrer
    address private constant NO_REFERRER_ADDRESS = address(type(uint160).max);

    /* ========== STATE VARIABLES ========== */

    /// @notice Controller contract.
    IController public immutable controller;

    /// @notice TradeManager contract.
    ITradeManager public immutable tradeManager;

    /// @notice Contains user traded volume for each day.
    mapping(address => mapping(uint256 => DailyVolumes)) public userDailyVolumes;

    /// @notice Defines mannualy set tier for a user.
    mapping(address => ManualUserTier) public manualUserTiers;

    /// @notice User referrer.
    mapping(address => address) private _userReferrer;

    /// @notice Defines fee size for volume.
    FeeSizes public feeSizes;

    /// @notice Defines volume for each tier.
    FeeVolumes public feeVolumes;

    // Storage gap
    uint256[50] __gap;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the UserManager contract.
     *
     * @param unlimitedOwner_ Unlimited owner contract.
     * @param controller_ Controller contract.
     */
    constructor(IUnlimitedOwner unlimitedOwner_, IController controller_, ITradeManager tradeManager_)
        UnlimitedOwnable(unlimitedOwner_)
    {
        controller = controller_;
        tradeManager = tradeManager_;
    }

    /**
     * @notice Initializes the data.
     */
    function initialize(uint8[7] memory feeSizes_, uint32[6] memory feeVolumes_) public onlyOwner initializer {
        require(feeSizes_.length == 7, "UserManager::initialize: Bad fee sizes array length");
        require(feeVolumes_.length == 6, "UserManager::initialize: Bad fee volumes array length");

        _setFeeSize(0, feeSizes_[0]);

        for (uint256 i; i < feeVolumes_.length; ++i) {
            _setFeeVolume(i + 1, feeVolumes_[i]);
            _setFeeSize(i + 1, feeSizes_[i + 1]);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice Gets users open and close position fee.
     * @dev The fee is based on users last 30 day volume.
     *
     * @param user_ user address
     * @return fee size in BPS
     */
    function getUserFee(address user_) external view returns (uint256) {
        Tier userTier = getUserTier(user_);

        FeeSizes memory _feeSizes = feeSizes;
        uint256 userFee;

        if (userTier == Tier.ZERO) {
            userFee = _feeSizes.baseFee;
        } else {
            if (userTier == Tier.ONE) {
                userFee = _feeSizes.fee1;
            } else if (userTier == Tier.TWO) {
                userFee = _feeSizes.fee2;
            } else if (userTier == Tier.THREE) {
                userFee = _feeSizes.fee3;
            } else if (userTier == Tier.FOUR) {
                userFee = _feeSizes.fee4;
            } else if (userTier == Tier.FIVE) {
                userFee = _feeSizes.fee5;
            } else {
                userFee = _feeSizes.fee6;
            }

            // if base fee is lower, use base fee (e.g. if there is a discount on fee)
            if (userFee > _feeSizes.baseFee) {
                userFee = _feeSizes.baseFee;
            }
        }

        return userFee;
    }

    /**
     * @notice Gets users fee tier.
     * @dev The fee is the bigger tier of the volume tier or manualy set one.
     *
     * @param user_ user address
     * @return userTier fee tier of the user
     */
    function getUserTier(address user_) public view returns (Tier userTier) {
        userTier = getUserVolumeTier(user_);
        Tier userManualTier = getUserManualTier(user_);

        if (userTier < userManualTier) {
            userTier = userManualTier;
        }
    }

    /**
     * @notice Gets users fee tier based on volume.
     * @dev The fee is based on users last 30 day volume.
     *
     * @param user_ user address
     * @return Tier fee tier of the user
     */
    function getUserVolumeTier(address user_) public view returns (Tier) {
        uint256 user30dayVolume = getUser30DaysVolume(user_);

        FeeVolumes memory _feeVolumes = feeVolumes;

        if (user30dayVolume < _feeVolumes.volume1) {
            return Tier.ZERO;
        }

        if (user30dayVolume < _feeVolumes.volume2) {
            return Tier.ONE;
        }

        if (user30dayVolume < _feeVolumes.volume3) {
            return Tier.TWO;
        }

        if (user30dayVolume < _feeVolumes.volume4) {
            return Tier.THREE;
        }

        if (user30dayVolume < _feeVolumes.volume5) {
            return Tier.FOUR;
        }

        if (user30dayVolume < _feeVolumes.volume6) {
            return Tier.FIVE;
        }

        return Tier.SIX;
    }

    /**
     * @notice Gets users fee manual tier.
     *
     * @param user_ user address
     * @return Tier fee tier of the user
     */
    function getUserManualTier(address user_) public view returns (Tier) {
        if (manualUserTiers[user_].validUntil >= block.timestamp) {
            return manualUserTiers[user_].tier;
        } else {
            return Tier.ZERO;
        }
    }

    /**
     * @notice Gets users last 30 days traded volume.
     *
     * @param user_ user address
     * @return user30dayVolume users last 30 days volume
     */
    function getUser30DaysVolume(address user_) public view returns (uint256 user30dayVolume) {
        for (uint256 i; i < 30; ++i) {
            (uint256 index, uint256 position) = _getPastIndexAndPosition(i);
            uint256 userDailyVolume = _getUserDailyVolume(user_, index, position);

            unchecked {
                user30dayVolume += userDailyVolume;
            }
        }
    }

    /**
     * @notice Gets the referrer of the user.
     *
     * @param user_ user address
     * @return referrer adress of the refererrer
     */
    function getUserReferrer(address user_) external view returns (address referrer) {
        referrer = _userReferrer[user_];

        if (referrer == NO_REFERRER_ADDRESS) {
            referrer = address(0);
        }
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Sets the referrer of the user. Referrer can only be set once. Of referrer is null, the user will be set
     * to NO_REFERRER_ADDRESS.
     *
     * @param user_ address of the user
     * @param referrer_ address of the referrer
     */
    function setUserReferrer(address user_, address referrer_) external onlyTradeManager {
        require(user_ != referrer_, "UserManager::setUserReferrer: User cannot be referrer");
        if (_userReferrer[user_] == address(0)) {
            if (referrer_ == address(0)) {
                _userReferrer[user_] = NO_REFERRER_ADDRESS;
            } else {
                _userReferrer[user_] = referrer_;
            }

            emit UserReferrerAdded(user_, referrer_);
        }
    }

    /**
     * @notice Adds user volume to total daily traded when new position is open.
     * @dev
     *
     * Requirements:
     * - The caller must be a valid trade pair
     *
     * @param user_ user address
     * @param volume_ volume to add
     */
    function addUserVolume(address user_, uint40 volume_) external onlyValidTradePair(msg.sender) {
        (uint256 index, uint256 position) = _getTodaysIndexAndPosition();
        _addUserDailyVolume(user_, index, position, volume_);

        emit UserVolumeAdded(user_, msg.sender, volume_);
    }

    /**
     * @notice Sets users manual tier including valid time.
     * @dev
     *
     * Requirements:
     * - The caller must be a controller
     *
     * @param user user address
     * @param tier tier to set
     * @param validUntil unix time when the manual tier expires
     */
    function setUserManualTier(address user, Tier tier, uint32 validUntil) external onlyOwner {
        manualUserTiers[user] = ManualUserTier(tier, validUntil);

        emit UserManualTierUpdated(user, tier, validUntil);
    }

    /**
     * @notice Sets fee sizes for a tier.
     * @dev
     * `feeIndexes` start with 0 as the base fee and increase by 1 for each tier.
     *
     * Requirements:
     * - The caller must be a controller
     * - `feeIndexes` and `feeSizes` must be of same length
     *
     * @param feeIndexes Index of feeSizes to update
     * @param feeSizes_ Fee sizes in BPS
     */
    function setFeeSizes(uint256[] calldata feeIndexes, uint8[] calldata feeSizes_) external onlyOwner {
        require(feeIndexes.length == feeSizes_.length, "UserManager::setFeeSizes: Array lengths don't match");

        for (uint256 i; i < feeIndexes.length; ++i) {
            _setFeeSize(feeIndexes[i], feeSizes_[i]);
        }
    }

    /**
     * @notice Sets minimum volume for a fee tier.
     * @dev
     * `feeIndexes` start with 1 as the tier one and increment by one.
     *
     * Requirements:
     * - The caller must be a controller
     * - `feeIndexes` and `feeVolumes_` must be of same length
     *
     * @param feeIndexes Index of feeVolumes_ to update
     * @param feeVolumes_ Fee volume for an index
     */
    function setFeeVolumes(uint256[] calldata feeIndexes, uint32[] calldata feeVolumes_) external onlyOwner {
        require(feeIndexes.length == feeVolumes_.length, "UserManager::setFeeVolumes: Array lengths don't match");

        for (uint256 i; i < feeIndexes.length; ++i) {
            _setFeeVolume(feeIndexes[i], feeVolumes_[i]);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @dev Adds volume to users daily volume.
     */
    function _addUserDailyVolume(address user, uint256 index, uint256 position, uint40 volume) private {
        DailyVolumes storage userDayVolume = userDailyVolumes[user][index];

        if (position == 0) {
            userDayVolume.zero += volume;
        } else if (position == 1) {
            userDayVolume.one += volume;
        } else if (position == 2) {
            userDayVolume.two += volume;
        } else if (position == 3) {
            userDayVolume.three += volume;
        } else if (position == 4) {
            userDayVolume.four += volume;
        } else {
            userDayVolume.five += volume;
        }
    }

    /**
     * @dev Returns users daily volume.
     */
    function _getUserDailyVolume(address user, uint256 index, uint256 position) private view returns (uint256) {
        DailyVolumes storage userDayVolume = userDailyVolumes[user][index];

        if (position == 0) {
            return userDayVolume.zero;
        } else if (position == 1) {
            return userDayVolume.one;
        } else if (position == 2) {
            return userDayVolume.two;
        } else if (position == 3) {
            return userDayVolume.three;
        } else if (position == 4) {
            return userDayVolume.four;
        } else {
            return userDayVolume.five;
        }
    }

    /**
     * @dev Returns todays index and position.
     */
    function _getTodaysIndexAndPosition() private view returns (uint256, uint256) {
        return _getTimeIndexAndPosition(block.timestamp);
    }

    /**
     * @dev Returns index and position for a point of time that is "saysInThePast" days away from now.
     */
    function _getPastIndexAndPosition(uint256 daysInThePast) private view returns (uint256, uint256) {
        unchecked {
            uint256 pastDate = block.timestamp - (daysInThePast * 1 days);
            return _getTimeIndexAndPosition(pastDate);
        }
    }

    /**
     * @dev Gets index and position for a point of time.
     */
    function _getTimeIndexAndPosition(uint256 timestamp) private pure returns (uint256 index, uint256 position) {
        unchecked {
            uint256 daysFromUnix = timestamp / 1 days;

            index = daysFromUnix / DAYS_IN_WORD;
            position = daysFromUnix % DAYS_IN_WORD;
        }
    }

    /**
     * @dev Sets fee size for an index.
     */
    function _setFeeSize(uint256 feeIndex, uint8 feeSize) private {
        require(feeSize <= MAX_FEE_SIZE, "UserManager::_setFeeSize: Fee size is too high");

        if (feeIndex == 0) {
            feeSizes.baseFee = feeSize;
        } else if (feeIndex == 1) {
            feeSizes.fee1 = feeSize;
        } else if (feeIndex == 2) {
            feeSizes.fee2 = feeSize;
        } else if (feeIndex == 3) {
            feeSizes.fee3 = feeSize;
        } else if (feeIndex == 4) {
            feeSizes.fee4 = feeSize;
        } else if (feeIndex == 5) {
            feeSizes.fee5 = feeSize;
        } else if (feeIndex == 6) {
            feeSizes.fee6 = feeSize;
        } else {
            revert("UserManager::_setFeeSize: Invalid fee index");
        }

        emit FeeSizeUpdated(feeIndex, feeSize);
    }

    /**
     * @dev Sets fee volume for an index.
     */
    function _setFeeVolume(uint256 feeIndex, uint32 feeVolume) private {
        if (feeIndex == 1) {
            feeVolumes.volume1 = feeVolume;
        } else if (feeIndex == 2) {
            feeVolumes.volume2 = feeVolume;
        } else if (feeIndex == 3) {
            feeVolumes.volume3 = feeVolume;
        } else if (feeIndex == 4) {
            feeVolumes.volume4 = feeVolume;
        } else if (feeIndex == 5) {
            feeVolumes.volume5 = feeVolume;
        } else if (feeIndex == 6) {
            feeVolumes.volume6 = feeVolume;
        } else {
            revert("UserManager::_setFeeVolume: Invalid fee index");
        }

        emit FeeVolumeUpdated(feeIndex, feeVolume);
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    /**
     * @dev Reverts if TradePair is not valid.
     */
    function _onlyValidTradePair(address tradePair) private view {
        require(controller.isTradePair(tradePair), "UserManager::_onlyValidTradePair: Trade pair is not valid");
    }

    /**
     * @dev Reverts when sender is not the TradeManager
     */
    function _onlyTradeManager() private view {
        require(msg.sender == address(tradeManager), "UserManager::_onlyTradeManager: only TradeManager");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @dev Reverts if TradePair is not valid.
     */
    modifier onlyValidTradePair(address tradePair) {
        _onlyValidTradePair(tradePair);
        _;
    }

    /**
     * @dev Verifies that TradeManager sent the transaction
     */
    modifier onlyTradeManager() {
        _onlyTradeManager();
        _;
    }
}