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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

interface IWhitelistedTokens {
  function isTokenAllowed(address token) external view returns (bool);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./Managed.sol";
import "./interfaces/IFarmManagement.sol";
import "./interfaces/IHasSupportedAsset.sol";
import "./interfaces/IHasAssetInfo.sol";
import "./interfaces/IHasFeeInfo.sol";
import "../interfaces/IWhitelistedTokens.sol";

contract FarmManagement is
    IFarmManagement, IHasSupportedAsset,
    Managed
{
    using SafeMathUpgradeable for uint256;

    event AssetAdded(address indexed farm, address manager, address asset, bool isDeposit);
    event AssetRemoved(address farm, address manager, address asset);
    event ManagementFeeSet(address farm, address manager, uint256 numerator, uint256 denominator);
    event PerformanceFeeSet(address farm, address manager, uint256 numerator, uint256 denominator);
    event EntranceFeeSet(address farm, address manager, uint256 numerator, uint256 denominator);
    event ExitFeeSet(address farm, address manager, uint256 numerator, uint256 denominator);

    address public factory;
    address public farm;
    IHasFeeInfo.Fees private fees;

    /*//////////////////////////////////////////////////////////////
                            SUPPORTED ASSETS
    //////////////////////////////////////////////////////////////*/
    Asset[] public supportedAssets;
    mapping(address => uint256) public assetPosition; // maps the asset to its 1-based position

    function initialize(
        address _factory,
        address _manager,
        address _farm,
        IHasFeeInfo.Fees memory _fees,
        Asset[] calldata _supportedAssets
    ) public initializer {
        require(_factory != address(0), "Invalid factory");
        require(_manager != address(0), "Invalid manager");
        require(_farm != address(0), "Invalid farm");

        factory = _factory;
        farm = _farm;
        fees = _fees;
        __Managed_init(_manager);

        _changeAssets(_supportedAssets, new address[](0));
    }

    function isSupportedAsset(address asset) public view override returns (bool) {
        return assetPosition[asset] != 0;
    }

    function isDepositAsset(address asset) external view returns (bool) {
        uint256 index = assetPosition[asset];
        return index != 0 && supportedAssets[index.sub(1)].isDeposit;
    }

    function changeAssets(Asset[] calldata _addAssets, address[] calldata _removeAssets) external onlyManager {
        _changeAssets(_addAssets, _removeAssets);
    }

    function _changeAssets(Asset[] calldata _addAssets, address[] memory _removeAssets) internal {
        for (uint8 i = 0; i < _removeAssets.length; i++) {
            _removeAsset(_removeAssets[i]);
        }

        for (uint8 i = 0; i < _addAssets.length; i++) {
            _addAsset(_addAssets[i]);
        }

        require(
            supportedAssets.length <= IHasAssetInfo(factory).getMaximumSupportedAssetCount(),
            "maximum assets reached"
        );

        require(getDepositAssets().length >= 1, "at least one deposit asset");
    }

    function _addAsset(Asset calldata _asset) internal {
        address asset = _asset.asset;
        bool isDeposit = _asset.isDeposit;

        require(IWhitelistedTokens(factory).isTokenAllowed(asset), "invalid asset");

        if (isSupportedAsset(asset)) {
            uint256 index = assetPosition[asset].sub(1);
            supportedAssets[index].isDeposit = isDeposit;
        } else {
            supportedAssets.push(Asset(asset, isDeposit));
            assetPosition[asset] = supportedAssets.length;
        }

        emit AssetAdded(farm, manager, asset, isDeposit);
    }

    /// @notice Remove asset from the pool
    /// @dev use asset address to remove from supportedAssets
    /// @param asset asset address
    function _removeAsset(address asset) internal {
        require(isSupportedAsset(asset), "asset not supported");

        require(assetBalance(asset) == 0, "cannot remove non-empty asset");

        uint256 length = supportedAssets.length;
        Asset memory lastAsset = supportedAssets[length.sub(1)];
        uint256 index = assetPosition[asset].sub(1); // adjusting the index because the map stores 1-based

        // overwrite the asset to be removed with the last supported asset
        supportedAssets[index] = lastAsset;
        assetPosition[lastAsset.asset] = index.add(1); // adjusting the index to be 1-based
        assetPosition[asset] = 0; // update the map

        // delete the last supported asset and resize the array
        supportedAssets.pop();

        emit AssetRemoved(farm, manager, asset);
    }

    function getSupportedAssets() external view override returns (Asset[] memory) {
        return supportedAssets;
    }

    function getDepositAssets() public view returns (address[] memory) {
        uint256 assetCount = supportedAssets.length;
        address[] memory depositAssets = new address[](assetCount);
        uint8 index = 0;

        for (uint8 i = 0; i < assetCount; i++) {
            if (supportedAssets[i].isDeposit) {
                depositAssets[index] = supportedAssets[i].asset;
                index++;
            }
        }

        // Reduce length for withdrawnAssets to remove the empty items
        uint256 reduceLength = assetCount.sub(index);
        assembly {
            mstore(depositAssets, sub(mload(depositAssets), reduceLength))
        }

        return depositAssets;
    }

    function getManagementFee() external view override returns (uint256, uint256) {
        (, uint256 managerFeeDenominator) = IHasFeeInfo(factory).getMaximumManagerFee();
        return (fees.management, managerFeeDenominator);
    }

    /// @notice Manager can set management fee
    function setManagementFee(uint256 numerator) external onlyManager {
        (uint256 maximumNumerator, uint256 maximumDenominator) = IHasFeeInfo(factory).getMaximumManagerFee();
        require(numerator <= maximumDenominator && numerator <= maximumNumerator, "invalid management fee");

        fees.management = numerator;

        emit ManagementFeeSet(farm, manager, numerator, maximumDenominator);
    }

    function getPerformanceFee() external view override returns (uint256, uint256) {
        (, uint256 performanceFeeDenominator) = IHasFeeInfo(factory).getMaximumPerformanceFee();
        return (fees.performance, performanceFeeDenominator);
    }

    /// @notice Manager can set performance fee
    function setPerformanceFee(uint256 numerator) external onlyManager {
        (uint256 maximumNumerator, uint256 maximumDenominator) = IHasFeeInfo(factory).getMaximumPerformanceFee();
        require(numerator <= maximumDenominator && numerator <= maximumNumerator, "invalid performance fee");

        fees.performance = numerator;

        emit PerformanceFeeSet(farm, manager, numerator, maximumDenominator);
    }

    function getEntranceFee() external view override returns (uint256, uint256) {
        (, uint256 entranceFeeDenominator) = IHasFeeInfo(factory).getMaximumEntranceFee();
        return (fees.entrance, entranceFeeDenominator);
    }

    /// @notice Manager can set entrance fee
    function setEntranceFee(uint256 numerator) external onlyManager {
        (uint256 maximumNumerator, uint256 maximumDenominator) = IHasFeeInfo(factory).getMaximumEntranceFee();
        require(numerator <= maximumDenominator && numerator <= maximumNumerator, "invalid entrance fee");

        fees.entrance = numerator;

        emit EntranceFeeSet(farm, manager, numerator, maximumDenominator);
    }

    function getExitFee() external view override returns (uint256, uint256) {
        (, uint256 exitFeeDenominator) = IHasFeeInfo(factory).getMaximumExitFee();
        return (fees.entrance, exitFeeDenominator);
    }

    /// @notice Manager can set exit fee
    function setExitFee(uint256 numerator) external onlyManager {
        (uint256 maximumNumerator, uint256 maximumDenominator) = IHasFeeInfo(factory).getMaximumExitFee();
        require(numerator <= maximumDenominator && numerator <= maximumNumerator, "invalid exit fee");

        fees.exit = numerator;

        emit ExitFeeSet(farm, manager, numerator, maximumDenominator);
    }

    /// @notice Get asset balance(including any staked balance in external contracts)
    function assetBalance(address asset) public view returns (uint256) {
        return IERC20Upgradeable(asset).balanceOf(address(farm));
    }

    /// @notice Return the total fund value of the pool
    /// @dev Calculate the total fund value from the supported assets
    /// @return value in USD
    function totalFundValue() external view override returns (uint256) {
        IHasAssetInfo assetInfo = IHasAssetInfo(factory);
        uint256 total = 0;
        uint256 assetCount = supportedAssets.length;

        for (uint256 i = 0; i < assetCount; i++) {
            address asset = supportedAssets[i].asset;
            total = total.add(assetInfo.assetValue(asset, assetBalance(asset)));
        }

        return total;
    }
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

interface IFarmManagement {
    function factory() external view returns (address);
    function farm() external view returns (address);
    function isDepositAsset(address asset) external view returns (bool);
    function getManagementFee() external view returns (uint256, uint256);
    function getPerformanceFee() external view returns (uint256, uint256);
    function getEntranceFee() external view returns (uint256, uint256);
    function getExitFee() external view returns (uint256, uint256);
    function totalFundValue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHasAssetInfo {
  function isValidAsset(address asset) external view returns (bool);

  function getAssetPrice(address asset) external view returns (uint256);
  function assetValue(address asset, uint256 amount) external view returns (uint256);

  function getMaximumSupportedAssetCount() external view returns (uint256);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

interface IHasFeeInfo {
  function getMaximumManagerFee() external view returns (uint256, uint256);
  function getMaximumPerformanceFee() external view returns (uint256, uint256);
  function getMaximumEntranceFee() external view returns (uint256, uint256);
  function getMaximumExitFee() external view returns (uint256, uint256);
  function getPenaltyFee(uint256 day) external view returns (uint256, uint256);

  struct Fees {
    uint256 management;
    uint256 performance;
    uint256 entrance;
    uint256 exit;
  }
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IHasSupportedAsset {
  struct Asset {
    address asset;
    bool isDeposit;
  }

  function getSupportedAssets() external view returns (Asset[] memory);

  function isSupportedAsset(address asset) external view returns (bool);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

interface IManaged {
  function manager() external view returns (address);

  function isMemberAllowed(address member) external view returns (bool);
}

// SPDX-License-Identifier: UNKNOWN
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./interfaces/IManaged.sol";

abstract contract Managed is IManaged, Initializable {
  using SafeMathUpgradeable for uint256;

  event ManagerUpdated(address newManager);
  event MemberAdded(address);
  event MemberRemoved(address);

  address public manager;

  address[] private _memberList;
  mapping(address => uint256) private _memberPosition;

  function __Managed_init(address _manager) internal onlyInitializing {
    require(_manager != address(0), "Invalid manager address");

    manager = _manager;
  }

  modifier onlyManager() {
    require(msg.sender == manager, "only manager");
    _;
  }

  function isMemberAllowed(address member) public view returns (bool) {
    return _memberPosition[member] != 0;
  }

  function getMembers() external view returns (address[] memory) {
    return _memberList;
  }

  function changeManager(address newManager) public onlyManager {
    require(newManager != address(0), "Invalid manager address");

    manager = newManager;

    emit ManagerUpdated(newManager);
  }

  function addMembers(address[] memory members) external onlyManager {
    for (uint256 i = 0; i < members.length; i++) {
      if (isMemberAllowed(members[i])) continue;

      _addMember(members[i]);
    }
  }

  function removeMembers(address[] memory members) external onlyManager {
    for (uint256 i = 0; i < members.length; i++) {
      if (!isMemberAllowed(members[i])) continue;

      _removeMember(members[i]);
    }
  }

  function addMember(address member) external onlyManager {
    if (isMemberAllowed(member)) return;

    _addMember(member);
  }

  function removeMember(address member) external onlyManager {
    if (!isMemberAllowed(member)) return;

    _removeMember(member);
  }

  function numberOfMembers() external view returns (uint256) {
    return _memberList.length;
  }

  function _addMember(address member) internal {
    _memberList.push(member);
    _memberPosition[member] = _memberList.length;
    emit MemberAdded(member);
  }

  function _removeMember(address member) internal {
    uint256 length = _memberList.length;
    uint256 index = _memberPosition[member].sub(1);

    address lastMember = _memberList[length.sub(1)];

    _memberList[index] = lastMember;
    _memberPosition[lastMember] = index.add(1);
    _memberPosition[member] = 0;

    _memberList.pop();

    emit MemberRemoved(member);
  }
}