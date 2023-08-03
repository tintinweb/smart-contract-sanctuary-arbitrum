/**
 *Submitted for verification at Arbiscan on 2023-08-03
*/

/**
 *Submitted for verification at Arbiscan on 2023-07-27
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

//  MIT
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


// File @openzeppelin/contracts-upgradeable/access/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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


// File @openzeppelin/contracts-upgradeable/security/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/extensions/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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


// File @openzeppelin/contracts/interfaces/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//  MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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


// File @openzeppelin/contracts/utils/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

//  MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}


// File contracts/adapters/gmx/interfaces/IGmxAdapter.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxAdapter {
    /// @notice Swaps tokens along the route determined by the path
    /// @dev The input token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens that must be received
    /// @return boughtAmount Amount of the bought tokens
    function buy(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 boughtAmount);

    /// @notice Sells back part of  bought tokens along the route
    /// @dev The output token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens (vault't underlying) that must be received
    /// @return amount of the bought tokens
    function sell(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 amount);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed only by trader
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function close(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed by anyone with delay
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function forceClose(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Creates leverage long or short position order at GMX
    /// @dev Calls createIncreasePosition() in GMXPositionRouter
    function leveragePosition() external returns (uint256);

    /// @notice Create order for closing/decreasing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    function closePosition() external returns (uint256);

    /// @notice Create order for closing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    ///      Can be executed by any user
    /// @param positionId Position index for vault
    function forceClosePosition(uint256 positionId) external returns (uint256);

    /// @notice Returns data for open position
    // todo
    function getPosition(uint256) external view returns (uint256[] memory);

    struct AdapterOperation {
        uint8 operationId;
        bytes data;
    }

    /// @notice Checks if operations are allowed on adapter
    /// @param traderOperations Array of suggested trader operations
    /// @return Returns 'true' if operation is allowed on adapter
    function isOperationAllowed(
        AdapterOperation[] memory traderOperations
    ) external view returns (bool);

    /// @notice Executes array of trader operations
    /// @param traderOperations Array of trader operations
    /// @return Returns 'true' if all trades completed with success
    function executeOperation(
        AdapterOperation[] memory traderOperations
    ) external returns (bool);
}


// File contracts/adapters/gmx/interfaces/IGmxOrderBook.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxOrderBook {
    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function increaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (IncreaseOrder memory);

    function decreaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function decreaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (DecreaseOrder memory);

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function executeDecreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeIncreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;
}

interface IGmxOrderBookReader {
    function getIncreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getDecreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getSwapOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);
}


// File contracts/adapters/gmx/interfaces/IGmxReader.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxReader {
    function getMaxAmountIn(
        address _vault,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        address _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256);

    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);

    function getTokenBalances(
        address _account,
        address[] memory _tokens
    ) external view returns (uint256[] memory);
}


// File contracts/adapters/gmx/interfaces/IGmxRouter.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    function increasePositionRequests(
        bytes32 requestKey
    ) external view returns (IncreasePositionRequest memory);

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function decreasePositionRequests(
        bytes32 requestKey
    ) external view returns (DecreasePositionRequest memory);

    /// @notice Returns current account's increase position index
    function increasePositionsIndex(
        address account
    ) external view returns (uint256);

    /// @notice Returns current account's decrease position index
    function decreasePositionsIndex(
        address positionRequester
    ) external view returns (uint256);

    /// @notice Returns request key
    function getRequestKey(
        address account,
        uint256 index
    ) external view returns (bytes32);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function minExecutionFee() external view returns (uint256);
}

interface IGmxRouter {
    function approvedPlugins(
        address user,
        address plugin
    ) external view returns (bool);

    function approvePlugin(address plugin) external;

    function denyPlugin(address plugin) external;

    function swap(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut,
        address receiver
    ) external;

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;
}


// File contracts/adapters/gmx/interfaces/IGmxVault.sol

//  MIT

pragma solidity >=0.8.0;

interface IGmxVault {
    function whitelistedTokens(address token) external view returns (bool);

    function stableTokens(address token) external view returns (bool);

    function shortableTokens(address token) external view returns (bool);

    function getMaxPrice(address indexToken) external view returns (uint256);

    function getMinPrice(address indexToken) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function isLeverageEnabled() external view returns (bool);

    function guaranteedUsd(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);
}


// File contracts/interfaces/IAdapter.sol

//  MIT

pragma solidity >=0.8.0;

interface IAdapter {
    struct AdapterOperation {
        // id to identify what type of operation the adapter should do
        // this is a generic operation
        uint8 operationId;
        // signatura of the funcion
        // abi.encodeWithSignature
        bytes data;
    }

    // receives the operation to perform in the adapter and the ratio to scale whatever needed
    // answers if the operation was successfull
    function executeOperation(
        bool,
        address,
        address,
        uint256,
        AdapterOperation memory
    ) external returns (bool, uint256);
}


// File contracts/interfaces/IPlatformAdapter.sol

//  MIT

pragma solidity >=0.8.0;

interface IPlatformAdapter {
    struct TradeOperation {
        uint8 platformId;
        uint8 actionId;
        bytes data;
    }

    error InvalidOperation(uint8 platformId, uint8 actionId);

    function createTrade(
        TradeOperation memory tradeOperation
    ) external returns (bytes memory);

    function totalAssets() external view returns (uint256);
}


// File contracts/interfaces/IBaseVault.sol

//  MIT

pragma solidity >=0.8.0;

interface IBaseVault {
    function underlyingTokenAddress() external view returns (address);

    function contractsFactoryAddress() external view returns (address);

    function currentRound() external view returns (uint256);

    function afterRoundBalance() external view returns (uint256);

    function getGmxShortCollaterals() external view returns (address[] memory);

    function getGmxShortIndexTokens() external view returns (address[] memory);

    function getAllowedTradeTokens() external view returns (address[] memory);
}


// File contracts/interfaces/ITraderWallet.sol

//  MIT

pragma solidity >=0.8.0;


interface ITraderWallet is IBaseVault {
    function vaultAddress() external view returns (address);

    function traderAddress() external view returns (address);

    function cumulativePendingDeposits() external view returns (uint256);

    function cumulativePendingWithdrawals() external view returns (uint256);

    function lastRolloverTimestamp() external view returns (uint256);

    function gmxShortPairs(address, address) external view returns (bool);

    function gmxShortCollaterals(uint256) external view returns (address);

    function gmxShortIndexTokens(uint256) external view returns (address);

    function initialize(
        address underlyingTokenAddress,
        address traderAddress,
        address ownerAddress
    ) external;

    function setVaultAddress(address vaultAddress) external;

    function setTraderAddress(address traderAddress) external;

    function addGmxShortPairs(
        address[] calldata collateralTokens,
        address[] calldata indexTokens
    ) external;

    function addAllowedTradeTokens(address[] calldata tokens) external;

    function removeAllowedTradeToken(address token) external;

    function addProtocolToUse(uint256 protocolId) external;

    function removeProtocolToUse(uint256 protocolId) external;

    function traderDeposit(uint256 amount) external;

    function withdrawRequest(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function rollover() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        bool replicate
    ) external;

    function getAdapterAddressPerProtocol(
        uint256 protocolId
    ) external view returns (address);

    function isAllowedTradeToken(address token) external view returns (bool);

    function allowedTradeTokensLength() external view returns (uint256);

    function allowedTradeTokensAt(
        uint256 index
    ) external view returns (address);

    function isTraderSelectedProtocol(
        uint256 protocolId
    ) external view returns (bool);

    function traderSelectedProtocolIdsLength() external view returns (uint256);

    function traderSelectedProtocolIdsAt(
        uint256 index
    ) external view returns (uint256);

    function getTraderSelectedProtocolIds()
        external
        view
        returns (uint256[] memory);

    function getContractValuation() external view returns (uint256);
}


// File contracts/adapters/gmx/GMXAdapter.sol

//  MIT

pragma solidity 0.8.19;










// import "hardhat/console.sol";

library GMXAdapter {
    using MathUpgradeable for uint256;

    address internal constant gmxRouter =
        0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;
    address internal constant gmxPositionRouter =
        0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868;
    IGmxVault internal constant gmxVault =
        IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    address internal constant gmxOrderBook =
        0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB;
    address internal constant gmxOrderBookReader =
        0xa27C20A7CF0e1C68C0460706bB674f98F362Bc21;
    address internal constant gmxReader =
        0x22199a49A999c351eF7927602CFB187ec3cae489;

    /// @notice The ratio denominator between traderWallet and usersVault
    uint256 private constant ratioDenominator = 1e18;

    /// @notice The slippage allowance for swap in the position
    uint256 public constant slippage = 1e17; // 10%

    struct IncreaseOrderLocalVars {
        address[] path;
        uint256 amountIn;
        address indexToken;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
    }

    event CreateIncreasePosition(address sender, bytes32 requestKey);
    event CreateDecreasePosition(address sender, bytes32 requestKey);

    error AddressZero();
    error InsufficientEtherBalance();
    error InvalidOperationId();
    error CreateSwapOrderFail();
    error CreateIncreasePositionFail(string);
    error CreateDecreasePositionFail(string);
    error CreateIncreasePositionOrderFail(string);
    error CreateDecreasePositionOrderFail(string);
    error NotSupportedTokens(address, address);
    error TooManyOrders();

    /// @notice Gives approve to operate with gmxPositionRouter
    /// @dev Needs to be called from wallet and vault in initialization
    function __initApproveGmxPlugin() external {
        IGmxRouter(gmxRouter).approvePlugin(gmxPositionRouter);
        IGmxRouter(gmxRouter).approvePlugin(gmxOrderBook);
    }

    /// @notice Executes operation with external protocol
    /// @param ratio Scaling ratio to
    /// @param traderOperation Encoded operation data
    /// @return bool 'true' if the operation completed successfully
    function executeOperation(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        IAdapter.AdapterOperation memory traderOperation
    ) external returns (bool, uint256) {
        if (uint256(traderOperation.operationId) == 0) {
            return
                _increasePosition(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 1) {
            return
                _decreasePosition(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 2) {
            return
                _createIncreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 3) {
            return
                _updateIncreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 4) {
            return _cancelIncreaseOrder(isTraderWallet, traderOperation.data);
        } else if (traderOperation.operationId == 5) {
            return
                _createDecreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 6) {
            return
                _updateDecreaseOrder(
                    isTraderWallet,
                    traderWallet,
                    usersVault,
                    ratio,
                    traderOperation.data
                );
        } else if (traderOperation.operationId == 7) {
            return _cancelDecreaseOrder(isTraderWallet, traderOperation.data);
        }
        revert InvalidOperationId();
    }

    /*
    @notice Opens new or increases the size of an existing position
    @param tradeData must contain parameters:
        path:       [collateralToken] or [tokenIn, collateralToken] if a swap is needed
        indexToken: the address of the token to long or short
        amountIn:   the amount of tokenIn to deposit as collateral
        minOut:     the min amount of collateralToken to swap for (can be zero if no swap is required)
        sizeDelta:  the USD value of the change in position size  (scaled 1e30)
        isLong:     whether to long or short position

    Additional params for increasing position
        executionFee:   can be set to PositionRouter.minExecutionFee
        referralCode:   referral code for affiliate rewards and rebates
        callbackTarget: an optional callback contract (note: has gas limit)
        acceptablePrice: the USD value of the max (for longs) or min (for shorts) index price acceptable when executing
    @return bool - Returns 'true' if position was created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _increasePosition(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address[] memory path,
            address indexToken,
            uint256 amountIn,
            uint256 minOut,
            uint256 sizeDelta,
            bool isLong
        ) = abi.decode(
                tradeData,
                (address[], address, uint256, uint256, uint256, bool)
            );

        if (isTraderWallet) {
            // only one check is enough
            address collateralToken = path[path.length - 1];
            if (
                !_validateTradeTokens(
                    traderWallet,
                    collateralToken,
                    indexToken,
                    isLong
                )
            ) {
                revert NotSupportedTokens(collateralToken, indexToken);
            }
            // calculate ratio for UserVault based on balances of tokenIn (path[0])
            uint256 traderBalance = IERC20(path[0]).balanceOf(traderWallet);
            uint256 vaultBalance = IERC20(path[0]).balanceOf(usersVault);
            ratio_ = vaultBalance.mulDiv(
                ratioDenominator,
                traderBalance,
                MathUpgradeable.Rounding.Down
            );
        } else {
            // scaling for Vault execution
            amountIn = (amountIn * ratio) / ratioDenominator;
            uint256 amountInAvailable = IERC20(path[0]).balanceOf(
                address(this)
            );
            if (amountInAvailable < amountIn) amountIn = amountInAvailable;
            sizeDelta = (sizeDelta * ratio) / ratioDenominator;
            minOut = (minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        _checkUpdateAllowance(path[0], address(gmxRouter), amountIn);
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createIncreasePosition.selector,
                path,
                indexToken,
                amountIn,
                minOut,
                sizeDelta,
                isLong,
                acceptablePrice,
                executionFee,
                0, // referralCode
                address(0) // callbackTarget
            )
        );

        if (!success) {
            revert CreateIncreasePositionFail(_getRevertMsg(data));
        }
        emit CreateIncreasePosition(address(this), bytes32(data));
        return (true, ratio_);
    }

    /*
    @notice Closes or decreases an existing position
    @param tradeData must contain parameters:
        path:            [collateralToken] or [collateralToken, tokenOut] if a swap is needed
        indexToken:      the address of the token that was longed (or shorted)
        collateralDelta: the amount of collateral in USD value to withdraw (doesn't matter when position is completely closing)
        sizeDelta:       the USD value of the change in position size (scaled to 1e30)
        isLong:          whether the position is a long or short
        minOut:          the min output token amount (can be zero if no swap is required)

    Additional params for increasing position
        receiver:       the address to receive the withdrawn tokens
        acceptablePrice: the USD value of the max (for longs) or min (for shorts) index price acceptable when executing
        executionFee:   can be set to PositionRouter.minExecutionFee
        withdrawETH:    only applicable if WETH will be withdrawn, the WETH will be unwrapped to ETH if this is set to true
        callbackTarget: an optional callback contract (note: has gas limit)
    @return bool - Returns 'true' if position was created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _decreasePosition(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address[] memory path,
            address indexToken,
            uint256 collateralDelta,
            uint256 sizeDelta,
            bool isLong,
            uint256 minOut
        ) = abi.decode(
                tradeData,
                (address[], address, uint256, uint256, bool, uint256)
            );
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        if (isTraderWallet) {
            // calculate ratio for UserVault based on size of opened position
            uint256 traderSize = _getPosition(
                traderWallet,
                path[0],
                indexToken,
                isLong
            )[0];
            uint256 vaultSize = _getPosition(
                usersVault,
                path[0],
                indexToken,
                isLong
            )[0];
            ratio_ = vaultSize.mulDiv(
                ratioDenominator,
                traderSize,
                MathUpgradeable.Rounding.Up
            );
        } else {
            // scaling for Vault
            uint256[] memory vaultPosition = _getPosition(
                usersVault,
                path[0],
                indexToken,
                isLong
            );
            uint256 positionSize = vaultPosition[0];
            uint256 positionCollateral = vaultPosition[1];

            sizeDelta = (sizeDelta * ratio) / ratioDenominator; // most important for closing
            if (sizeDelta > positionSize) sizeDelta = positionSize;
            collateralDelta = (collateralDelta * ratio) / ratioDenominator;
            if (collateralDelta > positionCollateral)
                collateralDelta = positionCollateral;

            minOut = (minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createDecreasePosition.selector,
                path,
                indexToken,
                collateralDelta,
                sizeDelta,
                isLong,
                address(this), // receiver
                acceptablePrice,
                minOut,
                executionFee,
                false, // withdrawETH
                address(0) // callbackTarget
            )
        );

        if (!success) {
            revert CreateDecreasePositionFail(_getRevertMsg(data));
        }
        emit CreateDecreasePosition(address(this), bytes32(data));
        return (true, ratio_);
    }

    /// /// /// ///
    /// Orders
    /// /// /// ///

    /*
    @notice Creates new order to open or increase position
    @param tradeData must contain parameters:
        path:            [collateralToken] or [tokenIn, collateralToken] if a swap is needed
        amountIn:        the amount of tokenIn to deposit as collateral
        indexToken:      the address of the token to long or short
        minOut:          the min amount of collateralToken to swap for (can be zero if no swap is required)
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        isLong:          whether to long or short position
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for creating new Long order
            in terms of Short position:
                'false' for creating new Short order

    Additional params for increasing position
        collateralToken: the collateral token (must be path[path.length-1] )
        executionFee:   can be set to OrderBook.minExecutionFee
        shouldWrap:     true if 'tokenIn' is native and should be wrapped
    @return bool - Returns 'true' if order was successfully created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _createIncreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        IncreaseOrderLocalVars memory vars;
        (
            vars.path,
            vars.amountIn,
            vars.indexToken,
            vars.minOut,
            vars.sizeDelta,
            vars.isLong,
            vars.triggerPrice,
            vars.triggerAboveThreshold
        ) = abi.decode(
            tradeData,
            (address[], uint256, address, uint256, uint256, bool, uint256, bool)
        );
        uint256 executionFee = IGmxOrderBook(gmxOrderBook).minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();
        address collateralToken = vars.path[vars.path.length - 1];

        if (isTraderWallet) {
            // only one check is enough
            if (
                !_validateTradeTokens(
                    traderWallet,
                    collateralToken,
                    vars.indexToken,
                    vars.isLong
                )
            ) {
                revert NotSupportedTokens(collateralToken, vars.indexToken);
            }
            if (!_validateIncreaseOrder(traderWallet)) {
                revert TooManyOrders();
            }

            // calculate ratio for UserVault based on balances of tokenIn (path[0])
            uint256 traderBalance = IERC20(vars.path[0]).balanceOf(
                traderWallet
            );
            uint256 vaultBalance = IERC20(vars.path[0]).balanceOf(usersVault);
            ratio_ = vaultBalance.mulDiv(
                ratioDenominator,
                traderBalance,
                MathUpgradeable.Rounding.Up
            );
        } else {
            if (!_validateIncreaseOrder(usersVault)) {
                revert TooManyOrders();
            }
            // scaling for Vault execution
            vars.amountIn = (vars.amountIn * ratio) / ratioDenominator;
            uint256 amountInAvailable = IERC20(vars.path[0]).balanceOf(
                address(this)
            );
            if (amountInAvailable < vars.amountIn)
                vars.amountIn = amountInAvailable;
            vars.sizeDelta = (vars.sizeDelta * ratio) / ratioDenominator;
            vars.minOut = (vars.minOut * ratio) / (ratioDenominator + slippage); // decreased due to price impact
        }

        _checkUpdateAllowance(vars.path[0], address(gmxRouter), vars.amountIn);

        (bool success, bytes memory data) = gmxOrderBook.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxOrderBook.createIncreaseOrder.selector,
                vars.path,
                vars.amountIn,
                vars.indexToken,
                vars.minOut,
                vars.sizeDelta,
                collateralToken,
                vars.isLong,
                vars.triggerPrice,
                vars.triggerAboveThreshold,
                executionFee,
                false // 'shouldWrap'
            )
        );

        if (!success) {
            revert CreateIncreasePositionOrderFail(_getRevertMsg(data));
        }
        return (true, ratio_);
    }

    /*
    @notice Updates exist increase order
    @param tradeData must contain parameters:
        orderIndexes:   the array with Wallet and Vault indexes of the exist order indexes to update
                        [0, 1]: 0 - Wallet, 1 - Vault
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for creating new Long order
            in terms of Short position:
                'false' for creating new Short order

    @return bool - Returns 'true' if order was successfully updated
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _updateIncreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            uint256[] memory orderIndexes,
            uint256 sizeDelta,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(tradeData, (uint256[], uint256, uint256, bool));

        uint256 orderIndex;

        if (isTraderWallet) {
            // calculate ratio for UserVault based on sizes of current orders
            IGmxOrderBook.IncreaseOrder memory walletOrder = _getIncreaseOrder(
                traderWallet,
                orderIndexes[0]
            );
            IGmxOrderBook.IncreaseOrder memory vaultOrder = _getIncreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            ratio_ = vaultOrder.sizeDelta.mulDiv(
                ratioDenominator,
                walletOrder.sizeDelta,
                MathUpgradeable.Rounding.Down
            );

            orderIndex = orderIndexes[0]; // first for traderWallet, second for usersVault
        } else {
            // scaling for Vault execution
            sizeDelta = (sizeDelta * ratio) / ratioDenominator;
            orderIndex = orderIndexes[1]; // first for traderWallet, second for usersVault
        }

        IGmxOrderBook(gmxOrderBook).updateIncreaseOrder(
            orderIndex,
            sizeDelta,
            triggerPrice,
            triggerAboveThreshold
        );
        return (true, ratio_);
    }

    /*
    @notice Cancels exist increase order
    @param isTraderWallet The flag, 'true' if caller is TraderWallet (and it will calculate ratio for UsersVault)
    @param tradeData must contain parameters:
        orderIndexes:  the array with Wallet and Vault indexes of the exist orders to update
    @return bool - Returns 'true' if order was canceled
    @return ratio_ - Unused value
    */
    function _cancelIncreaseOrder(
        bool isTraderWallet,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        uint256[] memory orderIndexes = abi.decode(tradeData, (uint256[]));

        // default trader Wallet value
        uint256 orderIndex;
        if (isTraderWallet) {
            // value for Wallet
            orderIndex = orderIndexes[0];
        } else {
            // value for Vault
            orderIndex = orderIndexes[1];
        }

        IGmxOrderBook(gmxOrderBook).cancelIncreaseOrder(orderIndex);
        return (true, ratio_);
    }

    /*
    @notice Creates new order to close or decrease position
            Also can be used to create (partial) stop-loss or take-profit orders
    @param tradeData must contain parameters:
        indexToken:      the address of the token that was longed (or shorted)
        sizeDelta:       the USD value of the change in position size (scaled to 1e30)
        collateralToken: the collateral token address
        collateralDelta: the amount of collateral in USD value to withdraw (scaled to 1e30)
        isLong:          whether the position is a long or short
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for take-profit orders, 'false' for stop-loss orders
            in terms of Short position:
                'false' for take-profit orders', true' for stop-loss orders
    @return bool - Returns 'true' if order was successfully created
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _createDecreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            address indexToken,
            uint256 sizeDelta,
            address collateralToken,
            uint256 collateralDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(
                tradeData,
                (address, uint256, address, uint256, bool, uint256, bool)
            );

        // for decrease order gmx requires strict: 'msg.value > minExecutionFee'
        // thats why we need to add 1
        uint256 executionFee = IGmxOrderBook(gmxOrderBook).minExecutionFee() +
            1;
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();

        if (isTraderWallet) {
            // calculate ratio for UserVault based on size of opened position
            uint256 traderSize = _getPosition(
                traderWallet,
                collateralToken,
                indexToken,
                isLong
            )[0];
            uint256 vaultSize = _getPosition(
                usersVault,
                collateralToken,
                indexToken,
                isLong
            )[0];
            ratio_ = vaultSize.mulDiv(
                ratioDenominator,
                traderSize,
                MathUpgradeable.Rounding.Up
            );
        } else {
            // scaling for Vault
            uint256[] memory vaultPosition = _getPosition(
                usersVault,
                collateralToken,
                indexToken,
                isLong
            );
            uint256 positionSize = vaultPosition[0];
            uint256 positionCollateral = vaultPosition[1];

            // rounding Up and then check amounts
            sizeDelta = sizeDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            ); // value important for closing
            if (sizeDelta > positionSize) sizeDelta = positionSize;
            collateralDelta = collateralDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            );
            if (collateralDelta > positionCollateral)
                collateralDelta = positionCollateral;
        }

        (bool success, bytes memory data) = gmxOrderBook.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxOrderBook.createDecreaseOrder.selector,
                indexToken,
                sizeDelta,
                collateralToken,
                collateralDelta,
                isLong,
                triggerPrice,
                triggerAboveThreshold
            )
        );

        if (!success) {
            revert CreateDecreasePositionOrderFail(_getRevertMsg(data));
        }
        return (true, ratio_);
    }

    /*
    @notice Updates exist decrease order
    @param tradeData must contain parameters:
        orderIndexes:   the array with Wallet and Vault indexes of the exist order indexes to update
                        [0, 1]: 0 - Wallet, 1 - Vault
        collateralDelta: the amount of collateral in USD value to withdraw (scaled to 1e30)
        sizeDelta:       the USD value of the change in position size  (scaled 1e30)
        triggerPrice:    the price at which the order should be executed
        triggerAboveThreshold:
            in terms of Long position:
                'true' for take-profit orders, 'false' for stop-loss orders
            in terms of Short position:
                'false' for take-profit orders', true' for stop-loss orders

    @return bool - Returns 'true' if order was successfully updated
    @return ratio_ - Value for scaling amounts from TraderWallet to UsersVault
    */
    function _updateDecreaseOrder(
        bool isTraderWallet,
        address traderWallet,
        address usersVault,
        uint256 ratio,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        (
            uint256[] memory orderIndexes,
            uint256 collateralDelta,
            uint256 sizeDelta,
            uint256 triggerPrice,
            bool triggerAboveThreshold
        ) = abi.decode(tradeData, (uint256[], uint256, uint256, uint256, bool));

        uint256 orderIndex;

        if (isTraderWallet) {
            // calculate ratio for UserVault based on sizes of current orders
            IGmxOrderBook.DecreaseOrder memory walletOrder = _getDecreaseOrder(
                traderWallet,
                orderIndexes[0]
            );
            IGmxOrderBook.DecreaseOrder memory vaultOrder = _getDecreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            ratio_ = vaultOrder.sizeDelta.mulDiv(
                ratioDenominator,
                walletOrder.sizeDelta,
                MathUpgradeable.Rounding.Up
            );

            orderIndex = orderIndexes[0]; // first for traderWallet, second for usersVault
        } else {
            // scaling for Vault execution
            // get current position
            IGmxOrderBook.DecreaseOrder memory vaultOrder = _getDecreaseOrder(
                usersVault,
                orderIndexes[1]
            );
            // rounding Up and then check amounts
            sizeDelta = sizeDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            ); // value important for closing
            if (sizeDelta > vaultOrder.sizeDelta)
                sizeDelta = vaultOrder.sizeDelta;
            collateralDelta = collateralDelta.mulDiv(
                ratio,
                ratioDenominator,
                MathUpgradeable.Rounding.Up
            );
            if (collateralDelta > vaultOrder.collateralDelta)
                collateralDelta = vaultOrder.collateralDelta;

            orderIndex = orderIndexes[1]; // first for traderWallet, second for usersVault
        }

        IGmxOrderBook(gmxOrderBook).updateDecreaseOrder(
            orderIndex,
            collateralDelta,
            sizeDelta,
            triggerPrice,
            triggerAboveThreshold
        );
        return (true, ratio_);
    }

    /*
        @notice Cancels exist decrease order
        @param isTraderWallet The flag, 'true' if caller is TraderWallet (and it will calculate ratio for UsersVault)
        @param tradeData must contain parameters:
            orderIndexes:      the array with Wallet and Vault indexes of the exist orders to update
        @return bool - Returns 'true' if order was canceled
        @return ratio_ - Unused value
    */
    function _cancelDecreaseOrder(
        bool isTraderWallet,
        bytes memory tradeData
    ) internal returns (bool, uint256 ratio_) {
        uint256[] memory orderIndexes = abi.decode(tradeData, (uint256[]));

        // default trader Wallet value
        uint256 orderIndex;
        if (isTraderWallet) {
            // value for Wallet
            orderIndex = orderIndexes[0];
        } else {
            // value for Vault
            orderIndex = orderIndexes[1];
        }

        IGmxOrderBook(gmxOrderBook).cancelDecreaseOrder(orderIndex);
        return (true, ratio_);
    }

    function _validateTradeTokens(
        address traderWallet,
        address collateralToken,
        address indexToken,
        bool isLong
    ) internal view returns (bool) {
        if (isLong) {
            address[] memory allowedTradeTokens = ITraderWallet(traderWallet)
                .getAllowedTradeTokens();
            for (uint256 i; i < allowedTradeTokens.length; ) {
                if (allowedTradeTokens[i] == indexToken) return true;
                unchecked {
                    ++i;
                }
            }
        } else {
            if (
                !ITraderWallet(traderWallet).gmxShortPairs(
                    collateralToken,
                    indexToken
                )
            ) {
                return false;
            }
            return true;
        }
        return false;
    }

    /// @dev account can't keep more than 10 orders because of expensive valuation
    ///      For gas saving check only oldest tenth order
    function _validateIncreaseOrder(
        address account
    ) internal view returns (bool) {
        uint256 latestIndex = IGmxOrderBook(gmxOrderBook).increaseOrdersIndex(
            account
        );
        if (latestIndex >= 10) {
            uint256 tenthIndex = latestIndex - 10;
            IGmxOrderBook.IncreaseOrder memory order = IGmxOrderBook(
                gmxOrderBook
            ).increaseOrders(account, tenthIndex);
            if (order.account != address(0)) {
                return false;
            }
        }
        return true;
    }

    /// @notice Updates allowance amount for token
    function _checkUpdateAllowance(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            IERC20(token).approve(spender, amount);
        }
    }

    /// @notice Helper function to track revers in call()
    function _getRevertMsg(
        bytes memory _returnData
    ) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getPosition(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    ) internal view returns (uint256[] memory) {
        address[] memory collaterals = new address[](1);
        collaterals[0] = collateralToken;
        address[] memory indexTokens = new address[](1);
        indexTokens[0] = indexToken;
        bool[] memory isLongs = new bool[](1);
        isLongs[0] = isLong;

        return
            IGmxReader(gmxReader).getPositions(
                address(gmxVault),
                account,
                collaterals,
                indexTokens,
                isLongs
            );
    }

    function _getIncreaseOrder(
        address account,
        uint256 index
    ) internal view returns (IGmxOrderBook.IncreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).increaseOrders(account, index);
    }

    function _getDecreaseOrder(
        address account,
        uint256 index
    ) internal view returns (IGmxOrderBook.DecreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).decreaseOrders(account, index);
    }

    function emergencyDecreasePosition(
        address[] calldata path,
        address indexToken,
        uint256 sizeDelta,
        bool isLong
    ) external {
        uint256 executionFee = IGmxPositionRouter(gmxPositionRouter)
            .minExecutionFee();
        if (address(this).balance < executionFee)
            revert InsufficientEtherBalance();
        uint256 acceptablePrice;
        if (isLong) {
            acceptablePrice = gmxVault.getMinPrice(indexToken);
        } else {
            acceptablePrice = gmxVault.getMaxPrice(indexToken);
        }

        (bool success, bytes memory data) = gmxPositionRouter.call{
            value: executionFee
        }(
            abi.encodeWithSelector(
                IGmxPositionRouter.createDecreasePosition.selector,
                path,
                indexToken,
                0, // collateralDelta
                sizeDelta,
                isLong,
                address(this), // receiver
                acceptablePrice,
                0, // minOut
                executionFee,
                false, // withdrawETH
                address(0) // callbackTarget
            )
        );
        if (!success) {
            revert CreateDecreasePositionFail(_getRevertMsg(data));
        }
        emit CreateDecreasePosition(address(this), bytes32(data));
    }
}


// File contracts/interfaces/Errors.sol

//  MIT

pragma solidity 0.8.19;

interface Errors {
    error ZeroAddress(string target);
    error ZeroAmount();
    error UserNotAllowed();
    error ShareTransferNotAllowed();
    error InvalidTraderWallet();
    error TokenTransferFailed();
    error InvalidRound();
    error InsufficientShares(uint256 unclaimedShareBalance);
    error InsufficientAssets(uint256 unclaimedAssetBalance);
    error InvalidRollover();
    error InvalidAdapter();
    error AdapterOperationFailed(address adapter);
    error ApproveFailed(address caller, address token, uint256 amount);
    error NotEnoughReservedAssets(
        uint256 underlyingContractBalance,
        uint256 reservedAssets
    );
    error TooBigAmount();

    error DoubleSet();
    error InvalidVault();
    error CallerNotAllowed();
    error TraderNotAllowed();
    error InvalidProtocol();
    error ProtocolIdPresent();
    error ProtocolIdNotPresent();
    error UsersVaultOperationFailed();
    error SendToTraderFailed();
    error InvalidToken();
    error TokenPresent();
    error NoUniswapPairWithUnderlyingToken(address token);
    error TooEarly();
}


// File contracts/interfaces/Events.sol

//  MIT

pragma solidity 0.8.19;

interface Events {
    event AdaptersRegistryAddressSet(address indexed adaptersRegistryAddress);

    event TraderWalletAddressSet(address indexed traderWalletAddress);
    event UserDeposited(
        address indexed caller,
        uint256 assetsAmount,
        uint256 currentRound
    );
    event WithdrawRequest(
        address indexed account,
        uint256 amount,
        uint256 currentRound
    );
    event SharesClaimed(
        uint256 round,
        uint256 shares,
        address caller,
        address receiver
    );
    event AssetsClaimed(
        uint256 round,
        uint256 assets,
        address owner,
        address receiver
    );
    event UsersVaultRolloverExecuted(
        uint256 round,
        uint256 underlyingTokenPerShare,
        uint256 sharesToMint,
        uint256 sharesToBurn,
        int256 overallProfit,
        uint256 unusedFunds
    );

    event VaultAddressSet(address indexed vaultAddress);
    event UnderlyingTokenAddressSet(address indexed underlyingTokenAddress);
    event TraderAddressSet(address indexed traderAddress);
    event ProtocolToUseAdded(uint256 protocolId);
    event ProtocolToUseRemoved(uint256 protocolId);
    event TraderDeposit(
        address indexed account,
        uint256 amount,
        uint256 currentRound
    );
    event OperationExecuted(
        uint256 protocolId,
        uint256 timestamp,
        string target,
        bool replicate,
        uint256 walletRatio
    );
    event TraderWalletRolloverExecuted(
        uint256 timestamp,
        uint256 round,
        int256 traderProfit,
        uint256 unusedFunds
    );
    event NewGmxShortTokens(address collateralToken, address indexToken);
    event TradeTokenAdded(address token);
    event TradeTokenRemoved(address token);
    event EmergencyCloseError(address closedToken, uint256 closedAmount);
}


// File contracts/interfaces/IAdaptersRegistry.sol

//  MIT

pragma solidity >=0.8.0;

interface IAdaptersRegistry {
    function getAdapterAddress(uint256) external view returns (bool, address);

    function allValidProtocols() external view returns (uint256[] memory);
}


// File contracts/interfaces/IContractsFactory.sol

//  MIT

pragma solidity >=0.8.0;

interface IContractsFactory {
    error ZeroAddress(string target);
    error InvalidCaller();
    error FeeRateError();
    error ZeroAmount();
    error InvestorAlreadyExists();
    error InvestorNotExists();
    error TraderAlreadyExists();
    error TraderNotExists();
    error FailedWalletDeployment();
    error FailedVaultDeployment();
    error InvalidWallet();
    error InvalidVault();
    error InvalidTrader();
    error InvalidToken();
    error TokenPresent();
    error UsersVaultAlreadyDeployed();

    event FeeRateSet(uint256 newFeeRate);
    event FeeReceiverSet(address newFeeReceiver);
    event InvestorAdded(address indexed investorAddress);
    event InvestorRemoved(address indexed investorAddress);
    event TraderAdded(address indexed traderAddress);
    event TraderRemoved(address indexed traderAddress);
    event GlobalTokenAdded(address tokenAddress);
    event GlobalTokenRemoved(address tokenAddress);
    event AdaptersRegistryAddressSet(address indexed adaptersRegistryAddress);
    event DynamicValuationAddressSet(address indexed dynamicValuationAddress);
    event LensAddressSet(address indexed lensAddress);
    event TraderWalletDeployed(
        address indexed traderWalletAddress,
        address indexed traderAddress,
        address indexed underlyingTokenAddress
    );
    event UsersVaultDeployed(
        address indexed usersVaultAddress,
        address indexed traderWalletAddress
    );
    event OwnershipToWalletChanged(
        address indexed traderWalletAddress,
        address indexed newOwner
    );
    event OwnershipToVaultChanged(
        address indexed usersVaultAddress,
        address indexed newOwner
    );
    event TraderWalletImplementationChanged(address indexed newImplementation);
    event UsersVaultImplementationChanged(address indexed newImplementation);

    function BASE() external view returns (uint256);

    function feeRate() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function dynamicValuationAddress() external view returns (address);

    function adaptersRegistryAddress() external view returns (address);

    function lensAddress() external view returns (address);

    function traderWalletsArray(uint256) external view returns (address);

    function isTraderWallet(address) external view returns (bool);

    function usersVaultsArray(uint256) external view returns (address);

    function isUsersVault(address) external view returns (bool);

    function allowedTraders(address) external view returns (bool);

    function allowedInvestors(address) external view returns (bool);

    function initialize(
        uint256 feeRate,
        address feeReceiver,
        address traderWalletImplementation,
        address usersVaultImplementation
    ) external;

    function addInvestors(address[] calldata investors) external;

    function addInvestor(address investorAddress) external;

    function removeInvestor(address investorAddress) external;

    function addTraders(address[] calldata traders) external;

    function addTrader(address traderAddress) external;

    function removeTrader(address traderAddress) external;

    function setDynamicValuationAddress(
        address dynamicValuationAddress
    ) external;

    function setAdaptersRegistryAddress(
        address adaptersRegistryAddress
    ) external;

    function setLensAddress(address lensAddress) external;

    function setFeeReceiver(address newFeeReceiver) external;

    function setFeeRate(uint256 newFeeRate) external;

    function setUsersVaultImplementation(address newImplementation) external;

    function setTraderWalletImplementation(address newImplementation) external;

    function addGlobalAllowedTokens(address[] calldata) external;

    function removeGlobalToken(address) external;

    function deployTraderWallet(
        address underlyingTokenAddress,
        address traderAddress,
        address owner
    ) external;

    function deployUsersVault(
        address traderWalletAddress,
        address owner,
        string memory sharesName,
        string memory sharesSymbol
    ) external;

    function usersVaultImplementation() external view returns (address);

    function traderWalletImplementation() external view returns (address);

    function numOfTraderWallets() external view returns (uint256);

    function numOfUsersVaults() external view returns (uint256);

    function isAllowedGlobalToken(address token) external returns (bool);

    function allowedGlobalTokensAt(
        uint256 index
    ) external view returns (address);

    function allowedGlobalTokensLength() external view returns (uint256);

    function getAllowedGlobalTokens() external view returns (address[] memory);
}


// File contracts/interfaces/IDynamicValuation.sol

//  MIT

pragma solidity >=0.8.0;

interface IDynamicValuation {
    struct OracleData {
        address dataFeed;
        uint8 dataFeedDecimals;
        uint32 heartbeat;
        uint8 tokenDecimals;
    }

    error WrongAddress();
    error NotUniqiueValues();

    error BadPrice();
    error TooOldPrice();
    error NoOracleForToken(address token);

    error NoObserver();

    error SequencerDown();
    error GracePeriodNotOver();

    event SetChainlinkOracle(address indexed token, OracleData oracleData);

    event SetGmxObserver(address indexed newGmxObserver);

    function factory() external view returns (address);

    function decimals() external view returns (uint8);

    function sequencerUptimeFeed() external view returns (address);

    function gmxObserver() external view returns (address);

    function initialize(
        address _factory,
        address _sequencerUptimeFeed,
        address _gmxObserver
    ) external;

    function setChainlinkPriceFeed(
        address token,
        address priceFeed,
        uint32 heartbeat
    ) external;

    function setGmxObserver(address newValue) external;

    function chainlinkOracles(
        address token
    ) external view returns (OracleData memory);

    function getOraclePrice(
        address token,
        uint256 amount
    ) external view returns (uint256);

    function getDynamicValuation(
        address addr
    ) external view returns (uint256 valuation);
}


// File contracts/BaseVault.sol

//  MIT

pragma solidity 0.8.19;









abstract contract BaseVault is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    IBaseVault,
    Errors,
    Events
{
    uint256 public constant BASE = 1e18; // 100%
    address public override underlyingTokenAddress;
    address public override contractsFactoryAddress;

    uint256 public override currentRound;

    uint256 public override afterRoundBalance;

    uint256 internal _ONE_UNDERLYING_TOKEN;

    modifier notZeroAddress(address _variable, string memory _message) {
        _checkZeroAddress(_variable, _message);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function __BaseVault_init(
        address _underlyingTokenAddress,
        address _ownerAddress
    ) internal onlyInitializing {
        __Ownable_init();
        __ReentrancyGuard_init();

        __BaseVault_init_unchained(_underlyingTokenAddress, _ownerAddress);
    }

    function __BaseVault_init_unchained(
        address _underlyingTokenAddress,
        address _ownerAddress
    ) internal onlyInitializing {
        _checkZeroAddress(_underlyingTokenAddress, "_underlyingTokenAddress");
        _checkZeroAddress(_ownerAddress, "_ownerAddress");

        _ONE_UNDERLYING_TOKEN =
            10 ** IERC20Metadata(_underlyingTokenAddress).decimals();

        underlyingTokenAddress = _underlyingTokenAddress;
        contractsFactoryAddress = msg.sender;

        transferOwnership(_ownerAddress);

        // THIS LINE IS COMMENTED JUST TO DEPLOY ON GOERLI WHERE THERE ARE NO GMX CONTRACTS
        GMXAdapter.__initApproveGmxPlugin();
    }

    receive() external payable {}

    /* OWNER FUNCTIONS */

    /* INTERNAL FUNCTIONS */

    function _executeOnAdapter(
        address _adapterAddress,
        bool _isTraderWallet,
        address _traderWallet,
        address _usersVault,
        uint256 _ratio,
        IAdapter.AdapterOperation memory _traderOperation
    ) internal returns (uint256) {
        (bool success, uint256 ratio) = IAdapter(_adapterAddress)
            .executeOperation(
                _isTraderWallet,
                _traderWallet,
                _usersVault,
                _ratio,
                _traderOperation
            );
        if (!success) revert AdapterOperationFailed(_adapterAddress);
        return ratio;
    }

    function _executeOnGmx(
        bool _isTraderWallet,
        address _traderWallet,
        address _usersVault,
        uint256 _ratio,
        IAdapter.AdapterOperation memory _traderOperation
    ) internal returns (uint256) {
        (bool success, uint256 ratio) = GMXAdapter.executeOperation(
            _isTraderWallet,
            _traderWallet,
            _usersVault,
            _ratio,
            _traderOperation
        );
        if (!success) revert AdapterOperationFailed(address(0));
        return ratio;
    }

    function _getAdapterAddress(
        uint256 _protocolId
    ) internal view returns (address) {
        (bool adapterExist, address adapterAddress) = IAdaptersRegistry(
            IContractsFactory(contractsFactoryAddress).adaptersRegistryAddress()
        ).getAdapterAddress(_protocolId);
        if (!adapterExist || adapterAddress == address(0))
            revert InvalidAdapter();

        return adapterAddress;
    }

    function _convertTokenAmountToUnderlyingAmount(
        address token,
        uint256 amount
    ) internal view returns (uint256 underlyingTokenAmount) {
        address _underlyingTokenAddress = underlyingTokenAddress;
        if (token == _underlyingTokenAddress) {
            return amount;
        }

        address _contractsFactoryAddress = contractsFactoryAddress;
        address dynamicValuationAddress = IContractsFactory(
            _contractsFactoryAddress
        ).dynamicValuationAddress();

        uint256 ONE_UNDERLYING_TOKEN = _ONE_UNDERLYING_TOKEN;

        uint256 tokenPrice = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(token, amount);
        uint256 underlyingPrice = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(_underlyingTokenAddress, ONE_UNDERLYING_TOKEN);

        return (tokenPrice * ONE_UNDERLYING_TOKEN) / underlyingPrice;
    }

    function _checkZeroRound() internal view {
        if (currentRound == 0) revert InvalidRound();
    }

    function _checkZeroAddress(
        address _variable,
        string memory _message
    ) internal pure {
        if (_variable == address(0)) revert ZeroAddress({target: _message});
    }

    // @todo consider adding TimeLock for this function?
    /// @notice Withdrawing tokens in the emergency case from the contract
    /// @dev Danger! Use this only in emergency case. Otherwise it can brake contract logic.
    /// @param token The token address to be withdrawn
    function emergencyWithdraw(IERC20 token) external onlyOwner {
        if (address(token) == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            uint256 ethBalance = address(this).balance;
            payable(owner()).transfer(ethBalance);
            return;
        }
        uint256 balance = token.balanceOf(address(this));
        token.transfer(owner(), balance);
    }

    /// @notice Decrease/close position in emergency case
    /// @dev Danger! Use this only in emergency case. Otherwise it can brake contract logic.
    /// @param path The swap path [collateralToken] or [collateralToken, tokenOut] if a swap is needed
    /// @param indexToken The address of the token that was longed (or shorted)
    /// @param sizeDelta The USD value of the change in position size (scaled to 1e30).
    ///                  To close position use current position's 'size'
    /// @param isLong Whether the position is a long or short
    function emergencyDecreasePosition(
        address[] calldata path,
        address indexToken,
        uint256 sizeDelta,
        bool isLong
    ) external onlyOwner {
        GMXAdapter.emergencyDecreasePosition(
            path,
            indexToken,
            sizeDelta,
            isLong
        );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File contracts/interfaces/IUsersVault.sol

//  MIT

pragma solidity >=0.8.0;


interface IUsersVault is IBaseVault, IERC20Upgradeable {
    struct UserData {
        uint256 round;
        uint256 pendingDepositAssets;
        uint256 pendingWithdrawShares;
        uint256 unclaimedDepositShares;
        uint256 unclaimedWithdrawAssets;
    }

    function traderWalletAddress() external view returns (address);

    function pendingDepositAssets() external view returns (uint256);

    function pendingWithdrawShares() external view returns (uint256);

    function processedWithdrawAssets() external view returns (uint256);

    function kunjiFeesAssets() external view returns (uint256);

    function userData(address) external view returns (UserData memory);

    function assetsPerShareXRound(uint256) external view returns (uint256);

    function initialize(
        address underlyingTokenAddress,
        address traderWalletAddress,
        address ownerAddress,
        string memory sharesName,
        string memory sharesSymbol
    ) external;

    function collectFees(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function userDeposit(uint256 amount) external;

    function withdrawRequest(uint256 sharesAmount) external;

    function rolloverFromTrader() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        uint256 walletRatio
    ) external;

    function getContractValuation() external view returns (uint256);

    function previewShares(address receiver) external view returns (uint256);

    function claim() external;
}


// File contracts/interfaces/ILens.sol

//  MIT

pragma solidity >=0.8.0;

interface ILens {
    struct ProcessedPosition {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 hasRealisedProfit;
        uint256 realisedPnl;
        uint256 lastIncreasedTime;
        bool hasProfit;
        uint256 delta;
        address collateralToken;
        address indexToken;
        bool isLong;
    }

    function getAllPositionsProcessed(
        address account
    ) external view returns (ProcessedPosition[] memory result);
}


// File contracts/UsersVault.sol

//  MIT

pragma solidity 0.8.19;










contract UsersVault is ERC20Upgradeable, BaseVault, IUsersVault {
    using SafeERC20 for IERC20;

    address public override traderWalletAddress;

    // Total amount of total deposit assets in mapped round
    uint256 public override pendingDepositAssets;

    // Total amount of total withdrawal shares in mapped round
    uint256 public override pendingWithdrawShares;

    uint256 public override processedWithdrawAssets;

    uint256 public override kunjiFeesAssets;

    // rollover time control
    uint256 public emergencyPeriod;
    bool public isEmergencyOpen;

    // slippage control
    uint256 public defaultSlippagePercent;
    uint256 public slippageStepPercent;
    uint256 public currentSlippage;

    // ratio per round
    mapping(uint256 => uint256) public assetsPerShareXRound;

    mapping(address => UserData) private _userData;
    mapping(uint256 => uint256) private _underlyingPriceXRound;

    modifier onlyTraderWallet() {
        if (msg.sender != traderWalletAddress) revert UserNotAllowed();
        _;
    }

    modifier onlyValidInvestors(address account) {
        if (
            !IContractsFactory(contractsFactoryAddress).allowedInvestors(
                account
            )
        ) revert UserNotAllowed();
        _;
    }

    function initialize(
        address _underlyingTokenAddress,
        address _traderWalletAddress,
        address _ownerAddress,
        string memory _sharesName,
        string memory _sharesSymbol
    ) external virtual override initializer {
        __UsersVault_init(
            _underlyingTokenAddress,
            _traderWalletAddress,
            _ownerAddress,
            _sharesName,
            _sharesSymbol
        );
    }

    function __UsersVault_init(
        address _underlyingTokenAddress,
        address _traderWalletAddress,
        address _ownerAddress,
        string memory _sharesName,
        string memory _sharesSymbol
    ) internal onlyInitializing {
        __BaseVault_init(_underlyingTokenAddress, _ownerAddress);
        __ERC20_init(_sharesName, _sharesSymbol);

        __UsersVault_init_unchained(_traderWalletAddress);
    }

    function __UsersVault_init_unchained(
        address _traderWalletAddress
    ) internal onlyInitializing {
        _checkZeroAddress(_traderWalletAddress, "_traderWalletAddress");

        traderWalletAddress = _traderWalletAddress;

        emergencyPeriod = 15 hours; // 15h
        defaultSlippagePercent = 150; // 1.5%
        slippageStepPercent = 100; // 1%
        currentSlippage = defaultSlippagePercent;
    }

    function collectFees(uint256 amount) external override onlyOwner {
        uint256 _kunjiFeesAssets = kunjiFeesAssets;

        if (amount > _kunjiFeesAssets) {
            revert TooBigAmount();
        }

        kunjiFeesAssets = _kunjiFeesAssets - amount;

        address feeReceiver = IContractsFactory(contractsFactoryAddress)
            .feeReceiver();
        IERC20(underlyingTokenAddress).transfer(feeReceiver, amount);
    }

    function setAdapterAllowanceOnToken(
        uint256 _protocolId,
        address _tokenAddress,
        bool _revoke
    ) external override onlyOwner {
        address _traderWalletAddress = traderWalletAddress;
        if (
            !ITraderWallet(_traderWalletAddress).isTraderSelectedProtocol(
                _protocolId
            )
        ) {
            revert InvalidProtocol();
        }
        if (
            !ITraderWallet(_traderWalletAddress).isAllowedTradeToken(
                _tokenAddress
            )
        ) {
            revert InvalidToken();
        }

        address adapterAddress = _getAdapterAddress(_protocolId);

        uint256 amount;
        if (!_revoke) amount = type(uint256).max;
        else amount = 0;

        IERC20(_tokenAddress).forceApprove(adapterAddress, amount);
    }

    function userDeposit(
        uint256 _amount
    ) external override onlyValidInvestors(msg.sender) {
        if (_amount == 0) revert ZeroAmount();

        UserData memory data = _updateUserData(msg.sender);

        _userData[msg.sender].pendingDepositAssets =
            data.pendingDepositAssets +
            _amount;

        pendingDepositAssets += _amount;

        IERC20(underlyingTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        emit UserDeposited(_msgSender(), _amount, currentRound);
    }

    function withdrawRequest(uint256 _sharesAmount) external override {
        if (_sharesAmount == 0) revert ZeroAmount();

        UserData memory data = _updateUserData(msg.sender);
        _userData[msg.sender].pendingWithdrawShares =
            data.pendingWithdrawShares +
            _sharesAmount;

        pendingWithdrawShares += _sharesAmount;

        super._transfer(msg.sender, address(this), _sharesAmount);

        emit WithdrawRequest(msg.sender, _sharesAmount, currentRound);
    }

    function rolloverFromTrader() external override onlyTraderWallet {
        uint256 _pendingDepositAssets = pendingDepositAssets;
        uint256 _pendingWithdrawShares = pendingWithdrawShares;

        if (_pendingDepositAssets == 0 && _pendingWithdrawShares == 0)
            revert InvalidRollover();

        uint256 _currentRound = currentRound;

        (
            uint256 newAfterRoundBalance,
            uint256 underlyingPrice,
            uint256 _processedWithdrawAssets,
            address _underlyingTokenAddress,
            uint256 ONE_UNDERLYING_TOKEN
        ) = _getContractValuationPrivate(_currentRound, _pendingDepositAssets);

        _checkReservedAssets(
            _underlyingTokenAddress,
            _pendingDepositAssets,
            _processedWithdrawAssets
        );

        int256 roundProfitValuation;
        if (_currentRound != 0) {
            (newAfterRoundBalance, roundProfitValuation) = _calculateProfit(
                newAfterRoundBalance,
                underlyingPrice,
                ONE_UNDERLYING_TOKEN
            );
        }

        _underlyingPriceXRound[_currentRound] = underlyingPrice;

        // calculate `assetsPerShare`
        uint256 valuationPerShare;
        uint256 underlyingTokenPerShare;
        {
            uint256 _totalSupply = totalSupply();
            if (_totalSupply == 0) {
                valuationPerShare = 1e18;
            } else {
                valuationPerShare =
                    (newAfterRoundBalance * 1e18) /
                    _totalSupply;
            }
            underlyingTokenPerShare =
                (valuationPerShare * ONE_UNDERLYING_TOKEN) /
                underlyingPrice;
        }
        assetsPerShareXRound[_currentRound] = valuationPerShare;

        // calculate `sharesToMint`
        uint256 sharesToMint;
        if (_pendingDepositAssets > 0) {
            uint256 pendingDepositValuation = (_pendingDepositAssets *
                underlyingPrice) / ONE_UNDERLYING_TOKEN;

            sharesToMint = (pendingDepositValuation * 1e18) / valuationPerShare;
        }

        // @note Need to burn `_pendingWithdrawShares` and to mint `sharesToMint` shares
        if (sharesToMint > _pendingWithdrawShares) {
            super._mint(address(this), sharesToMint - _pendingWithdrawShares);
        } else if (sharesToMint < _pendingWithdrawShares) {
            super._burn(address(this), _pendingWithdrawShares - sharesToMint);
        }

        if (_pendingDepositAssets > 0) {
            delete pendingDepositAssets;

            if (_currentRound != 0) {
                // @note In the round zero they are already included in the `newAfterRoundBalance`
                newAfterRoundBalance +=
                    (_pendingDepositAssets * underlyingPrice) /
                    ONE_UNDERLYING_TOKEN;
            }
        }

        if (_pendingWithdrawShares > 0) {
            uint256 processedWithdrawAssetsValuation = (valuationPerShare *
                _pendingWithdrawShares) / 1e18;
            newAfterRoundBalance -= processedWithdrawAssetsValuation;

            uint256 newProcessedWithdrawAssets = (processedWithdrawAssetsValuation *
                    ONE_UNDERLYING_TOKEN) / underlyingPrice;
            _processedWithdrawAssets += newProcessedWithdrawAssets;
            processedWithdrawAssets = _processedWithdrawAssets;

            delete pendingWithdrawShares;
        }

        uint256 unusedFunds = _checkReservedAssets(
            _underlyingTokenAddress,
            0 /* _pendingDepositAssets */,
            _processedWithdrawAssets
        );

        afterRoundBalance = newAfterRoundBalance;
        currentRound = _currentRound + 1;

        currentSlippage = defaultSlippagePercent;
        isEmergencyOpen = false;

        emit UsersVaultRolloverExecuted(
            _currentRound,
            underlyingTokenPerShare,
            sharesToMint,
            _pendingWithdrawShares, // sharesToBurn
            roundProfitValuation,
            unusedFunds
        );
    }

    function executeOnProtocol(
        uint256 _protocolId,
        IAdapter.AdapterOperation memory _traderOperation,
        uint256 _ratio
    ) external override onlyTraderWallet {
        _checkZeroRound();

        if (_protocolId == 1) {
            _executeOnGmx(
                false,
                address(0),
                address(this),
                _ratio,
                _traderOperation
            );
        } else {
            _executeOnAdapter(
                _getAdapterAddress(_protocolId),
                false, // usersVault
                address(0), // no need
                address(this),
                _ratio,
                _traderOperation
            );
        }

        // @note Check that reserved tokens are not sold
        _checkReservedAssets(
            underlyingTokenAddress,
            pendingDepositAssets,
            processedWithdrawAssets
        );
    }

    function previewShares(
        address receiver
    ) external view override returns (uint256) {
        (UserData memory data, , ) = _updateUserDataInMemory(receiver);

        return data.unclaimedDepositShares;
    }

    function previewAssets(address receiver) external view returns (uint256) {
        (UserData memory data, , ) = _updateUserDataInMemory(receiver);

        return data.unclaimedWithdrawAssets;
    }

    function claim() external override {
        UserData memory data = _updateUserData(msg.sender);

        if (data.unclaimedDepositShares > 0) {
            super._transfer(
                address(this),
                msg.sender,
                data.unclaimedDepositShares
            );

            delete _userData[msg.sender].unclaimedDepositShares;

            emit SharesClaimed(
                data.round,
                data.unclaimedDepositShares,
                msg.sender,
                msg.sender
            );
        }

        if (data.unclaimedWithdrawAssets > 0) {
            uint256 underlyingBalance = IERC20(underlyingTokenAddress)
                .balanceOf(address(this));

            uint256 transferAmount;
            if (underlyingBalance >= data.unclaimedWithdrawAssets) {
                transferAmount = data.unclaimedWithdrawAssets;
            } else {
                transferAmount = underlyingBalance;
            }

            _userData[msg.sender].unclaimedWithdrawAssets =
                data.unclaimedWithdrawAssets -
                transferAmount;

            IERC20(underlyingTokenAddress).safeTransfer(
                msg.sender,
                transferAmount
            );

            processedWithdrawAssets -= transferAmount;

            emit AssetsClaimed(
                data.round,
                transferAmount,
                msg.sender,
                msg.sender
            );
        }
    }

    //
    function getContractValuation() public view override returns (uint256) {
        (uint256 valuation, , , , ) = _getContractValuationPrivate(
            currentRound,
            pendingDepositAssets
        );

        return valuation;
    }

    function userData(
        address user
    ) external view override returns (UserData memory) {
        return _userData[user];
    }

    function getAllowedTradeTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return ITraderWallet(traderWalletAddress).getAllowedTradeTokens();
    }

    function getGmxShortCollaterals()
        external
        view
        override
        returns (address[] memory)
    {
        return ITraderWallet(traderWalletAddress).getGmxShortCollaterals();
    }

    function getGmxShortIndexTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return ITraderWallet(traderWalletAddress).getGmxShortIndexTokens();
    }

    function _checkReservedAssets(
        address _underlyingTokenAddress,
        uint256 _pendingDepositAssets,
        uint256 _processedWithdrawAssets
    ) private view returns (uint256) {
        uint256 reservedAssets = _pendingDepositAssets +
            _processedWithdrawAssets +
            kunjiFeesAssets;

        uint256 balance = IERC20(_underlyingTokenAddress).balanceOf(
            address(this)
        );

        if (balance < reservedAssets) {
            revert NotEnoughReservedAssets(balance, reservedAssets);
        }

        return balance - reservedAssets;
    }

    function _calculateProfit(
        uint256 newAfterRoundBalance,
        uint256 underlyingPrice,
        uint256 ONE_UNDERLYING_TOKEN
    )
        private
        returns (uint256 adjustedAfterRoundBalance, int256 roundProfitValuation)
    {
        roundProfitValuation =
            int256(newAfterRoundBalance) -
            int256(afterRoundBalance);
        uint256 feeRate = IContractsFactory(contractsFactoryAddress).feeRate();
        int256 kunjiFeesForRoundValuation = (roundProfitValuation *
            int256(feeRate)) / int256(BASE);

        int256 kunjiFeesForRoundAssets = (kunjiFeesForRoundValuation *
            int256(ONE_UNDERLYING_TOKEN)) / int256(underlyingPrice);
        uint256 _kunjiFeesAssets = kunjiFeesAssets;
        adjustedAfterRoundBalance = newAfterRoundBalance;
        if (int256(_kunjiFeesAssets) + kunjiFeesForRoundAssets < 0) {
            delete kunjiFeesAssets;

            // @note `newAfterRoundBalance` should be increased because reserved balance
            // of underlying tokens is decreased. It consists of pending deposits,
            // processed withdrawals, and kunji fees) =>
            // contract valuation is increased
            adjustedAfterRoundBalance +=
                (_kunjiFeesAssets * underlyingPrice) /
                ONE_UNDERLYING_TOKEN;
        } else {
            // @note always >= 0
            uint256 newKunjiFeesAssets = uint256(
                int256(_kunjiFeesAssets) + kunjiFeesForRoundAssets
            );

            adjustedAfterRoundBalance -= uint256(kunjiFeesForRoundValuation);

            kunjiFeesAssets = newKunjiFeesAssets;
        }
    }

    function _getContractValuationPrivate(
        uint256 _currentRound,
        uint256 _pendingDepositAssets
    )
        private
        view
        returns (
            uint256 valuation,
            uint256 underlyingPrice,
            uint256 _processedWithdrawAssets,
            address _underlyingTokenAddress,
            uint256 ONE_UNDERLYING_TOKEN
        )
    {
        _currentRound = currentRound;
        _processedWithdrawAssets = processedWithdrawAssets;

        address dynamicValuationAddress = IContractsFactory(
            contractsFactoryAddress
        ).dynamicValuationAddress();
        _underlyingTokenAddress = underlyingTokenAddress;

        ONE_UNDERLYING_TOKEN = _ONE_UNDERLYING_TOKEN;
        underlyingPrice = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(_underlyingTokenAddress, ONE_UNDERLYING_TOKEN);

        if (_currentRound == 0) {
            uint256 balance = IERC20(_underlyingTokenAddress).balanceOf(
                address(this)
            );

            valuation = (balance * underlyingPrice) / ONE_UNDERLYING_TOKEN;
        } else {
            uint256 totalVaultFundsValuation = IDynamicValuation(
                dynamicValuationAddress
            ).getDynamicValuation(address(this));

            uint256 pendingsFunds = _pendingDepositAssets +
                _processedWithdrawAssets +
                kunjiFeesAssets;
            uint256 pendingsFundsValuation = (pendingsFunds * underlyingPrice) /
                ONE_UNDERLYING_TOKEN;

            if (pendingsFundsValuation <= totalVaultFundsValuation) {
                valuation = totalVaultFundsValuation - pendingsFundsValuation;
            }
        }
    }

    function _updateUserDataInMemory(
        address user
    )
        private
        view
        returns (
            UserData memory data,
            bool updatedDepositData,
            bool updatedWithdrawData
        )
    {
        uint256 _currentRound = currentRound;

        data = _userData[user];

        if (
            data.round < _currentRound &&
            (data.pendingDepositAssets > 0 || data.pendingWithdrawShares > 0)
        ) {
            uint256 sharePrice = assetsPerShareXRound[data.round];

            uint256 underlyingPrice = _underlyingPriceXRound[data.round];

            if (data.pendingDepositAssets > 0) {
                uint256 pendingDepositValuation = (underlyingPrice *
                    data.pendingDepositAssets) / _ONE_UNDERLYING_TOKEN;

                data.unclaimedDepositShares +=
                    (pendingDepositValuation * 1e18) /
                    sharePrice;

                data.pendingDepositAssets = 0;

                updatedDepositData = true;
            }

            if (data.pendingWithdrawShares > 0) {
                uint256 processedWithdrawValuation = (data
                    .pendingWithdrawShares * sharePrice) / 1e18;

                data.unclaimedWithdrawAssets +=
                    (processedWithdrawValuation * _ONE_UNDERLYING_TOKEN) /
                    underlyingPrice;

                data.pendingWithdrawShares = 0;

                updatedWithdrawData = true;
            }
        }

        data.round = _currentRound;
    }

    function _updateUserData(
        address user
    ) private returns (UserData memory data) {
        bool updatedDepositData;
        bool updatedWithdrawData;
        (
            data,
            updatedDepositData,
            updatedWithdrawData
        ) = _updateUserDataInMemory(user);

        if (updatedDepositData) {
            delete _userData[user].pendingDepositAssets;
            _userData[user].unclaimedDepositShares = data
                .unclaimedDepositShares;
        }

        if (updatedWithdrawData) {
            delete _userData[user].pendingWithdrawShares;
            _userData[user].unclaimedWithdrawAssets = data
                .unclaimedWithdrawAssets;
        }

        // save to storage
        _userData[user].round = data.round;
    }

    function emergencyClose() external {
        address _traderWalletAddress = traderWalletAddress;
        if (
            ITraderWallet(_traderWalletAddress).lastRolloverTimestamp() +
                emergencyPeriod >
            block.timestamp &&
            !isEmergencyOpen
        ) revert TooEarly();
        bool isRequestFulfilled = _closeUniswapPositions(_traderWalletAddress);
        _closeGmxPositions(_traderWalletAddress);

        if (!isRequestFulfilled) {
            currentSlippage += slippageStepPercent;
            isEmergencyOpen = true;
        } else {
            currentSlippage = defaultSlippagePercent;
            isEmergencyOpen = false;
        }
    }

    /// return isRequestFulfilled The flag if 'requestedAmount' was fulfilled during closing
    function _closeUniswapPositions(
        address _traderWalletAddress
    ) internal returns (bool isRequestFulfilled) {
        // optimistically set true at start
        isRequestFulfilled = true;

        address[] memory tokens = ITraderWallet(_traderWalletAddress)
            .getAllowedTradeTokens();
        address _underlyingTokenAddress = underlyingTokenAddress;

        // first token in underlying, thus we pass it
        for (uint256 i = 1; i < tokens.length; ++i) {
            uint256 tokenBalance = IERC20Metadata(tokens[i]).balanceOf(
                _traderWalletAddress
            );
            if (tokenBalance > 0) {
                uint256 defaultSwapProtocol = 2; // uniswap
                IAdapter.AdapterOperation memory traderOperation;
                traderOperation.operationId = 1; // sell
                uint24 defaultPoolFee = 3000;
                bytes memory path = abi.encodePacked(
                    tokens[i],
                    defaultPoolFee,
                    _underlyingTokenAddress
                );

                uint256 amountOutMinimum = (_convertTokenAmountToUnderlyingAmount(
                        tokens[i],
                        tokenBalance
                    ) * (10000 - currentSlippage)) / 10000;

                traderOperation.data = abi.encode(
                    path,
                    tokenBalance,
                    amountOutMinimum
                );
                try
                    ITraderWallet(_traderWalletAddress).executeOnProtocol(
                        defaultSwapProtocol,
                        traderOperation,
                        true
                    )
                {
                    continue;
                } catch {
                    // try to swap 30% of initial amount
                    tokenBalance = (tokenBalance * 30) / 100;
                    amountOutMinimum =
                        (_convertTokenAmountToUnderlyingAmount(
                            tokens[i],
                            tokenBalance
                        ) * (10000 - currentSlippage)) /
                        10000;
                    traderOperation.data = abi.encode(
                        path,
                        tokenBalance,
                        amountOutMinimum
                    );
                    isRequestFulfilled = false;

                    try
                        ITraderWallet(_traderWalletAddress).executeOnProtocol(
                            defaultSwapProtocol,
                            traderOperation,
                            true
                        )
                    {} catch {
                        // increase default slippage for next tries
                        emit EmergencyCloseError(tokens[i], tokenBalance);
                    }
                }
            }
        }
        return (isRequestFulfilled);
    }

    function _closeGmxPositions(
        address _traderWalletAddress
    ) internal returns (bool isRequestFulfilled) {
        // optimistically set true at start
        isRequestFulfilled = true;

        address lens = IContractsFactory(contractsFactoryAddress).lensAddress();
        ILens.ProcessedPosition[] memory positions = ILens(lens)
            .getAllPositionsProcessed(_traderWalletAddress);
        if (positions.length == 0) return true; // exit because there are no positions

        address _underlyingTokenAddress = underlyingTokenAddress;
        for (uint256 i = 0; i < positions.length; ++i) {
            IAdapter.AdapterOperation memory traderOperation;
            traderOperation.operationId = 1; // decrease position
            uint256 collateralDelta = 0; // collateralDelta=0 because it doesn't matter when closing FULL position
            uint256 minOut;
            address[] memory path;
            if (positions[i].collateralToken == _underlyingTokenAddress) {
                path = new address[](1);
                path[0] = _underlyingTokenAddress;
            } else {
                path = new address[](2);
                path[0] = positions[i].collateralToken;
                path[1] = _underlyingTokenAddress;
            }
            traderOperation.data = abi.encode(
                path,
                positions[i].indexToken,
                collateralDelta,
                positions[i].size,
                positions[i].isLong,
                minOut
            );
            try
                ITraderWallet(_traderWalletAddress).executeOnProtocol(
                    1, // GMX
                    traderOperation,
                    true // replicate
                )
            {} catch {
                isRequestFulfilled = false;
                emit EmergencyCloseError(
                    positions[i].indexToken,
                    positions[i].size
                );
                continue;
            }
        }
    }

    /// @notice Disable share transfer
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256
    ) internal virtual override {
        if (
            _from != address(0) && 
            _from != address(this) && 
            _to != address(0) && 
            _to != address(this)
        ) revert ShareTransferNotAllowed();
    }
}