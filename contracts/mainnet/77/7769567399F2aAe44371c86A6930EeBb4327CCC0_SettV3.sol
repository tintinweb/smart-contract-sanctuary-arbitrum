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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.17;

contract UniswapV3StrategyStorage {
    
    /**
     * @param leverage Leverage used to decide how much to borrow from LendVault
     * @param minLeverage The lowest that leverage will be taken to when LendVault requests delever
     * @param tick0 Lower tick for uniswap v3 liquidity range
     * @param tick1 Upper tick for uniswap v3 liquidity range
     */
    struct Parameters {
        uint leverage;
        uint minLeverage;
        uint maxLeverage;
        int24 tick0;
        int24 tick1;
    }

    /**
     * @param ammCheckThreshold The deviation threshold allowed between pool price and oracle price
     * @param slippage Slippage used when using swapper
     * @param healthThreshold Minimum health below which liquidity position is exited
     */
    struct Thresholds {
        uint ammCheckThreshold;
        uint slippage;
        uint healthThreshold;
    }

    /**
     * @notice Important addresses related to Uniswap
     * @param want The address of the liquidity pool used for farming
     * @param stableToken The stable token from the liquidity pool
     * @param volatileToken The volatile token from the liquidity pool
     * @param positionsManager Uniswap v3 NFT positions manager
     */
    struct Addresses {
        address want;
        address stableToken;
        address volatileToken;
        address positionsManager;
    }

    Addresses public addresses;

    Thresholds public thresholds;

    Parameters public parameters;

    /// @notice Token id in uniswap v3 NFT position manager
    uint public positionId;

    /// @notice The price anchor that is set on every rebalance
    uint public priceAnchor;

    /// @notice The total amount of rewards that have been harvested since inception in terms of stable token
    uint public harvested;

    /// @notice The number of times that the strategy has been rebalanced
    uint public numRebalances;

    /// @notice The amount of the vault's deposit token that has been withdrawn from the strategy
    uint public withdrawn;

    // ---------- Previous transcation trackers ----------

    /// @notice Internal variable used to calculate the price change impact
    int public prevBalance;

    /// @notice The amount of tokens deposited from the vault until the latest transaction
    uint public prevDeposited;

    /// @notice The previous value of the debts expressed in terms of the vault's deposit token
    uint public prevDebt;

    /// @notice The harvestable amount expressed in stable token at the last transaction
    int public prevHarvestable;

    // ---------- PNLs ----------

    /// @notice The impact that swapping tokens has had on the strategy's pnl
    int public slippageImpact;

    /// @notice The change in the strategy's balance due to the change in the volatile token's price
    int public unrealizedPriceChangeImpact;

    /// @notice The unrealized price change impact that has become realized due to withdrawals
    int public realizedPriceChangeImpact;

    /// @notice Mapping from tokens to interest paid for borrowing the token
    mapping (address=>int) public interestPayments;

    /// @notice The interest payments for a token expressed in terms of the vault's deposit token
    mapping (address=>int) public interestPaymentsInDepositToken;

    int cachedBalance;
    uint prevCacheUpdateBlock;

    // Token balances at the previous transaction
    mapping (address=>uint) public prevBalances;

    // Token debts at previous transaction
    mapping (address=>uint) public prevDebts;

    // Token debts at the last repay or borrow event
    mapping (address=>uint) public prevDebtsAtRepayBorrow;

    // TVL of the strategy at the previosu transaction
    int public prevTvl;

    // Mapping from token to amount that can be harvested at previous transaction
    mapping (address=>uint) public prevHarvestables;

    /// @notice Mapping from token to list of tokens that can be used in its place when borrowing
    /// This mapping is meant for cases like in arbitrum where there are two USDC tokens
    mapping (address=>address[]) public interchangeableTokens;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import "../../interfaces/IController.sol";
import "../../interfaces/IBorrower.sol";
import "../../interfaces/IUniswapV3BaseStrategy.sol";
import "../../interfaces/IAddressProvider.sol";
import "../../interfaces/ILendVault.sol";
import "../../interfaces/IOracle.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IStrategyVault.sol";
import "../../utils/BlockNonEOAUpgradeable.sol";
import "../../utils/AccessControl.sol";
import "../../libraries/AddressArray.sol";
import "../../libraries/UintArray.sol";
import "../../interfaces/IRewards.sol";
import "../../interfaces/ISwapper.sol";

/**
 * @title SettV3
 * @notice This is the main vault contract that receives depositToken deposits, mints-burns shares in return, and allocates
 * to the underlying portfolio strategies.
 *
 *  @dev Source of Inspiration: https://github.com/iearn-finance/yearn-protocol/blob/develop/contracts/vaults/yVault.sol
 *  @dev Refer to the documentation/VAULT.MD for more information.
 */
contract SettV3 is
    ERC20Upgradeable,
    BlockNonEOAUpgradeable,
    AccessControl,
    PausableUpgradeable,
    IStrategyVault
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AddressArray for address[];
    using UintArray for uint[];

    /// @notice Underlying token address that the vault receives as a deposit
    address public depositToken;

    /// @notice Array of strategies that the vault deposits user funds into
    address[] public strategies;

    /// @notice Array representing the allocation of funds to each strategy
    uint256[] public strategyAllocation;

    /// @notice The harvest time of the last epoch harvest
    uint public previousHarvestTimeStamp;

    /// @notice Price per share at most recent epoch harvest
    uint public waterMark;

    /// @notice Performance fee charged by the protocol
    uint public performanceFee;

    /// @notice Admin fee charged by the protocol
    uint public adminFee;

    /// @notice Withdrawal fee charged by the protocol
    uint public withdrawalFee;

    /// @notice What fraction of the fee that goes to governance, the rest goes to the reserve
    uint public governanceFee;

    /// @notice Mapping from strategy to amount of token that has been deposited into it
    mapping(address => uint) public deposited;

    /// @notice Mapping from strategy to amount of tokens that have been withdrawn from it
    mapping(address => uint) public withdrawn;

    /// @notice Number of positions-investors held by the vault
    uint public numPositions;

    /// @notice Maximum number of strategies that the vault can have
    uint public constant maxStrategies = 5;

    /// @notice Maximum percentage fee that can be given to admin
    uint public constant maxFee = PRECISION;

    mapping(address => bool) internal hasPosition;

    uint internal constant secondsPerYear = 31449600;

    string internal secondName;

    event EpochHarvest(
        uint waterMark,
        uint fee,
        uint sharesMinted,
        uint256 totalSupply
    );

    event Deposit(
        address indexed user,
        uint tokens,
        uint shares,
        uint pricePerShare
    );

    event Withdraw(
        address indexed user,
        uint tokens,
        uint shares,
        uint pricePerShare
    );

    /**
     * @notice Initializes the contract
     * @dev This is an upgradable contract
     * @param _strategies Array of addresses that sets up the Liquidity Pool Strategey addresses that couples the controller-strategies to the vault
     * @param _strategyAllocation Array of integers that initializes the above mapped strategies allocations
     */
    function initialize(
        address _provider,
        address _depositToken,
        string memory name,
        string memory symbol,
        address[] memory _strategies,
        uint256[] memory _strategyAllocation
    ) public initializer {
        __AccessControl_init(_provider);
        __BlockNonEOAUpgradeable_init(_provider);
        __Pausable_init();

        // Input validaiton
        ERC20(_depositToken).name();
        for (uint i = 0; i<_strategies.length; i++) {
            IBorrower(_strategies[i]).getDebts();
        }

        // Initialize contract variables
        depositToken = _depositToken;
        __ERC20_init(name, symbol);
        waterMark = getPricePerFullShare();
        previousHarvestTimeStamp = block.timestamp;
        strategies = _strategies;
        strategyAllocation = _strategyAllocation;

        performanceFee = 2 * PRECISION/10; // Performance fee is 20%
        adminFee = 2 * PRECISION/100; // Admin fee is 2%
        withdrawalFee = PRECISION / 1000; // Withdrawal fee is 0.1%
        governanceFee = 2 * PRECISION / 100; // Governance gets 2% of all fee
        require(_strategies.length<=maxStrategies, "Too many wants");
        require(_strategyAllocation.length == _strategies.length, "E37");

        // Paused on launch
        _pause();
    }

    /// ===== View Functions =====

    /**
     * @notice Gets the current version of the vault
     */
    function version() public pure returns (string memory) {
        return "1.0";
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        if (bytes(secondName).length==0) {
            return super.name();
        }
        return secondName;
    }

    /**
     * @notice Get an array of all the strategies that the vault deposits into
     */
    function getStrategies() external view returns (address[] memory strats) {
        strats = strategies.copy();
    }

    /**
     * @notice Get an array representing the allocations of funds to each strategy
     */
    function getStrategyAllocations() external view returns (uint[] memory allocations) {
        allocations = strategyAllocation.copy();
    }

    /**
     * @notice Gets the price per share of a vault
     */
    function getPricePerFullShare() public view virtual returns (uint256) {
        if (totalSupply() == 0) {
            return 1e18;
        }
        return balance().mul(1e18).div(totalSupply());
    }

    /**
     * @notice Gets the price per share of a vault
     */
    function getPricePerFullShareOptimized() public virtual returns (uint256) {
        if (totalSupply() == 0) {
            return 1e18;
        }
        return balanceOptimized().mul(1e18).div(totalSupply());
    }

    /**
     * @notice Calculates the amount of tokens a user will get after withdrawing fully
     * @param user the address of the user to get the withdrawable
     */
    function getWithdrawable(
        address user
    ) public view returns (uint) {
        uint _shares = balanceOfWithRewards(user);
        uint fee = Math.min(_calculateFee(getPricePerFullShare())+withdrawalFee, maxFee);
        uint sharesAsFee = (_shares * fee) / PRECISION;
        _shares -= sharesAsFee;
        uint vaultBalance = balance();
        return (vaultBalance.mul(_shares)).div(Math.max(1, totalSupply()));
    }

    /**
     * @notice Return the total balance of the deposit token within the system
     * @dev Sums the balance in the Sett, the Controller, and the Strategy
     */
    function balance() public view virtual returns (uint256) {
        int256 _totalBalance = 0;
        uint256 _depositTokenBalance = IERC20(depositToken).balanceOf(
            address(this)
        );
        for (uint256 i = 0; i < strategies.length; i++) {
            _totalBalance += IBorrower(strategies[i]).balance();
        }
        return uint(_totalBalance) + _depositTokenBalance;
    }

    /**
     * @notice Return the user balance of minted ERC20 tokens + Rewards
     * @dev Sums the contract balance + staked balance
     */    
    function balanceOfWithRewards(address _user) public view returns (uint256 userBalance){
        userBalance += balanceOf(_user);
        IRewards rewards = IRewards(provider.rewardDistribution());        
        try rewards.balanceOf(address(this), _user, false, address(this)) {
            userBalance += rewards.balanceOf(address(this), _user, false, address(this));
        }catch{}                
    } 

    /**
     * @notice Return the total balance of the deposit token within the system
     * @dev Sums the balance in the Sett, the Controller, and the Strategy
     */
    function balanceOptimized() public virtual returns (uint256) {
        int256 _totalBalance = 0;
        uint256 _depositTokenBalance = IERC20(depositToken).balanceOf(
            address(this)
        );
        for (uint256 i = 0; i < strategies.length; i++) {
            _totalBalance += IBorrower(strategies[i]).balanceOptimized();
        }
        return uint(_totalBalance) + _depositTokenBalance;
    }

    /**
     * @notice Calculates the tvl, capacity and current depositable amount for the vault
     * @return depositable is the current max amount of depositToken that can be deposited into the vault
     * @return tvl is the total funds in possesion of a vault's strategies, including deposited
     * tokens and borrowed tokens
     * @return capacity is the highest tvl that the vault can achieve by depositing into strategies
     * and borrowing from the LendVault
     */
    function vaultCapacity() external view returns (uint depositable, uint tvl, uint capacity) {
        address[][] memory borrowableTokens = new address[][](strategies.length);
        uint[][] memory temp = new uint[][](strategies.length);
        uint totalAllocation;
        uint leverageSum;
        for (uint i = 0; i<strategies.length; i++) {
            (address[] memory strategyTokens, uint[] memory amounts) = ILendVault(provider.lendVault()).getBorrowerTokens(strategies[i]);
            borrowableTokens[i] = strategyTokens;
            temp[i] = amounts;
            (uint leverage,,,,) = IUniswapV3BaseStrategy(strategies[i]).parameters();
            leverageSum+=strategyAllocation[i] * leverage;
            totalAllocation+=strategyAllocation[i];
            tvl+=IBorrower(strategies[i]).tvl();
        }
        (address[] memory tokens,) = _combine(borrowableTokens, temp);
        uint averageLeverage = leverageSum / totalAllocation;

        uint totalBorrowable;
        for (uint i = 0; i<tokens.length; i++) {
            uint borrowable = _getBorrowable(tokens[i]);
            totalBorrowable+=IOracle(provider.oracle()).getValueInTermsOf(tokens[i], borrowable, depositToken);
        }
        uint approximateDepositable = (totalBorrowable * PRECISION * PRECISION / averageLeverage) / PRECISION;

        depositable = uint(int(approximateDepositable) + _correctDepositable(approximateDepositable, approximateDepositable));

        (address[] memory borrowTokens, uint[] memory borrowAmounts) = _simulateDeposits(depositable);

        uint totalBorrowed;
        for (uint i = 0; i<borrowTokens.length; i++) {
            totalBorrowed+=IOracle(provider.oracle()).getValueInTermsOf(borrowTokens[i], borrowAmounts[i], depositToken);
        }

        capacity = tvl + depositable + totalBorrowed;
    }


    /// ===== Public Actions =====

    /**
     * @notice Deposit a token other than the deposit token of the vault
     * The token will be swapped with the vault's deposit token using the provided slippage value by the swapper
     * @param _token The token being used to deposit instead of the deposit token
     * @param _amount Amount of token to use to make the deposit
     * @param _slippage the slippage value used by the swapper
     * @dev slippage represents how much of a loss can be accepted
     * Max slippage is PRECISION, in which case all funds can be lost
     * Min slippage is 0, representing no loss of funds
     */
    function depositOtherToken(address _token, uint256 _amount, uint256 _slippage) public payable whenNotPaused onlyEOA {
        require(msg.value==0 || _amount==0, "E39");
        uint256 startBalance = balanceOptimized();
        if (msg.value>0) {
            require(_token==provider.networkToken(), "E40");
            _amount = msg.value;
            IWETH(payable(provider.networkToken())).deposit{value: _amount}();
        } else {
            IERC20(_token).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        if (_token!=depositToken) {
            ISwapper swapper = ISwapper(provider.swapper());
            _approveSpender(address(swapper), _token, _amount);
            uint amountOut = swapper.swapExactTokensForTokens(_token, _amount, depositToken, _slippage);
            _deposit(amountOut, startBalance);
        } else {
            _deposit(_amount, startBalance);
        }
    }

    /**
     * @notice Deposit assets into the Sett, and return corresponding shares to the user
     * @param _amount the amount of underlying currency to deposit
     */
    function deposit(uint256 _amount) public payable whenNotPaused onlyEOA{
        uint256 startBalance = balanceOptimized();
        require(msg.value==0 || _amount==0, "E39");
        if (msg.value>0) {
            require(depositToken==provider.networkToken(), "E40");
            _amount = msg.value;
            IWETH(payable(provider.networkToken())).deposit{value: _amount}();
        } else {
            IERC20(depositToken).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        _deposit(_amount, startBalance);
    }

    /**
     * @notice Convenience function: Deposit entire balance of asset into the Sett, and return corresponding shares to the user
     */
    function depositAll() external whenNotPaused onlyEOA{
        uint256 startBalance = balanceOptimized();
        uint256 depositAmount = IERC20(depositToken).balanceOf(msg.sender);
        IERC20(depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            depositAmount
        );
        _deposit(depositAmount, startBalance);
    }

    /**
     * @notice Withdraws funds from the Sett-Vault and burn shares of the user
     * @dev returns the corresponding amount of the share value in underlying currency to the user.
     * @dev Fee in the form of shares will be given to governance and in the form of tokens to the reserve
     * @param _shares the amount of shares to burn for underlying currency
     */
    function withdraw(uint256 _shares) public whenNotPaused onlyEOA{
        _rewardWithdraw(_shares); 
        _withdraw(_shares);
    }

    /// @notice Convenience function: Withdraw all shares of the sender
    function withdrawAll() external whenNotPaused onlyEOA{
        _rewardWithdraw(balanceOfWithRewards(msg.sender));             
        _withdraw(balanceOf(msg.sender));
    }

    /// ===== Permissioned Actions: Governance =====

    /**
     * @notice Sets the fees to be charged by the protocol
     * @dev Only governance can call this function
     * @param performance The performance fee percentage to be charged by the vault
     * The performance fee is only applied if the vault has had a positive ROI since the last epoch harvest
     * @param admin The administration fee to be charged by the vault
     * @param withdrawal This is a low penalty fee for withdrawing, it is supposed to disincentivize withdrawal attacks.
     */
    function setFees(uint performance, uint admin, uint withdrawal) external restrictAccess(GOVERNOR) {
        require(performance<PRECISION, "Performance fee too high");
        require(admin<PRECISION, "Admin fee too high");
        require(withdrawal<PRECISION, "Withdrawal fee too high");
        performanceFee = performance;
        adminFee = admin;
        withdrawalFee = withdrawal;
    }

    /**
     * @notice Sets the governance fee
     * The governance fee represents what percentage of the fee goes to the governance address
     */
    function setGovernanceFee(uint _governanceFee) external restrictAccess(GOVERNOR) {
        require(_governanceFee<PRECISION, "Governance fee too high");
        governanceFee = _governanceFee;
    }

    /**
     * @notice This function sets the funds allocation in the strategies
     * @dev This is a permissioned function, the allocation can only be set by the governance.
     * @dev If a new allocation is set, funds are withdrawn from the strategies and redeposited based on the new allocation.
     * @dev The allocation set here will also determine how the deposits and withdrawals are made proportionally to the whole portfolio composition.
     * @param _strategies The strategies that the vault will deposit into
     * @param _strategiesAllocation The allocation of deposits into each strategy
     */
    function setStrategiesAndAllocations(
        address[] memory _strategies,
        uint256[] memory _strategiesAllocation
    ) public restrictAccess(GOVERNOR) {
        require(
            _strategiesAllocation.length == _strategies.length,
            "E37"
        );

        //TRIGGER WITHDRAW AND THEN NEW EARN
        for (uint256 i = 0; i < strategies.length; i++) {
            if (IBorrower(strategies[i]).balance()>0) {
                IController(provider.controller()).withdrawAll(strategies[i]);
            }
        }
        
        //REBALANCE ALLOCATIONS
        strategyAllocation = _strategiesAllocation;
        strategies = _strategies;
        earn();
    }

    /**
     * @notice Adds the deposited amount for a deprecated strategy to the new version and triggers
     * contract state migration via Controller
     * @dev withdrawn is not included in this function since the strategy now tracks withdrawn amounts
     */
    function migrateStrategy(address _oldAddress, address _newAddress) external restrictAccess(GOVERNOR) {
        deposited[_newAddress]+=deposited[_oldAddress];
        IController(provider.controller()).migrateStrategy(_oldAddress, _newAddress);
    }

    /**
     * @notice Reset strategy pnl to 0
     */
    function resetStrategyPnl(address _strategy) external restrictAccess(GOVERNOR) {
        deposited[_strategy] = uint(IBorrower(_strategy).balance());
        IController(provider.controller()).resetStrategyPnl(_strategy);
    }

    /**
     * @notice Change the name of the contract
     */
    function rename(string memory newName) external restrictAccess(GOVERNOR) {
        secondName = newName;
    }

    /// ===== Permissioned Functions: Trusted Actors =====

    /**
     * @notice This function harvests the fees from all strategies
     * @dev Can only be called by governance or the keeper
     * @dev This function is usually called by the keeper at the end of an epoch every 7 days.
     * @dev It mints shares to the governance address and sends a few tokens to the reserve.
     * The percentage given to goveranance and reserve are based on governanceFee
     */
    function epochHarvest() public whenNotPaused restrictAccess(GOVERNOR | KEEPER) {
        _harvest();
        _earn(IERC20(depositToken).balanceOf(address(this)));
        uint fee = Math.min(_calculateFee(getPricePerFullShareOptimized()), maxFee);
        previousHarvestTimeStamp = block.timestamp;
        uint sharesToMint = (totalSupply() * fee) / PRECISION;
        _mintFeeShares(sharesToMint);
        waterMark = getPricePerFullShare();
        emit EpochHarvest(
            waterMark,
            fee,
            sharesToMint,
            totalSupply()
        );
    }

    /**
     * @notice Transfer the underlying available tokens to be used in the strategies
     * @dev The controller will deposit into the Strategy for yield-generating activities
     */
    function earn() public whenNotPaused restrictAccess(GOVERNOR) {
        _earn(IERC20(depositToken).balanceOf(address(this)));
    }

    /**
     * @notice Transfer an amount of the specified token from the vault to the sender.
     * @dev This is purely a safeguard.
     * @param _token The address of the token that is stuck and should be transfered
     * @param _amount The amount that should be sent to the caller
     */
    function inCaseTokensGetStuck(address _token, uint256 _amount) public restrictAccess(GOVERNOR) {
        require(_amount>0, "E21");
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// ===== Internal Implementations =====

    /**
     * @notice Transfer the specified amount of depositToken to the strategies based on allocations
     */
    function _earn(uint amount) internal {
        uint256 totalAllocation = strategyAllocation.sum();
        for (uint256 i = 0; i < strategies.length; i++) {
            if (strategyAllocation[i] > 0) {
                uint256 _allocation = (strategyAllocation[i] * amount).div(totalAllocation);
                IERC20(depositToken).safeTransfer(
                    strategies[i],
                    _allocation
                );
                deposited[strategies[i]]+=_allocation;
                IController(provider.controller()).earn(strategies[i]);
            }
        }
    }

    /**
     * @notice Harvests all strategies under the vault
     */
    function _harvest() internal virtual {
        for (uint i = 0; i < strategies.length; i++) {
            IController(provider.controller()).harvest(strategies[i]);
        }
    }

    /**
     * @notice Deposit assets into the Sett, and return corresponding shares to the user
     * @param _depositAmount the amount of underlying currency to deposit
     */
    function _deposit(uint256 _depositAmount, uint256 _pool) internal virtual {
        _earn(_depositAmount);
        uint256 shares = 0;
        if (totalSupply() == 0) {
            shares = _depositAmount;
        } else {
            shares = (_depositAmount.mul(totalSupply())).div(_pool);
        }
        _mint(msg.sender, shares);
        if (!hasPosition[msg.sender]) {
            hasPosition[msg.sender] = true;
            numPositions += 1;
        }
                
        IRewards rewards = IRewards(provider.rewardDistribution());
        (, bool poolExists) = rewards.getPoolId(address(this), false, address(this));
        if(poolExists){
            approve(provider.rewardDistribution(), shares);                     
            try rewards.deposit(address(this), shares, msg.sender, false, address(this)){} catch {}
        }
        
        emit Deposit(
            msg.sender,
            _depositAmount,
            shares,
            getPricePerFullShare()
        );
    }

    /**
     * @notice Withdraws funds from the Sett-Vault and burn shares of the user
     * @dev returns the corresponding amount of the share value in underlying currency to the user.
     * @param _shares the amount of shares to exchange and burn for underlying currency
     */
    function _withdraw(uint256 _shares) internal virtual {
        if (_shares == balanceOf(msg.sender)) {
            hasPosition[msg.sender] = false;
            // numPositions -= 1;
        }
        uint fee = msg.sender!=provider.governance()?Math.min(_calculateFee(getPricePerFullShareOptimized())+withdrawalFee, maxFee):0;
        uint sharesAsFee = (_shares * fee) / PRECISION;
        uint governanceShares = sharesAsFee * governanceFee / PRECISION;
        uint reserveShares = sharesAsFee - governanceShares;
        uint userShares = _shares - sharesAsFee;

        uint _shares_calc = userShares + reserveShares;
        uint tokensWithdrawn = _withdrawFromStrategies(_shares_calc);
        _burn(msg.sender, _shares);
        _mint(provider.governance(), governanceShares);

        IERC20(depositToken).safeTransfer(msg.sender, tokensWithdrawn * userShares / Math.max(1, _shares_calc));
        IERC20(depositToken).safeTransfer(provider.reserve(), tokensWithdrawn * reserveShares / Math.max(1, _shares_calc));
        uint pps = getPricePerFullShareOptimized();
        emit Withdraw(
            msg.sender,
            tokensWithdrawn * userShares / Math.max(1, _shares_calc),
            _shares,
            pps
        );
    }

    /// ===== Pause Vault Actions =====

    /**
     * @notice Can pause the vault
     * @dev Only authorized actors can trigger this call
     */
    function pause() external restrictAccess(GOVERNOR)  {
        _pause();
    }

    /**
     * @notice Can un-pause the vault
     * @dev Only authorized actors can trigger this call
     */
    function unpause() external restrictAccess(GOVERNOR) {
        _unpause();
    }

    /// ===== Internal helper functions =====

    /**
     * @notice Calculates the total fee percentage based on watermark and current price per share
     * @return fee The fee that can be charged to the vault for its performance. Admin + Performance Fee
     */
    function _calculateFee(uint pricePerShare) internal view returns (uint fee) {
        if (pricePerShare > waterMark) {
            uint priceIncrease = pricePerShare - waterMark;
            fee =
                (priceIncrease * performanceFee) /
                (waterMark > 0 ? waterMark : 10 ** 18);
        }

        uint timeSinceEpoch = block.timestamp - previousHarvestTimeStamp;
        uint adminFeeNow = (adminFee * timeSinceEpoch) / (secondsPerYear);
        fee += adminFeeNow;
    }

    /**
     * @notice Mints shares for the governance and sends deposit token to reserve
     * @dev The reserve is not supposed to hold strategy vault tokens, hence they
     * are not minted here, but instead, tokens are directly sent to the reserve
     * corresponding to how many shares would have been minted
     */
    function _mintFeeShares(uint shares) internal {
        uint governanceShares = shares * governanceFee / PRECISION;
        uint reserveShares = shares - governanceShares;
        uint256 reserveTokens = _withdrawFromStrategies(reserveShares);
        _mint(provider.governance(), governanceShares);
        IERC20(depositToken).safeTransfer(provider.reserve(), reserveTokens);
    }

    /**
     * @notice Withdraws a desired amount of depositToken from the strategies
     * @param shares The amount of tokens that are needed to be withdrawn
     * @return tokensWithdrawn The amount of depositToken that was retrieved from the strategies
     */
    function _withdrawFromStrategies(uint shares) internal returns (uint tokensWithdrawn) {
        uint balanceStart = IERC20(depositToken).balanceOf(address(this));
        tokensWithdrawn = balanceStart * shares / totalSupply();
        for (uint256 i = 0; i < strategies.length; i++) {
            IController(provider.controller()).withdraw(strategies[i], shares * PRECISION / totalSupply());
        }
        tokensWithdrawn+=IERC20(depositToken).balanceOf(address(this)) - balanceStart;
    }

    /**
     * @notice Given a two dimensional array of tokens and amounts, gives a one
     * dimensional list of unique tokens and the combined amounts for the tokens
     */
    function _combine(
        address[][] memory strategyTokens,
        uint[][] memory strategyBorrowAmounts
    ) internal pure returns (address[] memory tokens, uint[] memory amounts) {
        uint maxTokens;
        for (uint i = 0; i<strategyTokens.length; i++) {
            maxTokens+=strategyTokens[i].length;
        }
        address[] memory tempTokens = new address[](maxTokens);
        uint[] memory tempAmounts = new uint[](maxTokens);
        uint tempTokensIndex;
        for (uint i = 0; i<strategyTokens.length; i++) {
            for (uint j = 0; j<strategyTokens[i].length; j++) {
                uint tokenIndex = tempTokens.findFirst(strategyTokens[i][j]);
                if (tokenIndex==tempTokens.length) {
                    tempTokens[tempTokensIndex] = strategyTokens[i][j];
                    tempAmounts[tempTokensIndex] = strategyBorrowAmounts[i][j];
                    tempTokensIndex+=1;
                } else {
                    tempAmounts[tokenIndex]+=strategyBorrowAmounts[i][j];
                }
            }
        }
        tokens = new address[](tempTokensIndex);
        amounts = new uint[](tempTokensIndex);
        for (uint i = 0; i<tempTokensIndex; i++) {
            tokens[i] = tempTokens[i];
            amounts[i] = tempAmounts[i];
        }
    }
    
    /**
     * @notice Simulates a deposit of a given amount to the vault and returns the tokens that will be borrowed
     * by the underlying strategies
     */
    function _simulateDeposits(uint amount) internal view returns (address[] memory tokens, uint[] memory amounts) {
        ILendVault lendVault = ILendVault(provider.lendVault());
        address[][] memory strategyTokens = new address[][](strategies.length);
        uint[][] memory strategyBorrowAmounts = new uint[][](strategies.length);
        
        uint256 totalAllocation = strategyAllocation.sum();
        address[] memory lendVaultTokens = lendVault.getSupportedTokens();
        uint[] memory availableLendVaultTokens = new uint[](lendVaultTokens.length);
        for (uint i = 0; i<lendVaultTokens.length; i++) {
            availableLendVaultTokens[i] = _getBorrowable(lendVaultTokens[i]);
        }
        for (uint i = 0; i<strategyAllocation.length; i++) {
            (strategyTokens[i], strategyBorrowAmounts[i]) = IBorrower(strategies[i]).getBorrowForDeposit(
                strategyAllocation[i] * amount / totalAllocation,
                lendVaultTokens,
                availableLendVaultTokens
            );
            for (uint j = 0; j<lendVaultTokens.length; j++) {
                uint idx = strategyTokens[i].findFirst(lendVaultTokens[j]);
                if (idx<strategyBorrowAmounts[i].length) {
                    availableLendVaultTokens[j]-=Math.min(strategyBorrowAmounts[i][idx], availableLendVaultTokens[j]);
                }
            }
        }

        (tokens, amounts) = _combine(strategyTokens, strategyBorrowAmounts);
    }

    /**
     * @notice Simulates vault deposit with given amount and returns a positive adjustment if more
     * can be deposited and negative adjustment if the deposit amount is too high
     */
    function _correctDepositable(uint amount, uint prevAdjustment) internal view returns (int adjustment) {
        IOracle oracle = IOracle(provider.oracle());
        (address[] memory borrowTokens, uint[] memory borrowAmounts) = _simulateDeposits(amount);
        int[] memory adjustments = new int[](borrowTokens.length);
        bool canBorrowMore = true;

        for (uint i = 0; i<borrowTokens.length; i++) {
            uint borrowable = _getBorrowable(borrowTokens[i]);
            if (borrowAmounts[i]>borrowable) {
                canBorrowMore = false;
                uint diff = borrowAmounts[i] - borrowable;
                uint inTermsOfDepositToken = oracle.getValueInTermsOf(borrowTokens[i], diff, depositToken);
                adjustments[i] = -int(inTermsOfDepositToken);
            } else {
                uint diff = borrowable - borrowAmounts[i];
                uint inTermsOfDepositToken = oracle.getValueInTermsOf(borrowTokens[i], diff, depositToken);
                adjustments[i] = int(inTermsOfDepositToken);
            }
        }

        for (uint i = 0; i<borrowTokens.length; i++) {
            if ((canBorrowMore && adjustments[i]>adjustment) || (!canBorrowMore && adjustments[i]<adjustment)) {
                adjustment = adjustments[i];
            }
        }

        adjustment = canBorrowMore?int(prevAdjustment/2):-int(prevAdjustment/2);
        uint adjustmentUsd = oracle.getValue(depositToken, adjustment>0?uint(adjustment):uint(-adjustment));

        if (adjustment==0 || adjustmentUsd<10**18) {
            adjustment = 0;
        } else {
            adjustment+=_correctDepositable(uint(int(amount) + adjustment), adjustment>0?uint(adjustment):uint(-adjustment));
        }
    }

    /**
     * @notice Calculates the amount of a given token that can currently be borrowed from the lend vault
     */
    function _getBorrowable(address token) internal view returns (uint borrowable) {
        ILendVault lendVault = ILendVault(provider.lendVault());
        uint totalAssets = lendVault.totalAssets(token);
        uint utilizationCap = lendVault.maxUtilization();
        uint usableTokens = utilizationCap * totalAssets / PRECISION;
        uint usedTokens = lendVault.getTotalDebt(token);
        borrowable = usableTokens>usedTokens?usableTokens - usedTokens:0;
    }

    function _rewardWithdraw(uint _shares) internal {
        IRewards rewards = IRewards(provider.rewardDistribution());  
        (, bool poolExists) = rewards.getPoolId(address(this), false, address(this));
        if(poolExists){
            uint256 balanceInRewards = rewards.balanceOf(address(this), msg.sender, false, address(this));
            uint256 balanceInContract = balanceOf(msg.sender);        
            uint256 balanceToWithdrawFromMasterChef = _shares - balanceInContract;
            if(balanceInRewards > 0 && balanceToWithdrawFromMasterChef > 0){
                try rewards.withdraw(address(this), balanceToWithdrawFromMasterChef, msg.sender, false, address(this)){} catch {}
            }
        }
    }

    /**
     * @notice Set approval to max for spender if approval isn't high enough
     */
    function _approveSpender(address spender, address token, uint amount) internal {
        uint allowance = IERC20(token).allowance(address(this), spender);
        if(allowance<amount) {
            IERC20(token).safeIncreaseAllowance(spender, 2**256-1-allowance);
        }
    }

    receive() external payable {
        IWETH(payable(provider.networkToken())).deposit{value: address(this).balance}();
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
    function uniswapV3StrategyMigrator() external view returns (address);
    function uniswapV3StrategyLogic() external view returns (address);
    function borrowerBalanceCalculator() external view returns (address);
    function keeper() external view returns (address);
    function governance() external view returns (address);
    function guardian() external view returns (address);
    function controller() external view returns (address);
    function vaults(uint index) external view returns (address);
    function getVaults() external view returns (address[] memory);
    function rewardDistribution() external view returns (address);
    function rewardToken() external view returns (address);

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
    function setUniswapV3StrategyMigrator(address _migrator) external;
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
     * @notice Get the amount of tokens that would be borrowed for a given deposit amount and lend vault reserves
     */
    function getBorrowForDeposit(uint amount, address[] memory lendTokens, uint[] memory availableLendTokens) external view returns (address[] memory borrowTokens, uint[] memory borrowAmounts);

    /**
     * @notice Copy the old contract state
     */
    function migrate(address oldStrategyAddress) external;

    /**
     * @notice Use migrator contract to reset pnl trackers
     */
    function resetPnlData() external;

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
    function migrateStrategy(address _oldAddress, address _newAddress) external;
    function resetStrategyPnl(address _strategy) external;
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

struct IRMDataMultiSlope {
    bool initialized;
    uint[] utilizationRates;
    uint baseBorrowRate;
    uint[] slopes;
    uint lendingPerformanceFee;
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
    function initializeToken(address token, IRMDataMultiSlope memory data) external;

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
     * @notice Get the balance from contract or reward contract staked
     * @param _user the user to consult
     * @param _token the balance of the token to consult
     * @return userBalance The balance of the user     
     */    
    function balanceOfWithRewards(address _user, address _token) external view returns (uint256 userBalance);    

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
     * @notice Calculates and returns the supply and borrow interest rates calculated at the last transaction
     * @dev supplyInterestRate = utilizationRate * borrowInterestRate * (PRECISION - lendingPerformanceFee)
     */
    function getInterestRates(address token) external view returns (uint supplyInterestRate, uint borrowInterestRate);

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

import "./IRewardsStorage.sol";

/**
* @param stakingToken The LP Token to be staked
* @param rewardToken The reward token that is given by the Masterchef
* @param allocationPoints The allocation point for that particular pool (amount of rewards of the pool)
* @param lastRewardBlock The last block that distributes rewards.
* @param accRewardPerShare The accumulated rewards per share
*/
struct Pool {
    address stakingToken;
    address rewardToken;
    uint256 allocationPoints;
    uint256 lastRewardBlock;
    uint256 accRewardPerShare;
    bool isLending;
    address lendingToken;
}


/// @notice Info of each MCV2 user.
/// `amount` LP token amount the user has provided.
/// `rewardPaid` The amount of RUMI paid to the user.
/// `pendingRewards` The amount of RUMI pending to be paid after withdraw
    struct UserInfo {
        uint256 amount;
        uint256 rewardPaid;
        uint256 pendingRewards;
        uint256 rewardDebt;
    }

interface IRewards is IRewardsStorage {
    
    /**
     * @notice Event emitted on a user or vault depositing tokens
     * @param user User that deposits into the vault+masterchef
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens staked     
     */
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice Event emitted on a user or vault withdrawing tokens
     * @param user User withdrawing
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens staked to withdraw            
     */
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    /**
     * @notice Event emitted on an emergency withdraw scenario
     * @param user User withdrawing
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens staked to withdraw            
     */
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    /**
     * @notice Event emitted on a user  harvesting of tokens
     * @param user User that deposits into the vault+masterchef
     * @param pid Pool Id of the deposit
     * @param amount Number of tokens harvested     
     */
    event Harvest(address indexed user, uint256 indexed pid, uint256 amount);    
    

    /**
     * @notice It sets caller whitelist, allowing vaults to call the Masterchef for autostaking
     * @param _callerToWhitelist address of caller to whitelist
     * @param _setOrUnset to set or unset whitelisted user
     */
    function setCallerWhitelist(address _callerToWhitelist, bool _setOrUnset) external;

    /**
     * @notice Change the speed of reward distributions
     * @param _rewardPerBlock the amount of rewards distributed per block
     */
    function changeRewardsPerBlock(uint256 _rewardPerBlock) external;    

    /**
     * @notice Sets the parameters of activation of caller whitelisting and enabling withdraws
     * @param _callerWhitelistActive Parameter to set or unset the caller whitelist
     * @param _withdrawEnabled It activates or deactivates withdrawals from users
     */
    function setParameters(bool _callerWhitelistActive, bool _withdrawEnabled) external;

    /**
     * @notice Returns the length of the pools
     * @return Number of pools
     */
    function poolLength() external view returns (uint256);

    /**
     * @notice Returns the pool id of a pool with address
     * @param _poolAddress address of the pool id to get
     * @param _isLending if the address to search is a lending pool
     * @param _lendingToken the lending token to search for
     * @return poolId Id of the pool
     * @return exists if the pool exists
     */
    function getPoolId(address _poolAddress, bool _isLending, address _lendingToken) external view returns (uint256 poolId, bool exists);

    /**
     * @notice Returns the data of a particular pool
     * @param _poolAddress address of the pool id to get
     * @param _isLending if the address to search is a lending pool
     * @param _lendingToken the lending token to search for
     * @return pool pool data
     */
    function getPoolData(address _poolAddress, bool _isLending, address _lendingToken) external view returns (Pool memory pool);
          
            
    /**
     * @notice It adds a Pool to the Masterchef array of pools
     * @param _stakingToken The Address Strategy or Vault token to be staked
     * @param _rewardToken The reward token to be distributed normally RUMI.
     * @param _allocationPoints The total tokens (allocation points) that the pool will be entitled to.
     * @param _isLending Is it a lending vault token
     * @param _lendingToken the lending token address
     */
    function addPool(address _stakingToken, address _rewardToken, uint256 _allocationPoints, bool _isLending, address _lendingToken) external;

    /**
     * @notice It sets a Poolwith new parameters
     * @param _pid The pool Id
     * @param _allocationPoints The reward token to be distributed normally RUMI.     
     */
    function setPool(uint256 _pid, uint256 _allocationPoints) external;    

    /**
     * @notice It removes pools, it requires the accRewardPerShare (pool not initiated)
     * @param _pid The pool Id     
     */
    function removePool(uint256 _pid) external;     

    /**
     * @notice Sets the new Endblock to finish reward emissions
     * @param _endBlock The ending block     
     */
    function setEndblock(uint256 _endBlock) external;     

    /**
     * @notice Sets the new Startblock to start reward emissions
     * @param _startBlock The ending block     
     */
    function setStartBlock(uint256 _startBlock) external;     

    /**
     * @notice Gets the blocks data
     * @return blockNumber current block number
     * @return _startBlock the block when the rewards started
     * @return blocksElapsed the amount of blocks elapsed since inception
     */
    function getBlocks() external view returns (uint256 blockNumber, uint256 _startBlock, uint256 blocksElapsed);        
    
    /**
     * @notice Gets the pending rewards to be distributed to a user
     * @param _pid Pool id to consult
     * @param _user The address of the user that the function will check for pending rewards
     * @return rewards Returns the amount of rewards
     */
    function getPendingReward(uint256 _pid, address _user) external view returns (uint256 rewards);

    /**
     * @notice Gets the staked balance
     * @param _poolAddress Pool address to check
     * @param _user The address of the user that the function will check for pending rewards
     * @param _isLending is this a lending pool
     * @param _lendingToken the lending token to consult
     * @return stakedBalance Returns the amount of staked tokens
     */
    function balanceOf(address _poolAddress, address _user, bool _isLending, address _lendingToken) external view returns (uint256 stakedBalance);

    /**
     * @notice Gets the staked balance
     * @param _poolAddress Pool address to check
     * @param _user The address of the user that the function will check for pending rewards
     * @param _isLending is this a lending pool
     * @param _lendingToken the lending token to consult
     * @return harvestBalance Returns the amount of pending rewards to be harvested
     */
    function getPendingHarvestableRewards(address _poolAddress, address _user, bool _isLending, address _lendingToken) external view returns (int256 harvestBalance);
    
    /**
     * @notice Deposit into the masterchef, done either by pool or user
     * @param _pid Pool ID to deposit to
     * @param _amount amount to deposit
     * @param _depositor the depositor (user or vault)
     */
    function deposit(uint256 _pid, uint256 _amount, address _depositor) external;

    /**
     * @notice Deposit into the masterchef, done either by pool or user
     * @param _poolAddress Pool address to deposit to
     * @param _amount amount to deposit
     * @param _depositor the depositor (user or vault)
     * @param _isLending is the deposit for a lending token
     * @param _lendingToken if it is lending token what is the address
     */
    function deposit(address _poolAddress, uint256 _amount, address _depositor, bool _isLending, address _lendingToken) external;
    
    /**
     * @notice Withdraw from the masterchef, done either by the pool (unstaking)
     * @param _poolAddress Pool address to withdraw to
     * @param _amount amount to deposit
     * @param _depositor the depositor (user or vault)
     * @param _isLending is the deposit for a lending token
     * @param _lendingToken if it is lending token what is the address
     */
    function withdraw(address _poolAddress, uint256 _amount, address _depositor, bool _isLending, address _lendingToken) external;

    /**
     * @notice Harvest from the masterchef, done by user
     * @param _poolAddress Pool address to withdraw to          
     * @param _isLending is the deposit for a lending token
     * @param _lendingToken if it is lending token what is the address
     */
    function harvest(address _poolAddress, bool _isLending, address _lendingToken) external;


    /**
     * @notice Withdraw everything from the Maserchef
     * @param _pid Pool ID to deposit to       
     */
    function emergencyWithdraw(uint256 _pid) external;    

    /**
     * @notice Withdraw leftover tokens from Masterchef
     * @param _amount amount of tokens to withdraw
     * @param _rewardToken reward token address
     */
    function withdrawAllLeftoverRewards(uint256 _amount, address _rewardToken) external;    

    /**
     * @notice Update reward variables for all pools. Be careful of gas spending!
     * @param pids Pool IDs of all to be updated. Make sure to update all active pools.
     */
    function massUpdatePools(uint256[] calldata pids) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IRewardsStorage {
   
    function rewardPerBlock() external view returns (uint256);
    function totalAllocationPoints(address rewardAddress) external view returns (uint256);
    function startBlock() external view returns (uint256);
    function endBlock() external view returns (uint256);
    function pools(uint position) external view returns (address, address, uint256, uint256, uint256, bool, address);
    function userInfo(uint poolId, address userAddress) external view returns (uint256,uint256, uint256, uint256);    
    function userAccumulatedReward(uint poolId, address userAddress) external view returns (uint256);
        
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
    function depositOtherToken(address token, uint256 _amount, uint256 _slippage) external payable;
    function deposit(uint256 _amount) external payable;
    // function depositAll() external;
    function withdraw(uint256 _shares) external;
    function withdrawAll() external;

    // Governance Actions
    function setFees(uint performance, uint admin, uint withdrawal) external;
    function setGovernanceFee(uint _governanceFee) external;
    function setStrategiesAndAllocations(address[] memory _strategies, uint256[] memory _strategiesAllocation) external;
    function migrateStrategy(address _oldAddress, address _newAddress) external;
    function resetStrategyPnl(address _strategy) external;

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
    function balanceOfWithRewards(address _user) external view returns (uint256 userBalance);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IBorrower.sol";
import "./IUniswapV3StrategyData.sol";
import "./IUniswapV3Storage.sol";
import "../Farming/UniswapV3StrategyStorage.sol";

interface IUniswapV3BaseStrategy is IBorrower, IUniswapV3Storage {
    function updateCache() external;
    function balanceOptimizedWithoutSlippage() external returns (int);
    function getAddresses() external view returns (address want, address stableToken, address volatileToken, address positionsManager);
    function getHarvestable() external view returns (uint harvestable);
    function getStableDebtFraction() external view returns (uint ratio);
    function getPnl() external view returns (IUniswapV3StrategyData.PNLData memory data);
    function getDepositToken() external view returns (address depositToken);
    function heartBeat()
        external
        view
        returns (
            bool ammCheck,
            int256 health,
            int256 equity,
            uint256 currentPrice
        );
    function setLeverageAndTicks(
        uint _leverage,
        int24 _multiplier0,
        int24 _multiplier1
    ) external;
    function setMinLeverage(uint _minLeverage) external;
    function setMaxLeverage(uint _maxLeverage) external;
    function setThresholds(UniswapV3StrategyStorage.Thresholds memory _thresholds) external;

    function calculateBorrowAmounts() external view returns (address[] memory tokens, int[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IUniswapV3Storage {
    function PRECISION() external view returns (uint);
    function provider() external view returns (address);
    function addresses() external view returns (address want, address stableToken, address volatileToken, address positionsManager);
    function thresholds() external view returns (uint ammCheckThreshold, uint slippage, uint healthThreshold);
    function parameters() external view returns (uint leverage, uint minLeverage, uint maxLeverage, int24 tick0, int24 tick1);
    function positionId() external view returns (uint);
    function priceAnchor() external view returns (uint);
    function harvested() external view returns (uint);
    function numRebalances() external view returns (uint);
    function withdrawn() external view returns (uint);
    function cache() external view returns (address[] memory, uint[] memory, address[] memory, uint[] memory, uint);
    function prevBalance() external view returns (int);
    function prevDeposited() external view returns (uint);
    function prevDebt() external view returns (uint);
    function prevHarvestable() external view returns (int);
    function slippageImpact() external view returns (int);
    function unrealizedPriceChangeImpact() external view returns (int);
    function realizedPriceChangeImpact() external view returns (int);
    function interestPayments(address token) external view returns (int);
    function interestPaymentsInDepositToken(address token) external view returns (int);
    function prevBalances(address token) external view returns (uint);
    function prevDebtsAtRepayBorrow(address token) external view returns (uint);
    function prevDebts(address token) external view returns (uint);
    function prevTvl() external view returns (int);
    function prevHarvestables(address token) external view returns (uint);
    function interchangeableTokens(address token, uint index) external view returns (address);
}

// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.17;

interface IUniswapV3StrategyData {

    struct PNLData {
        int pnl;
        int rewardProfit;
        int slippageLoss;
        address[] borrowedTokens;
        int[] interestPayments;
        int[] interestPaymentsInDepositToken;
        int unrealizedPriceImpact;
        int realizedPriceImpact;
    }

    function balanceInTermsOf(address token, address strategyAddress) external view returns (int balance);

    function getTVL(address strategyAddress) external view returns (uint tvl);
    
    function getPoolRatios(address strategyAddress) external view returns (uint stableRatio, uint volatileRatio, uint volatileRatioInStablePrice);

    function getAmounts(address strategyAddress) external view returns (address[] memory tokens, uint[] memory amounts);
    
    function getDebts(address strategyAddress) external view returns (address[] memory tokens, uint[] memory amounts);
    
    function getHarvestable(address strategyAddress) external view returns (uint harvestable);

    function getFees(address strategyAddress) external view returns (uint stableFee, uint volatileFee);
    
    function getPnl(address strategyAddress) external view returns (PNLData memory pnlData);

    function getStableDebtFraction(address strategyAddress) external view returns (uint ratio);

    function calculateUnrealizedPriceImpact(address strategyAddress) external view returns (int unrealizedPriceImpact);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

interface IWETH {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.17;

library UintArray {
    function sum(uint[] memory self) internal pure returns (uint) {
        uint total;
        for (uint i = 0; i < self.length; i++) {
            total += self[i];
        }
        return total;
    }

    function copy(uint[] memory self) internal pure returns (uint[] memory copied) {
        copied = new uint[](self.length);
        for (uint i = 0; i < self.length; i++) {
            copied[i] = self[i];
        }
    }
}

// SPDX-License-Identifier: BSL 1.1

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

// SPDX-License-Identifier: BSL 1.1

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IAddressProvider.sol";

/**
 * @dev Contract module that manages access from non EOA accounts (other contracts)
 *
 * Inheriting from `BlockNonEOAUpgradeable` will make the {onlyEOA} modifier
 * available, which can be applied to functions to make sure that only whitelisted
 * contracts or EOAs can call them if contract calls are disabled.
 */
abstract contract BlockNonEOAUpgradeable is Initializable {
    
    IAddressProvider public addressProvider;

    bool public allowContractCalls;

    mapping (address=>bool) public whitelistedUsers;

    function __BlockNonEOAUpgradeable_init(address _provider) internal onlyInitializing {
        addressProvider = IAddressProvider(_provider);
    }

    function _checkEOA() private view {
        if (!allowContractCalls && !whitelistedUsers[msg.sender]) {
            require(msg.sender == tx.origin, "E35");
        }
    }

    /**
     * @notice If contract calls are disabled, block non whitelisted contracts
     */
    modifier onlyEOA() {
        _checkEOA();
        _;
    }

    /**
     * @notice Set whether other contracts can call onlyEOA functions
     */
    function setAllowContractCalls(bool _allowContractCalls) public {
        require(msg.sender==addressProvider.governance(), "Unauthorized");
        allowContractCalls = _allowContractCalls;
    }

    /**
     * @notice Whitelist or remove whitelist access for nonEOAs for accessing onlyEOA functions
     */
    function setWhitelistUsers(address[] memory users, bool[] memory allowed) public {
        require(msg.sender==addressProvider.governance(), "Unauthorized");
        for (uint i = 0; i<users.length; i++) {
            whitelistedUsers[users[i]] = allowed[i];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}