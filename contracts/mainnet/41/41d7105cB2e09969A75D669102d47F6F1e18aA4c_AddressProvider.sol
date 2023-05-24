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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "./interfaces/IAddressProvider.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/ILendVault.sol";
import "./interfaces/IBorrower.sol";
import "./interfaces/IReserve.sol";
import "./interfaces/ISwapper.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IController.sol";
import "./interfaces/IStrategyVault.sol";
import "./interfaces/INonfungiblePositionManager.sol";
import "./libraries/AddressArray.sol";
import "./utils/AccessControl.sol";

/**
 * @notice AddressProvider acts as a registry for addresses that are used throughout the lending module
 * @dev Most of the setter functions call the address being set with an expected function as input validation
 */
contract AddressProvider is AccessControl, IAddressProvider {
    using AddressArray for address[];
    
    address public networkToken;
    address public usdc;
    address public usdt;
    address public dai;
    address public swapper;
    address public reserve;
    address public lendVault;
    address public borrowerManager;
    address public oracle;
    address public uniswapV3Integration;
    address public uniswapV3StrategyLogic;
    address public borrowerBalanceCalculator;

    // Farming addresses
    address public keeper;
    address public governance;
    address public guardian;
    address public controller;
    address[] public vaults;
    address public uniswapV3StrategyData;

    function initialize() external initializer {
        governance = msg.sender;
        provider = IAddressProvider(address(this));
    }

    function getVaults() external view returns (address[] memory v) {
        v = vaults.copy();
    }
    
    function setNetworkToken(address token) external restrictAccess(GOVERNOR) {
        networkToken = token;
        ERC20(networkToken).decimals();
    }

    function setUsdc(address token) external restrictAccess(GOVERNOR) {
        usdc = token;
        ERC20(usdc).decimals();
    }
    
    function setUsdt(address token) external restrictAccess(GOVERNOR) {
        usdt = token;
        ERC20(usdt).decimals();
    }
    
    function setDai(address token) external restrictAccess(GOVERNOR) {
        dai = token;
        ERC20(dai).decimals();
    }

    function setReserve(address _reserve) external restrictAccess(GOVERNOR) {
        reserve = _reserve;
        IReserve(_reserve).expectedBalance();
    }

    function setSwapper(address _swapper) external restrictAccess(GOVERNOR) {
        swapper = _swapper;
        ISwapper(_swapper).getETHValue(networkToken, 1e18);
    }

    function setLendVault(address _lendVault) external restrictAccess(GOVERNOR) {
        lendVault = _lendVault;
        ILendVault(_lendVault).getSupportedTokens();
    }

    function setBorrowerManager(address _manager) external restrictAccess(GOVERNOR) {
        borrowerManager = _manager;
    }
    
    function setOracle(address _oracle) external restrictAccess(GOVERNOR) {
        oracle = _oracle;
        IOracle(oracle).getPrice(networkToken);
    }
    
    function setUniswapV3Integration(address _integration) external restrictAccess(GOVERNOR) {
        uniswapV3Integration = _integration;
    }

    function setUniswapV3StrategyData(address _address) external restrictAccess(GOVERNOR) {
        uniswapV3StrategyData = _address;
    }

    function setUniswapV3StrategyLogic(address _logic) external restrictAccess(GOVERNOR) {
        uniswapV3StrategyLogic = _logic;
    }
    
    function setBorrowerBalanceCalculator(address _calculator) external restrictAccess(GOVERNOR) {
        borrowerBalanceCalculator = _calculator;
    }
    
    function setKeeper(address _keeper) external restrictAccess(GOVERNOR) {
        keeper = _keeper;
    }
    
    /**
     * @notice Sets the governance address and transfers ownership
     * to the new governance address
     */
    function setGovernance(address _governance) external restrictAccess(GOVERNOR) {
        governance = _governance;
    }
    
    function setGuardian(address _guardian) external restrictAccess(GOVERNOR) {
        guardian = _guardian;
    }
    
    function setController(address _controller) external restrictAccess(GOVERNOR) {
        IController(_controller).vaults(address(0));
        controller = _controller;
    }
    
    function addVault(address _vault) external restrictAccess(GOVERNOR) {
        IStrategyVault(_vault).depositToken();
        if (!vaults.exists(_vault)) vaults.push(_vault);
    }

    function removeVault(address _vault) external restrictAccess(GOVERNOR) {
        uint index = vaults.findFirst(_vault);
        if (index<vaults.length) {
            vaults[index] = vaults[vaults.length-1];
            vaults.pop();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAddressProvider {
    
    function networkToken() external view returns (address);
    function usdc() external view returns (address);
    function usdt() external view returns (address);
    function dai() external view returns (address);
    function swapper() external view returns (address);
    function reserve() external view returns (address);
    function lendVault() external view returns (address);
    function borrowerManager() external view returns (address);
    function oracle() external view returns (address);
    function uniswapV3Integration() external view returns (address);
    function uniswapV3StrategyData() external view returns (address);
    function uniswapV3StrategyLogic() external view returns (address);
    function borrowerBalanceCalculator() external view returns (address);
    function keeper() external view returns (address);
    function governance() external view returns (address);
    function guardian() external view returns (address);
    function controller() external view returns (address);
    function vaults(uint index) external view returns (address);
    function getVaults() external view returns (address[] memory);

    function setNetworkToken(address token) external;
    function setUsdc(address token) external;
    function setUsdt(address token) external;
    function setDai(address token) external;
    function setReserve(address _reserve) external;
    function setSwapper(address _swapper) external;
    function setLendVault(address _lendVault) external;
    function setBorrowerManager(address _manager) external;
    function setOracle(address _oracle) external;
    function setUniswapV3Integration(address _integration) external;
    function setUniswapV3StrategyData(address _address) external;
    function setUniswapV3StrategyLogic(address _logic) external;
    function setBorrowerBalanceCalculator(address _logic) external;
    function setKeeper(address _keeper) external;
    function setGovernance(address _governance) external;
    function setGuardian(address _guardian) external;
    function setController(address _controller) external;
    function addVault(address _vault) external;
    function removeVault(address _vault) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IBorrower {

    /**
     * @notice Returns the equity value of the strategy in terms of its stable token
     * @dev balance can be negative, indicating how much excess debt there is
     */
    function balance() external view returns (int balance);

    /**
     * @notice Returns the value of all the assets in the borrower's possession expressed
     * in terms of the borrower's vault's deposit token
     */
    function tvl() external view returns (uint currentTvl);

    /**
     * @notice Calculate the max amount of stable token that can be supplied and
     * the corresponding amount of stable and volatile tokens that will be borrowed
     * from the LendVault
     */
    function getDepositableAndBorrowables() external view returns (uint depositable, address[] memory tokens, uint[] memory borrowables);

    /**
     * @notice Returns cached balance if balance has previously been calculated
     * otherwise sets the cache with newly calculated balance
     */
    function balanceOptimized() external returns (int balance);

    /**
     * @notice Returns all the tokens in the borrower's posession after liquidating everything
     */
    function getAmounts() external view returns (address[] memory tokens, uint[] memory amounts);
    
    /**
     * @notice Returns all the tokens borrowed
     */
    function getDebts() external view returns (address[] memory tokens, uint[] memory amounts);

    /**
     * @notice Function to liquidate everything and transfer all funds to LendVault
     * @notice Called in case it is believed that the borrower won't be able to cover its debts
     * @return tokens Siezed tokens
     * @return amounts Amounts of siezed tokens
     */
    function siezeFunds() external returns (address[] memory tokens, uint[] memory amounts);

    /**
     * @notice Updates all tracked variables that are used in pnl calculation
     * @dev This funciton was introduced such that the LendVault can call it after siezing funds
     */
    function updateTrackers() external;

    /**
     * @notice Reduce leverage in order to pay back the specified debt
     * @param token Token that needs to be paid back
     * @param amount Amount of token that needs to be paid back
     */
    function delever(address token, uint amount) external;

    /**
     * @notice Exit liquidity position and repay all debts
     */
    function exit() external;

    /**
     * @notice Deposits all available funds into the appropriate liquidity position
     */
    function deposit() external;

    /**
     * @notice Permissioned function for controller to withdraw a token from the borrower
     */
    function withdrawOther(address token) external;

    /**
     * @notice Permissioned function called from controller or vault to withdraw to vault
     */
    function withdraw(uint256) external;

    /**
     * @notice Permissioned function called from controller or vault to withdraw all funds to vault
     */
    function withdrawAll() external;

    /**
     * @notice Harvest the rewards from the liquidity position, swap them and reinvest them
     */
    function harvest() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IController {
    function vaults(address) external view returns (address);

    function setVault(address _token, address _vault) external;
    function withdrawAll(address _token) external;
    function inCaseTokensGetStuck(address _token, uint256 _amount) external;
    function inCaseStrategyTokenGetStuck(address _strategy, address _token) external;
    function forceWithdraw(address _token, uint256 _amount) external;
    function harvest(address _token) external;
    function earn(address _token) external;
    function withdraw(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ILendVaultStorage.sol";

/**
* @param totalShares The total amount of shares that have been minted on the deposits of the token
* @param totalDebtShares The total number of debt shares that have been issued to borrowers of the token
* @param totalDebt The combined debt for the token from all borrowers
* @param totalDebtPaid The amount of total debt that has been paid for the token
* @param interestRate The current interest rate of the token
* @param lastInterestRateUpdate the last timestamp at which the interest rate was updated
* @param totalCreditLimit Sum of credit limits for all borrowers for the token
* @param lostFunds Funds lost due to borrowers defaulting
*/
struct TokenData {
    uint totalShares;
    uint totalDebtShares;
    uint totalDebt;
    uint interestRate;
    uint lastInterestRateUpdate;
    uint totalCreditLimit;
    uint lostFunds;
}

/**
* @notice Struct representing tokens siezed from a borrower and the debts that need to be paid
* @param borrowedTokens Tokens that have been borrowed and must be repaid
* @param debts Amounts of tokens borrowed
* @param siezedTokens Tokens siezed from borrower
* @param siezedAmounts Amounts of siezed tokens
*/
struct SiezedFunds {
    address[] borrowedTokens;
    uint[] debts;
    address[] siezedTokens;
    uint[] siezedAmounts;
}

/**
* @notice Data for a token needed to track debts
* @param initialized Flag to tell wether the data for the token has been initialized, only initialized tokens are allowed to be interacted with in this contract
* @param optimalUtilizationRate Ideal utilization rate for token
* @param baseBorrowRate The interest rate when utilization rate is 0
* @param slope1 The rate at which the interest rate grows with respect to utilization before utilization is greater than optimalUtilizationRate
* @param slope2 The rate at which the interest rate grows with respect to utilization after utilization is greater than optimalUtilizationRate
*/
struct IRMData {
    bool initialized;
    uint optimalUtilizationRate;
    uint baseBorrowRate;
    uint slope1;
    uint slope2;
}

interface ILendVault is ILendVaultStorage {
    
    /**
     * @notice Event emitted on a lender depositing tokens
     * @param token Token being deposited
     * @param lender Lender depositing the token
     * @param amount Number of tokens deposited
     * @param shares Number of shares minted
     */
    event Deposit(address indexed token, address indexed lender, uint amount, uint shares);

    /**
     * @notice Event emitted on a lender withdrawing tokens
     * @param token Token being withdrawn
     * @param lender Lender withdrawing the token
     * @param amount Number of tokens withdrawn
     * @param shares Number of shares burnt during the withdrawal
     * @param fee Amount of tokens used up as fee in case borrowers had to deleverage
     */
    event Withdraw(address indexed token, address indexed lender, uint amount, uint shares, uint fee);
    
    /**
     * @notice Event emitted when a borrower borrows
     * @param token Token being borrowed
     * @param borrower Address of the borrower
     * @param amount Number of tokens being borrowed
     * @param shares Number of debt shares minted
     */
    event Borrow(address indexed token, address indexed borrower, uint amount, uint shares);
    
    /**
     * @notice Event emitted when a borrower repays debt
     * @param token Token being repayed
     * @param borrower Address of the borrower
     * @param amount Number of tokens being repayed
     * @param shares Number of debt shares repayed
     */
    event Repay(address indexed token, address indexed borrower, uint amount, uint shares);
    
    /**
     * @notice Initializes the interest rate model data for a token based on provided data
     */
    function initializeToken(address token, IRMData memory data) external;

    /**
     * @notice Whitelists or blacklists a borrower for a token
     * @param borrower Borrower whose access to borrowing needs to be modified
     * @param token The token to change borrowing access for
     * @param allowBorrow Wether the borrower should be allowed to borrow token or not
     */
    function setBorrowerWhitelist(address borrower, address token, bool allowBorrow) external;

    /**
     @notice Set health threshold
     */
    function setHealthThreshold(uint _healthThreshold) external;
    
    /**
     @notice Set maximum utilization rate beyond which further borrowing will be reverted
     */
    function setMaxUtilization(uint _maxUtilization) external;

    /**
     @notice Set slippage
     */
    function setSlippage(uint _slippage) external;
    
    /**
     @notice Set delever fee
     */
    function setDeleverFee(uint _deleverFee) external;

    /**
     * @notice Get list of supported tokens
     */
    function getSupportedTokens() external view returns (address[] memory);

    /**
     * @notice Get list of tokens and amounts currently borrowed by borrower
     * @return tokens The tokens that the borrower has borrowed or can borrow
     * @return amounts The amount of each borrowed token
     */
    function getBorrowerTokens(address borrower) external view returns (address[] memory tokens, uint[] memory amounts);
    
    /**
     * @notice Get list of borrowers and borrowed amounts for a token
     * @return borrowers The addresses that have borrowed or can borrow the token
     * @return amounts The amount borrowed by each borrower
     */
    function getTokenBorrowers(address token) external view returns (address[] memory borrowers, uint[] memory amounts);

    /**
     * @notice Returns the shares of a lender for a token
     */
    function balanceOf(address lender, address token) external view returns (uint shares);

    /**
     * @notice Returns the amount of tokens that belong to the lender based on the lenders shares
     */
    function tokenBalanceOf(address lender, address token) external view returns (uint amount);

    /**
     * @notice Returns the utilization rate for the provided token
     * @dev Utilization rate for a token is calculated as follows
     * - U_t = B_t/D_t
     * - where B_t is the total amount borrowed for the token and D_t is the total amount deposited for the token
     */
    function utilizationRate(address token) external view returns (uint utilization);

    /**
     * @notice Returns the current reserves for a token plus the combined debt that borrowers have for that token
     */
    function totalAssets(address token) external view returns (uint amount);

    /**
     * @notice Calculates the amount of shares that are equivalent to the provided amount of tokens
     * @dev shares = totalShares[token]*amount/totalAssets(token)
     */
    function convertToShares(address token, uint amount) external view returns (uint shares);

    /**
     * @notice Calculates the amount of tokens that are equivalent to the provided amount of shares
     * @dev amount = totalAssets(token)*shares/totalShares(token)
     */
    function convertToAssets(address token, uint shares) external view returns (uint tokens);

    /**
     * @notice Calculates the total debt of a token including accrued interest
     */
    function getTotalDebt(address token) external view returns (uint totalDebt);

    /**
     * @notice Get the current debt of a borrower for a token
     */
    function getDebt(address token, address borrower) external view returns (uint debt);

    /**
     * @notice Get the health of the borrower
     * @dev health can be calculated approximated as:
     *      health = PRECISION*(totalETHValue-debtETHValue)/debtETHValue
     * @dev If a borrower can pay back nothing, health will be -PRECISION
     * @dev If a borrower can pay back exactly the debt and have nothing left, health will be 0
     */
    function checkHealth(address borrower) external view returns (int health);

    /**
     * @notice Accepts a deposit of a token from a user and mints corresponding shares
     * @dev The amount of shares minted are based on the convertToShares function
     */
    function deposit(address token, uint amount) external payable;
    
    /**
     * @notice Burns a user's shares corresponding to a token to redeem the deposited tokens
     * @dev The amount of tokens returned are based on the convertToAssets function
     * @dev In case the LendVault doesn't have enough tokens to pay back, funds will be requested from reserve
     * and tokens will be minted to the reserve corrseponding to how many tokens the reserve provides
     * @dev In case the reserve is unable to meet the demand, the BorrowerManager will delever the strategies
     * This will free up enough funds for the lender to withdraw
     * @dev A fee will also be charged in case deleveraging of borrowers is involved
     * This fee will be used as gas fee to re-optimize the ratio of leverages between borrowers
     */
    function withdrawShares(address token, uint shares) external;

    /**
     * @notice Similar to withdraw shares, but input is in amount of tokens
     */
    function withdrawAmount(address token, uint amount) external;

    /**
     * @notice Withdraws the entirety of a lender's deposit into the LendVault
     */
    function withdrawMax(address token) external;

    /**
     * @notice Function called by a whitelisted borrower to borrow a token
     * @dev For each borrower, debt share is recorded rather than debt amount
     * This makes it easy to accrue interest by simply increasing totalDebt
     * @dev Borrower debt can be calculated as: debt = debtShare*totalDebt/totalDebtShares
     * @param token Token to borrow from the vault
     * @param amount Amount of token to borrow
     */
    function borrow(address token, uint amount) external;

    /**
     * @notice Repay a borrowers debt of a token to the vault
     * @param token Token to repay to the vault
     * @param shares Debt shares to repay
     */
    function repayShares(address token, uint shares) external;

    /**
     * @notice Identical to repayShares, but input is in amount of tokens to repay
     */
    function repayAmount(address token, uint amount) external;

    /**
     * @notice Repays the max amount of tokens that the borrower can repay
     * @dev Repaid amount is calculated as the minimum of the borrower's balance
     * and the size of the borrower's debt
     */
    function repayMax(address token) external;

    /**
     * @notice Seize all the funds of a borrower to cover its debts and set its credit limit to 0
     * @dev Function will revert if the borrower's health is still above healthThreshold
     */
    function kill(address borrower) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ILendVaultStorage {

    function tokenData(address token) external view returns (uint, uint, uint, uint, uint, uint, uint);
    function irmData(address token) external view returns (bool, uint, uint, uint, uint);
    function debtShare(address token, address borrower) external view returns (uint);
    function creditLimits(address token, address borrower) external view returns (uint);
    function borrowerTokens(address borrower, uint index) external view returns (address);
    function tokenBorrowers(address token, uint index) external view returns (address);
    function supportedTokens(uint index) external view returns (address);
    function healthThreshold() external view returns (uint);
    function maxUtilization() external view returns (uint);
    function slippage() external view returns (uint);
    function deleverFeeETH() external view returns (uint);
    function borrowerWhitelist(address token, address borrower) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import "@uniswap/v3-periphery/contracts/interfaces/IPoolInitializer.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IERC721Permit.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IOracle {
    /**
     * @notice Get the USD price of a token
     * @dev Price has a precision of 18
     */
    function getPrice(address token) external view returns (uint price);

    /**
     * @notice Gets the price of a token in terms of another token
     */
    function getPriceInTermsOf(address token, address inTermsOf) external view returns (uint price);

    /**
     * @notice Get the USD value of a specific amount of a token
     */
    function getValue(address token, uint amount) external view returns (uint value);

    /**
     * @notice Get the value of a specific amount of a token in terms of another token
     */
    function getValueInTermsOf(address token, uint amount, address inTermsOf) external view returns (uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IReserve {

    /**
     * @notice Returns the expected balance of the reserve in terms of USD
     * @dev balance includes both token balances as well as LendVault shares expressed
     * in terms of USD
     */
    function expectedBalance() external view returns (uint balance);

    /**
     * @notice Request made by LendVault to get funds for withdrawal from a lender in event of high utilization or borrowers defaulting
     * @return fundsSent Amount of tokens sent back
     */
    function requestFunds(address token, uint amount) external returns(uint fundsSent);

    /**
     * @notice Burn the shares that the reserve received from LendVault for assisting withdrawals during low liquidity
     */
    function burnLendVaultShares(address token, uint shares) external;

    /**
     * @notice Withdraw a specified amount of a token to the governance address
     */
    function withdraw(address token, uint amount) external;

    /**
     * @notice Sets the slippage variable to use while using swapper
     * @notice Swaps are performed if a token is requested but the reserve doesn't
     * have enough of the token
     */
    function setSlippage(uint _slippage) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IStrategyVault {

    function depositToken() external view returns (address);
    function strategies(uint) external view returns (address);
    function strategyAllocation(uint) external view returns (uint256);
    function previousHarvestTimeStamp() external view returns (uint);
    function waterMark() external view returns (uint);
    function performanceFee() external view returns (uint);
    function adminFee() external view returns (uint);
    function withdrawalFee() external view returns (uint);
    function governanceFee() external view returns (uint);
    function deposited(address _strategy) external view returns (uint);
    function withdrawn(address _strategy) external view returns (uint);
    function numPositions() external view returns (uint);
    function maxStrategies() external view returns (uint);
    function maxFee() external view returns (uint);


    // User Actions
    function deposit(uint256 _amount) external;
    function depositAll() external;
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;

    // Governance Actions
    function setFees(uint performance, uint admin, uint withdrawal) external;
    function setGovernanceFee(uint _governanceFee) external;
    function setStrategiesAndAllocations(address[] memory _strategies, uint256[] memory _strategiesAllocation) external;

    // View Functions
    function version() external pure returns (string memory);
    function getStrategies() external view returns (address[] memory strats);
    function getStrategyAllocations() external view returns (uint[] memory allocations);
    function getPricePerFullShare() external view returns (uint256);
    function getPricePerFullShareOptimized() external returns (uint256);
    function getWithdrawable(address user) external view returns (uint);
    function balance() external view returns (uint256);
    function balanceOptimized() external returns (uint256);
    function vaultCapacity() external view returns (uint depositable, uint tvl, uint capacity);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface ISwapper {

    /**
     @notice Returns the value a the provided token in terms of ETH
     */
    function getETHValue(address token, uint amount) external view returns (uint value);

    /**
     * @notice Returns the value of the provided tokens in terms of ETH
     */
    function getETHValue(address[] memory tokens, uint[] memory amoutns) external view returns (uint value);

    /**
     @notice Get the amount of tokenIn needed to get amountOut tokens of tokenOut
     */
    function getAmountIn(address tokenIn, uint amountOut, address tokenOut) external view returns (uint amountIn);

    /**
     * @notice Returns the amount of tokenOut that can be obtained from amountIn worth of tokenIn
     */
    function getAmountOut(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut);

    /**
     * @notice Swap an exact amount of a token for another token
     * @dev slippage represents how much of a loss can be accepted
     * Max slippage is PRECISION, in which case all funds can be lost
     * Min slippage is 0, representing no loss of funds
     */
    function swapExactTokensForTokens(address tokenIn, uint amountIn, address tokenOut, uint slippage) external returns (uint amountOut);

    /**
     * @notice Swap a token for a specific amount of another token
     * @dev slippage represents how much of a loss can be accepted
     * Max slippage is PRECISION, in which case all funds can be lost
     * Min slippage is 0, representing no loss of funds
     */
    function swapTokensForExactTokens(address tokenIn, uint amountOut, address tokenOut, uint slippage) external returns (uint amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

library AddressArray {

    function findFirst(address[] memory self, address toFind) internal pure returns (uint) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                return i;
            }
        }
        return self.length;
    }

    function exists(address[] memory self, address toFind) internal pure returns (bool) {
        for (uint i = 0; i < self.length; i++) {
            if (self[i] == toFind) {
                return true;
            }
        }
        return false;
    }

    function copy(address[] memory self) internal pure returns (address[] memory copied) {
        copied = new address[](self.length);
        for (uint i = 0; i < self.length; i++) {
            copied[i] = self[i];
        }
    }

    function sortDescending(
        address[] memory self,
        uint[] memory nums
    ) internal pure returns (address[] memory, uint[] memory) {
        uint n = nums.length;
        for (uint i = 0; i < n - 1; i++) {
            for (uint j = 0; j < n - i - 1; j++) {
                if (nums[j] < nums[j + 1]) {
                    // Swap nums[j] and nums[j + 1]
                    uint temp = nums[j];
                    nums[j] = nums[j + 1];
                    nums[j + 1] = temp;

                    // Swap self[j] and self[j + 1]
                    address tempAddress = self[j];
                    self[j] = self[j + 1];
                    self[j + 1] = tempAddress;
                }
            }
        }
        return (self, nums);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IAddressProvider.sol";

/**
 * @dev Contract module that handles access control based on an address provider
 *
 * Each access level corresponds to an administrative address
 * A function can restrict access to a specific group of administrative addresses by using restrictAccess
 * In order to restrict access to GOVERNOR and CONTROLLER, the modifier should be restrictAccess(GOVERNOR | CONTROLLER)
 */
contract AccessControl is Initializable {

    uint public constant PRECISION = 1e20;
    
    // Access levels
    uint256 internal constant GOVERNOR = 1;
    uint256 internal constant KEEPER = 2;
    uint256 internal constant GUARDIAN = 4;
    uint256 internal constant CONTROLLER = 8;
    uint256 internal constant LENDVAULT = 16;

    // Address provider that keeps track of all administrative addresses
    IAddressProvider public provider;

    function __AccessControl_init(address _provider) internal onlyInitializing {
        provider = IAddressProvider(_provider);
        provider.governance();
    }

    function getAdmin(uint accessLevel) private view returns (address){
        if (accessLevel==GOVERNOR) return provider.governance();
        if (accessLevel==KEEPER) return provider.keeper();
        if (accessLevel==GUARDIAN) return provider.guardian();
        if (accessLevel==CONTROLLER) return provider.controller();
        if (accessLevel==LENDVAULT) return provider.lendVault();
        return address(0);
    }

    /**
     * @dev Function that checks if the msg.sender has access based on accessLevel
     * The check is performed outside of the modifier to minimize contract size
     */
    function _checkAuthorization(uint accessLevel) private view {
        bool authorized = false;
        for (uint i = 0; i<5; i++) {
            if ((accessLevel & 2**(i)) == 2**(i)) {
                if (msg.sender == getAdmin(2**(i))) {
                    return;
                }
            }

        }
        require(authorized, "Unauthorized");
    }


    modifier restrictAccess(uint accessLevel) {
        _checkAuthorization(accessLevel);
        _;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}