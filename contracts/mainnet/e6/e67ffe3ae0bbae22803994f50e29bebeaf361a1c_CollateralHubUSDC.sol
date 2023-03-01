// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMath {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;


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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;


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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Nuon/interfaces/IIncentive.sol



pragma solidity 0.8.7;

/// @title incentive contract interface
/// @author Fei Protocol
/// @notice Called by FEI token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentiveController {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of the FEI
    /// @param receiver the receiver address of the FEI
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of FEI transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

// File: contracts/utils/token/IAnyswapV4Token.sol



pragma solidity 0.8.7;

interface IAnyswapV4Token {
    function approveAndCall(
        address spender,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool);

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function Swapin(
        bytes32 txhash,
        address account,
        uint256 amount
    ) external returns (bool);

    function Swapout(uint256 amount, address bindaddr) external returns (bool);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/Nuon/interfaces/INUON.sol



pragma solidity 0.8.7;




interface INUON is IERC20, IAnyswapV4Token {
    function mint(address who, uint256 amount) external;

    function setNUONController(address _controller) external;

    function burn(uint256 amount) external;
}

// File: contracts/Nuon/interfaces/INLP.sol



pragma solidity 0.8.7;

interface INLP {

    function getPositionOwned(address _owner) external view returns (uint256);
    function _deletePositionInfo(address _user) external;
    function mintNLP(address _sender, uint256 _tokenId) external;
    function burnNLP(uint256 _tokenId) external;
    function _addAmountToPosition(
        uint256 _mintedAmount,
        uint256 _collateralAmount,
        uint256 _LPAmount,
        uint256 _position) external;

    function _createPosition(
        address _owner,
        uint256 _id) external;

    function _topUpPosition(
        uint256 _mintedAmount,
        uint256 _collateralAmount,
        uint256 _LPAmount,
        uint256 _position,
        address _receiver) external;
}

// File: contracts/Nuon/interfaces/INUONController.sol



pragma solidity 0.8.7;

interface INUONController {

    function getMintLimit(uint256 _nuonAmount) external view returns (uint256);

    function addPool(address pool_address) external;

    function getPools() external view returns (address[] memory);

    function addPools(address[] memory poolAddress) external;

    function removePool(address pool_address) external;

    function getNUONSupply() external view returns (uint256);

    function isPool(address pool) external view returns (bool);

    function isMintPaused() external view returns (bool);

    function isRedeemPaused() external view returns (bool);

    function isAllowedToMint(address _minter) external view returns (bool);

    function setFeesParameters(uint256 _mintingFee, uint256 _redeemFee)
        external;

    function setGlobalCollateralRatio(uint256 _globalCollateralRatio) external;

    function getMintingFee(address _CHUB) external view returns (uint256);

    function getRedeemFee(address _CHUB) external view returns (uint256);

    function getGlobalCollateralRatio(address _CHUB) external view returns (uint256);

    function getGlobalCollateralValue() external view returns (uint256);

    function toggleMinting() external;

    function toggleRedeeming() external;

    function getTargetCollateralValue() external view returns (uint256);

    function getMaxCratio(address _CHUB) external view returns (uint256);
}

// File: contracts/Nuon/interfaces/ITruflation.sol


pragma solidity ^0.8.7;

interface ITruflation {
    function getNuonTargetPeg() external view returns (uint256);
}

// File: contracts/utils/token/IERC20Burnable.sol



pragma solidity 0.8.7;


interface IERC20Burnable is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// File: contracts/Nuon/Pools/CollateralHub-USDC.sol



pragma solidity 0.8.7;










interface IUniswapPairOracle {
    function consult(address token, uint256 amountIn)
        external
        view
        returns (uint256 amountOut);
}

interface IChainlinkOracle {
    function latestAnswer() external view returns (uint256);
}

interface IUniswapRouterETH {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IRelayer {
    function depositOnVault(uint256 _amount) external returns(uint256);
    function withdrawFromVault(uint256 _shares) external returns (uint256);
    function getPPFS() external view returns (uint256);
}

/**
* @notice The Collateral Hub (CHub) is receiving collaterals from users, and mint them back NUON according to the collateral ratio defined in the NUON Controller
* @dev (Driiip) TheHashM
* @author This Chub is designed by Gniar & TheHashM 
*/
contract CollateralHubUSDC is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using SafeMath for uint256;

    /**
    * @dev Contract instances.
    */
    address private NUONController;
    address private Treasury;
    address private NUON;
    address private NuonOracleAddress;
    address private ChainlinkOracle;
    address private TruflationOracle;
    address private collateralUsed;
    address private unirouter;
    address private lpPair;
    address private NLP;
    address private Relayer;

    /**
    * @notice Contract Data : mapping and infos
    */
    mapping(uint256 => bool) private vaultsRedeemPaused;
    mapping(address => uint256) private usersIndex;
    mapping(address => uint256) private usersAmounts;
    mapping(address => uint256) private mintedAmount;
    mapping(address => uint256) private userLPs;
    mapping(address => bool) private nlpCheck;
    mapping(address => uint256) private nlpPerUser;

    address[] public users;
    address[] private collateralToNuonRoute;
    uint256 private liquidationFee;
    uint256 private minimumDepositAmount;
    uint256 private liquidityBuffer;
    uint256 private liquidityCheck;
    uint256 private maxNuonBurnPercent;
    uint256 private constant MAX_INT = 2**256 - 1;
    uint256 private assetMultiplier;
    uint256 private decimalDivisor;
    uint256 private count;

    /**
     * @notice Events.
     */
    event MintedNUON(address indexed user, uint256 NUONAmountD18, uint256 NuonPrice, uint256 collateralAmount);
    event Redeemed(address indexed user, uint256 fullAmount, uint256 NuonAmount);
    event depositedWithoutMint(address indexed user, uint256 fees, uint256 depositedAmount);
    event mintedWithoutDeposit(address indexed user, uint256 mintedAmount, uint256 collateralRequired);
    event redeemedWithoutNuon(address indexed user, uint256 fees, uint256 amountSentToUser);
    event burnedNuon(address indexed user, uint256 burnedAmount, uint256 LPSent);

    /**
    * @dev We deploy using initialize with openzeppelin/truffle-upgrades
    * @notice No 0 addresses allowed
    */
    function initialize(
        address _NUON,
        address _NUONController,
        address _treasury,
        address _truflationOracle,
        address _collateralUsed,
        address _ChainlinkOracle,
        uint256 _assetMultiplier,
        uint256 _liquidationFee,
        uint256 _decimalDivisor
    ) public initializer {

        NUON = _NUON;
        NUONController = _NUONController;
        Treasury = _treasury;
        TruflationOracle = _truflationOracle;
        collateralUsed = _collateralUsed;
        assetMultiplier = _assetMultiplier;
        ChainlinkOracle = _ChainlinkOracle;
        collateralToNuonRoute = [collateralUsed,NUON];
        liquidationFee = _liquidationFee;
        decimalDivisor = _decimalDivisor;
        count ++;
        __Ownable_init();
    }

    /**
     * @notice Sets the core addresses used by the contract
     * @param _treasury Treasury contract
     * @param _controller NUON controller
     */
    function setCoreAddresses(
        address _treasury,
        address _controller,
        address _router,
        address _lpPair,
        address[] memory _collateralToNuonRoute,
        address _NLP,
        address _Relayer,
        address _nuonOracle,
        address _truflation,
        address _ChainlinkOracle
    ) public onlyOwner {
        Treasury = _treasury;
        NUONController = _controller;
        unirouter = _router;
        lpPair = _lpPair;
        collateralToNuonRoute = _collateralToNuonRoute;
        NLP = _NLP;
        Relayer = _Relayer;
        NuonOracleAddress = _nuonOracle;
        TruflationOracle = _truflation;
        ChainlinkOracle = _ChainlinkOracle;
    }

    function setLiquidityParams(
        uint256 _liquidityCheck,
        uint256 _liquidityBuffer,
        uint256 _maxNuonBurnPercent,
        uint256 _minimumDepositAmount) public onlyOwner {
        require(_liquidityCheck != 0 && _liquidityBuffer != 0 && _minimumDepositAmount > 0, "Need to be above 0");
        require(_liquidityCheck <= 150e18 && _liquidityBuffer <= 50 && _maxNuonBurnPercent <= 99 , "Need to be below the limit");
        liquidityCheck = _liquidityCheck;
        liquidityBuffer = _liquidityBuffer;
        maxNuonBurnPercent = _maxNuonBurnPercent;
        minimumDepositAmount = _minimumDepositAmount;
    }
    
    /**
     * @notice A series of view functions to return the contract status.For front end peeps.
     */

    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    function getPositionOwned(address _owner) public view returns (uint256) {
        return nlpPerUser[_owner];
    }

    function viewUserCollateralAmount(address _user) public view returns (uint256) {
        return (usersAmounts[_user]);
    }

    function viewUserMintedAmount(address _user) public view returns (uint256) {
        return (mintedAmount[_user]);
    }

    function viewUserVaultSharesAmount(address _user) public view returns (uint256) {
        return (userLPs[_user]);
    }

    function getNUONPrice()
        public
        view
        returns (uint256)
    {
        uint256 assetPrice;
        if (NuonOracleAddress == address(0)) {
            assetPrice = 1e18;
        } else {
            assetPrice = IUniswapPairOracle(NuonOracleAddress).consult(NUON,1e18);
        }
        return assetPrice;
    }

    function getUserCollateralRatioInPercent(address _user)
        public
        view
        returns (uint256)
    {
        if (viewUserCollateralAmount(_user) > 0) {
            uint256 userTVL = (viewUserCollateralAmount(_user) * assetMultiplier) * getCollateralPrice() / 1e18;
            uint256 mintedValue = viewUserMintedAmount(_user) * getNUONPrice() / 1e18;
            return (userTVL * 1e18) / mintedValue * 100;
        } else {
            return 0;
        }

    }

    function getUserLiquidationStatus(address _user) public view returns (bool) {
        uint256 ratio = INUONController(NUONController).getGlobalCollateralRatio(address(this));
        if (collateralPercentToRatio(_user) > ratio) {
            return true;
        } else {
            return false;
        }
    }

    function collateralPercentToRatio(address _user)
        public
        view
        returns (uint256)
    {
        uint256 rat = 1e18 * 1e18 / getUserCollateralRatioInPercent(_user) * 100;
        return rat;
    }

    /**
     * @notice A view function to estimate the amount of NUON out. For front end peeps.
     * @param collateralAmount The amount of collateral that the user wants to use
     * return The NUON amount to be minted, the minting fee in d18 format, and the collateral to be deposited after the fees have been taken
     */
    function estimateMintedNUONAmount(uint256 collateralAmount, uint256 _collateralRatio)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        require(_collateralRatio <= INUONController(NUONController).getGlobalCollateralRatio(address(this)),"Collateral Ratio out of bounds");
        require(_collateralRatio >= INUONController(NUONController).getMaxCratio(address(this)),"Collateral Ratio too low");
        require(collateralAmount > minimumDepositAmount, "Please deposit more than the min required amount");

        uint256 collateralAmountAfterFees = collateralAmount.sub(
        collateralAmount.mul(INUONController(NUONController).getMintingFee(address(this)))
        .div(100)
        .div(1e18));

        uint256 collateralAmountAfterFeesD18 = collateralAmountAfterFees *
            assetMultiplier;

        uint256 NUONAmountD18;

        NUONAmountD18 = calcOverCollateralizedMintAmounts(
                _collateralRatio,
                getCollateralPrice(),
                collateralAmountAfterFeesD18
            );

        (uint256 collateralRequired,)= mintLiquidityHelper(NUONAmountD18);
        return (
                NUONAmountD18,
                INUONController(NUONController).getMintingFee(address(this)),
                collateralAmountAfterFees,
                collateralRequired
            );
    }

    /**
     * @notice A view function to get the collateral price of an asset directly on chain
     * return The asset price
     */
    function getCollateralPrice()
        public
        view
        returns (uint256)
    {
            uint256 assetPrice = IChainlinkOracle(ChainlinkOracle).latestAnswer().mul(1e10);
            return assetPrice;
    }

    /**
     * @notice A view function to estimate the collaterals out after NUON redeem. For end end peeps.
     * @param _user A specific user
     * @param NUONAmount The NUON amount to give back to the collateral hub.
     * return The collateral amount out, the NUON burned in the process, and the fees taken by the ecosystem
     */
    function estimateCollateralsOut(
        address _user,
        uint256 NUONAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 userAmount = usersAmounts[_user];
        uint256 userMintedAmount = mintedAmount[_user];
        
        require(userAmount > 0, 'You do not have any balance in that CHUB');

        uint256 fullAmount = calcOverCollateralizedRedeemAmounts(
            collateralPercentToRatio(_user),
            getCollateralPrice(),
            NUONAmount,
            assetMultiplier
        ).div(decimalDivisor);

        require(NUONAmount <= userMintedAmount, 'Not enough NUON to burn');
        if (NUONAmount == mintedAmount[msg.sender] || fullAmount >= userAmount) {
             fullAmount = userAmount;
        }

        uint256 fees = fullAmount
            .mul(INUONController(NUONController).getRedeemFee(address(this)))
            .div(100)
            .div(1e18);
        uint256 collateralFees = fullAmount.sub(fees);

        return (fullAmount, collateralFees, fees);
    }

    /**
     * @notice Used to mint NUON as a user deposit collaterals
     * return The minted NUON amount
     * @dev collateralAmount is in USDT
     */
    function mint(
        uint256 _collateralRatio,
        uint256 _amount
    )
        external
        nonReentrant
        returns (uint256)
    {
        require(
            INUONController(NUONController).isMintPaused() == false,
            'CHUB: Minting paused! Aaah!'
        );

        //cratio has to be bigger than the minimum required in the controller, otherwise user can get liquidated instantly
        //It has to be lower because lower means higher % cratio
        require(_collateralRatio <= INUONController(NUONController).getGlobalCollateralRatio(address(this)),"Collateral Ratio out of bounds");
        require(_collateralRatio >= INUONController(NUONController).getMaxCratio(address(this)),"Collateral Ratio too low");

        if (usersAmounts[msg.sender] == 0) {
            usersIndex[msg.sender] = users.length;
            users.push(msg.sender);
            if (msg.sender != owner()) {
                require(nlpCheck[msg.sender] == false, "You already have a position");
                //just used to increment new NFT IDs
                uint256 newItemId = count;
                count ++;
                INLP(NLP).mintNLP(msg.sender, newItemId);
                INLP(NLP)._createPosition(msg.sender,newItemId);
                nlpCheck[msg.sender] = true;
                nlpPerUser[msg.sender] = newItemId;
            }
        }
        //In case the above if statement isnt executed we need to instantiate the
        //storage element here to update the position status
        uint256 collateralAmount = _amount;
        require(collateralAmount > minimumDepositAmount, "Please deposit more than the min required amount");

        (uint256 NUONAmountD18,
        ,
        uint256 collateralAmountAfterFees,
        uint256 collateralRequired)  = estimateMintedNUONAmount(collateralAmount, _collateralRatio);
        uint256 userAmount = usersAmounts[msg.sender];
        usersAmounts[msg.sender] = userAmount.add(collateralAmountAfterFees);
        mintedAmount[msg.sender] = mintedAmount[msg.sender].add(NUONAmountD18);

        if (msg.sender != owner()) {
            IERC20Burnable(collateralUsed).transferFrom(msg.sender, address(this),_amount.add(collateralRequired));
            _addLiquidity(collateralRequired);
            INLP(NLP)._addAmountToPosition(mintedAmount[msg.sender], usersAmounts[msg.sender], userLPs[msg.sender], nlpPerUser[msg.sender]);
        } else {
            IERC20Burnable(collateralUsed).transferFrom(msg.sender, address(this),_amount);
        }
        
        IERC20Burnable(collateralUsed).transfer(
            Treasury,
            collateralAmount.sub(collateralAmountAfterFees)
        );
        INUON(NUON).mint(msg.sender, NUONAmountD18);
        emit MintedNUON(msg.sender, NUONAmountD18,getNUONPrice(),collateralAmount);
        return NUONAmountD18;
    }

    function addLiquidityForUser(uint256 _amount) public nonReentrant {
        require(usersAmounts[msg.sender] > 0, "You do not have a position in the CHUB");
        IERC20Burnable(collateralUsed).transferFrom(msg.sender, address(this),_amount);
        _addLiquidity(_amount);
    }

    function removeLiquidityForUser(uint256 _amount) public nonReentrant {
        require(usersAmounts[msg.sender] > 0, "You do not have a position in the CHUB");
        uint256 sharesAmount = userLPs[msg.sender];
        uint256 mintedValue = viewUserMintedAmount(msg.sender);
        require(sharesAmount >= _amount,"Cannot remove more than your full Balance");
        userLPs[msg.sender] = userLPs[msg.sender].sub(_amount);
        uint256 lpToSend = _removeUserLPs(_amount);
        require(getUserLiquidityCoverage(msg.sender,0) > liquidityCheck, "This will affect your liquidity coverage");
        IERC20Burnable(lpPair).transfer(msg.sender, lpToSend);
    }

    function _addLiquidity(uint256 _amount) internal {
        address router = unirouter;
        uint256 _amountDiv2 = _amount.div(2);
        IERC20Burnable(collateralUsed).approve(router, _amount);

        uint256 balBefore = IERC20Burnable(NUON).balanceOf(address(this));
        IUniswapRouterETH(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                _amountDiv2,
                0,
                collateralToNuonRoute,
                address(this),
                block.timestamp
        );
        uint256 balAfter = IERC20Burnable(NUON).balanceOf(address(this));
        IERC20Burnable(NUON).approve(router, balAfter.sub(balBefore));

        uint256 balOfLPBefore = IERC20Burnable(lpPair).balanceOf(address(this));
        IUniswapRouterETH(router).addLiquidity(
            NUON,
            collateralUsed,
            balAfter.sub(balBefore),
            _amountDiv2,
            0,
            0,
            address(this),
            block.timestamp
        );
        uint256 balOfLPAfter = IERC20Burnable(lpPair).balanceOf(address(this));
        
        IERC20Burnable(lpPair).approve(Relayer, balOfLPAfter.sub(balOfLPBefore));
        uint256 shares = IRelayer(Relayer).depositOnVault(balOfLPAfter.sub(balOfLPBefore));
        userLPs[msg.sender] = userLPs[msg.sender].add(shares);
    }

    function _removeUserLPs(uint256 _shares) internal returns (uint256) {
        uint256 LPReceived = IRelayer(Relayer).withdrawFromVault(_shares);
        return(LPReceived);
    }

    /**
     * @notice Used to redeem a collateral amount as a user gives back NUON
     * @param NUONAmount NUON amount to give back
     * @dev NUONAmount is always in d18, use estimateCollateralsOut() to estimate the amount of collaterals returned
     * Users from the market cannot redeem collaterals. Only minters.
     */
    function redeem(uint256 NUONAmount)
        external
        nonReentrant
    {
        
        require(
            INUONController(NUONController).isRedeemPaused() == false,
            'CHUB: Minting paused! Aaah!'
        );
        // Check is user should be liquidated
        if (getUserLiquidationStatus(msg.sender)) {
            liquidateUserAssets(msg.sender);
        } else {

        uint256 userAmount = usersAmounts[msg.sender];
        (uint256 fullAmount,uint256 fullAmountSubFees,uint256 fees) = estimateCollateralsOut(msg.sender,NUONAmount);

        if (NUONAmount == mintedAmount[msg.sender] || fullAmount >= userAmount) {
            fullAmount = userAmount;

            if (msg.sender != owner()) {
                uint256 usernlp = nlpPerUser[msg.sender];
                uint256 sharesAmount = userLPs[msg.sender];
                INLP(NLP).burnNLP(usernlp);
                INLP(NLP)._deletePositionInfo(msg.sender);
                _deleteUsersData(msg.sender);
                uint256 lpToSend = _removeUserLPs(sharesAmount);
                IERC20Burnable(lpPair).transfer(msg.sender, lpToSend);
            }
            mintedAmount[msg.sender] = 0;
            usersAmounts[msg.sender] = 0;
            delete users[usersIndex[msg.sender]];
            usersIndex[msg.sender] = 0;
        } else {
            require(fullAmount <= userAmount, 'Not enough balance');
            mintedAmount[msg.sender] = mintedAmount[msg.sender].sub(
            NUONAmount
            );
            usersAmounts[msg.sender] = userAmount.sub(fullAmount);
            if (msg.sender != owner()) {
                INLP(NLP)._addAmountToPosition(mintedAmount[msg.sender], usersAmounts[msg.sender], userLPs[msg.sender], nlpPerUser[msg.sender]);
            }
        }

        INUON(NUON).transferFrom(msg.sender, address(this), NUONAmount);
        IERC20Burnable(NUON).burn(NUONAmount);
        
        IERC20Burnable(collateralUsed).transfer(msg.sender, fullAmountSubFees);
        IERC20Burnable(collateralUsed).transfer(Treasury,fees);

        emit Redeemed(msg.sender, fullAmount, NUONAmount);

        }
    }

    function depositWithoutMint(
        uint256 _amount
    )
        external
        nonReentrant
    {
        require(
            INUONController(NUONController).isMintPaused() == false,
            'CHUB: Minting paused! Aaah!'
        );

        uint256 collateralAmount = _amount;
        require(collateralAmount > minimumDepositAmount, "Please deposit more than the min required amount");

        uint256 userAmount = usersAmounts[msg.sender];
        uint256 collateralAmountAfterFees = collateralAmount.sub(
        collateralAmount.mul(INUONController(NUONController).getMintingFee(address(this)))
        .div(100)
        .div(1e18));

        usersAmounts[msg.sender] = userAmount.add(collateralAmountAfterFees);

        if(getUserLiquidationStatus(msg.sender)) {
            revert("This will liquidate you");
        } else {
            IERC20Burnable(collateralUsed).transferFrom(msg.sender, address(this),_amount);
            INLP(NLP)._addAmountToPosition(mintedAmount[msg.sender], usersAmounts[msg.sender], userLPs[msg.sender], nlpPerUser[msg.sender]);
            IERC20Burnable(collateralUsed).transfer(
            Treasury,
            collateralAmount.sub(collateralAmountAfterFees));
            require(collateralPercentToRatio(msg.sender) >= INUONController(NUONController).getMaxCratio(address(this)),"Collateral Ratio too low");
            emit depositedWithoutMint(msg.sender, collateralAmount.sub(collateralAmountAfterFees),collateralAmountAfterFees);
        }
    }

    function _depositWithoutMintEstimation(
        uint256 _amount,
        address _user
    )
        public
        view
        returns(uint256,uint256,uint256)
    {

        require(_amount > minimumDepositAmount, "Please deposit more than the min required amount");
        uint256 collateralAmountAfterFees = _amount.sub(
        _amount.mul(INUONController(NUONController).getMintingFee(address(this)))
        .div(100)
        .div(1e18));

        uint256 ratio = INUONController(NUONController).getGlobalCollateralRatio(address(this));
        if (viewUserCollateralAmount(_user) > 0) {
            uint256 userTVL = ((viewUserCollateralAmount(_user).add(_amount)) * assetMultiplier) * getCollateralPrice() / 1e18;
            uint256 totalNUON = viewUserMintedAmount(_user);
            uint256 mintedValue =  totalNUON * getNUONPrice() / 1e18;
            uint256 result =  (userTVL * 1e18) / mintedValue * 100;
            uint256 rat = 1e18 * 1e18 / result * 100;
            require(rat < ratio, "This will liquidate you");
            return (result, collateralAmountAfterFees,userTVL);
        } else {
            return (0,0,0);
        }
    }

    /**
     * @notice Used to mint NUON without depositing collaterals, user has to have a position in the CHUB already
     * liquidations are automatic if user is over the threshold
     * return The minted NUON amount
     * @dev collateralAmount is in WETH
     */
    function mintWithoutDeposit(
        uint256 _amount
    )
        external
        nonReentrant
        returns (uint256)
    {
        require(
            INUONController(NUONController).isMintPaused() == false,
            'CHUB: Minting paused! Aaah!'
        );

        //cratio has to be bigger than the minimum required in the controller, otherwise user can get liquidated instantly
        //lower value means higher cratio
        require(usersAmounts[msg.sender] > 0, "You do not have a position in the CHUB");
        uint256 amountToMint = _amount;
        uint256 collateralRequired;

        mintedAmount[msg.sender] = mintedAmount[msg.sender].add(amountToMint);
        INLP(NLP)._addAmountToPosition(mintedAmount[msg.sender], usersAmounts[msg.sender], userLPs[msg.sender], nlpPerUser[msg.sender]);

        if (getUserLiquidityCoverage(msg.sender,0) < liquidityCheck) {
            (collateralRequired,)= mintLiquidityHelper(_amount);
            IERC20Burnable(collateralUsed).transferFrom(msg.sender, address(this),collateralRequired);
            _addLiquidity(collateralRequired);
        }

        if(getUserLiquidationStatus(msg.sender)) {
            revert("This will liquidate you");
        } else {
            INUON(NUON).mint(msg.sender, amountToMint);
            emit mintedWithoutDeposit(msg.sender, amountToMint,collateralRequired);
        }

        return amountToMint;
    }

    function _mintWithoutDepositEstimation(
        uint256 _amount,
        address _user
    )
        public
        view
        returns (uint256,uint256,uint256,uint256)
    {
        uint256 ratio = INUONController(NUONController).getGlobalCollateralRatio(address(this));
        require(usersAmounts[_user] > 0, "You do not have a position in the CHUB");
        if (viewUserCollateralAmount(_user) > 0) {
            uint256 userTVL = (viewUserCollateralAmount(_user) * assetMultiplier) * getCollateralPrice() / 1e18;
            uint256 totalNUON = viewUserMintedAmount(_user).add(_amount);
            uint256 mintedValue =  totalNUON * getNUONPrice() / 1e18;
            uint256 result =  (userTVL * 1e18) / mintedValue * 100;
            uint256 rat = 1e18 * 1e18 / result * 100;
            (uint256 collateralRequired,)= mintLiquidityHelper(_amount);

            require(rat < ratio, "This will liquidate you");
            return (result, _amount,totalNUON,collateralRequired);
        } else {
            return (0,0,0,0);
        }

        require(getUserLiquidityCoverage(_user,_amount) > liquidityCheck, "Increase your liquidity coverage");

    }

    /**
     * @notice Used to redeem a collateral amount without giving back NUON
     * @param _collateralAmount NUON amount to give back
     */
    function redeemWithoutNuon(uint256 _collateralAmount)
        external
        nonReentrant
    {
        require(
            INUONController(NUONController).isRedeemPaused() == false,
            'CHUB: Minting paused! Aaah!'
        );

        uint256 userAmount = usersAmounts[msg.sender];
        uint256 collateralAmount = _collateralAmount;
        require(userAmount > 0, 'You do not have any balance in that CHUB');
        require(collateralAmount < userAmount, "Cannot withdraw all the collaterals");

        usersAmounts[msg.sender] = userAmount.sub(collateralAmount);
        INLP(NLP)._addAmountToPosition(mintedAmount[msg.sender], usersAmounts[msg.sender], userLPs[msg.sender], nlpPerUser[msg.sender]);
        
        uint256 fees = collateralAmount
            .mul(INUONController(NUONController).getRedeemFee(address(this)))
            .div(100)
            .div(1e18);
        uint256 toUser = collateralAmount.sub(fees);
        
        if(getUserLiquidationStatus(msg.sender)) {
            revert("This will liquidate you");
        } else {
            IERC20Burnable(collateralUsed).transfer(msg.sender, toUser);
            IERC20Burnable(collateralUsed).transfer(Treasury,fees);
            emit redeemedWithoutNuon(msg.sender, fees, toUser);
        }
    }

    function _redeemWithoutNuonEstimation(uint256 _collateralAmount, address _user)
        public
        view
        returns(uint256,uint256,uint256)
    {
        uint256 ratio = INUONController(NUONController).getGlobalCollateralRatio(address(this));
        require(usersAmounts[_user] > 0, 'You do not have any balance in that CHUB');
        require(_collateralAmount < usersAmounts[_user], "Cannot withdraw all the collaterals");
        
        uint256 fees = _collateralAmount
            .mul(INUONController(NUONController).getRedeemFee(address(this)))
            .div(100)
            .div(1e18);
        uint256 toUser = _collateralAmount.sub(fees);

        if (viewUserCollateralAmount(_user) > 0) {
            uint256 camount = usersAmounts[_user].sub(_collateralAmount);
            uint256 userTVL = (camount * assetMultiplier) * getCollateralPrice() / 1e18;
            uint256 totalNUON = viewUserMintedAmount(_user);
            uint256 mintedValue =  totalNUON * getNUONPrice() / 1e18;
            uint256 result =  (userTVL * 1e18) / mintedValue * 100;
            uint256 rat = 1e18 * 1e18 / result * 100;
            require(rat < ratio, "This will liquidate you");
            return (result, toUser,camount);
        } else {
            return (0,0,0);
        }
    }

    /**
     * @notice Used to redeem a collateral amount without giving back NUON
     * @param _nuonAmount NUON amount to give back
     */
    function burnNUON(uint256 _nuonAmount)
        external
        nonReentrant
    {
        uint256 usernlp = nlpPerUser[msg.sender];
        require(
            INUONController(NUONController).isRedeemPaused() == false,
            'CHUB: Redeem paused! Aaah!'
        );

        uint256 nuonAmount = _nuonAmount;
        uint256 userAmount = usersAmounts[msg.sender];
        uint256 userMintedAmount = mintedAmount[msg.sender];

        require(userAmount > 0, 'You do not have any balance in that CHUB');
        uint256 maxBurn = userMintedAmount.mul(maxNuonBurnPercent).div(100);
        require(_nuonAmount < maxBurn, 'Cannot burn your whole balance of NUON');

        mintedAmount[msg.sender] = userMintedAmount.sub(nuonAmount);
        INLP(NLP)._addAmountToPosition(mintedAmount[msg.sender], usersAmounts[msg.sender], userLPs[msg.sender], nlpPerUser[msg.sender]);
        uint256 sharesToUser = redeemLiquidityHelper(nuonAmount,msg.sender);
        userLPs[msg.sender] = userLPs[msg.sender].sub(sharesToUser);

        if(getUserLiquidationStatus(msg.sender)) {
            revert("This will liquidate you");
        } else {
            IERC20Burnable(NUON).transferFrom(msg.sender, address(this), nuonAmount);
            uint256 lpToSend = _removeUserLPs(sharesToUser);
            IERC20Burnable(lpPair).transfer(msg.sender, lpToSend);
            IERC20Burnable(NUON).burn(nuonAmount);
            require(collateralPercentToRatio(msg.sender) >= INUONController(NUONController).getMaxCratio(address(this)),"Collateral Ratio too low");
            emit burnedNuon(msg.sender, nuonAmount, lpToSend);
        }
    }

    function _burnNUONEstimation(uint256 _NUONAmount, address _user) public view returns(uint256,uint256,uint256) {
        uint256 ratio = INUONController(NUONController).getGlobalCollateralRatio(address(this));

        require(usersAmounts[_user] > 0, 'You do not have any balance in that CHUB');
        uint256 maxBurn = mintedAmount[_user].mul(maxNuonBurnPercent).div(100);
        require(_NUONAmount < maxBurn, 'Cannot burn your whole balance of NUON');
        
        if (viewUserCollateralAmount(_user) > 0) {
            uint256 userTVL = (viewUserCollateralAmount(_user) * assetMultiplier) * getCollateralPrice() / 1e18;
            uint256 totalNUON = viewUserMintedAmount(_user).sub(_NUONAmount);
            uint256 mintedValue =  totalNUON * getNUONPrice() / 1e18;
            uint256 result =  (userTVL * 1e18) / mintedValue * 100;
            uint256 rat = 1e18 * 1e18 / result * 100;
            require(rat < ratio, "This will liquidate you");
            return (result, _NUONAmount, totalNUON);
        } else {
            return (0,0,0);
        }

    }

    function liquidateUserAssets(address _user) public {
        uint256 usernlp = nlpPerUser[_user];
        require(getUserLiquidationStatus(_user),"User cannot be liquidated");
        address router = unirouter;
        uint256 mintedAmount = mintedAmount[_user];
        uint256 userAmount = usersAmounts[_user];
        uint256 sharesAmount = userLPs[_user];
        
        INLP(NLP).burnNLP(usernlp);
        INLP(NLP)._deletePositionInfo(_user);
        _deleteUsersData(_user);

        (,uint256 collateralRequired) = mintLiquidityHelper(mintedAmount);
        uint256 liqProfit = userAmount - collateralRequired;
        IERC20Burnable(collateralUsed).approve(router, collateralRequired);

        uint256 balBefore = INUON(NUON).balanceOf(address(this));
        IUniswapRouterETH(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                collateralRequired,
                0,
                collateralToNuonRoute,
                address(this),
                block.timestamp
            );
        uint256 balAfter = INUON(NUON).balanceOf(address(this));

        INUON(NUON).burn(balAfter - balBefore);
        uint256 liqFee = liqProfit * liquidationFee / 1000;
        IERC20Burnable(collateralUsed).transfer(Treasury, liqProfit - liqFee);
        IERC20Burnable(collateralUsed).transfer(msg.sender, liqFee);
        uint256 lpToSend = _removeUserLPs(sharesAmount);
        IERC20Burnable(lpPair).transfer(_user, lpToSend);
    }

    /**
     * @notice View function used to compute the amount of NUON to be minted
     * @param collateralRatio Determined by the controller contract
     * @param collateralPrice Determined by the assigned oracle
     * @param collateralAmountD18 Collateral amount in d18 format
     * return The NUON amount to be minted
     */
    function calcOverCollateralizedMintAmounts(
        uint256 collateralRatio, // 500000000000000000
        uint256 collateralPrice, //20000000000000000000000
        uint256 collateralAmountD18 //15000000000000000000
    ) internal view returns (uint256) {
        uint256 collateralValue = (
            collateralAmountD18.mul(collateralPrice)).div(1e18);
        uint256 NUONValueToMint = collateralValue.mul(collateralRatio).div(ITruflation(TruflationOracle).getNuonTargetPeg());
        return NUONValueToMint;
    }

    /**
     * @notice View function used to compute the amount of collaterals given back to the user
     * @param collateralRatio Determined by the controller contract
     * @param collateralPrice Determined by the assigned oracle
     * @param NUONAmount NUON amount in d18 format
     * @param multiplier Collateral multiplier factor
     * return The amount of collateral out
     */
    function calcOverCollateralizedRedeemAmounts(
        uint256 collateralRatio,
        uint256 collateralPrice,
        uint256 NUONAmount,
        uint256 multiplier
    ) internal view returns (uint256) {
        uint256 NUONValueNeeded = (
            NUONAmount.mul(ITruflation(TruflationOracle).getNuonTargetPeg()).div(collateralRatio)
        ).mul(1e18);
        uint256 NUONAmountToBurn = (NUONValueNeeded.mul(multiplier).div(collateralPrice).div(1e18));
        return (NUONAmountToBurn);
    }

    function mintLiquidityHelper(uint256 _NUONAmountD18) internal view returns(uint256,uint256) {
        uint256 nuonValue = _NUONAmountD18.mul(getNUONPrice()).div(1e18);
        uint256 collateralRequired = nuonValue.mul(1e18).div(getCollateralPrice()).div(assetMultiplier);
        uint256 collateralBuffer = collateralRequired.mul(liquidityBuffer).div(100);
        return(collateralRequired.add(collateralBuffer),collateralRequired);
    }

    function redeemLiquidityHelper(uint256 _nuonAmount, address _user) internal view returns(uint256) {
        uint256 nuonAmount = _nuonAmount;
        uint256 lpAmount = userLPs[msg.sender];
        //we do not use the buffer for redeem
        (,uint256 collateralRequired) = mintLiquidityHelper(_nuonAmount);
        uint256 lpValue = getLPValueOfUser(_user);

        uint256 proportion = (collateralRequired.div(2)).mul(1e18).div(lpValue).mul(100);
        uint256 lpToUser = lpAmount.mul(proportion).div(1e18).div(100);
        return(lpToUser);
    }

    function getLPValueOfUser(address _user) internal view returns (uint256) {
        uint256 lpAmount = userLPs[_user].mul(IRelayer(Relayer).getPPFS()).div(1e18);
        uint256 userMintedAmount = mintedAmount[_user];

        uint256 collateralBal = IERC20Burnable(collateralUsed).balanceOf(lpPair);
        uint256 totalSupplyOf = IERC20Burnable(lpPair).totalSupply();
        uint256 lpValue = (lpAmount.mul(1e18).div(totalSupplyOf)).mul(collateralBal).div(1e18);
        return lpValue;
    }

    function getUserLiquidityCoverage(address _user, uint256 _extraAmount) public view returns(uint256) {
        uint256 lpValue = getLPValueOfUser(_user);
        uint256 userMintedAmount = mintedAmount[_user].add(_extraAmount);
        
        (,uint256 collateralRequired) = mintLiquidityHelper(userMintedAmount);
        uint256 coverage = lpValue.mul(1e18).div(collateralRequired).mul(100);
        
        return(coverage);
    }

    function _deleteUsersData(address _user) internal {
        mintedAmount[_user] = 0;
        usersAmounts[_user] = 0;
        userLPs[_user] = 0;
        delete users[usersIndex[_user]];
        usersIndex[_user] = 0;
        nlpCheck[_user] = false;
        delete nlpPerUser[_user];
    }

    function _reAssignNewOwnerBalances(address _user, address _receiver, bool _hasPosition, uint256 _tokenId) public {
        require(msg.sender == NLP, "Not the NLP");
        //if receiver does not have a position yet, we create one for him
        //otherwise we merge his actual position 
        if (_hasPosition == false) {
            mintedAmount[_receiver] = mintedAmount[_user];
            usersAmounts[_receiver] = usersAmounts[_user];
            userLPs[_receiver] = userLPs[_user];
            nlpPerUser[_receiver] = _tokenId;
            usersIndex[_receiver] = users.length;
            users.push(_receiver);
            nlpCheck[_receiver] = true;
            INLP(NLP)._addAmountToPosition(mintedAmount[_receiver], usersAmounts[_receiver], userLPs[_receiver],_tokenId);
        } else if (_hasPosition) {
            uint256 pos = getPositionOwned(_receiver);
            mintedAmount[_receiver] = mintedAmount[_receiver].add(mintedAmount[_user]);
            usersAmounts[_receiver] = usersAmounts[_receiver].add(usersAmounts[_user]);
            userLPs[_receiver] = userLPs[_receiver].add(userLPs[_user]);
            INLP(NLP)._topUpPosition(mintedAmount[_receiver], usersAmounts[_receiver], userLPs[_receiver],pos,_receiver);
            INLP(NLP)._deletePositionInfo(_user);
        }
        _deleteUsersData(_user);
    }
}