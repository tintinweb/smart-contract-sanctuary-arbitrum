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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

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

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
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
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
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
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
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
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     * - input must fit into 8 bits.
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
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1
/**
 *
 * For additional terms of the smart contract, please refer to the documentation uploaded under the documents section.
 * You can access the documents by calling the smart contract function named "getAllDocuments".
 *
 */
pragma solidity 0.8.15;

import {IERC20Standard} from "../../../interfaces/IERC20Standard.sol";
import {IAddressScreen} from "../../../interfaces/IAddressScreen.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {PreciseUnitMath} from "../../../libs/PreciseUnitMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title PV01SinglePaymentBondV1
 * @dev PV01SinglePaymentBond implementation contract for V1.
 * We intentionally use the "*Upgradeable.sol" versions of the Open Zeppelin contracts where applicable
 * because they support the initializer pattern which is required to support the bond factory initializing the clones it produces.
 */
contract PV01SinglePaymentBondV1 is PausableUpgradeable, OwnableUpgradeable, ERC20Upgradeable {
  using PreciseUnitMath for uint256;
  using SafeERC20 for IERC20Standard;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.Bytes32Set;
  using Address for address;

  /**
   * @dev Emitted when the address screening contract being used by this bond contract changes
   */
  event AddressScreenContractUpdated(address indexed newAddress, string reason);

  /**
   * @dev Emitted when an investor successfully claims their investment plus yield
   */
  event Claim(address indexed addr, uint256 bondTokenAmount, uint256 assetTokenAmount);

  /**
   * @dev Emitted when a funding commitment is removed from this bond contract
   */
  event FundingCommitmentRemoved(address indexed addr);

  /**
   * @dev Emitted when a funding commitment is updated on this bond contract
   */
  event FundingCommitmentUpdated(address indexed addr, uint256 bondTokenAmount, uint256 proceed, uint256 date);

  /**
   * @dev Emitted when a new document is added to this bond contract
   */
  event NewDocumentAdded(bytes32 indexed docNameHash, string docName, string uri, bytes32 docHashSha256);

  /**
   * @dev Emitted when a new funding commitment is added to this bond contract
   */
  event NewFundingCommitmentAdded(address indexed addr, uint256 bondTokenAmount, uint256 proceed, uint256 date);

  /**
   * @dev Emitted when all bond tokens have been claimed
   */
  event Redeemed();

  /**
   * @dev Emitted when this bond's maturity date is updated
   */
  event MaturityDateUpdated(uint64 newDate, string reason);

  /**
   * @dev Emitted when an investor pays a funding commitment
   */
  event SettleBondPurchase(address indexed addr, uint256 bondTokenAmount, uint256 proceed);

  /**
   * @dev Emitted when this bond is swept of remaining bond tokens
   */
  event Sweep(address indexed addr, uint256 assetTokenAmount);

  /**
   * @dev Emitted when this bond is swept of any non-bond tokens
   */
  event SweepOther(address indexed addr, address otherTokenAddress, uint256 otherTokenAmount);

  /**
   * @dev Caller address must be in the address screen allow list
   */
  modifier onlyAllowListed() {
    require(addressScreen.isAllowListed(msg.sender), "The caller must be in the allow list");
    _;
  }

  /**
   * @dev Details of a funding commitment
   */
  struct FundingCommitmentInternal {
    uint256 bondTokenAmount;
    uint256 proceed;
    uint256 date;
  }

  /**
   * @dev Details of a funding commitment along with the investor address for that funding commitment
   */
  struct FundingCommitmentExternal {
    address address_;
    FundingCommitmentInternal fundingCommitmentInternal;
  }

  /**
   * @dev Document details as stored in the bond contract
   */
  struct DocumentDetail {
    string docName;
    bytes32 docNameHash;
    bytes32 docHashSha256;
    uint256 lastModified;
    string uri;
  }

  /**
   * @dev Document specification provided when a document is created
   */
  struct DocumentSpec {
    string docName;
    bytes32 docHashSha256;
    string uri;
  }

  //------------------------------------------------------------------------------
  // Funding commitments
  //------------------------------------------------------------------------------
  /**
   * @dev Mapping of investor address => funding commitment details
   */
  mapping(address => FundingCommitmentInternal) internal fundingCommitments;

  /**
   * @dev Set of investor addresses that have funding commitments. Once an investor settles the bond purchase, the funding commitment is removed.
   */
  EnumerableSet.AddressSet internal addressWithFundingCommitment;

  //------------------------------------------------------------------------------
  // Documents
  //------------------------------------------------------------------------------
  /**
   * @dev Mapping of document name hashes => document details
   */
  mapping(bytes32 => DocumentDetail) internal documents;

  /**
   * @dev Set of document name hashes
   */
  EnumerableSet.Bytes32Set internal docNameHashes;

  //------------------------------------------------------------------------------
  // Asset token
  //------------------------------------------------------------------------------
  /**
   * @dev Number of decimals on the asset token
   */
  uint8 public assetTokenDecimals;

  /**
   * @dev Asset token
   */
  IERC20Standard public assetToken;

  //------------------------------------------------------------------------------
  // Bond details
  //------------------------------------------------------------------------------
  /**
   * @dev Maturity date for this bond contract
   */
  uint64 public maturityDate;

  /**
   * @dev Address screen contract used by this bond contract
   */
  IAddressScreen public addressScreen;

  /**
   * @dev Interest rate fraction of the investment, held as percentage with 18 decimals for example:
   * 10% => interestRateFraction_ = 10 ** 17. The interest rate fraction is not the annualised interest
   * rate, it is already pro-rata and can be used directly to calculate the total amount to redeem. Max value
   * is 1844% (a uint64 storing 18 decimals equivalent).
   */
  uint64 public interestRateFraction;

  /**
   * @dev Address of the bond issuer
   */
  address public bondIssuer;

  /**
   * @dev Time interval in seconds between the maturity date and the earliest possible sweep date.
   * This time interval is fixed at bond creation time and is used to calculate actual sweep date according
   * to the current maturity date.
   */
  uint64 public sweepDelaySecondsFromMaturityDate;

  /**
   * @dev Bond collateral identifier
   */
  string public collateralId;

  /**
   * @dev Bond type
   */
  bytes32 public constant BOND_TYPE = "SinglePaymentBond";

  /**
   * @dev Bond version for bond type
   */
  uint8 public constant VERSION = 1;

  string internal constant REASON_INITIALIZE = "Initialize";

  constructor() {
    _disableInitializers();
  }

  //------------------------------------------------------------------------------
  // External
  //------------------------------------------------------------------------------
  /**
    @dev Make explicit the intention to revert transaction if contract is directly sent Ether
  */
  receive() external payable {
    revert("Cannot send Ether directly to this contract");
  }

  /**
   * @dev Add a new document, reverts if document name already exists. Can emit {NewDocumentAdded}.
   * @param documentSpec the document specification
   */
  function addDocument(DocumentSpec calldata documentSpec) external onlyOwner {
    _addDocument(documentSpec);
  }

  /**
   * @dev Create multiple documents at once, reverts if any document name already exists.
   * Can emit one or more {NewDocumentAdded}.
   * @param documentSpecs array of document specifications
   */
  function addDocuments(DocumentSpec[] calldata documentSpecs) external onlyOwner {
    uint256 length = documentSpecs.length;
    require(length > 0, "No document specifications provided");
    for (uint256 i = 0; i < length; ) {
      _addDocument(documentSpecs[i]);
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Add a funding commitment. Can emit {NewFundingCommitmentAdded}.
   * @param fundingCommitment FundingCommitmentExternal
   */
  function addFundingCommitment(FundingCommitmentExternal calldata fundingCommitment) external onlyOwner {
    _addFundingCommitment(fundingCommitment);
  }

  /**
   * @dev Add funding commitments. Can emit one or more {NewFundingCommitmentAdded}.
   * @param fundingCommitments_ FundingCommitmentExternal[]
   */
  function addFundingCommitments(FundingCommitmentExternal[] calldata fundingCommitments_) external onlyOwner {
    uint256 length = fundingCommitments_.length;
    require(length > 0, "No Funding commitments provided");
    for (uint256 i = 0; i < length; ) {
      _addFundingCommitment(fundingCommitments_[i]);
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Add funding commitments and documents. This is a helper function to reduce possible approval
   * steps and save gas. If any funding commitment or any document is not valid, the whole transaction
   * reverts. Leaving either funding commitments or documents arrays empty is fine, but not both.
   * Can emit none, one or more {NewFundingCommitmentAdded} and {NewDocumentAdded}.
   * @param fundingCommitments_ array of funding commitments
   * @param documentSpecs_ array of document specifications
   */
  function addFundingCommitmentsAndDocuments(
    FundingCommitmentExternal[] calldata fundingCommitments_,
    DocumentSpec[] calldata documentSpecs_
  ) external onlyOwner {
    uint256 fundingsLength = fundingCommitments_.length;
    uint256 docsLength = documentSpecs_.length;
    require(fundingsLength > 0 || docsLength > 0, "Must provide either funding commitments, or documents, or both");

    // Funding commitments
    if (fundingsLength > 0) {
      for (uint256 i = 0; i < fundingsLength; ) {
        _addFundingCommitment(fundingCommitments_[i]);
        unchecked {
          i++;
        }
      }
    }

    // Documents
    if (docsLength > 0) {
      for (uint256 i = 0; i < docsLength; ) {
        _addDocument(documentSpecs_[i]);
        unchecked {
          i++;
        }
      }
    }
  }

  /**
   * @dev Burn an amount of bond tokens that are owned by the allow-listed sender. Equivalent of the sender doing a transfer to
   * address zero, but with the addition of reducing total supply. Can emit a {Transfer} event to address zero.
   * @param amount of bond tokens to burn
   */
  function burn(uint256 amount) external whenNotPaused onlyAllowListed {
    require(amount <= balanceOf(msg.sender), "Insufficient bond tokens held by sender");
    _burn(msg.sender, amount);
  }

  /**
   * @dev Get all documents. This includes all document details. We expect 2 or 3 docs per bond.
   * @return DocumentDetail[] array of document names
   */
  function getAllDocuments() external view returns (DocumentDetail[] memory) {
    uint256 length = docNameHashes.length();
    DocumentDetail[] memory docs = new DocumentDetail[](length);
    for (uint256 i = 0; i < length; ) {
      bytes32 docNameHash = docNameHashes.at(i);
      docs[i] = documents[docNameHash];
      unchecked {
        i++;
      }
    }
    return docs;
  }

  /**
   * @dev Get names of all documents. Expect 2 or 3 docs per bond.
   * @return string[] array of document names
   */
  function getAllDocumentNames() external view returns (string[] memory) {
    uint256 length = docNameHashes.length();
    string[] memory docNames = new string[](length);
    for (uint256 i = 0; i < length; ) {
      bytes32 docNameHash = docNameHashes.at(i);
      DocumentDetail memory document = documents[docNameHash];
      docNames[i] = document.docName;
      unchecked {
        i++;
      }
    }
    return docNames;
  }

  /**
   * @dev external function to get all the funding commitment
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees.
   */
  function getAllFundingCommitment() external view returns (FundingCommitmentExternal[] memory) {
    address[] memory addressWithFundingCommitment_ = addressWithFundingCommitment.values();
    FundingCommitmentExternal[] memory fundingCommitments_ = new FundingCommitmentExternal[](
      addressWithFundingCommitment_.length
    );
    for (uint256 i = 0; i < addressWithFundingCommitment_.length; ) {
      fundingCommitments_[i] = FundingCommitmentExternal({
        address_: addressWithFundingCommitment_[i],
        fundingCommitmentInternal: fundingCommitments[addressWithFundingCommitment_[i]]
      });
      unchecked {
        i++;
      }
    }
    return fundingCommitments_;
  }

  /**
   * @dev Amount of asset token remaining to be repaid by the bond issuer.
   * This is a convenience function for those interacting with the bond contract outside the platform.
   * The minimum value this function can return is zero, meaning nothing is due.
   * @return assetTokenAmount remaining to be repaid by the bond issuer
   */
  function getAmountToRepay() external view returns (uint256 assetTokenAmount) {
    uint256 totalDue = _calculateAmount(totalSupply(), interestRateFraction);
    uint256 totalReceived = assetToken.balanceOf(address(this));
    if (totalDue > totalReceived) {
      return totalDue - totalReceived;
    } else {
      return 0;
    }
  }

  /**
   * @dev Get details of a document
   * @param docName name of the document
   * @return DocumentDetail document detail
   */
  function getDocument(string calldata docName) external view returns (DocumentDetail memory) {
    bytes32 docNameHash = keccak256(abi.encodePacked(docName));
    return (documents[docNameHash]);
  }

  /**
   * @dev Returns the final amount of asset tokens based on the bond token amount provided as input.
   * @param bondTokenAmount_ uint256: amount of bond token to be used to calculate the final amount
   */
  function getFinalAmount(uint256 bondTokenAmount_) external view returns (uint256) {
    return _calculateAmount(bondTokenAmount_, interestRateFraction);
  }

  /**
   * @dev Returns the final amount of asset tokens based on the bond token balance of the user.
   * @param user_ address: address of the user to be used to calculate the final amount
   */
  function getFinalAmount(address user_) external view returns (uint256) {
    return _calculateAmount(balanceOf(user_), interestRateFraction);
  }

  /**
   * @dev Returns the funding commitment for the provided user address.
   * @param userAddress address: address of the user.
   */
  function getFundingCommitment(address userAddress) external view returns (FundingCommitmentInternal memory) {
    return fundingCommitments[userAddress];
  }

  /**
   * @dev Returns the addresses of all the user that have a funding commitment.
   */
  function getFundingCommitmentInvestors() external view returns (address[] memory) {
    return addressWithFundingCommitment.values();
  }

  /**
   * @dev Returns timestamp of the earliest date that a sweep can happen
   * @return unix timestamp of sweep date
   */
  function getSweepDate() external view returns (uint64) {
    return maturityDate + sweepDelaySecondsFromMaturityDate;
  }

  /**
   * @dev Called at bond creation time to initialise a new bond
   * @param name_ string: name of the bond
   * @param symbol_ string: symbol of the bond
   * @param fundingCommitments_ FundingCommitmentExternal[]: initial funding commitment
   * @param assetTokenAddress_ address: address of the asset token for the investments
   * @param interestRateFraction_ uint64: interest rate fraction of the investment, must be initialized as a percentage with
   *        18 decimals for example: 10% => interestRateFraction_ = 10 ** 17. The interest rate fraction is not the annualised interest
   *        rate, it is already pro-rata and can be used directly to calculate the total amount to redeem. Max value is 1844% (a
   *        uint64 storing 18 decimals equivalent). Converted to uint256 during calculations.
   * @param maturityDate_ uint64: unix timestamp of the maturity date
   * @param bondIssuer_ address: address of the bond issuer which will receive the investment token
   * @param addressScreen_ address: address of the previously deployed address screening contract
   * @param sweepDate_ uint64: unix timestamp of earliest sweep date, must be at least 7 days later than maturity date
   * @param owner_ address: owner administrator of bond able to call admin functions
   * @param collateralId_ string: external id of bond, may be blank
   */
  function initialize(
    string memory name_,
    string memory symbol_,
    FundingCommitmentExternal[] memory fundingCommitments_,
    address assetTokenAddress_,
    uint64 interestRateFraction_,
    uint64 maturityDate_,
    address bondIssuer_,
    address addressScreen_,
    uint64 sweepDate_,
    address owner_,
    string memory collateralId_
  ) public virtual initializer {
    require(bondIssuer_ != address(0), "bondIssuer cannot be address zero");
    require(sweepDate_ > maturityDate_, "sweepDate must be after maturityDate");
    require(owner_ != address(0), "Owner cannot be address zero");
    require(bytes(name_).length != 0, "name cannot be empty string");
    require(bytes(symbol_).length != 0, "symbol cannot be empty string");
    require(assetTokenAddress_ != address(0), "assetTokenAddress cannot be address zero");
    require(assetTokenAddress_.isContract(), "assetTokenAddress is not a contract");

    // ERC20 and owners
    __ERC20_init(name_, symbol_);
    _transferOwnership(owner_);
    bondIssuer = bondIssuer_;

    // Asset token, interest
    assetToken = IERC20Standard(assetTokenAddress_);
    assetTokenDecimals = assetToken.decimals();
    interestRateFraction = interestRateFraction_;

    // Dates
    _setMaturityDate(maturityDate_, REASON_INITIALIZE);
    sweepDelaySecondsFromMaturityDate = sweepDate_ - maturityDate;
    require(
      sweepDelaySecondsFromMaturityDate >= 3 days,
      "Sweep date must be at least 3 days after maturity date"
    );

    // Address screening
    _setAddressScreenContract(addressScreen_, REASON_INITIALIZE);

    // Funding commitments
    uint256 length_ = fundingCommitments_.length;
    for (uint256 i = 0; i < length_; ) {
      _addFundingCommitment(fundingCommitments_[i]);
      unchecked {
        i++;
      }
    }

    // Bond id
    collateralId = collateralId_;
  }

  /**
   * @dev Remove the funding commitment of the specified user. Can emit {FundingCommitmentRemoved}.
   * @param userAddress address
   */
  function removeFundingCommitment(address userAddress) external onlyOwner {
    _removeFundingCommitment(userAddress);
  }

  /**
   * @dev Remove funding commitments of the specified users. Can emit one or more {FundingCommitmentRemoved}.
   * @param userAddresses address
   */
  function removeFundingCommitments(address[] calldata userAddresses) external onlyOwner {
    uint256 length = userAddresses.length;
    for (uint256 i = 0; i < length; ) {
      _removeFundingCommitment(userAddresses[i]);
      unchecked {
        i++;
      }
    }
  }

  /**
   * @dev Checks and sets the address screening contract. Can emit {AddressScreenContractUpdated}.
   * @param newAddress new address of the screening contract
   * @param reason the reason for the change
   */
  function setAddressScreenContract(address newAddress, string calldata reason) external onlyOwner {
    _setAddressScreenContract(newAddress, reason);
  }

  /**
   * @dev Checks and sets a maturity date. Can emit {MaturityDateUpdated}.
   * @param newDate the maturity date
   * @param reason the reason for the change
   */
  function setMaturityDate(uint64 newDate, string calldata reason) external onlyOwner {
    // checks applied for external calls only (these checks do not apply during contract init)
    require(
      addressWithFundingCommitment.length() == 0,
      "Cannot change maturity date if funding commitments are present"
    );
    _setMaturityDate(newDate, reason);
  }

  /**
   * @dev Update a funding commitment. Can emit {FundingCommitmentUpdated}.
   * @param fundingCommitment FundingCommitmentExternal
   */
  function updateFundingCommitment(FundingCommitmentExternal calldata fundingCommitment) external onlyOwner {
    _updateFundingCommitment(fundingCommitment);
  }

  /**
   * @dev Update funding commitments. Can emit one more {FundingCommitmentUpdated}.
   * @param fundingCommitments_ FundingCommitmentExternal[]
   */
  function updateFundingCommitments(FundingCommitmentExternal[] calldata fundingCommitments_) external onlyOwner {
    uint256 length = fundingCommitments_.length;
    for (uint256 i = 0; i < length; ) {
      _updateFundingCommitment(fundingCommitments_[i]);
      unchecked {
        i++;
      }
    }
  }

  //------------------------------------------------------------------------------
  // Public
  //------------------------------------------------------------------------------
  /**
   * @dev Can be called by allow listed address in order to claim the investment.
   * Can emit {Claim} if claim was successful and {Redeemed} if bond is fully redeemed.
   * @return bondTokenAmount uint256: amount of bond token claimed
   * @return assetTokenAmount uint256: amount of asset token received by the user
   */
  function claim()
    public
    virtual
    whenNotPaused
    onlyAllowListed
    returns (uint256 bondTokenAmount, uint256 assetTokenAmount)
  {
    // Checks
    bondTokenAmount = balanceOf(msg.sender);
    require(bondTokenAmount > 0, "No bond token to claim");
    require(isRepaidInFull(), "The contract does not have the full amount of money to repay everyone back");

    // Effects
    _burn(msg.sender, bondTokenAmount);
    assetTokenAmount = _calculateAmount(bondTokenAmount, interestRateFraction);

    // Interactions (safeTransfer reverts if unsuccessful)
    assetToken.safeTransfer(msg.sender, assetTokenAmount);
    // events
    emit Claim(msg.sender, bondTokenAmount, assetTokenAmount);
    if (totalSupply() == 0) {
      // all funds have been claimed, the bond is redeemed
      emit Redeemed();
    }
  }

  /**
   * @dev Return decimals for the bond token. This is the same decimals as the associated asset token.
   */
  function decimals() public view override returns (uint8) {
    return assetTokenDecimals;
  }

  /**
   * @return hasBeenRepaid bool: did the bond issuer pay back the debt in full?
   */
  function isRepaidInFull() public view virtual returns (bool) {
    uint256 totalSupply_ = totalSupply();
    if (totalSupply_ > 0) {
      // bond tokens exist, do we have enough asset token to repay everyone?
      return assetToken.balanceOf(address(this)) >= _calculateAmount(totalSupply_, interestRateFraction);
    } else {
      // no bond tokens, can only have repaid in full if no funding commitments remain
      return addressWithFundingCommitment.length() == 0;
    }
  }

  /**
   * @dev Pauses this bond contract, preventing claim, settle bond purchase, bond token transfers.
   */
  function pause() public onlyOwner {
    _pause();
  }

  /**
   * @dev Can be called by an address in the funding commitment list in order to fulfill a funding commitment.
   * Can emit {SettleBondPurchase}.
   * @return bondTokenAmount uint256: amount of new bond token minted
   * @return proceed uint256: amount of asset token sent by the user to the bond issuer
   */
  function settleBondPurchase() public virtual whenNotPaused returns (uint256 bondTokenAmount, uint256 proceed) {
    // Checks
    bondTokenAmount = fundingCommitments[msg.sender].bondTokenAmount;
    proceed = fundingCommitments[msg.sender].proceed;
    require(bondTokenAmount > 0, "No funding commitment");
    uint256 date_ = fundingCommitments[msg.sender].date;
    require(block.timestamp <= date_, "Funding commitment date already passed");
    require(block.timestamp > date_ - (24 hours), "Timeout period has not finished yet");

    // Effects
    addressWithFundingCommitment.remove(msg.sender);
    delete fundingCommitments[msg.sender];

    // Interactions (safeTransferFrom reverts if unsuccessful)
    assetToken.safeTransferFrom(msg.sender, bondIssuer, proceed);
    _mint(msg.sender, bondTokenAmount);
    // events
    emit SettleBondPurchase(msg.sender, bondTokenAmount, proceed);
  }

  /**
   * @dev Can be called by the owner in order to take off all the remaining asset token in the bond.
   * The tokens are sent to the bond issuer. Can emit {Sweep}.
   * @return transferAmount uint256: amount of asset token received by the bond issuer
   */
  function sweep() public virtual onlyOwner returns (uint256 transferAmount) {
    require(
      block.timestamp >= (maturityDate + sweepDelaySecondsFromMaturityDate),
      "Sweep date not yet passed"
    );
    transferAmount = assetToken.balanceOf(address(this));
    require(transferAmount > 0, "There is nothing to sweep");
    assetToken.safeTransfer(bondIssuer, transferAmount);
    emit Sweep(bondIssuer, transferAmount);
  }

  /**
   * @dev Can be called by the owner in order to take off any other tokens accidentally sent to the bond. This means
   * tokens other than the asset token. The tokens are sent to the bond issuer. Can emit {SweepOther}.
   * @return transferAmount uint256: amount of token received by the bond issuer
   */
  function sweepOther(address otherTokenAddress) public virtual onlyOwner returns (uint256 transferAmount) {
    require(otherTokenAddress != address(assetToken), "Use sweep() to sweep asset token");
    IERC20Standard otherToken = IERC20Standard(otherTokenAddress);
    transferAmount = otherToken.balanceOf(address(this));
    require(transferAmount > 0, "There is nothing to sweep");
    otherToken.safeTransfer(bondIssuer, transferAmount);
    emit SweepOther(bondIssuer, otherTokenAddress, transferAmount);
  }

  /**
   * @dev Unpauses this bond contract, allowing claim, settle bond purchase, bond token transfers.
   */
  function unpause() public onlyOwner {
    _unpause();
  }

  //------------------------------------------------------------------------------
  // Internal
  //------------------------------------------------------------------------------

  /**
   * @dev Add a new document, reverts if document name already exists. Can emit {NewDocumentAdded}.
   * @param documentSpec the document specification
   */
  function _addDocument(DocumentSpec memory documentSpec) internal {
    string memory docName = documentSpec.docName;
    require(bytes(docName).length > 0, "Invalid document name");
    require(bytes(documentSpec.uri).length > 0, "Invalid URI");

    bytes32 docNameHash = keccak256(abi.encodePacked(docName));
    require(docNameHashes.add(docNameHash), "Document already exists for this docName");
    documents[docNameHash] = DocumentDetail(
      docName,
      docNameHash,
      documentSpec.docHashSha256,
      block.timestamp,
      documentSpec.uri
    );
    emit NewDocumentAdded(docNameHash, docName, documentSpec.uri, documentSpec.docHashSha256);
  }

  /**
   * @dev Internal function to add a funding commitment. Can emit {NewFundingCommitmentAdded}.
   * @param fundingCommitment FundingCommitmentExternal
   */
  function _addFundingCommitment(FundingCommitmentExternal memory fundingCommitment) internal {
    require(
      addressWithFundingCommitment.add(fundingCommitment.address_),
      "Funding commitment already exist for this address"
    );
    _checkAndSetFundingCommitment(fundingCommitment);
    emit NewFundingCommitmentAdded(
      fundingCommitment.address_,
      fundingCommitment.fundingCommitmentInternal.bondTokenAmount,
      fundingCommitment.fundingCommitmentInternal.proceed,
      fundingCommitment.fundingCommitmentInternal.date
    );
  }

  /**
   * @dev Apply transfer restrictions, this OpenZeppelin dev hook gets called inside
   * all mint, burn, transfer and transferFrom functions. Restrictions applied are:
   *  - contract must be not paused (restricts everything, transfers and minting and burning).
   *  - the spender/from/to addresses must be not on deny list.
   */
  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override whenNotPaused {
    super._beforeTokenTransfer(from, to, amount);
    require(!addressScreen.isDenyListed(from), "Token sender must not be on deny list");
    require(!addressScreen.isDenyListed(to), "Token receiver must not be on deny list");
    require(!addressScreen.isDenyListed(_msgSender()), "Transaction initiator must not be on deny list");
  }

  /**
   * @dev Returns the amount plus interest
   * @param amount uint256: amount to have interest added to it
   * @param _interestRateFraction uint256: interest rate fraction to be used
   */
  function _calculateAmount(uint256 amount, uint256 _interestRateFraction) internal pure returns (uint256) {
    return (amount + amount.mul(_interestRateFraction));
  }

  /**
   * @dev Internal function to check and add or modify a funding commitment.
   * @param fundingCommitment FundingCommitmentExternal
   */
  function _checkAndSetFundingCommitment(FundingCommitmentExternal memory fundingCommitment) internal {
    require(fundingCommitment.fundingCommitmentInternal.bondTokenAmount > 0, "Bond Token Amount must be more than 0");
    require(fundingCommitment.fundingCommitmentInternal.proceed > 0, "Proceed must be more than 0");
    require(
      fundingCommitment.fundingCommitmentInternal.date < maturityDate,
      "Date must be before maturityDate"
    );
    fundingCommitments[fundingCommitment.address_] = fundingCommitment.fundingCommitmentInternal;
  }

  /**
   * @dev Internal function to remove the funding commitment of the specified user. Can emit {FundingCommitmentRemoved}.
   * @param userAddress address
   */
  function _removeFundingCommitment(address userAddress) internal {
    require(
      addressWithFundingCommitment.remove(userAddress),
      "Funding commitment does not already exist for this address"
    );
    delete fundingCommitments[userAddress];
    emit FundingCommitmentRemoved(userAddress);
  }

  /**
   * @dev Checks and sets the address screening contract. Can emit {AddressScreenContractUpdated}.
   * @param newAddress new address of the screening contract
   * @param reason the reason for the change
   */
  function _setAddressScreenContract(address newAddress, string memory reason) internal {
    require(newAddress != address(0), "Address screen address cannot be address zero");
    require(newAddress.isContract(), "Address screen is not a contract");
    require(
      newAddress != address(addressScreen),
      "New address screen contract must be different from the existing address screen contract"
    );
    addressScreen = IAddressScreen(newAddress);
    emit AddressScreenContractUpdated(newAddress, reason);
  }

  /**
   * @dev Checks and sets a maturity date. Can emit {MaturityDateUpdated}.
   * @param newDate the maturity date
   * @param reason the reason for the change
   */
  function _setMaturityDate(uint64 newDate, string memory reason) internal {
    require(newDate > block.timestamp, "maturityDate must be in the future");
    require(
      newDate != maturityDate,
      "New maturity date must be different from the existing maturity date"
    );
    maturityDate = newDate;
    emit MaturityDateUpdated(newDate, reason);
  }

  /**
   * @dev Internal function to update a funding commitment. Can emit {FundingCommitmentUpdated}.
   * @param fundingCommitment FundingCommitmentExternal
   */
  function _updateFundingCommitment(FundingCommitmentExternal calldata fundingCommitment) internal {
    require(
      addressWithFundingCommitment.contains(fundingCommitment.address_),
      "Funding commitment does not already exist for this address"
    );
    _checkAndSetFundingCommitment(fundingCommitment);
    emit FundingCommitmentUpdated(
      fundingCommitment.address_,
      fundingCommitment.fundingCommitmentInternal.bondTokenAmount,
      fundingCommitment.fundingCommitmentInternal.proceed,
      fundingCommitment.fundingCommitmentInternal.date
    );
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title IAddressScreen
 * @dev Interface that the address screening contract exposes to consumers.
 */
interface IAddressScreen {
  /**
   * @dev Return true if the address is allow listed, false otherwise.
   * @param addr address
   */
  function isAllowListed(address addr) external view returns (bool);

  /**
   * @dev Returns true if the address is deny listed, false otherwise.
   * @param addr address
   */
  function isDenyListed(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Standard is IERC20 {
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @title PreciseUnitMath
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 */
library PreciseUnitMath {
  using SafeCast for int256;

  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10 ** 18;
  int256 internal constant PRECISE_UNIT_INT = 10 ** 18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;
  // Max and min signed integer value
  int256 internal constant MAX_INT_256 = type(int256).max;
  int256 internal constant MIN_INT_256 = type(int256).min;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnitInt() internal pure returns (int256) {
    return PRECISE_UNIT_INT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxInt256() internal pure returns (int256) {
    return MAX_INT_256;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function minInt256() internal pure returns (int256) {
    return MIN_INT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / PRECISE_UNIT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
   * significand of a number with 18 decimals precision.
   */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    return (a * b) / PRECISE_UNIT_INT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b - 1) / PRECISE_UNIT + 1;
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * PRECISE_UNIT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded towards 0).
   */
  function div(int256 a, int256 b) internal pure returns (int256) {
    return (a * PRECISE_UNIT_INT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "Cant divide by 0");

    return a > 0 ? (a * PRECISE_UNIT - 1) / b + 1 : 0;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0). When `a` is 0, 0 is
   * returned. When `b` is 0, method reverts with divide-by-zero error.
   */
  function divCeil(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "Cant divide by 0");

    a = a * PRECISE_UNIT_INT;
    int256 c = a / b;

    if (a % b != 0) {
      // a ^ b == 0 case is covered by the previous if statement, hence it won't resolve to --c
      (a ^ b > 0) ? ++c : --c;
    }

    return c;
  }

  /**
   * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
   */
  function divDown(int256 a, int256 b) internal pure returns (int256) {
    require(b != 0, "Cant divide by 0");
    require(a != MIN_INT_256 || b != -1, "Invalid input");

    int256 result = a / b;
    if (a ^ b < 0 && a % b != 0) {
      result -= 1;
    }

    return result;
  }

  /**
   * @dev Multiplies value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativeMul(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a * b, PRECISE_UNIT_INT);
  }

  /**
   * @dev Divides value a by value b where rounding is towards the lesser number.
   * (positive values are rounded towards zero and negative values are rounded away from 0).
   */
  function conservativeDiv(int256 a, int256 b) internal pure returns (int256) {
    return divDown(a * PRECISE_UNIT_INT, b);
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, "Value must be positive");

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      result = previousResult * a;
    }

    return result;
  }

  /**
   * @dev Returns true if a =~ b within range, false otherwise.
   */
  function approximatelyEquals(uint256 a, uint256 b, uint256 range) internal pure returns (bool) {
    return a <= b + range && a >= b - range;
  }

  /**
   * Returns the absolute value of int256 `a` as a uint256
   */
  function abs(int256 a) internal pure returns (uint256) {
    return a >= 0 ? a.toUint256() : (a * -1).toUint256();
  }

  /**
   * Returns the negation of a
   */
  function neg(int256 a) internal pure returns (int256) {
    require(a > MIN_INT_256, "Inversion overflow");
    return -a;
  }
}