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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

import {Position, Order, OrderType} from "../structs.sol";

interface ILiquidateVault {
    function validateLiquidationWithPosid(uint256 _posId) external view returns (bool, int256, int256, int256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Order, OrderType, OrderStatus, AddPositionOrder, DecreasePositionOrder, PositionTrigger} from "../structs.sol";

interface IOrderVault {
    function addTrailingStop(address _account, uint256 _posId, uint256[] memory _params) external;

    function addTriggerOrders(
        uint256 _posId,
        address _account,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external;

    function cancelPendingOrder(address _account, uint256 _posId) external;

    function updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) external;

    function cancelMarketOrder(uint256 _posId) external;

    function createNewOrder(
        uint256 _posId,
        address _accout,
        bool _isLong,
        uint256 _tokenId,
        uint256 _positionType,
        uint256[] memory _params,
        address _refer
    ) external;

    function createAddPositionOrder(
        address _owner,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _fee
    ) external;

    function createDecreasePositionOrder(uint256 _posId, uint256 _sizeDelta, uint256 _allowedPrice) external;

    function cancelAddPositionOrder(uint256 _posId) external;

    function deleteAddPositionOrder(uint256 _posId) external;

    function deleteDecreasePositionOrder(uint256 _posId) external;

    function getOrder(uint256 _posId) external view returns (Order memory);

    function getAddPositionOrder(uint256 _posId) external view returns (AddPositionOrder memory);

    function getDecreasePositionOrder(uint256 _posId) external view returns (DecreasePositionOrder memory);

    function getTriggerOrderInfo(uint256 _posId) external view returns (PositionTrigger memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, Order, OrderType, PaidFees} from "../structs.sol";

interface IPositionVault {
    function newPositionOrder(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function addOrRemoveCollateral(address _account, uint256 _posId, bool isPlus, uint256 _amount) external;

    function createAddPositionOrder(
        address _account,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function createDecreasePositionOrder(
        uint256 _posId,
        address _account,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function increasePosition(
        uint256 _posId,
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _price,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function decreasePositionByOrderVault(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function removeUserAlivePosition(address _user, uint256 _posId) external;

    function removeUserOpenOrder(address _user, uint256 _posId) external;

    function lastPosId() external view returns (uint256);

    function getPosition(uint256 _posId) external view returns (Position memory);

    function getUserPositionIds(address _account) external view returns (uint256[] memory);

    function getUserOpenOrderIds(address _account) external view returns (uint256[] memory);

    function getPaidFees(uint256 _posId) external view returns (PaidFees memory);

    function getVaultUSDBalance() external view returns (uint256);
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

interface ISettingsManager {
    function decreaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint32, uint32);

    function checkBanList(address _delegate) external view returns (bool);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function minCollateral() external view returns (uint256);

    function closeDeltaTime() external view returns (uint256);

    function expiryDuration() external view returns (uint256);

    function selfExecuteCooldown() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function liquidationPendingTime() external view returns (uint256);

    function depositFee(address token) external view returns (uint256);

    function withdrawFee(address token) external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(uint256 tokenId) external view returns (uint256);

    function totalOpenInterest() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function deductFeePercent(address _account) external view returns (uint256);

    function referrerTiers(address _referrer) external view returns (uint256);

    function tierFees(uint256 _tier) external view returns (uint256);

    function fundingIndex(uint256 _tokenId) external view returns (int256);

    function fundingRateFactor(uint256 _tokenId) external view returns (uint256);

    function slippageFactor(uint256 _tokenId) external view returns (uint256);

    function getFundingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getFundingChange(uint256 _tokenId) external view returns (int256);

    function getBorrowRate(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function getFundingRate(uint256 _tokenId) external view returns (int256);

    function getTradingFee(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getPnl(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _lastPrice,
        uint256 _lastIncreasedTime,
        uint256 _accruedBorrowFee,
        int256 _fundingIndex
    ) external view returns (int256, int256, int256);

    function updateFunding(uint256 _tokenId) external;

    function getBorrowFee(
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime,
        uint256 _tokenId,
        bool _isLong
    ) external view returns (uint256);

    function getUndiscountedTradingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getReferFee(address _refer) external view returns (uint256);

    function getReferFeeAndTraderRebate(address _refer) external view returns (uint256 referFee, uint256 traderRebate);

    function platformFees(address _platform) external view returns (uint256);

    function getPriceWithSlippage(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _price
    ) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isDeposit(address _token) external view returns (bool);

    function isStakingEnabled(address _token) external view returns (bool);

    function isUnstakingEnabled(address _token) external view returns (bool);

    function isIncreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isDecreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isWhitelistedFromCooldown(address _addr) external view returns (bool);

    function isWhitelistedFromTransferCooldown(address _addr) external view returns (bool);

    function isWithdraw(address _token) external view returns (bool);

    function lastFundingTimes(uint256 _tokenId) external view returns (uint256);

    function liquidateThreshold(uint256) external view returns (uint256);

    function tradingFee(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function defaultMaxOpenInterestPerUser() external view returns (uint256);

    function maxProfitPercent(uint256 _tokenId) external view returns (uint256);

    function defaultMaxProfitPercent() external view returns (uint256);

    function maxOpenInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function priceMovementPercent() external view returns (uint256);

    function maxOpenInterestPerUser(address _account) external view returns (uint256);

    function stakingFee(address token) external view returns (uint256);

    function unstakingFee(address token) external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function marketOrderGasFee() external view returns (uint256);

    function maxTriggerPerPosition() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVault {
    function accountDeltaIntoTotalUSD(bool _isIncrease, uint256 _delta) external;

    function distributeFee(uint256 _fee, address _refer, address _trader) external;

    function takeVUSDIn(address _account, uint256 _amount) external;

    function takeVUSDOut(address _account, uint256 _amount) external;

    function lastStakedAt(address _account) external view returns (uint256);

    function getVaultUSDBalance() external view returns (uint256);

    function getVLPPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ILiquidateVault.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOrderVault.sol";
import "./interfaces/IOperators.sol";

import {Constants} from "../access/Constants.sol";
import {OrderStatus, PaidFees, Temp} from "./structs.sol";

contract PositionVault is Constants, Initializable, ReentrancyGuardUpgradeable, IPositionVault {
    // constants
    ISettingsManager private settingsManager;
    ILiquidateVault private liquidateVault;
    IPriceManager private priceManager;
    IOrderVault private orderVault;
    IOperators private operators;
    IVault private vault;
    bool private isInitialized;

    // variables
    uint256 public override lastPosId;
    mapping(uint256 => Position) private positions; // posId => Position{}
    mapping(address => uint256[]) private userPositionIds; // userAddress => alive posIds[]
    mapping(address => uint256[]) private userOpenOrderIds; // userAddress => open orderIds[]
    mapping(uint256 => uint256) private userAliveIndexOf; // posId => index of userPositionIds[user], note that a position can only have a user
    mapping(uint256 => uint256) private userOpenOrderIndexOf; // posId => index of userPositionIds[user], note that a position can only have a user
    mapping(uint256 => PaidFees) private paidFees; // to track paid fees for each position

    // variables to faciliate market order execution (easier to batch execute and track without using event)
    uint256 public queueIndex;
    uint256[] public queuePosIds;

    mapping(uint256 => uint256) public removeCollateralOrders; // posId => collateralAmount

    event AddOrRemoveCollateral(uint256 posId, bool isPlus, uint256 amount, uint256 collateral, uint256 size);
    event ExecuteRemoveCollateral(uint256 posId);
    event ExecuteRemoveCollateralError(uint256 indexed posId, address indexed account, string err);
    event CreateAddPositionOrder(uint256 posId, uint256 collateral, uint256 size, uint256 allowedPrice);
    event CreateDecreasePositionOrder(uint256 posId, uint256 size, uint256 allowedPrice);
    event ExecuteAddPositionOrder(uint256 posId, uint256 collateral, uint256 size, uint256 feeUsd);
    event ExecuteDecreasePositionOrder(uint256 posId, uint256 size);
    event MarketOrderExecutionError(uint256 indexed posId, address indexed account, string err);
    event AddPositionExecutionError(uint256 indexed posId, address indexed account, string err);
    event DecreasePositionExecutionError(uint256 indexed posId, address indexed account, string err);
    event IncreasePosition(
        uint256 indexed posId,
        address indexed account,
        uint256 indexed tokenId,
        bool isLong,
        uint256[5] posData
    );
    event DecreasePosition(
        uint256 indexed posId,
        address indexed account,
        uint256 indexed tokenId,
        bool isLong,
        int256[3] pnlData,
        uint256[5] posData
    );
    event ClosePosition(
        uint256 indexed posId,
        address indexed account,
        uint256 indexed tokenId,
        bool isLong,
        int256[3] pnlData,
        uint256[5] posData
    );

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    function _onlyVault() private view {
        require(msg.sender == address(vault), "Only vault");
    }

    modifier onlyOrderVault() {
        _onlyOrderVault();
        _;
    }

    function _onlyOrderVault() private view {
        require(msg.sender == address(orderVault), "Only vault");
    }

    modifier onlyLiquidateVault() {
        require(msg.sender == address(liquidateVault), "Only vault");
        _;
    }

    modifier onlyOperator(uint256 level) {
        _onlyOperator(level);
        _;
    }

    function _onlyOperator(uint256 level) private view {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
    }

    /* ========== INITIALIZE FUNCTIONS ========== */

    function initialize(address _vault, address _priceManager, address _operators) public initializer {
        __ReentrancyGuard_init();
        // intitialize the admins
        vault = IVault(_vault);
        priceManager = IPriceManager(_priceManager);
        operators = IOperators(_operators);
    }

    function init(
        IOrderVault _orderVault,
        ILiquidateVault _liquidateVault,
        ISettingsManager _settingsManager
    ) external {
        require(!isInitialized, "initialized");

        liquidateVault = _liquidateVault;
        orderVault = _orderVault;
        settingsManager = _settingsManager;

        isInitialized = true;
    }

    /* ========== USER FUNCTIONS ========== */

    function newPositionOrder(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        // 0 -> market order
        // 1 -> limit order
        // 2 -> stop-market order
        // 3 -> stop-limit order
        uint256[] memory _params,
        // for market order:  _params[0] -> allowed price (revert if exceeded)
        // for limit order: _params[0] -> limit price
        // In stop-market order: _params[1] -> stop price,
        // In stop-limit order: _params[0] -> limit price, _params[1] -> stop price
        // for all orders: _params[2] -> collateral
        // for all orders: _params[3] -> size
        address _refer
    ) external onlyVault {
        validateIncreasePosition(_tokenId, _params[2], _params[3]);

        uint256 _lastPosId = lastPosId;
        Position storage position = positions[_lastPosId];
        position.owner = _account;
        position.refer = _refer;
        position.tokenId = _tokenId;
        position.isLong = _isLong;

        uint256 fee = settingsManager.getTradingFee(_account, _tokenId, _isLong, _params[3]);
        paidFees[_lastPosId].paidPositionFee = fee;
        vault.takeVUSDIn(_account, _params[2] + fee);

        if (_orderType == OrderType.MARKET) {
            require(
                !settingsManager.isIncreasingPositionDisabled(_tokenId),
                "current asset is disabled from increasing position"
            );
            require(_params[0] > 0, "market price is invalid");
            orderVault.createNewOrder(_lastPosId, _account, _isLong, _tokenId, POSITION_MARKET, _params, _refer);
            queuePosIds.push(_lastPosId);
        } else if (_orderType == OrderType.LIMIT) {
            require(_params[0] > 0, "limit price is invalid");
            orderVault.createNewOrder(_lastPosId, _account, _isLong, _tokenId, POSITION_LIMIT, _params, _refer);
            _addUserOpenOrder(position.owner, _lastPosId);
        } else if (_orderType == OrderType.STOP) {
            require(_params[1] > 0, "stop price is invalid");
            orderVault.createNewOrder(_lastPosId, _account, _isLong, _tokenId, POSITION_STOP_MARKET, _params, _refer);
            _addUserOpenOrder(position.owner, _lastPosId);
        } else if (_orderType == OrderType.STOP_LIMIT) {
            require(_params[0] > 0 && _params[1] > 0, "stop limit price is invalid");
            orderVault.createNewOrder(_lastPosId, _account, _isLong, _tokenId, POSITION_STOP_LIMIT, _params, _refer);
            _addUserOpenOrder(position.owner, _lastPosId);
        } else {
            revert("invalid order type");
        }

        lastPosId = _lastPosId + 1;
    }

    function addOrRemoveCollateral(
        address _account,
        uint256 _posId,
        bool isPlus,
        uint256 _amount
    ) external override onlyVault {
        Position storage position = positions[_posId];
        require(_account == position.owner, "you are not allowed to add position");
        require(position.size > 0, "Position not Open");

        if (isPlus) {
            position.collateral += _amount;
            validateMinLeverage(position.size, position.collateral);
            vault.takeVUSDIn(_account, _amount);
            emit AddOrRemoveCollateral(_posId, isPlus, _amount, position.collateral, position.size);
        } else {
            require(removeCollateralOrders[_posId] == 0, "order already exists");
            removeCollateralOrders[_posId] = _amount;

            queuePosIds.push(3 * 2 ** 128 + _posId);
        }
    }

    function createAddPositionOrder(
        address _account,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external override onlyVault {
        Position memory position = positions[_posId];

        require(
            !settingsManager.isIncreasingPositionDisabled(position.tokenId),
            "current asset is disabled from increasing position"
        );
        require(position.size > 0, "Position not Open");
        require(_account == position.owner, "you are not allowed to add position");
        validateIncreasePosition(position.tokenId, _collateralDelta, _sizeDelta);

        uint256 fee = settingsManager.getTradingFee(_account, position.tokenId, position.isLong, _sizeDelta);
        vault.takeVUSDIn(_account, _collateralDelta + fee);
        orderVault.createAddPositionOrder(_account, _posId, _collateralDelta, _sizeDelta, _allowedPrice, fee);

        queuePosIds.push(2 ** 128 + _posId);

        emit CreateAddPositionOrder(_posId, _collateralDelta, _sizeDelta, _allowedPrice);
    }

    function createDecreasePositionOrder(
        uint256 _posId,
        address _account,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external override onlyVault {
        Position memory position = positions[_posId];

        require(_sizeDelta > 0, "invalid size");
        require(position.size > 0, "Position not Open");
        require(_account == position.owner, "not allowed");

        orderVault.createDecreasePositionOrder(_posId, _sizeDelta, _allowedPrice);

        queuePosIds.push(2 ** 129 + _posId);

        emit CreateDecreasePositionOrder(_posId, _sizeDelta, _allowedPrice);
    }

    // allow users to close their positions themselves after selfExecuteCooldown, in case keepers are down
    function selfExecuteDecreasePositionOrder(uint256 _posId) external nonReentrant {
        Position memory position = positions[_posId];
        require(msg.sender == position.owner, "!owner");

        DecreasePositionOrder memory decreasePositionOrder = orderVault.getDecreasePositionOrder(_posId);
        require(
            block.timestamp > decreasePositionOrder.timestamp + settingsManager.selfExecuteCooldown(),
            "cannot self execute yet"
        );

        uint256 price = priceManager.getLastPrice(position.tokenId);
        // without check slippage to ensure success execute
        // user should read contract price feed to know the price before execution
        _decreasePosition(_posId, price, decreasePositionOrder.size);
        orderVault.deleteDecreasePositionOrder(_posId);
    }

    /* ========== OPERATOR FUNCTIONS ========== */

    function executeRemoveCollateral(uint256 _posId) external nonReentrant onlyOperator(1) {
        uint256 removeCollateralAmount = removeCollateralOrders[_posId];
        require(removeCollateralAmount > 0, "empty order");
        Position storage position = positions[_posId];
        require(position.size > 0, "Position not Open");

        position.collateral -= removeCollateralAmount;
        validateMaxLeverage(position.tokenId, position.size, position.collateral);
        (bool isPositionLiquidatable, , , ) = liquidateVault.validateLiquidationWithPosid(_posId);
        require(!isPositionLiquidatable, "position will be liquidated");
        vault.takeVUSDOut(position.owner, removeCollateralAmount);

        delete removeCollateralOrders[_posId];

        emit AddOrRemoveCollateral(_posId, false, removeCollateralAmount, position.collateral, position.size);
    }

    function executeOpenMarketOrder(uint256 _posId) public nonReentrant onlyOperator(1) {
        Position memory position = positions[_posId];
        Order memory order = orderVault.getOrder(_posId);

        require(order.size > 0 && order.status == OrderStatus.PENDING, "not open");
        require(order.positionType == POSITION_MARKET, "not market order");
        require(block.timestamp <= order.timestamp + settingsManager.expiryDuration(), "order has expired");

        uint256 price = priceManager.getLastPrice(position.tokenId);
        uint256 priceWithSlippage = settingsManager.getPriceWithSlippage(
            position.tokenId,
            position.isLong,
            order.size,
            price
        );
        checkSlippage(position.isLong, order.lmtPrice, priceWithSlippage);

        _increasePosition(
            _posId,
            position.owner,
            position.tokenId,
            position.isLong,
            price,
            order.collateral,
            order.size,
            paidFees[_posId].paidPositionFee
        );
        orderVault.updateOrder(_posId, order.positionType, 0, 0, OrderStatus.FILLED);
    }

    function executeAddPositionOrder(uint256 _posId) external nonReentrant onlyOperator(1) {
        Position memory position = positions[_posId];
        AddPositionOrder memory addPositionOrder = orderVault.getAddPositionOrder(_posId);

        require(addPositionOrder.size > 0, "order size is 0");
        require(block.timestamp <= addPositionOrder.timestamp + settingsManager.expiryDuration(), "order has expired");

        uint256 price = priceManager.getLastPrice(position.tokenId);
        uint256 priceWithSlippage = settingsManager.getPriceWithSlippage(
            position.tokenId,
            position.isLong,
            addPositionOrder.size,
            price
        );
        checkSlippage(position.isLong, addPositionOrder.allowedPrice, priceWithSlippage);

        _increasePosition(
            _posId,
            position.owner,
            position.tokenId,
            position.isLong,
            price,
            addPositionOrder.collateral,
            addPositionOrder.size,
            addPositionOrder.fee
        );
        orderVault.deleteAddPositionOrder(_posId);

        emit ExecuteAddPositionOrder(_posId, addPositionOrder.collateral, addPositionOrder.size, addPositionOrder.fee);
    }

    function executeDecreasePositionOrder(uint256 _posId) external nonReentrant onlyOperator(1) {
        Position memory position = positions[_posId];
        DecreasePositionOrder memory decreasePositionOrder = orderVault.getDecreasePositionOrder(_posId);

        require(
            block.timestamp <= decreasePositionOrder.timestamp + settingsManager.expiryDuration(),
            "order has expired"
        );

        uint256 decreaseSize = decreasePositionOrder.size > position.size ? position.size : decreasePositionOrder.size;
        uint256 price = priceManager.getLastPrice(position.tokenId);
        uint256 priceWithSlippage = settingsManager.getPriceWithSlippage(
            position.tokenId,
            !position.isLong, // decreasePosition is in opposite direction
            decreaseSize,
            price
        );
        checkSlippage(!position.isLong, decreasePositionOrder.allowedPrice, priceWithSlippage);

        _decreasePosition(_posId, price, decreaseSize);
        orderVault.deleteDecreasePositionOrder(_posId);

        emit ExecuteDecreasePositionOrder(_posId, decreaseSize);
    }

    function executeOrders(uint256 numOfOrders) external onlyOperator(1) {
        uint256 index = queueIndex;
        uint256 endIndex = index + numOfOrders;
        uint256 length = queuePosIds.length;

        if (index >= length) revert("nothing to execute");
        if (endIndex > length) endIndex = length;

        while (index < endIndex) {
            uint256 t = queuePosIds[index];
            uint256 orderType = t / 2 ** 128;
            uint256 posId = t % 2 ** 128;

            if (orderType == 0) {
                try this.executeOpenMarketOrder(posId) {} catch Error(string memory err) {
                    orderVault.cancelMarketOrder(posId);
                    emit MarketOrderExecutionError(posId, positions[posId].owner, err);
                } catch {
                    orderVault.cancelMarketOrder(posId);
                }
            } else if (orderType == 1) {
                try this.executeAddPositionOrder(posId) {} catch Error(string memory err) {
                    orderVault.cancelAddPositionOrder(posId);
                    emit AddPositionExecutionError(posId, positions[posId].owner, err);
                } catch {
                    orderVault.cancelAddPositionOrder(posId);
                }
            } else if (orderType == 2) {
                try this.executeDecreasePositionOrder(posId) {} catch Error(string memory err) {
                    orderVault.deleteDecreasePositionOrder(posId);
                    emit DecreasePositionExecutionError(posId, positions[posId].owner, err);
                } catch {
                    orderVault.deleteDecreasePositionOrder(posId);
                }
            } else if (orderType == 3) {
                try this.executeRemoveCollateral(posId) {} catch Error(string memory err) {
                    delete removeCollateralOrders[posId];
                    emit ExecuteRemoveCollateralError(posId, positions[posId].owner, err);
                } catch {
                    delete removeCollateralOrders[posId];
                }
            }

            delete queuePosIds[index];
            ++index;
        }

        queueIndex = index;
    }

    /* ========== HELPER FUNCTIONS ========== */

    function _increasePosition(
        uint256 _posId,
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _price,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) internal {
        require(
            !settingsManager.isIncreasingPositionDisabled(_tokenId),
            "current asset is disabled from increasing position"
        );

        Position storage position = positions[_posId];

        validateIncreasePosition(position.tokenId, position.collateral + _collateralDelta, position.size + _sizeDelta);

        _price = settingsManager.getPriceWithSlippage(position.tokenId, position.isLong, _sizeDelta, _price);

        settingsManager.updateFunding(_tokenId);
        settingsManager.increaseOpenInterest(_tokenId, _account, _isLong, _sizeDelta);

        if (position.size == 0) {
            position.averagePrice = _price;
            position.fundingIndex = settingsManager.fundingIndex(_tokenId);

            _addUserAlivePosition(_account, _posId);
        } else {
            position.averagePrice =
                (position.size * position.averagePrice + _sizeDelta * _price) /
                (position.size + _sizeDelta);
            position.fundingIndex =
                (int256(position.size) *
                    position.fundingIndex +
                    int256(_sizeDelta) *
                    settingsManager.fundingIndex(_tokenId)) /
                int256(position.size + _sizeDelta);
            position.accruedBorrowFee += settingsManager.getBorrowFee(
                position.size,
                position.lastIncreasedTime,
                _tokenId,
                _isLong
            );

            paidFees[_posId].paidPositionFee += _fee;
        }

        position.collateral += _collateralDelta;
        position.size += _sizeDelta;
        position.lastIncreasedTime = block.timestamp;

        vault.distributeFee(_fee, position.refer, _account);

        emit IncreasePosition(
            _posId,
            _account,
            _tokenId,
            _isLong,
            [_collateralDelta, _sizeDelta, position.averagePrice, _price, _fee]
        );
    }

    function increasePosition(
        uint256 _posId,
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _price,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external override onlyOrderVault {
        _increasePosition(_posId, _account, _tokenId, _isLong, _price, _collateralDelta, _sizeDelta, _fee);
    }

    function _decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) internal {
        Position storage position = positions[_posId];

        require(
            !settingsManager.isDecreasingPositionDisabled(position.tokenId),
            "current asset is disabled from decreasing position"
        );
        require(position.size > 0, "position size is zero");
        require(_sizeDelta > 0, "_sizeDelta is zero");
        require(block.timestamp > position.lastIncreasedTime + settingsManager.closeDeltaTime(), "!closeDeltaTime");

        if (_sizeDelta >= position.size) _sizeDelta = position.size;

        _price = settingsManager.getPriceWithSlippage(position.tokenId, !position.isLong, _sizeDelta, _price); // decreasePosition is in opposite direction

        settingsManager.updateFunding(position.tokenId);
        settingsManager.decreaseOpenInterest(position.tokenId, position.owner, position.isLong, _sizeDelta);

        uint256 countedBorrowFee;
        if (position.accruedBorrowFee > 0) {
            countedBorrowFee = (position.accruedBorrowFee * _sizeDelta) / position.size;
            position.accruedBorrowFee -= countedBorrowFee;
        }

        (int256 pnl, int256 fundingFee, int256 borrowFee) = settingsManager.getPnl(
            position.tokenId,
            position.isLong,
            _sizeDelta,
            position.averagePrice,
            _price,
            position.lastIncreasedTime,
            countedBorrowFee,
            position.fundingIndex
        );

        uint256 fee = settingsManager.getTradingFee(position.owner, position.tokenId, !position.isLong, _sizeDelta);

        uint256 collateralDelta = (position.collateral * _sizeDelta) / position.size;

        int256 usdOut = int256(collateralDelta) + pnl - int256(fee);
        if (usdOut > 0) vault.takeVUSDOut(position.owner, uint256(usdOut));

        if (pnl >= 0) {
            vault.accountDeltaIntoTotalUSD(false, uint256(pnl));
        } else {
            uint256 loss = uint256(-1 * pnl);
            uint256 maxLoss = collateralDelta - fee;
            if (loss > maxLoss) {
                vault.accountDeltaIntoTotalUSD(true, maxLoss);
            } else {
                vault.accountDeltaIntoTotalUSD(true, loss);
            }
        }

        vault.distributeFee(fee, position.refer, position.owner);

        // split fundingFee & borrowFee with vault & feeManager
        {
            int256 totalFees = fundingFee + borrowFee;
            if (totalFees >= 0) {
                uint256 totalFeesForFeeManager = (uint256(totalFees) *
                    (BASIS_POINTS_DIVISOR - settingsManager.feeRewardBasisPoints())) / BASIS_POINTS_DIVISOR;
                // take out accounted fees from vault and send to feeManager
                vault.accountDeltaIntoTotalUSD(false, totalFeesForFeeManager);
                vault.takeVUSDOut(settingsManager.feeManager(), totalFeesForFeeManager);
            } else {
                uint256 totalFeesForFeeManager = (uint256(-1 * totalFees) *
                    (BASIS_POINTS_DIVISOR - settingsManager.feeRewardBasisPoints())) / BASIS_POINTS_DIVISOR;
                // take out fees from feeManager and send to vault
                vault.accountDeltaIntoTotalUSD(true, totalFeesForFeeManager);
                vault.takeVUSDIn(settingsManager.feeManager(), totalFeesForFeeManager);
            }
        }

        if (_sizeDelta < position.size) {
            position.size -= _sizeDelta;
            position.collateral -= collateralDelta;
            paidFees[_posId].paidPositionFee += fee;
            paidFees[_posId].paidBorrowFee += uint256(borrowFee);
            paidFees[_posId].paidFundingFee += fundingFee;

            Temp memory temp = Temp({a: collateralDelta, b: _sizeDelta, c: position.averagePrice, d: _price, e: fee}); // use struct to prevent stack too deep error
            emit DecreasePosition(
                _posId,
                position.owner,
                position.tokenId,
                position.isLong,
                [pnl, fundingFee, borrowFee],
                [temp.a, temp.b, temp.c, temp.d, temp.e]
            );
        } else {
            Temp memory temp = Temp({a: collateralDelta, b: _sizeDelta, c: position.averagePrice, d: _price, e: fee}); // use struct to prevent stack too deep error
            emit ClosePosition(
                _posId,
                position.owner,
                position.tokenId,
                position.isLong,
                [pnl, fundingFee, borrowFee],
                [temp.a, temp.b, temp.c, temp.d, temp.e]
            );

            _removeUserAlivePosition(position.owner, _posId);
        }
    }

    // for vault to directly close user's position in forceClosePosition()
    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external override onlyVault {
        _decreasePosition(_posId, _price, _sizeDelta);
    }

    function decreasePositionByOrderVault(
        uint256 _posId,
        uint256 _price,
        uint256 _sizeDelta
    ) external override onlyOrderVault {
        _decreasePosition(_posId, _price, _sizeDelta);
    }

    function _addUserAlivePosition(address _user, uint256 _posId) internal {
        userAliveIndexOf[_posId] = userPositionIds[_user].length;
        userPositionIds[_user].push(_posId);
    }

    function _addUserOpenOrder(address _user, uint256 _posId) internal {
        userOpenOrderIndexOf[_posId] = userOpenOrderIds[_user].length;
        userOpenOrderIds[_user].push(_posId);
    }

    function removeUserAlivePosition(address _user, uint256 _posId) external override onlyLiquidateVault {
        _removeUserAlivePosition(_user, _posId);
    }

    function _removeUserAlivePosition(address _user, uint256 _posId) internal {
        uint256 index = userAliveIndexOf[_posId];
        uint256 lastIndex = userPositionIds[_user].length - 1;
        uint256 lastId = userPositionIds[_user][lastIndex];
        delete positions[_posId];
        userAliveIndexOf[lastId] = index;
        delete userAliveIndexOf[_posId];

        userPositionIds[_user][index] = lastId;
        userPositionIds[_user].pop();

        orderVault.cancelAddPositionOrder(_posId);
    }

    function removeUserOpenOrder(address _user, uint256 _posId) external override onlyOrderVault {
        _removeUserOpenOrder(_user, _posId);
    }

    function _removeUserOpenOrder(address _user, uint256 _posId) internal {
        uint256 index = userOpenOrderIndexOf[_posId];
        uint256 lastIndex = userOpenOrderIds[_user].length - 1;
        uint256 lastId = userOpenOrderIds[_user][lastIndex];
        userOpenOrderIndexOf[lastId] = index;
        delete userOpenOrderIndexOf[_posId];
        userOpenOrderIds[_user][index] = lastId;
        userOpenOrderIds[_user].pop();
    }

    /* ========== VALIDATE FUNCTIONS ========== */

    function validateIncreasePosition(uint256 _tokenId, uint256 _collateral, uint256 _size) internal view {
        require(_collateral >= settingsManager.minCollateral(), "!minCollateral");
        validateMinLeverage(_size, _collateral);
        validateMaxLeverage(_tokenId, _size, _collateral);
    }

    function validateMinLeverage(uint256 _size, uint256 _collateral) internal pure {
        require(_size >= _collateral, "leverage cannot be less than 1");
    }

    function validateMaxLeverage(uint256 _tokenId, uint256 _size, uint256 _collateral) internal view {
        require(_size * MIN_LEVERAGE <= _collateral * priceManager.maxLeverage(_tokenId), "maxLeverage exceeded");
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getPosition(uint256 _posId) external view override returns (Position memory) {
        return positions[_posId];
    }

    function getUserPositionIds(address _account) external view override returns (uint256[] memory) {
        return userPositionIds[_account];
    }

    function getUserOpenOrderIds(address _account) external view override returns (uint256[] memory) {
        return userOpenOrderIds[_account];
    }

    function getPaidFees(uint256 _posId) external view override returns (PaidFees memory) {
        return paidFees[_posId];
    }

    function getNumOfUnexecuted() external view returns (uint256) {
        return queuePosIds.length - queueIndex;
    }

    function getVaultUSDBalance() external view override returns (uint256) {
        return vault.getVaultUSDBalance();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    NONE,
    PENDING,
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct Order {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 size;
    uint256 collateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    uint256 timestamp;
}

struct AddPositionOrder {
    address owner;
    uint256 collateral;
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
    uint256 fee;
}

struct DecreasePositionOrder {
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
}

struct Position {
    address owner;
    address refer;
    bool isLong;
    uint256 tokenId;
    uint256 averagePrice;
    uint256 collateral;
    int256 fundingIndex;
    uint256 lastIncreasedTime;
    uint256 size;
    uint256 accruedBorrowFee;
}

struct PaidFees {
    uint256 paidPositionFee;
    uint256 paidBorrowFee;
    int256 paidFundingFee;
}

struct Temp {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
}

struct TriggerInfo {
    bool isTP;
    uint256 amountPercent;
    uint256 createdAt;
    uint256 price;
    uint256 triggeredAmount;
    uint256 triggeredAt;
    TriggerStatus status;
}

struct PositionTrigger {
    TriggerInfo[] triggers;
}