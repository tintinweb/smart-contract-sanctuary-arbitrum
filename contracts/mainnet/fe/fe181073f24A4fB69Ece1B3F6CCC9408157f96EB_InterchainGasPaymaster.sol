/**
 *Submitted for verification at Arbiscan.io on 2023-12-12
*/

// SPDX-License-Identifier: MIT OR Apache-2.0
// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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

// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/utils/math/[email protected]

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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;



/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;


/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/utils/introspection/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/crosschain/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/errors.sol)

pragma solidity ^0.8.4;

error NotCrossChainCall();
error InvalidCrossChainSender(address actual, address expected);


// File @openzeppelin/contracts/crosschain/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (crosschain/CrossChainEnabled.sol)

pragma solidity ^0.8.4;

/**
 * @dev Provides information for building cross-chain aware contracts. This
 * abstract contract provides accessors and modifiers to control the execution
 * flow when receiving cross-chain messages.
 *
 * Actual implementations of cross-chain aware contracts, which are based on
 * this abstraction, will  have to inherit from a bridge-specific
 * specialization. Such specializations are provided under
 * `crosschain/<chain>/CrossChainEnabled<chain>.sol`.
 *
 * _Available since v4.6._
 */
abstract contract CrossChainEnabled {
    /**
     * @dev Throws if the current function call is not the result of a
     * cross-chain execution.
     */
    modifier onlyCrossChain() {
        if (!_isCrossChain()) revert NotCrossChainCall();
        _;
    }

    /**
     * @dev Throws if the current function call is not the result of a
     * cross-chain execution initiated by `account`.
     */
    modifier onlyCrossChainSender(address expected) {
        address actual = _crossChainSender();
        if (expected != actual) revert InvalidCrossChainSender(actual, expected);
        _;
    }

    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message.
     */
    function _isCrossChain() internal view virtual returns (bool);

    /**
     * @dev Returns the address of the sender of the cross-chain message that
     * triggered the current function call.
     *
     * IMPORTANT: Should revert with `NotCrossChainCall` if the current function
     * call is not the result of a cross-chain message.
     */
    function _crossChainSender() internal view virtual returns (address);
}


// File @openzeppelin/contracts/crosschain/optimism/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (crosschain/optimism/LibOptimism.sol)

pragma solidity ^0.8.4;


/**
 * @dev Primitives for cross-chain aware contracts for https://www.optimism.io/[Optimism].
 * See the https://community.optimism.io/docs/developers/bridge/messaging/#accessing-msg-sender[documentation]
 * for the functionality used here.
 */
library LibOptimism {
    /**
     * @dev Returns whether the current function call is the result of a
     * cross-chain message relayed by `messenger`.
     */
    function isCrossChain(address messenger) internal view returns (bool) {
        return msg.sender == messenger;
    }

    /**
     * @dev Returns the address of the sender that triggered the current
     * cross-chain message through `messenger`.
     *
     * NOTE: {isCrossChain} should be checked before trying to recover the
     * sender, as it will revert with `NotCrossChainCall` if the current
     * function call is not the result of a cross-chain message.
     */
    function crossChainSender(address messenger) internal view returns (address) {
        if (!isCrossChain(messenger)) revert NotCrossChainCall();

        return ICrossDomainMessenger(messenger).xDomainMessageSender();
    }
}


// File @openzeppelin/contracts/crosschain/optimism/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (crosschain/optimism/CrossChainEnabledOptimism.sol)

pragma solidity ^0.8.4;


/**
 * @dev https://www.optimism.io/[Optimism] specialization or the
 * {CrossChainEnabled} abstraction.
 *
 * The messenger (`CrossDomainMessenger`) contract is provided and maintained by
 * the optimism team. You can find the address of this contract on mainnet and
 * kovan in the https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts/deployments[deployments section of Optimism monorepo].
 *
 * _Available since v4.6._
 */
abstract contract CrossChainEnabledOptimism is CrossChainEnabled {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _messenger;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address messenger) {
        _messenger = messenger;
    }

    /**
     * @dev see {CrossChainEnabled-_isCrossChain}
     */
    function _isCrossChain() internal view virtual override returns (bool) {
        return LibOptimism.isCrossChain(_messenger);
    }

    /**
     * @dev see {CrossChainEnabled-_crossChainSender}
     */
    function _crossChainSender() internal view virtual override onlyCrossChain returns (address) {
        return LibOptimism.crossChainSender(_messenger);
    }
}


// File @openzeppelin/contracts/token/ERC1155/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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


// File @openzeppelin/contracts/governance/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;




/**
 * @dev Contract module which acts as a timelocked controller. When set as the
 * owner of an `Ownable` smart contract, it enforces a timelock on all
 * `onlyOwner` maintenance operations. This gives time for users of the
 * controlled contract to exit before a potentially dangerous maintenance
 * operation is applied.
 *
 * By default, this contract is self administered, meaning administration tasks
 * have to go through the timelock process. The proposer (resp executor) role
 * is in charge of proposing (resp executing) operations. A common use case is
 * to position this {TimelockController} as the owner of a smart contract, with
 * a multisig or a DAO as the sole proposer.
 *
 * _Available since v3.3._
 */
contract TimelockController is AccessControl, IERC721Receiver, IERC1155Receiver {
    bytes32 public constant TIMELOCK_ADMIN_ROLE = keccak256("TIMELOCK_ADMIN_ROLE");
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    bytes32 public constant CANCELLER_ROLE = keccak256("CANCELLER_ROLE");
    uint256 internal constant _DONE_TIMESTAMP = uint256(1);

    mapping(bytes32 => uint256) private _timestamps;
    uint256 private _minDelay;

    /**
     * @dev Emitted when a call is scheduled as part of operation `id`.
     */
    event CallScheduled(
        bytes32 indexed id,
        uint256 indexed index,
        address target,
        uint256 value,
        bytes data,
        bytes32 predecessor,
        uint256 delay
    );

    /**
     * @dev Emitted when a call is performed as part of operation `id`.
     */
    event CallExecuted(bytes32 indexed id, uint256 indexed index, address target, uint256 value, bytes data);

    /**
     * @dev Emitted when operation `id` is cancelled.
     */
    event Cancelled(bytes32 indexed id);

    /**
     * @dev Emitted when the minimum delay for future operations is modified.
     */
    event MinDelayChange(uint256 oldDuration, uint256 newDuration);

    /**
     * @dev Initializes the contract with the following parameters:
     *
     * - `minDelay`: initial minimum delay for operations
     * - `proposers`: accounts to be granted proposer and canceller roles
     * - `executors`: accounts to be granted executor role
     * - `admin`: optional account to be granted admin role; disable with zero address
     *
     * IMPORTANT: The optional admin can aid with initial configuration of roles after deployment
     * without being subject to delay, but this role should be subsequently renounced in favor of
     * administration through timelocked proposals. Previous versions of this contract would assign
     * this admin to the deployer automatically and should be renounced as well.
     */
    constructor(
        uint256 minDelay,
        address[] memory proposers,
        address[] memory executors,
        address admin
    ) {
        _setRoleAdmin(TIMELOCK_ADMIN_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(PROPOSER_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(EXECUTOR_ROLE, TIMELOCK_ADMIN_ROLE);
        _setRoleAdmin(CANCELLER_ROLE, TIMELOCK_ADMIN_ROLE);

        // self administration
        _setupRole(TIMELOCK_ADMIN_ROLE, address(this));

        // optional admin
        if (admin != address(0)) {
            _setupRole(TIMELOCK_ADMIN_ROLE, admin);
        }

        // register proposers and cancellers
        for (uint256 i = 0; i < proposers.length; ++i) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
            _setupRole(CANCELLER_ROLE, proposers[i]);
        }

        // register executors
        for (uint256 i = 0; i < executors.length; ++i) {
            _setupRole(EXECUTOR_ROLE, executors[i]);
        }

        _minDelay = minDelay;
        emit MinDelayChange(0, minDelay);
    }

    /**
     * @dev Modifier to make a function callable only by a certain role. In
     * addition to checking the sender's role, `address(0)` 's role is also
     * considered. Granting a role to `address(0)` is equivalent to enabling
     * this role for everyone.
     */
    modifier onlyRoleOrOpenRole(bytes32 role) {
        if (!hasRole(role, address(0))) {
            _checkRole(role, _msgSender());
        }
        _;
    }

    /**
     * @dev Contract might receive/hold ETH as part of the maintenance process.
     */
    receive() external payable {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AccessControl) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns whether an id correspond to a registered operation. This
     * includes both Pending, Ready and Done operations.
     */
    function isOperation(bytes32 id) public view virtual returns (bool registered) {
        return getTimestamp(id) > 0;
    }

    /**
     * @dev Returns whether an operation is pending or not.
     */
    function isOperationPending(bytes32 id) public view virtual returns (bool pending) {
        return getTimestamp(id) > _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns whether an operation is ready or not.
     */
    function isOperationReady(bytes32 id) public view virtual returns (bool ready) {
        uint256 timestamp = getTimestamp(id);
        return timestamp > _DONE_TIMESTAMP && timestamp <= block.timestamp;
    }

    /**
     * @dev Returns whether an operation is done or not.
     */
    function isOperationDone(bytes32 id) public view virtual returns (bool done) {
        return getTimestamp(id) == _DONE_TIMESTAMP;
    }

    /**
     * @dev Returns the timestamp at with an operation becomes ready (0 for
     * unset operations, 1 for done operations).
     */
    function getTimestamp(bytes32 id) public view virtual returns (uint256 timestamp) {
        return _timestamps[id];
    }

    /**
     * @dev Returns the minimum delay for an operation to become valid.
     *
     * This value can be changed by executing an operation that calls `updateDelay`.
     */
    function getMinDelay() public view virtual returns (uint256 duration) {
        return _minDelay;
    }

    /**
     * @dev Returns the identifier of an operation containing a single
     * transaction.
     */
    function hashOperation(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(target, value, data, predecessor, salt));
    }

    /**
     * @dev Returns the identifier of an operation containing a batch of
     * transactions.
     */
    function hashOperationBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public pure virtual returns (bytes32 hash) {
        return keccak256(abi.encode(targets, values, payloads, predecessor, salt));
    }

    /**
     * @dev Schedule an operation containing a single transaction.
     *
     * Emits a {CallScheduled} event.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        bytes32 id = hashOperation(target, value, data, predecessor, salt);
        _schedule(id, delay);
        emit CallScheduled(id, 0, target, value, data, predecessor, delay);
    }

    /**
     * @dev Schedule an operation containing a batch of transactions.
     *
     * Emits one {CallScheduled} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'proposer' role.
     */
    function scheduleBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt,
        uint256 delay
    ) public virtual onlyRole(PROPOSER_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);
        _schedule(id, delay);
        for (uint256 i = 0; i < targets.length; ++i) {
            emit CallScheduled(id, i, targets[i], values[i], payloads[i], predecessor, delay);
        }
    }

    /**
     * @dev Schedule an operation that is to becomes valid after a given delay.
     */
    function _schedule(bytes32 id, uint256 delay) private {
        require(!isOperation(id), "TimelockController: operation already scheduled");
        require(delay >= getMinDelay(), "TimelockController: insufficient delay");
        _timestamps[id] = block.timestamp + delay;
    }

    /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */
    function cancel(bytes32 id) public virtual onlyRole(CANCELLER_ROLE) {
        require(isOperationPending(id), "TimelockController: operation cannot be cancelled");
        delete _timestamps[id];

        emit Cancelled(id);
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    // This function can reenter, but it doesn't pose a risk because _afterCall checks that the proposal is pending,
    // thus any modifications to the operation during reentrancy should be caught.
    // slither-disable-next-line reentrancy-eth
    function execute(
        address target,
        uint256 value,
        bytes calldata payload,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        bytes32 id = hashOperation(target, value, payload, predecessor, salt);

        _beforeCall(id, predecessor);
        _execute(target, value, payload);
        emit CallExecuted(id, 0, target, value, payload);
        _afterCall(id);
    }

    /**
     * @dev Execute an (ready) operation containing a batch of transactions.
     *
     * Emits one {CallExecuted} event per transaction in the batch.
     *
     * Requirements:
     *
     * - the caller must have the 'executor' role.
     */
    function executeBatch(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata payloads,
        bytes32 predecessor,
        bytes32 salt
    ) public payable virtual onlyRoleOrOpenRole(EXECUTOR_ROLE) {
        require(targets.length == values.length, "TimelockController: length mismatch");
        require(targets.length == payloads.length, "TimelockController: length mismatch");

        bytes32 id = hashOperationBatch(targets, values, payloads, predecessor, salt);

        _beforeCall(id, predecessor);
        for (uint256 i = 0; i < targets.length; ++i) {
            address target = targets[i];
            uint256 value = values[i];
            bytes calldata payload = payloads[i];
            _execute(target, value, payload);
            emit CallExecuted(id, i, target, value, payload);
        }
        _afterCall(id);
    }

    /**
     * @dev Execute an operation's call.
     */
    function _execute(
        address target,
        uint256 value,
        bytes calldata data
    ) internal virtual {
        (bool success, ) = target.call{value: value}(data);
        require(success, "TimelockController: underlying transaction reverted");
    }

    /**
     * @dev Checks before execution of an operation's calls.
     */
    function _beforeCall(bytes32 id, bytes32 predecessor) private view {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        require(predecessor == bytes32(0) || isOperationDone(predecessor), "TimelockController: missing dependency");
    }

    /**
     * @dev Checks after execution of an operation's calls.
     */
    function _afterCall(bytes32 id) private {
        require(isOperationReady(id), "TimelockController: operation is not ready");
        _timestamps[id] = _DONE_TIMESTAMP;
    }

    /**
     * @dev Changes the minimum timelock duration for future operations.
     *
     * Emits a {MinDelayChange} event.
     *
     * Requirements:
     *
     * - the caller must be the timelock itself. This can only be achieved by scheduling and later executing
     * an operation where the timelock is the target and the data is the ABI-encoded call to this function.
     */
    function updateDelay(uint256 newDelay) external virtual {
        require(msg.sender == address(this), "TimelockController: caller must be timelock");
        emit MinDelayChange(_minDelay, newDelay);
        _minDelay = newDelay;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


// File @openzeppelin/contracts/interfaces/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}


// File @openzeppelin/contracts/proxy/beacon/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts/proxy/ERC1967/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;




/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}


// File @openzeppelin/contracts/proxy/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}


// File @openzeppelin/contracts/proxy/ERC1967/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;


/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}


// File @openzeppelin/contracts/proxy/transparent/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}


// File @openzeppelin/contracts/proxy/transparent/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {
    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(
        TransparentUpgradeableProxy proxy,
        address implementation,
        bytes memory data
    ) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/token/ERC721/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts/utils/structs/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}


// File contracts/interfaces/hooks/IPostDispatchHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

interface IPostDispatchHook {
    enum Types {
        UNUSED,
        ROUTING,
        AGGREGATION,
        MERKLE_TREE,
        INTERCHAIN_GAS_PAYMASTER,
        FALLBACK_ROUTING,
        ID_AUTH_ISM,
        PAUSABLE,
        PROTOCOL_FEE
    }

    /**
     * @notice Returns an enum that represents the type of hook
     */
    function hookType() external view returns (uint8);

    /**
     * @notice Returns whether the hook supports metadata
     * @param metadata metadata
     * @return Whether the hook supports metadata
     */
    function supportsMetadata(bytes calldata metadata)
        external
        view
        returns (bool);

    /**
     * @notice Post action after a message is dispatched via the Mailbox
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     */
    function postDispatch(bytes calldata metadata, bytes calldata message)
        external
        payable;

    /**
     * @notice Compute the payment required by the postDispatch call
     * @param metadata The metadata required for the hook
     * @param message The message passed from the Mailbox.dispatch() call
     * @return Quoted payment for the postDispatch call
     */
    function quoteDispatch(bytes calldata metadata, bytes calldata message)
        external
        view
        returns (uint256);
}


// File contracts/interfaces/IInterchainSecurityModule.sol

pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    enum Types {
        UNUSED,
        ROUTING,
        AGGREGATION,
        LEGACY_MULTISIG,
        MERKLE_ROOT_MULTISIG,
        MESSAGE_ID_MULTISIG,
        NULL, // used with relayer carrying no metadata
        CCIP_READ
    }

    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        external
        returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}


// File contracts/interfaces/IMailbox.sol

pragma solidity >=0.8.0;


interface IMailbox {
    // ============ Events ============
    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param sender The address that dispatched the message
     * @param destination The destination domain of the message
     * @param recipient The message recipient address on `destination`
     * @param message Raw bytes of message
     */
    event Dispatch(
        address indexed sender,
        uint32 indexed destination,
        bytes32 indexed recipient,
        bytes message
    );

    /**
     * @notice Emitted when a new message is dispatched via Hyperlane
     * @param messageId The unique message identifier
     */
    event DispatchId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is processed
     * @param messageId The unique message identifier
     */
    event ProcessId(bytes32 indexed messageId);

    /**
     * @notice Emitted when a Hyperlane message is delivered
     * @param origin The origin domain of the message
     * @param sender The message sender address on `origin`
     * @param recipient The address that handled the message
     */
    event Process(
        uint32 indexed origin,
        bytes32 indexed sender,
        address indexed recipient
    );

    function localDomain() external view returns (uint32);

    function delivered(bytes32 messageId) external view returns (bool);

    function defaultIsm() external view returns (IInterchainSecurityModule);

    function defaultHook() external view returns (IPostDispatchHook);

    function latestDispatchedId() external view returns (bytes32);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body,
        bytes calldata defaultHookMetadata
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata defaultHookMetadata
    ) external view returns (uint256 fee);

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body,
        bytes calldata customHookMetadata,
        IPostDispatchHook customHook
    ) external payable returns (bytes32 messageId);

    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata customHookMetadata,
        IPostDispatchHook customHook
    ) external view returns (uint256 fee);

    function process(bytes calldata metadata, bytes calldata message)
        external
        payable;

    function recipientIsm(address recipient)
        external
        view
        returns (IInterchainSecurityModule module);
}


// File contracts/libs/TypeCasts.sol

pragma solidity >=0.6.11;

library TypeCasts {
    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}


// File contracts/libs/Message.sol

pragma solidity >=0.8.0;

/**
 * @title Hyperlane Message Library
 * @notice Library for formatted messages used by Mailbox
 **/
library Message {
    using TypeCasts for bytes32;

    uint256 private constant VERSION_OFFSET = 0;
    uint256 private constant NONCE_OFFSET = 1;
    uint256 private constant ORIGIN_OFFSET = 5;
    uint256 private constant SENDER_OFFSET = 9;
    uint256 private constant DESTINATION_OFFSET = 41;
    uint256 private constant RECIPIENT_OFFSET = 45;
    uint256 private constant BODY_OFFSET = 77;

    /**
     * @notice Returns formatted (packed) Hyperlane message with provided fields
     * @dev This function should only be used in memory message construction.
     * @param _version The version of the origin and destination Mailboxes
     * @param _nonce A nonce to uniquely identify the message on its origin chain
     * @param _originDomain Domain of origin chain
     * @param _sender Address of sender as bytes32
     * @param _destinationDomain Domain of destination chain
     * @param _recipient Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes of message body
     * @return Formatted message
     */
    function formatMessage(
        uint8 _version,
        uint32 _nonce,
        uint32 _originDomain,
        bytes32 _sender,
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes calldata _messageBody
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _version,
                _nonce,
                _originDomain,
                _sender,
                _destinationDomain,
                _recipient,
                _messageBody
            );
    }

    /**
     * @notice Returns the message ID.
     * @param _message ABI encoded Hyperlane message.
     * @return ID of `_message`
     */
    function id(bytes memory _message) internal pure returns (bytes32) {
        return keccak256(_message);
    }

    /**
     * @notice Returns the message version.
     * @param _message ABI encoded Hyperlane message.
     * @return Version of `_message`
     */
    function version(bytes calldata _message) internal pure returns (uint8) {
        return uint8(bytes1(_message[VERSION_OFFSET:NONCE_OFFSET]));
    }

    /**
     * @notice Returns the message nonce.
     * @param _message ABI encoded Hyperlane message.
     * @return Nonce of `_message`
     */
    function nonce(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[NONCE_OFFSET:ORIGIN_OFFSET]));
    }

    /**
     * @notice Returns the message origin domain.
     * @param _message ABI encoded Hyperlane message.
     * @return Origin domain of `_message`
     */
    function origin(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[ORIGIN_OFFSET:SENDER_OFFSET]));
    }

    /**
     * @notice Returns the message sender as bytes32.
     * @param _message ABI encoded Hyperlane message.
     * @return Sender of `_message` as bytes32
     */
    function sender(bytes calldata _message) internal pure returns (bytes32) {
        return bytes32(_message[SENDER_OFFSET:DESTINATION_OFFSET]);
    }

    /**
     * @notice Returns the message sender as address.
     * @param _message ABI encoded Hyperlane message.
     * @return Sender of `_message` as address
     */
    function senderAddress(bytes calldata _message)
        internal
        pure
        returns (address)
    {
        return sender(_message).bytes32ToAddress();
    }

    /**
     * @notice Returns the message destination domain.
     * @param _message ABI encoded Hyperlane message.
     * @return Destination domain of `_message`
     */
    function destination(bytes calldata _message)
        internal
        pure
        returns (uint32)
    {
        return uint32(bytes4(_message[DESTINATION_OFFSET:RECIPIENT_OFFSET]));
    }

    /**
     * @notice Returns the message recipient as bytes32.
     * @param _message ABI encoded Hyperlane message.
     * @return Recipient of `_message` as bytes32
     */
    function recipient(bytes calldata _message)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(_message[RECIPIENT_OFFSET:BODY_OFFSET]);
    }

    /**
     * @notice Returns the message recipient as address.
     * @param _message ABI encoded Hyperlane message.
     * @return Recipient of `_message` as address
     */
    function recipientAddress(bytes calldata _message)
        internal
        pure
        returns (address)
    {
        return recipient(_message).bytes32ToAddress();
    }

    /**
     * @notice Returns the message body.
     * @param _message ABI encoded Hyperlane message.
     * @return Body of `_message`
     */
    function body(bytes calldata _message)
        internal
        pure
        returns (bytes calldata)
    {
        return bytes(_message[BODY_OFFSET:]);
    }
}


// File contracts/client/MailboxClient.sol

pragma solidity >=0.6.11;

// ============ Internal Imports ============




// ============ External Imports ============


abstract contract MailboxClient is OwnableUpgradeable {
    using Message for bytes;

    IMailbox public immutable mailbox;

    uint32 public immutable localDomain;

    IPostDispatchHook public hook;

    IInterchainSecurityModule public interchainSecurityModule;

    // ============ Modifiers ============
    modifier onlyContract(address _contract) {
        require(
            Address.isContract(_contract),
            "MailboxClient: invalid mailbox"
        );
        _;
    }

    modifier onlyContractOrNull(address _contract) {
        require(
            Address.isContract(_contract) || _contract == address(0),
            "MailboxClient: invalid contract setting"
        );
        _;
    }

    /**
     * @notice Only accept messages from an Hyperlane Mailbox contract
     */
    modifier onlyMailbox() {
        require(
            msg.sender == address(mailbox),
            "MailboxClient: sender not mailbox"
        );
        _;
    }

    constructor(address _mailbox) onlyContract(_mailbox) {
        mailbox = IMailbox(_mailbox);
        localDomain = mailbox.localDomain();
        _transferOwnership(msg.sender);
    }

    /**
     * @notice Sets the address of the application's custom hook.
     * @param _hook The address of the hook contract.
     */
    function setHook(address _hook) public onlyContractOrNull(_hook) onlyOwner {
        hook = IPostDispatchHook(_hook);
    }

    /**
     * @notice Sets the address of the application's custom interchain security module.
     * @param _module The address of the interchain security module contract.
     */
    function setInterchainSecurityModule(address _module)
        public
        onlyContractOrNull(_module)
        onlyOwner
    {
        interchainSecurityModule = IInterchainSecurityModule(_module);
    }

    // ======== Initializer =========
    function _MailboxClient_initialize(
        address _hook,
        address _interchainSecurityModule,
        address _owner
    ) internal onlyInitializing {
        __Ownable_init();
        setHook(_hook);
        setInterchainSecurityModule(_interchainSecurityModule);
        _transferOwnership(_owner);
    }

    function _isLatestDispatched(bytes32 id) internal view returns (bool) {
        return mailbox.latestDispatchedId() == id;
    }

    function _metadata(
        uint32 /*_destinationDomain*/
    ) internal view virtual returns (bytes memory) {
        return "";
    }

    function _dispatch(
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        return
            _dispatch(_destinationDomain, _recipient, msg.value, _messageBody);
    }

    function _dispatch(
        uint32 _destinationDomain,
        bytes32 _recipient,
        uint256 _value,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        return
            mailbox.dispatch{value: _value}(
                _destinationDomain,
                _recipient,
                _messageBody,
                _metadata(_destinationDomain),
                hook
            );
    }

    function _quoteDispatch(
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes memory _messageBody
    ) internal view virtual returns (uint256) {
        return
            mailbox.quoteDispatch(
                _destinationDomain,
                _recipient,
                _messageBody,
                _metadata(_destinationDomain),
                hook
            );
    }
}


// File contracts/hooks/libs/StandardHookMetadata.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

/**
 * Format of metadata:
 *
 * [0:1] variant
 * [2:33] msg.value
 * [34:65] Gas limit for message (IGP)
 * [66:85] Refund address for message (IGP)
 * [86:] Custom metadata
 */
library StandardHookMetadata {
    uint8 private constant VARIANT_OFFSET = 0;
    uint8 private constant MSG_VALUE_OFFSET = 2;
    uint8 private constant GAS_LIMIT_OFFSET = 34;
    uint8 private constant REFUND_ADDRESS_OFFSET = 66;
    uint256 private constant MIN_METADATA_LENGTH = 86;

    uint16 public constant VARIANT = 1;

    /**
     * @notice Returns the variant of the metadata.
     * @param _metadata ABI encoded global hook metadata.
     * @return variant of the metadata as uint8.
     */
    function variant(bytes calldata _metadata) internal pure returns (uint16) {
        if (_metadata.length < VARIANT_OFFSET + 2) return 0;
        return uint16(bytes2(_metadata[VARIANT_OFFSET:VARIANT_OFFSET + 2]));
    }

    /**
     * @notice Returns the specified value for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @param _default Default fallback value.
     * @return Value for the message as uint256.
     */
    function msgValue(bytes calldata _metadata, uint256 _default)
        internal
        pure
        returns (uint256)
    {
        if (_metadata.length < MSG_VALUE_OFFSET + 32) return _default;
        return
            uint256(bytes32(_metadata[MSG_VALUE_OFFSET:MSG_VALUE_OFFSET + 32]));
    }

    /**
     * @notice Returns the specified gas limit for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @param _default Default fallback gas limit.
     * @return Gas limit for the message as uint256.
     */
    function gasLimit(bytes calldata _metadata, uint256 _default)
        internal
        pure
        returns (uint256)
    {
        if (_metadata.length < GAS_LIMIT_OFFSET + 32) return _default;
        return
            uint256(bytes32(_metadata[GAS_LIMIT_OFFSET:GAS_LIMIT_OFFSET + 32]));
    }

    /**
     * @notice Returns the specified refund address for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @param _default Default fallback refund address.
     * @return Refund address for the message as address.
     */
    function refundAddress(bytes calldata _metadata, address _default)
        internal
        pure
        returns (address)
    {
        if (_metadata.length < REFUND_ADDRESS_OFFSET + 20) return _default;
        return
            address(
                bytes20(
                    _metadata[REFUND_ADDRESS_OFFSET:REFUND_ADDRESS_OFFSET + 20]
                )
            );
    }

    /**
     * @notice Returns the specified refund address for the message.
     * @param _metadata ABI encoded global hook metadata.
     * @return Refund address for the message as address.
     */
    function getCustomMetadata(bytes calldata _metadata)
        internal
        pure
        returns (bytes calldata)
    {
        if (_metadata.length < MIN_METADATA_LENGTH) return _metadata[0:0];
        return _metadata[MIN_METADATA_LENGTH:];
    }

    /**
     * @notice Formats the specified gas limit and refund address into global hook metadata.
     * @param _msgValue msg.value for the message.
     * @param _gasLimit Gas limit for the message.
     * @param _refundAddress Refund address for the message.
     * @param _customMetadata Additional metadata to include in the global hook metadata.
     * @return ABI encoded global hook metadata.
     */
    function formatMetadata(
        uint256 _msgValue,
        uint256 _gasLimit,
        address _refundAddress,
        bytes memory _customMetadata
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                VARIANT,
                _msgValue,
                _gasLimit,
                _refundAddress,
                _customMetadata
            );
    }

    /**
     * @notice Formats the specified gas limit and refund address into global hook metadata.
     * @param _msgValue msg.value for the message.
     * @return ABI encoded global hook metadata.
     */
    function formatMetadata(uint256 _msgValue)
        internal
        view
        returns (bytes memory)
    {
        return formatMetadata(_msgValue, uint256(0), msg.sender, "");
    }

    /**
     * @notice Formats the specified gas limit and refund address into global hook metadata.
     * @param _gasLimit Gas limit for the message.
     * @param _refundAddress Refund address for the message.
     * @return ABI encoded global hook metadata.
     */
    function formatMetadata(uint256 _gasLimit, address _refundAddress)
        internal
        pure
        returns (bytes memory)
    {
        return formatMetadata(uint256(0), _gasLimit, _refundAddress, "");
    }
}


// File contracts/interfaces/IMessageRecipient.sol

pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable;
}


// File contracts/libs/EnumerableMapExtended.sol

pragma solidity >=0.6.11;

// ============ External Imports ============


// extends EnumerableMap with uint256 => bytes32 type
// modelled after https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/structs/EnumerableMap.sol
library EnumerableMapExtended {
    using EnumerableMap for EnumerableMap.Bytes32ToBytes32Map;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct UintToBytes32Map {
        EnumerableMap.Bytes32ToBytes32Map _inner;
    }

    // ============ Library Functions ============
    function keys(UintToBytes32Map storage map)
        internal
        view
        returns (uint256[] memory _keys)
    {
        uint256 _length = map._inner.length();
        _keys = new uint256[](_length);
        for (uint256 i = 0; i < _length; i++) {
            _keys[i] = uint256(map._inner._keys.at(i));
        }
    }

    function uint32Keys(UintToBytes32Map storage map)
        internal
        view
        returns (uint32[] memory _keys)
    {
        uint256[] memory uint256keys = keys(map);
        _keys = new uint32[](uint256keys.length);
        for (uint256 i = 0; i < uint256keys.length; i++) {
            _keys[i] = uint32(uint256keys[i]);
        }
    }

    function set(
        UintToBytes32Map storage map,
        uint256 key,
        bytes32 value
    ) internal {
        map._inner.set(bytes32(key), value);
    }

    function get(UintToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bytes32)
    {
        return map._inner.get(bytes32(key));
    }

    function tryGet(UintToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bool, bytes32)
    {
        return map._inner.tryGet(bytes32(key));
    }

    function remove(UintToBytes32Map storage map, uint256 key)
        internal
        returns (bool)
    {
        return map._inner.remove(bytes32(key));
    }

    function contains(UintToBytes32Map storage map, uint256 key)
        internal
        view
        returns (bool)
    {
        return map._inner.contains(bytes32(key));
    }

    function length(UintToBytes32Map storage map)
        internal
        view
        returns (uint256)
    {
        return map._inner.length();
    }

    function at(UintToBytes32Map storage map, uint256 index)
        internal
        view
        returns (uint256, bytes32)
    {
        (bytes32 key, bytes32 value) = map._inner.at(index);
        return (uint256(key), value);
    }
}


// File contracts/client/Router.sol

pragma solidity >=0.6.11;

// ============ Internal Imports ============






// ============ External Imports ============

abstract contract Router is MailboxClient, IMessageRecipient {
    using EnumerableMapExtended for EnumerableMapExtended.UintToBytes32Map;
    using Strings for uint32;

    // ============ Mutable Storage ============
    EnumerableMapExtended.UintToBytes32Map internal _routers;

    uint256[48] private __GAP; // gap for upgrade safety

    constructor(address _mailbox) MailboxClient(_mailbox) {}

    // ============ External functions ============
    function domains() external view returns (uint32[] memory) {
        return _routers.uint32Keys();
    }

    /**
     * @notice Returns the address of the Router contract for the given domain
     * @param _domain The remote domain ID.
     * @dev Returns 0 address if no router is enrolled for the given domain
     * @return router The address of the Router contract for the given domain
     */
    function routers(uint32 _domain) public view virtual returns (bytes32) {
        (, bytes32 _router) = _routers.tryGet(_domain);
        return _router;
    }

    /**
     * @notice Unregister the domain
     * @param _domain The domain of the remote Application Router
     */
    function unenrollRemoteRouter(uint32 _domain) external virtual onlyOwner {
        _unenrollRemoteRouter(_domain);
    }

    /**
     * @notice Register the address of a Router contract for the same Application on a remote chain
     * @param _domain The domain of the remote Application Router
     * @param _router The address of the remote Application Router
     */
    function enrollRemoteRouter(uint32 _domain, bytes32 _router)
        external
        virtual
        onlyOwner
    {
        _enrollRemoteRouter(_domain, _router);
    }

    /**
     * @notice Batch version of `enrollRemoteRouter`
     * @param _domains The domains of the remote Application Routers
     * @param _addresses The addresses of the remote Application Routers
     */
    function enrollRemoteRouters(
        uint32[] calldata _domains,
        bytes32[] calldata _addresses
    ) external virtual onlyOwner {
        require(_domains.length == _addresses.length, "!length");
        uint256 length = _domains.length;
        for (uint256 i = 0; i < length; i += 1) {
            _enrollRemoteRouter(_domains[i], _addresses[i]);
        }
    }

    /**
     * @notice Batch version of `unenrollRemoteRouter`
     * @param _domains The domains of the remote Application Routers
     */
    function unenrollRemoteRouters(uint32[] calldata _domains)
        external
        virtual
        onlyOwner
    {
        uint256 length = _domains.length;
        for (uint256 i = 0; i < length; i += 1) {
            _unenrollRemoteRouter(_domains[i]);
        }
    }

    /**
     * @notice Handles an incoming message
     * @param _origin The origin domain
     * @param _sender The sender address
     * @param _message The message
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable virtual override onlyMailbox {
        bytes32 _router = _mustHaveRemoteRouter(_origin);
        require(_router == _sender, "Enrolled router does not match sender");
        _handle(_origin, _sender, _message);
    }

    // ============ Virtual functions ============
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal virtual;

    // ============ Internal functions ============

    /**
     * @notice Set the router for a given domain
     * @param _domain The domain
     * @param _address The new router
     */
    function _enrollRemoteRouter(uint32 _domain, bytes32 _address)
        internal
        virtual
    {
        _routers.set(_domain, _address);
    }

    /**
     * @notice Remove the router for a given domain
     * @param _domain The domain
     */
    function _unenrollRemoteRouter(uint32 _domain) internal virtual {
        require(_routers.remove(_domain), _domainNotFoundError(_domain));
    }

    /**
     * @notice Return true if the given domain / router is the address of a remote Application Router
     * @param _domain The domain of the potential remote Application Router
     * @param _address The address of the potential remote Application Router
     */
    function _isRemoteRouter(uint32 _domain, bytes32 _address)
        internal
        view
        returns (bool)
    {
        return routers(_domain) == _address;
    }

    /**
     * @notice Assert that the given domain has a Application Router registered and return its address
     * @param _domain The domain of the chain for which to get the Application Router
     * @return _router The address of the remote Application Router on _domain
     */
    function _mustHaveRemoteRouter(uint32 _domain)
        internal
        view
        returns (bytes32)
    {
        (bool contained, bytes32 _router) = _routers.tryGet(_domain);
        require(contained, _domainNotFoundError(_domain));
        return _router;
    }

    function _domainNotFoundError(uint32 _domain)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "No router enrolled for domain: ",
                _domain.toString()
            );
    }

    function _dispatch(uint32 _destinationDomain, bytes memory _messageBody)
        internal
        virtual
        returns (bytes32)
    {
        return _dispatch(_destinationDomain, msg.value, _messageBody);
    }

    function _dispatch(
        uint32 _destinationDomain,
        uint256 _value,
        bytes memory _messageBody
    ) internal virtual returns (bytes32) {
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return
            super._dispatch(_destinationDomain, _router, _value, _messageBody);
    }

    function _quoteDispatch(
        uint32 _destinationDomain,
        bytes memory _messageBody
    ) internal view virtual returns (uint256) {
        bytes32 _router = _mustHaveRemoteRouter(_destinationDomain);
        return super._quoteDispatch(_destinationDomain, _router, _messageBody);
    }
}


// File contracts/client/GasRouter.sol

pragma solidity >=0.6.11;


abstract contract GasRouter is Router {
    // ============ Mutable Storage ============
    mapping(uint32 => uint256) public destinationGas;

    struct GasRouterConfig {
        uint32 domain;
        uint256 gas;
    }

    constructor(address _mailbox) Router(_mailbox) {}

    /**
     * @notice Sets the gas amount dispatched for each configured domain.
     * @param gasConfigs The array of GasRouterConfig structs
     */
    function setDestinationGas(GasRouterConfig[] calldata gasConfigs)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < gasConfigs.length; i += 1) {
            _setDestinationGas(gasConfigs[i].domain, gasConfigs[i].gas);
        }
    }

    /**
     * @notice Sets the gas amount dispatched for each configured domain.
     * @param domain The destination domain ID
     * @param gas The gas limit
     */
    function setDestinationGas(uint32 domain, uint256 gas) external onlyOwner {
        _setDestinationGas(domain, gas);
    }

    /**
     * @notice Returns the gas payment required to dispatch a message to the given domain's router.
     * @param _destinationDomain The domain of the router.
     * @return _gasPayment Payment computed by the registered InterchainGasPaymaster.
     */
    function quoteGasPayment(uint32 _destinationDomain)
        external
        view
        returns (uint256 _gasPayment)
    {
        return _quoteDispatch(_destinationDomain, "");
    }

    function _refundAddress(uint32) internal view virtual returns (address) {
        return msg.sender;
    }

    function _metadata(uint32 _destination)
        internal
        view
        virtual
        override
        returns (bytes memory)
    {
        return
            StandardHookMetadata.formatMetadata(
                destinationGas[_destination],
                _refundAddress(_destination)
            );
    }

    function _setDestinationGas(uint32 domain, uint256 gas) internal {
        destinationGas[domain] = gas;
    }
}


// File contracts/hooks/libs/AbstractPostDispatchHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============


/**
 * @title AbstractPostDispatch
 * @notice Abstract post dispatch hook supporting the current global hook metadata variant.
 */
abstract contract AbstractPostDispatchHook is IPostDispatchHook {
    using StandardHookMetadata for bytes;

    // ============ External functions ============

    /// @inheritdoc IPostDispatchHook
    function supportsMetadata(bytes calldata metadata)
        public
        pure
        virtual
        override
        returns (bool)
    {
        return
            metadata.length == 0 ||
            metadata.variant() == StandardHookMetadata.VARIANT;
    }

    /// @inheritdoc IPostDispatchHook
    function postDispatch(bytes calldata metadata, bytes calldata message)
        external
        payable
        override
    {
        require(
            supportsMetadata(metadata),
            "AbstractPostDispatchHook: invalid metadata variant"
        );
        _postDispatch(metadata, message);
    }

    /// @inheritdoc IPostDispatchHook
    function quoteDispatch(bytes calldata metadata, bytes calldata message)
        public
        view
        override
        returns (uint256)
    {
        require(
            supportsMetadata(metadata),
            "AbstractPostDispatchHook: invalid metadata variant"
        );
        return _quoteDispatch(metadata, message);
    }

    // ============ Internal functions ============

    /**
     * @notice Post dispatch hook implementation.
     * @param metadata The metadata of the message being dispatched.
     * @param message The message being dispatched.
     */
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        virtual;

    /**
     * @notice Quote dispatch hook implementation.
     * @param metadata The metadata of the message being dispatched.
     * @param message The message being dispatched.
     * @return The quote for the dispatch.
     */
    function _quoteDispatch(bytes calldata metadata, bytes calldata message)
        internal
        view
        virtual
        returns (uint256);
}


// File contracts/libs/LibBit.sol

pragma solidity >=0.8.0;

/// @notice Library for bit shifting and masking
library LibBit {
    function setBit(uint256 _value, uint256 _index)
        internal
        pure
        returns (uint256)
    {
        return _value | (1 << _index);
    }

    function clearBit(uint256 _value, uint256 _index)
        internal
        pure
        returns (uint256)
    {
        return _value & ~(1 << _index);
    }

    function isBitSet(uint256 _value, uint256 _index)
        internal
        pure
        returns (bool)
    {
        return (_value >> _index) & 1 == 1;
    }
}


// File contracts/isms/hook/AbstractMessageIdAuthorizedIsm.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============



// ============ External Imports ============



/**
 * @title AbstractMessageIdAuthorizedIsm
 * @notice Uses external verfication options to verify interchain messages which need a authorized caller
 */
abstract contract AbstractMessageIdAuthorizedIsm is
    IInterchainSecurityModule,
    Initializable
{
    using Address for address payable;
    using LibBit for uint256;
    using Message for bytes;
    // ============ Public Storage ============

    /// @notice Maps messageId to whether or not the message has been verified
    /// first bit is boolean for verification
    /// rest of bits is the amount to send to the recipient
    /// @dev bc of the bit packing, we can only send up to 2^255 wei
    /// @dev the first bit is reserved for verification and the rest 255 bits are for the msg.value
    mapping(bytes32 => uint256) public verifiedMessages;
    /// @notice Index of verification bit in verifiedMessages
    uint256 public constant VERIFIED_MASK_INDEX = 255;
    /// @notice address for the authorized hook
    bytes32 public authorizedHook;

    // ============ Events ============

    /// @notice Emitted when a message is received from the external bridge
    event ReceivedMessage(bytes32 indexed messageId);

    // ============ Initializer ============

    function setAuthorizedHook(bytes32 _hook) external initializer {
        require(
            _hook != bytes32(0),
            "AbstractMessageIdAuthorizedIsm: invalid authorized hook"
        );
        authorizedHook = _hook;
    }

    // ============ External Functions ============

    /**
     * @notice Verify a message was received by ISM.
     * @param message Message to verify.
     */
    function verify(
        bytes calldata,
        /*_metadata*/
        bytes calldata message
    ) external returns (bool) {
        bytes32 messageId = message.id();

        // check for the first bit (used for verification)
        bool verified = verifiedMessages[messageId].isBitSet(
            VERIFIED_MASK_INDEX
        );
        // rest 255 bits contains the msg.value passed from the hook
        if (verified) {
            uint256 _msgValue = verifiedMessages[messageId].clearBit(
                VERIFIED_MASK_INDEX
            );
            if (_msgValue > 0) {
                verifiedMessages[messageId] -= _msgValue;
                payable(message.recipientAddress()).sendValue(_msgValue);
            }
        }
        return verified;
    }

    /**
     * @notice Receive a message from the AbstractMessageIdAuthHook
     * @dev Only callable by the authorized hook.
     * @param messageId Hyperlane Id of the message.
     */
    function verifyMessageId(bytes32 messageId) external payable virtual {
        require(
            _isAuthorized(),
            "AbstractMessageIdAuthorizedIsm: sender is not the hook"
        );
        require(
            msg.value < 2**VERIFIED_MASK_INDEX,
            "AbstractMessageIdAuthorizedIsm: msg.value must be less than 2^255"
        );

        verifiedMessages[messageId] = msg.value.setBit(VERIFIED_MASK_INDEX);
        emit ReceivedMessage(messageId);
    }

    function _isAuthorized() internal view virtual returns (bool);
}


// File contracts/hooks/libs/AbstractMessageIdAuthHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============







/**
 * @title AbstractMessageIdAuthHook
 * @notice Message hook to inform an Abstract Message ID ISM of messages published through
 * a third-party bridge.
 */
abstract contract AbstractMessageIdAuthHook is
    AbstractPostDispatchHook,
    MailboxClient
{
    using StandardHookMetadata for bytes;
    using Message for bytes;

    // ============ Constants ============

    // left-padded address for ISM to verify messages
    bytes32 public immutable ism;
    // Domain of chain on which the ISM is deployed
    uint32 public immutable destinationDomain;

    // ============ Constructor ============

    constructor(
        address _mailbox,
        uint32 _destinationDomain,
        bytes32 _ism
    ) MailboxClient(_mailbox) {
        require(_ism != bytes32(0), "AbstractMessageIdAuthHook: invalid ISM");
        require(
            _destinationDomain != 0,
            "AbstractMessageIdAuthHook: invalid destination domain"
        );
        ism = _ism;
        destinationDomain = _destinationDomain;
    }

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure returns (uint8) {
        return uint8(IPostDispatchHook.Types.ID_AUTH_ISM);
    }

    // ============ Internal functions ============

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        override
    {
        bytes32 id = message.id();
        require(
            _isLatestDispatched(id),
            "AbstractMessageIdAuthHook: message not latest dispatched"
        );
        require(
            message.destination() == destinationDomain,
            "AbstractMessageIdAuthHook: invalid destination domain"
        );
        bytes memory payload = abi.encodeCall(
            AbstractMessageIdAuthorizedIsm.verifyMessageId,
            id
        );
        _sendMessageId(metadata, payload);
    }

    /**
     * @notice Send a message to the ISM.
     * @param metadata The metadata for the hook caller
     * @param payload The payload for call to the ISM
     */
    function _sendMessageId(bytes calldata metadata, bytes memory payload)
        internal
        virtual;
}


// File contracts/interfaces/hooks/IMessageDispatcher.sol

pragma solidity >=0.8.0;

/**
 * @title ERC-5164: Cross-Chain Execution Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IMessageDispatcher {
    /**
     * @notice Emitted when a message has successfully been dispatched to the executor chain.
     * @param messageId ID uniquely identifying the message
     * @param from Address that dispatched the message
     * @param toChainId ID of the chain receiving the message
     * @param to Address that will receive the message
     * @param data Data that was dispatched
     */
    event MessageDispatched(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed toChainId,
        address to,
        bytes data
    );

    function dispatchMessage(
        uint256 toChainId,
        address to,
        bytes calldata data
    ) external returns (bytes32);
}


// File contracts/hooks/aggregation/ERC5164Hook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============




// ============ External Imports ============

/**
 * @title 5164MessageHook
 * @notice Message hook to inform the 5164 ISM of messages published through
 * any of the 5164 adapters.
 */
contract ERC5164Hook is AbstractMessageIdAuthHook {
    IMessageDispatcher public immutable dispatcher;

    constructor(
        address _mailbox,
        uint32 _destinationDomain,
        bytes32 _ism,
        address _dispatcher
    ) AbstractMessageIdAuthHook(_mailbox, _destinationDomain, _ism) {
        require(
            Address.isContract(_dispatcher),
            "ERC5164Hook: invalid dispatcher"
        );
        dispatcher = IMessageDispatcher(_dispatcher);
    }

    // ============ Internal Functions ============

    function _quoteDispatch(bytes calldata, bytes calldata)
        internal
        pure
        override
        returns (uint256)
    {
        return 0; // EIP-5164 doesn't enforce a gas abstraction
    }

    function _sendMessageId(
        bytes calldata,
        /* metadata */
        bytes memory payload
    ) internal override {
        require(msg.value == 0, "ERC5164Hook: no value allowed");
        dispatcher.dispatchMessage(
            destinationDomain,
            TypeCasts.bytes32ToAddress(ism),
            payload
        );
    }
}


// File contracts/libs/MetaProxy.sol

pragma solidity >=0.7.6;

/// @dev Adapted from https://eips.ethereum.org/EIPS/eip-3448
library MetaProxy {
    bytes32 private constant PREFIX =
        hex"600b380380600b3d393df3363d3d373d3d3d3d60368038038091363936013d73";
    bytes13 private constant SUFFIX = hex"5af43d3d93803e603457fd5bf3";

    function bytecode(address _implementation, bytes memory _metadata)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                PREFIX,
                bytes20(_implementation),
                SUFFIX,
                _metadata,
                _metadata.length
            );
    }

    function metadata() internal pure returns (bytes memory) {
        bytes memory data;
        assembly {
            let posOfMetadataSize := sub(calldatasize(), 32)
            let size := calldataload(posOfMetadataSize)
            let dataPtr := sub(posOfMetadataSize, size)
            data := mload(64)
            // increment free memory pointer by metadata size + 32 bytes (length)
            mstore(64, add(data, add(size, 32)))
            mstore(data, size)
            let memPtr := add(data, 32)
            calldatacopy(memPtr, dataPtr, size)
        }
        return data;
    }
}


// File contracts/hooks/aggregation/StaticAggregationHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/




contract StaticAggregationHook is AbstractPostDispatchHook {
    using StandardHookMetadata for bytes;

    // ============ External functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.AGGREGATION);
    }

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        override
    {
        address[] memory _hooks = hooks(message);
        uint256 count = _hooks.length;
        for (uint256 i = 0; i < count; i++) {
            uint256 quote = IPostDispatchHook(_hooks[i]).quoteDispatch(
                metadata,
                message
            );

            IPostDispatchHook(_hooks[i]).postDispatch{value: quote}(
                metadata,
                message
            );
        }
    }

    /// @inheritdoc AbstractPostDispatchHook
    function _quoteDispatch(bytes calldata metadata, bytes calldata message)
        internal
        view
        override
        returns (uint256)
    {
        address[] memory _hooks = hooks(message);
        uint256 count = _hooks.length;
        uint256 total = 0;
        for (uint256 i = 0; i < count; i++) {
            total += IPostDispatchHook(_hooks[i]).quoteDispatch(
                metadata,
                message
            );
        }
        return total;
    }

    function hooks(bytes calldata) public pure returns (address[] memory) {
        return abi.decode(MetaProxy.metadata(), (address[]));
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}


// File contracts/libs/StaticAddressSetFactory.sol

pragma solidity >=0.8.0;
// ============ External Imports ============


// ============ Internal Imports ============

abstract contract StaticThresholdAddressSetFactory {
    // ============ Immutables ============
    address public immutable implementation;

    // ============ Constructor ============

    constructor() {
        implementation = _deployImplementation();
    }

    function _deployImplementation() internal virtual returns (address);

    /**
     * @notice Deploys a StaticThresholdAddressSet contract address for the given
     * values
     * @dev Consider sorting addresses to ensure contract reuse
     * @param _values An array of addresses
     * @param _threshold The threshold value to use
     * @return set The contract address representing this StaticThresholdAddressSet
     */
    function deploy(address[] calldata _values, uint8 _threshold)
        public
        returns (address)
    {
        (bytes32 _salt, bytes memory _bytecode) = _saltAndBytecode(
            _values,
            _threshold
        );
        address _set = _getAddress(_salt, _bytecode);
        if (!Address.isContract(_set)) {
            _set = Create2.deploy(0, _salt, _bytecode);
        }
        return _set;
    }

    /**
     * @notice Returns the StaticThresholdAddressSet contract address for the given
     * values
     * @dev Consider sorting addresses to ensure contract reuse
     * @param _values An array of addresses
     * @param _threshold The threshold value to use
     * @return set The contract address representing this StaticThresholdAddressSet
     */
    function getAddress(address[] calldata _values, uint8 _threshold)
        external
        view
        returns (address)
    {
        (bytes32 _salt, bytes memory _bytecode) = _saltAndBytecode(
            _values,
            _threshold
        );
        return _getAddress(_salt, _bytecode);
    }

    /**
     * @notice Returns the StaticThresholdAddressSet contract address for the given
     * values
     * @param _salt The salt used in Create2
     * @param _bytecode The metaproxy bytecode used in Create2
     * @return set The contract address representing this StaticThresholdAddressSet
     */
    function _getAddress(bytes32 _salt, bytes memory _bytecode)
        internal
        view
        returns (address)
    {
        bytes32 _bytecodeHash = keccak256(_bytecode);
        return Create2.computeAddress(_salt, _bytecodeHash);
    }

    /**
     * @notice Returns the create2 salt and bytecode for the given values
     * @param _values An array of addresses
     * @param _threshold The threshold value to use
     * @return _salt The salt used in Create2
     * @return _bytecode The metaproxy bytecode used in Create2
     */
    function _saltAndBytecode(address[] calldata _values, uint8 _threshold)
        internal
        view
        returns (bytes32, bytes memory)
    {
        bytes memory _metadata = abi.encode(_values, _threshold);
        bytes memory _bytecode = MetaProxy.bytecode(implementation, _metadata);
        bytes32 _salt = keccak256(_metadata);
        return (_salt, _bytecode);
    }
}

abstract contract StaticAddressSetFactory is StaticThresholdAddressSetFactory {
    /**
     * @notice Deploys a StaticAddressSet contract address for the given
     * values
     * @dev Consider sorting addresses to ensure contract reuse
     * @param _values An array of addresses
     * @return set The contract address representing this StaticAddressSet
     */
    function deploy(address[] calldata _values) external returns (address) {
        return super.deploy(_values, uint8(_values.length));
    }

    /**
     * @notice Returns the StaticAddressSet contract address for the given
     * values
     * @dev Consider sorting addresses to ensure contract reuse
     * @param _values An array of addresses
     * @return set The contract address representing this StaticAddressSet
     */
    function getAddress(address[] calldata _values)
        external
        view
        returns (address)
    {
        (bytes32 _salt, bytes memory _bytecode) = _saltAndBytecode(
            _values,
            uint8(_values.length)
        );
        return super._getAddress(_salt, _bytecode);
    }
}


// File contracts/hooks/aggregation/StaticAggregationHookFactory.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============


contract StaticAggregationHookFactory is StaticAddressSetFactory {
    function _deployImplementation()
        internal
        virtual
        override
        returns (address)
    {
        return address(new StaticAggregationHook());
    }
}


// File contracts/interfaces/IGasOracle.sol

pragma solidity >=0.8.0;

interface IGasOracle {
    struct RemoteGasData {
        // The exchange rate of the remote native token quoted in the local native token.
        // Scaled with 10 decimals, i.e. 1e10 is "one".
        uint128 tokenExchangeRate;
        uint128 gasPrice;
    }

    function getExchangeRateAndGasPrice(uint32 _destinationDomain)
        external
        view
        returns (uint128 tokenExchangeRate, uint128 gasPrice);
}


// File contracts/interfaces/IInterchainGasPaymaster.sol

pragma solidity >=0.6.11;

/**
 * @title IInterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains.
 */
interface IInterchainGasPaymaster {
    /**
     * @notice Emitted when a payment is made for a message's gas costs.
     * @param messageId The ID of the message to pay for.
     * @param destinationDomain The domain of the destination chain.
     * @param gasAmount The amount of destination gas paid for.
     * @param payment The amount of native tokens paid.
     */
    event GasPayment(
        bytes32 indexed messageId,
        uint32 indexed destinationDomain,
        uint256 gasAmount,
        uint256 payment
    );

    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasAmount,
        address _refundAddress
    ) external payable;

    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasAmount)
        external
        view
        returns (uint256);
}


// File contracts/libs/Indexed.sol

pragma solidity >=0.8.0;

contract Indexed {
    uint256 public immutable deployedBlock;

    constructor() {
        deployedBlock = block.number;
    }
}


// File contracts/hooks/igp/InterchainGasPaymaster.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============







// ============ External Imports ============



/**
 * @title InterchainGasPaymaster
 * @notice Manages payments on a source chain to cover gas costs of relaying
 * messages to destination chains and includes the gas overhead per destination
 * @dev The intended use of this contract is to store overhead gas amounts for destination
 * domains, e.g. Mailbox and ISM gas usage, such that users of this IGP are only required
 * to specify the gas amount used by their own applications.
 */
contract InterchainGasPaymaster is
    IInterchainGasPaymaster,
    AbstractPostDispatchHook,
    IGasOracle,
    Indexed,
    OwnableUpgradeable
{
    using Address for address payable;
    using Message for bytes;
    using StandardHookMetadata for bytes;
    // ============ Constants ============

    /// @notice The scale of gas oracle token exchange rates.
    uint256 internal constant TOKEN_EXCHANGE_RATE_SCALE = 1e10;
    /// @notice default for user call if metadata not provided
    uint256 internal immutable DEFAULT_GAS_USAGE = 50_000;

    // ============ Public Storage ============

    /// @notice Destination domain => gas oracle and overhead gas amount.
    mapping(uint32 => DomainGasConfig) public destinationGasConfigs;

    /// @notice The benficiary that can receive native tokens paid into this contract.
    address public beneficiary;

    // ============ Events ============

    /**
     * @notice Emitted when the gas oracle for a remote domain is set.
     * @param remoteDomain The remote domain.
     * @param gasOracle The gas oracle.
     * @param gasOverhead The destination gas overhead.
     */
    event DestinationGasConfigSet(
        uint32 remoteDomain,
        address gasOracle,
        uint96 gasOverhead
    );

    /**
     * @notice Emitted when the beneficiary is set.
     * @param beneficiary The new beneficiary.
     */
    event BeneficiarySet(address beneficiary);

    struct DomainGasConfig {
        IGasOracle gasOracle;
        uint96 gasOverhead;
    }

    struct GasParam {
        uint32 remoteDomain;
        DomainGasConfig config;
    }

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.INTERCHAIN_GAS_PAYMASTER);
    }

    /**
     * @param _owner The owner of the contract.
     * @param _beneficiary The beneficiary.
     */
    function initialize(address _owner, address _beneficiary)
        public
        initializer
    {
        __Ownable_init();
        _transferOwnership(_owner);
        _setBeneficiary(_beneficiary);
    }

    /**
     * @notice Transfers the entire native token balance to the beneficiary.
     * @dev The beneficiary must be able to receive native tokens.
     */
    function claim() external {
        // Transfer the entire balance to the beneficiary.
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "IGP: claim failed");
    }

    /**
     * @notice Sets the gas oracles for remote domains specified in the config array.
     * @param _configs An array of configs including the remote domain and gas oracles to set.
     */
    function setDestinationGasConfigs(GasParam[] calldata _configs)
        external
        onlyOwner
    {
        uint256 _len = _configs.length;
        for (uint256 i = 0; i < _len; i++) {
            _setDestinationGasConfig(
                _configs[i].remoteDomain,
                _configs[i].config.gasOracle,
                _configs[i].config.gasOverhead
            );
        }
    }

    /**
     * @notice Sets the beneficiary.
     * @param _beneficiary The new beneficiary.
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        _setBeneficiary(_beneficiary);
    }

    // ============ Public Functions ============

    /**
     * @notice Deposits msg.value as a payment for the relaying of a message
     * to its destination chain.
     * @dev Overpayment will result in a refund of native tokens to the _refundAddress.
     * Callers should be aware that this may present reentrancy issues.
     * @param _messageId The ID of the message to pay for.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasLimit The amount of destination gas to pay for.
     * @param _refundAddress The address to refund any overpayment to.
     */
    function payForGas(
        bytes32 _messageId,
        uint32 _destinationDomain,
        uint256 _gasLimit,
        address _refundAddress
    ) public payable override {
        uint256 _requiredPayment = quoteGasPayment(
            _destinationDomain,
            _gasLimit
        );
        require(
            msg.value >= _requiredPayment,
            "IGP: insufficient interchain gas payment"
        );
        uint256 _overpayment = msg.value - _requiredPayment;
        if (_overpayment > 0) {
            require(_refundAddress != address(0), "no refund address");
            payable(_refundAddress).sendValue(_overpayment);
        }

        emit GasPayment(
            _messageId,
            _destinationDomain,
            _gasLimit,
            _requiredPayment
        );
    }

    /**
     * @notice Quotes the amount of native tokens to pay for interchain gas.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasLimit The amount of destination gas to pay for.
     * @return The amount of native tokens required to pay for interchain gas.
     */
    function quoteGasPayment(uint32 _destinationDomain, uint256 _gasLimit)
        public
        view
        virtual
        override
        returns (uint256)
    {
        // Get the gas data for the destination domain.
        (
            uint128 _tokenExchangeRate,
            uint128 _gasPrice
        ) = getExchangeRateAndGasPrice(_destinationDomain);

        // The total cost quoted in destination chain's native token.
        uint256 _destinationGasCost = _gasLimit * uint256(_gasPrice);

        // Convert to the local native token.
        return
            (_destinationGasCost * _tokenExchangeRate) /
            TOKEN_EXCHANGE_RATE_SCALE;
    }

    /**
     * @notice Gets the token exchange rate and gas price from the configured gas oracle
     * for a given destination domain.
     * @param _destinationDomain The destination domain.
     * @return tokenExchangeRate The exchange rate of the remote native token quoted in the local native token.
     * @return gasPrice The gas price on the remote chain.
     */
    function getExchangeRateAndGasPrice(uint32 _destinationDomain)
        public
        view
        override
        returns (uint128 tokenExchangeRate, uint128 gasPrice)
    {
        IGasOracle _gasOracle = destinationGasConfigs[_destinationDomain]
            .gasOracle;

        require(
            address(_gasOracle) != address(0),
            string.concat(
                "Configured IGP doesn't support domain ",
                Strings.toString(_destinationDomain)
            )
        );

        return _gasOracle.getExchangeRateAndGasPrice(_destinationDomain);
    }

    /**
     * @notice Returns the stored destinationGasOverhead added to the _gasLimit.
     * @dev If there is no stored destinationGasOverhead, 0 is used. This is useful in the case
     *      the ISM deployer wants to subsidize the overhead gas cost. Then, can specify the gas oracle
     *      they want to use with the destination domain, but set the overhead to 0.
     * @param _destinationDomain The domain of the message's destination chain.
     * @param _gasLimit The amount of destination gas to pay for. This is only for application gas usage as
     *      the gas usage for the mailbox and the ISM is already accounted in the DomainGasConfig.gasOverhead
     */
    function destinationGasLimit(uint32 _destinationDomain, uint256 _gasLimit)
        public
        view
        returns (uint256)
    {
        return
            uint256(destinationGasConfigs[_destinationDomain].gasOverhead) +
            _gasLimit;
    }

    // ============ Internal Functions ============

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        override
    {
        payForGas(
            message.id(),
            message.destination(),
            destinationGasLimit(
                message.destination(),
                metadata.gasLimit(DEFAULT_GAS_USAGE)
            ),
            metadata.refundAddress(message.senderAddress())
        );
    }

    /// @inheritdoc AbstractPostDispatchHook
    function _quoteDispatch(bytes calldata metadata, bytes calldata message)
        internal
        view
        override
        returns (uint256)
    {
        return
            quoteGasPayment(
                message.destination(),
                destinationGasLimit(
                    message.destination(),
                    metadata.gasLimit(DEFAULT_GAS_USAGE)
                )
            );
    }

    /**
     * @notice Sets the beneficiary.
     * @param _beneficiary The new beneficiary.
     */
    function _setBeneficiary(address _beneficiary) internal {
        beneficiary = _beneficiary;
        emit BeneficiarySet(_beneficiary);
    }

    /**
     * @notice Sets the gas oracle and destination gas overhead for a remote domain.
     * @param _remoteDomain The remote domain.
     * @param _gasOracle The gas oracle.
     * @param _gasOverhead The destination gas overhead.
     */
    function _setDestinationGasConfig(
        uint32 _remoteDomain,
        IGasOracle _gasOracle,
        uint96 _gasOverhead
    ) internal {
        destinationGasConfigs[_remoteDomain] = DomainGasConfig(
            _gasOracle,
            _gasOverhead
        );
        emit DestinationGasConfigSet(
            _remoteDomain,
            address(_gasOracle),
            _gasOverhead
        );
    }
}


// File contracts/hooks/igp/StorageGasOracle.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============

// ============ External Imports ============

/**
 * @notice A gas oracle that uses data stored within the contract.
 * @dev This contract is intended to be owned by an address that will
 * update the stored remote gas data.
 */
contract StorageGasOracle is IGasOracle, Ownable {
    // ============ Public Storage ============

    /// @notice Keyed by remote domain, gas data on that remote domain.
    mapping(uint32 => IGasOracle.RemoteGasData) public remoteGasData;

    // ============ Events ============

    /**
     * @notice Emitted when an entry in `remoteGasData` is set.
     * @param remoteDomain The remote domain in which the gas data was set for.
     * @param tokenExchangeRate The exchange rate of the remote native token quoted in the local native token.
     * @param gasPrice The gas price on the remote chain.
     */
    event RemoteGasDataSet(
        uint32 indexed remoteDomain,
        uint128 tokenExchangeRate,
        uint128 gasPrice
    );

    struct RemoteGasDataConfig {
        uint32 remoteDomain;
        uint128 tokenExchangeRate;
        uint128 gasPrice;
    }

    // ============ External Functions ============

    /**
     * @notice Returns the stored `remoteGasData` for the `_destinationDomain`.
     * @param _destinationDomain The destination domain.
     * @return tokenExchangeRate The exchange rate of the remote native token quoted in the local native token.
     * @return gasPrice The gas price on the remote chain.
     */
    function getExchangeRateAndGasPrice(uint32 _destinationDomain)
        external
        view
        override
        returns (uint128 tokenExchangeRate, uint128 gasPrice)
    {
        // Intentionally allow unset / zero values
        IGasOracle.RemoteGasData memory _data = remoteGasData[
            _destinationDomain
        ];
        return (_data.tokenExchangeRate, _data.gasPrice);
    }

    /**
     * @notice Sets the remote gas data for many remotes at a time.
     * @param _configs The configs to use when setting the remote gas data.
     */
    function setRemoteGasDataConfigs(RemoteGasDataConfig[] calldata _configs)
        external
        onlyOwner
    {
        uint256 _len = _configs.length;
        for (uint256 i = 0; i < _len; i++) {
            _setRemoteGasData(_configs[i]);
        }
    }

    /**
     * @notice Sets the remote gas data using the values in `_config`.
     * @param _config The config to use when setting the remote gas data.
     */
    function setRemoteGasData(RemoteGasDataConfig calldata _config)
        external
        onlyOwner
    {
        _setRemoteGasData(_config);
    }

    // ============ Internal functions ============

    /**
     * @notice Sets the remote gas data using the values in `_config`.
     * @param _config The config to use when setting the remote gas data.
     */
    function _setRemoteGasData(RemoteGasDataConfig calldata _config) internal {
        remoteGasData[_config.remoteDomain] = IGasOracle.RemoteGasData({
            tokenExchangeRate: _config.tokenExchangeRate,
            gasPrice: _config.gasPrice
        });

        emit RemoteGasDataSet(
            _config.remoteDomain,
            _config.tokenExchangeRate,
            _config.gasPrice
        );
    }
}


// File contracts/libs/Merkle.sol

pragma solidity >=0.6.11;

// work based on eth2 deposit contract, which is used under CC0-1.0

/**
 * @title MerkleLib
 * @author Celo Labs Inc.
 * @notice An incremental merkle tree modeled on the eth2 deposit contract.
 **/
library MerkleLib {
    uint256 internal constant TREE_DEPTH = 32;
    uint256 internal constant MAX_LEAVES = 2**TREE_DEPTH - 1;

    /**
     * @notice Struct representing incremental merkle tree. Contains current
     * branch and the number of inserted leaves in the tree.
     **/
    struct Tree {
        bytes32[TREE_DEPTH] branch;
        uint256 count;
    }

    /**
     * @notice Inserts `_node` into merkle tree
     * @dev Reverts if tree is full
     * @param _node Element to insert into tree
     **/
    function insert(Tree storage _tree, bytes32 _node) internal {
        require(_tree.count < MAX_LEAVES, "merkle tree full");

        _tree.count += 1;
        uint256 size = _tree.count;
        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            if ((size & 1) == 1) {
                _tree.branch[i] = _node;
                return;
            }
            _node = keccak256(abi.encodePacked(_tree.branch[i], _node));
            size /= 2;
        }
        // As the loop should always end prematurely with the `return` statement,
        // this code should be unreachable. We assert `false` just to be safe.
        assert(false);
    }

    /**
     * @notice Calculates and returns`_tree`'s current root given array of zero
     * hashes
     * @param _zeroes Array of zero hashes
     * @return _current Calculated root of `_tree`
     **/
    function rootWithCtx(Tree storage _tree, bytes32[TREE_DEPTH] memory _zeroes)
        internal
        view
        returns (bytes32 _current)
    {
        uint256 _index = _tree.count;

        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            bytes32 _next = _tree.branch[i];
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_next, _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _zeroes[i]));
            }
        }
    }

    /// @notice Calculates and returns`_tree`'s current root
    function root(Tree storage _tree) internal view returns (bytes32) {
        return rootWithCtx(_tree, zeroHashes());
    }

    /// @notice Returns array of TREE_DEPTH zero hashes
    /// @return _zeroes Array of TREE_DEPTH zero hashes
    function zeroHashes()
        internal
        pure
        returns (bytes32[TREE_DEPTH] memory _zeroes)
    {
        _zeroes[0] = Z_0;
        _zeroes[1] = Z_1;
        _zeroes[2] = Z_2;
        _zeroes[3] = Z_3;
        _zeroes[4] = Z_4;
        _zeroes[5] = Z_5;
        _zeroes[6] = Z_6;
        _zeroes[7] = Z_7;
        _zeroes[8] = Z_8;
        _zeroes[9] = Z_9;
        _zeroes[10] = Z_10;
        _zeroes[11] = Z_11;
        _zeroes[12] = Z_12;
        _zeroes[13] = Z_13;
        _zeroes[14] = Z_14;
        _zeroes[15] = Z_15;
        _zeroes[16] = Z_16;
        _zeroes[17] = Z_17;
        _zeroes[18] = Z_18;
        _zeroes[19] = Z_19;
        _zeroes[20] = Z_20;
        _zeroes[21] = Z_21;
        _zeroes[22] = Z_22;
        _zeroes[23] = Z_23;
        _zeroes[24] = Z_24;
        _zeroes[25] = Z_25;
        _zeroes[26] = Z_26;
        _zeroes[27] = Z_27;
        _zeroes[28] = Z_28;
        _zeroes[29] = Z_29;
        _zeroes[30] = Z_30;
        _zeroes[31] = Z_31;
    }

    /**
     * @notice Calculates and returns the merkle root for the given leaf
     * `_item`, a merkle branch, and the index of `_item` in the tree.
     * @param _item Merkle leaf
     * @param _branch Merkle proof
     * @param _index Index of `_item` in tree
     * @return _current Calculated merkle root
     **/
    function branchRoot(
        bytes32 _item,
        bytes32[TREE_DEPTH] memory _branch, // cheaper than calldata indexing
        uint256 _index
    ) internal pure returns (bytes32 _current) {
        _current = _item;

        for (uint256 i = 0; i < TREE_DEPTH; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            // cheaper than calldata indexing _branch[i*32:(i+1)*32];
            bytes32 _next = _branch[i];
            if (_ithBit == 1) {
                _current = keccak256(abi.encodePacked(_next, _current));
            } else {
                _current = keccak256(abi.encodePacked(_current, _next));
            }
        }
    }

    // keccak256 zero hashes
    bytes32 internal constant Z_0 =
        hex"0000000000000000000000000000000000000000000000000000000000000000";
    bytes32 internal constant Z_1 =
        hex"ad3228b676f7d3cd4284a5443f17f1962b36e491b30a40b2405849e597ba5fb5";
    bytes32 internal constant Z_2 =
        hex"b4c11951957c6f8f642c4af61cd6b24640fec6dc7fc607ee8206a99e92410d30";
    bytes32 internal constant Z_3 =
        hex"21ddb9a356815c3fac1026b6dec5df3124afbadb485c9ba5a3e3398a04b7ba85";
    bytes32 internal constant Z_4 =
        hex"e58769b32a1beaf1ea27375a44095a0d1fb664ce2dd358e7fcbfb78c26a19344";
    bytes32 internal constant Z_5 =
        hex"0eb01ebfc9ed27500cd4dfc979272d1f0913cc9f66540d7e8005811109e1cf2d";
    bytes32 internal constant Z_6 =
        hex"887c22bd8750d34016ac3c66b5ff102dacdd73f6b014e710b51e8022af9a1968";
    bytes32 internal constant Z_7 =
        hex"ffd70157e48063fc33c97a050f7f640233bf646cc98d9524c6b92bcf3ab56f83";
    bytes32 internal constant Z_8 =
        hex"9867cc5f7f196b93bae1e27e6320742445d290f2263827498b54fec539f756af";
    bytes32 internal constant Z_9 =
        hex"cefad4e508c098b9a7e1d8feb19955fb02ba9675585078710969d3440f5054e0";
    bytes32 internal constant Z_10 =
        hex"f9dc3e7fe016e050eff260334f18a5d4fe391d82092319f5964f2e2eb7c1c3a5";
    bytes32 internal constant Z_11 =
        hex"f8b13a49e282f609c317a833fb8d976d11517c571d1221a265d25af778ecf892";
    bytes32 internal constant Z_12 =
        hex"3490c6ceeb450aecdc82e28293031d10c7d73bf85e57bf041a97360aa2c5d99c";
    bytes32 internal constant Z_13 =
        hex"c1df82d9c4b87413eae2ef048f94b4d3554cea73d92b0f7af96e0271c691e2bb";
    bytes32 internal constant Z_14 =
        hex"5c67add7c6caf302256adedf7ab114da0acfe870d449a3a489f781d659e8becc";
    bytes32 internal constant Z_15 =
        hex"da7bce9f4e8618b6bd2f4132ce798cdc7a60e7e1460a7299e3c6342a579626d2";
    bytes32 internal constant Z_16 =
        hex"2733e50f526ec2fa19a22b31e8ed50f23cd1fdf94c9154ed3a7609a2f1ff981f";
    bytes32 internal constant Z_17 =
        hex"e1d3b5c807b281e4683cc6d6315cf95b9ade8641defcb32372f1c126e398ef7a";
    bytes32 internal constant Z_18 =
        hex"5a2dce0a8a7f68bb74560f8f71837c2c2ebbcbf7fffb42ae1896f13f7c7479a0";
    bytes32 internal constant Z_19 =
        hex"b46a28b6f55540f89444f63de0378e3d121be09e06cc9ded1c20e65876d36aa0";
    bytes32 internal constant Z_20 =
        hex"c65e9645644786b620e2dd2ad648ddfcbf4a7e5b1a3a4ecfe7f64667a3f0b7e2";
    bytes32 internal constant Z_21 =
        hex"f4418588ed35a2458cffeb39b93d26f18d2ab13bdce6aee58e7b99359ec2dfd9";
    bytes32 internal constant Z_22 =
        hex"5a9c16dc00d6ef18b7933a6f8dc65ccb55667138776f7dea101070dc8796e377";
    bytes32 internal constant Z_23 =
        hex"4df84f40ae0c8229d0d6069e5c8f39a7c299677a09d367fc7b05e3bc380ee652";
    bytes32 internal constant Z_24 =
        hex"cdc72595f74c7b1043d0e1ffbab734648c838dfb0527d971b602bc216c9619ef";
    bytes32 internal constant Z_25 =
        hex"0abf5ac974a1ed57f4050aa510dd9c74f508277b39d7973bb2dfccc5eeb0618d";
    bytes32 internal constant Z_26 =
        hex"b8cd74046ff337f0a7bf2c8e03e10f642c1886798d71806ab1e888d9e5ee87d0";
    bytes32 internal constant Z_27 =
        hex"838c5655cb21c6cb83313b5a631175dff4963772cce9108188b34ac87c81c41e";
    bytes32 internal constant Z_28 =
        hex"662ee4dd2dd7b2bc707961b1e646c4047669dcb6584f0d8d770daf5d7e7deb2e";
    bytes32 internal constant Z_29 =
        hex"388ab20e2573d171a88108e79d820e98f26c0b84aa8b2f4aa4968dbb818ea322";
    bytes32 internal constant Z_30 =
        hex"93237c50ba75ee485f4c22adf2f741400bdf8d6a9cc7df7ecae576221665d735";
    bytes32 internal constant Z_31 =
        hex"8448818bb4ae4562849e949e17ac16e0be16688e156b5cf15e098c627c0056a9";
}


// File contracts/hooks/MerkleTreeHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/







contract MerkleTreeHook is AbstractPostDispatchHook, MailboxClient, Indexed {
    using Message for bytes;
    using MerkleLib for MerkleLib.Tree;
    using StandardHookMetadata for bytes;

    // An incremental merkle tree used to store outbound message IDs.
    MerkleLib.Tree internal _tree;

    event InsertedIntoTree(bytes32 messageId, uint32 index);

    constructor(address _mailbox) MailboxClient(_mailbox) {}

    // count cannot exceed 2**TREE_DEPTH, see MerkleLib.sol
    function count() public view returns (uint32) {
        return uint32(_tree.count);
    }

    function root() public view returns (bytes32) {
        return _tree.root();
    }

    function tree() public view returns (MerkleLib.Tree memory) {
        return _tree;
    }

    function latestCheckpoint() external view returns (bytes32, uint32) {
        return (root(), count() - 1);
    }

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.MERKLE_TREE);
    }

    // ============ Internal Functions ============

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(
        bytes calldata,
        /*metadata*/
        bytes calldata message
    ) internal override {
        require(msg.value == 0, "MerkleTreeHook: no value expected");

        // ensure messages which were not dispatched are not inserted into the tree
        bytes32 id = message.id();
        require(_isLatestDispatched(id), "message not dispatching");

        uint32 index = count();
        _tree.insert(id);
        emit InsertedIntoTree(id, index);
    }

    /// @inheritdoc AbstractPostDispatchHook
    function _quoteDispatch(
        bytes calldata,
        /*metadata*/
        bytes calldata /*message*/
    ) internal pure override returns (uint256) {
        return 0;
    }
}


// File contracts/interfaces/optimism/ICrossDomainMessenger.sol

pragma solidity >=0.8.0;

/**
 * @title ICrossDomainMessenger interface for bedrock update
 * @dev eth-optimism's version uses strict 0.8.15 which we don't want to restrict to
 */
interface ICrossDomainMessenger {
    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external payable;

    function relayMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _minGasLimit,
        bytes calldata _message
    ) external payable;

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);
}

interface IL2CrossDomainMessenger is ICrossDomainMessenger {
    function messageNonce() external view returns (uint256);
}


// File contracts/hooks/OPStackHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============





// ============ External Imports ============


/**
 * @title OPStackHook
 * @notice Message hook to inform the OPStackIsm of messages published through
 * the native OPStack bridge.
 * @notice This works only for L1 -> L2 messages.
 */
contract OPStackHook is AbstractMessageIdAuthHook {
    using StandardHookMetadata for bytes;

    // ============ Constants ============

    /// @notice messenger contract specified by the rollup
    ICrossDomainMessenger public immutable l1Messenger;

    // Gas limit for sending messages to L2
    // First 1.92e6 gas is provided by Optimism, see more here:
    // https://community.optimism.io/docs/developers/bridge/messaging/#for-l1-%E2%87%92-l2-transactions
    uint32 internal constant GAS_LIMIT = 1_920_000;

    // ============ Constructor ============

    constructor(
        address _mailbox,
        uint32 _destinationDomain,
        bytes32 _ism,
        address _l1Messenger
    ) AbstractMessageIdAuthHook(_mailbox, _destinationDomain, _ism) {
        require(
            Address.isContract(_l1Messenger),
            "OPStackHook: invalid messenger"
        );
        l1Messenger = ICrossDomainMessenger(_l1Messenger);
    }

    // ============ Internal functions ============
    function _quoteDispatch(bytes calldata, bytes calldata)
        internal
        pure
        override
        returns (uint256)
    {
        return 0; // gas subsidized by the L2
    }

    /// @inheritdoc AbstractMessageIdAuthHook
    function _sendMessageId(bytes calldata metadata, bytes memory payload)
        internal
        override
    {
        require(
            metadata.msgValue(0) < 2**255,
            "OPStackHook: msgValue must be less than 2 ** 255"
        );
        l1Messenger.sendMessage{value: metadata.msgValue(0)}(
            TypeCasts.bytes32ToAddress(ism),
            payload,
            GAS_LIMIT
        );
    }
}


// File contracts/hooks/PausableHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/




contract PausableHook is AbstractPostDispatchHook, Ownable, Pausable {
    using StandardHookMetadata for bytes;

    // ============ External functions ============

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.PAUSABLE);
    }

    // ============ Internal functions ============

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        override
        whenNotPaused
    {}

    /// @inheritdoc AbstractPostDispatchHook
    function _quoteDispatch(bytes calldata, bytes calldata)
        internal
        pure
        override
        returns (uint256)
    {
        return 0;
    }
}


// File contracts/hooks/routing/DomainRoutingHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============





// ============ External Imports ============

/**
 * @title DomainRoutingHook
 * @notice Delegates to a hook based on the destination domain of the message.
 */
contract DomainRoutingHook is AbstractPostDispatchHook, MailboxClient {
    using Strings for uint32;
    using Message for bytes;

    struct HookConfig {
        uint32 destination;
        address hook;
    }

    mapping(uint32 => IPostDispatchHook) public hooks;

    constructor(address _mailbox, address _owner) MailboxClient(_mailbox) {
        _transferOwnership(_owner);
    }

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure virtual override returns (uint8) {
        return uint8(IPostDispatchHook.Types.ROUTING);
    }

    function setHook(uint32 _destination, address _hook) public onlyOwner {
        hooks[_destination] = IPostDispatchHook(_hook);
    }

    function setHooks(HookConfig[] calldata configs) external onlyOwner {
        for (uint256 i = 0; i < configs.length; i++) {
            setHook(configs[i].destination, configs[i].hook);
        }
    }

    function supportsMetadata(bytes calldata)
        public
        pure
        virtual
        override
        returns (bool)
    {
        // routing hook does not care about metadata shape
        return true;
    }

    // ============ Internal Functions ============

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        virtual
        override
    {
        _getConfiguredHook(message).postDispatch{value: msg.value}(
            metadata,
            message
        );
    }

    /// @inheritdoc AbstractPostDispatchHook
    function _quoteDispatch(bytes calldata metadata, bytes calldata message)
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return _getConfiguredHook(message).quoteDispatch(metadata, message);
    }

    function _getConfiguredHook(bytes calldata message)
        internal
        view
        virtual
        returns (IPostDispatchHook hook)
    {
        hook = hooks[message.destination()];
        require(
            address(hook) != address(0),
            string.concat(
                "No hook configured for destination: ",
                message.destination().toString()
            )
        );
    }
}


// File contracts/hooks/routing/DestinationRecipientRoutingHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/



contract DestinationRecipientRoutingHook is DomainRoutingHook {
    using Message for bytes;

    /// @notice destination => recipient =>custom hook
    mapping(uint32 => mapping(bytes32 => address)) public customHooks;

    constructor(address mailbox, address owner)
        DomainRoutingHook(mailbox, owner)
    {}

    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        override
    {
        address customHookPreset = customHooks[message.destination()][
            message.recipient()
        ];
        if (customHookPreset != address(0)) {
            IPostDispatchHook(customHookPreset).postDispatch{value: msg.value}(
                metadata,
                message
            );
        } else {
            super._postDispatch(metadata, message);
        }
    }

    function configCustomHook(
        uint32 destinationDomain,
        bytes32 recipient,
        address hook
    ) external onlyOwner {
        customHooks[destinationDomain][recipient] = hook;
    }
}


// File contracts/hooks/routing/FallbackDomainRoutingHook.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/




/**
 * @title FallbackDomainRoutingHook
 * @notice Delegates to a hook based on the destination domain of the message.
 * If no hook is configured for the destination domain, delegates to a fallback hook.
 */
contract FallbackDomainRoutingHook is DomainRoutingHook {
    using Message for bytes;

    IPostDispatchHook public immutable fallbackHook;

    constructor(
        address _mailbox,
        address _owner,
        address _fallback
    ) DomainRoutingHook(_mailbox, _owner) {
        fallbackHook = IPostDispatchHook(_fallback);
    }

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.FALLBACK_ROUTING);
    }

    // ============ Internal Functions ============

    function _getConfiguredHook(bytes calldata message)
        internal
        view
        override
        returns (IPostDispatchHook)
    {
        IPostDispatchHook _hook = hooks[message.destination()];
        if (address(_hook) == address(0)) {
            _hook = fallbackHook;
        }
        return _hook;
    }
}


// File contracts/hooks/StaticProtocolFee.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============




// ============ External Imports ============


/**
 * @title StaticProtocolFee
 * @notice Collects a static protocol fee from the sender.
 */
contract StaticProtocolFee is AbstractPostDispatchHook, Ownable {
    using StandardHookMetadata for bytes;
    using Address for address payable;
    using Message for bytes;

    // ============ Constants ============

    /// @notice The maximum protocol fee that can be set.
    uint256 public immutable MAX_PROTOCOL_FEE;

    // ============ Public Storage ============

    /// @notice The current protocol fee.
    uint256 public protocolFee;
    /// @notice The beneficiary of protocol fees.
    address public beneficiary;

    // ============ Constructor ============

    constructor(
        uint256 _maxProtocolFee,
        uint256 _protocolFee,
        address _beneficiary,
        address _owner
    ) {
        MAX_PROTOCOL_FEE = _maxProtocolFee;
        _setProtocolFee(_protocolFee);
        _setBeneficiary(_beneficiary);
        _transferOwnership(_owner);
    }

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.PROTOCOL_FEE);
    }

    /**
     * @notice Sets the protocol fee.
     * @param _protocolFee The new protocol fee.
     */
    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        _setProtocolFee(_protocolFee);
    }

    /**
     * @notice Sets the beneficiary of protocol fees.
     * @param _beneficiary The new beneficiary.
     */
    function setBeneficiary(address _beneficiary) external onlyOwner {
        _setBeneficiary(_beneficiary);
    }

    /**
     * @notice Collects protocol fees from the contract.
     */
    function collectProtocolFees() external {
        payable(beneficiary).sendValue(address(this).balance);
    }

    // ============ Internal Functions ============

    /// @inheritdoc AbstractPostDispatchHook
    function _postDispatch(bytes calldata metadata, bytes calldata message)
        internal
        override
    {
        require(
            msg.value >= protocolFee,
            "StaticProtocolFee: insufficient protocol fee"
        );

        uint256 refund = msg.value - protocolFee;
        if (refund > 0) {
            payable(metadata.refundAddress(message.senderAddress())).sendValue(
                refund
            );
        }
    }

    /// @inheritdoc AbstractPostDispatchHook
    function _quoteDispatch(bytes calldata, bytes calldata)
        internal
        view
        override
        returns (uint256)
    {
        return protocolFee;
    }

    /**
     * @notice Sets the protocol fee.
     * @param _protocolFee The new protocol fee.
     */
    function _setProtocolFee(uint256 _protocolFee) internal {
        require(
            _protocolFee <= MAX_PROTOCOL_FEE,
            "StaticProtocolFee: exceeds max protocol fee"
        );
        protocolFee = _protocolFee;
    }

    /**
     * @notice Sets the beneficiary of protocol fees.
     * @param _beneficiary The new beneficiary.
     */
    function _setBeneficiary(address _beneficiary) internal {
        require(
            _beneficiary != address(0),
            "StaticProtocolFee: invalid beneficiary"
        );
        beneficiary = _beneficiary;
    }
}


// File contracts/interfaces/isms/IAggregationIsm.sol

pragma solidity >=0.6.11;

interface IAggregationIsm is IInterchainSecurityModule {
    /**
     * @notice Returns the set of modules responsible for verifying _message
     * and the number of modules that must verify
     * @dev Can change based on the content of _message
     * @param _message Hyperlane formatted interchain message
     * @return modules The array of ISM addresses
     * @return threshold The number of modules needed to verify
     */
    function modulesAndThreshold(bytes calldata _message)
        external
        view
        returns (address[] memory modules, uint8 threshold);
}


// File contracts/interfaces/isms/ICcipReadIsm.sol

pragma solidity >=0.8.0;

interface ICcipReadIsm is IInterchainSecurityModule {
    /// @dev https://eips.ethereum.org/EIPS/eip-3668
    /// @param sender the address of the contract making the call, usually address(this)
    /// @param urls the URLs to query for offchain data
    /// @param callData context needed for offchain service to service request
    /// @param callbackFunction function selector to call with offchain information
    /// @param extraData additional passthrough information to call callbackFunction with
    error OffchainLookup(
        address sender,
        string[] urls,
        bytes callData,
        bytes4 callbackFunction,
        bytes extraData
    );

    /**
     * @notice Reverts with the data needed to query information offchain
     * and be submitted via the origin mailbox
     * @dev See https://eips.ethereum.org/EIPS/eip-3668 for more information
     * @param _message data that will help construct the offchain query
     */
    function getOffchainVerifyInfo(bytes calldata _message) external view;
}


// File contracts/interfaces/isms/IMultisigIsm.sol

pragma solidity >=0.6.11;

interface IMultisigIsm is IInterchainSecurityModule {
    /**
     * @notice Returns the set of validators responsible for verifying _message
     * and the number of signatures required
     * @dev Can change based on the content of _message
     * @param _message Hyperlane formatted interchain message
     * @return validators The array of validator addresses
     * @return threshold The number of validator signatures needed
     */
    function validatorsAndThreshold(bytes calldata _message)
        external
        view
        returns (address[] memory validators, uint8 threshold);
}


// File contracts/interfaces/isms/IRoutingIsm.sol

pragma solidity >=0.8.0;

interface IRoutingIsm is IInterchainSecurityModule {
    /**
     * @notice Returns the ISM responsible for verifying _message
     * @dev Can change based on the content of _message
     * @param _message Formatted Hyperlane message (see Message.sol).
     * @return module The ISM to use to verify _message
     */
    function route(bytes calldata _message)
        external
        view
        returns (IInterchainSecurityModule);
}


// File contracts/isms/libs/AggregationIsmMetadata.sol

pragma solidity >=0.8.0;

/**
 * Format of metadata:
 *
 * [????:????] Metadata start/end uint32 ranges, packed as uint64
 * [????:????] ISM metadata, packed encoding
 */
library AggregationIsmMetadata {
    uint256 private constant RANGE_SIZE = 4;

    /**
     * @notice Returns whether or not metadata was provided for the ISM at
     * `_index`
     * @dev Callers must ensure _index is less than the number of metadatas
     * provided
     * @param _metadata Encoded Aggregation ISM metadata
     * @param _index The index of the ISM to check for metadata for
     * @return Whether or not metadata was provided for the ISM at `_index`
     */
    function hasMetadata(bytes calldata _metadata, uint8 _index)
        internal
        pure
        returns (bool)
    {
        (uint32 _start, ) = _metadataRange(_metadata, _index);
        return _start > 0;
    }

    /**
     * @notice Returns the metadata provided for the ISM at `_index`
     * @dev Callers must ensure _index is less than the number of metadatas
     * provided
     * @dev Callers must ensure `hasMetadata(_metadata, _index)`
     * @param _metadata Encoded Aggregation ISM metadata
     * @param _index The index of the ISM to return metadata for
     * @return The metadata provided for the ISM at `_index`
     */
    function metadataAt(bytes calldata _metadata, uint8 _index)
        internal
        pure
        returns (bytes calldata)
    {
        (uint32 _start, uint32 _end) = _metadataRange(_metadata, _index);
        return _metadata[_start:_end];
    }

    /**
     * @notice Returns the range of the metadata provided for the ISM at
     * `_index`, or zeroes if not provided
     * @dev Callers must ensure _index is less than the number of metadatas
     * provided
     * @param _metadata Encoded Aggregation ISM metadata
     * @param _index The index of the ISM to return metadata range for
     * @return The range of the metadata provided for the ISM at `_index`, or
     * zeroes if not provided
     */
    function _metadataRange(bytes calldata _metadata, uint8 _index)
        private
        pure
        returns (uint32, uint32)
    {
        uint256 _start = (uint32(_index) * RANGE_SIZE * 2);
        uint256 _mid = _start + RANGE_SIZE;
        uint256 _end = _mid + RANGE_SIZE;
        return (
            uint32(bytes4(_metadata[_start:_mid])),
            uint32(bytes4(_metadata[_mid:_end]))
        );
    }
}


// File contracts/isms/aggregation/AbstractAggregationIsm.sol

pragma solidity >=0.8.0;

// ============ External Imports ============

// ============ Internal Imports ============



/**
 * @title AggregationIsm
 * @notice Manages per-domain m-of-n ISM sets that are used to verify
 * interchain messages.
 */
abstract contract AbstractAggregationIsm is IAggregationIsm {
    // ============ Constants ============

    // solhint-disable-next-line const-name-snakecase
    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.AGGREGATION);

    // ============ Virtual Functions ============
    // ======= OVERRIDE THESE TO IMPLEMENT =======

    /**
     * @notice Returns the set of ISMs responsible for verifying _message
     * and the number of ISMs that must verify
     * @dev Can change based on the content of _message
     * @param _message Hyperlane formatted interchain message
     * @return modules The array of ISM addresses
     * @return threshold The number of ISMs needed to verify
     */
    function modulesAndThreshold(bytes calldata _message)
        public
        view
        virtual
        returns (address[] memory, uint8);

    // ============ Public Functions ============

    /**
     * @notice Requires that m-of-n ISMs verify the provided interchain message.
     * @param _metadata ABI encoded module metadata (see AggregationIsmMetadata.sol)
     * @param _message Formatted Hyperlane message (see Message.sol).
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        public
        returns (bool)
    {
        (address[] memory _isms, uint8 _threshold) = modulesAndThreshold(
            _message
        );
        uint256 _count = _isms.length;
        for (uint8 i = 0; i < _count; i++) {
            if (!AggregationIsmMetadata.hasMetadata(_metadata, i)) continue;
            IInterchainSecurityModule _ism = IInterchainSecurityModule(
                _isms[i]
            );
            require(
                _ism.verify(
                    AggregationIsmMetadata.metadataAt(_metadata, i),
                    _message
                ),
                "!verify"
            );
            _threshold -= 1;
        }
        require(_threshold == 0, "!threshold");
        return true;
    }
}


// File contracts/isms/aggregation/StaticAggregationIsm.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============



/**
 * @title StaticAggregationIsm
 * @notice Manages per-domain m-of-n ISM sets that are used to verify
 * interchain messages.
 */
contract StaticAggregationIsm is AbstractAggregationIsm {
    // ============ Public Functions ============

    /**
     * @notice Returns the set of ISMs responsible for verifying _message
     * and the number of ISMs that must verify
     * @dev Can change based on the content of _message
     * @return modules The array of ISM addresses
     * @return threshold The number of ISMs needed to verify
     */
    function modulesAndThreshold(bytes calldata)
        public
        view
        virtual
        override
        returns (address[] memory, uint8)
    {
        return abi.decode(MetaProxy.metadata(), (address[], uint8));
    }
}


// File contracts/isms/aggregation/StaticAggregationIsmFactory.sol

pragma solidity >=0.8.0;
// ============ Internal Imports ============


contract StaticAggregationIsmFactory is StaticThresholdAddressSetFactory {
    function _deployImplementation()
        internal
        virtual
        override
        returns (address)
    {
        return address(new StaticAggregationIsm());
    }
}


// File contracts/isms/multisig/AbstractMultisigIsm.sol

pragma solidity >=0.8.0;

// ============ External Imports ============

// ============ Internal Imports ============




/**
 * @title MultisigIsm
 * @notice Manages per-domain m-of-n Validator sets that are used to verify
 * interchain messages.
 * @dev See ./AbstractMerkleRootMultisigIsm.sol and ./AbstractMessageIdMultisigIsm.sol
 * for concrete implementations of `digest` and `signatureAt`.
 * @dev See ./StaticMultisigIsm.sol for concrete implementations.
 */
abstract contract AbstractMultisigIsm is IMultisigIsm {
    // ============ Virtual Functions ============
    // ======= OVERRIDE THESE TO IMPLEMENT =======

    /**
     * @notice Returns the set of validators responsible for verifying _message
     * and the number of signatures required
     * @dev Can change based on the content of _message
     * @param _message Hyperlane formatted interchain message
     * @return validators The array of validator addresses
     * @return threshold The number of validator signatures needed
     */
    function validatorsAndThreshold(bytes calldata _message)
        public
        view
        virtual
        returns (address[] memory, uint8);

    /**
     * @notice Returns the digest to be used for signature verification.
     * @param _metadata ABI encoded module metadata
     * @param _message Formatted Hyperlane message (see Message.sol).
     * @return digest The digest to be signed by validators
     */
    function digest(bytes calldata _metadata, bytes calldata _message)
        internal
        view
        virtual
        returns (bytes32);

    /**
     * @notice Returns the signature at a given index from the metadata.
     * @param _metadata ABI encoded module metadata
     * @param _index The index of the signature to return
     * @return signature Packed encoding of signature (65 bytes)
     */
    function signatureAt(bytes calldata _metadata, uint256 _index)
        internal
        pure
        virtual
        returns (bytes calldata);

    // ============ Public Functions ============

    /**
     * @notice Requires that m-of-n validators verify a merkle root,
     * and verifies a me∑rkle proof of `_message` against that root.
     * @param _metadata ABI encoded module metadata
     * @param _message Formatted Hyperlane message (see Message.sol).
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        public
        view
        returns (bool)
    {
        bytes32 _digest = digest(_metadata, _message);
        (
            address[] memory _validators,
            uint8 _threshold
        ) = validatorsAndThreshold(_message);
        require(_threshold > 0, "No MultisigISM threshold present for message");

        uint256 _validatorCount = _validators.length;
        uint256 _validatorIndex = 0;
        // Assumes that signatures are ordered by validator
        for (uint256 i = 0; i < _threshold; ++i) {
            address _signer = ECDSA.recover(_digest, signatureAt(_metadata, i));
            // Loop through remaining validators until we find a match
            while (
                _validatorIndex < _validatorCount &&
                _signer != _validators[_validatorIndex]
            ) {
                ++_validatorIndex;
            }
            // Fail if we never found a match
            require(_validatorIndex < _validatorCount, "!threshold");
            ++_validatorIndex;
        }
        return true;
    }
}


// File contracts/isms/ccip-read/AbstractCcipReadIsm.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============





/**
 * @title AbstractCcipReadIsm
 * @notice An ISM that allows arbitrary payloads to be submitted and verified on chain
 * @dev https://eips.ethereum.org/EIPS/eip-3668
 * @dev The AbstractCcipReadIsm provided by Hyperlane is left intentially minimalist as
 * the range of applications that could be supported by a CcipReadIsm are so broad. However
 * there are few things to note when building a custom CcipReadIsm.
 *
 * 1. `getOffchainVerifyInfo` should revert with a `OffchainLookup` error, which encodes
 *    the data necessary to query for offchain information
 * 2. For full CCIP Read specification compatibility, CcipReadIsm's should expose a function
 *    that in turn calls `process` on the configured Mailbox with the provided metadata and
 *    message. This functions selector should be provided as the `callbackFunction` payload
 *    for the OffchainLookup error
 */
abstract contract AbstractCcipReadIsm is ICcipReadIsm {
    // ============ Constants ============

    // solhint-disable-next-line const-name-snakecase
    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.CCIP_READ);
}


// File contracts/isms/hook/ERC5164Ism.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============




// ============ External Imports ============

/**
 * @title ERC5164Ism
 * @notice Uses the generic eip-5164 standard to verify interchain messages.
 */
contract ERC5164Ism is AbstractMessageIdAuthorizedIsm {
    // ============ Constants ============

    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.NULL);
    // corresponding 5164 executor address
    address public immutable executor;

    // ============ Constructor ============

    constructor(address _executor) {
        require(Address.isContract(_executor), "ERC5164Ism: invalid executor");
        executor = _executor;
    }

    /**
     * @notice Check if sender is authorized to message `verifyMessageId`.
     */
    function _isAuthorized() internal view override returns (bool) {
        return msg.sender == executor;
    }
}


// File contracts/isms/hook/OPStackIsm.sol

pragma solidity >=0.8.0;

/*@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
     @@@@@  HYPERLANE  @@@@@@@
    @@@@@@@@@@@@@@@@@@@@@@@@@
   @@@@@@@@@       @@@@@@@@@
  @@@@@@@@@       @@@@@@@@@
 @@@@@@@@@       @@@@@@@@@
@@@@@@@@@       @@@@@@@@*/

// ============ Internal Imports ============




// ============ External Imports ============


/**
 * @title OPStackIsm
 * @notice Uses the native Optimism bridge to verify interchain messages.
 */
contract OPStackIsm is
    CrossChainEnabledOptimism,
    AbstractMessageIdAuthorizedIsm
{
    // ============ Constants ============

    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.NULL);

    // ============ Constructor ============

    constructor(address _l2Messenger) CrossChainEnabledOptimism(_l2Messenger) {
        require(
            Address.isContract(_l2Messenger),
            "OPStackIsm: invalid L2Messenger"
        );
    }

    // ============ Internal function ============

    /**
     * @notice Check if sender is authorized to message `verifyMessageId`.
     */
    function _isAuthorized() internal view override returns (bool) {
        return
            _crossChainSender() == TypeCasts.bytes32ToAddress(authorizedHook);
    }
}


// File contracts/isms/libs/MerkleRootMultisigIsmMetadata.sol

pragma solidity >=0.8.0;

/**
 * Format of metadata:
 * [   0:  32] Origin merkle tree address
 * [  32:  36] Index of message ID in merkle tree
 * [  36:  68] Signed checkpoint message ID
 * [  68:1092] Merkle proof
 * [1092:1096] Signed checkpoint index (computed from proof and index)
 * [1096:????] Validator signatures (length := threshold * 65)
 */
library MerkleRootMultisigIsmMetadata {
    uint8 private constant ORIGIN_MERKLE_TREE_OFFSET = 0;
    uint8 private constant MESSAGE_INDEX_OFFSET = 32;
    uint8 private constant MESSAGE_ID_OFFSET = 36;
    uint8 private constant MERKLE_PROOF_OFFSET = 68;
    uint16 private constant MERKLE_PROOF_LENGTH = 32 * 32;
    uint16 private constant SIGNED_INDEX_OFFSET = 1092;
    uint16 private constant SIGNATURES_OFFSET = 1096;
    uint8 private constant SIGNATURE_LENGTH = 65;

    /**
     * @notice Returns the origin merkle tree hook of the signed checkpoint as bytes32.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Origin merkle tree hook of the signed checkpoint as bytes32
     */
    function originMerkleTreeHook(bytes calldata _metadata)
        internal
        pure
        returns (bytes32)
    {
        return
            bytes32(
                _metadata[ORIGIN_MERKLE_TREE_OFFSET:ORIGIN_MERKLE_TREE_OFFSET +
                    32]
            );
    }

    /**
     * @notice Returns the index of the message being proven.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Index of the target message in the merkle tree.
     */
    function messageIndex(bytes calldata _metadata)
        internal
        pure
        returns (uint32)
    {
        return
            uint32(
                bytes4(_metadata[MESSAGE_INDEX_OFFSET:MESSAGE_INDEX_OFFSET + 4])
            );
    }

    /**
     * @notice Returns the index of the signed checkpoint.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Index of the signed checkpoint
     */
    function signedIndex(bytes calldata _metadata)
        internal
        pure
        returns (uint32)
    {
        return
            uint32(
                bytes4(_metadata[SIGNED_INDEX_OFFSET:SIGNED_INDEX_OFFSET + 4])
            );
    }

    /**
     * @notice Returns the message ID of the signed checkpoint.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Message ID of the signed checkpoint
     */
    function signedMessageId(bytes calldata _metadata)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(_metadata[MESSAGE_ID_OFFSET:MESSAGE_ID_OFFSET + 32]);
    }

    /**
     * @notice Returns the merkle proof branch of the message.
     * @dev This appears to be more gas efficient than returning a calldata
     * slice and using that.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Merkle proof branch of the message.
     */
    function proof(bytes calldata _metadata)
        internal
        pure
        returns (bytes32[32] memory)
    {
        return
            abi.decode(
                _metadata[MERKLE_PROOF_OFFSET:MERKLE_PROOF_OFFSET +
                    MERKLE_PROOF_LENGTH],
                (bytes32[32])
            );
    }

    /**
     * @notice Returns the validator ECDSA signature at `_index`.
     * @dev Assumes signatures are sorted by validator
     * @dev Assumes `_metadata` encodes `threshold` signatures.
     * @dev Assumes `_index` is less than `threshold`
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @param _index The index of the signature to return.
     * @return The validator ECDSA signature at `_index`.
     */
    function signatureAt(bytes calldata _metadata, uint256 _index)
        internal
        pure
        returns (bytes calldata)
    {
        uint256 _start = SIGNATURES_OFFSET + (_index * SIGNATURE_LENGTH);
        uint256 _end = _start + SIGNATURE_LENGTH;
        return _metadata[_start:_end];
    }
}


// File contracts/libs/CheckpointLib.sol

pragma solidity >=0.8.0;

// ============ External Imports ============

library CheckpointLib {
    /**
     * @notice Returns the digest validators are expected to sign when signing checkpoints.
     * @param _origin The origin domain of the checkpoint.
     * @param _originmerkleTreeHook The address of the origin merkle tree hook as bytes32.
     * @param _checkpointRoot The root of the checkpoint.
     * @param _checkpointIndex The index of the checkpoint.
     * @param _messageId The message ID of the checkpoint.
     * @dev Message ID must match leaf content of checkpoint root at index.
     * @return The digest of the checkpoint.
     */
    function digest(
        uint32 _origin,
        bytes32 _originmerkleTreeHook,
        bytes32 _checkpointRoot,
        uint32 _checkpointIndex,
        bytes32 _messageId
    ) internal pure returns (bytes32) {
        bytes32 _domainHash = domainHash(_origin, _originmerkleTreeHook);
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(
                    abi.encodePacked(
                        _domainHash,
                        _checkpointRoot,
                        _checkpointIndex,
                        _messageId
                    )
                )
            );
    }

    /**
     * @notice Returns the domain hash that validators are expected to use
     * when signing checkpoints.
     * @param _origin The origin domain of the checkpoint.
     * @param _originmerkleTreeHook The address of the origin merkle tree as bytes32.
     * @return The domain hash.
     */
    function domainHash(uint32 _origin, bytes32 _originmerkleTreeHook)
        internal
        pure
        returns (bytes32)
    {
        // Including the origin merkle tree address in the signature allows the slashing
        // protocol to enroll multiple trees. Otherwise, a valid signature for
        // tree A would be indistinguishable from a fraudulent signature for tree B.
        // The slashing protocol should slash if validators sign attestations for
        // anything other than a whitelisted tree.
        return
            keccak256(
                abi.encodePacked(_origin, _originmerkleTreeHook, "HYPERLANE")
            );
    }
}


// File contracts/isms/multisig/AbstractMerkleRootMultisigIsm.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============






/**
 * @title `AbstractMerkleRootMultisigIsm` — multi-sig ISM with the validators-censorship resistance guarantee.
 * @notice This ISM allows using a newer signed checkpoint (say #33) to prove existence of an older message (#22) in the validators' MerkleTree.
 * This guarantees censorship resistance as validators cannot hide a message
 * by refusing to sign its checkpoint but later signing a checkpoint for a newer message.
 * If validators decide to censor a message, they are left with only one option — to not produce checkpoints at all.
 * Otherwise, the very next signed checkpoint (#33) can be used by any relayer to prove the previous message inclusion using this ISM.
 * This is censorship resistance is missing in the sibling implementation `AbstractMessageIdMultisigIsm`,
 * since it can only verify messages having the corresponding checkpoints.
 * @dev Provides the default implementation of verifying signatures over a checkpoint and the message inclusion in that checkpoint.
 * This abstract contract can be overridden for customizing the `validatorsAndThreshold()` (static or dynamic).
 * @dev May be adapted in future to support batch message verification against a single root.
 */
abstract contract AbstractMerkleRootMultisigIsm is AbstractMultisigIsm {
    using MerkleRootMultisigIsmMetadata for bytes;
    using Message for bytes;

    // ============ Constants ============

    // solhint-disable-next-line const-name-snakecase
    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.MERKLE_ROOT_MULTISIG);

    /**
     * @inheritdoc AbstractMultisigIsm
     */
    function digest(bytes calldata _metadata, bytes calldata _message)
        internal
        pure
        override
        returns (bytes32)
    {
        require(
            _metadata.messageIndex() <= _metadata.signedIndex(),
            "Invalid merkle index metadata"
        );
        // We verify a merkle proof of (messageId, index) I to compute root J
        bytes32 _signedRoot = MerkleLib.branchRoot(
            _message.id(),
            _metadata.proof(),
            _metadata.messageIndex()
        );
        // We provide (messageId, index) J in metadata for digest derivation
        return
            CheckpointLib.digest(
                _message.origin(),
                _metadata.originMerkleTreeHook(),
                _signedRoot,
                _metadata.signedIndex(),
                _metadata.signedMessageId()
            );
    }

    /**
     * @inheritdoc AbstractMultisigIsm
     */
    function signatureAt(bytes calldata _metadata, uint256 _index)
        internal
        pure
        virtual
        override
        returns (bytes calldata)
    {
        return _metadata.signatureAt(_index);
    }
}


// File contracts/isms/libs/MessageIdMultisigIsmMetadata.sol

pragma solidity >=0.8.0;

/**
 * Format of metadata:
 * [   0:  32] Origin merkle tree address
 * [  32:  64] Signed checkpoint root
 * [  64:  68] Signed checkpoint index
 * [  68:????] Validator signatures (length := threshold * 65)
 */
library MessageIdMultisigIsmMetadata {
    uint8 private constant ORIGIN_MERKLE_TREE_OFFSET = 0;
    uint8 private constant MERKLE_ROOT_OFFSET = 32;
    uint8 private constant MERKLE_INDEX_OFFSET = 64;
    uint8 private constant SIGNATURES_OFFSET = 68;
    uint8 private constant SIGNATURE_LENGTH = 65;

    /**
     * @notice Returns the origin merkle tree hook of the signed checkpoint as bytes32.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Origin merkle tree hook of the signed checkpoint as bytes32
     */
    function originMerkleTreeHook(bytes calldata _metadata)
        internal
        pure
        returns (bytes32)
    {
        return
            bytes32(
                _metadata[ORIGIN_MERKLE_TREE_OFFSET:ORIGIN_MERKLE_TREE_OFFSET +
                    32]
            );
    }

    /**
     * @notice Returns the merkle root of the signed checkpoint.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Merkle root of the signed checkpoint
     */
    function root(bytes calldata _metadata) internal pure returns (bytes32) {
        return bytes32(_metadata[MERKLE_ROOT_OFFSET:MERKLE_ROOT_OFFSET + 32]);
    }

    /**
     * @notice Returns the merkle index of the signed checkpoint.
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @return Merkle index of the signed checkpoint
     */
    function index(bytes calldata _metadata) internal pure returns (uint32) {
        return
            uint32(
                bytes4(_metadata[MERKLE_INDEX_OFFSET:MERKLE_INDEX_OFFSET + 4])
            );
    }

    /**
     * @notice Returns the validator ECDSA signature at `_index`.
     * @dev Assumes signatures are sorted by validator
     * @dev Assumes `_metadata` encodes `threshold` signatures.
     * @dev Assumes `_index` is less than `threshold`
     * @param _metadata ABI encoded Multisig ISM metadata.
     * @param _index The index of the signature to return.
     * @return The validator ECDSA signature at `_index`.
     */
    function signatureAt(bytes calldata _metadata, uint256 _index)
        internal
        pure
        returns (bytes calldata)
    {
        uint256 _start = SIGNATURES_OFFSET + (_index * SIGNATURE_LENGTH);
        uint256 _end = _start + SIGNATURE_LENGTH;
        return _metadata[_start:_end];
    }
}


// File contracts/isms/multisig/AbstractMessageIdMultisigIsm.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============





/**
 * @title `AbstractMessageIdMultisigIsm` — multi-sig ISM for the censorship-friendly validators.
 * @notice This ISM minimizes gas/performance overhead of the checkpoints verification by compromising on the censorship resistance.
 * For censorship resistance consider using `AbstractMerkleRootMultisigIsm`.
 * If the validators (`validatorsAndThreshold`) skip messages by not sign checkpoints for them,
 * the relayers will not be able to aggregate a quorum of signatures sufficient to deliver these messages via this ISM.
 * Integrations are free to choose the trade-off between the censorship resistance and the gas/processing overhead.
 * @dev Provides the default implementation of verifying signatures over a checkpoint related to a specific message ID.
 * This abstract contract can be customized to change the `validatorsAndThreshold()` (static or dynamic).
 */
abstract contract AbstractMessageIdMultisigIsm is AbstractMultisigIsm {
    using Message for bytes;
    using MessageIdMultisigIsmMetadata for bytes;

    // ============ Constants ============

    // solhint-disable-next-line const-name-snakecase
    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.MESSAGE_ID_MULTISIG);

    /**
     * @inheritdoc AbstractMultisigIsm
     */
    function digest(bytes calldata _metadata, bytes calldata _message)
        internal
        pure
        override
        returns (bytes32)
    {
        return
            CheckpointLib.digest(
                _message.origin(),
                _metadata.originMerkleTreeHook(),
                _metadata.root(),
                _metadata.index(),
                _message.id()
            );
    }

    /**
     * @inheritdoc AbstractMultisigIsm
     */
    function signatureAt(bytes calldata _metadata, uint256 _index)
        internal
        pure
        virtual
        override
        returns (bytes calldata)
    {
        return _metadata.signatureAt(_index);
    }
}


// File contracts/isms/multisig/StaticMultisigIsm.sol

pragma solidity >=0.8.0;
// ============ Internal Imports ============





/**
 * @title AbstractMetaProxyMultisigIsm
 * @notice Manages per-domain m-of-n Validator set that is used
 * to verify interchain messages.
 */
abstract contract AbstractMetaProxyMultisigIsm is AbstractMultisigIsm {
    /**
     * @inheritdoc AbstractMultisigIsm
     */
    function validatorsAndThreshold(bytes calldata)
        public
        pure
        override
        returns (address[] memory, uint8)
    {
        return abi.decode(MetaProxy.metadata(), (address[], uint8));
    }
}

// solhint-disable no-empty-blocks

/**
 * @title StaticMerkleRootMultisigIsm
 * @notice Manages per-domain m-of-n validator set that is used
 * to verify interchain messages using a merkle root signature quorum
 * and merkle proof of inclusion.
 */
contract StaticMerkleRootMultisigIsm is
    AbstractMerkleRootMultisigIsm,
    AbstractMetaProxyMultisigIsm
{

}

/**
 * @title StaticMessageIdMultisigIsm
 * @notice Manages per-domain m-of-n validator set that is used
 * to verify interchain messages using a message ID signature quorum.
 */
contract StaticMessageIdMultisigIsm is
    AbstractMessageIdMultisigIsm,
    AbstractMetaProxyMultisigIsm
{

}

// solhint-enable no-empty-blocks

contract StaticMerkleRootMultisigIsmFactory is
    StaticThresholdAddressSetFactory
{
    function _deployImplementation() internal override returns (address) {
        return address(new StaticMerkleRootMultisigIsm());
    }
}

contract StaticMessageIdMultisigIsmFactory is StaticThresholdAddressSetFactory {
    function _deployImplementation() internal override returns (address) {
        return address(new StaticMessageIdMultisigIsm());
    }
}


// File contracts/interfaces/IValidatorAnnounce.sol

pragma solidity >=0.6.11;

interface IValidatorAnnounce {
    /// @notice Returns a list of validators that have made announcements
    function getAnnouncedValidators() external view returns (address[] memory);

    /**
     * @notice Returns a list of all announced storage locations for `validators`
     * @param _validators The list of validators to get storage locations for
     * @return A list of announced storage locations
     */
    function getAnnouncedStorageLocations(address[] calldata _validators)
        external
        view
        returns (string[][] memory);

    /**
     * @notice Announces a validator signature storage location
     * @param _storageLocation Information encoding the location of signed
     * checkpoints
     * @param _signature The signed validator announcement
     * @return True upon success
     */
    function announce(
        address _validator,
        string calldata _storageLocation,
        bytes calldata _signature
    ) external returns (bool);
}


// File contracts/isms/multisig/ValidatorAnnounce.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============




// ============ External Imports ============


/**
 * @title ValidatorAnnounce
 * @notice Stores the location(s) of validator signed checkpoints
 */
contract ValidatorAnnounce is MailboxClient, IValidatorAnnounce {
    // ============ Libraries ============

    using EnumerableSet for EnumerableSet.AddressSet;
    using TypeCasts for address;

    // ============ Public Storage ============

    // The set of validators that have announced
    EnumerableSet.AddressSet private validators;
    // Storage locations of validator signed checkpoints
    mapping(address => string[]) private storageLocations;
    // Mapping to prevent the same announcement from being registered
    // multiple times.
    mapping(bytes32 => bool) private replayProtection;

    // ============ Events ============

    /**
     * @notice Emitted when a new validator announcement is made
     * @param validator The address of the announcing validator
     * @param storageLocation The storage location being announced
     */
    event ValidatorAnnouncement(
        address indexed validator,
        string storageLocation
    );

    // ============ Constructor ============

    constructor(address _mailbox) MailboxClient(_mailbox) {}

    // ============ External Functions ============

    /**
     * @notice Announces a validator signature storage location
     * @param _storageLocation Information encoding the location of signed
     * checkpoints
     * @param _signature The signed validator announcement
     * @return True upon success
     */
    function announce(
        address _validator,
        string calldata _storageLocation,
        bytes calldata _signature
    ) external returns (bool) {
        // Ensure that the same storage metadata isn't being announced
        // multiple times for the same validator.
        bytes32 _replayId = keccak256(
            abi.encodePacked(_validator, _storageLocation)
        );
        require(replayProtection[_replayId] == false, "replay");
        replayProtection[_replayId] = true;

        // Verify that the signature matches the declared validator
        bytes32 _announcementDigest = getAnnouncementDigest(_storageLocation);
        address _signer = ECDSA.recover(_announcementDigest, _signature);
        require(_signer == _validator, "!signature");

        // Store the announcement
        if (!validators.contains(_validator)) {
            validators.add(_validator);
        }
        storageLocations[_validator].push(_storageLocation);
        emit ValidatorAnnouncement(_validator, _storageLocation);
        return true;
    }

    /**
     * @notice Returns a list of all announced storage locations
     * @param _validators The list of validators to get registrations for
     * @return A list of registered storage metadata
     */
    function getAnnouncedStorageLocations(address[] calldata _validators)
        external
        view
        returns (string[][] memory)
    {
        string[][] memory _metadata = new string[][](_validators.length);
        for (uint256 i = 0; i < _validators.length; i++) {
            _metadata[i] = storageLocations[_validators[i]];
        }
        return _metadata;
    }

    /// @notice Returns a list of validators that have made announcements
    function getAnnouncedValidators() external view returns (address[] memory) {
        return validators.values();
    }

    /**
     * @notice Returns the digest validators are expected to sign when signing announcements.
     * @param _storageLocation Storage location string.
     * @return The digest of the announcement.
     */
    function getAnnouncementDigest(string memory _storageLocation)
        public
        view
        returns (bytes32)
    {
        return
            ECDSA.toEthSignedMessageHash(
                keccak256(abi.encodePacked(_domainHash(), _storageLocation))
            );
    }

    /**
     * @notice Returns the domain separator used in validator announcements.
     */
    function _domainHash() internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    localDomain,
                    address(mailbox).addressToBytes32(),
                    "HYPERLANE_ANNOUNCEMENT"
                )
            );
    }
}


// File contracts/isms/NoopIsm.sol

pragma solidity >=0.8.0;

contract NoopIsm is IInterchainSecurityModule {
    uint8 public constant override moduleType = uint8(Types.NULL);

    function verify(bytes calldata, bytes calldata)
        public
        pure
        override
        returns (bool)
    {
        return true;
    }
}


// File contracts/isms/PausableIsm.sol

pragma solidity >=0.8.0;

// ============ External Imports ============


// ============ Internal Imports ============

contract PausableIsm is IInterchainSecurityModule, Ownable, Pausable {
    uint8 public constant override moduleType = uint8(Types.NULL);

    /**
     * @inheritdoc IInterchainSecurityModule
     * @dev Reverts when paused, otherwise returns `true`.
     */
    function verify(bytes calldata, bytes calldata)
        external
        view
        whenNotPaused
        returns (bool)
    {
        return true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}


// File contracts/isms/routing/AbstractRoutingIsm.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============


/**
 * @title RoutingIsm
 */
abstract contract AbstractRoutingIsm is IRoutingIsm {
    // ============ Constants ============

    // solhint-disable-next-line const-name-snakecase
    uint8 public constant moduleType =
        uint8(IInterchainSecurityModule.Types.ROUTING);

    // ============ Virtual Functions ============
    // ======= OVERRIDE THESE TO IMPLEMENT =======

    /**
     * @notice Returns the ISM responsible for verifying _message
     * @dev Can change based on the content of _message
     * @param _message Formatted Hyperlane message (see Message.sol).
     * @return module The ISM to use to verify _message
     */
    function route(bytes calldata _message)
        public
        view
        virtual
        returns (IInterchainSecurityModule);

    // ============ Public Functions ============

    /**
     * @notice Routes _metadata and _message to the correct ISM
     * @param _metadata ABI encoded module metadata
     * @param _message Formatted Hyperlane message (see Message.sol).
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        public
        returns (bool)
    {
        return route(_message).verify(_metadata, _message);
    }
}


// File contracts/isms/routing/DomainRoutingIsm.sol

pragma solidity >=0.8.0;

// ============ External Imports ============



// ============ Internal Imports ============





/**
 * @title DomainRoutingIsm
 */
contract DomainRoutingIsm is AbstractRoutingIsm, OwnableUpgradeable {
    using EnumerableMapExtended for EnumerableMapExtended.UintToBytes32Map;
    using Message for bytes;
    using TypeCasts for bytes32;
    using TypeCasts for address;
    using Address for address;
    using Strings for uint32;

    // ============ Mutable Storage ============
    EnumerableMapExtended.UintToBytes32Map internal _modules;

    // ============ External Functions ============

    /**
     * @param _owner The owner of the contract.
     */
    function initialize(address _owner) public initializer {
        __Ownable_init();
        _transferOwnership(_owner);
    }

    /**
     * @notice Sets the ISMs to be used for the specified origin domains
     * @param _owner The owner of the contract.
     * @param _domains The origin domains
     * @param __modules The ISMs to use to verify messages
     */
    function initialize(
        address _owner,
        uint32[] calldata _domains,
        IInterchainSecurityModule[] calldata __modules
    ) public initializer {
        __Ownable_init();
        require(_domains.length == __modules.length, "length mismatch");
        uint256 _length = _domains.length;
        for (uint256 i = 0; i < _length; ++i) {
            _set(_domains[i], address(__modules[i]));
        }
        _transferOwnership(_owner);
    }

    /**
     * @notice Sets the ISM to be used for the specified origin domain
     * @param _domain The origin domain
     * @param _module The ISM to use to verify messages
     */
    function set(uint32 _domain, IInterchainSecurityModule _module)
        external
        onlyOwner
    {
        _set(_domain, address(_module));
    }

    /**
     * @notice Removes the specified origin domain
     * @param _domain The origin domain
     */
    function remove(uint32 _domain) external onlyOwner {
        _remove(_domain);
    }

    function domains() external view returns (uint256[] memory) {
        return _modules.keys();
    }

    function module(uint32 origin)
        public
        view
        virtual
        returns (IInterchainSecurityModule)
    {
        (bool contained, bytes32 _module) = _modules.tryGet(origin);
        require(contained, _originNotFoundError(origin));
        return IInterchainSecurityModule(_module.bytes32ToAddress());
    }

    // ============ Public Functions ============
    /**
     * @notice Returns the ISM responsible for verifying _message
     * @dev Can change based on the content of _message
     * @param _message Formatted Hyperlane message (see Message.sol).
     * @return module The ISM to use to verify _message
     */
    function route(bytes calldata _message)
        public
        view
        override
        returns (IInterchainSecurityModule)
    {
        return module(_message.origin());
    }

    // ============ Internal Functions ============

    /**
     * @notice Removes the specified origin domain's ISM
     * @param _domain The origin domain
     */
    function _remove(uint32 _domain) internal {
        require(_modules.remove(_domain), _originNotFoundError(_domain));
    }

    function _originNotFoundError(uint32 _origin)
        internal
        pure
        returns (string memory)
    {
        return string.concat("No ISM found for origin: ", _origin.toString());
    }

    /**
     * @notice Sets the ISM to be used for the specified origin domain
     * @param _domain The origin domain
     * @param _module The ISM to use to verify messages
     */
    function _set(uint32 _domain, address _module) internal {
        require(_module.isContract(), "ISM must be a contract");
        _modules.set(_domain, _module.addressToBytes32());
    }
}


// File contracts/isms/routing/DefaultFallbackRoutingIsm.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============





// ============ External Imports ============

contract DefaultFallbackRoutingIsm is DomainRoutingIsm, MailboxClient {
    using EnumerableMapExtended for EnumerableMapExtended.UintToBytes32Map;
    using Address for address;
    using TypeCasts for bytes32;

    constructor(address _mailbox) MailboxClient(_mailbox) {}

    function module(uint32 origin)
        public
        view
        override
        returns (IInterchainSecurityModule)
    {
        (bool contained, bytes32 _module) = _modules.tryGet(origin);
        if (contained) {
            return IInterchainSecurityModule(_module.bytes32ToAddress());
        } else {
            return mailbox.defaultIsm();
        }
    }
}


// File contracts/libs/MinimalProxy.sol

pragma solidity >=0.6.11;

// Library for building bytecode of minimal proxies (see https://eips.ethereum.org/EIPS/eip-1167)
library MinimalProxy {
    bytes20 private constant PREFIX =
        hex"3d602d80600a3d3981f3363d3d373d3d3d363d73";
    bytes15 private constant SUFFIX = hex"5af43d82803e903d91602b57fd5bf3";

    function create(address implementation) internal returns (address proxy) {
        bytes memory _bytecode = bytecode(implementation);
        assembly {
            proxy := create(0, add(_bytecode, 32), mload(_bytecode))
        }
    }

    function bytecode(address implementation)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(PREFIX, bytes20(implementation), SUFFIX);
    }
}


// File contracts/isms/routing/DomainRoutingIsmFactory.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============




abstract contract AbstractDomainRoutingIsmFactory {
    /**
     * @notice Emitted when a routing module is deployed
     * @param module The deployed ISM
     */
    event ModuleDeployed(DomainRoutingIsm module);

    // ============ External Functions ============

    /**
     * @notice Deploys and initializes a DomainRoutingIsm using a minimal proxy
     * @param _domains The origin domains
     * @param _modules The ISMs to use to verify messages
     */
    function deploy(
        uint32[] calldata _domains,
        IInterchainSecurityModule[] calldata _modules
    ) external returns (DomainRoutingIsm) {
        DomainRoutingIsm _ism = DomainRoutingIsm(
            MinimalProxy.create(implementation())
        );
        emit ModuleDeployed(_ism);
        _ism.initialize(msg.sender, _domains, _modules);
        return _ism;
    }

    function implementation() public view virtual returns (address);
}

/**
 * @title DomainRoutingIsmFactory
 */
contract DomainRoutingIsmFactory is AbstractDomainRoutingIsmFactory {
    // ============ Immutables ============
    address internal immutable _implementation;

    constructor() {
        _implementation = address(new DomainRoutingIsm());
    }

    function implementation() public view override returns (address) {
        return _implementation;
    }
}

/**
 * @title DefaultFallbackRoutingIsmFactory
 */
contract DefaultFallbackRoutingIsmFactory is AbstractDomainRoutingIsmFactory {
    // ============ Immutables ============
    address internal immutable _implementation;

    constructor(address mailbox) {
        _implementation = address(new DefaultFallbackRoutingIsm(mailbox));
    }

    function implementation() public view override returns (address) {
        return _implementation;
    }
}


// File contracts/middleware/libs/Call.sol

pragma solidity ^0.8.13;

library CallLib {
    struct StaticCall {
        // supporting non EVM targets
        bytes32 to;
        bytes data;
    }

    struct Call {
        // supporting non EVM targets
        bytes32 to;
        uint256 value;
        bytes data;
    }

    struct StaticCallWithCallback {
        StaticCall _call;
        bytes callback;
    }

    function call(Call memory _call)
        internal
        returns (bytes memory returnData)
    {
        return
            Address.functionCallWithValue(
                TypeCasts.bytes32ToAddress(_call.to),
                _call.data,
                _call.value
            );
    }

    function staticcall(StaticCall memory _call)
        private
        view
        returns (bytes memory)
    {
        return
            Address.functionStaticCall(
                TypeCasts.bytes32ToAddress(_call.to),
                _call.data
            );
    }

    function staticcall(StaticCallWithCallback memory _call)
        internal
        view
        returns (bytes memory callback)
    {
        return bytes.concat(_call.callback, staticcall(_call._call));
    }

    function multicall(Call[] memory calls) internal {
        uint256 i = 0;
        uint256 len = calls.length;
        while (i < len) {
            call(calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function multistaticcall(StaticCallWithCallback[] memory _calls)
        internal
        view
        returns (bytes[] memory)
    {
        uint256 i = 0;
        uint256 len = _calls.length;
        bytes[] memory callbacks = new bytes[](len);
        while (i < len) {
            callbacks[i] = staticcall(_calls[i]);
            unchecked {
                ++i;
            }
        }
        return callbacks;
    }

    function multicallto(address to, bytes[] memory calls) internal {
        uint256 i = 0;
        uint256 len = calls.length;
        while (i < len) {
            Address.functionCall(to, calls[i]);
            unchecked {
                ++i;
            }
        }
    }

    function build(bytes32 to, bytes memory data)
        internal
        pure
        returns (StaticCall memory)
    {
        return StaticCall(to, data);
    }

    function build(address to, bytes memory data)
        internal
        pure
        returns (StaticCall memory)
    {
        return build(TypeCasts.addressToBytes32(to), data);
    }

    function build(
        bytes32 to,
        uint256 value,
        bytes memory data
    ) internal pure returns (Call memory) {
        return Call(to, value, data);
    }

    function build(
        address to,
        uint256 value,
        bytes memory data
    ) internal pure returns (Call memory) {
        return Call(TypeCasts.addressToBytes32(to), value, data);
    }

    function build(
        bytes32 to,
        bytes memory data,
        bytes memory callback
    ) internal pure returns (StaticCallWithCallback memory) {
        return StaticCallWithCallback(build(to, data), callback);
    }

    function build(
        address to,
        bytes memory data,
        bytes memory callback
    ) internal pure returns (StaticCallWithCallback memory) {
        return StaticCallWithCallback(build(to, data), callback);
    }
}


// File contracts/middleware/libs/InterchainAccountMessage.sol

pragma solidity >=0.8.0;


/**
 * Format of message:
 * [   0:  32] ICA owner
 * [  32:  64] ICA ISM
 * [  64:????] Calls, abi encoded
 */
library InterchainAccountMessage {
    using TypeCasts for bytes32;

    /**
     * @notice Returns formatted (packed) InterchainAccountMessage
     * @dev This function should only be used in memory message construction.
     * @param _owner The owner of the interchain account
     * @param _ism The address of the remote ISM
     * @param _to The address of the contract to call
     * @param _value The value to include in the call
     * @param _data The calldata
     * @return Formatted message body
     */
    function encode(
        address _owner,
        bytes32 _ism,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal pure returns (bytes memory) {
        CallLib.Call[] memory _calls = new CallLib.Call[](1);
        _calls[0] = CallLib.build(_to, _value, _data);
        return abi.encode(TypeCasts.addressToBytes32(_owner), _ism, _calls);
    }

    /**
     * @notice Returns formatted (packed) InterchainAccountMessage
     * @dev This function should only be used in memory message construction.
     * @param _owner The owner of the interchain account
     * @param _ism The address of the remote ISM
     * @param _calls The sequence of calls to make
     * @return Formatted message body
     */
    function encode(
        bytes32 _owner,
        bytes32 _ism,
        CallLib.Call[] calldata _calls
    ) internal pure returns (bytes memory) {
        return abi.encode(_owner, _ism, _calls);
    }

    /**
     * @notice Returns formatted (packed) InterchainAccountMessage
     * @dev This function should only be used in memory message construction.
     * @param _owner The owner of the interchain account
     * @param _ism The address of the remote ISM
     * @param _calls The sequence of calls to make
     * @return Formatted message body
     */
    function encode(
        address _owner,
        bytes32 _ism,
        CallLib.Call[] calldata _calls
    ) internal pure returns (bytes memory) {
        return encode(TypeCasts.addressToBytes32(_owner), _ism, _calls);
    }

    /**
     * @notice Parses and returns the calls from the provided message
     * @param _message The interchain account message
     * @return The array of calls
     */
    function decode(bytes calldata _message)
        internal
        pure
        returns (
            bytes32,
            bytes32,
            CallLib.Call[] memory
        )
    {
        return abi.decode(_message, (bytes32, bytes32, CallLib.Call[]));
    }

    /**
     * @notice Parses and returns the ISM address from the provided message
     * @param _message The interchain account message
     * @return The ISM encoded in the message
     */
    function ism(bytes calldata _message) internal pure returns (address) {
        return address(bytes20(_message[44:64]));
    }
}


// File contracts/isms/routing/InterchainAccountIsm.sol

pragma solidity >=0.8.0;
// ============ Internal Imports ============





/**
 * @title InterchainAccountIsm
 */
contract InterchainAccountIsm is AbstractRoutingIsm {
    IMailbox private immutable mailbox;

    // ============ Constructor ============
    constructor(address _mailbox) {
        mailbox = IMailbox(_mailbox);
    }

    // ============ Public Functions ============

    /**
     * @notice Returns the ISM responsible for verifying _message
     * @param _message Formatted Hyperlane message (see Message.sol).
     * @return module The ISM to use to verify _message
     */
    function route(bytes calldata _message)
        public
        view
        virtual
        override
        returns (IInterchainSecurityModule)
    {
        address _ism = InterchainAccountMessage.ism(Message.body(_message));
        if (_ism == address(0)) {
            return mailbox.defaultIsm();
        } else {
            return IInterchainSecurityModule(_ism);
        }
    }
}


// File contracts/upgrade/Versioned.sol

pragma solidity >=0.6.11;

/**
 * @title Versioned
 * @notice Version getter for contracts
 **/
contract Versioned {
    uint8 public constant VERSION = 3;
}


// File contracts/Mailbox.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============








// ============ External Imports ============


contract Mailbox is IMailbox, Indexed, Versioned, OwnableUpgradeable {
    // ============ Libraries ============

    using Message for bytes;
    using TypeCasts for bytes32;
    using TypeCasts for address;

    // ============ Constants ============

    // Domain of chain on which the contract is deployed
    uint32 public immutable localDomain;

    // ============ Public Storage ============

    // A monotonically increasing nonce for outbound unique message IDs.
    uint32 public nonce;

    // The latest dispatched message ID used for auth in post-dispatch hooks.
    bytes32 public latestDispatchedId;

    // The default ISM, used if the recipient fails to specify one.
    IInterchainSecurityModule public defaultIsm;

    // The default post dispatch hook, used for post processing of opting-in dispatches.
    IPostDispatchHook public defaultHook;

    // The required post dispatch hook, used for post processing of ALL dispatches.
    IPostDispatchHook public requiredHook;

    // Mapping of message ID to delivery context that processed the message.
    struct Delivery {
        address processor;
        uint48 blockNumber;
    }
    mapping(bytes32 => Delivery) internal deliveries;

    // ============ Events ============

    /**
     * @notice Emitted when the default ISM is updated
     * @param module The new default ISM
     */
    event DefaultIsmSet(address indexed module);

    /**
     * @notice Emitted when the default hook is updated
     * @param hook The new default hook
     */
    event DefaultHookSet(address indexed hook);

    /**
     * @notice Emitted when the required hook is updated
     * @param hook The new required hook
     */
    event RequiredHookSet(address indexed hook);

    // ============ Constructor ============
    constructor(uint32 _localDomain) {
        localDomain = _localDomain;
    }

    // ============ Initializers ============
    function initialize(
        address _owner,
        address _defaultIsm,
        address _defaultHook,
        address _requiredHook
    ) external initializer {
        __Ownable_init();
        setDefaultIsm(_defaultIsm);
        setDefaultHook(_defaultHook);
        setRequiredHook(_requiredHook);
        transferOwnership(_owner);
    }

    // ============ External Functions ============
    /**
     * @notice Dispatches a message to the destination domain & recipient
     * using the default hook and empty metadata.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes content of message body
     * @return The message ID inserted into the Mailbox's merkle tree
     */
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external payable override returns (bytes32) {
        return
            dispatch(
                _destinationDomain,
                _recipientAddress,
                _messageBody,
                _messageBody[0:0],
                defaultHook
            );
    }

    /**
     * @notice Dispatches a message to the destination domain & recipient.
     * @param destinationDomain Domain of destination chain
     * @param recipientAddress Address of recipient on destination chain as bytes32
     * @param messageBody Raw bytes content of message body
     * @param hookMetadata Metadata used by the post dispatch hook
     * @return The message ID inserted into the Mailbox's merkle tree
     */
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata hookMetadata
    ) external payable override returns (bytes32) {
        return
            dispatch(
                destinationDomain,
                recipientAddress,
                messageBody,
                hookMetadata,
                defaultHook
            );
    }

    /**
     * @notice Computes quote for dipatching a message to the destination domain & recipient
     * using the default hook and empty metadata.
     * @param destinationDomain Domain of destination chain
     * @param recipientAddress Address of recipient on destination chain as bytes32
     * @param messageBody Raw bytes content of message body
     * @return fee The payment required to dispatch the message
     */
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee) {
        return
            quoteDispatch(
                destinationDomain,
                recipientAddress,
                messageBody,
                messageBody[0:0],
                defaultHook
            );
    }

    /**
     * @notice Computes quote for dispatching a message to the destination domain & recipient.
     * @param destinationDomain Domain of destination chain
     * @param recipientAddress Address of recipient on destination chain as bytes32
     * @param messageBody Raw bytes content of message body
     * @param defaultHookMetadata Metadata used by the default post dispatch hook
     * @return fee The payment required to dispatch the message
     */
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata defaultHookMetadata
    ) external view returns (uint256 fee) {
        return
            quoteDispatch(
                destinationDomain,
                recipientAddress,
                messageBody,
                defaultHookMetadata,
                defaultHook
            );
    }

    /**
     * @notice Attempts to deliver `_message` to its recipient. Verifies
     * `_message` via the recipient's ISM using the provided `_metadata`.
     * @param _metadata Metadata used by the ISM to verify `_message`.
     * @param _message Formatted Hyperlane message (refer to Message.sol).
     */
    function process(bytes calldata _metadata, bytes calldata _message)
        external
        payable
        override
    {
        /// CHECKS ///

        // Check that the message was intended for this mailbox.
        require(_message.version() == VERSION, "Mailbox: bad version");
        require(
            _message.destination() == localDomain,
            "Mailbox: unexpected destination"
        );

        // Check that the message hasn't already been delivered.
        bytes32 _id = _message.id();
        require(delivered(_id) == false, "Mailbox: already delivered");

        // Get the recipient's ISM.
        address recipient = _message.recipientAddress();
        IInterchainSecurityModule ism = recipientIsm(recipient);

        /// EFFECTS ///

        deliveries[_id] = Delivery({
            processor: msg.sender,
            blockNumber: uint48(block.number)
        });
        emit Process(_message.origin(), _message.sender(), recipient);
        emit ProcessId(_id);

        /// INTERACTIONS ///

        // Verify the message via the interchain security module.
        require(
            ism.verify(_metadata, _message),
            "Mailbox: ISM verification failed"
        );

        // Deliver the message to the recipient.
        IMessageRecipient(recipient).handle{value: msg.value}(
            _message.origin(),
            _message.sender(),
            _message.body()
        );
    }

    /**
     * @notice Returns the account that processed the message.
     * @param _id The message ID to check.
     * @return The account that processed the message.
     */
    function processor(bytes32 _id) external view returns (address) {
        return deliveries[_id].processor;
    }

    /**
     * @notice Returns the account that processed the message.
     * @param _id The message ID to check.
     * @return The number of the block that the message was processed at.
     */
    function processedAt(bytes32 _id) external view returns (uint48) {
        return deliveries[_id].blockNumber;
    }

    // ============ Public Functions ============

    /**
     * @notice Dispatches a message to the destination domain & recipient.
     * @param destinationDomain Domain of destination chain
     * @param recipientAddress Address of recipient on destination chain as bytes32
     * @param messageBody Raw bytes content of message body
     * @param metadata Metadata used by the post dispatch hook
     * @param hook Custom hook to use instead of the default
     * @return The message ID inserted into the Mailbox's merkle tree
     */
    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata metadata,
        IPostDispatchHook hook
    ) public payable virtual returns (bytes32) {
        if (address(hook) == address(0)) {
            hook = defaultHook;
        }

        /// CHECKS ///

        // Format the message into packed bytes.
        bytes memory message = _buildMessage(
            destinationDomain,
            recipientAddress,
            messageBody
        );
        bytes32 id = message.id();

        /// EFFECTS ///

        latestDispatchedId = id;
        nonce += 1;
        emit Dispatch(msg.sender, destinationDomain, recipientAddress, message);
        emit DispatchId(id);

        /// INTERACTIONS ///
        uint256 requiredValue = requiredHook.quoteDispatch(metadata, message);
        // if underpaying, defer to required hook's reverting behavior
        if (msg.value < requiredValue) {
            requiredValue = msg.value;
        }
        requiredHook.postDispatch{value: requiredValue}(metadata, message);
        hook.postDispatch{value: msg.value - requiredValue}(metadata, message);

        return id;
    }

    /**
     * @notice Computes quote for dispatching a message to the destination domain & recipient.
     * @param destinationDomain Domain of destination chain
     * @param recipientAddress Address of recipient on destination chain as bytes32
     * @param messageBody Raw bytes content of message body
     * @param metadata Metadata used by the post dispatch hook
     * @param hook Custom hook to use instead of the default
     * @return fee The payment required to dispatch the message
     */
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata metadata,
        IPostDispatchHook hook
    ) public view returns (uint256 fee) {
        if (address(hook) == address(0)) {
            hook = defaultHook;
        }

        bytes memory message = _buildMessage(
            destinationDomain,
            recipientAddress,
            messageBody
        );
        return
            requiredHook.quoteDispatch(metadata, message) +
            hook.quoteDispatch(metadata, message);
    }

    /**
     * @notice Returns true if the message has been processed.
     * @param _id The message ID to check.
     * @return True if the message has been delivered.
     */
    function delivered(bytes32 _id) public view override returns (bool) {
        return deliveries[_id].blockNumber > 0;
    }

    /**
     * @notice Sets the default ISM for the Mailbox.
     * @param _module The new default ISM. Must be a contract.
     */
    function setDefaultIsm(address _module) public onlyOwner {
        require(
            Address.isContract(_module),
            "Mailbox: default ISM not contract"
        );
        defaultIsm = IInterchainSecurityModule(_module);
        emit DefaultIsmSet(_module);
    }

    /**
     * @notice Sets the default post dispatch hook for the Mailbox.
     * @param _hook The new default post dispatch hook. Must be a contract.
     */
    function setDefaultHook(address _hook) public onlyOwner {
        require(
            Address.isContract(_hook),
            "Mailbox: default hook not contract"
        );
        defaultHook = IPostDispatchHook(_hook);
        emit DefaultHookSet(_hook);
    }

    /**
     * @notice Sets the required post dispatch hook for the Mailbox.
     * @param _hook The new default post dispatch hook. Must be a contract.
     */
    function setRequiredHook(address _hook) public onlyOwner {
        require(
            Address.isContract(_hook),
            "Mailbox: required hook not contract"
        );
        requiredHook = IPostDispatchHook(_hook);
        emit RequiredHookSet(_hook);
    }

    /**
     * @notice Returns the ISM to use for the recipient, defaulting to the
     * default ISM if none is specified.
     * @param _recipient The message recipient whose ISM should be returned.
     * @return The ISM to use for `_recipient`.
     */
    function recipientIsm(address _recipient)
        public
        view
        returns (IInterchainSecurityModule)
    {
        // use low-level staticcall in case of revert or empty return data
        (bool success, bytes memory returnData) = _recipient.staticcall(
            abi.encodeCall(
                ISpecifiesInterchainSecurityModule.interchainSecurityModule,
                ()
            )
        );
        // check if call was successful and returned data
        if (success && returnData.length != 0) {
            // check if returnData is a valid address
            address ism = abi.decode(returnData, (address));
            // check if the ISM is a contract
            if (ism != address(0)) {
                return IInterchainSecurityModule(ism);
            }
        }
        // Use the default if a valid one is not specified by the recipient.
        return defaultIsm;
    }

    // ============ Internal Functions ============
    function _buildMessage(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) internal view returns (bytes memory) {
        return
            Message.formatMessage(
                VERSION,
                nonce,
                localDomain,
                msg.sender.addressToBytes32(),
                destinationDomain,
                recipientAddress,
                messageBody
            );
    }
}


// File contracts/middleware/libs/OwnableMulticall.sol

pragma solidity ^0.8.13;

// ============ Internal Imports ============

/*
 * @title OwnableMulticall
 * @dev Permits immutable owner address to execute calls with value to other contracts.
 */
contract OwnableMulticall {
    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    function multicall(CallLib.Call[] calldata calls) external onlyOwner {
        return CallLib.multicall(calls);
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}


// File contracts/middleware/InterchainAccountRouter.sol

pragma solidity ^0.8.13;

// ============ Internal Imports ============







// ============ External Imports ============



/*
 * @title A contract that allows accounts on chain A to call contracts via a
 * proxy contract on chain B.
 */
contract InterchainAccountRouter is Router {
    // ============ Libraries ============

    using TypeCasts for address;
    using TypeCasts for bytes32;

    // ============ Constants ============

    address internal implementation;
    bytes32 internal bytecodeHash;

    // ============ Public Storage ============
    mapping(uint32 => bytes32) public isms;

    // ============ Upgrade Gap ============

    uint256[47] private __GAP;

    // ============ Events ============

    /**
     * @notice Emitted when a default ISM is set for a remote domain
     * @param domain The remote domain
     * @param ism The address of the remote ISM
     */
    event RemoteIsmEnrolled(uint32 indexed domain, bytes32 ism);

    /**
     * @notice Emitted when an interchain call is dispatched to a remote domain
     * @param destination The destination domain on which to make the call
     * @param owner The local owner of the remote ICA
     * @param router The address of the remote router
     * @param ism The address of the remote ISM
     */
    event RemoteCallDispatched(
        uint32 indexed destination,
        address indexed owner,
        bytes32 router,
        bytes32 ism
    );

    /**
     * @notice Emitted when an interchain account contract is deployed
     * @param origin The domain of the chain where the message was sent from
     * @param owner The address of the account that sent the message
     * @param ism The address of the local ISM
     * @param account The address of the proxy account that was created
     */
    event InterchainAccountCreated(
        uint32 indexed origin,
        bytes32 indexed owner,
        address ism,
        address account
    );

    // ============ Constructor ============

    constructor(address _mailbox) Router(_mailbox) {}

    // ============ Initializers ============

    /**
     * @notice Initializes the contract with HyperlaneConnectionClient contracts
     * @param _interchainGasPaymaster Unused but required by HyperlaneConnectionClient
     * @param _interchainSecurityModule The address of the local ISM contract
     * @param _owner The address with owner privileges
     */
    function initialize(
        address _interchainGasPaymaster,
        address _interchainSecurityModule,
        address _owner
    ) external initializer {
        _MailboxClient_initialize(
            _interchainGasPaymaster,
            _interchainSecurityModule,
            _owner
        );

        implementation = address(new OwnableMulticall(address(this)));
        // cannot be stored immutably because it is dynamically sized
        bytes memory _bytecode = MinimalProxy.bytecode(implementation);
        bytecodeHash = keccak256(_bytecode);
    }

    /**
     * @notice Registers the address of remote InterchainAccountRouter
     * and ISM contracts to use as a default when making interchain calls
     * @param _destination The remote domain
     * @param _router The address of the remote InterchainAccountRouter
     * @param _ism The address of the remote ISM
     */
    function enrollRemoteRouterAndIsm(
        uint32 _destination,
        bytes32 _router,
        bytes32 _ism
    ) external onlyOwner {
        _enrollRemoteRouterAndIsm(_destination, _router, _ism);
    }

    /**
     * @notice Registers the address of remote InterchainAccountRouters
     * and ISM contracts to use as defaults when making interchain calls
     * @param _destinations The remote domains
     * @param _routers The address of the remote InterchainAccountRouters
     * @param _isms The address of the remote ISMs
     */
    function enrollRemoteRouterAndIsms(
        uint32[] calldata _destinations,
        bytes32[] calldata _routers,
        bytes32[] calldata _isms
    ) external onlyOwner {
        require(
            _destinations.length == _routers.length &&
                _destinations.length == _isms.length,
            "length mismatch"
        );
        for (uint256 i = 0; i < _destinations.length; i++) {
            _enrollRemoteRouterAndIsm(_destinations[i], _routers[i], _isms[i]);
        }
    }

    // ============ External Functions ============
    /**
     * @notice Dispatches a single remote call to be made by an owner's
     * interchain account on the destination domain
     * @dev Uses the default router and ISM addresses for the destination
     * domain, reverting if none have been configured
     * @param _destination The remote domain of the chain to make calls on
     * @param _to The address of the contract to call
     * @param _value The value to include in the call
     * @param _data The calldata
     * @return The Hyperlane message ID
     */
    function callRemote(
        uint32 _destination,
        address _to,
        uint256 _value,
        bytes memory _data
    ) external returns (bytes32) {
        bytes32 _router = routers(_destination);
        bytes32 _ism = isms[_destination];
        bytes memory _body = InterchainAccountMessage.encode(
            msg.sender,
            _ism,
            _to,
            _value,
            _data
        );
        return _dispatchMessage(_destination, _router, _ism, _body);
    }

    /**
     * @notice Dispatches a sequence of remote calls to be made by an owner's
     * interchain account on the destination domain
     * @dev Uses the default router and ISM addresses for the destination
     * domain, reverting if none have been configured
     * @dev Recommend using CallLib.build to format the interchain calls.
     * @param _destination The remote domain of the chain to make calls on
     * @param _calls The sequence of calls to make
     * @return The Hyperlane message ID
     */
    function callRemote(uint32 _destination, CallLib.Call[] calldata _calls)
        external
        returns (bytes32)
    {
        bytes32 _router = routers(_destination);
        bytes32 _ism = isms[_destination];
        return callRemoteWithOverrides(_destination, _router, _ism, _calls);
    }

    /**
     * @notice Handles dispatched messages by relaying calls to the interchain account
     * @param _origin The origin domain of the interchain account
     * @param _sender The sender of the interchain message
     * @param _message The InterchainAccountMessage containing the account
     * owner, ISM, and sequence of calls to be relayed
     * @dev Does not need to be onlyRemoteRouter, as this application is designed
     * to receive messages from untrusted remote contracts.
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external payable override onlyMailbox {
        (
            bytes32 _owner,
            bytes32 _ism,
            CallLib.Call[] memory _calls
        ) = InterchainAccountMessage.decode(_message);

        OwnableMulticall _interchainAccount = getDeployedInterchainAccount(
            _origin,
            _owner,
            _sender,
            _ism.bytes32ToAddress()
        );
        _interchainAccount.multicall(_calls);
    }

    /**
     * @notice Returns the local address of an interchain account
     * @dev This interchain account is not guaranteed to have been deployed
     * @param _origin The remote origin domain of the interchain account
     * @param _router The remote origin InterchainAccountRouter
     * @param _owner The remote owner of the interchain account
     * @param _ism The local address of the ISM
     * @return The local address of the interchain account
     */
    function getLocalInterchainAccount(
        uint32 _origin,
        address _owner,
        address _router,
        address _ism
    ) external view returns (OwnableMulticall) {
        return
            getLocalInterchainAccount(
                _origin,
                _owner.addressToBytes32(),
                _router.addressToBytes32(),
                _ism
            );
    }

    /**
     * @notice Returns the remote address of a locally owned interchain account
     * @dev This interchain account is not guaranteed to have been deployed
     * @dev This function will only work if the destination domain is
     * EVM compatible
     * @param _destination The remote destination domain of the interchain account
     * @param _owner The local owner of the interchain account
     * @return The remote address of the interchain account
     */
    function getRemoteInterchainAccount(uint32 _destination, address _owner)
        external
        view
        returns (address)
    {
        address _router = routers(_destination).bytes32ToAddress();
        address _ism = isms[_destination].bytes32ToAddress();
        return getRemoteInterchainAccount(_owner, _router, _ism);
    }

    // ============ Public Functions ============

    /**
     * @notice Returns and deploys (if not already) an interchain account
     * @param _origin The remote origin domain of the interchain account
     * @param _owner The remote owner of the interchain account
     * @param _router The remote origin InterchainAccountRouter
     * @param _ism The local address of the ISM
     * @return The address of the interchain account
     */
    function getDeployedInterchainAccount(
        uint32 _origin,
        address _owner,
        address _router,
        address _ism
    ) public returns (OwnableMulticall) {
        return
            getDeployedInterchainAccount(
                _origin,
                _owner.addressToBytes32(),
                _router.addressToBytes32(),
                _ism
            );
    }

    /**
     * @notice Returns and deploys (if not already) an interchain account
     * @param _origin The remote origin domain of the interchain account
     * @param _owner The remote owner of the interchain account
     * @param _router The remote origin InterchainAccountRouter
     * @param _ism The local address of the ISM
     * @return The address of the interchain account
     */
    function getDeployedInterchainAccount(
        uint32 _origin,
        bytes32 _owner,
        bytes32 _router,
        address _ism
    ) public returns (OwnableMulticall) {
        bytes32 _salt = _getSalt(
            _origin,
            _owner,
            _router,
            _ism.addressToBytes32()
        );
        address payable _account = _getLocalInterchainAccount(_salt);
        if (!Address.isContract(_account)) {
            bytes memory _bytecode = MinimalProxy.bytecode(implementation);
            _account = payable(Create2.deploy(0, _salt, _bytecode));
            emit InterchainAccountCreated(_origin, _owner, _ism, _account);
        }
        return OwnableMulticall(_account);
    }

    /**
     * @notice Returns the local address of a remotely owned interchain account
     * @dev This interchain account is not guaranteed to have been deployed
     * @param _origin The remote origin domain of the interchain account
     * @param _owner The remote owner of the interchain account
     * @param _router The remote InterchainAccountRouter
     * @param _ism The local address of the ISM
     * @return The local address of the interchain account
     */
    function getLocalInterchainAccount(
        uint32 _origin,
        bytes32 _owner,
        bytes32 _router,
        address _ism
    ) public view returns (OwnableMulticall) {
        return
            OwnableMulticall(
                _getLocalInterchainAccount(
                    _getSalt(_origin, _owner, _router, _ism.addressToBytes32())
                )
            );
    }

    /**
     * @notice Returns the remote address of a locally owned interchain account
     * @dev This interchain account is not guaranteed to have been deployed
     * @dev This function will only work if the destination domain is
     * EVM compatible
     * @param _owner The local owner of the interchain account
     * @param _router The remote InterchainAccountRouter
     * @param _ism The remote address of the ISM
     * @return The remote address of the interchain account
     */
    function getRemoteInterchainAccount(
        address _owner,
        address _router,
        address _ism
    ) public view returns (address) {
        require(_router != address(0), "no router specified for destination");
        // Derives the address of the first contract deployed by _router using
        // the CREATE opcode.
        address _implementation = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xd6),
                            bytes1(0x94),
                            _router,
                            bytes1(0x01)
                        )
                    )
                )
            )
        );
        bytes memory _proxyBytecode = MinimalProxy.bytecode(_implementation);
        bytes32 _bytecodeHash = keccak256(_proxyBytecode);
        bytes32 _salt = _getSalt(
            localDomain,
            _owner.addressToBytes32(),
            address(this).addressToBytes32(),
            _ism.addressToBytes32()
        );
        return Create2.computeAddress(_salt, _bytecodeHash, _router);
    }

    /**
     * @notice Dispatches a sequence of remote calls to be made by an owner's
     * interchain account on the destination domain
     * @dev Recommend using CallLib.build to format the interchain calls
     * @param _destination The remote domain of the chain to make calls on
     * @param _router The remote router address
     * @param _ism The remote ISM address
     * @param _calls The sequence of calls to make
     * @return The Hyperlane message ID
     */
    function callRemoteWithOverrides(
        uint32 _destination,
        bytes32 _router,
        bytes32 _ism,
        CallLib.Call[] calldata _calls
    ) public returns (bytes32) {
        bytes memory _body = InterchainAccountMessage.encode(
            msg.sender,
            _ism,
            _calls
        );
        return _dispatchMessage(_destination, _router, _ism, _body);
    }

    // ============ Internal Functions ============

    /**
     * @dev Required for use of Router, compiler will not include this function in the bytecode
     */
    function _handle(
        uint32,
        bytes32,
        bytes calldata
    ) internal pure override {
        assert(false);
    }

    /**
     * @notice Overrides Router._enrollRemoteRouter to also enroll a default ISM
     * @param _destination The remote domain
     * @param _address The address of the remote InterchainAccountRouter
     * @dev Sets the default ISM to the zero address
     */
    function _enrollRemoteRouter(uint32 _destination, bytes32 _address)
        internal
        override
    {
        _enrollRemoteRouterAndIsm(_destination, _address, bytes32(0));
    }

    // ============ Private Functions ============

    /**
     * @notice Registers the address of a remote ISM contract to use as default
     * @param _destination The remote domain
     * @param _ism The address of the remote ISM
     */
    function _enrollRemoteIsm(uint32 _destination, bytes32 _ism) private {
        isms[_destination] = _ism;
        emit RemoteIsmEnrolled(_destination, _ism);
    }

    /**
     * @notice Registers the address of remote InterchainAccountRouter
     * and ISM contracts to use as a default when making interchain calls
     * @param _destination The remote domain
     * @param _router The address of the remote InterchainAccountRouter
     * @param _ism The address of the remote ISM
     */
    function _enrollRemoteRouterAndIsm(
        uint32 _destination,
        bytes32 _router,
        bytes32 _ism
    ) private {
        require(
            routers(_destination) == bytes32(0) &&
                isms[_destination] == bytes32(0),
            "router and ISM defaults are immutable once set"
        );
        Router._enrollRemoteRouter(_destination, _router);
        _enrollRemoteIsm(_destination, _ism);
    }

    /**
     * @notice Dispatches an InterchainAccountMessage to the remote router
     * @param _destination The remote domain
     * @param _router The address of the remote InterchainAccountRouter
     * @param _ism The address of the remote ISM
     * @param _body The InterchainAccountMessage body
     */
    function _dispatchMessage(
        uint32 _destination,
        bytes32 _router,
        bytes32 _ism,
        bytes memory _body
    ) private returns (bytes32) {
        require(_router != bytes32(0), "no router specified for destination");
        emit RemoteCallDispatched(_destination, msg.sender, _router, _ism);
        return mailbox.dispatch(_destination, _router, _body);
    }

    /**
     * @notice Returns the salt used to deploy an interchain account
     * @param _origin The remote origin domain of the interchain account
     * @param _owner The remote owner of the interchain account
     * @param _router The remote origin InterchainAccountRouter
     * @param _ism The local address of the ISM
     * @return The CREATE2 salt used for deploying the interchain account
     */
    function _getSalt(
        uint32 _origin,
        bytes32 _owner,
        bytes32 _router,
        bytes32 _ism
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_origin, _owner, _router, _ism));
    }

    /**
     * @notice Returns the address of the interchain account on the local chain
     * @param _salt The CREATE2 salt used for deploying the interchain account
     * @return The address of the interchain account
     */
    function _getLocalInterchainAccount(bytes32 _salt)
        private
        view
        returns (address payable)
    {
        return payable(Create2.computeAddress(_salt, bytecodeHash));
    }
}


// File contracts/middleware/libs/InterchainQueryMessage.sol

pragma solidity ^0.8.13;

/**
 * Format of message:
 * [   0: 32] Sender address
 * [  32: 64] Message type (left padded with zeroes)
 * [  64:???] Encoded call array
 */
library InterchainQueryMessage {
    uint256 private constant SENDER_OFFSET = 0;
    uint256 private constant TYPE_OFFSET = 32;
    uint256 private constant CALLS_OFFSET = 64;

    enum MessageType {
        QUERY,
        RESPONSE
    }

    /**
     * @notice Parses and returns the query sender from the provided message
     * @param _message The interchain query message
     * @return The query sender as bytes32
     */
    function sender(bytes calldata _message) internal pure returns (bytes32) {
        return bytes32(_message[SENDER_OFFSET:TYPE_OFFSET]);
    }

    /**
     * @notice Parses and returns the message type from the provided message
     * @param _message The interchain query message
     * @return The message type (query or response)
     */
    function messageType(bytes calldata _message)
        internal
        pure
        returns (MessageType)
    {
        // left padded with zeroes
        return MessageType(uint8(bytes1(_message[CALLS_OFFSET - 1])));
    }

    /**
     * @notice Returns formatted InterchainQueryMessage, type == QUERY
     * @param _sender The query sender as bytes32
     * @param _calls The sequence of queries to make, with the corresponding
     * response callbacks
     * @return Formatted message body
     */
    function encode(
        bytes32 _sender,
        CallLib.StaticCallWithCallback[] calldata _calls
    ) internal pure returns (bytes memory) {
        return abi.encode(_sender, MessageType.QUERY, _calls);
    }

    /**
     * @notice Returns formatted InterchainQueryMessage, type == QUERY
     * @param _sender The query sender as bytes32
     * @param _to The address of the contract to query
     * @param _data The calldata encoding the query
     * @param _callback The calldata of the callback that will be made on the sender.
     * The return value of the query will be appended.
     * @return Formatted message body
     */
    function encode(
        bytes32 _sender,
        address _to,
        bytes memory _data,
        bytes memory _callback
    ) internal pure returns (bytes memory) {
        CallLib.StaticCallWithCallback[]
            memory _calls = new CallLib.StaticCallWithCallback[](1);
        _calls[0] = CallLib.build(_to, _data, _callback);
        return abi.encode(_sender, MessageType.QUERY, _calls);
    }

    /**
     * @notice Parses and returns the calls and callbacks from the message
     * @param _message The interchain query message, type == QUERY
     * @return _calls The sequence of queries to make with the corresponding
     * response callbacks
     */
    function callsWithCallbacks(bytes calldata _message)
        internal
        pure
        returns (CallLib.StaticCallWithCallback[] memory _calls)
    {
        assert(messageType(_message) == MessageType.QUERY);
        (, , _calls) = abi.decode(
            _message,
            (bytes32, MessageType, CallLib.StaticCallWithCallback[])
        );
    }

    /**
     * @notice Returns formatted InterchainQueryMessage, type == RESPONSE
     * @param _sender The query sender as bytes32
     * @param _calls The sequence of callbacks to make
     * @return Formatted message body
     */
    function encode(bytes32 _sender, bytes[] memory _calls)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(_sender, MessageType.RESPONSE, _calls);
    }

    /**
     * @notice Parses and returns the callbacks from the message
     * @param _message The interchain query message, type == RESPONSE
     * @return _calls The sequence of callbacks to make
     */
    function rawCalls(bytes calldata _message)
        internal
        pure
        returns (bytes[] memory _calls)
    {
        assert(messageType(_message) == MessageType.RESPONSE);
        (, , _calls) = abi.decode(_message, (bytes32, MessageType, bytes[]));
    }
}


// File contracts/middleware/InterchainQueryRouter.sol

pragma solidity ^0.8.13;

// ============ Internal Imports ============




// ============ External Imports ============



/**
 * @title Interchain Query Router that performs remote view calls on other chains and returns the result.
 * @dev Currently does not support Sovereign Consensus (user specified Interchain Security Modules).
 */
contract InterchainQueryRouter is Router {
    using TypeCasts for address;
    using TypeCasts for bytes32;
    using InterchainQueryMessage for bytes;

    /**
     * @notice Emitted when a query is dispatched to another chain.
     * @param destination The domain of the chain to query.
     * @param sender The address that dispatched the query.
     */
    event QueryDispatched(uint32 indexed destination, address indexed sender);
    /**
     * @notice Emitted when a query is executed on the and callback dispatched to the origin chain.
     * @param originDomain The domain of the chain that dispatched the query and receives the callback.
     * @param sender The address to receive the result.
     */
    event QueryExecuted(uint32 indexed originDomain, bytes32 indexed sender);
    /**
     * @notice Emitted when a query is resolved on the origin chain.
     * @param destination The domain of the chain that was queried.
     * @param sender The address that resolved the query.
     */
    event QueryResolved(uint32 indexed destination, address indexed sender);

    constructor(address _mailbox) Router(_mailbox) {}

    /**
     * @notice Initializes the Router contract with Hyperlane core contracts and the address of the interchain security module.
     * @param _interchainGasPaymaster The address of the interchain gas paymaster contract.
     * @param _interchainSecurityModule The address of the interchain security module contract.
     * @param _owner The address with owner privileges.
     */
    function initialize(
        address _interchainGasPaymaster,
        address _interchainSecurityModule,
        address _owner
    ) external initializer {
        _MailboxClient_initialize(
            _interchainGasPaymaster,
            _interchainSecurityModule,
            _owner
        );
    }

    /**
     * @notice Dispatches a sequence of static calls (query) to the destination domain and set of callbacks to resolve the results on the dispatcher.
     * @param _destination The domain of the chain to query.
     * @param _to The address of the contract to query
     * @param _data The calldata encoding the query
     * @param _callback The calldata of the callback that will be made on the sender.
     * The return value of the query will be appended.
     * @dev Callbacks must be returned to the `msg.sender` for security reasons. Require this contract is the `msg.sender` on callbacks.
     */
    function query(
        uint32 _destination,
        address _to,
        bytes memory _data,
        bytes memory _callback
    ) public returns (bytes32 messageId) {
        emit QueryDispatched(_destination, msg.sender);

        messageId = _dispatch(
            _destination,
            InterchainQueryMessage.encode(
                msg.sender.addressToBytes32(),
                _to,
                _data,
                _callback
            )
        );
    }

    /**
     * @notice Dispatches a sequence of static calls (query) to the destination domain and set of callbacks to resolve the results on the dispatcher.
     * @param _destination The domain of the chain to query.
     * @param calls The sequence of static calls to dispatch and callbacks on the sender to resolve the results.
     * @dev Recommend using CallLib.build to format the interchain calls.
     * @dev Callbacks must be returned to the `msg.sender` for security reasons. Require this contract is the `msg.sender` on callbacks.
     */
    function query(
        uint32 _destination,
        CallLib.StaticCallWithCallback[] calldata calls
    ) public returns (bytes32 messageId) {
        emit QueryDispatched(_destination, msg.sender);
        messageId = _dispatch(
            _destination,
            InterchainQueryMessage.encode(msg.sender.addressToBytes32(), calls)
        );
    }

    /**
     * @notice Handles a message from remote enrolled Interchain Query Router.
     * @param _origin The domain of the chain that sent the message.
     * @param _message The ABI-encoded interchain query.
     */
    function _handle(
        uint32 _origin,
        bytes32, // router sender
        bytes calldata _message
    ) internal override {
        InterchainQueryMessage.MessageType messageType = _message.messageType();
        bytes32 sender = _message.sender();
        if (messageType == InterchainQueryMessage.MessageType.QUERY) {
            CallLib.StaticCallWithCallback[]
                memory callsWithCallback = InterchainQueryMessage
                    .callsWithCallbacks(_message);
            bytes[] memory callbacks = CallLib.multistaticcall(
                callsWithCallback
            );
            emit QueryExecuted(_origin, sender);
            _dispatch(
                _origin,
                InterchainQueryMessage.encode(sender, callbacks)
            );
        } else if (messageType == InterchainQueryMessage.MessageType.RESPONSE) {
            address senderAddress = sender.bytes32ToAddress();
            bytes[] memory rawCalls = _message.rawCalls();
            CallLib.multicallto(senderAddress, rawCalls);
            emit QueryResolved(_origin, senderAddress);
        } else {
            assert(false);
        }
    }
}


// File contracts/middleware/liquidity-layer/interfaces/circle/ICircleMessageTransmitter.sol

pragma solidity ^0.8.13;

interface ICircleMessageTransmitter {
    /**
     * @notice Receive a message. Messages with a given nonce
     * can only be broadcast once for a (sourceDomain, destinationDomain)
     * pair. The message body of a valid message is passed to the
     * specified recipient for further processing.
     *
     * @dev Attestation format:
     * A valid attestation is the concatenated 65-byte signature(s) of exactly
     * `thresholdSignature` signatures, in increasing order of attester address.
     * ***If the attester addresses recovered from signatures are not in
     * increasing order, signature verification will fail.***
     * If incorrect number of signatures or duplicate signatures are supplied,
     * signature verification will fail.
     *
     * Message format:
     * Field Bytes Type Index
     * version 4 uint32 0
     * sourceDomain 4 uint32 4
     * destinationDomain 4 uint32 8
     * nonce 8 uint64 12
     * sender 32 bytes32 20
     * recipient 32 bytes32 52
     * messageBody dynamic bytes 84
     * @param _message Message bytes
     * @param _attestation Concatenated 65-byte signature(s) of `_message`, in increasing order
     * of the attester address recovered from signatures.
     * @return success bool, true if successful
     */
    function receiveMessage(bytes memory _message, bytes calldata _attestation)
        external
        returns (bool success);

    function usedNonces(bytes32 _nonceId) external view returns (bool);
}


// File contracts/middleware/liquidity-layer/interfaces/circle/ITokenMessenger.sol

pragma solidity ^0.8.13;

interface ITokenMessenger {
    event MessageSent(bytes message);

    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given burnToken is not supported
     * - given destinationDomain has no TokenMessenger registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain (ETH = 0, AVAX = 1)
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurn(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken
    ) external returns (uint64 _nonce);

    /**
     * @notice Deposits and burns tokens from sender to be minted on destination domain. The mint
     * on the destination domain must be called by `_destinationCaller`.
     * WARNING: if the `_destinationCaller` does not represent a valid address as bytes32, then it will not be possible
     * to broadcast the message on the destination domain. This is an advanced feature, and the standard
     * depositForBurn() should be preferred for use cases where a specific destination caller is not required.
     * Emits a `DepositForBurn` event.
     * @dev reverts if:
     * - given destinationCaller is zero address
     * - given burnToken is not supported
     * - given destinationDomain has no TokenMessenger registered
     * - transferFrom() reverts. For example, if sender's burnToken balance or approved allowance
     * to this contract is less than `amount`.
     * - burn() reverts. For example, if `amount` is 0.
     * - MessageTransmitter returns false or reverts.
     * @param _amount amount of tokens to burn
     * @param _destinationDomain destination domain
     * @param _mintRecipient address of mint recipient on destination domain
     * @param _burnToken address of contract to burn deposited tokens, on local domain
     * @param _destinationCaller caller on the destination domain, as bytes32
     * @return _nonce unique nonce reserved by message
     */
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64 _nonce);
}


// File contracts/middleware/liquidity-layer/interfaces/ILiquidityLayerAdapter.sol

pragma solidity ^0.8.13;

interface ILiquidityLayerAdapter {
    function sendTokens(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        address _token,
        uint256 _amount
    ) external returns (bytes memory _adapterData);

    function receiveTokens(
        uint32 _originDomain, // Hyperlane domain
        address _recipientAddress,
        uint256 _amount,
        bytes calldata _adapterData // The adapter data from the message
    ) external returns (address, uint256);
}


// File contracts/middleware/liquidity-layer/adapters/CircleBridgeAdapter.sol

pragma solidity ^0.8.13;




contract CircleBridgeAdapter is ILiquidityLayerAdapter, Router {
    using SafeERC20 for IERC20;

    /// @notice The TokenMessenger contract.
    ITokenMessenger public tokenMessenger;

    /// @notice The Circle MessageTransmitter contract.
    ICircleMessageTransmitter public circleMessageTransmitter;

    /// @notice The LiquidityLayerRouter contract.
    address public liquidityLayerRouter;

    /// @notice Hyperlane domain => Circle domain.
    /// ATM, known Circle domains are Ethereum = 0 and Avalanche = 1.
    /// Note this could result in ambiguity between the Circle domain being
    /// Ethereum or unknown.
    mapping(uint32 => uint32) public hyperlaneDomainToCircleDomain;

    /// @notice Token symbol => address of token on local chain.
    mapping(string => IERC20) public tokenSymbolToAddress;

    /// @notice Local chain token address => token symbol.
    mapping(address => string) public tokenAddressToSymbol;

    /**
     * @notice Emits the nonce of the Circle message when a token is bridged.
     * @param nonce The nonce of the Circle message.
     */
    event BridgedToken(uint64 nonce);

    /**
     * @notice Emitted when the Hyperlane domain to Circle domain mapping is updated.
     * @param hyperlaneDomain The Hyperlane domain.
     * @param circleDomain The Circle domain.
     */
    event DomainAdded(uint32 indexed hyperlaneDomain, uint32 circleDomain);

    /**
     * @notice Emitted when a local token and its token symbol have been added.
     */
    event TokenAdded(address indexed token, string indexed symbol);

    /**
     * @notice Emitted when a local token and its token symbol have been removed.
     */
    event TokenRemoved(address indexed token, string indexed symbol);

    modifier onlyLiquidityLayerRouter() {
        require(msg.sender == liquidityLayerRouter, "!liquidityLayerRouter");
        _;
    }

    constructor(address _mailbox) Router(_mailbox) {}

    /**
     * @param _owner The new owner.
     * @param _tokenMessenger The TokenMessenger contract.
     * @param _circleMessageTransmitter The Circle MessageTransmitter contract.
     * @param _liquidityLayerRouter The LiquidityLayerRouter contract.
     */
    function initialize(
        address _owner,
        address _tokenMessenger,
        address _circleMessageTransmitter,
        address _liquidityLayerRouter
    ) external initializer {
        __Ownable_init();
        _transferOwnership(_owner);

        tokenMessenger = ITokenMessenger(_tokenMessenger);
        circleMessageTransmitter = ICircleMessageTransmitter(
            _circleMessageTransmitter
        );
        liquidityLayerRouter = _liquidityLayerRouter;
    }

    function sendTokens(
        uint32 _destinationDomain,
        bytes32, // _recipientAddress, unused
        address _token,
        uint256 _amount
    ) external onlyLiquidityLayerRouter returns (bytes memory) {
        string memory _tokenSymbol = tokenAddressToSymbol[_token];
        require(
            bytes(_tokenSymbol).length > 0,
            "CircleBridgeAdapter: Unknown token"
        );

        uint32 _circleDomain = hyperlaneDomainToCircleDomain[
            _destinationDomain
        ];
        bytes32 _remoteRouter = _mustHaveRemoteRouter(_destinationDomain);

        // Approve the token to Circle. We assume that the LiquidityLayerRouter
        // has already transferred the token to this contract.
        require(
            IERC20(_token).approve(address(tokenMessenger), _amount),
            "!approval"
        );

        uint64 _nonce = tokenMessenger.depositForBurn(
            _amount,
            _circleDomain,
            _remoteRouter, // Mint to the remote router
            _token
        );

        emit BridgedToken(_nonce);
        return abi.encode(_nonce, _tokenSymbol);
    }

    // Returns the token and amount sent
    function receiveTokens(
        uint32 _originDomain, // Hyperlane domain
        address _recipient,
        uint256 _amount,
        bytes calldata _adapterData // The adapter data from the message
    ) external onlyLiquidityLayerRouter returns (address, uint256) {
        _mustHaveRemoteRouter(_originDomain);
        // The origin Circle domain
        uint32 _originCircleDomain = hyperlaneDomainToCircleDomain[
            _originDomain
        ];
        // Get the token symbol and nonce of the transfer from the _adapterData
        (uint64 _nonce, string memory _tokenSymbol) = abi.decode(
            _adapterData,
            (uint64, string)
        );

        // Require the circle message to have been processed
        bytes32 _nonceId = _circleNonceId(_originCircleDomain, _nonce);
        require(
            circleMessageTransmitter.usedNonces(_nonceId),
            "Circle message not processed yet"
        );

        IERC20 _token = tokenSymbolToAddress[_tokenSymbol];
        require(
            address(_token) != address(0),
            "CircleBridgeAdapter: Unknown token"
        );

        // Transfer the token out to the recipient
        // Circle doesn't charge any fee, so we can safely transfer out the
        // exact amount that was bridged over.
        _token.safeTransfer(_recipient, _amount);

        return (address(_token), _amount);
    }

    // This contract is only a Router to be aware of remote router addresses,
    // and doesn't actually send/handle Hyperlane messages directly
    function _handle(
        uint32, // origin
        bytes32, // sender
        bytes calldata // message
    ) internal pure override {
        revert("No messages expected");
    }

    function addDomain(uint32 _hyperlaneDomain, uint32 _circleDomain)
        external
        onlyOwner
    {
        hyperlaneDomainToCircleDomain[_hyperlaneDomain] = _circleDomain;

        emit DomainAdded(_hyperlaneDomain, _circleDomain);
    }

    function addToken(address _token, string calldata _tokenSymbol)
        external
        onlyOwner
    {
        require(
            _token != address(0) && bytes(_tokenSymbol).length > 0,
            "Cannot add default values"
        );

        // Require the token and token symbol to be unset.
        address _existingToken = address(tokenSymbolToAddress[_tokenSymbol]);
        require(_existingToken == address(0), "token symbol already has token");

        string memory _existingSymbol = tokenAddressToSymbol[_token];
        require(
            bytes(_existingSymbol).length == 0,
            "token already has token symbol"
        );

        tokenAddressToSymbol[_token] = _tokenSymbol;
        tokenSymbolToAddress[_tokenSymbol] = IERC20(_token);

        emit TokenAdded(_token, _tokenSymbol);
    }

    function removeToken(address _token, string calldata _tokenSymbol)
        external
        onlyOwner
    {
        // Require the provided token and token symbols match what's in storage.
        address _existingToken = address(tokenSymbolToAddress[_tokenSymbol]);
        require(_existingToken == _token, "Token mismatch");

        string memory _existingSymbol = tokenAddressToSymbol[_token];
        require(
            keccak256(bytes(_existingSymbol)) == keccak256(bytes(_tokenSymbol)),
            "Token symbol mismatch"
        );

        // Delete them from storage.
        delete tokenSymbolToAddress[_tokenSymbol];
        delete tokenAddressToSymbol[_token];

        emit TokenRemoved(_token, _tokenSymbol);
    }

    /**
     * @notice Gets the Circle nonce ID by hashing _originCircleDomain and _nonce.
     * @param _originCircleDomain Domain of chain where the transfer originated
     * @param _nonce The unique identifier for the message from source to
              destination
     * @return hash of source and nonce
     */
    function _circleNonceId(uint32 _originCircleDomain, uint64 _nonce)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_originCircleDomain, _nonce));
    }
}


// File contracts/middleware/liquidity-layer/interfaces/portal/IPortalTokenBridge.sol

pragma solidity ^0.8.13;

// Portal's interface from their docs
interface IPortalTokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

    struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;
        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;
        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(
        address indexed oldContract,
        address indexed newContract
    );

    function transferTokensWithPayload(
        address token,
        uint256 amount,
        uint16 recipientChain,
        bytes32 recipient,
        uint32 nonce,
        bytes memory payload
    ) external payable returns (uint64 sequence);

    function completeTransferWithPayload(bytes memory encodedVm)
        external
        returns (bytes memory);

    function parseTransferWithPayload(bytes memory encoded)
        external
        pure
        returns (TransferWithPayload memory transfer);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress)
        external
        view
        returns (address);

    function isWrappedAsset(address token) external view returns (bool);
}


// File contracts/middleware/liquidity-layer/adapters/PortalAdapter.sol

pragma solidity ^0.8.13;



contract PortalAdapter is ILiquidityLayerAdapter, Router {
    /// @notice The Portal TokenBridge contract.
    IPortalTokenBridge public portalTokenBridge;

    /// @notice The LiquidityLayerRouter contract.
    address public liquidityLayerRouter;

    /// @notice Hyperlane domain => Wormhole domain.
    mapping(uint32 => uint16) public hyperlaneDomainToWormholeDomain;
    /// @notice transferId => token address
    mapping(bytes32 => address) public portalTransfersProcessed;

    // We could technically use Portal's sequence number here but it doesn't
    // get passed through, so we would have to parse the VAA twice
    // 224 bits should be large enough and allows us to pack into a single slot
    // with a Hyperlane domain
    uint224 public nonce = 0;

    constructor(address _mailbox) Router(_mailbox) {}

    /**
     * @notice Emits the nonce of the Portal message when a token is bridged.
     * @param nonce The nonce of the Portal message.
     * @param portalSequence The sequence of the Portal message.
     * @param destination The hyperlane domain of the destination
     */
    event BridgedToken(
        uint256 nonce,
        uint64 portalSequence,
        uint32 destination
    );

    /**
     * @notice Emitted when the Hyperlane domain to Wormhole domain mapping is updated.
     * @param hyperlaneDomain The Hyperlane domain.
     * @param wormholeDomain The Wormhole domain.
     */
    event DomainAdded(uint32 indexed hyperlaneDomain, uint32 wormholeDomain);

    modifier onlyLiquidityLayerRouter() {
        require(msg.sender == liquidityLayerRouter, "!liquidityLayerRouter");
        _;
    }

    /**
     * @param _owner The new owner.
     * @param _portalTokenBridge The Portal TokenBridge contract.
     * @param _liquidityLayerRouter The LiquidityLayerRouter contract.
     */
    function initialize(
        address _owner,
        address _portalTokenBridge,
        address _liquidityLayerRouter
    ) public initializer {
        // Transfer ownership of the contract to deployer
        _transferOwnership(_owner);

        portalTokenBridge = IPortalTokenBridge(_portalTokenBridge);
        liquidityLayerRouter = _liquidityLayerRouter;
    }

    /**
     * Sends tokens as requested by the router
     * @param _destinationDomain The hyperlane domain of the destination
     * @param _token The token address
     * @param _amount The amount of tokens to send
     */
    function sendTokens(
        uint32 _destinationDomain,
        bytes32, // _recipientAddress, unused
        address _token,
        uint256 _amount
    ) external onlyLiquidityLayerRouter returns (bytes memory) {
        nonce = nonce + 1;
        uint16 _wormholeDomain = hyperlaneDomainToWormholeDomain[
            _destinationDomain
        ];

        bytes32 _remoteRouter = _mustHaveRemoteRouter(_destinationDomain);

        // Approve the token to Portal. We assume that the LiquidityLayerRouter
        // has already transferred the token to this contract.
        require(
            IERC20(_token).approve(address(portalTokenBridge), _amount),
            "!approval"
        );

        uint64 _portalSequence = portalTokenBridge.transferTokensWithPayload(
            _token,
            _amount,
            _wormholeDomain,
            _remoteRouter,
            // Nonce for grouping Portal messages in the same tx, not relevant for us
            // https://book.wormhole.com/technical/evm/coreLayer.html#emitting-a-vaa
            0,
            // Portal Payload used in completeTransfer
            abi.encode(localDomain, nonce)
        );

        emit BridgedToken(nonce, _portalSequence, _destinationDomain);
        return abi.encode(nonce);
    }

    /**
     * Sends the tokens to the recipient as requested by the router
     * @param _originDomain The hyperlane domain of the origin
     * @param _recipient The address of the recipient
     * @param _amount The amount of tokens to send
     * @param _adapterData The adapter data from the origin chain, containing the nonce
     */
    function receiveTokens(
        uint32 _originDomain, // Hyperlane domain
        address _recipient,
        uint256 _amount,
        bytes calldata _adapterData // The adapter data from the message
    ) external onlyLiquidityLayerRouter returns (address, uint256) {
        // Get the nonce information from the adapterData
        uint224 _nonce = abi.decode(_adapterData, (uint224));

        address _tokenAddress = portalTransfersProcessed[
            transferId(_originDomain, _nonce)
        ];

        require(
            _tokenAddress != address(0x0),
            "Portal Transfer has not yet been completed"
        );

        IERC20 _token = IERC20(_tokenAddress);

        // Transfer the token out to the recipient
        // TODO: use safeTransfer
        // Portal doesn't charge any fee, so we can safely transfer out the
        // exact amount that was bridged over.
        require(_token.transfer(_recipient, _amount), "!transfer out");
        return (_tokenAddress, _amount);
    }

    /**
     * Completes the Portal transfer which sends the funds to this adapter.
     * The router can call receiveTokens to move those funds to the ultimate recipient.
     * @param encodedVm The VAA from the Wormhole Guardians
     */
    function completeTransfer(bytes memory encodedVm) public {
        bytes memory _tokenBridgeTransferWithPayload = portalTokenBridge
            .completeTransferWithPayload(encodedVm);
        IPortalTokenBridge.TransferWithPayload
            memory _transfer = portalTokenBridge.parseTransferWithPayload(
                _tokenBridgeTransferWithPayload
            );

        (uint32 _originDomain, uint224 _nonce) = abi.decode(
            _transfer.payload,
            (uint32, uint224)
        );

        // Logic taken from here https://github.com/wormhole-foundation/wormhole/blob/dev.v2/ethereum/contracts/bridge/Bridge.sol#L503
        address tokenAddress = _transfer.tokenChain ==
            hyperlaneDomainToWormholeDomain[localDomain]
            ? TypeCasts.bytes32ToAddress(_transfer.tokenAddress)
            : portalTokenBridge.wrappedAsset(
                _transfer.tokenChain,
                _transfer.tokenAddress
            );

        portalTransfersProcessed[
            transferId(_originDomain, _nonce)
        ] = tokenAddress;
    }

    // This contract is only a Router to be aware of remote router addresses,
    // and doesn't actually send/handle Hyperlane messages directly
    function _handle(
        uint32, // origin
        bytes32, // sender
        bytes calldata // message
    ) internal pure override {
        revert("No messages expected");
    }

    function addDomain(uint32 _hyperlaneDomain, uint16 _wormholeDomain)
        external
        onlyOwner
    {
        hyperlaneDomainToWormholeDomain[_hyperlaneDomain] = _wormholeDomain;

        emit DomainAdded(_hyperlaneDomain, _wormholeDomain);
    }

    /**
     * The key that is used to track fulfilled Portal transfers
     * @param _hyperlaneDomain The hyperlane of the origin
     * @param _nonce The nonce of the adapter on the origin
     */
    function transferId(uint32 _hyperlaneDomain, uint224 _nonce)
        public
        pure
        returns (bytes32)
    {
        return bytes32(abi.encodePacked(_hyperlaneDomain, _nonce));
    }
}


// File contracts/interfaces/ILiquidityLayerMessageRecipient.sol

pragma solidity ^0.8.13;

interface ILiquidityLayerMessageRecipient {
    function handleWithTokens(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message,
        address _token,
        uint256 _amount
    ) external;
}


// File contracts/interfaces/ILiquidityLayerRouter.sol

pragma solidity >=0.6.11;

interface ILiquidityLayerRouter {
    function dispatchWithTokens(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        address _token,
        uint256 _amount,
        string calldata _bridge,
        bytes calldata _messageBody
    ) external returns (bytes32);
}


// File contracts/middleware/liquidity-layer/LiquidityLayerRouter.sol

pragma solidity ^0.8.13;





contract LiquidityLayerRouter is Router, ILiquidityLayerRouter {
    using SafeERC20 for IERC20;

    // Token bridge => adapter address
    mapping(string => address) public liquidityLayerAdapters;

    event LiquidityLayerAdapterSet(string indexed bridge, address adapter);

    constructor(address _mailbox) Router(_mailbox) {}

    /**
     * @notice Initializes the Router contract with Hyperlane core contracts and the address of the interchain security module.
     * @param _interchainGasPaymaster The address of the interchain gas paymaster contract.
     * @param _interchainSecurityModule The address of the interchain security module contract.
     * @param _owner The address with owner privileges.
     */
    function initialize(
        address _interchainGasPaymaster,
        address _interchainSecurityModule,
        address _owner
    ) external initializer {
        _MailboxClient_initialize(
            _interchainGasPaymaster,
            _interchainSecurityModule,
            _owner
        );
    }

    function dispatchWithTokens(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        address _token,
        uint256 _amount,
        string calldata _bridge,
        bytes calldata _messageBody
    ) external returns (bytes32) {
        ILiquidityLayerAdapter _adapter = _getAdapter(_bridge);

        // Transfer the tokens to the adapter
        IERC20(_token).safeTransferFrom(msg.sender, address(_adapter), _amount);

        // Reverts if the bridge was unsuccessful.
        // Gets adapter-specific data that is encoded into the message
        // ultimately sent via Hyperlane.
        bytes memory _adapterData = _adapter.sendTokens(
            _destinationDomain,
            _recipientAddress,
            _token,
            _amount
        );

        // The user's message "wrapped" with metadata required by this middleware
        bytes memory _messageWithMetadata = abi.encode(
            TypeCasts.addressToBytes32(msg.sender),
            _recipientAddress, // The "user" recipient
            _amount, // The amount of the tokens sent over the bridge
            _bridge, // The destination token bridge ID
            _adapterData, // The adapter-specific data
            _messageBody // The "user" message
        );

        // Dispatch the _messageWithMetadata to the destination's LiquidityLayerRouter.
        return _dispatch(_destinationDomain, _messageWithMetadata);
    }

    // Handles a message from an enrolled remote LiquidityLayerRouter
    function _handle(
        uint32 _origin,
        bytes32, // _sender, unused
        bytes calldata _message
    ) internal override {
        // Decode the message with metadata, "unwrapping" the user's message body
        (
            bytes32 _originalSender,
            bytes32 _userRecipientAddress,
            uint256 _amount,
            string memory _bridge,
            bytes memory _adapterData,
            bytes memory _userMessageBody
        ) = abi.decode(
                _message,
                (bytes32, bytes32, uint256, string, bytes, bytes)
            );

        ILiquidityLayerMessageRecipient _userRecipient = ILiquidityLayerMessageRecipient(
                TypeCasts.bytes32ToAddress(_userRecipientAddress)
            );

        // Reverts if the adapter hasn't received the bridged tokens yet
        (address _token, uint256 _receivedAmount) = _getAdapter(_bridge)
            .receiveTokens(
                _origin,
                address(_userRecipient),
                _amount,
                _adapterData
            );

        if (_userMessageBody.length > 0) {
            _userRecipient.handleWithTokens(
                _origin,
                _originalSender,
                _userMessageBody,
                _token,
                _receivedAmount
            );
        }
    }

    function setLiquidityLayerAdapter(string calldata _bridge, address _adapter)
        external
        onlyOwner
    {
        liquidityLayerAdapters[_bridge] = _adapter;
        emit LiquidityLayerAdapterSet(_bridge, _adapter);
    }

    function _getAdapter(string memory _bridge)
        internal
        view
        returns (ILiquidityLayerAdapter _adapter)
    {
        _adapter = ILiquidityLayerAdapter(liquidityLayerAdapters[_bridge]);
        // Require the adapter to have been set
        require(address(_adapter) != address(0), "No adapter found for bridge");
    }
}


// File contracts/mock/MockToken.sol

pragma solidity ^0.8.13;

contract MockToken is ERC20Upgradeable {
    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}


// File contracts/mock/MockCircleMessageTransmitter.sol

pragma solidity ^0.8.13;


contract MockCircleMessageTransmitter is ICircleMessageTransmitter {
    mapping(bytes32 => bool) processedNonces;
    MockToken token;

    constructor(MockToken _token) {
        token = _token;
    }

    function receiveMessage(bytes memory, bytes calldata)
        external
        pure
        returns (bool success)
    {
        success = true;
    }

    function hashSourceAndNonce(uint32 _source, uint64 _nonce)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_source, _nonce));
    }

    function process(
        bytes32 _nonceId,
        address _recipient,
        uint256 _amount
    ) public {
        processedNonces[_nonceId] = true;
        token.mint(_recipient, _amount);
    }

    function usedNonces(bytes32 _nonceId) external view returns (bool) {
        return processedNonces[_nonceId];
    }
}


// File contracts/mock/MockCircleTokenMessenger.sol

pragma solidity ^0.8.13;


contract MockCircleTokenMessenger is ITokenMessenger {
    uint64 public nextNonce = 0;
    MockToken token;

    constructor(MockToken _token) {
        token = _token;
    }

    function depositForBurn(
        uint256 _amount,
        uint32,
        bytes32,
        address _burnToken
    ) external returns (uint64 _nonce) {
        nextNonce = nextNonce + 1;
        _nonce = nextNonce;
        require(address(token) == _burnToken);
        token.transferFrom(msg.sender, address(this), _amount);
        token.burn(_amount);
    }

    function depositForBurnWithCaller(
        uint256,
        uint32,
        bytes32,
        address,
        bytes32
    ) external returns (uint64 _nonce) {
        nextNonce = nextNonce + 1;
        _nonce = nextNonce;
    }
}


// File contracts/mock/MockERC5164.sol

pragma solidity ^0.8.13;

contract MockMessageDispatcher is IMessageDispatcher {
    function dispatchMessage(
        uint256 toChainId,
        address to,
        bytes calldata data
    ) external returns (bytes32) {
        bytes32 messageId = keccak256(abi.encodePacked(toChainId, to, data));

        // simulate a successful dispatch
        emit MessageDispatched(messageId, msg.sender, toChainId, to, data);

        return messageId;
    }
}

contract MockMessageExecutor {
    event MessageIdExecuted(
        uint256 indexed fromChainId,
        bytes32 indexed messageId
    );
}


// File contracts/test/TestIsm.sol

pragma solidity >=0.6.11;

contract TestIsm is IInterchainSecurityModule {
    uint8 public moduleType = uint8(Types.NULL);

    bool verifyResult = true;

    function setVerify(bool _verify) public {
        verifyResult = _verify;
    }

    function verify(bytes calldata, bytes calldata) public view returns (bool) {
        return verifyResult;
    }
}


// File contracts/test/TestPostDispatchHook.sol

pragma solidity >=0.8.0;


contract TestPostDispatchHook is AbstractPostDispatchHook {
    // ============ Public Storage ============

    // test fees for quoteDispatch
    uint256 public fee = 0;

    // ============ External Functions ============

    /// @inheritdoc IPostDispatchHook
    function hookType() external pure override returns (uint8) {
        return uint8(IPostDispatchHook.Types.UNUSED);
    }

    function supportsMetadata(bytes calldata)
        public
        pure
        override
        returns (bool)
    {
        return true;
    }

    function setFee(uint256 _fee) external {
        fee = _fee;
    }

    // ============ Internal functions ============
    function _postDispatch(
        bytes calldata,
        /*metadata*/
        bytes calldata /*message*/
    ) internal pure override {
        // test - empty
    }

    function _quoteDispatch(
        bytes calldata,
        /*metadata*/
        bytes calldata /*message*/
    ) internal view override returns (uint256) {
        return fee;
    }
}


// File contracts/mock/MockMailbox.sol

pragma solidity ^0.8.0;








contract MockMailbox is Mailbox {
    using Message for bytes;

    uint32 public inboundUnprocessedNonce = 0;
    uint32 public inboundProcessedNonce = 0;

    mapping(uint32 => MockMailbox) public remoteMailboxes;
    mapping(uint256 => bytes) public inboundMessages;

    constructor(uint32 _domain) Mailbox(_domain) {
        TestIsm ism = new TestIsm();
        defaultIsm = ism;

        TestPostDispatchHook hook = new TestPostDispatchHook();
        defaultHook = hook;
        requiredHook = hook;

        _transferOwnership(msg.sender);
        _disableInitializers();
    }

    function addRemoteMailbox(uint32 _domain, MockMailbox _mailbox) external {
        remoteMailboxes[_domain] = _mailbox;
    }

    function dispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody,
        bytes calldata metadata,
        IPostDispatchHook hook
    ) public payable override returns (bytes32) {
        bytes memory message = _buildMessage(
            destinationDomain,
            recipientAddress,
            messageBody
        );
        bytes32 id = super.dispatch(
            destinationDomain,
            recipientAddress,
            messageBody,
            metadata,
            hook
        );

        MockMailbox _destinationMailbox = remoteMailboxes[destinationDomain];
        require(
            address(_destinationMailbox) != address(0),
            "Missing remote mailbox"
        );
        _destinationMailbox.addInboundMessage(message);

        return id;
    }

    function addInboundMessage(bytes calldata message) external {
        inboundMessages[inboundUnprocessedNonce] = message;
        inboundUnprocessedNonce++;
    }

    function processNextInboundMessage() public {
        bytes memory _message = inboundMessages[inboundProcessedNonce];
        Mailbox(address(this)).process("", _message);
        inboundProcessedNonce++;
    }
}


// File contracts/test/TestInterchainGasPaymaster.sol

pragma solidity >=0.8.0;

// ============ Internal Imports ============

contract TestInterchainGasPaymaster is InterchainGasPaymaster {
    uint256 public constant gasPrice = 10;

    constructor() {
        initialize(msg.sender, msg.sender);
    }

    function quoteGasPayment(uint32, uint256 gasAmount)
        public
        pure
        override
        returns (uint256)
    {
        return gasPrice * gasAmount;
    }
}


// File contracts/mock/MockHyperlaneEnvironment.sol

pragma solidity ^0.8.13;



contract MockHyperlaneEnvironment {
    uint32 originDomain;
    uint32 destinationDomain;

    mapping(uint32 => MockMailbox) public mailboxes;
    mapping(uint32 => TestInterchainGasPaymaster) public igps;
    mapping(uint32 => IInterchainSecurityModule) public isms;

    constructor(uint32 _originDomain, uint32 _destinationDomain) {
        originDomain = _originDomain;
        destinationDomain = _destinationDomain;

        MockMailbox originMailbox = new MockMailbox(_originDomain);
        MockMailbox destinationMailbox = new MockMailbox(_destinationDomain);

        originMailbox.addRemoteMailbox(_destinationDomain, destinationMailbox);
        destinationMailbox.addRemoteMailbox(_originDomain, originMailbox);

        isms[originDomain] = new TestIsm();
        isms[destinationDomain] = new TestIsm();

        originMailbox.setDefaultIsm(address(isms[originDomain]));
        destinationMailbox.setDefaultIsm(address(isms[destinationDomain]));

        igps[originDomain] = new TestInterchainGasPaymaster();
        igps[destinationDomain] = new TestInterchainGasPaymaster();

        originMailbox.transferOwnership(msg.sender);
        destinationMailbox.transferOwnership(msg.sender);

        mailboxes[_originDomain] = originMailbox;
        mailboxes[_destinationDomain] = destinationMailbox;
    }

    function processNextPendingMessage() public {
        mailboxes[destinationDomain].processNextInboundMessage();
    }

    function processNextPendingMessageFromDestination() public {
        mailboxes[originDomain].processNextInboundMessage();
    }
}


// File contracts/mock/MockPortalBridge.sol

pragma solidity ^0.8.13;



contract MockPortalBridge is IPortalTokenBridge {
    uint256 nextNonce = 0;
    MockToken token;

    constructor(MockToken _token) {
        token = _token;
    }

    function transferTokensWithPayload(
        address,
        uint256 amount,
        uint16,
        bytes32,
        uint32,
        bytes memory
    ) external payable returns (uint64 sequence) {
        nextNonce = nextNonce + 1;
        token.transferFrom(msg.sender, address(this), amount);
        token.burn(amount);
        return uint64(nextNonce);
    }

    function wrappedAsset(uint16, bytes32) external view returns (address) {
        return address(token);
    }

    function isWrappedAsset(address) external pure returns (bool) {
        return true;
    }

    function completeTransferWithPayload(bytes memory encodedVm)
        external
        returns (bytes memory)
    {
        (uint32 _originDomain, uint224 _nonce, uint256 _amount) = abi.decode(
            encodedVm,
            (uint32, uint224, uint256)
        );

        token.mint(msg.sender, _amount);
        // Format it so that parseTransferWithPayload returns the desired payload
        return
            abi.encode(
                TypeCasts.addressToBytes32(address(token)),
                adapterData(_originDomain, _nonce, address(token))
            );
    }

    function parseTransferWithPayload(bytes memory encoded)
        external
        pure
        returns (TransferWithPayload memory transfer)
    {
        (bytes32 tokenAddress, bytes memory payload) = abi.decode(
            encoded,
            (bytes32, bytes)
        );
        transfer.payload = payload;
        transfer.tokenAddress = tokenAddress;
    }

    function adapterData(
        uint32 _originDomain,
        uint224 _nonce,
        address _token
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                _originDomain,
                _nonce,
                TypeCasts.addressToBytes32(_token)
            );
    }

    function mockPortalVaa(
        uint32 _originDomain,
        uint224 _nonce,
        uint256 _amount
    ) public pure returns (bytes memory) {
        return abi.encode(_originDomain, _nonce, _amount);
    }
}


// File contracts/test/ERC20Test.sol

pragma solidity >=0.8.0;

contract ERC20Test is ERC20 {
    uint8 public immutable _decimals;

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        uint8 __decimals
    ) ERC20(name, symbol) {
        _decimals = __decimals;
        _mint(msg.sender, totalSupply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}


// File contracts/test/ERC721Test.sol

pragma solidity >=0.8.0;

contract ERC721Test is ERC721Enumerable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintAmount
    ) ERC721(name, symbol) {
        for (uint256 i = 0; i < _mintAmount; i++) {
            _mint(msg.sender, i);
        }
    }

    function _baseURI() internal pure override returns (string memory) {
        return "TEST-BASE-URI";
    }
}


// File contracts/test/TestRecipient.sol

pragma solidity >=0.8.0;


contract TestRecipient is
    Ownable,
    IMessageRecipient,
    ISpecifiesInterchainSecurityModule
{
    IInterchainSecurityModule public interchainSecurityModule;
    bytes32 public lastSender;
    bytes public lastData;

    address public lastCaller;
    string public lastCallMessage;

    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        uint256 indexed value,
        string message
    );

    event ReceivedCall(address indexed caller, uint256 amount, string message);

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable virtual override {
        emit ReceivedMessage(_origin, _sender, msg.value, string(_data));
        lastSender = _sender;
        lastData = _data;
    }

    function fooBar(uint256 amount, string calldata message) external {
        emit ReceivedCall(msg.sender, amount, message);
        lastCaller = msg.sender;
        lastCallMessage = message;
    }

    function setInterchainSecurityModule(address _ism) external onlyOwner {
        interchainSecurityModule = IInterchainSecurityModule(_ism);
    }
}


// File contracts/test/LightTestRecipient.sol

pragma solidity >=0.6.11;

contract LightTestRecipient is TestRecipient {
    // solhint-disable-next-line no-empty-blocks
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external payable override {
        // do nothing
    }
}


// File contracts/test/TestGasRouter.sol

pragma solidity >=0.6.11;

contract TestGasRouter is GasRouter {
    constructor(address _mailbox) GasRouter(_mailbox) {}

    function dispatch(uint32 _destination, bytes memory _msg) external payable {
        _dispatch(_destination, _msg);
    }

    function _handle(
        uint32,
        bytes32,
        bytes calldata
    ) internal pure override {}
}


// File contracts/test/TestLiquidityLayerMessageRecipient.sol

pragma solidity ^0.8.13;

contract TestLiquidityLayerMessageRecipient is ILiquidityLayerMessageRecipient {
    event HandledWithTokens(
        uint32 origin,
        bytes32 sender,
        bytes message,
        address token,
        uint256 amount
    );

    function handleWithTokens(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message,
        address _token,
        uint256 _amount
    ) external {
        emit HandledWithTokens(_origin, _sender, _message, _token, _amount);
    }
}


// File contracts/test/TestMailbox.sol

pragma solidity >=0.8.0;





contract TestMailbox is Mailbox {
    using TypeCasts for bytes32;

    constructor(uint32 _localDomain) Mailbox(_localDomain) {
        _transferOwnership(msg.sender);
    }

    function testHandle(
        uint32 _origin,
        bytes32 _sender,
        bytes32 _recipient,
        bytes calldata _body
    ) external {
        IMessageRecipient(_recipient.bytes32ToAddress()).handle(
            _origin,
            _sender,
            _body
        );
    }

    function buildOutboundMessage(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata body
    ) external view returns (bytes memory) {
        return _buildMessage(destinationDomain, recipientAddress, body);
    }

    function buildInboundMessage(
        uint32 originDomain,
        bytes32 recipientAddress,
        bytes32 senderAddress,
        bytes calldata body
    ) external view returns (bytes memory) {
        return
            Message.formatMessage(
                VERSION,
                nonce,
                originDomain,
                senderAddress,
                localDomain,
                recipientAddress,
                body
            );
    }

    function updateLatestDispatchedId(bytes32 _id) external {
        latestDispatchedId = _id;
    }
}


// File contracts/test/TestMerkle.sol

pragma solidity >=0.8.0;

contract TestMerkle {
    using MerkleLib for MerkleLib.Tree;

    MerkleLib.Tree public tree;

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function insert(bytes32 _node) external {
        tree.insert(_node);
    }

    function branchRoot(
        bytes32 _leaf,
        bytes32[32] calldata _proof,
        uint256 _index
    ) external pure returns (bytes32 _node) {
        return MerkleLib.branchRoot(_leaf, _proof, _index);
    }

    /**
     * @notice Returns the number of inserted leaves in the tree
     */
    function count() public view returns (uint256) {
        return tree.count;
    }

    function root() public view returns (bytes32) {
        return tree.root();
    }
}


// File contracts/test/TestMerkleTreeHook.sol

pragma solidity >=0.8.0;


contract TestMerkleTreeHook is MerkleTreeHook {
    using MerkleLib for MerkleLib.Tree;

    constructor(address _mailbox) MerkleTreeHook(_mailbox) {}

    function proof() external view returns (bytes32[32] memory) {
        bytes32[32] memory _zeroes = MerkleLib.zeroHashes();
        uint256 _index = _tree.count - 1;
        bytes32[32] memory _proof;

        for (uint256 i = 0; i < 32; i++) {
            uint256 _ithBit = (_index >> i) & 0x01;
            if (_ithBit == 1) {
                _proof[i] = _tree.branch[i];
            } else {
                _proof[i] = _zeroes[i];
            }
        }
        return _proof;
    }

    function insert(bytes32 _id) external {
        _tree.insert(_id);
    }
}


// File contracts/test/TestMessage.sol

pragma solidity >=0.6.11;

contract TestMessage {
    using Message for bytes;

    function version(bytes calldata _message)
        external
        pure
        returns (uint32 _version)
    {
        return _message.version();
    }

    function nonce(bytes calldata _message)
        external
        pure
        returns (uint256 _nonce)
    {
        return _message.nonce();
    }

    function body(bytes calldata _message)
        external
        pure
        returns (bytes calldata _body)
    {
        return _message.body();
    }

    function origin(bytes calldata _message)
        external
        pure
        returns (uint32 _origin)
    {
        return _message.origin();
    }

    function sender(bytes calldata _message)
        external
        pure
        returns (bytes32 _sender)
    {
        return _message.sender();
    }

    function destination(bytes calldata _message)
        external
        pure
        returns (uint32 _destination)
    {
        return _message.destination();
    }

    function recipient(bytes calldata _message)
        external
        pure
        returns (bytes32 _recipient)
    {
        return _message.recipient();
    }

    function recipientAddress(bytes calldata _message)
        external
        pure
        returns (address _recipient)
    {
        return _message.recipientAddress();
    }

    function id(bytes calldata _message) external pure returns (bytes32) {
        return _message.id();
    }
}


// File contracts/test/TestQuery.sol

pragma solidity ^0.8.13;



contract TestQuery {
    InterchainQueryRouter public router;

    event Owner(uint256, address);

    constructor(address _router) {
        router = InterchainQueryRouter(_router);
    }

    /**
     * @dev Fetches owner of InterchainQueryRouter on provided domain and passes along with provided secret to `this.receiveRouterOwner`
     */
    function queryRouterOwner(uint32 domain, uint256 secret) external {
        address target = TypeCasts.bytes32ToAddress(router.routers(domain));
        CallLib.StaticCallWithCallback[]
            memory calls = new CallLib.StaticCallWithCallback[](1);
        calls[0] = CallLib.build(
            target,
            abi.encodeWithSelector(Ownable.owner.selector),
            abi.encodeWithSelector(this.receiveRouterOwner.selector, secret)
        );
        router.query(domain, calls);
    }

    /**
     * @dev `msg.sender` must be restricted to `this.router` to prevent any local account from spoofing query data.
     */
    function receiveRouterOwner(uint256 secret, address owner) external {
        require(msg.sender == address(router), "TestQuery: not from router");
        emit Owner(secret, owner);
    }
}


// File contracts/test/TestQuerySender.sol

pragma solidity >=0.8.0;


contract TestQuerySender {
    InterchainQueryRouter queryRouter;

    address public lastAddressResult;
    uint256 public lastUint256Result;
    bytes32 public lastBytes32Result;

    event ReceivedAddressResult(address result);
    event ReceivedUint256Result(uint256 result);
    event ReceivedBytes32Result(bytes32 result);

    function initialize(address _queryRouterAddress) external {
        queryRouter = InterchainQueryRouter(_queryRouterAddress);
    }

    function queryAddress(
        uint32 _destinationDomain,
        address _target,
        bytes calldata _targetData,
        uint256 _gasAmount
    ) external payable {
        queryAndPayFor(
            _destinationDomain,
            _target,
            _targetData,
            this.handleQueryAddressResult.selector,
            _gasAmount
        );
    }

    function handleQueryAddressResult(address _result) external {
        emit ReceivedAddressResult(_result);
        lastAddressResult = _result;
    }

    function queryUint256(
        uint32 _destinationDomain,
        address _target,
        bytes calldata _targetData,
        uint256 _gasAmount
    ) external payable {
        queryAndPayFor(
            _destinationDomain,
            _target,
            _targetData,
            this.handleQueryUint256Result.selector,
            _gasAmount
        );
    }

    function handleQueryUint256Result(uint256 _result) external {
        emit ReceivedUint256Result(_result);
        lastUint256Result = _result;
    }

    function queryBytes32(
        uint32 _destinationDomain,
        address _target,
        bytes calldata _targetData,
        uint256 _gasAmount
    ) external payable {
        queryAndPayFor(
            _destinationDomain,
            _target,
            _targetData,
            this.handleQueryBytes32Result.selector,
            _gasAmount
        );
    }

    function handleQueryBytes32Result(bytes32 _result) external {
        emit ReceivedBytes32Result(_result);
        lastBytes32Result = _result;
    }

    function queryAndPayFor(
        uint32 _destinationDomain,
        address _target,
        bytes calldata _targetData,
        bytes4 _callbackSelector,
        uint256 /*_gasAmount*/
    ) internal {
        queryRouter.query(
            _destinationDomain,
            _target,
            _targetData,
            abi.encodePacked(_callbackSelector)
        );
    }
}


// File contracts/test/TestRouter.sol

pragma solidity >=0.6.11;

contract TestRouter is Router {
    event InitializeOverload();

    constructor(address _mailbox) Router(_mailbox) {}

    function initialize(address _hook, address _interchainSecurityModule)
        public
        initializer
    {
        _MailboxClient_initialize(_hook, _interchainSecurityModule, msg.sender);
    }

    function _handle(
        uint32,
        bytes32,
        bytes calldata
    ) internal pure override {}

    function isRemoteRouter(uint32 _domain, bytes32 _potentialRemoteRouter)
        external
        view
        returns (bool)
    {
        return _isRemoteRouter(_domain, _potentialRemoteRouter);
    }

    function mustHaveRemoteRouter(uint32 _domain)
        external
        view
        returns (bytes32)
    {
        return _mustHaveRemoteRouter(_domain);
    }

    function dispatch(uint32 _destination, bytes memory _msg) external payable {
        _dispatch(_destination, _msg);
    }
}


// File contracts/test/TestSendReceiver.sol

pragma solidity >=0.8.0;






contract TestSendReceiver is IMessageRecipient {
    using TypeCasts for address;

    uint256 public constant HANDLE_GAS_AMOUNT = 50_000;

    event Handled(bytes32 blockHash);

    function dispatchToSelf(
        IMailbox _mailbox,
        uint32 _destinationDomain,
        bytes calldata _messageBody
    ) external payable {
        bytes memory hookMetadata = StandardHookMetadata.formatMetadata(
            HANDLE_GAS_AMOUNT,
            msg.sender
        );
        // TODO: handle topping up?
        _mailbox.dispatch{value: msg.value}(
            _destinationDomain,
            address(this).addressToBytes32(),
            _messageBody,
            hookMetadata
        );
    }

    function dispatchToSelf(
        IMailbox _mailbox,
        uint32 _destinationDomain,
        bytes calldata _messageBody,
        IPostDispatchHook hook
    ) external payable {
        bytes memory hookMetadata = StandardHookMetadata.formatMetadata(
            HANDLE_GAS_AMOUNT,
            msg.sender
        );
        // TODO: handle topping up?
        _mailbox.dispatch{value: msg.value}(
            _destinationDomain,
            address(this).addressToBytes32(),
            _messageBody,
            hookMetadata,
            hook
        );
    }

    function handle(
        uint32,
        bytes32,
        bytes calldata
    ) external payable override {
        bytes32 blockHash = previousBlockHash();
        bool isBlockHashEndIn0 = uint256(blockHash) % 16 == 0;
        require(!isBlockHashEndIn0, "block hash ends in 0");
        emit Handled(blockHash);
    }

    function previousBlockHash() internal view returns (bytes32) {
        return blockhash(block.number - 1);
    }
}


// File contracts/test/TestTokenRecipient.sol

pragma solidity >=0.8.0;

contract TestTokenRecipient is ILiquidityLayerMessageRecipient {
    bytes32 public lastSender;
    bytes public lastData;
    address public lastToken;
    uint256 public lastAmount;

    address public lastCaller;
    string public lastCallMessage;

    event ReceivedMessage(
        uint32 indexed origin,
        bytes32 indexed sender,
        string message,
        address token,
        uint256 amount
    );

    event ReceivedCall(address indexed caller, uint256 amount, string message);

    function handleWithTokens(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data,
        address _token,
        uint256 _amount
    ) external override {
        emit ReceivedMessage(_origin, _sender, string(_data), _token, _amount);
        lastSender = _sender;
        lastData = _data;
        lastToken = _token;
        lastAmount = _amount;
    }

    function fooBar(uint256 amount, string calldata message) external {
        emit ReceivedCall(msg.sender, amount, message);
        lastCaller = msg.sender;
        lastCallMessage = message;
    }
}


// File contracts/token/libs/TokenMessage.sol

pragma solidity >=0.8.0;

library TokenMessage {
    function format(
        bytes32 _recipient,
        uint256 _amount,
        bytes memory _metadata
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(_recipient, _amount, _metadata);
    }

    function recipient(bytes calldata message) internal pure returns (bytes32) {
        return bytes32(message[0:32]);
    }

    function amount(bytes calldata message) internal pure returns (uint256) {
        return uint256(bytes32(message[32:64]));
    }

    // alias for ERC721
    function tokenId(bytes calldata message) internal pure returns (uint256) {
        return amount(message);
    }

    function metadata(bytes calldata message)
        internal
        pure
        returns (bytes calldata)
    {
        return message[64:];
    }
}


// File contracts/token/libs/TokenRouter.sol

pragma solidity >=0.8.0;




/**
 * @title Hyperlane Token Router that extends Router with abstract token (ERC20/ERC721) remote transfer functionality.
 * @author Abacus Works
 */
abstract contract TokenRouter is GasRouter {
    using TypeCasts for bytes32;
    using TypeCasts for address;
    using TokenMessage for bytes;

    /**
     * @dev Emitted on `transferRemote` when a transfer message is dispatched.
     * @param destination The identifier of the destination chain.
     * @param recipient The address of the recipient on the destination chain.
     * @param amount The amount of tokens burnt on the origin chain.
     */
    event SentTransferRemote(
        uint32 indexed destination,
        bytes32 indexed recipient,
        uint256 amount
    );

    /**
     * @dev Emitted on `_handle` when a transfer message is processed.
     * @param origin The identifier of the origin chain.
     * @param recipient The address of the recipient on the destination chain.
     * @param amount The amount of tokens minted on the destination chain.
     */
    event ReceivedTransferRemote(
        uint32 indexed origin,
        bytes32 indexed recipient,
        uint256 amount
    );

    constructor(address _mailbox) GasRouter(_mailbox) {}

    /**
     * @notice Transfers `_amountOrId` token to `_recipient` on `_destination` domain.
     * @dev Delegates transfer logic to `_transferFromSender` implementation.
     * @dev Emits `SentTransferRemote` event on the origin chain.
     * @param _destination The identifier of the destination chain.
     * @param _recipient The address of the recipient on the destination chain.
     * @param _amountOrId The amount or identifier of tokens to be sent to the remote recipient.
     * @return messageId The identifier of the dispatched message.
     */
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amountOrId
    ) external payable virtual returns (bytes32 messageId) {
        return
            _transferRemote(_destination, _recipient, _amountOrId, msg.value);
    }

    /**
     * @notice Transfers `_amountOrId` token to `_recipient` on `_destination` domain.
     * @dev Delegates transfer logic to `_transferFromSender` implementation.
     * @dev Emits `SentTransferRemote` event on the origin chain.
     * @param _destination The identifier of the destination chain.
     * @param _recipient The address of the recipient on the destination chain.
     * @param _amountOrId The amount or identifier of tokens to be sent to the remote recipient.
     * @param _gasPayment The amount of native token to pay for interchain gas.
     * @return messageId The identifier of the dispatched message.
     */
    function _transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amountOrId,
        uint256 _gasPayment
    ) internal returns (bytes32 messageId) {
        bytes memory metadata = _transferFromSender(_amountOrId);
        messageId = _dispatch(
            _destination,
            _gasPayment,
            TokenMessage.format(_recipient, _amountOrId, metadata)
        );
        emit SentTransferRemote(_destination, _recipient, _amountOrId);
    }

    /**
     * @dev Should transfer `_amountOrId` of tokens from `msg.sender` to this token router.
     * @dev Called by `transferRemote` before message dispatch.
     * @dev Optionally returns `metadata` associated with the transfer to be passed in message.
     */
    function _transferFromSender(uint256 _amountOrId)
        internal
        virtual
        returns (bytes memory metadata);

    /**
     * @notice Returns the balance of `account` on this token router.
     * @param account The address to query the balance of.
     * @return The balance of `account`.
     */
    function balanceOf(address account) external virtual returns (uint256);

    /**
     * @dev Mints tokens to recipient when router receives transfer message.
     * @dev Emits `ReceivedTransferRemote` event on the destination chain.
     * @param _origin The identifier of the origin chain.
     * @param _message The encoded remote transfer message containing the recipient address and amount.
     */
    function _handle(
        uint32 _origin,
        bytes32,
        bytes calldata _message
    ) internal virtual override {
        bytes32 recipient = _message.recipient();
        uint256 amount = _message.amount();
        bytes calldata metadata = _message.metadata();
        _transferTo(recipient.bytes32ToAddress(), amount, metadata);
        emit ReceivedTransferRemote(_origin, recipient, amount);
    }

    /**
     * @dev Should transfer `_amountOrId` of tokens from this token router to `_recipient`.
     * @dev Called by `handle` after message decoding.
     * @dev Optionally handles `metadata` associated with transfer passed in message.
     */
    function _transferTo(
        address _recipient,
        uint256 _amountOrId,
        bytes calldata metadata
    ) internal virtual;
}


// File contracts/token/HypERC20.sol

pragma solidity >=0.8.0;

/**
 * @title Hyperlane ERC20 Token Router that extends ERC20 with remote transfer functionality.
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 */
contract HypERC20 is ERC20Upgradeable, TokenRouter {
    uint8 private immutable _decimals;

    constructor(uint8 __decimals, address _mailbox) TokenRouter(_mailbox) {
        _decimals = __decimals;
    }

    /**
     * @notice Initializes the Hyperlane router, ERC20 metadata, and mints initial supply to deployer.
     * @param _totalSupply The initial supply of the token.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    function initialize(
        uint256 _totalSupply,
        string memory _name,
        string memory _symbol
    ) external initializer {
        // Initialize ERC20 metadata
        __ERC20_init(_name, _symbol);
        _mint(msg.sender, _totalSupply);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address _account)
        public
        view
        virtual
        override(TokenRouter, ERC20Upgradeable)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(_account);
    }

    /**
     * @dev Burns `_amount` of token from `msg.sender` balance.
     * @inheritdoc TokenRouter
     */
    function _transferFromSender(uint256 _amount)
        internal
        override
        returns (bytes memory)
    {
        _burn(msg.sender, _amount);
        return bytes(""); // no metadata
    }

    /**
     * @dev Mints `_amount` of token to `_recipient` balance.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata // no metadata
    ) internal virtual override {
        _mint(_recipient, _amount);
    }
}


// File contracts/token/libs/FastTokenRouter.sol

pragma solidity >=0.8.0;


/**
 * @title Common FastTokenRouter functionality for ERC20 Tokens with remote transfer support.
 * @author Abacus Works
 */
abstract contract FastTokenRouter is TokenRouter {
    using TypeCasts for bytes32;
    using TokenMessage for bytes;

    uint256 public fastTransferId;
    // maps `fastTransferId` to the filler address.
    mapping(bytes32 => address) filledFastTransfers;

    /**
     * @dev delegates transfer logic to `_transferTo`.
     * @inheritdoc TokenRouter
     */
    function _handle(
        uint32 _origin,
        bytes32,
        bytes calldata _message
    ) internal virtual override {
        bytes32 recipient = _message.recipient();
        uint256 amount = _message.amount();
        bytes calldata metadata = _message.metadata();
        _transferTo(recipient.bytes32ToAddress(), amount, _origin, metadata);
        emit ReceivedTransferRemote(_origin, recipient, amount);
    }

    /**
     * @dev Transfers `_amount` of token to `_recipient`/`fastFiller` who provided LP.
     * @dev Called by `handle` after message decoding.
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        uint32 _origin,
        bytes calldata _metadata
    ) internal virtual {
        address _tokenRecipient = _getTokenRecipient(
            _recipient,
            _amount,
            _origin,
            _metadata
        );

        _fastTransferTo(_tokenRecipient, _amount);
    }

    /**
     * @dev allows an external user to full an unfilled fast transfer order.
     * @param _recipient The recepient of the wrapped token on base chain.
     * @param _amount The amount of wrapped tokens that is being bridged.
     * @param _fastFee The fee the bridging entity will pay.
     * @param _fastTransferId Id assigned on the remote chain to uniquely identify the transfer.
     */
    function fillFastTransfer(
        address _recipient,
        uint256 _amount,
        uint256 _fastFee,
        uint32 _origin,
        uint256 _fastTransferId
    ) external virtual {
        bytes32 filledFastTransfersKey = _getFastTransfersKey(
            _origin,
            _fastTransferId,
            _amount,
            _fastFee,
            _recipient
        );
        require(
            filledFastTransfers[filledFastTransfersKey] == address(0),
            "request already filled"
        );

        filledFastTransfers[filledFastTransfersKey] = msg.sender;

        _fastRecieveFrom(msg.sender, _amount - _fastFee);
        _fastTransferTo(_recipient, _amount - _fastFee);
    }

    /**
     * @dev Transfers `_amountOrId` token to `_recipient` on `_destination` domain.
     * @dev Delegates transfer logic to `_fastTransferFromSender` implementation.
     * @dev Emits `SentTransferRemote` event on the origin chain.
     * @param _destination The identifier of the destination chain.
     * @param _recipient The address of the recipient on the destination chain.
     * @param _amountOrId The amount or identifier of tokens to be sent to the remote recipient.
     * @return messageId The identifier of the dispatched message.
     */
    function fastTransferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amountOrId,
        uint256 _fastFee
    ) public payable virtual returns (bytes32 messageId) {
        uint256 _fastTransferId = fastTransferId + 1;
        fastTransferId = _fastTransferId;
        bytes memory metadata = _fastTransferFromSender(
            _amountOrId,
            _fastFee,
            _fastTransferId
        );

        messageId = _dispatch(
            _destination,
            TokenMessage.format(_recipient, _amountOrId, metadata)
        );
        emit SentTransferRemote(_destination, _recipient, _amountOrId);
    }

    /**
     * @dev Burns `_amount` of token from `msg.sender` balance.
     * @dev Pays `_fastFee` of tokens to LP on source chain.
     * @dev Returns `fastFee` as bytes in the form of metadata.
     */
    function _fastTransferFromSender(
        uint256 _amount,
        uint256 _fastFee,
        uint256 _fastTransferId
    ) internal virtual returns (bytes memory) {
        _fastRecieveFrom(msg.sender, _amount);
        return abi.encode(_fastFee, _fastTransferId);
    }

    /**
     * @dev returns an address that indicates who should recieve the bridged tokens.
     * @dev if _fastFees was inlcuded and someone filled the order before the mailbox made the contract call, the filler gets the funds.
     */
    function _getTokenRecipient(
        address _recipient,
        uint256 _amount,
        uint32 _origin,
        bytes calldata _metadata
    ) internal view returns (address) {
        if (_metadata.length == 0) {
            return _recipient;
        }

        // decode metadata to extract `_fastFee` and `_fastTransferId`.
        (uint256 _fastFee, uint256 _fastTransferId) = abi.decode(
            _metadata,
            (uint256, uint256)
        );

        address _fillerAddress = filledFastTransfers[
            _getFastTransfersKey(
                _origin,
                _fastTransferId,
                _amount,
                _fastFee,
                _recipient
            )
        ];
        if (_fillerAddress != address(0)) {
            return _fillerAddress;
        }

        return _recipient;
    }

    /**
     * @dev generates the key for storing the filler address of fast transfers.
     */
    function _getFastTransfersKey(
        uint32 _origin,
        uint256 _fastTransferId,
        uint256 _amount,
        uint256 _fastFee,
        address _recipient
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _origin,
                    _fastTransferId,
                    _amount,
                    _fastFee,
                    _recipient
                )
            );
    }

    /**
     * @dev Should transfer `_amount` of tokens to `_recipient`.
     * @dev The implementation is delegated.
     */
    function _fastTransferTo(address _recipient, uint256 _amount)
        internal
        virtual;

    /**
     * @dev Should collect `amount` of tokens from `_sender`.
     * @dev The implementation is delegated.
     */
    function _fastRecieveFrom(address _sender, uint256 _amount)
        internal
        virtual;
}


// File contracts/token/extensions/FastHypERC20.sol

pragma solidity >=0.8.0;



/**
 * @title Hyperlane ERC20 Token Router that extends ERC20 with remote transfer functionality.
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 */
contract FastHypERC20 is FastTokenRouter, HypERC20 {
    constructor(uint8 __decimals, address _mailbox)
        HypERC20(__decimals, _mailbox)
    {}

    /**
     * @dev delegates transfer logic to `_transferTo`.
     * @inheritdoc TokenRouter
     */
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal virtual override(FastTokenRouter, TokenRouter) {
        FastTokenRouter._handle(_origin, _sender, _message);
    }

    /**
     * @dev Mints `_amount` of tokens to `_recipient`.
     * @inheritdoc FastTokenRouter
     */
    function _fastTransferTo(address _recipient, uint256 _amount)
        internal
        override
    {
        _mint(_recipient, _amount);
    }

    /**
     * @dev Burns `_amount` of tokens from `_recipient`.
     * @inheritdoc FastTokenRouter
     */
    function _fastRecieveFrom(address _sender, uint256 _amount)
        internal
        override
    {
        _burn(_sender, _amount);
    }

    function balanceOf(address _account)
        public
        view
        virtual
        override(HypERC20, TokenRouter)
        returns (uint256)
    {
        return ERC20Upgradeable.balanceOf(_account);
    }
}


// File contracts/token/HypERC20Collateral.sol

pragma solidity >=0.8.0;




/**
 * @title Hyperlane ERC20 Token Collateral that wraps an existing ERC20 with remote transfer functionality.
 * @author Abacus Works
 */
contract HypERC20Collateral is TokenRouter {
    using SafeERC20 for IERC20;

    IERC20 public immutable wrappedToken;

    /**
     * @notice Constructor
     * @param erc20 Address of the token to keep as collateral
     */
    constructor(address erc20, address _mailbox) TokenRouter(_mailbox) {
        wrappedToken = IERC20(erc20);
    }

    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return wrappedToken.balanceOf(_account);
    }

    /**
     * @dev Transfers `_amount` of `wrappedToken` from `msg.sender` to this contract.
     * @inheritdoc TokenRouter
     */
    function _transferFromSender(uint256 _amount)
        internal
        override
        returns (bytes memory)
    {
        wrappedToken.safeTransferFrom(msg.sender, address(this), _amount);
        return bytes(""); // no metadata
    }

    /**
     * @dev Transfers `_amount` of `wrappedToken` from this contract to `_recipient`.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata // no metadata
    ) internal virtual override {
        wrappedToken.safeTransfer(_recipient, _amount);
    }
}


// File contracts/token/extensions/FastHypERC20Collateral.sol

pragma solidity >=0.8.0;




/**
 * @title Hyperlane ERC20 Token Collateral that wraps an existing ERC20 with remote transfer functionality.
 * @author Abacus Works
 */
contract FastHypERC20Collateral is FastTokenRouter, HypERC20Collateral {
    using SafeERC20 for IERC20;

    /**
     * @notice Constructor
     * @param erc20 Address of the token to keep as collateral
     */
    constructor(address erc20, address _mailbox)
        HypERC20Collateral(erc20, _mailbox)
    {}

    /**
     * @dev delegates transfer logic to `_transferTo`.
     * @inheritdoc FastTokenRouter
     */
    function _handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) internal virtual override(FastTokenRouter, TokenRouter) {
        FastTokenRouter._handle(_origin, _sender, _message);
    }

    /**
     * @dev Transfers `_amount` of `wrappedToken` to `_recipient`.
     * @inheritdoc FastTokenRouter
     */
    function _fastTransferTo(address _recipient, uint256 _amount)
        internal
        override
    {
        wrappedToken.safeTransfer(_recipient, _amount);
    }

    /**
     * @dev Transfers in `_amount` of `wrappedToken` from `_recipient`.
     * @inheritdoc FastTokenRouter
     */
    function _fastRecieveFrom(address _sender, uint256 _amount)
        internal
        override
    {
        wrappedToken.safeTransferFrom(_sender, address(this), _amount);
    }
}


// File contracts/token/HypERC721Collateral.sol

pragma solidity >=0.8.0;


/**
 * @title Hyperlane ERC721 Token Collateral that wraps an existing ERC721 with remote transfer functionality.
 * @author Abacus Works
 */
contract HypERC721Collateral is TokenRouter {
    IERC721 public immutable wrappedToken;

    /**
     * @notice Constructor
     * @param erc721 Address of the token to keep as collateral
     */
    constructor(address erc721, address _mailbox) TokenRouter(_mailbox) {
        wrappedToken = IERC721(erc721);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return IERC721(wrappedToken).ownerOf(_tokenId);
    }

    /**
     * @dev Returns the balance of `_account` for `wrappedToken`.
     * @inheritdoc TokenRouter
     */
    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return IERC721(wrappedToken).balanceOf(_account);
    }

    /**
     * @dev Transfers `_tokenId` of `wrappedToken` from `msg.sender` to this contract.
     * @inheritdoc TokenRouter
     */
    function _transferFromSender(uint256 _tokenId)
        internal
        virtual
        override
        returns (bytes memory)
    {
        // safeTransferFrom not used here because recipient is this contract
        wrappedToken.transferFrom(msg.sender, address(this), _tokenId);
        return bytes(""); // no metadata
    }

    /**
     * @dev Transfers `_tokenId` of `wrappedToken` from this contract to `_recipient`.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _tokenId,
        bytes calldata // no metadata
    ) internal override {
        wrappedToken.safeTransferFrom(address(this), _recipient, _tokenId);
    }
}


// File contracts/token/extensions/HypERC721URICollateral.sol

pragma solidity >=0.8.0;

/**
 * @title Hyperlane ERC721 Token Collateral that wraps an existing ERC721 with remote transfer and URI relay functionality.
 * @author Abacus Works
 */
contract HypERC721URICollateral is HypERC721Collateral {
    // solhint-disable-next-line no-empty-blocks
    constructor(address erc721, address _mailbox)
        HypERC721Collateral(erc721, _mailbox)
    {}

    /**
     * @dev Transfers `_tokenId` of `wrappedToken` from `msg.sender` to this contract.
     * @return The URI of `_tokenId` on `wrappedToken`.
     * @inheritdoc HypERC721Collateral
     */
    function _transferFromSender(uint256 _tokenId)
        internal
        override
        returns (bytes memory)
    {
        HypERC721Collateral._transferFromSender(_tokenId);
        return
            bytes(
                IERC721MetadataUpgradeable(address(wrappedToken)).tokenURI(
                    _tokenId
                )
            );
    }
}


// File contracts/token/HypERC721.sol

pragma solidity >=0.8.0;



/**
 * @title Hyperlane ERC721 Token Router that extends ERC721 with remote transfer functionality.
 * @author Abacus Works
 */
contract HypERC721 is ERC721EnumerableUpgradeable, TokenRouter {
    constructor(address _mailbox) TokenRouter(_mailbox) {}

    /**
     * @notice Initializes the Hyperlane router, ERC721 metadata, and mints initial supply to deployer.
     * @param _mintAmount The amount of NFTs to mint to `msg.sender`.
     * @param _name The name of the token.
     * @param _symbol The symbol of the token.
     */
    function initialize(
        uint256 _mintAmount,
        string memory _name,
        string memory _symbol
    ) external initializer {
        address owner = msg.sender;
        _transferOwnership(owner);

        __ERC721_init(_name, _symbol);
        for (uint256 i = 0; i < _mintAmount; i++) {
            _safeMint(owner, i);
        }
    }

    function balanceOf(address _account)
        public
        view
        virtual
        override(TokenRouter, ERC721Upgradeable, IERC721Upgradeable)
        returns (uint256)
    {
        return ERC721Upgradeable.balanceOf(_account);
    }

    /**
     * @dev Asserts `msg.sender` is owner and burns `_tokenId`.
     * @inheritdoc TokenRouter
     */
    function _transferFromSender(uint256 _tokenId)
        internal
        virtual
        override
        returns (bytes memory)
    {
        require(ownerOf(_tokenId) == msg.sender, "!owner");
        _burn(_tokenId);
        return bytes(""); // no metadata
    }

    /**
     * @dev Mints `_tokenId` to `_recipient`.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _tokenId,
        bytes calldata // no metadata
    ) internal virtual override {
        _safeMint(_recipient, _tokenId);
    }
}


// File contracts/token/extensions/HypERC721URIStorage.sol

pragma solidity >=0.8.0;



/**
 * @title Hyperlane ERC721 Token that extends ERC721URIStorage with remote transfer and URI relay functionality.
 * @author Abacus Works
 */
contract HypERC721URIStorage is HypERC721, ERC721URIStorageUpgradeable {
    constructor(address _mailbox) HypERC721(_mailbox) {}

    function balanceOf(address account)
        public
        view
        override(HypERC721, ERC721Upgradeable)
        returns (uint256)
    {
        return HypERC721.balanceOf(account);
    }

    /**
     * @return _tokenURI The URI of `_tokenId`.
     * @inheritdoc HypERC721
     */
    function _transferFromSender(uint256 _tokenId)
        internal
        override
        returns (bytes memory _tokenURI)
    {
        _tokenURI = bytes(tokenURI(_tokenId)); // requires minted
        HypERC721._transferFromSender(_tokenId);
    }

    /**
     * @dev Sets the URI for `_tokenId` to `_tokenURI`.
     * @inheritdoc HypERC721
     */
    function _transferTo(
        address _recipient,
        uint256 _tokenId,
        bytes calldata _tokenURI
    ) internal override {
        HypERC721._transferTo(_recipient, _tokenId, _tokenURI);
        _setTokenURI(_tokenId, string(_tokenURI)); // requires minted
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721EnumerableUpgradeable, ERC721Upgradeable) {
        ERC721EnumerableUpgradeable._beforeTokenTransfer(
            from,
            to,
            tokenId,
            batchSize
        );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721EnumerableUpgradeable, ERC721Upgradeable)
        returns (bool)
    {
        return ERC721EnumerableUpgradeable.supportsInterface(interfaceId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        ERC721URIStorageUpgradeable._burn(tokenId);
    }
}


// File contracts/token/HypNative.sol

pragma solidity >=0.8.0;



/**
 * @title Hyperlane Native Token Router that extends ERC20 with remote transfer functionality.
 * @author Abacus Works
 * @dev Supply on each chain is not constant but the aggregate supply across all chains is.
 */
contract HypNative is TokenRouter {
    /**
     * @dev Emitted when native tokens are donated to the contract.
     * @param sender The address of the sender.
     * @param amount The amount of native tokens donated.
     */
    event Donation(address indexed sender, uint256 amount);

    constructor(address _mailbox) TokenRouter(_mailbox) {}

    /**
     * @inheritdoc TokenRouter
     * @dev uses (`msg.value` - `_amount`) as interchain gas payment and `msg.sender` as refund address.
     */
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) public payable virtual override returns (bytes32 messageId) {
        require(msg.value >= _amount, "Native: amount exceeds msg.value");
        uint256 gasPayment = msg.value - _amount;
        return _transferRemote(_destination, _recipient, _amount, gasPayment);
    }

    function balanceOf(address _account)
        external
        view
        override
        returns (uint256)
    {
        return _account.balance;
    }

    /**
     * @inheritdoc TokenRouter
     * @dev No-op because native amount is transferred in `msg.value`
     * @dev Compiler will not include this in the bytecode.
     */
    function _transferFromSender(uint256)
        internal
        pure
        override
        returns (bytes memory)
    {
        return bytes(""); // no metadata
    }

    /**
     * @dev Sends `_amount` of native token to `_recipient` balance.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata // no metadata
    ) internal virtual override {
        Address.sendValue(payable(_recipient), _amount);
    }

    receive() external payable {
        emit Donation(msg.sender, msg.value);
    }
}


// File contracts/token/extensions/HypNativeScaled.sol

pragma solidity >=0.8.0;


/**
 * @title Hyperlane Native Token that scales native value by a fixed factor for consistency with other tokens.
 * @dev The scale factor multiplies the `message.amount` to the local native token amount.
 *      Conversely, it divides the local native `msg.value` amount by `scale` to encode the `message.amount`.
 * @author Abacus Works
 */
contract HypNativeScaled is HypNative {
    uint256 public immutable scale;

    constructor(uint256 _scale, address _mailbox) HypNative(_mailbox) {
        scale = _scale;
    }

    /**
     * @inheritdoc HypNative
     * @dev Sends scaled `msg.value` (divided by `scale`) to `_recipient`.
     */
    function transferRemote(
        uint32 _destination,
        bytes32 _recipient,
        uint256 _amount
    ) public payable override returns (bytes32 messageId) {
        require(msg.value >= _amount, "Native: amount exceeds msg.value");
        uint256 gasPayment = msg.value - _amount;
        uint256 scaledAmount = _amount / scale;
        return
            _transferRemote(_destination, _recipient, scaledAmount, gasPayment);
    }

    /**
     * @dev Sends scaled `_amount` (multipled by `scale`) to `_recipient`.
     * @inheritdoc TokenRouter
     */
    function _transferTo(
        address _recipient,
        uint256 _amount,
        bytes calldata metadata // no metadata
    ) internal override {
        uint256 scaledAmount = _amount * scale;
        HypNative._transferTo(_recipient, scaledAmount, metadata);
    }
}


// File contracts/upgrade/ProxyAdmin.sol

// OpenZeppelin Contracts v4.4.1 (proxy/transparent/ProxyAdmin.sol)

pragma solidity ^0.8.0;


// File contracts/upgrade/TimelockController.sol

// OpenZeppelin Contracts (last updated v4.7.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;


// File contracts/upgrade/TransparentUpgradeableProxy.sol

// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;


// File contracts/interfaces/IRouter.sol

pragma solidity >=0.8.0;

interface IRouter {
    function domains() external view returns (uint32[] memory);

    function routers(uint32 _domain) external view returns (bytes32);

    function enrollRemoteRouter(uint32 _domain, bytes32 _router) external;

    function enrollRemoteRouters(
        uint32[] calldata _domains,
        bytes32[] calldata _routers
    ) external;
}