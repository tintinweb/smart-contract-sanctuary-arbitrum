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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEIP712} from "./IEIP712.sol";

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer is IEIP712 {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address user, address token, address spender)
        external
        view
        returns (uint160 amount, uint48 expiration, uint48 nonce);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEIP712 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISignatureTransfer} from "./ISignatureTransfer.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
interface IPermit2 is ISignatureTransfer, IAllowanceTransfer {
// IPermit2 unifies the two interfaces so users have maximal flexibility with their approval.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IEIP712} from "./IEIP712.sol";

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer is IEIP712 {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IPredyPool.sol";
import "../interfaces/IHooks.sol";

abstract contract BaseHookCallback is IHooks {
    IPredyPool immutable _predyPool;

    error CallerIsNotPredyPool();

    constructor(IPredyPool predyPool) {
        _predyPool = predyPool;
    }

    modifier onlyPredyPool() {
        if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();
        _;
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Initializable} from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IPredyPool.sol";
import "../interfaces/IHooks.sol";

abstract contract BaseHookCallbackUpgradable is Initializable, IHooks {
    IPredyPool _predyPool;

    error CallerIsNotPredyPool();

    constructor() {}

    modifier onlyPredyPool() {
        if (msg.sender != address(_predyPool)) revert CallerIsNotPredyPool();
        _;
    }

    function __BaseHookCallback_init(IPredyPool predyPool) internal onlyInitializing {
        _predyPool = predyPool;
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {BaseHookCallbackUpgradable} from "./BaseHookCallbackUpgradable.sol";
import {PredyPoolQuoter} from "../lens/PredyPoolQuoter.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {DataType} from "../libraries/DataType.sol";
import "../interfaces/IFillerMarket.sol";
import "./SettlementCallbackLib.sol";

abstract contract BaseMarketUpgradable is IFillerMarket, BaseHookCallbackUpgradable {
    struct SettlementParamsV3Internal {
        address filler;
        address contractAddress;
        bytes encodedData;
        uint256 maxQuoteAmountPrice;
        uint256 minQuoteAmountPrice;
        uint256 price;
        uint256 feePrice;
        uint256 minFee;
    }

    address public whitelistFiller;

    PredyPoolQuoter internal _quoter;

    mapping(uint256 pairId => address quoteTokenAddress) internal _quoteTokenMap;

    mapping(address settlementContractAddress => bool) internal _whiteListedSettlements;

    modifier onlyFiller() {
        if (msg.sender != whitelistFiller) revert CallerIsNotFiller();
        _;
    }

    constructor() {}

    function __BaseMarket_init(IPredyPool predyPool, address _whitelistFiller, address quoterAddress)
        internal
        onlyInitializing
    {
        __BaseHookCallback_init(predyPool);

        whitelistFiller = _whitelistFiller;

        _quoter = PredyPoolQuoter(quoterAddress);
    }

    function predySettlementCallback(
        address quoteToken,
        address baseToken,
        bytes memory settlementData,
        int256 baseAmountDelta
    ) external onlyPredyPool {
        SettlementCallbackLib.SettlementParams memory settlementParams = decodeParamsV3(settlementData, baseAmountDelta);

        SettlementCallbackLib.validate(_whiteListedSettlements, settlementParams);
        SettlementCallbackLib.execSettlement(_predyPool, quoteToken, baseToken, settlementParams, baseAmountDelta);
    }

    function decodeParamsV3(bytes memory settlementData, int256 baseAmountDelta)
        internal
        pure
        returns (SettlementCallbackLib.SettlementParams memory)
    {
        SettlementParamsV3Internal memory settlementParamsV3 = abi.decode(settlementData, (SettlementParamsV3Internal));

        uint256 tradeAmountAbs = Math.abs(baseAmountDelta);

        uint256 fee = settlementParamsV3.feePrice * tradeAmountAbs / Constants.Q96;

        if (fee < settlementParamsV3.minFee) {
            fee = settlementParamsV3.minFee;
        }

        uint256 maxQuoteAmount = settlementParamsV3.maxQuoteAmountPrice * tradeAmountAbs / Constants.Q96;
        uint256 minQuoteAmount = settlementParamsV3.minQuoteAmountPrice * tradeAmountAbs / Constants.Q96;

        return SettlementCallbackLib.SettlementParams(
            settlementParamsV3.filler,
            settlementParamsV3.contractAddress,
            settlementParamsV3.encodedData,
            baseAmountDelta > 0 ? minQuoteAmount : maxQuoteAmount,
            settlementParamsV3.price,
            int256(fee)
        );
    }

    function reallocate(uint256 pairId, IFillerMarket.SettlementParamsV3 memory settlementParams)
        external
        returns (bool relocationOccurred)
    {
        return _predyPool.reallocate(pairId, _getSettlementDataFromV3(settlementParams, msg.sender));
    }

    function execLiquidationCall(
        uint256 vaultId,
        uint256 closeRatio,
        IFillerMarket.SettlementParamsV3 memory settlementParams
    ) external virtual returns (IPredyPool.TradeResult memory) {
        return
            _predyPool.execLiquidationCall(vaultId, closeRatio, _getSettlementDataFromV3(settlementParams, msg.sender));
    }

    function _getSettlementDataFromV3(IFillerMarket.SettlementParamsV3 memory settlementParams, address filler)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(
            SettlementParamsV3Internal(
                filler,
                settlementParams.contractAddress,
                settlementParams.encodedData,
                settlementParams.maxQuoteAmountPrice,
                settlementParams.minQuoteAmountPrice,
                settlementParams.price,
                settlementParams.feePrice,
                settlementParams.minFee
            )
        );
    }

    /**
     * @notice Updates the whitelist filler address
     * @dev only owner can call this function
     */
    function updateWhitelistFiller(address newWhitelistFiller) external onlyFiller {
        whitelistFiller = newWhitelistFiller;
    }

    /**
     * @notice Updates the whitelist settlement address
     * @dev only owner can call this function
     */
    function updateWhitelistSettlement(address settlementContractAddress, bool isEnabled) external onlyFiller {
        _whiteListedSettlements[settlementContractAddress] = isEnabled;
    }

    /// @notice Registers quote token address for the pair
    function updateQuoteTokenMap(uint256 pairId) external {
        if (_quoteTokenMap[pairId] == address(0)) {
            _quoteTokenMap[pairId] = _getQuoteTokenAddress(pairId);
        }
    }

    /// @notice Checks if entryTokenAddress is registerd for the pair
    function _validateQuoteTokenAddress(uint256 pairId, address entryTokenAddress) internal view {
        require(_quoteTokenMap[pairId] != address(0) && entryTokenAddress == _quoteTokenMap[pairId]);
    }

    function _getQuoteTokenAddress(uint256 pairId) internal view returns (address) {
        DataType.PairStatus memory pairStatus = _predyPool.getPairStatus(pairId);

        return pairStatus.quotePool.token;
    }

    function _revertTradeResult(IPredyPool.TradeResult memory tradeResult) internal pure {
        bytes memory data = abi.encode(tradeResult);

        assembly {
            revert(add(32, data), mload(data))
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {ISettlement} from "../interfaces/ISettlement.sol";
import {Constants} from "../libraries/Constants.sol";
import {Math} from "../libraries/math/Math.sol";
import {IFillerMarket} from "../interfaces/IFillerMarket.sol";

library SettlementCallbackLib {
    using SafeTransferLib for ERC20;
    using Math for uint256;

    struct SettlementParams {
        address sender;
        address contractAddress;
        bytes encodedData;
        uint256 maxQuoteAmount;
        uint256 price;
        int256 fee;
    }

    function decodeParams(bytes memory settlementData) internal pure returns (SettlementParams memory) {
        return abi.decode(settlementData, (SettlementParams));
    }

    function validate(
        mapping(address settlementContractAddress => bool) storage _whiteListedSettlements,
        SettlementParams memory settlementParams
    ) internal view {
        if (
            settlementParams.contractAddress != address(0) && !_whiteListedSettlements[settlementParams.contractAddress]
        ) {
            revert IFillerMarket.SettlementContractIsNotWhitelisted();
        }
    }

    function execSettlement(
        IPredyPool predyPool,
        address quoteToken,
        address baseToken,
        SettlementParams memory settlementParams,
        int256 baseAmountDelta
    ) internal {
        if (settlementParams.fee < 0) {
            ERC20(quoteToken).safeTransferFrom(
                settlementParams.sender, address(predyPool), uint256(-settlementParams.fee)
            );
        }

        execSettlementInternal(predyPool, quoteToken, baseToken, settlementParams, baseAmountDelta);

        if (settlementParams.fee > 0) {
            predyPool.take(true, settlementParams.sender, uint256(settlementParams.fee));
        }
    }

    function execSettlementInternal(
        IPredyPool predyPool,
        address quoteToken,
        address baseToken,
        SettlementParams memory settlementParams,
        int256 baseAmountDelta
    ) internal {
        if (baseAmountDelta > 0) {
            sell(
                predyPool,
                quoteToken,
                baseToken,
                settlementParams,
                settlementParams.sender,
                settlementParams.price,
                uint256(baseAmountDelta)
            );
        } else if (baseAmountDelta < 0) {
            buy(
                predyPool,
                quoteToken,
                baseToken,
                settlementParams,
                settlementParams.sender,
                settlementParams.price,
                uint256(-baseAmountDelta)
            );
        }
    }

    function sell(
        IPredyPool predyPool,
        address quoteToken,
        address baseToken,
        SettlementParams memory settlementParams,
        address sender,
        uint256 price,
        uint256 sellAmount
    ) internal {
        if (settlementParams.contractAddress == address(0)) {
            // direct fill
            uint256 quoteAmount = sellAmount * price / Constants.Q96;

            predyPool.take(false, sender, sellAmount);

            ERC20(quoteToken).safeTransferFrom(sender, address(predyPool), quoteAmount);

            return;
        }

        predyPool.take(false, address(this), sellAmount);
        ERC20(baseToken).approve(address(settlementParams.contractAddress), sellAmount);

        uint256 quoteAmountFromUni = ISettlement(settlementParams.contractAddress).swapExactIn(
            quoteToken,
            baseToken,
            settlementParams.encodedData,
            sellAmount,
            settlementParams.maxQuoteAmount,
            address(this)
        );

        if (price == 0) {
            ERC20(quoteToken).safeTransfer(address(predyPool), quoteAmountFromUni);
        } else {
            uint256 quoteAmount = sellAmount * price / Constants.Q96;

            if (quoteAmount > quoteAmountFromUni) {
                ERC20(quoteToken).safeTransferFrom(sender, address(this), quoteAmount - quoteAmountFromUni);
            } else if (quoteAmountFromUni > quoteAmount) {
                ERC20(quoteToken).safeTransfer(sender, quoteAmountFromUni - quoteAmount);
            }

            ERC20(quoteToken).safeTransfer(address(predyPool), quoteAmount);
        }
    }

    function buy(
        IPredyPool predyPool,
        address quoteToken,
        address baseToken,
        SettlementParams memory settlementParams,
        address sender,
        uint256 price,
        uint256 buyAmount
    ) internal {
        if (settlementParams.contractAddress == address(0)) {
            // direct fill
            uint256 quoteAmount = buyAmount * price / Constants.Q96;

            predyPool.take(true, sender, quoteAmount);

            ERC20(baseToken).safeTransferFrom(sender, address(predyPool), buyAmount);

            return;
        }

        predyPool.take(true, address(this), settlementParams.maxQuoteAmount);
        ERC20(quoteToken).approve(address(settlementParams.contractAddress), settlementParams.maxQuoteAmount);

        uint256 quoteAmountToUni = ISettlement(settlementParams.contractAddress).swapExactOut(
            quoteToken,
            baseToken,
            settlementParams.encodedData,
            buyAmount,
            settlementParams.maxQuoteAmount,
            address(predyPool)
        );

        if (price == 0) {
            ERC20(quoteToken).safeTransfer(address(predyPool), settlementParams.maxQuoteAmount - quoteAmountToUni);
        } else {
            uint256 quoteAmount = buyAmount * price / Constants.Q96;

            if (quoteAmount > quoteAmountToUni) {
                ERC20(quoteToken).safeTransfer(sender, quoteAmount - quoteAmountToUni);
            } else if (quoteAmountToUni > quoteAmount) {
                ERC20(quoteToken).safeTransferFrom(sender, address(this), quoteAmountToUni - quoteAmount);
            }

            ERC20(quoteToken).safeTransfer(address(predyPool), settlementParams.maxQuoteAmount - quoteAmount);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IFillerMarket {
    error SignerIsNotVaultOwner();

    error CallerIsNotFiller();

    error SettlementContractIsNotWhitelisted();

    struct SignedOrder {
        bytes order;
        bytes sig;
    }

    struct SettlementParams {
        address contractAddress;
        bytes encodedData;
        uint256 maxQuoteAmount;
        uint256 price;
        int256 fee;
    }

    struct SettlementParamsV3 {
        address contractAddress;
        bytes encodedData;
        uint256 maxQuoteAmountPrice;
        uint256 minQuoteAmountPrice;
        uint256 price;
        uint256 feePrice;
        uint256 minFee;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

import "./IPredyPool.sol";

interface IHooks {
    function predySettlementCallback(
        address quoteToken,
        address baseToken,
        bytes memory settlementData,
        int256 baseAmountDelta
    ) external;

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import {ISettlement} from "./ISettlement.sol";
import {DataType} from "../libraries/DataType.sol";

interface IPredyPool {
    /// @notice Thrown when the caller is not operator
    error CallerIsNotOperator();

    /// @notice Thrown when the caller is not pool creator
    error CallerIsNotPoolCreator();

    /// @notice Thrown when the caller is not the current locker
    error LockedBy(address locker);

    /// @notice Thrown when a base token is not netted out after a lock
    error BaseTokenNotSettled();

    /// @notice Thrown when a quote token is not netted out after a lock
    error QuoteTokenNotSettled();

    /// @notice Thrown when a amount is 0
    error InvalidAmount();

    /// @notice Thrown when a pair id does not exist
    error InvalidPairId();

    /// @notice Thrown when a vault isn't danger
    error VaultIsNotDanger(int256 vaultValue, int256 minMargin);

    /// @notice Thrown when a trader address is not allowed
    error TraderNotAllowed();

    // VaultLib
    error VaultAlreadyHasAnotherPair();

    error VaultAlreadyHasAnotherMarginId();

    error CallerIsNotVaultOwner();

    struct TradeParams {
        uint256 pairId;
        uint256 vaultId;
        int256 tradeAmount;
        int256 tradeAmountSqrt;
        bytes extraData;
    }

    struct TradeResult {
        Payoff payoff;
        uint256 vaultId;
        int256 fee;
        int256 minMargin;
        int256 averagePrice;
        uint256 sqrtTwap;
        uint256 sqrtPrice;
    }

    struct Payoff {
        int256 perpEntryUpdate;
        int256 sqrtEntryUpdate;
        int256 sqrtRebalanceEntryUpdateUnderlying;
        int256 sqrtRebalanceEntryUpdateStable;
        int256 perpPayoff;
        int256 sqrtPayoff;
    }

    struct Position {
        int256 margin;
        int256 amountQuote;
        int256 amountSqrt;
        int256 amountBase;
    }

    struct VaultStatus {
        uint256 id;
        int256 vaultValue;
        int256 minMargin;
        uint256 oraclePrice;
        DataType.FeeAmount feeAmount;
        Position position;
    }

    function trade(TradeParams memory tradeParams, bytes memory settlementData)
        external
        returns (TradeResult memory tradeResult);
    function execLiquidationCall(uint256 vaultId, uint256 closeRatio, bytes memory settlementData)
        external
        returns (TradeResult memory tradeResult);

    function reallocate(uint256 pairId, bytes memory settlementData) external returns (bool relocationOccurred);

    function updateRecepient(uint256 vaultId, address recipient) external;

    function createVault(uint256 pairId) external returns (uint256);

    function take(bool isQuoteAsset, address to, uint256 amount) external;

    function getSqrtPrice(uint256 pairId) external view returns (uint160);

    function getSqrtIndexPrice(uint256 pairId) external view returns (uint256);

    function getVault(uint256 vaultId) external view returns (DataType.Vault memory);
    function getPairStatus(uint256 pairId) external view returns (DataType.PairStatus memory);

    function revertPairStatus(uint256 pairId) external;
    function revertVaultStatus(uint256 vaultId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0;

interface ISettlement {
    function swapExactIn(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient
    ) external returns (uint256 amountOut);

    function swapExactOut(
        address quoteToken,
        address baseToken,
        bytes memory data,
        uint256 amountOut,
        uint256 amountInMaximum,
        address recipient
    ) external returns (uint256 amountIn);

    function quoteSwapExactIn(bytes memory data, uint256 amountIn) external returns (uint256 amountOut);

    function quoteSwapExactOut(bytes memory data, uint256 amountOut) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../interfaces/IPredyPool.sol";
import "../interfaces/IFillerMarket.sol";
import "../base/BaseHookCallback.sol";
import "../base/SettlementCallbackLib.sol";

/**
 * @notice Quoter contract for PredyPool
 * The purpose of lens is to be able to simulate transactions without having tokens.
 */
contract PredyPoolQuoter is BaseHookCallback {
    constructor(IPredyPool _predyPool) BaseHookCallback(_predyPool) {}

    function predySettlementCallback(address quoteToken, address baseToken, bytes memory data, int256 baseAmountDelta)
        external
    {
        if (data.length > 0) {
            SettlementCallbackLib.execSettlement(
                _predyPool, quoteToken, baseToken, SettlementCallbackLib.decodeParams(data), baseAmountDelta
            );
        } else {
            _revertBaseAmountDelta(baseAmountDelta);
        }
    }

    function _revertBaseAmountDelta(int256 baseAmountDelta) internal pure {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, baseAmountDelta)
            revert(ptr, 32)
        }
    }

    function predyTradeAfterCallback(IPredyPool.TradeParams memory, IPredyPool.TradeResult memory tradeResult)
        external
        view
        override(BaseHookCallback)
        onlyPredyPool
    {
        bytes memory data = abi.encode(tradeResult);

        assembly {
            revert(add(32, data), mload(data))
        }
    }

    /**
     * @notice Quotes trade
     * @param tradeParams The trade details
     * @param settlementParams The route of settlement created by filler
     */
    function quoteTrade(
        IPredyPool.TradeParams memory tradeParams,
        IFillerMarket.SettlementParams memory settlementParams
    ) external returns (IPredyPool.TradeResult memory tradeResult) {
        try _predyPool.trade(tradeParams, _getSettlementData(settlementParams, msg.sender)) {}
        catch (bytes memory reason) {
            tradeResult = _parseRevertReasonAsTradeResult(reason);
        }
    }

    function quoteBaseAmountDelta(IPredyPool.TradeParams memory tradeParams)
        external
        returns (int256 baseAmountDelta)
    {
        try _predyPool.trade(tradeParams, "") {}
        catch (bytes memory reason) {
            return _parseRevertReasonAsBaseAmountDelta(reason);
        }
    }

    function quoteLiquidation(uint256 vaultId, uint256 closeRatio) external returns (int256 baseAmountDelta) {
        try _predyPool.execLiquidationCall(vaultId, closeRatio, "") {}
        catch (bytes memory reason) {
            return _parseRevertReasonAsBaseAmountDelta(reason);
        }
    }

    function quoteReallocation(uint256 pairId) external returns (int256 baseAmountDelta) {
        try _predyPool.reallocate(pairId, "") {}
        catch (bytes memory reason) {
            return _parseRevertReasonAsBaseAmountDelta(reason);
        }
    }

    function quotePairStatus(uint256 pairId) external returns (DataType.PairStatus memory pairStatus) {
        try _predyPool.revertPairStatus(pairId) {}
        catch (bytes memory reason) {
            pairStatus = _parseRevertReasonAsPairStatus(reason);
        }
    }

    function quoteVaultStatus(uint256 vaultId) external returns (IPredyPool.VaultStatus memory vaultStatus) {
        try _predyPool.revertVaultStatus(vaultId) {}
        catch (bytes memory reason) {
            vaultStatus = _parseRevertReasonAsVaultStatus(reason);
        }
    }

    /// @notice Return the tradeResult of given abi-encoded trade result
    /// @param tradeResult abi-encoded order, including `reactor` as the first encoded struct member
    function _parseRevertReasonAsTradeResult(bytes memory reason)
        private
        pure
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        if (reason.length != 384) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (IPredyPool.TradeResult));
        }
    }

    function _parseRevertReasonAsBaseAmountDelta(bytes memory reason) private pure returns (int256) {
        if (reason.length != 32) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }

        return abi.decode(reason, (int256));
    }

    function _parseRevertReasonAsPairStatus(bytes memory reason)
        private
        pure
        returns (DataType.PairStatus memory pairStatus)
    {
        if (reason.length != 1920) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (DataType.PairStatus));
        }
    }

    function _parseRevertReasonAsVaultStatus(bytes memory reason)
        private
        pure
        returns (IPredyPool.VaultStatus memory vaultStatus)
    {
        if (reason.length < 320) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (IPredyPool.VaultStatus));
        }
    }

    function _getSettlementData(IFillerMarket.SettlementParams memory settlementParams, address filler)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(
            SettlementCallbackLib.SettlementParams(
                filler,
                settlementParams.contractAddress,
                settlementParams.encodedData,
                settlementParams.maxQuoteAmount,
                settlementParams.price,
                settlementParams.fee
            )
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library Constants {
    uint256 internal constant ONE = 1e18;

    uint256 internal constant MAX_VAULTS = 18446744073709551616;
    uint256 internal constant MAX_PAIRS = 18446744073709551616;

    // Margin option
    int256 internal constant MIN_MARGIN_AMOUNT = 1e6;

    uint256 internal constant MIN_LIQUIDITY = 100;

    uint256 internal constant MIN_SQRT_PRICE = 79228162514264337593;
    uint256 internal constant MAX_SQRT_PRICE = 79228162514264337593543950336000000000;

    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;

    // 0.2%
    uint256 internal constant BASE_MIN_COLLATERAL_WITH_DEBT = 2000;
    // 2.5% scaled by 1e6
    uint256 internal constant BASE_LIQ_SLIPPAGE_SQRT_TOLERANCE = 12422;
    // 5.0% scaled by 1e6
    uint256 internal constant MAX_LIQ_SLIPPAGE_SQRT_TOLERANCE = 24710;
    // 2.5% scaled by 1e6
    uint256 internal constant SLIPPAGE_SQRT_TOLERANCE = 12422;

    // 10%
    uint256 internal constant SQUART_KINK_UR = 10 * 1e16;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {Perp} from "./Perp.sol";

library DataType {
    struct PairStatus {
        uint256 id;
        address marginId;
        address poolOwner;
        Perp.AssetPoolStatus quotePool;
        Perp.AssetPoolStatus basePool;
        Perp.AssetRiskParams riskParams;
        Perp.SqrtPerpAssetStatus sqrtAssetStatus;
        address priceFeed;
        bool isQuoteZero;
        bool whitelistEnabled;
        uint8 feeRatio;
        uint256 lastUpdateTimestamp;
    }

    struct Vault {
        uint256 id;
        address marginId;
        address owner;
        address recipient;
        int256 margin;
        Perp.UserStatus openPosition;
    }

    struct RebalanceFeeGrowthCache {
        int256 stableGrowth;
        int256 underlyingGrowth;
    }

    struct FeeAmount {
        int256 feeAmountBase;
        int256 feeAmountQuote;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library InterestRateModel {
    struct IRMParams {
        uint256 baseRate;
        uint256 kinkRate;
        uint256 slope1;
        uint256 slope2;
    }

    uint256 private constant _ONE = 1e18;

    function calculateInterestRate(IRMParams memory irmParams, uint256 utilizationRatio)
        internal
        pure
        returns (uint256)
    {
        uint256 ir = irmParams.baseRate;

        if (utilizationRatio <= irmParams.kinkRate) {
            ir += (utilizationRatio * irmParams.slope1) / _ONE;
        } else {
            ir += (irmParams.kinkRate * irmParams.slope1) / _ONE;
            ir += (irmParams.slope2 * (utilizationRatio - irmParams.kinkRate)) / _ONE;
        }

        return ir;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

library Bps {
    uint32 public constant ONE = 1e6;

    function upper(uint256 price, uint256 bps) internal pure returns (uint256) {
        return price * bps / ONE;
    }

    function lower(uint256 price, uint256 bps) internal pure returns (uint256) {
        return price * ONE / bps;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "lib/v3-core/contracts/libraries/FullMath.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-core/contracts/libraries/FixedPoint96.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

library LPMath {
    function calculateAmount0ForLiquidityWithTicks(int24 tickA, int24 tickB, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return calculateAmount0ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickA), TickMath.getSqrtRatioAtTick(tickB), liquidityAmount, isRoundUp
        );
    }

    function calculateAmount1ForLiquidityWithTicks(int24 tickA, int24 tickB, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return calculateAmount1ForLiquidity(
            TickMath.getSqrtRatioAtTick(tickA), TickMath.getSqrtRatioAtTick(tickB), liquidityAmount, isRoundUp
        );
    }

    function calculateAmount0ForLiquidity(
        uint160 sqrtRatioA,
        uint160 sqrtRatioB,
        uint256 liquidityAmount,
        bool isRoundUp
    ) internal pure returns (int256) {
        if (liquidityAmount == 0 || sqrtRatioA == sqrtRatioB) {
            return 0;
        }

        bool swaped = sqrtRatioA > sqrtRatioB;

        if (sqrtRatioA > sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);

        int256 r;

        bool _isRoundUp = swaped ? !isRoundUp : isRoundUp;
        uint256 numerator = liquidityAmount;

        if (_isRoundUp) {
            uint256 r0 = FullMath.mulDivRoundingUp(numerator, FixedPoint96.Q96, sqrtRatioA);
            uint256 r1 = FullMath.mulDiv(numerator, FixedPoint96.Q96, sqrtRatioB);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        } else {
            uint256 r0 = FullMath.mulDiv(numerator, FixedPoint96.Q96, sqrtRatioA);
            uint256 r1 = FullMath.mulDivRoundingUp(numerator, FixedPoint96.Q96, sqrtRatioB);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        }

        if (swaped) {
            return -r;
        } else {
            return r;
        }
    }

    function calculateAmount1ForLiquidity(
        uint160 sqrtRatioA,
        uint160 sqrtRatioB,
        uint256 liquidityAmount,
        bool isRoundUp
    ) internal pure returns (int256) {
        if (liquidityAmount == 0 || sqrtRatioA == sqrtRatioB) {
            return 0;
        }

        bool swaped = sqrtRatioA < sqrtRatioB;

        if (sqrtRatioA < sqrtRatioB) (sqrtRatioA, sqrtRatioB) = (sqrtRatioB, sqrtRatioA);

        int256 r;

        bool _isRoundUp = swaped ? !isRoundUp : isRoundUp;

        if (_isRoundUp) {
            uint256 r0 = FullMath.mulDivRoundingUp(liquidityAmount, sqrtRatioA, FixedPoint96.Q96);
            uint256 r1 = FullMath.mulDiv(liquidityAmount, sqrtRatioB, FixedPoint96.Q96);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        } else {
            uint256 r0 = FullMath.mulDiv(liquidityAmount, sqrtRatioA, FixedPoint96.Q96);
            uint256 r1 = FullMath.mulDivRoundingUp(liquidityAmount, sqrtRatioB, FixedPoint96.Q96);

            r = SafeCast.toInt256(r0) - SafeCast.toInt256(r1);
        }

        if (swaped) {
            return -r;
        } else {
            return r;
        }
    }

    /**
     * @notice Calculates L / (1.0001)^(b/2)
     */
    function calculateAmount0OffsetWithTick(int24 upper, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return SafeCast.toInt256(calculateAmount0Offset(TickMath.getSqrtRatioAtTick(upper), liquidityAmount, isRoundUp));
    }

    /**
     * @notice Calculates L / sqrt{p_b}
     */
    function calculateAmount0Offset(uint160 sqrtRatio, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (uint256)
    {
        if (isRoundUp) {
            return FullMath.mulDivRoundingUp(liquidityAmount, FixedPoint96.Q96, sqrtRatio);
        } else {
            return FullMath.mulDiv(liquidityAmount, FixedPoint96.Q96, sqrtRatio);
        }
    }

    /**
     * @notice Calculates L * (1.0001)^(a/2)
     */
    function calculateAmount1OffsetWithTick(int24 lower, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (int256)
    {
        return SafeCast.toInt256(calculateAmount1Offset(TickMath.getSqrtRatioAtTick(lower), liquidityAmount, isRoundUp));
    }

    /**
     * @notice Calculates L * sqrt{p_a}
     */
    function calculateAmount1Offset(uint160 sqrtRatio, uint256 liquidityAmount, bool isRoundUp)
        internal
        pure
        returns (uint256)
    {
        if (isRoundUp) {
            return FullMath.mulDivRoundingUp(liquidityAmount, sqrtRatio, FixedPoint96.Q96);
        } else {
            return FullMath.mulDiv(liquidityAmount, sqrtRatio, FixedPoint96.Q96);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "lib/v3-core/contracts/libraries/FullMath.sol";
import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {SafeCast} from "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {Constants} from "../Constants.sol";

library Math {
    using SafeCast for uint256;

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function fullMulDivInt256(int256 x, uint256 y, uint256 z) internal pure returns (int256) {
        if (x == 0) {
            return 0;
        } else if (x > 0) {
            return FullMath.mulDiv(uint256(x), y, z).toInt256();
        } else {
            return -FullMath.mulDiv(uint256(-x), y, z).toInt256();
        }
    }

    function fullMulDivDownInt256(int256 x, uint256 y, uint256 z) internal pure returns (int256) {
        if (x == 0) {
            return 0;
        } else if (x > 0) {
            return FullMath.mulDiv(uint256(x), y, z).toInt256();
        } else {
            return -FullMath.mulDivRoundingUp(uint256(-x), y, z).toInt256();
        }
    }

    function mulDivDownInt256(int256 x, uint256 y, uint256 z) internal pure returns (int256) {
        if (x == 0) {
            return 0;
        } else if (x > 0) {
            return FixedPointMathLib.mulDivDown(uint256(x), y, z).toInt256();
        } else {
            return -FixedPointMathLib.mulDivUp(uint256(-x), y, z).toInt256();
        }
    }

    function addDelta(uint256 a, int256 b) internal pure returns (uint256) {
        if (b >= 0) {
            return a + uint256(b);
        } else {
            return a - uint256(-b);
        }
    }

    function calSqrtPriceToPrice(uint256 sqrtPrice) internal pure returns (uint256 price) {
        price = FullMath.mulDiv(sqrtPrice, sqrtPrice, Constants.Q96);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct OrderInfo {
    address market;
    address trader;
    uint256 nonce;
    uint256 deadline;
}

/// @notice helpers for handling OrderInfo objects
library OrderInfoLib {
    bytes internal constant ORDER_INFO_TYPE = "OrderInfo(address market,address trader,uint256 nonce,uint256 deadline)";
    bytes32 internal constant ORDER_INFO_TYPE_HASH = keccak256(ORDER_INFO_TYPE);

    /// @notice hash an OrderInfo object
    /// @param info The OrderInfo object to hash
    function hash(OrderInfo memory info) internal pure returns (bytes32) {
        return keccak256(abi.encode(ORDER_INFO_TYPE_HASH, info.market, info.trader, info.nonce, info.deadline));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {ISignatureTransfer} from "lib/permit2/src/interfaces/ISignatureTransfer.sol";
import {ResolvedOrder} from "./ResolvedOrder.sol";

/// @notice handling some permit2-specific encoding
library Permit2Lib {
    /// @notice returns a ResolvedOrder into a permit object
    function toPermit(ResolvedOrder memory order)
        internal
        pure
        returns (ISignatureTransfer.PermitTransferFrom memory)
    {
        return ISignatureTransfer.PermitTransferFrom({
            permitted: ISignatureTransfer.TokenPermissions({token: order.token, amount: order.amount}),
            nonce: order.info.nonce,
            deadline: order.info.deadline
        });
    }

    /// @notice returns a ResolvedOrder into a permit object
    function transferDetails(ResolvedOrder memory order, address to)
        internal
        pure
        returns (ISignatureTransfer.SignatureTransferDetails memory)
    {
        return ISignatureTransfer.SignatureTransferDetails({to: to, requestedAmount: order.amount});
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OrderInfo} from "./OrderInfoLib.sol";

struct ResolvedOrder {
    OrderInfo info;
    address token;
    uint256 amount;
    bytes32 hash;
    bytes sig;
}

library ResolvedOrderLib {
    /// @notice thrown when the order targets a different market contract
    error InvalidMarket();

    /// @notice thrown if the order has expired
    error DeadlinePassed();

    /// @notice Validates a resolved order, reverting if invalid
    /// @param resolvedOrder resovled order
    function validate(ResolvedOrder memory resolvedOrder) internal view {
        if (address(this) != address(resolvedOrder.info.market)) {
            revert InvalidMarket();
        }

        if (block.timestamp > resolvedOrder.info.deadline) {
            revert DeadlinePassed();
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-periphery/contracts/libraries/PositionKey.sol";
import "lib/v3-core/contracts/libraries/FixedPoint96.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/solmate/src/utils/SafeCastLib.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {IPredyPool} from "../interfaces/IPredyPool.sol";
import "./ScaledAsset.sol";
import "./InterestRateModel.sol";
import "./PremiumCurveModel.sol";
import "./Constants.sol";
import {DataType} from "./DataType.sol";
import "./UniHelper.sol";
import "./math/LPMath.sol";
import "./math/Math.sol";
import "./Reallocation.sol";

/// @title Perp library to calculate perp positions
library Perp {
    using ScaledAsset for ScaledAsset.AssetStatus;
    using SafeCastLib for uint256;
    using Math for int256;

    /// @notice Thrown when the supply of 2*squart can not cover borrow
    error SqrtAssetCanNotCoverBorrow();

    /// @notice Thrown when the available liquidity is not enough to withdraw
    error NoCFMMLiquidityError();

    /// @notice Thrown when the LP position is out of range
    error OutOfRangeError();

    struct AssetPoolStatus {
        address token;
        address supplyTokenAddress;
        ScaledAsset.AssetStatus tokenStatus;
        InterestRateModel.IRMParams irmParams;
        uint256 accumulatedProtocolRevenue;
        uint256 accumulatedCreatorRevenue;
    }

    struct AssetRiskParams {
        uint256 riskRatio;
        int24 rangeSize;
        int24 rebalanceThreshold;
        uint64 minSlippage;
        uint64 maxSlippage;
    }

    struct PositionStatus {
        int256 amount;
        int256 entryValue;
    }

    struct SqrtPositionStatus {
        int256 amount;
        int256 entryValue;
        int256 quoteRebalanceEntryValue;
        int256 baseRebalanceEntryValue;
        uint256 entryTradeFee0;
        uint256 entryTradeFee1;
    }

    struct UpdatePerpParams {
        int256 tradeAmount;
        int256 stableAmount;
    }

    struct UpdateSqrtPerpParams {
        int256 tradeSqrtAmount;
        int256 stableAmount;
    }

    struct SqrtPerpAssetStatus {
        address uniswapPool;
        int24 tickLower;
        int24 tickUpper;
        uint64 numRebalance;
        uint256 totalAmount;
        uint256 borrowedAmount;
        uint256 lastRebalanceTotalSquartAmount;
        uint256 lastFee0Growth;
        uint256 lastFee1Growth;
        uint256 borrowPremium0Growth;
        uint256 borrowPremium1Growth;
        uint256 fee0Growth;
        uint256 fee1Growth;
        ScaledAsset.UserStatus rebalancePositionBase;
        ScaledAsset.UserStatus rebalancePositionQuote;
        int256 rebalanceInterestGrowthBase;
        int256 rebalanceInterestGrowthQuote;
    }

    struct UserStatus {
        uint256 pairId;
        int24 rebalanceLastTickLower;
        int24 rebalanceLastTickUpper;
        uint64 lastNumRebalance;
        PositionStatus perp;
        SqrtPositionStatus sqrtPerp;
        ScaledAsset.UserStatus basePosition;
        ScaledAsset.UserStatus stablePosition;
    }

    event PremiumGrowthUpdated(
        uint256 indexed pairId,
        uint256 totalAmount,
        uint256 borrowAmount,
        uint256 fee0Growth,
        uint256 fee1Growth,
        uint256 spread
    );
    event SqrtPositionUpdated(uint256 indexed pairId, int256 open, int256 close);

    function createAssetStatus(address uniswapPool, int24 tickLower, int24 tickUpper)
        internal
        pure
        returns (SqrtPerpAssetStatus memory)
    {
        return SqrtPerpAssetStatus(
            uniswapPool,
            tickLower,
            tickUpper,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            ScaledAsset.createUserStatus(),
            ScaledAsset.createUserStatus(),
            0,
            0
        );
    }

    function createPerpUserStatus(uint64 _pairId) internal pure returns (UserStatus memory) {
        return UserStatus(
            _pairId,
            0,
            0,
            0,
            PositionStatus(0, 0),
            SqrtPositionStatus(0, 0, 0, 0, 0, 0),
            ScaledAsset.createUserStatus(),
            ScaledAsset.createUserStatus()
        );
    }

    /// @notice Settle the interest on rebalance positions up to this block and update the rebalance fee growth value
    function updateRebalanceInterestGrowth(
        DataType.PairStatus memory _pairStatus,
        SqrtPerpAssetStatus storage _sqrtAssetStatus
    ) internal {
        // settle the interest on rebalance position
        // fee growths are scaled by 1e18
        if (_sqrtAssetStatus.lastRebalanceTotalSquartAmount > 0) {
            _sqrtAssetStatus.rebalanceInterestGrowthBase += _pairStatus.basePool.tokenStatus.settleUserFee(
                _sqrtAssetStatus.rebalancePositionBase
            ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);

            _sqrtAssetStatus.rebalanceInterestGrowthQuote += _pairStatus.quotePool.tokenStatus.settleUserFee(
                _sqrtAssetStatus.rebalancePositionQuote
            ) * 1e18 / int256(_sqrtAssetStatus.lastRebalanceTotalSquartAmount);
        }
    }

    /**
     * @notice Reallocates LP position to be in range.
     * In case of in-range
     *   token0
     *     1/sqrt(x) - 1/sqrt(b1) -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(b2) - 1/sqrt(b1)
     *   token1
     *     sqrt(x) - sqrt(a1) -> sqrt(x) - sqrt(a2)
     *       sqrt(a2) - sqrt(a1)
     *
     * In case of out-of-range (tick high b1 < x)
     *   token0
     *     0 -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(b2) - 1/sqrt(x)
     *   token1
     *     sqrt(b1) - sqrt(a1) -> sqrt(x) - sqrt(a2)
     *       sqrt(b1) - sqrt(a1) - (sqrt(x) - sqrt(a2))
     *
     * In case of out-of-range (tick low x < a1)
     *   token0
     *     1/sqrt(a1) - 1/sqrt(b1) -> 1/sqrt(x) - 1/sqrt(b2)
     *       1/sqrt(a1) - 1/sqrt(b1) - (1/sqrt(x) - 1/sqrt(b2))
     *   token1
     *     0 -> sqrt(x) - sqrt(a2)
     *       sqrt(a2) - sqrt(x)
     */
    function reallocate(
        DataType.PairStatus storage _assetStatusUnderlying,
        SqrtPerpAssetStatus storage _sqrtAssetStatus
    ) internal returns (bool, bool, int256 deltaPositionBase, int256 deltaPositionQuote) {
        (uint160 currentSqrtPrice, int24 currentTick,,,,,) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).slot0();

        // If the current tick does not reach the threshold, then do nothing
        if (
            _sqrtAssetStatus.tickLower + _assetStatusUnderlying.riskParams.rebalanceThreshold < currentTick
                && currentTick < _sqrtAssetStatus.tickUpper - _assetStatusUnderlying.riskParams.rebalanceThreshold
        ) {
            saveLastFeeGrowth(_sqrtAssetStatus);

            return (false, false, 0, 0);
        }

        // If the total liquidity is 0, then do nothing
        uint128 totalLiquidityAmount = getAvailableLiquidityAmount(
            address(this), _sqrtAssetStatus.uniswapPool, _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper
        );

        if (totalLiquidityAmount == 0) {
            (_sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper) =
                Reallocation.getNewRange(_assetStatusUnderlying, currentTick);

            saveLastFeeGrowth(_sqrtAssetStatus);

            return (false, true, 0, 0);
        }

        // if the current tick does reach the threshold, then rebalance
        int24 tick;
        bool isOutOfRange;

        if (currentTick < _sqrtAssetStatus.tickLower) {
            // lower out
            isOutOfRange = true;
            tick = _sqrtAssetStatus.tickLower;
        } else if (currentTick < _sqrtAssetStatus.tickUpper) {
            // in range
            isOutOfRange = false;
        } else {
            // upper out
            isOutOfRange = true;
            tick = _sqrtAssetStatus.tickUpper;
        }

        rebalanceForInRange(_assetStatusUnderlying, _sqrtAssetStatus, currentTick, totalLiquidityAmount);

        saveLastFeeGrowth(_sqrtAssetStatus);

        // if the current tick is out of range, then swap
        if (isOutOfRange) {
            (deltaPositionBase, deltaPositionQuote) =
                swapForOutOfRange(_assetStatusUnderlying, currentSqrtPrice, tick, totalLiquidityAmount);
        }

        return (true, true, deltaPositionBase, deltaPositionQuote);
    }

    function rebalanceForInRange(
        DataType.PairStatus storage _assetStatusUnderlying,
        SqrtPerpAssetStatus storage _sqrtAssetStatus,
        int24 _currentTick,
        uint128 _totalLiquidityAmount
    ) internal {
        (uint256 receivedAmount0, uint256 receivedAmount1) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).burn(
            _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, _totalLiquidityAmount
        );

        IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).collect(
            address(this), _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, type(uint128).max, type(uint128).max
        );

        (_sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper) =
            Reallocation.getNewRange(_assetStatusUnderlying, _currentTick);

        (uint256 requiredAmount0, uint256 requiredAmount1) = IUniswapV3Pool(_sqrtAssetStatus.uniswapPool).mint(
            address(this), _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, _totalLiquidityAmount, ""
        );

        // these amounts are originally int256, so we can cast these to int256 safely
        updateRebalancePosition(
            _assetStatusUnderlying,
            int256(receivedAmount0) - int256(requiredAmount0),
            int256(receivedAmount1) - int256(requiredAmount1)
        );
    }

    /**
     * @notice Swaps additional token amounts for rebalance.
     * In case of out-of-range (tick high b1 < x)
     *   token0
     *       1/sqrt(x)　- 1/sqrt(b1)
     *   token1
     *       sqrt(x) - sqrt(b1)
     *
     * In case of out-of-range (tick low x < a1)
     *   token0
     *       1/sqrt(x) - 1/sqrt(a1)
     *   token1
     *       sqrt(x) - sqrt(a1)
     */
    function swapForOutOfRange(
        DataType.PairStatus storage pairStatus,
        uint160 _currentSqrtPrice,
        int24 _tick,
        uint128 _totalLiquidityAmount
    ) internal returns (int256 deltaPositionBase, int256 deltaPositionQuote) {
        uint160 tickSqrtPrice = TickMath.getSqrtRatioAtTick(_tick);

        // 1/_currentSqrtPrice - 1/tickSqrtPrice
        int256 deltaPosition0 =
            LPMath.calculateAmount0ForLiquidity(_currentSqrtPrice, tickSqrtPrice, _totalLiquidityAmount, true);

        // _currentSqrtPrice - tickSqrtPrice
        int256 deltaPosition1 =
            LPMath.calculateAmount1ForLiquidity(_currentSqrtPrice, tickSqrtPrice, _totalLiquidityAmount, true);

        if (pairStatus.isQuoteZero) {
            deltaPositionQuote = -deltaPosition0;
            deltaPositionBase = -deltaPosition1;
        } else {
            deltaPositionBase = -deltaPosition0;
            deltaPositionQuote = -deltaPosition1;
        }

        updateRebalancePosition(pairStatus, deltaPosition0, deltaPosition1);
    }

    function getAvailableLiquidityAmount(
        address _controllerAddress,
        address _uniswapPool,
        int24 _tickLower,
        int24 _tickUpper
    ) internal view returns (uint128) {
        bytes32 positionKey = PositionKey.compute(_controllerAddress, _tickLower, _tickUpper);

        (uint128 liquidity,,,,) = IUniswapV3Pool(_uniswapPool).positions(positionKey);

        return liquidity;
    }

    function settleUserBalance(DataType.PairStatus storage _pairStatus, UserStatus storage _userStatus) internal {
        (int256 deltaPositionUnderlying, int256 deltaPositionStable) =
            updateRebalanceEntry(_pairStatus.sqrtAssetStatus, _userStatus, _pairStatus.isQuoteZero);

        if (deltaPositionUnderlying == 0 && deltaPositionStable == 0) {
            return;
        }

        _userStatus.sqrtPerp.baseRebalanceEntryValue += deltaPositionUnderlying;
        _userStatus.sqrtPerp.quoteRebalanceEntryValue += deltaPositionStable;

        // already settled fee

        _pairStatus.basePool.tokenStatus.updatePosition(
            _pairStatus.sqrtAssetStatus.rebalancePositionBase, -deltaPositionUnderlying, _pairStatus.id, false
        );
        _pairStatus.quotePool.tokenStatus.updatePosition(
            _pairStatus.sqrtAssetStatus.rebalancePositionQuote, -deltaPositionStable, _pairStatus.id, true
        );

        _pairStatus.basePool.tokenStatus.updatePosition(
            _userStatus.basePosition, deltaPositionUnderlying, _pairStatus.id, false
        );
        _pairStatus.quotePool.tokenStatus.updatePosition(
            _userStatus.stablePosition, deltaPositionStable, _pairStatus.id, true
        );
    }

    function updateFeeAndPremiumGrowth(uint256 _pairId, SqrtPerpAssetStatus storage _assetStatus) internal {
        if (_assetStatus.totalAmount == 0) {
            return;
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            UniHelper.getFeeGrowthInside(_assetStatus.uniswapPool, _assetStatus.tickLower, _assetStatus.tickUpper);

        uint256 f0;
        uint256 f1;

        // overflow of feeGrowth is unchecked in Uniswap V3
        unchecked {
            f0 = feeGrowthInside0X128 - _assetStatus.lastFee0Growth;
            f1 = feeGrowthInside1X128 - _assetStatus.lastFee1Growth;
        }

        if (f0 == 0 && f1 == 0) {
            return;
        }

        uint256 utilization = getUtilizationRatio(_assetStatus);

        uint256 spreadParam = PremiumCurveModel.calculatePremiumCurve(utilization);

        _assetStatus.fee0Growth += FullMath.mulDiv(
            f0, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount
        );
        _assetStatus.fee1Growth += FullMath.mulDiv(
            f1, _assetStatus.totalAmount + _assetStatus.borrowedAmount * spreadParam / 1000, _assetStatus.totalAmount
        );

        _assetStatus.borrowPremium0Growth += FullMath.mulDiv(f0, 1000 + spreadParam, 1000);
        _assetStatus.borrowPremium1Growth += FullMath.mulDiv(f1, 1000 + spreadParam, 1000);

        _assetStatus.lastFee0Growth = feeGrowthInside0X128;
        _assetStatus.lastFee1Growth = feeGrowthInside1X128;

        emit PremiumGrowthUpdated(_pairId, _assetStatus.totalAmount, _assetStatus.borrowedAmount, f0, f1, spreadParam);
    }

    function saveLastFeeGrowth(SqrtPerpAssetStatus storage _assetStatus) internal {
        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            UniHelper.getFeeGrowthInside(_assetStatus.uniswapPool, _assetStatus.tickLower, _assetStatus.tickUpper);

        _assetStatus.lastFee0Growth = feeGrowthInside0X128;
        _assetStatus.lastFee1Growth = feeGrowthInside1X128;
    }

    /**
     * @notice Computes reuired amounts to increase or decrease sqrt positions.
     * (L/sqrt{x}, L * sqrt{x})
     */
    function computeRequiredAmounts(
        SqrtPerpAssetStatus storage _sqrtAssetStatus,
        bool _isQuoteZero,
        UserStatus memory _userStatus,
        int256 _tradeSqrtAmount
    ) internal returns (int256 requiredAmountUnderlying, int256 requiredAmountStable) {
        if (_tradeSqrtAmount == 0) {
            return (0, 0);
        }

        if (!Reallocation.isInRange(_sqrtAssetStatus)) {
            revert OutOfRangeError();
        }

        int256 requiredAmount0;
        int256 requiredAmount1;

        if (_tradeSqrtAmount > 0) {
            (requiredAmount0, requiredAmount1) = increase(_sqrtAssetStatus, uint256(_tradeSqrtAmount));

            if (_sqrtAssetStatus.totalAmount == _sqrtAssetStatus.borrowedAmount) {
                // if available liquidity was 0 and added first liquidity then update last fee growth
                saveLastFeeGrowth(_sqrtAssetStatus);
            }
        } else if (_tradeSqrtAmount < 0) {
            (requiredAmount0, requiredAmount1) = decrease(_sqrtAssetStatus, uint256(-_tradeSqrtAmount));
        }

        if (_isQuoteZero) {
            requiredAmountStable = requiredAmount0;
            requiredAmountUnderlying = requiredAmount1;
        } else {
            requiredAmountStable = requiredAmount1;
            requiredAmountUnderlying = requiredAmount0;
        }

        (int256 offsetUnderlying, int256 offsetStable) = calculateSqrtPerpOffset(
            _userStatus, _sqrtAssetStatus.tickLower, _sqrtAssetStatus.tickUpper, _tradeSqrtAmount, _isQuoteZero
        );

        requiredAmountUnderlying -= offsetUnderlying;
        requiredAmountStable -= offsetStable;
    }

    function updatePosition(
        DataType.PairStatus storage _pairStatus,
        UserStatus storage _userStatus,
        UpdatePerpParams memory _updatePerpParams,
        UpdateSqrtPerpParams memory _updateSqrtPerpParams
    ) internal returns (IPredyPool.Payoff memory payoff) {
        (payoff.perpEntryUpdate, payoff.perpPayoff) = calculateEntry(
            _userStatus.perp.amount,
            _userStatus.perp.entryValue,
            _updatePerpParams.tradeAmount,
            _updatePerpParams.stableAmount
        );

        (payoff.sqrtRebalanceEntryUpdateUnderlying, payoff.sqrtRebalanceEntryUpdateStable) = calculateSqrtPerpOffset(
            _userStatus,
            _pairStatus.sqrtAssetStatus.tickLower,
            _pairStatus.sqrtAssetStatus.tickUpper,
            _updateSqrtPerpParams.tradeSqrtAmount,
            _pairStatus.isQuoteZero
        );

        (payoff.sqrtEntryUpdate, payoff.sqrtPayoff) = calculateEntry(
            _userStatus.sqrtPerp.amount,
            _userStatus.sqrtPerp.entryValue,
            _updateSqrtPerpParams.tradeSqrtAmount,
            _updateSqrtPerpParams.stableAmount
        );

        _userStatus.perp.amount += _updatePerpParams.tradeAmount;

        // Update entry value
        _userStatus.perp.entryValue += payoff.perpEntryUpdate;
        _userStatus.sqrtPerp.entryValue += payoff.sqrtEntryUpdate;
        _userStatus.sqrtPerp.quoteRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateStable;
        _userStatus.sqrtPerp.baseRebalanceEntryValue += payoff.sqrtRebalanceEntryUpdateUnderlying;

        // Update sqrt position
        updateSqrtPosition(
            _pairStatus.id, _pairStatus.sqrtAssetStatus, _userStatus, _updateSqrtPerpParams.tradeSqrtAmount
        );

        _pairStatus.basePool.tokenStatus.updatePosition(
            _userStatus.basePosition,
            _updatePerpParams.tradeAmount + payoff.sqrtRebalanceEntryUpdateUnderlying,
            _pairStatus.id,
            false
        );

        _pairStatus.quotePool.tokenStatus.updatePosition(
            _userStatus.stablePosition,
            payoff.perpEntryUpdate + payoff.sqrtEntryUpdate + payoff.sqrtRebalanceEntryUpdateStable,
            _pairStatus.id,
            true
        );
    }

    function updateSqrtPosition(
        uint256 _pairId,
        SqrtPerpAssetStatus storage _assetStatus,
        UserStatus storage _userStatus,
        int256 _amount
    ) internal {
        int256 openAmount;
        int256 closeAmount;

        if (_userStatus.sqrtPerp.amount * _amount >= 0) {
            openAmount = _amount;
        } else {
            if (_userStatus.sqrtPerp.amount.abs() >= _amount.abs()) {
                closeAmount = _amount;
            } else {
                openAmount = _userStatus.sqrtPerp.amount + _amount;
                closeAmount = -_userStatus.sqrtPerp.amount;
            }
        }

        if (_assetStatus.totalAmount == _assetStatus.borrowedAmount) {
            // if available liquidity was 0 and added first liquidity then update last fee growth
            saveLastFeeGrowth(_assetStatus);
        }

        if (closeAmount > 0) {
            _assetStatus.borrowedAmount -= uint256(closeAmount);
        } else if (closeAmount < 0) {
            if (getAvailableSqrtAmount(_assetStatus, true) < uint256(-closeAmount)) {
                revert SqrtAssetCanNotCoverBorrow();
            }
            _assetStatus.totalAmount -= uint256(-closeAmount);
        }

        if (openAmount > 0) {
            _assetStatus.totalAmount += uint256(openAmount);

            _userStatus.sqrtPerp.entryTradeFee0 = _assetStatus.fee0Growth;
            _userStatus.sqrtPerp.entryTradeFee1 = _assetStatus.fee1Growth;
        } else if (openAmount < 0) {
            if (getAvailableSqrtAmount(_assetStatus, false) < uint256(-openAmount)) {
                revert SqrtAssetCanNotCoverBorrow();
            }

            _assetStatus.borrowedAmount += uint256(-openAmount);

            _userStatus.sqrtPerp.entryTradeFee0 = _assetStatus.borrowPremium0Growth;
            _userStatus.sqrtPerp.entryTradeFee1 = _assetStatus.borrowPremium1Growth;
        }

        _userStatus.sqrtPerp.amount += _amount;

        emit SqrtPositionUpdated(_pairId, openAmount, closeAmount);
    }

    /**
     * @notice Gets available sqrt amount
     * max available amount is 98% of total amount
     */
    function getAvailableSqrtAmount(SqrtPerpAssetStatus memory _assetStatus, bool _isWithdraw)
        internal
        pure
        returns (uint256)
    {
        uint256 buffer = Math.max(_assetStatus.totalAmount / 50, Constants.MIN_LIQUIDITY);
        uint256 available = _assetStatus.totalAmount - _assetStatus.borrowedAmount;

        if (_isWithdraw && _assetStatus.borrowedAmount == 0) {
            return available;
        }

        if (available >= buffer) {
            return available - buffer;
        } else {
            return 0;
        }
    }

    function getUtilizationRatio(SqrtPerpAssetStatus memory _assetStatus) internal pure returns (uint256) {
        if (_assetStatus.totalAmount == 0) {
            return 0;
        }

        uint256 utilization = _assetStatus.borrowedAmount * Constants.ONE / _assetStatus.totalAmount;

        if (utilization > 1e18) {
            return 1e18;
        }

        return utilization;
    }

    function updateRebalanceEntry(
        SqrtPerpAssetStatus storage _assetStatus,
        UserStatus storage _userStatus,
        bool _isQuoteZero
    ) internal returns (int256 rebalancePositionUpdateUnderlying, int256 rebalancePositionUpdateStable) {
        // Rebalance position should be over repayed or deposited.
        // rebalancePositionUpdate values must be rounded down to a smaller value.

        if (_userStatus.sqrtPerp.amount == 0) {
            _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
            _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

            return (0, 0);
        }

        if (_assetStatus.lastRebalanceTotalSquartAmount == 0) {
            // last user who settles rebalance position
            _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
            _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

            return
                (_assetStatus.rebalancePositionBase.positionAmount, _assetStatus.rebalancePositionQuote.positionAmount);
        }

        int256 deltaPosition0 = LPMath.calculateAmount0ForLiquidityWithTicks(
            _assetStatus.tickUpper,
            _userStatus.rebalanceLastTickUpper,
            _userStatus.sqrtPerp.amount.abs(),
            _userStatus.sqrtPerp.amount < 0
        );

        int256 deltaPosition1 = LPMath.calculateAmount1ForLiquidityWithTicks(
            _assetStatus.tickLower,
            _userStatus.rebalanceLastTickLower,
            _userStatus.sqrtPerp.amount.abs(),
            _userStatus.sqrtPerp.amount < 0
        );

        _userStatus.rebalanceLastTickLower = _assetStatus.tickLower;
        _userStatus.rebalanceLastTickUpper = _assetStatus.tickUpper;

        if (_userStatus.sqrtPerp.amount < 0) {
            deltaPosition0 = -deltaPosition0;
            deltaPosition1 = -deltaPosition1;
        }

        if (_isQuoteZero) {
            rebalancePositionUpdateUnderlying = deltaPosition1;
            rebalancePositionUpdateStable = deltaPosition0;
        } else {
            rebalancePositionUpdateUnderlying = deltaPosition0;
            rebalancePositionUpdateStable = deltaPosition1;
        }
    }

    function calculateEntry(int256 _positionAmount, int256 _entryValue, int256 _tradeAmount, int256 _valueUpdate)
        internal
        pure
        returns (int256 deltaEntry, int256 payoff)
    {
        if (_tradeAmount == 0) {
            return (0, 0);
        }

        if (_positionAmount * _tradeAmount >= 0) {
            // open position
            deltaEntry = _valueUpdate;
        } else {
            if (_positionAmount.abs() >= _tradeAmount.abs()) {
                // close position

                int256 closeStableAmount = _entryValue * _tradeAmount / _positionAmount;

                deltaEntry = closeStableAmount;
                payoff = _valueUpdate - closeStableAmount;
            } else {
                // close full and open position

                int256 closeStableAmount = -_entryValue;
                int256 openStableAmount = _valueUpdate * (_positionAmount + _tradeAmount) / _tradeAmount;

                deltaEntry = closeStableAmount + openStableAmount;
                payoff = _valueUpdate - closeStableAmount - openStableAmount;
            }
        }
    }

    // private functions

    function increase(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)
        internal
        returns (int256 requiredAmount0, int256 requiredAmount1)
    {
        (uint256 amount0, uint256 amount1) = IUniswapV3Pool(_assetStatus.uniswapPool).mint(
            address(this), _assetStatus.tickLower, _assetStatus.tickUpper, _liquidityAmount.safeCastTo128(), ""
        );

        requiredAmount0 = -SafeCast.toInt256(amount0);
        requiredAmount1 = -SafeCast.toInt256(amount1);
    }

    function decrease(SqrtPerpAssetStatus memory _assetStatus, uint256 _liquidityAmount)
        internal
        returns (int256 receivedAmount0, int256 receivedAmount1)
    {
        if (_assetStatus.totalAmount - _assetStatus.borrowedAmount < _liquidityAmount) {
            revert NoCFMMLiquidityError();
        }

        (uint256 amount0, uint256 amount1) = IUniswapV3Pool(_assetStatus.uniswapPool).burn(
            _assetStatus.tickLower, _assetStatus.tickUpper, _liquidityAmount.safeCastTo128()
        );

        // collect burned token amounts
        IUniswapV3Pool(_assetStatus.uniswapPool).collect(
            address(this), _assetStatus.tickLower, _assetStatus.tickUpper, type(uint128).max, type(uint128).max
        );

        receivedAmount0 = SafeCast.toInt256(amount0);
        receivedAmount1 = SafeCast.toInt256(amount1);
    }

    /**
     * @notice Calculates sqrt perp offset
     * open: (L/sqrt{b}, L * sqrt{a})
     * close: (-L * e0, -L * e1)
     */
    function calculateSqrtPerpOffset(
        UserStatus memory _userStatus,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _tradeSqrtAmount,
        bool _isQuoteZero
    ) internal pure returns (int256 offsetUnderlying, int256 offsetStable) {
        int256 openAmount;
        int256 closeAmount;

        if (_userStatus.sqrtPerp.amount * _tradeSqrtAmount >= 0) {
            openAmount = _tradeSqrtAmount;
        } else {
            if (_userStatus.sqrtPerp.amount.abs() >= _tradeSqrtAmount.abs()) {
                closeAmount = _tradeSqrtAmount;
            } else {
                openAmount = _userStatus.sqrtPerp.amount + _tradeSqrtAmount;
                closeAmount = -_userStatus.sqrtPerp.amount;
            }
        }

        if (openAmount != 0) {
            // L / sqrt(b)
            offsetUnderlying = LPMath.calculateAmount0OffsetWithTick(_tickUpper, openAmount.abs(), openAmount < 0);

            // L * sqrt(a)
            offsetStable = LPMath.calculateAmount1OffsetWithTick(_tickLower, openAmount.abs(), openAmount < 0);

            if (openAmount < 0) {
                offsetUnderlying = -offsetUnderlying;
                offsetStable = -offsetStable;
            }

            if (_isQuoteZero) {
                // Swap if the pool is Stable-Underlying pair
                (offsetUnderlying, offsetStable) = (offsetStable, offsetUnderlying);
            }
        }

        if (closeAmount != 0) {
            offsetStable += closeAmount * _userStatus.sqrtPerp.quoteRebalanceEntryValue / _userStatus.sqrtPerp.amount;
            offsetUnderlying += closeAmount * _userStatus.sqrtPerp.baseRebalanceEntryValue / _userStatus.sqrtPerp.amount;
        }
    }

    function updateRebalancePosition(
        DataType.PairStatus storage _pairStatus,
        int256 _updateAmount0,
        int256 _updateAmount1
    ) internal {
        SqrtPerpAssetStatus storage sqrtAsset = _pairStatus.sqrtAssetStatus;

        if (_pairStatus.isQuoteZero) {
            _pairStatus.quotePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionQuote, _updateAmount0, _pairStatus.id, true
            );
            _pairStatus.basePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionBase, _updateAmount1, _pairStatus.id, false
            );
        } else {
            _pairStatus.basePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionBase, _updateAmount0, _pairStatus.id, false
            );
            _pairStatus.quotePool.tokenStatus.updatePosition(
                sqrtAsset.rebalancePositionQuote, _updateAmount1, _pairStatus.id, true
            );
        }
    }

    /// @notice called after reallocation
    function finalizeReallocation(SqrtPerpAssetStatus storage sqrtPerpStatus) internal {
        // LastRebalanceTotalSquartAmount is the total amount of positions that will have to pay rebalancing interest in the future
        sqrtPerpStatus.lastRebalanceTotalSquartAmount = sqrtPerpStatus.totalAmount + sqrtPerpStatus.borrowedAmount;
        sqrtPerpStatus.numRebalance++;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "./Constants.sol";

library PremiumCurveModel {
    /**
     * @notice Calculates premium curve
     * 0 {ur <= 0.1}
     * 1.6 * (UR-0.1)^2 {0.1 < ur}
     * @param utilization utilization ratio scaled by 1e18
     * @return spread parameter scaled by 1e3
     */
    function calculatePremiumCurve(uint256 utilization) internal pure returns (uint256) {
        if (utilization <= Constants.SQUART_KINK_UR) {
            return 0;
        }

        uint256 b = (utilization - Constants.SQUART_KINK_UR);

        return (1600 * b * b / Constants.ONE) / Constants.ONE;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-core/contracts/libraries/FixedPoint96.sol";
import "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {DataType} from "./DataType.sol";
import "./Perp.sol";
import "./ScaledAsset.sol";

library Reallocation {
    using SafeCast for uint256;

    /**
     * @notice Gets new available range
     */
    function getNewRange(DataType.PairStatus memory _assetStatusUnderlying, int24 currentTick)
        internal
        view
        returns (int24 lower, int24 upper)
    {
        int24 tickSpacing = IUniswapV3Pool(_assetStatusUnderlying.sqrtAssetStatus.uniswapPool).tickSpacing();

        ScaledAsset.AssetStatus memory token0Status;
        ScaledAsset.AssetStatus memory token1Status;

        if (_assetStatusUnderlying.isQuoteZero) {
            token0Status = _assetStatusUnderlying.quotePool.tokenStatus;
            token1Status = _assetStatusUnderlying.basePool.tokenStatus;
        } else {
            token0Status = _assetStatusUnderlying.basePool.tokenStatus;
            token1Status = _assetStatusUnderlying.quotePool.tokenStatus;
        }

        return _getNewRange(_assetStatusUnderlying, token0Status, token1Status, currentTick, tickSpacing);
    }

    function _getNewRange(
        DataType.PairStatus memory _assetStatusUnderlying,
        ScaledAsset.AssetStatus memory _token0Status,
        ScaledAsset.AssetStatus memory _token1Status,
        int24 currentTick,
        int24 tickSpacing
    ) internal pure returns (int24 lower, int24 upper) {
        Perp.SqrtPerpAssetStatus memory sqrtAssetStatus = _assetStatusUnderlying.sqrtAssetStatus;

        lower = currentTick - _assetStatusUnderlying.riskParams.rangeSize;
        upper = currentTick + _assetStatusUnderlying.riskParams.rangeSize;

        int24 previousCenterTick = (sqrtAssetStatus.tickLower + sqrtAssetStatus.tickUpper) / 2;

        uint256 availableAmount = sqrtAssetStatus.totalAmount - sqrtAssetStatus.borrowedAmount;

        if (availableAmount > 0) {
            if (currentTick < previousCenterTick) {
                // move to lower
                int24 minLowerTick = calculateMinLowerTick(
                    sqrtAssetStatus.tickLower,
                    ScaledAsset.getAvailableCollateralValue(_token1Status),
                    availableAmount,
                    tickSpacing
                );

                if (lower < minLowerTick && minLowerTick < currentTick) {
                    lower = minLowerTick;
                    upper = lower + _assetStatusUnderlying.riskParams.rangeSize * 2;
                }
            } else {
                // move to upper
                int24 maxUpperTick = calculateMaxUpperTick(
                    sqrtAssetStatus.tickUpper,
                    ScaledAsset.getAvailableCollateralValue(_token0Status),
                    availableAmount,
                    tickSpacing
                );

                if (upper > maxUpperTick && maxUpperTick >= currentTick) {
                    upper = maxUpperTick;
                    lower = upper - _assetStatusUnderlying.riskParams.rangeSize * 2;
                }
            }
        }

        lower = calculateUsableTick(lower, tickSpacing);
        upper = calculateUsableTick(upper, tickSpacing);
    }

    /**
     * @notice Returns the flag that a tick is within a range or not
     */
    function isInRange(Perp.SqrtPerpAssetStatus memory sqrtAssetStatus) internal view returns (bool) {
        (, int24 currentTick,,,,,) = IUniswapV3Pool(sqrtAssetStatus.uniswapPool).slot0();

        return _isInRange(sqrtAssetStatus, currentTick);
    }

    function _isInRange(Perp.SqrtPerpAssetStatus memory sqrtAssetStatus, int24 currentTick)
        internal
        pure
        returns (bool)
    {
        return (sqrtAssetStatus.tickLower <= currentTick && currentTick < sqrtAssetStatus.tickUpper);
    }

    /**
     * @notice Normalizes a tick by tick spacing
     */
    function calculateUsableTick(int24 _tick, int24 tickSpacing) internal pure returns (int24 result) {
        require(tickSpacing > 0);

        result = _tick;

        if (result < TickMath.MIN_TICK) {
            result = TickMath.MIN_TICK;
        } else if (result > TickMath.MAX_TICK) {
            result = TickMath.MAX_TICK;
        }

        result = (result / tickSpacing) * tickSpacing;
    }

    /**
     * @notice The minimum tick that can be moved from the currentLowerTick, calculated from token1 amount
     */
    function calculateMinLowerTick(
        int24 currentLowerTick,
        uint256 available,
        uint256 liquidityAmount,
        int24 tickSpacing
    ) internal pure returns (int24 minLowerTick) {
        uint160 sqrtPrice =
            calculateAmount1ForLiquidity(TickMath.getSqrtRatioAtTick(currentLowerTick), available, liquidityAmount);

        minLowerTick = TickMath.getTickAtSqrtRatio(sqrtPrice);

        minLowerTick += tickSpacing;

        if (minLowerTick > currentLowerTick - tickSpacing) {
            minLowerTick = currentLowerTick - tickSpacing;
        }
    }

    /**
     * @notice The maximum tick that can be moved from the currentUpperTick, calculated from token0 amount
     */
    function calculateMaxUpperTick(
        int24 currentUpperTick,
        uint256 available,
        uint256 liquidityAmount,
        int24 tickSpacing
    ) internal pure returns (int24 maxUpperTick) {
        uint160 sqrtPrice =
            calculateAmount0ForLiquidity(TickMath.getSqrtRatioAtTick(currentUpperTick), available, liquidityAmount);

        maxUpperTick = TickMath.getTickAtSqrtRatio(sqrtPrice);

        maxUpperTick -= tickSpacing;

        if (maxUpperTick < currentUpperTick + tickSpacing) {
            maxUpperTick = currentUpperTick + tickSpacing;
        }
    }

    function calculateAmount1ForLiquidity(uint160 sqrtRatioA, uint256 available, uint256 liquidityAmount)
        internal
        pure
        returns (uint160)
    {
        uint160 sqrtPrice = (available * FixedPoint96.Q96 / liquidityAmount).toUint160();

        if (sqrtRatioA <= sqrtPrice + TickMath.MIN_SQRT_RATIO) {
            return TickMath.MIN_SQRT_RATIO + 1;
        }

        return sqrtRatioA - sqrtPrice;
    }

    function calculateAmount0ForLiquidity(uint160 sqrtRatioB, uint256 available, uint256 liquidityAmount)
        internal
        pure
        returns (uint160)
    {
        uint256 denominator1 = available * sqrtRatioB / FixedPoint96.Q96;

        if (liquidityAmount <= denominator1) {
            return TickMath.MAX_SQRT_RATIO - 1;
        }

        uint160 sqrtPrice = uint160(liquidityAmount * sqrtRatioB / (liquidityAmount - denominator1));

        if (sqrtPrice <= TickMath.MIN_SQRT_RATIO) {
            return TickMath.MIN_SQRT_RATIO + 1;
        }

        return sqrtPrice;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {FixedPointMathLib} from "lib/solmate/src/utils/FixedPointMathLib.sol";
import {SafeCast} from "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {Constants} from "./Constants.sol";
import {Math} from "./math/Math.sol";

library ScaledAsset {
    using Math for int256;
    using SafeCast for uint256;

    struct AssetStatus {
        uint256 totalCompoundDeposited;
        uint256 totalNormalDeposited;
        uint256 totalNormalBorrowed;
        uint256 assetScaler;
        uint256 assetGrowth;
        uint256 debtGrowth;
    }

    struct UserStatus {
        int256 positionAmount;
        uint256 lastFeeGrowth;
    }

    event ScaledAssetPositionUpdated(uint256 indexed pairId, bool isStable, int256 open, int256 close);

    function createAssetStatus() internal pure returns (AssetStatus memory) {
        return AssetStatus(0, 0, 0, Constants.ONE, 0, 0);
    }

    function createUserStatus() internal pure returns (UserStatus memory) {
        return UserStatus(0, 0);
    }

    function addAsset(AssetStatus storage tokenState, uint256 _amount) internal returns (uint256 claimAmount) {
        if (_amount == 0) {
            return 0;
        }

        claimAmount = FixedPointMathLib.mulDivDown(_amount, Constants.ONE, tokenState.assetScaler);

        tokenState.totalCompoundDeposited += claimAmount;
    }

    function removeAsset(AssetStatus storage tokenState, uint256 _supplyTokenAmount, uint256 _amount)
        internal
        returns (uint256 finalBurnAmount, uint256 finalWithdrawAmount)
    {
        if (_amount == 0) {
            return (0, 0);
        }

        require(_supplyTokenAmount > 0, "S3");

        uint256 burnAmount = FixedPointMathLib.mulDivDown(_amount, Constants.ONE, tokenState.assetScaler);

        if (_supplyTokenAmount < burnAmount) {
            finalBurnAmount = _supplyTokenAmount;
        } else {
            finalBurnAmount = burnAmount;
        }

        finalWithdrawAmount = FixedPointMathLib.mulDivDown(finalBurnAmount, tokenState.assetScaler, Constants.ONE);

        require(getAvailableCollateralValue(tokenState) >= finalWithdrawAmount, "S0");

        tokenState.totalCompoundDeposited -= finalBurnAmount;
    }

    function isSameSign(int256 a, int256 b) internal pure returns (bool) {
        return (a >= 0 && b >= 0) || (a < 0 && b < 0);
    }

    function updatePosition(
        ScaledAsset.AssetStatus storage tokenStatus,
        ScaledAsset.UserStatus storage userStatus,
        int256 _amount,
        uint256 _pairId,
        bool _isStable
    ) internal {
        // Confirms fee has been settled before position updating.
        if (userStatus.positionAmount > 0) {
            require(userStatus.lastFeeGrowth == tokenStatus.assetGrowth, "S2");
        } else if (userStatus.positionAmount < 0) {
            require(userStatus.lastFeeGrowth == tokenStatus.debtGrowth, "S2");
        }

        int256 openAmount;
        int256 closeAmount;

        if (isSameSign(userStatus.positionAmount, _amount)) {
            openAmount = _amount;
        } else {
            if (userStatus.positionAmount.abs() >= _amount.abs()) {
                closeAmount = _amount;
            } else {
                openAmount = userStatus.positionAmount + _amount;
                closeAmount = -userStatus.positionAmount;
            }
        }

        if (closeAmount > 0) {
            tokenStatus.totalNormalBorrowed -= uint256(closeAmount);
        } else if (closeAmount < 0) {
            // not to check available amount
            require(getAvailableCollateralValue(tokenStatus) >= uint256(-closeAmount), "S0");

            tokenStatus.totalNormalDeposited -= uint256(-closeAmount);
        }

        if (openAmount > 0) {
            tokenStatus.totalNormalDeposited += uint256(openAmount);

            userStatus.lastFeeGrowth = tokenStatus.assetGrowth;
        } else if (openAmount < 0) {
            require(getAvailableCollateralValue(tokenStatus) >= uint256(-openAmount), "S0");

            tokenStatus.totalNormalBorrowed += uint256(-openAmount);

            userStatus.lastFeeGrowth = tokenStatus.debtGrowth;
        }

        userStatus.positionAmount += _amount;

        emit ScaledAssetPositionUpdated(_pairId, _isStable, openAmount, closeAmount);
    }

    function computeUserFee(ScaledAsset.AssetStatus memory _assetStatus, ScaledAsset.UserStatus memory _userStatus)
        internal
        pure
        returns (int256 interestFee)
    {
        if (_userStatus.positionAmount > 0) {
            interestFee = (getAssetFee(_assetStatus, _userStatus)).toInt256();
        } else {
            interestFee = -(getDebtFee(_assetStatus, _userStatus)).toInt256();
        }
    }

    function settleUserFee(ScaledAsset.AssetStatus memory _assetStatus, ScaledAsset.UserStatus storage _userStatus)
        internal
        returns (int256 interestFee)
    {
        interestFee = computeUserFee(_assetStatus, _userStatus);

        if (_userStatus.positionAmount > 0) {
            _userStatus.lastFeeGrowth = _assetStatus.assetGrowth;
        } else {
            _userStatus.lastFeeGrowth = _assetStatus.debtGrowth;
        }
    }

    function getAssetFee(AssetStatus memory tokenState, UserStatus memory accountState)
        internal
        pure
        returns (uint256)
    {
        require(accountState.positionAmount >= 0, "S1");

        return FixedPointMathLib.mulDivDown(
            tokenState.assetGrowth - accountState.lastFeeGrowth,
            // never overflow
            uint256(accountState.positionAmount),
            Constants.ONE
        );
    }

    function getDebtFee(AssetStatus memory tokenState, UserStatus memory accountState)
        internal
        pure
        returns (uint256)
    {
        require(accountState.positionAmount <= 0, "S1");

        return FixedPointMathLib.mulDivUp(
            tokenState.debtGrowth - accountState.lastFeeGrowth,
            // never overflow
            uint256(-accountState.positionAmount),
            Constants.ONE
        );
    }

    // update scaler
    function updateScaler(AssetStatus storage tokenState, uint256 _interestRate, uint8 _reserveFactor)
        internal
        returns (uint256)
    {
        if (tokenState.totalCompoundDeposited == 0 && tokenState.totalNormalDeposited == 0) {
            return 0;
        }

        uint256 protocolFee = FixedPointMathLib.mulDivDown(
            FixedPointMathLib.mulDivDown(_interestRate, getTotalDebtValue(tokenState), Constants.ONE),
            _reserveFactor,
            100
        );

        // supply interest rate is InterestRate * Utilization * (1 - ReserveFactor)
        uint256 supplyInterestRate = FixedPointMathLib.mulDivDown(
            FixedPointMathLib.mulDivDown(
                _interestRate, getTotalDebtValue(tokenState), getTotalCollateralValue(tokenState)
            ),
            100 - _reserveFactor,
            100
        );

        tokenState.debtGrowth += _interestRate;
        tokenState.assetScaler =
            FixedPointMathLib.mulDivDown(tokenState.assetScaler, Constants.ONE + supplyInterestRate, Constants.ONE);
        tokenState.assetGrowth += supplyInterestRate;

        return protocolFee;
    }

    function getTotalCollateralValue(AssetStatus memory tokenState) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivDown(tokenState.totalCompoundDeposited, tokenState.assetScaler, Constants.ONE)
            + tokenState.totalNormalDeposited;
    }

    function getTotalDebtValue(AssetStatus memory tokenState) internal pure returns (uint256) {
        return tokenState.totalNormalBorrowed;
    }

    function getAvailableCollateralValue(AssetStatus memory tokenState) internal pure returns (uint256) {
        return getTotalCollateralValue(tokenState) - getTotalDebtValue(tokenState);
    }

    function getUtilizationRatio(AssetStatus memory tokenState) internal pure returns (uint256) {
        if (tokenState.totalCompoundDeposited == 0 && tokenState.totalNormalDeposited == 0) {
            return 0;
        }

        uint256 utilization = FixedPointMathLib.mulDivDown(
            getTotalDebtValue(tokenState), Constants.ONE, getTotalCollateralValue(tokenState)
        );

        if (utilization > 1e18) {
            return 1e18;
        }

        return utilization;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IPredyPool} from "../interfaces/IPredyPool.sol";
import {Constants} from "./Constants.sol";
import {Bps} from "./math/Bps.sol";
import {Math} from "./math/Math.sol";

library SlippageLib {
    using Bps for uint256;

    // 1.5% scaled by 1e8
    uint256 public constant MAX_ACCEPTABLE_SQRT_PRICE_RANGE = 100747209;

    error InvalidAveragePrice();

    error SlippageTooLarge();

    error OutOfAcceptablePriceRange();

    function checkPrice(
        uint256 sqrtBasePrice,
        IPredyPool.TradeResult memory tradeResult,
        uint256 slippageTolerance,
        uint256 maxAcceptableSqrtPriceRange
    ) internal pure {
        uint256 basePrice = Math.calSqrtPriceToPrice(sqrtBasePrice);

        if (tradeResult.averagePrice == 0) {
            revert InvalidAveragePrice();
        }

        if (tradeResult.averagePrice > 0) {
            // short
            if (basePrice.lower(slippageTolerance) > uint256(tradeResult.averagePrice)) {
                revert SlippageTooLarge();
            }
        } else if (tradeResult.averagePrice < 0) {
            // long
            if (basePrice.upper(slippageTolerance) < uint256(-tradeResult.averagePrice)) {
                revert SlippageTooLarge();
            }
        }

        if (
            maxAcceptableSqrtPriceRange > 0
                && (
                    tradeResult.sqrtPrice < sqrtBasePrice * 1e8 / maxAcceptableSqrtPriceRange
                        || sqrtBasePrice * maxAcceptableSqrtPriceRange / 1e8 < tradeResult.sqrtPrice
                )
        ) {
            revert OutOfAcceptablePriceRange();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "lib/v3-core/contracts/libraries/TickMath.sol";
import "lib/v3-periphery/contracts/libraries/PositionKey.sol";
import "../vendors/IUniswapV3PoolOracle.sol";
import "./Constants.sol";

library UniHelper {
    uint256 internal constant _ORACLE_PERIOD = 30 minutes;

    function getSqrtPrice(address uniswapPoolAddress) internal view returns (uint160 sqrtPrice) {
        (sqrtPrice,,,,,,) = IUniswapV3Pool(uniswapPoolAddress).slot0();
    }

    /**
     * Gets square root of time weighted average price.
     */
    function getSqrtTWAP(address uniswapPoolAddress) internal view returns (uint160 sqrtTwapX96) {
        (sqrtTwapX96,) = callUniswapObserve(IUniswapV3Pool(uniswapPoolAddress), _ORACLE_PERIOD);
    }

    /**
     * sqrt price in stable token
     */
    function convertSqrtPrice(uint160 sqrtPriceX96, bool isQuoteZero) internal pure returns (uint160) {
        if (isQuoteZero) {
            return uint160((Constants.Q96 << Constants.RESOLUTION) / sqrtPriceX96);
        } else {
            return sqrtPriceX96;
        }
    }

    function callUniswapObserve(IUniswapV3Pool uniswapPool, uint256 ago) internal view returns (uint160, uint256) {
        uint32[] memory secondsAgos = new uint32[](2);

        secondsAgos[0] = uint32(ago);
        secondsAgos[1] = 0;

        (bool success, bytes memory data) =
            address(uniswapPool).staticcall(abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos));

        if (!success) {
            if (keccak256(data) != keccak256(abi.encodeWithSignature("Error(string)", "OLD"))) {
                revertBytes(data);
            }

            (,, uint16 index, uint16 cardinality,,,) = uniswapPool.slot0();

            (uint32 oldestAvailableAge,,, bool initialized) = uniswapPool.observations((index + 1) % cardinality);

            if (!initialized) {
                (oldestAvailableAge,,,) = uniswapPool.observations(0);
            }

            ago = block.timestamp - oldestAvailableAge;
            secondsAgos[0] = uint32(ago);

            (success, data) = address(uniswapPool).staticcall(
                abi.encodeWithSelector(IUniswapV3PoolOracle.observe.selector, secondsAgos)
            );
            if (!success) {
                revertBytes(data);
            }
        }

        int56[] memory tickCumulatives = abi.decode(data, (int56[]));

        int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(int256(ago)));

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(tick);

        return (sqrtPriceX96, ago);
    }

    function revertBytes(bytes memory errMsg) internal pure {
        if (errMsg.length > 0) {
            assembly {
                revert(add(32, errMsg), mload(errMsg))
            }
        }

        revert("e/empty-error");
    }

    function getFeeGrowthInsideLast(address uniswapPoolAddress, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128)
    {
        bytes32 positionKey = PositionKey.compute(address(this), tickLower, tickUpper);

        // this is now updated to the current transaction
        (, feeGrowthInside0LastX128, feeGrowthInside1LastX128,,) =
            IUniswapV3Pool(uniswapPoolAddress).positions(positionKey);
    }

    function getFeeGrowthInside(address uniswapPoolAddress, int24 tickLower, int24 tickUpper)
        internal
        view
        returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128)
    {
        (, int24 tickCurrent,,,,,) = IUniswapV3Pool(uniswapPoolAddress).slot0();

        uint256 feeGrowthGlobal0X128 = IUniswapV3Pool(uniswapPoolAddress).feeGrowthGlobal0X128();
        uint256 feeGrowthGlobal1X128 = IUniswapV3Pool(uniswapPoolAddress).feeGrowthGlobal1X128();

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;

        unchecked {
            {
                (,, uint256 lowerFeeGrowthOutside0X128, uint256 lowerFeeGrowthOutside1X128,,,,) =
                    IUniswapV3Pool(uniswapPoolAddress).ticks(tickLower);

                if (tickCurrent >= tickLower) {
                    feeGrowthBelow0X128 = lowerFeeGrowthOutside0X128;
                    feeGrowthBelow1X128 = lowerFeeGrowthOutside1X128;
                } else {
                    feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lowerFeeGrowthOutside0X128;
                    feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lowerFeeGrowthOutside1X128;
                }
            }

            // calculate fee growth above
            uint256 feeGrowthAbove0X128;
            uint256 feeGrowthAbove1X128;

            {
                (,, uint256 upperFeeGrowthOutside0X128, uint256 upperFeeGrowthOutside1X128,,,,) =
                    IUniswapV3Pool(uniswapPoolAddress).ticks(tickUpper);

                if (tickCurrent < tickUpper) {
                    feeGrowthAbove0X128 = upperFeeGrowthOutside0X128;
                    feeGrowthAbove1X128 = upperFeeGrowthOutside1X128;
                } else {
                    feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upperFeeGrowthOutside0X128;
                    feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upperFeeGrowthOutside1X128;
                }
            }

            feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
            feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library ArrayLib {
    function addItem(uint256[] storage items, uint256 item) internal {
        items.push(item);
    }

    function removeItem(uint256[] storage items, uint256 item) internal {
        uint256 index = getItemIndex(items, item);

        removeItemByIndex(items, index);
    }

    function removeItemByIndex(uint256[] storage items, uint256 index) internal {
        items[index] = items[items.length - 1];
        items.pop();
    }

    function getItemIndex(uint256[] memory items, uint256 item) internal pure returns (uint256) {
        uint256 index = type(uint256).max;

        for (uint256 i = 0; i < items.length; i++) {
            if (items[i] == item) {
                index = i;
                break;
            }
        }

        return index;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {OrderInfo, OrderInfoLib} from "../../libraries/orders/OrderInfoLib.sol";
import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {ResolvedOrder} from "../../libraries/orders/ResolvedOrder.sol";

struct GammaModifyInfo {
    bool isEnabled;
    uint64 expiration;
    uint256 lowerLimit;
    uint256 upperLimit;
    uint32 hedgeInterval;
    uint32 sqrtPriceTrigger;
    uint32 minSlippageTolerance;
    uint32 maxSlippageTolerance;
    uint16 auctionPeriod;
    uint32 auctionRange;
}

library GammaModifyInfoLib {
    bytes internal constant GAMMA_MODIFY_INFO_TYPE = abi.encodePacked(
        "GammaModifyInfo(",
        "bool isEnabled,",
        "uint64 expiration,",
        "uint256 lowerLimit,",
        "uint256 upperLimit,",
        "uint32 hedgeInterval,",
        "uint32 sqrtPriceTrigger,",
        "uint32 minSlippageTolerance,",
        "uint32 maxSlippageTolerance,",
        "uint16 auctionPeriod,",
        "uint32 auctionRange)"
    );

    bytes32 internal constant GAMMA_MODIFY_INFO_TYPE_HASH = keccak256(GAMMA_MODIFY_INFO_TYPE);

    /// @notice hash an GammaModifyInfo object
    /// @param info The GammaModifyInfo object to hash
    function hash(GammaModifyInfo memory info) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                GAMMA_MODIFY_INFO_TYPE_HASH,
                info.isEnabled,
                info.expiration,
                info.lowerLimit,
                info.upperLimit,
                info.hedgeInterval,
                info.sqrtPriceTrigger,
                info.minSlippageTolerance,
                info.maxSlippageTolerance,
                info.auctionPeriod,
                info.auctionRange
            )
        );
    }
}

struct GammaOrder {
    OrderInfo info;
    uint64 pairId;
    uint256 positionId;
    address entryTokenAddress;
    int256 quantity;
    int256 quantitySqrt;
    int256 marginAmount;
    uint256 baseSqrtPrice;
    uint32 slippageTolerance;
    uint8 leverage;
    GammaModifyInfo modifyInfo;
}

/// @notice helpers for handling general order objects
library GammaOrderLib {
    using OrderInfoLib for OrderInfo;

    bytes internal constant GAMMA_ORDER_TYPE = abi.encodePacked(
        "GammaOrder(",
        "OrderInfo info,",
        "uint64 pairId,",
        "uint256 positionId,",
        "address entryTokenAddress,",
        "int256 quantity,",
        "int256 quantitySqrt,",
        "int256 marginAmount,",
        "uint256 baseSqrtPrice,",
        "uint32 slippageTolerance,",
        "uint8 leverage,",
        "GammaModifyInfo modifyInfo)"
    );

    /// @dev Note that sub-structs have to be defined in alphabetical order in the EIP-712 spec
    bytes internal constant ORDER_TYPE =
        abi.encodePacked(GAMMA_ORDER_TYPE, GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE, OrderInfoLib.ORDER_INFO_TYPE);
    bytes32 internal constant GAMMA_ORDER_TYPE_HASH = keccak256(ORDER_TYPE);

    string internal constant TOKEN_PERMISSIONS_TYPE = "TokenPermissions(address token,uint256 amount)";
    string internal constant PERMIT2_ORDER_TYPE = string(
        abi.encodePacked(
            "GammaOrder witness)",
            GammaModifyInfoLib.GAMMA_MODIFY_INFO_TYPE,
            GAMMA_ORDER_TYPE,
            OrderInfoLib.ORDER_INFO_TYPE,
            TOKEN_PERMISSIONS_TYPE
        )
    );

    /// @notice hash the given order
    /// @param order the order to hash
    /// @return the eip-712 order hash
    function hash(GammaOrder memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encode(
                GAMMA_ORDER_TYPE_HASH,
                order.info.hash(),
                order.pairId,
                order.positionId,
                order.entryTokenAddress,
                order.quantity,
                order.quantitySqrt,
                order.marginAmount,
                order.baseSqrtPrice,
                order.slippageTolerance,
                order.leverage,
                GammaModifyInfoLib.hash(order.modifyInfo)
            )
        );
    }

    function resolve(GammaOrder memory gammaOrder, bytes memory sig) internal pure returns (ResolvedOrder memory) {
        uint256 amount = gammaOrder.marginAmount > 0 ? uint256(gammaOrder.marginAmount) : 0;

        return ResolvedOrder(gammaOrder.info, gammaOrder.entryTokenAddress, amount, hash(gammaOrder), sig);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {ReentrancyGuardUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import {IPermit2} from "lib/permit2/src/interfaces/IPermit2.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";
import {IFillerMarket} from "../../interfaces/IFillerMarket.sol";
import {BaseMarketUpgradable} from "../../base/BaseMarketUpgradable.sol";
import {BaseHookCallbackUpgradable} from "../../base/BaseHookCallbackUpgradable.sol";
import {Permit2Lib} from "../../libraries/orders/Permit2Lib.sol";
import {ResolvedOrder, ResolvedOrderLib} from "../../libraries/orders/ResolvedOrder.sol";
import {SlippageLib} from "../../libraries/SlippageLib.sol";
import {Bps} from "../../libraries/math/Bps.sol";
import {DataType} from "../../libraries/DataType.sol";
import {Constants} from "../../libraries/Constants.sol";
import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";
import {ArrayLib} from "./ArrayLib.sol";
import {GammaTradeMarketLib} from "./GammaTradeMarketLib.sol";

/**
 * @notice Gamma trade market contract
 */
contract GammaTradeMarket is IFillerMarket, BaseMarketUpgradable, ReentrancyGuardUpgradeable {
    using ResolvedOrderLib for ResolvedOrder;
    using ArrayLib for uint256[];
    using GammaOrderLib for GammaOrder;
    using Permit2Lib for ResolvedOrder;
    using SafeTransferLib for ERC20;

    error PositionNotFound();
    error PositionHasDifferentPairId();
    error PositionIsNotClosed();
    error InvalidOrder();
    error SignerIsNotPositionOwner();
    error TooShortHedgeInterval();
    error HedgeTriggerNotMatched();
    error DeltaIsZero();
    error AlreadyClosed();
    error AutoCloseTriggerNotMatched();
    error MarginUpdateMustBeZero();

    struct UserPosition {
        uint256 vaultId;
        address owner;
        uint64 pairId;
        uint8 leverage;
        uint256 expiration;
        uint256 lowerLimit;
        uint256 upperLimit;
        uint256 lastHedgedTime;
        uint256 hedgeInterval;
        uint256 lastHedgedSqrtPrice;
        uint256 sqrtPriceTrigger;
        GammaTradeMarketLib.AuctionParams auctionParams;
    }

    enum CallbackType {
        NONE,
        QUOTE,
        TRADE,
        CLOSE,
        HEDGE_BY_TIME,
        HEDGE_BY_PRICE,
        CLOSE_BY_TIME,
        CLOSE_BY_PRICE
    }

    struct CallbackData {
        CallbackType callbackType;
        address trader;
        int256 marginAmountUpdate;
    }

    IPermit2 internal _permit2;

    mapping(address owner => uint256[]) public positionIDs;
    mapping(uint256 positionId => UserPosition) internal userPositions;

    event GammaPositionTraded(
        address indexed trader,
        uint256 pairId,
        uint256 positionId,
        int256 quantity,
        int256 quantitySqrt,
        IPredyPool.Payoff payoff,
        int256 fee,
        int256 marginAmount,
        CallbackType callbackType
    );

    event GammaPositionModified(address indexed trader, uint256 pairId, uint256 positionId, GammaModifyInfo modifyInfo);

    constructor() {}

    function initialize(IPredyPool predyPool, address permit2Address, address whitelistFiller, address quoterAddress)
        public
        initializer
    {
        __ReentrancyGuard_init();
        __BaseMarket_init(predyPool, whitelistFiller, quoterAddress);

        _permit2 = IPermit2(permit2Address);
    }

    function predyTradeAfterCallback(
        IPredyPool.TradeParams memory tradeParams,
        IPredyPool.TradeResult memory tradeResult
    ) external override(BaseHookCallbackUpgradable) onlyPredyPool {
        CallbackData memory callbackData = abi.decode(tradeParams.extraData, (CallbackData));
        ERC20 quoteToken = ERC20(_getQuoteTokenAddress(tradeParams.pairId));

        if (callbackData.callbackType == CallbackType.QUOTE) {
            _revertTradeResult(tradeResult);
        } else {
            if (tradeResult.minMargin == 0) {
                if (callbackData.marginAmountUpdate != 0) {
                    revert MarginUpdateMustBeZero();
                }

                DataType.Vault memory vault = _predyPool.getVault(tradeParams.vaultId);

                _predyPool.take(true, callbackData.trader, uint256(vault.margin));

                // remove position index
                _removePosition(tradeParams.vaultId);

                emit GammaPositionTraded(
                    callbackData.trader,
                    tradeParams.pairId,
                    tradeParams.vaultId,
                    tradeParams.tradeAmount,
                    tradeParams.tradeAmountSqrt,
                    tradeResult.payoff,
                    tradeResult.fee,
                    -vault.margin,
                    callbackData.callbackType == CallbackType.TRADE ? CallbackType.CLOSE : callbackData.callbackType
                );
            } else {
                int256 marginAmountUpdate = callbackData.marginAmountUpdate;

                if (marginAmountUpdate > 0) {
                    quoteToken.safeTransfer(address(_predyPool), uint256(marginAmountUpdate));
                } else if (marginAmountUpdate < 0) {
                    _predyPool.take(true, callbackData.trader, uint256(-marginAmountUpdate));
                }

                emit GammaPositionTraded(
                    callbackData.trader,
                    tradeParams.pairId,
                    tradeParams.vaultId,
                    tradeParams.tradeAmount,
                    tradeParams.tradeAmountSqrt,
                    tradeResult.payoff,
                    tradeResult.fee,
                    marginAmountUpdate,
                    callbackData.callbackType
                );
            }
        }
    }

    function execLiquidationCall(
        uint256 vaultId,
        uint256 closeRatio,
        IFillerMarket.SettlementParamsV3 memory settlementParams
    ) external override returns (IPredyPool.TradeResult memory tradeResult) {
        tradeResult =
            _predyPool.execLiquidationCall(vaultId, closeRatio, _getSettlementDataFromV3(settlementParams, msg.sender));

        if (closeRatio == 1e18) {
            _removePosition(vaultId);
        }
    }

    // open position
    function _executeTrade(GammaOrder memory gammaOrder, bytes memory sig, SettlementParamsV3 memory settlementParams)
        internal
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        ResolvedOrder memory resolvedOrder = GammaOrderLib.resolve(gammaOrder, sig);

        _validateQuoteTokenAddress(gammaOrder.pairId, gammaOrder.entryTokenAddress);

        _verifyOrder(resolvedOrder);

        // execute trade
        tradeResult = _predyPool.trade(
            IPredyPool.TradeParams(
                gammaOrder.pairId,
                gammaOrder.positionId,
                gammaOrder.quantity,
                gammaOrder.quantitySqrt,
                abi.encode(CallbackData(CallbackType.TRADE, gammaOrder.info.trader, gammaOrder.marginAmount))
            ),
            _getSettlementDataFromV3(settlementParams, msg.sender)
        );

        if (tradeResult.minMargin > 0) {
            // only whitelisted filler can open position
            if (msg.sender != whitelistFiller) {
                revert CallerIsNotFiller();
            }
        }

        UserPosition storage userPosition = _getOrInitPosition(
            tradeResult.vaultId, gammaOrder.positionId == 0, gammaOrder.info.trader, gammaOrder.pairId
        );

        _saveUserPosition(userPosition, gammaOrder.modifyInfo);

        userPosition.leverage = gammaOrder.leverage;

        // init last hedge status
        userPosition.lastHedgedSqrtPrice = tradeResult.sqrtTwap;
        userPosition.lastHedgedTime = block.timestamp;

        if (gammaOrder.positionId == 0) {
            _addPositionIndex(gammaOrder.info.trader, userPosition.vaultId);

            _predyPool.updateRecepient(tradeResult.vaultId, gammaOrder.info.trader);
        }

        SlippageLib.checkPrice(
            gammaOrder.baseSqrtPrice,
            tradeResult,
            gammaOrder.slippageTolerance,
            SlippageLib.MAX_ACCEPTABLE_SQRT_PRICE_RANGE
        );
    }

    function _modifyAutoHedgeAndClose(GammaOrder memory gammaOrder, bytes memory sig) internal {
        if (gammaOrder.quantity != 0 || gammaOrder.quantitySqrt != 0 || gammaOrder.marginAmount != 0) {
            revert InvalidOrder();
        }

        ResolvedOrder memory resolvedOrder = GammaOrderLib.resolve(gammaOrder, sig);

        _verifyOrder(resolvedOrder);

        // save user position
        UserPosition storage userPosition =
            _getOrInitPosition(gammaOrder.positionId, false, gammaOrder.info.trader, gammaOrder.pairId);

        _saveUserPosition(userPosition, gammaOrder.modifyInfo);
    }

    function autoHedge(uint256 positionId, SettlementParamsV3 memory settlementParams)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        UserPosition storage userPosition = userPositions[positionId];

        if (userPosition.vaultId == 0 || positionId != userPosition.vaultId) {
            revert PositionNotFound();
        }

        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(userPosition.pairId);

        // check auto hedge condition
        (bool hedgeRequired, uint256 slippageTorelance, CallbackType triggerType) =
            _validateHedgeCondition(userPosition, sqrtPrice);

        if (!hedgeRequired) {
            revert HedgeTriggerNotMatched();
        }

        userPosition.lastHedgedSqrtPrice = sqrtPrice;
        userPosition.lastHedgedTime = block.timestamp;

        // execute trade
        DataType.Vault memory vault = _predyPool.getVault(userPosition.vaultId);

        int256 delta = _calculateDelta(sqrtPrice, vault.openPosition.sqrtPerp.amount, vault.openPosition.perp.amount);

        if (delta == 0) {
            revert DeltaIsZero();
        }

        IPredyPool.TradeParams memory tradeParams = IPredyPool.TradeParams(
            userPosition.pairId,
            userPosition.vaultId,
            -delta,
            0,
            abi.encode(CallbackData(triggerType, userPosition.owner, 0))
        );

        tradeResult = _predyPool.trade(tradeParams, _getSettlementDataFromV3(settlementParams, msg.sender));

        SlippageLib.checkPrice(sqrtPrice, tradeResult, slippageTorelance, SlippageLib.MAX_ACCEPTABLE_SQRT_PRICE_RANGE);
    }

    function autoClose(uint256 positionId, SettlementParamsV3 memory settlementParams)
        external
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        // save user position
        UserPosition memory userPosition = userPositions[positionId];

        if (userPosition.vaultId == 0 || positionId != userPosition.vaultId) {
            revert PositionNotFound();
        }

        // check auto close condition
        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(userPosition.pairId);

        (bool closeRequired, uint256 slippageTorelance, CallbackType triggerType) =
            _validateCloseCondition(userPosition, sqrtPrice);

        if (!closeRequired) {
            revert AutoCloseTriggerNotMatched();
        }

        // execute close
        DataType.Vault memory vault = _predyPool.getVault(userPosition.vaultId);

        IPredyPool.TradeParams memory tradeParams = IPredyPool.TradeParams(
            userPosition.pairId,
            userPosition.vaultId,
            -vault.openPosition.perp.amount,
            -vault.openPosition.sqrtPerp.amount,
            abi.encode(CallbackData(triggerType, userPosition.owner, 0))
        );

        if (tradeParams.tradeAmount == 0 && tradeParams.tradeAmountSqrt == 0) {
            revert AlreadyClosed();
        }

        tradeResult = _predyPool.trade(tradeParams, _getSettlementDataFromV3(settlementParams, msg.sender));

        SlippageLib.checkPrice(sqrtPrice, tradeResult, slippageTorelance, SlippageLib.MAX_ACCEPTABLE_SQRT_PRICE_RANGE);
    }

    function quoteTrade(GammaOrder memory gammaOrder, SettlementParamsV3 memory settlementParams) external {
        // execute trade
        _predyPool.trade(
            IPredyPool.TradeParams(
                gammaOrder.pairId,
                gammaOrder.positionId,
                gammaOrder.quantity,
                gammaOrder.quantitySqrt,
                abi.encode(CallbackData(CallbackType.QUOTE, gammaOrder.info.trader, gammaOrder.marginAmount))
            ),
            _getSettlementDataFromV3(settlementParams, msg.sender)
        );
    }

    function checkAutoHedgeAndClose(uint256 positionId)
        external
        view
        returns (bool hedgeRequired, bool closeRequired, uint256 resultPositionId)
    {
        UserPosition memory userPosition = userPositions[positionId];

        DataType.Vault memory vault = _predyPool.getVault(userPosition.vaultId);

        if (vault.openPosition.perp.amount == 0 && vault.openPosition.sqrtPerp.amount == 0) {
            return (false, false, positionId);
        }

        uint256 sqrtPrice = _predyPool.getSqrtIndexPrice(userPosition.pairId);

        (hedgeRequired,,) = _validateHedgeCondition(userPosition, sqrtPrice);

        (closeRequired,,) = _validateCloseCondition(userPosition, sqrtPrice);

        resultPositionId = positionId;
    }

    struct UserPositionResult {
        UserPosition userPosition;
        IPredyPool.VaultStatus vaultStatus;
        DataType.Vault vault;
    }

    function getUserPositions(address owner) external returns (UserPositionResult[] memory) {
        uint256[] memory userPositionIDs = positionIDs[owner];

        UserPositionResult[] memory results = new UserPositionResult[](userPositionIDs.length);

        for (uint64 i = 0; i < userPositionIDs.length; i++) {
            uint256 positionId = userPositionIDs[i];

            results[i] = _getUserPosition(positionId);
        }

        return results;
    }

    function _getUserPosition(uint256 positionId) internal returns (UserPositionResult memory result) {
        UserPosition memory userPosition = userPositions[positionId];

        if (userPosition.vaultId == 0) {
            // if user has no position, return empty vault status and vault
            return result;
        }

        return UserPositionResult(
            userPosition, _quoter.quoteVaultStatus(userPosition.vaultId), _predyPool.getVault(userPosition.vaultId)
        );
    }

    function _addPositionIndex(address trader, uint256 newPositionId) internal {
        positionIDs[trader].addItem(newPositionId);
    }

    function removePosition(uint256 positionId) external onlyFiller {
        DataType.Vault memory vault = _predyPool.getVault(userPositions[positionId].vaultId);

        if (vault.margin != 0 || vault.openPosition.perp.amount != 0 || vault.openPosition.sqrtPerp.amount != 0) {
            revert PositionIsNotClosed();
        }

        _removePosition(positionId);
    }

    function _removePosition(uint256 positionId) internal {
        address trader = userPositions[positionId].owner;

        positionIDs[trader].removeItem(positionId);
    }

    function _getOrInitPosition(uint256 positionId, bool isCreatedNew, address trader, uint64 pairId)
        internal
        returns (UserPosition storage userPosition)
    {
        userPosition = userPositions[positionId];

        if (isCreatedNew) {
            userPosition.vaultId = positionId;
            userPosition.owner = trader;
            userPosition.pairId = pairId;
            return userPosition;
        }

        if (positionId == 0 || userPosition.vaultId == 0) {
            revert PositionNotFound();
        }

        if (userPosition.owner != trader) {
            revert SignerIsNotPositionOwner();
        }

        if (userPosition.pairId != pairId) {
            revert PositionHasDifferentPairId();
        }

        return userPosition;
    }

    function _saveUserPosition(UserPosition storage userPosition, GammaModifyInfo memory modifyInfo) internal {
        if (!modifyInfo.isEnabled) {
            return;
        }

        if (0 < modifyInfo.hedgeInterval && 10 minutes > modifyInfo.hedgeInterval) {
            revert TooShortHedgeInterval();
        }

        require(modifyInfo.maxSlippageTolerance >= modifyInfo.minSlippageTolerance);
        require(modifyInfo.maxSlippageTolerance <= 2 * Bps.ONE);

        // auto close condition
        userPosition.expiration = modifyInfo.expiration;
        userPosition.lowerLimit = modifyInfo.lowerLimit;
        userPosition.upperLimit = modifyInfo.upperLimit;

        // auto hedge condition
        userPosition.hedgeInterval = modifyInfo.hedgeInterval;
        userPosition.sqrtPriceTrigger = modifyInfo.sqrtPriceTrigger;
        userPosition.auctionParams.minSlippageTolerance = modifyInfo.minSlippageTolerance;
        userPosition.auctionParams.maxSlippageTolerance = modifyInfo.maxSlippageTolerance;
        userPosition.auctionParams.auctionPeriod = modifyInfo.auctionPeriod;
        userPosition.auctionParams.auctionRange = modifyInfo.auctionRange;

        emit GammaPositionModified(userPosition.owner, userPosition.pairId, userPosition.vaultId, modifyInfo);
    }

    function _calculateDelta(uint256 _sqrtPrice, int256 _sqrtAmount, int256 perpAmount)
        internal
        pure
        returns (int256)
    {
        // delta of 'x + 2 * sqrt(x)' is '1 + 1 / sqrt(x)'
        return perpAmount + _sqrtAmount * int256(Constants.Q96) / int256(_sqrtPrice);
    }

    function _validateHedgeCondition(UserPosition memory userPosition, uint256 sqrtIndexPrice)
        internal
        view
        returns (bool, uint256 slippageTolerance, CallbackType)
    {
        if (
            userPosition.hedgeInterval > 0
                && userPosition.lastHedgedTime + userPosition.hedgeInterval <= block.timestamp
        ) {
            return (
                true,
                GammaTradeMarketLib.calculateSlippageTolerance(
                    userPosition.lastHedgedTime + userPosition.hedgeInterval,
                    block.timestamp,
                    userPosition.auctionParams
                    ),
                CallbackType.HEDGE_BY_TIME
            );
        }

        // if sqrtPriceTrigger is 0, it means that the user doesn't want to use this feature
        if (userPosition.sqrtPriceTrigger == 0) {
            return (false, 0, CallbackType.NONE);
        }

        uint256 upperThreshold = userPosition.lastHedgedSqrtPrice * userPosition.sqrtPriceTrigger / Bps.ONE;
        uint256 lowerThreshold = userPosition.lastHedgedSqrtPrice * Bps.ONE / userPosition.sqrtPriceTrigger;

        if (lowerThreshold >= sqrtIndexPrice) {
            return (
                true,
                GammaTradeMarketLib.calculateSlippageToleranceByPrice(
                    sqrtIndexPrice, lowerThreshold, userPosition.auctionParams
                    ),
                CallbackType.HEDGE_BY_PRICE
            );
        }

        if (upperThreshold <= sqrtIndexPrice) {
            return (
                true,
                GammaTradeMarketLib.calculateSlippageToleranceByPrice(
                    upperThreshold, sqrtIndexPrice, userPosition.auctionParams
                    ),
                CallbackType.HEDGE_BY_PRICE
            );
        }

        return (false, 0, CallbackType.NONE);
    }

    function _validateCloseCondition(UserPosition memory userPosition, uint256 sqrtIndexPrice)
        internal
        view
        returns (bool, uint256 slippageTolerance, CallbackType)
    {
        if (userPosition.expiration <= block.timestamp) {
            return (
                true,
                GammaTradeMarketLib.calculateSlippageTolerance(
                    userPosition.expiration, block.timestamp, userPosition.auctionParams
                    ),
                CallbackType.CLOSE_BY_TIME
            );
        }

        uint256 upperThreshold = userPosition.upperLimit;
        uint256 lowerThreshold = userPosition.lowerLimit;

        if (lowerThreshold > 0 && lowerThreshold >= sqrtIndexPrice) {
            return (
                true,
                GammaTradeMarketLib.calculateSlippageToleranceByPrice(
                    sqrtIndexPrice, lowerThreshold, userPosition.auctionParams
                    ),
                CallbackType.CLOSE_BY_PRICE
            );
        }

        if (upperThreshold > 0 && upperThreshold <= sqrtIndexPrice) {
            return (
                true,
                GammaTradeMarketLib.calculateSlippageToleranceByPrice(
                    upperThreshold, sqrtIndexPrice, userPosition.auctionParams
                    ),
                CallbackType.CLOSE_BY_PRICE
            );
        }

        return (false, 0, CallbackType.NONE);
    }

    function _verifyOrder(ResolvedOrder memory order) internal {
        order.validate();

        _permit2.permitWitnessTransferFrom(
            order.toPermit(),
            order.transferDetails(address(this)),
            order.info.trader,
            order.hash,
            GammaOrderLib.PERMIT2_ORDER_TYPE,
            order.sig
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {GammaTradeMarket} from "./GammaTradeMarket.sol";
import {OrderInfo} from "../../libraries/orders/OrderInfoLib.sol";
import {GammaOrder, GammaOrderLib, GammaModifyInfo} from "./GammaOrder.sol";
import {L2GammaDecoder} from "./L2GammaDecoder.sol";
import {IPredyPool} from "../../interfaces/IPredyPool.sol";

struct GammaOrderL2 {
    address trader;
    uint256 nonce;
    uint256 positionId;
    int256 quantity;
    int256 quantitySqrt;
    int256 marginAmount;
    uint256 baseSqrtPrice;
    bytes32 param;
    bytes32 modifyParam;
    uint256 lowerLimit;
    uint256 upperLimit;
}

struct GammaModifyOrderL2 {
    address trader;
    uint256 nonce;
    uint256 deadline;
    uint256 positionId;
    bytes32 param;
    uint256 lowerLimit;
    uint256 upperLimit;
}

/**
 * @notice Gamma trade market contract for Layer2.
 * Optimizing calldata size in this contract since L2 calldata is relatively expensive.
 */
contract GammaTradeMarketL2 is GammaTradeMarket {
    // execute trade
    function executeTradeL2(GammaOrderL2 memory order, bytes memory sig, SettlementParamsV3 memory settlementParams)
        external
        nonReentrant
        returns (IPredyPool.TradeResult memory tradeResult)
    {
        GammaModifyInfo memory modifyInfo =
            L2GammaDecoder.decodeGammaModifyInfo(order.modifyParam, order.lowerLimit, order.upperLimit);
        (uint64 deadline, uint64 pairId, uint32 slippageTolerance, uint8 leverage) =
            L2GammaDecoder.decodeGammaParam(order.param);

        return _executeTrade(
            GammaOrder(
                OrderInfo(address(this), order.trader, order.nonce, deadline),
                pairId,
                order.positionId,
                _quoteTokenMap[pairId],
                order.quantity,
                order.quantitySqrt,
                order.marginAmount,
                order.baseSqrtPrice,
                slippageTolerance,
                leverage,
                modifyInfo
            ),
            sig,
            settlementParams
        );
    }

    // modify position (hedge or close)
    function modifyAutoHedgeAndClose(GammaModifyOrderL2 memory order, bytes memory sig) external {
        GammaModifyInfo memory modifyInfo =
            L2GammaDecoder.decodeGammaModifyInfo(order.param, order.lowerLimit, order.upperLimit);

        uint64 pairId = userPositions[order.positionId].pairId;

        _modifyAutoHedgeAndClose(
            GammaOrder(
                OrderInfo(address(this), order.trader, order.nonce, order.deadline),
                pairId,
                order.positionId,
                _quoteTokenMap[pairId],
                0,
                0,
                0,
                0,
                0,
                0,
                modifyInfo
            ),
            sig
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Bps} from "../../../src/libraries/math/Bps.sol";

library GammaTradeMarketLib {
    struct AuctionParams {
        uint32 minSlippageTolerance;
        uint32 maxSlippageTolerance;
        uint16 auctionPeriod;
        uint32 auctionRange;
    }

    function calculateSlippageTolerance(uint256 startTime, uint256 currentTime, AuctionParams memory auctionParams)
        internal
        pure
        returns (uint256)
    {
        if (currentTime <= startTime) {
            return auctionParams.minSlippageTolerance;
        }

        uint256 elapsed = (currentTime - startTime) * Bps.ONE / auctionParams.auctionPeriod;

        if (elapsed > Bps.ONE) {
            return auctionParams.maxSlippageTolerance;
        }

        return (
            auctionParams.minSlippageTolerance
                + elapsed * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance) / Bps.ONE
        );
    }

    /**
     * @notice Calculate slippage tolerance by price
     * trader want to trade in price1 >= price2,
     * slippage tolerance will be increased if price1 <= price2
     */
    function calculateSlippageToleranceByPrice(uint256 price1, uint256 price2, AuctionParams memory auctionParams)
        internal
        pure
        returns (uint256)
    {
        if (price2 <= price1) {
            return auctionParams.minSlippageTolerance;
        }

        uint256 ratio = (price2 * Bps.ONE / price1 - Bps.ONE);

        if (ratio > auctionParams.auctionRange) {
            return auctionParams.maxSlippageTolerance;
        }

        return (
            auctionParams.minSlippageTolerance
                + ratio * (auctionParams.maxSlippageTolerance - auctionParams.minSlippageTolerance)
                    / auctionParams.auctionRange
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

import {GammaModifyInfo} from "./GammaOrder.sol";

library L2GammaDecoder {
    function decodeGammaModifyInfo(bytes32 args, uint256 lowerLimit, uint256 upperLimit)
        internal
        pure
        returns (GammaModifyInfo memory)
    {
        (
            bool isEnabled,
            uint64 expiration,
            uint32 hedgeInterval,
            uint32 sqrtPriceTrigger,
            uint32 minSlippageTolerance,
            uint32 maxSlippageTolerance,
            uint16 auctionPeriod,
            uint32 auctionRange
        ) = decodeGammaModifyParam(args);

        return GammaModifyInfo(
            isEnabled,
            expiration,
            lowerLimit,
            upperLimit,
            hedgeInterval,
            sqrtPriceTrigger,
            minSlippageTolerance,
            maxSlippageTolerance,
            auctionPeriod,
            auctionRange
        );
    }

    function decodeGammaParam(bytes32 args)
        internal
        pure
        returns (uint64 deadline, uint64 pairId, uint32 slippageTolerance, uint8 leverage)
    {
        assembly {
            deadline := and(args, 0xFFFFFFFFFFFFFFFF)
            pairId := and(shr(64, args), 0xFFFFFFFFFFFFFFFF)
            slippageTolerance := and(shr(128, args), 0xFFFFFFFF)
            leverage := and(shr(160, args), 0xFF)
        }
    }

    function decodeGammaModifyParam(bytes32 args)
        internal
        pure
        returns (
            bool isEnabled,
            uint64 expiration,
            uint32 hedgeInterval,
            uint32 sqrtPriceTrigger,
            uint32 minSlippageTolerance,
            uint32 maxSlippageTolerance,
            uint16 auctionPeriod,
            uint32 auctionRange
        )
    {
        uint32 isEnabledUint = 0;

        assembly {
            expiration := and(args, 0xFFFFFFFFFFFFFFFF)
            hedgeInterval := and(shr(64, args), 0xFFFFFFFF)
            sqrtPriceTrigger := and(shr(96, args), 0xFFFFFFFF)
            minSlippageTolerance := and(shr(128, args), 0xFFFFFFFF)
            maxSlippageTolerance := and(shr(160, args), 0xFFFFFFFF)
            auctionRange := and(shr(192, args), 0xFFFFFFFF)
            isEnabledUint := and(shr(224, args), 0xFFFF)
            auctionPeriod := and(shr(240, args), 0xFFFF)
        }

        if (isEnabledUint == 1) {
            isEnabled = true;
        } else {
            isEnabled = false;
        }
    }
}

//SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.17;

interface IUniswapV3PoolOracle {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    function liquidity() external view returns (uint128);

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory liquidityCumulatives);

    function observations(uint256 index)
        external
        view
        returns (uint32 blockTimestamp, int56 tickCumulative, uint160 liquidityCumulative, bool initialized);

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}