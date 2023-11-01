// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseRewardPool {
    function stakingDecimals() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function rewardTokenInfos()
        external
        view
        returns
        (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        );

    function earned(address account, address token)
        external
        view
        returns (uint256);

    function allEarned(address account)
        external
        view
        returns (uint256[] memory pendingBonusRewards);

    function queueNewRewards(uint256 _rewards, address token)
        external
        returns (bool);

    function getReward(address _account, address _receiver) external returns (bool);

    function getRewards(address _account, address _receiver, address[] memory _rewardTokens) external;

    function updateFor(address account) external;

    function updateManager(address _rewardManager, bool _allowed) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IConverter {

    function convert(uint256 _amountIn, uint256 _convertRatio, uint256 _minimutRec, uint256 _mode) external returns (uint256);

    function convertFor(uint256 _amountIn, uint256 _convertRatio, uint256 _minimutRec, address _for, uint256 _mode) external returns (uint256);

    function smartConvert(uint256 _amountIn, uint256 _mode) external returns (uint256);

    function depositFor(uint256 _amountIn, address _for) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDelegateRegistry {
    function delegation(
        address _delegator,
        bytes32 _id
    ) external view returns (address);

    function setDelegate(bytes32 _id, address _delegate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPoolHelper.sol";


interface IHarvesttablePoolHelper is IPoolHelper {
    function harvest() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterMagpie {
    function poolLength() external view returns (uint256);

    function setPoolManagerStatus(address _address, bool _bool) external;

    function add(
        uint256 _allocPoint,
        address _stakingTokenToken,
        address _rewarder,
        address _helper,
        bool _helperNeedsHarvest
    ) external;

    function createRewarder(
        address _stakingToken,
        address mainRewardToken
    ) external returns (address);

    function set(
        address _stakingToken,
        uint256 _allocPoint,
        address _helper,
        address _rewarder,
        bool _helperNeedsHarvest
    ) external;

    // View function to see pending GMPs on frontend.
    function getPoolInfo(
        address token
    )
        external
        view
        returns (
            uint256 emission,
            uint256 allocpoint,
            uint256 sizeOfPool,
            uint256 totalPoint
        );

    function rewarderBonusTokenInfo(
        address _stakingToken
    )
        external
        view
        returns (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        );

    function pendingTokens(
        address _stakingToken,
        address _user,
        address token
    )
        external
        view
        returns (
            uint256 _pendingGMP,
            address _bonusTokenAddress,
            string memory _bonusTokenSymbol,
            uint256 _pendingBonusToken
        );

    function allPendingTokens(
        address _stakingToken,
        address _user
    )
        external
        view
        returns (
            uint256 pendingMGP,
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
        );

    function massUpdatePools() external;

    function updatePool(address _stakingToken) external;

    function deposit(address _stakingToken, uint256 _amount) external;

    function withdraw(address _stakingToken, uint256 _amount) external;

    function depositFor(
        address _stakingToken,
        uint256 _amount,
        address sender
    ) external;

    function withdrawFor(
        address _stakingToken,
        uint256 _amount,
        address _sender
    ) external;

    function depositVlMGPFor(uint256 _amount, address sender) external;

    function withdrawVlMGPFor(uint256 _amount, address sender) external;

    function depositMWomSVFor(uint256 _amount, address sender) external;

    function withdrawMWomSVFor(uint256 _amount, address sender) external;

    function multiclaimFor(
        address[] calldata _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function multiclaimOnBehalf(
        address[] memory _stakingTokens,
        address[][] calldata _rewardTokens,
        address user_address
    ) external;

    function emergencyWithdraw(address _stakingToken, address sender) external;

    function updateEmissionRate(uint256 _gmpPerSec) external;

    function stakingInfo(
        address _stakingToken,
        address _user
    ) external view returns (uint256 depositAmount, uint256 availableAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IMintableERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address, uint256) external;
    function faucet(uint256) external;

    function burn(address, uint256) external;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolHelper {
    function totalStaked() external view returns (uint256);

    function balance(address _address) external view returns (uint256);

    function deposit(uint256 amount, uint256 minimumAmount) external;

    function withdraw(uint256 amount, uint256 minimumAmount) external;

    function isNative() external view returns (bool);

    function pid() external view returns (uint256);

    function depositToken() external view returns (address);

    function lpToken() external view returns (address);

    function rewarder() external view returns (address);

    function stakingToken() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISimpleHelper {
    function depositFor(uint256 _amount, address _for) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWNative {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IBNBZapper {
    function previewTotalAmount(IERC20[][] calldata inTokens, uint256[][] calldata amounts) external view returns(uint256 bnbAmount);
    function zapInToken(address _from, uint256 amount, uint256 minRec, address receiver) external returns (uint256 bnbAmount);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMasterWombat {

    function getAssetPid(address lp) external view returns(uint256);
    
    function depositFor(uint256 pid, uint256 amount, address account) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256);

    function multiClaim(uint256[] memory _pids) external returns (
        uint256 transfered,
        uint256[] memory amounts,
        uint256[] memory additionalRewards
    );

    function pendingTokens(uint256 _pid, address _user) external view
        returns (
            uint256 pendingRewards,
            IERC20[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols,
            uint256[] memory pendingBonusRewards
    );

    function migrate(uint256[] calldata _pids) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMultiRewarder {
    function onReward(address _user, uint256 _lpAmount) external returns (uint256[] memory rewards);

    function pendingTokens(address _user) external view returns (uint256[] memory rewards);

    function rewardTokens() external view returns (IERC20[] memory tokens);

    function rewardLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IMWom is IERC20 {
    function deposit(uint256 _amount) external;
    function convert(uint256 amount) external;
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/**
 * @dev Interface of the VeWom
 */
interface IVeWom {
    struct Breeding {
        uint48 unlockTime;
        uint104 womAmount;
        uint104 veWomAmount;
    }

    struct UserInfo {
        // reserve usage for future upgrades
        uint256[10] reserved;
        Breeding[] breedings;
    }

    function totalSupply() external view returns (uint256);

    function balanceOf(address _addr) external view returns (uint256);

    function isUser(address _addr) external view returns (bool);

    function getUserInfo(address addr) external view returns (Breeding[] memory);

    function mint(uint256 amount, uint256 lockDays) external returns (uint256 veWomAmount);

    function burn(uint256 slot) external;

    function whitelist() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IMultiRewarder.sol';

interface IWombatBribe is IMultiRewarder {

    function onVote(
        address user,
        uint256 newVote,
        uint256 originalTotalVotes
    ) external returns (uint256[] memory rewards);

}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IWombatPool {
    function ampFactor() external view returns (uint256);

    /**
     * @notice Deposits amount of tokens into pool ensuring deadline
     * @dev Asset needs to be created and added to pool before any operation. This function assumes tax free token.
     * @param token The token address to be deposited
     * @param amount The amount to be deposited
     * @param to The user accountable for deposit, receiving the Wombat assets (lp)
     * @param deadline The deadline to be respected
     * @return liquidity Total asset liquidity minted
     */
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256 liquidity);

    /**
     * @notice Withdraws liquidity amount of asset to `to` address ensuring minimum amount required
     * @param token The token to be withdrawn
     * @param liquidity The liquidity to be withdrawn
     * @param minimumAmount The minimum amount that will be accepted by user
     * @param to The user receiving the withdrawal
     * @param deadline The deadline to be respected
     * @return amount The total amount withdrawn
     */
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

pragma solidity ^0.8.0;

interface IWombatStaking {
    function convertWOM(uint256 amount) external returns (uint256);

    function masterWombat() external view returns (address);

    function deposit(
        address _lpToken,
        uint256 _amount,
        uint256 _minAmount,
        address _for,
        address _from
    ) external;

    function depositLP(address _lpToken, uint256 _lpAmount, address _for) external;

    function withdraw(
        address _lpToken,
        uint256 _amount,
        uint256 _minAmount,
        address _sender
    ) external;

    function withdrawLP(address _lpToken, uint256 _lpAmount, address _sender) external;

    function getPoolLp(address _lpToken) external view returns (address);

    function harvest(address _lpToken) external;

    function burnReceiptToken(address _lpToken, uint256 _amount) external;

    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    ) external returns (address[][] memory rewardTokens, uint256[][] memory feeAmounts);

    function voter() external view returns (address);

    function pendingBribeCallerFee(
        address[] calldata pendingPools
    )
        external
        view
        returns (IERC20[][] memory rewardTokens, uint256[][] memory callerFeeAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IWombatBribe.sol';

interface IWombatGauge {
    function notifyRewardAmount(IERC20 token, uint256 amount) external;
}

interface IWombatVoter {
    struct GaugeInfo {
        uint104 supplyBaseIndex;
        uint104 supplyVoteIndex;
        uint40 nextEpochStartTime;
        uint128 claimable;
        bool whitelist;
        IWombatGauge gaugeManager;
        IWombatBribe bribe;
    }
    
    struct GaugeWeight {
        uint128 allocPoint;
        uint128 voteWeight; // total amount of votes for an LP-token
    }

    function infos(address) external view returns (GaugeInfo memory);

    function getUserVotes(address _user, address _lpToken) external view returns (uint256);

    function lpTokenLength() external view returns (uint256);

    function weights(address _lpToken) external view returns (GaugeWeight memory);    

    function pendingBribes(address[] calldata _lpTokens, address _user)
        external
        view
        returns (uint256[][] memory bribeRewards);

    function vote(address[] calldata _lpVote, int256[] calldata _deltas)
        external
        returns (uint256[][] memory bribeRewards);
}

// SPDX-License-Identifier: GPL-3.0

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library DSMath {
    uint256 public constant WAD = 10**18;

    // Babylonian Method
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Babylonian Method with initial guess
    function sqrt(uint256 y, uint256 guess) internal pure returns (uint256 z) {
        if (y > 3) {
            if (guess > y || guess == 0) {
                z = y;
            } else {
                z = guess;
            }
            uint256 x = (y / z + z) / 2;
            while (x != z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((x * WAD) + (y / 2)) / y;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MintableERC20} from "./MintableERC20.sol";
import {BaseRewardPoolV3} from "../rewards/BaseRewardPoolV3.sol";
import {WombatPoolHelperV3} from "../wombat/WombatPoolHelperV3.sol";
import {BribeRewardPool} from "../rewards/BribeRewardPool.sol";

library MagpieFactoryLib {
    function createERC20(
        string memory name_,
        string memory symbol_
    ) public returns (address) {
        ERC20 token = new MintableERC20(name_, symbol_);
        return address(token);
    }

    function createRewarder(
        address _stakingToken,
        address _mainRewardToken,
        address _masterMagpie,
        address _rewardManager
    ) external returns (address) {
        BaseRewardPoolV3 _rewarder = new BaseRewardPoolV3(
            _stakingToken,
            _mainRewardToken,
            _masterMagpie,
            _rewardManager
        );
        return address(_rewarder);
    }

    function createWombatPoolHelper(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _lpToken,
        address _wombatStaking,
        address _masterMagpie,
        address _rewarder,
        address _mWom,
        bool _isNative
    ) public returns (address) {
        WombatPoolHelperV3 pool = new WombatPoolHelperV3(
            _pid,
            _stakingToken,
            _depositToken,
            _lpToken,
            _wombatStaking,
            _masterMagpie,
            _rewarder,
            _mWom,
            _isNative
        );
        return address(pool);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MintableERC20 is ERC20, Ownable {
    /*
    The ERC20 deployed will be owned by the others contracts of the protocol, specifically by
    MasterMagpie and WombatStaking, forbidding the misuse of these functions for nefarious purposes
    */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {} 

    function mint(address account, uint256 amount) external virtual onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external virtual onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    int256 public constant WAD = 10**18;

    //rounds to zero if x*y < WAD / 2
    function wdiv(int256 x, int256 y) internal pure returns (int256) {
        return ((x * WAD) + (y / 2)) / y;
    }

    //rounds to zero if x*y < WAD / 2
    function wmul(int256 x, int256 y) internal pure returns (int256) {
        return ((x * y) + (WAD / 2)) / WAD;
    }

    // Babylonian Method (typecast as int)
    function sqrt(int256 y) internal pure returns (int256 z) {
        if (y > 3) {
            z = y;
            int256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Babylonian Method with initial guess (typecast as int)
    function sqrt(int256 y, int256 guess) internal pure returns (int256 z) {
        if (y > 3) {
            if (guess > 0 && guess <= y) {
                z = guess;
            } else if (guess < 0 && -guess <= y) {
                z = -guess;
            } else {
                z = y;
            }
            int256 x = (y / z + z) / 2;
            while (x != z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // Convert x to WAD (18 decimals) from d decimals.
    function toWad(int256 x, uint8 d) internal pure returns (int256) {
        if (d < 18) {
            return x * int256(10**(18 - d));
        } else if (d > 18) {
            return (x / int256(10**(d - 18)));
        }
        return x;
    }

    // Convert x from WAD (18 decimals) to d decimals.
    function fromWad(int256 x, uint8 d) internal pure returns (int256) {
        if (d < 18) {
            return (x / int256(10**(18 - d)));
        } else if (d > 18) {
            return x * int256(10**(d - 18));
        }
        return x;
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'value must be positive');
        return uint256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMasterMagpie.sol";
import "../interfaces/IBaseRewardPool.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BaseRewardPool is Ownable, IBaseRewardPool {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    address public immutable stakingToken;
    address public immutable operator;          // master magpie

    address[] public rewardTokens;

    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    mapping(address => Reward) public rewards;                           // [rewardToken]
    // amount by [rewardToken][account], 
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;                 
    mapping(address => mapping(address => uint256)) public userRewards;  // amount by [rewardToken][account]
    mapping(address => bool) public isRewardToken;
    mapping(address => bool) public managers;

    /* ============ Events ============ */

    event RewardAdded(uint256 _reward, address indexed _token);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _receiver, uint256 _reward, address indexed _token);
    event ManagerUpdated(address indexed _manager, bool _allowed);

    /* ============ Errors ============ */

    error OnlyManager();
    error OnlyMasterMagpie();
    error NotAllowZeroAddress();
    error MustBeRewardToken();

    /* ============ Constructor ============ */

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _masterMagpie,
        address _rewardManager
    ) {
        if(
            _stakingToken == address(0) ||
            _masterMagpie  == address(0) ||
            _rewardManager  == address(0)
        ) revert NotAllowZeroAddress();

        stakingToken = _stakingToken;
        operator = _masterMagpie;

        if (_rewardToken != address(0)) {
            rewards[_rewardToken] = Reward({
                rewardToken: _rewardToken,
                rewardPerTokenStored: 0,
                queuedRewards: 0,
                historicalRewards: 0
            });
            rewardTokens.push(_rewardToken);
        }

        isRewardToken[_rewardToken] = true;
        managers[_rewardManager] = true;
    }

    /* ============ Modifiers ============ */

    modifier updateReward(address _account) {
        _updateFor(_account);
        _;
    }

    modifier onlyManager() {
        if (!managers[msg.sender])
            revert OnlyManager();
        _;
    }

    modifier onlyMasterMagpie() {
        if (msg.sender != operator)
            revert OnlyMasterMagpie();
        _;
    }

    /* ============ External Getters ============ */

    /// @notice Returns decimals of reward token
    /// @param _rewardToken Address of reward token
    /// @return Returns decimals of reward token
    function rewardDecimals(address _rewardToken)
        public
        view
        returns (uint256)
    {
        return IERC20Metadata(_rewardToken).decimals();
    }

    /// @notice Returns decimals of staking token
    /// @return Returns decimals of staking token
    function stakingDecimals() public override view returns (uint256) {
        return IERC20Metadata(stakingToken).decimals();
    }

    /// @notice Returns current amount of staked tokens
    /// @return Returns current amount of staked tokens
    function totalStaked() external override virtual view returns (uint256) {
        return IERC20(stakingToken).balanceOf(operator);
    }

    /// @notice Returns amount of staked tokens in master magpie by account
    /// @param _account Address account
    /// @return Returns amount of staked tokens by account
    function balanceOf(address _account) public override virtual view returns (uint256) {
        (uint256 staked, ) =  IMasterMagpie(operator).stakingInfo(stakingToken, _account);
        return staked;
    }

    /// @notice Returns amount of reward token per staking tokens in pool
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token per staking tokens in pool
    function rewardPerToken(address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return rewards[_rewardToken].rewardPerTokenStored;
    }

    function rewardTokenInfos()
        override
        external
        view
        returns
        (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        )
    {
        uint256 rewardTokensLength = rewardTokens.length;
        bonusTokenAddresses = new address[](rewardTokensLength);
        bonusTokenSymbols = new string[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; i++) {
            bonusTokenAddresses[i] = rewardTokens[i];
            bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
        }
    }

    /// @notice Returns amount of reward token earned by a user
    /// @param _account Address account
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token earned by a user
    function earned(address _account, address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return (
            (((balanceOf(_account) *
                (rewardPerToken(_rewardToken) -
                    userRewardPerTokenPaid[_rewardToken][_account])) /
                (10**stakingDecimals())) + userRewards[_rewardToken][_account])
        );
    }

    /// @notice Returns amount of all reward tokens
    /// @param _account Address account
    /// @return pendingBonusRewards as amounts of all rewards.
    function allEarned(address _account)
        external
        override
        view
        returns (
            uint256[] memory pendingBonusRewards
        )
    {
        uint256 length = rewardTokens.length;
        pendingBonusRewards = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            pendingBonusRewards[i] = earned(_account, rewardTokens[i]);
        }

        return pendingBonusRewards;
    }

    function getStakingToken() external view returns (address) {
        return stakingToken;
    }

    /* ============ External Functions ============ */

    /// @notice Updates the reward information for one account
    /// @param _account Address account
    function updateFor(address _account) override external {
        _updateFor(_account);
    }

    /// @notice Calculates and sends reward to user. Only callable by masterMagpie
    /// @param _account Address account
    function getReward(address _account, address _receiver)
        override
        public
        onlyMasterMagpie
        updateReward(_account)
        returns (bool)
    {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = userRewards[rewardToken][_account]; // updated during updateReward modifier
            if (reward > 0) {
                userRewards[rewardToken][_account] = 0;
                IERC20(rewardToken).safeTransfer(_receiver, reward);
                emit RewardPaid(_account, _receiver, reward, rewardToken);
            }
        }

        return true;
    }

    function getRewards(address _account, address _receiver, address[] memory _rewardTokens) override external {

    }

    function getRewardLength() external view returns(uint256) {
        return rewardTokens.length;
    }

    /* ============ Admin Functions ============ */

    function updateManager(address _rewardManager, bool _allowed) external onlyOwner {
        managers[_rewardManager] = _allowed;

        emit ManagerUpdated(_rewardManager, managers[_rewardManager]);
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only callable by manager
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function queueNewRewards(uint256 _amountReward, address _rewardToken)
        override
        external
        onlyManager
        returns (bool)
    {
        if (!isRewardToken[_rewardToken]) {
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }

        _provisionReward(_amountReward, _rewardToken);
        return true;
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only possible to donate already registered token
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function donateRewards(uint256 _amountReward, address _rewardToken) external {
        if (!isRewardToken[_rewardToken])
            revert MustBeRewardToken();

        _provisionReward(_amountReward, _rewardToken);
    }

    /* ============ Internal Functions ============ */

    function _updateFor(address _account) internal {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            userRewards[rewardToken][_account] = earned(_account, rewardToken);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(rewardToken);
        }
    }

    function _provisionReward(uint256 _amountReward, address _rewardToken) internal {
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountReward
        );
        Reward storage rewardInfo = rewards[_rewardToken];
        rewardInfo.historicalRewards =
            rewardInfo.historicalRewards +
            _amountReward;
        if (this.totalStaked() == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10**stakingDecimals()) /
                this.totalStaked();
        }
        emit RewardAdded(_amountReward, _rewardToken);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMasterMagpie.sol";
import "../interfaces/IBaseRewardPool.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BaseRewardPoolV3 is Ownable, IBaseRewardPool {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    uint256 public constant DENOMINATOR = 10**12;

    address public immutable stakingToken;
    address public immutable operator;          // master magpie
    uint256 public immutable stakingTokenDecimals;

    address[] public rewardTokens;

    struct Reward {
        address rewardToken;
        uint256 rewardPerTokenStored;
        uint256 queuedRewards;
        uint256 historicalRewards;
    }

    mapping(address => Reward) public rewards;                           // [rewardToken]
    // amount by [rewardToken][account], 
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;                 
    mapping(address => mapping(address => uint256)) public userRewards;  // amount by [rewardToken][account]
    mapping(address => bool) public isRewardToken;
    mapping(address => bool) public managers;

    /* ============ Events ============ */

    event RewardAdded(uint256 _reward, address indexed _token);
    event Staked(address indexed _user, uint256 _amount);
    event Withdrawn(address indexed _user, uint256 _amount);
    event RewardPaid(address indexed _user, address indexed _receiver, uint256 _reward, address indexed _token);
    event ManagerUpdated(address indexed _manager, bool _allowed);
    event EmergencyWithdrawn(address indexed _manager, address _token, uint256 _amount);

    /* ============ Errors ============ */

    error OnlyManager();
    error OnlyMasterMagpie();
    error NotAllowZeroAddress();
    error MustBeRewardToken();

    /* ============ Constructor ============ */

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _masterMagpie,
        address _rewardManager
    ) {
        if(
            _stakingToken == address(0) ||
            _masterMagpie  == address(0) ||
            _rewardManager  == address(0)
        ) revert NotAllowZeroAddress();

        stakingToken = _stakingToken;
        stakingTokenDecimals = IERC20Metadata(stakingToken).decimals();
        operator = _masterMagpie;

        if (_rewardToken != address(0)) {
            rewards[_rewardToken] = Reward({
                rewardToken: _rewardToken,
                rewardPerTokenStored: 0,
                queuedRewards: 0,
                historicalRewards: 0
            });
            rewardTokens.push(_rewardToken);

            isRewardToken[_rewardToken] = true;
        }

        managers[_rewardManager] = true;
    }

    /* ============ Modifiers ============ */

    modifier onlyManager() {
        if (!managers[msg.sender])
            revert OnlyManager();
        _;
    }

    modifier onlyMasterMagpie() {
        if (msg.sender != operator)
            revert OnlyMasterMagpie();
        _;
    }

    modifier updateReward(address _account) {
        _updateFor(_account);
        _;
    }

    modifier updateRewards(address _account, address[] memory _rewards) {
        uint256 length = _rewards.length;
        uint256 userShare = balanceOf(_account);
        
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = _rewards[index];
            // if a reward stopped queuing, no need to recalculate to save gas fee
            if (userRewardPerTokenPaid[rewardToken][_account] == rewardPerToken(rewardToken))
                continue;
            userRewards[rewardToken][_account] = _earned(_account, rewardToken, userShare);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(rewardToken);
        }
        _;
    }  

    /* ============ External Getters ============ */

    /// @notice Returns current amount of staked tokens
    /// @return Returns current amount of staked tokens
    function totalStaked() public override virtual view returns (uint256) {
        return IERC20(stakingToken).balanceOf(operator);
    }

    /// @notice Returns amount of staked tokens in master magpie by account
    /// @param _account Address account
    /// @return Returns amount of staked tokens by account
    function balanceOf(address _account) public override virtual view returns (uint256) {
        (uint256 staked, ) =  IMasterMagpie(operator).stakingInfo(stakingToken, _account);
        return staked;
    }

    function stakingDecimals() external override virtual view returns (uint256) {
        return stakingTokenDecimals;
    }

    /// @notice Returns amount of reward token per staking tokens in pool in 10**12
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token per staking tokens in pool in 10**12
    function rewardPerToken(address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return rewards[_rewardToken].rewardPerTokenStored;
    }

    function rewardTokenInfos()
        override
        external
        view
        returns
        (
            address[] memory bonusTokenAddresses,
            string[] memory bonusTokenSymbols
        )
    {
        uint256 rewardTokensLength = rewardTokens.length;
        bonusTokenAddresses = new address[](rewardTokensLength);
        bonusTokenSymbols = new string[](rewardTokensLength);
        for (uint256 i; i < rewardTokensLength; i++) {
            bonusTokenAddresses[i] = rewardTokens[i];
            bonusTokenSymbols[i] = IERC20Metadata(address(bonusTokenAddresses[i])).symbol();
        }
    }

    /// @notice Returns amount of reward token earned by a user
    /// @param _account Address account
    /// @param _rewardToken Address reward token
    /// @return Returns amount of reward token earned by a user
    function earned(address _account, address _rewardToken)
        public
        override
        view
        returns (uint256)
    {
        return _earned(_account, _rewardToken, balanceOf(_account));
    }

    /// @notice Returns amount of all reward tokens
    /// @param _account Address account
    /// @return pendingBonusRewards as amounts of all rewards.
    function allEarned(address _account)
        external
        override
        view
        returns (
            uint256[] memory pendingBonusRewards
        )
    {
        uint256 length = rewardTokens.length;
        pendingBonusRewards = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            pendingBonusRewards[i] = earned(_account, rewardTokens[i]);
        }

        return pendingBonusRewards;
    }

    function getRewardLength() external view returns(uint256) {
        return rewardTokens.length;
    }    

    /* ============ External Functions ============ */

    /// @notice Updates the reward information for one account
    /// @param _account Address account
    function updateFor(address _account) override external {
        _updateFor(_account);
    }

    function getReward(address _account, address _receiver)
        public
        onlyMasterMagpie
        updateReward(_account)
        returns (bool)
    {
        uint256 length = rewardTokens.length;

        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = userRewards[rewardToken][_account]; // updated during updateReward modifier
            if (reward > 0) {
                _sendReward(rewardToken, _account, _receiver, reward);
            }
        }

        return true;
    }

    function getRewards(address _account, address _receiver, address[] memory _rewardTokens) override
        external
        onlyMasterMagpie
        updateRewards(_account, _rewardTokens)
    {
        uint256 length = _rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = _rewardTokens[index];
            uint256 reward = userRewards[rewardToken][_account]; // updated during updateReward modifier
            if (reward > 0) {
                _sendReward(rewardToken, _account, _receiver, reward);
            }
        }
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only possible to donate already registered token
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function donateRewards(uint256 _amountReward, address _rewardToken) external {
        if (!isRewardToken[_rewardToken])
            revert MustBeRewardToken();

        _provisionReward(_amountReward, _rewardToken);
    }

    /* ============ Admin Functions ============ */

    function updateManager(address _rewardManager, bool _allowed) external onlyOwner {
        managers[_rewardManager] = _allowed;

        emit ManagerUpdated(_rewardManager, managers[_rewardManager]);
    }

    /// @notice Sends new rewards to be distributed to the users staking. Only callable by manager
    /// @param _amountReward Amount of reward token to be distributed
    /// @param _rewardToken Address reward token
    function queueNewRewards(uint256 _amountReward, address _rewardToken)
        override
        external
        onlyManager
        returns (bool)
    {
        if (!isRewardToken[_rewardToken]) {
            rewardTokens.push(_rewardToken);
            isRewardToken[_rewardToken] = true;
        }

        _provisionReward(_amountReward, _rewardToken);
        return true;
    }

    function emergencyWithdraw(address _rewardToken, address _to) external onlyManager {
        uint256 amount = IERC20(_rewardToken).balanceOf(address(this));
        IERC20(_rewardToken).safeTransfer(_to, amount);
        emit EmergencyWithdrawn(_to, _rewardToken, amount);
    }

    /* ============ Internal Functions ============ */

    function _provisionReward(uint256 _amountReward, address _rewardToken) internal {
        IERC20(_rewardToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountReward
        );
        Reward storage rewardInfo = rewards[_rewardToken];
        rewardInfo.historicalRewards =
            rewardInfo.historicalRewards +
            _amountReward;

        uint256 totalStake = totalStaked();
        if (totalStake == 0) {
            rewardInfo.queuedRewards += _amountReward;
        } else {
            if (rewardInfo.queuedRewards > 0) {
                _amountReward += rewardInfo.queuedRewards;
                rewardInfo.queuedRewards = 0;
            }
            rewardInfo.rewardPerTokenStored =
                rewardInfo.rewardPerTokenStored +
                (_amountReward * 10**stakingTokenDecimals * DENOMINATOR) /
                totalStake;
        }
        emit RewardAdded(_amountReward, _rewardToken);
    }

    function _earned(address _account, address _rewardToken, uint256 _userShare) internal view returns (uint256) {
        return ((_userShare *
            (rewardPerToken(_rewardToken) -
                userRewardPerTokenPaid[_rewardToken][_account])) /
            (10**stakingTokenDecimals * DENOMINATOR)) + userRewards[_rewardToken][_account];
    }

    function _sendReward(address _rewardToken, address _account, address _receiver, uint256 _amount) internal {
        userRewards[_rewardToken][_account] = 0;
        IERC20(_rewardToken).safeTransfer(_receiver, _amount);
        emit RewardPaid(_account, _receiver, _amount, _rewardToken);
    }

    function _updateFor(address _account) internal {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            // if a reward stopped queuing, no need to recalculate to save gas fee
            if (userRewardPerTokenPaid[rewardToken][_account] == rewardPerToken(rewardToken))
                continue;

            userRewards[rewardToken][_account] = earned(_account, rewardToken);
            userRewardPerTokenPaid[rewardToken][_account] = rewardPerToken(rewardToken);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./BaseRewardPool.sol";
import "./BaseRewardPoolV3.sol";

/// @title A contract for managing rewards for a pool
/// @author Magpie Team
/// @notice You can use this contract for getting informations about rewards for a specific pools
contract BribeRewardPool is BaseRewardPoolV3 {
    using SafeERC20 for IERC20;

    /* ============ State Variables ============ */

    uint256 public totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== Errors ========== */

    error OnlyOperator();    

    /* ============ Constructor ============ */

    constructor(
        address _stakingToken,
        address _rewardToken,
        address _operator,
        address _rewardManager
    ) BaseRewardPoolV3(_stakingToken, _rewardToken, _operator, _rewardManager) {}

    /* ============ Modifiers ============ */

    modifier onlyOperator() {
        if (msg.sender != operator)
            revert OnlyOperator();
        _;
    }

    /* ============ External Getters ============ */

    function balanceOf(address _account) public override virtual view returns (uint256) {
        return _balances[_account];
    }

    function totalStaked() public override virtual view returns (uint256) {
        return totalSupply;
    }

    /* ============ External Functions ============ */

    /// @notice Updates information for a user in case of staking. Can only be called by the Masterchief operator
    /// @param _for Address account
    /// @param _amount Amount of newly staked tokens by the user on masterchief
    function stakeFor(address _for, uint256 _amount)
        external
        virtual
        onlyOperator
        updateRewards(_for, rewardTokens)
    {
        totalSupply = totalSupply + _amount;
        _balances[_for] = _balances[_for] + _amount;

        emit Staked(_for, _amount);
    }

    /// @notice Updates informaiton for a user in case of a withdraw. Can only be called by the Masterchief operator
    /// @param _for Address account
    /// @param _amount Amount of withdrawed tokens by the user on masterchief
    function withdrawFor(
        address _for,
        uint256 _amount,
        bool claim
    ) external virtual onlyOperator updateRewards(_for, rewardTokens) {
        totalSupply = totalSupply - _amount;
        _balances[_for] = _balances[_for] - _amount;

        emit Withdrawn(_for, _amount);

        if (claim) {
            _getReward(_for);
        }
    }

    /* ============ Internal Functions ============ */

    function _getReward(address _account) internal virtual {
        uint256 length = rewardTokens.length;
        for (uint256 index = 0; index < length; ++index) {
            address rewardToken = rewardTokens[index];
            uint256 reward = earned(_account, rewardToken);
            if (reward > 0) {
                userRewards[rewardToken][_account] = 0;
                IERC20(rewardToken).safeTransfer(_account, reward);
                emit RewardPaid(_account, _account, reward, rewardToken);
            }
        }
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IHarvesttablePoolHelper.sol";
import "../interfaces/wombat/IWombatStaking.sol";
import "../interfaces/wombat/IMasterWombat.sol";
import "../interfaces/IMasterMagpie.sol";
import "../interfaces/IMintableERC20.sol";
import "../interfaces/IWNative.sol";
import "../interfaces/ISimpleHelper.sol";
/// @title WombatPoolHelper
/// @author Magpie Team
/// @notice This contract is the main contract that user will intreact with in order to stake stable in Wombat Pool

/// @dev Upgrades in PoolHelperV3 are: 
/// 1. Added the withdrawLP functionality
/// 2. Added the functionality to claim rewards with withdraw of deposit token or LP token

contract WombatPoolHelperV3 is IHarvesttablePoolHelper, ISimpleHelper {
    using SafeERC20 for IERC20;

    /* ============ Constants ============ */

    address public immutable depositToken; // token to deposit into wombat
    address public immutable lpToken; // lp token receive from wombat, also the pool identified on womabtStaking
    address public immutable stakingToken; // token staking to master magpie
    address public immutable mWom;

    address public immutable masterMagpie;
    address public immutable wombatStaking;
    address public immutable rewarder;

    uint256 public immutable pid; // pid on master wombat

    bool public immutable isNative;

    /* ============ Events ============ */

    event NewDeposit(address indexed _user, uint256 _amount);
    event NewLpDeposit(address indexed _user, uint256 _amount);
    event NewWithdraw(address indexed _user, uint256 _amount);
    event NewLpWithdraw(address indexed _user, uint256 _amount);

    /* ============ Errors ============ */

    error NotNativeToken();

    /* ============ Constructor ============ */

    constructor(
        uint256 _pid,
        address _stakingToken,
        address _depositToken,
        address _lpToken,
        address _wombatStaking,
        address _masterMagpie,
        address _rewarder,
        address _mWom,
        bool _isNative
    ) {
        pid = _pid;
        stakingToken = _stakingToken;
        depositToken = _depositToken;
        lpToken = _lpToken;
        wombatStaking = _wombatStaking;
        masterMagpie = _masterMagpie;
        rewarder = _rewarder;
        mWom = _mWom;
        isNative = _isNative;
    }

    /* ============ External Getters ============ */

    /// notice get the amount of total staked LP token in master magpie
    function totalStaked() external view override returns (uint256) {
        return IBaseRewardPool(rewarder).totalStaked();
    }

    /// @notice get the total amount of shares of a user
    /// @param _address the user
    /// @return the amount of shares
    function balance(
        address _address
    ) external view override returns (uint256) {
        return IBaseRewardPool(rewarder).balanceOf(_address);
    }

    /// @notice returns the number of pending MGP of the contract for the given pool
    /// returns pendingTokens the number of pending MGP
    function pendingWom() external view returns (uint256 pendingTokens) {
        (pendingTokens, , , ) = IMasterWombat(
            IWombatStaking(wombatStaking).masterWombat()
        ).pendingTokens(pid, wombatStaking);
    }

    /* ============ External Functions ============ */

    /// @notice deposit stables in wombat pool, autostake in master magpie
    /// @param _amount the amount of stables to deposit
    function deposit(
        uint256 _amount,
        uint256 _minimumLiquidity
    ) external override {
        _deposit(_amount, _minimumLiquidity, msg.sender, msg.sender);
    }

    function depositFor(uint256 _amount, address _for) external {
        IERC20(depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );
        IERC20(depositToken).safeApprove(wombatStaking, _amount);
        _deposit(_amount, 0, _for, address(this));
    }

    function depositLP(uint256 _lpAmount) external {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IWombatStaking(wombatStaking).depositLP(lpToken, _lpAmount, msg.sender);
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, msg.sender);

        emit NewLpDeposit(msg.sender, _lpAmount);
    }

    function depositNative(uint256 _minimumLiquidity) external payable {
        if (!isNative) revert NotNativeToken();
        // Dose need to limit the amount must > 0?

        // Swap the BNB to wBNB
        _wrapNative();
        // depsoit wBNB to the pool
        IWNative(depositToken).approve(wombatStaking, msg.value);
        _deposit(msg.value, _minimumLiquidity, msg.sender, address(this));
        IWNative(depositToken).approve(wombatStaking, 0);
    }

    /// @notice withdraw stables from wombat pool, auto unstake from master Magpie
    /// @param _liquidity the amount of liquidity to withdraw
    function withdraw(
        uint256 _liquidity,
        uint256 _minAmount
    ) external override {
        _withdraw(_liquidity, _minAmount, false);
    }

    function withdrawAndClaim(
        uint256 _liquidity,
        uint256 _minAmount,
        bool _isClaim
    ) external {
        _withdraw(_liquidity, _minAmount, _isClaim);
    }

    function withdrawLP(uint256 _amount, bool claim) external {
        // withdraw from wombat exchange and harvest rewards to base rewarder
        IWombatStaking(wombatStaking).withdrawLP(lpToken, _amount, msg.sender);
        // unstke from Master Wombat and trigger reward distribution from basereward
        _unstake(_amount, msg.sender);
        // claim all rewards
        if (claim) _claimRewards(msg.sender);
        // burn the staking token withdrawn from Master Magpie
        IWombatStaking(wombatStaking).burnReceiptToken(lpToken, _amount);
        emit NewLpWithdraw(msg.sender, _amount);
    }

    function harvest() external override {
        IWombatStaking(wombatStaking).harvest(lpToken);
    }

    /* ============ Internal Functions ============ */

    function _withdraw(
        uint256 _liquidity,
        uint256 _minAmount,
        bool _claim
    ) internal {
        // we have to withdraw from wombat exchange to harvest reward to base rewarder
        IWombatStaking(wombatStaking).withdraw(
            lpToken,
            _liquidity,
            _minAmount,
            msg.sender
        );
        // then we unstake from master wombat to trigger reward distribution from basereward
        _unstake(_liquidity, msg.sender);

        if (_claim) _claimRewards(msg.sender);

        //  last burn the staking token withdrawn from Master Magpie
        IWombatStaking(wombatStaking).burnReceiptToken(lpToken, _liquidity);
        emit NewWithdraw(msg.sender, _liquidity);
    }

    function _claimRewards(address _for) internal {
        address[] memory stakingTokens = new address[](1);
        stakingTokens[0] = stakingToken;
        address[][] memory rewardTokens = new address[][](1);
        IMasterMagpie(masterMagpie).multiclaimFor(
            stakingTokens,
            rewardTokens,
            _for
        );
    }

    function _deposit(
        uint256 _amount,
        uint256 _minimumLiquidity,
        address _for,
        address _from
    ) internal {
        uint256 beforeDeposit = IERC20(stakingToken).balanceOf(address(this));
        IWombatStaking(wombatStaking).deposit(
            lpToken,
            _amount,
            _minimumLiquidity,
            _for,
            _from
        );
        uint256 afterDeposit = IERC20(stakingToken).balanceOf(address(this));
        _stake(afterDeposit - beforeDeposit, _for);

        emit NewDeposit(_for, _amount);
    }

    function _wrapNative() internal {
        IWNative(depositToken).deposit{value: msg.value}();
    }

    /// @notice stake the receipt token in the masterchief of GMP on behalf of the caller
    function _stake(uint256 _amount, address _sender) internal {
        IERC20(stakingToken).safeApprove(masterMagpie, _amount);
        IMasterMagpie(masterMagpie).depositFor(stakingToken, _amount, _sender);
    }

    /// @notice unstake from the masterchief of GMP on behalf of the caller
    function _unstake(uint256 _amount, address _sender) internal {
        IMasterMagpie(masterMagpie).withdrawFor(stakingToken, _amount, _sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20, ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { IWombatPool } from "../interfaces/wombat/IWombatPool.sol";
import { IMasterWombat } from "../interfaces/wombat/IMasterWombat.sol";
import { IVeWom } from "../interfaces/wombat/IVeWom.sol";
import { IMWom } from "../interfaces/wombat/IMWom.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IMintableERC20.sol";
import "../interfaces/IPoolHelper.sol";
import "../interfaces/IBaseRewardPool.sol";
import "../interfaces/IMasterMagpie.sol";
import "../interfaces/IConverter.sol";
import "../libraries/MagpieFactoryLib.sol";
import "../libraries/DSMath.sol";
import "../libraries/SignedSafeMath.sol";

import "../interfaces/wombat/IWombatVoter.sol";
import "../interfaces/wombat/IWombatBribe.sol";
import "../interfaces/pancake/IBNBZapper.sol";
import "../interfaces/IDelegateRegistry.sol";

contract WombatStaking is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeERC20 for IERC20;
    using DSMath for uint256;
    using SignedSafeMath for int256;

    /* ============ Structs ============ */

    struct Pool {
        uint256 pid; // pid on master wombat
        address depositToken; // token to be deposited on wombat
        address lpAddress; // token received after deposit on wombat
        address receiptToken; // token to receive after
        address rewarder;
        address helper;
        address depositTarget;
        bool isActive;
    }

    struct Fees {
        uint256 value; // allocation denominated by DENOMINATOR
        address to;
        bool isMWOM;
        bool isAddress;
        bool isActive;
    }

    /* ============ State Variables ============ */

    // Addresses
    address public wom;
    address public veWom;
    address public mWom;

    address public masterWombat;
    address public masterMagpie;

    // Fees
    uint256 constant DENOMINATOR = 10000;
    uint256 public totalFee;

    uint256 public lockDays;

    mapping(address => Pool) public pools;
    mapping(address => address[]) public assetToBonusRewards; // extra rewards for alt pool

    address[] private poolTokenList;

    Fees[] public feeInfos;

    /* ==== variable added for first upgrade === */

    mapping(address => bool) public isPoolFeeFree;
    // for bribe
    address public smartWomConverter;
    IWombatVoter public voter;
    address public bribeManager;
    uint256 public bribeCallerFee;
    uint256 public bribeProtocolFee;
    address public bribeFeeCollector;

    address public constant wbnb = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    /* ==== variable added for second upgrade === */

    address public delegateRegistry;
    address public BNBZapper;
    uint256 public harvestCallerFee;

    /* ============ Events ============ */

    // Admin
    event PoolAdded(
        uint256 _pid,
        address _depositToken,
        address _lpAddress,
        address _helper,
        address _rewarder,
        address _receiptToken
    );
    event PoolRemoved(uint256 _pid, address _lpToken);
    event PoolHelperUpdated(address _lpToken);
    event MasterMagpieUpdated(address _oldMasterMagpie, address _newMasterMagpie);
    event MasterWombatUpdated(address _oldWombatStaking, address _newWombatStaking);
    event BribeManagerUpdated(address _oldBribeManager, address _bribeManager);
    event SmartWomConverterUpdated(
        address _oldSmartWomConverterUpdated,
        address _newSmartWomConverterUpdated
    );
    event SetMWom(address _oldmWom, address _newmWom);
    event SetLockDays(uint256 _oldLockDays, uint256 _newLockDays);

    // Fee
    event AddFee(address _to, uint256 _value, bool _isMWOM, bool _isAddress);
    event SetFee(address _to, uint256 _value);
    event RemoveFee(uint256 value, address to, bool _isMWOM, bool _isAddress);
    event RewardPaidTo(address _to, address _rewardToken, uint256 _feeAmount);
    event HarvestCallerFeeSent(address _to, uint256 _womAmountToBNB);
    event SetHarvestCallerFee(uint256 _feeAmount);

    // Deposit Withdraw
    event NewDeposit(
        address indexed _user,
        address indexed _depositToken,
        uint256 _depositAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event NewLPDeposit(
        address indexed _user,
        address indexed _lpToken,
        uint256 _lpAmount,
        address indexed _receptToken,
        uint256 _receptAmount
    );

    event NewWithdraw(
        address indexed _user,
        address indexed _depositToken,
        uint256 _liquitity
    );

    event NewLpWithdraw(
        address indexed _user,
        address indexed _lpToken,
        uint256 _lpAmount
    );

    // mWom
    event WomLocked(uint256 _amount, uint256 _lockDays, uint256 _veWomAccumulated);

    // Bribe
    event BribeSet(
        address _voter,
        address _bribeManager,
        uint256 _bribeCallerFee,
        uint256 _bribeProtocolFee,
        address _bribeFeeCollector
    );

    event DelegateRegistrySet(address _oldDelegateRegistry, address _newDelegateRegistry);

    event SnapshotDelegateSet(
        address indexed _delegator,
        bytes32 indexed _id,
        address indexed _delegate
    );

    /* ============ Errors ============ */

    error OnlyPoolHelper();
    error OnlyActivePool();
    error PoolOccupied();
    error InvalidFee();
    error OnlyBribeMamager();
    error LengthMismatch();
    error InvalidInput();
    error DelegateRegistryNotSet();
    error TotalFeeOverflow();

    /* ============ Constructor ============ */

    function __WombatStaking_init(
        address _wom,
        address _veWom,
        address _masterWombat,
        address _masterMagpie
    ) public initializer {
        __Ownable_init();
        wom = _wom;
        veWom = _veWom;
        masterWombat = _masterWombat;
        masterMagpie = _masterMagpie;
        lockDays = 1461;
    }

    /* ============ Modifiers ============ */

    modifier _onlyPoolHelper(address _lpToken) {
        Pool storage poolInfo = pools[_lpToken];
        if (msg.sender != poolInfo.helper) revert OnlyPoolHelper();
        _;
    }

    modifier _onlyActivePool(address _lpToken) {
        Pool storage poolInfo = pools[_lpToken];
        if (!poolInfo.isActive) revert OnlyActivePool();
        _;
    }

    modifier _onlyActivePoolHelper(address _lpToken) {
        Pool storage poolInfo = pools[_lpToken];
        if (msg.sender != poolInfo.helper) revert OnlyPoolHelper();
        if (!poolInfo.isActive) revert OnlyActivePool();
        _;
    }

    /// @notice payable function needed to receive BNB
    receive() external payable {}

    /* ============ External Getters ============ */

    /// @notice get the number of veWom of this contract
    function accumelatedVeWom() external view returns (uint256) {
        return IERC20(veWom).balanceOf(address(this));
    }

    function pendingBribeCallerFee(
        address[] calldata pendingPools
    )
        external
        view
        returns (IERC20[][] memory rewardTokens, uint256[][] memory callerFeeAmount)
    {
        // Warning: Arguments do not take into account repeated elements in the pendingPools list
        uint256[][] memory pending = voter.pendingBribes(pendingPools, address(this));

        rewardTokens = new IERC20[][](pending.length);
        callerFeeAmount = new uint256[][](pending.length);

        for (uint256 i; i < pending.length; i++) {
            rewardTokens[i] = IWombatBribe(voter.infos(pendingPools[i]).bribe)
                .rewardTokens();
            callerFeeAmount[i] = new uint256[](pending[i].length);

            for (uint256 j; j < pending[i].length; j++) {
                if (pending[i][j] > 0) {
                    callerFeeAmount[i][j] =
                        (pending[i][j] * bribeCallerFee) /
                        DENOMINATOR;
                }
            }
        }
    }

    /* ============ External Functions ============ */

    /// @notice deposit wombat pool token in a wombat Pool
    /// @dev this function can only be called by a PoolHelper
    /// @param _lpAddress the lp token to deposit into wombat pool
    /// @param _amount the amount to deposit
    /// @param _for the user to deposit for
    /// @param _from the address to transfer from
    function deposit(
        address _lpAddress,
        uint256 _amount,
        uint256 _minimumLiquidity,
        address _for,
        address _from
    ) external nonReentrant whenNotPaused _onlyActivePoolHelper(_lpAddress) {
        // Get information of the Pool of the token
        Pool storage poolInfo = pools[_lpAddress];

        address depositToken = poolInfo.depositToken;
        (uint256[] memory rewardTokenPreBal, IERC20[] memory rewardTokens) = _rewardBeforeBalances(
            poolInfo.lpAddress
        );

        IERC20(depositToken).safeTransferFrom(_from, address(this), _amount);
        IERC20(depositToken).safeApprove(poolInfo.depositTarget, _amount);
        uint256 liqudiity = IWombatPool(poolInfo.depositTarget).deposit(
            depositToken,
            _amount,
            _minimumLiquidity,
            address(this),
            block.timestamp,
            true
        );

        _calculateAndSendReward(_lpAddress, rewardTokenPreBal, rewardTokens, false); 
        // update variables
        IMintableERC20(poolInfo.receiptToken).mint(msg.sender, liqudiity);
        emit NewDeposit(_for, depositToken, _amount, poolInfo.receiptToken, liqudiity);
    }

    function depositLP(
        address _lpAddress,
        uint256 _lpAmount,
        address _for
    ) external nonReentrant whenNotPaused _onlyActivePoolHelper(_lpAddress) {
        // Get information of the Pool of the token
        Pool storage poolInfo = pools[_lpAddress];
        // Transfer lp to this contract and stake it to wombat
        (uint256[] memory rewardTokenPreBal, IERC20[] memory rewardTokens) = _rewardBeforeBalances(
            poolInfo.lpAddress
        );
        IERC20(poolInfo.lpAddress).safeTransferFrom(_for, address(this), _lpAmount);

        IERC20(poolInfo.lpAddress).safeApprove(masterWombat, _lpAmount);
        IMasterWombat(masterWombat).deposit(poolInfo.pid, _lpAmount);

        _calculateAndSendReward(_lpAddress, rewardTokenPreBal, rewardTokens, false); // triggers harvest from wombat exchange
        IMintableERC20(poolInfo.receiptToken).mint(msg.sender, _lpAmount);

        emit NewLPDeposit(
            _for,
            poolInfo.lpAddress,
            _lpAmount,
            poolInfo.receiptToken,
            _lpAmount
        );
    }

    /// @notice withdraw from a wombat Pool. Note!!! pool helper has to burn receipt token!
    /// @dev Only a PoolHelper can call this function
    /// @param _lpToken the address of the wombat pool lp token
    /// @param _liquidity wombat pool liquidity
    /// @param _minAmount The minimal amount the user accepts because of slippage
    /// @param _sender the address of the user
    function withdraw(
        address _lpToken,
        uint256 _liquidity,
        uint256 _minAmount,
        address _sender
    ) external nonReentrant whenNotPaused _onlyPoolHelper(_lpToken) {
        Pool storage poolInfo = pools[_lpToken];

        IERC20(poolInfo.lpAddress).safeApprove(poolInfo.depositTarget, _liquidity);

        (uint256[] memory rewardTokenPreBal, IERC20[] memory rewardTokens) = _rewardBeforeBalances(
            poolInfo.lpAddress
        );
        IMasterWombat(masterWombat).withdraw(poolInfo.pid, _liquidity);
        _calculateAndSendReward(_lpToken, rewardTokenPreBal, rewardTokens, false);

        uint256 beforeWithdraw = IERC20(poolInfo.depositToken).balanceOf(address(this));
        IWombatPool(poolInfo.depositTarget).withdraw(
            poolInfo.depositToken,
            _liquidity,
            _minAmount,
            address(this),
            block.timestamp
        );

        IERC20(poolInfo.depositToken).safeTransfer(
            _sender,
            IERC20(poolInfo.depositToken).balanceOf(address(this)) - beforeWithdraw
        );

        emit NewWithdraw(_sender, poolInfo.depositToken, _liquidity);
    }

    function withdrawLP(
        address _lpToken,
        uint256 _lpAmount,
        address _sender
    ) external nonReentrant whenNotPaused _onlyPoolHelper(_lpToken) {
        Pool storage poolInfo = pools[_lpToken];

        uint256 beforeLpWithdraw = IERC20(poolInfo.lpAddress).balanceOf(address(this));

        (uint256[] memory rewardTokenPreBal, IERC20[] memory rewardTokens) = _rewardBeforeBalances(
            poolInfo.lpAddress
        );

        IMasterWombat(masterWombat).withdraw(poolInfo.pid, _lpAmount);
        _calculateAndSendReward(_lpToken, rewardTokenPreBal, rewardTokens, false);
        IERC20(poolInfo.lpAddress).safeTransfer(
            _sender,
            IERC20(poolInfo.lpAddress).balanceOf(address(this)) - beforeLpWithdraw
        );

        emit NewLpWithdraw(_sender, poolInfo.lpAddress, _lpAmount);
    }

    function burnReceiptToken(
        address _lpToken,
        uint256 _amount
    ) external whenNotPaused _onlyPoolHelper(_lpToken) {
        IMintableERC20(pools[_lpToken].receiptToken).burn(msg.sender, _amount);
    }

    /// @notice harvest a Pool from Wombat
    /// @param _lpToken wombat pool lp as helper identifier
    function harvest(address _lpToken) external whenNotPaused _onlyActivePool(_lpToken) {
        Pool storage poolInfo = pools[_lpToken];
        (uint256[] memory rewardTokenPreBal, IERC20[] memory rewardTokens) = _rewardBeforeBalances(
            poolInfo.lpAddress
        );
        // Approve Transfer to Master Wombat for Staking
        IERC20(_lpToken).safeApprove(masterWombat, 0);
        IMasterWombat(masterWombat).deposit(poolInfo.pid, 0);
        _calculateAndSendReward(_lpToken, rewardTokenPreBal, rewardTokens, true);
    }

    function batchHarvest(
        address[] calldata _lpTokens,
        uint256 minReceive
    ) external whenNotPaused nonReentrant {
        _tobatchMasterWomAndSendReward(_lpTokens, minReceive); // triggers harvest from wombat exchange
    }
    /// @notice convert WOM to mWOM
    /// @param _amount the number of WOM to convert
    /// @dev the WOM must already be in the contract
    function convertWOM(uint256 _amount) external whenNotPaused returns (uint256) {
        uint256 veWomMintedAmount = 0;
        if (_amount > 0) {
            IERC20(wom).safeApprove(veWom, _amount);
            veWomMintedAmount = IVeWom(veWom).mint(_amount, lockDays);
        }
        emit WomLocked(_amount, lockDays, veWomMintedAmount);
        return veWomMintedAmount;
    }

    /// @notice stake all the WOM balance of the contract
    function convertAllWom() external whenNotPaused {
        this.convertWOM(IERC20(wom).balanceOf(address(this)));
    }

    /* ============ Admin Functions ============ */

    /// @notice Vote on WOM gauges
    /// @dev voting harvest the pools, even if the pool has no changing vote,
    /// so we have to ensure that each reward token goes to the good rewarder
    /// @dev this function can cost a lot of gas, so maybe we will not launch it at every interaction
    function vote(
        address[] calldata _lpVote,
        int256[] calldata _deltas,
        address[] calldata _rewarders,
        address caller
    )
        external
        returns (IERC20[][] memory rewardTokens, uint256[][] memory callerFeeAmounts)
    {
        if (msg.sender != bribeManager) revert OnlyBribeMamager();

        if (_lpVote.length != _rewarders.length || _lpVote.length != _deltas.length)
            revert LengthMismatch();
        uint256[][] memory rewardAmounts = voter.vote(_lpVote, _deltas);
        rewardTokens = new IERC20[][](rewardAmounts.length);
        callerFeeAmounts = new uint256[][](rewardAmounts.length);

        for (uint256 i; i < rewardAmounts.length; i++) {
            address bribesContract = address(voter.infos(_lpVote[i]).bribe);

            if (bribesContract != address(0)) {
                rewardTokens[i] = IWombatBribe(bribesContract).rewardTokens();
                callerFeeAmounts[i] = new uint256[](rewardAmounts[i].length);

                for (uint256 j; j < rewardAmounts[i].length; j++) {
                    uint256 rewardAmount = rewardAmounts[i][j];
                    uint256 callerFeeAmount = 0;

                    if (rewardAmount > 0) {
                        // if reward token is bnb, wrap it first
                        if (address(rewardTokens[i][j]) == address(0)) {
                            Address.sendValue(payable(wbnb), rewardAmount);
                            rewardTokens[i][j] = IERC20(wbnb);
                        }

                        uint256 protocolFee = (rewardAmount * bribeProtocolFee) /
                            DENOMINATOR;

                        if (protocolFee > 0) {
                            IERC20(rewardTokens[i][j]).safeTransfer(
                                bribeFeeCollector,
                                protocolFee
                            );
                        }

                        if (caller != address(0) && bribeCallerFee != 0) {
                            callerFeeAmount =
                                (rewardAmount * bribeCallerFee) /
                                DENOMINATOR;
                            IERC20(rewardTokens[i][j]).safeTransfer(
                                bribeManager,
                                callerFeeAmount
                            );
                        }

                        rewardAmount -= protocolFee;
                        rewardAmount -= callerFeeAmount;
                        IERC20(rewardTokens[i][j]).safeApprove(
                            _rewarders[i],
                            rewardAmount
                        );
                        IBaseRewardPool(_rewarders[i]).queueNewRewards(
                            rewardAmount,
                            address(rewardTokens[i][j])
                        );
                    }

                    callerFeeAmounts[i][j] = callerFeeAmount;
                }
            }
        }
    }

    /// @notice Register a new Pool on Wombat Staking and Master Magpie
    /// @dev this function will deploy a new WombatPoolHelper, and add the Pool to the masterMagpie
    /// @param _pid the pid of the Pool on master wombat
    /// @param _depositToken the token to stake in the wombat Pool
    /// @param _lpAddress the address of the recepit token after deposit into wombat Pool. Also used for the pool identifier on WombatStaking
    /// @param _depositTarget the address to deposit for alt Pool
    /// @param _receiptName the name of the receipt Token
    /// @param _receiptSymbol the symbol of the receipt Token
    /// @param _allocPoints the weight of the MGP allocation
   function registerPool(
        uint256 _pid,
        address _depositToken,
        address _lpAddress,
        address _depositTarget,
        string memory _receiptName,
        string memory _receiptSymbol,
        uint256 _allocPoints,
        bool _isNative
    ) external onlyOwner {
        if (pools[_lpAddress].isActive != false) {
            revert PoolOccupied();
        }

        address newToken = MagpieFactoryLib.createERC20(
            _receiptName,
            _receiptSymbol
        );

        address rewarder = IMasterMagpie(masterMagpie).createRewarder(
            newToken,
            wom
        );

        address helper = MagpieFactoryLib.createWombatPoolHelper(
            _pid,
            newToken,
            _depositToken,
            _lpAddress,
            address(this),
            masterMagpie,
            rewarder,
            mWom,
            _isNative
        );

        IMasterMagpie(masterMagpie).add(
            _allocPoints,
            newToken,
            rewarder,
            address(helper),
            true
        );

        pools[_lpAddress] = Pool({
            pid: _pid,
            isActive: true,
            depositToken: _depositToken,
            lpAddress: _lpAddress,
            receiptToken: newToken,
            rewarder: rewarder,
            helper: helper,
            depositTarget: _depositTarget
        });
        poolTokenList.push(_depositToken);

        emit PoolAdded(
            _pid,
            _depositToken,
            _lpAddress,
            helper,
            rewarder,
            newToken
        );
    }

    /// @notice set the mWom address
    /// @param _mWom the mWom address
    function setMWom(address _mWom) external onlyOwner {
        address oldmWom = mWom;
        mWom = _mWom;
        emit SetMWom(oldmWom, mWom);
    }

    function setLockDays(uint256 _newLockDays) external onlyOwner {
        uint256 oldLockDays = lockDays;
        lockDays = _newLockDays;
        emit SetLockDays(oldLockDays, lockDays);
    }

    /// @notice mark the pool as inactive
    function removePool(address _lpToken) external onlyOwner {
        pools[_lpToken].isActive = false;
        emit PoolRemoved(pools[_lpToken].pid, _lpToken);
    }

    /// @notice update the pool information on wombat deposit and master magpie.
    function updatePoolHelper(
        address _lpAddress,
        uint256 _pid,
        address _poolHelper,
        address _rewarder,
        address _depositToken,
        address _depositTarget,
        uint256 _allocPoint
    ) external onlyOwner _onlyActivePool(_lpAddress) {
        Pool storage poolInfo = pools[_lpAddress];
        poolInfo.pid = _pid;
        poolInfo.helper = _poolHelper;
        poolInfo.rewarder = _rewarder;
        poolInfo.depositToken = _depositToken;
        poolInfo.depositTarget = _depositTarget;

        IMasterMagpie(masterMagpie).set(
            poolInfo.receiptToken,
            _allocPoint,
            _poolHelper,
            _rewarder,
            true
        );

        emit PoolHelperUpdated(_lpAddress);
    }

    function upgradeHelper(address _lpAddress) external onlyOwner {

        Pool storage poolInfo = pools[_lpAddress];
        IPoolHelper oldPoolHelper = IPoolHelper(poolInfo.helper);
        address newHelper = MagpieFactoryLib.createWombatPoolHelper(
            oldPoolHelper.pid(),
            oldPoolHelper.stakingToken(),
            oldPoolHelper.depositToken(),
            oldPoolHelper.lpToken(),
            address(this),
            masterMagpie,
            oldPoolHelper.rewarder(),
            mWom,
            oldPoolHelper.isNative()
        );
        poolInfo.helper = newHelper;

        (,uint256 allocPoint,,) = IMasterMagpie(masterMagpie).getPoolInfo(oldPoolHelper.stakingToken());
        IMasterMagpie(masterMagpie).set(
            oldPoolHelper.stakingToken(),
            allocPoint,
            newHelper,
            oldPoolHelper.rewarder(),
            true
        );
    }

    // function setMasterMagpie(address _masterMagpie) external onlyOwner {
    //     address oldMasterMagpie = masterMagpie;
    //     masterMagpie = _masterMagpie;

    //     emit MasterMagpieUpdated(oldMasterMagpie, masterMagpie);
    // }

    // function setMasterWombat(address _masterWombat) external onlyOwner {
    //     address oldMasterWombat = masterWombat;
    //     masterWombat = _masterWombat;

    //     emit MasterWombatUpdated(oldMasterWombat, masterWombat);
    // }

    function setBribeManager(address _bribeManager) external onlyOwner {
        address oldBribeManager = bribeManager;
        bribeManager = _bribeManager;

        emit BribeManagerUpdated(oldBribeManager, bribeManager);
    }

    // function setSmartConvert(address _smartConvert) external onlyOwner {
    //     address oldsmartWomConverter = smartWomConverter;
    //     smartWomConverter = _smartConvert;

    //     emit SmartWomConverterUpdated(oldsmartWomConverter, smartWomConverter);
    // }

    function setHarvestCallerFee(uint256 _harvestCallerFee) external onlyOwner {
        harvestCallerFee = _harvestCallerFee;
        emit SetHarvestCallerFee(harvestCallerFee);
    }

    function setBNBZapper(address newZapper) external onlyOwner {
        BNBZapper = newZapper;
    }
    
    // function setDelegateRegistry(address _delegateRegistry) external onlyOwner {
    //     if (_delegateRegistry == address(0)) revert InvalidInput();

    //     address oldDelegateRegistry = delegateRegistry;
    //     delegateRegistry = _delegateRegistry;

    //     emit DelegateRegistrySet(oldDelegateRegistry, _delegateRegistry);
    // }

    // function setSnapshotDelegate(bytes32 _id, address _delegate) external onlyOwner {
    //     if (delegateRegistry == address(0)) revert DelegateRegistryNotSet();
    //     if (_delegate == address(0) || _id == bytes32(0)) revert InvalidInput();

    //     IDelegateRegistry(delegateRegistry).setDelegate(_id, _delegate);

    //     emit SnapshotDelegateSet(address(this), _id, _delegate);
    // }

    // /**
    //  * @notice pause wombat staking, restricting certain operations
    //  */
    // function pause() external nonReentrant onlyOwner {
    //     _pause();
    // }

    // /**
    //  * @notice unpause wombat staking, enabling certain operations
    //  */
    // function unpause() external nonReentrant onlyOwner {
    //     _unpause();
    // }

    /// @notice This function adds a fee to the magpie protocol
    /// @param _value the initial value for that fee
    /// @param _to the address or contract that receives the fee
    /// @param isMWOM true if the fee is sent as MWOM, otherwise it will be WOM
    /// @param _isAddress true if the receiver is an address, otherwise it's a BaseRewarder
    function addFee(
        uint256 _value,
        address _to,
        bool isMWOM,
        bool _isAddress
    ) external onlyOwner {
        if (_value >= DENOMINATOR) revert InvalidFee();

        feeInfos.push(
            Fees({
                value: _value,
                to: _to,
                isMWOM: isMWOM,
                isAddress: _isAddress,
                isActive: true
            })
        );
        totalFee += _value;
        if(totalFee > DENOMINATOR) revert TotalFeeOverflow();
        emit AddFee(_to, _value, isMWOM, _isAddress);
    }

    /// @notice change the value of some fee
    /// @dev the value must be between the min and the max specified when registering the fee
    /// @dev the value must match the max fee requirements
    /// @param _index the index of the fee in the fee list
    /// @param _value the new value of the fee
    function setFee(
        uint256 _index,
        uint256 _value,
        address _to,
        bool _isMWOM,
        bool _isAddress,
        bool _isActive
    ) external onlyOwner {
        if (_value >= DENOMINATOR) revert InvalidFee();

        Fees storage fee = feeInfos[_index];
        fee.to = _to;
        fee.isMWOM = _isMWOM;
        fee.isAddress = _isAddress;
        fee.isActive = _isActive;

        totalFee = totalFee - fee.value + _value;
        if(totalFee > DENOMINATOR) revert TotalFeeOverflow();
        fee.value = _value;

        emit SetFee(fee.to, _value);
    }

    /// @notice remove some fee
    /// @param _index the index of the fee in the fee list
    function removeFee(uint256 _index) external onlyOwner {
        Fees memory feeToRemove = feeInfos[_index];

        for (uint i = _index; i < feeInfos.length - 1; i++) {
            feeInfos[i] = feeInfos[i + 1];
        }
        feeInfos.pop();
        totalFee -= feeToRemove.value;

        emit RemoveFee(
            feeToRemove.value,
            feeToRemove.to,
            feeToRemove.isMWOM,
            feeToRemove.isAddress
        );
    }

    function setPoolRewardFeeFree(address _lpToken, bool isFeeFree) external onlyOwner {
        isPoolFeeFree[_lpToken] = isFeeFree;
    }

    function setBribe(
        address _voter,
        address _bribeManager,
        uint256 _bribeCallerFee,
        uint256 _bribeProtocolFee,
        address _bribeFeeCollector
    ) external onlyOwner {
        if ((_bribeCallerFee + _bribeProtocolFee) > DENOMINATOR) revert InvalidFee();

        voter = IWombatVoter(_voter);
        bribeManager = _bribeManager;
        bribeCallerFee = _bribeCallerFee;
        bribeProtocolFee = _bribeProtocolFee;
        bribeFeeCollector = _bribeFeeCollector;

        emit BribeSet(
            _voter,
            _bribeManager,
            _bribeCallerFee,
            _bribeProtocolFee,
            _bribeFeeCollector
        );
    }

    /* ============ Internal Functions ============ */

    function _calculateAndSendReward(
        address _lpToken,
        uint256[] memory _rewardTokenPreBal,
        IERC20[] memory _rewardTokens,
        bool _isCaller
    ) internal {
        Pool storage poolInfo = pools[_lpToken];

        uint256 rewardTokensLength = _rewardTokens.length;
        for (uint256 i; i < rewardTokensLength; i++) {
            address rewardToken = address(_rewardTokens[i]);
            uint256 rewardAmount = IERC20(rewardToken).balanceOf(address(this)) -
                _rewardTokenPreBal[i];

            if (rewardAmount > 0) {
                _sendRewards(
                    _lpToken,
                    rewardToken,
                    poolInfo.rewarder,
                    rewardAmount,
                    rewardAmount
                );
            }
        }
    }

    function _tobatchMasterWomAndSendReward(address[] calldata _lpTokens, uint256 minReceive) internal {
        uint256 harvestCallerTotalWomFee;

        for (uint j = 0; j < _lpTokens.length; j++) {
            Pool storage poolInfo = pools[_lpTokens[j]];
            if (poolInfo.lpAddress != _lpTokens[j]) revert OnlyActivePool();

            (uint256[] memory beforeBalances, IERC20[] memory rewardTokens) = _rewardBeforeBalances(
            poolInfo.lpAddress
            );
            uint256 rewardTokenLength = rewardTokens.length;

            IMasterWombat(masterWombat).deposit(poolInfo.pid, 0); // triggers harvest from wombat exchange
            uint256 cuurentMarketHarvestCallerFee;

            for (uint256 i; i < rewardTokenLength; i++) {

                address rewardToken = address(rewardTokens[i]);
                uint256 rewardAmount = IERC20(rewardTokens[i]).balanceOf(
                    address(this)
                ) - beforeBalances[i];

                uint256 originalRewardAmount = rewardAmount;

                if(rewardAmount>0 && harvestCallerFee > 0 && rewardToken ==wom) {
                
                uint256 womRewards = rewardAmount;
                cuurentMarketHarvestCallerFee = (womRewards *
                    harvestCallerFee) / DENOMINATOR;
                rewardAmount = rewardAmount - cuurentMarketHarvestCallerFee;
                harvestCallerTotalWomFee += cuurentMarketHarvestCallerFee;
                }
                if (rewardAmount > 0) {
                    _sendRewards(
                        _lpTokens[i],
                        rewardToken,
                        poolInfo.rewarder,
                        originalRewardAmount,
                        rewardAmount
                    );
                }
            }
        }

        if(harvestCallerTotalWomFee > 0) {
            if(BNBZapper != address(0)){
                IERC20(wom).safeApprove(BNBZapper, harvestCallerTotalWomFee);
                uint256 minReceivedWithSlippage = minReceive * 99 /100; // 1% slippage
                IBNBZapper(BNBZapper).zapInToken(
                    wom,
                    harvestCallerTotalWomFee,
                    minReceivedWithSlippage,
                    tx.origin
                );
            }
            else{
                IERC20(wom).transfer(tx.origin, harvestCallerTotalWomFee);
            }

            emit HarvestCallerFeeSent(tx.origin, harvestCallerTotalWomFee);
        }
    }

    function _rewardBeforeBalances(
        address _lpToken
    ) internal view returns (uint256[] memory beforeBalances, IERC20[] memory rewardTokens) {
        Pool storage poolInfo = pools[_lpToken];
        (, IERC20[] memory bonusTokens, , ) = IMasterWombat(masterWombat).pendingTokens(poolInfo.pid, address(this));
        uint256 bonusTokensLength = bonusTokens.length;
        
        beforeBalances = new uint256[](bonusTokensLength+1);
        rewardTokens = new IERC20[](bonusTokensLength+1);

        for (uint256 i = 0; i < bonusTokensLength; i++) {
            beforeBalances[i] = bonusTokens[i].balanceOf(address(this));
            rewardTokens[i] = bonusTokens[i];
        }
        beforeBalances[bonusTokensLength] = IERC20(wom).balanceOf(address(this));
        rewardTokens[bonusTokensLength] = IERC20(wom);
    }

    /// @notice Send rewards to the rewarders
    /// @param _rewardToken the address of the reward token to send
    /// @param _rewarder the rewarder that will get the rewards
    /// @param _originalRewardAmount the initial amount of rewards after harvest
    /// @param _leftRewardAmount the intial amount - harvest caller rewardfee amount after harvest
    function _sendRewards(
        address _lpToken,
        address _rewardToken,
        address _rewarder,
        uint256 _originalRewardAmount,
        uint256 _leftRewardAmount
        // uint256 _amount
    ) internal {
        if (_leftRewardAmount == 0) return;
        uint256 originalRewardAmount = _originalRewardAmount;
        uint256 _amount = _leftRewardAmount;

        if (!isPoolFeeFree[_lpToken]) {
            for (uint256 i = 0; i < feeInfos.length; i++) {
                Fees storage feeInfo = feeInfos[i];

                if (feeInfo.isActive) {
                    address rewardToken = _rewardToken;
                    uint256 feeAmount = (originalRewardAmount * feeInfo.value) /
                        DENOMINATOR;
                    _amount -= feeAmount;
                    uint256 feeTosend = feeAmount;

                    if (feeInfo.isMWOM && rewardToken == wom) {
                        if (smartWomConverter != address(0)) {
                            IERC20(wom).safeApprove(smartWomConverter, feeAmount);
                            uint256 beforeBalnce = IMWom(mWom).balanceOf(address(this));
                            IConverter(smartWomConverter).smartConvert(feeAmount, 0);
                            rewardToken = mWom;
                            feeTosend =
                                IMWom(mWom).balanceOf(address(this)) -
                                beforeBalnce;
                        } else {
                            IERC20(wom).safeApprove(mWom, feeAmount);
                            uint256 beforeBalnce = IMWom(mWom).balanceOf(address(this));
                            IMWom(mWom).deposit(feeAmount);
                            rewardToken = mWom;
                            feeTosend =
                                IMWom(mWom).balanceOf(address(this)) -
                                beforeBalnce;
                        }
                    }

                    if (!feeInfo.isAddress) {
                        IERC20(rewardToken).safeApprove(feeInfo.to, 0);
                        IERC20(rewardToken).safeApprove(feeInfo.to, feeTosend);
                        IBaseRewardPool(feeInfo.to).queueNewRewards(
                            feeTosend,
                            rewardToken
                        );
                    } else {
                        IERC20(rewardToken).safeTransfer(feeInfo.to, feeTosend);
                        emit RewardPaidTo(feeInfo.to, rewardToken, feeTosend);
                    }
                }
            }
        }

        IERC20(_rewardToken).safeApprove(_rewarder, 0);
        IERC20(_rewardToken).safeApprove(_rewarder, _amount);
        IBaseRewardPool(_rewarder).queueNewRewards(_amount, _rewardToken);
    }
}